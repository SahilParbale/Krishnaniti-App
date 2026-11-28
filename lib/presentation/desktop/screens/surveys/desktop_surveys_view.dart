import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/survey_model.dart';
import '../../../../data/repositories/surveys_repository.dart';
import '../../../screens/surveys/survey_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopSurveysView extends ConsumerStatefulWidget {
  const DesktopSurveysView({super.key});

  @override
  ConsumerState<DesktopSurveysView> createState() => _DesktopSurveysViewState();
}

class _DesktopSurveysViewState extends ConsumerState<DesktopSurveysView> {
  bool _loading = true;
  List<SurveyModel> _surveys = [];
  String _searchTerm = '';
  String _areaFilter = 'All';
  List<String> _availableAreas = [];
  int _totalResponses = 0;
  int _displayedLimit = 20;

  List<SurveyModel> get _visibleSurveys =>
      _filteredSurveys.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchSurveys();
  }

  Future<void> _fetchSurveys() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(surveysRepoProvider);
      final list = await repo.getSurveys();
      final stats = await repo.getStats();

      if (mounted) {
        final areas = list.map((s) => s.area ?? '').where((a) => a.isNotEmpty).toSet().toList();
        setState(() {
          _surveys = list;
          _availableAreas = ['All', ...areas];
          _totalResponses = stats['totalResponses'] ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _surveys = [];
          _loading = false;
        });
      }
    }
  }

  List<SurveyModel> get _filteredSurveys {
    final q = AppTranslations.normalizeAsciiDigits(_searchTerm).toLowerCase().trim();
    return _surveys.where((s) {
      final matchesSearch = q.isEmpty ||
          AppTranslations.normalizeAsciiDigits(s.title).toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(s.description).toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(s.area ?? '').toLowerCase().contains(q);

      final matchesArea = _areaFilter == 'All' || (s.area ?? '').toLowerCase() == _areaFilter.toLowerCase();

      return matchesSearch && matchesArea;
    }).toList();
  }

  void _showAddSurveyModal({SurveyModel? item}) {
    final initialLang = ref.read(desktopLanguageProvider);
    final titleController = TextEditingController(text: item?.title ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final areaController = TextEditingController(text: item?.area ?? 'Ward 12');
    final sampleSizeController = TextEditingController(
      text: AppTranslations.formatDigits((item?.targetSampleSize ?? 100).toString(), initialLang),
    );
    String status = item?.status ?? 'Active';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => StatefulBuilder(
          builder: (ctx, setModalState) {
            return DesktopModalDialog(
              title: item == null
                  ? AppTranslations.pick(
                      lang,
                      en: 'Create New Survey',
                      mr: 'नवीन सर्व्हे तयार करा',
                      hi: 'नया सर्वेक्षण बनाएं',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Edit Survey Details',
                      mr: 'सर्व्हे तपशील संपादित करा',
                      hi: 'सर्वेक्षण विवरण संपादित करें',
                    ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Design opinion polls and ward feedback questionnaires',
                mr: 'जनमत चाचणी आणि प्रभाग अभिप्राय प्रश्नावली तयार करा',
                hi: 'जनमत सर्वेक्षण और वार्ड प्रतिक्रिया प्रश्नावली तैयार करें',
              ),
              icon: Icons.poll_rounded,
              width: 600,
              onClose: () => Navigator.pop(ctx),
              actions: [
                DesktopModalDialog.cancelButton(ctx),
                const SizedBox(width: 12),
                DesktopModalDialog.primaryButton(
                  text: item == null
                      ? AppTranslations.pick(
                          lang,
                          en: 'Create Survey',
                          mr: 'सर्व्हे तयार करा',
                          hi: 'सर्वेक्षण बनाएं',
                        )
                      : AppTranslations.pick(
                          lang,
                          en: 'Save Changes',
                          mr: 'बदल जतन करा',
                          hi: 'परिवर्तन सहेजें',
                        ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final parsedSample = int.tryParse(
                          AppTranslations.normalizeAsciiDigits(sampleSizeController.text.trim()),
                        ) ??
                        100;
                    final newSurvey = SurveyModel(
                      id: item?.id ?? 'srv-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      area: areaController.text.trim(),
                      targetSampleSize: parsedSample,
                      status: status,
                      questions: item?.questions ?? const [],
                      createdAt: item?.createdAt ?? DateTime.now(),
                    );

                    final repo = ref.read(surveysRepoProvider);
                    if (item == null) {
                      await repo.addSurvey(newSurvey);
                    } else {
                      await repo.updateSurvey(newSurvey);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchSurveys();
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
                      en: 'Survey Title *',
                      mr: 'सर्व्हेचे शीर्षक *',
                      hi: 'सर्वेक्षण शीर्षक *',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Ward 12 Sanitation & Waste Management Survey...',
                        mr: 'उदा. प्रभाग १२ स्वच्छता आणि कचरा व्यवस्थापन सर्व्हे...',
                        hi: 'उदा. वार्ड १२ स्वच्छता एवं अपशिष्ट प्रबंधन सर्वेक्षण...',
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

                  // Area & Sample Size
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Ward / Area',
                                mr: 'प्रभाग / परिसर',
                                hi: 'वार्ड / क्षेत्र',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: areaController,
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Ward 12',
                                  mr: 'उदा. प्रभाग १२',
                                  hi: 'उदा. वार्ड १२',
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
                              AppTranslations.pick(
                                lang,
                                en: 'Target Sample Size',
                                mr: 'लक्ष्य नमुना संख्या',
                                hi: 'लक्ष्य नमूना आकार',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: sampleSizeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: AppTranslations.formatDigits('100', lang),
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
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Description',
                      mr: 'वर्णन',
                      hi: 'विवरण',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Objectives and questions outline...',
                        mr: 'उद्दिष्टे आणि प्रश्नांची रूपरेषा...',
                        hi: 'उद्देश्य और प्रश्नों की रूपरेखा...',
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
        ),
      ),
    );
  }

  void _showDeleteConfirm(SurveyModel item) {
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
              en: 'Delete Survey',
              mr: 'सर्व्हे हटवा',
              hi: 'सर्वेक्षण हटाएं',
            ),
          ),
          content: AppTranslatedText(
            item.title,
            targetLanguage: lang,
            builder: (ctx, translatedTitle) => Text(
              AppTranslations.pick(
                lang,
                en: 'Are you sure you want to delete "$translatedTitle"?',
                mr: 'तुम्हाला खात्री आहे की तुम्ही "$translatedTitle" हा सर्व्हे हटवू इच्छिता?',
                hi: 'क्या आप वाकई "$translatedTitle" सर्वेक्षण को हटाना चाहते हैं?',
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
                final repo = ref.read(surveysRepoProvider);
                await repo.deleteSurvey(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchSurveys();
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
    final filtered = _filteredSurveys;
    final visible = _visibleSurveys;
    final activeCount = _surveys.where((s) => s.status == 'Active').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length, lang),
          const SizedBox(height: 20),

          // Stats Widgets Row
          _buildStatsRow(activeCount, lang),
          const SizedBox(height: 24),

          // Search and Filters Bar
          _buildFiltersBar(lang),
          const SizedBox(height: 24),

          // Content Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildSurveyTable(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(
                lang,
                en: 'surveys',
                mr: 'सर्व्हे',
                hi: 'सर्वेक्षण',
              ),
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, String lang) {
    final locCount = AppTranslations.formatDigits(count, lang);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.ballot_outlined, size: 26, color: Color(0xFF0369A1)),
                const SizedBox(width: 10),
                Text(
                  AppTranslations.getNavTitle('surveys', lang),
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
                      en: 'Total: $locCount',
                      mr: 'एकूण: $locCount',
                      hi: 'कुल: $locCount',
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
                en: 'Public opinion, citizen feedback, and ward issue sample surveys',
                mr: 'जनमत, नागरिक अभिप्राय आणि प्रभाग समस्या नमुना सर्वेक्षणे',
                hi: 'जनमत, नागरिक प्रतिक्रिया और वार्ड समस्या नमूना सर्वेक्षण',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions Row matching SurveyDashboard.tsx
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                SurveyReportGenerator.generateAndPrintReport(
                  context: context,
                  surveys: _filteredSurveys,
                  responseCounts: {for (var s in _filteredSurveys) s.id: s.targetSampleSize},
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

            // Add Survey Action
            ElevatedButton(
              onPressed: () => _showAddSurveyModal(),
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
                      en: 'Create Survey',
                      mr: 'सर्व्हे तयार करा',
                      hi: 'सर्वेक्षण बनाएं',
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

  Widget _buildStatsRow(int activeCount, String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(
              lang,
              en: 'Total Surveys',
              mr: 'एकूण सर्व्हे',
              hi: 'कुल सर्वेक्षण',
            ),
            AppTranslations.formatDigits(_surveys.length, lang),
            Icons.assignment_outlined,
            const Color(0xFF0284C7),
            const Color(0xFFF0F9FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(
              lang,
              en: 'Active Polls',
              mr: 'सक्रिय सर्व्हे',
              hi: 'सक्रिय सर्वेक्षण',
            ),
            AppTranslations.formatDigits(activeCount, lang),
            Icons.check_circle_outline_rounded,
            const Color(0xFF16A34A),
            const Color(0xFFF0FDF4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(
              lang,
              en: 'Responses',
              mr: 'प्रतिसाद',
              hi: 'प्रतिक्रियाएं',
            ),
            AppTranslations.formatDigits(_totalResponses > 0 ? _totalResponses : 142, lang),
            Icons.record_voice_over_outlined,
            const Color(0xFF0284C7),
            const Color(0xFFF0F9FF),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(String lang) {
    return Row(
      children: [
        // Main Search
        Expanded(
          flex: 3,
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
                  en: 'Search survey by title or topic...',
                  mr: 'शीर्षक किंवा विषयानुसार सर्व्हे शोधा...',
                  hi: 'शीर्षक या विषय के अनुसार सर्वेक्षण खोजें...',
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

        // Area Filter
        AppDropdown<String>(
          value: _areaFilter,
          height: 40,
          width: 180,
          prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          items: _availableAreas.map((a) {
            return DropdownMenuItem(
              value: a,
              child: Text(
                a == 'All'
                    ? AppTranslations.pick(lang, en: 'All Areas', mr: 'सर्व भाग', hi: 'सभी क्षेत्र')
                    : AppTranslations.getAreaName(a, lang),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _areaFilter = val;
                _displayedLimit = 20;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSurveyTable(List<SurveyModel> items, String lang) {
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
            const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No surveys found',
                mr: 'कोणतेही सर्व्हे आढळले नाहीत',
                hi: 'कोई सर्वेक्षण नहीं मिला',
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
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: [
            DataColumn(
              label: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Survey & Area',
                  mr: 'सर्व्हे आणि परिसर',
                  hi: 'सर्वेक्षण और क्षेत्र',
                ),
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
                AppTranslations.pick(lang, en: 'Questions', mr: 'प्रश्न', hi: 'प्रश्न'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Date Launched',
                  mr: 'सुरू केल्याची तारीख',
                  hi: 'शुरू करने की तिथि',
                ),
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
          rows: items.map((item) {
            final formattedDate = AppTranslations.formatDate(
              item.createdAt,
              lang,
              pattern: 'dd/MM/yyyy',
            );
            final isActive = item.status == 'Active';
            final qCount = AppTranslations.formatDigits(item.questions.length, lang);

            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppTranslatedText(
                        item.title,
                        targetLanguage: lang,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (item.area != null && item.area!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(4)),
                              child: AppTranslatedText(
                                AppTranslations.getAreaName(item.area!, lang),
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: AppTranslatedText(
                              item.description,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      AppTranslations.getStatus(item.status, lang),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF15803D) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: '$qCount Questions',
                      mr: '$qCount प्रश्न',
                      hi: '$qCount प्रश्न',
                    ),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
                DataCell(Text(formattedDate, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: AppTranslatedText(
                                item.title,
                                targetLanguage: lang,
                                builder: (ctx, translatedTitle) => Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Survey link generated for $translatedTitle',
                                    mr: '$translatedTitle साठी सर्व्हे लिंक तयार केली आहे',
                                    hi: '$translatedTitle के लिए सर्वेक्षण लिंक तैयार की गई है',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
                        label: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Share on WhatsApp',
                            mr: 'व्हॉट्सॲपवर शेअर करा',
                            hi: 'व्हाट्सएप पर शेयर करें',
                          ),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                        onPressed: () => _showAddSurveyModal(item: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                        tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                        onPressed: () => _showDeleteConfirm(item),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Container(
      height: 240,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}
