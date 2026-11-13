import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/scheme_model.dart';
import '../../../data/repositories/schemes_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'scheme_detail_screen.dart';
import 'scheme_report_generator.dart';

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

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'All',
      'labelEn': 'All',
      'labelMr': 'सर्व',
      'keywords': <String>[],
    },
    {
      'id': 'Women',
      'labelEn': 'Women',
      'labelMr': 'महिला',
      'keywords': ['women', 'mahila', 'girl', 'lady', 'widow', 'wife', 'female', 'महिला', 'विधवा', 'पत्नी', 'मुली'],
    },
    {
      'id': 'Student',
      'labelEn': 'Student',
      'labelMr': 'विद्यार्थी',
      'keywords': ['student', 'education', 'scholarship', 'school', 'college', 'vidyarthi', 'विद्यार्थी', 'शिक्षण', 'शिष्यवृत्ती', 'शाळा', 'महाविद्यालय'],
    },
    {
      'id': 'Senior Citizen',
      'labelEn': 'Senior Citizen',
      'labelMr': 'ज्येष्ठ नागरिक',
      'keywords': ['senior', 'pension', 'old', 'age', 'vrrudh', 'jeyshtha', 'ज्येष्ठ', 'नागरिक', 'पेन्शन', 'वृद्ध'],
    },
    {
      'id': 'Farmer',
      'labelEn': 'Farmer',
      'labelMr': 'शेतकरी',
      'keywords': ['farmer', 'agriculture', 'kisan', 'crop', 'shetkari', 'शेतकरी', 'कृषी', 'पीक'],
    },
    {
      'id': 'Health',
      'labelEn': 'Health',
      'labelMr': 'आरोग्य',
      'keywords': ['health', 'medical', 'treatment', 'hospital', 'insurance', 'aarogya', 'आरोग्य', 'वैद्यकीय', 'उपचार', 'रुग्णालय', 'विमा'],
    },
    {
      'id': 'Youth',
      'labelEn': 'Youth',
      'labelMr': 'तरुण / युवक',
      'keywords': ['youth', 'employment', 'job', 'skill', 'training', 'tarun', 'युवक', 'रोजगार', 'नोकरी', 'कौशल्य', 'प्रशिक्षण', 'तरुण', 'फेरीवाले'],
    },
    {
      'id': 'Housing',
      'labelEn': 'Housing',
      'labelMr': 'घरकुल / आवास',
      'keywords': ['housing', 'home', 'house', 'awas', 'gharkul', 'घरकुल', 'आवास', 'घर', 'शौचालय'],
    },
  ];

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
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    final text = 'Namaskar $applicantName ji, regarding your application for $schemeName at Nagarsevak Office.';
    final uri = Uri.parse('https://wa.me/91$clean?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // -------------------------------------------------------------
  // SMART SCHEME MATCHER MODAL
  // -------------------------------------------------------------
  void _showSmartMatcherModal() {
    final isMr = ref.read(isMarathiProvider);
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
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
              padding: EdgeInsets.only(
                top: 8,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMr ? 'स्मार्ट योजना शोधक' : 'Smart Scheme Matcher',
                              style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              isMr ? 'नागरिकांच्या पात्रतेनुसार अचूक योजना शोधा' : 'Find exact matching welfare schemes',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(sheetCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Age & Gender side-by-side
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(isMr ? 'वय (वर्षे)' : 'Citizen Age (Years)', isRequired: true),
                                    TextField(
                                      controller: ageCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: inputDec(hint: isMr ? 'उदा. २४, ६५...' : 'e.g. 24, 65...'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(isMr ? 'लिंग' : 'Gender', isRequired: true),
                                    DropdownButtonFormField<String>(
                                      initialValue: gender,
                                      decoration: inputDec(),
                                      items: [
                                        DropdownMenuItem(value: 'Male', child: Text(isMr ? 'पुरुष' : 'Male')),
                                        DropdownMenuItem(value: 'Female', child: Text(isMr ? 'महिला' : 'Female')),
                                        DropdownMenuItem(value: 'Other', child: Text(isMr ? 'इतर' : 'Other')),
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
                                    fieldLabel(isMr ? 'वार्षिक उत्पन्न (₹)' : 'Annual Income (₹)'),
                                    TextField(
                                      controller: incomeCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: inputDec(hint: isMr ? 'उदा. १५००००' : 'e.g. 150000'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(isMr ? 'व्यवसाय / शिक्षण' : 'Occupation'),
                                    TextField(
                                      controller: occCtrl,
                                      decoration: inputDec(hint: isMr ? 'विद्यार्थी, शेतकरी...' : 'Student, Farmer...'),
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
                                final age = int.tryParse(ageCtrl.text.trim()) ?? 30;
                                final occ = occCtrl.text.trim().toLowerCase();

                                // Matching algorithm matching Nagarsevak-Managment AI Matcher
                                final matched = <int>[];
                                for (final s in _schemes) {
                                  final cat = s.category.toLowerCase();
                                  final text = '${s.name} ${s.description} ${s.eligibility} ${s.benefits}'.toLowerCase();

                                  if (gender == 'Female' && (cat == 'women' || text.contains('महिला') || text.contains('ladki'))) {
                                    matched.add(s.id);
                                  }
                                  if (age >= 60 && (cat == 'senior citizen' || text.contains('senior') || text.contains('ज्येष्ठ') || text.contains('वृद्ध'))) {
                                    matched.add(s.id);
                                  }
                                  if ((occ.contains('student') || occ.contains('विद्यार्थी') || age <= 25) && (cat == 'student' || text.contains('scholarship') || text.contains('शिष्यवृत्ती'))) {
                                    matched.add(s.id);
                                  }
                                  if ((occ.contains('farmer') || occ.contains('शेतकरी')) && (cat == 'farmer' || text.contains('kisan') || text.contains('कृषी'))) {
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
                                isMr ? 'पात्र योजना शोधा' : 'Find Matching Schemes',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
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
    final isMr = ref.read(isMarathiProvider);
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
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
              padding: EdgeInsets.only(
                top: 8,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMr ? 'नवीन शासकीय योजना जोडा' : 'Add New Government Scheme',
                          style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(sheetCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                    fieldLabel(isMr ? 'योजनेचे नाव' : 'Scheme Name', isRequired: true),
                                    TextField(
                                      controller: nameCtrl,
                                      decoration: inputDec(hint: isMr ? 'उदा. प्रधानमंत्री आवास योजना' : 'e.g. PM Awas Yojana'),
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
                                    fieldLabel(isMr ? 'वर्ग / विभाग' : 'Category', isRequired: true),
                                    DropdownButtonFormField<String>(
                                      initialValue: selectedCat,
                                      decoration: inputDec(),
                                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                                    fieldLabel(isMr ? 'आर्थिक लाभ व अनुदान' : 'Financial Benefits & Grants', isRequired: true),
                                    TextField(
                                      controller: benCtrl,
                                      maxLines: 2,
                                      decoration: inputDec(hint: isMr ? 'उदा. ₹२.५ लाख अनुदान...' : 'e.g. ₹2.5 Lakhs grant...'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(isMr ? 'पात्रता अटी' : 'Eligibility Criteria', isRequired: true),
                                    TextField(
                                      controller: eligCtrl,
                                      maxLines: 2,
                                      decoration: inputDec(hint: isMr ? 'उत्पन्न मर्यादा, वय...' : 'Income limit, age...'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Documents
                          fieldLabel(isMr ? 'आवश्यक कागदपत्रे' : 'Documents Required Checklist', isRequired: true),
                          TextField(
                            controller: docCtrl,
                            maxLines: 2,
                            decoration: inputDec(hint: isMr ? 'आधार कार्ड, रेशन कार्ड, उत्पन्न दाखला...' : 'Aadhaar, Ration card, Income proof...'),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          fieldLabel(isMr ? 'योजनेचा तपशील व उद्दिष्ट' : 'Description & Objectives', isRequired: true),
                          TextField(
                            controller: descCtrl,
                            maxLines: 2,
                            decoration: inputDec(hint: isMr ? 'योजनेची संक्षिप्त उद्दिष्टे...' : 'Brief objective and overview...'),
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
                                    SnackBar(content: Text(isMr ? 'कृपया योजनेचे नाव प्रविष्ट करा' : 'Please enter scheme name')),
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
                                      content: Text(isMr ? 'योजना यशस्वीरित्या जोडली!' : 'Scheme added successfully!'),
                                      backgroundColor: const Color(0xFF16A34A),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                isMr ? 'योजना जतन करा' : 'Save Scheme',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
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
    final isMr = ref.read(isMarathiProvider);
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
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
              padding: EdgeInsets.only(
                top: 8,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMr ? 'अर्जाची स्थिती अद्यतनित करा' : 'Update Application Status',
                              style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              app.applicantName,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(sheetCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fieldLabel(isMr ? 'स्थिती' : 'Status', isRequired: true),
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
                                        st == 'Pending' ? (isMr ? 'प्रलंबित' : 'Pending') : st == 'Approved' ? (isMr ? 'मंजूर' : 'Approved') : (isMr ? 'नाकारले' : 'Rejected'),
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
                            fieldLabel(isMr ? 'मंजूर लाभ / अनुदान तपशील' : 'Sanctioned Benefit / Grant Details'),
                            TextField(
                              controller: benefitCtrl,
                              decoration: inputDec(hint: isMr ? 'उदा. ₹१,५००/महिना डीबीटी मंजूर...' : 'e.g. ₹1,500/month DBT approved...'),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (currentStatus.toLowerCase() == 'rejected') ...[
                            fieldLabel(isMr ? 'नाकारण्याचे कारण' : 'Reason for Rejection'),
                            TextField(
                              controller: reasonCtrl,
                              decoration: inputDec(hint: isMr ? 'उदा. उत्पन्न मर्यादा ओलांडली...' : 'e.g. Income exceeds ₹2.5 Lakhs limit...'),
                            ),
                            const SizedBox(height: 14),
                          ],
                          fieldLabel(isMr ? 'अधिकारी / कार्यालयीन टीप' : 'Officer / Office Notes'),
                          TextField(
                            controller: notesCtrl,
                            maxLines: 2,
                            decoration: inputDec(hint: isMr ? 'पुढील कार्यवाहीच्या नोंदी...' : 'Follow-up remarks...'),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isMr ? 'अर्जाची स्थिती अद्यतनित केली: $currentStatus' : 'Application updated to $currentStatus')),
                                  );
                                }
                              },
                              child: Text(
                                isMr ? 'स्थिती अद्यतनित करा' : 'Update Status',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
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
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Delete Application?'),
        content: const Text('Are you sure you want to remove this citizen application?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await ref.read(schemesRepoProvider).deleteApplication(id);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application removed.')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
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
              tooltip: 'Open Menu Drawer',
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
            children: const [
              Text(
                'Govt Schemes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Central and state welfare schemes database',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
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
                              label: isMr ? 'शासकीय योजना' : 'Schemes',
                              count: _schemes.length,
                              isActive: _activeTab == 'schemes',
                            ),
                            _buildPrimaryTab(
                              id: 'applications',
                              label: isMr ? 'लाभार्थी व अर्ज' : 'Applications',
                              count: _applications.length,
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
                        ? _buildSchemesView(isMr, displayedSchemes)
                        : _buildApplicationsView(isMr, displayedApps),
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
                  isMr ? 'नवीन योजना' : 'Add Scheme',
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
    required bool isActive,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = id),
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
                  '$count',
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
  Widget _buildSchemesView(bool isMr, List<SchemeModel> displayedSchemes) {
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
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: isMr ? 'योजना, लाभ किंवा पात्रता शोधा...' : 'Search schemes, benefits, eligibility...',
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
                                setState(() {});
                              },
                              child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
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
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      SchemeReportGenerator.generateAndPrintListReport(
                        schemes: displayedSchemes,
                        isMarathi: isMr,
                        categoryFilter: _selectedCategory,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFF0284C7)),
                    ),
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
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final cat = _categories[idx];
                    final catId = cat['id'] as String;
                    final isSel = _selectedCategory == catId;
                    final label = isMr ? cat['labelMr'] as String : cat['labelEn'] as String;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = catId),
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
                            isMr ? 'मॅचर फिल्टर सक्रिय (${displayedSchemes.length} योजना)' : 'Smart Filter Active (${displayedSchemes.length} schemes)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _matchedSchemeIds = null),
                        child: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
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
                        isMr ? 'कोणतीही योजना आढळली नाही' : 'No schemes match your filter',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _selectedCategory = 'All';
                            _matchedSchemeIds = null;
                          });
                        },
                        child: const Text('Reset All Filters'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayedSchemes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final scheme = displayedSchemes[idx];
                    return _buildSchemeCard(isMr, scheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSchemeCard(bool isMr, SchemeModel scheme) {
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
                        child: Text(
                          scheme.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: scheme.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scheme.localizedName(isMr),
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
            Text(
              scheme.localizedDescription(isMr),
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
                    child: Text(
                      scheme.localizedBenefits(isMr),
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
                      isMarathi: isMr,
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: Text(isMr ? 'पत्रक' : 'Flyer', style: const TextStyle(fontSize: 12)),
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
                  label: Text(isMr ? 'अर्ज करा' : 'Apply', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
  Widget _buildApplicationsView(bool isMr, List<SchemeApplicationModel> displayedApps) {
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
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: isMr ? 'नागरिक किंवा मोबाईल शोधा...' : 'Search applicant name, mobile, address...',
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
                                setState(() {});
                              },
                              child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      SchemeReportGenerator.generateAndPrintBeneficiaryReport(
                        applications: displayedApps,
                        isMarathi: isMr,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Status Filter Pills
              Row(
                children: [
                  _buildStatusPill('All', isMr ? 'सर्व' : 'All', _applications.length),
                  const SizedBox(width: 8),
                  _buildStatusPill('Pending', isMr ? 'प्रलंबित' : 'Pending', _applications.where((a) => a.isPending).length),
                  const SizedBox(width: 8),
                  _buildStatusPill('Approved', isMr ? 'मंजूर' : 'Approved', _applications.where((a) => a.isApproved).length),
                  const SizedBox(width: 8),
                  _buildStatusPill('Rejected', isMr ? 'नाकारलेले' : 'Rejected', _applications.where((a) => a.isRejected).length),
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
                        isMr ? 'कोणतेही अर्ज आढळले नाहीत' : 'No applications found',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayedApps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final app = displayedApps[idx];
                    return _buildApplicationCard(isMr, app);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(String id, String label, int count) {
    final isSel = _applicationStatusFilter.toLowerCase() == id.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _applicationStatusFilter = id),
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
              '$label ($count)',
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

  Widget _buildApplicationCard(bool isMr, SchemeApplicationModel app) {
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
                    Text(
                      app.applicantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      app.schemeName ?? 'Scheme #${app.schemeId}',
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
                  app.status.toUpperCase(),
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
                child: Text(
                  app.address,
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
                app.mobile,
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
                  Expanded(
                    child: Text(
                      'Benefit: ${app.benefit}',
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
                  Expanded(
                    child: Text(
                      'Reason: ${app.rejectionReason}',
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
                label: Text(isMr ? 'हटवा' : 'Delete', style: const TextStyle(fontSize: 12)),
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
                label: Text(isMr ? 'स्थिती बदला' : 'Update Status', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
