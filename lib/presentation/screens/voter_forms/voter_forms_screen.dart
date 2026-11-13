import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/voter_application_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/voter_applications_repository.dart';
import '../../providers/auth_provider.dart';
import 'voter_forms_report_generator.dart';
import '../../navigation/app_drawer.dart';

class VoterFormsScreen extends ConsumerStatefulWidget {
  const VoterFormsScreen({super.key});

  @override
  ConsumerState<VoterFormsScreen> createState() => _VoterFormsScreenState();
}

class _VoterFormsScreenState extends ConsumerState<VoterFormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedFormType = 'All';

  bool _isLoading = true;
  List<VoterApplicationModel> _applications = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'submitted': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final repo = ref.read(voterApplicationsRepoProvider);

    final apps = await repo.getApplications(
      searchQuery: _searchController.text,
      statusFilter: _selectedStatus,
      formTypeFilter: _selectedFormType,
    );
    final stats = await repo.getStatistics();

    if (mounted) {
      setState(() {
        _applications = apps;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) clean = '91$clean';
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openAddEditModal([VoterApplicationModel? appToEdit]) {
    final isMr = ref.read(isMarathiProvider);
    final nameCtrl = TextEditingController(text: appToEdit?.applicantName ?? '');
    final mobileCtrl = TextEditingController(text: appToEdit?.applicantMobile ?? '');
    final notesCtrl = TextEditingController(text: appToEdit?.notes ?? '');
    String formType = appToEdit?.formType ?? 'Form 6';
    String status = appToEdit?.status ?? 'Submitted';
    String? linkedVoterId = appToEdit?.voterId;

    // Search state for existing voters
    final voterSearchCtrl = TextEditingController();
    List<VoterModel> voterSuggestions = [];
    bool isSearchingVoter = false;

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                : [],
          ),
        ),
      );
    }

    InputDecoration inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
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
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.how_to_reg_rounded,
                              color: Color(0xFF0284C7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            appToEdit == null
                                ? (isMr ? 'नवीन अर्ज नोंदवा' : 'Log Voter Application')
                                : (isMr ? 'अर्ज संपादित करा' : 'Edit Voter Application'),
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Optional Voter Auto-complete Search
                      if (appToEdit == null) ...[
                        fieldLabel(isMr ? 'मतदार यादीतून शोधा (पर्यायी)' : 'Search Name from Voter Roll (Optional)'),
                        TextField(
                          controller: voterSearchCtrl,
                          decoration: inputDec(
                            hintText: isMr ? 'नाव किंवा ओळखपत्र (EPIC) नंबर प्रविष्ट करा...' : 'Type name or EPIC number...',
                            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                            suffixIcon: isSearchingVoter
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : null,
                          ),
                          onChanged: (val) async {
                            if (val.trim().length >= 2) {
                              setModalState(() => isSearchingVoter = true);
                              final repo = ref.read(voterApplicationsRepoProvider);
                              final results = await repo.searchVoters(val);
                              setModalState(() {
                                voterSuggestions = results;
                                isSearchingVoter = false;
                              });
                            } else {
                              setModalState(() => voterSuggestions = []);
                            }
                          },
                        ),
                        if (voterSuggestions.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 160),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: voterSuggestions.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final v = voterSuggestions[idx];
                                return ListTile(
                                  dense: true,
                                  title: Text(v.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text('EPIC: ${v.epicNo} · Booth: ${v.booth}', style: const TextStyle(fontSize: 11)),
                                  trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF0284C7), size: 18),
                                  onTap: () {
                                    setModalState(() {
                                      nameCtrl.text = v.displayName;
                                      if (v.mobile != null) mobileCtrl.text = v.mobile!;
                                      linkedVoterId = v.id;
                                      voterSuggestions = [];
                                      voterSearchCtrl.clear();
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],

                      // Applicant Name & Mobile Number side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'अर्जदाराचे नाव' : 'Applicant Name', isRequired: true),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: inputDec(
                                    hintText: isMr ? 'उदा. राहुल सुरेश शिंदे' : 'e.g. Rahul Suresh Shinde',
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
                                fieldLabel(isMr ? 'मोबाईल नंबर' : 'Mobile Number'),
                                TextField(
                                  controller: mobileCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: inputDec(
                                    hintText: '98220xxxxx',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Form Type & Status side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'अर्जाचा प्रकार' : 'Form Type', isRequired: true),
                                DropdownButtonFormField<String>(
                                  value: formType,
                                  decoration: inputDec(),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(value: 'Form 6', child: Text(isMr ? 'नमुना ६ - नवीन नोंदणी' : 'Form 6 - New Reg', style: const TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'Form 7', child: Text(isMr ? 'नमुना ७ - नाव वगळणे' : 'Form 7 - Deletion', style: const TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'Form 8', child: Text(isMr ? 'नमुना ८ - दुरुस्ती' : 'Form 8 - Update', style: const TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'Search', child: Text(isMr ? 'यादी शोध साहाय्य' : 'Roll Search', style: const TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => formType = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'अर्जाची स्थिती' : 'Status', isRequired: true),
                                DropdownButtonFormField<String>(
                                  value: status,
                                  decoration: inputDec(),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(value: 'Submitted', child: Text(isMr ? 'दाखल (Submitted)' : 'Submitted', style: const TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'Pending', child: Text(isMr ? 'प्रलंबित (Pending)' : 'Pending', style: const TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'Approved', child: Text(isMr ? 'मंजूर (Approved)' : 'Approved', style: const TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'Rejected', child: Text(isMr ? 'नाकारले (Rejected)' : 'Rejected', style: const TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => status = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      fieldLabel(isMr ? 'नोंद / शेरा / कागदपत्रे' : 'Notes / Remarks / Documents Attached'),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: inputDec(
                          hintText: isMr
                              ? 'उदा. आधार कार्ड जोडले, जन्मदिनांक दुरुस्ती, नवीन पीव्हीसी कार्ड मागणी.'
                              : 'e.g. Aadhaar card attached, DOB correction, PVC card request.',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isMr ? 'कृपया अर्जदाराचे नाव प्रविष्ट करा.' : 'Please enter applicant name.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            final appModel = VoterApplicationModel(
                              id: appToEdit?.id ?? 'app-${DateTime.now().millisecondsSinceEpoch}',
                              voterId: linkedVoterId,
                              applicantName: name,
                              applicantMobile: mobileCtrl.text.trim().isNotEmpty ? mobileCtrl.text.trim() : null,
                              formType: formType,
                              status: status,
                              notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                              createdAt: appToEdit?.createdAt ?? DateTime.now(),
                            );

                            final repo = ref.read(voterApplicationsRepoProvider);
                            if (appToEdit == null) {
                              await repo.addApplication(appModel);
                            } else {
                              await repo.updateApplication(appModel);
                            }

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (!mounted) return;
                            _loadApplications();

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  appToEdit == null
                                      ? (isMr ? 'अर्ज यशस्वीरित्या नोंदवला गेला!' : 'Application logged successfully!')
                                      : (isMr ? 'अर्जाचे तपशील अद्यतनित केले!' : 'Application details updated!'),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                          label: Text(
                            appToEdit == null
                                ? (isMr ? 'अर्ज जतन करा' : 'Save Application')
                                : (isMr ? 'बदल जतन करा' : 'Save Changes'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteApplication(VoterApplicationModel app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Application'),
        content: Text('Are you sure you want to delete ${app.formType} application for ${app.applicantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(voterApplicationsRepoProvider);
              await repo.deleteApplication(app.id);
              if (!mounted) return;
              _loadApplications();
              messenger.showSnackBar(
                const SnackBar(content: Text('Application deleted successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
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
              'Voter Forms',
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
              'ECI Form 6, Form 7, Form 8 registration helpdesk',
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
        onPressed: () => _openAddEditModal(),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Application', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'ECI Forms & Guides', icon: Icon(Icons.description_outlined, size: 18)),
                  Tab(text: 'Application History', icon: Icon(Icons.history_edu_outlined, size: 18)),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOfficialFormsTab(),
                _buildApplicationsHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialFormsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ECI Helpline Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Election Commission Helpline: 1950',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Toll-free helpline for voter registration & roll assistance',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _makePhoneCall('1950'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Official Election Commission (ECI) Forms',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Official forms for new registration, corrections, and constituency transfer',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 14),

          // 4 ECI Form Service Cards
          _buildEciFormCard(
            title: 'Search in Electoral Roll',
            description: 'Search your name and part number in the official voter roll to locate your polling booth.',
            requiredDocs: 'Personal details, EPIC number, or registered mobile number',
            requirements: [
              'Search by personal details (Name, Age, Gender, District)',
              'Direct search by EPIC number',
              'Search by registered mobile number',
            ],
            icon: Icons.search_rounded,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            buttonText: 'Search Official Roll',
            url: 'https://electoralsearch.eci.gov.in',
          ),

          const SizedBox(height: 14),

          _buildEciFormCard(
            title: 'New Voter Registration (Form 6)',
            description: 'For first-time voters (completed 18 years of age) or citizens shifted from other constituencies.',
            requiredDocs: 'Passport size photo, age proof, residence proof',
            requirements: [
              'Recent passport size color photograph',
              'Identity proof (Aadhaar Card / PAN Card / Driving License)',
              'Residence proof (Electricity bill / Bank passbook / Ration card)',
              'Age proof (Birth certificate / 10th marksheet)',
            ],
            icon: Icons.person_add_alt_1_rounded,
            color: const Color(0xFF0284C7),
            bgColor: const Color(0xFFF0F9FF),
            borderColor: const Color(0xFFBAE6FD),
            buttonText: 'Fill Form 6 Online',
            url: 'https://voters.eci.gov.in/form6',
          ),

          const SizedBox(height: 14),

          _buildEciFormCard(
            title: 'Deletion of Name from Roll (Form 7)',
            description: 'For objecting to an entry or deleting names of deceased / permanently shifted electors.',
            requiredDocs: 'EPIC number of elector, reason and supporting document',
            requirements: [
              'EPIC number and roll part details of the elector',
              'Reason for deletion (Shifted / Deceased / Duplicate entry)',
              'Municipal death certificate in case of deceased elector',
            ],
            icon: Icons.person_remove_alt_1_rounded,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
            buttonText: 'Fill Form 7 Online',
            url: 'https://voters.eci.gov.in/form7',
          ),

          const SizedBox(height: 14),

          _buildEciFormCard(
            title: 'Update Voter Details (Form 8)',
            description: 'For corrections in name, address, DOB, or ordering a replacement Smart PVC voter card.',
            requiredDocs: 'Existing EPIC number, supporting proof for correction',
            requirements: [
              'Existing EPIC number',
              'Proof of correction (Name/Address/DOB change documents)',
              'New address proof (for shifting within constituency)',
            ],
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA7F3D0),
            buttonText: 'Fill Form 8 Online',
            url: 'https://voters.eci.gov.in/form8',
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEciFormCard({
    required String title,
    required String description,
    required String requiredDocs,
    required List<String> requirements,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required String buttonText,
    required String url,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 12),

                // Documents required
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Required Documents: $requiredDocs',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Checklist
                ...requirements.map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 14),

                // Launch External Link Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchExternalUrl(url),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 KPI Summary Widgets
          _buildStatsGrid(),

          const SizedBox(height: 16),

          // Search and Filters Bar
          _buildSearchAndFilters(),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Logged Applications: ${_applications.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Approval Rate: ${_stats['total'] > 0 ? ((_stats['approved'] / _stats['total']) * 100).round() : 0}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => VoterFormsReportGenerator.generateAndPrintReport(applications: _applications),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFFDC2626)),
                    label: const Text('PDF Report', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      backgroundColor: const Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Applications List
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xFF0284C7)),
              ),
            )
          else if (_applications.isEmpty)
            _buildEmptyApplicationsState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _applications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildApplicationCard(_applications[index]),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final total = _stats['total'] ?? 0;
    final approved = _stats['approved'] ?? 0;
    final pending = _stats['pending'] ?? 0;
    final submitted = _stats['submitted'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 1.7 : 1.45,
          children: [
            _buildStatCard('Total Applications', total.toString(), Icons.assignment_outlined, const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
            _buildStatCard('Approved', approved.toString(), Icons.check_circle_outlined, const Color(0xFF10B981), const Color(0xFFECFDF5)),
            _buildStatCard('Pending', pending.toString(), Icons.hourglass_top_outlined, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
            _buildStatCard('Submitted', submitted.toString(), Icons.send_outlined, const Color(0xFF0284C7), const Color(0xFFF0F9FF)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => _loadApplications(),
            decoration: InputDecoration(
              hintText: 'Search applicant name, mobile or notes...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadApplications();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          const SizedBox(height: 10),

          // Filters Row
          Row(
            children: [
              // Status Filter Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Status')),
                        DropdownMenuItem(value: 'Submitted', child: Text('Submitted')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                          _loadApplications();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Form Type Filter Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFormType,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Forms')),
                        DropdownMenuItem(value: 'Form 6', child: Text('Form 6 (New)')),
                        DropdownMenuItem(value: 'Form 7', child: Text('Form 7 (Deletion)')),
                        DropdownMenuItem(value: 'Form 8', child: Text('Form 8 (Update)')),
                        DropdownMenuItem(value: 'Search', child: Text('Roll Search')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedFormType = val);
                          _loadApplications();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(VoterApplicationModel app) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.applicantName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    if (app.applicantMobile != null && app.applicantMobile!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            app.applicantMobile!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: app.statusBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: app.statusBorderColor),
                    ),
                    child: Text(
                      app.statusMarathi,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: app.statusColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit',
                    onPressed: () => _openAddEditModal(app),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDeleteApplication(app),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Form Type Pill & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  app.formTypeMarathi,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(app.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // Notes if present
          if (app.notes != null && app.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                app.notes!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
              ),
            ),
          ],

          // Quick call actions if mobile present
          if (app.applicantMobile != null && app.applicantMobile!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(app.applicantMobile!),
                    icon: const Icon(Icons.phone, size: 13),
                    label: const Text('Call', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWhatsApp(app.applicantMobile!),
                    icon: const Icon(Icons.chat_bubble_outline, size: 13),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFFBBF7D0)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyApplicationsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_edu_rounded, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            'No applications found.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Change search filters or log a new application.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openAddEditModal(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log Application'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
