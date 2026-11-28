import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/core/services/translation_service.dart';
import 'package:nagarsevak_mobile/data/models/complaint_model.dart';
import 'package:nagarsevak_mobile/data/repositories/complaints_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import 'package:nagarsevak_mobile/presentation/screens/complaints/new_complaint_screen.dart';
import 'package:nagarsevak_mobile/presentation/screens/complaints/complaint_detail_screen.dart';
import 'package:nagarsevak_mobile/presentation/screens/ward_problems/ward_problems_report_generator.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_dropdown.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_load_more_footer.dart';

/// Desktop Ward Problems View matching WardWiseProblem.tsx verbatim:
/// - Sticky Header: Title + Subtitle + Found Badge + Help + New Problem
/// - View Mode Toggle: 3x3 Grid vs Report Table
/// - 3-Filter Toolbar: Search + Area dropdown + Date dropdown
/// - Status Filter Pills: All, Pending, Assigned, InProgress, Resolved
/// - Responsive 3-Column Card Grid (grid-cols-1 md:grid-cols-2 lg:grid-cols-3)
class DesktopWardProblemsView extends ConsumerStatefulWidget {
  const DesktopWardProblemsView({super.key});

  @override
  ConsumerState<DesktopWardProblemsView> createState() => _DesktopWardProblemsViewState();
}

class _DesktopWardProblemsViewState extends ConsumerState<DesktopWardProblemsView> {
  String _viewMode = 'grid'; // 'grid' | 'table'
  String _filterStatus = 'All'; // 'All', 'Pending', 'Assigned', 'InProgress', 'Resolved'
  String _searchQuery = '';
  String _selectedArea = 'All';
  String _selectedDate = 'All';
  ComplaintModel? _selectedProblem;
  int _displayedLimit = 20;

  bool _loading = true;
  List<ComplaintModel> _problems = [];

