import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../complaints/complaint_detail_screen.dart';
import '../complaints/new_complaint_bottom_sheet.dart';
import 'ward_problems_report_generator.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';

/// WardWiseProblem Screen matching EXACTLY the web page:
/// Nagarsevak-Managment/src/pages/ward/WardWiseProblem.tsx
class WardProblemsScreen extends ConsumerStatefulWidget {
  const WardProblemsScreen({super.key});

  @override
  ConsumerState<WardProblemsScreen> createState() => _WardProblemsScreenState();
}

class _WardProblemsScreenState extends ConsumerState<WardProblemsScreen> {
  // View mode: 'grid' or 'report' matching WardWiseProblem.tsx
  String _viewMode = 'grid';

  // Status Filter: 'All', 'Pending', 'Assigned', 'InProgress', 'Resolved'
  String _filterStatus = 'All';

  // Search & Filter State
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _areaSearchCtrl = TextEditingController();
  final TextEditingController _dateSearchCtrl = TextEditingController();

  bool _showAreaDropdown = false;
  bool _showDateDropdown = false;

  bool _loading = true;
  List<ComplaintModel> _complaints = [];
  int _displayedLimit = 20;

  List<ComplaintModel> get _visibleComplaints =>
      _filteredComplaints.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _areaSearchCtrl.dispose();
    _dateSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final repo = ref.read(complaintsRepoProvider);
      final list = await repo.getWardProblems();

