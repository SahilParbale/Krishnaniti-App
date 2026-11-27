import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/desktop_modal_dialog.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../providers/language_provider.dart';
import '../../../../data/models/duplicate_voter_group_model.dart';
import '../../../../data/repositories/duplicate_voters_repository.dart';
import '../../../screens/duplicate_voters/duplicate_voters_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

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
        query: _searchTerm,
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
      builder: (ctx) => DesktopModalDialog(
        title: 'Delete Duplicate Record',
        subtitle: 'Are you sure you want to delete this duplicate voter record?',
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
            child: const Text('Delete Record', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        child: const Text(
          'This action cannot be undone. The duplicate voter entry will be permanently removed from the database.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
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
    final totalAffected = _groups.fold<int>(0, (sum, g) => sum + g.recordsCount);
    final estExtra = _groups.fold<int>(0, (sum, g) => sum + g.extraRecordsCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // 3 Stats Metric Cards
          _buildStatsRow(_groups.length, totalAffected, estExtra),
          const SizedBox(height: 24),

          // Search and Action Bar
          _buildFilterBar(),
          const SizedBox(height: 24),

          // Content Groups List
          if (_loading)
            _buildLoadingState()
          else if (_groups.isEmpty)
            _buildEmptyState()
          else ...[
            _buildGroupsList(),
            AppLoadMoreFooter(
              currentCount: _visibleGroups.length,
              totalCount: _groups.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: 'नोंदी',
              isMarathi: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalAffected = _groups.fold<int>(0, (sum, g) => sum + g.recordsCount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, size: 28, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Text(
                  'Duplicate Voters',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Identify, compare, and resolve duplicate voter entries across ward booths and EPIC records',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Download Report matching DuplicateVoters.tsx
        OutlinedButton.icon(
          onPressed: () {
            DuplicateVotersReportGenerator.generateAndPrintReport(
              context: context,
              duplicateGroups: _groups,
              totalAffectedVoters: totalAffected,
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
    );
  }

  Widget _buildStatsRow(int groupsCount, int affectedCount, int estExtra) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Duplicate Clusters', groupsCount.toString(), Icons.group_work_outlined, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Total Affected Voters', affectedCount.toString(), Icons.people_outline_rounded, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Estimated Extra Records', estExtra.toString(), Icons.delete_sweep_outlined, const Color(0xFF64748B), const Color(0xFFF1F5F9)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
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
              decoration: const InputDecoration(
                hintText: 'Search voter by name or EPIC number...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Match Criteria Dropdown
        AppDropdown<String>(
          value: _matchType,
          height: 40,
          width: 170,
          prefixIcon: const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF94A3B8)),
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          items: const [
            DropdownMenuItem(value: 'name', child: Text('Match by Name')),
            DropdownMenuItem(value: 'epic', child: Text('Match by EPIC')),
            DropdownMenuItem(value: 'mobile', child: Text('Match by Mobile')),
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
        OutlinedButton(onPressed: _expandAll, child: const Text('Expand All', style: TextStyle(fontSize: 12))),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _collapseAll, child: const Text('Collapse All', style: TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _buildGroupsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _visibleGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final group = _visibleGroups[index];
        final isExpanded = _expandedKeys.contains(group.normalizedKey);

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
                            Text(group.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('${group.recordsCount} duplicate records detected matching this identity', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFFFECACA))),
                        child: Text('${group.recordsCount} Records', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
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
                      const Text(
                        'Side-by-Side Comparison — Identify canonical record and remove duplicate:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
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
                                        Text(voter.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                        if (isFirst)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('Primary', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('EPIC: ${voter.epicNo} · Sr: ${voter.serialNo ?? "-"}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF334155))),
                                    const SizedBox(height: 4),
                                    Text('Age: ${voter.age} · Gender: ${voter.gender} · Booth: ${voter.booth}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: Text(voter.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _deleteVoter(voter.id),
                                        icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFDC2626)),
                                        label: const Text('Delete Record', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
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
          Icon(Icons.verified_outlined, size: 48, color: Color(0xFF16A34A)),
          SizedBox(height: 12),
          Text('No Duplicate Voters Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
          SizedBox(height: 6),
          Text('All voter records in the ward are unique and reconciled.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(height: 240, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2.5));
  }
}
