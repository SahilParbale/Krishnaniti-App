import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/voter_application_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/voter_applications_repository.dart';
import '../../providers/language_provider.dart';
import 'voter_forms_report_generator.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';

class VoterFormsScreen extends ConsumerStatefulWidget {
  const VoterFormsScreen({super.key});

  @override
  ConsumerState<VoterFormsScreen> createState() => _VoterFormsScreenState();
}

class _VoterFormsScreenState extends ConsumerState<VoterFormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedFormType = 'All';
  int _displayedLimit = 20;

  bool _isLoading = true;
  List<VoterApplicationModel> _applications = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'submitted': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };

  List<VoterApplicationModel> get _visibleApplications =>
      _applications.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final repo = ref.read(voterApplicationsRepoProvider);

    final apps = await repo.getApplications(
      searchQuery: AppTranslations.normalizeAsciiDigits(_searchController.text),
      statusFilter: _selectedStatus,
      formTypeFilter: _selectedFormType,
    );
    final stats = await repo.getStatistics();

    if (mounted) {
      setState(() {
        _applications = apps;
        _stats = stats;
        _isLoading = false;
        _displayedLimit = 20;
      });
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final clean = AppTranslations.normalizeAsciiDigits(phone).replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    var clean = AppTranslations.normalizeAsciiDigits(phone).replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) clean = '91$clean';
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openAddEditModal([VoterApplicationModel? appToEdit]) {
    final lang = ref.read(appLanguageProvider);
    final nameCtrl = TextEditingController(text: appToEdit?.applicantName ?? '');
    final mobileCtrl = TextEditingController(text: appToEdit?.applicantMobile ?? '');
    final notesCtrl = TextEditingController(text: appToEdit?.notes ?? '');
    String formType = appToEdit?.formType ?? 'Form 6';
    String status = appToEdit?.status ?? 'Submitted';
    String? linkedVoterId = appToEdit?.voterId;

    // Search Mode State
    bool isSearchMode = false;
    final voterSearchCtrl = TextEditingController();
    List<VoterModel> voterSuggestions = [];
    bool isSearchingVoter = false;

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return AppFieldLabel(label: text, isRequired: isRequired);
    }

    InputDecoration inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                  icon: Icons.how_to_reg_rounded,
                  title: appToEdit == null
                      ? AppTranslations.pick(
                          lang,
                          en: 'Log New Application',
                          mr: 'नवीन अर्ज नोंदवा',
                          hi: 'नया आवेदन दर्ज करें',
                        )
                      : AppTranslations.pick(
                          lang,
                          en: 'Edit Voter Application',
                          mr: 'मतदार अर्ज नोंदी सुधारा',
                          hi: 'मतदाता आवेदन विवरण संपादित करें',
                        ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Voter registration, modification and deletion forms',
                    mr: 'फॉर्म ६, ६ए, ७ किंवा ८ अंतर्गत मतदार नोंदणी अर्ज',
                    hi: 'फॉर्म ६, ६ए, ७ या ८ के अंतर्गत मतदाता पंजीकरण आवेदन',
                  ),
                  onClose: () => Navigator.pop(ctx),
                ),

                // 2. SCROLLABLE BODY & BUTTONS
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      14,
                      18,
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    children: [
                      // Link Voter Search Card (When not in search mode, no voter linked, and not editing)
                      if (!isSearchMode && appToEdit == null && linkedVoterId == null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBAE6FD), style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE0F2FE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_search_rounded, color: Color(0xFF0284C7), size: 20),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Link Voter from Roll',
                                  mr: 'मतदार यादीतून लिंक करा',
                                  hi: 'मतदाता सूची से लिंक करें',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Search voter list to auto-fill applicant name and mobile',
                                  mr: 'मतदार यादीतील नाव शोधून अर्जाचे नाव व मोबाईल स्वयंचलित भरा',
                                  hi: 'आवेदक का नाम और मोबाइल स्वतः भरने के लिए मतदाता सूची खोजें',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.search, size: 16, color: Color(0xFF0284C7)),
                                label: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Search Voter Roll',
                                    mr: 'मतदार यादी शोधा',
                                    hi: 'मतदाता सूची खोजें',
                                  ),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                                onPressed: () => setModalState(() => isSearchMode = true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Dedicated Voter Search Panel
                      if (isSearchMode) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                    icon: const Icon(Icons.arrow_back, size: 16),
                                    label: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Back to form',
                                        mr: 'अर्जाकडे परत जा',
                                        hi: 'फॉर्म पर वापस जाएं',
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () => setModalState(() => isSearchMode = false),
                                  ),
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Search Voter',
                                      mr: 'मतदार शोधा',
                                      hi: 'मतदाता खोजें',
                                    ),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: voterSearchCtrl,
                                autofocus: true,
                                decoration: inputDec(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'Search by name, mobile or EPIC...',
                                    mr: 'नाव, मोबाईल किंवा ओळखपत्र (EPIC) नंबर...',
                                    hi: 'नाम, मोबाइल या EPIC नंबर से खोजें...',
                                  ),
                                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                                  suffixIcon: isSearchingVoter
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                        )
                                      : null,
                                ),
                                onChanged: (val) async {
                                  final cleanQ = AppTranslations.normalizeAsciiDigits(val);
                                  if (cleanQ.trim().length >= 2) {
                                    setModalState(() => isSearchingVoter = true);
                                    final repo = ref.read(voterApplicationsRepoProvider);
                                    final results = await repo.searchVoters(cleanQ);
                                    setModalState(() {
                                      voterSuggestions = results;
                                      isSearchingVoter = false;
                                    });
                                  } else {
                                    setModalState(() => voterSuggestions = []);
                                  }
                                },
                              ),
                              if (voterSuggestions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 180),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: voterSuggestions.length,
                                    separatorBuilder: (_, index) => const Divider(height: 1),
                                    itemBuilder: (context, idx) {
                                      final v = voterSuggestions[idx];
                                      return ListTile(
                                        dense: true,
                                        visualDensity: VisualDensity.compact,
                                        title: AppTranslatedText(
                                          v.displayNameFor(lang),
                                          targetLanguage: lang,
                                          isName: true,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                        ),
                                        subtitle: Text(
                                          '${AppTranslations.formatDigits(v.age, lang)}${AppTranslations.pick(lang, en: "Y", mr: "व", hi: "व")} • ${v.genderLabel(lang)} • EPIC: ${AppTranslations.formatDigits(v.epicNo, lang)}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                        trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7), size: 20),
                                        onTap: () {
                                          setModalState(() {
                                            nameCtrl.text = v.displayName;
                                            if (v.mobile != null && v.mobile!.isNotEmpty) {
                                              mobileCtrl.text = v.mobile!;
                                            }
                                            linkedVoterId = v.id;
                                            isSearchMode = false;
                                            voterSuggestions = [];
                                            voterSearchCtrl.clear();
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppTranslations.pick(
                                                  lang,
                                                  en: 'Voter linked successfully!',
                                                  mr: 'मतदार लिंक केला!',
                                                  hi: 'मतदाता सफलतापूर्वक लिंक किया गया!',
                                                ),
                                              ),
                                              backgroundColor: const Color(0xFF16A34A),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Linked Voter Indicator Banner
                      if (linkedVoterId != null && linkedVoterId!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${AppTranslations.pick(lang, en: "Linked to Voter ID", mr: "मतदार ओळखपत्र क्र. शी लिंक केले", hi: "मतदाता पहचान पत्र क्र. से लिंक किया गया")}: ${AppTranslations.formatDigits(linkedVoterId, lang)}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ),
                              InkWell(
                                onTap: () => setModalState(() => linkedVoterId = null),
                                child: Text(
                                  AppTranslations.pick(lang, en: 'Remove', mr: 'काढून टाका', hi: 'हटाएं'),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Applicant Name
                      fieldLabel(
                        AppTranslations.pick(lang, en: 'Applicant Name', mr: 'अर्जदाराचे नाव', hi: 'आवेदक का नाम'),
                        isRequired: true,
                      ),
                      TextField(
                        controller: nameCtrl,
                        decoration: inputDec(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'e.g. Rahul Suresh Shinde',
                            mr: 'उदा. राहुल सुरेश शिंदे',
                            hi: 'उदा. राहुल सुरेश शिंदे',
                          ),
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Applicant Mobile
                      fieldLabel(
                        AppTranslations.pick(lang, en: 'Applicant Mobile', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                      ),
                      TextField(
                        controller: mobileCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: inputDec(
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF64748B)),
                          hintText: AppTranslations.formatDigits('98220xxxxx', lang),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Form Type & Status side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(lang, en: 'Form Type', mr: 'अर्जाचा प्रकार', hi: 'आवेदन प्रकार'),
                                  isRequired: true,
                                  value: formType,
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Form 6',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Form 6 (New Reg)',
                                          mr: 'नमुना ६ (नवीन नोंदणी)',
                                          hi: 'फॉर्म ६ (नया पंजीकरण)',
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Form 7',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Form 7 (Deletion)',
                                          mr: 'नमुना ७ (नाव वगळणे)',
                                          hi: 'फॉर्म ७ (नाम विलोपन)',
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Form 8',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Form 8 (Correction)',
                                          mr: 'नमुना ८ (दुरुस्ती)',
                                          hi: 'फॉर्म ८ (सुधार)',
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Search',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Roll Search',
                                          mr: 'यादी शोध साहाय्य',
                                          hi: 'मतदाता सूची खोज',
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => formType = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(lang, en: 'Status', mr: 'अर्जाची स्थिती', hi: 'आवेदन स्थिति'),
                                  isRequired: true,
                                  value: status,
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Submitted',
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'Submitted', mr: 'दाखल', hi: 'जमा किया गया'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Pending',
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Approved',
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'Approved', mr: 'मंजूर', hi: 'स्वीकृत'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Rejected',
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'Rejected', mr: 'नाकारले', hi: 'अस्वीकृत'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => status = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      fieldLabel(
                        AppTranslations.pick(
                          lang,
                          en: 'Notes / Remarks / Documents Attached',
                          mr: 'नोंद / शेरा / कागदपत्रे',
                          hi: 'टिप्पणी / विवरण / संलग्न दस्तावेज़',
                        ),
                      ),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: inputDec(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'e.g. Aadhaar card attached, DOB correction, PVC card request.',
                            mr: 'उदा. आधार कार्ड जोडले, जन्मदिनांक दुरुस्ती, नवीन पीव्हीसी कार्ड मागणी.',
                            hi: 'उदा. आधार कार्ड संलग्न, जन्मतिथि सुधार, पीवीसी कार्ड अनुरोध।',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Buttons: Cancel & Save Application
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Please enter applicant name.',
                                          mr: 'कृपया अर्जदाराचे नाव प्रविष्ट करा.',
                                          hi: 'कृपया आवेदक का नाम दर्ज करें।',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final normalizedMob = AppTranslations.normalizeAsciiDigits(mobileCtrl.text.trim());
                                final messenger = ScaffoldMessenger.of(context);
                                final appModel = VoterApplicationModel(
                                  id: appToEdit?.id ?? 'app-${DateTime.now().millisecondsSinceEpoch}',
                                  voterId: linkedVoterId,
                                  applicantName: name,
                                  applicantMobile: normalizedMob.isNotEmpty ? normalizedMob : null,
                                  formType: formType,
                                  status: status,
                                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                                  createdAt: appToEdit?.createdAt ?? DateTime.now(),
                                );

                                final repo = ref.read(voterApplicationsRepoProvider);
                                if (appToEdit == null) {
                                  await repo.addApplication(appModel);
                                } else {
                                  await repo.updateApplication(appModel);
                                }

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (!mounted) return;
                                _loadApplications();

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      appToEdit == null
                                          ? AppTranslations.pick(
                                              lang,
                                              en: 'Application logged successfully!',
                                              mr: 'अर्ज यशस्वीरित्या नोंदवला गेला!',
                                              hi: 'आवेदन सफलतापूर्वक दर्ज किया गया!',
                                            )
                                          : AppTranslations.pick(
                                              lang,
                                              en: 'Application details updated!',
                                              mr: 'अर्जाचे तपशील अद्यतनित केले!',
                                              hi: 'आवेदन विवरण अपडेट किया गया!',
                                            ),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                              label: Text(
                                appToEdit == null
                                    ? AppTranslations.pick(lang, en: 'Save Application', mr: 'अर्ज जतन करा', hi: 'आवेदन सहेजें')
                                    : AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'बदलाव सहेजें'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteApplication(VoterApplicationModel app, String lang) async {
    final tName = await DynamicTranslationService.translateOrRaw(
      app.applicantName,
      lang,
      isName: true,
    );
    if (!mounted) return;
    final fTypeLabel = app.formTypeLabel(lang);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppTranslations.pick(
            lang,
            en: 'Delete Application',
            mr: 'अर्ज हटवा',
            hi: 'आवेदन हटाएं',
          ),
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to delete $fTypeLabel application for $tName?',
            mr: 'तुम्हाला खात्री आहे की तुम्हाला $tName यांचा $fTypeLabel अर्ज हटवायचा आहे?',
            hi: 'क्या आप वाकई $tName का $fTypeLabel आवेदन हटाना चाहते हैं?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(voterApplicationsRepoProvider);
              await repo.deleteApplication(app.id);
              if (!mounted) return;
              _loadApplications();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Application deleted successfully.',
                      mr: 'अर्ज यशस्वीरित्या हटवला.',
                      hi: 'आवेदन सफलतापूर्वक हटा दिया गया।',
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Open Menu Drawer',
              mr: 'मेनू ड्रॉवर उघडा',
              hi: 'मेनू ड्रॉवर खोलें',
            ),
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
              AppTranslations.pick(
                lang,
                en: 'Voter Forms',
                mr: 'मतदार अर्ज',
                hi: 'मतदाता फॉर्म',
              ),
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
              AppTranslations.pick(
                lang,
                en: 'ECI Form 6, Form 7, Form 8 registration helpdesk',
                mr: 'निवडणूक आयोग नमुना ६, ७, ८ नोंदणी मदत केंद्र',
                hi: 'चुनाव आयोग फॉर्म ६, ७, ८ पंजीकरण सहायता केंद्र',
              ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          AppTranslations.pick(
            lang,
            en: 'Log Application',
            mr: 'अर्ज नोंदवा',
            hi: 'आवेदन दर्ज करें',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'ECI Forms & Guides',
                              mr: 'निवडणूक अर्ज व माहिती',
                              hi: 'चुनाव फॉर्म व दिशानिर्देश',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_edu_outlined, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Application History',
                              mr: 'अर्जांचा इतिहास',
                              hi: 'आवेदन इतिहास',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOfficialFormsTab(lang),
                _buildApplicationsHistoryTab(lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialFormsTab(String lang) {
    final helplineStr = AppTranslations.formatDigits('1950', lang);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ECI Helpline Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Election Commission Helpline: $helplineStr',
                          mr: 'निवडणूक आयोग हेल्पलाईन: $helplineStr',
                          hi: 'चुनाव आयोग हेल्पलाइन: $helplineStr',
                        ),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Toll-free helpline for voter registration & roll assistance',
                          mr: 'मतदार नोंदणी आणि यादी सहाय्यासाठी टोल-फ्री हेल्पलाईन',
                          hi: 'मतदाता पंजीकरण और सूची सहायता के लिए टोल-फ्री हेल्पलाइन',
                        ),
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _makePhoneCall('1950'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    AppTranslations.pick(lang, en: 'Call', mr: 'कॉल', hi: 'कॉल'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            AppTranslations.pick(
              lang,
              en: 'Official Election Commission (ECI) Forms',
              mr: 'अधिकृत निवडणूक आयोग (ECI) अर्ज',
              hi: 'आधिकारिक चुनाव आयोग (ECI) फॉर्म',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Official forms for new registration, corrections, and constituency transfer',
              mr: 'नवीन नोंदणी, दुरुस्ती आणि मतदारसंघ बदलासाठी अधिकृत नमुने',
              hi: 'नए पंजीकरण, सुधार और निर्वाचन क्षेत्र स्थानांतरण के लिए आधिकारिक फॉर्म',
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 14),

          // 4 ECI Form Service Cards
          _buildEciFormCard(
            lang: lang,
            title: AppTranslations.pick(
              lang,
              en: 'Search in Electoral Roll',
              mr: 'मतदार यादीत नाव शोधा',
              hi: 'मतदाता सूची में खोजें',
            ),
            description: AppTranslations.pick(
              lang,
              en: 'Search your name and part number in the official voter roll to locate your polling booth.',
              mr: 'तुमचे मतदान केंद्र शोधण्यासाठी अधिकृत मतदार यादीत नाव आणि भाग क्रमांक तपासा.',
              hi: 'अपना मतदान केंद्र जानने के लिए आधिकारिक मतदाता सूची में अपना नाम और भाग संख्या खोजें।',
            ),
            requiredDocs: AppTranslations.pick(
              lang,
              en: 'Personal details, EPIC number, or registered mobile number',
              mr: 'वैयक्तिक तपशील, ओळखपत्र (EPIC) क्र. किंवा नोंदणीकृत मोबाईल नंबर',
              hi: 'व्यक्तिगत विवरण, EPIC नंबर या पंजीकृत मोबाइल नंबर',
            ),
            requirements: [
              AppTranslations.pick(
                lang,
                en: 'Search by personal details (Name, Age, Gender, District)',
                mr: 'वैयक्तिक माहितीद्वारे शोध (नाव, वय, लिंग, जिल्हा)',
                hi: 'व्यक्तिगत विवरण से खोजें (नाम, उम्र, लिंग, जिला)',
              ),
              AppTranslations.pick(
                lang,
                en: 'Direct search by EPIC number',
                mr: 'ओळखपत्र (EPIC) क्रमांकाद्वारे थेट शोध',
                hi: 'EPIC नंबर द्वारा सीधी खोज',
              ),
              AppTranslations.pick(
                lang,
                en: 'Search by registered mobile number',
                mr: 'नोंदणीकृत मोबाईल नंबरद्वारे शोध',
                hi: 'पंजीकृत मोबाइल नंबर से खोजें',
              ),
            ],
            icon: Icons.search_rounded,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            buttonText: AppTranslations.pick(
              lang,
              en: 'Search Official Roll',
              mr: 'अधिकृत यादीत शोधा',
              hi: 'आधिकारिक सूची में खोजें',
            ),
            url: 'https://electoralsearch.eci.gov.in',
          ),

          const SizedBox(height: 14),

          _buildEciFormCard(
            lang: lang,
            title: AppTranslations.pick(
              lang,
              en: 'New Voter Registration (Form 6)',
              mr: 'नवीन मतदार नोंदणी (नमुना ६)',
              hi: 'नया मतदाता पंजीकरण (फॉर्म ६)',
            ),
            description: AppTranslations.pick(
              lang,
              en: 'For first-time voters (completed 18 years of age) or citizens shifted from other constituencies.',
              mr: 'पहिल्यांदाच मतदान करणाऱ्यांसाठी (१८ वर्षे पूर्ण) किंवा इतर मतदारसंघातून स्थलांतरित नागरिकांसाठी.',
              hi: 'पहली बार मतदान करने वालों (१८ वर्ष पूर्ण) या अन्य क्षेत्रों से आए नागरिकों के लिए।',
            ),
            requiredDocs: AppTranslations.pick(
              lang,
              en: 'Passport size photo, age proof, residence proof',
              mr: 'पासपोर्ट आकाराचा फोटो, वयाचा पुरावा, निवासाचा पुरावा',
              hi: 'पासपोर्ट आकार की फोटो, आयु प्रमाण, निवास प्रमाण',
            ),
            requirements: [
              AppTranslations.pick(
                lang,
                en: 'Recent passport size color photograph',
                mr: 'अलीकडील पासपोर्ट आकाराचा रंगीत फोटो',
                hi: 'हाल का पासपोर्ट आकार का रंगीन फोटोग्राफ',
              ),
              AppTranslations.pick(
                lang,
                en: 'Identity proof (Aadhaar Card / PAN Card / Driving License)',
                mr: 'ओळख पुरावा (आधार कार्ड / पॅन कार्ड / ड्रायव्हिंग लायसन्स)',
                hi: 'पहचान प्रमाण (आधार कार्ड / पैन कार्ड / ड्राइविंग लाइसेंस)',
              ),
              AppTranslations.pick(
                lang,
                en: 'Residence proof (Electricity bill / Bank passbook / Ration card)',
                mr: 'निवास पुरावा (वीज बिल / बँक पासबुक / रेशन कार्ड)',
                hi: 'निवास प्रमाण (बिजली बिल / बैंक पासबुक / राशन कार्ड)',
              ),
              AppTranslations.pick(
                lang,
                en: 'Age proof (Birth certificate / 10th marksheet)',
                mr: 'वयाचा पुरावा (जन्म दाखला / १० वी गुणपत्रिका)',
                hi: 'आयु प्रमाण (जन्म प्रमाण पत्र / १०वीं की मार्कशीट)',
              ),
            ],
            icon: Icons.person_add_alt_1_rounded,
            color: const Color(0xFF0284C7),
            bgColor: const Color(0xFFF0F9FF),
            borderColor: const Color(0xFFBAE6FD),
            buttonText: AppTranslations.pick(
              lang,
              en: 'Fill Form 6 Online',
              mr: 'नमुना ६ ऑनलाइन भरा',
              hi: 'फॉर्म ६ ऑनलाइन भरें',
            ),
            url: 'https://voters.eci.gov.in/form6',
          ),

          const SizedBox(height: 14),

          _buildEciFormCard(
            lang: lang,
            title: AppTranslations.pick(
              lang,
              en: 'Deletion of Name from Roll (Form 7)',
              mr: 'यादीतून नाव वगळणे (नमुना ७)',
              hi: 'सूची से नाम हटाना (फॉर्म ७)',
            ),
            description: AppTranslations.pick(
              lang,
              en: 'For objecting to an entry or deleting names of deceased / permanently shifted electors.',
              mr: 'नोंदीवर आक्षेप घेण्यासाठी किंवा मयत / कायमस्वरूपी स्थलांतरित मतदारांचे नाव वगळण्यासाठी.',
              hi: 'किसी प्रविष्टि पर आपत्ति दर्ज करने या मृत / स्थायी रूप से स्थानांतरित मतदाताओं के नाम हटाने के लिए।',
            ),
            requiredDocs: AppTranslations.pick(
              lang,
              en: 'EPIC number of elector, reason and supporting document',
              mr: 'मतदाराचा EPIC क्रमांक, कारण आणि सहाय्यक कागदपत्रे',
              hi: 'मतदाता का EPIC नंबर, कारण और सहायक दस्तावेज़',
            ),
            requirements: [
              AppTranslations.pick(
                lang,
                en: 'EPIC number and roll part details of the elector',
                mr: 'मतदाराचा EPIC क्रमांक आणि यादी भाग तपशील',
                hi: 'मतदाता का EPIC नंबर और सूची भाग विवरण',
              ),
              AppTranslations.pick(
                lang,
                en: 'Reason for deletion (Shifted / Deceased / Duplicate entry)',
                mr: 'नाव वगळण्याचे कारण (स्थलांतरित / मयत / दुबार नोंद)',
                hi: 'नाम हटाने का कारण (स्थानांतरित / मृत / डुप्लिकेट प्रविष्टि)',
              ),
              AppTranslations.pick(
                lang,
                en: 'Municipal death certificate in case of deceased elector',
                mr: 'मयत मतदाराच्या बाबतीत महानगरपालिका मृत्यू दाखला',
                hi: 'मृत मतदाता के मामले में नगर निगम का मृत्यु प्रमाण पत्र',
              ),
            ],
            icon: Icons.person_remove_alt_1_rounded,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
            buttonText: AppTranslations.pick(
              lang,
              en: 'Fill Form 7 Online',
              mr: 'नमुना ७ ऑनलाइन भरा',
              hi: 'फॉर्म ७ ऑनलाइन भरें',
            ),
            url: 'https://voters.eci.gov.in/form7',
          ),

          const SizedBox(height: 14),

          _buildEciFormCard(
            lang: lang,
            title: AppTranslations.pick(
              lang,
              en: 'Update Voter Details (Form 8)',
              mr: 'मतदार तपशील दुरुस्ती (नमुना ८)',
              hi: 'मतदाता विवरण अपडेट (फॉर्म ८)',
            ),
            description: AppTranslations.pick(
              lang,
              en: 'For corrections in name, address, DOB, or ordering a replacement Smart PVC voter card.',
              mr: 'नाव, पत्ता, जन्मतारीख दुरुस्ती किंवा नवीन स्मार्ट PVC मतदार कार्ड मिळवण्यासाठी.',
              hi: 'नाम, पता, जन्मतिथि सुधारने या नया स्मार्ट PVC मतदाता कार्ड मंगाने के लिए।',
            ),
            requiredDocs: AppTranslations.pick(
              lang,
              en: 'Existing EPIC number, supporting proof for correction',
              mr: 'सध्याचा EPIC क्रमांक आणि दुरुस्तीसाठी पुरावा',
              hi: 'मौजूदा EPIC नंबर, सुधार के लिए सहायक प्रमाण',
            ),
            requirements: [
              AppTranslations.pick(
                lang,
                en: 'Existing EPIC number',
                mr: 'सध्याचा ओळखपत्र (EPIC) क्रमांक',
                hi: 'मौजूदा EPIC नंबर',
              ),
              AppTranslations.pick(
                lang,
                en: 'Proof of correction (Name/Address/DOB change documents)',
                mr: 'दुरुस्तीचा पुरावा (नाव / पत्ता / जन्मतारीख बदलाची कागदपत्रे)',
                hi: 'सुधार का प्रमाण (नाम/पता/जन्मतिथि परिवर्तन दस्तावेज़)',
              ),
              AppTranslations.pick(
                lang,
                en: 'New address proof (for shifting within constituency)',
                mr: 'नवीन पत्त्याचा पुरावा (मतदारसंघांतर्गत स्थलांतरासाठी)',
                hi: 'नए पते का प्रमाण (निर्वाचन क्षेत्र के भीतर बदलाव के लिए)',
              ),
            ],
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA7F3D0),
            buttonText: AppTranslations.pick(
              lang,
              en: 'Fill Form 8 Online',
              mr: 'नमुना ८ ऑनलाइन भरा',
              hi: 'फॉर्म ८ ऑनलाइन भरें',
            ),
            url: 'https://voters.eci.gov.in/form8',
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEciFormCard({
    required String lang,
    required String title,
    required String description,
    required String requiredDocs,
    required List<String> requirements,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required String buttonText,
    required String url,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 12),

                // Documents required
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${AppTranslations.pick(lang, en: "Required Documents", mr: "आवश्यक कागदपत्रे", hi: "आवश्यक दस्तावेज़")}: $requiredDocs',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Checklist
                ...requirements.map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 14),

                // Launch External Link Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchExternalUrl(url),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsHistoryTab(String lang) {
    final total = (_stats['total'] ?? 0) as int;
    final approved = (_stats['approved'] ?? 0) as int;
    final approvalRate = total > 0 ? ((approved / total) * 100).round() : 0;
    final appsCountStr = AppTranslations.formatDigits(_applications.length, lang);
    final rateStr = AppTranslations.formatDigits(approvalRate, lang);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 KPI Summary Widgets
          _buildStatsGrid(lang),

          const SizedBox(height: 16),

          // Search and Filters Bar
          _buildSearchAndFilters(lang),

          const SizedBox(height: 14),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Logged Applications: $appsCountStr',
                  mr: 'नोंदवलेले अर्ज: $appsCountStr',
                  hi: 'दर्ज आवेदन: $appsCountStr',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF475569)),
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Approval Rate: $rateStr%',
                      mr: 'मंजुरी दर: $rateStr%',
                      hi: 'स्वीकृति दर: $rateStr%',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A)),
                  ),
                  AppPdfButton.outlined(
                    label: AppTranslations.getDownloadReport(lang),
                    onPressed: () => VoterFormsReportGenerator.generateAndPrintReport(
                      applications: _applications,
                      lang: lang,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Applications List
          if (_isLoading)
            const AppShimmerList(count: 6)
          else if (_applications.isEmpty)
            _buildEmptyApplicationsState(lang)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _visibleApplications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildApplicationCard(_visibleApplications[index], lang),
            ),

          if (!_isLoading && _applications.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: _visibleApplications.length,
              totalCount: _applications.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(
                lang,
                en: 'applications',
                mr: 'अर्ज',
                hi: 'आवेदन',
              ),
              isMarathi: lang == 'mr',
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String lang) {
    final total = _stats['total'] ?? 0;
    final approved = _stats['approved'] ?? 0;
    final pending = _stats['pending'] ?? 0;
    final submitted = _stats['submitted'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 1.7 : 1.45,
          children: [
            _buildStatCard(
              AppTranslations.pick(lang, en: 'Total Applications', mr: 'एकूण अर्ज', hi: 'कुल आवेदन'),
              AppTranslations.formatDigits(total, lang),
              Icons.assignment_outlined,
              const Color(0xFF4F46E5),
              const Color(0xFFEEF2FF),
            ),
            _buildStatCard(
              AppTranslations.pick(lang, en: 'Approved', mr: 'मंजूर', hi: 'स्वीकृत'),
              AppTranslations.formatDigits(approved, lang),
              Icons.check_circle_outlined,
              const Color(0xFF10B981),
              const Color(0xFFECFDF5),
            ),
            _buildStatCard(
              AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित'),
              AppTranslations.formatDigits(pending, lang),
              Icons.hourglass_top_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            _buildStatCard(
              AppTranslations.pick(lang, en: 'Submitted', mr: 'दाखल', hi: 'जमा किए गए'),
              AppTranslations.formatDigits(submitted, lang),
              Icons.send_outlined,
              const Color(0xFF0284C7),
              const Color(0xFFF0F9FF),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    count,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => _loadApplications(),
            decoration: InputDecoration(
              hintText: AppTranslations.pick(
                lang,
                en: 'Search applicant name, mobile or notes...',
                mr: 'अर्जदाराचे नाव, मोबाईल किंवा नोंद शोधा...',
                hi: 'आवेदक नाम, मोबाइल या टिप्पणी खोजें...',
              ),
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadApplications();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filters Row
          Row(
            children: [
              // Status Filter Dropdown
              Expanded(
                child: AppDropdown<String>(
                  title: AppTranslations.pick(
                    lang,
                    en: 'Filter by Status',
                    mr: 'स्थितीनुसार निवडा',
                    hi: 'स्थिति से फ़िल्टर करें',
                  ),
                  value: _selectedStatus,
                  items: [
                    DropdownMenuItem(
                      value: 'All',
                      child: Text(AppTranslations.pick(lang, en: 'All Status', mr: 'सर्व स्थिती', hi: 'सभी स्थिति')),
                    ),
                    DropdownMenuItem(
                      value: 'Submitted',
                      child: Text(AppTranslations.pick(lang, en: 'Submitted', mr: 'दाखल', hi: 'जमा किया गया')),
                    ),
                    DropdownMenuItem(
                      value: 'Pending',
                      child: Text(AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित')),
                    ),
                    DropdownMenuItem(
                      value: 'Approved',
                      child: Text(AppTranslations.pick(lang, en: 'Approved', mr: 'मंजूर', hi: 'स्वीकृत')),
                    ),
                    DropdownMenuItem(
                      value: 'Rejected',
                      child: Text(AppTranslations.pick(lang, en: 'Rejected', mr: 'नाकारले', hi: 'अस्वीकृत')),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStatus = val);
                      _loadApplications();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Form Type Filter Dropdown
              Expanded(
                child: AppDropdown<String>(
                  title: AppTranslations.pick(
                    lang,
                    en: 'Filter by Form Type',
                    mr: 'अर्ज प्रकारानुसार निवडा',
                    hi: 'फॉर्म प्रकार से फ़िल्टर करें',
                  ),
                  value: _selectedFormType,
                  items: [
                    DropdownMenuItem(
                      value: 'All',
                      child: Text(AppTranslations.pick(lang, en: 'All Forms', mr: 'सर्व नमुने', hi: 'सभी फॉर्म')),
                    ),
                    DropdownMenuItem(
                      value: 'Form 6',
                      child: Text(AppTranslations.pick(lang, en: 'Form 6 (New)', mr: 'नमुना ६ (नवीन)', hi: 'फॉर्म ६ (नया)')),
                    ),
                    DropdownMenuItem(
                      value: 'Form 7',
                      child: Text(AppTranslations.pick(lang, en: 'Form 7 (Deletion)', mr: 'नमुना ७ (वगळणे)', hi: 'फॉर्म ७ (विलोपन)')),
                    ),
                    DropdownMenuItem(
                      value: 'Form 8',
                      child: Text(AppTranslations.pick(lang, en: 'Form 8 (Update)', mr: 'नमुना ८ (दुरुस्ती)', hi: 'फॉर्म ८ (अपडेट)')),
                    ),
                    DropdownMenuItem(
                      value: 'Search',
                      child: Text(AppTranslations.pick(lang, en: 'Roll Search', mr: 'यादी शोध', hi: 'सूची खोज')),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedFormType = val);
                      _loadApplications();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(VoterApplicationModel app, String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTranslatedText(
                      app.applicantName,
                      targetLanguage: lang,
                      isName: true,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    if (app.applicantMobile != null && app.applicantMobile!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            AppTranslations.formatDigits(app.applicantMobile!, lang),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: app.statusBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: app.statusBorderColor),
                    ),
                    child: Text(
                      app.statusLabel(lang),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: app.statusColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादन', hi: 'संपादित करें'),
                    onPressed: () => _openAddEditModal(app),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                    onPressed: () => _confirmDeleteApplication(app, lang),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Form Type Pill & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  app.formTypeLabel(lang),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
              ),
              Text(
                AppTranslations.formatDate(app.createdAt, lang, pattern: 'dd MMM yyyy'),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // Notes if present
          if (app.notes != null && app.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: AppTranslatedText(
                app.notes!,
                targetLanguage: lang,
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
              ),
            ),
          ],

          // Quick call actions if mobile present
          if (app.applicantMobile != null && app.applicantMobile!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(app.applicantMobile!),
                    icon: const Icon(Icons.phone, size: 13),
                    label: Text(
                      AppTranslations.pick(lang, en: 'Call', mr: 'कॉल', hi: 'कॉल'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWhatsApp(app.applicantMobile!),
                    icon: const Icon(Icons.chat_bubble_outline, size: 13),
                    label: Text(
                      AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सअॅप', hi: 'व्हाट्सऐप'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFFBBF7D0)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyApplicationsState(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_edu_rounded, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No applications found.',
              mr: 'कोणतेही अर्ज आढळले नाहीत.',
              hi: 'कोई आवेदन नहीं मिला।',
            ),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Change search filters or log a new application.',
              mr: 'शोध फिल्टर बदला किंवा नवीन अर्ज नोंदवा.',
              hi: 'खोज फ़िल्टर बदलें या नया आवेदन दर्ज करें।',
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openAddEditModal(),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              AppTranslations.pick(lang, en: 'Log Application', mr: 'अर्ज नोंदवा', hi: 'आवेदन दर्ज करें'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
