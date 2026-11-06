import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../data/models/diary_task_model.dart';
import '../../../data/repositories/diary_tasks_repository.dart';
import '../../providers/auth_provider.dart';
import 'diary_report_generator.dart';

class DiaryDetailScreen extends ConsumerStatefulWidget {
  final DiaryTaskModel task;
  final VoidCallback? onTaskUpdated;

  const DiaryDetailScreen({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  @override
  ConsumerState<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends ConsumerState<DiaryDetailScreen> {
  late DiaryTaskModel _task;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Color get _priorityColor {
    switch (_task.priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626); // red-600
      case 'medium':
        return const Color(0xFFD97706); // amber-600
      case 'low':
        return const Color(0xFF16A34A); // green-600
      default:
        return const Color(0xFF0284C7);
    }
  }

  Color get _priorityBgColor {
    switch (_task.priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFFEF2F2);
      case 'medium':
        return const Color(0xFFFEFCE8);
      case 'low':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFF0F9FF);
    }
  }

  Future<void> _toggleStatus() async {
    setState(() => _isUpdating = true);
    final newStatus = _task.isCompleted ? 'Pending' : 'Completed';
    try {
      final repo = ref.read(diaryTasksRepoProvider);
      await repo.updateTask(_task.id, {'status': newStatus});
      setState(() {
        _task = _task.copyWith(status: newStatus);
      });
      widget.onTaskUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'Completed' ? 'Task marked as Completed' : 'Task marked as Pending'),
            backgroundColor: newStatus == 'Completed' ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Delete Task?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_task.title}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isUpdating = true);
              try {
                final repo = ref.read(diaryTasksRepoProvider);
                await repo.deleteTask(_task.id);
                widget.onTaskUpdated?.call();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted'), backgroundColor: Color(0xFF0F766E)),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isUpdating = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet() {
    final titleCtrl = TextEditingController(text: _task.title);
    final descCtrl = TextEditingController(text: _task.description ?? '');
    final addrCtrl = TextEditingController(text: _task.address ?? '');
    final officeCtrl = TextEditingController(text: _task.officeName ?? '');
    final personCtrl = TextEditingController(text: _task.meetPersonName ?? '');
    final staffCtrl = TextEditingController(text: _task.assignedStaffName ?? '');

    DateTime? selectedDate = _task.dueDate;
    TimeOfDay? selectedTime;
    if (_task.dueTime != null && _task.dueTime!.isNotEmpty) {
      try {
        final parts = _task.dueTime!.split(':');
        selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }
    String selectedPriority = _task.priority;
    String selectedStatus = _task.status;

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
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        'Edit Diary Task',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text('Task Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Meeting with Executive Engineer',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Priority & Status
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: ['Low', 'Medium', 'High'].contains(selectedPriority) ? selectedPriority : 'Medium',
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Low', child: Text('Low (कमी)')),
                                      DropdownMenuItem(value: 'Medium', child: Text('Medium (मध्यम)')),
                                      DropdownMenuItem(value: 'High', child: Text('High (उच्च)')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedPriority = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: ['Pending', 'Completed', 'InProgress'].contains(selectedStatus) ? selectedStatus : 'Pending',
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Pending', child: Text('Pending (प्रलंबित)')),
                                      DropdownMenuItem(value: 'InProgress', child: Text('In Progress (प्रगतीत)')),
                                      DropdownMenuItem(value: 'Completed', child: Text('Completed (पूर्ण)')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedStatus = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Date & Time
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Scheduled Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setModalState(() => selectedDate = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 8),
                                          Text(
                                            selectedDate != null ? DateFormat('dd MMM yyyy').format(selectedDate!) : 'Pick Date',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                                  const Text('Scheduled Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
                                      );
                                      if (picked != null) {
                                        setModalState(() => selectedTime = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 8),
                                          Text(
                                            selectedTime != null ? selectedTime!.format(context) : 'Pick Time',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

                        // Location & Office
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Location / Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: addrCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Sector 2 Market Road',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                                  const Text('Office / Dept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: officeCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Water Supply Dept',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                                      hintText: 'e.g. Executive Engineer',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                                  const Text('Assigned To', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: staffCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Sunil Shinde (JE)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Description
                        const Text('Detailed Instructions & Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Agenda points, background, or action required...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final t = titleCtrl.text.trim();
                              if (t.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter task title')),
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              setState(() => _isUpdating = true);
                              try {
                                String? timeStr;
                                if (selectedTime != null) {
                                  timeStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                                }

                                final updates = {
                                  'title': t,
                                  'description': descCtrl.text.trim(),
                                  'priority': selectedPriority,
                                  'status': selectedStatus,
                                  'due_date': selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null,
                                  'due_time': timeStr,
                                  'address': addrCtrl.text.trim(),
                                  'office_name': officeCtrl.text.trim(),
                                  'meet_person_name': personCtrl.text.trim(),
                                  'assigned_to': staffCtrl.text.trim(),
                                };

                                final repo = ref.read(diaryTasksRepoProvider);
                                await repo.updateTask(_task.id, updates);
                                setState(() {
                                  _task = _task.copyWith(
                                    title: t,
                                    description: descCtrl.text.trim(),
                                    priority: selectedPriority,
                                    status: selectedStatus,
                                    dueDate: selectedDate,
                                    dueTime: timeStr,
                                    address: addrCtrl.text.trim(),
                                    officeName: officeCtrl.text.trim(),
                                    meetPersonName: personCtrl.text.trim(),
                                    assignedStaffName: staffCtrl.text.trim(),
                                  );
                                });
                                widget.onTaskUpdated?.call();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Task updated successfully'),
                                      backgroundColor: Color(0xFF0F766E),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isUpdating = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMr ? 'दैनंदिनी नोंद तपशील' : 'Diary Task Details',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                _task.formattedDate,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Export Task Slip PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
              onPressed: () {
                DiaryReportGenerator.generateAndPrintSingleTask(_task);
              },
            ),
            IconButton(
              tooltip: 'Edit Task',
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: _showEditSheet,
            ),
            IconButton(
              tooltip: 'Delete Task',
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _showDeleteDialog,
            ),
          ],
        ),
        body: _isUpdating
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Status & Title Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Priority Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _priorityBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _priorityColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flag_rounded, size: 12, color: _priorityColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_task.priority} Priority',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _priorityColor),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _task.isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _task.isCompleted ? const Color(0xFF86EFAC) : const Color(0xFFFDE047),
                                  ),
                                ),
                                child: Text(
                                  _task.isCompleted ? (isMr ? 'पूर्ण झाले' : 'Completed') : (isMr ? 'प्रलंबित' : 'Pending'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _task.isCompleted ? const Color(0xFF166534) : const Color(0xFF854D0E),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Task Title
                          Text(
                            _task.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Date & Time Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildMetaTag(
                                icon: Icons.calendar_today_outlined,
                                label: _task.formattedDate,
                                color: const Color(0xFF0284C7),
                              ),
                              if (_task.formattedTime.isNotEmpty)
                                _buildMetaTag(
                                  icon: Icons.access_time_rounded,
                                  label: _task.formattedTime,
                                  color: const Color(0xFFD97706),
                                ),
                              if (_task.address != null && _task.address!.isNotEmpty)
                                _buildMetaTag(
                                  icon: Icons.location_on_outlined,
                                  label: _task.address!,
                                  color: const Color(0xFF475569),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Quick Toggle Action Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _task.isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _task.isCompleted ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: _task.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _task.isCompleted ? 'Task is Completed' : 'Task is Open / Pending',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _task.isCompleted ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                  Text(
                                    _task.isCompleted ? 'Tap to mark as pending again' : 'Tap to mark as completed',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _toggleStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _task.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              _task.isCompleted ? 'Reopen' : 'Done',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Key Meeting Info
                    if ((_task.officeName != null && _task.officeName!.isNotEmpty) ||
                        (_task.meetPersonName != null && _task.meetPersonName!.isNotEmpty) ||
                        (_task.assignedStaffName != null && _task.assignedStaffName!.isNotEmpty))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Appointment & Assignment Details',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),
                            if (_task.officeName != null && _task.officeName!.isNotEmpty)
                              _buildDetailRow(Icons.business_rounded, 'Office / Department', _task.officeName!),
                            if (_task.meetPersonName != null && _task.meetPersonName!.isNotEmpty)
                              _buildDetailRow(Icons.person_outline_rounded, 'Person to Meet', _task.meetPersonName!),
                            if (_task.assignedStaffName != null && _task.assignedStaffName!.isNotEmpty)
                              _buildDetailRow(Icons.badge_outlined, 'Assigned Staff', _task.assignedStaffName!),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Description / Notes
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description & Agenda Notes',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _task.description != null && _task.description!.isNotEmpty
                                ? _task.description!
                                : 'No additional discussion details recorded.',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetaTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0284C7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
