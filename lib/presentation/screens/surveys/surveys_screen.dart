import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/survey_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/surveys_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'create_survey_screen.dart';
import 'survey_detail_screen.dart';
import 'survey_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class SurveysScreen extends ConsumerStatefulWidget {
  const SurveysScreen({super.key});

  @override
  ConsumerState<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends ConsumerState<SurveysScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  List<SurveyModel> _allSurveys = [];
  Map<String, int> _surveyResponseCounts = {};
  int _totalVoters = 42560;
  String _selectedArea = 'All';
  String _statusFilter = 'All'; // 'All', 'Active', 'Draft', 'Closed'
  String _displayMode = 'cards'; // 'cards' or 'table'
  Map<String, int> _areaCounts = {};
  int _displayedLimit = 20;

  List<SurveyModel> get _visibleSurveys =>
      _filteredSurveys.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSurveys({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final repo = ref.read(surveysRepoProvider);
    final votersRepo = ref.read(votersRepoProvider);

    try {
      final vCount = await votersRepo.getVotersCount();
      if (vCount > 0) _totalVoters = vCount;
    } catch (_) {}

    final surveys = await repo.getSurveys();
    final areas = await repo.getAreasWithCount();

    // Load response counts for each survey
    final Map<String, int> counts = {};
    for (final s in surveys) {
      final resps = await repo.getResponses(s.id);
      counts[s.id] = resps.length;
    }

    if (mounted) {
      setState(() {
        _allSurveys = surveys;
        _areaCounts = areas;
        _surveyResponseCounts = counts;
        _isLoading = false;
        _displayedLimit = 20;
      });
    }
  }

  String _formatIndianInt(int value, String lang) {
    final s = value.toString();
    final formatted = s.length <= 3
        ? s
        : () {
            final last3 = s.substring(s.length - 3);
            var rest = s.substring(0, s.length - 3);
            final parts = <String>[];
            while (rest.length > 2) {
              parts.insert(0, rest.substring(rest.length - 2));
              rest = rest.substring(0, rest.length - 2);
            }
            if (rest.isNotEmpty) parts.insert(0, rest);
            return '${parts.join(',')},$last3';
          }();
    return AppTranslations.formatDigits(formatted, lang);
  }

  List<SurveyModel> get _filteredSurveys {
    final lang = ref.read(appLanguageProvider);
    var list = List<SurveyModel>.from(_allSurveys);

    // Search query filter
    final q = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim().toLowerCase());
    if (q.isNotEmpty) {
      list = list.where((s) {
        final tTitle = (DynamicTranslationService.getCachedTranslation(s.title, lang) ?? '').toLowerCase();
        final tDesc = (DynamicTranslationService.getCachedTranslation(s.description, lang) ?? '').toLowerCase();
        final tArea = (DynamicTranslationService.getCachedTranslation(
                  AppTranslations.getAreaName(s.area ?? '', lang),
                  lang,
                ) ??
                '')
            .toLowerCase();
        return s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            (s.area?.toLowerCase().contains(q) ?? false) ||
            tTitle.contains(q) ||
            tDesc.contains(q) ||
            tArea.contains(q);
      }).toList();
    }

    // Area filter
    if (_selectedArea != 'All') {
      list = list.where((s) => s.area == _selectedArea).toList();
    }

    // Status filter
    if (_statusFilter != 'All') {
      list = list.where((s) => s.status.toLowerCase() == _statusFilter.toLowerCase()).toList();
    }

    return list;
  }

  int get _sampleSizeTarget => (_totalVoters * 0.01).ceil();

  int get _totalResponsesAcrossAll => _surveyResponseCounts.values.fold(0, (a, b) => a + b);

  Future<void> _deleteSurvey(SurveyModel survey) async {
    final lang = ref.read(appLanguageProvider);
    final tTitle = await DynamicTranslationService.translateOrRaw(survey.title, lang);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Delete Survey?',
                  mr: 'सर्व्हेक्षण हटवायचे का?',
                  hi: 'सर्वेक्षण हटाएं?',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to delete "$tTitle"? This action cannot be undone.',
            mr: 'तुम्हाला खात्री आहे की "$tTitle" हटवायचे आहे? ही कृती पूर्ववत करता येणार नाही.',
            hi: 'क्या आप वाकई "$tTitle" को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
          ),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final repo = ref.read(surveysRepoProvider);
      await repo.deleteSurvey(survey.id);
      _loadSurveys();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Survey deleted successfully',
              mr: 'सर्व्हेक्षण यशस्वीरित्या हटवले गेले',
              hi: 'सर्वेक्षण सफलतापूर्वक हटा दिया गया',
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showHelpGuide(String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Sample Surveys Guide',
                          mr: 'नमुना सर्व्हेक्षण मार्गदर्शक',
                          hi: 'नमूना सर्वेक्षण गाइड',
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Scientific Opinion Polling Methodology',
                          mr: 'शास्त्रीय जनमत चाचणी पद्धत',
                          hi: 'वैज्ञानिक जनमत सर्वेक्षण पद्धति',
                        ),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildHelpPoint(
              icon: Icons.pie_chart_rounded,
              title: AppTranslations.pick(
                lang,
                en: '1% Sample Size Target',
                mr: '१% नमुना आकार लक्ष्य',
                hi: '१% नमूना आकार लक्ष्य',
              ),
              desc: AppTranslations.pick(
                lang,
                en: 'Surveying a representative sample of 1% (426 citizens) out of 42,560 voters gives 95% statistical confidence in public opinion.',
                mr: '४२,५६० मतदारांपैकी १% (४२६ नागरिक) प्रातिनिधिक नमुन्याचे सर्वेक्षण केल्यास जनमताबाबत ९५% अचूक निष्कर्ष मिळतात.',
                hi: '४२,५६० मतदाताओं में से १% (४२६ नागरिकों) के प्रतिनिधि नमूने का सर्वेक्षण जनमत में ९५% सांख्यिकीय विश्वास प्रदान करता है।',
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.share_rounded,
              title: AppTranslations.pick(
                lang,
                en: 'Direct WhatsApp Distribution',
                mr: 'थेट व्हॉट्सअॅप वितरण',
                hi: 'सीधा व्हाट्सऐप वितरण',
              ),
              desc: AppTranslations.pick(
                lang,
                en: 'Send personalized WhatsApp magic links to citizens so they can fill out the questionnaire in 2 minutes.',
                mr: 'नागरिकांना वैयक्तिक व्हॉट्सअॅप लिंक पाठवा जेणेकरून ते २ मिनिटांत प्रश्नावली भरू शकतील.',
                hi: 'नागरिकों को व्यक्तिगत व्हाट्सऐप लिंक भेजें ताकि वे २ मिनट में प्रश्नावली भर सकें।',
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.bar_chart_rounded,
              title: AppTranslations.pick(
                lang,
                en: 'Live Analytics & Graphs',
                mr: 'थेट विश्लेषण आणि आलेख',
                hi: 'लाइव विश्लेषण और ग्राफ़',
              ),
              desc: AppTranslations.pick(
                lang,
                en: 'Instant statistical breakdown of Yes/No, MCQ and star ratings with downloadable PDF reports.',
                mr: 'होय/नाही, बहुपर्यायी आणि स्टार रेटिंगचे त्वरित विश्लेषण व डाउनलोड करण्यायोग्य PDF अहवाल.',
                hi: 'हाँ/नहीं, बहुविकल्पीय और स्टार रेटिंग का त्वरित विश्लेषण व डाउनलोड करने योग्य PDF रिपोर्ट।',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  AppTranslations.pick(lang, en: 'Got it', mr: 'समजले', hi: 'समझ गया'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpPoint({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0284C7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  void _openWhatsAppShareModal(SurveyModel survey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WhatsAppShareModal(
        survey: survey,
        votersRepo: ref.read(votersRepoProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final filtered = _filteredSurveys;
    final activeCount = _allSurveys.where((s) => s.status.toLowerCase() == 'active').length;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NagarsevakAppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
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
              AppTranslations.getNavTitle('surveys', lang),
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
              lang == 'mr'
                  ? 'जनमत चाचणी आणि मतदार भावना'
                  : (lang == 'hi'
                      ? 'जनमत सर्वेक्षण और मतदाता भावना'
                      : 'Opinion polls & voter sentiment'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Surveys Guide',
              mr: 'सर्व्हेक्षण मार्गदर्शक',
              hi: 'सर्वेक्षण गाइड',
            ),
            onPressed: () => _showHelpGuide(lang),
          ),
        ],
      ),
      body: _isLoading
          ? const AppShimmerList(count: 6)
          : RefreshIndicator(
              onRefresh: _loadSurveys,
              color: const Color(0xFF0284C7),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // KPI Stats Cards Row
                  _buildKpiStatsRow(activeCount, lang),
                  const SizedBox(height: 16),

                  // Search & Area Filter Bar
                  _buildSearchAndFilterBar(filtered, lang),
                  const SizedBox(height: 12),

                  // Status Chips & View Mode Switcher Row
                  _buildStatusTabsRow(filtered.length, lang),
                  const SizedBox(height: 16),

                  // Surveys List (Cards or Table)
                  if (filtered.isEmpty)
                    _buildEmptyState(lang)
                  else if (_displayMode == 'table')
                    _buildSurveysTable(_visibleSurveys, lang)
                  else
                    ..._visibleSurveys.map((s) => _buildSurveyCard(s, lang)),

                  if (!_isLoading && filtered.isNotEmpty)
                    AppLoadMoreFooter(
                      currentCount: _visibleSurveys.length,
                      totalCount: filtered.length,
                      pageSize: 20,
                      onLoadMore: () {
                        setState(() => _displayedLimit += 20);
                      },
                      label: AppTranslations.pick(lang, en: 'surveys', mr: 'सर्व्हेक्षणे', hi: 'सर्वेक्षण'),
                      isMarathi: lang == 'mr',
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          lang == 'mr' ? 'नवीन सर्वेक्षण' : (lang == 'hi' ? 'नया सर्वेक्षण' : 'New Survey'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: () => _openSurveyModal(),
      ),
    );
  }

  Future<void> _openSurveyModal({SurveyModel? surveyToEdit}) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateSurveyBottomSheet(surveyToEdit: surveyToEdit),
    );
    if (res == true) {
      _loadSurveys();
    }
  }

  Widget _buildKpiStatsRow(int activeCount, String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: lang == 'mr' ? 'एकूण मतदार' : (lang == 'hi' ? 'कुल मतदाता' : 'Total Voters'),
            value: _formatIndianInt(_totalVoters, lang),
            subtitle: lang == 'mr' ? 'प्रभाग १२ मतदार यादी' : (lang == 'hi' ? 'वार्ड १२ मतदाता सूची' : 'Ward 12 Voter Roll'),
            icon: Icons.people_alt_rounded,
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: lang == 'mr' ? 'नमुना लक्ष्य (१%)' : (lang == 'hi' ? 'नमूना लक्ष्य (१%)' : 'Sample Target (1%)'),
            value: _formatIndianInt(_sampleSizeTarget, lang),
            subtitle: lang == 'mr' ? 'प्रमाणित नमुना आकार' : (lang == 'hi' ? 'मानक नमूना आकार' : 'Standard Sample Size'),
            icon: Icons.pie_chart_rounded,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: lang == 'mr' ? 'सक्रिय सर्वेक्षण' : (lang == 'hi' ? 'सक्रिय सर्वेक्षण' : 'Active Polls'),
            value: AppTranslations.formatDigits(activeCount, lang),
            subtitle: '${lang == 'mr' ? 'एकूण प्रतिसाद' : (lang == 'hi' ? 'कुल प्रतिक्रियाएं' : 'Total Responses')}: ${AppTranslations.formatDigits(_totalResponsesAcrossAll, lang)}',
            icon: Icons.assignment_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const Icon(Icons.trending_up_rounded, size: 14, color: Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(List<SurveyModel> filtered, String lang) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() => _displayedLimit = 20),
              decoration: InputDecoration(
                hintText: lang == 'mr'
                    ? 'सर्वेक्षण, विषय किंवा परिसर शोधा...'
                    : (lang == 'hi'
                        ? 'सर्वेक्षण, विषय या क्षेत्र खोजें...'
                        : 'Search survey, topic, or area...'),
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _displayedLimit = 20);
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Container(
            height: 28,
            width: 1,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Area Dropdown (Themed Component)
          AppDropdown<String>(
            title: lang == 'mr' ? 'परिसर निवडा' : (lang == 'hi' ? 'क्षेत्र चुनें' : 'Filter by Area'),
            value: _selectedArea,
            height: 36,
            isExpanded: false,
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            hintText: lang == 'mr' ? 'परिसर निवडा' : (lang == 'hi' ? 'क्षेत्र चुनें' : 'Select Area'),
            prefixIcon: Icon(
              Icons.location_on_outlined,
              size: 16,
              color: _selectedArea != 'All' ? const Color(0xFF0284C7) : Colors.grey.shade600,
            ),
            items: [
              DropdownMenuItem(
                value: 'All',
                child: Text(AppTranslations.getAllAreas(lang)),
              ),
              ..._areaCounts.keys.map(
                (area) => DropdownMenuItem(
                  value: area,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: AppTranslatedText(
                          AppTranslations.getAreaName(area, lang),
                          targetLanguage: lang,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppTranslations.formatDigits(_areaCounts[area], lang),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedArea = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),

          AppPdfButton.icon(
            tooltip: AppTranslations.getDownloadReport(lang),
            onPressed: () => SurveyReportGenerator.generateAndPrintReport(
              surveys: filtered,
              responseCounts: _surveyResponseCounts,
              totalVoters: _totalVoters,
              lang: lang,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabsRow(int resultCount, String lang) {
    final tabs = [
      {'label': AppTranslations.getAll(lang), 'key': 'All'},
      {'label': AppTranslations.getStatus('Active', lang), 'key': 'Active'},
      {'label': AppTranslations.getStatus('Draft', lang), 'key': 'Draft'},
      {'label': AppTranslations.getStatus('Closed', lang), 'key': 'Closed'},
    ];

    return Row(
      children: [
        Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((t) {
                final isSel = _statusFilter.toLowerCase() == t['key']!.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(t['label']!),
                    selected: isSel,
                    onSelected: (_) => setState(() {
                      _statusFilter = t['key']!;
                      _displayedLimit = 20;
                    }),
                    selectedColor: const Color(0xFF0284C7),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? Colors.white : Colors.grey.shade700,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSel ? const Color(0xFF0284C7) : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Toggle view: Cards vs Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.view_agenda_outlined,
                  size: 18,
                  color: _displayMode == 'cards' ? const Color(0xFF0284C7) : Colors.grey,
                ),
                tooltip: AppTranslations.pick(lang, en: 'Card View', mr: 'कार्ड दृश्य', hi: 'कार्ड दृश्य'),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _displayMode = 'cards'),
              ),
              Container(width: 1, height: 20, color: Colors.grey.shade200),
              IconButton(
                icon: Icon(
                  Icons.table_chart_outlined,
                  size: 18,
                  color: _displayMode == 'table' ? const Color(0xFF0284C7) : Colors.grey,
                ),
                tooltip: AppTranslations.pick(lang, en: 'Table View', mr: 'तक्ता दृश्य', hi: 'तालिका दृश्य'),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _displayMode = 'table'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSurveyCard(SurveyModel survey, String lang) {
    final responseCount = _surveyResponseCounts[survey.id] ?? 0;
    final target = survey.targetSampleSize > 0 ? survey.targetSampleSize : _sampleSizeTarget;
    final progress = (responseCount / target).clamp(0.0, 1.0);
    final percent = ((responseCount / target) * 100).toInt();

    Color statusColor;
    Color statusBg;

    switch (survey.status.toLowerCase()) {
      case 'active':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        break;
      case 'draft':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      case 'closed':
      default:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        break;
    }

    final statusLabel = AppTranslations.getStatus(survey.status, lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (survey.area != null && survey.area!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 10, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: AppTranslatedText(
                                      AppTranslations.getAreaName(survey.area!, lang),
                                      targetLanguage: lang,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0284C7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${AppTranslations.formatDigits(survey.questions.length, lang)} ${lang == 'mr' ? 'प्रश्न' : (lang == 'hi' ? 'प्रश्न' : 'Questions')}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppTranslatedText(
                        survey.title,
                        targetLanguage: lang,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _openSurveyModal(surveyToEdit: survey);
                    } else if (action == 'delete') {
                      _deleteSurvey(survey);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Text(lang == 'mr' ? 'सर्वेक्षण संपादित करा' : (lang == 'hi' ? 'सर्वेक्षण संपादित करें' : 'Edit Survey')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Text(
                            lang == 'mr' ? 'हटवा' : (lang == 'hi' ? 'हटाएं' : 'Delete'),
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Description
          if (survey.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppTranslatedText(
                survey.description,
                targetLanguage: lang,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Target Sample Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.group_outlined, size: 15, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Text(
                            lang == 'mr' ? 'नमुना प्रगती' : (lang == 'hi' ? 'नमूना प्रगति' : 'Sample Progress'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${AppTranslations.formatDigits(responseCount, lang)} / ${AppTranslations.formatDigits(target, lang)} (${AppTranslations.formatDigits(percent, lang)}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lang == 'mr' ? 'लक्ष्य' : (lang == 'hi' ? 'लक्ष्य' : 'Target')}: ${AppTranslations.formatDigits('1%', lang)} (${AppTranslations.formatDigits(target, lang)} ${lang == 'mr' ? 'मतदार' : (lang == 'hi' ? 'मतदाता' : 'voters')})',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            AppTranslations.formatDate(survey.createdAt, lang, pattern: 'dd MMM yyyy'),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Action Buttons Bottom Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Analytics / Report Button
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bar_chart_rounded, size: 17, color: Color(0xFF0284C7)),
                    label: Text(
                      lang == 'mr' ? 'विश्लेषण व निकाल' : (lang == 'hi' ? 'विश्लेषण और परिणाम' : 'Analysis & Results'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: const Color(0xFFF0F9FF),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurveyDetailScreen(survey: survey),
                        ),
                      ).then((res) { if (res == true) _loadSurveys(showLoading: false); });
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // WhatsApp Broadcast Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                  label: Text(
                    lang == 'mr' ? 'व्हॉट्सअ‍ॅप शेअर' : (lang == 'hi' ? 'व्हाट्सएप शेयर' : 'WhatsApp Share'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => _openWhatsAppShareModal(survey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveysTable(List<SurveyModel> list, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columns: [
              DataColumn(label: Text(lang == 'mr' ? 'शीर्षक व परिसर' : (lang == 'hi' ? 'शीर्षक व क्षेत्र' : 'Title & Area'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(lang == 'mr' ? 'स्थिती' : (lang == 'hi' ? 'स्थिति' : 'Status'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(lang == 'mr' ? 'प्रश्न' : (lang == 'hi' ? 'प्रश्न' : 'Questions'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(lang == 'mr' ? 'प्रतिसाद / लक्ष्य' : (lang == 'hi' ? 'प्रतिक्रियाएं / लक्ष्य' : 'Responses / Target'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(lang == 'mr' ? 'दिनांक' : (lang == 'hi' ? 'दिनांक' : 'Date'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(lang == 'mr' ? 'कृती' : (lang == 'hi' ? 'क्रिया' : 'Action'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: list.map((s) {
              final resp = _surveyResponseCounts[s.id] ?? 0;
              final target = s.targetSampleSize > 0 ? s.targetSampleSize : _sampleSizeTarget;

              return DataRow(
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppTranslatedText(
                          s.title,
                          targetLanguage: lang,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (s.area != null && s.area!.isNotEmpty)
                          AppTranslatedText(
                            AppTranslations.getAreaName(s.area!, lang),
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7)),
                          ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.status.toLowerCase() == 'active'
                            ? const Color(0xFFDCFCE7)
                            : (s.status.toLowerCase() == 'draft' ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppTranslations.getStatus(s.status, lang),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: s.status.toLowerCase() == 'active'
                              ? const Color(0xFF16A34A)
                              : (s.status.toLowerCase() == 'draft' ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(AppTranslations.formatDigits(s.questions.length, lang), style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Text(
                      '${AppTranslations.formatDigits(resp, lang)} / ${AppTranslations.formatDigits(target, lang)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                  DataCell(
                    Text(
                      AppTranslations.formatDate(s.createdAt, lang, pattern: 'dd/MM/yy'),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFF0284C7)),
                          tooltip: lang == 'mr' ? 'विश्लेषण' : (lang == 'hi' ? 'विश्लेषण' : 'Analysis'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SurveyDetailScreen(survey: s),
                              ),
                            ).then((res) { if (res == true) _loadSurveys(showLoading: false); });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF25D366)),
                          tooltip: lang == 'mr' ? 'व्हॉट्सअ‍ॅप शेअर' : (lang == 'hi' ? 'व्हाट्सएप शेयर' : 'WhatsApp Share'),
                          onPressed: () => _openWhatsAppShareModal(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                          tooltip: lang == 'mr' ? 'संपादित करा' : (lang == 'hi' ? 'संपादित करें' : 'Edit'),
                          onPressed: () => _openSurveyModal(surveyToEdit: s),
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
    );
  }

  Widget _buildEmptyState(String lang) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            lang == 'mr'
                ? 'कोणतीही सर्वेक्षणे सापडली नाहीत'
                : (lang == 'hi' ? 'कोई सर्वेक्षण नहीं मिला' : 'No surveys found'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            lang == 'mr'
                ? 'नागरिकांचा अभिप्राय गोळा करण्यासाठी नवीन सर्वेक्षण तयार करा.'
                : (lang == 'hi'
                    ? 'नागरिक प्रतिक्रिया एकत्र करने के लिए नया सर्वेक्षण बनाएं.'
                    : 'Create a new survey to gather citizen feedback.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openSurveyModal(),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: Text(
              lang == 'mr'
                  ? 'पहिले सर्वेक्षण तयार करा'
                  : (lang == 'hi' ? 'पहला सर्वेक्षण बनाएं' : 'Create First Survey'),
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

/// WhatsApp Share Modal with Voter Selection
class _WhatsAppShareModal extends ConsumerStatefulWidget {
  final SurveyModel survey;
  final VotersRepository votersRepo;

  const _WhatsAppShareModal({
    required this.survey,
    required this.votersRepo,
  });

  @override
  ConsumerState<_WhatsAppShareModal> createState() => _WhatsAppShareModalState();
}

class _WhatsAppShareModalState extends ConsumerState<_WhatsAppShareModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;
  List<VoterModel> _allVoters = [];
  final Set<String> _selectedVoterIds = {};
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadVoters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoading = true);
    try {
      final voters = await widget.votersRepo.searchVoters(pageSize: 50);
      final withMobile = voters.where((v) => v.mobile != null && v.mobile!.trim().isNotEmpty).toList();

      if (withMobile.isNotEmpty) {
        _allVoters = withMobile;
      } else {
        // Fallback simulated list of Prabhag 12 voters
        _allVoters = _getSimulatedVoters();
      }
    } catch (_) {
      _allVoters = _getSimulatedVoters();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<VoterModel> _getSimulatedVoters() {
    return [
      VoterModel(
        id: 'v1',
        nameMarathi: 'Rajesh Dattatray Joshi',
        nameEnglish: 'Rajesh Dattatraya Joshi',
        epicNo: 'MH/12/042/102941',
        booth: '28/Shaniwar Peth',
        address: 'Sadashiv Sadan, Shaniwar Peth',
        age: 48,
        gender: 'M',
        mobile: '9822014589',
      ),
      VoterModel(
        id: 'v2',
        nameMarathi: 'Suvarna Mangesh Kulkarni',
        nameEnglish: 'Suvarna Mangesh Kulkarni',
        epicNo: 'MH/12/042/102942',
        booth: '28/Shaniwar Peth',
        address: '102, Anand Apt, Kasba Peth',
        age: 42,
        gender: 'F',
        mobile: '9850123490',
      ),
      VoterModel(
        id: 'v3',
        nameMarathi: 'Sachin Vitthalrao Deshpande',
        nameEnglish: 'Sachin Vitthalrao Deshpande',
        epicNo: 'MH/12/042/103115',
        booth: '29/Raviwar Peth',
        address: 'House No. 415, Raviwar Peth',
        age: 39,
        gender: 'M',
        mobile: '9422033481',
      ),
      VoterModel(
        id: 'v4',
        nameMarathi: 'Anita Chandrashekhar Bapat',
        nameEnglish: 'Anita Chandrashekhar Bapat',
        epicNo: 'MH/12/042/104210',
        booth: '30/Somwar Peth',
        address: 'Bapat Wada, Somwar Peth',
        age: 52,
        gender: 'F',
        mobile: '9890456123',
      ),
      VoterModel(
        id: 'v5',
        nameMarathi: 'Mahesh Prabhakar Phadke',
        nameEnglish: 'Mahesh Prabhakar Phadke',
        epicNo: 'MH/12/042/105118',
        booth: '31/Mangalwar Peth',
        address: 'Phadke Galli, Mangalwar Peth',
        age: 35,
        gender: 'M',
        mobile: '9764512980',
      ),
      VoterModel(
        id: 'v6',
        nameMarathi: 'Deepali Gajanan More',
        nameEnglish: 'Deepali Gajanan More',
        epicNo: 'MH/12/042/106720',
        booth: '28/Shaniwar Peth',
        address: 'Opp. Shaniwar Wada, Shaniwar Peth',
        age: 29,
        gender: 'F',
        mobile: '9823412567',
      ),
    ];
  }

  List<VoterModel> get _filteredVoters {
    final lang = ref.read(appLanguageProvider);
    final q = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim().toLowerCase());
    if (q.isEmpty) return _allVoters;
    return _allVoters.where((v) {
      final cachedName = (DynamicTranslationService.getCachedTranslation(
                v.displayName,
                lang,
                isName: true,
              ) ??
              '')
          .toLowerCase();
      return v.nameMarathi.toLowerCase().contains(q) ||
          v.nameEnglish.toLowerCase().contains(q) ||
          cachedName.contains(q) ||
          (AppTranslations.normalizeAsciiDigits(v.mobile ?? '').contains(q));
    }).toList();
  }

  void _toggleSelectAll() {
    final current = _filteredVoters;
    if (_selectedVoterIds.length == current.length && current.isNotEmpty) {
      setState(() => _selectedVoterIds.clear());
    } else {
      setState(() {
        _selectedVoterIds.addAll(current.map((v) => v.id));
      });
    }
  }

  Future<void> _sendWhatsAppBroadcast() async {
    if (_selectedVoterIds.isEmpty) return;
    final lang = ref.read(appLanguageProvider);
    setState(() => _isSending = true);

    final selected = _allVoters.where((v) => _selectedVoterIds.contains(v.id)).toList();
    final tTitle = await DynamicTranslationService.translateOrRaw(widget.survey.title, lang);

    // Send survey links to selected voters via WhatsApp
    for (int i = 0; i < selected.length; i++) {
      final voter = selected[i];
      final mobile = AppTranslations.normalizeAsciiDigits(voter.mobile!).replaceAll(RegExp(r'\D'), '');
      final magicLink = 'https://nagarsevak.app/s/${widget.survey.id}?v=${voter.id}';
      final tVoterName = await DynamicTranslationService.translateOrRaw(
        voter.displayName,
        lang,
        isName: true,
      );
      final body = AppTranslations.pick(
        lang,
        en: 'Greetings $tVoterName,\n\n'
            'We are conducting this public opinion survey to understand your thoughts on the development of Ward 12:\n\n'
            '*Topic:* $tTitle\n\n'
            'Please click the link below to record your valuable 2-minute feedback:\n$magicLink\n\n'
            '- Office of Corporator, Ward 12',
        mr: 'नमस्कार $tVoterName,\n\n'
            'प्रभाग १२ च्या विकासाबाबत आपले मत जाणून घेण्यासाठी आम्ही हे जनमत सर्व्हेक्षण घेत आहोत:\n\n'
            '*विषय:* $tTitle\n\n'
            'कृपया खालील लिंकवर क्लिक करून आपला २ मिनिटांचा मौल्यवान अभिप्राय नोंदवा:\n$magicLink\n\n'
            '- नगरसेवक कार्यालय, प्रभाग १२',
        hi: 'नमस्ते $tVoterName,\n\n'
            'वार्ड १२ के विकास पर आपके विचार जानने के लिए हम यह जनमत सर्वेक्षण आयोजित कर रहे हैं:\n\n'
            '*विषय:* $tTitle\n\n'
            'अपनी २ मिनट की बहुमूल्य प्रतिक्रिया दर्ज करने के लिए नीचे दिए गए लिंक पर क्लिक करें:\n$magicLink\n\n'
            '- नगरसेवक कार्यालय, वार्ड १२',
      );
      final msg = Uri.encodeComponent(body);

      final url = Uri.parse('https://wa.me/91$mobile?text=$msg');
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (i < selected.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
      Navigator.pop(context);
      final cntStr = AppTranslations.formatDigits(selected.length, lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'WhatsApp survey link sent to $cntStr voters!',
              mr: '$cntStr मतदारांना व्हॉट्सअॅप सर्व्हेक्षण लिंक पाठवली!',
              hi: '$cntStr मतदाताओं को व्हाट्सऐप सर्वेक्षण लिंक भेजा गया!',
            ),
          ),
          backgroundColor: const Color(0xFF25D366),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final filtered = _filteredVoters;
    final allSelected = filtered.isNotEmpty && _selectedVoterIds.length == filtered.length;
    final filteredCnt = AppTranslations.formatDigits(filtered.length, lang);
    final selCnt = AppTranslations.formatDigits(_selectedVoterIds.length, lang);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send_rounded, color: Color(0xFF25D366)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Send Survey via WhatsApp',
                          mr: 'व्हॉट्सअॅपद्वारे सर्व्हेक्षण पाठवा',
                          hi: 'व्हाट्सऐप द्वारा सर्वेक्षण भेजें',
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      AppTranslatedText(
                        widget.survey.title,
                        targetLanguage: lang,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search by name or mobile number...',
                  mr: 'नाव किंवा मोबाईल नंबरने शोधा...',
                  hi: 'नाम या मोबाइल नंबर से खोजें...',
                ),
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF25D366)),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Select All Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: _toggleSelectAll,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: allSelected,
                      activeColor: const Color(0xFF25D366),
                      onChanged: (_) => _toggleSelectAll(),
                    ),
                    Flexible(
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Select All ($filteredCnt voters)',
                          mr: 'सर्व निवडा ($filteredCnt मतदार)',
                          hi: 'सभी चुनें ($filteredCnt मतदाता)',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: '$selCnt Selected',
                          mr: '$selCnt निवडले',
                          hi: '$selCnt चयनित',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF25D366),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Voters List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)))
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'No voters with mobile numbers found.',
                            mr: 'मोबाईल नंबर असलेले मतदार आढळले नाहीत.',
                            hi: 'मोबाइल नंबर वाले कोई मतदाता नहीं मिले।',
                          ),
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final v = filtered[idx];
                          final isChecked = _selectedVoterIds.contains(v.id);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isChecked) {
                                  _selectedVoterIds.remove(v.id);
                                } else {
                                  _selectedVoterIds.add(v.id);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: const Color(0xFF25D366),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedVoterIds.add(v.id);
                                        } else {
                                          _selectedVoterIds.remove(v.id);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppTranslatedText(
                                          v.displayName,
                                          targetLanguage: lang,
                                          isName: true,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_iphone, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              AppTranslations.formatDigits('+91 ${v.mobile ?? ""}', lang),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (v.booth.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Text('• ', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                              Flexible(
                                                child: AppTranslatedText(
                                                  v.booth,
                                                  targetLanguage: lang,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _selectedVoterIds.isEmpty || _isSending ? null : _sendWhatsAppBroadcast,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  label: Text(
                    _isSending
                        ? AppTranslations.pick(lang, en: 'Sending...', mr: 'पाठवत आहे...', hi: 'भेजा जा रहा है...')
                        : AppTranslations.pick(
                            lang,
                            en: 'Send link to $selCnt voters',
                            mr: '$selCnt मतदारांना लिंक पाठवा',
                            hi: '$selCnt मतदाताओं को लिंक भेजें',
                          ),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

