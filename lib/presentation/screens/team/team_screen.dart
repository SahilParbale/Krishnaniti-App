import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
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
      'सस्नेह नमस्कार ${member.displayName},\n'
      'प्रभाग क्र. १२ नगरसेवक कार्यालयामार्फत संपर्क करत आहोत.',
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
                        'माझा कार्यसंघ (My Team) मार्गदर्शक',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'कार्यालयीन कर्मचारी व काम वाटप व्यवस्था',
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
              title: '१. कार्यालयीन टीम (Office Team)',
              desc: 'कार्यालय प्रशासक, जनसंपर्क अधिकारी, वाहन चालक, शिपाई व मदतनीस.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.flag_rounded,
              title: '२. पक्ष व संघटना कार्यकर्ते (Party Workers)',
              desc: 'युवक आघाडी, महिला आघाडी, सोशल मीडिया सेल व ज्येष्ठ नागरिक सेल पदाधिकारी.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.handshake_rounded,
              title: '३. शासकीय व सहकार (Cooperative & Municipal)',
              desc: 'मनपा ड्रेनेज, पाणीपुरवठा, महावितरण वीज कर्मचारी व सोसायटी चेअरमन प्रतिनिधी.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.auto_fix_high_rounded,
              title: '४. ऑटो-असाईन कीवर्ड नियम (Auto Assignment)',
              desc: 'नागरिकांच्या तक्रारीतील विषयानुसार (उदा. पाणी, लाईट, कचरा) संबंधित कर्मचाऱ्याकडे तक्रार आपोआप वर्ग होते.',
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
                child: const Text('समजले', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showAddMemberModal() {
    final nameCtrl = TextEditingController();
    final nameMrCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'शनिवार पेठ');
    final keywordsCtrl = TextEditingController();
    final societyCtrl = TextEditingController();
    String category = 'Office';
    String wing = 'युवक आघाडी';

    final wings = ref.read(teamRepoProvider).getPartyWings();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_rounded, color: Color(0xFF0284C7), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('नवीन टीम सदस्य जोडा (Add Member)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Toggle Segment
                    const Text('श्रेणी (Category)*', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        {'key': 'Office', 'label': 'ऑफिस टीम'},
                        {'key': 'Party', 'label': 'पक्ष कार्यकर्ते'},
                        {'key': 'Cooperative', 'label': 'शासकीय/सहकार'},
                      ].map((c) {
                        final isSel = category == c['key'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ChoiceChip(
                              label: Text(c['label']!),
                              selected: isSel,
                              onSelected: (_) => setModalState(() => category = c['key']!),
                              selectedColor: const Color(0xFF0284C7),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Name (Marathi)
                    const Text('पूर्ण नाव (मराठी)*', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: nameMrCtrl,
                      decoration: InputDecoration(
                        hintText: 'उदा. रमेश बाळासाहेब कदम',
                        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Name (English)
                    const Text('पूर्ण नाव (English)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Ramesh Balasaheb Kadam',
                        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Mobile & Role Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('मोबाईल नंबर*', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextField(
                                controller: mobileCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '9822011223',
                                  prefixText: '+91 ',
                                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
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
                              const Text('पद / भूमिका*', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextField(
                                controller: roleCtrl,
                                decoration: InputDecoration(
                                  hintText: category == 'Office' ? 'कार्यालय प्रशासक' : (category == 'Party' ? 'प्रभाग अध्यक्ष' : 'प्लंबर / वीज कामगार'),
                                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Conditional: Wing for Party or Society for Cooperative
                    if (category == 'Party') ...[
                      const Text('पक्ष आघाडी / कक्ष (Wing)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: wing,
                            isExpanded: true,
                            items: wings.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => wing = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else if (category == 'Cooperative') ...[
                      const Text('सोसायटी किंवा शासकीय कार्यालय नाव', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: societyCtrl,
                        decoration: InputDecoration(
                          hintText: 'उदा. शनिवार पेठ फेडरेशन किंवा मनपा ड्रेनेज शाखा',
                          hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Area & Keywords
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('कार्यक्षेत्र (Area)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextField(
                                controller: areaCtrl,
                                decoration: InputDecoration(
                                  hintText: 'उदा. शनिवार पेठ',
                                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
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
                              const Text('ऑटो-कीवर्ड (अल्पविरामाने)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextField(
                                controller: keywordsCtrl,
                                decoration: InputDecoration(
                                  hintText: 'उदा. पाणी, ड्रेनेज, लाईट',
                                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameMrCtrl.text.trim().isEmpty && nameCtrl.text.trim().isEmpty) return;
                          if (mobileCtrl.text.trim().isEmpty) return;

                          final kw = keywordsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                          final newMember = TeamMemberModel(
                            id: 'stf-${DateTime.now().millisecondsSinceEpoch}',
                            name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : nameMrCtrl.text.trim(),
                            nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : null,
                            mobile: mobileCtrl.text.trim(),
                            role: roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : 'Staff',
                            category: category,
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'प्रभाग १२',
                            partyWing: category == 'Party' ? wing : null,
                            societyName: category == 'Cooperative' ? societyCtrl.text.trim() : null,
                            keywords: kw,
                            joinedDate: DateTime.now(),
                          );

                          final repo = ref.read(teamRepoProvider);
                          await repo.addTeamMember(newMember);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          _loadTeam();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('नवीन सदस्य यशस्वीरीत्या जोडला गेला!'), backgroundColor: Color(0xFF16A34A)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('सदस्य जतन करा (Save Member)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
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
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'माझा कार्यसंघ (My Team)',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'कार्यालयीन कर्मचारी, कार्यकर्ते व काम वाटप व्यवस्था',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: 'टीम अहवाल डाउनलोड करा',
            onPressed: () => TeamReportGenerator.generateAndPrintReport(
              staffList: filtered,
              activeCategory: _selectedCategory == 'All' ? 'सर्व टीम' : _selectedCategory,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'मदत व माहिती',
            onPressed: _showHelpGuide,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'रिफ्रेश',
            onPressed: _loadTeam,
          ),
        ],
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
                  _buildSearchBar(),
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
        label: const Text('नवीन सदस्य', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddMemberModal,
      ),
    );
  }

  Widget _buildKpiStrip(int total, int office, int party, int coop) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'एकूण सदस्य',
            value: '$total',
            subtitle: 'माझा कार्यसंघ',
            icon: Icons.groups_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'ऑफिस टीम',
            value: '$office',
            subtitle: 'कार्यालयीन कर्मचारी',
            icon: Icons.business_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'पक्ष कार्यकर्ते',
            value: '$party',
            subtitle: 'आघाड्या व कक्ष',
            icon: Icons.flag_rounded,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'शासकीय/सहकार',
            value: '$coop',
            subtitle: 'मनपा व संस्था',
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'नाव, पद, आघाडी, परिसर किंवा कीवर्ड शोधा...',
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
    );
  }

  Widget _buildCategoryTabsBar(int resultCount) {
    final categories = [
      {'key': 'All', 'label': 'सर्व टीम'},
      {'key': 'Office', 'label': 'कार्यालयीन (Office)'},
      {'key': 'Party', 'label': 'पक्ष कार्यकर्ते (Party)'},
      {'key': 'Cooperative', 'label': 'शासकीय/सहकार'},
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
                tooltip: 'कार्ड दृश्य',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _viewMode = 'cards'),
              ),
              Container(width: 1, height: 18, color: Colors.grey.shade200),
              IconButton(
                icon: Icon(Icons.table_rows_rounded, size: 17, color: _viewMode == 'table' ? const Color(0xFF0284C7) : Colors.grey),
                tooltip: 'तक्ता दृश्य',
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
                  Text(member.area ?? 'प्रभाग १२', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
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
                    label: const Text('काम सोपवा', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
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
                    label: const Text('व्हॉट्सॲप', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    tooltip: 'कॉल करा',
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
              DataColumn(label: Text('नाव', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('भूमिका / पद', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('श्रेणी', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('आघाडी / संस्था', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('कार्यक्षेत्र', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('मोबाईल', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('कृती', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                  DataCell(Text(m.area ?? 'प्रभाग १२', style: const TextStyle(fontSize: 11))),
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
            'कोणताही सदस्य आढळला नाही',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            'शोध शब्द तपासून पहा किंवा नवीन सदस्य जोडा.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('नवीन सदस्य जोडा', style: TextStyle(color: Colors.white)),
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
