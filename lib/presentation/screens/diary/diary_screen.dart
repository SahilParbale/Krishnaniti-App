import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/diary_task_model.dart';
import '../../../data/repositories/diary_tasks_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
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
  bool _isLoading = true;

  int _displayedLimit = 20;

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
      final loc = (t.address != null && t.address!.trim().isNotEmpty)
          ? t.address!.trim()
          : (t.officeName != null && t.officeName!.trim().isNotEmpty)
              ? t.officeName!.trim()
              : '';
      if (loc.isNotEmpty) {
        set.add(loc);
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
        final taskArea = '${task.address ?? ""} ${task.officeName ?? ""}'.toLowerCase();
        if (!taskArea.contains(_selectedArea.toLowerCase())) {
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

  List<DiaryTaskModel> get _visibleTasks =>
      _filteredTasks.take(_displayedLimit).toList();

  void _changeTimelineDate(int days) {
    setState(() {
      _selectedTimelineDate = _selectedTimelineDate.add(Duration(days: days));
      _displayedLimit = 20;
    });
  }

  void _jumpToToday() {
    setState(() {
      _selectedTimelineDate = DateTime.now();
      _displayedLimit = 20;
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

  void _openAddTaskModal() {
    final lang = ref.read(appLanguageProvider);
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
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. FIXED HEADER
                AppModalHeader(
                  icon: Icons.event_note_rounded,
                  title: AppTranslations.pick(
                    lang,
                    en: 'New Diary Task / Visit',
                    mr: 'नवीन डायरी कार्य / बैठक नोंद',
                    hi: 'नया डायरी कार्य / भेंट',
                  ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Schedule daily agenda, officer visits and field work',
                    mr: 'दैनिक नियोजन, बैठका व क्षेत्रीय भेटींची नोंद',
                    hi: 'दैनिक कार्यसूची, बैठकें और क्षेत्रीय दौरे',
                  ),
                  onClose: () => Navigator.pop(ctx),
                ),

                // 2. SCROLLABLE FORM BODY
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      14,
                      18,
                      MediaQuery.of(ctx).viewInsets.bottom + 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Title
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Task / Meeting Title',
                            mr: 'कामाचे नाव / विषय',
                            hi: 'कार्य / बैठक का शीर्षक',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: AppTranslations.pick(
                              lang,
                              en: 'e.g. Meeting with Executive Engineer regarding Water pipeline',
                              mr: 'उदा. पाणीपुरवठ्याबाबत कार्यकारी अभियंत्यांसोबत बैठक',
                              hi: 'उदा. जल आपूर्ति के संबंध में कार्यकारी अभियंता के साथ बैठक',
                            ),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Scheduled Date',
                                      mr: 'नियोजित तारीख',
                                      hi: 'निर्धारित तिथि',
                                    ),
                                    isRequired: true,
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showThemedDatePicker(
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
                                          Flexible(
                                            child: Text(
                                              AppTranslations.formatDate(selectedDate, lang, pattern: 'dd MMM yyyy'),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                                      en: 'Time',
                                      mr: 'वेळ',
                                      hi: 'समय',
                                    ),
                                    isRequired: true,
                                  ),
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
                                          Flexible(
                                            child: Text(
                                              AppTranslations.formatTime(
                                                DateTime(2026, 1, 1, selectedTime.hour, selectedTime.minute),
                                                lang,
                                              ),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

                        // Priority Dropdown
                        AppDropdownFormField<String>(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Priority Level',
                            mr: 'प्राधान्यता स्तर',
                            hi: 'प्राथमिकता स्तर',
                          ),
                          value: selectedPriority,
                          items: [
                            DropdownMenuItem(value: 'Low', child: Text(AppTranslations.getPriority('Low', lang))),
                            DropdownMenuItem(value: 'Medium', child: Text(AppTranslations.getPriority('Medium', lang))),
                            DropdownMenuItem(value: 'High', child: Text(AppTranslations.getPriority('High', lang))),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Address / Area',
                                      mr: 'पत्ता / परिसर',
                                      hi: 'पता / क्षेत्र',
                                    ),
                                  ),
                                  TextField(
                                    controller: addrCtrl,
                                    decoration: InputDecoration(
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. Ward Office / Lane 4',
                                        mr: 'उदा. प्रभाग कार्यालय / गल्ली ४',
                                        hi: 'उदा. वार्ड कार्यालय / गली ४',
                                      ),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Office / Department',
                                      mr: 'कार्यालय / विभाग',
                                      hi: 'कार्यालय / विभाग',
                                    ),
                                  ),
                                  TextField(
                                    controller: officeCtrl,
                                    decoration: InputDecoration(
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. PMC Water Supply Dept',
                                        mr: 'उदा. मनपा पाणीपुरवठा विभाग',
                                        hi: 'उदा. नगर निगम जल आपूर्ति विभाग',
                                      ),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Person to Meet',
                                      mr: 'भेटायची व्यक्ती',
                                      hi: 'मिलने वाले व्यक्ति',
                                    ),
                                  ),
                                  TextField(
                                    controller: personCtrl,
                                    decoration: InputDecoration(
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. S. V. Kulkarni',
                                        mr: 'उदा. एस. व्ही. कुलकर्णी',
                                        hi: 'उदा. एस. वी. कुलकर्णी',
                                      ),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Assigned Staff',
                                      mr: 'नेमलेला कर्मचारी',
                                      hi: 'नियुक्त कर्मचारी',
                                    ),
                                  ),
                                  TextField(
                                    controller: staffCtrl,
                                    decoration: InputDecoration(
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. Prashant Kadam (PA)',
                                        mr: 'उदा. प्रशांत कदम (पी.ए.)',
                                        hi: 'उदा. प्रशांत कदम (पी.ए.)',
                                      ),
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
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Detailed Instructions & Notes',
                            mr: 'सविस्तर सूचना व टिपण',
                            hi: 'विस्तृत निर्देश और नोट्स',
                          ),
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: AppTranslations.pick(
                              lang,
                              en: 'Agenda points, background, or action items...',
                              mr: 'अजेंडा मुद्दे, पार्श्वभूमी किंवा कार्यवाहीचे मुद्दे...',
                              hi: 'कार्यसूची के बिंदु, पृष्ठभूमि या आवश्यक कार्रवाई...',
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Save Button (Scrolls together with form)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Please enter task title',
                                        mr: 'कृपया कामाचे शीर्षक प्रविष्ट करा',
                                        hi: 'कृपया कार्य का शीर्षक दर्ज करें',
                                      ),
                                    ),
                                  ),
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
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Diary task added successfully!',
                                          mr: 'दैनिक नोंद यशस्वीरीत्या जतन झाली!',
                                          hi: 'डायरी कार्य सफलतापूर्वक जोड़ा गया!',
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFF0F766E),
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
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Save & Schedule',
                                mr: 'जतन करा आणि वेळापत्रक ठरवा',
                                hi: 'सहेजें और शेड्यूल करें',
                              ),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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
    final lang = ref.watch(appLanguageProvider);
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
              tooltip: AppTranslations.pick(
                lang,
                en: 'Open Menu Drawer',
                mr: 'मेनू उघडा',
                hi: 'मेनू खोलें',
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.getNavTitle('tasks', lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Task management, daily visits and itinerary',
                  mr: 'दैनिक नियोजन, बैठका व क्षेत्रीय भेटींची नोंद',
                  hi: 'दैनिक कार्यसूची, बैठकें और क्षेत्रीय दौरे',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
            AppTranslations.pick(lang, en: 'New Task', mr: 'नवीन नोंद', hi: 'नई प्रविष्टि'),
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
                        label: AppTranslations.pick(lang, en: 'Timeline', mr: 'टाइमलाइन', hi: 'समयरेखा'),
                        count: todayTasksCount,
                        lang: lang,
                        isActive: _activeTab == 'timeline',
                        icon: Icons.access_time_rounded,
                        onTap: () => setState(() {
                          _activeTab = 'timeline';
                          _displayedLimit = 20;
                        }),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // All Tasks Tab
                    Expanded(
                      child: _buildPrimaryTab(
                        label: AppTranslations.pick(lang, en: 'All Tasks', mr: 'सर्व कामे', hi: 'सभी कार्य'),
                        count: allTasksCount,
                        lang: lang,
                        isActive: _activeTab == 'all',
                        icon: Icons.format_list_bulleted_rounded,
                        onTap: () => setState(() {
                          _activeTab = 'all';
                          _displayedLimit = 20;
                        }),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Completed Tab
                    Expanded(
                      child: _buildPrimaryTab(
                        label: AppTranslations.getStatus('completed', lang),
                        count: completedCount,
                        lang: lang,
                        isActive: _activeTab == 'completed',
                        icon: Icons.check_circle_outline_rounded,
                        onTap: () => setState(() {
                          _activeTab = 'completed';
                          _displayedLimit = 20;
                        }),
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
                          AppTranslations.pick(lang, en: 'Today', mr: 'आज', hi: 'आज'),
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
                            Flexible(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showThemedDatePicker(
                                    context: context,
                                    initialDate: _selectedTimelineDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedTimelineDate = picked;
                                      _displayedLimit = 20;
                                    });
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, size: 15, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        AppTranslations.formatDate(_selectedTimelineDate, lang, pattern: 'dd MMM yyyy'),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
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
                    AppPdfButton.icon(
                      tooltip: AppTranslations.getDownloadReport(lang),
                      onPressed: () {
                        DiaryReportGenerator.generateAndPrintTasksReport(
                          tasks: filtered,
                          filterTitle: _activeTab == 'timeline'
                              ? '${AppTranslations.pick(lang, en: 'Date', mr: 'दिनांक', hi: 'तिथि')}: ${AppTranslations.formatDate(_selectedTimelineDate, lang, pattern: 'dd MMM yyyy')}'
                              : 'Tab: $_activeTab | Priority: $_selectedPriority',
                          lang: lang,
                        );
                      },
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
                        onChanged: (_) => setState(() => _displayedLimit = 20),
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'Search title, address, office...',
                            mr: 'शीर्षक, पत्ता, कार्यालय किंवा व्यक्ती शोधा...',
                            hi: 'शीर्षक, पता, कार्यालय या व्यक्ति खोजें...',
                          ),
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _displayedLimit = 20);
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
                      AppDropdown<String>(
                        title: AppTranslations.pick(lang, en: 'Filter by Area', mr: 'भाग निवडा', hi: 'क्षेत्र चुनें'),
                        value: _selectedArea,
                        height: 40,
                        isExpanded: false,
                        backgroundColor: _selectedArea != 'All' ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                        borderColor: _selectedArea != 'All' ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                        hintText: AppTranslations.pick(lang, en: 'Filter by Area', mr: 'भाग निवडा', hi: 'क्षेत्र चुनें'),
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: _selectedArea != 'All' ? const Color(0xFF0284C7) : const Color(0xFF475569),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text(AppTranslations.getAllAreas(lang)),
                          ),
                          ..._uniqueAreas.map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: AppTranslatedText(
                                AppTranslations.getAreaName(a, lang),
                                targetLanguage: lang,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedArea = val;
                              _displayedLimit = 20;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(width: 8),
                    AppPdfButton.icon(
                      tooltip: AppTranslations.getDownloadReport(lang),
                      onPressed: () {
                        DiaryReportGenerator.generateAndPrintTasksReport(
                          tasks: filtered,
                          filterTitle: 'Tab: $_activeTab | Priority: $_selectedPriority',
                          lang: lang,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // 3. Main Tasks List / Timeline
            Expanded(
              child: _isLoading
                  ? const AppShimmerList(count: 6)
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
                                      ? AppTranslations.pick(
                                          lang,
                                          en: 'No tasks scheduled for this day',
                                          mr: 'आजच्या तारखेला कोणतीही कामे नाहीत',
                                          hi: 'आज के लिए कोई कार्य निर्धारित नहीं है',
                                        )
                                      : AppTranslations.pick(
                                          lang,
                                          en: 'No diary tasks found',
                                          mr: 'कोणत्याही नोंदी आढळल्या नाहीत',
                                          hi: 'कोई डायरी कार्य नहीं मिला',
                                        ),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Tap "+ New Task" below to record a meeting, visit, or appointment.',
                                    mr: 'नवीन काम किंवा दौरा जोडण्यासाठी खालील "+ नवीन नोंद" वर टॅप करा.',
                                    hi: 'नई प्रविष्टि या दौरा जोड़ने के लिए नीचे "+ नई प्रविष्टि" पर टैप करें।',
                                  ),
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
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            itemCount: _visibleTasks.length + (filtered.isNotEmpty ? 1 : 0),
                            itemBuilder: (ctx, index) {
                              if (index == _visibleTasks.length) {
                                return AppLoadMoreFooter(
                                  currentCount: _visibleTasks.length,
                                  totalCount: filtered.length,
                                  pageSize: 20,
                                  onLoadMore: () => setState(() => _displayedLimit += 20),
                                  label: AppTranslations.pick(lang, en: 'tasks', mr: 'कामे', hi: 'कार्य'),
                                );
                              }
                              final task = _visibleTasks[index];
                              return _buildTaskCard(task, lang);
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
    required String lang,
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
            Flexible(
              child: Text(
                '$label (${AppTranslations.formatDigits(count, lang)})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(DiaryTaskModel task, String lang) {
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

    final formattedTime = _formatTaskTime(task, lang);

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
                        AppTranslatedText(
                          task.title,
                          targetLanguage: lang,
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
                          AppTranslatedText(
                            task.description!,
                            targetLanguage: lang,
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
                      border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      AppTranslations.getPriority(task.priority, lang),
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
                  if (formattedTime.isNotEmpty)
                    _buildPill(
                      Icons.access_time_rounded,
                      formattedTime,
                      const Color(0xFF0284C7),
                      const Color(0xFFF0F9FF),
                    ),
                  if (task.dueDate != null && _activeTab != 'timeline')
                    _buildPill(
                      Icons.calendar_today_outlined,
                      AppTranslations.formatDate(task.dueDate!, lang, pattern: 'MMM d, yyyy'),
                      const Color(0xFF475569),
                      const Color(0xFFF8FAFC),
                    ),
                  if (task.officeName != null && task.officeName!.isNotEmpty)
                    _buildPill(
                      Icons.business_outlined,
                      task.officeName!,
                      const Color(0xFF6B21A8),
                      const Color(0xFFFAF5FF),
                      translate: true,
                      lang: lang,
                    ),
                  if (task.address != null && task.address!.isNotEmpty)
                    _buildPill(
                      Icons.location_on_outlined,
                      AppTranslations.getAreaName(task.address!, lang),
                      const Color(0xFF334155),
                      const Color(0xFFF1F5F9),
                      translate: true,
                      lang: lang,
                    ),
                  if (task.meetPersonName != null && task.meetPersonName!.isNotEmpty)
                    _buildPill(
                      Icons.person_outline,
                      task.meetPersonName!,
                      const Color(0xFF0F766E),
                      const Color(0xFFF0FDFA),
                      translate: true,
                      isName: true,
                      lang: lang,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Footer: Assigned to & Details link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (task.assignedStaffName != null && task.assignedStaffName!.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: AppTranslatedText(
                              task.assignedStaffName!,
                              isName: true,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  Row(
                    children: [
                      Text(
                        AppTranslations.getDetails(lang),
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

  Widget _buildPill(
    IconData icon,
    String label,
    Color textColor,
    Color bgColor, {
    bool translate = false,
    bool isName = false,
    String? lang,
  }) {
    final textStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: translate
                ? AppTranslatedText(
                    label,
                    isName: isName,
                    targetLanguage: lang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  )
                : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
          ),
        ],
      ),
    );
  }
}