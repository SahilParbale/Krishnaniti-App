import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import '../../../../data/models/election_result_model.dart';
import '../../../../data/repositories/election_results_repository.dart';
import '../../../screens/results/result_analysis_report_generator.dart';
import '../../../widgets/app_dropdown.dart';

class DesktopResultAnalysisView extends ConsumerStatefulWidget {
  const DesktopResultAnalysisView({super.key});

  @override
  ConsumerState<DesktopResultAnalysisView> createState() => _DesktopResultAnalysisViewState();
}

class _DesktopResultAnalysisViewState extends ConsumerState<DesktopResultAnalysisView> {
  bool _loading = true;
  String _selectedWard = '';
  List<String> _availableWards = [];
  List<ElectionResultModel> _results = [];
  String _selectedCandidate = '';
  List<String> _availableCandidates = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(electionResultsRepoProvider);
      final wards = await repo.getWards();
      _availableWards = wards.isNotEmpty ? wards : ['Ward 12', 'Ward 13', 'Ward 14'];
      _selectedWard = _availableWards.first;

      await _loadResultsForWard(_selectedWard);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadResultsForWard(String ward) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(electionResultsRepoProvider);
      final data = await repo.getResults(ward: ward);
      _results = data;

      if (_results.isNotEmpty) {
        _availableCandidates = _results.first.candidateVotes.keys.toList();
        if (!_availableCandidates.contains(_selectedCandidate) && _availableCandidates.isNotEmpty) {
          // Find candidate with max votes
          String bestCand = _availableCandidates.first;
          int maxVotes = -1;
          for (final c in _availableCandidates) {
            final total = _results.fold<int>(0, (sum, r) => sum + r.votesFor(c));
            if (total > maxVotes) {
              maxVotes = total;
              bestCand = c;
            }
          }
          _selectedCandidate = bestCand;
        }
      } else {
        _availableCandidates = [];
        _selectedCandidate = '';
      }
    } catch (_) {
      _results = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes = _results.fold<int>(0, (sum, r) => sum + r.totalVotesCasted);
    final ourVotes = _results.fold<int>(0, (sum, r) => sum + r.votesFor(_selectedCandidate));
    final voteShare = totalVotes > 0 ? (ourVotes / totalVotes) * 100 : 0.0;
    final winningBooths = _results.where((r) => r.isWinner(_selectedCandidate)).length;
    final losingBooths = _results.length - winningBooths;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          if (_loading)
            _buildLoadingState()
          else if (_results.isEmpty)
            _buildEmptyState()
          else ...[
            // Stats Row
            _buildStatsRow(totalVotes, ourVotes, voteShare, winningBooths, losingBooths),
            const SizedBox(height: 24),

            // Detailed Booth Performance Table
            _buildBoothPerformanceTable(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Result Analysis',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Election Performance Report: ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                Text(
                  _selectedCandidate.isEmpty ? 'All Candidates' : _selectedCandidate,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
              ],
            ),
          ],
        ),

        // Controls
        Row(
          children: [
            // Ward Dropdown
            AppDropdown<String>(
              value: _availableWards.contains(_selectedWard) ? _selectedWard : null,
              height: 40,
              width: 160,
              label: 'Ward',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
              items: _availableWards.map((w) {
                return DropdownMenuItem(value: w, child: Text(w));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedWard = val);
                  _loadResultsForWard(val);
                }
              },
            ),
            const SizedBox(width: 12),

            // Candidate Dropdown
            if (_availableCandidates.isNotEmpty)
              AppDropdown<String>(
                value: _availableCandidates.contains(_selectedCandidate) ? _selectedCandidate : null,
                height: 40,
                width: 180,
                label: 'Candidate',
                prefixIcon: const Icon(Icons.person_outline, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: _availableCandidates.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCandidate = val);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(int totalVotes, int ourVotes, double voteShare, int winningBooths, int losingBooths) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Votes Received',
                value: ourVotes.toString(),
                subtitle: 'Total out of $totalVotes votes polled',
                icon: Icons.people_alt_outlined,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFF0F9FF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Vote Share %',
                value: '${voteShare.toStringAsFixed(1)}%',
                subtitle: 'Share of total votes cast',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: const Color(0xFF9333EA),
                iconBg: const Color(0xFFFAF5FF),
                progress: voteShare / 100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Strongholds',
                value: winningBooths.toString(),
                subtitle: 'Booths leading in vote count',
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFF0FDF4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Trailing Booths',
                value: losingBooths.toString(),
                subtitle: 'Booths requiring strategic outreach',
                icon: Icons.cancel_outlined,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEF2F2),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildBoothPerformanceTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table header bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Booth Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(100)),
                      child: Text('${_results.length} Booths', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ResultAnalysisReportGenerator.generateAndPrintReport(
                      context: context,
                      ward: _selectedWard,
                      selectedCandidate: _selectedCandidate,
                      results: _results,
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
                  label: Text(
                    AppTranslations.getDownloadReport(ref.watch(desktopLanguageProvider)),
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
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 28,
              horizontalMargin: 24,
              columns: [
                const DataColumn(label: Text('Booth No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                ..._availableCandidates.map((c) => DataColumn(
                      label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                    )),
                const DataColumn(label: Text('Total Polled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                const DataColumn(label: Text('Winning Candidate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                const DataColumn(label: Text('Margin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
              ],
              rows: _results.map((r) {
                return DataRow(
                  cells: [
                    DataCell(Text(r.boothNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)))),
                    ..._availableCandidates.map((c) {
                      final votes = r.votesFor(c);
                      final isWin = r.isWinner(c);
                      final isSelected = c == _selectedCandidate;

                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isWin ? const Color(0xFFDCFCE7) : (isSelected ? const Color(0xFFF0F9FF) : Colors.transparent),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            votes.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: (isWin || isSelected) ? FontWeight.bold : FontWeight.normal,
                              color: isWin ? const Color(0xFF15803D) : (isSelected ? const Color(0xFF0369A1) : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      );
                    }),
                    DataCell(Text(r.totalVotesCasted.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)))),
                    DataCell(
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFEAB308)),
                          const SizedBox(width: 4),
                          Text(r.winner, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: Text('+${r.margin}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.how_to_vote_outlined, size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          const Text('No Election Results Available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          SizedBox(height: 6),
          const Text('Election results data has not been uploaded yet.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}
