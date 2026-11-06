import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../providers/auth_provider.dart';
import 'new_complaint_screen.dart';
import 'complaint_detail_screen.dart';
import '../../navigation/app_drawer.dart';

class ComplaintsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  final ValueChanged<int>? onTabChange;

  const ComplaintsScreen({super.key, this.onBackToHome, this.onTabChange});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen> {
  // Primary Tabs matching Nagarsevak-Managment: 'Complaints' | 'Personal Help'
  String _activeTab = 'Complaints'; 

  // Status Filter: 'All', 'Pending', 'Assigned', 'InProgress', 'Resolved'
  String _selectedStatus = 'All';

  // Area / Ward Filter
  String _selectedArea = 'All';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  // Area Complaints Dataset
  List<ComplaintModel> _areaComplaints = [];

  // Personal Help Requests Dataset
  List<ComplaintModel> _personalRequests = [];

  // Default Mock Area Complaints matching Nagarsevak-Managment
  final List<ComplaintModel> _defaultAreaComplaints = [
    ComplaintModel(
      id: 'REQ-10234',
      title: 'Street light not working near lane corner',
      description: 'Street light lamp fixture damaged near lane 4 corner, dark and dangerous at night.',
      category: 'StreetLight',
      status: 'Pending',
      ward: 'Ward 12',
      area: 'Lane 4',
      location: 'Ward 12, Lane 4, Sector 2',
      citizenName: 'Ramesh Patil',
      citizenMobile: '9876543210',
      assignedTo: 'staff-1',
      assignedStaffName: 'Sunil Shinde (Electrical JE)',
      assignedStaffMobile: '9822012345',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      progressUpdates: [
        ComplaintProgressUpdate(
          note: 'Complaint registered by citizen via WhatsApp helpline. Forwarded to electrical maintenance wing.',
          status: 'Pending',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          updatedBy: 'Citizen Helpdesk',
        ),
      ],
    ),
    ComplaintModel(
      id: 'REQ-10233',
      title: 'Garbage not collected for 2 consecutive days',
      description: 'Municipal waste disposal vehicle missed sector B collection point. Garbage overflowing.',
      category: 'Cleaning',
      status: 'InProgress',
      ward: 'Ward 12',
      area: 'Sector B',
      location: 'Ward 12, Sector B Market Road',
      citizenName: 'Sushma Kulkarni',
      citizenMobile: '9876543211',
      assignedTo: 'staff-2',
      assignedStaffName: 'Santosh Gaikwad (Sanitation Sup.)',
      assignedStaffMobile: '9822023456',
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      progressUpdates: [
        ComplaintProgressUpdate(
          note: 'Sanitation squad deployed with mini compactor vehicle. Garbage clearing initiated at Sector B corner.',
          status: 'InProgress',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          updatedBy: 'Santosh Gaikwad (Sanitation Sup.)',
        ),
      ],
    ),
    ComplaintModel(
      id: 'REQ-10232',
      title: 'Drinking water pipeline leakage on main road',
      description: 'Underground drinking water supply pipeline joint leaking heavily, water wasting.',
      category: 'Water',
      status: 'Resolved',
      ward: 'Ward 12',
      area: 'MG Road',
      location: 'Ward 12, MG Road Junction',
      citizenName: 'Amit Deshmukh',
      citizenMobile: '9876543212',
      assignedTo: 'staff-3',
      assignedStaffName: 'Pradeep Joshi (Water Works Dept)',
      assignedStaffMobile: '9822034567',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      progressUpdates: [
        ComplaintProgressUpdate(
          note: 'Excavation completed. Main distribution pipe fracture identified. Replacement collar clamp ordered.',
          status: 'InProgress',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          updatedBy: 'Pradeep Joshi (Water Works Dept)',
        ),
        ComplaintProgressUpdate(
          note: 'New collar clamp installed and pressure tested. Trench refilled with gravel. Water supply resumed.',
          status: 'Resolved',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          updatedBy: 'Pradeep Joshi (Water Works Dept)',
        ),
      ],
    ),
    ComplaintModel(
      id: 'REQ-10231',
      title: 'Deep pothole repair on Station Road',
      description: 'Rainwater filled depression causing severe vehicular congestion and bike skids.',
      category: 'Road',
      status: 'Assigned',
      ward: 'Ward 12',
      area: 'Station Rd',
      location: 'Ward 12, Station Road Sector 3',
      citizenName: 'Sunita Shinde',
      citizenMobile: '9876543213',
      assignedTo: 'staff-4',
      assignedStaffName: 'Anand Jadhav (Road Engineering)',
      assignedStaffMobile: '9822045678',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ComplaintModel(
      id: 'REQ-10230',
      title: 'Stormwater drainage line clogging & desilting',
      description: 'Monsoon gutter blockage cleared by sanitation squad with suction machinery.',
      category: 'Drainage',
      status: 'Resolved',
      ward: 'Ward 12',
      area: 'Shanti Nagar',
      location: 'Ward 12, Shanti Nagar Lane 3',
      citizenName: 'Vikas Jadhav',
      citizenMobile: '9876543214',
      assignedTo: 'staff-2',
      assignedStaffName: 'Santosh Gaikwad (Sanitation Sup.)',
      assignedStaffMobile: '9822023456',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      progressUpdates: [
        ComplaintProgressUpdate(
          note: 'Stormwater line suction vehicle deployed. Silt blockage of 12 meters removed. Flow returned to normal.',
          status: 'Resolved',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          updatedBy: 'Santosh Gaikwad (Sanitation Sup.)',
        ),
      ],
    ),
    ComplaintModel(
      id: 'REQ-10229',
      title: 'Overhanging tree branch trimming near bus stop',
      description: 'Heavy banyan branches touching 11KV overhead power cable, risk of short circuit.',
      category: 'StreetLight',
      status: 'Pending',
      ward: 'Ward 12',
      area: 'Sector 4',
      location: 'Ward 12, Sector 4 Bus Terminus',
      citizenName: 'Prakash More',
      citizenMobile: '9876543215',
      assignedTo: 'staff-1',
      assignedStaffName: 'Sunil Shinde (Electrical JE)',
      assignedStaffMobile: '9822012345',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  // Default Mock Personal Requests matching Nagarsevak-Managment
  final List<ComplaintModel> _defaultPersonalRequests = [
    ComplaintModel(
      id: 'PR-5012',
      title: 'Financial aid application for open heart surgery',
      description: 'Parvati Kamble requires Nagarsevak recommendation letter for CM Relief Fund at Sancheti Hospital.',
      category: 'Medical Aid',
      status: 'InProgress',
      ward: 'Ward 12',
      area: 'Shivaji Nagar',
      location: 'Ward 12, Shivaji Nagar',
      citizenName: 'Parvati Bai Kamble',
      citizenMobile: '9822011223',
      assignedTo: 'staff-5',
      assignedStaffName: 'Prashant Kadam (Welfare Desk)',
      assignedStaffMobile: '9822056789',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      progressUpdates: [
        ComplaintProgressUpdate(
          note: 'Hospital estimate verified. Application drafted for Chief Minister Medical Relief Fund.',
          status: 'InProgress',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          updatedBy: 'Prashant Kadam (Welfare Desk)',
        ),
      ],
    ),
    ComplaintModel(
      id: 'PR-5011',
      title: 'Higher education engineering scholarship recommendation',
      description: 'Needy engineering student requesting financial scholarship endorsement for college fees.',
      category: 'Scholarship',
      status: 'Pending',
      ward: 'Ward 12',
      area: 'Sector 3',
      location: 'Ward 12, Sector 3',
      citizenName: 'Rohit Vinod Pawar',
      citizenMobile: '9822044556',
      assignedTo: 'staff-5',
      assignedStaffName: 'Prashant Kadam (Welfare Desk)',
      assignedStaffMobile: '9822056789',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ComplaintModel(
      id: 'PR-5010',
      title: 'Ration card name addition & yellow card issue',
      description: 'Citizen needs facilitation at Food & Civil Supplies Tehsildar office for BPL beneficiary card.',
      category: 'Ration Card',
      status: 'Resolved',
      ward: 'Ward 12',
      area: 'Lane 2',
      location: 'Ward 12, Lane 2',
      citizenName: 'Anita Suresh Kadam',
      citizenMobile: '9822077889',
      assignedTo: 'staff-5',
      assignedStaffName: 'Prashant Kadam (Welfare Desk)',
      assignedStaffMobile: '9822056789',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      progressUpdates: [
        ComplaintProgressUpdate(
          note: 'Application verified and submitted to Tehsildar office.',
          status: 'InProgress',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          updatedBy: 'Prashant Kadam (Welfare Desk)',
        ),
        ComplaintProgressUpdate(
          note: 'Tehsildar office verification completed. New ration card endorsement slip issued to citizen.',
          status: 'Resolved',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          updatedBy: 'Prashant Kadam (Welfare Desk)',
        ),
      ],
    ),
    ComplaintModel(
      id: 'PR-5009',
      title: 'Sanjay Gandhi Niradhar pension scheme registration',
      description: 'Elderly widow citizen assistance for monthly government pension scheme documentation.',
      category: 'Pension Scheme',
      status: 'Resolved',
      ward: 'Ward 12',
      area: 'Sector 5',
      location: 'Ward 12, Sector 5',
      citizenName: 'Gangubai Shinde',
      citizenMobile: '9822099001',
      assignedTo: 'staff-5',
      assignedStaffName: 'Prashant Kadam (Welfare Desk)',
      assignedStaffMobile: '9822056789',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ComplaintModel(
      id: 'PR-5008',
      title: 'Character & residence bonafide recommendation letter',
      description: 'Citizen requires official Nagarsevak recommendation letter for government recruitment verification.',
      category: 'Recommendation',
      status: 'Pending',
      ward: 'Ward 12',
      area: 'Sector 4',
      location: 'Ward 12, Sector 4',
      citizenName: 'Swapnil Mane',
      citizenMobile: '9822033445',
      assignedTo: 'staff-5',
      assignedStaffName: 'Prashant Kadam (Welfare Desk)',
      assignedStaffMobile: '9822056789',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _areaComplaints = List.from(_defaultAreaComplaints);
    _personalRequests = List.from(_defaultPersonalRequests);
    _fetchComplaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(complaintsRepoProvider);
      final results = await repo.getComplaints();

      if (mounted) {
        setState(() {
          if (results.isNotEmpty) {
            // Split by type if personal help vs area complaints
            final area = <ComplaintModel>[];
            final personal = <ComplaintModel>[];
            for (final item in results) {
              if (item.category.toLowerCase().contains('personal') ||
                  item.category.toLowerCase().contains('help') ||
                  item.category.toLowerCase().contains('scholar') ||
                  item.category.toLowerCase().contains('medical')) {
                personal.add(item);
              } else {
                area.add(item);
              }
            }
            if (area.isNotEmpty) _areaComplaints = area;
            if (personal.isNotEmpty) _personalRequests = personal;
          }
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

  // Update Status directly in memory & database
  Future<void> _updateStatus(ComplaintModel complaint, String newStatus) async {
    try {
      await ref.read(complaintsRepoProvider).updateStatus(complaint.id, newStatus);
    } catch (_) {}

    setState(() {
      final updater = (ComplaintModel c) {
        if (c.id == complaint.id) {
          return ComplaintModel(
            id: c.id,
            title: c.title,
            description: c.description,
            category: c.category,
            status: newStatus,
            ward: c.ward,
            area: c.area,
            location: c.location,
            citizenName: c.citizenName,
            citizenMobile: c.citizenMobile,
            assignedStaffName: c.assignedStaffName,
            photos: c.photos,
            createdAt: c.createdAt,
            tenantId: c.tenantId,
          );
        }
        return c;
      };

      _areaComplaints = _areaComplaints.map(updater).toList();
      _personalRequests = _personalRequests.map(updater).toList();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ${complaint.id} status to $newStatus'),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Open Full Complaint Details Page matching ComplaintDetail.tsx
  void _openDetailSheet(ComplaintModel complaint, bool isMr) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintDetailScreen(complaint: complaint),
      ),
    ).then((_) {
      _fetchComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
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
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMr ? 'तक्रारी आणि विनंती' : 'Requests & Complaints',
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                isMr ? 'नागरिकांच्या समस्या आणि विनंती व्यवस्थापन' : 'Manage citizen problems & requests',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          actions: [
            // Found Badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  isMr ? 'एकूण: ${filtered.length}' : 'Found: ${filtered.length}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 21),
              tooltip: 'Refresh',
              onPressed: _fetchComplaints,
            ),
            const SizedBox(width: 4),
          ],
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
                        label: isMr ? 'परिसरातील तक्रारी' : 'Area Complaints',
                        icon: Icons.domain_rounded,
                        badgeCount: _areaComplaints.length,
                        isSelected: _activeTab == 'Complaints',
                        onTap: () {
                          setState(() {
                            _activeTab = 'Complaints';
                            _selectedStatus = 'All';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _TabButton(
                        label: isMr ? 'वैयक्तिक विनंती' : 'Personal Help',
                        icon: Icons.volunteer_activism_rounded,
                        badgeCount: _personalRequests.length,
                        isSelected: _activeTab == 'Personal Help',
                        onTap: () {
                          setState(() {
                            _activeTab = 'Personal Help';
                            _selectedStatus = 'All';
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
                      label: isMr ? 'सर्व' : 'Total',
                      count: totalCount,
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFF0F9FF),
                      isSelected: _selectedStatus == 'All',
                      onTap: () => setState(() => _selectedStatus = 'All'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiStatCard(
                      label: isMr ? 'प्रलंबित' : 'Pending',
                      count: pendingCount,
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEF2F2),
                      isSelected: _selectedStatus == 'Pending',
                      onTap: () => setState(() => _selectedStatus = 'Pending'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiStatCard(
                      label: isMr ? 'चालू' : 'In Progress',
                      count: inProgressCount,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      isSelected: _selectedStatus == 'InProgress',
                      onTap: () => setState(() => _selectedStatus = 'InProgress'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiStatCard(
                      label: isMr ? 'सोडवले' : 'Resolved',
                      count: resolvedCount,
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFF0FDF4),
                      isSelected: _selectedStatus == 'Resolved',
                      onTap: () => setState(() => _selectedStatus = 'Resolved'),
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
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: isMr ? 'तक्रार, नागरिक किंवा फोन शोधा...' : 'Search title, citizen, phone...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 19),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
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

                  // Area Filter Dropdown
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _selectedArea == 'All' ? const Color(0xFFF8FAFC) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedArea == 'All' ? const Color(0xFFE2E8F0) : const Color(0xFF0284C7),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedArea,
                        icon: Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: _selectedArea == 'All' ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _selectedArea == 'All' ? const Color(0xFF334155) : const Color(0xFF0284C7),
                        ),
                        items: _availableAreas.map((area) {
                          return DropdownMenuItem<String>(
                            value: area,
                            child: Text(area == 'All' ? (isMr ? 'सर्व भाग' : 'All Areas') : area),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedArea = val);
                        },
                      ),
                    ),
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
                      label: isMr ? 'सर्व (${_currentList.length})' : 'All (${_currentList.length})',
                      isSelected: _selectedStatus == 'All',
                      onTap: () => setState(() => _selectedStatus = 'All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: isMr ? 'प्रलंबित ($pendingCount)' : 'Pending ($pendingCount)',
                      color: const Color(0xFFDC2626),
                      isSelected: _selectedStatus == 'Pending',
                      onTap: () => setState(() => _selectedStatus = 'Pending'),
                    ),
                    if (_activeTab == 'Complaints') ...[
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: isMr ? 'सोपवलेले' : 'Assigned',
                        color: const Color(0xFF0284C7),
                        isSelected: _selectedStatus == 'Assigned',
                        onTap: () => setState(() => _selectedStatus = 'Assigned'),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: isMr ? 'काम चालू ($inProgressCount)' : 'In Progress ($inProgressCount)',
                      color: const Color(0xFFD97706),
                      isSelected: _selectedStatus == 'InProgress',
                      onTap: () => setState(() => _selectedStatus = 'InProgress'),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: isMr ? 'सोडवलेले ($resolvedCount)' : 'Resolved ($resolvedCount)',
                      color: const Color(0xFF16A34A),
                      isSelected: _selectedStatus == 'Resolved',
                      onTap: () => setState(() => _selectedStatus = 'Resolved'),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // 5. Main Complaints List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0284C7)),
                    )
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
                                isMr ? 'कोणतीही तक्रार आढळली नाही' : 'No matching requests found',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isMr ? 'वेगळा फिल्टर किंवा शोध शब्द वापरून पहा' : 'Try clearing filters or search query',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchComplaints,
                          color: const Color(0xFF0284C7),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _ComplaintCard(
                                complaint: item,
                                isMr: isMr,
                                onTap: () => _openDetailSheet(item, isMr),
                                onQuickStatusTap: () => _openDetailSheet(item, isMr),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),

        // Floating Action Button (+ New Request) matching Nagarsevak-Managment
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NewComplaintScreen(),
              ),
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
            isMr ? 'नवीन तक्रार' : 'New Request',
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
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.badgeCount,
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
                '$badgeCount',
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
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _KpiStatCard({
    required this.label,
    required this.count,
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
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? color : const Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF64748B),
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
  final VoidCallback onTap;
  final VoidCallback onQuickStatusTap;

  const _ComplaintCard({
    required this.complaint,
    required this.isMr,
    required this.onTap,
    required this.onQuickStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBorder;
    Color cardBg;
    Color statusColor;
    String statusLabel;

    switch (complaint.status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        cardBorder = const Color(0xFFBBF7D0);
        cardBg = const Color(0xFFF0FDF4);
        statusColor = const Color(0xFF16A34A);
        statusLabel = isMr ? 'सोडवलेले' : 'Resolved';
        break;
      case 'inprogress':
        cardBorder = const Color(0xFFFDE68A);
        cardBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFD97706);
        statusLabel = isMr ? 'काम चालू' : 'In Progress';
        break;
      case 'assigned':
        cardBorder = const Color(0xFFBAE6FD);
        cardBg = const Color(0xFFF0F9FF);
        statusColor = const Color(0xFF0284C7);
        statusLabel = isMr ? 'सोपवलेले' : 'Assigned';
        break;
      default:
        cardBorder = const Color(0xFFFECACA);
        cardBg = const Color(0xFFFEF2F2);
        statusColor = const Color(0xFFDC2626);
        statusLabel = isMr ? 'प्रलंबित' : 'Pending';
    }

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
                      complaint.category.toUpperCase(),
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

              // Title
              Text(
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
                Text(
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
                                  ? ' • ${complaint.citizenMobile}'
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
                        'Assigned: ${complaint.assignedStaffName}',
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
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(complaint.createdAt),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      if (complaint.area != null && complaint.area!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            complaint.area!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ],
                  ),

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
                      children: const [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF0284C7)),
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

/// Rich Complaint Detail Modal Bottom Sheet matching ComplaintDetail.tsx
class _ComplaintDetailModal extends StatelessWidget {
  final ComplaintModel complaint;
  final bool isMr;
  final ValueChanged<String> onUpdateStatus;

  const _ComplaintDetailModal({
    required this.complaint,
    required this.isMr,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Center Drag Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row: Complaint Token ID & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.id,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category: ${complaint.category}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  _StatusBadgeLarge(status: complaint.status),
                ],
              ),

              const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

              // Title & Description
              Text(
                complaint.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description.isNotEmpty ? complaint.description : 'No detailed description provided.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 16),

              // Citizen Contact Card
              if (complaint.citizenName != null && complaint.citizenName!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_circle_outlined, size: 20, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  complaint.citizenName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (complaint.citizenMobile != null)
                                  Text(
                                    complaint.citizenMobile!,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (complaint.citizenMobile != null && complaint.citizenMobile!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse('tel:${complaint.citizenMobile}');
                                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                                },
                                icon: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF16A34A)),
                                label: const Text('Call Citizen', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF86EFAC)),
                                  backgroundColor: const Color(0xFFF0FDF4),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final clean = complaint.citizenMobile!.replaceAll(RegExp(r'\D'), '');
                                  final text = Uri.encodeComponent(
                                      'Namaskar, regarding your civic request "${complaint.title}" (#${complaint.id}), our office has updated the status.');
                                  final uri = Uri.parse('https://wa.me/91$clean?text=$text');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.chat_rounded, size: 16, color: Color(0xFF059669)),
                                label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF6EE7B7)),
                                  backgroundColor: const Color(0xFFECFDF5),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Location & Timestamp Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        complaint.location ?? complaint.area ?? 'Ward 12 Prabhag Area',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(complaint.createdAt),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Status Change Action Bar matching Nagarsevak-Managment
              const Text(
                'Update Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatusActionButton(
                      label: 'Pending',
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEF2F2),
                      isActive: complaint.status.toLowerCase() == 'pending',
                      onTap: () => onUpdateStatus('Pending'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusActionButton(
                      label: 'In Progress',
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      isActive: complaint.status.toLowerCase() == 'inprogress',
                      onTap: () => onUpdateStatus('InProgress'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusActionButton(
                      label: 'Resolved',
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFF0FDF4),
                      isActive: complaint.status.toLowerCase() == 'resolved',
                      onTap: () => onUpdateStatus('Resolved'),
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

/// Large Status Badge for Detail Modal
class _StatusBadgeLarge extends StatelessWidget {
  final String status;

  const _StatusBadgeLarge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF16A34A);
        label = 'Resolved';
        break;
      case 'inprogress':
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFFD97706);
        label = 'In Progress';
        break;
      case 'assigned':
        bg = const Color(0xFFF0F9FF);
        border = const Color(0xFFBAE6FD);
        text = const Color(0xFF0284C7);
        label = 'Assigned';
        break;
      default:
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFDC2626);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}

/// Status Action Button inside Detail Sheet
class _StatusActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusActionButton({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
