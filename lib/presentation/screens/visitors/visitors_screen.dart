import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/visitor_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/visitors_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../navigation/app_bar_leading_nav_button.dart';
import '../../providers/auth_provider.dart';
import 'visitor_detail_screen.dart';
import 'visitor_report_generator.dart';

class VisitorsScreen extends ConsumerStatefulWidget {
  const VisitorsScreen({super.key});

  @override
  ConsumerState<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends ConsumerState<VisitorsScreen> {
  // Primary Tabs matching Complaints & Requests pattern:
  // 'today', 'all', 'complaints_help'
  String _activeTab = 'today';

  String _selectedPurpose = 'All';
  String _selectedArea = 'All';

  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;

  List<VisitorModel> _allVisitors = [];

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchVisitors() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(visitorsRepoProvider);
      final list = await repo.getVisitors();
      setState(() {
        _allVisitors = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<String> get _uniqueAreas {
    final set = <String>{};
    for (final v in _allVisitors) {
      if (v.area != null && v.area!.trim().isNotEmpty) {
        set.add(v.area!.trim());
      }
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<VisitorModel> get _filteredVisitors {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allVisitors.where((v) {
      // Primary Tab
      if (_activeTab == 'today') {
        if (!v.isToday) return false;
      } else if (_activeTab == 'complaints_help') {
        final p = v.purpose.toLowerCase();
        if (p != 'complaint' && p != 'help' && p != 'donation') return false;
      }

      // Search Query (name or mobile)
      if (query.isNotEmpty) {
        final nameMatch = v.name.toLowerCase().contains(query);
        final mobileMatch = v.mobile.contains(query);
        final areaMatch = v.area?.toLowerCase().contains(query) ?? false;
        final refMatch = v.reference?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !mobileMatch && !areaMatch && !refMatch) return false;
      }

      // Purpose Filter
      if (_selectedPurpose != 'All' && v.purpose.toLowerCase() != _selectedPurpose.toLowerCase()) {
        return false;
      }

      // Area Filter
      if (_selectedArea != 'All') {
        final a = v.area ?? '';
        if (!a.toLowerCase().contains(_selectedArea.toLowerCase())) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
  }

  Future<void> _makePhoneCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    final fullNumber = clean.length == 10 ? '91$clean' : clean;
    final uri = Uri.parse('https://wa.me/$fullNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openAddVisitorModal() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final eventDateCtrl = TextEditingController();
    final eventTimeCtrl = TextEditingController();

    String selectedPurpose = 'Meeting';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isGreeting = selectedPurpose == 'Greeting' || selectedPurpose == 'Invitation';
          final isDonation = selectedPurpose == 'Donation' || selectedPurpose == 'Help';

          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Log New Visitor',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & Voter Lookup
                        const Text('Visitor Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: nameCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Enter citizen / visitor name',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                _openVoterLookup((voter) {
                                  nameCtrl.text = voter.displayName;
                                  if (voter.mobile != null && voter.mobile!.isNotEmpty) {
                                    mobileCtrl.text = voter.mobile!;
                                  }
                                  if (voter.address.isNotEmpty) {
                                    areaCtrl.text = voter.address;
                                  }
                                  setModalState(() {});
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBAE6FD)),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.how_to_reg_outlined, size: 18, color: Color(0xFF0284C7)),
                                    SizedBox(width: 4),
                                    Text('Voters', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Contact Mobile
                        const Text('Contact Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: mobileCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixText: '+91 ',
                            hintText: '9876543210',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Purpose Dropdown
                        const Text('Purpose / Reason for Visit *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedPurpose,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Complaint', child: Text('Complaint (तक्रार)')),
                            DropdownMenuItem(value: 'Meeting', child: Text('Meeting (भेट / चर्चा)')),
                            DropdownMenuItem(value: 'Greeting', child: Text('Greeting / Invite (निमंत्रण / सत्कार)')),
                            DropdownMenuItem(value: 'Help', child: Text('Help / Relief (वैयक्तिक मदत)')),
                            DropdownMenuItem(value: 'Donation', child: Text('Donation (देणगी / निधी)')),
                            DropdownMenuItem(value: 'Other', child: Text('Other (इतर)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPurpose = val);
                          },
                        ),

                        const SizedBox(height: 16),

                        // Area / Locality or Event Venue
                        Text(
                          isGreeting ? 'Event Venue / Address' : 'Area / Locality',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: areaCtrl,
                          decoration: InputDecoration(
                            hintText: isGreeting ? 'e.g. Shivaji Chowk Community Hall' : 'e.g. Lane 4, Sector 2',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        if (isGreeting) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Event Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: eventDateCtrl,
                                      decoration: InputDecoration(
                                        hintText: 'YYYY-MM-DD',
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
                                    const Text('Event Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: eventTimeCtrl,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. 18:30',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (isDonation) ...[
                          const SizedBox(height: 16),
                          const Text('Requested Assistance Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              hintText: '5000',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Reference
                        const Text('Reference / Leader (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: refCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Sunil Shinde (JE) / Self',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Discussion Remarks
                        const Text('Discussion Notes & Remarks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: remarksCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Brief summary of problem, petition, or conversation...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter visitor name')),
                                );
                                return;
                              }

                              Navigator.pop(ctx);
                              final newVisitor = VisitorModel(
                                id: 'VIS-${DateTime.now().millisecondsSinceEpoch % 10000}',
                                name: name,
                                mobile: mobileCtrl.text.trim(),
                                purpose: selectedPurpose,
                                area: areaCtrl.text.trim(),
                                reference: refCtrl.text.trim(),
                                remarks: remarksCtrl.text.trim(),
                                eventDate: eventDateCtrl.text.trim(),
                                eventTime: eventTimeCtrl.text.trim(),
                                amount: amountCtrl.text.trim(),
                                visitDate: DateTime.now(),
                              );

                              setState(() {
                                _allVisitors.insert(0, newVisitor);
                              });

                              try {
                                final repo = ref.read(visitorsRepoProvider);
                                await repo.addVisitor(newVisitor);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Visitor checked in successfully!'),
                                      backgroundColor: Color(0xFF0F766E),
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
                            child: const Text('Check-In Visitor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
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

  void _openVoterLookup(Function(VoterModel voter) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final voterSearchCtrl = TextEditingController();
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
                      const Text('Select Voter from Ward Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    onChanged: (_) {
                      setSheetState(() {});
                    },
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

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final filtered = _filteredVisitors;

    final todayCount = _allVisitors.where((v) => v.isToday).length;
    final allCount = _allVisitors.length;
    final complaintHelpCount = _allVisitors.where((v) {
      final p = v.purpose.toLowerCase();
      return p == 'complaint' || p == 'help' || p == 'donation';
    }).length;

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
          leading: const AppBarLeadingNavButton(),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Visitor Log',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Daily constituent office meeting register and time log',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
          onPressed: _openAddVisitorModal,
          backgroundColor: const Color(0xFF0284C7),
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: Text(
            isMr ? 'नवीन नोंद' : 'Log Visitor',
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
                    // Today Tab
                    Expanded(
                      child: _buildPrimaryTab(
                        label: isMr ? 'आजच्या भेटी' : 'Today',
                        count: todayCount,
                        isActive: _activeTab == 'today',
                        icon: Icons.today_rounded,
                        onTap: () => setState(() => _activeTab = 'today'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // All Visitors Tab
                    Expanded(
                      child: _buildPrimaryTab(
                        label: isMr ? 'सर्व नोंदी' : 'All Visitors',
                        count: allCount,
                        isActive: _activeTab == 'all',
                        icon: Icons.people_alt_rounded,
                        onTap: () => setState(() => _activeTab = 'all'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Complaints & Help Tab
                    Expanded(
                      child: _buildPrimaryTab(
                        label: isMr ? 'तक्रारी / मदत' : 'Grievances',
                        count: complaintHelpCount,
                        isActive: _activeTab == 'complaints_help',
                        icon: Icons.volunteer_activism_rounded,
                        onTap: () => setState(() => _activeTab = 'complaints_help'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Search & Area Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: isMr ? 'नाव किंवा मोबाईल नंबर शोधा...' : 'Search by name or mobile...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
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
                    PopupMenuButton<String>(
                      initialValue: _selectedArea,
                      tooltip: 'Filter by Area',
                      icon: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: _selectedArea != 'All' ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedArea != 'All' ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: _selectedArea != 'All' ? const Color(0xFF0284C7) : const Color(0xFF475569),
                        ),
                      ),
                      onSelected: (val) => setState(() => _selectedArea = val),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'All', child: Text('All Areas (सर्व परिसर)')),
                        ..._uniqueAreas.map((a) => PopupMenuItem(value: a, child: Text(a))),
                      ],
                    ),
                  ],
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      VisitorReportGenerator.generateAndPrintListReport(
                        visitors: filtered,
                        filterTitle: 'Tab: $_activeTab | Purpose: $_selectedPurpose',
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // 3. Visitor List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 52, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                Text(
                                  isMr ? 'कोणत्याही भेटींच्या नोंदी आढळल्या नाहीत' : 'No visitor records found',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isMr
                                      ? 'कार्यालयात येणाऱ्या नागरिकाची नोंद करण्यासाठी खालील "+ नवीन नोंद" वर टॅप करा.'
                                      : 'Tap "+ Log Visitor" below to register a citizen visit or appointment.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchVisitors,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, index) {
                              final visitor = filtered[index];
                              return _buildVisitorCard(visitor, isMr);
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
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorCard(VisitorModel visitor, bool isMr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VisitorDetailScreen(
                visitor: visitor,
                onVisitorUpdated: _fetchVisitors,
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
              // Top Row: Avatar, Name, Mobile, Purpose Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: visitor.purposeBgColor,
                    child: Text(
                      visitor.name.isNotEmpty ? visitor.name[0].toUpperCase() : 'V',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: visitor.purposeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visitor.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (visitor.mobile.isNotEmpty)
                          Text(
                            '+91 ${visitor.mobile}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: visitor.purposeBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: visitor.purposeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      visitor.purpose,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: visitor.purposeColor,
                      ),
                    ),
                  ),
                ],
              ),

              if (visitor.remarks != null && visitor.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  visitor.remarks!,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),

              // Badges Row: Time, Location, Amount, Reference
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildTag(
                    Icons.access_time_rounded,
                    '${visitor.formattedDate}, ${visitor.formattedTime}',
                    const Color(0xFF0284C7),
                    const Color(0xFFF0F9FF),
                  ),
                  if (visitor.area != null && visitor.area!.isNotEmpty)
                    _buildTag(
                      Icons.location_on_outlined,
                      visitor.area!,
                      const Color(0xFF475569),
                      const Color(0xFFF8FAFC),
                    ),
                  if (visitor.amount != null && visitor.amount!.isNotEmpty)
                    _buildTag(
                      Icons.currency_rupee_rounded,
                      '₹${visitor.amount}',
                      const Color(0xFF16A34A),
                      const Color(0xFFF0FDF4),
                    ),
                  if (visitor.reference != null && visitor.reference!.isNotEmpty)
                    _buildTag(
                      Icons.person_pin_circle_outlined,
                      'Ref: ${visitor.reference!}',
                      const Color(0xFF6B21A8),
                      const Color(0xFFFAF5FF),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Footer Quick Actions (Call, WhatsApp, Details)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (visitor.mobile.isNotEmpty)
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _makePhoneCall(visitor.mobile),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.phone_outlined, size: 13, color: Color(0xFF0284C7)),
                                SizedBox(width: 4),
                                Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _openWhatsApp(visitor.mobile),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),

                  Row(
                    children: [
                      Text(
                        isMr ? 'तपशील' : 'Details',
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

  Widget _buildTag(IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}

