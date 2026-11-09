import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/newspaper_clipping_model.dart';
import '../../../data/repositories/newspaper_clippings_repository.dart';
import '../../navigation/app_drawer.dart';
import 'newspaper_clipping_detail_screen.dart';
import 'newspaper_report_generator.dart';

class NewspaperClippingsScreen extends ConsumerStatefulWidget {
  const NewspaperClippingsScreen({super.key});

  @override
  ConsumerState<NewspaperClippingsScreen> createState() =>
      _NewspaperClippingsScreenState();
}

class _NewspaperClippingsScreenState
    extends ConsumerState<NewspaperClippingsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _activeSentiment = 'all'; // 'all' | 'positive' | 'negative'
  String _selectedNewspaper = 'All'; // 'All' | 'Sakal' | 'Lokmat' | ...
  String _filterDate = '';
  String _viewMode = 'grid'; // 'grid' | 'table'

  bool _isLoading = true;
  List<NewspaperClippingModel> _allClippings = [];

  final List<String> _newspapers = [
    'All',
    'Sakal',
    'Lokmat',
    'Maharashtra Times',
    'Pudhari',
    'Loksatta',
    'The Indian Express',
  ];

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
    final repo = ref.read(newspaperClippingsRepoProvider);
    final items = await repo.getClippings();
    if (mounted) {
      setState(() {
        _allClippings = items;
        _isLoading = false;
      });
    }
  }

  List<NewspaperClippingModel> get _filteredClippings {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allClippings.where((c) {
      // Sentiment tab filter
      if (_activeSentiment == 'positive' && !c.isPositive) return false;
      if (_activeSentiment == 'negative' && c.isPositive) return false;

      // Newspaper publication filter
      if (_selectedNewspaper != 'All' &&
          c.newspaper.toLowerCase() != _selectedNewspaper.toLowerCase()) {
        return false;
      }

      // Date filter
      if (_filterDate.isNotEmpty && c.date != _filterDate) {
        return false;
      }

      // Search query
      if (query.isNotEmpty) {
        final titleEnMatch = c.title.toLowerCase().contains(query);
        final titleMrMatch = c.titleMarathi.toLowerCase().contains(query);
        final descEnMatch = c.description.toLowerCase().contains(query);
        final descMrMatch = c.descriptionMarathi.toLowerCase().contains(query);
        final paperMatch = c.newspaper.toLowerCase().contains(query);
        final actionMatch =
            c.actionTaken?.toLowerCase().contains(query) ?? false;
        final journalistMatch =
            c.journalistName?.toLowerCase().contains(query) ?? false;

        if (!titleEnMatch &&
            !titleMrMatch &&
            !descEnMatch &&
            !descMrMatch &&
            !paperMatch &&
            !actionMatch &&
            !journalistMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showHelpTutorial() {
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
                'Newspaper Clipping Guide',
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
                  'Newspaper Clippings & Media Monitoring Guide',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0284C7)),
                ),
                SizedBox(height: 10),
                _GuideStep(
                  number: '1',
                  title: 'Coverage Categories',
                  desc:
                      'Switch between "Positive" and "Negative" to track public appreciation versus critical issues requiring municipal resolution.',
                ),
                _GuideStep(
                  number: '2',
                  title: 'Add New Clipping',
                  desc:
                      'Upload news cutting images along with Marathi headline, page number, edition, and civic action taken report.',
                ),
                _GuideStep(
                  number: '3',
                  title: 'Official PDF Report',
                  desc:
                      'Generate landscape A4 print-ready reports with clippings ledger for ward party meetings and review.',
                ),
                _GuideStep(
                  number: '4',
                  title: 'Dual Views',
                  desc:
                      'Toggle between rich visual news card grid and tabular audit report view.',
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

  void _showAddClippingModal() {
    final titleMrCtrl = TextEditingController();
    final titleEnCtrl = TextEditingController();
    final descMrCtrl = TextEditingController();
    final descEnCtrl = TextEditingController();
    final actionCtrl = TextEditingController();
    final pageCtrl = TextEditingController(text: 'Page 3 • Pune Metro');
    final imageCtrl = TextEditingController();
    final journalistCtrl = TextEditingController();
    String newspaper = 'Sakal';
    String sentiment = _activeSentiment == 'negative' ? 'negative' : 'positive';
    String dateStr = DateTime.now().toString().substring(0, 10);

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
                            Icon(Icons.add_photo_alternate_outlined,
                                color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Add Newspaper Clipping',
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
                        const Text('Coverage Type',
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
                                    'Negative / Civic Issue',
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

                        // Newspaper Dropdown
                        const Text('Newspaper',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: newspaper,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          items: _newspapers
                              .where((n) => n != 'All')
                              .map((p) => DropdownMenuItem(
                                  value: p, child: Text(p)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => newspaper = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // Headline Marathi
                        const Text('Headline (Marathi / Local)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleMrCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Road resurfacing in Ward 12...',
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
                            hintText: 'e.g. Major development fund sanctioned...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description Marathi
                        const Text('Description',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descMrCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter article summary here...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Civic Action Taken
                        const Text('Civic Action Taken',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: actionCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Action taken by Nagarsevak after news publication...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Image URL & Page
                        TextField(
                          controller: imageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Image / Clipping URL (Optional)',
                            hintText: 'https://images.unsplash.com/...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: pageCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Page & Edition',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: journalistCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Journalist / Byline',
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
                            'Save Clipping',
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
                                        Text('Please enter headline for clipping.')),
                              );
                              return;
                            }

                            final newClip = NewspaperClippingModel(
                              id: 'clip_${DateTime.now().millisecondsSinceEpoch}',
                              title: enText.isNotEmpty ? enText : mrText,
                              titleMarathi: mrText.isNotEmpty ? mrText : enText,
                              newspaper: newspaper,
                              date: dateStr,
                              sentiment: sentiment,
                              imageUrl: imageCtrl.text.trim().isNotEmpty
                                  ? imageCtrl.text.trim()
                                  : 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80&w=800',
                              pageNumber: pageCtrl.text.trim().isNotEmpty
                                  ? pageCtrl.text.trim()
                                  : 'Page 3',
                              description: descEnCtrl.text.trim().isNotEmpty
                                  ? descEnCtrl.text.trim()
                                  : descMrCtrl.text.trim(),
                              descriptionMarathi:
                                  descMrCtrl.text.trim().isNotEmpty
                                      ? descMrCtrl.text.trim()
                                      : descEnCtrl.text.trim(),
                              actionTaken: actionCtrl.text.trim().isNotEmpty
                                  ? actionCtrl.text.trim()
                                  : 'Conducted site inspection with PMC municipal engineers and resolved the issue.',
                              journalistName: journalistCtrl.text.trim().isNotEmpty
                                  ? journalistCtrl.text.trim()
                                  : null,
                            );

                            final repo = ref.read(newspaperClippingsRepoProvider);
                            await repo.addClipping(newClip);
                            if (modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                            }
                            _loadData();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Newspaper clipping added successfully!'),
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
    final filtered = _filteredClippings;
    final totalCount = _allClippings.length;
    final positiveCount = _allClippings.where((c) => c.isPositive).length;
    final negativeCount = _allClippings.where((c) => !c.isPositive).length;
    final papersCount =
        _allClippings.map((c) => c.newspaper).toSet().length;

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
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Open Menu Drawer',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Newspaper Clipping',
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
                'Print news media coverage archive and press releases',
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
                    // 1) SENTIMENT TABS (Positive vs Negative News)
                    _buildSentimentTabs(
                      positiveCount: positiveCount,
                      negativeCount: negativeCount,
                      totalCount: totalCount,
                    ),
                    const SizedBox(height: 14),

                    // 2) 4 EXECUTIVE SUMMARY KPI CARDS
                    _buildKpiGrid(
                      total: totalCount,
                      positive: positiveCount,
                      negative: negativeCount,
                      papers: papersCount,
                    ),
                    const SizedBox(height: 14),

                    // 3) SEARCH & FILTER BAR
                    _buildFiltersBar(),
                    const SizedBox(height: 12),

                    // 4) RESULTS BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Showing ${filtered.length} of $totalCount clippings',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (_filterDate.isNotEmpty)
                              InkWell(
                                onTap: () => setState(() => _filterDate = ''),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Row(
                                    children: [
                                      Text('Date: $_filterDate',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF0284C7),
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.close,
                                          size: 14, color: Color(0xFF0284C7)),
                                    ],
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                _viewMode == 'grid'
                                    ? Icons.table_chart_outlined
                                    : Icons.grid_view_rounded,
                                color: const Color(0xFF0284C7),
                                size: 20,
                              ),
                              tooltip: _viewMode == 'grid'
                                  ? 'Switch to Table'
                                  : 'Switch to Grid',
                              onPressed: () {
                                setState(() {
                                  _viewMode = _viewMode == 'grid' ? 'table' : 'grid';
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined,
                                  color: Color(0xFF0284C7), size: 20),
                              tooltip: 'Download PDF Report',
                              onPressed: () {
                                NewspaperReportGenerator.generateAndPrintReport(
                                  clippings: filtered,
                                  sentimentFilter: _activeSentiment == 'all'
                                      ? 'All News'
                                      : (_activeSentiment == 'positive'
                                          ? 'Positive News'
                                          : 'Negative Issues'),
                                  newspaperFilter: _selectedNewspaper,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.help_outline_rounded,
                                  color: Color(0xFF64748B), size: 20),
                              tooltip: 'Help Guide',
                              onPressed: _showHelpTutorial,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 5) DUAL VIEW (GRID CARDS vs REPORT TABLE)
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else if (_viewMode == 'grid')
                      ...filtered.map((item) => _buildClippingCard(item))
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
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text('Add Clipping',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _showAddClippingModal,
        ),
      ),
    );
  }

  // 1) Sentiment Tabs
  Widget _buildSentimentTabs({
    required int positiveCount,
    required int negativeCount,
    required int totalCount,
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
            child: _buildTabButton(
              id: 'all',
              label: 'All News',
              marathi: 'All News',
              count: totalCount,
              activeColor: const Color(0xFF0284C7),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              id: 'positive',
              label: 'Positive',
              marathi: 'Positive',
              count: positiveCount,
              activeColor: const Color(0xFF16A34A),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              id: 'negative',
              label: 'Civic Issues',
              marathi: 'Civic Issues',
              count: negativeCount,
              activeColor: const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String id,
    required String label,
    required String marathi,
    required int count,
    required Color activeColor,
  }) {
    final isSelected = _activeSentiment == id;

    return GestureDetector(
      onTap: () => setState(() => _activeSentiment = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              marathi,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2) 4 Executive KPI Cards
  Widget _buildKpiGrid({
    required int total,
    required int positive,
    required int negative,
    required int papers,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiItem(
                title: 'Total Clippings',
                marathi: 'Total',
                value: '$total',
                icon: Icons.newspaper_rounded,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiItem(
                title: 'Positive News',
                marathi: 'Positive',
                value: '$positive',
                icon: Icons.thumb_up_alt_outlined,
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFF0FDF4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiItem(
                title: 'Civic Issues',
                marathi: 'Civic Issues',
                value: '$negative',
                icon: Icons.report_problem_outlined,
                color: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiItem(
                title: 'Dailies Covered',
                marathi: 'Dailies',
                value: '$papers',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF9333EA),
                bgColor: const Color(0xFFFAF5FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiItem({
    required String title,
    required String marathi,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
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
          Text(
            marathi,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // 3) Filters Bar
  Widget _buildFiltersBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search headline, topic, Sakal, Lokmat...',
              hintStyle:
                  const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Newspaper horizontal filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _newspapers.map((paper) {
              final isSel = _selectedNewspaper == paper;
              final count = paper == 'All'
                  ? _allClippings.length
                  : _allClippings
                      .where((c) =>
                          c.newspaper.toLowerCase() == paper.toLowerCase())
                      .length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    '$paper ($count)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: const Color(0xFF0284C7),
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSel
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onSelected: (val) {
                    setState(() => _selectedNewspaper = paper);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 4) Clipping Card
  Widget _buildClippingCard(NewspaperClippingModel item) {
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewspaperClippingDetailScreen(
                clipping: item,
                onUpdated: _loadData,
                onDeleted: _loadData,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Thumbnail
            Stack(
              children: [
                Image.network(
                  item.imageUrl,
                  width: double.infinity,
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) {
                    return Container(
                      width: double.infinity,
                      height: 140,
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.newspaper_rounded,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text(
                            item.newspaper,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Newspaper Tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.newspaperBrandColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.newspaper,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Sentiment Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.sentimentBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: item.sentimentColor, width: 0.8),
                    ),
                    child: Text(
                      item.sentimentLabelMarathi,
                      style: TextStyle(
                        color: item.sentimentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Date Bar
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content text
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titleMarathi,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.descriptionMarathi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF475569),
                    ),
                  ),
                  if (item.actionTaken != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFCBD5E1), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.isPositive
                                ? Icons.check_circle_outline_rounded
                                : Icons.report_problem_outlined,
                            size: 13,
                            color: item.sentimentColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Action: ${item.actionTaken!}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom bar with action link
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.pageNumber ?? 'Page 3',
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                  Row(
                    children: const [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: Color(0xFF0284C7)),
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

  // 5) Report Table View
  Widget _buildTableView(List<NewspaperClippingModel> clippings) {
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
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Newspaper')),
            DataColumn(label: Text('Headline (Marathi / English)')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Action Taken')),
            DataColumn(label: Text('Action')),
          ],
          rows: clippings.map((c) {
            return DataRow(
              cells: [
                DataCell(Text(c.date)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.newspaperBrandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: c.newspaperBrandColor, width: 0.5),
                    ),
                    child: Text(
                      c.newspaper,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: c.newspaperBrandColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      c.titleMarathi,
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
                      color: c.sentimentBgColor,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: c.sentimentColor, width: 0.5),
                    ),
                    child: Text(
                      c.sentimentLabelMarathi,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: c.sentimentColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 160,
                    child: Text(
                      c.actionTaken ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Color(0xFF0284C7)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewspaperClippingDetailScreen(
                            clipping: c,
                            onUpdated: _loadData,
                            onDeleted: _loadData,
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
          Icon(Icons.newspaper_outlined, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No newspaper clippings found',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1E293B)),
          ),
          SizedBox(height: 4),
          Text(
            'Try switching categories or clearing search filters.',
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

