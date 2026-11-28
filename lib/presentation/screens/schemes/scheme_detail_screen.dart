import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../../data/models/scheme_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/schemes_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import 'scheme_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class SchemeDetailScreen extends ConsumerStatefulWidget {
  final SchemeModel scheme;
  final VoidCallback? onSchemeUpdated;

  const SchemeDetailScreen({
    super.key,
    required this.scheme,
    this.onSchemeUpdated,
  });

  @override
  ConsumerState<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends ConsumerState<SchemeDetailScreen> {
  late SchemeModel _scheme;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scheme = widget.scheme;
  }

  String _categoryLabel(String categoryId, String lang) {
    switch (categoryId.trim().toLowerCase()) {
      case 'all':
        return AppTranslations.pick(lang, en: 'All', mr: 'सर्व', hi: 'सभी');
      case 'women':
        return AppTranslations.pick(lang, en: 'Women', mr: 'महिला', hi: 'महिला');
      case 'student':
        return AppTranslations.pick(lang, en: 'Student', mr: 'विद्यार्थी', hi: 'विद्यार्थी');
      case 'senior citizen':
        return AppTranslations.pick(lang, en: 'Senior Citizen', mr: 'ज्येष्ठ नागरिक', hi: 'वरिष्ठ नागरिक');
      case 'farmer':
        return AppTranslations.pick(lang, en: 'Farmer', mr: 'शेतकरी', hi: 'किसान');
      case 'health':
        return AppTranslations.pick(lang, en: 'Health', mr: 'आरोग्य', hi: 'स्वास्थ्य');
      case 'youth':
        return AppTranslations.pick(lang, en: 'Youth', mr: 'तरुण / युवक', hi: 'युवा');
      case 'housing':
        return AppTranslations.pick(lang, en: 'Housing', mr: 'घरकुल / आवास', hi: 'आवास');
      default:
        return categoryId;
    }
  }

  void _showApplyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _SchemeApplicationSheet(
        scheme: _scheme,
        onApplied: () {
          final lang = ref.read(appLanguageProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Application registered successfully!',
                  mr: 'अर्ज यशस्वीरित्या नोंदवला गेला!',
                  hi: 'आवेदन सफलतापूर्वक दर्ज किया गया!',
                ),
              ),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
          if (widget.onSchemeUpdated != null) widget.onSchemeUpdated!();
        },
      ),
    );
  }

  void _showEditSchemeSheet() {
    final lang = ref.read(appLanguageProvider);
    final nameCtrl = TextEditingController(text: _scheme.name);
    final descCtrl = TextEditingController(text: _scheme.description);
    final eligCtrl = TextEditingController(text: _scheme.eligibility);
    final benCtrl = TextEditingController(text: _scheme.benefits);
    final docCtrl = TextEditingController(text: _scheme.documents);
    String selectedCat = _scheme.category;

    final categories = ['All', 'Women', 'Student', 'Senior Citizen', 'Farmer', 'Health', 'Youth', 'Housing'];

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
                  AppModalHeader(
                    icon: Icons.edit_note_rounded,
                    title: AppTranslations.pick(lang, en: 'Edit Scheme Details', mr: 'योजनेचा तपशील सुधारा', hi: 'योजना विवरण संपादित करें'),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Update government scheme criteria and details',
                      mr: 'शासकीय योजनेचे निकष व तपशील अद्यतनित करा',
                      hi: 'सरकारी योजना के मानदंड और विवरण अपडेट करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 16,
                        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Scheme Name', mr: 'योजनेचे नाव', hi: 'योजना का नाम'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: nameCtrl,
                                    decoration: appInputDecoration(hint: AppTranslations.pick(lang, en: 'e.g. PM Awas Yojana', mr: 'उदा. प्रधानमंत्री आवास योजना', hi: 'उदा. प्रधानमंत्री आवास योजना')),
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
                                    value: categories.contains(selectedCat) ? selectedCat : 'All',
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
                        const SizedBox(height: 14),

                        // Benefits & Eligibility side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Benefits & Entitlements', mr: 'आर्थिक लाभ व अनुदान', hi: 'वित्तीय लाभ और पात्रता'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: benCtrl,
                                    maxLines: 2,
                                    decoration: appInputDecoration(
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Eligibility Criteria', mr: 'पात्रता अटी', hi: 'पात्रता मानदंड'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: eligCtrl,
                                    maxLines: 2,
                                    decoration: appInputDecoration(hint: AppTranslations.pick(lang, en: 'Income limit, age...', mr: 'उत्पन्न मर्यादा, वय...', hi: 'आय सीमा, आयु...')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Documents
                        AppFieldLabel(
                          label: AppTranslations.pick(lang, en: 'Required Documents Checklist', mr: 'आवश्यक कागदपत्रे', hi: 'आवश्यक दस्तावेज़ सूची'),
                          isRequired: true,
                        ),
                        TextField(
                          controller: docCtrl,
                          maxLines: 2,
                          decoration: appInputDecoration(hint: AppTranslations.pick(lang, en: 'Aadhaar, Ration card, Income proof...', mr: 'आधार कार्ड, रेशन कार्ड, उत्पन्न दाखला...', hi: 'आधार कार्ड, राशन कार्ड, आय प्रमाणपत्र...')),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        AppFieldLabel(
                          label: AppTranslations.pick(lang, en: 'Description & Objectives', mr: 'योजनेचा तपशील व उद्दिष्ट', hi: 'विवरण और उद्देश्य'),
                          isRequired: true,
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: appInputDecoration(hint: AppTranslations.pick(lang, en: 'Brief objective and overview...', mr: 'योजनेची संक्षिप्त उद्दिष्टे...', hi: 'योजना का संक्षिप्त विवरण...')),
                        ),
                        const SizedBox(height: 24),

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
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    final updated = _scheme.copyWith(
                                      name: nameCtrl.text.trim(),
                                      category: selectedCat,
                                      description: descCtrl.text.trim(),
                                      benefits: benCtrl.text.trim(),
                                      eligibility: eligCtrl.text.trim(),
                                      documents: docCtrl.text.trim(),
                                    );
                                    Navigator.pop(sheetCtx);
                                    setState(() {
                                      _scheme = updated;
                                      _isSaving = true;
                                    });
                                    await ref.read(schemesRepoProvider).updateScheme(updated);
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(AppTranslations.pick(lang, en: 'Scheme updated successfully!', mr: 'योजना माहिती अद्यतनित केली!', hi: 'योजना विवरण सफलतापूर्वक अपडेट किया गया!')),
                                          backgroundColor: const Color(0xFF16A34A),
                                        ),
                                      );
                                      if (widget.onSchemeUpdated != null) widget.onSchemeUpdated!();
                                    }
                                  },
                            child: Text(
                              AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'परिवर्तन सहेजें'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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

  void _confirmDelete() {
    final lang = ref.read(appLanguageProvider);
    final rawTitle = _scheme.localizedNameFor(lang);
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(AppTranslations.pick(lang, en: 'Delete Scheme?', mr: 'योजना हटवायची का?', hi: 'योजना हटाएँ?')),
        content: AppTranslatedText(
          rawTitle,
          targetLanguage: lang,
          builder: (_, translatedTitle) => Text(
            AppTranslations.pick(
              lang,
              en: 'Are you sure you want to delete "$translatedTitle"? This cannot be undone.',
              mr: 'तुम्हाला "$translatedTitle" ही योजना कायमची हटवायची आहे का? ही कृती पूर्ववत करता येणार नाही.',
              hi: 'क्या आप वाकई "$translatedTitle" को हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await ref.read(schemesRepoProvider).deleteScheme(_scheme.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppTranslations.pick(lang, en: 'Scheme deleted.', mr: 'योजना हटवली.', hi: 'योजना हटाई गई।'))),
                );
                if (widget.onSchemeUpdated != null) widget.onSchemeUpdated!();
                Navigator.pop(context);
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'पीछे'),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Text(
            AppTranslations.pick(lang, en: 'Scheme Details', mr: 'योजनेचा तपशील', hi: 'योजना विवरण'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AppPdfButton.icon(
                  tooltip: AppTranslations.pick(lang, en: 'Download Report', mr: 'अहवाल डाउनलोड करा', hi: 'रिपोर्ट डाउनलोड करें'),
                  onPressed: () {
                    SchemeReportGenerator.generateAndPrintSingleSchemeFlyer(
                      scheme: _scheme,
                      isMarathi: lang == 'mr',
                      lang: lang,
                    );
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
              tooltip: AppTranslations.pick(lang, en: 'Edit Scheme', mr: 'योजना संपादित करा', hi: 'योजना संपादित करें'),
              onPressed: _showEditSchemeSheet,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
              tooltip: AppTranslations.pick(lang, en: 'Delete Scheme', mr: 'योजना हटवा', hi: 'योजना हटाएँ'),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scheme Main Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _scheme.bgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _scheme.color.withValues(alpha: 0.3)),
                          ),
                          child: Icon(_scheme.icon, color: _scheme.color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _scheme.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: AppTranslatedText(
                                  _categoryLabel(_scheme.category, lang).toUpperCase(),
                                  targetLanguage: lang,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _scheme.color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppTranslatedText(
                                _scheme.localizedNameFor(lang),
                                targetLanguage: lang,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppTranslatedText(
                      _scheme.localizedDescriptionFor(lang),
                      targetLanguage: lang,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Benefits & Entitlements Box
              _DetailSectionCard(
                icon: Icons.stars_rounded,
                iconColor: const Color(0xFF16A34A),
                borderColor: const Color(0xFFBBF7D0),
                bgColor: const Color(0xFFF0FDF4),
                title: AppTranslations.pick(lang, en: 'Financial Benefits & Entitlements', mr: 'योजनेचे लाभ व अनुदान', hi: 'वित्तीय लाभ और पात्रता'),
                content: _scheme.localizedBenefitsFor(lang),
              ),

              const SizedBox(height: 14),

              // Eligibility Criteria Box
              _DetailSectionCard(
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF0284C7),
                borderColor: const Color(0xFFBAE6FD),
                bgColor: const Color(0xFFF0F9FF),
                title: AppTranslations.pick(lang, en: 'Eligibility Criteria', mr: 'पात्रता निकष', hi: 'पात्रता मानदंड'),
                content: _scheme.localizedEligibilityFor(lang),
              ),

              const SizedBox(height: 14),

              // Documents Required Box
              _DetailSectionCard(
                icon: Icons.checklist_rounded,
                iconColor: const Color(0xFFD97706),
                borderColor: const Color(0xFFFDE68A),
                bgColor: const Color(0xFFFFFBEB),
                title: AppTranslations.pick(lang, en: 'Required Documents Checklist', mr: 'आवश्यक कागदपत्रे', hi: 'आवश्यक दस्तावेज़ सूची'),
                content: _scheme.localizedDocumentsFor(lang),
              ),

              const SizedBox(height: 16),

              // Helpdesk & Ward Office Contact
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Color(0xFF0284C7), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Ward Office Citizen Helpdesk',
                              mr: 'नगरसेवक कार्यालय सहाय्यता कक्ष',
                              hi: 'वार्ड कार्यालय नागरिक सहायता केंद्र',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppTranslations.formatDigits(
                              AppTranslations.pick(
                                lang,
                                en: 'Ward 12 Office | Mon - Sat, 10:00 AM - 6:00 PM',
                                mr: 'प्रभाग 12 कार्यालय | सोमवार - शनिवार, स. 10 ते सायं. 6',
                                hi: 'वार्ड 12 कार्यालय | सोमवार - शनिवार, सुबह 10 से शाम 6 बजे',
                              ),
                              lang,
                            ),
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    SchemeReportGenerator.generateAndPrintSingleSchemeFlyer(
                      scheme: _scheme,
                      isMarathi: lang == 'mr',
                      lang: lang,
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    AppTranslations.pick(lang, en: 'Download Report', mr: 'अहवाल', hi: 'रिपोर्ट'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showApplyModal,
                  icon: const Icon(Icons.assignment_ind_rounded, size: 20),
                  label: Text(
                    AppTranslations.pick(lang, en: 'Apply for Citizen', mr: 'नागरिकाचा अर्ज भरा', hi: 'नागरिक आवेदन भरें'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final Color bgColor;
  final String title;
  final String content;

  const _DetailSectionCard({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.bgColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // Split bullet points if text contains commas or bullet markers
    final lines = content.split(RegExp(r'[,;]|\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (lines.length > 1)
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: AppTranslatedText(
                        line,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AppTranslatedText(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _SchemeApplicationSheet extends ConsumerStatefulWidget {
  final SchemeModel scheme;
  final VoidCallback onApplied;

  const _SchemeApplicationSheet({
    required this.scheme,
    required this.onApplied,
  });

  @override
  ConsumerState<_SchemeApplicationSheet> createState() => _SchemeApplicationSheetState();
}

class _SchemeApplicationSheetState extends ConsumerState<_SchemeApplicationSheet> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _benefitCtrl = TextEditingController();
  int? _selectedVoterId;
  bool _isSubmitting = false;

  void _openVoterPicker() {
    final voterSearchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            final lang = ref.watch(appLanguageProvider);
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  AppModalHeader(
                    icon: Icons.person_search_rounded,
                    title: AppTranslations.pick(lang, en: 'Select Citizen / Voter', mr: 'नागरिक / मतदार निवडा', hi: 'नागरिक / मतदाता चुनें'),
                    subtitle: AppTranslations.pick(lang, en: 'Search and link voter to scheme', mr: 'मतदार शोधून योजनेशी जोडा', hi: 'मतदाता खोजकर योजना से जोड़ें'),
                    onClose: () => Navigator.pop(bCtx),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: voterSearchCtrl,
                      decoration: appInputDecoration(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'Search voter by name or EPIC ID...',
                          mr: 'नाव किंवा EPIC क्रमांकाने शोधा...',
                          hi: 'नाम या EPIC नंबर से खोजें...',
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<VoterModel>>(
                      future: ref.read(votersRepoProvider).searchVoters(
                            query: voterSearchCtrl.text.trim().isNotEmpty ? voterSearchCtrl.text.trim() : null,
                            pageSize: 40,
                          ),
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final voters = snapshot.data ?? [];
                        if (voters.isEmpty) {
                          return Center(
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'No voters found in database',
                                mr: 'डेटाबेसमध्ये कोणतेही मतदार सापडले नाहीत',
                                hi: 'डेटाबेस में कोई मतदाता नहीं मिला',
                              ),
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: voters.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final v = voters[idx];
                            final vName = lang == 'en'
                                ? (v.nameEnglish.isNotEmpty ? v.nameEnglish : v.nameMarathi)
                                : (v.nameMarathi.isNotEmpty ? v.nameMarathi : v.nameEnglish);
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF0F9FF),
                                child: AppTranslatedText(
                                  vName.isNotEmpty ? vName : 'V',
                                  isName: true,
                                  targetLanguage: lang,
                                  builder: (_, tName) => Text(
                                    tName.trim().isNotEmpty ? tName.trim()[0].toUpperCase() : 'V',
                                    style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              title: AppTranslatedText(
                                vName,
                                isName: true,
                                targetLanguage: lang,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Row(
                                children: [
                                  if (v.epicNo.isNotEmpty)
                                    Text(
                                      AppTranslations.formatDigits('EPIC: ${v.epicNo} | ', lang),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  Expanded(
                                    child: AppTranslatedText(
                                      v.address,
                                      targetLanguage: lang,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0284C7)),
                              onTap: () {
                                Navigator.pop(bCtx);
                                setState(() {
                                  _nameCtrl.text = vName;
                                  if (v.mobile != null && v.mobile!.isNotEmpty) {
                                    _mobileCtrl.text = v.mobile!;
                                  }
                                  if (v.address.isNotEmpty) {
                                    _addressCtrl.text = v.address;
                                  }
                                  _selectedVoterId = int.tryParse(v.id);
                                });
                              },
                            );
                          },
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final rawSchemeTitle = widget.scheme.localizedNameFor(lang);
    final subtitleScheme = DynamicTranslationService.getCachedTranslation(rawSchemeTitle, lang) ??
        rawSchemeTitle;

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
          AppModalHeader(
            icon: Icons.person_add_alt_1_rounded,
            title: AppTranslations.pick(lang, en: 'Citizen Scheme Application', mr: 'नागरिक योजना अर्ज', hi: 'नागरिक योजना आवेदन'),
            subtitle: subtitleScheme,
            onClose: () => Navigator.pop(context),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                // Applicant Name & Mobile Number side-by-side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppFieldLabel(
                            label: AppTranslations.pick(lang, en: 'Applicant Name', mr: 'अर्जदाराचे नाव', hi: 'आवेदक का नाम'),
                            isRequired: true,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(lang, en: 'Enter full name...', mr: 'पूर्ण नाव प्रविष्ट करा...', hi: 'पूरा नाम दर्ज करें...'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _openVoterPicker,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBAE6FD)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_search_rounded, size: 16, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 3),
                                      Text(
                                        AppTranslations.pick(lang, en: 'Voters', mr: 'मतदार', hi: 'मतदाता'),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                          AppFieldLabel(
                            label: AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                            isRequired: true,
                          ),
                          TextField(
                            controller: _mobileCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            decoration: appInputDecoration(
                              prefixText: AppTranslations.formatDigits('+91 ', lang),
                              hint: AppTranslations.formatDigits('98xxxxxxxx', lang),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Residential Address & Expected Benefit side-by-side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppFieldLabel(
                            label: AppTranslations.pick(lang, en: 'Address / Prabhag Area', mr: 'पत्ता / प्रभाग क्षेत्र', hi: 'पता / वार्ड क्षेत्र'),
                            isRequired: true,
                          ),
                          TextField(
                            controller: _addressCtrl,
                            decoration: appInputDecoration(
                              hint: AppTranslations.pick(lang, en: 'House no, lane, prabhag area...', mr: 'घर क्र., लेन, प्रभाग...', hi: 'मकान नं., गली, वार्ड...'),
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
                          AppFieldLabel(
                            label: AppTranslations.pick(lang, en: 'Expected Benefit / Note', mr: 'अपेक्षित लाभ / मंजुरी टीप', hi: 'अपेक्षित लाभ / टिप्पणी'),
                          ),
                          TextField(
                            controller: _benefitCtrl,
                            decoration: appInputDecoration(
                              hint: AppTranslations.formatDigits(
                                AppTranslations.pick(lang, en: 'e.g. ₹1,500/month...', mr: 'उदा. ₹1,500/महिना...', hi: 'उदा. ₹1,500/माह...'),
                                lang,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Officer Remarks / Follow-up notes
                AppFieldLabel(
                  label: AppTranslations.pick(lang, en: 'Officer / Office Notes', mr: 'अधिकारी / कार्यालयीन टीप', hi: 'अधिकारी / कार्यालय नोट'),
                ),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: appInputDecoration(
                    hint: AppTranslations.pick(lang, en: 'Documents verified, verification token...', mr: 'कागदपत्रे तपासली, टोकन क्रमांक...', hi: 'दस्तावेज़ सत्यापित, टोकन क्रमांक...'),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
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
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (_nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(lang, en: 'Please enter applicant name', mr: 'कृपया अर्जदाराचे नाव प्रविष्ट करा', hi: 'कृपया आवेदक का नाम दर्ज करें'),
                                  ),
                                ),
                              );
                              return;
                            }
                            if (_mobileCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(lang, en: 'Please enter applicant mobile number', mr: 'कृपया मोबाईल नंबर प्रविष्ट करा', hi: 'कृपया आवेदक का मोबाइल नंबर दर्ज करें'),
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() => _isSubmitting = true);
                            final nav = Navigator.of(context);
                            final app = SchemeApplicationModel(
                              id: 0,
                              schemeId: widget.scheme.id,
                              schemeName: widget.scheme.name,
                              voterId: _selectedVoterId,
                              applicantName: _nameCtrl.text.trim(),
                              mobile: _mobileCtrl.text.trim(),
                              address: _addressCtrl.text.trim(),
                              status: 'Pending',
                              benefit: _benefitCtrl.text.trim().isNotEmpty ? _benefitCtrl.text.trim() : null,
                              notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                              createdAt: DateTime.now(),
                            );

                            await ref.read(schemesRepoProvider).createApplication(app);
                            if (!mounted) return;
                            setState(() => _isSubmitting = false);
                            nav.pop();
                            widget.onApplied();
                          },
                    child: _isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            AppTranslations.pick(lang, en: 'Submit Application', mr: 'अर्ज सादर करा', hi: 'आवेदन जमा करें'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

