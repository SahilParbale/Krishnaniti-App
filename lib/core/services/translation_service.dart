import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import '../localization/app_translations.dart';
import '../../presentation/providers/language_provider.dart';

/// Cross-Lingual Dynamic Translation Service supporting ALL 6 directions
/// (`en <-> mr <-> hi`) for present & future user-added data.
///
/// Features:
/// - Instant lookup in static 3-language dictionary & custom domain overrides.
/// - Domain term protection (Dhankawadi, Katraj, Ward/Sector labels, etc.).
/// - Bidirectional digit localization (`0-9 <-> ०-९`) preserving URLs & emails.
/// - In-memory + persistent SharedPreferences caching (`ns_dyn_tr_v1_`).
/// - In-flight request deduplication & bounded concurrency queue (avoids HTTP 429).
/// - Multi-endpoint fallback: Google Translate (`gtx` GET -> `GoogleTranslator` `siteGT`).
/// - Full multi-word name phonetic transliteration via Google Input Tools (`en -> mr/hi`)
///   + deterministic Devanagari-to-Latin phonetic transliterator (`mr/hi -> en`).
class DynamicTranslationService {
  DynamicTranslationService._();

  static final GoogleTranslator _siteTranslator = GoogleTranslator(client: ClientType.siteGT);
  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _inFlight = {};
  static const int _maxCacheSize = 3000;
  static const String _prefPrefix = 'ns_dyn_tr_v1_';
  static bool _diskLoaded = false;

  // Bounded concurrency pool (max 4 simultaneous HTTP translation calls)
  static const int _maxConcurrent = 4;
  static int _activeRequests = 0;
  static final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  static final RegExp _devanagariRegex = RegExp(r'[\u0900-\u097F]');
  static final RegExp _latinRegex = RegExp(r'[A-Za-z]');

  static bool containsDevanagari(String text) => _devanagariRegex.hasMatch(text);
  static bool containsLatin(String text) => _latinRegex.hasMatch(text);

  static Future<void> _acquireSlot() async {
    if (_activeRequests < _maxConcurrent) {
      _activeRequests++;
      return;
    }
    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
  }

  static void _releaseSlot() {
    if (_waitQueue.isNotEmpty) {
      final next = _waitQueue.removeFirst();
      next.complete();
    } else if (_activeRequests > 0) {
      _activeRequests--;
    }
  }

