import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nagarsevak_mobile/core/theme/app_colors.dart';
import 'package:nagarsevak_mobile/data/models/diary_task_model.dart';
import 'package:nagarsevak_mobile/data/repositories/diary_tasks_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/common/desktop_modal_dialog.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';

/// Desktop Tasks View matching Tasks.tsx verbatim:
/// - Sticky Header: Title + Found Counter + Help + Scan Doc + New Task
/// - 12-Column Search & Filter Bar (Search 6 cols, Area 3 cols, Date 3 cols)
/// - View Mode & Date Navigator Bar (Timeline vs Grid vs Report)
/// - 3x3 Layout Grid View (3 columns of cards matching lines 878-960)
/// - Vertical Timeline View with time indicator dots (matching lines 746-820)
/// - Tabular Report View (matching lines 663-740)
class DesktopTasksView extends ConsumerStatefulWidget {
  const DesktopTasksView({super.key});

  @override
  ConsumerState<DesktopTasksView> createState() => _DesktopTasksViewState();
}

class _DesktopTasksViewState extends ConsumerState<DesktopTasksView> {
  String _viewMode = 'grid'; // 'timeline' | 'grid' | 'report'
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String _selectedArea = 'All';

  bool _loading = true;
  List<DiaryTaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(diaryTasksRepoProvider);
      final list = await repo.getTasks();
      if (mounted) {
        setState(() {
          _tasks = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _uniqueAreas {
    final areas = <String>{};
    for (final t in _tasks) {
      if (t.address != null && t.address!.trim().isNotEmpty) {
        areas.add(t.address!.trim());
      } else if (t.officeName != null && t.officeName!.trim().isNotEmpty) {
        areas.add(t.officeName!.trim());
      }
    }
    final sorted = areas.toList()..sort();
    return ['All', ...sorted];
  }

  List<DiaryTaskModel> get _filteredTasks {
    return _tasks.where((t) {
      if (_selectedArea != 'All') {
        final matches = (t.address != null && t.address == _selectedArea) ||
            (t.officeName != null && t.officeName == _selectedArea);
        if (!matches) return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchTitle = t.title.toLowerCase().contains(q);
        final matchDesc = (t.description ?? '').toLowerCase().contains(q);
        final matchStaff = (t.assignedStaffName ?? '').toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchStaff) return false;
      }
      return true;
    }).toList();
  }

  List<DiaryTaskModel> get _timelineTasks {
    final selStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _filteredTasks.where((t) {
      if (t.dueDate == null) return false;
      final dStr = DateFormat('yyyy-MM-dd').format(t.dueDate!);
      return dStr == selStr;
    }).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _openNewTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String priority = 'Medium';
    DateTime dueDate = DateTime.now();
    TimeOfDay dueTime = TimeOfDay.now();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => DesktopModalDialog(
          title: 'New Task',
          subtitle: 'Create and assign follow-up tasks, reminders and deadlines',
          icon: Icons.assignment_rounded,
          width: 540,
          onClose: () => Navigator.pop(ctx),
          actions: [
            DesktopModalDialog.cancelButton(ctx),
            const SizedBox(width: 12),
            DesktopModalDialog.primaryButton(
              text: 'Save Task',
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final newTask = DiaryTaskModel(
                  id: '',
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  priority: priority,
                  status: 'Pending',
                  dueDate: dueDate,
                  dueTime: '${dueTime.hour.toString().padLeft(2, '0')}:${dueTime.minute.toString().padLeft(2, '0')}',
                  address: addressCtrl.text.trim(),
                );
                await ref.read(diaryTasksRepoProvider).addTask(newTask);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadTasks();
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
                controller: titleCtrl,
                decoration: desktopInputDecoration(hintText: 'Enter task title...'),
              ),
              const SizedBox(height: 14),
              const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: desktopInputDecoration(hintText: 'Optional details or instructions...'),
              ),
              const SizedBox(height: 14),
              const Text('Location / Office Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: addressCtrl,
                decoration: desktopInputDecoration(hintText: 'e.g. Ward Office, Civic Center...'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Priority: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(width: 10),
                  ...['Low', 'Medium', 'High'].map((p) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p, style: TextStyle(fontSize: 12, fontWeight: priority == p ? FontWeight.bold : FontWeight.normal)),
                          selected: priority == p,
                          selectedColor: AppColors.brand100,
                          onSelected: (_) => setDlgState(() => priority = p),
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final isMr = lang == 'mr';
    final items = _viewMode == 'timeline' ? _timelineTasks : _filteredTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row (matching Tasks.tsx lines 361-392)
            _buildHeader(isMr, items.length),

            const SizedBox(height: 16),

            // 2. Filters Grid (matching Tasks.tsx lines 395-468)
            _buildFilterBar(isMr),

            const SizedBox(height: 16),

            // 3. View Mode & Date Navigator Bar (matching Tasks.tsx lines 471-525)
            _buildViewModeBar(isMr),

            const SizedBox(height: 20),

            // 4. Content Area
            if (_loading)
              _buildLoadingGrid()
            else if (items.isEmpty)
              _buildEmptyState(isMr)
            else if (_viewMode == 'grid')
              _build3x3TaskGrid(items, isMr)
            else if (_viewMode == 'timeline')
              _buildTimelineView(items, isMr)
            else
              _buildReportView(items, isMr),
          ],
        ),
      ),
    );
  }

  // --- Header Row ---
  Widget _buildHeader(bool isMr, int foundCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Task Management',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text(
                    'Found: $foundCount',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isMr
                  ? 'Daily office diaries, citizen meetings and task tracking'
                  : 'Schedule and manage daily office tasks and citizen visits',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Help + Scan Doc + New Task
        Row(
          children: [

            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.document_scanner_outlined, size: 18, color: Color(0xFF475569)),
              label: Text(
                'Scan Doc',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _openNewTaskDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'New Task',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Filter Bar (12-column layout matching Tasks.tsx lines 395-468) ---
  Widget _buildFilterBar(bool isMr) {
    return Row(
      children: [
        // Main Search (6 cols)
        Expanded(
          flex: 6,
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search tasks by title, description, staff...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Colors.white,
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
        ),
        const SizedBox(width: 12),

        // Area Dropdown (3 cols)
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            value: _selectedArea,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            items: _uniqueAreas.map((area) {
              return DropdownMenuItem(
                value: area,
                child: Text(
                  area == 'All' ? 'All Areas' : area,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedArea = val);
            },
          ),
        ),
      ],
    );
  }

  // --- View Mode & Date Navigator Bar (matching Tasks.tsx lines 471-525) ---
  Widget _buildViewModeBar(bool isMr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // View Toggles: Timeline | Grid | Report
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildViewToggleButton(
                  icon: Icons.schedule_rounded,
                  label: 'Timeline',
                  isActive: _viewMode == 'timeline',
                  onTap: () => setState(() => _viewMode = 'timeline'),
                ),
                _buildViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Grid',
                  isActive: _viewMode == 'grid',
                  onTap: () => setState(() => _viewMode = 'grid'),
                ),
                _buildViewToggleButton(
                  icon: Icons.table_chart_outlined,
                  label: 'Report',
                  isActive: _viewMode == 'report',
                  onTap: () => setState(() => _viewMode = 'report'),
                ),
              ],
            ),
          ),

          // Date Navigator (When Timeline view is active)
          if (_viewMode == 'timeline') ...[
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _selectedDate = DateTime.now()),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isToday(_selectedDate) ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _isToday(_selectedDate) ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: () => _changeDate(-1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        onPressed: () => _changeDate(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3x3 Layout Grid View (matching Tasks.tsx lines 878-960) ---
  Widget _build3x3TaskGrid(List<DiaryTaskModel> items, bool isMr) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Exact 3 columns on standard/large desktop (3x3 grid)
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.45,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final task = items[index];
            return _buildTaskCard(task, isMr);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(DiaryTaskModel task, bool isMr) {
    final isDone = task.isCompleted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  await ref.read(diaryTasksRepoProvider).toggleStatus(task.id, isDone);
                  _loadTasks();
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    isDone ? 'Completed' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDone ? const Color(0xFF16A34A) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Description
          if (task.description != null && task.description!.isNotEmpty) ...[
            Expanded(
              child: Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
              ),
            ),
          ] else ...[
            const Spacer(),
          ],

          const SizedBox(height: 8),

          // Priority badge
          _buildPriorityBadge(task.priority, isMr),

          const SizedBox(height: 8),

          // Date / Time info
          if (task.dueDate != null || (task.dueTime != null && task.dueTime!.isNotEmpty)) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 5),
                Text(
                  '${task.formattedDate}${task.formattedTime.isNotEmpty ? ' • ${task.formattedTime}' : ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Location / Office info
          if (task.address != null || task.officeName != null) ...[
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.address ?? task.officeName ?? '',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority, bool isMr) {
    Color bg = const Color(0xFFFEF3C7);
    Color fg = const Color(0xFFD97706);
    final pLower = priority.toLowerCase();
    if (pLower == 'high') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (pLower == 'low') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        priority,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // --- Timeline View (matching Tasks.tsx lines 746-820) ---
  Widget _buildTimelineView(List<DiaryTaskModel> items, bool isMr) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final task = items[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time label
              SizedBox(
                width: 90,
                child: Text(
                  task.formattedTime.isNotEmpty ? task.formattedTime : 'Anytime',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                ),
              ),
              const SizedBox(width: 12),
              // Dot & Line
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Card Details
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(task.description!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Report View (matching Tasks.tsx lines 663-740) ---
  Widget _buildReportView(List<DiaryTaskModel> items, bool isMr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Due Date', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: items.map((task) {
            return DataRow(
              cells: [
                DataCell(Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(_buildPriorityBadge(task.priority, isMr)),
                DataCell(Text(task.status)),
                DataCell(Text(task.formattedDate)),
                DataCell(Text(task.address ?? task.officeName ?? '-')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildEmptyState(bool isMr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No tasks found',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search criteria',
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
