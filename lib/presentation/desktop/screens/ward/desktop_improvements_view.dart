import '../../../../core/theme/app_colors.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/improvement_model.dart';
import '../../../../data/repositories/improvements_repository.dart';
import '../../../screens/ward_improvements/improvement_detail_screen.dart';
import '../../../screens/ward_improvements/improvement_report_generator.dart';

class DesktopImprovementsView extends ConsumerStatefulWidget {
  const DesktopImprovementsView({super.key});

  @override
  ConsumerState<DesktopImprovementsView> createState() => _DesktopImprovementsViewState();
}

class _DesktopImprovementsViewState extends ConsumerState<DesktopImprovementsView> {
  bool _loading = true;
  List<ImprovementModel> _improvements = [];
  String _searchTerm = '';
  String _areaSearch = '';
  String _dateSearch = '';
  String _statusFilter = 'All'; // 'All' | 'Pending' | 'Planned' | 'In Progress' | 'Complete'
  String _viewMode = 'grid'; // 'grid' | 'table'

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final repo = ref.read(improvementsRepoProvider);
      final list = await repo.getImprovements();
      if (mounted) {
        setState(() {
          _improvements = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _improvements = [];
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  List<ImprovementModel> get _filteredImprovements {
    return _improvements.where((item) {
      final matchesSearch = _searchTerm.isEmpty ||
          item.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          item.location.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesArea = _areaSearch.isEmpty ||
          item.area.toLowerCase().contains(_areaSearch.toLowerCase());

      final matchesDate = _dateSearch.isEmpty ||
          _formatDate(item.createdAt).toLowerCase().contains(_dateSearch.toLowerCase());

      final matchesStatus = _statusFilter == 'All' || item.status == _statusFilter;

      return matchesSearch && matchesArea && matchesDate && matchesStatus;
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'All') return _improvements.length;
    return _improvements.where((i) => i.status == status).length;
  }

  Future<void> _handleVote(ImprovementModel item) async {
    final repo = ref.read(improvementsRepoProvider);
    final newVotes = await repo.voteImprovement(item.id);
    if (mounted) {
      setState(() {
        _improvements = _improvements.map((imp) {
          if (imp.id == item.id) {
            return imp.copyWith(votes: newVotes);
          }
          return imp;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text('Vote registered successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  void _showAddModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final areaController = TextEditingController(text: 'Ward 12');
    final peopleController = TextEditingController();
    String selectedStatus = 'Pending';
    bool isGeneratingAI = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: 'Suggest Ward Improvement',
            subtitle: 'Civic suggestions, road works, and infrastructural proposals',
            icon: Icons.lightbulb_outline_rounded,
            width: 600,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: 'Submit Improvement',
                onPressed: () async {
                            if (titleController.text.trim().isEmpty) return;
                            final newImp = ImprovementModel(
                              id: 'imp-${DateTime.now().millisecondsSinceEpoch}',
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              location: locationController.text.trim().isEmpty ? 'Ward 12' : locationController.text.trim(),
                              area: areaController.text.trim().isEmpty ? 'Ward 12' : areaController.text.trim(),
                              status: selectedStatus,
                              peopleBenefited: int.tryParse(peopleController.text.trim()),
                              createdAt: DateTime.now().toIso8601String(),
                            );

                            final repo = ref.read(improvementsRepoProvider);
                            await repo.addImprovement(newImp);
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchData();
                          },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                    const Text('Improvement Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Install open gym equipment in garden...',
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

                    // Description + AI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Description *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        TextButton.icon(
                          onPressed: isGeneratingAI || titleController.text.trim().isEmpty
                              ? null
                              : () async {
                                  setModalState(() => isGeneratingAI = true);
                                  await Future.delayed(const Duration(milliseconds: 600));
                                  descController.text =
                                      'Under ${titleController.text.trim()}, community infrastructure will improve significantly for citizens.';
                                  setModalState(() => isGeneratingAI = false);
                                },
                          icon: isGeneratingAI
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF0284C7)),
                          label: Text(
                            isGeneratingAI ? 'Generating...' : 'Auto-Generate (AI)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Provide details about the suggested improvement...',
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

                    // Location & Area
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: locationController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Public Garden',
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
                              const Text('Ward / Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaController,
                                decoration: InputDecoration(
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

                    // Status & People Benefited
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedStatus,
                                items: const [
                                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'Planned', child: Text('Planned')),
                                  DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                                  DropdownMenuItem(value: 'Complete', child: Text('Complete')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedStatus = val);
                                },
                                decoration: InputDecoration(
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
                              const Text('Estimated Beneficiaries', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: peopleController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 500',
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
                                      ],
            ),
          );
        },
      ),
    );  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredImprovements;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(),
          const SizedBox(height: 16),

          // Search Filters
          _buildFilterRow(),
          const SizedBox(height: 16),

          // Status Tabs
          _buildStatusTabs(),
          const SizedBox(height: 24),

          // Content
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildReportTable(filtered)
          else
            _buildCardGrid(filtered),
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
          children: const [
            Text(
              'Possible Improvements',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Track civic improvement proposals and public suggestions',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Propose Improvement
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ImprovementReportGenerator.generateAndPrintImprovementReport(
                  context: context,
                  improvements: _filteredImprovements,
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

            // Propose New Button (ns-btn-primary matching PossibleImprovements.tsx)
            ElevatedButton(
              onPressed: _showAddModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7), // bg-brand-600
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // rounded-xl
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white), // Plus w-4 h-4
                  SizedBox(width: 8), // gap-2
                  Text(
                    'Propose Improvement',
                    style: TextStyle(
                      fontSize: 14, // text-sm
                      fontWeight: FontWeight.w600, // font-semibold
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

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        // Main Search (Col 6)
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchTerm = val),
              decoration: const InputDecoration(
                hintText: 'Search improvement, location, topic...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Area Filter (Col 3)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _areaSearch = val),
              decoration: InputDecoration(
                hintText: 'Search Area...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: _areaSearch.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _areaSearch = ''))
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Date Filter (Col 3)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _dateSearch = val),
              decoration: InputDecoration(
                hintText: 'Search date (e.g. Nov 2024)',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: _dateSearch.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _dateSearch = ''))
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs() {
    final tabs = [
      {'key': 'All', 'label': 'All'},
      {'key': 'Pending', 'label': 'Pending'},
      {'key': 'Planned', 'label': 'Planned'},
      {'key': 'In Progress', 'label': 'In Progress'},
      {'key': 'Complete', 'label': 'Complete'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tabs.map((tab) {
            final key = tab['key']!;
            final label = tab['label']!;
            final isSelected = _statusFilter == key;
            final count = _countForStatus(key);

            return InkWell(
              onTap: () => setState(() => _statusFilter = key),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Color(0x200284C7), blurRadius: 4, offset: Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildViewToggleButton(
                icon: Icons.grid_view_rounded,
                label: 'Grid',
                isActive: _viewMode == 'grid',
                onTap: () => setState(() => _viewMode = 'grid'),
              ),
              const SizedBox(width: 4),
              _buildViewToggleButton(
                icon: Icons.table_rows_rounded,
                label: 'Table',
                isActive: _viewMode == 'table',
                onTap: () => setState(() => _viewMode = 'table'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<ImprovementModel> items) {
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
            Icon(Icons.lightbulb_outline, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No improvements found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 290,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return InkWell(
              onTap: () {
                Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ImprovementDetailScreen(improvement: item),
                  ),
                ).then((res) {
                  if (res == true) _fetchData(showLoading: false);
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Status pill + Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusBadge(item.status),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(_formatDate(item.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Expanded(
                          child: Text(
                            item.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ),

                        // Bottom Meta info
                        Container(
                          padding: const EdgeInsets.only(top: 10),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${item.location}${item.area.isNotEmpty ? ', ${item.area}' : ''}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (item.peopleBenefited != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.group_outlined, size: 13, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item.peopleBenefited} Beneficiaries',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                        ),
                                      ],
                                    )
                                  else
                                    const SizedBox.shrink(),

                                  // Upvote button
                                  InkWell(
                                    onTap: () => _handleVote(item),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.thumb_up_alt_outlined, size: 13, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${item.votes}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Subtle Watermark Lightbulb in top right
                  Positioned(
                    top: 14,
                    right: 14,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.04,
                        child: Icon(Icons.lightbulb, size: 70, color: Colors.blueGrey.shade800),
                      ),
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

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    Color border;

    if (status == 'Complete') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF15803D);
      border = const Color(0xFFBBF7D0);
    } else if (status == 'In Progress') {
      bg = const Color(0xFFF0F9FF);
      text = const Color(0xFF0369A1);
      border = const Color(0xFFBAE6FD);
    } else if (status == 'Planned') {
      bg = const Color(0xFFFAF5FF);
      text = const Color(0xFF7E22CE);
      border = const Color(0xFFE9D5FF);
    } else {
      bg = const Color(0xFFFFF7ED);
      text = const Color(0xFFC2410C);
      border = const Color(0xFFFED7AA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildReportTable(List<ImprovementModel> items) {
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
            const DataColumn(label: Text('Sr No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Improvement Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Location & Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Votes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
          ],
          rows: List.generate(items.length, (index) {
            final item = items[index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                DataCell(Text('${item.location} (${item.area})', style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                DataCell(_buildStatusBadge(item.status)),
                DataCell(Text(_formatDate(item.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(Text('${item.votes}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
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
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