  /// Hydrate in-memory cache from SharedPreferences once
  static Future<void> ensureDiskCacheLoaded() async {
    if (_diskLoaded) return;
    _diskLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final k in keys) {
        if (k.startsWith(_prefPrefix)) {
          final val = prefs.getString(k);
          if (val != null && val.isNotEmpty) {
            _cache[k.substring(_prefPrefix.length)] = val;
          }
        }
      }
    } catch (_) {}
  }

  /// Fast synchronous lookup in static dictionary, custom overrides, or in-memory cache
  static String? getCachedTranslation(
    String text,
    String targetLang, {
    bool isName = false,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    // Normalize purely numeric/symbol strings instantaneously
    if (!containsDevanagari(trimmed) && !containsLatin(trimmed)) {
      return AppTranslations.formatDigits(text, targetLang);
    }

    // Fast path for English target: if purely Latin (no Devanagari), return formatted digits
    if (targetLang == 'en' && !containsDevanagari(trimmed)) {
      return AppTranslations.formatDigits(text, 'en');
    }

    // 1. Static dictionary / cross-maps / custom overrides (instant zero-latency)
    if (!isName) {
      final staticHit = AppTranslations.tr(trimmed, lang: targetLang);
      if (staticHit != null && !(targetLang == 'en' && containsDevanagari(staticHit))) {
        return AppTranslations.formatDigits(staticHit, targetLang);
      }
    }

    // 2. Check structured civic area / status / type patterns
    if (!isName) {
      final areaHit = _tryStructuredCivicMatch(trimmed, targetLang);
      if (areaHit != null) return areaHit;
    }

    // 3. In-memory cache lookup
    final cacheKey = isName ? 'translit_${trimmed}_$targetLang' : '${trimmed}_$targetLang';
    if (_cache.containsKey(cacheKey)) {
      return AppTranslations.formatDigits(_cache[cacheKey]!, targetLang);
    }

    // If name in Devanagari -> English, deterministic phonetic transliterator works offline instantly
    if (isName && targetLang == 'en' && containsDevanagari(trimmed)) {
      final transliterated = transliterateDevanagariToLatin(trimmed);
      _saveToCache(cacheKey, transliterated);
      return AppTranslations.formatDigits(transliterated, 'en');
    }

    return null;
  }

  static String? _tryStructuredCivicMatch(String trimmed, String targetLang) {
    final lower = trimmed.toLowerCase();
    if (RegExp(r'^(?:sector|ward|prabhag|lane|सेक्टर|प्रभाग|वार्ड|गल्ली|गली)\b', caseSensitive: false)
        .hasMatch(trimmed)) {
      final res = AppTranslations.getAreaName(trimmed, targetLang);
      if (res != trimmed) return res;
    }
    const fastStatuses = {
      'pending', 'assigned', 'inprogress', 'in progress', 'resolved', 'closed',
      'approved', 'rejected', 'completed', 'planned',
    };
    if (fastStatuses.contains(lower)) {
      return AppTranslations.getStatus(trimmed, targetLang);
    }
    return null;
  }

  /// Translates dynamic text asynchronously across ALL 6 directions (`en <-> mr <-> hi`)
  static Future<String> translateText(
    String text,
    String targetLang, {
    String sourceLang = 'auto',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    await ensureDiskCacheLoaded();

    // If purely Latin and target is English, format any localized digits and return
    if (targetLang == 'en' && !containsDevanagari(trimmed)) {
      return AppTranslations.formatDigits(text, 'en');
    }

    // If neither Devanagari nor Latin letters exist (e.g. pure number "125" or date "2026-11-27"), format digits
    if (!containsDevanagari(trimmed) && !containsLatin(trimmed)) {
      return AppTranslations.formatDigits(text, targetLang);
    }

    // Fast-check synchronous dictionary & memory/disk cache
    final cached = getCachedTranslation(trimmed, targetLang);
    if (cached != null) return cached;

    final cacheKey = '${trimmed}_$targetLang';
    if (_inFlight.containsKey(cacheKey)) {
      return _inFlight[cacheKey]!;
    }

    final future = _performTranslate(text, trimmed, targetLang, sourceLang, cacheKey);
    _inFlight[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  static Future<String> _performTranslate(
    String originalText,
    String trimmed,
    String targetLang,
    String sourceLang,
    String cacheKey,
  ) async {
    // 1. Protect known civic terms (`Dhankawadi`, `Katraj`, certificate types, etc.)
    String textToTranslate = trimmed;
    final protections = <({String placeholder, String replacement})>[];

    final overrides = AppTranslations.customOverrides[targetLang];
    if (overrides != null && overrides.isNotEmpty) {
      final sortedKeys = overrides.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
      for (int i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        if (key.length < 4) continue; // Avoid over-eager short word replacements
        final regex = RegExp('\\b${RegExp.escape(key)}\\b', caseSensitive: false);
        if (regex.hasMatch(textToTranslate)) {
          final placeholder = '[[_${protections.length}_]]';
          protections.add((placeholder: placeholder, replacement: overrides[key]!));
          textToTranslate = textToTranslate.replaceAll(regex, placeholder);
        }
      }
    }

    if (protections.length == 1 && textToTranslate.trim() == protections[0].placeholder) {
      final res = AppTranslations.formatDigits(protections[0].replacement, targetLang);
      _saveToCache(cacheKey, res, persist: true);
      return res;
    }

    // 2. Chunk long texts (>450 chars) by newline/sentence to avoid URI length limits
    if (textToTranslate.length > 450) {
      final delimiter = textToTranslate.contains('\n\n')
          ? '\n\n'
          : (textToTranslate.contains('\n') ? '\n' : '. ');
      final rawParts = textToTranslate.split(delimiter);
      if (rawParts.length > 1) {
        final chunks = <String>[];
        var current = '';
        for (final piece in rawParts) {
          if (current.length + piece.length > 420 && current.isNotEmpty) {
            chunks.add(current);
            current = piece;
          } else {
            current = current.isEmpty ? piece : '$current$delimiter$piece';
          }
        }
        if (current.isNotEmpty) chunks.add(current);

        final translatedParts = await Future.wait(
          chunks.map((c) => c.trim().isEmpty
              ? Future.value(c)
              : _singleApiCall(c, targetLang, sourceLang)),
        );
        var combined = translatedParts.join(delimiter);
        combined = _restoreProtections(combined, protections);
        final formatted = AppTranslations.formatDigits(combined, targetLang);
        _saveToCache(cacheKey, formatted, persist: true);
        return formatted;
      }
    }

    // 3. Single translation call with concurrency limiting
    final rawResult = await _singleApiCall(textToTranslate, targetLang, sourceLang);
    if (rawResult.trim().isNotEmpty) {
      final restored = _restoreProtections(rawResult, protections);
      final formatted = AppTranslations.formatDigits(restored, targetLang);
      _saveToCache(cacheKey, formatted, persist: true);
      return formatted;
    }

    return AppTranslations.formatDigits(originalText, targetLang);
  }

  static String _restoreProtections(
    String text,
    List<({String placeholder, String replacement})> protections,
  ) {
    var result = text;
    for (int i = 0; i < protections.length; i++) {
      final p = protections[i];
      final flexRegex = RegExp('\\[\\s*\\[\\s*_$i\\s*_\\]\\s*\\]');
      result = result.replaceAll(flexRegex, p.replacement);
      result = result.replaceAll(p.placeholder, p.replacement);
    }
    return result;
  }

  static Future<String> _singleApiCall(
    String text,
    String targetLang,
    String sourceLang,
  ) async {
    final sl = sourceLang == 'autodetect' ? 'auto' : sourceLang;
    await _acquireSlot();
    try {
      // Endpoint 1: Direct Google Translate GTX (CORS friendly for Flutter Web & low latency on Mobile)
      try {
        final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
          'client': 'gtx',
          'sl': sl,
          'tl': targetLang,
          'dt': 't',
          'q': text,
        });
        final resp = await http.get(uri).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final jsonData = jsonDecode(resp.body);
          if (jsonData is List && jsonData.isNotEmpty && jsonData[0] is List) {
            final sb = StringBuffer();
            for (final seg in (jsonData[0] as List)) {
              if (seg is List && seg.isNotEmpty && seg[0] != null) {
                sb.write(seg[0].toString());
              }
            }
            final out = sb.toString().trim();
            if (out.isNotEmpty) return out;
          }
        }
      } catch (_) {}

      // Endpoint 2: Fallback to GoogleTranslator package (`siteGT`)
      try {
        final translation = await _siteTranslator
            .translate(text, from: sl, to: targetLang)
            .timeout(const Duration(seconds: 5));
        final out = translation.text.trim();
        if (out.isNotEmpty) return out;
      } catch (_) {}

      return text;
    } finally {
      _releaseSlot();
    }
  }

  static const Map<String, Map<String, String>> _honorificMap = {
    'mr': {
      'Mr.': 'श्री.',
      'Mr': 'श्री.',
      'Mrs.': 'सौ.',
      'Mrs': 'सौ.',
      'Ms.': 'कु.',
      'Ms': 'कु.',
      'Miss': 'कु.',
      'Dr.': 'डॉ.',
      'Dr': 'डॉ.',
      'Shri': 'श्री.',
      'Smt.': 'सौ.',
      'Adv.': 'अ‍ॅड.',
    },
    'hi': {
      'Mr.': 'श्री',
      'Mr': 'श्री',
      'Mrs.': 'श्रीमती',
      'Mrs': 'श्रीमती',
      'Ms.': 'सुश्री',
      'Ms': 'सुश्री',
      'Miss': 'सुश्री',
      'Dr.': 'डॉ.',
      'Dr': 'डॉ.',
      'Shri': 'श्री',
      'Smt.': 'श्रीमती',
      'Adv.': 'एड.',
    },
    'en': {
      'श्री.': 'Mr.',
      'श्री': 'Shri',
      'सौ.': 'Mrs.',
      'श्रीमती': 'Mrs.',
      'कु.': 'Ms.',
      'सुश्री': 'Ms.',
      'डॉ.': 'Dr.',
      'अ‍ॅड.': 'Adv.',
      'एड.': 'Adv.',
    },
  };

  /// Bidirectional phonetic transliteration for citizen, voter, staff, society & leader names.
  /// Handles `en -> mr/hi` (multi-word Google Input Tools) AND `mr/hi -> en` (deterministic phonetic).
  static Future<String> transliterateName(String name, String targetLang) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return name;

    await ensureDiskCacheLoaded();

    if (targetLang == 'en') {
      if (!containsDevanagari(trimmed)) {
        return AppTranslations.formatDigits(name, 'en');
      }
      final cacheKey = 'translit_${trimmed}_en';
      if (_cache.containsKey(cacheKey)) {
        return AppTranslations.formatDigits(_cache[cacheKey]!, 'en');
      }
      final res = transliterateDevanagariToLatin(trimmed);
      final formatted = AppTranslations.formatDigits(res, 'en');
      _saveToCache(cacheKey, formatted, persist: true);
      return formatted;
    }

    if (targetLang != 'mr' && targetLang != 'hi') {
      return AppTranslations.formatDigits(name, targetLang);
    }

    final cacheKey = 'translit_${trimmed}_$targetLang';
    if (_cache.containsKey(cacheKey)) {
      return AppTranslations.formatDigits(_cache[cacheKey]!, targetLang);
    }

    if (_inFlight.containsKey(cacheKey)) {
      return _inFlight[cacheKey]!;
    }

    final future = _performTransliterate(trimmed, targetLang, cacheKey);
    _inFlight[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  static Future<String> _performTransliterate(
    String trimmed,
    String targetLang,
    String cacheKey,
  ) async {
    // If already in Devanagari with no Latin letters (e.g. Marathi name displayed in Hindi),
    // preserve phonetics across Devanagari directly after digit formatting.
    if (containsDevanagari(trimmed) && !containsLatin(trimmed)) {
      final direct = AppTranslations.formatDigits(trimmed, targetLang);
      _saveToCache(cacheKey, direct, persist: true);
      return direct;
    }

    // Extract honorific prefix
    var body = trimmed;
    var honorificPrefix = '';
    final hMap = _honorificMap[targetLang];
    if (hMap != null) {
      final prefixes = hMap.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
      for (final prefix in prefixes) {
        if (body.toLowerCase().startsWith(prefix.toLowerCase())) {
          final nextIdx = prefix.length;
          if (nextIdx == body.length || body[nextIdx] == ' ' || prefix.endsWith('.')) {
            honorificPrefix = '${hMap[prefix]!} ';
            body = body.substring(prefix.length).trim();
            break;
          }
        }
      }
    }

    if (body.isEmpty) {
      return honorificPrefix.trim();
    }

    // Title-case all-caps society/voter names (e.g. "EXCEL RESIDENCY" -> "Excel Residency")
    // so Google Input Tools transliterates every word cleanly instead of skipping caps.
    final normalizedBody = body.split(RegExp(r'\s+')).map((word) {
      if (word.length > 2 && word == word.toUpperCase() && !RegExp(r'^(CHS|APT|II|III|IV)$').hasMatch(word)) {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }
      return word;
    }).join(' ');

    await _acquireSlot();
    try {
      final uri = Uri.parse(
        'https://inputtools.google.com/request?text=${Uri.encodeComponent(normalizedBody)}&itc=$targetLang-t-i0-und&num=1',
      );
      final response = await http.post(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] == 'SUCCESS' && data.length > 1) {
          final tokens = data[1];
          if (tokens is List && tokens.isNotEmpty) {
            final parts = <String>[];
            for (final item in tokens) {
              if (item is List && item.length > 1 && item[1] is List && (item[1] as List).isNotEmpty) {
                parts.add(item[1][0].toString());
              } else if (item is List && item.isNotEmpty) {
                parts.add(item[0].toString());
              }
            }
            if (parts.isNotEmpty) {
              final rawJoined = '$honorificPrefix${parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim()}';
              final formatted = AppTranslations.formatDigits(rawJoined, targetLang);
              _saveToCache(cacheKey, formatted, persist: true);
              return formatted;
            }
          }
        }
      }
    } catch (_) {
    } finally {
      _releaseSlot();
    }

    // Fallback to Google Translate if Input Tools didn't respond cleanly
    final fallback = await translateText(body, targetLang);
    final result = AppTranslations.formatDigits('$honorificPrefix$fallback'.trim(), targetLang);
    _saveToCache(cacheKey, result, persist: true);
    return result;
  }

  /// Convenience helper for translating or transliterating any arbitrary string (for PDFs/dropdowns)
  static Future<String> translateOrRaw(
    String text,
    String targetLang, {
    bool isName = false,
  }) async {
    if (text.trim().isEmpty) return text;
    if (isName) return transliterateName(text, targetLang);
    return translateText(text, targetLang);
  }

  /// Deduplicated parallel batch translator for PDF report tables and dropdown lists.
  static Future<Map<String, String>> translateBatch(
    Iterable<String> texts,
    String targetLang, {
    bool isName = false,
  }) async {
    await ensureDiskCacheLoaded();
    final unique = <String>{};
    for (final t in texts) {
      final clean = t.trim();
      if (clean.isNotEmpty) unique.add(clean);
    }
    final resultMap = <String, String>{};
    if (unique.isEmpty) return resultMap;

    await Future.wait(unique.map((item) async {
      final res = isName
          ? await transliterateName(item, targetLang)
          : await translateText(item, targetLang);
      resultMap[item] = res;
    }));
    return resultMap;
  }

  /// Deterministic offline phonetic transliterator from Devanagari (Marathi/Hindi) to English/Latin.
  /// Converts names like "श्री. रमेश पाटील" -> "Mr. Ramesh Patil" without translating meaning.
  static String transliterateDevanagariToLatin(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return input;

    // Handle Devanagari honorifics
    var working = trimmed;
    final enHMap = _honorificMap['en']!;
    var prefix = '';
    final keys = enHMap.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final k in keys) {
      if (working.startsWith(k)) {
        prefix = '${enHMap[k]!} ';
        working = working.substring(k.length).trim();
        break;
      }
    }

    const vowels = {
      'अ': 'a', 'आ': 'aa', 'इ': 'i', 'ई': 'ee', 'उ': 'u', 'ऊ': 'oo',
      'ऋ': 'ri', 'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au', 'अं': 'am', 'अः': 'ah',
      'ॲ': 'ae', 'ऑ': 'o',
    };
    const consonants = {
      'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'ng',
      'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'ny',
      'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
      'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
      'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm',
      'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'v', 'श': 'sh',
      'ष': 'sh', 'स': 's', 'ह': 'h', 'ळ': 'l',
      'क़': 'q', 'ख़': 'kh', 'ग़': 'gh', 'ज़': 'z', 'ड़': 'd', 'ढ़': 'dh', 'फ़': 'f',
    };
    const matras = {
      'ा': 'a', 'ि': 'i', 'ी': 'ee', 'ु': 'u', 'ू': 'oo',
      'ृ': 'ri', 'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au',
      'ॅ': 'ae', 'ॉ': 'o', 'ं': 'n', 'ः': 'h', 'ँ': 'n',
    };
    const digits = {
      '०': '0', '१': '1', '२': '2', '३': '3', '४': '4',
      '५': '5', '६': '6', '७': '7', '८': '8', '९': '9',
    };

    final words = working.split(RegExp(r'\s+'));
    final convertedWords = <String>[];

    for (final w in words) {
      if (w.isEmpty) continue;
      final sb = StringBuffer();
      final runes = w.runes.toList();
      for (int i = 0; i < runes.length; i++) {
        final ch = String.fromCharCode(runes[i]);
        final next = (i + 1 < runes.length) ? String.fromCharCode(runes[i + 1]) : null;

        if (digits.containsKey(ch)) {
          sb.write(digits[ch]);
        } else if (vowels.containsKey(ch)) {
          sb.write(vowels[ch]);
        } else if (consonants.containsKey(ch)) {
          sb.write(consonants[ch]);
          if (next == '्') {
            // Virama suppresses inherent 'a'
            i++;
          } else if (next != null && matras.containsKey(next)) {
            sb.write(matras[next]);
            i++;
            // Check following anusvara/chandrabindu
            if (i + 1 < runes.length) {
              final after = String.fromCharCode(runes[i + 1]);
              if (after == 'ं' || after == 'ँ') {
                sb.write('n');
                i++;
              }
            }
          } else {
            // Inherent schwa 'a' except typical word-final consonant schwa-deletion in names
            final isLastChar = (i == runes.length - 1);
            if (!isLastChar) {
              sb.write('a');
            }
          }
        } else if (matras.containsKey(ch)) {
          sb.write(matras[ch]);
        } else if (ch == '।') {
          sb.write('.');
        } else if (ch != '्' && ch != '\u200D' && ch != '\u200C') {
          sb.write(ch);
        }
      }
      final resWord = sb.toString();
      if (resWord.isNotEmpty) {
        convertedWords.add('${resWord[0].toUpperCase()}${resWord.substring(1)}');
      }
    }

    return '$prefix${convertedWords.join(' ')}'.trim();
  }

  static void _saveToCache(String key, String value, {bool persist = false}) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
    if (persist) {
      SharedPreferences.getInstance().then((prefs) {
        return prefs.setString('$_prefPrefix$key', value);
      }).catchError((_) => false);
    }
  }
}

