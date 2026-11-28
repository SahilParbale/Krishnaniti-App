import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../data/models/duplicate_voter_group_model.dart';
import '../../../../data/repositories/duplicate_voters_repository.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/duplicate_voters/duplicate_voters_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';
import '../../common/desktop_modal_dialog.dart';

class DesktopDuplicateVotersView extends ConsumerStatefulWidget {
  const DesktopDuplicateVotersView({super.key});

  @override
  ConsumerState<DesktopDuplicateVotersView> createState() => _DesktopDuplicateVotersViewState();
}

class _DesktopDuplicateVotersViewState extends ConsumerState<DesktopDuplicateVotersView> {
  bool _loading = true;
  List<DuplicateVoterGroupModel> _groups = [];
  int _displayedLimit = 20;
  List<DuplicateVoterGroupModel> get _visibleGroups =>
      _groups.take(_displayedLimit).toList();
  String _searchTerm = '';
  String _matchType = 'name'; // 'name', 'epic', 'mobile'
  final Set<String> _expandedKeys = {};

  @override
  void initState() {
    super.initState();
    _fetchDuplicates();
  }

  Future<void> _fetchDuplicates() async {
    setState(() {
      _displayedLimit = 20;
      _loading = true;
    });
    try {
      final repo = ref.read(duplicateVotersRepoProvider);
      final list = await repo.getDuplicateGroups(
        matchType: _matchType,
        query: AppTranslations.normalizeAsciiDigits(_searchTerm),
      );

      if (mounted) {
        setState(() {
          _groups = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _groups = [];
          _loading = false;
        });
      }
    }
  }

  void _toggleGroup(String key) {
    setState(() {
      if (_expandedKeys.contains(key)) {
        _expandedKeys.remove(key);
      } else {
        _expandedKeys.add(key);
      }
    });
  }

  void _expandAll() {
    setState(() {
      _expandedKeys.addAll(_groups.map((g) => g.normalizedKey));
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedKeys.clear();
    });
  }

