import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/diary_task_model.dart';
import '../../../data/repositories/diary_tasks_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'diary_detail_screen.dart';
import 'diary_report_generator.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  // Primary Tabs matching Complaints & Requests pattern:
  // 'timeline' (Today's Schedule), 'all' (All Tasks), 'completed' (Completed)
  String _activeTab = 'timeline';

  DateTime _selectedTimelineDate = DateTime.now();
  String _selectedPriority = 'All';
  String _selectedArea = 'All';

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  List<DiaryTaskModel> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(diaryTasksRepoProvider);
      final list = await repo.getTasks();
      setState(() {
        _allTasks = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<String> get _uniqueAreas {
    final set = <String>{};
    for (final t in _allTasks) {
      if (t.address != null && t.address!.trim().isNotEmpty) {
        set.add(t.address!.trim());
      }
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DiaryTaskModel> get _filteredTasks {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allTasks.where((task) {
      // Primary Tab Filtering
      if (_activeTab == 'timeline') {
        if (task.dueDate == null) return false;
        if (!_isSameDay(task.dueDate!, _selectedTimelineDate)) return false;
      } else if (_activeTab == 'completed') {
        if (!task.isCompleted) return false;
      } else if (_activeTab == 'all') {
        // all tasks
      }

      // Search Query
      if (query.isNotEmpty) {
        final titleMatch = task.title.toLowerCase().contains(query);
        final descMatch = task.description?.toLowerCase().contains(query) ?? false;
        final addrMatch = task.address?.toLowerCase().contains(query) ?? false;
        final officeMatch = task.officeName?.toLowerCase().contains(query) ?? false;
        final personMatch = task.meetPersonName?.toLowerCase().contains(query) ?? false;
        if (!titleMatch && !descMatch && !addrMatch && !officeMatch && !personMatch) {
          return false;
        }
      }

      // Priority Filter
      if (_selectedPriority != 'All' && task.priority.toLowerCase() != _selectedPriority.toLowerCase()) {
        return false;
      }

      // Area Filter
      if (_selectedArea != 'All') {
        final taskArea = task.address ?? '';
        if (!taskArea.toLowerCase().contains(_selectedArea.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        // Timeline sorted by time
        if (_activeTab == 'timeline') {
          final tA = a.dueTime ?? '23:59';
          final tB = b.dueTime ?? '23:59';
          return tA.compareTo(tB);
        }
        // Others sorted by date descending
        final dA = a.dueDate ?? DateTime(2000);
        final dB = b.dueDate ?? DateTime(2000);
        return dB.compareTo(dA);
      });
  }

  void _changeTimelineDate(int days) {
    setState(() {
      _selectedTimelineDate = _selectedTimelineDate.add(Duration(days: days));
    });
  }

  void _jumpToToday() {
    setState(() {
      _selectedTimelineDate = DateTime.now();
    });
  }

  Future<void> _toggleTaskStatus(DiaryTaskModel task) async {
    final repo = ref.read(diaryTasksRepoProvider);
    final isDone = task.isCompleted;
    final updated = task.copyWith(status: isDone ? 'Pending' : 'Completed');

    setState(() {
      final index = _allTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _allTasks[index] = updated;
      }
    });

    try {
      await repo.toggleStatus(task.id, isDone);
    } catch (_) {}
  }

  void _openAddTaskModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final officeCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final staffCtrl = TextEditingController();

    DateTime selectedDate = _activeTab == 'timeline' ? _selectedTimelineDate : DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String selectedPriority = 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Modal Handle & Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New Diary Task / Visit',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Title
                        const Text('Task / Meeting Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Meeting with Executive Engineer regarding Water pipeline',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Date & Time Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Scheduled Date *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setModalState(() => selectedDate = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('dd MMM yyyy').format(selectedDate),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Time *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: selectedTime,
                                      );
                                      if (picked != null) {
                                        setModalState(() => selectedTime = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 8),
                                          Text(
                                            selectedTime.format(context),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

                        const SizedBox(height: 16),

                        // Priority Dropdown
                        const Text('Priority Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedPriority,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Low', child: Text('Low (कमी प्राधान्यता)')),
                            DropdownMenuItem(value: 'Medium', child: Text('Medium (मध्यम प्राधान्यता)')),
                            DropdownMenuItem(value: 'High', child: Text('High (उच्च प्राधान्यता)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPriority = val);
                          },
                        ),

                        const SizedBox(height: 16),

                        // Address / Location & Office
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Address / Area', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: addrCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Ward Office / Lane 4',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Office / Department', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: officeCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. PMC Water Supply Dept',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Person to meet & Assigned staff
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Person to Meet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: personCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. S. V. Kulkarni',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Assigned Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: staffCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Prashant Kadam (PA)',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Description / Notes
                        const Text('Detailed Instructions & Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Agenda points, background, or action items...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter task title')),
                                );
                                return;
                              }

                              Navigator.pop(ctx);
                              final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                              final newTask = DiaryTaskModel(
                                id: 'TASK-${DateTime.now().millisecondsSinceEpoch % 10000}',
                                title: title,
                                description: descCtrl.text.trim(),
                                priority: selectedPriority,
                                status: 'Pending',
                                dueDate: selectedDate,
                                dueTime: timeStr,
                                address: addrCtrl.text.trim(),
                                officeName: officeCtrl.text.trim(),
                                meetPersonName: personCtrl.text.trim(),
                                assignedStaffName: staffCtrl.text.trim(),
                                createdAt: DateTime.now(),
                              );

                              setState(() {
                                _allTasks.insert(0, newTask);
                              });

                              try {
                                final repo = ref.read(diaryTasksRepoProvider);
                                await repo.addTask(newTask);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Diary task added successfully!'),
                                      backgroundColor: Color(0xFF0F766E),
                                    ),
                                  );
                                }
                              } catch (_) {}
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Save & Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
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
    final isMr = ref.watch(isMarathiProvider);
    final filtered = _filteredTasks;

    final todayTasksCount = _allTasks.where((t) => t.dueDate != null && _isSameDay(t.dueDate!, DateTime.now())).length;
    final allTasksCount = _allTasks.length;
    final completedCount = _allTasks.where((t) => t.isCompleted).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const NagarsevakAppDrawer(
          currentTabIndex: 0,
        ),
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
                'Diary',
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
                'Task management, daily visits and itinerary',
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddTaskModal,
          backgroundColor: const Color(0xFF0284C7),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            isMr ? 'नवीन नोंद' : 'New Task',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: Column(
          children: [
            // 1. Primary Navigation Tabs (matching Complaints & Requests format)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Timeline Tab
                    Expanded(
                      child: _buildPrimaryTab(
                        label: isMr ? 'टाइमलाइन' : 'Timeline',
                        count: todayTasksCount,
                        isActive: _activeTab == 'timeline',
                        icon: Icons.access_time_rounded,
                        onTap: () => setState(() => _activeTab = 'timeline'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // All Tasks Tab
                    Expanded(
                      child: _buildPrimaryTab(
                        label: isMr ? 'सर्व कामे' : 'All Tasks',
                        count: allTasksCount,
                        isActive: _activeTab == 'all',
                        icon: Icons.format_list_bulleted_rounded,
                        onTap: () => setState(() => _activeTab = 'all'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Completed Tab
                    Expanded(
                      child: _buildPrimaryTab(
                        label: isMr ? 'पूर्ण झालेली' : 'Completed',
                        count: completedCount,
                        isActive: _activeTab == 'completed',
                        icon: Icons.check_circle_outline_rounded,
                        onTap: () => setState(() => _activeTab = 'completed'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Timeline Subheader (Date Switcher) or Search Bar
            if (_activeTab == 'timeline') ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    // Today Shortcut
                    InkWell(
                      onTap: _jumpToToday,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _isSameDay(_selectedTimelineDate, DateTime.now())
                              ? const Color(0xFFE0F2FE)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isSameDay(_selectedTimelineDate, DateTime.now())
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          isMr ? 'आज' : 'Today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isSameDay(_selectedTimelineDate, DateTime.now())
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Date Navigator
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF0284C7)),
                              onPressed: () => _changeTimelineDate(-1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedTimelineDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => _selectedTimelineDate = picked);
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, size: 15, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('EEE, dd MMM yyyy').format(_selectedTimelineDate),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF0284C7)),
                              onPressed: () => _changeTimelineDate(1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        DiaryReportGenerator.generateAndPrintTasksReport(
                          tasks: filtered,
                          filterTitle: _activeTab == 'timeline'
                              ? 'Date: ${DateFormat('dd MMM yyyy').format(_selectedTimelineDate)}'
                              : 'Tab: $_activeTab | Priority: $_selectedPriority',
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Search & Area Filter Bar for 'All' / 'Completed'
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: isMr ? 'शीर्षक, पत्ता, कार्यालय किंवा व्यक्ती शोधा...' : 'Search title, address, office...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    ),
                    if (_uniqueAreas.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        initialValue: _selectedArea,
                        tooltip: 'Filter by Area',
                        icon: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _selectedArea != 'All' ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedArea != 'All' ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: _selectedArea != 'All' ? const Color(0xFF0284C7) : const Color(0xFF475569),
                          ),
                        ),
                        onSelected: (val) => setState(() => _selectedArea = val),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'All', child: Text('All Areas (सर्व परिसर)')),
                          ..._uniqueAreas.map((a) => PopupMenuItem(value: a, child: Text(a))),
                        ],
                      ),
                    ],
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        DiaryReportGenerator.generateAndPrintTasksReport(
                          tasks: filtered,
                          filterTitle: 'Tab: $_activeTab | Priority: $_selectedPriority',
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // 3. Main Tasks List / Timeline
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_note_outlined, size: 52, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                Text(
                                  _activeTab == 'timeline'
                                      ? (isMr ? 'आजच्या तारखेला कोणतीही कामे नाहीत' : 'No tasks scheduled for this day')
                                      : (isMr ? 'कोणत्याही नोंदी आढळल्या नाहीत' : 'No diary tasks found'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isMr
                                      ? 'नवीन काम किंवा दौरा जोडण्यासाठी खालील "+ नवीन नोंद" वर टॅप करा.'
                                      : 'Tap "+ New Task" below to record a meeting, visit, or appointment.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchTasks,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, index) {
                              final task = filtered[index];
                              return _buildTaskCard(task, isMr);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryTab({
    required String label,
    required int count,
    required bool isActive,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(DiaryTaskModel task, bool isMr) {
    Color priorityColor;
    Color priorityBg;
    switch (task.priority.toLowerCase()) {
      case 'high':
        priorityColor = const Color(0xFFDC2626);
        priorityBg = const Color(0xFFFEF2F2);
        break;
      case 'medium':
        priorityColor = const Color(0xFFD97706);
        priorityBg = const Color(0xFFFEFCE8);
        break;
      default:
        priorityColor = const Color(0xFF16A34A);
        priorityBg = const Color(0xFFF0FDF4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.isCompleted ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: task.isCompleted ? 1.2 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DiaryDetailScreen(
                task: task,
                onTaskUpdated: _fetchTasks,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Checkbox, Title & Priority
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // One-Tap Status Checkbox
                  InkWell(
                    onTap: () => _toggleTaskStatus(task),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10, top: 2),
                      child: Icon(
                        task.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: task.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ),
                  ),

                  // Title & Meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: task.isCompleted ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            height: 1.3,
                          ),
                        ),
                        if (task.description != null && task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Priority Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      task.priority,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Badges Row: Time, Location, Office, Person
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (task.formattedTime.isNotEmpty)
                    _buildPill(Icons.access_time_rounded, task.formattedTime, const Color(0xFF0284C7), const Color(0xFFF0F9FF)),
                  if (task.dueDate != null && _activeTab != 'timeline')
                    _buildPill(Icons.calendar_today_outlined, task.formattedDate, const Color(0xFF475569), const Color(0xFFF8FAFC)),
                  if (task.officeName != null && task.officeName!.isNotEmpty)
                    _buildPill(Icons.business_outlined, task.officeName!, const Color(0xFF6B21A8), const Color(0xFFFAF5FF)),
                  if (task.address != null && task.address!.isNotEmpty)
                    _buildPill(Icons.location_on_outlined, task.address!, const Color(0xFF334155), const Color(0xFFF1F5F9)),
                  if (task.meetPersonName != null && task.meetPersonName!.isNotEmpty)
                    _buildPill(Icons.person_outline, task.meetPersonName!, const Color(0xFF0F766E), const Color(0xFFF0FDFA)),
                ],
              ),

              const SizedBox(height: 8),

              // Footer: Assigned to & Details link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (task.assignedStaffName != null && task.assignedStaffName!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          task.assignedStaffName!,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),

                  Row(
                    children: [
                      Text(
                        isMr ? 'तपशील' : 'Details',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0284C7)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}
