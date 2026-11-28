import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/voter_application_model.dart';
import '../../../../data/repositories/voter_applications_repository.dart';
import '../../../screens/voter_forms/voter_forms_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopVoterFormsView extends ConsumerStatefulWidget {
  const DesktopVoterFormsView({super.key});

  @override
  ConsumerState<DesktopVoterFormsView> createState() => _DesktopVoterFormsViewState();
}

class _DesktopVoterFormsViewState extends ConsumerState<DesktopVoterFormsView> {
  bool _loading = true;
  List<VoterApplicationModel> _applications = [];
  String _searchTerm = '';
  String _selectedStatus = 'All';
  String _selectedFormType = 'All';
  int _displayedLimit = 20;

  List<VoterApplicationModel> get _visibleApplications =>
      _applications.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(voterApplicationsRepoProvider);
      final list = await repo.getApplications(
        searchQuery: AppTranslations.normalizeAsciiDigits(_searchTerm),
        statusFilter: _selectedStatus,
        formTypeFilter: _selectedFormType,
      );
      if (mounted) {
        setState(() {
          _applications = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _applications = [];
          _loading = false;
        });
      }
    }
  }

  void _showAddModal({VoterApplicationModel? item}) {
    final nameController = TextEditingController(text: item?.applicantName ?? '');
    final mobileController = TextEditingController(text: item?.applicantMobile ?? '');
    final notesController = TextEditingController(text: item?.notes ?? '');
    String formType = item?.formType ?? 'Form 6';
    String status = item?.status ?? 'Submitted';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return ValueListenableBuilder<String>(
            valueListenable: appLanguageValueNotifier,
            builder: (ctx, lang, _) {
              return DesktopModalDialog(
                title: item == null
                    ? AppTranslations.pick(
                        lang,
                        en: 'New Voter Registration Form',
                        mr: 'नवीन मतदार नोंदणी अर्ज',
                        hi: 'नया मतदाता पंजीकरण फॉर्म',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Edit Form Details',
                        mr: 'अर्ज तपशील संपादित करा',
                        hi: 'फॉर्म विवरण संपादित करें',
                      ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Election Commission Forms 6, 7, 8 tracking and submission',
                  mr: 'निवडणूक आयोग फॉर्म ६, ७, ८ ट्रॅकिंग आणि नोंदणी',
                  hi: 'चुनाव आयोग फॉर्म ६, ७, ८ ट्रैकिंग और सबमिशन',
                ),
                icon: Icons.description_rounded,
                width: 600,
                onClose: () => Navigator.pop(ctx),
                actions: [
                  DesktopModalDialog.cancelButton(ctx),
                  const SizedBox(width: 12),
                  DesktopModalDialog.primaryButton(
                    text: item == null
                        ? AppTranslations.pick(
                            lang,
                            en: 'Save Form',
                            mr: 'अर्ज जतन करा',
                            hi: 'फॉर्म सहेजें',
                          )
                        : AppTranslations.pick(
                            lang,
                            en: 'Save Changes',
                            mr: 'बदल जतन करा',
                            hi: 'परिवर्तन सहेजें',
                          ),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final cleanMobile = AppTranslations.normalizeAsciiDigits(
                        mobileController.text.trim(),
                      );
                      final newApp = VoterApplicationModel(
                        id: item?.id ?? 'app-${DateTime.now().millisecondsSinceEpoch}',
                        applicantName: nameController.text.trim(),
                        applicantMobile: cleanMobile.isNotEmpty ? cleanMobile : null,
                        formType: formType,
                        status: status,
                        notes: notesController.text.trim(),
                        createdAt: item?.createdAt ?? DateTime.now(),
                      );

                      final repo = ref.read(voterApplicationsRepoProvider);
                      if (item == null) {
                        await repo.addApplication(newApp);
                      } else {
                        await repo.updateApplication(newApp);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchApplications();
                    },
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Applicant Name
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Applicant Name *',
                        mr: 'अर्जदाराचे नाव *',
                        hi: 'आवेदक का नाम *',
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. Sagar R. Shinde...',
                          mr: 'उदा. सागर रा. शिंदे...',
                          hi: 'जैसे सागर आर. शिंदे...',
                        ),
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mobile & Form Type
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Mobile Number',
                                  mr: 'मोबाईल नंबर',
                                  hi: 'मोबाइल नंबर',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mobileController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.formatDigits('98XXXXXXXX', lang),
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Form Type *',
                                  mr: 'अर्जाचा प्रकार *',
                                  hi: 'फॉर्म का प्रकार *',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              AppDropdown<String>(
                                value: formType,
                                height: 44,
                                backgroundColor: const Color(0xFFF8FAFC),
                                borderColor: const Color(0xFFE2E8F0),
                                items: [
                                  DropdownMenuItem(
                                    value: 'Form 6',
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Form 6 (New Voter)',
                                        mr: 'फॉर्म ६ (नवीन मतदार)',
                                        hi: 'फॉर्म ६ (नया मतदाता)',
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Form 7',
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Form 7 (Objection / Deletion)',
                                        mr: 'फॉर्म ७ (हरकत / नाव वगळणे)',
                                        hi: 'फॉर्म ७ (आपत्ति / नाम विलोपन)',
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Form 8',
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Form 8 (Correction)',
                                        mr: 'फॉर्म ८ (तपशील दुरुस्ती)',
                                        hi: 'फॉर्म ८ (विवरण सुधार)',
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Search',
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Search in Voter List',
                                        mr: 'मतदार यादीत शोध',
                                        hi: 'मतदाता सूची में खोजें',
                                      ),
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
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Application Status',
                        mr: 'अर्जाची स्थिती',
                        hi: 'आवेदन की स्थिति',
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: status,
                      height: 44,
                      backgroundColor: const Color(0xFFF8FAFC),
                      borderColor: const Color(0xFFE2E8F0),
                      items: [
                        DropdownMenuItem(
                          value: 'Submitted',
                          child: Text(AppTranslations.pick(lang, en: 'Submitted', mr: 'दाखल केला', hi: 'जमा किया गया')),
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
                          child: Text(AppTranslations.pick(lang, en: 'Rejected', mr: 'नाकारला', hi: 'अस्वीकृत')),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Reference No. & Notes',
                        mr: 'संदर्भ क्रमांक आणि नोंदी',
                        hi: 'संदर्भ संख्या और नोट्स',
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'ECI application reference no. or notes...',
                          mr: 'निवडणूक आयोग संदर्भ क्र. किंवा नोंदी...',
                          hi: 'ईसीआई आवेदन संदर्भ सं. या नोट्स...',
                        ),
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(VoterApplicationModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppTranslations.pick(
              lang,
              en: 'Delete Application',
              mr: 'अर्ज हटवा',
              hi: 'आवेदन हटाएं',
            ),
          ),
          content: AppTranslatedText(
            item.applicantName,
            isName: true,
            targetLanguage: lang,
            builder: (context, translatedName) => Text(
              AppTranslations.pick(
                lang,
                en: 'Are you sure you want to delete application for "$translatedName"?',
                mr: '"$translatedName" यांचा अर्ज हटवायचा आहे का?',
                hi: 'क्या आप वाकई "$translatedName" का आवेदन हटाना चाहते हैं?',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(voterApplicationsRepoProvider);
                await repo.deleteApplication(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchApplications();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: Text(
                AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(_applications.length, lang),
          const SizedBox(height: 20),

          // 4 Action Link Cards matching VoterForms.tsx
          _buildActionCards(lang),
          const SizedBox(height: 24),

          // Filter Row
          _buildFilterRow(lang),
          const SizedBox(height: 24),

          // Table / Grid of logged applications
          if (_loading)
            _buildLoadingState()
          else
            _buildApplicationsTable(_visibleApplications, lang),

          if (!_loading && _applications.isNotEmpty)
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
        ],
      ),
    );
  }

  Widget _buildHeader(int count, String lang) {
    final countStr = AppTranslations.formatDigits(count, lang);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 26, color: Color(0xFF0369A1)),
                  const SizedBox(width: 10),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Voter Forms',
                      mr: 'मतदार अर्ज',
                      hi: 'मतदाता फॉर्म',
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Total: $countStr',
                        mr: 'एकूण: $countStr',
                        hi: 'कुल: $countStr',
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Form 6 (New Voter), Form 7 (Deletion), Form 8 (Correction) and ECI application tracker',
                  mr: 'फॉर्म ६ (नवीन नोंदणी), फॉर्म ७ (वगळणे), फॉर्म ८ (दुरुस्ती) आणि निवडणूक आयोग अर्ज ट्रॅकर',
                  hi: 'फॉर्म ६ (नया मतदाता), फॉर्म ७ (विलोपन), फॉर्म ८ (सुधार) और ईसीआई आवेदन ट्रैकर',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions Row matching VoterForms.tsx
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                VoterFormsReportGenerator.generateAndPrintReport(
                  context: context,
                  applications: _applications,
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.getDownloadReport(lang),
                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),

            // Add Button
            ElevatedButton(
              onPressed: () => _showAddModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'New Application',
                      mr: 'नवीन अर्ज',
                      hi: 'नया आवेदन',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCards(String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildFormActionCard(
            title: AppTranslations.pick(lang, en: 'Search in Voter List', mr: 'मतदार यादीत शोध', hi: 'मतदाता सूची में खोज'),
            subtitle: AppTranslations.pick(lang, en: 'Electoral Search (ECI)', mr: 'मतदार शोध (ECI)', hi: 'मतदाता खोज (ECI)'),
            color: const Color(0xFFEA580C),
            bg: const Color(0xFFFFF7ED),
            icon: Icons.search_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildFormActionCard(
            title: AppTranslations.pick(lang, en: 'Form 6: New Registration', mr: 'फॉर्म ६: नवीन नोंदणी', hi: 'फॉर्म ६: नया पंजीकरण'),
            subtitle: AppTranslations.pick(lang, en: 'New Voter Registration', mr: 'नवीन मतदार नोंदणी', hi: 'नया मतदाता पंजीकरण'),
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFF0F9FF),
            icon: Icons.person_add_alt_1_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildFormActionCard(
            title: AppTranslations.pick(lang, en: 'Form 7: Objection / Deletion', mr: 'फॉर्म ७: हरकत / वगळणे', hi: 'फॉर्म ७: आपत्ति / विलोपन'),
            subtitle: AppTranslations.pick(lang, en: 'Deletion / Objection', mr: 'नाव वगळणे / हरकत', hi: 'नाम हटाना / आपत्ति'),
            color: const Color(0xFFDC2626),
            bg: const Color(0xFFFEF2F2),
            icon: Icons.person_remove_alt_1_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildFormActionCard(
            title: AppTranslations.pick(lang, en: 'Form 8: Correction of Entries', mr: 'फॉर्म ८: नोंदी दुरुस्ती', hi: 'फॉर्म ८: प्रविष्टि सुधार'),
            subtitle: AppTranslations.pick(lang, en: 'Modification / Shifting', mr: 'बदल / स्थलांतर', hi: 'संशोधन / स्थानांतरण'),
            color: const Color(0xFF16A34A),
            bg: const Color(0xFFF0FDF4),
            icon: Icons.how_to_reg_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildFormActionCard({
    required String title,
    required String subtitle,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildFilterRow(String lang) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) {
                _displayedLimit = 20;
                _searchTerm = val;
                _fetchApplications();
              },
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search applicant by name, mobile, reference no...',
                  mr: 'अर्जदाराचे नाव, मोबाईल, संदर्भ क्र. शोधा...',
                  hi: 'आवेदक का नाम, मोबाइल, संदर्भ सं. से खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Status Filter
        AppDropdown<String>(
          value: _selectedStatus,
          height: 40,
          width: 170,
          prefixIcon: const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF94A3B8)),
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          items: [
            DropdownMenuItem(
              value: 'All',
              child: Text(AppTranslations.pick(lang, en: 'All Status', mr: 'सर्व स्थिती', hi: 'सभी स्थिति')),
            ),
            DropdownMenuItem(
              value: 'Submitted',
              child: Text(AppTranslations.pick(lang, en: 'Submitted', mr: 'दाखल केला', hi: 'जमा किया गया')),
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
              child: Text(AppTranslations.pick(lang, en: 'Rejected', mr: 'नाकारला', hi: 'अस्वीकृत')),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _displayedLimit = 20;
                _selectedStatus = val;
              });
              _fetchApplications();
            }
          },
        ),
      ],
    );
  }

  Widget _buildApplicationsTable(List<VoterApplicationModel> items, String lang) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.description_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No applications found',
                mr: 'कोणतेही अर्ज सापडले नाहीत',
                hi: 'कोई आवेदन नहीं मिला',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columnSpacing: 24,
                horizontalMargin: 20,
                columns: [
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Applicant Name', mr: 'अर्जदाराचे नाव', hi: 'आवेदक का नाम'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Form Type', mr: 'अर्जाचा प्रकार', hi: 'फॉर्म प्रकार'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      AppTranslations.pick(lang, en: 'Actions', mr: 'कृती', hi: 'कार्रवाई'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
                rows: items.map((app) {
                  final formattedDate = AppTranslations.formatDate(app.createdAt, lang, pattern: 'dd/MM/yyyy');
                  final mobileStr = (app.applicantMobile != null && app.applicantMobile!.trim().isNotEmpty)
                      ? AppTranslations.formatDigits(app.applicantMobile!, lang)
                      : '-';

                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppTranslatedText(
                              app.applicantName,
                              isName: true,
                              targetLanguage: lang,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            if (app.notes != null && app.notes!.isNotEmpty)
                              AppTranslatedText(
                                app.notes!,
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                          ],
                        ),
                      ),
                      DataCell(Text(mobileStr, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(4)),
                          child: Text(app.formTypeLabel(lang), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: app.statusBgColor, borderRadius: BorderRadius.circular(100), border: Border.all(color: app.statusBorderColor)),
                          child: Text(app.statusLabel(lang), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: app.statusColor)),
                        ),
                      ),
                      DataCell(Text(formattedDate, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                              onPressed: () => _showAddModal(item: app),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                              tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                              onPressed: () => _showDeleteConfirm(app),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(height: 240, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2.5));
  }
}
