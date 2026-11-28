import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/diary_task_model.dart';
import '../../../data/repositories/diary_tasks_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_pdf_button.dart';
import 'diary_report_generator.dart';
import '../../widgets/app_dropdown.dart';

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

  String _formatTaskTime(DiaryTaskModel task, String lang) {
    if (task.dueTime == null || task.dueTime!.isEmpty) return '';
    try {
      final parts = task.dueTime!.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        return AppTranslations.formatTime(DateTime(2026, 1, 1, hour, min), lang);
      }
    } catch (_) {}
    return AppTranslations.formatDigits(task.formattedTime, lang);
  }

  Future<void> _toggleStatus() async {
    final lang = ref.read(appLanguageProvider);
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
            content: Text(
              newStatus == 'Completed'
                  ? AppTranslations.pick(
                      lang,
                      en: 'Task marked as Completed',
                      mr: 'कार्य पूर्ण म्हणून नोंदवले',
                      hi: 'कार्य पूर्ण के रूप में चिह्नित',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Task marked as Pending',
                      mr: 'कार्य प्रलंबित म्हणून नोंदवले',
                      hi: 'कार्य लंबित के रूप में चिह्नित',
                    ),
            ),
            backgroundColor: newStatus == 'Completed' ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Failed to update status: $e',
                mr: 'स्थिती अद्यतनित करण्यात अयशस्वी: $e',
                hi: 'स्थिति अपडेट करने में विफल: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showDeleteDialog() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Delete Task?',
                  mr: 'कार्य हटवायचे का?',
                  hi: 'कार्य हटाएं?',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: AppTranslatedText(
          _task.title,
          targetLanguage: lang,
          builder: (context, trTitle) => Text(
            AppTranslations.pick(
              lang,
              en: 'Are you sure you want to delete "$trTitle"? This action cannot be undone.',
              mr: 'तुम्हाला "$trTitle" हे कार्य नक्की हटवायचे आहे का? ही कृती पूर्ववत करता येणार नाही.',
              hi: 'क्या आप वाकई "$trTitle" को हटाना चाहते हैं? यह कार्रवाई पूर्ववत नहीं की जा सकती।',
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
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
                    SnackBar(
                      content: Text(
                        AppTranslations.pick(lang, en: 'Task deleted', mr: 'कार्य हटवले गेले', hi: 'कार्य हटाया गया'),
                      ),
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Failed to delete: $e',
                          mr: 'हटवण्यात अयशस्वी: $e',
                          hi: 'हटाने में विफल: $e',
                        ),
                      ),
                      backgroundColor: Colors.red,
                    ),
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
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं')),
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

    final lang = ref.read(appLanguageProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. FIXED HEADER
                AppModalHeader(
                  icon: Icons.edit_note_rounded,
                  title: AppTranslations.pick(
                    lang,
                    en: 'Edit Diary Task',
                    mr: 'दैनंदिनी नोंद संपादित करा',
                    hi: 'डायरी कार्य संपादित करें',
                  ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Update daily agenda, location, and details',
                    mr: 'दैनिक नियोजन व माहिती अद्ययावत करा',
                    hi: 'दैनिक कार्यसूची, स्थान और विवरण अपडेट करें',
                  ),
                  onClose: () => Navigator.pop(ctx),
                ),

                // 2. SCROLLABLE FORM
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(ctx).viewInsets.bottom + 12,
                    ),
                    children: [
                      // Title
                      AppFieldLabel(
                        label: AppTranslations.pick(
                          lang,
                          en: 'Task Title',
                          mr: 'कार्याचे शीर्षक',
                          hi: 'कार्य का शीर्षक',
                        ),
                        isRequired: true,
                      ),
                      TextField(
                        controller: titleCtrl,
                        decoration: appInputDecoration(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Meeting with Executive Engineer',
                            mr: 'उदा. कार्यकारी अभियंत्यांची भेट',
                            hi: 'उदा. कार्यकारी अभियंता के साथ बैठक',
                          ),
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
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Priority',
                                    mr: 'प्राधान्यता',
                                    hi: 'प्राथमिकता',
                                  ),
                                  value: ['Low', 'Medium', 'High'].contains(selectedPriority) ? selectedPriority : 'Medium',
                                  items: [
                                    DropdownMenuItem(value: 'Low', child: Text(AppTranslations.getPriority('Low', lang))),
                                    DropdownMenuItem(value: 'Medium', child: Text(AppTranslations.getPriority('Medium', lang))),
                                    DropdownMenuItem(value: 'High', child: Text(AppTranslations.getPriority('High', lang))),
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
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Status',
                                    mr: 'स्थिती',
                                    hi: 'स्थिति',
                                  ),
                                  value: ['Pending', 'Completed', 'InProgress'].contains(selectedStatus) ? selectedStatus : 'Pending',
                                  items: [
                                    DropdownMenuItem(value: 'Pending', child: Text(AppTranslations.getStatus('Pending', lang))),
                                    DropdownMenuItem(value: 'InProgress', child: Text(AppTranslations.getStatus('InProgress', lang))),
                                    DropdownMenuItem(value: 'Completed', child: Text(AppTranslations.getStatus('Completed', lang))),
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Scheduled Date',
                                    mr: 'नियोजित दिनांक',
                                    hi: 'निर्धारित तिथि',
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showThemedDatePicker(
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            selectedDate != null
                                                ? AppTranslations.formatDate(selectedDate!, lang, pattern: 'dd MMM yyyy')
                                                : AppTranslations.pick(
                                                    lang,
                                                    en: 'Pick Date',
                                                    mr: 'दिनांक निवडा',
                                                    hi: 'तिथि चुनें',
                                                  ),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Scheduled Time',
                                    mr: 'नियोजित वेळ',
                                    hi: 'निर्धारित समय',
                                  ),
                                ),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            selectedTime != null
                                                ? AppTranslations.formatTime(
                                                    DateTime(2026, 1, 1, selectedTime!.hour, selectedTime!.minute),
                                                    lang,
                                                  )
                                                : AppTranslations.pick(
                                                    lang,
                                                    en: 'Pick Time',
                                                    mr: 'वेळ निवडा',
                                                    hi: 'समय चुनें',
                                                  ),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Location / Address',
                                    mr: 'ठिकाण / पत्ता',
                                    hi: 'स्थान / पता',
                                  ),
                                ),
                                TextField(
                                  controller: addrCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Sector 2 Market Road',
                                      mr: 'उदा. सेक्टर २ मार्केट रोड',
                                      hi: 'उदा. सेक्टर २ मार्केट रोड',
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Office / Dept',
                                    mr: 'कार्यालय / विभाग',
                                    hi: 'कार्यालय / विभाग',
                                  ),
                                ),
                                TextField(
                                  controller: officeCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Water Supply Dept',
                                      mr: 'उदा. पाणी पुरवठा विभाग',
                                      hi: 'उदा. जल आपूर्ति विभाग',
                                    ),
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Person to Meet',
                                    mr: 'भेट घ्यावयाची व्यक्ती',
                                    hi: 'मिलने वाले व्यक्ति',
                                  ),
                                ),
                                TextField(
                                  controller: personCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Executive Engineer',
                                      mr: 'उदा. कार्यकारी अभियंता',
                                      hi: 'उदा. कार्यकारी अभियंता',
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Assigned To',
                                    mr: 'नियुक्त कार्यकर्ता',
                                    hi: 'नियुक्त कार्यकर्ता',
                                  ),
                                ),
                                TextField(
                                  controller: staffCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Sunil Shinde (JE)',
                                      mr: 'उदा. सुनील शिंदे (जेई)',
                                      hi: 'उदा. सुनील शिंदे (जेई)',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      AppFieldLabel(
                        label: AppTranslations.pick(
                          lang,
                          en: 'Detailed Instructions & Notes',
                          mr: 'तपशीलवार सूचना / मुद्दे',
                          hi: 'विस्तृत निर्देश व नोट्स',
                        ),
                      ),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: appInputDecoration(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'Agenda points, background, or action required...',
                            mr: 'अजेंडा, पार्श्वभूमी किंवा आवश्यक कृती...',
                            hi: 'कार्यसूची के बिंदु, पृष्ठभूमि या आवश्यक कार्रवाई...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save Changes Button (Scrolls together with form)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final t = titleCtrl.text.trim();
                            if (t.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Please enter task title',
                                      mr: 'कृपया कार्याचे शीर्षक प्रविष्ट करा',
                                      hi: 'कृपया कार्य का शीर्षक दर्ज करें',
                                    ),
                                  ),
                                ),
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
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Task updated successfully',
                                        mr: 'नोंद यशस्वीरित्या अद्ययावत केली',
                                        hi: 'कार्य सफलतापूर्वक अपडेट किया गया',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF0F766E),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Failed to update: $e',
                                        mr: 'अद्ययावत करण्यात अयशस्वी: $e',
                                        hi: 'अपडेट करने में विफल: $e',
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
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
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Save Changes',
                              mr: 'बदल जतन करा',
                              hi: 'बदलाव सहेजें',
                            ),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
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
    final lang = ref.watch(appLanguageProvider);
    final formattedDate = _task.dueDate != null
        ? AppTranslations.formatDate(_task.dueDate!, lang, pattern: 'MMM d, yyyy')
        : '-';
    final formattedTime = _formatTaskTime(_task, lang);

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
                AppTranslations.pick(
                  lang,
                  en: 'Diary Task Details',
                  mr: 'दैनंदिनी नोंद तपशील',
                  hi: 'डायरी कार्य विवरण',
                ),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AppPdfButton.icon(
                  tooltip: AppTranslations.getDownloadReport(lang),
                  onPressed: () {
                    DiaryReportGenerator.generateAndPrintSingleTask(_task, lang: lang);
                  },
                ),
              ),
            ),
            IconButton(
              tooltip: AppTranslations.pick(lang, en: 'Edit Task', mr: 'कार्य संपादित करा', hi: 'कार्य संपादित करें'),
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: _showEditSheet,
            ),
            IconButton(
              tooltip: AppTranslations.pick(lang, en: 'Delete Task', mr: 'कार्य हटवा', hi: 'कार्य हटाएं'),
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
                                  border: Border.all(color: _priorityColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flag_rounded, size: 12, color: _priorityColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppTranslations.getPriority(_task.priority, lang),
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
                                  AppTranslations.getStatus(_task.status, lang),
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
                          AppTranslatedText(
                            _task.title,
                            targetLanguage: lang,
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
                                label: formattedDate,
                                color: const Color(0xFF0284C7),
                              ),
                              if (formattedTime.isNotEmpty)
                                _buildMetaTag(
                                  icon: Icons.access_time_rounded,
                                  label: formattedTime,
                                  color: const Color(0xFFD97706),
                                ),
                              if (_task.address != null && _task.address!.isNotEmpty)
                                _buildMetaTag(
                                  icon: Icons.location_on_outlined,
                                  label: AppTranslations.getAreaName(_task.address!, lang),
                                  color: const Color(0xFF475569),
                                  translate: true,
                                  lang: lang,
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
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  _task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: _task.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _task.isCompleted
                                            ? AppTranslations.pick(
                                                lang,
                                                en: 'Task is Completed',
                                                mr: 'कार्य पूर्ण झाले आहे',
                                                hi: 'कार्य पूर्ण हो चुका है',
                                              )
                                            : AppTranslations.pick(
                                                lang,
                                                en: 'Task is Open / Pending',
                                                mr: 'कार्य प्रलंबित आहे',
                                                hi: 'कार्य लंबित है',
                                              ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _task.isCompleted ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                                        ),
                                      ),
                                      Text(
                                        _task.isCompleted
                                            ? AppTranslations.pick(
                                                lang,
                                                en: 'Tap to mark as pending again',
                                                mr: 'पुन्हा प्रलंबित करण्यासाठी टॅप करा',
                                                hi: 'फिर से लंबित करने के लिए टैप करें',
                                              )
                                            : AppTranslations.pick(
                                                lang,
                                                en: 'Tap to mark as completed',
                                                mr: 'पूर्ण म्हणून नोंदवण्यासाठी टॅप करा',
                                                hi: 'पूर्ण करने के लिए टैप करें',
                                              ),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _toggleStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _task.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              _task.isCompleted
                                  ? AppTranslations.pick(lang, en: 'Reopen', mr: 'पुन्हा उघडा', hi: 'पुनः खोलें')
                                  : AppTranslations.pick(lang, en: 'Done', mr: 'पूर्ण करा', hi: 'पूर्ण करें'),
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
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Appointment & Assignment Details',
                                mr: 'भेट व जबाबदारी तपशील',
                                hi: 'मुलाकात व कार्य आवंटन विवरण',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),
                            if (_task.officeName != null && _task.officeName!.isNotEmpty)
                              _buildDetailRow(
                                Icons.business_rounded,
                                AppTranslations.pick(
                                  lang,
                                  en: 'Office / Department',
                                  mr: 'कार्यालय / विभाग',
                                  hi: 'कार्यालय / विभाग',
                                ),
                                _task.officeName!,
                                lang: lang,
                              ),
                            if (_task.meetPersonName != null && _task.meetPersonName!.isNotEmpty)
                              _buildDetailRow(
                                Icons.person_outline_rounded,
                                AppTranslations.pick(
                                  lang,
                                  en: 'Person to Meet',
                                  mr: 'भेटायची व्यक्ती',
                                  hi: 'मिलने वाले व्यक्ति',
                                ),
                                _task.meetPersonName!,
                                isName: true,
                                lang: lang,
                              ),
                            if (_task.assignedStaffName != null && _task.assignedStaffName!.isNotEmpty)
                              _buildDetailRow(
                                Icons.badge_outlined,
                                AppTranslations.pick(
                                  lang,
                                  en: 'Assigned Staff',
                                  mr: 'नियुक्त कर्मचारी',
                                  hi: 'नियुक्त कर्मचारी',
                                ),
                                _task.assignedStaffName!,
                                isName: true,
                                lang: lang,
                              ),
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
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Description & Agenda Notes',
                              mr: 'तपशील आणि अजेंडा नोंदी',
                              hi: 'विवरण और कार्यसूची',
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          if (_task.description != null && _task.description!.isNotEmpty)
                            AppTranslatedText(
                              _task.description!,
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.5),
                            )
                          else
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'No additional discussion details recorded.',
                                mr: 'कोणतीही अतिरिक्त चर्चा किंवा टिपण उपलब्ध नाही.',
                                hi: 'कोई अतिरिक्त विवरण दर्ज नहीं है।',
                              ),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
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
    bool translate = false,
    String? lang,
  }) {
    final style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color);
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
          Flexible(
            child: translate
                ? AppTranslatedText(
                    label,
                    targetLanguage: lang,
                    style: style,
                  )
                : Text(
                    label,
                    style: style,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value, {
    bool isName = false,
    required String lang,
  }) {
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
                AppTranslatedText(
                  value,
                  isName: isName,
                  targetLanguage: lang,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}