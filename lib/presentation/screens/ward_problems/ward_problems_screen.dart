import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/auth_provider.dart';
import '../complaints/complaint_detail_screen.dart';
import '../ward_map/ward_map_screen.dart';
import 'ward_problems_report_generator.dart';

class WardProblemsScreen extends ConsumerStatefulWidget {
  const WardProblemsScreen({super.key});

  @override
  ConsumerState<WardProblemsScreen> createState() => _WardProblemsScreenState();
}

class _WardProblemsScreenState extends ConsumerState<WardProblemsScreen> {
  // Primary Tabs: 'all', 'pending_active', 'resolved'
  String _activeTab = 'all';

  // Filters
  String _selectedStatus = 'All'; // 'All', 'Pending', 'Assigned', 'InProgress', 'Resolved'
  String _selectedArea = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List<ComplaintModel> _allProblems = [];
  List<StaffModel> _staffList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(complaintsRepoProvider);
      final results = await Future.wait([
        repo.getWardProblems(),
        repo.getStaffList(),
      ]);

      if (mounted) {
        setState(() {
          _allProblems = results[0] as List<ComplaintModel>;
          _staffList = results[1] as List<StaffModel>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dynamic unique areas with problem counts
  List<Map<String, dynamic>> get _uniqueAreasWithCounts {
    final Map<String, int> counts = {};
    for (final p in _allProblems) {
      final a = p.area?.trim();
      if (a != null && a.isNotEmpty) {
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    final list = counts.entries.map((e) => {'name': e.key, 'count': e.value}).toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list;
  }

  List<ComplaintModel> get _filteredProblems {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allProblems.where((p) {
      // 1. Primary Tab filter
      if (_activeTab == 'pending_active') {
        if (p.isResolved || p.status.toLowerCase() == 'closed') return false;
      } else if (_activeTab == 'resolved') {
        if (!p.isResolved && p.status.toLowerCase() != 'closed') return false;
      }

      // 2. Status Chip filter
      if (_selectedStatus != 'All') {
        if (p.status.toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
      }

      // 3. Area filter
      if (_selectedArea != 'All') {
        final areaVal = p.area?.trim().toLowerCase() ?? '';
        if (!areaVal.contains(_selectedArea.toLowerCase())) {
          return false;
        }
      }

      // 4. Keyword search
      if (query.isNotEmpty) {
        final titleMatch = p.title.toLowerCase().contains(query);
        final descMatch = p.description.toLowerCase().contains(query);
        final areaMatch = p.area?.toLowerCase().contains(query) ?? false;
        final locMatch = p.location?.toLowerCase().contains(query) ?? false;
        final citizenMatch = p.citizenName?.toLowerCase().contains(query) ?? false;
        final staffMatch = p.assignedStaffName?.toLowerCase().contains(query) ?? false;
        if (!titleMatch && !descMatch && !areaMatch && !locMatch && !citizenMatch && !staffMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String name, String title) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    final text = 'Namaskar $name ji, regarding ward civic problem "$title" registered with Nagarsevak Office.';
    final uri = Uri.parse('https://wa.me/91$clean?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // -------------------------------------------------------------
  // NEW WARD PROBLEM BOTTOM SHEET
  // -------------------------------------------------------------
  void _showNewWardProblemSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'Shivajinagar, Sector 3');
    final locCtrl = TextEditingController();
    final citizenNameCtrl = TextEditingController();
    final citizenMobileCtrl = TextEditingController();
    String? selectedVoterId;
    String selectedCategory = 'SelfIdentified';
    String? selectedStaffId;

    final categories = [
      'SelfIdentified',
      'Road',
      'Water',
      'Drainage',
      'StreetLight',
      'Cleaning',
      'Encroachment',
      'Other',
    ];

    void openVoterLookup(Function(VoterModel) onSelected) {
      final voterSearchCtrl = TextEditingController();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (sheetCtx, setSheetState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Citizen / Voter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: voterSearchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type voter name or EPIC ID...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FutureBuilder<List<VoterModel>>(
                        future: ref.read(votersRepoProvider).searchVoters(
                              query: voterSearchCtrl.text.trim().isNotEmpty ? voterSearchCtrl.text.trim() : null,
                              pageSize: 40,
                            ),
                        builder: (bCtx, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final voters = snapshot.data ?? [];
                          if (voters.isEmpty) {
                            return const Center(child: Text('No voters found in database'));
                          }
                          return ListView.separated(
                            itemCount: voters.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (lCtx, idx) {
                              final v = voters[idx];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFF0F9FF),
                                  child: Text(
                                    v.displayName.isNotEmpty ? v.displayName[0] : 'V',
                                    style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(v.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('${v.epicNo.isNotEmpty ? "EPIC: ${v.epicNo} | " : ""}${v.address}', style: const TextStyle(fontSize: 12)),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0284C7)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onSelected(v);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.report_problem_outlined, color: Color(0xFF0284C7), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Log Ward Problem / Issue',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Text(
                      'Record self-identified civic problems or area issues requiring municipal action',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const Divider(height: 20),

                    // Problem Title
                    const Text('Problem Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'e.g. Low water pressure, open drainage, dark streetlight...',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category
                    const Text('Category / Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c == 'SelfIdentified' ? 'SelfIdentified (स्व-ओळखलेली)' : c))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Detailed Description
                    const Text('Detailed Description *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Exact issue description, severity, citizen impact...',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Area & Location
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prabhag Area *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  hintText: 'e.g. Shivajinagar, Lane 4...',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Landmark / Spot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: locCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  hintText: 'Near Mandir / Pole No...',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Citizen / Spotter linkage
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Citizen / Area Spotter Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: citizenNameCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Enter name or select voter...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            openVoterLookup((voter) {
                              setModalState(() {
                                citizenNameCtrl.text = voter.displayName;
                                if (voter.mobile != null && voter.mobile!.isNotEmpty) {
                                  citizenMobileCtrl.text = voter.mobile!;
                                }
                                if (voter.address.isNotEmpty) {
                                  areaCtrl.text = voter.address;
                                }
                                selectedVoterId = voter.id;
                              });
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.person_search_rounded, size: 18, color: Color(0xFF0284C7)),
                                SizedBox(width: 4),
                                Text('Voters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Citizen Mobile
                    const Text('Citizen Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: citizenMobileCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '10-digit mobile number...',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Assign Staff Officer
                    if (_staffList.isNotEmpty) ...[
                      const Text('Assign Field Coordinator / Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStaffId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        hint: const Text('Select staff member to assign...'),
                        items: _staffList.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.role})'))).toList(),
                        onChanged: (val) => setModalState(() => selectedStaffId = val),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter problem title')),
                            );
                            return;
                          }
                          Navigator.pop(sheetCtx);
                          final created = await ref.read(complaintsRepoProvider).createWardProblem(
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                category: selectedCategory,
                                area: areaCtrl.text.trim(),
                                location: locCtrl.text.trim(),
                                citizenName: citizenNameCtrl.text.trim().isNotEmpty ? citizenNameCtrl.text.trim() : null,
                                citizenMobile: citizenMobileCtrl.text.trim().isNotEmpty ? citizenMobileCtrl.text.trim() : null,
                                voterId: selectedVoterId,
                                assignedTo: selectedStaffId,
                              );
                          setState(() {
                            _allProblems.insert(0, created);
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ward problem logged successfully!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: const Text('Log Problem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final displayed = _filteredProblems;

    final pendingCount = _allProblems.where((p) => p.isPending || p.status.toLowerCase() == 'assigned' || p.isInProgress).length;
    final resolvedCount = _allProblems.where((p) => p.isResolved || p.status.toLowerCase() == 'closed').length;

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
              tooltip: 'Open Menu Drawer',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Ward Problems Heatmap',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Self-identified & ward civic pain points',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: [
            // Map View Shortcut
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Colors.white, size: 21),
              tooltip: 'Ward Map View',
              onPressed: () {
                ref.read(activeScreenProvider.notifier).setScreen('ward_map');
              },
            ),
            // PDF Export
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 21),
              tooltip: 'Export PDF Report',
              onPressed: () {
                WardProblemsReportGenerator.generateAndPrintReport(
                  problems: displayed,
                  areaFilter: _selectedArea,
                  statusFilter: _selectedStatus,
                );
              },
            ),
            // Refresh
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              tooltip: 'Refresh',
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : Column(
                children: [
                  // 1) PRIMARY TABS
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildPrimaryTab(
                              id: 'all',
                              label: isMr ? 'सर्व समस्या' : 'All Problems',
                              count: _allProblems.length,
                              isActive: _activeTab == 'all',
                            ),
                            _buildPrimaryTab(
                              id: 'pending_active',
                              label: isMr ? 'प्रलंबित / सुरू' : 'Active / Pending',
                              count: pendingCount,
                              isActive: _activeTab == 'pending_active',
                            ),
                            _buildPrimaryTab(
                              id: 'resolved',
                              label: isMr ? 'निकाली' : 'Resolved',
                              count: resolvedCount,
                              isActive: _activeTab == 'resolved',
                            ),
                          ],
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                      ],
                    ),
                  ),

                  // 2) SEARCH & AREA FILTERS BAR
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(
                      children: [
                        // Search
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                  decoration: InputDecoration(
                                    hintText: isMr ? 'समस्या, परिसर किंवा नागरिक शोधा...' : 'Search problem, area, citizen...',
                                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (_searchCtrl.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                  child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Areas Horizontal Pill Bar
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildAreaPill('All', isMr ? 'सर्व परिसर' : 'All Areas', _allProblems.length),
                              const SizedBox(width: 6),
                              ..._uniqueAreasWithCounts.map((a) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _buildAreaPill(
                                    a['name'] as String,
                                    a['name'] as String,
                                    a['count'] as int,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Status Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusChip('All', isMr ? 'सर्व' : 'All'),
                              _buildStatusChip('Pending', isMr ? 'प्रलंबित' : 'Pending'),
                              _buildStatusChip('Assigned', isMr ? 'नेमलेले' : 'Assigned'),
                              _buildStatusChip('InProgress', isMr ? 'सुरू' : 'In Progress'),
                              _buildStatusChip('Resolved', isMr ? 'निकाली' : 'Resolved'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                  // 3) PROBLEMS LIST
                  Expanded(
                    child: displayed.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 54, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text(
                                  isMr ? 'कोणतीही समस्या आढळली नाही' : 'No ward problems found',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _selectedArea = 'All';
                                      _selectedStatus = 'All';
                                    });
                                  },
                                  child: const Text('Reset All Filters'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayed.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final problem = displayed[idx];
                              return _buildProblemCard(isMr, problem);
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 3,
          onPressed: _showNewWardProblemSheet,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            isMr ? 'नवीन समस्या नोंदवा' : 'Log Problem',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryTab({
    required String id,
    required String label,
    required int count,
    required bool isActive,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF0284C7) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAreaPill(String id, String label, int count) {
    final isSel = _selectedArea.toLowerCase() == id.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => _selectedArea = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Center(
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              color: isSel ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSel = _selectedStatus.toLowerCase() == status.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSel,
        selectedColor: const Color(0xFF0284C7),
        labelStyle: TextStyle(
          color: isSel ? Colors.white : const Color(0xFF475569),
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSel ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
        onSelected: (_) => setState(() => _selectedStatus = status),
      ),
    );
  }

  Widget _buildProblemCard(bool isMr, ComplaintModel problem) {
    // Colors matching WardWiseProblem.tsx
    Color statusBg;
    Color statusText;
    if (problem.isResolved) {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF16A34A);
    } else if (problem.isInProgress) {
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFFD97706);
    } else if (problem.isAssigned) {
      statusBg = const Color(0xFFDBEAFE);
      statusText = const Color(0xFF2563EB);
    } else {
      statusBg = const Color(0xFFFEE2E2);
      statusText = const Color(0xFFDC2626);
    }

    final isSelf = problem.category.toLowerCase() == 'selfidentified';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(
              complaint: problem,
            ),
          ),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Status badge + Category badge + Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        problem.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: statusText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isSelf ? const Color(0xFFFFF7ED) : const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelf ? const Color(0xFFFFEDD5) : const Color(0xFFBAE6FD),
                        ),
                      ),
                      child: Text(
                        isSelf ? (isMr ? 'स्व-ओळखलेली' : 'Self-Identified') : problem.category,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelf ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              problem.title,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Description
            Text(
              problem.description,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Assigned Staff Badge (if assigned)
            if (problem.assignedStaffName != null && problem.assignedStaffName!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.engineering_outlined, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 5),
                    Text(
                      'Assigned: ${problem.assignedStaffName}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                    ),
                    if (problem.assignedStaffMobile != null && problem.assignedStaffMobile!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _makePhoneCall(problem.assignedStaffMobile!),
                        child: const Icon(Icons.call, size: 13, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Citizen / Spotter Badge (if present)
            if (problem.citizenName != null && problem.citizenName!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Text(
                      'Reported by: ${problem.citizenName}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                    ),
                    if (problem.citizenMobile != null && problem.citizenMobile!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _makePhoneCall(problem.citizenMobile!),
                        child: const Icon(Icons.call, size: 13, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _openWhatsApp(problem.citizenMobile!, problem.citizenName!, problem.title),
                        child: const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            const Divider(height: 12, color: Color(0xFFF1F5F9)),

            // Footer: Date & Area/Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(problem.createdAt),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                if (problem.area != null && problem.area!.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF0284C7)),
                      const SizedBox(width: 3),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          problem.area!,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

