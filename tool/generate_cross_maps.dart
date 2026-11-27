import 'dart:convert';
import 'dart:io';
import 'package:nagarsevak_mobile/core/localization/app_translations_data.dart';

void main() async {
  final mrToEn = <String, String>{};
  final mrToHi = <String, String>{};
  final hiToEn = <String, String>{};
  final hiToMr = <String, String>{};

  for (final enKey in kAppReverseMr.keys) {
    final mrVal = kAppReverseMr[enKey]?.trim().toLowerCase();
    final hiVal = kAppReverseHi[enKey]?.trim().toLowerCase();
    if (mrVal != null && mrVal.isNotEmpty) {
      mrToEn[mrVal] = enKey;
      if (hiVal != null && hiVal.isNotEmpty) {
        mrToHi[mrVal] = kAppReverseHi[enKey]!;
      }
    }
    if (hiVal != null && hiVal.isNotEmpty) {
      hiToEn[hiVal] = enKey;
      if (mrVal != null && mrVal.isNotEmpty) {
        hiToMr[hiVal] = kAppReverseMr[enKey]!;
      }
    }
  }

  print('Cross maps: mrToEn: ${mrToEn.length}, mrToHi: ${mrToHi.length}, hiToEn: ${hiToEn.length}, hiToMr: ${hiToMr.length}');

  final file = File('lib/core/localization/app_translations_data.dart');
  final content = await file.readAsString();

  final buf = StringBuffer(content);
  buf.writeln();
  buf.writeln('const Map<String, String> kAppCrossMrToEn = ${jsonEncode(mrToEn)};');
  buf.writeln();
  buf.writeln('const Map<String, String> kAppCrossMrToHi = ${jsonEncode(mrToHi)};');
  buf.writeln();
  buf.writeln('const Map<String, String> kAppCrossHiToEn = ${jsonEncode(hiToEn)};');
  buf.writeln();
  buf.writeln('const Map<String, String> kAppCrossHiToMr = ${jsonEncode(hiToMr)};');

  await file.writeAsString(buf.toString());
  print('Cross-language maps successfully written to app_translations_data.dart!');
}
