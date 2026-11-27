import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../localization/app_translations.dart';
import '../../presentation/providers/language_provider.dart';

/// Dynamic Translation Service matching Nagarsevak-Managment
/// Powered by GoogleTranslator Flutter package + AppTranslations static dictionary + caching.
/// Seamlessly translates user-added data, titles, descriptions, names and notes.
class DynamicTranslationService {
  DynamicTranslationService._();

  static final GoogleTranslator _translator = GoogleTranslator();
  static final Map<String, String> _cache = {};
  static const int _maxCacheSize = 2000;

  /// Fast synchronous lookup in static dictionary, custom overrides, or in-memory cache
  static String? getCachedTranslation(String text, String targetLang) {
    if (targetLang == 'en' || text.trim().isEmpty) return text;

    final trimmed = text.trim();

    // 1. Static dictionary lookup (Instant zero-latency)
    final staticHit = AppTranslations.tr(trimmed, lang: targetLang);
    if (staticHit != null) return staticHit;

    // 2. In-memory cache lookup
    final key = '${trimmed}_$targetLang';
    if (_cache.containsKey(key)) return _cache[key];

    return null;
  }

  /// Translates dynamic text asynchronously using GoogleTranslator package
  static Future<String> translateText(
    String text,
    String targetLang, {
    String sourceLang = 'auto',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || targetLang == 'en') {
      return text;
    }

    // Fast-check cache & dictionary
    final cached = getCachedTranslation(trimmed, targetLang);
    if (cached != null) return cached;

    final cacheKey = '${trimmed}_$targetLang';

    try {
      // Use the GoogleTranslator package
      final translation = await _translator.translate(
        trimmed,
        from: sourceLang == 'auto' ? 'auto' : sourceLang,
        to: targetLang,
      );

      final result = translation.text.trim();
      if (result.isNotEmpty) {
        _saveToCache(cacheKey, result);
        return result;
      }
    } catch (_) {
      // Fallback: return original text safely
    }

    return text;
  }

  /// Phonetic transliteration for citizen/voter names matching Nagarsevak-Managment
  static Future<String> transliterateName(String name, String targetLang) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || (targetLang != 'mr' && targetLang != 'hi')) {
      return name;
    }

    final cacheKey = 'translit_${trimmed}_$targetLang';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final uri = Uri.parse(
        'https://inputtools.google.com/request?text=${Uri.encodeComponent(trimmed)}&itc=$targetLang-t-i0-und&num=1',
      );
      final response = await http.post(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] == 'SUCCESS' && data.length > 1) {
          final list = data[1];
          if (list is List && list.isNotEmpty && list[0] is List) {
            final cand = list[0][1];
            if (cand is List && cand.isNotEmpty) {
              final result = cand[0].toString();
              _saveToCache(cacheKey, result);
              return result;
            }
          }
        }
      }
    } catch (_) {}

    // Fallback to regular translate if phonetic transliteration fails
    return translateText(trimmed, targetLang);
  }

  static void _saveToCache(String key, String value) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }
}

/// Reactive Widget that displays text translated into the active app language.
/// Instant display from static dictionary or cache, with background dynamic translation.
class AppTranslatedText extends ConsumerStatefulWidget {
  final String text;
  final String? targetLanguage;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isName;

  const AppTranslatedText(
    this.text, {
    super.key,
    this.targetLanguage,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isName = false,
  });

  @override
  ConsumerState<AppTranslatedText> createState() => _AppTranslatedTextState();
}

class _AppTranslatedTextState extends ConsumerState<AppTranslatedText> {
  String _displayedText = '';

  @override
  void initState() {
    super.initState();
    _displayedText = widget.text;
    _resolveTranslation();
  }

  @override
  void didUpdateWidget(covariant AppTranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.targetLanguage != widget.targetLanguage ||
        oldWidget.isName != widget.isName) {
      _displayedText = widget.text;
      _resolveTranslation();
    }
  }

  void _resolveTranslation() {
    final String currentLang = widget.targetLanguage ?? ref.read(appLanguageProvider);
    if (currentLang == 'en' || widget.text.trim().isEmpty) {
      _displayedText = widget.text;
      return;
    }

    final cached = DynamicTranslationService.getCachedTranslation(widget.text, currentLang);
    if (cached != null) {
      _displayedText = cached;
      return;
    }

    // Asynchronously translate or transliterate
    final future = widget.isName
        ? DynamicTranslationService.transliterateName(widget.text, currentLang)
        : DynamicTranslationService.translateText(widget.text, currentLang);

    future.then((translated) {
      if (mounted && translated != _displayedText) {
        setState(() {
          _displayedText = translated;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for language changes if targetLanguage is dynamic
    if (widget.targetLanguage == null) {
      ref.listen<String>(appLanguageProvider, (prev, next) {
        if (prev != next) {
          _resolveTranslation();
        }
      });
    }

    // Direct synchronous fallback if already in dictionary for instant rendering
    final String currentLang = widget.targetLanguage ?? ref.watch(appLanguageProvider);
    final String instantHit = currentLang == 'en'
        ? widget.text
        : (AppTranslations.tr(widget.text, lang: currentLang) ?? _displayedText);

    final String finalText = currentLang == 'en'
        ? instantHit
        : AppTranslations.formatDigits(instantHit, currentLang);

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
