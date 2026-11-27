import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

void main() async {
  final file = File('lib/core/localization/translations_data.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  final en = data['en'] as Map<String, dynamic>;
  final mr = (data['mr'] ?? {}) as Map<String, dynamic>;
  final hi = (data['hi'] ?? {}) as Map<String, dynamic>;

  final translator = GoogleTranslator();

  // Find all keys in en that are missing in mr or hi
  print('Ensuring all modules exist...');
  for (final mod in en.keys) {
    if (!mr.containsKey(mod)) mr[mod] = <String, dynamic>{};
    if (!hi.containsKey(mod)) hi[mod] = <String, dynamic>{};
  }

  // Pre-seed common words map
  final Map<String, String> reverseMr = {};
  final Map<String, String> reverseHi = {};

  void walk(dynamic e, dynamic m, dynamic h) {
    if (e is Map<String, dynamic>) {
      for (final k in e.keys) {
        final ev = e[k];
        final mv = (m is Map) ? m[k] : null;
        final hv = (h is Map) ? h[k] : null;
        if (ev is String) {
          final trimmed = ev.trim();
          if (trimmed.isNotEmpty) {
            if (mv is String && mv.trim().isNotEmpty) {
              reverseMr[trimmed.toLowerCase()] = mv.trim();
            }
            if (hv is String && hv.trim().isNotEmpty) {
              reverseHi[trimmed.toLowerCase()] = hv.trim();
            }
          }
        } else if (ev is Map) {
          walk(ev, mv, hv);
        }
      }
    }
  }

  walk(en, mr, hi);
  print('Initial MR index: ${reverseMr.length}, HI index: ${reverseHi.length}');

  // Output app_translations_data.dart
  final outputDart = '''
/// Auto-generated complete translations dataset matching Nagarsevak-Managment
const Map<String, dynamic> kAppTranslationsData = ${jsonEncode({
    'en': en,
    'mr': mr,
    'hi': hi,
  })};

const Map<String, String> kAppReverseMr = ${jsonEncode(reverseMr)};

const Map<String, String> kAppReverseHi = ${jsonEncode(reverseHi)};
''';

  File('lib/core/localization/app_translations_data.dart')
      .writeAsStringSync(outputDart);
  print('Successfully generated lib/core/localization/app_translations_data.dart');
}
