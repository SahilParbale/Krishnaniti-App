import '../../navigation/app_bar_leading_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/media_tracking_model.dart';
import '../../../data/models/social_post_model.dart'; // for IntFormatting
import '../../../data/repositories/media_tracking_repository.dart';
import '../../navigation/app_drawer.dart';
import 'media_tracking_detail_screen.dart';
import 'media_tracking_report_generator.dart';

class MediaTrackingScreen extends ConsumerStatefulWidget {
  const MediaTrackingScreen({super.key});

  @override
  ConsumerState<MediaTrackingScreen> createState() =>
      _MediaTrackingScreenState();
}

class _MediaTrackingScreenState extends ConsumerState<MediaTrackingScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedProfileId = 'all';
  String _activeSentiment = 'all'; // 'all' | 'positive' | 'negative'
  String _viewMode = 'stream'; // 'stream' | 'table'
  bool _showTelemetry = false;
  bool _isScanning = false;

  bool _isLoading = true;
  List<MediaTrackingArticleModel> _allArticles = [];
  List<TrackingProfileModel> _profiles = [];
  List<TelemetryLogEntry> _telemetryLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(mediaTrackingRepoProvider);
    final articles = await repo.getArticles();
    final profiles = await repo.getProfiles();
    final logs = await repo.getTelemetryLogs();

    if (mounted) {
      setState(() {
        _allArticles = articles;
        _profiles = profiles;
        _telemetryLogs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _simulateScanning() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media portals scan completed! Feeds updated.'),
          backgroundColor: Color(0xFF0284C7),
        ),
      );
    }
  }

  List<MediaTrackingArticleModel> get _filteredArticles {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allArticles.where((a) {
      // Profile Filter
      if (_selectedProfileId != 'all') {
        final profile = _profiles.firstWhere((p) => p.id == _selectedProfileId,
            orElse: () => _profiles.first);
        if (profile.query.isNotEmpty) {
          final pq = profile.query.toLowerCase();
          final matchesProfile =
              a.personTracked.toLowerCase().contains(pq) ||
                  a.title.toLowerCase().contains(pq);
          if (!matchesProfile) return false;
        }
      }

      // Sentiment Filter
      if (_activeSentiment == 'positive' && !a.isPositive) return false;
      if (_activeSentiment == 'negative' && !a.isNegative) return false;

      // Search Query
      if (query.isNotEmpty) {
        final titleEnMatch = a.title.toLowerCase().contains(query);
        final titleMrMatch = a.titleMarathi.toLowerCase().contains(query);
        final sourceMatch = a.source.toLowerCase().contains(query);
        final summaryEnMatch = a.summary.toLowerCase().contains(query);
        final summaryMrMatch = a.summaryMarathi.toLowerCase().contains(query);
        final personMatch = a.personTracked.toLowerCase().contains(query);
        final keywordMatch = a.keywords.any((k) => k.toLowerCase().contains(query));

        if (!titleEnMatch &&
            !titleMrMatch &&
            !sourceMatch &&
            !summaryEnMatch &&
            !summaryMrMatch &&
            !personMatch &&
            !keywordMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showHelpGuide() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Media Tracking Guide',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Media Tracking & Online Portal Monitoring Guide',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0284C7)),
                ),
                SizedBox(height: 10),
                _GuideStep(
                  number: '1',
                  title: 'Search & Profiles',
                  desc:
                      'Track news mentions of the Nagarsevak, opposition leaders, or Prabhag 12 development works across regional portals.',
                ),
                _GuideStep(
                  number: '2',
                  title: 'Telemetry Logs',
                  desc:
                      'Tap the terminal icon to inspect real-time RSS crawlers scanning Sakal, ABP Majha, TV9, Lokmat, and Twitter.',
                ),
                _GuideStep(
                  number: '3',
                  title: 'Save to Newspaper Clippings',
                  desc:
                      'One-click export allows any online digital story to be archived directly into your official Newspaper Clippings register.',
                ),
                _GuideStep(
                  number: '4',
                  title: 'PDF Audit Reports',
                  desc:
                      'Download official landscape A4 reports summarizing sentiment share and estimated digital media reach.',
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  void _showAddArticleModal() {
    final titleMrCtrl = TextEditingController();
    final titleEnCtrl = TextEditingController();
    final sourceCtrl = TextEditingController(text: 'Lokmat News18');
    final urlCtrl = TextEditingController();
    final summaryMrCtrl = TextEditingController();
    final summaryEnCtrl = TextEditingController();
    final personCtrl = TextEditingController(text: 'Amit Chougale (Nagarsevak)');
    final reachCtrl = TextEditingController(text: '25000');
    String sentiment = 'positive';
    String sourceType = 'portal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.add_link_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Track Web News URL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Sentiment Type
                        const Text('Coverage Sentiment',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setModalState(() => sentiment = 'positive'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: sentiment == 'positive'
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: sentiment == 'positive'
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Positive',
                                    style: TextStyle(
                                      color: sentiment == 'positive'
                                          ? Colors.white
                                          : const Color(0xFF334155),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setModalState(() => sentiment = 'negative'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: sentiment == 'negative'
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: sentiment == 'negative'
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Critical',
                                    style: TextStyle(
                                      color: sentiment == 'negative'
                                          ? Colors.white
                                          : const Color(0xFF334155),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Source Portal
                        const Text('Source Portal',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: sourceCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. TV9 Marathi, ABP Majha, Lokmat...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // URL
                        const Text('Portal Article URL',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: urlCtrl,
                          decoration: const InputDecoration(
                            hintText: 'https://news-portal.com/article/...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Headline Marathi
                        const Text('Headline (Marathi / Regional)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleMrCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Development works in Ward 12...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Headline English
                        const Text('Headline (English)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleEnCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Ward 12 civic initiatives praised...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Summary Marathi
                        const Text('Summary',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: summaryMrCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subject & Reach
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: personCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Person / Subject Tracked',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: reachCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Est. Reach',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text(
                            'Save & Start Tracking',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () async {
                            final mrText = titleMrCtrl.text.trim();
                            final enText = titleEnCtrl.text.trim();
                            if (mrText.isEmpty && enText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please enter headline for article.')),
                              );
                              return;
                            }

                            final newArticle = MediaTrackingArticleModel(
                              id: 'med_${DateTime.now().millisecondsSinceEpoch}',
                              title: enText.isNotEmpty ? enText : mrText,
                              titleMarathi: mrText.isNotEmpty ? mrText : enText,
                              source: sourceCtrl.text.trim().isNotEmpty
                                  ? sourceCtrl.text.trim()
                                  : 'Online Portal',
                              sourceType: sourceType,
                              date: DateTime.now().toString().substring(0, 10),
                              time: '12:00 PM',
                              sentiment: sentiment,
                              personTracked: personCtrl.text.trim(),
                              url: urlCtrl.text.trim().isNotEmpty
                                  ? urlCtrl.text.trim()
                                  : 'https://news.google.com',
                              summary: summaryEnCtrl.text.trim().isNotEmpty
                                  ? summaryEnCtrl.text.trim()
                                  : summaryMrCtrl.text.trim(),
                              summaryMarathi: summaryMrCtrl.text.trim().isNotEmpty
                                  ? summaryMrCtrl.text.trim()
                                  : summaryEnCtrl.text.trim(),
                              reachEstimate:
                                  int.tryParse(reachCtrl.text) ?? 20000,
                              keywords: ['#Pune', '#Media', '#Development'],
                            );

                            final repo = ref.read(mediaTrackingRepoProvider);
                            await repo.addArticle(newArticle);
                            if (modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                            }
                            _loadData();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Media mention added to tracking dashboard!'),
                                  backgroundColor: Color(0xFF0284C7),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredArticles;
    final totalCount = _allArticles.length;
    final positiveCount = _allArticles.where((a) => a.isPositive).length;
    final negativeCount = _allArticles.where((a) => a.isNegative).length;
    final positiveRatio =
        totalCount > 0 ? (positiveCount / totalCount) * 100 : 0.0;
    final totalReach =
        _allArticles.fold<int>(0, (acc, a) => acc + a.reachEstimate);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: const AppBarLeadingNavButton(),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Media Tracking',
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
                'TV channels & digital news tracking',
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
        drawer: const NagarsevakAppDrawer(),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  children: [
                    // 1) SEARCH & SCANNER BAR
                    _buildSearchBar(),
                    const SizedBox(height: 12),

                    // 2) QUICK PROFILES CHIPS
                    _buildProfilesCarousel(),
                    const SizedBox(height: 14),

                    // 3) 4 EXECUTIVE SUMMARY KPI CARDS
                    _buildKpiGrid(
                      total: totalCount,
                      positive: positiveCount,
                      negative: negativeCount,
                      ratio: positiveRatio,
                      reach: totalReach,
                    ),
                    const SizedBox(height: 14),

                    // 4) TELEMETRY TERMINAL LOGS (Collapsible)
                    if (_showTelemetry) ...[
                      _buildTelemetryTerminal(),
                      const SizedBox(height: 14),
                    ],

                    // 5) SENTIMENT FILTER TABS
                    _buildSentimentTabs(
                      total: totalCount,
                      positive: positiveCount,
                      negative: negativeCount,
                    ),
                    const SizedBox(height: 12),

                    // 6) RESULTS COUNT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Showing ${filtered.length} of $totalCount news mentions',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (_searchCtrl.text.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Row(
                                    children: const [
                                      Text('Clear',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF0284C7),
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(width: 4),
                                      Icon(Icons.close,
                                          size: 14, color: Color(0xFF0284C7)),
                                    ],
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                _viewMode == 'stream'
                                    ? Icons.table_chart_outlined
                                    : Icons.view_stream_rounded,
                                color: const Color(0xFF0284C7),
                                size: 20,
                              ),
                              tooltip: _viewMode == 'stream'
                                  ? 'Switch to Table'
                                  : 'Switch to Stream',
                              onPressed: () {
                                setState(() {
                                  _viewMode = _viewMode == 'stream' ? 'table' : 'stream';
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _showTelemetry ? Icons.terminal_rounded : Icons.terminal_outlined,
                                color: _showTelemetry ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                                size: 20,
                              ),
                              tooltip: 'Scanner Telemetry Logs',
                              onPressed: () {
                                setState(() => _showTelemetry = !_showTelemetry);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined,
                                  color: Color(0xFF0284C7), size: 20),
                              tooltip: 'Download PDF Report',
                              onPressed: () {
                                MediaTrackingReportGenerator.generateAndPrintReport(
                                  articles: filtered,
                                  profileFilter: _selectedProfileId,
                                  sentimentFilter: _activeSentiment,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.help_outline_rounded,
                                  color: Color(0xFF64748B), size: 20),
                              tooltip: 'Help Guide',
                              onPressed: _showHelpGuide,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 7) DUAL VIEW (STREAM CARDS vs REPORT TABLE)
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else if (_viewMode == 'stream')
                      ...filtered.map((item) => _buildStreamCard(item))
                    else
                      _buildTableView(filtered),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_link_rounded),
          label: const Text('Track URL',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _showAddArticleModal,
        ),
      ),
    );
  }

  // 1) Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Enter name or topic (e.g. Amit Chougale)...',
                hintStyle:
                    TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchCtrl.clear();
                setState(() {});
              },
            ),
          // Scan Portals Button
          InkWell(
            onTap: _isScanning ? null : _simulateScanning,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0284C7),
                borderRadius:
                    BorderRadius.horizontal(right: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  if (_isScanning)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.radar_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _isScanning ? 'Scanning...' : 'Scan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2) Quick Profiles Carousel
  Widget _buildProfilesCarousel() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _profiles.map((prof) {
          final isSel = _selectedProfileId == prof.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                '${prof.name} (${prof.mentionsCount})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? Colors.white : const Color(0xFF334155),
                ),
              ),
              selected: isSel,
              selectedColor: const Color(0xFF0284C7),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSel
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedProfileId = prof.id);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // 3) 4 Executive KPI Cards
  Widget _buildKpiGrid({
    required int total,
    required int positive,
    required int negative,
    required double ratio,
    required int reach,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiTile(
                title: 'Total Mentions',
                marathi: 'Total Mentions',
                value: '$total',
                icon: Icons.language_rounded,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                subtext: '8 Portals Active',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiTile(
                title: 'Sentiment Ratio',
                marathi: 'Sentiment Ratio',
                value: '${ratio.toStringAsFixed(0)}%',
                icon: Icons.sentiment_very_satisfied_rounded,
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFF0FDF4),
                subtext: '$positive Positive',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiTile(
                title: 'Critical Issues',
                marathi: 'Critical Issues',
                value: '$negative',
                icon: Icons.shield_outlined,
                color: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
                subtext: 'Needs Follow-up',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiTile(
                title: 'Est. Digital Reach',
                marathi: 'Total Reach',
                value: reach.toLocaleString(),
                icon: Icons.remove_red_eye_outlined,
                color: const Color(0xFF9333EA),
                bgColor: const Color(0xFFFAF5FF),
                subtext: 'Web Impressions',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiTile({
    required String title,
    required String marathi,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                marathi,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4) Telemetry Terminal Box
  Widget _buildTelemetryTerminal() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF22C55E)),
                  SizedBox(width: 6),
                  Text(
                    'TELEMETRY TERMINAL • RSS & WEB SCRAPING ENGINE',
                    style: TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showTelemetry = false),
                child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          const SizedBox(height: 8),
          ..._telemetryLogs.map((log) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[${log.timestamp}]',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.portal,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      log.message,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 5) Sentiment Tabs
  Widget _buildSentimentTabs({
    required int total,
    required int positive,
    required int negative,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildSentimentTabItem('all', 'All Mentions', 'All Mentions', total, const Color(0xFF0284C7)),
          ),
          Expanded(
            child: _buildSentimentTabItem('positive', 'Positive', 'Positive', positive, const Color(0xFF16A34A)),
          ),
          Expanded(
            child: _buildSentimentTabItem('negative', 'Critical', 'Critical', negative, const Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentTabItem(
      String id, String label, String marathi, int count, Color color) {
    final isSel = _activeSentiment == id;

    return GestureDetector(
      onTap: () => setState(() => _activeSentiment = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isSel ? Colors.white : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSel
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              marathi,
              style: TextStyle(
                fontSize: 9,
                color: isSel
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6) Stream Card
  Widget _buildStreamCard(MediaTrackingArticleModel article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MediaTrackingDetailScreen(
                article: article,
                onArticleUpdated: _loadData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: article.sourceBrandColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(article.sourceIcon,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              article.source,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${article.date} • ${article.time}',
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: article.sentimentBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: article.sentimentColor, width: 0.8),
                    ),
                    child: Text(
                      article.sentimentLabelMarathi,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: article.sentimentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tracked Subject Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_rounded,
                      size: 13, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Text(
                    article.personTracked,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Headline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                article.titleMarathi,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                article.summaryMarathi,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Bottom Actions Bar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined,
                          size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${article.reachEstimate.toLocaleString()} reach',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (article.isSavedToClipping)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Saved in Clippings',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () async {
                            final repo = ref.read(mediaTrackingRepoProvider);
                            await repo.saveToClipping(article.id);
                            _loadData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Saved to Newspaper Clippings!'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: const [
                              Icon(Icons.bookmark_add_outlined,
                                  size: 14, color: Color(0xFF0284C7)),
                              SizedBox(width: 3),
                              Text(
                                'Save to Clipping',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7) Report Table View
  Widget _buildTableView(List<MediaTrackingArticleModel> articles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
          horizontalMargin: 12,
          columnSpacing: 16,
          headingTextStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A)),
          dataTextStyle:
              const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
          columns: const [
            DataColumn(label: Text('Date & Time')),
            DataColumn(label: Text('Source Portal')),
            DataColumn(label: Text('Tracked Profile')),
            DataColumn(label: Text('Headline (Marathi / English)')),
            DataColumn(label: Text('Sentiment')),
            DataColumn(label: Text('Reach'), numeric: true),
            DataColumn(label: Text('Action')),
          ],
          rows: articles.map((a) {
            return DataRow(
              cells: [
                DataCell(Text('${a.date}\n${a.time}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: a.sourceBrandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: a.sourceBrandColor, width: 0.5),
                    ),
                    child: Text(
                      a.source,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: a.sourceBrandColor,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(a.personTracked)),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      a.titleMarathi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: a.sentimentBgColor,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: a.sentimentColor, width: 0.5),
                    ),
                    child: Text(
                      a.sentimentLabelMarathi,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: a.sentimentColor,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(a.reachEstimate.toLocaleString())),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Color(0xFF0284C7)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MediaTrackingDetailScreen(
                            article: a,
                            onArticleUpdated: _loadData,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No media mentions found',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1E293B)),
          ),
          SizedBox(height: 4),
          Text(
            'Try scanning portals again or selecting "All Profiles".',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFF0284C7),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

