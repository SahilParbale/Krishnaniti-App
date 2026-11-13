import '../../navigation/app_bar_leading_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/duplicate_voter_group_model.dart';
import '../../../data/repositories/duplicate_voters_repository.dart';
import '../voters/voter_profile_screen.dart';
import 'duplicate_voters_report_generator.dart';
import '../../navigation/app_drawer.dart';

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
            const Expanded(
              child: Text(
                'Delete Duplicate Record?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${voter.displayName} (EPIC: ${voter.epicNo.isNotEmpty ? voter.epicNo : '-'}) will be permanently removed.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. Please ensure you are deleting the exact extra duplicate record.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete'),
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
          content: Text('Duplicate record for ${voter.displayName} deleted successfully.'),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAffected = _stats['totalAffectedVoters'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBarLeadingNavButton(),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Duplicate Voters',
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
              'Duplicate voter entries & cleanup',
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
      body: RefreshIndicator(
        onRefresh: _loadDuplicates,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3 KPI Metric Cards
              _buildStatsRow(),

              const SizedBox(height: 16),

              // Search & Match Type Selector
              _buildSearchAndFilters(),

              const SizedBox(height: 14),

              // Controls Bar (Expand / Collapse All & Counts)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Groups: ${_duplicateGroups.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _expandAll,
                        icon: const Icon(Icons.unfold_more, size: 16),
                        label: const Text('Expand All', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: _collapseAll,
                        icon: const Icon(Icons.unfold_less, size: 16),
                        label: const Text('Collapse All', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => DuplicateVotersReportGenerator.generateAndPrintReport(
                          duplicateGroups: _duplicateGroups,
                          totalAffectedVoters: totalAffected,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFFDC2626)),
                        label: const Text('PDF Report', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Duplicate Groups List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                  ),
                )
              else if (_duplicateGroups.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _duplicateGroups.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _buildGroupCard(_duplicateGroups[index]),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final groupsCount = _duplicateGroups.length;
    final totalAffected = _stats['totalAffectedVoters'] ?? 0;
    final estExtra = _stats['estimatedExtraRecords'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 3 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 2.4 : 1.15,
          children: [
            _buildStatCard(
              title: 'Duplicate Groups',
              subtitle: 'Duplicate Groups',
              count: groupsCount.toString(),
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFBAE6FD),
            ),
            _buildStatCard(
              title: 'Affected Voters',
              subtitle: 'Affected Voters',
              count: totalAffected.toString(),
              color: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
            ),
            _buildStatCard(
              title: 'Extra Records',
              subtitle: 'Form 7 Extras',
              count: estExtra.toString(),
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

  Widget _buildSearchAndFilters() {
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
              hintText: 'Search duplicate names or voters...',
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
              const Text(
                'Match Criteria: ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              _buildMatchTypeChip(label: 'Same Full Name', type: 'name'),
              _buildMatchTypeChip(label: 'Same EPIC No.', type: 'epic'),
              _buildMatchTypeChip(label: 'Same Mobile No.', type: 'mobile'),
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

  Widget _buildGroupCard(DuplicateVoterGroupModel group) {
    final isExpanded = _expandedGroups.contains(group.normalizedKey);
    final count = group.recordsCount;

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
                        Text(
                          group.displayName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count voter records found with this name',
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
                      '$count Duplicates',
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
                    child: const Row(
                      children: [
                        Icon(Icons.compare_arrows_rounded, size: 16, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Comparison: Keep the accurate record and submit Form 7 for deletion',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
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
                          itemBuilder: (context, idx) => _buildVoterComparisonCard(group.voters[idx], idx, group.normalizedKey),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: count,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) => _buildVoterComparisonCard(group.voters[idx], idx, group.normalizedKey),
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

  Widget _buildVoterComparisonCard(VoterModel voter, int index, String groupKey) {
    final isFirst = index == 0;

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
                  isFirst ? 'Primary Record' : 'Duplicate Entry #${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isFirst ? const Color(0xFF047857) : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (voter.favour != null)
                Text(
                  voter.favourLabelMarathi,
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
          Text(
            voter.displayName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (voter.nameEnglish.isNotEmpty && voter.nameEnglish != voter.displayName)
            Text(
              voter.nameEnglish,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                child: _buildAttributeItem('EPIC No.', voter.epicNo.isNotEmpty ? voter.epicNo : '-'),
              ),
              Expanded(
                child: _buildAttributeItem('Part / Serial No.', voter.serialNo != null ? voter.serialNo.toString() : '-'),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: _buildAttributeItem('Age & Gender', '${voter.age} Yrs / ${voter.gender}'),
              ),
              Expanded(
                child: _buildAttributeItem('House No.', voter.houseNo ?? '-'),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: _buildAttributeItem('Polling Station', voter.booth),
              ),
              Expanded(
                child: _buildAttributeItem('Mobile', voter.mobile ?? '-'),
              ),
            ],
          ),

          // Address
          if (voter.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '📍 ${voter.address}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                  label: const Text('Details', style: TextStyle(fontSize: 11)),
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
                    label: const Text('Delete', style: TextStyle(fontSize: 11)),
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

  Widget _buildAttributeItem(String label, String value) {
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
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            'No duplicate voters found!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'All voter records are unique. Clean database maintained!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
