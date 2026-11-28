import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import 'package:nagarsevak_mobile/core/theme/app_colors.dart';
import 'package:nagarsevak_mobile/data/models/diary_task_model.dart';
import 'package:nagarsevak_mobile/data/repositories/diary_tasks_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/common/desktop_modal_dialog.dart';
import 'package:nagarsevak_mobile/presentation/screens/diary/diary_report_generator.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_dropdown.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_load_more_footer.dart';

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
  String _viewMode = 'grid'; // 'timeline' | 'grid' | 'table'
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String _selectedArea = 'All';
  String _selectedDateFilter = 'All';
  int _displayedLimit = 20;

  bool _loading = true;
  List<DiaryTaskModel> _tasks = [];

  List<DiaryTaskModel> get _visibleTasks =>
      _filteredTasks.take(_displayedLimit).toList();

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

  List<String> get _uniqueDates {
    final dates = <String>{};
    for (final t in _tasks) {
      if (t.dueDate != null) {
        dates.add(DateFormat('yyyy-MM-dd').format(t.dueDate!));
      }
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return ['All', ...sorted];
  }

  List<DiaryTaskModel> get _filteredTasks {
    return _tasks.where((t) {
      if (_selectedArea != 'All') {
        final matches = (t.address != null && t.address == _selectedArea) ||
            (t.officeName != null && t.officeName == _selectedArea);
        if (!matches) return false;
      }
      if (_selectedDateFilter != 'All') {
        if (t.dueDate == null) return false;
        final formatted = DateFormat('yyyy-MM-dd').format(t.dueDate!);
        if (formatted != _selectedDateFilter) {
          return false;
        }
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = AppTranslations.normalizeAsciiDigits(_searchQuery).toLowerCase().trim();
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
    final DateTime dueDate = DateTime.now();
    final TimeOfDay dueTime = TimeOfDay.now();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, dlgLang, _) => StatefulBuilder(
          builder: (ctx, setDlgState) => DesktopModalDialog(
            title: AppTranslations.pick(dlgLang, en: 'New Task', mr: 'नवीन कार्य', hi: 'नया कार्य'),
            subtitle: AppTranslations.pick(
              dlgLang,
              en: 'Create and assign follow-up tasks, reminders and deadlines',
              mr: 'पाठपुरावा कामे, स्मरणपत्रे आणि अंतिम मुदती तयार करा',
              hi: 'फ़ॉलो-अप कार्य, रिमाइंडर और समय-सीमा बनाएं और सौंपें',
            ),
            icon: Icons.assignment_rounded,
            width: 540,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: AppTranslations.pick(dlgLang, en: 'Save Task', mr: 'कार्य जतन करा', hi: 'कार्य सहेजें'),
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
                Text(
                  AppTranslations.pick(dlgLang, en: 'Task Title *', mr: 'कामाचे शीर्षक *', hi: 'कार्य शीर्षक *'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      dlgLang,
                      en: 'Enter task title...',
                      mr: 'कामाचे शीर्षक लिहा...',
                      hi: 'कार्य शीर्षक दर्ज करें...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppTranslations.pick(dlgLang, en: 'Description', mr: 'वर्णन', hi: 'विवरण'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      dlgLang,
                      en: 'Optional details or instructions...',
                      mr: 'ऐच्छिक तपशील किंवा सूचना...',
                      hi: 'वैकल्पिक विवरण या निर्देश...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppTranslations.pick(
                    dlgLang,
                    en: 'Location / Office Name',
                    mr: 'ठिकाण / कार्यालयाचे नाव',
                    hi: 'स्थान / कार्यालय का नाम',
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: addressCtrl,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      dlgLang,
                      en: 'e.g. Ward Office, Civic Center...',
                      mr: 'उदा. प्रभाग कार्यालय, नागरी केंद्र...',
                      hi: 'जैसे वार्ड कार्यालय, नागरिक केंद्र...',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      AppTranslations.pick(dlgLang, en: 'Priority:', mr: 'प्राधान्य:', hi: 'प्राथमिकता:'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    ...['Low', 'Medium', 'High'].map(
                      (p) => ChoiceChip(
                        label: Text(
                          AppTranslations.getPriority(p, dlgLang),
                          style: TextStyle(fontSize: 12, fontWeight: priority == p ? FontWeight.bold : FontWeight.normal),
                        ),
                        selected: priority == p,
                        selectedColor: AppColors.brand100,
                        onSelected: (_) => setDlgState(() => priority = p),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final items = _viewMode == 'timeline' ? _timelineTasks : _filteredTasks;
    final visibleItems = _viewMode == 'timeline' ? _timelineTasks : _visibleTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row (matching Tasks.tsx lines 361-392)
            _buildHeader(lang, items.length),

            const SizedBox(height: 16),

            // 2. Filters Grid (matching Tasks.tsx lines 395-468)
            _buildFilterBar(lang),

            const SizedBox(height: 16),

            // 3. View Mode & Date Navigator Bar (matching Tasks.tsx lines 471-525)
            _buildViewModeBar(lang),

            const SizedBox(height: 20),

            // 4. Content Area
            if (_loading)
              _buildLoadingGrid()
            else if (items.isEmpty)
              _buildEmptyState(lang)
            else if (_viewMode == 'grid')
              _build3x3TaskGrid(visibleItems, lang)
            else if (_viewMode == 'timeline')
              _buildTimelineView(items, lang)
            else
              _buildReportView(visibleItems, lang),

            // 5. Pagination Load More Footer
            if (!_loading && items.isNotEmpty && _viewMode != 'timeline')
              AppLoadMoreFooter(
                currentCount: visibleItems.length,
                totalCount: items.length,
                pageSize: 20,
                onLoadMore: () {
                  setState(() => _displayedLimit += 20);
                },
                label: lang == 'mr' ? 'कामे' : (lang == 'hi' ? 'कार्य' : 'tasks'),
                isMarathi: lang == 'mr',
              ),
          ],
        ),
      ),
    );
  }

  // --- Header Row ---
  Widget _buildHeader(String lang, int foundCount) {
    final title = AppTranslations.t('tasks.title', lang: lang);
    final subtitle = AppTranslations.t('tasks.subtitle', lang: lang);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_box_outlined, size: 26, color: Color(0xFF0369A1)),
                const SizedBox(width: 10),
                Text(
                  title,
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
                    AppTranslations.formatFound(foundCount, lang),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Scan Doc + New Task
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                DiaryReportGenerator.generateAndPrintTasksReport(
                  context: context,
                  tasks: _filteredTasks,
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.getDownloadReport(lang),
                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),

            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.document_scanner_outlined, size: 16, color: Color(0xFF475569)),
              label: Text(
                AppTranslations.t('tasks.scan_doc', lang: lang),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _openNewTaskDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.t('tasks.new_task', lang: lang),
                    style: const TextStyle(
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

  // --- Filter Bar (12-column layout matching Tasks.tsx lines 395-468) ---
  Widget _buildFilterBar(String lang) {
    final searchHint = lang == 'mr'
        ? 'कार्ये, वर्णन, कर्मचाऱ्यांनुसार शोधा...'
        : (lang == 'hi' ? 'कार्य, विवरण, कर्मचारियों द्वारा खोजें...' : 'Search tasks by title, description, staff...');
    final allAreasLabel = lang == 'mr' ? 'सर्व भाग' : (lang == 'hi' ? 'सभी क्षेत्र' : 'All Areas');
    final allDatesLabel = lang == 'mr' ? 'सर्व तारखा' : (lang == 'hi' ? 'सभी तिथियां' : 'All Dates');

    return Row(
      children: [
        // Main Search (6 cols)
        Expanded(
          flex: 6,
          child: TextField(
            onChanged: (v) => setState(() {
              _searchQuery = v;
              _displayedLimit = 20;
            }),
            decoration: InputDecoration(
              hintText: searchHint,
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
          child: AppDropdown<String>(
            value: _selectedArea,
            height: 42,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueAreas.map((area) {
              return DropdownMenuItem(
                value: area,
                child: Text(
                  area == 'All' ? allAreasLabel : AppTranslations.getAreaName(area, lang),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedArea = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),

        // Date Dropdown (3 cols matching Tasks.tsx:441)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedDateFilter,
            height: 42,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueDates.map((date) {
              String label;
              if (date == 'All') {
                label = allDatesLabel;
              } else {
                final parsed = DateTime.tryParse(date);
                label = parsed != null
                    ? AppTranslations.formatDate(parsed, lang, pattern: 'MMM d, yyyy')
                    : AppTranslations.formatDigits(date, lang);
              }
              return DropdownMenuItem(
                value: date,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDateFilter = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  // --- View Mode & Date Navigator Bar (matching Tasks.tsx lines 471-525) ---
  Widget _buildViewModeBar(String lang) {
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
                  label: lang == 'mr' ? 'टाइमलाइन' : (lang == 'hi' ? 'समयरेखा' : 'Timeline'),
                  isActive: _viewMode == 'timeline',
                  onTap: () => setState(() => _viewMode = 'timeline'),
                ),
                _buildViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  label: AppTranslations.t('common.grid', lang: lang),
                  isActive: _viewMode == 'grid',
                  onTap: () => setState(() => _viewMode = 'grid'),
                ),
                _buildViewToggleButton(
                  icon: Icons.table_rows_rounded,
                  label: lang == 'mr' ? 'तक्ता' : (lang == 'hi' ? 'तालिका' : 'Table'),
                  isActive: _viewMode == 'table',
                  onTap: () => setState(() => _viewMode = 'table'),
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
                      lang == 'mr' ? 'आज' : (lang == 'hi' ? 'आज' : 'TODAY'),
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
                              AppTranslations.formatDate(_selectedDate, lang, pattern: 'MMM d, yyyy'),
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
  Widget _build3x3TaskGrid(List<DiaryTaskModel> items, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Standard 3-by-3 format across desktop screens
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final task = items[index];
            return _buildTaskCard(task, lang);
          },
        );
      },
    );
  }

  String _formatTaskDate(DiaryTaskModel task, String lang) {
    if (task.dueDate == null) return '-';
    return AppTranslations.formatDate(task.dueDate!, lang, pattern: 'MMM d, yyyy');
  }

  String _formatTaskTime(DiaryTaskModel task, String lang) {
    final raw = task.dueTime;
    if (raw == null || raw.trim().isEmpty) return '';
    final clean = AppTranslations.normalizeAsciiDigits(raw.trim());
    final parts = clean.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return AppTranslations.formatTime(DateTime(2026, 1, 1, h, m), lang);
      }
    }
    return AppTranslations.formatDigits(task.formattedTime, lang);
  }

  Widget _buildLocalizedLocationText(
    String raw,
    String lang, {
    TextStyle? style,
    TextOverflow? overflow,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return Text(raw, style: style, overflow: overflow);
    }
    final mapped = AppTranslations.getAreaName(trimmed, lang);
    final changed = mapped.trim().toLowerCase() != trimmed.toLowerCase() &&
        mapped != AppTranslations.formatDigits(trimmed, lang);
    if (changed || (lang == 'en' && !DynamicTranslationService.containsDevanagari(trimmed))) {
      return Text(mapped, style: style, overflow: overflow);
    }
    return AppTranslatedText(
      trimmed,
      targetLanguage: lang,
      style: style,
      overflow: overflow,
    );
  }

  Widget _buildTaskCard(DiaryTaskModel task, String lang) {
    final isDone = task.isCompleted;
    final dateLabel = _formatTaskDate(task, lang);
    final timeLabel = _formatTaskTime(task, lang);

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
                child: AppTranslatedText(
                  task.title,
                  targetLanguage: lang,
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
                    isDone ? AppTranslations.getStatus('completed', lang) : AppTranslations.getStatus('pending', lang),
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
              child: AppTranslatedText(
                task.description!,
                targetLanguage: lang,
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
          _buildPriorityBadge(task.priority, lang),

          const SizedBox(height: 8),

          // Date / Time info
          if (task.dueDate != null || (task.dueTime != null && task.dueTime!.isNotEmpty)) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 5),
                Text(
                  '$dateLabel${timeLabel.isNotEmpty ? ' • $timeLabel' : ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Location / Office info
          if ((task.address != null && task.address!.trim().isNotEmpty) ||
              (task.officeName != null && task.officeName!.trim().isNotEmpty)) ...[
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildLocalizedLocationText(
                    task.address ?? task.officeName ?? '',
                    lang,
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

  Widget _buildPriorityBadge(String priority, String lang) {
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
        AppTranslations.getPriority(priority, lang),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // --- Timeline View (matching Tasks.tsx lines 746-820) ---
  Widget _buildTimelineView(List<DiaryTaskModel> items, String lang) {
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
          final timeStr = _formatTaskTime(task, lang);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time label
              SizedBox(
                width: 90,
                child: Text(
                  timeStr.isNotEmpty ? timeStr : AppTranslations.pick(lang, en: 'Anytime', mr: 'कधीही', hi: 'कभी भी'),
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
                      AppTranslatedText(
                        task.title,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        AppTranslatedText(
                          task.description!,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
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
  Widget _buildReportView(List<DiaryTaskModel> items, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(AppTranslations.getReportColumn('title', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('priority', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('status', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('due_date', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('location_area', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: items.map((task) {
            final locRaw = task.address ?? task.officeName ?? '-';
            return DataRow(
              cells: [
                DataCell(
                  AppTranslatedText(
                    task.title,
                    targetLanguage: lang,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(_buildPriorityBadge(task.priority, lang)),
                DataCell(Text(AppTranslations.getStatus(task.status, lang))),
                DataCell(Text(_formatTaskDate(task, lang))),
                DataCell(_buildLocalizedLocationText(locRaw, lang)),
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

  Widget _buildEmptyState(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            AppTranslations.t('tasks.no_tasks', lang: lang),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          Text(
            lang == 'mr' ? 'कृपया फिल्टर किंवा शोध निकष बदला' : (lang == 'hi' ? 'कृपया फ़िल्टर या खोज मानदंड बदलें' : 'Try adjusting your search criteria'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
