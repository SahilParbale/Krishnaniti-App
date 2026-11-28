import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../../data/models/karyakarta_work_model.dart';
import '../../../data/repositories/karyakarta_work_repository.dart';
import 'karyakarta_work_report_generator.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';

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
  int _displayedLimit = 20;

  List<KaryakartaStaffWorkload> get _visibleWorkloads =>
      _workloads.take(_displayedLimit).toList();

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
      final unassignedTasks = await repo.getUnassignedTasks();
      final unassignedComplaints = await repo.getUnassignedComplaints();
      final allStaff = await repo.getAllStaffList();
      final areas = await repo.getAvailableAreas();

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
      _displayedLimit = 20;
    });
    _loadData();
  }

  Future<void> _handleUpdateTaskStatus(String taskId, String currentStatus) async {
    final newStatus = currentStatus.toLowerCase() == 'pending' ? 'In Progress' : 'Completed';
    final repo = ref.read(karyakartaWorkRepoProvider);
    final lang = ref.read(appLanguageProvider);
    await repo.updateTaskStatus(taskId, newStatus);
    if (mounted) {
      final statusLabel = AppTranslations.getStatus(newStatus, lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Task status updated: $statusLabel',
              mr: 'कामाची स्थिती अद्यतनित केली: $statusLabel',
              hi: 'कार्य स्थिति अपडेट की गई: $statusLabel',
            ),
          ),
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    }
  }

  Future<void> _handleReassignTask(String taskId, String newStaffId) async {
    final repo = ref.read(karyakartaWorkRepoProvider);
    final lang = ref.read(appLanguageProvider);
    await repo.reassignTask(taskId, newStaffId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Task reassigned successfully!',
              mr: 'काम यशस्वीरित्या पुन्हा नेमले!',
              hi: 'कार्य सफलतापूर्वक पुनः सौंपा गया!',
            ),
          ),
          backgroundColor: const Color(0xFF0284C7),
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
    final lang = ref.read(appLanguageProvider);
    await repo.updateComplaintStatus(complaintId, newStatus);
    if (mounted) {
      final statusLabel = AppTranslations.getStatus(newStatus, lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Complaint status updated: $statusLabel',
              mr: 'तक्रारीची स्थिती अद्यतनित केली: $statusLabel',
              hi: 'शिकायत स्थिति अपडेट की गई: $statusLabel',
            ),
          ),
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    }
  }

  Future<void> _handleReassignComplaint(String complaintId, String newStaffId) async {
    final repo = ref.read(karyakartaWorkRepoProvider);
    final lang = ref.read(appLanguageProvider);
    await repo.reassignComplaint(complaintId, newStaffId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Complaint reassigned successfully!',
              mr: 'तक्रार यशस्वीरित्या पुन्हा नेमली!',
              hi: 'शिकायत सफलतापूर्वक पुनः सौंपी गई!',
            ),
          ),
          backgroundColor: const Color(0xFF0284C7),
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
    final lang = ref.read(appLanguageProvider);
    final repo = ref.read(karyakartaWorkRepoProvider);
    final allTasks = await repo.getTasks();
    final allComplaints = await repo.getComplaints();
    final tabStaff = _workloads.map((w) => w.staff).toList();

    String tabLabel = 'Office Team';
    if (_activeTab == 'Cooperative') tabLabel = 'Government Work';
    if (_activeTab == 'Party') tabLabel = 'Party Cadre';

    await KaryakartaWorkReportGenerator.generateAndPrintReport(
      context: mounted ? context : null,
      staffList: tabStaff,
      tasks: allTasks,
      complaints: allComplaints,
      activeTabLabel: tabLabel,
      categoryFilter: _activeTab,
      lang: lang,
    );
  }

  void _showReportPreviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, dialogRef, _) {
          final lang = dialogRef.watch(appLanguageProvider);
          final tabTitle = _getTabTitle(_activeTab, lang);
          final generatedAt = AppTranslations.formatDateTime(DateTime.now(), lang);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.description_outlined, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Workload Report — $tabTitle',
                      mr: 'कार्यभार अहवाल — $tabTitle',
                      hi: 'कार्यभार रिपोर्ट — $tabTitle',
                    ),
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
                    AppTranslations.pick(
                      lang,
                      en: 'Generated: $generatedAt',
                      mr: 'तयार केले: $generatedAt',
                      hi: 'निर्मित: $generatedAt',
                    ),
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
                        _buildPreviewRow(
                          AppTranslations.pick(lang, en: 'Total Members:', mr: 'एकूण सदस्य:', hi: 'कुल सदस्य:'),
                          AppTranslations.formatDigits(_workloads.length, lang),
                        ),
                        _buildPreviewRow(
                          AppTranslations.pick(lang, en: 'Total Workload:', mr: 'एकूण कार्यभार:', hi: 'कुल कार्यभार:'),
                          AppTranslations.pick(
                            lang,
                            en: '${_summary.totalLoad} (${_summary.totalTasks} Tasks + ${_summary.totalComplaints} Complaints)',
                            mr: '${AppTranslations.formatDigits(_summary.totalLoad, lang)} (${AppTranslations.formatDigits(_summary.totalTasks, lang)} कामे + ${AppTranslations.formatDigits(_summary.totalComplaints, lang)} तक्रारी)',
                            hi: '${AppTranslations.formatDigits(_summary.totalLoad, lang)} (${AppTranslations.formatDigits(_summary.totalTasks, lang)} कार्य + ${AppTranslations.formatDigits(_summary.totalComplaints, lang)} शिकायतें)',
                          ),
                        ),
                        _buildPreviewRow(
                          AppTranslations.pick(lang, en: 'Pending Load:', mr: 'प्रलंबित कार्यभार:', hi: 'लंबित कार्यभार:'),
                          AppTranslations.formatDigits(_summary.pendingLoad, lang),
                        ),
                        _buildPreviewRow(
                          AppTranslations.pick(lang, en: 'In Progress:', mr: 'सुरू असलेले:', hi: 'प्रगति में:'),
                          AppTranslations.formatDigits(_summary.inProgressLoad, lang),
                        ),
                        _buildPreviewRow(
                          AppTranslations.pick(lang, en: 'Completed:', mr: 'पूर्ण झालेले:', hi: 'पूर्ण:'),
                          AppTranslations.formatDigits(_summary.completedLoad, lang),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'This report will be generated on official Ward 12 letterhead in A4 landscape format.',
                      mr: 'हा अहवाल प्रभाग १२ च्या अधिकृत लेटरहेडवर A4 लँडस्केप स्वरूपात तयार केला जाईल.',
                      hi: 'यह रिपोर्ट वार्ड १२ के आधिकारिक लेटरहेड पर A4 लैंडस्केप प्रारूप में तैयार की जाएगी।',
                    ),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
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
                label: Text(AppTranslations.getDownloadReport(lang)),
              ),
            ],
          );
        },
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getTabTitle(String tab, String lang) {
    switch (tab) {
      case 'Office':
        return AppTranslations.pick(lang, en: 'Office Team', mr: 'कार्यालय टीम', hi: 'कार्यालय टीम');
      case 'Cooperative':
        return AppTranslations.pick(lang, en: 'Government Work', mr: 'शासकीय कामे', hi: 'सरकारी कार्य');
      case 'Party':
        return AppTranslations.pick(lang, en: 'Party Cadre', mr: 'पक्ष संघटना', hi: 'पार्टी कार्यकर्ता');
      default:
        return AppTranslations.translateDirect(tab, lang: lang);
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
    final lang = ref.watch(appLanguageProvider);
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
              AppTranslations.pick(
                lang,
                en: 'Karyakarta Work Management',
                mr: 'कार्यकर्ता काम व्यवस्थापन',
                hi: 'कार्यकर्ता कार्य प्रबंधन',
              ),
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
                en: 'Field tasks & team workload',
                mr: 'क्षेत्रीय कामे आणि टीम कार्यभार',
                hi: 'फील्ड कार्य और टीम कार्यभार',
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: AppLanguageSegmentedSelector(isCompact: true),
          ),
        ],
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
              _buildCategoryTabBar(lang),
              const SizedBox(height: 12),

              // 2. Search & Area Filter Bar
              _buildFilterBar(lang),
              const SizedBox(height: 14),

              // 3. 4 KPI Dashboard Counters
              _buildKpiDashboard(lang),
              const SizedBox(height: 16),

              // 4. Drilldown Details Panel (if a member is selected)
              if (_selectedMemberWorkload != null) ...[
                _buildMemberDrilldownPanel(_selectedMemberWorkload!, lang),
                const SizedBox(height: 16),
              ],

              // 5. Workload Matrix Table / Cards Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 20, color: tabColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Team Workload Monitor',
                              mr: 'टीम कार्यभार निरीक्षण',
                              hi: 'टीम कार्यभार निगरानी',
                            ),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppPdfButton.outlined(
                    label: AppTranslations.getDownloadReport(lang),
                    onPressed: _generatePdfReport,
                  ),
                ],
              ),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Tasks & complaints assigned to each member — click card to expand',
                  mr: 'प्रत्येक सदस्याला नेमलेली कामे व तक्रारी — तपशीलासाठी कार्डवर क्लिक करा',
                  hi: 'प्रत्येक सदस्य को सौंपे गए कार्य और शिकायतें — विवरण देखने के लिए कार्ड पर क्लिक करें',
                ),
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),

              // 6. Staff Workload Cards List
              if (_isLoading)
                const AppShimmerList(count: 4)
              else if (_workloads.isEmpty)
                _buildEmptyState(lang)
              else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _visibleWorkloads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final workload = _visibleWorkloads[index];
                    final isSelected = _selectedMemberWorkload?.staff.id == workload.staff.id;
                    return _buildStaffWorkloadCard(workload, isSelected, lang);
                  },
                ),
                AppLoadMoreFooter(
                  currentCount: _visibleWorkloads.length,
                  totalCount: _workloads.length,
                  pageSize: 20,
                  onLoadMore: () => setState(() => _displayedLimit += 20),
                  label: AppTranslations.pick(
                    lang,
                    en: 'members',
                    mr: 'कार्यकर्ते',
                    hi: 'कार्यकर्ता',
                  ),
                  isMarathi: lang == 'mr',
                ),
              ],

              const SizedBox(height: 20),

              // 7. Unassigned Work Pool Section
              if (_unassignedTasks.isNotEmpty || _unassignedComplaints.isNotEmpty) ...[
                _buildUnassignedWorkPool(lang),
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
  Widget _buildCategoryTabBar(String lang) {
    final tabs = [
      {
        'id': 'Office',
        'title': AppTranslations.pick(lang, en: 'Office Team', mr: 'कार्यालय टीम', hi: 'कार्यालय टीम'),
        'icon': Icons.apartment_outlined,
        'color': const Color(0xFF6D28D9),
      },
      {
        'id': 'Cooperative',
        'title': AppTranslations.pick(lang, en: 'Govt Work', mr: 'शासकीय कामे', hi: 'सरकारी कार्य'),
        'icon': Icons.work_outline_rounded,
        'color': const Color(0xFF0284C7),
      },
      {
        'id': 'Party',
        'title': AppTranslations.pick(lang, en: 'Party Cadre', mr: 'पक्ष संघटना', hi: 'पार्टी कार्यकर्ता'),
        'icon': Icons.flag_outlined,
        'color': const Color(0xFFF97316),
      },
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
                        AppTranslations.formatDigits(staffCount, lang),
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
  Widget _buildFilterBar(String lang) {
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
                _searchQuery = AppTranslations.normalizeAsciiDigits(val);
                setState(() => _displayedLimit = 20);
                _loadData();
              },
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search name or mobile...',
                  mr: 'नाव किंवा मोबाइल शोधा...',
                  hi: 'नाम या मोबाइल खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          setState(() => _displayedLimit = 20);
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
          child: AppDropdown<String>(
            title: AppTranslations.pick(
              lang,
              en: 'Filter by Area',
              mr: 'परिसरानुसार निवडा',
              hi: 'क्षेत्र के अनुसार फ़िल्टर करें',
            ),
            value: _selectedArea,
            height: 42,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: 'All', child: Text(AppTranslations.getAllAreas(lang))),
              ..._areas.map(
                (a) => DropdownMenuItem(value: a, child: Text(AppTranslations.getAreaName(a, lang))),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedArea = val;
                  _displayedLimit = 20;
                });
                _loadData();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        AppPdfButton.outlined(
          label: AppTranslations.pick(lang, en: 'Reports', mr: 'अहवाल', hi: 'रिपोर्ट'),
          onPressed: _showReportPreviewDialog,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: 4 KPI Cards
  // ─────────────────────────────────────────────────────────────
  Widget _buildKpiDashboard(String lang) {
    return Row(
      children: [
        _buildMetricTile(
          title: AppTranslations.pick(lang, en: 'Total Workload', mr: 'एकूण कार्यभार', hi: 'कुल कार्यभार'),
          value: AppTranslations.formatDigits(_summary.totalLoad, lang),
          subtitle: AppTranslations.pick(
            lang,
            en: '${_summary.totalTasks} Tasks · ${_summary.totalComplaints} Complaints',
            mr: '${AppTranslations.formatDigits(_summary.totalTasks, lang)} कामे · ${AppTranslations.formatDigits(_summary.totalComplaints, lang)} तक्रारी',
            hi: '${AppTranslations.formatDigits(_summary.totalTasks, lang)} कार्य · ${AppTranslations.formatDigits(_summary.totalComplaints, lang)} शिकायतें',
          ),
          bg: const Color(0xFFF1F5F9),
          textColor: const Color(0xFF1E293B),
        ),
        const SizedBox(width: 8),
        _buildMetricTile(
          title: AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित'),
          value: AppTranslations.formatDigits(_summary.pendingLoad, lang),
          subtitle: AppTranslations.pick(lang, en: 'Needs Attention', mr: 'लक्ष आवश्यक', hi: 'ध्यान आवश्यक'),
          bg: const Color(0xFFFFFBEB),
          textColor: const Color(0xFFB45309),
        ),
        const SizedBox(width: 8),
        _buildMetricTile(
          title: AppTranslations.pick(lang, en: 'In Progress', mr: 'प्रगतीपथावर', hi: 'प्रगति में'),
          value: AppTranslations.formatDigits(_summary.inProgressLoad, lang),
          subtitle: AppTranslations.pick(lang, en: 'Active Work', mr: 'सक्रिय काम', hi: 'सक्रिय कार्य'),
          bg: const Color(0xFFEFF6FF),
          textColor: const Color(0xFF1D4ED8),
        ),
        const SizedBox(width: 8),
        _buildMetricTile(
          title: AppTranslations.pick(lang, en: 'Completed', mr: 'पूर्ण', hi: 'पूर्ण'),
          value: AppTranslations.formatDigits(_summary.completedLoad, lang),
          subtitle: AppTranslations.pick(lang, en: 'Resolved & Closed', mr: 'निराकरण व बंद', hi: 'समाधान व बंद'),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
              ),
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
  Widget _buildStaffWorkloadCard(KaryakartaStaffWorkload workload, bool isSelected, String lang) {
    final staff = workload.staff;
    final tabColor = _getTabColor(_activeTab);
    final rawStaffName = (lang == 'en' && staff.name.trim().isNotEmpty)
        ? staff.name
        : staff.displayName;

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
                      AppTranslatedText(
                        rawStaffName,
                        isName: true,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      AppTranslatedText(
                        AppTranslations.getRoleName(staff.role, lang),
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                      ),
                      if (staff.area != null && staff.area!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 2),
                            Flexible(
                              child: AppTranslatedText(
                                AppTranslations.getAreaName(staff.area!, lang),
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Mobile & Direct Call Action
                InkWell(
                  onTap: () => launchUrl(Uri.parse('tel:${AppTranslations.normalizeAsciiDigits(staff.mobile)}')),
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
                          AppTranslations.formatDigits(staff.mobile, lang),
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
                      Text(
                        AppTranslations.pick(lang, en: 'Tasks: ', mr: 'कामे: ', hi: 'कार्य: '),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      Text(
                        AppTranslations.formatDigits(workload.tasksPending, lang),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: workload.tasksPending > 0 ? const Color(0xFFB45309) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        ' / ${AppTranslations.formatDigits(workload.tasksTotal, lang)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
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
                      Text(
                        AppTranslations.pick(lang, en: 'Complaints: ', mr: 'तक्रारी: ', hi: 'शिकायतें: '),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      Text(
                        AppTranslations.formatDigits(workload.complaintsPending, lang),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: workload.complaintsPending > 0 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        ' / ${AppTranslations.formatDigits(workload.complaintsTotal, lang)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
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
                          Text(
                            AppTranslations.pick(lang, en: 'Progress: ', mr: 'प्रगती: ', hi: 'प्रगति: '),
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                          Text(
                            '${AppTranslations.formatDigits(workload.progressPct, lang)}%',
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
                    isSelected
                        ? AppTranslations.pick(lang, en: 'Hide', mr: 'लपवा', hi: 'छिपाएं')
                        : AppTranslations.pick(lang, en: 'View Details', mr: 'तपशील पहा', hi: 'विवरण देखें'),
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
                  label: Text(
                    AppTranslations.pick(lang, en: 'Assign', mr: 'नेमा', hi: 'सौंपें'),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
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
  Widget _buildMemberDrilldownPanel(KaryakartaStaffWorkload workload, String lang) {
    final staff = workload.staff;
    final rawStaffName = (lang == 'en' && staff.name.trim().isNotEmpty)
        ? staff.name
        : staff.displayName;

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
                      AppTranslatedText(
                        rawStaffName,
                        isName: true,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppTranslatedText(
                            AppTranslations.getRoleName(staff.role, lang),
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFE0F2FE)),
                          ),
                          if (staff.area != null && staff.area!.isNotEmpty) ...[
                            const Text(' · ', style: TextStyle(fontSize: 12, color: Color(0xFFE0F2FE))),
                            AppTranslatedText(
                              AppTranslations.getAreaName(staff.area!, lang),
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 12, color: Color(0xFFE0F2FE)),
                            ),
                          ],
                        ],
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
                  label: Text(
                    AppTranslations.pick(lang, en: 'Assign Task', mr: 'काम नेमा', hi: 'कार्य सौंपें'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
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
                _buildMiniStat(
                  AppTranslations.pick(lang, en: 'Total', mr: 'एकूण', hi: 'कुल'),
                  AppTranslations.formatDigits(workload.totalAssigned, lang),
                  const Color(0xFF334155),
                ),
                _buildMiniStat(
                  AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित'),
                  AppTranslations.formatDigits(workload.totalPending, lang),
                  const Color(0xFFD97706),
                ),
                _buildMiniStat(
                  AppTranslations.pick(lang, en: 'Done', mr: 'पूर्ण', hi: 'पूर्ण'),
                  AppTranslations.formatDigits(workload.totalCompleted, lang),
                  const Color(0xFF047857),
                ),
                _buildMiniStat(
                  AppTranslations.pick(lang, en: 'Progress', mr: 'प्रगती', hi: 'प्रगति'),
                  '${AppTranslations.formatDigits(workload.progressPct, lang)}%',
                  const Color(0xFF0284C7),
                ),
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
                _buildSubTabButton(
                  'tasks',
                  AppTranslations.pick(lang, en: 'Tasks', mr: 'कामे', hi: 'कार्य'),
                  workload.tasksTotal,
                  lang,
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  'complaints',
                  AppTranslations.pick(lang, en: 'Complaints', mr: 'तक्रारी', hi: 'शिकायतें'),
                  workload.complaintsTotal,
                  lang,
                ),
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
                  ..._buildTasksList(workload.tasks, lang)
                else
                  ..._buildComplaintsList(workload.complaints, lang),
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

  Widget _buildSubTabButton(String tabId, String title, int count, String lang) {
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
                AppTranslations.formatDigits(count, lang),
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

  List<Widget> _buildTasksList(List<KaryakartaWorkTask> tasks, String lang) {
    if (tasks.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 36, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'No tasks assigned yet.',
                    mr: 'अद्याप कोणतेही काम नेमलेले नाही.',
                    hi: 'अभी तक कोई कार्य नहीं सौंपा गया है।',
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
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
                  child: AppTranslatedText(
                    task.title,
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    AppTranslations.getStatus(task.status, lang),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 3),
              AppTranslatedText(
                task.description!,
                targetLanguage: lang,
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
                    AppTranslations.getPriority(task.priority, lang),
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: priorityColor),
                  ),
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(width: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 10, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Text(
                        AppTranslations.formatDate(task.dueDate!, lang),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
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
                          child: AppTranslatedText(
                            task.address!,
                            targetLanguage: lang,
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
                AppDropdown<String>(
                  title: AppTranslations.pick(lang, en: 'Assign Task To', mr: 'काम कोणाला नेमायचे', hi: 'कार्य किसे सौंपें'),
                  value: task.assignedStaffId ?? '',
                  height: 30,
                  isExpanded: false,
                  hintText: AppTranslations.pick(lang, en: 'Assign...', mr: 'नेमा...', hi: 'सौंपें...'),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(AppTranslations.pick(lang, en: 'Unassigned', mr: 'न नेमलेले', hi: 'असाइन नहीं')),
                    ),
                    ..._allStaff.map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: AppTranslatedText(
                          lang == 'en' && s.name.trim().isNotEmpty ? s.name : s.displayName,
                          isName: true,
                          targetLanguage: lang,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null && val != task.assignedStaffId) {
                      _handleReassignTask(task.id, val);
                    }
                  },
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
                      task.isPending
                          ? AppTranslations.pick(lang, en: 'Start', mr: 'सुरू करा', hi: 'शुरू करें')
                          : AppTranslations.pick(lang, en: 'Complete', mr: 'पूर्ण करा', hi: 'पूर्ण करें'),
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

  List<Widget> _buildComplaintsList(List<KaryakartaWorkComplaint> complaints, String lang) {
    if (complaints.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.assignment_turned_in_outlined, size: 36, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'No complaints assigned.',
                    mr: 'कोणत्याही तक्रारी नेमलेल्या नाहीत.',
                    hi: 'कोई शिकायत असाइन नहीं की गई है।',
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
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
                  child: AppTranslatedText(
                    complaint.title,
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    AppTranslations.getStatus(complaint.status, lang),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            if (complaint.voterName != null && complaint.voterName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    AppTranslations.pick(lang, en: 'From: ', mr: 'कडून: ', hi: 'प्रेषक: '),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w500),
                  ),
                  Flexible(
                    child: AppTranslatedText(
                      complaint.voterName!,
                      isName: true,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (complaint.voterMobile != null && complaint.voterMobile!.isNotEmpty)
                    Text(
                      ' (${AppTranslations.formatDigits(complaint.voterMobile!, lang)})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ],
            if (complaint.description != null && complaint.description!.isNotEmpty) ...[
              const SizedBox(height: 3),
              AppTranslatedText(
                complaint.description!,
                targetLanguage: lang,
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
                      AppTranslations.getComplaintType(complaint.type!, lang),
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                    ),
                  ),
                if (complaint.area != null && complaint.area!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 2),
                        Flexible(
                          child: AppTranslatedText(
                            AppTranslations.getAreaName(complaint.area!, lang),
                            targetLanguage: lang,
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
                AppDropdown<String>(
                  title: AppTranslations.pick(lang, en: 'Assign Complaint To', mr: 'तक्रार कोणाला नेमायची', hi: 'शिकायत किसे सौंपें'),
                  value: complaint.assignedTo ?? '',
                  height: 30,
                  isExpanded: false,
                  hintText: AppTranslations.pick(lang, en: 'Assign...', mr: 'नेमा...', hi: 'सौंपें...'),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(AppTranslations.pick(lang, en: 'Unassigned', mr: 'न नेमलेले', hi: 'असाइन नहीं')),
                    ),
                    ..._allStaff.map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: AppTranslatedText(
                          lang == 'en' && s.name.trim().isNotEmpty ? s.name : s.displayName,
                          isName: true,
                          targetLanguage: lang,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null && val != complaint.assignedTo) {
                      _handleReassignComplaint(complaint.id, val);
                    }
                  },
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
                      complaint.isPending
                          ? AppTranslations.pick(lang, en: 'Start', mr: 'सुरू करा', hi: 'शुरू करें')
                          : AppTranslations.pick(lang, en: 'Resolve', mr: 'निराकरण करा', hi: 'समाधान करें'),
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
  Widget _buildUnassignedWorkPool(String lang) {
    final tasksLen = AppTranslations.formatDigits(_unassignedTasks.length, lang);
    final complaintsLen = AppTranslations.formatDigits(_unassignedComplaints.length, lang);

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
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Unassigned Work Pool',
                          mr: 'न नेमलेल्या कामांचा विभाग',
                          hi: 'असाइन न किए गए कार्य',
                        ),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: '$tasksLen tasks and $complaintsLen complaints pending assignment',
                          mr: '$tasksLen कामे आणि $complaintsLen तक्रारी नेमण्यासाठी प्रलंबित',
                          hi: '$tasksLen कार्य और $complaintsLen शिकायतें असाइन करने के लिए लंबित',
                        ),
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
                AppTranslations.pick(
                  lang,
                  en: 'Unassigned Tasks ($tasksLen):',
                  mr: 'न नेमलेली कामे ($tasksLen):',
                  hi: 'असाइन न किए गए कार्य ($tasksLen):',
                ),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
            ),
            ..._unassignedTasks.map((t) => _buildUnassignedTaskRow(t, lang)),
          ],

          // Unassigned Complaints
          if (_unassignedComplaints.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Unassigned Complaints ($complaintsLen):',
                  mr: 'न नेमलेल्या तक्रारी ($complaintsLen):',
                  hi: 'असाइन न की गई शिकायतें ($complaintsLen):',
                ),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
            ),
            ..._unassignedComplaints.map((c) => _buildUnassignedComplaintRow(c, lang)),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildUnassignedTaskRow(KaryakartaWorkTask task, String lang) {
    final assignLabel = AppTranslations.pick(lang, en: '— Assign —', mr: '— नेमा —', hi: '— सौंपें —');
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
                AppTranslatedText(
                  task.title,
                  targetLanguage: lang,
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
                        AppTranslations.getPriority(task.priority, lang),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: task.priority.toLowerCase() == 'high' ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        AppTranslations.formatDate(task.dueDate!, lang),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppDropdown<String>(
            title: AppTranslations.pick(lang, en: 'Assign Task', mr: 'काम नेमा', hi: 'कार्य सौंपें'),
            value: '',
            height: 32,
            isExpanded: false,
            backgroundColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFF86EFAC),
            hintText: assignLabel,
            items: [
              DropdownMenuItem(value: '', child: Text(assignLabel, style: const TextStyle(color: Color(0xFF94A3B8)))),
              ..._allStaff.map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: AppTranslatedText(
                          lang == 'en' && s.name.trim().isNotEmpty ? s.name : s.displayName,
                          isName: true,
                          targetLanguage: lang,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(' (${_getTabTitle(s.category, lang)})'),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null && val.isNotEmpty) {
                _handleReassignTask(task.id, val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedComplaintRow(KaryakartaWorkComplaint complaint, String lang) {
    final assignLabel = AppTranslations.pick(lang, en: '— Assign —', mr: '— नेमा —', hi: '— सौंपें —');
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
                AppTranslatedText(
                  complaint.title,
                  targetLanguage: lang,
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
                      AppTranslations.getComplaintType(complaint.type!, lang),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppDropdown<String>(
            title: AppTranslations.pick(lang, en: 'Assign Complaint', mr: 'तक्रार नेमा', hi: 'शिकायत सौंपें'),
            value: '',
            height: 32,
            isExpanded: false,
            backgroundColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFF86EFAC),
            hintText: assignLabel,
            items: [
              DropdownMenuItem(value: '', child: Text(assignLabel, style: const TextStyle(color: Color(0xFF94A3B8)))),
              ..._allStaff.map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: AppTranslatedText(
                          lang == 'en' && s.name.trim().isNotEmpty ? s.name : s.displayName,
                          isName: true,
                          targetLanguage: lang,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(' (${_getTabTitle(s.category, lang)})'),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null && val.isNotEmpty) {
                _handleReassignComplaint(complaint.id, val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    final tabTitle = _getTabTitle(_activeTab, lang);
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
            AppTranslations.pick(
              lang,
              en: 'No members found in $tabTitle.',
              mr: '$tabTitle मध्ये कोणतेही सदस्य सापडले नाहीत.',
              hi: '$tabTitle में कोई सदस्य नहीं मिला।',
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Change search filters or add members from staff management.',
              mr: 'शोध फिल्टर बदला किंवा कर्मचारी व्यवस्थापनातून सदस्य जोडा.',
              hi: 'खोज फ़िल्टर बदलें या स्टाफ़ प्रबंधन से सदस्य जोड़ें।',
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
    final lang = ref.read(appLanguageProvider);
    final rawName = (lang == 'en' && widget.staff.name.trim().isNotEmpty)
        ? widget.staff.name
        : widget.staff.displayName;

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

      final localizedStaffName = await DynamicTranslationService.translateOrRaw(
        rawName,
        lang,
        isName: true,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onTaskAssigned();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Task assigned to $localizedStaffName successfully!',
                mr: '$localizedStaffName यांना काम यशस्वीरित्या नेमले!',
                hi: '$localizedStaffName को कार्य सफलतापूर्वक सौंपा गया!',
              ),
            ),
            backgroundColor: const Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Error assigning task. Please try again.',
                mr: 'काम नेमताना त्रुटी आली. कृपया पुन्हा प्रयत्न करा.',
                hi: 'कार्य सौंपने में त्रुटि। कृपया पुनः प्रयास करें।',
              ),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final rawStaffName = (lang == 'en' && widget.staff.name.trim().isNotEmpty)
        ? widget.staff.name
        : widget.staff.displayName;

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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
          children: [
            AppTranslatedText(
              rawStaffName,
              isName: true,
              targetLanguage: lang,
              builder: (_, translatedName) => AppModalHeader(
                icon: Icons.assignment_add,
                title: AppTranslations.pick(lang, en: 'Assign New Task', mr: 'नवीन काम नेमा', hi: 'नया कार्य सौंपें'),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'To: $translatedName',
                  mr: 'प्रति: $translatedName',
                  hi: 'को: $translatedName',
                ),
                onClose: () => Navigator.pop(context),
              ),
            ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title
                      AppFieldLabel(
                        label: AppTranslations.pick(lang, en: 'Task Title', mr: 'कामाचे शीर्षक', hi: 'कार्य शीर्षक'),
                        isRequired: true,
                      ),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 13),
                        decoration: inputDec(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Ward 12 road pothole repairs',
                            mr: 'उदा. प्रभाग १२ मधील रस्त्यावरील खड्डे दुरुस्ती',
                            hi: 'उदा. वार्ड १२ सड़क गड्ढा मरम्मत',
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? AppTranslations.pick(
                                lang,
                                en: 'Please enter task title',
                                mr: 'कृपया कामाचे शीर्षक टाका',
                                hi: 'कृपया कार्य शीर्षक दर्ज करें',
                              )
                            : null,
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
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(lang, en: 'Priority', mr: 'प्राधान्य', hi: 'प्राथमिकता'),
                                  value: _priority,
                                  items: [
                                    DropdownMenuItem(value: 'Low', child: Text(AppTranslations.getPriority('Low', lang))),
                                    DropdownMenuItem(value: 'Medium', child: Text(AppTranslations.getPriority('Medium', lang))),
                                    DropdownMenuItem(value: 'High', child: Text(AppTranslations.getPriority('High', lang))),
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(lang, en: 'Due Date', mr: 'अंतिम तारीख', hi: 'नियत तिथि'),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showThemedDatePicker(
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
                                        Flexible(
                                          child: Text(
                                            _dueDate != null
                                                ? AppTranslations.formatDate(_dueDate!, lang, pattern: 'dd/MM/yyyy')
                                                : AppTranslations.pick(lang, en: 'Select Date', mr: 'तारीख निवडा', hi: 'तिथि चुनें'),
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
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
                      const SizedBox(height: 12),

                      // Address / Location
                      AppFieldLabel(
                        label: AppTranslations.pick(lang, en: 'Location / Address', mr: 'ठिकाण / पत्ता', hi: 'स्थान / पता'),
                      ),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(fontSize: 13),
                        decoration: inputDec(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Opposite Ganpati Temple, Shaniwar Peth',
                            mr: 'उदा. गणपती मंदिरासमोर, शनिवार पेठ',
                            hi: 'उदा. गणपति मंदिर के सामने, शनिवार पेठ',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      AppFieldLabel(
                        label: AppTranslations.pick(lang, en: 'Details / Instructions', mr: 'तपशील / सूचना', hi: 'विवरण / निर्देश'),
                      ),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13),
                        decoration: inputDec(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'Enter more details and instructions about this task...',
                            mr: 'या कामाबद्दल अधिक तपशील आणि सूचना लिहा...',
                            hi: 'इस कार्य के बारे में अधिक विवरण और निर्देश दर्ज करें...',
                          ),
                        ),
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
                              : Text(
                                  AppTranslations.pick(lang, en: 'Assign Task', mr: 'काम नेमा', hi: 'कार्य सौंपें'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
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
