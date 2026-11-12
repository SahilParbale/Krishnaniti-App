// Form constants matching Nagarsevak-Managment LetterForm.tsx and translations.ts

class LetterTypeOption {
  final String key;
  final String en;
  final String mr;

  const LetterTypeOption({
    required this.key,
    required this.en,
    required this.mr,
  });
}

const List<LetterTypeOption> kLetterTypeOptions = [
  LetterTypeOption(
    key: 'Residential Certificate',
    en: 'Residential Certificate',
    mr: 'रहिवासी दाखला',
  ),
  LetterTypeOption(
    key: 'Character Certificate',
    en: 'Character Certificate',
    mr: 'चारित्र्याचा दाखला',
  ),
  LetterTypeOption(
    key: 'No Objection Certificate (NOC)',
    en: 'No Objection Certificate (NOC)',
    mr: 'ना हरकत प्रमाणपत्र (NOC)',
  ),
  LetterTypeOption(
    key: 'Income Certificate',
    en: 'Income Certificate',
    mr: 'उत्पन्न प्रमाणपत्र',
  ),
  LetterTypeOption(
    key: 'Recommendation Letter',
    en: 'Recommendation Letter',
    mr: 'शिफारस पत्र',
  ),
  LetterTypeOption(
    key: 'College / Admission Recommendation',
    en: 'College / Admission Recommendation',
    mr: 'महाविद्यालयीन प्रवेश शिफारस',
  ),
  LetterTypeOption(
    key: 'Hospitalization / CM Relief Recommendation',
    en: 'Hospitalization / CM Relief Recommendation',
    mr: 'वैद्यकीय मदत / सीएम सहायता निधी शिफारस',
  ),
  LetterTypeOption(
    key: 'Commercial Electricity Meter NOC',
    en: 'Commercial Electricity Meter NOC',
    mr: 'विद्युत मीटर ना हरकत प्रमाणपत्र',
  ),
  LetterTypeOption(
    key: 'Other Official Request',
    en: 'Other Official Request',
    mr: 'इतर अधिकृत पत्र',
  ),
];

const List<String> kGenderOptions = [
  'Male',
  'Female',
  'Other',
];

