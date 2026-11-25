import '../../../../core/theme/app_colors.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/sadasya_model.dart';
import '../../../../data/repositories/sadasya_repository.dart';
import '../../../screens/sadasya/sadasya_report_generator.dart';

class DesktopSadasyaView extends ConsumerStatefulWidget {
  const DesktopSadasyaView({super.key});

  @override
  ConsumerState<DesktopSadasyaView> createState() => _DesktopSadasyaViewState();
}

class _DesktopSadasyaViewState extends ConsumerState<DesktopSadasyaView> {
  bool _loading = true;
  List<SadasyaModel> _sadasyas = [];
  String _searchTerm = '';
  String _areaFilter = 'All';
  String _voterFilter = 'all'; // 'all', 'voter', 'non-voter'
  String _viewMode = 'grid'; // 'grid' | 'report'
  List<String> _availableAreas = [];

  @override
  void initState() {
    super.initState();
    _fetchSadasyas();
  }

  Future<void> _fetchSadasyas() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(sadasyaRepoProvider);
      final list = await repo.getSadasyas();
      if (mounted) {
        final areas = list.map((s) => s.area ?? '').where((a) => a.isNotEmpty).toSet().toList();
        setState(() {
          _sadasyas = list;
          _availableAreas = ['All', ...areas];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sadasyas = [];
          _loading = false;
        });
      }
    }
  }

  List<SadasyaModel> get _filteredSadasyas {
    return _sadasyas.where((s) {
      final matchesSearch = _searchTerm.isEmpty ||
          s.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (s.nameMarathi?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          s.mobile.contains(_searchTerm) ||
          (s.voterId?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);

      final matchesArea = _areaFilter == 'All' || (s.area ?? '').toLowerCase() == _areaFilter.toLowerCase();

      bool matchesVoter = true;
      if (_voterFilter == 'voter') matchesVoter = s.isVoter;
      if (_voterFilter == 'non-voter') matchesVoter = !s.isVoter;

      return matchesSearch && matchesArea && matchesVoter;
    }).toList();
  }

  void _showAddEditModal({SadasyaModel? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final mobileController = TextEditingController(text: item?.mobile ?? '');
    final ageController = TextEditingController(text: item != null && item.age > 0 ? item.age.toString() : '');
    final areaController = TextEditingController(text: item?.area ?? 'Ward 12');
    final addressController = TextEditingController(text: item?.address ?? '');
    final roleController = TextEditingController(text: item?.role ?? 'Active Worker');
    bool isVoter = item?.isVoter ?? true;
    final voterIdController = TextEditingController(text: item?.voterId ?? '');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: item == null ? 'Add Member' : 'Edit Member Details',
            subtitle: 'Manage party members, active karyakartas and volunteers',
            icon: Icons.people_alt_rounded,
            width: 600,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: item == null ? 'Add Member' : 'Save Changes',
                onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;
                            final newSadasya = SadasyaModel(
                              id: item?.id ?? 'sad-${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text.trim(),
                              nameMarathi: nameController.text.trim(),
                              mobile: mobileController.text.trim(),
                              age: int.tryParse(ageController.text.trim()) ?? 0,
                              area: areaController.text.trim(),
                              address: addressController.text.trim(),
                              role: roleController.text.trim(),
                              isVoter: isVoter,
                              voterId: isVoter ? voterIdController.text.trim() : null,
                              registeredAt: item?.registeredAt ?? DateTime.now(),
                            );

                            final repo = ref.read(sadasyaRepoProvider);
                            if (item == null) {
                              await repo.addSadasya(newSadasya);
                            } else {
                              await repo.updateSadasya(newSadasya);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchSadasyas();
                          },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                    const Text('Full Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Rahul S. Patil...',
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

                    // Mobile & Age
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mobile *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mobileController,
                                keyboardType: TextInputType.phone,
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Age', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '32',
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

                    // Area & Role
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
                                  hintText: 'e.g. Shastri Nagar',
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
                              const Text('Role / Responsibility', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: roleController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Booth In-charge',
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

                    // Address
                    const Text('Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Residential address and landmark...',
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

                    // Voter Checkbox & EPIC
                    Row(
                      children: [
                        Checkbox(
                          value: isVoter,
                          onChanged: (val) => setModalState(() => isVoter = val ?? true),
                          activeColor: const Color(0xFF0284C7),
                        ),
                        const Text('Is Registered Voter in Ward', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      ],
                    ),
                    if (isVoter) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: voterIdController,
                        decoration: InputDecoration(
                          hintText: 'EPIC No. (e.g. MH/12/345/678901)',
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
                                      ],
            ),
          );
        },
      ),
    );  }

  void _showDeleteConfirm(SadasyaModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete "${item.displayName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(sadasyaRepoProvider);
              await repo.deleteSadasya(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchSadasyas();
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
    final filtered = _filteredSadasyas;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length),
          const SizedBox(height: 20),

          // Search and Filters Bar
          _buildFiltersBar(),
          const SizedBox(height: 24),

          // Content Grid or Report
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'report')
            _buildReportTable(filtered)
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
                  'Sadasya (Members)',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text('Total: $count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Registered party members, booth heads and active cadre directory',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Add Member
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                SadasyaReportGenerator.generateAndPrintReport(members: _filteredSadasyas);
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
              onPressed: () => _showAddEditModal(),
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
                    'Add Member',
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

  Widget _viewModeButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0F9FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (val) => setState(() => _searchTerm = val),
              decoration: const InputDecoration(
                hintText: 'Search member by name, mobile, EPIC...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Area Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _areaFilter,
              underline: const SizedBox(),
              items: _availableAreas.map((a) {
                return DropdownMenuItem(value: a, child: Text(a == 'All' ? 'All Areas' : a, style: const TextStyle(fontSize: 12)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _areaFilter = val);
              },
            ),
          ),
          const SizedBox(width: 12),

          // Voter Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _voterFilter,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'voter', child: Text('Voters', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'non-voter', child: Text('Non-Voters', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _voterFilter = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(List<SadasyaModel> items) {
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
            Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No members found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
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
            mainAxisExtent: 270,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Avatar + Name + Status
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFF0F9FF),
                        child: Text(
                          item.initials,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1), fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.role ?? 'Active Worker',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isVoter ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          item.isVoter ? 'Voter' : 'Non-Voter',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.isVoter ? const Color(0xFF15803D) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Mobile
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(item.mobile, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Area
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.area ?? 'Ward 12',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Address
                  Expanded(
                    child: Text(
                      item.displayAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
                    ),
                  ),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.voterId != null && item.voterId!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: Text(item.voterId!, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF475569))),
                          )
                        else
                          const SizedBox(),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                              onPressed: () => _showAddEditModal(item: item),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                              onPressed: () => _showDeleteConfirm(item),
                              tooltip: 'Delete',
                            ),
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

  Widget _buildReportTable(List<SadasyaModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: const [
            const DataColumn(label: Text('Member Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('EPIC No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
          ],
          rows: items.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      Text(item.role ?? 'Active Worker', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                DataCell(Text(item.mobile, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
                DataCell(Text(item.area ?? '-', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(Text(item.displayAddress, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                DataCell(Text(item.voterId ?? '-', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF475569)))),
                DataCell(
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showAddEditModal(item: item)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)), onPressed: () => _showDeleteConfirm(item)),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
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
            mainAxisExtent: 260,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
