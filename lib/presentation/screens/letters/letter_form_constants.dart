// Form constants matching Nagarsevak-Managment LetterForm.tsx and translations.ts
import 'package:flutter/material.dart';

class LetterTypeOption {
  final String key;
  final String en;
  final String mr;
  final String hi;

  const LetterTypeOption({
    required this.key,
    required this.en,
    required this.mr,
    this.hi = '',
  });

  String getLabel(String lang) {
    if (lang == 'mr') return mr;
    if (lang == 'hi') return hi.isNotEmpty ? hi : mr;
    return en;
  }
}

const List<LetterTypeOption> kLetterTypeOptions = [
  LetterTypeOption(
    key: 'Residential Certificate',
    en: 'Residential Certificate',
    mr: 'रहिवासी दाखला',
    hi: 'निवास प्रमाणपत्र',
  ),
  LetterTypeOption(
    key: 'Character Certificate',
    en: 'Character Certificate',
    mr: 'चारित्र्याचा दाखला',
    hi: 'चरित्र प्रमाणपत्र',
  ),
  LetterTypeOption(
    key: 'No Objection Certificate (NOC)',
    en: 'No Objection Certificate (NOC)',
    mr: 'ना हरकत प्रमाणपत्र (NOC)',
    hi: 'अनापत्ति प्रमाणपत्र (NOC)',
  ),
  LetterTypeOption(
    key: 'Income Certificate',
    en: 'Income Certificate',
    mr: 'उत्पन्न प्रमाणपत्र',
    hi: 'आय प्रमाणपत्र',
  ),
  LetterTypeOption(
    key: 'Recommendation Letter',
    en: 'Recommendation Letter',
    mr: 'शिफारस पत्र',
    hi: 'सिफारिश पत्र',
  ),
  LetterTypeOption(
    key: 'College / Admission Recommendation',
    en: 'College / Admission Recommendation',
    mr: 'महाविद्यालयीन प्रवेश शिफारस',
    hi: 'कॉलेज / प्रवेश सिफारिश',
  ),
  LetterTypeOption(
    key: 'Hospitalization / CM Relief Recommendation',
    en: 'Hospitalization / CM Relief Recommendation',
    mr: 'वैद्यकीय मदत / सीएम सहायता निधी शिफारस',
    hi: 'अस्पताल में भर्ती / मुख्यमंत्री राहत सहायता सिफारिश',
  ),
  LetterTypeOption(
    key: 'Commercial Electricity Meter NOC',
    en: 'Commercial Electricity Meter NOC',
    mr: 'विद्युत मीटर ना हरकत प्रमाणपत्र',
    hi: 'व्यावसायिक बिजली मीटर अनापत्ति प्रमाणपत्र (NOC)',
  ),
  LetterTypeOption(
    key: 'Other Official Request',
    en: 'Other Official Request',
    mr: 'इतर अधिकृत पत्र',
    hi: 'अन्य आधिकारिक अनुरोध',
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
  final String hiLabel;
  final TextInputType keyboardType;
  final String placeholderEn;
  final String placeholderMr;
  final String placeholderHi;

  const DynamicFieldMeta({
    required this.key,
    required this.enLabel,
    required this.mrLabel,
    this.hiLabel = '',
    this.keyboardType = TextInputType.text,
    required this.placeholderEn,
    required this.placeholderMr,
    this.placeholderHi = '',
  });

  String getLabel(String lang) {
    if (lang == 'mr') return mrLabel;
    if (lang == 'hi') return hiLabel.isNotEmpty ? hiLabel : mrLabel;
    return enLabel;
  }

  String getPlaceholder(String lang) {
    if (lang == 'mr') return placeholderMr;
    if (lang == 'hi') return placeholderHi.isNotEmpty ? placeholderHi : placeholderMr;
    return placeholderEn;
  }
}

const Map<String, DynamicFieldMeta> kDynamicFieldDefinitions = {
  'age': DynamicFieldMeta(
    key: 'age',
    enLabel: 'Age',
    mrLabel: 'वय',
    hiLabel: 'आयु',
    keyboardType: TextInputType.number,
    placeholderEn: 'Enter Age (e.g. 28)',
    placeholderMr: 'वय प्रविष्ट करा (उदा. २८)',
    placeholderHi: 'आयु दर्ज करें (उदा. २८)',
  ),
  'years_of_residency': DynamicFieldMeta(
    key: 'years_of_residency',
    enLabel: 'Years of Residency',
    mrLabel: 'वास्तव्याची वर्षे',
    hiLabel: 'निवास के वर्ष',
    keyboardType: TextInputType.number,
    placeholderEn: 'Years living in ward (e.g. 15)',
    placeholderMr: 'वास्तव्याची वर्षे (उदा. १५)',
    placeholderHi: 'वार्ड में रहने के वर्ष (उदा. १५)',
  ),
  'ward_no': DynamicFieldMeta(
    key: 'ward_no',
    enLabel: 'Ward No.',
    mrLabel: 'प्रभाग क्रमांक',
    hiLabel: 'वार्ड क्रमांक',
    placeholderEn: 'Ward No. (e.g. 12)',
    placeholderMr: 'प्रभाग क्रमांक (उदा. १२)',
    placeholderHi: 'वार्ड क्रमांक (उदा. १२)',
  ),
  'school_name': DynamicFieldMeta(
    key: 'school_name',
    enLabel: 'School / College Name',
    mrLabel: 'शाळेचे / महाविद्यालयाचे नाव',
    hiLabel: 'स्कूल / कॉलेज का नाम',
    placeholderEn: 'Enter School or College Name',
    placeholderMr: 'शाळेचे / महाविद्यालयाचे नाव प्रविष्ट करा',
    placeholderHi: 'स्कूल या कॉलेज का नाम दर्ज करें',
  ),
  'school_city': DynamicFieldMeta(
    key: 'school_city',
    enLabel: 'School City',
    mrLabel: 'शाळेचे शहर',
    hiLabel: 'स्कूल का शहर',
    placeholderEn: 'Enter City',
    placeholderMr: 'शहर प्रविष्ट करा',
    placeholderHi: 'शहर दर्ज करें',
  ),
  'financial_condition': DynamicFieldMeta(
    key: 'financial_condition',
    enLabel: 'Financial Condition',
    mrLabel: 'आर्थिक स्थिती',
    hiLabel: 'आर्थिक स्थिति',
    placeholderEn: 'e.g. Needy / Middle / Poor',
    placeholderMr: 'उदा. गरजू / मध्यम / अल्पभूधारक',
    placeholderHi: 'उदा. जरूरतमंद / मध्यम / कमजोर वर्ग',
  ),
  'class_or_course_name': DynamicFieldMeta(
    key: 'class_or_course_name',
    enLabel: 'Class / Course Name',
    mrLabel: 'वर्ग / अभ्यासक्रमाचे नाव',
    hiLabel: 'कक्षा / पाठ्यक्रम का नाम',
    placeholderEn: 'e.g. 11th Science / B.Com / Diploma',
    placeholderMr: 'उदा. ११वी विज्ञान / बी.कॉम / डिप्लोमा',
    placeholderHi: 'उदा. ११वीं विज्ञान / बी.कॉम / डिप्लोमा',
  ),
  'company_name': DynamicFieldMeta(
    key: 'company_name',
    enLabel: 'Company Name',
    mrLabel: 'कंपनीचे नाव',
    hiLabel: 'कंपनी का नाम',
    placeholderEn: 'Enter Company or Organization Name',
    placeholderMr: 'कंपनीचे किंवा संस्थेचे नाव',
    placeholderHi: 'कंपनी या संगठन का नाम दर्ज करें',
  ),
  'company_address': DynamicFieldMeta(
    key: 'company_address',
    enLabel: 'Company Address',
    mrLabel: 'कंपनीचा पत्ता',
    hiLabel: 'कंपनी का पता',
    placeholderEn: 'Enter Office / Company Address',
    placeholderMr: 'कार्यालय / कंपनीचा पत्ता',
    placeholderHi: 'कार्यालय / कंपनी का पता दर्ज करें',
  ),
  'education_degree': DynamicFieldMeta(
    key: 'education_degree',
    enLabel: 'Education / Degree',
    mrLabel: 'शिक्षण (पदवी)',
    hiLabel: 'शिक्षा / डिग्री',
    placeholderEn: 'e.g. B.Tech / MBA / Graduate',
    placeholderMr: 'उदा. बी.टेक / पदवीधर / १२वी',
    placeholderHi: 'उदा. बी.टेक / स्नातक / १२वीं',
  ),
  'years_known': DynamicFieldMeta(
    key: 'years_known',
    enLabel: 'Years Known',
    mrLabel: 'ओळखीची वर्षे',
    hiLabel: 'परिचय के वर्ष',
    keyboardType: TextInputType.number,
    placeholderEn: 'Years known personally (e.g. 10)',
    placeholderMr: 'वैयक्तिक ओळखीची वर्षे (उदा. १०)',
    placeholderHi: 'व्यक्तिगत परिचय के वर्ष (उदा. १०)',
  ),
  'reason_for_certificate': DynamicFieldMeta(
    key: 'reason_for_certificate',
    enLabel: 'Reason for Certificate',
    mrLabel: 'प्रमाणपत्राचे कारण',
    hiLabel: 'प्रमाणपत्र का कारण',
    placeholderEn: 'e.g. Bank Account / Passport / Verification',
    placeholderMr: 'उदा. बँक खाते / पासपोर्ट / पडताळणी',
    placeholderHi: 'उदा. बैंक खाता / पासपोर्ट / सत्यापन',
  ),
  'municipality_name': DynamicFieldMeta(
    key: 'municipality_name',
    enLabel: 'Municipality Name',
    mrLabel: 'नगरपालिकेचे / मनपा नाव',
    hiLabel: 'नगरपालिका / महानगरपालिका का नाम',
    placeholderEn: 'e.g. PMC / PCMC / Municipal Council',
    placeholderMr: 'उदा. पुणे मनपा / नगरपालिका',
    placeholderHi: 'उदा. पुणे मनपा / नगर परिषद',
  ),
  'date_of_death': DynamicFieldMeta(
    key: 'date_of_death',
    enLabel: 'Date of Death',
    mrLabel: 'मृत्यूची तारीख',
    hiLabel: 'मृत्यु की तिथि',
    placeholderEn: 'DD/MM/YYYY',
    placeholderMr: 'दिनांक (उदा. १५/०१/२०२६)',
    placeholderHi: 'तिथि (उदा. १५/०१/२०२६)',
  ),
  'cause_of_death': DynamicFieldMeta(
    key: 'cause_of_death',
    enLabel: 'Cause of Death',
    mrLabel: 'मृत्यूचे कारण',
    hiLabel: 'मृत्यु का कारण',
    placeholderEn: 'Natural / Illness / Accident',
    placeholderMr: 'नैसर्गिक / आजारपण / अपघात',
    placeholderHi: 'प्राकृतिक / बीमारी / दुर्घटना',
  ),
  'hospital_name': DynamicFieldMeta(
    key: 'hospital_name',
    enLabel: 'Hospital Name',
    mrLabel: 'रुग्णालयाचे नाव',
    hiLabel: 'अस्पताल का नाम',
    placeholderEn: 'Enter Hospital Name',
    placeholderMr: 'रुग्णालयाचे नाव प्रविष्ट करा',
    placeholderHi: 'अस्पताल का नाम दर्ज करें',
  ),
  'gas_agency_name': DynamicFieldMeta(
    key: 'gas_agency_name',
    enLabel: 'Gas Agency Name',
    mrLabel: 'गॅस एजन्सीचे नाव',
    hiLabel: 'गैस एजेंसी का नाम',
    placeholderEn: 'Enter Gas Agency Name',
    placeholderMr: 'गॅस वितरकाचे नाव',
    placeholderHi: 'गैस एजेंसी का नाम दर्ज करें',
  ),
  'city_name': DynamicFieldMeta(
    key: 'city_name',
    enLabel: 'City Name',
    mrLabel: 'शहराचे नाव',
    hiLabel: 'शहर का नाम',
    placeholderEn: 'Enter City',
    placeholderMr: 'शहर प्रविष्ट करा',
    placeholderHi: 'शहर दर्ज करें',
  ),
  'tehsil_name': DynamicFieldMeta(
    key: 'tehsil_name',
    enLabel: 'Tehsil Name',
    mrLabel: 'तहसीलचे नाव',
    hiLabel: 'तहसील का नाम',
    placeholderEn: 'Enter Tehsil Name',
    placeholderMr: 'तहसीलचे नाव प्रविष्ट करा',
    placeholderHi: 'तहसील का नाम दर्ज करें',
  ),
  'annual_income': DynamicFieldMeta(
    key: 'annual_income',
    enLabel: 'Annual Income',
    mrLabel: 'वार्षिक उत्पन्न (₹)',
    hiLabel: 'वार्षिक आय (₹)',
    keyboardType: TextInputType.number,
    placeholderEn: 'Annual Income (e.g. 1,50,000)',
    placeholderMr: 'वार्षिक उत्पन्न (उदा. १,५०,०००)',
    placeholderHi: 'वार्षिक आय (उदा. १,५०,०००)',
  ),
  'source_of_income': DynamicFieldMeta(
    key: 'source_of_income',
    enLabel: 'Source of Income',
    mrLabel: 'उत्पन्नाचा स्रोत',
    hiLabel: 'आय का स्रोत',
    placeholderEn: 'Agriculture / Business / Employment',
    placeholderMr: 'शेती / व्यवसाय / नोकरी',
    placeholderHi: 'कृषि / व्यवसाय / रोजगार',
  ),
  'mseb_branch_name': DynamicFieldMeta(
    key: 'mseb_branch_name',
    enLabel: 'MSEB Branch Name',
    mrLabel: 'महावितरण शाखा',
    hiLabel: 'महावितरण / बिजली विभाग शाखा',
    placeholderEn: 'e.g. MSEDCL Subdivision / Substation',
    placeholderMr: 'उदा. महावितरण उपविभाग शाखा',
    placeholderHi: 'उदा. बिजली विभाग उपखंड शाखा',
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

