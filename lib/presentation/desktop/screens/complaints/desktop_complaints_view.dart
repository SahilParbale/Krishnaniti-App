import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nagarsevak_mobile/data/models/complaint_model.dart';
import 'package:nagarsevak_mobile/data/repositories/complaints_repository.dart';
import 'package:nagarsevak_mobile/presentation/desktop/shell/desktop_sidebar.dart';
import 'package:nagarsevak_mobile/presentation/screens/complaints/new_complaint_screen.dart';
import 'package:nagarsevak_mobile/presentation/screens/complaints/complaint_detail_screen.dart';
import 'package:nagarsevak_mobile/presentation/screens/complaints/complaint_report_generator.dart';
import 'package:nagarsevak_mobile/presentation/widgets/app_dropdown.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/core/services/translation_service.dart';
import 'package:nagarsevak_mobile/presentation/providers/language_provider.dart';

/// Desktop Complaints & Requests View matching ComplaintList.tsx 1:1:
/// - Sticky Header with Title, Found badge, Help button, and + New Request button
/// - Area Complaints vs Personal Help Tab Navigation
/// - Grid vs Report View Mode Toggle
/// - Search, Area Filter, and Date Filter
/// - Status Filter Pills (All, Pending, Assigned, InProgress, Resolved)
/// - Responsive 3-Column Card Grid with exact color coding per status
class DesktopComplaintsView extends ConsumerStatefulWidget {
  const DesktopComplaintsView({super.key});

  @override
  ConsumerState<DesktopComplaintsView> createState() => _DesktopComplaintsViewState();
}

class _DesktopComplaintsViewState extends ConsumerState<DesktopComplaintsView> {
  String _activeTab = 'Complaints'; // 'Complaints' | 'Personal Help'
  String _filterStatus = 'All'; // 'All', 'Pending', 'Assigned', 'InProgress', 'Resolved'
  String _viewMode = 'grid'; // 'grid' | 'table'
  String _searchQuery = '';
  String _selectedArea = 'All';
  String _selectedDate = 'All';
  ComplaintModel? _selectedComplaint;

