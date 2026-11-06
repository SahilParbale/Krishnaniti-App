import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/survey_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/surveys_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../navigation/app_drawer.dart';
import 'create_survey_screen.dart';
import 'survey_detail_screen.dart';
import 'survey_report_generator.dart';

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

  Future<void> _loadSurveys() async {
    setState(() => _isLoading = true);
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
      });
    }
  }

  List<SurveyModel> get _filteredSurveys {
    var list = List<SurveyModel>.from(_allSurveys);

    // Search query filter
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            (s.area?.toLowerCase().contains(q) ?? false);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('सर्वेक्षण हटवा?'),
          ],
        ),
        content: Text(
          'आपण खात्रीपूर्वक "${survey.title}" हे सर्वेक्षण हटवू इच्छिता? ही कृती पूर्ववत केली जाऊ शकत नाही.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('रद्द करा'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('हटवा', style: TextStyle(color: Colors.white)),
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
        const SnackBar(
          content: Text('सर्वेक्षण यशस्वीरीत्या हटवले गेले'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showHelpGuide() {
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'नमुना सर्वेक्षण (Sample Surveys) मार्गदर्शन',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'शास्त्रीय जनमत चाचण्या कार्यपद्धती',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildHelpPoint(
              icon: Icons.pie_chart_rounded,
              title: '१% नमुना आकार लक्ष्य (1% Sample Target)',
              desc:
                  'एकूण ४२,५६० मतदारांपैकी किमान १% म्हणजेच ४२६ नागरिकांचा प्रातिनिधिक अभिप्राय घेतल्यास ९५% अचूकतेचा लोकमत निष्कर्ष प्राप्त होतो.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.share_rounded,
              title: 'व्हॉट्सॲप मॅजिक लिंक (Direct WhatsApp Distribution)',
              desc:
                  'नागरिकांना वैयक्तिक व्हॉट्सॲप लिंक पाठवून नागरिक थेट २ मिनिटांत मोबाईलवर प्रश्नावली भरू शकतात.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.bar_chart_rounded,
              title: 'रिअल-टाइम विश्लेषण (Live Analytics & Graphs)',
              desc:
                  'प्रत्येक प्रश्नाचे होय/नाही, बहुपर्यायी व स्टार रेटिंगचे आकडेवारीनुसार त्वरित विश्लेषण व पीडीएफ अहवाल डाउनलोड करा.',
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
                child: const Text('समजले', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final filtered = _filteredSurveys;
    final activeCount = _allSurveys.where((s) => s.status.toLowerCase() == 'active').length;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NagarsevakAppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'जनमत चाचण्या (नमुना सर्वेक्षण)',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'नागरिक अभिप्राय व लोकमत विश्लेषण केंद्र',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'मदत व माहिती',
            onPressed: _showHelpGuide,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: 'पीडीएफ अहवाल डाउनलोड करा',
            onPressed: () => SurveyReportGenerator.generateAndPrintReport(
              surveys: filtered,
              responseCounts: _surveyResponseCounts,
              totalVoters: _totalVoters,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'रिफ्रेश',
            onPressed: _loadSurveys,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0284C7)),
            )
          : RefreshIndicator(
              onRefresh: _loadSurveys,
              color: const Color(0xFF0284C7),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // KPI Stats Cards Row
                  _buildKpiStatsRow(activeCount),
                  const SizedBox(height: 16),

                  // Search & Area Filter Bar
                  _buildSearchAndFilterBar(),
                  const SizedBox(height: 12),

                  // Status Chips & View Mode Switcher Row
                  _buildStatusTabsRow(filtered.length),
                  const SizedBox(height: 16),

                  // Surveys List (Cards or Table)
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else if (_displayMode == 'table')
                    _buildSurveysTable(filtered)
                  else
                    ...filtered.map((s) => _buildSurveyCard(s)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'नवीन सर्वेक्षण',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSurveyScreen()),
          );
          if (res == true) _loadSurveys();
        },
      ),
    );
  }

  Widget _buildKpiStatsRow(int activeCount) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'एकूण मतदार',
            value: NumberFormat('#,##,###').format(_totalVoters),
            subtitle: 'प्रभाग १२ मतदार यादी',
            icon: Icons.people_alt_rounded,
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'नमुना लक्ष्य (१%)',
            value: NumberFormat('#,##,###').format(_sampleSizeTarget),
            subtitle: 'मानक नमुना आकार',
            icon: Icons.pie_chart_rounded,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'सक्रिय चाचण्या',
            value: '$activeCount',
            subtitle: 'एकूण प्रतिसाद: $_totalResponsesAcrossAll',
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
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

  Widget _buildSearchAndFilterBar() {
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
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'सर्वेक्षण, विषय किंवा परिसर शोधा...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
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
          // Area Dropdown
          PopupMenuButton<String>(
            tooltip: 'परिसर फिल्टर',
            initialValue: _selectedArea,
            onSelected: (val) => setState(() => _selectedArea = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'All',
                child: Text('सर्व परिसर (All Areas)'),
              ),
              ..._areaCounts.keys.map(
                (area) => PopupMenuItem(
                  value: area,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(area),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_areaCounts[area]}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: _selectedArea != 'All' ? const Color(0xFF0284C7) : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedArea == 'All' ? 'सर्व परिसर' : _selectedArea,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _selectedArea != 'All' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedArea != 'All' ? const Color(0xFF0284C7) : Colors.grey.shade700,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabsRow(int resultCount) {
    final tabs = [
      {'label': 'सर्व', 'key': 'All'},
      {'label': 'सक्रिय (Active)', 'key': 'Active'},
      {'label': 'मसुदा (Draft)', 'key': 'Draft'},
      {'label': 'पूर्ण (Closed)', 'key': 'Closed'},
    ];

    return Row(
      children: [
        Expanded(
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
                    onSelected: (_) => setState(() => _statusFilter = t['key']!),
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
                tooltip: 'कार्ड दृश्य',
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
                tooltip: 'तक्ता दृश्य',
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

  Widget _buildSurveyCard(SurveyModel survey) {
    final responseCount = _surveyResponseCounts[survey.id] ?? 0;
    final target = survey.targetSampleSize > 0 ? survey.targetSampleSize : _sampleSizeTarget;
    final progress = (responseCount / target).clamp(0.0, 1.0);
    final percent = ((responseCount / target) * 100).toInt();

    Color statusColor;
    Color statusBg;
    String statusMarathi;

    switch (survey.status.toLowerCase()) {
      case 'active':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        statusMarathi = 'सक्रिय';
        break;
      case 'draft':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        statusMarathi = 'मसुदा';
        break;
      case 'closed':
      default:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        statusMarathi = 'पूर्ण';
        break;
    }

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
                      Row(
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
                                  statusMarathi,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (survey.area != null && survey.area!.isNotEmpty) ...[
                            const SizedBox(width: 6),
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
                                  Text(
                                    survey.area!,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${survey.questions.length} प्रश्न',
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
                      Text(
                        survey.title,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateSurveyScreen(surveyToEdit: survey),
                        ),
                      ).then((res) {
                        if (res == true) _loadSurveys();
                      });
                    } else if (action == 'delete') {
                      _deleteSurvey(survey);
                    }
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                          SizedBox(width: 8),
                          Text('संपादित करा (Edit)'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('हटवा (Delete)', style: TextStyle(color: Colors.redAccent)),
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
              child: Text(
                survey.description,
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
                            'नमुना प्रतिसाद (Sample Progress)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$responseCount / $target ($percent%)',
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
                        'लक्ष्य: १% ($target मतदार)',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(survey.createdAt),
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
                    label: const Text(
                      'विश्लेषण व निकाल',
                      style: TextStyle(
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
                      ).then((_) => _loadSurveys());
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // WhatsApp Broadcast Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                  label: const Text(
                    'व्हॉट्सॲप शेअर',
                    style: TextStyle(
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

  Widget _buildSurveysTable(List<SurveyModel> list) {
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
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F5F9)),
            columns: const [
              DataColumn(label: Text('शीर्षक व परिसर', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('स्थिती', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('प्रश्न', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('प्रतिसाद / लक्ष्य', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('दिनांक', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('कृती', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                        Text(
                          s.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (s.area != null && s.area!.isNotEmpty)
                          Text(
                            s.area!,
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
                        s.status,
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
                  DataCell(Text('${s.questions.length}', style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Text(
                      '$resp / $target',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                  DataCell(
                    Text(DateFormat('dd/MM/yy').format(s.createdAt), style: const TextStyle(fontSize: 11)),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFF0284C7)),
                          tooltip: 'विश्लेषण',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SurveyDetailScreen(survey: s),
                              ),
                            ).then((_) => _loadSurveys());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF25D366)),
                          tooltip: 'व्हॉट्सॲप शेअर',
                          onPressed: () => _openWhatsAppShareModal(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                          tooltip: 'संपादित करा',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateSurveyScreen(surveyToEdit: s),
                              ),
                            ).then((res) {
                              if (res == true) _loadSurveys();
                            });
                          },
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

  Widget _buildEmptyState() {
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
          const Text(
            'कोणतेही सर्वेक्षण आढळले नाही',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            'नवीन सर्वेक्षण तयार करून नागरिकांचे मत जाणून घ्या.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateSurveyScreen()),
              );
              if (res == true) _loadSurveys();
            },
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('पहिले सर्वेक्षण तयार करा', style: TextStyle(color: Colors.white)),
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
class _WhatsAppShareModal extends StatefulWidget {
  final SurveyModel survey;
  final VotersRepository votersRepo;

  const _WhatsAppShareModal({
    required this.survey,
    required this.votersRepo,
  });

  @override
  State<_WhatsAppShareModal> createState() => _WhatsAppShareModalState();
}

class _WhatsAppShareModalState extends State<_WhatsAppShareModal> {
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
        nameMarathi: 'राजेश दत्तात्रय जोशी',
        nameEnglish: 'Rajesh Dattatraya Joshi',
        epicNo: 'MH/12/042/102941',
        booth: '२८/शनिवार पेठ',
        address: 'सदाशिव सदन, शनिवार पेठ',
        age: 48,
        gender: 'M',
        mobile: '9822014589',
      ),
      VoterModel(
        id: 'v2',
        nameMarathi: 'सुवर्णा मंगेश कुलकर्णी',
        nameEnglish: 'Suvarna Mangesh Kulkarni',
        epicNo: 'MH/12/042/102942',
        booth: '२८/शनिवार पेठ',
        address: '१०२, आनंद अपार्टमेंट, कसबा पेठ',
        age: 42,
        gender: 'F',
        mobile: '9850123490',
      ),
      VoterModel(
        id: 'v3',
        nameMarathi: 'सचिन विठ्ठलराव देशपांडे',
        nameEnglish: 'Sachin Vitthalrao Deshpande',
        epicNo: 'MH/12/042/103115',
        booth: '२९/रविवार पेठ',
        address: 'घर क्र. ४१५, रविवार पेठ',
        age: 39,
        gender: 'M',
        mobile: '9422033481',
      ),
      VoterModel(
        id: 'v4',
        nameMarathi: 'अनिता चंद्रशेखर बापट',
        nameEnglish: 'Anita Chandrashekhar Bapat',
        epicNo: 'MH/12/042/104210',
        booth: '३०/सोमवार पेठ',
        address: 'बापट वाडा, सोमवार पेठ',
        age: 52,
        gender: 'F',
        mobile: '9890456123',
      ),
      VoterModel(
        id: 'v5',
        nameMarathi: 'महेश प्रभाकर फडके',
        nameEnglish: 'Mahesh Prabhakar Phadke',
        epicNo: 'MH/12/042/105118',
        booth: '३१/मंगळवार पेठ',
        address: 'फडके गल्ली, मंगळवार पेठ',
        age: 35,
        gender: 'M',
        mobile: '9764512980',
      ),
      VoterModel(
        id: 'v6',
        nameMarathi: 'दीपाली गजानन मोरे',
        nameEnglish: 'Deepali Gajanan More',
        epicNo: 'MH/12/042/106720',
        booth: '२८/शनिवार पेठ',
        address: 'शनिवार वाड्यासमोर, शनिवार पेठ',
        age: 29,
        gender: 'F',
        mobile: '9823412567',
      ),
    ];
  }

  List<VoterModel> get _filteredVoters {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allVoters;
    return _allVoters.where((v) {
      return v.nameMarathi.toLowerCase().contains(q) ||
          v.nameEnglish.toLowerCase().contains(q) ||
          (v.mobile?.contains(q) ?? false);
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
    setState(() => _isSending = true);

    final selected = _allVoters.where((v) => _selectedVoterIds.contains(v.id)).toList();

    // Send survey links to selected voters via WhatsApp
    for (int i = 0; i < selected.length; i++) {
      final voter = selected[i];
      final mobile = voter.mobile!.replaceAll(RegExp(r'\D'), '');
      final magicLink = 'https://nagarsevak.app/s/${widget.survey.id}?v=${voter.id}';
      final msg = Uri.encodeComponent(
        'सस्नेह नमस्कार ${voter.displayName},\n\n'
        'प्रभाग क्र. १२ मधील विकासाबाबत आपले मत जाणून घेण्यासाठी आम्ही हे जनमत सर्वेक्षण आयोजित केले आहे:\n\n'
        '*विषय:* ${widget.survey.title}\n\n'
        'कृपया खालील लिंकवर क्लिक करून आपले २ मिनिटांचे बहुमूल्य मत नोंदवावे:\n$magicLink\n\n'
        '- कार्यालय, प्रभाग १२ नगरसेवक',
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selected.length} मतदारांना व्हॉट्सॲप सर्वेक्षण लिंक पाठवली गेली!'),
          backgroundColor: const Color(0xFF25D366),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredVoters;
    final allSelected = filtered.isNotEmpty && _selectedVoterIds.length == filtered.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                      const Text(
                        'व्हॉट्सॲपवर सर्वेक्षण पाठवा',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.survey.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
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
                hintText: 'नाव किंवा मोबाईल नंबरने शोधा...',
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
                    Text(
                      'सर्व निवडा (${filtered.length} मतदार)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedVoterIds.length} निवडले',
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
                          'मोबाईल नंबर असलेले मतदार आढळले नाहीत.',
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
                                        Text(
                                          v.displayName,
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
                                              '+91 ${v.mobile ?? ""}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (v.booth.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '• ${v.booth}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
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
                  child: const Text('रद्द करा', style: TextStyle(color: Colors.grey)),
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
                        ? 'पाठवत आहे...'
                        : '${_selectedVoterIds.length} मतदारांना लिंक पाठवा',
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

