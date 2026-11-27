import 'package:translator/translator.dart';

void main() async {
  final translator = GoogleTranslator();
  final resMr = await translator.translate('Citizen Complaints & Grievances', to: 'mr');
  final resHi = await translator.translate('Citizen Complaints & Grievances', to: 'hi');
  print('MR: ${resMr.text}');
  print('HI: ${resHi.text}');
}
