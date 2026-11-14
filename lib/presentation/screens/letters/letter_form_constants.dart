// Form constants matching Nagarsevak-Managment LetterForm.tsx and translations.ts
import 'package:flutter/material.dart';

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

/// Dynamic Field metadata matching Nagarsevak-Managment translations.ts (letters.dynamic.*)
class DynamicFieldMeta {
  final String key;
  final String enLabel;
  final String mrLabel;
  final TextInputType keyboardType;
  final String placeholderEn;
  final String placeholderMr;

  const DynamicFieldMeta({
    required this.key,
    required this.enLabel,
    required this.mrLabel,
    this.keyboardType = TextInputType.text,
    required this.placeholderEn,
    required this.placeholderMr,
  });
}

const Map<String, DynamicFieldMeta> kDynamicFieldDefinitions = {
  'age': DynamicFieldMeta(
    key: 'age',
    enLabel: 'Age',
    mrLabel: 'वय',
    keyboardType: TextInputType.number,
    placeholderEn: 'Enter Age (e.g. 28)',
    placeholderMr: 'वय प्रविष्ट करा (उदा. २८)',
  ),
  'years_of_residency': DynamicFieldMeta(
    key: 'years_of_residency',
    enLabel: 'Years of Residency',
    mrLabel: 'वास्तव्याची वर्षे',
    keyboardType: TextInputType.number,
    placeholderEn: 'Years living in ward (e.g. 15)',
    placeholderMr: 'वास्तव्याची वर्षे (उदा. १५)',
  ),
  'ward_no': DynamicFieldMeta(
    key: 'ward_no',
    enLabel: 'Ward No.',
    mrLabel: 'प्रभाग क्रमांक',
    placeholderEn: 'Ward No. (e.g. 12)',
    placeholderMr: 'प्रभाग क्रमांक (उदा. १२)',
  ),
  'school_name': DynamicFieldMeta(
    key: 'school_name',
    enLabel: 'School / College Name',
    mrLabel: 'शाळेचे / महाविद्यालयाचे नाव',
    placeholderEn: 'Enter School or College Name',
    placeholderMr: 'शाळेचे / महाविद्यालयाचे नाव प्रविष्ट करा',
  ),
  'school_city': DynamicFieldMeta(
    key: 'school_city',
    enLabel: 'School City',
    mrLabel: 'शाळेचे शहर',
    placeholderEn: 'Enter City',
    placeholderMr: 'शहर प्रविष्ट करा',
  ),
  'financial_condition': DynamicFieldMeta(
    key: 'financial_condition',
    enLabel: 'Financial Condition',
    mrLabel: 'आर्थिक स्थिती',
    placeholderEn: 'e.g. Needy / Middle / Poor',
    placeholderMr: 'उदा. गरजू / मध्यम / अल्पभूधारक',
  ),
  'class_or_course_name': DynamicFieldMeta(
    key: 'class_or_course_name',
    enLabel: 'Class / Course Name',
    mrLabel: 'वर्ग / अभ्यासक्रमाचे नाव',
    placeholderEn: 'e.g. 11th Science / B.Com / Diploma',
    placeholderMr: 'उदा. ११वी विज्ञान / बी.कॉम / डिप्लोमा',
  ),
  'company_name': DynamicFieldMeta(
    key: 'company_name',
    enLabel: 'Company Name',
    mrLabel: 'कंपनीचे नाव',
    placeholderEn: 'Enter Company or Organization Name',
    placeholderMr: 'कंपनीचे किंवा संस्थेचे नाव',
  ),
  'company_address': DynamicFieldMeta(
    key: 'company_address',
    enLabel: 'Company Address',
    mrLabel: 'कंपनीचा पत्ता',
    placeholderEn: 'Enter Office / Company Address',
    placeholderMr: 'कार्यालय / कंपनीचा पत्ता',
  ),
  'education_degree': DynamicFieldMeta(
    key: 'education_degree',
    enLabel: 'Education / Degree',
    mrLabel: 'शिक्षण (पदवी)',
    placeholderEn: 'e.g. B.Tech / MBA / Graduate',
    placeholderMr: 'उदा. बी.टेक / पदवीधर / १२वी',
  ),
  'years_known': DynamicFieldMeta(
    key: 'years_known',
    enLabel: 'Years Known',
    mrLabel: 'ओळखीची वर्षे',
    keyboardType: TextInputType.number,
    placeholderEn: 'Years known personally (e.g. 10)',
    placeholderMr: 'वैयक्तिक ओळखीची वर्षे (उदा. १०)',
  ),
  'reason_for_certificate': DynamicFieldMeta(
    key: 'reason_for_certificate',
    enLabel: 'Reason for Certificate',
    mrLabel: 'प्रमाणपत्राचे कारण',
    placeholderEn: 'e.g. Bank Account / Passport / Verification',
    placeholderMr: 'उदा. बँक खाते / पासपोर्ट / पडताळणी',
  ),
  'municipality_name': DynamicFieldMeta(
    key: 'municipality_name',
    enLabel: 'Municipality Name',
    mrLabel: 'नगरपालिकेचे / मनपा नाव',
    placeholderEn: 'e.g. PMC / PCMC / Municipal Council',
    placeholderMr: 'उदा. पुणे मनपा / नगरपालिका',
  ),
  'date_of_death': DynamicFieldMeta(
    key: 'date_of_death',
    enLabel: 'Date of Death',
    mrLabel: 'मृत्यूची तारीख',
    placeholderEn: 'DD/MM/YYYY',
    placeholderMr: 'दिनांक (उदा. १५/०१/२०२६)',
  ),
  'cause_of_death': DynamicFieldMeta(
    key: 'cause_of_death',
    enLabel: 'Cause of Death',
    mrLabel: 'मृत्यूचे कारण',
    placeholderEn: 'Natural / Illness / Accident',
    placeholderMr: 'नैसर्गिक / आजारपण / अपघात',
  ),
  'hospital_name': DynamicFieldMeta(
    key: 'hospital_name',
    enLabel: 'Hospital Name',
    mrLabel: 'रुग्णालयाचे नाव',
    placeholderEn: 'Enter Hospital Name',
    placeholderMr: 'रुग्णालयाचे नाव प्रविष्ट करा',
  ),
  'gas_agency_name': DynamicFieldMeta(
    key: 'gas_agency_name',
    enLabel: 'Gas Agency Name',
    mrLabel: 'गॅस एजन्सीचे नाव',
    placeholderEn: 'Enter Gas Agency Name',
    placeholderMr: 'गॅस वितरकाचे नाव',
  ),
  'city_name': DynamicFieldMeta(
    key: 'city_name',
    enLabel: 'City Name',
    mrLabel: 'शहराचे नाव',
    placeholderEn: 'Enter City',
    placeholderMr: 'शहर प्रविष्ट करा',
  ),
  'tehsil_name': DynamicFieldMeta(
    key: 'tehsil_name',
    enLabel: 'Tehsil Name',
    mrLabel: 'तहसीलचे नाव',
    placeholderEn: 'Enter Tehsil Name',
    placeholderMr: 'तहसीलचे नाव प्रविष्ट करा',
  ),
  'annual_income': DynamicFieldMeta(
    key: 'annual_income',
    enLabel: 'Annual Income',
    mrLabel: 'वार्षिक उत्पन्न (₹)',
    keyboardType: TextInputType.number,
    placeholderEn: 'Annual Income (e.g. 1,50,000)',
    placeholderMr: 'वार्षिक उत्पन्न (उदा. १,५०,०००)',
  ),
  'source_of_income': DynamicFieldMeta(
    key: 'source_of_income',
    enLabel: 'Source of Income',
    mrLabel: 'उत्पन्नाचा स्रोत',
    placeholderEn: 'Agriculture / Business / Employment',
    placeholderMr: 'शेती / व्यवसाय / नोकरी',
  ),
  'mseb_branch_name': DynamicFieldMeta(
    key: 'mseb_branch_name',
    enLabel: 'MSEB Branch Name',
    mrLabel: 'महावितरण शाखा',
    placeholderEn: 'e.g. MSEDCL Subdivision / Substation',
    placeholderMr: 'उदा. महावितरण उपविभाग शाखा',
  ),
};

const Map<String, List<String>> kDefaultLetterTypeFields = {
  'Residential Certificate': ['age', 'years_of_residency', 'ward_no'],
  'Character Certificate': ['years_known', 'reason_for_certificate'],
  'No Objection Certificate (NOC)': ['reason_for_certificate', 'municipality_name'],
  'Income Certificate': ['annual_income', 'source_of_income', 'tehsil_name'],
  'Recommendation Letter': ['company_name', 'company_address', 'education_degree'],
  'College / Admission Recommendation': [
    'school_name',
    'class_or_course_name',
    'school_city',
    'financial_condition'
  ],
  'Hospitalization / CM Relief Recommendation': [
    'hospital_name',
    'city_name',
    'financial_condition'
  ],
  'Commercial Electricity Meter NOC': ['mseb_branch_name', 'city_name'],
  'Other Official Request': ['ward_no', 'reason_for_certificate'],
};

