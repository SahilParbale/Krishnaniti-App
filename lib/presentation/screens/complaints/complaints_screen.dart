import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import 'new_complaint_bottom_sheet.dart';
import 'complaint_detail_screen.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'complaint_report_generator.dart';

class ComplaintsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  final ValueChanged<int>? onTabChange;

  const ComplaintsScreen({super.key, this.onBackToHome, this.onTabChange});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Primary Tabs matching Nagarsevak-Managment: 'Complaints' | 'Personal Help'
  String _activeTab = 'Complaints'; 

  // Status Filter: 'All', 'Pending', 'Assigned', 'InProgress', 'Resolved'
  String _selectedStatus = 'All';

  // Area / Ward Filter
  String _selectedArea = 'All';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  int _displayedLimit = 20;

  // Area Complaints Dataset
  List<ComplaintModel> _areaComplaints = [];

  // Personal Help Requests Dataset
  List<ComplaintModel> _personalRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final repo = ref.read(complaintsRepoProvider);
      final results = await repo.getComplaints();
      final personalResults = await repo.getPersonalRequests();

      if (mounted) {
        setState(() {
          _areaComplaints = results;
          _personalRequests = personalResults;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Get active dataset based on selected Tab
  List<ComplaintModel> get _currentList {
    return _activeTab == 'Complaints' ? _areaComplaints : _personalRequests;
  }

  // Filtered complaints based on search, area, and status filter
  List<ComplaintModel> get _filteredComplaints {
    return _currentList.where((c) {
      // 1. Status Filter
      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'InProgress') {
          if (c.status.toLowerCase() != 'inprogress' && c.status.toLowerCase() != 'assigned') {
            return false;
          }
        } else if (c.status.toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
      }

      // 2. Area Filter
      if (_selectedArea != 'All') {
        final matchesArea = (c.area != null && c.area!.toLowerCase().contains(_selectedArea.toLowerCase())) ||
            (c.location != null && c.location!.toLowerCase().contains(_selectedArea.toLowerCase()));
        if (!matchesArea) return false;
      }

      // 3. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesQuery = c.id.toLowerCase().contains(q) ||
            c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.category.toLowerCase().contains(q) ||
            (c.citizenName != null && c.citizenName!.toLowerCase().contains(q)) ||
            (c.citizenMobile != null && c.citizenMobile!.contains(q)) ||
            (c.area != null && c.area!.toLowerCase().contains(q));
        if (!matchesQuery) return false;
      }

      return true;
    }).toList();
  }

  List<ComplaintModel> get _visibleComplaints =>
      _filteredComplaints.take(_displayedLimit).toList();

  // Available unique areas for dropdown
  List<String> get _availableAreas {
    final areas = <String>{'All'};
    for (final c in _currentList) {
      if (c.area != null && c.area!.trim().isNotEmpty) {
        areas.add(c.area!.trim());
      }
    }
    return areas.toList();
  }

  // Open Full Complaint Details Page matching ComplaintDetail.tsx
  void _openDetailSheet(ComplaintModel complaint, bool isMr) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintDetailScreen(complaint: complaint),
      ),
    ).then((res) {
      if (res == true) _fetchComplaints(showLoading: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = ref.watch(appLanguageProvider);
    final isMr = lang == 'mr';
    final isHi = lang == 'hi';
    final filtered = _filteredComplaints;

    // Calculate real-time KPI counts for current tab
    final totalCount = _currentList.length;
    final pendingCount = _currentList.where((c) => c.status.toLowerCase() == 'pending').length;
    final inProgressCount = _currentList.where((c) => c.status.toLowerCase() == 'inprogress' || c.status.toLowerCase() == 'assigned').length;
    final resolvedCount = _currentList.where((c) => c.status.toLowerCase() == 'resolved' || c.status.toLowerCase() == 'closed').length;

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
        drawer: NagarsevakAppDrawer(
          currentTabIndex: 1,
          onTabChange: widget.onTabChange,
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Open Menu Drawer',
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
                AppTranslations.t('complaints.title', lang: lang),
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
                AppTranslations.t('complaints.subtitle', lang: lang),
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
        body: Column(
          children: [
            // 1. Dual Primary Tabs: 'Area Complaints' & 'Personal Help'
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: AppTranslations.t('complaints.tabs_area', lang: lang),
                        icon: Icons.domain_rounded,
                        badgeCount: _areaComplaints.length,
                        lang: lang,
                        isSelected: _activeTab == 'Complaints',
                        onTap: () {
                          setState(() {
                            _activeTab = 'Complaints';
                            _selectedStatus = 'All';
                            _displayedLimit = 20;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _TabButton(
                        label: AppTranslations.t('complaints.tabs_personal', lang: lang),
                        icon: Icons.volunteer_activism_rounded,
                        badgeCount: _personalRequests.length,
                        lang: lang,
                        isSelected: _activeTab == 'Personal Help',
                        onTap: () {
                          setState(() {
                            _activeTab = 'Personal Help';
                            _selectedStatus = 'All';
                            _displayedLimit = 20;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Interactive KPI Stats Strip matching Nagarsevak-Managment
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiStatCard(
                      label: AppTranslations.t('common.all', lang: lang),
                      count: totalCount,
                      lang: lang,
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFF0F9FF),
                      isSelected: _selectedStatus == 'All',
                      onTap: () => setState(() {
                        _selectedStatus = 'All';
                        _displayedLimit = 20;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiStatCard(
                      label: AppTranslations.getStatus('pending', lang),
                      count: pendingCount,
                      lang: lang,
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEF2F2),
                      isSelected: _selectedStatus == 'Pending',
                      onTap: () => setState(() {
                        _selectedStatus = 'Pending';
                        _displayedLimit = 20;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiStatCard(
                      label: AppTranslations.getStatus('inprogress', lang),
                      count: inProgressCount,
                      lang: lang,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      isSelected: _selectedStatus == 'InProgress',
                      onTap: () => setState(() {
                        _selectedStatus = 'InProgress';
                        _displayedLimit = 20;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiStatCard(
                      label: AppTranslations.getStatus('resolved', lang),
                      count: resolvedCount,
                      lang: lang,
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFF0FDF4),
                      isSelected: _selectedStatus == 'Resolved',
                      onTap: () => setState(() {
                        _selectedStatus = 'Resolved';
                        _displayedLimit = 20;
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Search and Area Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  // Search Box
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() {
                          _searchQuery = val.trim();
                          _displayedLimit = 20;
                        }),
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: lang == 'mr'
                              ? 'तक्रार, नागरिक किंवा फोन शोधा...'
                              : (lang == 'hi' ? 'शिकायत, नागरिक या फोन खोजें...' : 'Search title, citizen, phone...'),
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 19),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _displayedLimit = 20;
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Area Filter Dropdown (Themed Component)
                  AppDropdown<String>(
                    title: lang == 'mr' ? 'भाग निवडा' : (lang == 'hi' ? 'क्षेत्र चुनें' : 'Filter by Area'),
                    value: _selectedArea,
                    height: 42,
                    isExpanded: false,
                    backgroundColor: _selectedArea == 'All' ? const Color(0xFFF8FAFC) : const Color(0xFFE0F2FE),
                    borderColor: _selectedArea == 'All' ? const Color(0xFFCBD5E1) : const Color(0xFF0284C7),
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: _selectedArea == 'All' ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                    ),
                    items: _availableAreas.map((area) {
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(area == 'All'
                            ? (lang == 'mr' ? 'सर्व भाग' : (lang == 'hi' ? 'सभी क्षेत्र' : 'All Areas'))
                            : AppTranslations.getAreaName(area, lang)),
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
                  const SizedBox(width: 8),

                  // Download Complaints PDF Report Button
                  AppPdfButton.icon(
                    tooltip: lang == 'mr' ? 'अहवाल डाउनलोड करा' : (lang == 'hi' ? 'रिपोर्ट डाउनलोड करें' : 'Download Report'),
                    onPressed: () {
                      ComplaintReportGenerator.generateAndPrintReport(
                        complaints: filtered,
                        statusFilter: _selectedStatus != 'All' ? _selectedStatus : null,
                        areaFilter: _selectedArea != 'All' ? _selectedArea : null,
                        title: _activeTab == 'Complaints'
                            ? (lang == 'mr'
                                ? 'नागरी तक्रारी व अडचणी रजिस्टर'
                                : (lang == 'hi' ? 'नागरिक शिकायत रजिस्टर' : 'Citizen Grievance & Complaints Register'))
                            : (lang == 'mr'
                                ? 'वैयक्तिक मदत व विनंत्या रजिस्टर'
                                : (lang == 'hi' ? 'व्यक्तिगत सहायता अनुरोध रजिस्टर' : 'Personal Assistance Requests Register')),
                        lang: lang,
                      );
                    },
                  ),
                ],
              ),
            ),

            // 4. Horizontal Status Filter Pills
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterPill(
                      label: '${AppTranslations.t("common.all", lang: lang)} (${AppTranslations.formatDigits(_currentList.length, lang)})',
                      isSelected: _selectedStatus == 'All',
                      onTap: () => setState(() {
                        _selectedStatus = 'All';
                        _displayedLimit = 20;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: '${AppTranslations.getStatus("pending", lang)} (${AppTranslations.formatDigits(pendingCount, lang)})',
                      color: const Color(0xFFDC2626),
                      isSelected: _selectedStatus == 'Pending',
                      onTap: () => setState(() {
                        _selectedStatus = 'Pending';
                        _displayedLimit = 20;
                      }),
                    ),
                    if (_activeTab == 'Complaints') ...[
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: AppTranslations.getStatus('assigned', lang),
                        color: const Color(0xFF0284C7),
                        isSelected: _selectedStatus == 'Assigned',
                        onTap: () => setState(() {
                          _selectedStatus = 'Assigned';
                          _displayedLimit = 20;
                        }),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: '${AppTranslations.getStatus("inprogress", lang)} (${AppTranslations.formatDigits(inProgressCount, lang)})',
                      color: const Color(0xFFD97706),
                      isSelected: _selectedStatus == 'InProgress',
                      onTap: () => setState(() {
                        _selectedStatus = 'InProgress';
                        _displayedLimit = 20;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: '${AppTranslations.getStatus("resolved", lang)} (${AppTranslations.formatDigits(resolvedCount, lang)})',
                      color: const Color(0xFF16A34A),
                      isSelected: _selectedStatus == 'Resolved',
                      onTap: () => setState(() {
                        _selectedStatus = 'Resolved';
                        _displayedLimit = 20;
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // 5. Main Complaints List
            Expanded(
              child: _isLoading
                  ? const AppShimmerList(count: 6)
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.assignment_late_outlined, size: 28, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                lang == 'mr'
                                    ? 'कोणतीही तक्रार आढळली नाही'
                                    : (lang == 'hi' ? 'कोई शिकायत नहीं मिली' : 'No matching requests found'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang == 'mr'
                                    ? 'नवीन तक्रार अथवा विनंती नोंदवा'
                                    : (lang == 'hi' ? 'नई शिकायत या अनुरोध दर्ज करें' : 'Try clearing filters or register a new request'),
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final created = await NewComplaintBottomSheet.show(
                                    context,
                                    initialTab: _activeTab,
                                  );
                                  if (created == true) {
                                    _fetchComplaints();
                                  }
                                },
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(
                                  _activeTab == 'Complaints'
                                      ? (lang == 'mr'
                                          ? 'नवीन तक्रार नोंदवा'
                                          : (lang == 'hi' ? 'नई शिकायत दर्ज करें' : 'Add New Complaint'))
                                      : (lang == 'mr'
                                          ? 'नवीन वैयक्तिक विनंती'
                                          : (lang == 'hi' ? 'नया व्यक्तिगत अनुरोध' : 'Add Personal Request')),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchComplaints,
                          color: const Color(0xFF0284C7),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            itemCount: _visibleComplaints.length +
                                (filtered.isNotEmpty ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _visibleComplaints.length) {
                                return AppLoadMoreFooter(
                                  currentCount: _visibleComplaints.length,
                                  totalCount: filtered.length,
                                  pageSize: 20,
                                  onLoadMore: () {
                                    setState(() => _displayedLimit += 20);
                                  },
                                  label: lang == 'mr' ? 'तक्रारी' : (lang == 'hi' ? 'शिकायतें' : 'complaints'),
                                  isMarathi: isMr,
                                );
                              }
                              final item = _visibleComplaints[index];
                              return _ComplaintCard(
                                complaint: item,
                                isMr: isMr,
                                lang: lang,
                                onTap: () => _openDetailSheet(item, isMr),
                                onQuickStatusTap: () => _openDetailSheet(item, isMr),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),

        // Floating Action Button
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final created = await NewComplaintBottomSheet.show(
              context,
              initialTab: _activeTab,
            );
            if (created == true) {
              _fetchComplaints();
            }
          },
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            _activeTab == 'Complaints'
                ? (lang == 'mr' ? 'नवीन तक्रार' : (lang == 'hi' ? 'नई शिकायत' : 'New Complaint'))
                : (lang == 'mr' ? 'नवीन विनंती' : (lang == 'hi' ? 'नया अनुरोध' : 'New Personal Request')),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-COMPONENTS
// ---------------------------------------------------------------------------

/// Top Navigation Tab Button (Area Complaints vs Personal Help)
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final int badgeCount;
  final String lang;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.badgeCount,
    this.lang = 'en',
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppTranslations.formatDigits(badgeCount, lang),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive KPI Metric Card
class _KpiStatCard extends StatelessWidget {
  final String label;
  final int count;
  final String lang;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _KpiStatCard({
    required this.label,
    required this.count,
    this.lang = 'en',
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppTranslations.formatDigits(count, lang),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? color : const Color(0xFF0F172A),
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status Filter Pill Chip
class _FilterPill extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF0284C7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            width: 1.1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

/// Rich Complaint Card matching Nagarsevak-Managment
class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool isMr;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onQuickStatusTap;

  const _ComplaintCard({
    required this.complaint,
    this.isMr = false,
    this.lang = 'en',
    required this.onTap,
    required this.onQuickStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBorder;
    Color cardBg;
    Color statusColor;

    switch (complaint.status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        cardBorder = const Color(0xFFBBF7D0);
        cardBg = const Color(0xFFF0FDF4);
        statusColor = const Color(0xFF16A34A);
        break;
      case 'inprogress':
        cardBorder = const Color(0xFFFDE68A);
        cardBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFD97706);
        break;
      case 'assigned':
        cardBorder = const Color(0xFFBAE6FD);
        cardBg = const Color(0xFFF0F9FF);
        statusColor = const Color(0xFF0284C7);
        break;
      default:
        cardBorder = const Color(0xFFFECACA);
        cardBg = const Color(0xFFFEF2F2);
        statusColor = const Color(0xFFDC2626);
    }

    final statusLabel = AppTranslations.getStatus(complaint.status, lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status & Category Badges Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppTranslations.getComplaintType(complaint.category, lang).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title with dynamic on-the-fly translation
              AppTranslatedText(
                complaint.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.25,
                ),
              ),

              if (complaint.description.isNotEmpty) ...[
                const SizedBox(height: 5),
                AppTranslatedText(
                  complaint.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Citizen Contact Badge (Name & Phone) with Direct Call & WhatsApp Buttons
              if (complaint.citizenName != null && complaint.citizenName!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          complaint.citizenName! +
                              (complaint.citizenMobile != null && complaint.citizenMobile!.isNotEmpty
                                  ? ' • ${AppTranslations.formatDigits(complaint.citizenMobile!, lang)}'
                                  : ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      if (complaint.citizenMobile != null && complaint.citizenMobile!.isNotEmpty) ...[
                        InkWell(
                          onTap: () async {
                            final uri = Uri.parse('tel:${complaint.citizenMobile}');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(Icons.phone_rounded, size: 16, color: Color(0xFF16A34A)),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final clean = complaint.citizenMobile!.replaceAll(RegExp(r'\D'), '');
                            final text = Uri.encodeComponent(
                                'Namaskar, regarding your request "${complaint.title}" (#${complaint.id}), our office has registered the update.');
                            final uri = Uri.parse('https://wa.me/91$clean?text=$text');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(Icons.chat_rounded, size: 16, color: Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Added By Staff Badge (matching Nagarsevak-Managment ComplaintList.tsx line 730)
              if (complaint.addedByStaffName != null && complaint.addedByStaffName!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_pin_rounded, size: 13, color: Color(0xFF475569)),
                      const SizedBox(width: 5),
                      Text(
                        '${lang == "mr" ? "नोंदणीकर्ता:" : (lang == "hi" ? "दर्जकर्ता:" : "Added By:")} ${complaint.addedByStaffName}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Staff Assigned Badge
              if (complaint.assignedStaffName != null && complaint.assignedStaffName!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, size: 13, color: Color(0xFF0284C7)),
                      const SizedBox(width: 5),
                      Text(
                        '${lang == "mr" ? "नियुक्त:" : (lang == "hi" ? "नियुक्त:" : "Assigned:")} ${complaint.assignedStaffName}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              // Bottom Info Bar: Date, Location & Update Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.formatDigits(DateFormat('MMM d, h:mm a').format(complaint.createdAt), lang),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        if (complaint.area != null && complaint.area!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              AppTranslations.getAreaName(complaint.area!, lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quick Action arrow
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang == 'mr' ? 'तपशील' : (lang == 'hi' ? 'विवरण' : 'Details'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF0284C7)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