      if (mounted) {
        setState(() {
          _complaints = list;
          _loading = false;
          _displayedLimit = 20;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Unique Areas with counts matching WardWiseProblem.tsx lines 222-227
  List<Map<String, dynamic>> get _uniqueAreas {
    final Map<String, int> counts = {};
    for (final c in _complaints) {
      final a = c.area?.trim();
      if (a != null && a.isNotEmpty) {
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    final list = counts.entries.map((e) => {'name': e.key, 'count': e.value}).toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list;
  }

  // Unique Dates with counts matching WardWiseProblem.tsx lines 230-237
  List<Map<String, dynamic>> get _uniqueDates {
    final Map<String, int> counts = {};
    final Map<String, DateTime> dateMap = {};
    for (final c in _complaints) {
      final dt = c.createdAt;
      final dateStr =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      counts[dateStr] = (counts[dateStr] ?? 0) + 1;
      dateMap[dateStr] = dt;
    }
    final list = counts.entries.map((e) {
      final dt = dateMap[e.key]!;
      return {
        'value': e.key,
        'date': dt,
        'display': AppTranslations.formatDate(dt, 'en', pattern: 'MMM d, yyyy'),
        'count': e.value,
      };
    }).toList();
    list.sort((a, b) => b['value'].toString().compareTo(a['value'].toString()));
    return list;
  }

  // Filtered complaints matching WardWiseProblem.tsx lines 240-251
  List<ComplaintModel> get _filteredComplaints {
    final search = _searchCtrl.text.trim().toLowerCase();
    final normSearch = AppTranslations.normalizeAsciiDigits(search);
    final areaSearch = _areaSearchCtrl.text.trim().toLowerCase();
    final normAreaSearch = AppTranslations.normalizeAsciiDigits(areaSearch);
    final dateSearch = _dateSearchCtrl.text.trim().toLowerCase();
    final normDateSearch = AppTranslations.normalizeAsciiDigits(dateSearch);

    return _complaints.where((c) {
      final matchesSearch = search.isEmpty ||
          c.title.toLowerCase().contains(search) ||
          c.description.toLowerCase().contains(search) ||
          (c.citizenName?.toLowerCase().contains(search) ?? false) ||
          (c.citizenMobile != null &&
              AppTranslations.normalizeAsciiDigits(c.citizenMobile!)
                  .toLowerCase()
                  .contains(normSearch));

      final areaLower = c.area?.toLowerCase() ?? '';
      final matchesArea = areaSearch.isEmpty ||
          areaLower.contains(areaSearch) ||
          AppTranslations.normalizeAsciiDigits(areaLower).contains(normAreaSearch);

      final dateEn =
          AppTranslations.formatDate(c.createdAt, 'en', pattern: 'MMM d, yyyy')
              .toLowerCase();
      final dateMr = AppTranslations.normalizeAsciiDigits(
        AppTranslations.formatDate(c.createdAt, 'mr', pattern: 'MMM d, yyyy'),
      ).toLowerCase();
      final dateHi = AppTranslations.normalizeAsciiDigits(
        AppTranslations.formatDate(c.createdAt, 'hi', pattern: 'MMM d, yyyy'),
      ).toLowerCase();
      final matchesDate = dateSearch.isEmpty ||
          dateEn.contains(normDateSearch) ||
          dateMr.contains(normDateSearch) ||
          dateHi.contains(normDateSearch);

      final statusMatch = _filterStatus == 'All' ||
          c.status.toLowerCase() == _filterStatus.toLowerCase();

      return statusMatch && matchesSearch && matchesArea && matchesDate;
    }).toList();
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFFDCFCE7);
      case 'closed':
        return const Color(0xFFF3F4F6);
      case 'pending':
        return const Color(0xFFFEF2F2);
      case 'assigned':
        return const Color(0xFFEFF6FF);
      case 'inprogress':
        return const Color(0xFFFEF9C3);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF166534);
      case 'closed':
        return const Color(0xFF1F2937);
      case 'pending':
        return const Color(0xFFB91C1C);
      case 'assigned':
        return const Color(0xFF1D4ED8);
      case 'inprogress':
        return const Color(0xFFA16207);
      default:
        return const Color(0xFF1F2937);
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFFBBF7D0);
      case 'closed':
        return const Color(0xFFE5E7EB);
      case 'pending':
        return const Color(0xFFFEE2E2);
      case 'assigned':
        return const Color(0xFFDBEAFE);
      case 'inprogress':
        return const Color(0xFFFEF08A);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  String _getStatusText(String status, String lang) =>
      AppTranslations.getStatus(status, lang);

  Color _getTypeBg(String type) {
    if (type == 'SelfIdentified') return const Color(0xFFFFF7ED);
    return const Color(0xFFF0F9FF);
  }

  Color _getTypeTextColor(String type) {
    if (type == 'SelfIdentified') return const Color(0xFFC2410C);
    return const Color(0xFF0369A1);
  }

  Color _getTypeBorderColor(String type) {
    if (type == 'SelfIdentified') return const Color(0xFFFFEDD5);
    return const Color(0xFFE0F2FE);
  }

  void _openNewWardProblemModal() {
    NewComplaintBottomSheet.show(
      context,
      initialTab: 'Complaints',
      hidePersonalHelp: true,
    ).then((val) {
      if (val == true) {
        _fetchComplaints();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final filtered = _filteredComplaints;

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
        drawer: const NagarsevakAppDrawer(currentTabIndex: 0),
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
                AppTranslations.getNavTitle('ward_problems', lang),
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
                lang == 'mr'
                    ? 'तक्रारी व नागरिकांच्या अडचणी'
                    : (lang == 'hi'
                        ? 'शिकायतें और नागरिक समस्याएं'
                        : 'Grievances & civic issues'),
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
        body: _loading
            ? const AppShimmerList(count: 6)
            : RefreshIndicator(
                onRefresh: _fetchComplaints,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: const EdgeInsets.only(top: 10),
                  children: [
                    // Search and Filters Card matching WardWiseProblem.tsx lines 358-472
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                        children: [
                          // 1) General Search Input
                          Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() => _displayedLimit = 20),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                      lang,
                      en: 'Search by title, description or citizen...',
                      mr: 'समस्या किंवा नागरिक शोधा...',
                      hi: 'समस्या या नागरिक खोजें...',
                    ),
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                prefixIcon: const Icon(Icons.search, size: 19, color: Color(0xFF94A3B8)),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _displayedLimit = 20);
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 2) Row with Area Search & Date Search (with Dropdowns)
                          Row(
                            children: [
                              // Area Search with Dropdown matching WardWiseProblem.tsx lines 374-409
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: TextField(
                                        controller: _areaSearchCtrl,
                                        onTap: () => setState(() => _showAreaDropdown = true),
                                        onChanged: (_) => setState(() => _showAreaDropdown = true),
                                        style: const TextStyle(fontSize: 12.5),
                                        decoration: InputDecoration(
                                          hintText: AppTranslations.pick(
                                lang,
                                en: 'Search area...',
                                mr: 'परिसर शोधा...',
                                hi: 'क्षेत्र खोजें...',
                              ),
                                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                                          suffixIcon: _areaSearchCtrl.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                                                  onPressed: () {
                                                    _areaSearchCtrl.clear();
                                                    setState(() {
                                                      _showAreaDropdown = false;
                                                      _displayedLimit = 20;
                                                    });
                                                  },
                                                )
                                              : null,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Date Search with Dropdown matching WardWiseProblem.tsx lines 412-447
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: TextField(
                                    controller: _dateSearchCtrl,
                                    onTap: () => setState(() => _showDateDropdown = true),
                                    onChanged: (_) => setState(() => _showDateDropdown = true),
                                    style: const TextStyle(fontSize: 12.5),
                                    decoration: InputDecoration(
                                      hintText: AppTranslations.pick(
                                lang,
                                en: 'Filter by date...',
                                mr: 'तारीख फिल्टर...',
                                hi: 'तारीख फ़िल्टर...',
                              ),
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 17, color: Color(0xFF94A3B8)),
                                      suffixIcon: _dateSearchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                                              onPressed: () {
                                                _dateSearchCtrl.clear();
                                                setState(() {
                                                  _showDateDropdown = false;
                                                  _displayedLimit = 20;
                                                });
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Area Dropdown Box if open
                          if (_showAreaDropdown && _uniqueAreas.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children: _uniqueAreas
                                    .where((a) {
                                      if (_areaSearchCtrl.text.isEmpty) return true;
                                      final q = _areaSearchCtrl.text.toLowerCase();
                                      final normQ = AppTranslations.normalizeAsciiDigits(q);
                                      final name = a['name'].toString().toLowerCase();
                                      return name.contains(q) ||
                                          AppTranslations.normalizeAsciiDigits(name)
                                              .contains(normQ);
                                    })
                                    .map((area) {
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: AppTranslatedText(
                                      area['name'] as String,
                                      targetLanguage: lang,
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        AppTranslations.formatDigits(
                                          '${area['count']}',
                                          lang,
                                        ),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _areaSearchCtrl.text = area['name'] as String;
                                        _showAreaDropdown = false;
                                        _displayedLimit = 20;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          // Date Dropdown Box if open
                          if (_showDateDropdown && _uniqueDates.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children: _uniqueDates
                                    .where((d) {
                                      return _dateSearchCtrl.text.isEmpty ||
                                        d['display']
                                            .toString()
                                            .toLowerCase()
                                            .contains(
                                              AppTranslations.normalizeAsciiDigits(
                                                _dateSearchCtrl.text,
                                              ).toLowerCase(),
                                            ) ||
                                        AppTranslations.normalizeAsciiDigits(
                                          AppTranslations.formatDate(
                                            d['date'] as DateTime,
                                            lang,
                                            pattern: 'MMM d, yyyy',
                                          ),
                                        ).toLowerCase().contains(
                                              AppTranslations.normalizeAsciiDigits(
                                                _dateSearchCtrl.text,
                                              ).toLowerCase(),
                                            );
                                  }).map((d) {
                                    final formattedDate = AppTranslations.formatDate(
                                      d['date'] as DateTime,
                                      lang,
                                      pattern: 'MMM d, yyyy',
                                    );
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      title: Text(
                                        formattedDate,
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          AppTranslations.formatDigits(
                                            '${d['count']}',
                                            lang,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF475569),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _dateSearchCtrl.text = formattedDate;
                                          _showDateDropdown = false;
                                          _displayedLimit = 20;
                                        });
                                      },
                                    );
                                  }).toList(),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // 3) Horizontal Status Pills matching WardWiseProblem.tsx lines 451-471
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStatusPill('All', lang == 'mr' ? 'सर्व' : (lang == 'hi' ? 'सभी' : 'All')),
                                _buildStatusPill('Pending', lang == 'mr' ? 'प्रलंबित' : (lang == 'hi' ? 'लंबित' : 'Pending')),
                                _buildStatusPill('Assigned', lang == 'mr' ? 'नेमलेले' : (lang == 'hi' ? 'सौंपा गया' : 'Assigned')),
                                _buildStatusPill('InProgress', lang == 'mr' ? 'सुरू' : (lang == 'hi' ? 'प्रगति पर' : 'In Progress')),
                                _buildStatusPill('Resolved', lang == 'mr' ? 'निकाली' : (lang == 'hi' ? 'समाधान हुआ' : 'Resolved')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Secondary Tools: Count, View Mode & PDF Export
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Text(
                                '${AppTranslations.pick(lang, en: "Total Issues", mr: "एकूण समस्या", hi: "कुल समस्याएं")}: ${AppTranslations.formatDigits(filtered.length, lang)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              // View Mode Toggle (Grid / Report Table)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => setState(() => _viewMode = 'grid'),
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _viewMode == 'grid' ? const Color(0xFF0284C7) : Colors.transparent,
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                        ),
                                        child: Icon(
                                          Icons.grid_view_rounded,
                                          size: 17,
                                          color: _viewMode == 'grid' ? Colors.white : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => _viewMode = 'report'),
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _viewMode == 'report' ? const Color(0xFF0284C7) : Colors.transparent,
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                        ),
                                        child: Icon(
                                          Icons.table_chart_outlined,
                                          size: 17,
                                          color: _viewMode == 'report' ? Colors.white : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // PDF Export Button (Themed Component)
                              AppPdfButton(
                                label: AppTranslations.getDownloadReport(lang),
                                style: AppPdfButtonStyle.outlined,
                                onPressed: () {
                                  WardProblemsReportGenerator.generateAndPrintReport(
                                    problems: filtered,
                                    areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
                                    statusFilter: _filterStatus,
                                    lang: lang,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Content: Report Table or Cards Grid
                    if (_viewMode == 'report') ...[
                      _buildReportTableView(lang, _visibleComplaints),
                    ] else ...[
                      _buildCardsGridView(_visibleComplaints, lang),
                    ],
                    AppLoadMoreFooter(
                      currentCount: _visibleComplaints.length,
                      totalCount: filtered.length,
                      pageSize: 20,
                      onLoadMore: () => setState(() => _displayedLimit += 20),
                      label: AppTranslations.pick(
                        lang,
                        en: 'problems',
                        mr: 'तक्रारी',
                        hi: 'शिकायतें',
                      ),
                      isMarathi: lang == 'mr',
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: _openNewWardProblemModal,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            AppTranslations.pick(
              lang,
              en: 'New Problem',
              mr: 'नवीन तक्रार नोंदवा',
              hi: 'नई समस्या दर्ज करें',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, String label) {
    final isSelected = _filterStatus.toLowerCase() == status.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() {
          _filterStatus = status;
          _displayedLimit = 20;
        }),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // Cards Grid View matching WardWiseProblem.tsx lines 559-634
  Widget _buildCardsGridView(List<ComplaintModel> items, String lang) {
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No requests found for this filter',
                mr: 'कोणतीही समस्या आढळली नाही',
                hi: 'इस फ़िल्टर के लिए कोई समस्या नहीं मिली',
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openNewWardProblemModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                AppTranslations.pick(
                  lang,
                  en: 'New Request',
                  mr: 'नवीन तक्रार नोंदवा',
                  hi: 'नया अनुरोध दर्ज करें',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final c = items[idx];
          return InkWell(
            onTap: () {
              Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ComplaintDetailScreen(complaint: c),
                ),
              ).then((res) {
                if (res == true) _fetchComplaints(showLoading: false);
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  // Top Row: Status badge and Type Badge matching lines 567-580
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusBg(c.status),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getStatusBorderColor(c.status)),
                        ),
                        child: Text(
                          _getStatusText(c.status, lang),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusTextColor(c.status),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getTypeBg(c.category),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getTypeBorderColor(c.category)),
                        ),
                        child: c.category == 'SelfIdentified'
                            ? Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Self Identified',
                                  mr: 'स्व-ओळखलेली',
                                  hi: 'स्व-चिह्नित',
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getTypeTextColor(c.category),
                                ),
                              )
                            : AppTranslatedText(
                                c.category,
                                targetLanguage: lang,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getTypeTextColor(c.category),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Staff Assigned Tag matching lines 582-587
                  if (c.assignedStaffName != null && c.status.toLowerCase() == 'assigned') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Color(0xFF1D4ED8)),
                          const SizedBox(width: 4),
                          Text(
                            '${AppTranslations.pick(lang, en: 'Assigned', mr: 'नियुक्त', hi: 'सौंपा गया')}: ',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                          ),
                          Flexible(
                            child: AppTranslatedText(
                              c.assignedStaffName!,
                              targetLanguage: lang,
                              isName: true,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                            ),
                          ),
                          if (c.assignedStaffMobile != null && c.assignedStaffMobile!.isNotEmpty)
                            Text(
                              AppTranslations.formatDigits(' | ${c.assignedStaffMobile}', lang),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Citizen / Submitter Info matching lines 589-596
                  if (c.citizenName != null && c.citizenName!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 13, color: Color(0xFF475569)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: AppTranslatedText(
                              c.citizenName!,
                              targetLanguage: lang,
                              isName: true,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          ),
                          if (c.citizenMobile != null && c.citizenMobile!.isNotEmpty) ...[
                            Text(
                              AppTranslations.formatDigits(' | ${c.citizenMobile}', lang),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Title matching line 599
                  AppTranslatedText(
                    c.title,
                    targetLanguage: lang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (c.description.isNotEmpty && c.description != c.title) ...[
                    const SizedBox(height: 4),
                    AppTranslatedText(
                      c.description,
                      targetLanguage: lang,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Bottom Row: Date & Location matching lines 606-619
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            '${AppTranslations.formatDate(c.createdAt, lang, pattern: 'MMM d')}, ${AppTranslations.formatTime(c.createdAt, lang)}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      if ((c.area != null && c.area!.isNotEmpty) || (c.location != null && c.location!.isNotEmpty)) ...[
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: AppTranslatedText(
                                  c.area != null && c.location != null && c.area!.isNotEmpty && c.location!.isNotEmpty
                                      ? '${c.area!}, ${c.location!}'
                                      : ((c.area != null && c.area!.isNotEmpty) ? c.area! : (c.location ?? '')),
                                  targetLanguage: lang,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Report Table View matching WardWiseProblem.tsx lines 475-557
  Widget _buildReportTableView(String lang, List<ComplaintModel> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          // Table Header Bar with Download Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppTranslations.pick(lang, en: "Report View", mr: "अहवाल तक्ता", hi: "रिपोर्ट तालिका")} (${AppTranslations.formatDigits('${items.length}', lang)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    WardProblemsReportGenerator.generateAndPrintReport(
                      problems: items,
                      areaFilter: _areaSearchCtrl.text.isNotEmpty ? _areaSearchCtrl.text : 'All Areas',
                      statusFilter: _filterStatus,
                      lang: lang,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F9FF),
                    foregroundColor: const Color(0xFF0284C7),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(
                    AppTranslations.getDownloadReport(lang),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Horizontally Scrollable Data Table matching exactly columns from line 493
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 20,
              columns: [
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Sr No', mr: 'क्र.', hi: 'क्र.'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Title & Type', mr: 'शीर्षक व प्रकार', hi: 'शीर्षक व प्रकार'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Citizen Info', mr: 'नागरिक माहिती', hi: 'नागरिक जानकारी'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text(AppTranslations.pick(lang, en: 'Date', mr: 'तारीख', hi: 'तारीख'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final c = entry.value;
                return DataRow(
                  onSelectChanged: (_) {
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintDetailScreen(complaint: c),
                      ),
                    ).then((res) {
                      if (res == true) _fetchComplaints(showLoading: false);
                    });
                  },
                  cells: [
                    DataCell(Text(AppTranslations.formatDigits('${idx + 1}', lang), style: const TextStyle(fontSize: 12))),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: AppTranslatedText(
                          c.area ?? c.location ?? AppTranslations.pick(lang, en: 'Ward 12', mr: 'प्रभाग १२', hi: 'वार्ड १२'),
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              c.title,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            AppTranslatedText(
                              c.description,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusBg(c.status),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getStatusBorderColor(c.status)),
                        ),
                        child: Text(
                          _getStatusText(c.status, lang),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusTextColor(c.status),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              c.citizenName ?? '--',
                              targetLanguage: lang,
                              isName: true,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            if (c.citizenMobile != null && c.citizenMobile!.isNotEmpty)
                              Text(AppTranslations.formatDigits(c.citizenMobile!, lang), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        AppTranslations.formatDate(c.createdAt, lang, pattern: 'MMM d, yyyy'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