  bool _loading = true;
  List<ComplaintModel> _complaints = [];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final repo = ref.read(complaintsRepoProvider);
      final data = await repo.getComplaints(limit: 100);
      if (mounted) {
        setState(() {
          _complaints = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _uniqueAreas {
    final areas = <String>{};
    for (final c in _complaints) {
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
    for (final c in _complaints) {
      dates.add(DateFormat('MMM d, yyyy').format(c.createdAt));
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return ['All', ...sorted];
  }

  List<ComplaintModel> get _filteredComplaints {
    return _complaints.where((c) {
      // Tab filter
      if (_activeTab == 'Personal Help') {
        if (c.category.toLowerCase() != 'personal help' && !c.id.startsWith('pr-')) {
          return false;
        }
      } else {
        if (c.category.toLowerCase() == 'personal help' || c.id.startsWith('pr-')) {
          return false;
        }
      }

      // Status filter
      if (_filterStatus != 'All') {
        if (c.status.toLowerCase() != _filterStatus.toLowerCase()) {
          return false;
        }
      }

      // Area filter
      if (_selectedArea != 'All') {
        final matchesArea = (c.area != null && c.area == _selectedArea) ||
            (c.location != null && c.location == _selectedArea);
        if (!matchesArea) return false;
      }

      // Date filter matching ComplaintList.tsx:371
      if (_selectedDate != 'All') {
        final formattedDate = DateFormat('MMM d, yyyy').format(c.createdAt);
        if (!formattedDate.toLowerCase().contains(_selectedDate.toLowerCase())) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchTitle = c.title.toLowerCase().contains(q);
        final matchDesc = c.description.toLowerCase().contains(q);
        final matchCitizen = (c.citizenName ?? '').toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchCitizen) return false;
      }

      return true;
    }).toList();
  }

  void _openNewComplaintModal() {
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
      if (res == true) _loadComplaints(showLoading: false);
    });
  }

  void _openComplaintDetail(ComplaintModel complaint) {
    setState(() {
      _selectedComplaint = complaint;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedComplaint != null) {
      return ComplaintDetailScreen(
        complaint: _selectedComplaint!,
        onBack: () {
          setState(() => _selectedComplaint = null);
          _loadComplaints(showLoading: false);
        },
      );
    }

    final lang = ref.watch(desktopLanguageProvider);
    final isMr = lang == 'mr';
    final items = _filteredComplaints;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // bg-slate-50
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row
            _buildHeader(lang, items.length),

            const SizedBox(height: 16),

            // 2. Tabs & View Toggle Row
            _buildTabsAndViewToggle(lang),

            const SizedBox(height: 16),

            // 3. Search and Filters Card
            _buildFilterCard(lang),

            const SizedBox(height: 24),

            // 4. Content: Loading / Empty / Grid or Table
            if (_loading)
              _buildLoadingGrid()
            else if (items.isEmpty)
              _buildEmptyState(isMr)
            else if (_viewMode == 'table')
              _buildComplaintTable(items, lang)
            else
              _buildComplaintGrid(items, lang),
          ],
        ),
      ),
    );
  }

  // --- Header Row ---
  Widget _buildHeader(String lang, int foundCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.t('complaints.title', lang: lang),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    AppTranslations.t('complaints.subtitle', lang: lang),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      '${lang == "mr" ? "सापडले" : (lang == "hi" ? "मिले" : "Found")}: $foundCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action Buttons: Download Report + New Request / New Complaint
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ComplaintReportGenerator.generateAndPrintReport(
                  context: context,
                  complaints: _filteredComplaints,
                  statusFilter: _filterStatus,
                  areaFilter: _selectedArea,
                  title: _activeTab == 'Personal Help'
                      ? (lang == 'mr'
                          ? 'वैयक्तिक मदत विनंती अहवाल'
                          : (lang == 'hi' ? 'व्यक्तिगत अनुरोध रिपोर्ट' : 'Personal Requests Report'))
                      : (lang == 'mr'
                          ? 'प्रभागातील तक्रारी अहवाल'
                          : (lang == 'hi' ? 'वार्ड शिकायतें रिपोर्ट' : 'Area Complaints Report')),
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                lang == 'mr' ? 'अहवाल डाउनलोड करा' : (lang == 'hi' ? 'रिपोर्ट डाउनलोड करें' : 'Download Report'),
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
              onPressed: _openNewComplaintModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _activeTab == 'Personal Help'
                        ? (lang == 'mr' ? 'नवीन विनंती' : (lang == 'hi' ? 'नया अनुरोध' : 'New Request'))
                        : (lang == 'mr' ? 'नवीन तक्रार' : (lang == 'hi' ? 'नई शिकायत' : 'New Complaint')),
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

  // --- Tabs & View Toggle Row ---
  Widget _buildTabsAndViewToggle(String lang) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildTabButton(
                title: AppTranslations.t('complaints.tabs.area', lang: lang),
                isActive: _activeTab == 'Complaints',
                onTap: () => setState(() => _activeTab = 'Complaints'),
              ),
              const SizedBox(width: 24),
              _buildTabButton(
                title: AppTranslations.t('complaints.tabs.personal', lang: lang),
                isActive: _activeTab == 'Personal Help',
                onTap: () => setState(() => _activeTab = 'Personal Help'),
              ),
            ],
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
                  label: lang == 'mr' ? 'ग्रिड' : (lang == 'hi' ? 'ग्रिड' : 'Grid'),
                  isActive: _viewMode == 'grid',
                  onTap: () => setState(() => _viewMode = 'grid'),
                ),
                const SizedBox(width: 4),
                _buildViewToggleButton(
                  icon: Icons.table_rows_rounded,
                  label: lang == 'mr' ? 'तक्ता' : (lang == 'hi' ? 'तालिका' : 'Table'),
                  isActive: _viewMode == 'table',
                  onTap: () => setState(() => _viewMode = 'table'),
                ),
              ],
            ),
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

  Widget _buildComplaintTable(List<ComplaintModel> items, String lang) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(AppTranslations.getReportColumn('title', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('citizen', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('category', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('area', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('status', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(AppTranslations.getReportColumn('date', lang), style: const TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text(lang == 'mr' ? 'कृती' : (lang == 'hi' ? 'कार्रवाई' : 'Actions'), style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: items.map((c) {
            final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(c.createdAt);
            return DataRow(
              cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: AppTranslatedText(
                      c.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(c.citizenName ?? '-')),
                DataCell(_buildCategoryBadge(c.category)),
                DataCell(Text(c.area ?? '-')),
                DataCell(_buildStatusBadge(c.status, lang)),
                DataCell(Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
                    tooltip: 'View Details',
                    onPressed: () => _openComplaintDetail(c),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF0284C7) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // --- Filter Bar Card ---
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
          // Row 1: Search Inputs
          // Row 1: Search + Area Dropdown + Date Dropdown
          Row(
            children: [
              // 1. General Search
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: lang == 'mr'
                        ? 'तक्रार, नागरिक किंवा फोन शोधा...'
                        : (lang == 'hi' ? 'शिकायत, नागरिक या फोन खोजें...' : 'Search complaints by title, description...'),
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              const SizedBox(width: 12),

              // 2. Area Filter Dropdown
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
                            ? (lang == 'mr' ? 'सर्व भाग' : (lang == 'hi' ? 'सभी क्षेत्र' : 'All Areas'))
                            : area,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedArea = val);
                  },
                ),
              ),
              const SizedBox(width: 12),

              // 3. Date Filter Dropdown
              Expanded(
                flex: 1,
                child: AppDropdown<String>(
                  value: _selectedDate,
                  height: 42,
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  items: _uniqueDates.map((date) {
                    return DropdownMenuItem(
                      value: date,
                      child: Text(
                        date == 'All'
                            ? (lang == 'mr' ? 'सर्व तारखा' : (lang == 'hi' ? 'सभी तिथियां' : 'All Dates'))
                            : date,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDate = val);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Status Pills
          Row(
            children: [
              _buildStatusPill('All', AppTranslations.t('common.all', lang: lang)),
              _buildStatusPill('Pending', AppTranslations.getStatus('pending', lang)),
              _buildStatusPill('Assigned', AppTranslations.getStatus('assigned', lang)),
              _buildStatusPill('InProgress', AppTranslations.getStatus('inprogress', lang)),
              _buildStatusPill('Resolved', AppTranslations.getStatus('resolved', lang)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String statusKey, String label) {
    final isSelected = _filterStatus == statusKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _filterStatus = statusKey),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            ),
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

  // --- Complaint Grid (matching ComplaintList.tsx lines 681-750) ---
  Widget _buildComplaintGrid(List<ComplaintModel> items, String lang) {
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
            final complaint = items[index];
            return _buildComplaintCard(complaint, lang);
          },
        );
      },
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint, String lang) {
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);

    final statusLower = complaint.status.toLowerCase();
    if (statusLower == 'resolved') {
      bgColor = const Color(0xFFF0FDF4); // green-50
      borderColor = const Color(0xFF86EFAC); // green-300
    } else if (statusLower == 'inprogress' || statusLower == 'assigned') {
      bgColor = const Color(0xFFFEFCE8); // yellow-50
      borderColor = const Color(0xFFFDE047); // yellow-300
    } else if (statusLower == 'pending') {
      bgColor = const Color(0xFFFEF2F2); // red-50
      borderColor = const Color(0xFFFCA5A5); // red-300
    }

    final dateStr = DateFormat('MMM d, h:mm a').format(complaint.createdAt);

    return InkWell(
      onTap: () => _openComplaintDetail(complaint),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
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
            // Top Row: Status badge & Category badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(complaint.status, lang),
                _buildCategoryBadge(complaint.category),
              ],
            ),

            const SizedBox(height: 8),

            // Citizen Info Tag (if available)
            if (complaint.citizenName != null && complaint.citizenName!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${complaint.citizenName}${complaint.citizenMobile != null ? ' | ${complaint.citizenMobile}' : ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Assigned Staff Tag (if assigned)
            if (complaint.assignedStaffName != null && complaint.assignedStaffName!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF), // blue-50
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBAE6FD)), // blue-200
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge_outlined, size: 12, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        complaint.assignedStaffName!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Complaint Title with on-the-fly dynamic translation
            AppTranslatedText(
              complaint.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A), // slate-900
              ),
            ),

            const SizedBox(height: 4),

            // Complaint Description with on-the-fly dynamic translation
            Expanded(
              child: AppTranslatedText(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B), // slate-500
                  height: 1.35,
                ),
              ),
            ),

            // Card Footer: Date & Location
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
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  if (complaint.area != null || complaint.location != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            complaint.area ?? complaint.location ?? '',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildStatusBadge(String status, String lang) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    Color border = const Color(0xFFCBD5E1);

    final lower = status.toLowerCase();
    if (lower == 'pending') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      border = const Color(0xFFFECACA);
    } else if (lower == 'assigned') {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF4338CA);
      border = const Color(0xFFC7D2FE);
    } else if (lower == 'inprogress') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
      border = const Color(0xFFFDE68A);
    } else if (lower == 'resolved') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      border = const Color(0xFFBBF7D0);
    }

    final label = AppTranslations.getStatus(status, lang);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      ),
    );
  }

  // --- Skeleton Loading Grid ---
  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.55,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 80, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Container(height: 18, width: 160, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            Container(height: 14, width: double.infinity, color: const Color(0xFFF1F5F9)),
            const Spacer(),
            Container(height: 12, width: 100, color: const Color(0xFFF1F5F9)),
          ],
        ),
      ),
    );
  }

  // --- Empty State ---
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
            'No complaints found',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filter options',
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
