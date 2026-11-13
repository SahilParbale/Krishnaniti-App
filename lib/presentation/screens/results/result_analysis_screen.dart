import '../../navigation/app_bar_leading_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/election_result_model.dart';
import '../../../data/repositories/election_results_repository.dart';
import '../../navigation/app_drawer.dart';
import 'result_analysis_report_generator.dart';

class ResultAnalysisScreen extends ConsumerStatefulWidget {
  const ResultAnalysisScreen({super.key});

  @override
  ConsumerState<ResultAnalysisScreen> createState() => _ResultAnalysisScreenState();
}

class _ResultAnalysisScreenState extends ConsumerState<ResultAnalysisScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  String _selectedWard = '';
  List<String> _availableWards = [];

  String _selectedCandidate = '';
  List<String> _availableCandidates = [];

  List<ElectionResultModel> _results = [];
  String _boothFilter = 'all'; // 'all', 'winning', 'losing'
  String _displayMode = 'cards'; // 'cards' or 'table'

  @override
  void initState() {
    super.initState();
    _loadWardsAndResults();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWardsAndResults() async {
    setState(() => _isLoading = true);
    final repo = ref.read(electionResultsRepoProvider);

    final wards = await repo.getWards();
    _availableWards = wards;

    if (wards.isNotEmpty && (_selectedWard.isEmpty || !wards.contains(_selectedWard))) {
      _selectedWard = wards.first;
    }

    if (_selectedWard.isNotEmpty) {
      final results = await repo.getResults(ward: _selectedWard);
      _results = results;

      final candidates = await repo.getCandidates(_selectedWard);
      _availableCandidates = candidates;

      // Select candidate with highest overall votes by default
      if (candidates.isNotEmpty) {
        if (!_availableCandidates.contains(_selectedCandidate)) {
          String bestCandidate = candidates.first;
          int maxVotes = -1;
          for (final c in candidates) {
            final total = results.fold<int>(0, (sum, r) => sum + r.votesFor(c));
            if (total > maxVotes) {
              maxVotes = total;
              bestCandidate = c;
            }
          }
          _selectedCandidate = bestCandidate;
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onWardChanged(String? newWard) async {
    if (newWard == null || newWard == _selectedWard) return;
    setState(() {
      _selectedWard = newWard;
      _isLoading = true;
    });

    final repo = ref.read(electionResultsRepoProvider);
    final results = await repo.getResults(ward: newWard);
    final candidates = await repo.getCandidates(newWard);

    _results = results;
    _availableCandidates = candidates;

    if (candidates.isNotEmpty) {
      String bestCandidate = candidates.first;
      int maxVotes = -1;
      for (final c in candidates) {
        final total = results.fold<int>(0, (sum, r) => sum + r.votesFor(c));
        if (total > maxVotes) {
          maxVotes = total;
          bestCandidate = c;
        }
      }
      _selectedCandidate = bestCandidate;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onCandidateChanged(String? newCandidate) {
    if (newCandidate == null || newCandidate == _selectedCandidate) return;
    setState(() {
      _selectedCandidate = newCandidate;
    });
  }

  // Filtered booth list
  List<ElectionResultModel> get _filteredBooths {
    var list = _results.where((r) =>
        r.boothNumber != 'एकूण मत' &&
        r.boothNumber != 'टपाल मतदान' &&
        r.boothNumber != 'सर्व मतदान केंद्र नोंदवण्यात आलेली मते').toList();

    // Search query filter
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((b) {
        return b.boothNumber.toLowerCase().contains(q) ||
            b.boothName.toLowerCase().contains(q) ||
            b.winner.toLowerCase().contains(q);
      }).toList();
    }

    // Tab filter
    if (_boothFilter == 'winning') {
      list = list.where((b) => b.isWinner(_selectedCandidate)).toList();
    } else if (_boothFilter == 'losing') {
      list = list.where((b) => !b.isWinner(_selectedCandidate)).toList();
    }

    // Sort numerically
    list.sort((a, b) {
      final aMatch = RegExp(r'\d+').firstMatch(a.boothNumber);
      final bMatch = RegExp(r'\d+').firstMatch(b.boothNumber);
      if (aMatch != null && bMatch != null) {
        return int.parse(aMatch.group(0)!).compareTo(int.parse(bMatch.group(0)!));
      }
      return a.boothNumber.compareTo(b.boothNumber);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    // Aggregated stats
    final totalVotesRow = _results.where((r) => r.boothNumber == 'एकूण मत').firstOrNull;
    final totalVotes = totalVotesRow != null
        ? totalVotesRow.totalVotesCasted
        : _results.fold<int>(0, (sum, r) => sum + r.totalVotesCasted);

    final ourVotes = totalVotesRow != null
        ? totalVotesRow.votesFor(_selectedCandidate)
        : _results.fold<int>(0, (sum, r) => sum + r.votesFor(_selectedCandidate));

    final voteShare = totalVotes > 0 ? (ourVotes / totalVotes) * 100 : 0.0;
    final winningBooths = _results.where((r) => r.isWinner(_selectedCandidate)).length;
    final losingBooths = _results.isNotEmpty ? (_results.length - winningBooths) : 0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NagarsevakAppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF0284C7)),
                  SizedBox(height: 16),
                  Text(
                    'Loading election results data...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadWardsAndResults,
              color: const Color(0xFF0284C7),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card with Ward & Candidate Selectors
                    _buildHeaderSelectorsCard(),

                    const SizedBox(height: 16),

                    // 4 KPI Stat Cards
                    _buildKpiStatsGrid(ourVotes, totalVotes, voteShare, winningBooths, losingBooths),

                    const SizedBox(height: 20),

                    // Booths Performance Section Header & View Switcher
                    _buildSectionControls(),

                    const SizedBox(height: 12),

                    // Content: Cards or Table
                    if (_filteredBooths.isEmpty)
                      _buildEmptyState()
                    else if (_displayMode == 'table' || isDesktop)
                      _buildTableView()
                    else
                      _buildCardsView(),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBoothDialog,
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_chart_rounded, color: Colors.white),
        label: const Text(
          'Add Result',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0284C7),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: const AppBarLeadingNavButton(),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Result Analysis',
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
            'Election results & booth margins',
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
    );
  }

  Widget _buildHeaderSelectorsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: Color(0xFF0284C7), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Report',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _selectedCandidate.isNotEmpty ? _selectedCandidate : 'Select Candidate',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0369A1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 20),
                    tooltip: 'Help Guide',
                    visualDensity: VisualDensity.compact,
                    onPressed: _showHelpGuide,
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
                    tooltip: 'Download PDF Report',
                    visualDensity: VisualDensity.compact,
                    onPressed: _exportPdfReport,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Dropdowns Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Flex(
                direction: isNarrow ? Axis.vertical : Axis.horizontal,
                children: [
                  // Ward Selector
                  Expanded(
                    flex: isNarrow ? 0 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Ward:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _availableWards.contains(_selectedWard) ? _selectedWard : null,
                              hint: const Text('Select Ward', style: TextStyle(fontSize: 13)),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0284C7)),
                              items: _availableWards.map((w) {
                                return DropdownMenuItem(
                                  value: w,
                                  child: Text(
                                    w,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: _onWardChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isNarrow) const SizedBox(height: 12) else const SizedBox(width: 14),

                  // Candidate Selector
                  Expanded(
                    flex: isNarrow ? 0 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analyze for Candidate:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _availableCandidates.contains(_selectedCandidate) ? _selectedCandidate : null,
                              hint: const Text('Select Candidate', style: TextStyle(fontSize: 13)),
                              icon: const Icon(Icons.person_pin_rounded, color: Color(0xFF0284C7)),
                              items: _availableCandidates.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: _onCandidateChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStatsGrid(int ourVotes, int totalVotes, double voteShare, int winningBooths, int losingBooths) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final cardTotalVotes = _buildKpiCard(
          title: 'Total Votes',
          value: NumberFormat('#,##,###').format(ourVotes),
          subtitle: 'Out of ${NumberFormat('#,##,###').format(totalVotes)} Total',
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF3B82F6),
          cardBg: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
        );

        final cardVoteShare = _buildKpiCard(
          title: 'Vote Share',
          value: '${voteShare.toStringAsFixed(1)}%',
          subtitle: 'Percentage of total ward votes',
          icon: Icons.pie_chart_rounded,
          iconColor: const Color(0xFFA855F7),
          cardBg: const Color(0xFFFAF5FF),
          borderColor: const Color(0xFFE9D5FF),
          progressPercent: voteShare / 100,
        );

        final cardWinning = _buildKpiCard(
          title: 'Winning Booths',
          value: '$winningBooths',
          subtitle: 'Strongholds',
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF16A34A),
          cardBg: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
        );

        final cardLosing = _buildKpiCard(
          title: 'Losing Booths',
          value: '$losingBooths',
          subtitle: 'Needs Work / Trailing',
          icon: Icons.cancel_rounded,
          iconColor: const Color(0xFFDC2626),
          cardBg: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cardTotalVotes),
              const SizedBox(width: 12),
              Expanded(child: cardVoteShare),
              const SizedBox(width: 12),
              Expanded(child: cardWinning),
              const SizedBox(width: 12),
              Expanded(child: cardLosing),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cardTotalVotes),
                const SizedBox(width: 12),
                Expanded(child: cardVoteShare),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: cardWinning),
                const SizedBox(width: 12),
                Expanded(child: cardLosing),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
    double? progressPercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: iconColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (progressPercent != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                minHeight: 5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionControls() {
    return Column(
      children: [
        // Title Row with View Toggles and PDF button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.how_to_vote_rounded, color: Color(0xFF0284C7), size: 20),
                SizedBox(width: 8),
                Text(
                  'Booth-wise Result Performance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            Row(
              children: [
                // Cards / Table toggle
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton(
                        icon: Icons.view_agenda_outlined,
                        tooltip: 'Cards View',
                        isSelected: _displayMode == 'cards',
                        onTap: () => setState(() => _displayMode = 'cards'),
                      ),
                      _buildToggleButton(
                        icon: Icons.table_chart_outlined,
                        tooltip: 'Table View',
                        isSelected: _displayMode == 'table',
                        onTap: () => setState(() => _displayMode = 'table'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _exportPdfReport,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    backgroundColor: const Color(0xFFF0F9FF),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text(
                    'PDF Report',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Search bar
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search by booth number or school name...',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Filter chips: All / Strongholds / Needs work
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'All Booths (${_results.where((r) => r.boothNumber != "एकूण मत" && r.boothNumber != "Total").length})'),
              const SizedBox(width: 8),
              _buildFilterChip('winning', 'Strongholds (${_results.where((r) => r.isWinner(_selectedCandidate)).length})'),
              const SizedBox(width: 8),
              _buildFilterChip('losing', 'Needs Work (${_results.where((r) => !r.isWinner(_selectedCandidate) && r.boothNumber != "एकूण मत" && r.boothNumber != "Total").length})'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _boothFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _boothFilter = key),
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

  Widget _buildCardsView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredBooths.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booth = _filteredBooths[index];
        final isWin = booth.isWinner(_selectedCandidate);
        final candidateVotes = booth.votesFor(_selectedCandidate);
        final voteShare = booth.voteShareFor(_selectedCandidate);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isWin ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
              width: isWin ? 1.5 : 1,
            ),
          ),
          color: Colors.white,
          child: InkWell(
            onTap: () => _showBoothDetailDialog(booth),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Booth Number & Status Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          'Booth No. ${booth.boothNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isWin ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isWin ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isWin ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                              size: 14,
                              color: isWin ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isWin ? 'Lead (+${booth.margin})' : 'Trail (${booth.winner})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isWin ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Booth Name
                  Text(
                    booth.boothName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Candidate Vote Progress & Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCandidate,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$candidateVotes votes (${voteShare.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total Votes',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${booth.totalVotesCasted} / ${booth.totalVoters > 0 ? booth.totalVoters : "-"}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Progress Bar for Selected Candidate
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (voteShare / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isWin ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                      ),
                      minHeight: 6,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Runner Up or Winner Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Winner: ${booth.winner}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isWin ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          fontWeight: isWin ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Margin: +${booth.margin} votes',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView() {
    final candidates = _availableCandidates;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: [
              const DataColumn(
                label: Text(
                  'Booth No.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              const DataColumn(
                label: Text(
                  'Polling Station / Venue',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              ...candidates.map((c) {
                final isSelected = c == _selectedCandidate;
                return DataColumn(
                  label: Text(
                    c,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                    ),
                  ),
                );
              }),
              const DataColumn(
                label: Text(
                  'Total Votes',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              const DataColumn(
                label: Text(
                  'Winner',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              const DataColumn(
                label: Text(
                  'Margin',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
            ],
            rows: _filteredBooths.map((booth) {
              final isWin = booth.isWinner(_selectedCandidate);

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (isWin) return const Color(0xFFF0FDF4).withOpacity(0.4);
                  return null;
                }),
                cells: [
                  DataCell(
                    Text(
                      booth.boothNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        booth.boothName,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ...candidates.map((c) {
                    final votes = booth.votesFor(c);
                    final isCandidateWinner = booth.isWinner(c);
                    final isCandidateSelected = c == _selectedCandidate;

                    Color textColor = const Color(0xFF475569);
                    FontWeight fontWeight = FontWeight.normal;

                    if (isCandidateWinner) {
                      textColor = const Color(0xFF15803D);
                      fontWeight = FontWeight.bold;
                    } else if (isCandidateSelected) {
                      textColor = const Color(0xFF0284C7);
                      fontWeight = FontWeight.w600;
                    }

                    return DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCandidateWinner
                              ? const Color(0xFFDCFCE7)
                              : (isCandidateSelected ? const Color(0xFFE0F2FE) : Colors.transparent),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$votes',
                          style: TextStyle(color: textColor, fontWeight: fontWeight),
                        ),
                      ),
                    );
                  }),
                  DataCell(
                    Text(
                      '${booth.totalVotesCasted}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  DataCell(
                    Text(
                      booth.winner,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: booth.isWinner(_selectedCandidate) ? const Color(0xFF15803D) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '+${booth.margin}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No polling booths found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please try different search keywords or filters',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _showBoothDetailDialog(ElectionResultModel booth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booth No. ${booth.boothNumber}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booth.boothName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Statistics Summary
            Row(
              children: [
                _buildStatPill('Total Voters', '${booth.totalVoters > 0 ? booth.totalVoters : "-"}'),
                const SizedBox(width: 8),
                _buildStatPill('Votes Casted', '${booth.totalVotesCasted}'),
                const SizedBox(width: 8),
                _buildStatPill('Turnout %', '${booth.turnoutPercentage.toStringAsFixed(1)}%'),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Candidate Votes Breakdown',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 10),

            // Candidates vote list
            ...booth.candidateVotes.entries.map((entry) {
              final cName = entry.key;
              final votes = entry.value;
              final percent = booth.totalVotesCasted > 0 ? (votes / booth.totalVotesCasted) * 100 : 0.0;
              final isWinner = booth.isWinner(cName);
              final isSelected = cName == _selectedCandidate;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (isWinner)
                              const Icon(Icons.stars_rounded, size: 16, color: Color(0xFF16A34A)),
                            if (isWinner) const SizedBox(width: 4),
                            Text(
                              cName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isWinner || isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isWinner
                                    ? const Color(0xFF15803D)
                                    : (isSelected ? const Color(0xFF0284C7) : const Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$votes votes (${percent.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isWinner ? const Color(0xFF15803D) : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isWinner
                              ? const Color(0xFF16A34A)
                              : (isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8)),
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  void _showHelpGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Election Results Analysis Guide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Select Ward & Candidate:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'Select your ward and the candidate you wish to analyze from the dropdowns above.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              SizedBox(height: 12),
              Text(
                '2. Strongholds & Trailing Booths:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'Booths where your selected candidate gained the highest votes are highlighted as Strongholds (in green). Other booths are categorized as Needs Work (in amber/red).',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              SizedBox(height: 12),
              Text(
                '3. Table & Card Views:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'Switch between responsive mobile Cards view and full Table view using the toggle buttons above.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              SizedBox(height: 12),
              Text(
                '4. Official PDF Report:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'Click "Download PDF" to generate and print a full landscape A4 performance audit report.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdfReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating official election results PDF report...'),
          duration: Duration(seconds: 2),
        ),
      );

      await ResultAnalysisReportGenerator.generateAndPrintReport(
        ward: _selectedWard,
        selectedCandidate: _selectedCandidate,
        results: _results,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openAddBoothDialog() {
    final boothNumCtrl = TextEditingController();
    final boothNameCtrl = TextEditingController();
    final totalVotersCtrl = TextEditingController(text: '1000');
    final Map<String, TextEditingController> candidateControllers = {};

    for (final c in _availableCandidates) {
      candidateControllers[c] = TextEditingController(text: '0');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Polling Booth Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: boothNumCtrl,
                decoration: const InputDecoration(
                  labelText: 'Booth Number (e.g. 12/15)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: boothNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Polling Station / School Venue',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: totalVotersCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Registered Voters',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Candidate Votes Received:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...candidateControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: entry.value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final num = boothNumCtrl.text.trim();
              final name = boothNameCtrl.text.trim();
              if (num.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              Map<String, int> votesMap = {};
              int totalCast = 0;
              String bestCand = '';
              int bestVotes = -1;
              int secondBestVotes = 0;

              candidateControllers.forEach((c, ctrl) {
                final v = int.tryParse(ctrl.text.trim()) ?? 0;
                votesMap[c] = v;
                totalCast += v;
                if (v > bestVotes) {
                  secondBestVotes = bestVotes;
                  bestVotes = v;
                  bestCand = c;
                } else if (v > secondBestVotes) {
                  secondBestVotes = v;
                }
              });

              final newResult = ElectionResultModel(
                id: 'res-${DateTime.now().millisecondsSinceEpoch}',
                wardName: _selectedWard,
                boothNumber: num,
                boothName: name,
                totalVoters: int.tryParse(totalVotersCtrl.text.trim()) ?? totalCast,
                totalVotesCasted: totalCast,
                candidateVotes: votesMap,
                winner: bestCand,
                margin: (bestVotes - secondBestVotes).clamp(0, 999999),
                createdAt: DateTime.now(),
              );

              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(electionResultsRepoProvider);
              await repo.addResult(newResult);

              Navigator.pop(ctx);
              await _loadWardsAndResults();

              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Polling booth result saved successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

