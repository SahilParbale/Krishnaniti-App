import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_drawer.dart';
import 'team_member_profile_screen.dart';
import 'team_report_generator.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  List<TeamMemberModel> _allMembers = [];
  Map<String, int> _teamStats = {};
  String _selectedCategory = 'All'; // 'All', 'Office', 'Party', 'Cooperative'
  String _viewMode = 'cards'; // 'cards' or 'table'

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeam() async {
    setState(() => _isLoading = true);
    final repo = ref.read(teamRepoProvider);

    final members = await repo.getTeamMembers(
      category: _selectedCategory != 'All' ? _selectedCategory : null,
      query: _searchCtrl.text.trim(),
    );
    final stats = await repo.getTeamStats();

    if (mounted) {
      setState(() {
        _allMembers = members;
        _teamStats = stats;
        _isLoading = false;
      });
    }
  }

  List<TeamMemberModel> get _filteredMembers {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allMembers;

    return _allMembers.where((m) {
      final inKeywords = m.keywords.any((k) => k.toLowerCase().contains(q));
      return m.name.toLowerCase().contains(q) ||
          (m.nameMarathi?.toLowerCase().contains(q) ?? false) ||
          m.role.toLowerCase().contains(q) ||
          m.mobile.contains(q) ||
          (m.area?.toLowerCase().contains(q) ?? false) ||
          (m.partyWing?.toLowerCase().contains(q) ?? false) ||
          (m.societyName?.toLowerCase().contains(q) ?? false) ||
          inKeywords;
    }).toList();
  }

  void _callMember(String mobile) async {
    final url = Uri.parse('tel:+91$mobile');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  void _messageOnWhatsApp(TeamMemberModel member) async {
    final msg = Uri.encodeComponent(
      'Greetings ${member.displayName},\n'
      'Contacting you from Ward 12 Corporator Office.',
    );
    final url = Uri.parse('https://wa.me/91${member.mobile}?text=$msg');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showHelpGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Team Guide',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Staff and Task Allocation System',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildHelpPoint(
              icon: Icons.business_rounded,
              title: '1. Office Team',
              desc: 'Office admin, PR officer, driver, peon, and assistants.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.flag_rounded,
              title: '2. Party & Organization Cadre',
              desc: 'Youth wing, women wing, social media cell, and senior citizens cell functionaries.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.handshake_rounded,
              title: '3. Municipal & Cooperative Staff',
              desc: 'Municipal drainage, water supply, electricity utility staff, and society chairman representatives.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.auto_fix_high_rounded,
              title: '4. Auto Assignment Rules',
              desc: 'Citizen complaints automatically route to the relevant staff based on topic keywords (water, light, waste, etc.).',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpPoint({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0284C7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddMemberModal() => _showMemberModal();

  void _showMemberModal({TeamMemberModel? memberToEdit}) {
    final isMr = ref.read(isMarathiProvider);
    final nameCtrl = TextEditingController(text: memberToEdit?.name ?? '');
    final mobileCtrl = TextEditingController(text: memberToEdit?.mobile ?? '');
    final emailCtrl = TextEditingController(text: memberToEdit?.email ?? '');
    final passwordCtrl = TextEditingController();
    bool showPassword = false;
    final roleCtrl = TextEditingController(text: memberToEdit?.role ?? '');
    final areaCtrl = TextEditingController(text: memberToEdit?.area ?? 'Ward 12, Shaniwar Peth');
    final societyCtrl = TextEditingController(text: memberToEdit?.societyName ?? '');
    final keywordsCtrl = TextEditingController(text: memberToEdit?.keywords.join(', ') ?? '');

    String category = memberToEdit?.category ?? 'Office';
    String paksh = memberToEdit?.paksh ?? '';
    String partyWing = memberToEdit?.partyWing ?? '';
    String pad = memberToEdit?.pad ?? '';
    bool canAssignWork = memberToEdit?.canAssignWork ?? true;

    final complaintCategories = [
      {'id': 'Road', 'label': isMr ? 'रस्ते (Roads)' : 'Roads (रस्ते)'},
      {'id': 'Water', 'label': isMr ? 'पाणीपुरवठा (Water Supply)' : 'Water Supply (पाणीपुरवठा)'},
      {'id': 'StreetLight', 'label': isMr ? 'वीज/लाईट (Street Lights)' : 'Electricity/Street Lights (वीज/लाईट)'},
      {'id': 'Cleaning', 'label': isMr ? 'कचरा/स्वच्छता (Cleaning)' : 'Cleaning/Waste (कचरा/स्वच्छता)'},
      {'id': 'Drainage', 'label': isMr ? 'गटार/ड्रेनेज (Drainage)' : 'Drainage (गटार/ड्रेनेज)'},
      {'id': 'Other', 'label': isMr ? 'इतर (Other)' : 'Other (इतर)'},
    ];

    List<String> selectedCategories = (memberToEdit?.keywords ?? [])
        .where((k) => complaintCategories.any((c) => c['id'] == k))
        .toList();

    final availablePermissions = [
      {'id': 'complaints', 'label': isMr ? 'तक्रारी व विनंत्या' : 'Complaints & Requests'},
      {'id': 'letters', 'label': isMr ? 'पत्रव्यवहार व अर्ज' : 'Letters & Applications'},
      {'id': 'tasks', 'label': isMr ? 'कामे व कार्ये' : 'Task Management'},
      {'id': 'visitors', 'label': isMr ? 'अभ्यागत नोंद' : 'Visitor Log'},
      {'id': 'schemes', 'label': isMr ? 'शासकीय योजना' : 'Government Schemes'},
      {'id': 'ward_problems', 'label': isMr ? 'प्रभाग समस्या' : 'Ward Problems'},
      {'id': 'ward_info', 'label': isMr ? 'प्रभाग नकाशा' : 'Ward Map'},
      {'id': 'work_history', 'label': isMr ? 'कामांचा इतिहास' : 'Work History'},
      {'id': 'improvements', 'label': isMr ? 'प्रभाग सुधारणा' : 'Ward Improvements'},
      {'id': 'provision', 'label': isMr ? 'प्रभाग तरतूद' : 'Ward Provision'},
      {'id': 'gb_register', 'label': isMr ? 'जीबी रजिस्टर' : 'GB Register / Diary'},
      {'id': 'budget', 'label': isMr ? 'प्रभाग अंदाजपत्रक' : 'Ward Budget'},
      {'id': 'gov_office', 'label': isMr ? 'शासकीय कार्यालये' : 'Government Offices'},
      {'id': 'social', 'label': isMr ? 'सोशल मीडिया ॲनालिटिक्स' : 'Social Media Analytics'},
      {'id': 'newspaper', 'label': isMr ? 'वर्तमानपत्र कात्रणे' : 'Newspaper Clippings'},
      {'id': 'media_tracking', 'label': isMr ? 'मीडिया ट्रॅकिंग' : 'Media Tracking'},
      {'id': 'bot', 'label': isMr ? 'व्हॉट्सॲप बॉट' : 'WhatsApp Bot'},
      {'id': 'ai_content', 'label': isMr ? 'एआय कंटेंट स्टुडिओ' : 'AI Content Studio'},
      {'id': 'events', 'label': isMr ? 'कार्यक्रम व निमंत्रणे' : 'Events & Invites'},
      {'id': 'gallery', 'label': isMr ? 'फोटो गॅलरी' : 'Media Gallery'},
      {'id': 'results', 'label': isMr ? 'निवडणूक निकाल' : 'Election Results'},
      {'id': 'sadasya', 'label': isMr ? 'पक्ष सदस्य' : 'Party Members (Sadasya)'},
      {'id': 'surveys', 'label': isMr ? 'जनमत चाचण्या' : 'Surveys'},
      {'id': 'voters', 'label': isMr ? 'मतदार यादी शोध' : 'Voter Search'},
      {'id': 'social_organizations', 'label': isMr ? 'मंडळ व संस्था' : 'NGO & Mandals Info'},
      {'id': 'staff', 'label': isMr ? 'संघ व्यवस्थापन' : 'Staff Management'},
    ];

    List<String> selectedPermissions = memberToEdit?.permissions != null
        ? List<String>.from(memberToEdit!.permissions!)
        : ['complaints', 'letters', 'tasks', 'visitors', 'ward_problems'];

    final partyWingsList = [
      'युवक आघाडी',
      'महिला आघाडी',
      'विद्यार्थी आघाडी',
      'शेतकरी आघाडी',
      'कामगार आघाडी',
      'व्यापारी आघाडी',
      'अल्पसंख्याक आघाडी',
      'ओबीसी आघाडी',
      'ज्येष्ठ नागरिक आघाडी',
      'क्रीडा आघाडी',
      'आयटी सेल',
      'सोशल मीडिया सेल',
      'जनसंपर्क विभाग',
      'स्वयंसेवक संघटना',
    ];

    final partyPostsList = [
      'अध्यक्ष (President)',
      'उपाध्यक्ष (Vice President)',
      'सचिव (Secretary)',
      'सहसचिव (Joint Secretary)',
      'कोषाध्यक्ष (Treasurer)',
      'संघटक (Organizer)',
      'सदस्य (Member)',
    ];

    final roleSuggestions = [
      'Office Admin',
      'Personal Assistant',
      'Ward President',
      'Booth Pramukh',
      'Electrician',
      'Plumber',
      'Sanitation Worker',
    ];

    Widget fieldLabel(String text, {bool isRequired = false, String? optionalNote}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            RichText(
              text: TextSpan(
                text: text,
                style: const TextStyle(
                  fontSize: 12.5,
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
            if (optionalNote != null) ...[
              const SizedBox(width: 6),
              Text(
                '($optionalNote)',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ],
        ),
      );
    }

    InputDecoration inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon, String? prefixText}) {
      return InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
                            child: Icon(
                              memberToEdit != null ? Icons.edit_rounded : Icons.person_add_rounded,
                              color: const Color(0xFF0284C7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            memberToEdit != null
                                ? (isMr ? 'सदस्याची माहिती सुधारा' : 'Edit Staff Member')
                                : (isMr ? 'नवीन कर्मचारी / कार्यकर्ता जोडा' : 'Add Staff Member'),
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Row 1: Category & Political Party
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'श्रेणी / विभाग' : 'Category', isRequired: true),
                                DropdownButtonFormField<String>(
                                  initialValue: category,
                                  decoration: inputDec(),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Office',
                                      child: Text(isMr ? 'कार्यालयीन कर्मचारी' : 'Office Team', style: const TextStyle(fontSize: 12.5)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Party',
                                      child: Text(isMr ? 'पक्ष पदाधिकारी / कार्यकर्ते' : 'Party Cadre', style: const TextStyle(fontSize: 12.5)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Cooperative',
                                      child: Text(isMr ? 'महापालिका / इतर संस्था' : 'Municipal / Co-op', style: const TextStyle(fontSize: 12.5)),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => category = val);
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
                                fieldLabel(isMr ? 'राजकीय पक्ष (पक्ष)' : 'Political Party', optionalNote: isMr ? 'ऐच्छिक' : 'Optional'),
                                DropdownButtonFormField<String>(
                                  initialValue: paksh,
                                  decoration: inputDec(),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(value: '', child: Text(isMr ? 'पक्ष निवडा' : 'Select Party', style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'BJP', child: Text(isMr ? 'भाजप (भारतीय जनता पक्ष)' : 'BJP (Bharatiya Janata Party)', style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'INC', child: Text(isMr ? 'काँग्रेस (आय)' : 'INC (Congress)', style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'NCP', child: Text(isMr ? 'राष्ट्रवादी काँग्रेस' : 'NCP (Nationalist Congress Party)', style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'SHS', child: Text(isMr ? 'शिवसेना' : 'Shiv Sena', style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'UBT', child: Text(isMr ? 'शिवसेना (UBT)' : 'Shivsena (UBT)', style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'MNS', child: Text(isMr ? 'मनसे (MNS)' : 'MNS', style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'AAP', child: Text(isMr ? 'आप (Aam Aadmi Party)' : 'AAP', style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'Independent', child: Text(isMr ? 'अपक्ष' : 'Independent', style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'Other', child: Text(isMr ? 'इतर / कोणताही नाही' : 'Other / None', style: const TextStyle(fontSize: 12.5))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => paksh = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Full Name
                      fieldLabel(isMr ? 'पूर्ण नाव' : 'Full Name', isRequired: true),
                      TextField(
                        controller: nameCtrl,
                        decoration: inputDec(
                          hintText: isMr ? 'उदा. रमेश बाळासाहेब कदम' : 'e.g. Ramesh Balasaheb Kadam',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mobile Number (+91 prefix)
                      fieldLabel(isMr ? 'मोबाईल नंबर' : 'Mobile Number', isRequired: true),
                      TextField(
                        controller: mobileCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: inputDec(
                          prefixText: '+91 ',
                          hintText: '9876543210',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email & Password (Login ID & Password)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'ईमेल (Login ID)' : 'Email (Login ID)'),
                                TextField(
                                  controller: emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: inputDec(
                                    hintText: 'staff@example.com',
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
                                fieldLabel(isMr ? 'पासवर्ड' : 'Password'),
                                TextField(
                                  controller: passwordCtrl,
                                  obscureText: !showPassword,
                                  decoration: inputDec(
                                    hintText: '••••••••',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        size: 18,
                                        color: const Color(0xFF64748B),
                                      ),
                                      onPressed: () => setModalState(() => showPassword = !showPassword),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Role / Designation with quick suggestion chips
                      fieldLabel(isMr ? 'पद / हुद्दा' : 'Role / Designation', isRequired: true),
                      TextField(
                        controller: roleCtrl,
                        decoration: inputDec(
                          hintText: isMr ? 'उदा. कार्यालय प्रशासक, प्रभाग अध्यक्ष...' : 'e.g. Office Admin, Ward President...',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: roleSuggestions.map((r) {
                          return ActionChip(
                            label: Text(r, style: const TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onPressed: () => setModalState(() => roleCtrl.text = r),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Work Area & Society Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'कार्यक्षेत्र / परिसर' : 'Work Area'),
                                TextField(
                                  controller: areaCtrl,
                                  decoration: inputDec(
                                    hintText: isMr ? 'उदा. शनिवार पेठ' : 'e.g. Shaniwar Peth',
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
                                fieldLabel(isMr ? 'सोसायटीचे नाव' : 'Society Name', optionalNote: isMr ? 'ऐच्छिक' : 'Optional'),
                                TextField(
                                  controller: societyCtrl,
                                  decoration: inputDec(
                                    hintText: isMr ? 'उदा. रॉयल हाईट्स' : 'e.g. Royal Heights',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Party Wing & Designation/Post (Pad)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(isMr ? 'पक्ष आघाडी / सेल' : 'Party Wing', optionalNote: isMr ? 'ऐच्छिक' : 'Optional'),
                                DropdownButtonFormField<String>(
                                  initialValue: partyWingsList.contains(partyWing) ? partyWing : '',
                                  decoration: inputDec(),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(value: '', child: Text(isMr ? 'आघाडी निवडा' : 'Select Wing', style: const TextStyle(fontSize: 12.5))),
                                    ...partyWingsList.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 12.5)))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => partyWing = val);
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
                                fieldLabel(isMr ? 'पद (आघाडीतील पद)' : 'Designation / Post', optionalNote: isMr ? 'ऐच्छिक' : 'Optional'),
                                DropdownButtonFormField<String>(
                                  initialValue: partyPostsList.any((p) => p.startsWith(pad) && pad.isNotEmpty)
                                      ? partyPostsList.firstWhere((p) => p.startsWith(pad))
                                      : '',
                                  decoration: inputDec(),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(value: '', child: Text(isMr ? 'पद निवडा' : 'Select Post', style: const TextStyle(fontSize: 12.5))),
                                    ...partyPostsList.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12.5)))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => pad = val.split(' ')[0]);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Auto Keywords
                      fieldLabel(isMr ? 'ऑटो कीवर्ड्स' : 'Auto Keywords', optionalNote: isMr ? 'ऐच्छिक' : 'Optional'),
                      TextField(
                        controller: keywordsCtrl,
                        decoration: inputDec(
                          hintText: isMr ? 'पाणी, ड्रेनेज, वीज, कचरा' : 'water, drainage, electricity, waste',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 14),
                        child: Text(
                          isMr
                              ? 'तक्रारींचे स्वयंचलित वाटप करण्यासाठी कीवर्ड्स (स्वल्पविरामाने वेगळे करा)'
                              : 'Keywords used to auto-assign incoming citizen complaints',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),

                      // Complaint Categories (Auto-Assign)
                      fieldLabel(isMr ? 'तक्रार श्रेणी (स्वयंचलित वाटप)' : 'Complaint Categories (Auto-Assign)'),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: complaintCategories.map((cat) {
                            final catId = cat['id']!;
                            final isChecked = selectedCategories.contains(catId);
                            return FilterChip(
                              label: Text(cat['label']!, style: TextStyle(fontSize: 12, color: isChecked ? Colors.indigo.shade900 : const Color(0xFF334155))),
                              selected: isChecked,
                              selectedColor: const Color(0xFFC7D2FE),
                              checkmarkColor: Colors.indigo.shade900,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedCategories.add(catId);
                                  } else {
                                    selectedCategories.remove(catId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Permissions (Access Control)
                      fieldLabel(isMr ? 'परवानग्या व अधिकार (Access Control)' : 'Permissions (Access Control)'),
                      Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${selectedPermissions.length} / ${availablePermissions.length} ${isMr ? 'अधिकार निवडले' : 'selected'}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      if (selectedPermissions.length == availablePermissions.length) {
                                        selectedPermissions.clear();
                                      } else {
                                        selectedPermissions = availablePermissions.map((p) => p['id']!).toList();
                                      }
                                    });
                                  },
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  child: Text(
                                    selectedPermissions.length == availablePermissions.length
                                        ? (isMr ? 'सर्व काढा' : 'Deselect All')
                                        : (isMr ? 'सर्व निवडा' : 'Select All'),
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 8, color: Color(0xFFE2E8F0)),
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: availablePermissions.length,
                                itemBuilder: (context, idx) {
                                  final perm = availablePermissions[idx];
                                  final permId = perm['id']!;
                                  final isChecked = selectedPermissions.contains(permId);
                                  return CheckboxListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: const Color(0xFF0284C7),
                                    title: Text(perm['label']!, style: const TextStyle(fontSize: 12.5)),
                                    value: isChecked,
                                    onChanged: (val) {
                                      setModalState(() {
                                        if (val == true) {
                                          selectedPermissions.add(permId);
                                        } else {
                                          selectedPermissions.remove(permId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Management Access: Assign Work to Other Staff
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFEF08A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: canAssignWork,
                              activeColor: const Color(0xFF0284C7),
                              onChanged: (val) => setModalState(() => canAssignWork = val ?? true),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMr ? 'इतर कर्मचाऱ्यांना काम सोपवण्याची परवानगी द्या' : 'Assign Work to Other Staff',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF713F12)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isMr
                                        ? 'या युझरला इतर कर्मचाऱ्यांना तक्रारी व कार्ये वाटप करण्याचे अधिकार मिळतील.'
                                        : 'Allow this user to delegate tasks and citizen complaints to other staff members.',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF854D0E)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Buttons: Cancel & Save Member
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                isMr ? 'रद्द करा' : 'Cancel',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                              label: Text(
                                memberToEdit != null
                                    ? (isMr ? 'बदल जतन करा' : 'Save Changes')
                                    : (isMr ? 'सदस्य जतन करा' : 'Save Member'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              onPressed: () async {
                                if (nameCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isMr ? 'कृपया सदस्याचे नाव प्रविष्ट करा.' : 'Please enter member name.')),
                                  );
                                  return;
                                }
                                if (mobileCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isMr ? 'कृपया मोबाईल नंबर प्रविष्ट करा.' : 'Please enter mobile number.')),
                                  );
                                  return;
                                }

                                final manualKw = keywordsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                final combinedKw = {...manualKw, ...selectedCategories}.toList();

                                final member = TeamMemberModel(
                                  id: memberToEdit?.id ?? 'stf-${DateTime.now().millisecondsSinceEpoch}',
                                  name: nameCtrl.text.trim(),
                                  nameMarathi: nameCtrl.text.trim(),
                                  mobile: mobileCtrl.text.trim(),
                                  email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                                  role: roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : 'Staff',
                                  category: category,
                                  area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                                  partyWing: partyWing.isNotEmpty ? partyWing : null,
                                  paksh: paksh.isNotEmpty ? paksh : null,
                                  pad: pad.isNotEmpty ? pad : null,
                                  societyName: societyCtrl.text.trim().isNotEmpty ? societyCtrl.text.trim() : null,
                                  keywords: combinedKw,
                                  permissions: selectedPermissions,
                                  canAssignWork: canAssignWork,
                                  joinedDate: memberToEdit?.joinedDate ?? DateTime.now(),
                                );

                                final messenger = ScaffoldMessenger.of(context);
                                final repo = ref.read(teamRepoProvider);
                                if (memberToEdit != null) {
                                  await repo.updateTeamMember(member);
                                } else {
                                  await repo.addTeamMember(member);
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                if (!mounted) return;
                                _loadTeam();

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      memberToEdit != null
                                          ? (isMr ? 'सदस्याची माहिती अद्यतनित केली!' : 'Member updated successfully!')
                                          : (isMr ? 'नवीन सदस्य यशस्वीरित्या जोडला गेला!' : 'New member added successfully!'),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMembers;
    final totalMembers = _teamStats['total'] ?? _allMembers.length;
    final officeCount = _teamStats['office'] ?? 0;
    final partyCount = _teamStats['party'] ?? 0;
    final coopCount = _teamStats['cooperative'] ?? 0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NagarsevakAppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
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
          children: const [
            Text(
              'My Team',
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
              'Nagarsevak office staff, field coordinators and roles',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : RefreshIndicator(
              onRefresh: _loadTeam,
              color: const Color(0xFF0284C7),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // KPI Header Strip
                  _buildKpiStrip(totalMembers, officeCount, partyCount, coopCount),
                  const SizedBox(height: 14),

                  // Search Bar
                  _buildSearchBar(filtered),
                  const SizedBox(height: 10),

                  // Category Tabs & View Mode Row
                  _buildCategoryTabsBar(filtered.length),
                  const SizedBox(height: 14),

                  // Team Members List (Cards or Table)
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else if (_viewMode == 'table')
                    _buildTableView(filtered)
                  else
                    ...filtered.map((m) => _buildTeamCard(m)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('New Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddMemberModal,
      ),
    );
  }

  Widget _buildKpiStrip(int total, int office, int party, int coop) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'Total Members',
            value: '$total',
            subtitle: 'My Team',
            icon: Icons.groups_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'Office Team',
            value: '$office',
            subtitle: 'Office Staff',
            icon: Icons.business_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'Party Cadre',
            value: '$party',
            subtitle: 'Wings & Cells',
            icon: Icons.flag_rounded,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'Municipal / Coop',
            value: '$coop',
            subtitle: 'Municipal & Orgs',
            icon: Icons.handshake_rounded,
            color: const Color(0xFF7C3AED),
            bg: const Color(0xFFEDE9FE),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(List<TeamMemberModel> filtered) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search name, role, wing, area, or keyword...',
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          Container(
            height: 28,
            width: 1,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 20),
            tooltip: 'Help Guide',
            visualDensity: VisualDensity.compact,
            onPressed: _showHelpGuide,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
            tooltip: 'Download Team Report',
            visualDensity: VisualDensity.compact,
            onPressed: () => TeamReportGenerator.generateAndPrintReport(
              staffList: filtered,
              activeCategory: _selectedCategory == 'All' ? 'All Team' : _selectedCategory,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabsBar(int resultCount) {
    final categories = [
      {'key': 'All', 'label': 'All Team'},
      {'key': 'Office', 'label': 'Office Team'},
      {'key': 'Party', 'label': 'Party Cadre'},
      {'key': 'Cooperative', 'label': 'Municipal / Coop'},
    ];

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSel = _selectedCategory == cat['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSel,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat['key']!);
                      _loadTeam();
                    },
                    selectedColor: const Color(0xFF0284C7),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? Colors.white : Colors.grey.shade700,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSel ? const Color(0xFF0284C7) : Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Toggle view
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.grid_view_rounded, size: 17, color: _viewMode == 'cards' ? const Color(0xFF0284C7) : Colors.grey),
                tooltip: 'Card View',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _viewMode = 'cards'),
              ),
              Container(width: 1, height: 18, color: Colors.grey.shade200),
              IconButton(
                icon: Icon(Icons.table_rows_rounded, size: 17, color: _viewMode == 'table' ? const Color(0xFF0284C7) : Colors.grey),
                tooltip: 'Table View',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _viewMode = 'table'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(TeamMemberModel member) {
    final isMr = ref.watch(isMarathiProvider);
    Color catColor = const Color(0xFF0284C7);
    Color catBg = const Color(0xFFE0F2FE);

    if (member.category == 'Party') {
      catColor = const Color(0xFFD97706);
      catBg = const Color(0xFFFEF3C7);
    } else if (member.category == 'Cooperative') {
      catColor = const Color(0xFF7C3AED);
      catBg = const Color(0xFFEDE9FE);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TeamMemberProfileScreen(member: member)),
          ).then((_) => _loadTeam());
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Avatar, Name, Category pill, Role
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: catBg,
                    child: Text(
                      member.displayName.isNotEmpty ? member.displayName.substring(0, 1) : 'S',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: catColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        if (member.name != member.displayName)
                          Text(member.name, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: catBg,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: catColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                member.categoryLabelMarathi,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: catColor),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                member.roleLabelMarathi,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    tooltip: isMr ? 'माहिती सुधारा' : 'Edit Member',
                    onPressed: () => _showMemberModal(memberToEdit: member),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 10),

              // Sub-info: Wing or Society or Area
              if (member.partyWing != null && member.partyWing!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 13, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        '${member.partyWing!} ${member.pad != null ? "• ${member.pad}" : ""}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),

              if (member.societyName != null && member.societyName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment_rounded, size: 13, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          member.societyName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF5B21B6)),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(member.area ?? 'Ward 12', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(width: 8),
                  Icon(Icons.phone_iphone_rounded, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text('+91 ${member.mobile}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                ],
              ),

              // Keywords Chips
              if (member.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: member.keywords.take(4).map((k) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        k,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Quick Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.assignment_add, size: 14, color: Color(0xFF0284C7)),
                    label: const Text('Assign Task', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TeamMemberProfileScreen(member: member)),
                      ).then((_) => _loadTeam());
                    },
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 13, color: Colors.white),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _messageOnWhatsApp(member),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.phone, size: 18, color: Color(0xFF0284C7)),
                    tooltip: 'Call',
                    onPressed: () => _callMember(member.mobile),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(List<TeamMemberModel> list) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columns: const [
              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Role / Designation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Wing / Organization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Work Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: list.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;

              String sub = '-';
              if (m.category == 'Party' && m.partyWing != null) {
                sub = m.partyWing!;
              } else if (m.category == 'Cooperative' && m.societyName != null) {
                sub = m.societyName!;
              }

              return DataRow(
                cells: [
                  DataCell(Text('${idx + 1}', style: const TextStyle(fontSize: 11))),
                  DataCell(
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TeamMemberProfileScreen(member: m)),
                        ).then((_) => _loadTeam());
                      },
                      child: Text(
                        m.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  DataCell(Text(m.roleLabelMarathi, style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.category == 'Office'
                            ? const Color(0xFFE0F2FE)
                            : (m.category == 'Party' ? const Color(0xFFFEF3C7) : const Color(0xFFEDE9FE)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m.categoryLabelMarathi,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: m.category == 'Office'
                              ? const Color(0xFF0284C7)
                              : (m.category == 'Party' ? const Color(0xFFD97706) : const Color(0xFF7C3AED)),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(sub, style: const TextStyle(fontSize: 11))),
                  DataCell(Text(m.area ?? 'Ward 12', style: const TextStyle(fontSize: 11))),
                  DataCell(Text('+91 ${m.mobile}', style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone, size: 16, color: Color(0xFF0284C7)),
                          onPressed: () => _callMember(m.mobile),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, size: 15, color: Color(0xFF25D366)),
                          onPressed: () => _messageOnWhatsApp(m),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No team members found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your search terms or add a new team member.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Add New Member', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _showAddMemberModal,
          ),
        ],
      ),
    );
  }
}
