import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/karyakarta_work_model.dart';
import '../../../data/repositories/karyakarta_work_repository.dart';
import 'karyakarta_work_report_generator.dart';
import '../../navigation/app_drawer.dart';

class KaryakartaWorkManagementScreen extends ConsumerStatefulWidget {
  const KaryakartaWorkManagementScreen({super.key});

  @override
  ConsumerState<KaryakartaWorkManagementScreen> createState() => _KaryakartaWorkManagementScreenState();
}

class _KaryakartaWorkManagementScreenState extends ConsumerState<KaryakartaWorkManagementScreen> {
  String _activeTab = 'Office'; // 'Office', 'Cooperative', 'Party'
  String _searchQuery = '';
  String _selectedArea = 'All';

  bool _isLoading = false;
  List<KaryakartaStaffWorkload> _workloads = [];
  KaryakartaWorkloadSummary _summary = KaryakartaWorkloadSummary.empty();
  List<KaryakartaWorkTask> _unassignedTasks = [];
  List<KaryakartaWorkComplaint> _unassignedComplaints = [];
  List<KaryakartaWorkStaff> _allStaff = [];
  List<String> _areas = [];

  // Selected member for detail drilldown
  KaryakartaStaffWorkload? _selectedMemberWorkload;
  String _drilldownTab = 'tasks'; // 'tasks' or 'complaints'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(karyakartaWorkRepoProvider);

