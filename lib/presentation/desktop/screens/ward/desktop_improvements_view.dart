<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/improvement_model.dart';
import '../../../../data/repositories/improvements_repository.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/ward_improvements/improvement_detail_screen.dart';
import '../../../screens/ward_improvements/improvement_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';
import '../../common/desktop_modal_dialog.dart';

class DesktopImprovementsView extends ConsumerStatefulWidget {
  const DesktopImprovementsView({super.key});

  @override
  ConsumerState<DesktopImprovementsView> createState() => _DesktopImprovementsViewState();
}

class _DesktopImprovementsViewState extends ConsumerState<DesktopImprovementsView> {
  bool _loading = true;
  List<ImprovementModel> _improvements = [];
  String _searchTerm = '';
  String _selectedArea = 'All';
  String _selectedDate = 'All';
  String _statusFilter = 'All'; // 'All' | 'Pending' | 'Planned' | 'In Progress' | 'Complete'
  String _viewMode = 'grid'; // 'grid' | 'table'
  int _displayedLimit = 20;

  List<ImprovementModel> get _visibleImprovements =>
      _filteredImprovements.take(_displayedLimit).toList();

  List<String> get _uniqueAreas {
    final areas = _improvements
        .map((i) => i.area.trim())
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...areas];
  }

  List<String> get _uniqueDates {
    final dates = _improvements
        .map((i) => _canonicalDateKey(i.createdAt))
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return ['All', ...dates];
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final repo = ref.read(improvementsRepoProvider);
      final list = await repo.getImprovements();
      if (mounted) {
        setState(() {
          _improvements = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _improvements = [];
          _loading = false;
        });
      }
    }
  }

  String _canonicalDateKey(String raw) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw.trim();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(String raw, String lang) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      return AppTranslations.formatDate(dt, lang, pattern: 'MMM d, yyyy');
    }
    return AppTranslations.formatDigits(raw, lang);
  }

  String _localizedStatus(String status, String lang) {
    switch (status.toLowerCase()) {
      case 'complete':
      case 'completed':
        return AppTranslations.pick(lang, en: 'Complete', mr: 'पूर्ण झाले', hi: 'पूर्ण हुआ');
      case 'in progress':
      case 'inprogress':
        return AppTranslations.pick(lang, en: 'In Progress', mr: 'प्रगतीपथावर', hi: 'प्रगति पर');
      case 'planned':
        return AppTranslations.pick(lang, en: 'Planned', mr: 'नियोजित', hi: 'नियोजित');
      case 'pending':
      default:
        return AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित');
    }
  }

  List<ImprovementModel> get _filteredImprovements {
    final q = AppTranslations.normalizeAsciiDigits(_searchTerm.trim()).toLowerCase();
    return _improvements.where((item) {
      final matchesSearch = q.isEmpty ||
          AppTranslations.normalizeAsciiDigits(item.title).toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(item.description).toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(item.location).toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(item.area).toLowerCase().contains(q);

      final matchesArea = _selectedArea == 'All' ||
          item.area.toLowerCase().trim() == _selectedArea.toLowerCase().trim();

      final matchesDate = _selectedDate == 'All' ||
          _canonicalDateKey(item.createdAt) == _selectedDate;

      final matchesStatus = _statusFilter == 'All' || item.status == _statusFilter;

      return matchesSearch && matchesArea && matchesDate && matchesStatus;
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'All') return _improvements.length;
    return _improvements.where((i) => i.status == status).length;
  }

  Future<void> _handleVote(ImprovementModel item) async {
    final lang = ref.read(desktopLanguageProvider);
    final repo = ref.read(improvementsRepoProvider);
    final newVotes = await repo.voteImprovement(item.id);
    if (mounted) {
      setState(() {
        _improvements = _improvements.map((imp) {
          if (imp.id == item.id) {
            return imp.copyWith(votes: newVotes);
          }
          return imp;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Vote registered successfully!',
              mr: 'मत यशस्वीरित्या नोंदवले!',
              hi: 'वोट सफलतापूर्वक दर्ज किया गया!',
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  void _showAddModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final areaController = TextEditingController(text: 'Ward 12');
    final peopleController = TextEditingController();
    String selectedStatus = 'Pending';
    bool isGeneratingAI = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final lang = modalRef.watch(desktopLanguageProvider);
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return DesktopModalDialog(
                title: AppTranslations.pick(
                  lang,
                  en: 'Suggest Ward Improvement',
                  mr: 'प्रभाग सुधारणा सुचवा',
                  hi: 'वार्ड सुधार का सुझाव दें',
                ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Civic suggestions, road works, and infrastructural proposals',
                  mr: 'नागरी सूचना, रस्ते कामे आणि पायाभूत सुविधा प्रस्ताव',
                  hi: 'नागरिक सुझाव, सड़क कार्य और बुनियादी ढांचा प्रस्ताव',
                ),
                icon: Icons.lightbulb_outline_rounded,
                width: 600,
                onClose: () => Navigator.pop(ctx),
                actions: [
                  DesktopModalDialog.cancelButton(ctx),
                  const SizedBox(width: 12),
                  DesktopModalDialog.primaryButton(
                    text: AppTranslations.pick(
                      lang,
                      en: 'Submit Improvement',
                      mr: 'सुधारणा सबमिट करा',
                      hi: 'सुधार सबमिट करें',
                    ),
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final newImp = ImprovementModel(
                        id: 'imp-${DateTime.now().millisecondsSinceEpoch}',
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        location: locationController.text.trim().isEmpty ? 'Ward 12' : locationController.text.trim(),
                        area: areaController.text.trim().isEmpty ? 'Ward 12' : areaController.text.trim(),
                        status: selectedStatus,
                        peopleBenefited: int.tryParse(
                          AppTranslations.normalizeAsciiDigits(peopleController.text.trim()),
                        ),
                        createdAt: DateTime.now().toIso8601String(),
                      );

                      final repo = ref.read(improvementsRepoProvider);
                      await repo.addImprovement(newImp);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchData();
                    },
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Improvement Title *',
                        mr: 'सुधारणेचे शीर्षक *',
                        hi: 'सुधार शीर्षक *',
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. Install open gym equipment in garden...',
                          mr: 'उदा. उद्यानात ओपन जिम उपकरणे बसवणे...',
                          hi: 'उदा. उद्यान में ओपन जिम उपकरण लगाना...',
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

                    // Description + AI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.pick(lang, en: 'Description *', mr: 'वर्णन *', hi: 'विवरण *'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        TextButton.icon(
                          onPressed: isGeneratingAI || titleController.text.trim().isEmpty
                              ? null
                              : () async {
                                  setModalState(() => isGeneratingAI = true);
                                  await Future.delayed(const Duration(milliseconds: 600));
                                  final topic = titleController.text.trim();
                                  descController.text = AppTranslations.pick(
                                    lang,
                                    en: 'Under $topic, community infrastructure will improve significantly for citizens.',
                                    mr: '$topic अंतर्गत नागरिकांसाठी सामुदायिक पायाभूत सुविधांमध्ये लक्षणीय सुधारणा होईल.',
                                    hi: '$topic के अंतर्गत नागरिकों के लिए सामुदायिक बुनियादी ढांचे में उल्लेखनीय सुधार होगा।',
                                  );
                                  setModalState(() => isGeneratingAI = false);
                                },
                          icon: isGeneratingAI
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF0284C7)),
                          label: Text(
                            isGeneratingAI
                                ? AppTranslations.pick(lang, en: 'Generating...', mr: 'तयार करत आहे...', hi: 'तैयार हो रहा है...')
                                : AppTranslations.pick(lang, en: 'Auto-Generate (AI)', mr: 'AI ने तयार करा', hi: 'AI से तैयार करें'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Provide details about the suggested improvement...',
                          mr: 'सुचवलेल्या सुधारणेचा तपशील द्या...',
                          hi: 'सुझाए गए सुधार का विवरण दें...',
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

                    // Location & Area
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Location *', mr: 'ठिकाण *', hi: 'स्थान *'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: locationController,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Public Garden',
                                    mr: 'उदा. सार्वजनिक उद्यान',
                                    hi: 'उदा. सार्वजनिक उद्यान',
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
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Ward / Area', mr: 'प्रभाग / परिसर', hi: 'वार्ड / क्षेत्र'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaController,
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
                    const SizedBox(height: 16),

                    // Status & People Benefited
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              AppDropdown<String>(
                                value: selectedStatus,
                                height: 44,
                                backgroundColor: const Color(0xFFF8FAFC),
                                borderColor: const Color(0xFFE2E8F0),
                                items: [
                                  DropdownMenuItem(value: 'Pending', child: Text(_localizedStatus('Pending', lang))),
                                  DropdownMenuItem(value: 'Planned', child: Text(_localizedStatus('Planned', lang))),
                                  DropdownMenuItem(value: 'In Progress', child: Text(_localizedStatus('In Progress', lang))),
                                  DropdownMenuItem(value: 'Complete', child: Text(_localizedStatus('Complete', lang))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedStatus = val);
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
                                  en: 'Estimated Beneficiaries',
                                  mr: 'अंदाजे लाभार्थी',
                                  hi: 'अनुमानित लाभार्थी',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: peopleController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(lang, en: 'e.g. 500', mr: 'उदा. ५००', hi: 'उदा. ५००'),
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
                      ],
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredImprovements;
    final visible = _visibleImprovements;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(lang),
          const SizedBox(height: 16),

          // Search Filters
          _buildFilterRow(lang),
          const SizedBox(height: 16),

          // Status Tabs
          _buildStatusTabs(lang),
          const SizedBox(height: 24),

          // Content
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildReportTable(visible, lang)
          else
            _buildCardGrid(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(lang, en: 'improvements', mr: 'सुधारणा', hi: 'सुधार'),
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
                  const Icon(Icons.trending_up_rounded, size: 26, color: Color(0xFF0369A1)),
                  const SizedBox(width: 10),
                  Text(
                    AppTranslations.getNavTitle('improvements', lang),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Track civic improvement proposals and public suggestions',
                  mr: 'नागरी सुधारणा प्रस्ताव आणि सार्वजनिक सूचनांचा मागोवा घ्या',
                  hi: 'नागरिक सुधार प्रस्तावों और सार्वजनिक सुझावों को ट्रैक करें',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions: Download Report + Propose Improvement
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ImprovementReportGenerator.generateAndPrintImprovementReport(
                  context: context,
                  improvements: _filteredImprovements,
                  statusFilter: _statusFilter,
                  areaFilter: _selectedArea,
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

            // Propose New Button (ns-btn-primary matching PossibleImprovements.tsx)
            ElevatedButton(
              onPressed: _showAddModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7), // bg-brand-600
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // rounded-xl
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white), // Plus w-4 h-4
                  const SizedBox(width: 8), // gap-2
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Propose Improvement',
                      mr: 'सुधारणा सुचवा',
                      hi: 'सुधार का सुझाव दें',
                    ),
                    style: const TextStyle(
                      fontSize: 14, // text-sm
                      fontWeight: FontWeight.w600, // font-semibold
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

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String lang) {
    return Row(
      children: [
        // Main Search (Col 6)
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _searchTerm = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search improvement, location, topic...',
                  mr: 'सुधारणा, ठिकाण, विषय शोधा...',
                  hi: 'सुधार, स्थान, विषय खोजें...',
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

        // Area Filter (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedArea,
            height: 44,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueAreas.map((area) {
              final label = area == 'All'
                  ? AppTranslations.getAllAreas(lang)
                  : AppTranslations.getAreaName(area, lang);
              return DropdownMenuItem(
                value: area,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedArea = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 14),

        // Date Filter (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedDate,
            height: 44,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueDates.map((date) {
              final label = date == 'All'
                  ? AppTranslations.pick(lang, en: 'All Dates', mr: 'सर्व तारखा', hi: 'सभी तिथियां')
                  : _formatDate(date, lang);
              return DropdownMenuItem(
                value: date,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDate = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs(String lang) {
    final tabs = [
      {'key': 'All', 'label': AppTranslations.getAll(lang)},
      {'key': 'Pending', 'label': _localizedStatus('Pending', lang)},
      {'key': 'Planned', 'label': _localizedStatus('Planned', lang)},
      {'key': 'In Progress', 'label': _localizedStatus('In Progress', lang)},
      {'key': 'Complete', 'label': _localizedStatus('Complete', lang)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tabs.map((tab) {
              final key = tab['key']!;
              final label = tab['label']!;
              final isSelected = _statusFilter == key;
              final count = AppTranslations.formatDigits(_countForStatus(key), lang);

              return InkWell(
                onTap: () => setState(() {
                  _statusFilter = key;
                  _displayedLimit = 20;
                }),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isSelected
                        ? const [BoxShadow(color: Color(0x200284C7), blurRadius: 4, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          count,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildViewToggleButton(
                icon: Icons.grid_view_rounded,
                label: AppTranslations.pick(lang, en: 'Grid', mr: 'ग्रिड', hi: 'ग्रिड'),
                isActive: _viewMode == 'grid',
                onTap: () => setState(() => _viewMode = 'grid'),
              ),
              const SizedBox(width: 4),
              _buildViewToggleButton(
                icon: Icons.table_rows_rounded,
                label: AppTranslations.pick(lang, en: 'Table', mr: 'तक्ता', hi: 'तालिका'),
                isActive: _viewMode == 'table',
                onTap: () => setState(() => _viewMode = 'table'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<ImprovementModel> items, String lang) {
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
            const Icon(Icons.lightbulb_outline, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No improvements found',
                mr: 'कोणत्याही सुधारणा आढळल्या नाहीत',
                hi: 'कोई सुधार नहीं मिला',
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
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 290,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final areaLabel = item.area.isNotEmpty
                ? AppTranslations.getAreaName(item.area, lang)
                : '';
            final locDisplay = areaLabel.isNotEmpty
                ? '${item.location}, $areaLabel'
                : item.location;

            return InkWell(
              onTap: () {
                Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ImprovementDetailScreen(improvement: item),
                  ),
                ).then((res) {
                  if (res == true) _fetchData(showLoading: false);
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Status pill + Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusBadge(item.status, lang),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(_formatDate(item.createdAt, lang), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        AppTranslatedText(
                          item.title,
                          targetLanguage: lang,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Expanded(
                          child: AppTranslatedText(
                            item.description,
                            targetLanguage: lang,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ),

                        // Bottom Meta info
                        Container(
                          padding: const EdgeInsets.only(top: 10),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: AppTranslatedText(
                                      locDisplay,
                                      targetLanguage: lang,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (item.peopleBenefited != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.group_outlined, size: 13, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: '${AppTranslations.formatDigits(item.peopleBenefited, lang)} Beneficiaries',
                                            mr: '${AppTranslations.formatDigits(item.peopleBenefited, lang)} लाभार्थी',
                                            hi: '${AppTranslations.formatDigits(item.peopleBenefited, lang)} लाभार्थी',
                                          ),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                        ),
                                      ],
                                    )
                                  else
                                    const SizedBox.shrink(),

                                  // Upvote button
                                  InkWell(
                                    onTap: () => _handleVote(item),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Tooltip(
                                      message: AppTranslations.pick(lang, en: 'Upvote', mr: 'मत द्या', hi: 'वोट दें'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.thumb_up_alt_outlined, size: 13, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 6),
                                            Text(
                                              AppTranslations.formatDigits(item.votes, lang),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Subtle Watermark Lightbulb in top right
                  Positioned(
                    top: 14,
                    right: 14,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.04,
                        child: Icon(Icons.lightbulb, size: 70, color: Colors.blueGrey.shade800),
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

  Widget _buildStatusBadge(String status, String lang) {
    Color bg;
    Color text;
    Color border;

    if (status == 'Complete') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF15803D);
      border = const Color(0xFFBBF7D0);
    } else if (status == 'In Progress') {
      bg = const Color(0xFFF0F9FF);
      text = const Color(0xFF0369A1);
      border = const Color(0xFFBAE6FD);
    } else if (status == 'Planned') {
      bg = const Color(0xFFFAF5FF);
      text = const Color(0xFF7E22CE);
      border = const Color(0xFFE9D5FF);
    } else {
      bg = const Color(0xFFFFF7ED);
      text = const Color(0xFFC2410C);
      border = const Color(0xFFFED7AA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        _localizedStatus(status, lang),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildReportTable(List<ImprovementModel> items, String lang) {
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
            const Icon(Icons.lightbulb_outline, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No improvements found',
                mr: 'कोणत्याही सुधारणा आढळल्या नाहीत',
                hi: 'कोई सुधार नहीं मिला',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: [
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Sr No', mr: 'अ.क्र.', hi: 'क्र. सं.'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Improvement Title', mr: 'सुधारणेचे शीर्षक', hi: 'सुधार शीर्षक'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Location & Area', mr: 'ठिकाण आणि परिसर', hi: 'स्थान और क्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Votes', mr: 'मते', hi: 'वोट'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            ],
            rows: List.generate(items.length, (index) {
              final item = items[index];
              final areaText = AppTranslations.getAreaName(item.area, lang);
              return DataRow(
                cells: [
                  DataCell(Text(AppTranslations.formatDigits(index + 1, lang), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppTranslatedText(item.title, targetLanguage: lang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        AppTranslatedText(item.description, targetLanguage: lang, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  DataCell(AppTranslatedText('${item.location} ($areaText)', targetLanguage: lang, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                  DataCell(_buildStatusBadge(item.status, lang)),
                  DataCell(Text(_formatDate(item.createdAt, lang), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                  DataCell(Text(AppTranslations.formatDigits(item.votes, lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                ],
              );
            }),
          ),
        ),
      ),
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
            mainAxisExtent: 260,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
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
import '../../../../data/models/improvement_model.dart';
import '../../../../data/repositories/improvements_repository.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/ward_improvements/improvement_detail_screen.dart';
import '../../../screens/ward_improvements/improvement_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';
import '../../common/desktop_modal_dialog.dart';

class DesktopImprovementsView extends ConsumerStatefulWidget {
  const DesktopImprovementsView({super.key});

  @override
  ConsumerState<DesktopImprovementsView> createState() => _DesktopImprovementsViewState();
}

class _DesktopImprovementsViewState extends ConsumerState<DesktopImprovementsView> {
  bool _loading = true;
  List<ImprovementModel> _improvements = [];
  String _searchTerm = '';
  String _selectedArea = 'All';
  String _selectedDate = 'All';
  String _statusFilter = 'All'; // 'All' | 'Pending' | 'Planned' | 'In Progress' | 'Complete'
  String _viewMode = 'grid'; // 'grid' | 'table'
  int _displayedLimit = 20;

  List<ImprovementModel> get _visibleImprovements =>
      _filteredImprovements.take(_displayedLimit).toList();

  List<String> get _uniqueAreas {
    final areas = _improvements
        .map((i) => i.area.trim())
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...areas];
  }

  List<String> get _uniqueDates {
    final dates = _improvements
        .map((i) => _canonicalDateKey(i.createdAt))
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return ['All', ...dates];
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final repo = ref.read(improvementsRepoProvider);
      final list = await repo.getImprovements();
      if (mounted) {
        setState(() {
          _improvements = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _improvements = [];
          _loading = false;
        });
      }
    }
  }

  String _canonicalDateKey(String raw) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw.trim();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(String raw, String lang) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      return AppTranslations.formatDate(dt, lang, pattern: 'MMM d, yyyy');
    }
    return AppTranslations.formatDigits(raw, lang);
  }

  String _localizedStatus(String status, String lang) {
    switch (status.toLowerCase()) {
      case 'complete':
      case 'completed':
        return AppTranslations.pick(lang, en: 'Complete', mr: 'पूर्ण झाले', hi: 'पूर्ण हुआ');
      case 'in progress':
      case 'inprogress':
        return AppTranslations.pick(lang, en: 'In Progress', mr: 'प्रगतीपथावर', hi: 'प्रगति पर');
      case 'planned':
        return AppTranslations.pick(lang, en: 'Planned', mr: 'नियोजित', hi: 'नियोजित');
      case 'pending':
      default:
        return AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित');
    }
  }

  List<ImprovementModel> get _filteredImprovements {
    final q = AppTranslations.normalizeAsciiDigits(_searchTerm.trim()).toLowerCase();
    return _improvements.where((item) {
      final matchesSearch = q.isEmpty ||
          AppTranslations.normalizeAsciiDigits(item.title).toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(item.description).toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(item.location).toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(item.area).toLowerCase().contains(q);

      final matchesArea = _selectedArea == 'All' ||
          item.area.toLowerCase().trim() == _selectedArea.toLowerCase().trim();

      final matchesDate = _selectedDate == 'All' ||
          _canonicalDateKey(item.createdAt) == _selectedDate;

      final matchesStatus = _statusFilter == 'All' || item.status == _statusFilter;

      return matchesSearch && matchesArea && matchesDate && matchesStatus;
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'All') return _improvements.length;
    return _improvements.where((i) => i.status == status).length;
  }

  Future<void> _handleVote(ImprovementModel item) async {
    final lang = ref.read(desktopLanguageProvider);
    final repo = ref.read(improvementsRepoProvider);
    final newVotes = await repo.voteImprovement(item.id);
    if (mounted) {
      setState(() {
        _improvements = _improvements.map((imp) {
          if (imp.id == item.id) {
            return imp.copyWith(votes: newVotes);
          }
          return imp;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Vote registered successfully!',
              mr: 'मत यशस्वीरित्या नोंदवले!',
              hi: 'वोट सफलतापूर्वक दर्ज किया गया!',
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  void _showAddModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final areaController = TextEditingController(text: 'Ward 12');
    final peopleController = TextEditingController();
    String selectedStatus = 'Pending';
    bool isGeneratingAI = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final lang = modalRef.watch(desktopLanguageProvider);
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return DesktopModalDialog(
                title: AppTranslations.pick(
                  lang,
                  en: 'Suggest Ward Improvement',
                  mr: 'प्रभाग सुधारणा सुचवा',
                  hi: 'वार्ड सुधार का सुझाव दें',
                ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Civic suggestions, road works, and infrastructural proposals',
                  mr: 'नागरी सूचना, रस्ते कामे आणि पायाभूत सुविधा प्रस्ताव',
                  hi: 'नागरिक सुझाव, सड़क कार्य और बुनियादी ढांचा प्रस्ताव',
                ),
                icon: Icons.lightbulb_outline_rounded,
                width: 600,
                onClose: () => Navigator.pop(ctx),
                actions: [
                  DesktopModalDialog.cancelButton(ctx),
                  const SizedBox(width: 12),
                  DesktopModalDialog.primaryButton(
                    text: AppTranslations.pick(
                      lang,
                      en: 'Submit Improvement',
                      mr: 'सुधारणा सबमिट करा',
                      hi: 'सुधार सबमिट करें',
                    ),
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final newImp = ImprovementModel(
                        id: 'imp-${DateTime.now().millisecondsSinceEpoch}',
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        location: locationController.text.trim().isEmpty ? 'Ward 12' : locationController.text.trim(),
                        area: areaController.text.trim().isEmpty ? 'Ward 12' : areaController.text.trim(),
                        status: selectedStatus,
                        peopleBenefited: int.tryParse(
                          AppTranslations.normalizeAsciiDigits(peopleController.text.trim()),
                        ),
                        createdAt: DateTime.now().toIso8601String(),
                      );

                      final repo = ref.read(improvementsRepoProvider);
                      await repo.addImprovement(newImp);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchData();
                    },
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Improvement Title *',
                        mr: 'सुधारणेचे शीर्षक *',
                        hi: 'सुधार शीर्षक *',
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. Install open gym equipment in garden...',
                          mr: 'उदा. उद्यानात ओपन जिम उपकरणे बसवणे...',
                          hi: 'उदा. उद्यान में ओपन जिम उपकरण लगाना...',
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

                    // Description + AI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.pick(lang, en: 'Description *', mr: 'वर्णन *', hi: 'विवरण *'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        TextButton.icon(
                          onPressed: isGeneratingAI || titleController.text.trim().isEmpty
                              ? null
                              : () async {
                                  setModalState(() => isGeneratingAI = true);
                                  await Future.delayed(const Duration(milliseconds: 600));
                                  final topic = titleController.text.trim();
                                  descController.text = AppTranslations.pick(
                                    lang,
                                    en: 'Under $topic, community infrastructure will improve significantly for citizens.',
                                    mr: '$topic अंतर्गत नागरिकांसाठी सामुदायिक पायाभूत सुविधांमध्ये लक्षणीय सुधारणा होईल.',
                                    hi: '$topic के अंतर्गत नागरिकों के लिए सामुदायिक बुनियादी ढांचे में उल्लेखनीय सुधार होगा।',
                                  );
                                  setModalState(() => isGeneratingAI = false);
                                },
                          icon: isGeneratingAI
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF0284C7)),
                          label: Text(
                            isGeneratingAI
                                ? AppTranslations.pick(lang, en: 'Generating...', mr: 'तयार करत आहे...', hi: 'तैयार हो रहा है...')
                                : AppTranslations.pick(lang, en: 'Auto-Generate (AI)', mr: 'AI ने तयार करा', hi: 'AI से तैयार करें'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Provide details about the suggested improvement...',
                          mr: 'सुचवलेल्या सुधारणेचा तपशील द्या...',
                          hi: 'सुझाए गए सुधार का विवरण दें...',
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

                    // Location & Area
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Location *', mr: 'ठिकाण *', hi: 'स्थान *'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: locationController,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Public Garden',
                                    mr: 'उदा. सार्वजनिक उद्यान',
                                    hi: 'उदा. सार्वजनिक उद्यान',
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
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Ward / Area', mr: 'प्रभाग / परिसर', hi: 'वार्ड / क्षेत्र'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaController,
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
                    const SizedBox(height: 16),

                    // Status & People Benefited
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              AppDropdown<String>(
                                value: selectedStatus,
                                height: 44,
                                backgroundColor: const Color(0xFFF8FAFC),
                                borderColor: const Color(0xFFE2E8F0),
                                items: [
                                  DropdownMenuItem(value: 'Pending', child: Text(_localizedStatus('Pending', lang))),
                                  DropdownMenuItem(value: 'Planned', child: Text(_localizedStatus('Planned', lang))),
                                  DropdownMenuItem(value: 'In Progress', child: Text(_localizedStatus('In Progress', lang))),
                                  DropdownMenuItem(value: 'Complete', child: Text(_localizedStatus('Complete', lang))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedStatus = val);
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
                                  en: 'Estimated Beneficiaries',
                                  mr: 'अंदाजे लाभार्थी',
                                  hi: 'अनुमानित लाभार्थी',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: peopleController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(lang, en: 'e.g. 500', mr: 'उदा. ५००', hi: 'उदा. ५००'),
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
                      ],
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredImprovements;
    final visible = _visibleImprovements;

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(lang),
          const SizedBox(height: 16),

          // Search Filters
          _buildFilterRow(lang),
          const SizedBox(height: 16),

          // Status Tabs
          _buildStatusTabs(lang),
          const SizedBox(height: 24),

          // Content
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildReportTable(visible, lang)
          else
            _buildCardGrid(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(lang, en: 'improvements', mr: 'सुधारणा', hi: 'सुधार'),
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
                AppTranslations.getNavTitle('improvements', lang),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Track civic improvement proposals and public suggestions',
                  mr: 'नागरी सुधारणा प्रस्ताव आणि सार्वजनिक सूचनांचा मागोवा घ्या',
                  hi: 'नागरिक सुधार प्रस्तावों और सार्वजनिक सुझावों को ट्रैक करें',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions: Download Report + Propose Improvement
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ImprovementReportGenerator.generateAndPrintImprovementReport(
                  context: context,
                  improvements: _filteredImprovements,
                  statusFilter: _statusFilter,
                  areaFilter: _selectedArea,
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

            // Propose New Button (ns-btn-primary matching PossibleImprovements.tsx)
            ElevatedButton(
              onPressed: _showAddModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7), // bg-brand-600
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // rounded-xl
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white), // Plus w-4 h-4
                  const SizedBox(width: 8), // gap-2
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Propose Improvement',
                      mr: 'सुधारणा सुचवा',
                      hi: 'सुधार का सुझाव दें',
                    ),
                    style: const TextStyle(
                      fontSize: 14, // text-sm
                      fontWeight: FontWeight.w600, // font-semibold
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

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String lang) {
    return Row(
      children: [
        // Main Search (Col 6)
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _searchTerm = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search improvement, location, topic...',
                  mr: 'सुधारणा, ठिकाण, विषय शोधा...',
                  hi: 'सुधार, स्थान, विषय खोजें...',
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

        // Area Filter (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedArea,
            height: 44,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueAreas.map((area) {
              final label = area == 'All'
                  ? AppTranslations.getAllAreas(lang)
                  : AppTranslations.getAreaName(area, lang);
              return DropdownMenuItem(
                value: area,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedArea = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 14),

        // Date Filter (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedDate,
            height: 44,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueDates.map((date) {
              final label = date == 'All'
                  ? AppTranslations.pick(lang, en: 'All Dates', mr: 'सर्व तारखा', hi: 'सभी तिथियां')
                  : _formatDate(date, lang);
              return DropdownMenuItem(
                value: date,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDate = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs(String lang) {
    final tabs = [
      {'key': 'All', 'label': AppTranslations.getAll(lang)},
      {'key': 'Pending', 'label': _localizedStatus('Pending', lang)},
      {'key': 'Planned', 'label': _localizedStatus('Planned', lang)},
      {'key': 'In Progress', 'label': _localizedStatus('In Progress', lang)},
      {'key': 'Complete', 'label': _localizedStatus('Complete', lang)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tabs.map((tab) {
              final key = tab['key']!;
              final label = tab['label']!;
              final isSelected = _statusFilter == key;
              final count = AppTranslations.formatDigits(_countForStatus(key), lang);

              return InkWell(
                onTap: () => setState(() {
                  _statusFilter = key;
                  _displayedLimit = 20;
                }),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isSelected
                        ? const [BoxShadow(color: Color(0x200284C7), blurRadius: 4, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          count,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildViewToggleButton(
                icon: Icons.grid_view_rounded,
                label: AppTranslations.pick(lang, en: 'Grid', mr: 'ग्रिड', hi: 'ग्रिड'),
                isActive: _viewMode == 'grid',
                onTap: () => setState(() => _viewMode = 'grid'),
              ),
              const SizedBox(width: 4),
              _buildViewToggleButton(
                icon: Icons.table_rows_rounded,
                label: AppTranslations.pick(lang, en: 'Table', mr: 'तक्ता', hi: 'तालिका'),
                isActive: _viewMode == 'table',
                onTap: () => setState(() => _viewMode = 'table'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<ImprovementModel> items, String lang) {
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
            const Icon(Icons.lightbulb_outline, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No improvements found',
                mr: 'कोणत्याही सुधारणा आढळल्या नाहीत',
                hi: 'कोई सुधार नहीं मिला',
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
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 290,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final areaLabel = item.area.isNotEmpty
                ? AppTranslations.getAreaName(item.area, lang)
                : '';
            final locDisplay = areaLabel.isNotEmpty
                ? '${item.location}, $areaLabel'
                : item.location;

            return InkWell(
              onTap: () {
                Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ImprovementDetailScreen(improvement: item),
                  ),
                ).then((res) {
                  if (res == true) _fetchData(showLoading: false);
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Status pill + Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusBadge(item.status, lang),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(_formatDate(item.createdAt, lang), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        AppTranslatedText(
                          item.title,
                          targetLanguage: lang,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Expanded(
                          child: AppTranslatedText(
                            item.description,
                            targetLanguage: lang,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ),

                        // Bottom Meta info
                        Container(
                          padding: const EdgeInsets.only(top: 10),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: AppTranslatedText(
                                      locDisplay,
                                      targetLanguage: lang,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (item.peopleBenefited != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.group_outlined, size: 13, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: '${AppTranslations.formatDigits(item.peopleBenefited, lang)} Beneficiaries',
                                            mr: '${AppTranslations.formatDigits(item.peopleBenefited, lang)} लाभार्थी',
                                            hi: '${AppTranslations.formatDigits(item.peopleBenefited, lang)} लाभार्थी',
                                          ),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                        ),
                                      ],
                                    )
                                  else
                                    const SizedBox.shrink(),

                                  // Upvote button
                                  InkWell(
                                    onTap: () => _handleVote(item),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Tooltip(
                                      message: AppTranslations.pick(lang, en: 'Upvote', mr: 'मत द्या', hi: 'वोट दें'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.thumb_up_alt_outlined, size: 13, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 6),
                                            Text(
                                              AppTranslations.formatDigits(item.votes, lang),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Subtle Watermark Lightbulb in top right
                  Positioned(
                    top: 14,
                    right: 14,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.04,
                        child: Icon(Icons.lightbulb, size: 70, color: Colors.blueGrey.shade800),
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

  Widget _buildStatusBadge(String status, String lang) {
    Color bg;
    Color text;
    Color border;

    if (status == 'Complete') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF15803D);
      border = const Color(0xFFBBF7D0);
    } else if (status == 'In Progress') {
      bg = const Color(0xFFF0F9FF);
      text = const Color(0xFF0369A1);
      border = const Color(0xFFBAE6FD);
    } else if (status == 'Planned') {
      bg = const Color(0xFFFAF5FF);
      text = const Color(0xFF7E22CE);
      border = const Color(0xFFE9D5FF);
    } else {
      bg = const Color(0xFFFFF7ED);
      text = const Color(0xFFC2410C);
      border = const Color(0xFFFED7AA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        _localizedStatus(status, lang),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildReportTable(List<ImprovementModel> items, String lang) {
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
            const Icon(Icons.lightbulb_outline, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No improvements found',
                mr: 'कोणत्याही सुधारणा आढळल्या नाहीत',
                hi: 'कोई सुधार नहीं मिला',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: [
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Sr No', mr: 'अ.क्र.', hi: 'क्र. सं.'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Improvement Title', mr: 'सुधारणेचे शीर्षक', hi: 'सुधार शीर्षक'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Location & Area', mr: 'ठिकाण आणि परिसर', hi: 'स्थान और क्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Votes', mr: 'मते', hi: 'वोट'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            ],
            rows: List.generate(items.length, (index) {
              final item = items[index];
              final areaText = AppTranslations.getAreaName(item.area, lang);
              return DataRow(
                cells: [
                  DataCell(Text(AppTranslations.formatDigits(index + 1, lang), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppTranslatedText(item.title, targetLanguage: lang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        AppTranslatedText(item.description, targetLanguage: lang, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  DataCell(AppTranslatedText('${item.location} ($areaText)', targetLanguage: lang, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                  DataCell(_buildStatusBadge(item.status, lang)),
                  DataCell(Text(_formatDate(item.createdAt, lang), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                  DataCell(Text(AppTranslations.formatDigits(item.votes, lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                ],
              );
            }),
          ),
        ),
      ),
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
            mainAxisExtent: 260,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
>>>>>>> 17bec4832fa7973ec0a7a95e6bdb86fded9bbc1c
