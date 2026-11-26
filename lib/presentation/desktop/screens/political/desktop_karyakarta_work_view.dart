import '../../../../core/theme/app_colors.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/karyakarta_work_model.dart';
import '../../../../data/repositories/karyakarta_work_repository.dart';
import '../../../screens/karyakarta_work/karyakarta_work_report_generator.dart';

class DesktopKaryakartaWorkView extends ConsumerStatefulWidget {
  const DesktopKaryakartaWorkView({super.key});

  @override
  ConsumerState<DesktopKaryakartaWorkView> createState() => _DesktopKaryakartaWorkViewState();
}

class _DesktopKaryakartaWorkViewState extends ConsumerState<DesktopKaryakartaWorkView> {
  bool _loading = true;
  List<KaryakartaStaffWorkload> _workloads = [];
  KaryakartaWorkloadSummary _summary = KaryakartaWorkloadSummary.empty();
  String _activeTab = 'Office'; // 'Office', 'Cooperative', 'Party'
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _fetchWorkloads();
  }

  Future<void> _fetchWorkloads() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(karyakartaWorkRepoProvider);
      final workloads = await repo.getStaffWorkloads(category: _activeTab, query: _searchTerm);
      final summary = await repo.getSummaryStats(category: _activeTab);

      if (mounted) {
        setState(() {
          _workloads = workloads;
          _summary = summary;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _workloads = [];
          _loading = false;
        });
      }
    }
  }

  void _showQuickTaskModal(KaryakartaWorkStaff staff) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final addressController = TextEditingController(text: staff.area ?? 'Ward 12');
    String priority = 'Medium';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: 'Assign Task: ${staff.displayName}',
            subtitle: 'Assign field responsibilities and deadlines to karyakartas',
            icon: Icons.assignment_ind_rounded,
            width: 540,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: 'Assign Task',
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;
                  final repo = ref.read(karyakartaWorkRepoProvider);
                  await repo.assignTask(
                    staffId: staff.id,
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    priority: priority,
                    address: addressController.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchWorkloads();
                },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Task Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Distribute ward scheme pamphlets...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: priority,
                              items: const [
                                DropdownMenuItem(value: 'High', child: Text('High')),
                                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                                DropdownMenuItem(value: 'Low', child: Text('Low')),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => priority = val);
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
                            const Text('Location / Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: addressController,
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
                  const SizedBox(height: 14),

                  const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Detailed task description and instructions...',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Overview 4 Metric Cards
          _buildStatsRow(),
          const SizedBox(height: 24),

          // Tab Bar & Search
          _buildTabBar(),
          const SizedBox(height: 20),

          // Grid of Staff Workload Cards
          if (_loading)
            _buildLoadingGrid()
          else
            _buildWorkloadGrid(),
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
              'Karyakarta Work Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            SizedBox(height: 4),
            Text(
              'Assign, monitor, and track daily tasks and complaint resolutions across ward teams',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Download Report matching KaryakartaWorkManagement.tsx
        OutlinedButton.icon(
          onPressed: () {
            final allStaff = _workloads.map((w) => w.staff).toList();
            final allTasks = _workloads.expand((w) => w.tasks).toList();
            final allComplaints = _workloads.expand((w) => w.complaints).toList();
            KaryakartaWorkReportGenerator.generateAndPrintReport(
              context: context,
              staffList: allStaff,
              tasks: allTasks,
              complaints: allComplaints,
              activeTabLabel: _activeTab == 'all' ? 'All Teams' : (_activeTab == 'office' ? 'Office Staff' : 'Field Workers'),
              categoryFilter: _activeTab,
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
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Total Assigned', _summary.totalLoad.toString(), Icons.assignment_outlined, const Color(0xFF475569), const Color(0xFFF1F5F9)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Pending Tasks', _summary.pendingLoad.toString(), Icons.hourglass_empty_rounded, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('In Progress', _summary.inProgressLoad.toString(), Icons.pending_actions_rounded, const Color(0xFF0284C7), const Color(0xFFF0F9FF)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Completed', _summary.completedLoad.toString(), Icons.check_circle_outline_rounded, const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
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

  Widget _buildTabBar() {
    final tabs = [
      {'key': 'Office', 'label': 'Office Team', 'icon': Icons.apartment_rounded},
      {'key': 'Party', 'label': 'Party Karyakarta', 'icon': Icons.flag_outlined},
      {'key': 'Cooperative', 'label': 'Cooperative & Govt', 'icon': Icons.business_outlined},
    ];

    return Row(
      children: [
        ...tabs.map((t) {
          final key = t['key'] as String;
          final label = t['label'] as String;
          final icon = t['icon'] as IconData;
          final isSelected = _activeTab == key;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                setState(() => _activeTab = key);
                _fetchWorkloads();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF475569))),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        SizedBox(
          width: 260,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              onChanged: (val) {
                _searchTerm = val;
                _fetchWorkloads();
              },
              decoration: const InputDecoration(
                hintText: 'Search karyakarta...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadGrid() {
    if (_workloads.isEmpty) {
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
            Icon(Icons.assignment_ind_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text('No karyakartas or staff found in this category', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
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
          itemCount: _workloads.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) {
            final w = _workloads[index];
            final staff = w.staff;

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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFF0F9FF),
                        child: Text(
                          staff.displayName.isNotEmpty ? staff.displayName[0].toUpperCase() : 'K',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text('${staff.role} · ${staff.area ?? "Ward 12"}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(100)),
                        child: Text('${w.progressPct}% Done', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Work breakdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tasks', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text('${w.tasksPending} Pending / ${w.tasksTotal}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Complaints', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text('${w.complaintsPending} Pending / ${w.complaintsTotal}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: w.totalAssigned > 0 ? (w.totalCompleted / w.totalAssigned).clamp(0.0, 1.0) : 0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      minHeight: 6,
                    ),
                  ),

                  const Spacer(),

                  // Quick Action: Assign Task
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Workload: ${w.totalAssigned}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ElevatedButton.icon(
                        onPressed: () => _showQuickTaskModal(staff),
                        icon: const Icon(Icons.add_task_rounded, size: 14, color: Colors.white),
                        label: const Text('Assign Task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
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
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
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
