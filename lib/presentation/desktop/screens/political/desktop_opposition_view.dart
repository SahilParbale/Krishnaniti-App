import '../../../../core/theme/app_colors.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/opposition_model.dart';
import '../../../../data/repositories/opposition_repository.dart';
import '../../../screens/opposition/opposition_report_generator.dart';

class DesktopOppositionView extends ConsumerStatefulWidget {
  const DesktopOppositionView({super.key});

  @override
  ConsumerState<DesktopOppositionView> createState() => _DesktopOppositionViewState();
}

class _DesktopOppositionViewState extends ConsumerState<DesktopOppositionView> {
  bool _loading = true;
  List<OppositionMemberModel> _members = [];
  String _searchTerm = '';
  String _partyFilter = 'All';
  String _typeFilter = 'all'; // 'all', 'candidates', 'workers'

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(oppositionRepoProvider);
      final list = await repo.getMembers(
        party: _partyFilter,
        type: _typeFilter,
      );
      if (mounted) {
        setState(() {
          _members = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _members = [];
          _loading = false;
        });
      }
    }
  }

  List<OppositionMemberModel> get _filteredMembers {
    return _members.where((m) {
      final matchesSearch = _searchTerm.isEmpty ||
          m.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          m.party.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (m.mobile?.contains(_searchTerm) ?? false) ||
          (m.area?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);

      return matchesSearch;
    }).toList();
  }

  void _showAddMemberModal({OppositionMemberModel? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final mobileController = TextEditingController(text: item?.mobile ?? '');
    final partyController = TextEditingController(text: item?.party ?? 'Opposition Party');
    final roleController = TextEditingController(text: item?.role ?? 'Opposition Candidate');
    final areaController = TextEditingController(text: item?.area ?? 'Ward 12');
    final strongholdsController = TextEditingController(text: (item?.strongholds ?? []).join(', '));
    final notesController = TextEditingController(text: item?.notes ?? '');
    bool isCandidate = item?.isCandidate ?? false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: item == null ? 'Add Opposition Leader' : 'Edit Leader Details',
            subtitle: 'Track opposition profiles, political party, and local influence',
            icon: Icons.shield_outlined,
            width: 600,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: item == null ? 'Add Leader' : 'Save Changes',
                onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;
                            final strongholds = strongholdsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                            final newMember = OppositionMemberModel(
                              id: item?.id ?? 'opp-${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text.trim(),
                              party: partyController.text.trim(),
                              mobile: mobileController.text.trim().isNotEmpty ? mobileController.text.trim() : null,
                              role: roleController.text.trim(),
                              area: areaController.text.trim(),
                              strongholds: strongholds,
                              notes: notesController.text.trim(),
                              isCandidate: isCandidate,
                              createdAt: item?.createdAt ?? DateTime.now(),
                            );

                            final repo = ref.read(oppositionRepoProvider);
                            if (item == null) {
                              await repo.addMember(newMember);
                            } else {
                              await repo.updateMember(newMember);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchMembers();
                          },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                    const Text('Leader Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Sunil Y. Thorat...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Party & Mobile
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Political Party *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: partyController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Opposition Party Name',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mobile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mobileController,
                                decoration: InputDecoration(
                                  hintText: '98XXXXXXXX',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Candidate Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: isCandidate,
                          onChanged: (val) => setModalState(() => isCandidate = val ?? false),
                          activeColor: const Color(0xFFDC2626),
                        ),
                        const Text('Is Official Candidate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Area & Strongholds
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ward / Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Main Street',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Strongholds / Influence Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: strongholdsController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Booth No. 24, 25',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    const Text('Notes & Political Strategy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Political background, local strengths and weaknesses...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                                      ],
            ),
          );
        },
      ),
    );  }

  void _showDeleteConfirm(OppositionMemberModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(oppositionRepoProvider);
              await repo.deleteMember(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchMembers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMembers;
    final candidateCount = _members.where((m) => m.isCandidate).length;
    final workerCount = _members.length - candidateCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length),
          const SizedBox(height: 20),

          // Stats
          _buildStatsRow(candidateCount, workerCount),
          const SizedBox(height: 24),

          // Search & Filter
          _buildFilterBar(),
          const SizedBox(height: 24),

          // Content Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildCardGrid(filtered),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Opposition Info',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text('Total: $count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Track opposition candidates, key cadres and local political strongholds',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions Row matching OppositionManagement.tsx
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                final repo = ref.read(oppositionRepoProvider);
                OppositionReportGenerator.generateAndPrintReport(
                  members: _filteredMembers,
                  getCandidateName: repo.getCandidateName,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: const Text('Download Report', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),

            // Add Member
            ElevatedButton(
              onPressed: () => _showAddMemberModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(int candidates, int workers) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Total Tracked', _members.length.toString(), Icons.groups_outlined, const Color(0xFF475569), const Color(0xFFF1F5F9)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Candidates', candidates.toString(), Icons.campaign_rounded, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Key Workers', workers.toString(), Icons.person_pin_circle_outlined, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchTerm = val),
              decoration: const InputDecoration(
                hintText: 'Search leader by name, party, area...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Type Filter (All, Candidates, Workers)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _typeFilter,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'candidates', child: Text('Candidates Only', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'workers', child: Text('Workers Only', style: TextStyle(fontSize: 12))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _typeFilter = val);
                _fetchMembers();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<OppositionMemberModel> items) {
    if (items.isEmpty) {
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
            Icon(Icons.shield_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No opposition members found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: item.isCandidate ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Text(item.partyFullLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isCandidate ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          item.typeLabelMarathi,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.isCandidate ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),

                  // Role / Area
                  Text(
                    '${item.role ?? "Cadre"} · ${item.area ?? "Ward 12"}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),

                  // Strongholds
                  if (item.strongholds.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: item.strongholds.take(3).map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Text(s, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                        );
                      }).toList(),
                    ),

                  const Spacer(),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.mobile != null && item.mobile!.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(item.mobile!, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                            ],
                          )
                        else
                          const SizedBox(),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showAddMemberModal(item: item)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)), onPressed: () => _showDeleteConfirm(item)),
                          ],
                        ),
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

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 240,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
