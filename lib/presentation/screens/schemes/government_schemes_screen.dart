import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../../data/models/scheme_model.dart';
import '../../../data/repositories/schemes_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'scheme_detail_screen.dart';
import 'scheme_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class GovernmentSchemesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  final ValueChanged<int>? onTabChange;

  const GovernmentSchemesScreen({
    super.key,
    this.onBackToHome,
    this.onTabChange,
  });

  @override
  ConsumerState<GovernmentSchemesScreen> createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends ConsumerState<GovernmentSchemesScreen> {
  // Primary Tabs: 'schemes' (default) or 'applications'
  String _activeTab = 'schemes';

  // Filters for Schemes
  String _selectedCategory = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  // Filters for Applications
  String _applicationStatusFilter = 'All'; // 'All', 'Pending', 'Approved', 'Rejected'
  final TextEditingController _appSearchCtrl = TextEditingController();

  // Smart Matcher Filter list of IDs (null if not filtering)
  List<int>? _matchedSchemeIds;

  bool _isLoading = true;
  List<SchemeModel> _schemes = [];
  List<SchemeApplicationModel> _applications = [];

  int _schemesLimit = 20;
  int _appsLimit = 20;

  List<SchemeModel> get _visibleSchemes =>
      _filteredSchemes.take(_schemesLimit).toList();

  List<SchemeApplicationModel> get _visibleApplications =>
      _filteredApplications.take(_appsLimit).toList();

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'All',
      'labelEn': 'All',
      'labelMr': 'सर्व',
      'labelHi': 'सभी',
      'keywords': <String>[],
    },
    {
      'id': 'Women',
      'labelEn': 'Women',
      'labelMr': 'महिला',
      'labelHi': 'महिला',
      'keywords': ['women', 'mahila', 'girl', 'lady', 'widow', 'wife', 'female', 'महिला', 'विधवा', 'पत्नी', 'मुली'],
    },
    {
      'id': 'Student',
      'labelEn': 'Student',
      'labelMr': 'विद्यार्थी',
      'labelHi': 'विद्यार्थी',
      'keywords': ['student', 'education', 'scholarship', 'school', 'college', 'vidyarthi', 'विद्यार्थी', 'शिक्षण', 'शिष्यवृत्ती', 'शाळा', 'महाविद्यालय'],
    },
    {
      'id': 'Senior Citizen',
      'labelEn': 'Senior Citizen',
      'labelMr': 'ज्येष्ठ नागरिक',
      'labelHi': 'वरिष्ठ नागरिक',
      'keywords': ['senior', 'pension', 'old', 'age', 'vrrudh', 'jeyshtha', 'ज्येष्ठ', 'नागरिक', 'पेन्शन', 'वृद्ध', 'वरिष्ठ'],
    },
    {
      'id': 'Farmer',
      'labelEn': 'Farmer',
      'labelMr': 'शेतकरी',
      'labelHi': 'किसान',
      'keywords': ['farmer', 'agriculture', 'kisan', 'crop', 'shetkari', 'शेतकरी', 'कृषी', 'पीक', 'किसान'],
    },
    {
      'id': 'Health',
      'labelEn': 'Health',
      'labelMr': 'आरोग्य',
      'labelHi': 'स्वास्थ्य',
      'keywords': ['health', 'medical', 'treatment', 'hospital', 'insurance', 'aarogya', 'आरोग्य', 'वैद्यकीय', 'उपचार', 'रुग्णालय', 'विमा', 'स्वास्थ्य'],
    },
    {
      'id': 'Youth',
      'labelEn': 'Youth',
      'labelMr': 'तरुण / युवक',
      'labelHi': 'युवा',
      'keywords': ['youth', 'employment', 'job', 'skill', 'training', 'tarun', 'युवक', 'रोजगार', 'नोकरी', 'कौशल्य', 'प्रशिक्षण', 'तरुण', 'फेरीवाले', 'युवा'],
    },
    {
      'id': 'Housing',
      'labelEn': 'Housing',
      'labelMr': 'घरकुल / आवास',
      'labelHi': 'आवास',
      'keywords': ['housing', 'home', 'house', 'awas', 'gharkul', 'घरकुल', 'आवास', 'घर', 'शौचालय'],
    },
  ];

  String _categoryLabel(String categoryId, String lang) {
    final hit = _categories.cast<Map<String, dynamic>?>().firstWhere(
          (c) => (c!['id'] as String).toLowerCase() == categoryId.trim().toLowerCase(),
          orElse: () => null,
        );
    if (hit == null) return categoryId;
    return lang == 'mr'
        ? hit['labelMr'] as String
        : (lang == 'hi' ? hit['labelHi'] as String : hit['labelEn'] as String);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _appSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(schemesRepoProvider);
      final schemesFuture = repo.getSchemes();
      final appsFuture = repo.getApplications();

      final res = await Future.wait([schemesFuture, appsFuture]);
      if (mounted) {
        setState(() {
          _schemes = res[0] as List<SchemeModel>;
          _applications = res[1] as List<SchemeApplicationModel>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filtered Schemes Logic matching Nagarsevak-Managment SchemeList.tsx
  List<SchemeModel> get _filteredSchemes {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _schemes.where((s) {
      // 1. Smart Matcher filter
      if (_matchedSchemeIds != null && !_matchedSchemeIds!.contains(s.id)) {
        return false;
      }

      // 2. Search query
      if (query.isNotEmpty) {
        final nameMatch = s.name.toLowerCase().contains(query);
        final descMatch = s.description.toLowerCase().contains(query);
        final benMatch = s.benefits.toLowerCase().contains(query);
        final eligMatch = s.eligibility.toLowerCase().contains(query);
        final catMatch = s.category.toLowerCase().contains(query);
        if (!nameMatch && !descMatch && !benMatch && !eligMatch && !catMatch) {
          return false;
        }
      }

      // 3. Category matching
      if (_selectedCategory != 'All') {
        if (s.category.toLowerCase() == _selectedCategory.toLowerCase()) {
          return true;
        }
        // Fallback to keyword matching
        final catItem = _categories.firstWhere(
          (c) => (c['id'] as String).toLowerCase() == _selectedCategory.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        final keywords = (catItem['keywords'] as List<String>?) ?? [];
        if (keywords.isNotEmpty) {
          final combined = '${s.name} ${s.description} ${s.eligibility} ${s.benefits}'.toLowerCase();
          final matches = keywords.any((k) => combined.contains(k.toLowerCase()));
          if (!matches) return false;
        } else {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Filtered Applications Logic
  List<SchemeApplicationModel> get _filteredApplications {
    final query = _appSearchCtrl.text.trim().toLowerCase();

    return _applications.where((app) {
      if (_applicationStatusFilter != 'All') {
        if (app.status.toLowerCase() != _applicationStatusFilter.toLowerCase()) {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final nameMatch = app.applicantName.toLowerCase().contains(query);
        final mobileMatch = app.mobile.contains(query);
        final addressMatch = app.address.toLowerCase().contains(query);
        final schemeMatch = app.schemeName?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !mobileMatch && !addressMatch && !schemeMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Communication Launchers
  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String applicantName, String? schemeName) async {
    final clean = AppTranslations.normalizeAsciiDigits(phone).replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    final lang = ref.read(appLanguageProvider);
    final schemeLabel = schemeName ?? AppTranslations.pick(lang, en: 'Government Scheme', mr: 'शासकीय योजना', hi: 'सरकारी योजना');
    final text = AppTranslations.pick(
      lang,
      en: 'Namaskar $applicantName ji, regarding your application for $schemeLabel at Nagarsevak Office.',
      mr: 'नमस्कार $applicantName जी, नगरसेवक कार्यालयातील आपल्या "$schemeLabel" अर्जाबाबत.',
      hi: 'नमस्कार $applicantName जी, नगरसेवक कार्यालय में आपके "$schemeLabel" आवेदन के संबंध में।',
    );
    final uri = Uri.parse('https://wa.me/91$clean?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // -------------------------------------------------------------
  // SMART SCHEME MATCHER MODAL
  // -------------------------------------------------------------
  void _showSmartMatcherModal() {
    final lang = ref.read(appLanguageProvider);
    final ageCtrl = TextEditingController();
    final incomeCtrl = TextEditingController();
    final occCtrl = TextEditingController();
    String gender = 'Male';

    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return AppFieldLabel(label: text, isRequired: isRequired);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. FIXED HEADER
                  AppModalHeader(
                    icon: Icons.auto_awesome_rounded,
                    title: AppTranslations.pick(lang, en: 'Smart Scheme Matcher', mr: 'स्मार्ट योजना शोधक', hi: 'स्मार्ट योजना मैचिंग'),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Find exact matching welfare schemes',
                      mr: 'नागरिकांच्या पात्रतेनुसार अचूक योजना शोधा',
                      hi: 'नागरिकों की पात्रता के अनुसार सटीक योजनाएं खोजें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),

                  // 2. SCROLLABLE FORM BODY & BUTTONS
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(
                        18,
                        14,
                        18,
                        MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      children: [
                        // Age & Gender side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel(
                                    AppTranslations.pick(lang, en: 'Citizen Age (Years)', mr: 'वय (वर्षे)', hi: 'नागरिक की आयु (वर्ष)'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: ageCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: inputDec(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. 24, 65...', mr: 'उदा. 24, 65...', hi: 'उदा. 24, 65...'),
                                        lang,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppDropdownFormField<String>(
                                    label: AppTranslations.pick(lang, en: 'Gender', mr: 'लिंग', hi: 'लिंग'),
                                    isRequired: true,
                                    value: gender,
                                    items: [
                                      DropdownMenuItem(value: 'Male', child: Text(AppTranslations.pick(lang, en: 'Male', mr: 'पुरुष', hi: 'पुरुष'))),
                                      DropdownMenuItem(value: 'Female', child: Text(AppTranslations.pick(lang, en: 'Female', mr: 'महिला', hi: 'महिला'))),
                                      DropdownMenuItem(value: 'Other', child: Text(AppTranslations.pick(lang, en: 'Other', mr: 'इतर', hi: 'अन्य'))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => gender = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Income & Occupation side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel(AppTranslations.pick(lang, en: 'Annual Income (₹)', mr: 'वार्षिक उत्पन्न (₹)', hi: 'वार्षिक आय (₹)')),
                                  TextField(
                                    controller: incomeCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: inputDec(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. 150000', mr: 'उदा. 150000', hi: 'उदा. 150000'),
                                        lang,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel(AppTranslations.pick(lang, en: 'Occupation', mr: 'व्यवसाय / शिक्षण', hi: 'व्यवसाय / शिक्षा')),
                                  TextField(
                                    controller: occCtrl,
                                    decoration: inputDec(
                                      hint: AppTranslations.pick(lang, en: 'Student, Farmer...', mr: 'विद्यार्थी, शेतकरी...', hi: 'विद्यार्थी, किसान...'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final age = int.tryParse(AppTranslations.normalizeAsciiDigits(ageCtrl.text.trim())) ?? 30;
                              final occ = occCtrl.text.trim().toLowerCase();

                              // Matching algorithm matching Nagarsevak-Managment AI Matcher
                              final matched = <int>[];
                              for (final s in _schemes) {
                                final cat = s.category.toLowerCase();
                                final text = '${s.name} ${s.description} ${s.eligibility} ${s.benefits}'.toLowerCase();

                                if (gender == 'Female' && (cat == 'women' || text.contains('महिला') || text.contains('ladki'))) {
                                  matched.add(s.id);
                                }
                                if (age >= 60 && (cat == 'senior citizen' || text.contains('senior') || text.contains('ज्येष्ठ') || text.contains('वृद्ध') || text.contains('वरिष्ठ'))) {
                                  matched.add(s.id);
                                }
                                if ((occ.contains('student') || occ.contains('विद्यार्थी') || age <= 25) && (cat == 'student' || text.contains('scholarship') || text.contains('शिष्यवृत्ती') || text.contains('छात्रवृत्ति'))) {
                                  matched.add(s.id);
                                }
                                if ((occ.contains('farmer') || occ.contains('शेतकरी') || occ.contains('किसान')) && (cat == 'farmer' || text.contains('kisan') || text.contains('कृषी') || text.contains('किसान'))) {
                                  matched.add(s.id);
                                }
                                if ((occ.contains('vendor') || occ.contains('फेरीवाला') || occ.contains('business') || occ.contains('youth')) && (cat == 'youth' || text.contains('svanidhi') || text.contains('loan'))) {
                                  matched.add(s.id);
                                }
                                // Universal health & housing schemes
                                if (cat == 'health' || cat == 'housing') {
                                  matched.add(s.id);
                                }
                              }

                              Navigator.pop(sheetCtx);
                              setState(() {
                                _matchedSchemeIds = matched.isNotEmpty ? matched : _schemes.map((s) => s.id).toList();
                              });
                            },
                            icon: const Icon(Icons.search, size: 20),
                            label: Text(
                              AppTranslations.pick(lang, en: 'Find Matching Schemes', mr: 'पात्र योजना शोधा', hi: 'पात्र योजनाएं खोजें'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // ADD NEW SCHEME MODAL
  // -------------------------------------------------------------
  void _showAddSchemeSheet() {
    final lang = ref.read(appLanguageProvider);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final eligCtrl = TextEditingController();
    final benCtrl = TextEditingController();
    final docCtrl = TextEditingController();
    String selectedCat = 'Housing';

    final categories = ['All', 'Women', 'Student', 'Senior Citizen', 'Farmer', 'Health', 'Youth', 'Housing'];

    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return AppFieldLabel(label: text, isRequired: isRequired);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. FIXED HEADER
                  AppModalHeader(
                    icon: Icons.account_balance_rounded,
                    title: AppTranslations.pick(lang, en: 'Add New Government Scheme', mr: 'नवीन शासकीय योजना जोडा', hi: 'नई सरकारी योजना जोड़ें'),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Record government welfare schemes, criteria and benefits',
                      mr: 'कल्याणकारी योजनांची पात्रता, कागदपत्रे व लाभ नोंदवा',
                      hi: 'कल्याणकारी योजनाओं की पात्रता, दस्तावेज़ और लाभ दर्ज करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),

                  // 2. SCROLLABLE FORM BODY & BUTTONS
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(
                        18,
                        14,
                        18,
                        MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      children: [
                        // Scheme Name & Category side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel(AppTranslations.pick(lang, en: 'Scheme Name', mr: 'योजनेचे नाव', hi: 'योजना का नाम'), isRequired: true),
                                  TextField(
                                    controller: nameCtrl,
                                    decoration: inputDec(hint: AppTranslations.pick(lang, en: 'e.g. PM Awas Yojana', mr: 'उदा. प्रधानमंत्री आवास योजना', hi: 'उदा. प्रधानमंत्री आवास योजना')),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppDropdownFormField<String>(
                                    label: AppTranslations.pick(lang, en: 'Category', mr: 'वर्ग / विभाग', hi: 'श्रेणी / विभाग'),
                                    isRequired: true,
                                    value: selectedCat,
                                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c, lang)))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedCat = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Benefits & Eligibility side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel(AppTranslations.pick(lang, en: 'Financial Benefits & Grants', mr: 'आर्थिक लाभ व अनुदान', hi: 'वित्तीय लाभ और अनुदान'), isRequired: true),
                                  TextField(
                                    controller: benCtrl,
                                    maxLines: 2,
                                    decoration: inputDec(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. ₹2.5 Lakhs grant...', mr: 'उदा. ₹2.5 लाख अनुदान...', hi: 'उदा. ₹2.5 लाख अनुदान...'),
                                        lang,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel(AppTranslations.pick(lang, en: 'Eligibility Criteria', mr: 'पात्रता अटी', hi: 'पात्रता शर्तें'), isRequired: true),
                                  TextField(
                                    controller: eligCtrl,
                                    maxLines: 2,
                                    decoration: inputDec(hint: AppTranslations.pick(lang, en: 'Income limit, age...', mr: 'उत्पन्न मर्यादा, वय...', hi: 'आय सीमा, आयु...')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Documents
                        fieldLabel(AppTranslations.pick(lang, en: 'Documents Required Checklist', mr: 'आवश्यक कागदपत्रे', hi: 'आवश्यक दस्तावेज़ सूची'), isRequired: true),
                        TextField(
                          controller: docCtrl,
                          maxLines: 2,
                          decoration: inputDec(hint: AppTranslations.pick(lang, en: 'Aadhaar, Ration card, Income proof...', mr: 'आधार कार्ड, रेशन कार्ड, उत्पन्न दाखला...', hi: 'आधार कार्ड, राशन कार्ड, आय प्रमाणपत्र...')),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        fieldLabel(AppTranslations.pick(lang, en: 'Description & Objectives', mr: 'योजनेचा तपशील व उद्दिष्ट', hi: 'विवरण और उद्देश्य'), isRequired: true),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: inputDec(hint: AppTranslations.pick(lang, en: 'Brief objective and overview...', mr: 'योजनेची संक्षिप्त उद्दिष्टे...', hi: 'योजना का संक्षिप्त विवरण...')),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppTranslations.pick(lang, en: 'Please enter scheme name', mr: 'कृपया योजनेचे नाव प्रविष्ट करा', hi: 'कृपया योजना का नाम दर्ज करें'))),
                                );
                                return;
                              }
                              final newScheme = SchemeModel(
                                id: 0,
                                name: nameCtrl.text.trim(),
                                category: selectedCat,
                                description: descCtrl.text.trim(),
                                benefits: benCtrl.text.trim(),
                                eligibility: eligCtrl.text.trim(),
                                documents: docCtrl.text.trim(),
                                createdAt: DateTime.now(),
                              );
                              Navigator.pop(sheetCtx);
                              final created = await ref.read(schemesRepoProvider).createScheme(newScheme);
                              setState(() {
                                _schemes.insert(0, created);
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppTranslations.pick(lang, en: 'Scheme added successfully!', mr: 'योजना यशस्वीरित्या जोडली!', hi: 'योजना सफलतापूर्वक जोड़ी गई!')),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              AppTranslations.pick(lang, en: 'Save Scheme', mr: 'योजना जतन करा', hi: 'योजना सहेजें'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // APPLICATION STATUS UPDATE SHEET
  // -------------------------------------------------------------
  void _showApplicationStatusSheet(SchemeApplicationModel app) {
    final lang = ref.read(appLanguageProvider);
    String currentStatus = app.status;
    final benefitCtrl = TextEditingController(text: app.benefit ?? '');
    final notesCtrl = TextEditingController(text: app.notes ?? '');
    final reasonCtrl = TextEditingController(text: app.rejectionReason ?? '');

    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return AppFieldLabel(label: text, isRequired: isRequired);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            final subtitleName = DynamicTranslationService.getCachedTranslation(
                  app.applicantName,
                  lang,
                  isName: true,
                ) ??
                AppTranslations.formatDigits(app.applicantName, lang);
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. FIXED HEADER
                  AppModalHeader(
                    icon: Icons.edit_note_rounded,
                    title: AppTranslations.pick(lang, en: 'Update Application Status', mr: 'अर्जाची स्थिती अद्यतनित करा', hi: 'आवेदन की स्थिति अपडेट करें'),
                    subtitle: subtitleName,
                    onClose: () => Navigator.pop(sheetCtx),
                  ),

                  // 2. SCROLLABLE FORM BODY & BUTTONS
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(
                        18,
                        14,
                        18,
                        MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      children: [
                        fieldLabel(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'), isRequired: true),
                        Row(
                          children: ['Pending', 'Approved', 'Rejected'].map((st) {
                            final isSel = currentStatus.toLowerCase() == st.toLowerCase();
                            Color bg = isSel
                                ? (st == 'Approved'
                                    ? const Color(0xFF16A34A)
                                    : st == 'Rejected'
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFD97706))
                                : const Color(0xFFF1F5F9);
                            Color text = isSel ? Colors.white : const Color(0xFF475569);
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => currentStatus = st),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppTranslations.getStatus(st, lang),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: text, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        if (currentStatus.toLowerCase() == 'approved') ...[
                          fieldLabel(AppTranslations.pick(lang, en: 'Sanctioned Benefit / Grant Details', mr: 'मंजूर लाभ / अनुदान तपशील', hi: 'स्वीकृत लाभ / अनुदान विवरण')),
                          TextField(
                            controller: benefitCtrl,
                            decoration: inputDec(
                              hint: AppTranslations.formatDigits(
                                AppTranslations.pick(lang, en: 'e.g. ₹1,500/month DBT approved...', mr: 'उदा. ₹1,500/महिना डीबीटी मंजूर...', hi: 'उदा. ₹1,500/माह डीबीटी स्वीकृत...'),
                                lang,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (currentStatus.toLowerCase() == 'rejected') ...[
                          fieldLabel(AppTranslations.pick(lang, en: 'Reason for Rejection', mr: 'नाकारण्याचे कारण', hi: 'अस्वीकृति का कारण')),
                          TextField(
                            controller: reasonCtrl,
                            decoration: inputDec(
                              hint: AppTranslations.formatDigits(
                                AppTranslations.pick(lang, en: 'e.g. Income exceeds ₹2.5 Lakhs limit...', mr: 'उदा. उत्पन्न मर्यादा ओलांडली...', hi: 'उदा. आय ₹2.5 लाख सीमा से अधिक...'),
                                lang,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        fieldLabel(AppTranslations.pick(lang, en: 'Officer / Office Notes', mr: 'अधिकारी / कार्यालयीन टीप', hi: 'अधिकारी / कार्यालय नोट')),
                        TextField(
                          controller: notesCtrl,
                          maxLines: 2,
                          decoration: inputDec(hint: AppTranslations.pick(lang, en: 'Follow-up remarks...', mr: 'पुढील कार्यवाहीच्या नोंदी...', hi: 'अनुवर्ती टिप्पणी...')),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              Navigator.pop(sheetCtx);
                              await ref.read(schemesRepoProvider).updateApplicationStatus(
                                    app.id,
                                    currentStatus,
                                    benefit: benefitCtrl.text.trim().isNotEmpty ? benefitCtrl.text.trim() : null,
                                    rejectionReason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                                    notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                                  );
                              _loadData();
                              if (mounted) {
                                final localizedSt = AppTranslations.getStatus(currentStatus, lang);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Application updated to $localizedSt',
                                        mr: 'अर्जाची स्थिती अद्यतनित केली: $localizedSt',
                                        hi: 'आवेदन की स्थिति अपडेट की गई: $localizedSt',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              AppTranslations.pick(lang, en: 'Update Status', mr: 'स्थिती अद्यतनित करा', hi: 'स्थिति अपडेट करें'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteApplication(int id) {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(AppTranslations.pick(lang, en: 'Delete Application?', mr: 'अर्ज हटवायचा का?', hi: 'आवेदन हटाएँ?')),
        content: Text(AppTranslations.pick(
          lang,
          en: 'Are you sure you want to remove this citizen application?',
          mr: 'तुम्हाला हा नागरिक अर्ज कायमचा हटवायचा आहे का?',
          hi: 'क्या आप वाकई इस नागरिक आवेदन को हटाना चाहते हैं?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await ref.read(schemesRepoProvider).deleteApplication(id);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppTranslations.pick(lang, en: 'Application removed.', mr: 'अर्ज हटवला.', hi: 'आवेदन हटाया गया।'))),
                );
              }
            },
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final displayedSchemes = _filteredSchemes;
    final displayedApps = _filteredApplications;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const NagarsevakAppDrawer(currentTabIndex: 0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: lang == 'mr' ? 'मेनू उघडा' : (lang == 'hi' ? 'मेनू खोलें' : 'Open Menu Drawer'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.t('schemes.title', lang: lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                AppTranslations.t('schemes.subtitle', lang: lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: const [],
        ),
        body: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: AppShimmerList(count: 6),
              )
            : Column(
                children: [
                  // 1) PRIMARY TABS: Schemes vs Applications
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildPrimaryTab(
                              id: 'schemes',
                              label: AppTranslations.pick(lang, en: 'Schemes', mr: 'शासकीय योजना', hi: 'सरकारी योजनाएं'),
                              count: _schemes.length,
                              lang: lang,
                              isActive: _activeTab == 'schemes',
                            ),
                            _buildPrimaryTab(
                              id: 'applications',
                              label: AppTranslations.pick(lang, en: 'Applications', mr: 'लाभार्थी व अर्ज', hi: 'लाभार्थी व आवेदन'),
                              count: _applications.length,
                              lang: lang,
                              isActive: _activeTab == 'applications',
                            ),
                          ],
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                      ],
                    ),
                  ),

                  // 2) TAB CONTENT
                  Expanded(
                    child: _activeTab == 'schemes'
                        ? _buildSchemesView(lang, displayedSchemes)
                        : _buildApplicationsView(lang, displayedApps),
                  ),
                ],
              ),
        floatingActionButton: _activeTab == 'schemes'
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 3,
                onPressed: _showAddSchemeSheet,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(
                  AppTranslations.pick(lang, en: 'Add Scheme', mr: 'नवीन योजना', hi: 'नई योजना'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    );
  }

  // Primary Tab Bar item
  Widget _buildPrimaryTab({
    required String id,
    required String label,
    required int count,
    required String lang,
    required bool isActive,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _activeTab = id;
          _schemesLimit = 20; _appsLimit = 20;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF0284C7) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppTranslations.formatDigits('$count', lang),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SCHEMES TAB VIEW
  // -------------------------------------------------------------
  Widget _buildSchemesView(String lang, List<SchemeModel> displayedSchemes) {
    return Column(
      children: [
        // Search & Smart Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: [
              // Search field + Actions
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() => _schemesLimit = 20),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'Search schemes, benefits, eligibility...',
                                  mr: 'योजना, लाभ किंवा पात्रता शोधा...',
                                  hi: 'योजना, लाभ या पात्रता खोजें...',
                                ),
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _schemesLimit = 20);
                              },
                              child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: AppTranslations.pick(lang, en: 'Smart Scheme Matcher', mr: 'स्मार्ट योजना शोधक', hi: 'स्मार्ट योजना मैचिंग'),
                    child: InkWell(
                      onTap: _showSmartMatcherModal,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, size: 20, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppPdfButton.icon(
                    tooltip: AppTranslations.pick(lang, en: 'Download Report', mr: 'अहवाल डाउनलोड करा', hi: 'रिपोर्ट डाउनलोड करें'),
                    onPressed: () {
                      SchemeReportGenerator.generateAndPrintListReport(
                        schemes: displayedSchemes,
                        isMarathi: lang == 'mr',
                        lang: lang,
                        categoryFilter: _selectedCategory,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Categories Horizontal Scroll
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final cat = _categories[idx];
                    final catId = cat['id'] as String;
                    final isSel = _selectedCategory == catId;
                    final label = lang == 'mr'
                        ? cat['labelMr'] as String
                        : (lang == 'hi' ? cat['labelHi'] as String : cat['labelEn'] as String);

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory = catId;
                        _schemesLimit = 20; _appsLimit = 20;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF0284C7) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Matched filter reset banner (if Smart Matcher is active)
              if (_matchedSchemeIds != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF16A34A), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            AppTranslations.formatDigits(
                              AppTranslations.pick(
                                lang,
                                en: 'Smart Filter Active (${displayedSchemes.length} schemes)',
                                mr: 'मॅचर फिल्टर सक्रिय (${displayedSchemes.length} योजना)',
                                hi: 'स्मार्ट फ़िल्टर सक्रिय (${displayedSchemes.length} योजनाएं)',
                              ),
                              lang,
                            ),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _matchedSchemeIds = null;
                          _schemesLimit = 20; _appsLimit = 20;
                        }),
                        child: Text(
                          AppTranslations.pick(lang, en: 'Reset', mr: 'रीसेट', hi: 'रीसेट'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

        // Schemes List
        Expanded(
          child: displayedSchemes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 54, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No schemes match your filter',
                          mr: 'कोणतीही योजना आढळली नाही',
                          hi: 'फ़िल्टर से मेल खाती कोई योजना नहीं मिली',
                        ),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _selectedCategory = 'All';
                            _matchedSchemeIds = null;
                            _schemesLimit = 20; _appsLimit = 20;
                          });
                        },
                        child: Text(
                          AppTranslations.pick(lang, en: 'Reset All Filters', mr: 'सर्व फिल्टर्स रीसेट करा', hi: 'सभी फ़िल्टर रीसेट करें'),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visibleSchemes.length + (displayedSchemes.isNotEmpty ? 1 : 0),
                  itemBuilder: (ctx, idx) {
                    if (idx == _visibleSchemes.length) {
                      return AppLoadMoreFooter(
                        currentCount: _visibleSchemes.length,
                        totalCount: displayedSchemes.length,
                        pageSize: 20,
                        onLoadMore: () {
                          setState(() => _schemesLimit += 20);
                        },
                        label: AppTranslations.pick(lang, en: 'schemes', mr: 'योजना', hi: 'योजनाएं'),
                        isMarathi: lang == 'mr',
                      );
                    }
                    final scheme = _visibleSchemes[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSchemeCard(lang, scheme),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSchemeCard(String lang, SchemeModel scheme) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchemeDetailScreen(
              scheme: scheme,
              onSchemeUpdated: _loadData,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon + Category Badge + Action Arrow
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(scheme.icon, color: scheme.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AppTranslatedText(
                          _categoryLabel(scheme.category, lang).toUpperCase(),
                          targetLanguage: lang,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: scheme.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppTranslatedText(
                        scheme.localizedNameFor(lang),
                        targetLanguage: lang,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),

            const SizedBox(height: 10),

            // Description
            AppTranslatedText(
              scheme.localizedDescriptionFor(lang),
              targetLanguage: lang,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Benefits highlight pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFF16A34A), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AppTranslatedText(
                      scheme.localizedBenefitsFor(lang),
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Card Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    SchemeReportGenerator.generateAndPrintSingleSchemeFlyer(
                      scheme: scheme,
                      isMarathi: lang == 'mr',
                      lang: lang,
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: Text(AppTranslations.pick(lang, en: 'Flyer', mr: 'पत्रक', hi: 'विवरणिका'), style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SchemeDetailScreen(
                          scheme: scheme,
                          onSchemeUpdated: _loadData,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_ind_rounded, size: 15),
                  label: Text(AppTranslations.pick(lang, en: 'Apply', mr: 'अर्ज करा', hi: 'आवेदन करें'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // APPLICATIONS / BENEFICIARIES TAB VIEW
  // -------------------------------------------------------------
  Widget _buildApplicationsView(String lang, List<SchemeApplicationModel> displayedApps) {
    return Column(
      children: [
        // Applications Search & Status Filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: [
              // Search + Actions
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _appSearchCtrl,
                              onChanged: (_) => setState(() => _appsLimit = 20),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(lang, en: 'Search applicant name, mobile, address...', mr: 'नागरिक किंवा मोबाईल शोधा...', hi: 'आवेदक या मोबाइल खोजें...'),
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_appSearchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _appSearchCtrl.clear();
                                setState(() => _appsLimit = 20);
                              },
                              child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppPdfButton.icon(
                    tooltip: AppTranslations.pick(lang, en: 'Download Report', mr: 'अहवाल डाउनलोड करा', hi: 'रिपोर्ट डाउनलोड करें'),
                    onPressed: () {
                      SchemeReportGenerator.generateAndPrintBeneficiaryReport(
                        applications: displayedApps,
                        isMarathi: lang == 'mr',
                        lang: lang,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Status Filter Pills
              Row(
                children: [
                  _buildStatusPill('All', AppTranslations.pick(lang, en: 'All', mr: 'सर्व', hi: 'सभी'), _applications.length, lang),
                  const SizedBox(width: 8),
                  _buildStatusPill('Pending', AppTranslations.getStatus('Pending', lang), _applications.where((a) => a.isPending).length, lang),
                  const SizedBox(width: 8),
                  _buildStatusPill('Approved', AppTranslations.getStatus('Approved', lang), _applications.where((a) => a.isApproved).length, lang),
                  const SizedBox(width: 8),
                  _buildStatusPill('Rejected', AppTranslations.getStatus('Rejected', lang), _applications.where((a) => a.isRejected).length, lang),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

        // Applications List
        Expanded(
          child: displayedApps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 54, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.pick(lang, en: 'No applications found', mr: 'कोणतेही अर्ज आढळले नाहीत', hi: 'कोई आवेदन नहीं मिला'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visibleApplications.length + (displayedApps.isNotEmpty ? 1 : 0),
                  itemBuilder: (ctx, idx) {
                    if (idx == _visibleApplications.length) {
                      return AppLoadMoreFooter(
                        currentCount: _visibleApplications.length,
                        totalCount: displayedApps.length,
                        pageSize: 20,
                        onLoadMore: () {
                          setState(() => _appsLimit += 20);
                        },
                        label: AppTranslations.pick(lang, en: 'applications', mr: 'अर्ज', hi: 'आवेदन'),
                        isMarathi: lang == 'mr',
                      );
                    }
                    final app = _visibleApplications[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildApplicationCard(lang, app),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(String id, String label, int count, String lang) {
    final isSel = _applicationStatusFilter.toLowerCase() == id.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _applicationStatusFilter = id;
          _schemesLimit = 20; _appsLimit = 20;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF0284C7) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              AppTranslations.formatDigits('$label ($count)', lang),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(String lang, SchemeApplicationModel app) {
    final schemeFallback = AppTranslations.formatDigits(
      '${AppTranslations.pick(lang, en: 'Scheme', mr: 'योजना', hi: 'योजना')} #${app.schemeId}',
      lang,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Applicant Name & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTranslatedText(
                      app.applicantName,
                      isName: true,
                      targetLanguage: lang,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    AppTranslatedText(
                      app.schemeName ?? schemeFallback,
                      targetLanguage: lang,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: app.statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppTranslations.getStatus(app.status, lang).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: app.statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Address & Mobile
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: AppTranslatedText(
                  app.address,
                  targetLanguage: lang,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                AppTranslations.formatDigits(app.mobile, lang),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const Spacer(),
              // Quick Call
              InkWell(
                onTap: () => _makePhoneCall(app.mobile),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.call_rounded, size: 16, color: Color(0xFF0284C7)),
                ),
              ),
              const SizedBox(width: 6),
              // Quick WhatsApp
              InkWell(
                onTap: () => _openWhatsApp(app.mobile, app.applicantName, app.schemeName),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),

          if (app.benefit != null && app.benefit!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFF16A34A), size: 15),
                  const SizedBox(width: 6),
                  Text(
                    AppTranslations.pick(lang, en: 'Benefit:', mr: 'लाभ:', hi: 'लाभ:'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppTranslatedText(
                      app.benefit!,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (app.rejectionReason != null && app.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 15),
                  const SizedBox(width: 6),
                  Text(
                    AppTranslations.pick(lang, en: 'Reason:', mr: 'कारण:', hi: 'कारण:'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppTranslatedText(
                      app.rejectionReason!,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                onPressed: () => _deleteApplication(app.id),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ'), style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  minimumSize: Size.zero,
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showApplicationStatusSheet(app),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(AppTranslations.pick(lang, en: 'Update Status', mr: 'स्थिती बदला', hi: 'स्थिति बदलें'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
