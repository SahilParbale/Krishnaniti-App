import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../presentation/providers/language_provider.dart';

/// Dynamic Translation Service matching Nagarsevak-Managment (translationService.ts)
/// Automatically translates user-added data (complaints, letters, titles, descriptions, notes)
/// into Marathi ('mr') or Hindi ('hi') on the fly using Google Translate GTX API + in-memory caching.
class DynamicTranslationService {
  DynamicTranslationService._();

  static final Map<String, String> _cache = {};
  static const int _maxCacheSize = 1000;

  static const String _apiUrl = 'https://translate.googleapis.com/translate_a/single';

  /// Pre-seeded dictionary matching Nagarsevak-Managment CUSTOM_TRANSLATIONS
  static const Map<String, Map<String, String>> _customOverrides = {
    'mr': {
      'Dhankawadi': 'धनकवडी',
      'Bibwewadi': 'बिबवेवाडी',
      'Katraj': 'कात्रज',
      'Sahakar Nagar': 'सहकार नगर',
      'Padmavati': 'पद्मावती',
      'Balaji Nagar': 'बालाजी नगर',
      'Parvati': 'पार्वती',
      'Pune': 'पुणे',
      'Maharashtra': 'महाराष्ट्र',
      'Lokmanya Nagar': 'लोकमान्य नगर',
      'Waste Management': 'कचरा व्यवस्थापन',
      'Street Lighting': 'पथदिवे',
      'Water Distribution': 'पाणी पुरवठा',
      'Public Health': 'सार्वजनिक आरोग्य',
      'Road Construction': 'रस्ते बांधकाम',
      'Administration': 'प्रशासन',
      'water issue': 'पाणी समस्या',
      'Cleanliness Drive': 'स्वच्छता मोहीम',
      'Pothole on Road': 'रस्त्यावरील खड्डा',
      'Street light not working': 'पथदिवे बंद आहेत',
      'Garbage pile up': 'कचऱ्याचे ढीग',
      'Drainage Leakage': 'ड्रेनेज गळती',
      'Hospital Admission': 'रुग्णालय प्रवेश',
      'School Admission': 'शाळा प्रवेश',
      'Residence Certificate': 'रहिवासी दाखला',
      'Income Certificate': 'उत्पन्न दाखला',
      'Character Certificate': 'चारित्र्य दाखला',
      'Pending': 'लंबित',
      'In Progress': 'प्रगतीपथावर',
      'Resolved': 'निवारण झाले',
      'Closed': 'बंद',
    },
    'hi': {
      'Dhankawadi': 'धनकवडी',
      'Bibwewadi': 'बिबवेवाडी',
      'Katraj': 'कात्रज',
      'Sahakar Nagar': 'सहकार नगर',
      'Padmavati': 'पद्मावती',
      'Balaji Nagar': 'बालाजी नगर',
      'Parvati': 'पार्वती',
      'Pune': 'पुणे',
      'Maharashtra': 'महाराष्ट्र',
      'Lokmanya Nagar': 'लोकमान्य नगर',
      'Waste Management': 'कचरा प्रबंधन',
      'Street Lighting': 'स्ट्रीट लाइट',
      'Water Distribution': 'जल वितरण',
      'Public Health': 'सार्वजनिक स्वास्थ्य',
      'Road Construction': 'सड़क निर्माण',
      'Administration': 'प्रशासन',
      'water issue': 'पानी की समस्या',
      'Cleanliness Drive': 'स्वच्छता अभियान',
      'Pothole on Road': 'सड़क पर गड्ढा',
      'Street light not working': 'स्ट्रीट लाइट बंद है',
      'Garbage pile up': 'कचरे का ढेर',
      'Drainage Leakage': 'ड्रेनेज लीकेज',
      'Hospital Admission': 'अस्पताल प्रवेश',
      'School Admission': 'स्कूल प्रवेश',
      'Residence Certificate': 'निवास प्रमाण पत्र',
      'Income Certificate': 'आय प्रमाण पत्र',
      'Character Certificate': 'चरित्र प्रमाण पत्र',
      'Pending': 'लंबित',
      'In Progress': 'प्रगति पर',
      'Resolved': 'समाधान हुआ',
      'Closed': 'बंद',
    },
  };

  /// Synchronous fast-lookup if already cached or in dictionary
  static String? getCachedTranslation(String text, String targetLang) {
    if (targetLang == 'en' || text.trim().isEmpty) return text;

    final key = '${text.trim()}_$targetLang';
    if (_cache.containsKey(key)) return _cache[key];

    // Check custom overrides
    final overrides = _customOverrides[targetLang];
    if (overrides != null && overrides.containsKey(text.trim())) {
      return overrides[text.trim()];
    }

    return null;
  }

  /// Translates text on the fly.
  /// If targetLang is 'en' or already translated, returns immediately.
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
      final uri = Uri.parse(_apiUrl).replace(queryParameters: {
        'client': 'gtx',
        'sl': sourceLang,
        'tl': targetLang,
        'dt': 't',
        'q': trimmed,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final dynamic parsed = jsonDecode(response.body);
        if (parsed is List && parsed.isNotEmpty && parsed[0] is List) {
          final buffer = StringBuffer();
          for (final segment in parsed[0]) {
            if (segment is List && segment.isNotEmpty) {
              buffer.write(segment[0]?.toString() ?? '');
            }
          }
          final translated = buffer.toString().trim();
          if (translated.isNotEmpty) {
            _saveToCache(cacheKey, translated);
            return translated;
          }
        }
      }
    } catch (_) {
      // Return original on network timeout / failure
    }

    return text;
  }

  static void _saveToCache(String key, String value) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }
}

/// Reactive Widget that displays text translated into the active app language.
/// Seamlessly reflects user language switches (English, Marathi, Hindi).
class AppTranslatedText extends ConsumerStatefulWidget {
  final String text;
  final String? targetLanguage;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppTranslatedText(
    this.text, {
    super.key,
    this.targetLanguage,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
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
    if (oldWidget.text != widget.text || oldWidget.targetLanguage != widget.targetLanguage) {
      _displayedText = widget.text;
      _resolveTranslation();
    }
  }

  void _resolveTranslation() {
    final String currentLang = widget.targetLanguage ?? ref.read(appLanguageProvider);
    if (currentLang == 'en') {
      _displayedText = widget.text;
      return;
    }

    final cached = DynamicTranslationService.getCachedTranslation(widget.text, currentLang);
    if (cached != null) {
      _displayedText = cached;
      return;
    }

    // Asynchronously fetch translation
    DynamicTranslationService.translateText(widget.text, currentLang).then((translated) {
      if (mounted) {
        setState(() {
          _displayedText = translated;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for language changes if targetLanguage is not hardcoded
    if (widget.targetLanguage == null) {
      ref.listen<String>(appLanguageProvider, (prev, next) {
        if (prev != next) {
          _resolveTranslation();
        }
      });
    }

    return Text(
      _displayedText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
