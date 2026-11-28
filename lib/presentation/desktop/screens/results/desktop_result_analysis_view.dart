import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../../../data/models/election_result_model.dart';
import '../../../../data/repositories/election_results_repository.dart';
import '../../../screens/results/result_analysis_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

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
  int _displayedLimit = 20;
  List<ElectionResultModel> get _visibleResults =>
      _results.take(_displayedLimit).toList();
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
    setState(() {
      _displayedLimit = 20;
      _loading = true;
    });
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
    final lang = ref.watch(desktopLanguageProvider);
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
          _buildHeader(lang),
          const SizedBox(height: 24),

          if (_loading)
            _buildLoadingState()
          else if (_results.isEmpty)
            _buildEmptyState(lang)
          else ...[
            // Stats Row
            _buildStatsRow(totalVotes, ourVotes, voteShare, winningBooths, losingBooths, lang),
            const SizedBox(height: 24),

            // Detailed Booth Performance Table
            _buildBoothPerformanceTable(lang),
          ],
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
                  const Icon(Icons.bar_chart_rounded, size: 26, color: Color(0xFF0369A1)),
                  const SizedBox(width: 10),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Result Analysis',
                      mr: 'निकाल विश्लेषण',
                      hi: 'चुनाव परिणाम विश्लेषण',
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Election Performance Report: ',
                      mr: 'निवडणूक कामगिरी अहवाल: ',
                      hi: 'चुनाव प्रदर्शन रिपोर्ट: ',
                    ),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  Flexible(
                    child: _selectedCandidate.isEmpty
                        ? Text(
                            AppTranslations.pick(
                              lang,
                              en: 'All Candidates',
                              mr: 'सर्व उमेदवार',
                              hi: 'सभी उम्मीदवार',
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                          )
                        : AppTranslatedText(
                            _selectedCandidate,
                            isName: true,
                            targetLanguage: lang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Controls
        Row(
          children: [
            // Ward Dropdown
            AppDropdown<String>(
              value: _availableWards.contains(_selectedWard) ? _selectedWard : null,
              height: 40,
              width: 160,
              label: AppTranslations.pick(lang, en: 'Ward', mr: 'प्रभाग', hi: 'वार्ड'),
              prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
              items: _availableWards.map((w) {
                return DropdownMenuItem(
                  value: w,
                  child: AppTranslatedText(
                    AppTranslations.getAreaName(w, lang),
                    targetLanguage: lang,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
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
                label: AppTranslations.pick(lang, en: 'Candidate', mr: 'उमेदवार', hi: 'उम्मीदवार'),
                prefixIcon: const Icon(Icons.person_outline, size: 16, color: Color(0xFF94A3B8)),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                items: _availableCandidates.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: AppTranslatedText(
                      c,
                      isName: true,
                      targetLanguage: lang,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
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

  Widget _buildStatsRow(int totalVotes, int ourVotes, double voteShare, int winningBooths, int losingBooths, String lang) {
    final totalVotesStr = AppTranslations.formatDigits(totalVotes, lang);
    final ourVotesStr = AppTranslations.formatDigits(ourVotes, lang);
    final shareStr = AppTranslations.formatDigits('${voteShare.toStringAsFixed(1)}%', lang);
    final winStr = AppTranslations.formatDigits(winningBooths, lang);
    final loseStr = AppTranslations.formatDigits(losingBooths, lang);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: AppTranslations.pick(lang, en: 'Total Votes Received', mr: 'एकूण मिळालेली मते', hi: 'कुल प्राप्त मत'),
                value: ourVotesStr,
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Total out of $totalVotesStr votes polled',
                  mr: 'एकूण $totalVotesStr मतदानापैकी मते',
                  hi: 'कुल $totalVotesStr डाले गए मतों में से',
                ),
                icon: Icons.people_alt_outlined,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFF0F9FF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: AppTranslations.pick(lang, en: 'Vote Share %', mr: 'मतदानाची टक्केवारी %', hi: 'मत प्रतिशत %'),
                value: shareStr,
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Share of total votes cast',
                  mr: 'एकूण मतदानातील वाटा',
                  hi: 'कुल डाले गए मतों का हिस्सा',
                ),
                icon: Icons.pie_chart_outline_rounded,
                iconColor: const Color(0xFF9333EA),
                iconBg: const Color(0xFFFAF5FF),
                progress: voteShare / 100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: AppTranslations.pick(lang, en: 'Strongholds', mr: 'बालेकिल्ले (आघाडीचे बूथ)', hi: 'मजबूत गढ़ (आगे बूथ)'),
                value: winStr,
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Booths leading in vote count',
                  mr: 'मतमोजणीत आघाडीवर असलेले बूथ',
                  hi: 'मतगणना में आगे रहने वाले बूथ',
                ),
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFF0FDF4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: AppTranslations.pick(lang, en: 'Trailing Booths', mr: 'पिछाडीवरील बूथ', hi: 'पिछड़े हुए बूथ'),
                value: loseStr,
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Booths requiring strategic outreach',
                  mr: 'विशेष लक्ष देण्याची गरज असलेले बूथ',
                  hi: 'विशेष रणनीति की आवश्यकता वाले बूथ',
                ),
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildBoothPerformanceTable(String lang) {
    final boothCountStr = AppTranslations.formatDigits(_results.length, lang);
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
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Booth Performance',
                        mr: 'बूथनिहाय कामगिरी',
                        hi: 'बूथवार प्रदर्शन',
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(100)),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: '$boothCountStr Booths',
                          mr: '$boothCountStr बूथ',
                          hi: '$boothCountStr बूथ',
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
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
                DataColumn(
                  label: Text(
                    AppTranslations.pick(lang, en: 'Booth No', mr: 'बूथ क्र.', hi: 'बूथ सं.'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                  ),
                ),
                ..._availableCandidates.map((c) => DataColumn(
                      label: AppTranslatedText(
                        c,
                        isName: true,
                        targetLanguage: lang,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                      ),
                    )),
                DataColumn(
                  label: Text(
                    AppTranslations.pick(lang, en: 'Total Polled', mr: 'एकूण मतदान', hi: 'कुल मतदान'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                  ),
                ),
                DataColumn(
                  label: Text(
                    AppTranslations.pick(lang, en: 'Winning Candidate', mr: 'विजयी उमेदवार', hi: 'विजयी उम्मीदवार'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                  ),
                ),
                DataColumn(
                  label: Text(
                    AppTranslations.pick(lang, en: 'Margin', mr: 'मताधिक्य', hi: 'जीत का अंतर'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                  ),
                ),
              ],
              rows: _visibleResults.map((r) {
                return DataRow(
                  cells: [
                    DataCell(
                      AppTranslatedText(
                        r.boothNumber,
                        targetLanguage: lang,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ),
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
                            AppTranslations.formatDigits(votes, lang),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: (isWin || isSelected) ? FontWeight.bold : FontWeight.normal,
                              color: isWin ? const Color(0xFF15803D) : (isSelected ? const Color(0xFF0369A1) : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      );
                    }),
                    DataCell(
                      Text(
                        AppTranslations.formatDigits(r.totalVotesCasted, lang),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFEAB308)),
                          const SizedBox(width: 4),
                          AppTranslatedText(
                            r.winner,
                            isName: true,
                            targetLanguage: lang,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          '+${AppTranslations.formatDigits(r.margin, lang)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (!_loading && _results.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: _visibleResults.length,
              totalCount: _results.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(
                lang,
                en: 'booths',
                mr: 'बूथ',
                hi: 'बूथ',
              ),
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
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
          const Icon(Icons.how_to_vote_outlined, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No Election Results Available',
              mr: 'निवडणूक निकाल उपलब्ध नाहीत',
              hi: 'चुनाव परिणाम उपलब्ध नहीं हैं',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Election results data has not been uploaded yet.',
              mr: 'निवडणूक निकालाचा डेटा अद्याप अपलोड केलेला नाही.',
              hi: 'चुनाव परिणाम डेटा अभी तक अपलोड नहीं किया गया है।',
            ),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
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
