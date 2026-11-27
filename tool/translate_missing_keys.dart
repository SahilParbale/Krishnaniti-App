import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

void main() async {
  print('Starting full translation compilation...');
  final file = File('lib/core/localization/translations_data.json');
  if (!file.existsSync()) {
    print('translations_data.json not found!');
    return;
  }

  final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final en = data['en'] as Map<String, dynamic>? ?? {};
  final mr = data['mr'] as Map<String, dynamic>? ?? {};
  final hi = data['hi'] as Map<String, dynamic>? ?? {};

  final translator = GoogleTranslator();

  // Helper to deep traverse and fill missing translations
  Future<void> fillTranslations(
    Map<String, dynamic> source,
    Map<String, dynamic> target,
    String targetLang,
    String prefix,
  ) async {
    for (final key in source.keys) {
      final sourceVal = source[key];
      final currentPath = prefix.isEmpty ? key : '$prefix.$key';

      if (sourceVal is Map<String, dynamic>) {
        if (!target.containsKey(key) || target[key] is! Map<String, dynamic>) {
          target[key] = <String, dynamic>{};
        }
        await fillTranslations(
          sourceVal,
          target[key] as Map<String, dynamic>,
          targetLang,
          currentPath,
        );
      } else if (sourceVal is String && sourceVal.trim().isNotEmpty) {
        final existing = target[key];
        if (existing == null ||
            existing is! String ||
            existing.trim().isEmpty ||
            existing == 'undefined' ||
            existing == sourceVal && targetLang != 'en' && !isShortAcronym(sourceVal)) {
          // Translate
          try {
            final res = await translator.translate(sourceVal, from: 'en', to: targetLang);
            final translated = res.text.trim();
            target[key] = translated.isNotEmpty ? translated : sourceVal;
            print('[$targetLang] $currentPath: "$sourceVal" -> "${target[key]}"');
            // Small throttle to be gentle
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (e) {
            print('Error translating $currentPath: $e');
            target[key] = sourceVal;
          }
        }
      }
    }
  }

  print('1. Filling missing Marathi translations...');
  await fillTranslations(en, mr, 'mr', '');

  print('2. Filling missing Hindi translations...');
  await fillTranslations(en, hi, 'hi', '');

  data['en'] = en;
  data['mr'] = mr;
  data['hi'] = hi;

  // Save updated JSON
  final encoder = const JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(data));
  print('Saved updated translations_data.json!');

  // Build reverse maps
  final reverseMr = <String, String>{};
  final reverseHi = <String, String>{};

  void buildReverseMaps(
    Map<String, dynamic> enNode,
    Map<String, dynamic> mrNode,
    Map<String, dynamic> hiNode,
  ) {
    for (final key in enNode.keys) {
      final enVal = enNode[key];
      final mrVal = mrNode[key];
      final hiVal = hiNode[key];

      if (enVal is Map<String, dynamic>) {
        buildReverseMaps(
          enVal,
          mrVal is Map<String, dynamic> ? mrVal : {},
          hiVal is Map<String, dynamic> ? hiVal : {},
        );
      } else if (enVal is String && enVal.trim().isNotEmpty) {
        final cleanEn = enVal.trim().toLowerCase();
        if (mrVal is String && mrVal.trim().isNotEmpty) {
          reverseMr[cleanEn] = mrVal.trim();
        }
        if (hiVal is String && hiVal.trim().isNotEmpty) {
          reverseHi[cleanEn] = hiVal.trim();
        }
      }
    }
  }

  buildReverseMaps(en, mr, hi);
  print('Reverse maps generated: MR = ${reverseMr.length}, HI = ${reverseHi.length}');

  // Save Dart code file
  final dartFile = File('lib/core/localization/app_translations_data.dart');
  final dartBuf = StringBuffer();
  dartBuf.writeln('// GENERATED FILE - DO NOT EDIT MANUALLY');
  dartBuf.writeln('// Contains complete 3-language translation dictionary [en, mr, hi]');
  dartBuf.writeln('const Map<String, dynamic> kAppTranslationsData = ${jsonEncode(data)};');
  dartBuf.writeln();
  dartBuf.writeln('const Map<String, String> kAppReverseMr = ${jsonEncode(reverseMr)};');
  dartBuf.writeln();
  dartBuf.writeln('const Map<String, String> kAppReverseHi = ${jsonEncode(reverseHi)};');

  await dartFile.writeAsString(dartBuf.toString());
  print('Saved updated app_translations_data.dart!');
  print('Translation compilation finished successfully!');
}

bool isShortAcronym(String s) {
  final t = s.trim();
  if (t.length <= 4 && t == t.toUpperCase() && !t.contains(' ')) return true;
  if (t == 'All' || t == 'ID' || t == 'PDF' || t == 'SMS' || t == 'AI' || t == 'OCR' || t == 'EPIC') return true;
  return false;
}
