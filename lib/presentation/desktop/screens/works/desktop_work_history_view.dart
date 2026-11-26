import '../../../../core/theme/app_colors.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/work_history_model.dart';
import '../../../../data/repositories/work_history_repository.dart';
import '../../../screens/works/work_detail_screen.dart';
import '../../../screens/works/work_report_generator.dart';
import '../../../screens/works/ahwal_report_generator.dart';
import '../../../widgets/app_dropdown.dart';

class DesktopWorkHistoryView extends ConsumerStatefulWidget {
  const DesktopWorkHistoryView({super.key});

  @override
  ConsumerState<DesktopWorkHistoryView> createState() => _DesktopWorkHistoryViewState();
}

class _DesktopWorkHistoryViewState extends ConsumerState<DesktopWorkHistoryView> {
  bool _loading = true;
  List<WorkHistoryModel> _items = [];
  String _searchTerm = '';
  String _areaSearch = '';
  String _dateSearch = '';
  String _viewMode = 'grid'; // 'grid' | 'table'

  // Ahwal Selection mode
  bool _selectionMode = false;
  final Set<String> _selectedWorkIds = <String>{};

  // Dropdown states
  bool _showAreaDropdown = false;
  bool _showDateDropdown = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final repo = ref.read(workHistoryRepoProvider);
      final works = await repo.getWorks();
      if (mounted) {
        setState(() {
          _items = works;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = [];
          _loading = false;
        });
      }
    }
  }

  List<WorkHistoryModel> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = _searchTerm.isEmpty ||
          item.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          item.location.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesArea = _areaSearch.isEmpty ||
          item.area.toLowerCase().contains(_areaSearch.toLowerCase());

      final matchesDate = _dateSearch.isEmpty ||
          _formatDate(item.date).toLowerCase().contains(_dateSearch.toLowerCase());

      return matchesSearch && matchesArea && matchesDate;
    }).toList();
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

  Map<String, int> get _areaSuggestions {
    final map = <String, int>{};
    for (final item in _items) {
      if (item.area.isNotEmpty) {
        map[item.area] = (map[item.area] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<String, int> get _dateSuggestions {
    final map = <String, int>{};
    for (final item in _items) {
      final formatted = _formatDate(item.date);
      if (formatted.isNotEmpty) {
        map[formatted] = (map[formatted] ?? 0) + 1;
      }
    }
    return map;
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedWorkIds.clear();
    });
  }

  void _handleCardClick(WorkHistoryModel item) {
    if (_selectionMode) {
      setState(() {
        if (_selectedWorkIds.contains(item.id)) {
          _selectedWorkIds.remove(item.id);
        } else {
          _selectedWorkIds.add(item.id);
        }
      });
      return;
    }

    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkDetailScreen(work: item),
      ),
    ).then((res) {
      if (res == true) _fetchData(showLoading: false);
    });
  }

  void _showAddWorkModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final areaController = TextEditingController(text: 'Ward 12');
    final peopleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedStatus = 'Planned';
    String completionDate = DateTime.now().toIso8601String().split('T')[0];
    bool isGeneratingAI = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: 'Add New Work',
            subtitle: 'Record completed, in-progress, and planned ward development works',
            icon: Icons.construction_rounded,
            width: 600,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: 'Add Work',
                onPressed: () async {
                            if (titleController.text.trim().isEmpty) return;
                            final newWork = WorkHistoryModel(
                              id: 'work-${DateTime.now().millisecondsSinceEpoch}',
                              source: 'Manual',
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              location: locationController.text.trim().isEmpty ? 'Ward 12' : locationController.text.trim(),
                              area: areaController.text.trim().isEmpty ? 'Ward 12' : areaController.text.trim(),
                              status: selectedStatus,
                              date: completionDate,
                              amount: double.tryParse(amountController.text.trim()),
                              peopleBenefited: int.tryParse(peopleController.text.trim()),
                            );

                            final repo = ref.read(workHistoryRepoProvider);
                            await repo.addWork(newWork);
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
                    const Text('Project Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Main road asphalting...',
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

                    // Description + AI Button
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
                                      'Under ${titleController.text.trim()}, development work will be completed on schedule using high-quality materials for citizens.';
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
                        hintText: 'Describe the work details...',
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
                                  hintText: 'e.g. Shivaji Chowk',
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

                    // Status & Amount
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              AppDropdown<String>(
                                value: selectedStatus,
                                height: 44,
                                backgroundColor: const Color(0xFFF8FAFC),
                                borderColor: const Color(0xFFE2E8F0),
                                items: const [
                                  DropdownMenuItem(value: 'Planned', child: Text('Planned')),
                                  DropdownMenuItem(value: 'InProgress', child: Text('In Progress')),
                                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedStatus = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Amount (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  hintText: '50000',
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

                    // People Benefited
                    const Text('People Benefited', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: peopleController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 1200',
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sticky Top Section
          _buildHeader(filtered.length),
          const SizedBox(height: 16),

          // Selection Mode Bar
          if (_selectionMode) ...[
            _buildSelectionBar(),
            const SizedBox(height: 16),
          ],

          // Filter Row
          _buildFilterRow(),
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

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title & Badge
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Work History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text(
                    'Total: $count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Recorded development and maintenance civil works',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Action Buttons: Download Report + Add Work
        Row(
          children: [
            if (!_selectionMode) ...[
              // Download Report
              OutlinedButton.icon(
                onPressed: () {
                  WorkReportGenerator.generateAndPrintWorkReport(
                    context: context,
                    works: _filteredItems,
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
              const SizedBox(width: 10),

              // Generate Ahwal
              OutlinedButton.icon(
                onPressed: _toggleSelectionMode,
                icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF334155)),
                label: const Text('Generate Ahwal', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Add Work Button (ns-btn-primary matching WorkHistory.tsx)
            ElevatedButton(
              onPressed: _showAddWorkModal,
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
                    'Add Work',
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

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '${_selectedWorkIds.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  const Text('Works Selected', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Select works to include in the Ahwal report.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _toggleSelectionMode,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _selectedWorkIds.isEmpty
                    ? null
                    : () {
                        final selectedWorks = _items.where((w) => _selectedWorkIds.contains(w.id)).toList();
                        AhwalReportGenerator.generateAndPrintAhwal(
                          context: context,
                          selectedWorks: selectedWorks,
                        );
                      },
                icon: const Icon(Icons.description, size: 16, color: Colors.white),
                label: const Text('Preview Ahwal Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  disabledBackgroundColor: const Color(0xFF7DD3FC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
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
                hintText: 'Search work by title, location...',
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
          child: AppDropdown<String>(
            value: _areaSearch.isEmpty ? 'All' : _areaSearch,
            height: 44,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: ['All', ..._areaSuggestions.keys].map((area) {
              final count = area == 'All' ? _items.length : (_areaSuggestions[area] ?? 0);
              return DropdownMenuItem(
                value: area,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(area == 'All' ? 'All Areas' : area),
                    Text('($count)', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _areaSearch = (val == null || val == 'All') ? '' : val);
            },
          ),
        ),
        const SizedBox(width: 14),

        // Date Filter (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _dateSearch.isEmpty ? 'All' : _dateSearch,
            height: 44,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: ['All', ..._dateSuggestions.keys].map((date) {
              final count = date == 'All' ? _items.length : (_dateSuggestions[date] ?? 0);
              return DropdownMenuItem(
                value: date,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(date == 'All' ? 'All Dates' : date),
                    Text('($count)', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _dateSearch = (val == null || val == 'All') ? '' : val);
            },
          ),
        ),
        const SizedBox(width: 14),
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

  Widget _buildCardGrid(List<WorkHistoryModel> items) {
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
            Icon(Icons.assignment_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No records found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
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
            mainAxisExtent: 310,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = _selectedWorkIds.contains(item.id);

            Color borderColor;
            Color bgColor;
            if (item.status == 'Completed') {
              borderColor = const Color(0xFFBBF7D0);
              bgColor = const Color(0xFFF0FDF4);
            } else if (item.status == 'InProgress') {
              borderColor = const Color(0xFFFEF08A);
              bgColor = const Color(0xFFFEFCE8);
            } else {
              borderColor = const Color(0xFFE2E8F0);
              bgColor = Colors.white;
            }

            return InkWell(
              onTap: () => _handleCardClick(item),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectionMode && isSelected ? const Color(0xFF0284C7) : borderColor,
                    width: _selectionMode && isSelected ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Status Badge + Source pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(item.status),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.build_outlined, size: 12, color: Color(0xFF0EA5E9)),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.source,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectionMode) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                                  border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
                      ],
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

                    // Bottom info block
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Column(
                        children: [
                          if (item.source == 'Manual' && item.feedbackCount > 0) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE0F2FE)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.feedbackCount} Feedback',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                                  ),
                                  Text(
                                    '${item.feedbackRating} ★',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(_formatDate(item.date), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              const Spacer(),
                              if (item.amount != null && item.amount! > 0)
                                Text(
                                  '₹ ${NumberFormat('#,##,###').format(item.amount)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${item.location}${item.area.isNotEmpty ? ' (${item.area})' : ''}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'Completed') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
            SizedBox(width: 4),
            const Text('Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
          ],
        ),
      );
    } else if (status == 'InProgress') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.handyman, size: 12, color: Color(0xFF0284C7)),
            SizedBox(width: 4),
            const Text('In Progress', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.schedule, size: 12, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            const Text('Planned', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          ],
        ),
      );
    }
  }

  Widget _buildReportTable(List<WorkHistoryModel> items) {
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
            const DataColumn(label: Text('Work Title & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Location & Ward', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
          ],
          rows: List.generate(items.length, (index) {
            final item = items[index];
            return DataRow(
              cells: [
                DataCell(
                  _selectionMode
                      ? Checkbox(
                          value: _selectedWorkIds.contains(item.id),
                          onChanged: (_) => _handleCardClick(item),
                        )
                      : Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  onTap: () => _handleCardClick(item),
                ),
                DataCell(Text('${item.location} (${item.area})', style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                DataCell(_buildStatusBadge(item.status)),
                DataCell(Text(_formatDate(item.date), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(
                  Text(
                    item.amount != null ? '₹ ${NumberFormat('#,##,###').format(item.amount)}' : '--',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                  ),
                ),
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