    try {
      final workloads = await repo.getStaffWorkloads(
        category: _activeTab,
        query: _searchQuery,
        area: _selectedArea,
      );
      final summary = await repo.getSummaryStats(category: _activeTab);
      final unassignedTasks = repo.getUnassignedTasks();
      final unassignedComplaints = repo.getUnassignedComplaints();
      final allStaff = repo.getAllStaffList();
      final areas = repo.getAvailableAreas();

      if (mounted) {
        setState(() {
          _workloads = workloads;
          _summary = summary;
          _unassignedTasks = unassignedTasks;
          _unassignedComplaints = unassignedComplaints;
          _allStaff = allStaff;
          _areas = areas;

          // If a member was selected, update their workload data
          if (_selectedMemberWorkload != null) {
            final updated = workloads.where((w) => w.staff.id == _selectedMemberWorkload!.staff.id).toList();
            _selectedMemberWorkload = updated.isNotEmpty ? updated.first : null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onTabChanged(String tabId) {
    setState(() {
      _activeTab = tabId;
      _selectedMemberWorkload = null;
    });
    _loadData();
  }

  Future<void> _handleUpdateTaskStatus(String taskId, String currentStatus) async {
    final newStatus = currentStatus.toLowerCase() == 'pending' ? 'In Progress' : 'Completed';
    final repo = ref.read(karyakartaWorkRepoProvider);
    await repo.updateTaskStatus(taskId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task status updated: $newStatus'),
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    }
  }

  Future<void> _handleReassignTask(String taskId, String newStaffId) async {
    final repo = ref.read(karyakartaWorkRepoProvider);
    await repo.reassignTask(taskId, newStaffId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task reassigned successfully!'),
          backgroundColor: Color(0xFF0284C7),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    }
  }

  Future<void> _handleUpdateComplaintStatus(String complaintId, String currentStatus) async {
    final newStatus = (currentStatus.toLowerCase() == 'pending' || currentStatus.toLowerCase() == 'assigned')
        ? 'InProgress'
        : 'Resolved';
    final repo = ref.read(karyakartaWorkRepoProvider);
    await repo.updateComplaintStatus(complaintId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint status updated: $newStatus'),
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    }
  }

  Future<void> _handleReassignComplaint(String complaintId, String newStaffId) async {
    final repo = ref.read(karyakartaWorkRepoProvider);
    await repo.reassignComplaint(complaintId, newStaffId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint reassigned successfully!'),
          backgroundColor: Color(0xFF0284C7),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    }
  }

  void _openQuickTaskModal(KaryakartaWorkStaff staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickTaskAssignmentSheet(
        staff: staff,
        onTaskAssigned: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    final repo = ref.read(karyakartaWorkRepoProvider);
    final allTasks = await repo.getTasks();
    final allComplaints = await repo.getComplaints();
    final tabStaff = _workloads.map((w) => w.staff).toList();

    String tabLabel = 'Office Team';
    if (_activeTab == 'Cooperative') tabLabel = 'Government Work';
    if (_activeTab == 'Party') tabLabel = 'Party Cadre';

    await KaryakartaWorkReportGenerator.generateAndPrintReport(
      staffList: tabStaff,
      tasks: allTasks,
      complaints: allComplaints,
      activeTabLabel: tabLabel,
      categoryFilter: _activeTab,
    );
  }

  void _showReportPreviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.description_outlined, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Workload Report — ${_getTabTitle(_activeTab)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildPreviewRow('Total Members:', '${_workloads.length}'),
                    _buildPreviewRow('Total Workload:', '${_summary.totalLoad} (${_summary.totalTasks} Tasks + ${_summary.totalComplaints} Complaints)'),
                    _buildPreviewRow('Pending Load:', '${_summary.pendingLoad}'),
                    _buildPreviewRow('In Progress:', '${_summary.inProgressLoad}'),
                    _buildPreviewRow('Completed:', '${_summary.completedLoad}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This report will be generated on official Ward 12 letterhead in A4 landscape format.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _generatePdfReport();
            },
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Download / Print PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  String _getTabTitle(String tab) {
    switch (tab) {
      case 'Office':
        return 'Office Team';
      case 'Cooperative':
        return 'Government Work';
      case 'Party':
        return 'Party Cadre';
      default:
        return tab;
    }
  }

  Color _getTabColor(String tab) {
    switch (tab) {
      case 'Office':
        return const Color(0xFF6D28D9); // Violet
      case 'Cooperative':
        return const Color(0xFF0284C7); // Sky
      case 'Party':
        return const Color(0xFFF97316); // Brand / Orange
      default:
        return const Color(0xFF0284C7);
    }
  }

  Color _getTabBg(String tab) {
    switch (tab) {
      case 'Office':
        return const Color(0xFFEDE9FE);
      case 'Cooperative':
        return const Color(0xFFE0F2FE);
      case 'Party':
        return const Color(0xFFFFEDD5);
      default:
        return const Color(0xFFE0F2FE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabColor = _getTabColor(_activeTab);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            tooltip: 'Open Menu Drawer',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Karyakarta Work Management',
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
              'Field tasks & team workload',
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
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Team Tab Navigation
              _buildCategoryTabBar(),
              const SizedBox(height: 12),

              // 2. Search & Area Filter Bar
              _buildFilterBar(),
              const SizedBox(height: 14),

              // 3. 4 KPI Dashboard Counters
              _buildKpiDashboard(),
              const SizedBox(height: 16),

              // 4. Drilldown Details Panel (if a member is selected)
              if (_selectedMemberWorkload != null) ...[
                _buildMemberDrilldownPanel(_selectedMemberWorkload!),
                const SizedBox(height: 16),
              ],

              // 5. Workload Matrix Table / Cards Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 20, color: tabColor),
                      const SizedBox(width: 6),
                      const Text(
                        'Team Workload Monitor',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _generatePdfReport,
                    icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
                    label: const Text(
                      'Download PDF',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
              const Text(
                'Tasks & complaints assigned to each member — click card to expand',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),

              // 6. Staff Workload Cards List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_workloads.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _workloads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final workload = _workloads[index];
                    final isSelected = _selectedMemberWorkload?.staff.id == workload.staff.id;
                    return _buildStaffWorkloadCard(workload, isSelected);
                  },
                ),

              const SizedBox(height: 20),

              // 7. Unassigned Work Pool Section
              if (_unassignedTasks.isNotEmpty || _unassignedComplaints.isNotEmpty) ...[
                _buildUnassignedWorkPool(),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: Category Tabs
  // ─────────────────────────────────────────────────────────────
  Widget _buildCategoryTabBar() {
    final tabs = [
      {'id': 'Office', 'title': 'Office Team', 'icon': Icons.apartment_outlined, 'color': const Color(0xFF6D28D9)},
      {'id': 'Cooperative', 'title': 'Govt Work', 'icon': Icons.work_outline_rounded, 'color': const Color(0xFF0284C7)},
      {'id': 'Party', 'title': 'Party Cadre', 'icon': Icons.flag_outlined, 'color': const Color(0xFFF97316)},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: tabs.map((tab) {
          final id = tab['id'] as String;
          final isSelected = _activeTab == id;
          final color = tab['color'] as Color;
          final staffCount = _allStaff.where((s) => s.category.toLowerCase() == id.toLowerCase()).length;

          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _getTabBg(id) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? Border.all(color: color.withOpacity(0.3)) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab['icon'] as IconData, size: 16, color: isSelected ? color : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tab['title'] as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? color : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected ? color : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$staffCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: Filter Bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Row(
      children: [
        // Name / Mobile Search
        Expanded(
          flex: 3,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _searchQuery = val;
                _loadData();
              },
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search name or mobile...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _loadData();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Area Filter Dropdown
        Expanded(
          flex: 2,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedArea,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('All Areas')),
                  ..._areas.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedArea = val);
                    _loadData();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _showReportPreviewDialog,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFFDC2626)),
                SizedBox(width: 5),
                Text('Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: 4 KPI Cards
  // ─────────────────────────────────────────────────────────────
  Widget _buildKpiDashboard() {
    return Row(
      children: [
        _buildMetricTile(
          title: 'Total Workload',
          value: '${_summary.totalLoad}',
          subtitle: '${_summary.totalTasks} Tasks · ${_summary.totalComplaints} Complaints',
          bg: const Color(0xFFF1F5F9),
          textColor: const Color(0xFF1E293B),
        ),
        const SizedBox(width: 8),
        _buildMetricTile(
          title: 'Pending',
          value: '${_summary.pendingLoad}',
          subtitle: 'Needs Attention',
          bg: const Color(0xFFFFFBEB),
          textColor: const Color(0xFFB45309),
        ),
        const SizedBox(width: 8),
        _buildMetricTile(
          title: 'In Progress',
          value: '${_summary.inProgressLoad}',
          subtitle: 'Active Work',
          bg: const Color(0xFFEFF6FF),
          textColor: const Color(0xFF1D4ED8),
        ),
        const SizedBox(width: 8),
        _buildMetricTile(
          title: 'Completed',
          value: '${_summary.completedLoad}',
          subtitle: 'Resolved & Closed',
          bg: const Color(0xFFECFDF5),
          textColor: const Color(0xFF047857),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color bg,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.9)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 8.5, color: const Color(0xFF64748B).withOpacity(0.9)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: Staff Workload Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildStaffWorkloadCard(KaryakartaStaffWorkload workload, bool isSelected) {
    final staff = workload.staff;
    final tabColor = _getTabColor(_activeTab);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMemberWorkload = null;
          } else {
            _selectedMemberWorkload = workload;
            _drilldownTab = 'tasks';
          }
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0x150284C7) : const Color(0x06000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Row 1: Avatar, Name, Role, Call, Area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Initials Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _getTabBg(_activeTab),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tabColor.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: tabColor),
                  ),
                ),
                const SizedBox(width: 10),

                // Name & Role & Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.displayName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staff.role,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                      ),
                      if (staff.area != null && staff.area!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 2),
                            Text(
                              staff.area!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Mobile & Direct Call Action
                InkWell(
                  onTap: () => launchUrl(Uri.parse('tel:${staff.mobile}')),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 12, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          staff.mobile,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Row 2: Metrics (Tasks, Complaints, Progress Bar)
            Row(
              children: [
                // Tasks Count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: workload.tasksPending > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('Tasks: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        '${workload.tasksPending}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: workload.tasksPending > 0 ? const Color(0xFFB45309) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(' / ${workload.tasksTotal}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Complaints Count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: workload.complaintsPending > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('Complaints: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        '${workload.complaintsPending}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: workload.complaintsPending > 0 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(' / ${workload.complaintsTotal}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),

                const Spacer(),

                // Progress Bar
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Progress: ', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text(
                            '${workload.progressPct}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: workload.progressPct / 100.0,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 3: Action Buttons (View/Hide Drilldown & Assign Task)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View / Hide Drilldown Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
                    backgroundColor: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: () {
                    setState(() {
                      if (isSelected) {
                        _selectedMemberWorkload = null;
                      } else {
                        _selectedMemberWorkload = workload;
                        _drilldownTab = 'tasks';
                      }
                    });
                  },
                  icon: Icon(
                    isSelected ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 14,
                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                  ),
                  label: Text(
                    isSelected ? 'Hide' : 'View Details',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // + Assign Task Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: () => _openQuickTaskModal(staff),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Assign', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: Member Drilldown Panel
  // ─────────────────────────────────────────────────────────────
  Widget _buildMemberDrilldownPanel(KaryakartaStaffWorkload workload) {
    final staff = workload.staff;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0284C7), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Banner Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        '${staff.role}${staff.area != null ? ' · ${staff.area}' : ''}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE0F2FE)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => _openQuickTaskModal(staff),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Assign Task', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _selectedMemberWorkload = null),
                ),
              ],
            ),
          ),

          // Mini 4-stat bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                _buildMiniStat('Total', '${workload.totalAssigned}', const Color(0xFF334155)),
                _buildMiniStat('Pending', '${workload.totalPending}', const Color(0xFFD97706)),
                _buildMiniStat('Done', '${workload.totalCompleted}', const Color(0xFF047857)),
                _buildMiniStat('Progress', '${workload.progressPct}%', const Color(0xFF0284C7)),
              ],
            ),
          ),

          // Sub-tabs (Tasks / Complaints)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                _buildSubTabButton('tasks', 'Tasks', workload.tasksTotal),
                const SizedBox(width: 8),
                _buildSubTabButton('complaints', 'Complaints', workload.complaintsTotal),
              ],
            ),
          ),

          // Tab content
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              children: [
                if (_drilldownTab == 'tasks')
                  ..._buildTasksList(workload.tasks)
                else
                  ..._buildComplaintsList(workload.complaints),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String tabId, String title, int count) {
    final isSelected = _drilldownTab == tabId;
    return GestureDetector(
      onTap: () => setState(() => _drilldownTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTasksList(List<KaryakartaWorkTask> tasks) {
    if (tasks.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 36, color: Color(0xFFCBD5E1)),
                SizedBox(height: 6),
                Text('No tasks assigned yet.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ),
      ];
    }

    return tasks.map((task) {
      Color priorityBg = const Color(0xFFF1F5F9);
      Color priorityColor = const Color(0xFF64748B);
      if (task.priority.toLowerCase() == 'high') {
        priorityBg = const Color(0xFFFEE2E2);
        priorityColor = const Color(0xFFDC2626);
      } else if (task.priority.toLowerCase() == 'medium') {
        priorityBg = const Color(0xFFFEF3C7);
        priorityColor = const Color(0xFFD97706);
      }

      Color statusBg = const Color(0xFFF1F5F9);
      Color statusColor = const Color(0xFF64748B);
      if (task.isCompleted) {
        statusBg = const Color(0xFFECFDF5);
        statusColor = const Color(0xFF047857);
      } else if (task.isInProgress) {
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
      } else {
        statusBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFB45309);
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    task.status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                task.description!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(color: priorityBg, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    task.priority,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: priorityColor),
                  ),
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(width: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 10, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Text(task.formattedDueDate, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
                if (task.address != null && task.address!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            task.address!,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reassign dropdown
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: task.assignedStaffId ?? '',
                      hint: const Text('Assign...', style: TextStyle(fontSize: 10)),
                      icon: const Icon(Icons.arrow_drop_down, size: 16),
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F172A)),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Unassigned')),
                        ..._allStaff.map(
                          (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null && val != task.assignedStaffId) {
                          _handleReassignTask(task.id, val);
                        }
                      },
                    ),
                  ),
                ),

                // Status advance button
                if (!task.isCompleted)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _handleUpdateTaskStatus(task.id, task.status),
                    icon: const Icon(Icons.bolt, size: 12),
                    label: Text(
                      task.isPending ? 'Start' : 'Complete',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildComplaintsList(List<KaryakartaWorkComplaint> complaints) {
    if (complaints.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 36, color: Color(0xFFCBD5E1)),
                SizedBox(height: 6),
                Text('No complaints assigned.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ),
      ];
    }

    return complaints.map((complaint) {
      Color statusBg = const Color(0xFFF1F5F9);
      Color statusColor = const Color(0xFF64748B);
      if (complaint.isResolved) {
        statusBg = const Color(0xFFECFDF5);
        statusColor = const Color(0xFF047857);
      } else if (complaint.isInProgress) {
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
      } else {
        statusBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFB45309);
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    complaint.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    complaint.status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            if (complaint.voterName != null) ...[
              const SizedBox(height: 2),
              Text(
                'From: ${complaint.voterName} ${complaint.voterMobile != null ? '(${complaint.voterMobile})' : ''}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w500),
              ),
            ],
            if (complaint.description != null && complaint.description!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                complaint.description!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                if (complaint.type != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      complaint.type!,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                    ),
                  ),
                if (complaint.area != null) ...[
                  const SizedBox(width: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 2),
                      Text(complaint.area!, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reassign dropdown
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: complaint.assignedTo ?? '',
                      hint: const Text('Assign...', style: TextStyle(fontSize: 10)),
                      icon: const Icon(Icons.arrow_drop_down, size: 16),
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F172A)),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Unassigned')),
                        ..._allStaff.map(
                          (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null && val != complaint.assignedTo) {
                          _handleReassignComplaint(complaint.id, val);
                        }
                      },
                    ),
                  ),
                ),

                // Status advance button
                if (!complaint.isResolved)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _handleUpdateComplaintStatus(complaint.id, complaint.status),
                    icon: const Icon(Icons.bolt, size: 12),
                    label: Text(
                      complaint.isPending ? 'Start' : 'Resolve',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: Unassigned Work Pool
  // ─────────────────────────────────────────────────────────────
  Widget _buildUnassignedWorkPool() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unassigned Work Pool',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                      Text(
                        '${_unassignedTasks.length} tasks and ${_unassignedComplaints.length} complaints pending assignment',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFDE68A)),

          // Unassigned Tasks
          if (_unassignedTasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                'Unassigned Tasks (${_unassignedTasks.length}):',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
            ),
            ..._unassignedTasks.map((t) => _buildUnassignedTaskRow(t)),
          ],

          // Unassigned Complaints
          if (_unassignedComplaints.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                'Unassigned Complaints (${_unassignedComplaints.length}):',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
            ),
            ..._unassignedComplaints.map((c) => _buildUnassignedComplaintRow(c)),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildUnassignedTaskRow(KaryakartaWorkTask task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: task.priority.toLowerCase() == 'high' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: task.priority.toLowerCase() == 'high' ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(width: 6),
                      Text(task.formattedDueDate, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: '',
                hint: const Text('— Assign —', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF15803D)),
                items: [
                  const DropdownMenuItem(value: '', child: Text('— Assign —', style: TextStyle(color: Color(0xFF94A3B8)))),
                  ..._allStaff.map(
                    (s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.category})')),
                  ),
                ],
                onChanged: (val) {
                  if (val != null && val.isNotEmpty) {
                    _handleReassignTask(task.id, val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedComplaintRow(KaryakartaWorkComplaint complaint) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                if (complaint.type != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      complaint.type!,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: '',
                hint: const Text('— Assign —', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF15803D)),
                items: [
                  const DropdownMenuItem(value: '', child: Text('— Assign —', style: TextStyle(color: Color(0xFF94A3B8)))),
                  ..._allStaff.map(
                    (s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.category})')),
                  ),
                ],
                onChanged: (val) {
                  if (val != null && val.isNotEmpty) {
                    _handleReassignComplaint(complaint.id, val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            'No members found in ${_getTabTitle(_activeTab)}.',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Change search filters or add members from staff management.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Quick Task Assignment Modal BottomSheet
// ─────────────────────────────────────────────────────────────
class _QuickTaskAssignmentSheet extends ConsumerStatefulWidget {
  final KaryakartaWorkStaff staff;
  final VoidCallback onTaskAssigned;

  const _QuickTaskAssignmentSheet({
    required this.staff,
    required this.onTaskAssigned,
  });

  @override
  ConsumerState<_QuickTaskAssignmentSheet> createState() => _QuickTaskAssignmentSheetState();
}

class _QuickTaskAssignmentSheetState extends ConsumerState<_QuickTaskAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  String _priority = 'Medium';
  DateTime? _dueDate;
  String _dueTime = '10:00';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(karyakartaWorkRepoProvider);

    try {
      await repo.assignTask(
        staffId: widget.staff.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        dueTime: _dueTime,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onTaskAssigned();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Task assigned to ${widget.staff.name} successfully!'),
            backgroundColor: const Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Error assigning task. Please try again.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 20,
        ),
        child: Column(
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 6, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_add, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign New Task',
                        style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'To: ${widget.staff.displayName}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title
                      fieldLabel('Task Title', isRequired: true),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 13),
                        decoration: inputDec(hint: 'e.g. Ward 12 road pothole repairs'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter task title' : null,
                      ),
                      const SizedBox(height: 12),

                      // Priority & Due Date Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Priority Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Priority'),
                                DropdownButtonFormField<String>(
                                  initialValue: _priority,
                                  decoration: inputDec(),
                                  items: const [
                                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                                    DropdownMenuItem(value: 'High', child: Text('High')),
                                  ],
                                  onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Due Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Due Date'),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _dueDate ?? DateTime.now(),
                                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) setState(() => _dueDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : 'Select Date',
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Address / Location
                      fieldLabel('Location / Address'),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(fontSize: 13),
                        decoration: inputDec(hint: 'e.g. Opposite Ganpati Temple, Shaniwar Peth'),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      fieldLabel('Details / Instructions'),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13),
                        decoration: inputDec(hint: 'Enter more details and instructions about this task...'),
                      ),
                      const SizedBox(height: 20),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Assign Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
