import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/duplicate_voter_group_model.dart';
import '../../../data/repositories/duplicate_voters_repository.dart';
import '../voters/voter_profile_screen.dart';
import 'duplicate_voters_report_generator.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';

class DuplicateVotersScreen extends ConsumerStatefulWidget {
  const DuplicateVotersScreen({super.key});

  @override
  ConsumerState<DuplicateVotersScreen> createState() => _DuplicateVotersScreenState();
}

class _DuplicateVotersScreenState extends ConsumerState<DuplicateVotersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedGroups = {};
  String _selectedMatchType = 'name'; // 'name' | 'epic' | 'mobile'

  bool _isLoading = true;
  List<DuplicateVoterGroupModel> _duplicateGroups = [];
  Map<String, dynamic> _stats = {
    'duplicateGroups': 0,
    'totalAffectedVoters': 0,
    'estimatedExtraRecords': 0,
    'cleanRecordsCount': 0,
  };
  int _displayedLimit = 20;

  List<DuplicateVoterGroupModel> get _visibleGroups =>
      _duplicateGroups.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadDuplicates();
  }

  Future<void> _loadDuplicates() async {
    setState(() => _isLoading = true);
    final repo = ref.read(duplicateVotersRepoProvider);

    final groups = await repo.getDuplicateGroups(
      query: _searchController.text,
      matchType: _selectedMatchType,
    );
    final stats = await repo.getStatistics();

    if (mounted) {
      setState(() {
        _duplicateGroups = groups;
        _stats = stats;
        _isLoading = false;
        _displayedLimit = 20;
        // Default expand first 2 groups for great initial view
        if (_expandedGroups.isEmpty && groups.isNotEmpty) {
          _expandedGroups.addAll(groups.take(2).map((g) => g.normalizedKey));
        }
      });
    }
  }

  void _toggleGroup(String key) {
    setState(() {
      if (_expandedGroups.contains(key)) {
        _expandedGroups.remove(key);
      } else {
        _expandedGroups.add(key);
      }
    });
  }

  void _expandAll() {
    setState(() {
      _expandedGroups.addAll(_duplicateGroups.map((g) => g.normalizedKey));
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedGroups.clear();
    });
  }

  Future<void> _confirmDeleteVoter(VoterModel voter, String groupKey) async {
    final lang = ref.read(appLanguageProvider);
    final tName = await DynamicTranslationService.translateOrRaw(
      voter.displayNameFor(lang),
      lang,
      isName: true,
    );
    if (!mounted) return;
    final epicStr = AppTranslations.formatDigits(
      voter.epicNo.isNotEmpty ? voter.epicNo : '-',
      lang,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Delete Duplicate Record?',
                  mr: 'दुबार नोंद हटवायची का?',
                  hi: 'डुप्लिकेट रिकॉर्ड हटाएं?',
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.pick(
                lang,
                en: '$tName (EPIC: $epicStr) will be permanently removed.',
                mr: '$tName (EPIC: $epicStr) कायमचे काढले जाईल.',
                hi: '$tName (EPIC: $epicStr) को स्थायी रूप से हटा दिया जाएगा।',
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslations.pick(
                lang,
                en: 'This action cannot be undone. Please ensure you are deleting the exact extra duplicate record.',
                mr: 'ही कृती पूर्ववत करता येणार नाही. कृपया अचूक अतिरिक्त दुबार नोंदच हटवत असल्याची खात्री करा.',
                hi: 'यह क्रिया पूर्ववत नहीं की जा सकती। कृपया सुनिश्चित करें कि आप सही अतिरिक्त डुप्लिकेट रिकॉर्ड हटा रहे हैं।',
              ),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(AppTranslations.pick(lang, en: 'Yes, Delete', mr: 'होय, हटवा', hi: 'हाँ, हटाएं')),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final repo = ref.read(duplicateVotersRepoProvider);
      await repo.deleteVoter(voter.id);
      _loadDuplicates();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Duplicate record for $tName deleted successfully.',
              mr: '$tName यांची दुबार नोंद यशस्वीरित्या हटवली.',
              hi: '$tName का डुप्लिकेट रिकॉर्ड सफलतापूर्वक हटा दिया गया।',
            ),
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final totalAffected = _stats['totalAffectedVoters'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
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
              AppTranslations.pick(
                lang,
                en: 'Duplicate Voters',
                mr: 'दुबार मतदार',
                hi: 'डुप्लिकेट मतदाता',
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
                en: 'Duplicate voter entries & cleanup',
                mr: 'दुबार मतदार नोंदी तपासणी व स्वच्छता',
                hi: 'डुप्लिकेट मतदाता प्रविष्टियाँ और सुधार',
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadDuplicates,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3 KPI Metric Cards
              _buildStatsRow(lang),

              const SizedBox(height: 16),

              // Search & Match Type Selector
              _buildSearchAndFilters(lang),

              const SizedBox(height: 14),

              // Controls Bar (Expand / Collapse All & Counts)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Total Groups: ${AppTranslations.formatDigits(_duplicateGroups.length, lang)}',
                      mr: 'एकूण गट: ${AppTranslations.formatDigits(_duplicateGroups.length, lang)}',
                      hi: 'कुल समूह: ${AppTranslations.formatDigits(_duplicateGroups.length, lang)}',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                  ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _expandAll,
                        icon: const Icon(Icons.unfold_more, size: 16),
                        label: Text(
                          AppTranslations.pick(lang, en: 'Expand All', mr: 'सर्व उघडा', hi: 'सभी खोलें'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _collapseAll,
                        icon: const Icon(Icons.unfold_less, size: 16),
                        label: Text(
                          AppTranslations.pick(lang, en: 'Collapse All', mr: 'सर्व बंद करा', hi: 'सभी बंद करें'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                      AppPdfButton.outlined(
                        label: AppTranslations.getDownloadReport(lang),
                        onPressed: () => DuplicateVotersReportGenerator.generateAndPrintReport(
                          duplicateGroups: _duplicateGroups,
                          totalAffectedVoters: totalAffected,
                          lang: lang,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Duplicate Groups List
              if (_isLoading)
                const AppShimmerList(count: 6)
              else if (_duplicateGroups.isEmpty)
                _buildEmptyState(lang)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _visibleGroups.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _buildGroupCard(_visibleGroups[index], lang),
                ),

              if (!_isLoading && _duplicateGroups.isNotEmpty)
                AppLoadMoreFooter(
                  currentCount: _visibleGroups.length,
                  totalCount: _duplicateGroups.length,
                  pageSize: 20,
                  onLoadMore: () {
                    setState(() => _displayedLimit += 20);
                  },
                  label: AppTranslations.pick(lang, en: 'groups', mr: 'गट', hi: 'समूह'),
                  isMarathi: lang == 'mr',
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(String lang) {
    final groupsCount = _duplicateGroups.length;
    final totalAffected = _stats['totalAffectedVoters'] ?? 0;
    final estExtra = _stats['estimatedExtraRecords'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 2.4 : 1.15,
          children: [
            _buildStatCard(
              title: AppTranslations.pick(lang, en: 'Duplicate Groups', mr: 'दुबार गट', hi: 'डुप्लिकेट समूह'),
              subtitle: AppTranslations.pick(lang, en: 'Duplicate Groups', mr: 'समान नोंदी गट', hi: 'समान समूह'),
              count: AppTranslations.formatDigits(groupsCount, lang),
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFBAE6FD),
            ),
            _buildStatCard(
              title: AppTranslations.pick(lang, en: 'Affected Voters', mr: 'प्रभावित मतदार', hi: 'प्रभावित मतदाता'),
              subtitle: AppTranslations.pick(lang, en: 'Affected Voters', mr: 'एकूण नोंदी', hi: 'कुल प्रविष्टियाँ'),
              count: AppTranslations.formatDigits(totalAffected, lang),
              color: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
            ),
            _buildStatCard(
              title: AppTranslations.pick(lang, en: 'Extra Records', mr: 'अतिरिक्त नोंदी', hi: 'अतिरिक्त रिकॉर्ड'),
              subtitle: AppTranslations.pick(lang, en: 'Form 7 Extras', mr: 'फॉर्म ७ अतिरिक्त', hi: 'फॉर्म ७ अतिरिक्त'),
              count: AppTranslations.formatDigits(estExtra, lang),
              color: const Color(0xFF475569),
              bgColor: const Color(0xFFF8FAFC),
              borderColor: const Color(0xFFE2E8F0),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required String count,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => _loadDuplicates(),
            decoration: InputDecoration(
              hintText: AppTranslations.pick(
                lang,
                en: 'Search duplicate names or voters...',
                mr: 'दुबार नावे किंवा मतदार शोधा...',
                hi: 'डुप्लिकेट नाम या मतदाता खोजें...',
              ),
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadDuplicates();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Match Criteria Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Match Criteria: ',
                  mr: 'जुळणी निकष: ',
                  hi: 'मिलान मानदंड: ',
                ),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              _buildMatchTypeChip(
                label: AppTranslations.pick(lang, en: 'Same Full Name', mr: 'समान पूर्ण नाव', hi: 'समान पूरा नाम'),
                type: 'name',
              ),
              _buildMatchTypeChip(
                label: AppTranslations.pick(lang, en: 'Same EPIC No.', mr: 'समान ओळखपत्र क्र.', hi: 'समान EPIC नं.'),
                type: 'epic',
              ),
              _buildMatchTypeChip(
                label: AppTranslations.pick(lang, en: 'Same Mobile No.', mr: 'समान मोबाईल क्र.', hi: 'समान मोबाइल नं.'),
                type: 'mobile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTypeChip({required String label, required String type}) {
    final isSelected = _selectedMatchType == type;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedMatchType = type);
          _loadDuplicates();
        }
      },
    );
  }

  Widget _buildGroupCard(DuplicateVoterGroupModel group, String lang) {
    final isExpanded = _expandedGroups.contains(group.normalizedKey);
    final count = group.recordsCount;
    final countStr = AppTranslations.formatDigits(count, lang);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Group Header (Clickable)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _toggleGroup(group.normalizedKey),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTranslatedText(
                          group.displayName,
                          targetLanguage: lang,
                          isName: _selectedMatchType == 'name',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: '$countStr voter records found with this match',
                            mr: 'या नोंदीशी जुळणारे $countStr मतदार आढळले',
                            hi: 'इस मिलान के $countStr मतदाता रिकॉर्ड मिले',
                          ),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: '$countStr Duplicates',
                        mr: '$countStr दुबार',
                        hi: '$countStr डुप्लिकेट',
                      ),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Side-by-Side Comparison Section
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(14),
              color: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.compare_arrows_rounded, size: 16, color: Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Comparison: Keep the accurate record and submit Form 7 for deletion',
                              mr: 'तुलना: अचूक नोंद ठेवा आणि अतिरिक्त नोंदीसाठी फॉर्म ७ दाखल करा',
                              hi: 'तुलना: सटीक रिकॉर्ड रखें और हटाने के लिए फॉर्म ७ जमा करें',
                            ),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Side-by-Side Voters Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      if (isWide) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: count >= 3 ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.88,
                          ),
                          itemCount: count,
                          itemBuilder: (context, idx) => _buildVoterComparisonCard(group.voters[idx], idx, group.normalizedKey, lang),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: count,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) => _buildVoterComparisonCard(group.voters[idx], idx, group.normalizedKey, lang),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoterComparisonCard(VoterModel voter, int index, String groupKey, String lang) {
    final isFirst = index == 0;
    final entryNum = AppTranslations.formatDigits(index + 1, lang);
    final ageStr = AppTranslations.formatDigits(voter.age, lang);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFirst ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
          width: isFirst ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Record vs Duplicate Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFirst ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isFirst ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  isFirst
                      ? AppTranslations.pick(lang, en: 'Primary Record', mr: 'मूळ नोंद', hi: 'मुख्य रिकॉर्ड')
                      : AppTranslations.pick(
                          lang,
                          en: 'Duplicate Entry #$entryNum',
                          mr: 'दुबार नोंद #$entryNum',
                          hi: 'डुप्लिकेट प्रविष्टि #$entryNum',
                        ),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isFirst ? const Color(0xFF047857) : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (voter.favour != null)
                Text(
                  voter.favourLabel(lang),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: voter.favour == 'Favourable' ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Voter Name
          AppTranslatedText(
            voter.displayNameFor(lang),
            targetLanguage: lang,
            isName: true,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Attributes Grid (EPIC, Serial, Age, Gender, Booth, House, Mobile)
          Row(
            children: [
              Expanded(
                child: _buildAttributeItem(
                  AppTranslations.pick(lang, en: 'EPIC No.', mr: 'ओळखपत्र क्र.', hi: 'EPIC नं.'),
                  voter.epicNo.isNotEmpty ? AppTranslations.formatDigits(voter.epicNo, lang) : '-',
                ),
              ),
              Expanded(
                child: _buildAttributeItem(
                  AppTranslations.pick(lang, en: 'Part / Serial No.', mr: 'भाग / अनुक्र.', hi: 'भाग / क्र.'),
                  voter.serialNo != null ? AppTranslations.formatDigits(voter.serialNo, lang) : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: _buildAttributeItem(
                  AppTranslations.pick(lang, en: 'Age & Gender', mr: 'वय व लिंग', hi: 'उम्र और लिंग'),
                  AppTranslations.pick(
                    lang,
                    en: '$ageStr Yrs / ${voter.genderLabel(lang)}',
                    mr: '$ageStr वर्षे / ${voter.genderLabel(lang)}',
                    hi: '$ageStr वर्ष / ${voter.genderLabel(lang)}',
                  ),
                ),
              ),
              Expanded(
                child: _buildAttributeItem(
                  AppTranslations.pick(lang, en: 'House No.', mr: 'घर क्र.', hi: 'मकान नं.'),
                  voter.houseNo != null ? AppTranslations.formatDigits(voter.houseNo, lang) : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: _buildAttributeItem(
                  AppTranslations.pick(lang, en: 'Polling Station', mr: 'मतदान केंद्र', hi: 'मतदान केंद्र'),
                  voter.booth,
                  lang: lang,
                  translateValue: true,
                ),
              ),
              Expanded(
                child: _buildAttributeItem(
                  AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'),
                  voter.mobile != null ? AppTranslations.formatDigits(voter.mobile, lang) : '-',
                ),
              ),
            ],
          ),

          // Address
          if (voter.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: AppTranslatedText(
                    voter.address,
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),
          const SizedBox(height: 10),

          // Actions Row (View Profile & Delete Duplicate)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VoterProfileScreen(voter: voter),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: Text(
                    AppTranslations.getDetails(lang),
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              if (!isFirst) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteVoter(voter, groupKey),
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: Text(
                      AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeItem(
    String label,
    String value, {
    String? lang,
    bool translateValue = false,
  }) {
    const valStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        if (translateValue && lang != null)
          AppTranslatedText(
            value,
            targetLanguage: lang,
            style: valStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else
          Text(
            value,
            style: valStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildEmptyState(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, size: 48, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No duplicate voters found!',
              mr: 'दुबार मतदार आढळले नाहीत!',
              hi: 'कोई डुप्लिकेट मतदाता नहीं मिला!',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.pick(
              lang,
              en: 'All voter records are unique. Clean database maintained!',
              mr: 'सर्व मतदार नोंदी अद्वितीय आहेत. स्वच्छ डेटाबेस राखला आहे!',
              hi: 'सभी मतदाता रिकॉर्ड अद्वितीय हैं। स्वच्छ डेटाबेस बना हुआ है!',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