  Future<void> _deleteVoter(String voterId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => DesktopModalDialog(
          title: AppTranslations.pick(
            lang,
            en: 'Delete Duplicate Record',
            mr: 'दुबार नोंद हटवा',
            hi: 'डुप्लीकेट रिकॉर्ड हटाएं',
          ),
          subtitle: AppTranslations.pick(
            lang,
            en: 'Are you sure you want to delete this duplicate voter record?',
            mr: 'तुम्हाला खात्री आहे की तुम्ही ही दुबार मतदार नोंद हटवू इच्छिता?',
            hi: 'क्या आप वाकई इस डुप्लिकेट मतदाता रिकॉर्ड को हटाना चाहते हैं?',
          ),
          icon: Icons.delete_outline_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
          width: 480,
          onClose: () => Navigator.pop(ctx, false),
          actions: [
            DesktopModalDialog.cancelButton(ctx, onPressed: () => Navigator.pop(ctx, false)),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Delete Record',
                  mr: 'नोंद हटवा',
                  hi: 'रिकॉर्ड हटाएं',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          child: Text(
            AppTranslations.pick(
              lang,
              en: 'This action cannot be undone. The duplicate voter entry will be permanently removed from the database.',
              mr: 'ही कृती पूर्ववत करता येणार नाही. ही दुबार मतदार नोंद डेटाबेसमधून कायमस्वरूपी काढून टाकली जाईल.',
              hi: 'यह क्रिया पूर्ववत नहीं की जा सकती। डुप्लिकेट मतदाता प्रविष्टि डेटाबेस से स्थायी रूप से हटा दी जाएगी।',
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(duplicateVotersRepoProvider);
      await repo.deleteVoter(voterId);
      _fetchDuplicates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final totalAffected = _groups.fold<int>(0, (sum, g) => sum + g.recordsCount);
    final estExtra = _groups.fold<int>(0, (sum, g) => sum + g.extraRecordsCount);

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(lang),
          const SizedBox(height: 20),

          // 3 Stats Metric Cards
          _buildStatsRow(_groups.length, totalAffected, estExtra, lang),
          const SizedBox(height: 24),

          // Search and Action Bar
          _buildFilterBar(lang),
          const SizedBox(height: 24),

          // Content Groups List
          if (_loading)
            _buildLoadingState()
          else if (_groups.isEmpty)
            _buildEmptyState(lang)
          else ...[
            _buildGroupsList(lang),
            AppLoadMoreFooter(
              currentCount: _visibleGroups.length,
              totalCount: _groups.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(lang, en: 'records', mr: 'नोंदी', hi: 'रिकॉर्ड'),
              isMarathi: lang == 'mr',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String lang) {
    final totalAffected = _groups.fold<int>(0, (sum, g) => sum + g.recordsCount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 28, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Duplicate Voters',
                      mr: 'दुबार मतदार',
                      hi: 'डुप्लीकेट मतदाता',
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Identify, compare, and resolve duplicate voter entries across ward booths and EPIC records',
                  mr: 'प्रभाग बूथ आणि EPIC नोंदींमधील दुबार मतदार नोंदी ओळखा, तुलना करा आणि सोडवा',
                  hi: 'वार्ड बूथ और EPIC रिकॉर्ड में डुप्लीकेट मतदाता प्रविष्टियों की पहचान करें, तुलना करें और समाधान करें',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Download Report matching DuplicateVoters.tsx
        OutlinedButton.icon(
          onPressed: () {
            DuplicateVotersReportGenerator.generateAndPrintReport(
              context: context,
              duplicateGroups: _groups,
              totalAffectedVoters: totalAffected,
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
    );
  }

  Widget _buildStatsRow(int groupsCount, int affectedCount, int estExtra, String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Duplicate Clusters', mr: 'दुबार गट', hi: 'डुप्लीकेट समूह'),
            AppTranslations.formatDigits(groupsCount, lang),
            Icons.group_work_outlined,
            const Color(0xFFD97706),
            const Color(0xFFFFFBEB),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Total Affected Voters', mr: 'एकूण बाधित मतदार', hi: 'कुल प्रभावित मतदाता'),
            AppTranslations.formatDigits(affectedCount, lang),
            Icons.people_outline_rounded,
            const Color(0xFFDC2626),
            const Color(0xFFFEF2F2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            AppTranslations.pick(lang, en: 'Estimated Extra Records', mr: 'अंदाजे अतिरिक्त नोंदी', hi: 'अनुमानित अतिरिक्त रिकॉर्ड'),
            AppTranslations.formatDigits(estExtra, lang),
            Icons.delete_sweep_outlined,
            const Color(0xFF64748B),
            const Color(0xFFF1F5F9),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(String lang) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) {
                _displayedLimit = 20;
                _searchTerm = val;
                _fetchDuplicates();
              },
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search voter by name or EPIC number...',
                  mr: 'मतदाराचे नाव किंवा EPIC क्रमांकाने शोधा...',
                  hi: 'नाम या EPIC नंबर से मतदाता खोजें...',
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

        // Match Criteria Dropdown
        AppDropdown<String>(
          value: _matchType,
          height: 40,
          width: 190,
          prefixIcon: const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF94A3B8)),
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          items: [
            DropdownMenuItem(
              value: 'name',
              child: Text(AppTranslations.pick(lang, en: 'Match by Name', mr: 'नावाने जुळणी', hi: 'नाम से मिलान')),
            ),
            DropdownMenuItem(
              value: 'epic',
              child: Text(AppTranslations.pick(lang, en: 'Match by EPIC', mr: 'EPIC द्वारे जुळणी', hi: 'EPIC से मिलान')),
            ),
            DropdownMenuItem(
              value: 'mobile',
              child: Text(AppTranslations.pick(lang, en: 'Match by Mobile', mr: 'मोबाईलने जुळणी', hi: 'मोबाइल से मिलान')),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _displayedLimit = 20;
                _matchType = val;
              });
              _fetchDuplicates();
            }
          },
        ),
        const SizedBox(width: 10),

        // Expand / Collapse buttons
        OutlinedButton(
          onPressed: _expandAll,
          child: Text(
            AppTranslations.pick(lang, en: 'Expand All', mr: 'सर्व उघडा', hi: 'सभी खोलें'),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _collapseAll,
          child: Text(
            AppTranslations.pick(lang, en: 'Collapse All', mr: 'सर्व बंद करा', hi: 'सभी बंद करें'),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsList(String lang) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _visibleGroups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final group = _visibleGroups[index];
        final isExpanded = _expandedKeys.contains(group.normalizedKey);
        final countStr = AppTranslations.formatDigits(group.recordsCount, lang);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: Column(
            children: [
              // Group Header
              InkWell(
                onTap: () => _toggleGroup(group.normalizedKey),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.warning_rounded, color: Color(0xFFD97706), size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (group.matchType == 'name')
                              AppTranslatedText(
                                group.voters.isNotEmpty
                                    ? group.voters.first.displayNameFor(lang)
                                    : group.displayName,
                                isName: true,
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              )
                            else
                              Text(
                                AppTranslations.formatDigits(group.displayName, lang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: '$countStr duplicate records detected matching this identity',
                                mr: 'या ओळखीशी जुळणाऱ्या $countStr दुबार नोंदी आढळल्या आहेत',
                                hi: 'इस पहचान से मेल खाने वाले $countStr डुप्लीकेट रिकॉर्ड मिले हैं',
                              ),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: '$countStr Records',
                            mr: '$countStr नोंदी',
                            hi: '$countStr रिकॉर्ड',
                          ),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),

              // Expanded Side-by-Side Comparison Cards
              if (isExpanded) ...[
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Side-by-Side Comparison — Identify canonical record and remove duplicate:',
                          mr: 'तुलनात्मक तपासणी — मूळ नोंद ओळखा आणि दुबार नोंद हटवा:',
                          hi: 'तुलनात्मक जांच — मुख्य रिकॉर्ड पहचानें और डुप्लीकेट हटाएं:',
                        ),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: group.voters.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 220,
                            ),
                            itemBuilder: (context, vIdx) {
                              final voter = group.voters[vIdx];
                              final isFirst = vIdx == 0;
                              final epicStr = AppTranslations.formatDigits(
                                voter.epicNo.isNotEmpty ? voter.epicNo : '-',
                                lang,
                              );
                              final srStr = AppTranslations.formatDigits(voter.serialNo ?? '-', lang);
                              final ageStr = AppTranslations.formatDigits(voter.age, lang);
                              final genderStr = voter.genderLabel(lang);
                              final boothStr = AppTranslations.formatDigits(voter.booth, lang);

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isFirst ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: AppTranslatedText(
                                            voter.displayNameFor(lang),
                                            isName: true,
                                            targetLanguage: lang,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                          ),
                                        ),
                                        if (isFirst) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                            child: Text(
                                              AppTranslations.pick(lang, en: 'Primary', mr: 'मुख्य', hi: 'प्राथमिक'),
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'EPIC: $epicStr · Sr: $srStr',
                                        mr: 'EPIC: $epicStr · क्र.: $srStr',
                                        hi: 'EPIC: $epicStr · क्र.: $srStr',
                                      ),
                                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF334155)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Age: $ageStr · Gender: $genderStr · Booth: $boothStr',
                                        mr: 'वय: $ageStr · लिंग: $genderStr · बूथ: $boothStr',
                                        hi: 'उम्र: $ageStr · लिंग: $genderStr · बूथ: $boothStr',
                                      ),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: AppTranslatedText(
                                        voter.address,
                                        targetLanguage: lang,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _deleteVoter(voter.id),
                                        icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFDC2626)),
                                        label: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Delete Record',
                                            mr: 'नोंद हटवा',
                                            hi: 'रिकॉर्ड हटाएं',
                                          ),
                                          style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFFECACA)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
      },
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
          const Icon(Icons.verified_outlined, size: 48, color: Color(0xFF16A34A)),
          const SizedBox(height: 12),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No Duplicate Voters Found',
              mr: 'दुबार मतदार आढळले नाहीत',
              hi: 'कोई डुप्लीकेट मतदाता नहीं मिला',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.pick(
              lang,
              en: 'All voter records in the ward are unique and reconciled.',
              mr: 'प्रभागातील सर्व मतदार नोंदी अद्वितीय आणि पडताळलेल्या आहेत.',
              hi: 'वार्ड में सभी मतदाता रिकॉर्ड अद्वितीय और सत्यापित हैं।',
            ),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(height: 240, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2.5));
  }
}
