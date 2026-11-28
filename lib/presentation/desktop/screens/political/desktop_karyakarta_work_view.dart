<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/karyakarta_work_model.dart';
import '../../../../data/repositories/karyakarta_work_repository.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/karyakarta_work/karyakarta_work_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';
import '../../common/desktop_modal_dialog.dart';

class DesktopKaryakartaWorkView extends ConsumerStatefulWidget {
  const DesktopKaryakartaWorkView({super.key});

  @override
  ConsumerState<DesktopKaryakartaWorkView> createState() => _DesktopKaryakartaWorkViewState();
}

class _DesktopKaryakartaWorkViewState extends ConsumerState<DesktopKaryakartaWorkView> {
  bool _loading = true;
  List<KaryakartaStaffWorkload> _workloads = [];
  KaryakartaWorkloadSummary _summary = KaryakartaWorkloadSummary.empty();
  String _activeTab = 'Office'; // 'Office', 'Cooperative', 'Party'
  String _searchTerm = '';
  int _displayedLimit = 20;

  List<KaryakartaStaffWorkload> get _visibleWorkloads =>
      _workloads.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchWorkloads();
  }

  Future<void> _fetchWorkloads() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(karyakartaWorkRepoProvider);
      final normalizedQuery = AppTranslations.normalizeAsciiDigits(_searchTerm);
      final workloads = await repo.getStaffWorkloads(category: _activeTab, query: normalizedQuery);
      final summary = await repo.getSummaryStats(category: _activeTab);

      if (mounted) {
        setState(() {
          _workloads = workloads;
          _summary = summary;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _workloads = [];
          _loading = false;
        });
      }
    }
  }

  String _staffNameFor(KaryakartaWorkStaff staff, String lang) {
    if (lang == 'en' && staff.name.trim().isNotEmpty) {
      return staff.name.trim();
    }
    return staff.displayName;
  }

  String _tabLabel(String tabKey, String lang) {
    switch (tabKey) {
      case 'Party':
        return AppTranslations.pick(lang, en: 'Party Karyakarta', mr: 'पक्ष कार्यकर्ता', hi: 'पार्टी कार्यकर्ता');
      case 'Cooperative':
        return AppTranslations.pick(lang, en: 'Cooperative & Govt', mr: 'सहकारी व शासकीय', hi: 'सहकारी एवं सरकारी');
      case 'Office':
      default:
        return AppTranslations.pick(lang, en: 'Office Team', mr: 'कार्यालयीन टीम', hi: 'कार्यालय टीम');
    }
  }

  void _showQuickTaskModal(KaryakartaWorkStaff staff) {
    final initialLang = ref.read(desktopLanguageProvider);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final rawInitialArea = (staff.area != null && staff.area!.trim().isNotEmpty)
        ? staff.area!
        : 'Ward 12';
    final addressController = TextEditingController(
      text: AppTranslations.getAreaName(rawInitialArea, initialLang),
    );
    String priority = 'Medium';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => StatefulBuilder(
          builder: (ctx, setModalState) {
            return AppTranslatedText(
              _staffNameFor(staff, lang),
              isName: true,
              targetLanguage: lang,
              builder: (context, translatedStaffName) {
                return DesktopModalDialog(
                  title: AppTranslations.pick(
                    lang,
                    en: 'Assign Task: $translatedStaffName',
                    mr: 'काम सोपवा: $translatedStaffName',
                    hi: 'कार्य सौंपें: $translatedStaffName',
                  ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Assign field responsibilities and deadlines to karyakartas',
                    mr: 'कार्यकर्त्यांना क्षेत्रीय जबाबदाऱ्या आणि अंतिम मुदत नेमून द्या',
                    hi: 'कार्यकर्ताओं को क्षेत्रीय जिम्मेदारियाँ और समय-सीमा सौंपें',
                  ),
                  icon: Icons.assignment_ind_rounded,
                  width: 540,
                  onClose: () => Navigator.pop(ctx),
                  actions: [
                    DesktopModalDialog.cancelButton(ctx),
                    const SizedBox(width: 12),
                    DesktopModalDialog.primaryButton(
                      text: AppTranslations.pick(
                        lang,
                        en: 'Assign Task',
                        mr: 'काम सोपवा',
                        hi: 'कार्य सौंपें',
                      ),
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        final repo = ref.read(karyakartaWorkRepoProvider);
                        await repo.assignTask(
                          staffId: staff.id,
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          priority: priority,
                          address: addressController.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetchWorkloads();
                      },
                    ),
                  ],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Task Title *',
                          mr: 'कामाचे शीर्षक *',
                          hi: 'कार्य का शीर्षक *',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'e.g. Distribute ward scheme pamphlets...',
                            mr: 'उदा. प्रभाग योजना माहितीपत्रके वाटप करणे...',
                            hi: 'उदा. वार्ड योजना पंपलेट वितरित करना...',
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
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Priority',
                                    mr: 'प्राधान्य',
                                    hi: 'प्राथमिकता',
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 6),
                                AppDropdown<String>(
                                  value: priority,
                                  height: 44,
                                  backgroundColor: const Color(0xFFF8FAFC),
                                  borderColor: const Color(0xFFE2E8F0),
                                  items: [
                                    DropdownMenuItem(value: 'High', child: Text(AppTranslations.getPriority('High', lang))),
                                    DropdownMenuItem(value: 'Medium', child: Text(AppTranslations.getPriority('Medium', lang))),
                                    DropdownMenuItem(value: 'Low', child: Text(AppTranslations.getPriority('Low', lang))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => priority = val);
                                  },
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
                                    en: 'Location / Area',
                                    mr: 'ठिकाण / परिसर',
                                    hi: 'स्थान / क्षेत्र',
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: addressController,
                                  decoration: InputDecoration(
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
                        ],
                      ),
                      const SizedBox(height: 14),

                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Description',
                          mr: 'तपशील / वर्णन',
                          hi: 'विवरण',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'Detailed task description and instructions...',
                            mr: 'कामाचे सविस्तर वर्णन आणि सूचना...',
                            hi: 'कार्य का विस्तृत विवरण और निर्देश...',
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
          _buildHeader(lang),
          const SizedBox(height: 20),

          // Overview 4 Metric Cards
          _buildStatsRow(lang),
          const SizedBox(height: 24),

          // Tab Bar & Search
          _buildTabBar(lang),
          const SizedBox(height: 20),

          // Grid of Staff Workload Cards
          if (_loading)
            _buildLoadingGrid()
          else
            _buildWorkloadGrid(_visibleWorkloads, lang),

          if (!_loading && _workloads.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: _visibleWorkloads.length,
              totalCount: _workloads.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(lang, en: 'workers', mr: 'कार्यकर्ते', hi: 'कार्यकर्ता'),
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_ind_outlined, size: 26, color: Color(0xFF0369A1)),
                  const SizedBox(width: 10),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Karyakarta Work Management',
                      mr: 'कार्यकर्ता काम व्यवस्थापन',
                      hi: 'कार्यकर्ता कार्य प्रबंधन',
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Assign, monitor, and track daily tasks and complaint resolutions across ward teams',
                  mr: 'प्रभाग टीममधील दैनंदिन कामे आणि तक्रार निवारणाचे वाटप, देखरेख व मागोवा घ्या',
                  hi: 'वार्ड टीमों के बीच दैनिक कार्यों और शिकायत समाधान का आवंटन, निगरानी और ट्रैकिंग करें',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Download Report matching KaryakartaWorkManagement.tsx
        OutlinedButton.icon(
          onPressed: () {
            final allStaff = _workloads.map((w) => w.staff).toList();
            final allTasks = _workloads.expand((w) => w.tasks).toList();
            final allComplaints = _workloads.expand((w) => w.complaints).toList();
            KaryakartaWorkReportGenerator.generateAndPrintReport(
              context: context,
              staffList: allStaff,
              tasks: allTasks,
              complaints: allComplaints,
              activeTabLabel: _tabLabel(_activeTab, lang),
              categoryFilter: _activeTab,
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
      ],
    );
  }

  Widget _buildStatsRow(String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Total Assigned', mr: 'एकूण नेमलेली कामे', hi: 'कुल सौंपे गए कार्य'),
            AppTranslations.formatDigits(_summary.totalLoad, lang),
            Icons.assignment_outlined,
            const Color(0xFF475569),
            const Color(0xFFF1F5F9),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Pending Tasks', mr: 'प्रलंबित कामे', hi: 'लंबित कार्य'),
            AppTranslations.formatDigits(_summary.pendingLoad, lang),
            Icons.hourglass_empty_rounded,
            const Color(0xFFD97706),
            const Color(0xFFFFFBEB),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'In Progress', mr: 'सुरू असलेली कामे', hi: 'प्रगति पर'),
            AppTranslations.formatDigits(_summary.inProgressLoad, lang),
            Icons.pending_actions_rounded,
            const Color(0xFF0284C7),
            const Color(0xFFF0F9FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Completed', mr: 'पूर्ण झालेली कामे', hi: 'पूर्ण कार्य'),
            AppTranslations.formatDigits(_summary.completedLoad, lang),
            Icons.check_circle_outline_rounded,
            const Color(0xFF16A34A),
            const Color(0xFFF0FDF4),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(String lang) {
    final tabs = [
      {'key': 'Office', 'label': _tabLabel('Office', lang), 'icon': Icons.apartment_rounded},
      {'key': 'Party', 'label': _tabLabel('Party', lang), 'icon': Icons.flag_outlined},
      {'key': 'Cooperative', 'label': _tabLabel('Cooperative', lang), 'icon': Icons.business_outlined},
    ];

    return Row(
      children: [
        ...tabs.map((t) {
          final key = t['key'] as String;
          final label = t['label'] as String;
          final icon = t['icon'] as IconData;
          final isSelected = _activeTab == key;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTab = key;
                  _displayedLimit = 20;
                });
                _fetchWorkloads();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF475569))),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        SizedBox(
          width: 260,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                  _displayedLimit = 20;
                });
                _fetchWorkloads();
              },
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search karyakarta...',
                  mr: 'कार्यकर्ता शोधा...',
                  hi: 'कार्यकर्ता खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadGrid(List<KaryakartaStaffWorkload> workloads, String lang) {
    if (workloads.isEmpty) {
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
            const Icon(Icons.assignment_ind_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No karyakartas or staff found in this category',
                mr: 'या श्रेणीत कोणतेही कार्यकर्ते किंवा कर्मचारी आढळले नाहीत',
                hi: 'इस श्रेणी में कोई कार्यकर्ता या कर्मचारी नहीं मिला',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workloads.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) {
            final w = workloads[index];
            final staff = w.staff;
            final staffDisplay = _staffNameFor(staff, lang);
            final roleStr = AppTranslations.getRoleName(staff.role, lang);
            final rawArea = (staff.area != null && staff.area!.trim().isNotEmpty)
                ? staff.area!
                : 'Ward 12';
            final pctStr = AppTranslations.formatDigits('${w.progressPct}%', lang);
            final tPend = AppTranslations.formatDigits(w.tasksPending, lang);
            final tTotal = AppTranslations.formatDigits(w.tasksTotal, lang);
            final cPend = AppTranslations.formatDigits(w.complaintsPending, lang);
            final cTotal = AppTranslations.formatDigits(w.complaintsTotal, lang);
            final totalLoadStr = AppTranslations.formatDigits(w.totalAssigned, lang);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFF0F9FF),
                        child: AppTranslatedText(
                          staffDisplay,
                          isName: true,
                          targetLanguage: lang,
                          builder: (_, translatedName) {
                            final trimmed = translatedName.trim();
                            final initial = trimmed.isNotEmpty
                                ? trimmed[0].toUpperCase()
                                : AppTranslations.pick(lang, en: 'K', mr: 'का', hi: 'का');
                            return Text(
                              initial,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              staffDisplay,
                              isName: true,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            AppTranslatedText(
                              AppTranslations.getAreaName(rawArea, lang),
                              targetLanguage: lang,
                              builder: (_, translatedArea) => Text(
                                '$roleStr · $translatedArea',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(100)),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: '$pctStr Done',
                            mr: '$pctStr पूर्ण',
                            hi: '$pctStr पूर्ण',
                          ),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Work breakdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Tasks', mr: 'कामे', hi: 'कार्य'),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: '$tPend Pending / $tTotal',
                                  mr: '$tPend प्रलंबित / $tTotal',
                                  hi: '$tPend लंबित / $tTotal',
                                ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Complaints', mr: 'तक्रारी', hi: 'शिकायतें'),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: '$cPend Pending / $cTotal',
                                  mr: '$cPend प्रलंबित / $cTotal',
                                  hi: '$cPend लंबित / $cTotal',
                                ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: w.totalAssigned > 0 ? (w.totalCompleted / w.totalAssigned).clamp(0.0, 1.0) : 0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      minHeight: 6,
                    ),
                  ),

                  const Spacer(),

                  // Quick Action: Assign Task
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Workload: $totalLoadStr',
                          mr: 'कामाचा भार: $totalLoadStr',
                          hi: 'कार्यभार: $totalLoadStr',
                        ),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showQuickTaskModal(staff),
                        icon: const Icon(Icons.add_task_rounded, size: 14, color: Colors.white),
                        label: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Assign Task',
                            mr: 'काम सोपवा',
                            hi: 'कार्य सौंपें',
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 240,
          ),
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
=======
import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/karyakarta_work_model.dart';
import '../../../../data/repositories/karyakarta_work_repository.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/karyakarta_work/karyakarta_work_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';
import '../../common/desktop_modal_dialog.dart';

class DesktopKaryakartaWorkView extends ConsumerStatefulWidget {
  const DesktopKaryakartaWorkView({super.key});

  @override
  ConsumerState<DesktopKaryakartaWorkView> createState() => _DesktopKaryakartaWorkViewState();
}

class _DesktopKaryakartaWorkViewState extends ConsumerState<DesktopKaryakartaWorkView> {
  bool _loading = true;
  List<KaryakartaStaffWorkload> _workloads = [];
  KaryakartaWorkloadSummary _summary = KaryakartaWorkloadSummary.empty();
  String _activeTab = 'Office'; // 'Office', 'Cooperative', 'Party'
  String _searchTerm = '';
  int _displayedLimit = 20;

  List<KaryakartaStaffWorkload> get _visibleWorkloads =>
      _workloads.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchWorkloads();
  }

  Future<void> _fetchWorkloads() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(karyakartaWorkRepoProvider);
      final normalizedQuery = AppTranslations.normalizeAsciiDigits(_searchTerm);
      final workloads = await repo.getStaffWorkloads(category: _activeTab, query: normalizedQuery);
      final summary = await repo.getSummaryStats(category: _activeTab);

      if (mounted) {
        setState(() {
          _workloads = workloads;
          _summary = summary;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _workloads = [];
          _loading = false;
        });
      }
    }
  }

  String _staffNameFor(KaryakartaWorkStaff staff, String lang) {
    if (lang == 'en' && staff.name.trim().isNotEmpty) {
      return staff.name.trim();
    }
    return staff.displayName;
  }

  String _tabLabel(String tabKey, String lang) {
    switch (tabKey) {
      case 'Party':
        return AppTranslations.pick(lang, en: 'Party Karyakarta', mr: 'पक्ष कार्यकर्ता', hi: 'पार्टी कार्यकर्ता');
      case 'Cooperative':
        return AppTranslations.pick(lang, en: 'Cooperative & Govt', mr: 'सहकारी व शासकीय', hi: 'सहकारी एवं सरकारी');
      case 'Office':
      default:
        return AppTranslations.pick(lang, en: 'Office Team', mr: 'कार्यालयीन टीम', hi: 'कार्यालय टीम');
    }
  }

  void _showQuickTaskModal(KaryakartaWorkStaff staff) {
    final initialLang = ref.read(desktopLanguageProvider);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final rawInitialArea = (staff.area != null && staff.area!.trim().isNotEmpty)
        ? staff.area!
        : 'Ward 12';
    final addressController = TextEditingController(
      text: AppTranslations.getAreaName(rawInitialArea, initialLang),
    );
    String priority = 'Medium';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => StatefulBuilder(
          builder: (ctx, setModalState) {
            return AppTranslatedText(
              _staffNameFor(staff, lang),
              isName: true,
              targetLanguage: lang,
              builder: (context, translatedStaffName) {
                return DesktopModalDialog(
                  title: AppTranslations.pick(
                    lang,
                    en: 'Assign Task: $translatedStaffName',
                    mr: 'काम सोपवा: $translatedStaffName',
                    hi: 'कार्य सौंपें: $translatedStaffName',
                  ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Assign field responsibilities and deadlines to karyakartas',
                    mr: 'कार्यकर्त्यांना क्षेत्रीय जबाबदाऱ्या आणि अंतिम मुदत नेमून द्या',
                    hi: 'कार्यकर्ताओं को क्षेत्रीय जिम्मेदारियाँ और समय-सीमा सौंपें',
                  ),
                  icon: Icons.assignment_ind_rounded,
                  width: 540,
                  onClose: () => Navigator.pop(ctx),
                  actions: [
                    DesktopModalDialog.cancelButton(ctx),
                    const SizedBox(width: 12),
                    DesktopModalDialog.primaryButton(
                      text: AppTranslations.pick(
                        lang,
                        en: 'Assign Task',
                        mr: 'काम सोपवा',
                        hi: 'कार्य सौंपें',
                      ),
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        final repo = ref.read(karyakartaWorkRepoProvider);
                        await repo.assignTask(
                          staffId: staff.id,
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          priority: priority,
                          address: addressController.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetchWorkloads();
                      },
                    ),
                  ],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Task Title *',
                          mr: 'कामाचे शीर्षक *',
                          hi: 'कार्य का शीर्षक *',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'e.g. Distribute ward scheme pamphlets...',
                            mr: 'उदा. प्रभाग योजना माहितीपत्रके वाटप करणे...',
                            hi: 'उदा. वार्ड योजना पंपलेट वितरित करना...',
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
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Priority',
                                    mr: 'प्राधान्य',
                                    hi: 'प्राथमिकता',
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 6),
                                AppDropdown<String>(
                                  value: priority,
                                  height: 44,
                                  backgroundColor: const Color(0xFFF8FAFC),
                                  borderColor: const Color(0xFFE2E8F0),
                                  items: [
                                    DropdownMenuItem(value: 'High', child: Text(AppTranslations.getPriority('High', lang))),
                                    DropdownMenuItem(value: 'Medium', child: Text(AppTranslations.getPriority('Medium', lang))),
                                    DropdownMenuItem(value: 'Low', child: Text(AppTranslations.getPriority('Low', lang))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => priority = val);
                                  },
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
                                    en: 'Location / Area',
                                    mr: 'ठिकाण / परिसर',
                                    hi: 'स्थान / क्षेत्र',
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: addressController,
                                  decoration: InputDecoration(
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
                        ],
                      ),
                      const SizedBox(height: 14),

                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Description',
                          mr: 'तपशील / वर्णन',
                          hi: 'विवरण',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'Detailed task description and instructions...',
                            mr: 'कामाचे सविस्तर वर्णन आणि सूचना...',
                            hi: 'कार्य का विस्तृत विवरण और निर्देश...',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(lang),
          const SizedBox(height: 20),

          // Overview 4 Metric Cards
          _buildStatsRow(lang),
          const SizedBox(height: 24),

          // Tab Bar & Search
          _buildTabBar(lang),
          const SizedBox(height: 20),

          // Grid of Staff Workload Cards
          if (_loading)
            _buildLoadingGrid()
          else
            _buildWorkloadGrid(_visibleWorkloads, lang),

          if (!_loading && _workloads.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: _visibleWorkloads.length,
              totalCount: _workloads.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(lang, en: 'workers', mr: 'कार्यकर्ते', hi: 'कार्यकर्ता'),
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Karyakarta Work Management',
                  mr: 'कार्यकर्ता काम व्यवस्थापन',
                  hi: 'कार्यकर्ता कार्य प्रबंधन',
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Assign, monitor, and track daily tasks and complaint resolutions across ward teams',
                  mr: 'प्रभाग टीममधील दैनंदिन कामे आणि तक्रार निवारणाचे वाटप, देखरेख व मागोवा घ्या',
                  hi: 'वार्ड टीमों के बीच दैनिक कार्यों और शिकायत समाधान का आवंटन, निगरानी और ट्रैकिंग करें',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Download Report matching KaryakartaWorkManagement.tsx
        OutlinedButton.icon(
          onPressed: () {
            final allStaff = _workloads.map((w) => w.staff).toList();
            final allTasks = _workloads.expand((w) => w.tasks).toList();
            final allComplaints = _workloads.expand((w) => w.complaints).toList();
            KaryakartaWorkReportGenerator.generateAndPrintReport(
              context: context,
              staffList: allStaff,
              tasks: allTasks,
              complaints: allComplaints,
              activeTabLabel: _tabLabel(_activeTab, lang),
              categoryFilter: _activeTab,
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
      ],
    );
  }

  Widget _buildStatsRow(String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Total Assigned', mr: 'एकूण नेमलेली कामे', hi: 'कुल सौंपे गए कार्य'),
            AppTranslations.formatDigits(_summary.totalLoad, lang),
            Icons.assignment_outlined,
            const Color(0xFF475569),
            const Color(0xFFF1F5F9),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Pending Tasks', mr: 'प्रलंबित कामे', hi: 'लंबित कार्य'),
            AppTranslations.formatDigits(_summary.pendingLoad, lang),
            Icons.hourglass_empty_rounded,
            const Color(0xFFD97706),
            const Color(0xFFFFFBEB),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'In Progress', mr: 'सुरू असलेली कामे', hi: 'प्रगति पर'),
            AppTranslations.formatDigits(_summary.inProgressLoad, lang),
            Icons.pending_actions_rounded,
            const Color(0xFF0284C7),
            const Color(0xFFF0F9FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Completed', mr: 'पूर्ण झालेली कामे', hi: 'पूर्ण कार्य'),
            AppTranslations.formatDigits(_summary.completedLoad, lang),
            Icons.check_circle_outline_rounded,
            const Color(0xFF16A34A),
            const Color(0xFFF0FDF4),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(String lang) {
    final tabs = [
      {'key': 'Office', 'label': _tabLabel('Office', lang), 'icon': Icons.apartment_rounded},
      {'key': 'Party', 'label': _tabLabel('Party', lang), 'icon': Icons.flag_outlined},
      {'key': 'Cooperative', 'label': _tabLabel('Cooperative', lang), 'icon': Icons.business_outlined},
    ];

    return Row(
      children: [
        ...tabs.map((t) {
          final key = t['key'] as String;
          final label = t['label'] as String;
          final icon = t['icon'] as IconData;
          final isSelected = _activeTab == key;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTab = key;
                  _displayedLimit = 20;
                });
                _fetchWorkloads();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF475569))),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        SizedBox(
          width: 260,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                  _displayedLimit = 20;
                });
                _fetchWorkloads();
              },
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search karyakarta...',
                  mr: 'कार्यकर्ता शोधा...',
                  hi: 'कार्यकर्ता खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadGrid(List<KaryakartaStaffWorkload> workloads, String lang) {
    if (workloads.isEmpty) {
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
            const Icon(Icons.assignment_ind_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No karyakartas or staff found in this category',
                mr: 'या श्रेणीत कोणतेही कार्यकर्ते किंवा कर्मचारी आढळले नाहीत',
                hi: 'इस श्रेणी में कोई कार्यकर्ता या कर्मचारी नहीं मिला',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workloads.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) {
            final w = workloads[index];
            final staff = w.staff;
            final staffDisplay = _staffNameFor(staff, lang);
            final roleStr = AppTranslations.getRoleName(staff.role, lang);
            final rawArea = (staff.area != null && staff.area!.trim().isNotEmpty)
                ? staff.area!
                : 'Ward 12';
            final pctStr = AppTranslations.formatDigits('${w.progressPct}%', lang);
            final tPend = AppTranslations.formatDigits(w.tasksPending, lang);
            final tTotal = AppTranslations.formatDigits(w.tasksTotal, lang);
            final cPend = AppTranslations.formatDigits(w.complaintsPending, lang);
            final cTotal = AppTranslations.formatDigits(w.complaintsTotal, lang);
            final totalLoadStr = AppTranslations.formatDigits(w.totalAssigned, lang);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFF0F9FF),
                        child: AppTranslatedText(
                          staffDisplay,
                          isName: true,
                          targetLanguage: lang,
                          builder: (_, translatedName) {
                            final trimmed = translatedName.trim();
                            final initial = trimmed.isNotEmpty
                                ? trimmed[0].toUpperCase()
                                : AppTranslations.pick(lang, en: 'K', mr: 'का', hi: 'का');
                            return Text(
                              initial,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              staffDisplay,
                              isName: true,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            AppTranslatedText(
                              AppTranslations.getAreaName(rawArea, lang),
                              targetLanguage: lang,
                              builder: (_, translatedArea) => Text(
                                '$roleStr · $translatedArea',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(100)),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: '$pctStr Done',
                            mr: '$pctStr पूर्ण',
                            hi: '$pctStr पूर्ण',
                          ),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Work breakdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Tasks', mr: 'कामे', hi: 'कार्य'),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: '$tPend Pending / $tTotal',
                                  mr: '$tPend प्रलंबित / $tTotal',
                                  hi: '$tPend लंबित / $tTotal',
                                ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Complaints', mr: 'तक्रारी', hi: 'शिकायतें'),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: '$cPend Pending / $cTotal',
                                  mr: '$cPend प्रलंबित / $cTotal',
                                  hi: '$cPend लंबित / $cTotal',
                                ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: w.totalAssigned > 0 ? (w.totalCompleted / w.totalAssigned).clamp(0.0, 1.0) : 0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      minHeight: 6,
                    ),
                  ),

                  const Spacer(),

                  // Quick Action: Assign Task
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Workload: $totalLoadStr',
                          mr: 'कामाचा भार: $totalLoadStr',
                          hi: 'कार्यभार: $totalLoadStr',
                        ),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showQuickTaskModal(staff),
                        icon: const Icon(Icons.add_task_rounded, size: 14, color: Colors.white),
                        label: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Assign Task',
                            mr: 'काम सोपवा',
                            hi: 'कार्य सौंपें',
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 240,
          ),
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
>>>>>>> 17bec4832fa7973ec0a7a95e6bdb86fded9bbc1c