/// Reactive Widget that displays ANY text (static OR user-added future data in any language)
/// translated/transliterated into the active app language (`en`, `mr`, `hi`) with localized numerals.
class AppTranslatedText extends ConsumerStatefulWidget {
  final String text;
  final String? targetLanguage;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isName;
  final bool translateDigits;
  final String prefix;
  final String suffix;
  final Widget Function(BuildContext context, String translated)? builder;

  const AppTranslatedText(
    this.text, {
    super.key,
    this.targetLanguage,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isName = false,
    this.translateDigits = true,
    this.prefix = '',
    this.suffix = '',
    this.builder,
  });

  @override
  ConsumerState<AppTranslatedText> createState() => _AppTranslatedTextState();
}

class _AppTranslatedTextState extends ConsumerState<AppTranslatedText> {
  String _displayedText = '';
  int _requestToken = 0;

  @override
  void initState() {
    super.initState();
    _displayedText = widget.text;
    _resolveTranslation(ref.read(appLanguageProvider));
  }

  @override
  void didUpdateWidget(covariant AppTranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.targetLanguage != widget.targetLanguage ||
        oldWidget.isName != widget.isName) {
      _displayedText = widget.text;
      _resolveTranslation(widget.targetLanguage ?? ref.read(appLanguageProvider));
    }
  }

  void _resolveTranslation(String targetLang) {
    final clean = widget.text.trim();
    if (clean.isEmpty) {
      _displayedText = widget.text;
      return;
    }

    // Fast path: purely Latin when target is English
    if (targetLang == 'en' && !DynamicTranslationService.containsDevanagari(clean)) {
      _displayedText = widget.translateDigits
          ? AppTranslations.formatDigits(widget.text, 'en')
          : widget.text;
      return;
    }

    final cached = DynamicTranslationService.getCachedTranslation(
      widget.text,
      targetLang,
      isName: widget.isName,
    );
    if (cached != null) {
      _displayedText = cached;
      return;
    }

    final myToken = ++_requestToken;
    final future = widget.isName
        ? DynamicTranslationService.transliterateName(widget.text, targetLang)
        : DynamicTranslationService.translateText(widget.text, targetLang);

    future.then((translated) {
      if (mounted && myToken == _requestToken && translated != _displayedText) {
        setState(() {
          _displayedText = translated;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targetLanguage == null) {
      ref.listen<String>(appLanguageProvider, (prev, next) {
        if (prev != next) {
          _resolveTranslation(next);
        }
      });
    }

    final String currentLang = widget.targetLanguage ?? ref.watch(appLanguageProvider);
    final String? syncHit = DynamicTranslationService.getCachedTranslation(
      widget.text,
      currentLang,
      isName: widget.isName,
    );
    final String baseText = syncHit ?? _displayedText;
    final String formatted = widget.translateDigits
        ? AppTranslations.formatDigits(baseText, currentLang)
        : baseText;
    final String finalText = '${widget.prefix}$formatted${widget.suffix}';

    if (widget.builder != null) {
      return widget.builder!(context, finalText);
    }

    return Text(
      finalText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// Helpful String extension for synchronous or quick translations and Devanagari numerals
extension AppTranslateStringX on String {
  String tr(WidgetRef ref) => AppTranslations.translateDirect(this, lang: ref.watch(appLanguageProvider));
  String trLang(String lang) => AppTranslations.translateDirect(this, lang: lang);
  String toDev(String lang) => AppTranslations.formatDigits(this, lang);
  String trDev(String lang) => AppTranslations.formatDigits(AppTranslations.translateDirect(this, lang: lang), lang);
}

extension AppTranslateNumX on num {
  String toDev(String lang) => AppTranslations.formatDigits(this, lang);
  String toDevanagari(String lang) => AppTranslations.formatDigits(this, lang);
}