  List<ComplaintModel> get _visibleProblems =>
      _filteredProblems.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadWardProblems();
  }

  Future<void> _loadWardProblems({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final repo = ref.read(complaintsRepoProvider);
      final all = await repo.getComplaints(limit: 100);
      // Filter for ward problems / self-identified issues
      final wardList = all.where((c) {
        final cat = c.category.toLowerCase();
        return cat == 'selfidentified' || cat == 'ward problem' || cat == 'area problem' || cat.contains('ward');
      }).toList();

      if (mounted) {
        setState(() {
          _problems = wardList.isNotEmpty ? wardList : all;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _uniqueAreas {
    final areas = <String>{};
    for (final c in _problems) {
      if (c.area != null && c.area!.trim().isNotEmpty) {
        areas.add(c.area!.trim());
      } else if (c.location != null && c.location!.trim().isNotEmpty) {
        areas.add(c.location!.trim());
      }
    }
    final sorted = areas.toList()..sort();
    return ['All', ...sorted];
  }

  List<String> get _uniqueDates {
    final dates = <String>{};
    for (final c in _problems) {
      dates.add(AppTranslations.formatDate(c.createdAt, 'en', pattern: 'yyyy-MM-dd'));
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return ['All', ...sorted];
  }

  List<ComplaintModel> get _filteredProblems {
    return _problems.where((c) {
      if (_filterStatus != 'All') {
        if (c.status.toLowerCase() != _filterStatus.toLowerCase()) return false;
      }
      if (_selectedArea != 'All') {
        final matches = (c.area != null && c.area == _selectedArea) ||
            (c.location != null && c.location == _selectedArea);
        if (!matches) return false;
      }
      if (_selectedDate != 'All') {
        final dateKey = AppTranslations.formatDate(c.createdAt, 'en', pattern: 'yyyy-MM-dd');
        if (dateKey != _selectedDate) {
          return false;
        }
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = AppTranslations.normalizeAsciiDigits(_searchQuery).toLowerCase().trim();
        final matchTitle = AppTranslations.normalizeAsciiDigits(c.title).toLowerCase().contains(q);
        final matchDesc = AppTranslations.normalizeAsciiDigits(c.description).toLowerCase().contains(q);
        final matchArea = AppTranslations.normalizeAsciiDigits(c.area ?? '').toLowerCase().contains(q);
        final matchLoc = AppTranslations.normalizeAsciiDigits(c.location ?? '').toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchArea && !matchLoc) return false;
      }
      return true;
    }).toList();
  }

  void _openNewProblemModal() {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Container(
          width: 680,
          constraints: const BoxConstraints(maxHeight: 740),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const NewComplaintScreen(),
        ),
      ),
    ).then((res) {
      if (res == true) _loadWardProblems(showLoading: false);
    });
  }

  void _openDetail(ComplaintModel problem) {
    setState(() {
      _selectedProblem = problem;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedProblem != null) {
      return ComplaintDetailScreen(
        complaint: _selectedProblem!,
        onBack: () {
          setState(() => _selectedProblem = null);
          _loadWardProblems(showLoading: false);
        },
      );
    }

    final lang = ref.watch(desktopLanguageProvider);
    final isMr = lang == 'mr';
    final items = _filteredProblems;
    final visibleItems = _visibleProblems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row (matching WardWiseProblem.tsx lines 305-356)
            _buildHeader(lang, items.length),

            const SizedBox(height: 16),

            // 2. Filter Toolbar (matching lines 358-472)
            _buildFilterCard(lang),

            const SizedBox(height: 24),

            // 3. Main Content: 3x3 Card Grid or Report Table
            if (_loading)
              _buildLoadingGrid()
            else if (items.isEmpty)
              _buildEmptyState(lang)
            else if (_viewMode == 'grid')
              _build3x3Grid(visibleItems, lang)
            else
              _buildReportTable(visibleItems, lang),

            // 4. Pagination Load More Footer
            if (!_loading && items.isNotEmpty)
              AppLoadMoreFooter(
                currentCount: visibleItems.length,
                totalCount: items.length,
                pageSize: 20,
                onLoadMore: () {
                  setState(() => _displayedLimit += 20);
                },
                label: AppTranslations.pick(
                  lang,
                  en: 'problems',
                  mr: 'समस्या',
                  hi: 'समस्याएं',
                ),
                isMarathi: isMr,
              ),
          ],
        ),
      ),
    );
  }

  // --- Header Row ---
  Widget _buildHeader(String lang, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 26, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Text(
                  AppTranslations.getNavTitle('ward_problems', lang),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.5),
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
                    AppTranslations.formatFound(count, lang),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.pick(
                lang,
                en: 'Track self-identified and ward-level civic problems',
                mr: 'प्रभागातील रस्ते, पाणी व स्थानिक नागरी समस्यांचे व्यवस्थापन',
                hi: 'वार्ड की सड़क, पानी और स्थानीय नागरिक समस्याओं का प्रबंधन',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + New Request
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                WardProblemsReportGenerator.generateAndPrintReport(
                  context: context,
                  problems: _filteredProblems,
                  areaFilter: _selectedArea,
                  statusFilter: _filterStatus,
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

            ElevatedButton(
              onPressed: _openNewProblemModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7), // bg-brand-600
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // rounded-xl
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white), // Plus w-4 h-4
                  const SizedBox(width: 8), // gap-2
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'New Problem',
                      mr: 'नवीन समस्या',
                      hi: 'नई समस्या',
                    ),
                    style: const TextStyle(
                      fontSize: 14, // text-sm
                      fontWeight: FontWeight.w600, // font-semibold
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

  // --- Filter Card (Search + Area + Status Pills) ---
  Widget _buildFilterCard(String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          // Row 1: Search & Area & Date Filters (matching WardWiseProblem.tsx grid-cols-3)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _displayedLimit = 20;
                  }),
                  decoration: InputDecoration(
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Search problems by title, description...',
                      mr: 'समस्या, वर्णन शोधा...',
                      hi: 'समस्या, विवरण खोजें...',
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: AppDropdown<String>(
                  value: _selectedArea,
                  height: 42,
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  items: _uniqueAreas.map((area) {
                    return DropdownMenuItem(
                      value: area,
                      child: Text(
                        area == 'All'
                            ? AppTranslations.pick(lang, en: 'All Areas', mr: 'सर्व भाग', hi: 'सभी क्षेत्र')
                            : AppTranslations.getAreaName(area, lang),
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
              Expanded(
                flex: 1,
                child: AppDropdown<String>(
                  value: _selectedDate,
                  height: 42,
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  items: _uniqueDates.map((date) {
                    final display = date == 'All'
                        ? AppTranslations.pick(lang, en: 'All Dates', mr: 'सर्व तारखा', hi: 'सभी तिथियां')
                        : AppTranslations.formatDate(DateTime.parse(date), lang, pattern: 'MMM d, yyyy');
                    return DropdownMenuItem(
                      value: date,
                      child: Text(
                        display,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDate = val;
                        _displayedLimit = 20;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Status Pills & View Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusPill('All', AppTranslations.t('common.all', lang: lang)),
                    _buildStatusPill('Pending', AppTranslations.getStatus('pending', lang)),
                    _buildStatusPill('Assigned', AppTranslations.getStatus('assigned', lang)),
                    _buildStatusPill('InProgress', AppTranslations.getStatus('inprogress', lang)),
                    _buildStatusPill('Resolved', AppTranslations.getStatus('resolved', lang)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildViewToggleButton(
                      icon: Icons.grid_view_rounded,
                      label: AppTranslations.pick(lang, en: 'Grid', mr: 'ग्रिड', hi: 'ग्रिड'),
                      isActive: _viewMode == 'grid',
                      onTap: () => setState(() => _viewMode = 'grid'),
                    ),
                    const SizedBox(width: 4),
                    _buildViewToggleButton(
                      icon: Icons.table_rows_rounded,
                      label: AppTranslations.pick(lang, en: 'Table', mr: 'तक्ता', hi: 'तालिका'),
                      isActive: _viewMode == 'table',
                      onTap: () => setState(() => _viewMode = 'table'),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String statusKey, String label) {
    final isSelected = _filterStatus == statusKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() {
          _filterStatus = statusKey;
          _displayedLimit = 20;
        }),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // --- 3x3 Card Grid (matching WardWiseProblem.tsx line 559) ---
  Widget _build3x3Grid(List<ComplaintModel> items, String lang) {
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
            final problem = items[index];
            return _buildProblemCard(problem, lang);
          },
        );
      },
    );
  }

  Widget _buildProblemCard(ComplaintModel problem, String lang) {
    final dateStr = AppTranslations.formatDate(problem.createdAt, lang, pattern: 'MMM d, yyyy');

    return InkWell(
      onTap: () => _openDetail(problem),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(problem.status, lang),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED), // orange-50
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFED7AA)), // orange-200
                  ),
                  child: Text(
                    AppTranslations.getComplaintType(problem.category, lang),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFC2410C)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (problem.assignedStaffName != null && problem.assignedStaffName!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: AppTranslatedText(
                        problem.assignedStaffName!,
                        isName: true,
                        targetLanguage: lang,
                        prefix: '${AppTranslations.pick(lang, en: 'Assigned:', mr: 'नियुक्त:', hi: 'नियुक्त:')} ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            AppTranslatedText(
              problem.title,
              targetLanguage: lang,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: AppTranslatedText(
                problem.description,
                targetLanguage: lang,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
              ),
            ),

            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  if (problem.area != null || problem.location != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: AppTranslatedText(
                            AppTranslations.getAreaName(problem.area ?? problem.location ?? '', lang),
                            targetLanguage: lang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, [String lang = 'en']) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    final lower = status.toLowerCase();
    if (lower == 'pending') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (lower == 'assigned') {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF4338CA);
    } else if (lower == 'inprogress') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (lower == 'resolved') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(AppTranslations.getStatus(status, lang), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildReportTable(List<ComplaintModel> items, String lang) {
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
            DataColumn(label: Text(AppTranslations.getReportColumn('area', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('title', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('status', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Assigned Staff', mr: 'नियुक्त कर्मचारी', hi: 'नियुक्त कर्मचारी'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            DataColumn(label: Text(AppTranslations.getReportColumn('date', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: items.map((p) {
            return DataRow(
              cells: [
                DataCell(
                  AppTranslatedText(
                    AppTranslations.getAreaName(p.area ?? p.location ?? '-', lang),
                    targetLanguage: lang,
                  ),
                ),
                DataCell(
                  AppTranslatedText(
                    p.title,
                    targetLanguage: lang,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(_buildStatusBadge(p.status, lang)),
                DataCell(
                  p.assignedStaffName != null && p.assignedStaffName!.trim().isNotEmpty
                      ? AppTranslatedText(
                          p.assignedStaffName!,
                          isName: true,
                          targetLanguage: lang,
                        )
                      : const Text('-'),
                ),
                DataCell(Text(AppTranslations.formatDate(p.createdAt, lang, pattern: 'MMM d, yyyy'))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(strokeWidth: 2)));
  }

  Widget _buildEmptyState(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No ward problems recorded yet',
              mr: 'कोणतीही प्रभागातील समस्या नोंदवलेली नाही',
              hi: 'कोई वार्ड समस्या अभी तक दर्ज नहीं की गई',
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
