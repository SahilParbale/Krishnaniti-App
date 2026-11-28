import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/election_result_model.dart';
import '../../../data/repositories/election_results_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
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

  String _formatIndianCount(int n, String lang) {
    final s = n.toString();
    String formatted;
    if (s.length <= 3) {
      formatted = s;
    } else {
      final last3 = s.substring(s.length - 3);
      final rest = s.substring(0, s.length - 3);
      final restFormatted = rest.replaceAllMapped(RegExp(r'\B(?=(\d{2})+(?!\d))'), (_) => ',');
      formatted = '$restFormatted,$last3';
    }
    return AppTranslations.formatDigits(formatted, lang);
  }

  // Filtered booth list
  List<ElectionResultModel> get _filteredBooths {
    var list = _results.where((r) =>
        r.boothNumber != 'एकूण मत' &&
        r.boothNumber != 'टपाल मतदान' &&
        r.boothNumber != 'सर्व मतदान केंद्र नोंदवण्यात आलेली मते').toList();

    // Search query filter
    final q = _searchCtrl.text.trim().toLowerCase();
    final normQ = AppTranslations.normalizeAsciiDigits(q);
    if (q.isNotEmpty) {
      list = list.where((b) {
        final bn = b.boothNumber.toLowerCase();
        return bn.contains(q) ||
            AppTranslations.normalizeAsciiDigits(bn).contains(normQ) ||
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
    final lang = ref.watch(appLanguageProvider);
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
      appBar: _buildAppBar(lang),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF0284C7)),
                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Loading election results data...',
                      mr: 'निवडणूक निकालांची माहिती लोड होत आहे...',
                      hi: 'चुनाव परिणाम डेटा लोड हो रहा है...',
                    ),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
                    _buildHeaderSelectorsCard(lang),

                    const SizedBox(height: 16),

                    // 4 KPI Stat Cards
                    _buildKpiStatsGrid(ourVotes, totalVotes, voteShare, winningBooths, losingBooths, lang),

                    const SizedBox(height: 20),

                    // Booths Performance Section Header & View Switcher
                    _buildSectionControls(lang),

                    const SizedBox(height: 12),

                    // Content: Cards or Table
                    if (_filteredBooths.isEmpty)
                      _buildEmptyState(lang)
                    else if (_displayMode == 'table' || isDesktop)
                      _buildTableView(lang)
                    else
                      _buildCardsView(lang),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(String lang) {
    return AppBar(
      backgroundColor: const Color(0xFF0284C7),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
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
            AppTranslations.pick(
              lang,
              en: 'Result Analysis',
              mr: 'निकाल विश्लेषण',
              hi: 'परिणाम विश्लेषण',
            ),
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
            AppTranslations.pick(
              lang,
              en: 'Election results & booth margins',
              mr: 'निवडणूक निकाल आणि बूथ मताधिक्य',
              hi: 'चुनावी परिणाम और बूथ अंतर',
            ),
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
      actions: const [],
    );
  }

  Widget _buildHeaderSelectorsCard(String lang) {
    final selectCandidateLabel = AppTranslations.pick(
      lang,
      en: 'Select Candidate',
      mr: 'उमेदवार निवडा',
      hi: 'उम्मीदवार चुनें',
    );
    final selectWardLabel = AppTranslations.pick(
      lang,
      en: 'Select Ward',
      mr: 'प्रभाग निवडा',
      hi: 'वार्ड चुनें',
    );
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
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Performance Report',
                        mr: 'कामगिरी अहवाल',
                        hi: 'प्रदर्शन रिपोर्ट',
                      ),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    if (_selectedCandidate.isNotEmpty)
                      AppTranslatedText(
                        _selectedCandidate,
                        targetLanguage: lang,
                        isName: true,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369A1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        selectCandidateLabel,
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
                  const SizedBox(width: 4),
                  AppPdfButton.icon(
                    tooltip: AppTranslations.getDownloadReport(lang),
                    onPressed: () => _exportPdfReport(lang),
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
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Select Ward:',
                            mr: 'प्रभाग निवडा:',
                            hi: 'वार्ड चुनें:',
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        AppDropdown<String>(
                          title: selectWardLabel,
                          value: _availableWards.contains(_selectedWard) ? _selectedWard : null,
                          hint: selectWardLabel,
                          items: _availableWards.map((w) {
                            return DropdownMenuItem(
                              value: w,
                              child: AppTranslatedText(
                                w,
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _onWardChanged,
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
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Analyze for Candidate:',
                            mr: 'उमेदवाराचे विश्लेषण:',
                            hi: 'उम्मीदवार का विश्लेषण:',
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        AppDropdown<String>(
                          title: selectCandidateLabel,
                          value: _availableCandidates.contains(_selectedCandidate) ? _selectedCandidate : null,
                          hint: selectCandidateLabel,
                          prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF0284C7), size: 18),
                          items: _availableCandidates.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: AppTranslatedText(
                                c,
                                targetLanguage: lang,
                                isName: true,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _onCandidateChanged,
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

  Widget _buildKpiStatsGrid(int ourVotes, int totalVotes, double voteShare, int winningBooths, int losingBooths, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final cardTotalVotes = _buildKpiCard(
          title: AppTranslations.pick(lang, en: 'Total Votes', mr: 'एकूण मते', hi: 'कुल मत'),
          value: _formatIndianCount(ourVotes, lang),
          subtitle: AppTranslations.pick(
            lang,
            en: 'Out of ${_formatIndianCount(totalVotes, lang)} Total',
            mr: 'एकूण ${_formatIndianCount(totalVotes, lang)} पैकी',
            hi: 'कुल ${_formatIndianCount(totalVotes, lang)} में से',
          ),
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF3B82F6),
          cardBg: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
        );

        final cardVoteShare = _buildKpiCard(
          title: AppTranslations.pick(lang, en: 'Vote Share', mr: 'मत हिस्सा', hi: 'मत प्रतिशत'),
          value: '${AppTranslations.formatDigits(voteShare.toStringAsFixed(1), lang)}%',
          subtitle: AppTranslations.pick(
            lang,
            en: 'Percentage of total ward votes',
            mr: 'एकूण प्रभाग मतांची टक्केवारी',
            hi: 'कुल वार्ड मतों का प्रतिशत',
          ),
          icon: Icons.pie_chart_rounded,
          iconColor: const Color(0xFFA855F7),
          cardBg: const Color(0xFFFAF5FF),
          borderColor: const Color(0xFFE9D5FF),
          progressPercent: voteShare / 100,
        );

        final cardWinning = _buildKpiCard(
          title: AppTranslations.pick(lang, en: 'Winning Booths', mr: 'विजयी मतदान केंद्रे', hi: 'विजयी बूथ'),
          value: AppTranslations.formatDigits('$winningBooths', lang),
          subtitle: AppTranslations.pick(lang, en: 'Strongholds', mr: 'बालेकिल्ले / भक्कम केंद्र', hi: 'मजबूत बूथ'),
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF16A34A),
          cardBg: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
        );

        final cardLosing = _buildKpiCard(
          title: AppTranslations.pick(lang, en: 'Losing Booths', mr: 'पिछाडीची मतदान केंद्रे', hi: 'पिछड़ते बूथ'),
          value: AppTranslations.formatDigits('$losingBooths', lang),
          subtitle: AppTranslations.pick(lang, en: 'Needs Work / Trailing', mr: 'लक्ष आवश्यक / पिछाडीवर', hi: 'सुधार आवश्यक / पीछे'),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: iconColor,
                letterSpacing: -0.5,
              ),
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

  Widget _buildSectionControls(String lang) {
    final allBoothCount = _results.where((r) => r.boothNumber != "एकूण मत" && r.boothNumber != "Total").length;
    final winCount = _results.where((r) => r.isWinner(_selectedCandidate)).length;
    final loseCount = _results.where((r) => !r.isWinner(_selectedCandidate) && r.boothNumber != "एकूण मत" && r.boothNumber != "Total").length;
    return Column(
      children: [
        // Title Row with View Toggles and PDF button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.how_to_vote_rounded, color: Color(0xFF0284C7), size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Booth-wise Result Performance',
                        mr: 'बूथनिहाय निकाल कामगिरी',
                        hi: 'बूथ-वार परिणाम प्रदर्शन',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
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
                        tooltip: AppTranslations.pick(lang, en: 'Cards View', mr: 'कार्ड दृश्य', hi: 'कार्ड दृश्य'),
                        isSelected: _displayMode == 'cards',
                        onTap: () => setState(() => _displayMode = 'cards'),
                      ),
                      _buildToggleButton(
                        icon: Icons.table_chart_outlined,
                        tooltip: AppTranslations.pick(lang, en: 'Table View', mr: 'तक्ता दृश्य', hi: 'तालिका दृश्य'),
                        isSelected: _displayMode == 'table',
                        onTap: () => setState(() => _displayMode = 'table'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppPdfButton.outlined(
                  label: AppTranslations.getDownloadReport(lang),
                  onPressed: () => _exportPdfReport(lang),
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
            hintText: AppTranslations.pick(
              lang,
              en: 'Search by booth number or school name...',
              mr: 'बूथ क्रमांक किंवा शाळेच्या नावाने शोधा...',
              hi: 'बूथ संख्या या स्कूल के नाम से खोजें...',
            ),
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    tooltip: AppTranslations.pick(lang, en: 'Clear', mr: 'साफ करा', hi: 'साफ़ करें'),
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
              _buildFilterChip('all', '${AppTranslations.pick(lang, en: 'All Booths', mr: 'सर्व मतदान केंद्रे', hi: 'सभी बूथ')} (${AppTranslations.formatDigits('$allBoothCount', lang)})'),
              const SizedBox(width: 8),
              _buildFilterChip('winning', '${AppTranslations.pick(lang, en: 'Strongholds', mr: 'बालेकिल्ले', hi: 'मजबूत बूथ')} (${AppTranslations.formatDigits('$winCount', lang)})'),
              const SizedBox(width: 8),
              _buildFilterChip('losing', '${AppTranslations.pick(lang, en: 'Needs Work', mr: 'लक्ष आवश्यक', hi: 'सुधार आवश्यक')} (${AppTranslations.formatDigits('$loseCount', lang)})'),
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

  Widget _buildCardsView(String lang) {
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
            onTap: () => _showBoothDetailDialog(booth, lang),
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
                          '${AppTranslations.pick(lang, en: 'Booth No.', mr: 'बूथ क्र.', hi: 'बूथ सं.')} ${AppTranslations.formatDigits(booth.boothNumber, lang)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Container(
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
                              isWin
                                  ? Text(
                                      '${AppTranslations.pick(lang, en: 'Lead', mr: 'आघाडी', hi: 'बढ़त')} (+${AppTranslations.formatDigits('${booth.margin}', lang)})',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    )
                                  : Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${AppTranslations.pick(lang, en: 'Trail', mr: 'पिछाडी', hi: 'पीछे')} (',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFB91C1C),
                                            ),
                                          ),
                                          Flexible(
                                            child: AppTranslatedText(
                                              booth.winner,
                                              targetLanguage: lang,
                                              isName: true,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFB91C1C),
                                              ),
                                            ),
                                          ),
                                          const Text(
                                            ')',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFB91C1C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Booth Name
                  AppTranslatedText(
                    booth.boothName,
                    targetLanguage: lang,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              _selectedCandidate,
                              targetLanguage: lang,
                              isName: true,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppTranslations.formatDigits('$candidateVotes', lang)} ${AppTranslations.pick(lang, en: 'votes', mr: 'मते', hi: 'मत')} (${AppTranslations.formatDigits(voteShare.toStringAsFixed(1), lang)}%)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppTranslations.pick(lang, en: 'Total Votes', mr: 'एकूण मते', hi: 'कुल मत'),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${AppTranslations.formatDigits('${booth.totalVotesCasted}', lang)} / ${booth.totalVoters > 0 ? AppTranslations.formatDigits('${booth.totalVoters}', lang) : "-"}',
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
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${AppTranslations.pick(lang, en: 'Winner', mr: 'विजेता', hi: 'विजेता')}: ',
                              style: TextStyle(
                                fontSize: 11,
                                color: isWin ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                fontWeight: isWin ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            Flexible(
                              child: AppTranslatedText(
                                booth.winner,
                                targetLanguage: lang,
                                isName: true,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isWin ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  fontWeight: isWin ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${AppTranslations.pick(lang, en: 'Margin', mr: 'फरक', hi: 'अंतर')}: +${AppTranslations.formatDigits('${booth.margin}', lang)} ${AppTranslations.pick(lang, en: 'votes', mr: 'मते', hi: 'मत')}',
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

  Widget _buildTableView(String lang) {
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
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Booth No.', mr: 'बूथ क्र.', hi: 'बूथ सं.'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Polling Station / Venue', mr: 'मतदान केंद्र / ठिकाण', hi: 'मतदान केंद्र / स्थान'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              ...candidates.map((c) {
                final isSelected = c == _selectedCandidate;
                return DataColumn(
                  label: AppTranslatedText(
                    c,
                    targetLanguage: lang,
                    isName: true,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                    ),
                  ),
                );
              }),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Total Votes', mr: 'एकूण मते', hi: 'कुल मत'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Winner', mr: 'विजेता', hi: 'विजेता'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Margin', mr: 'फरक', hi: 'अंतर'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
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
                      AppTranslations.formatDigits(booth.boothNumber, lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: AppTranslatedText(
                        booth.boothName,
                        targetLanguage: lang,
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
                          AppTranslations.formatDigits('$votes', lang),
                          style: TextStyle(color: textColor, fontWeight: fontWeight),
                        ),
                      ),
                    );
                  }),
                  DataCell(
                    Text(
                      AppTranslations.formatDigits('${booth.totalVotesCasted}', lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  DataCell(
                    AppTranslatedText(
                      booth.winner,
                      targetLanguage: lang,
                      isName: true,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: booth.isWinner(_selectedCandidate) ? const Color(0xFF15803D) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '+${AppTranslations.formatDigits('${booth.margin}', lang)}',
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

  Widget _buildEmptyState(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No polling booths found',
              mr: 'कोणतेही मतदान केंद्र सापडले नाही',
              hi: 'कोई मतदान केंद्र नहीं मिला',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Please try different search keywords or filters',
              mr: 'कृपया वेगळे शोध शब्द किंवा फिल्टर वापरून पहा',
              hi: 'कृपया अन्य खोज शब्द या फ़िल्टर आज़माएँ',
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _showBoothDetailDialog(ElectionResultModel booth, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. FIXED HEADER
            AppModalHeader(
              icon: Icons.how_to_vote_rounded,
              title: '${AppTranslations.pick(lang, en: 'Booth No.', mr: 'बूथ क्र.', hi: 'बूथ सं.')} ${AppTranslations.formatDigits(booth.boothNumber, lang)}',
              subtitle: DynamicTranslationService.getCachedTranslation(booth.boothName, lang) ?? booth.boothName,
              onClose: () => Navigator.pop(ctx),
            ),

            // 2. SCROLLABLE BREAKDOWN & CLOSE BUTTON
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                children: [
                  // Statistics Summary
                  Row(
                    children: [
                      _buildStatPill(
                        AppTranslations.pick(lang, en: 'Total Voters', mr: 'एकूण मतदार', hi: 'कुल मतदाता'),
                        booth.totalVoters > 0 ? AppTranslations.formatDigits('${booth.totalVoters}', lang) : '-',
                      ),
                      const SizedBox(width: 8),
                      _buildStatPill(
                        AppTranslations.pick(lang, en: 'Votes Casted', mr: 'झालेले मतदान', hi: 'पड़े मत'),
                        AppTranslations.formatDigits('${booth.totalVotesCasted}', lang),
                      ),
                      const SizedBox(width: 8),
                      _buildStatPill(
                        AppTranslations.pick(lang, en: 'Turnout %', mr: 'मतदान %', hi: 'मतदान %'),
                        '${AppTranslations.formatDigits(booth.turnoutPercentage.toStringAsFixed(1), lang)}%',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Candidate Votes Breakdown',
                      mr: 'उमेदवारनिहाय मतांचा तपशील',
                      hi: 'उम्मीदवार-वार मत विवरण',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
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
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (isWinner)
                                      const Icon(Icons.stars_rounded, size: 16, color: Color(0xFF16A34A)),
                                    if (isWinner) const SizedBox(width: 4),
                                    Flexible(
                                      child: AppTranslatedText(
                                        cName,
                                        targetLanguage: lang,
                                        isName: true,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isWinner || isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isWinner
                                              ? const Color(0xFF15803D)
                                              : (isSelected ? const Color(0xFF0284C7) : const Color(0xFF334155)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${AppTranslations.formatDigits('$votes', lang)} ${AppTranslations.pick(lang, en: 'votes', mr: 'मते', hi: 'मत')} (${AppTranslations.formatDigits(percent.toStringAsFixed(1), lang)}%)',
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
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
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
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Election Results Analysis Guide',
                  mr: 'निवडणूक निकाल विश्लेषण मार्गदर्शक',
                  hi: 'चुनाव परिणाम विश्लेषण मार्गदर्शिका',
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: '1. Select Ward & Candidate:',
                  mr: '१. प्रभाग आणि उमेदवार निवडा:',
                  hi: '१. वार्ड व उम्मीदवार चुनें:',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Select your ward and the candidate you wish to analyze from the dropdowns above.',
                  mr: 'वरील ड्रॉपडाउनमधून तुमचा प्रभाग आणि विश्लेषणासाठी उमेदवार निवडा.',
                  hi: 'ऊपर दिए गए ड्रॉपडाउन से अपना वार्ड व विश्लेषण के लिए उम्मीदवार चुनें।',
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.pick(
                  lang,
                  en: '2. Strongholds & Trailing Booths:',
                  mr: '२. बालेकिल्ले व पिछाडीची मतदान केंद्रे:',
                  hi: '२. मजबूत व पिछड़ते मतदान केंद्र:',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Booths where your selected candidate gained the highest votes are highlighted as Strongholds (in green). Other booths are categorized as Needs Work (in amber/red).',
                  mr: 'निवडलेल्या उमेदवारास सर्वाधिक मते मिळालेली केंद्रे बालेकिल्ले (हिरव्या रंगात) व इतर पिछाडीची केंद्रे लाल रंगात दिसतात.',
                  hi: 'जिन बूथों पर चयनित उम्मीदवार को सर्वाधिक मत मिले हैं वे हरे रंग में मजबूत बूथ के रूप में दिखते हैं।',
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.pick(
                  lang,
                  en: '3. Table & Card Views:',
                  mr: '३. तक्ता व कार्ड दृश्य:',
                  hi: '३. तालिका व कार्ड दृश्य:',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Switch between responsive mobile Cards view and full Table view using the toggle buttons above.',
                  mr: 'वरील बटणांद्वारे कार्ड आणि तक्ता स्वरूपात सहज बदला.',
                  hi: 'ऊपर दिए गए टॉगल से कार्ड और तालिका दृश्य के बीच बदलें।',
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.pick(
                  lang,
                  en: '4. Official PDF Report:',
                  mr: '४. अधिकृत पीडीएफ अहवाल:',
                  hi: '४. आधिकारिक पीडीएफ रिपोर्ट:',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Click "Download Report" to generate and print a full landscape A4 performance audit report.',
                  mr: 'संपूर्ण लँडस्केप A4 कामगिरी अहवाल डाउनलोड करण्यासाठी "अहवाल" वर क्लिक करा.',
                  hi: 'पूर्ण लैंडस्केप A4 प्रदर्शन ऑडिट रिपोर्ट डाउनलोड करने के लिए "रिपोर्ट डाउनलोड करें" पर क्लिक करें।',
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Got it', mr: 'समजले', hi: 'समझ गया'),
              style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdfReport(String lang) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Generating official election results PDF report...',
              mr: 'अधिकृत निवडणूक निकाल पीडीएफ अहवाल तयार होत आहे...',
              hi: 'आधिकारिक चुनाव परिणाम पीडीएफ रिपोर्ट तैयार हो रही है...',
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await ResultAnalysisReportGenerator.generateAndPrintReport(
        ward: _selectedWard,
        selectedCandidate: _selectedCandidate,
        results: _results,
        lang: lang,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.pick(lang, en: 'Error generating PDF', mr: 'पीडीएफ तयार करण्यात त्रुटी', hi: 'पीडीएफ बनाने में त्रुटि')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}
