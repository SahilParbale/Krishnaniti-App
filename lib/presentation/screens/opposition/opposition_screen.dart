import '../../navigation/app_bar_leading_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/opposition_model.dart';
import '../../../data/repositories/opposition_repository.dart';
import '../../navigation/app_drawer.dart';
import 'opposition_detail_screen.dart';
import 'opposition_report_generator.dart';

class OppositionScreen extends ConsumerStatefulWidget {
  const OppositionScreen({super.key});

  @override
  ConsumerState<OppositionScreen> createState() => _OppositionScreenState();
}

class _OppositionScreenState extends ConsumerState<OppositionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'all'; // 'all', 'candidate', 'worker'
  String _selectedParty = 'all'; // 'all', 'INC', 'NCP', 'UBT', 'MNS', 'BJP', 'Independent'
  String _selectedArea = '';
  int _viewMode = 0; // 0 = Cards, 1 = Table

  bool _isLoading = true;
  List<OppositionMemberModel> _members = [];
  Map<String, int> _stats = {
    'total': 0,
    'candidates': 0,
    'workers': 0,
    'controversies': 0,
    'activities': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadOppositionData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOppositionData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(oppositionRepoProvider);

    final members = await repo.getMembers(
      party: _selectedParty == 'all' ? null : _selectedParty,
      type: _selectedType == 'all' ? null : _selectedType,
      area: _selectedArea.isEmpty ? null : _selectedArea,
      query: _searchController.text.trim(),
    );

    final stats = await repo.getOppositionStats();

    if (mounted) {
      setState(() {
        _members = members;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Color _getPartyColor(String party) {
    switch (party.toUpperCase()) {
      case 'INC':
        return const Color(0xFF0284C7);
      case 'NCP':
        return const Color(0xFF10B981);
      case 'UBT':
        return const Color(0xFFF97316);
      case 'MNS':
        return const Color(0xFF8B5CF6);
      case 'BJP':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getCandidacyStatusColor(String? status) {
    switch (status) {
      case 'Won':
        return const Color(0xFF16A34A);
      case 'Lost':
        return const Color(0xFF64748B);
      case 'Withdrawn':
        return const Color(0xFFDC2626);
      case 'Contesting':
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFFD97706);
    }
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ===========================================================================
  // ADD / EDIT OPPOSITION MEMBER MODAL
  // ===========================================================================
  void _showMemberForm({OppositionMemberModel? memberToEdit}) {
    final nameCtrl = TextEditingController(text: memberToEdit?.name ?? '');
    final phoneCtrl = TextEditingController(text: memberToEdit?.mobile ?? '');
    final roleCtrl = TextEditingController(text: memberToEdit?.role ?? '');
    final areaCtrl = TextEditingController(text: memberToEdit?.area ?? '');
    final strongholdsCtrl = TextEditingController(text: memberToEdit != null ? memberToEdit.strongholds.join(', ') : '');
    final notesCtrl = TextEditingController(text: memberToEdit?.notes ?? '');

    bool isCandidate = memberToEdit?.isCandidate ?? false;
    String party = memberToEdit?.party ?? 'INC';
    String candidacyStatus = memberToEdit?.candidacyStatus ?? 'Declared';
    final constCtrl = TextEditingController(text: memberToEdit?.constituency ?? 'Ward 12 (Pune PMC)');
    final oppCtrl = TextEditingController(text: memberToEdit?.opposingCandidate ?? 'Sitting Corporator');
    String? selectedCandidateId = memberToEdit?.candidateId;

    final repo = ref.read(oppositionRepoProvider);
    final candidatesList = _members.where((m) => m.isCandidate && m.id != memberToEdit?.id).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.group_add_rounded, color: Color(0xFF0284C7), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      memberToEdit == null ? 'Add New Opposition Member' : 'Edit Opposition Member',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Record Type Switch: Worker vs Candidate
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => isCandidate = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !isCandidate ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !isCandidate ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
                            ),
                            child: const Text('Opposition Cadre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => isCandidate = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCandidate ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isCandidate ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
                            ),
                            child: const Text('Opposition Candidate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Full Name
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Adv. Ramesh Shinde',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Party & Mobile Row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: party,
                        decoration: InputDecoration(
                          labelText: 'Party *',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'INC', child: Text('Congress (INC)')),
                          DropdownMenuItem(value: 'NCP', child: Text('NCP')),
                          DropdownMenuItem(value: 'UBT', child: Text('Shiv Sena (UBT)')),
                          DropdownMenuItem(value: 'MNS', child: Text('MNS')),
                          DropdownMenuItem(value: 'BJP', child: Text('BJP')),
                          DropdownMenuItem(value: 'Independent', child: Text('Independent (Ind)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => party = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '98220xxxxx',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Role / Designation
                TextField(
                  controller: roleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Role / Designation',
                    hintText: 'e.g. Ex-Corporator, Ward President, Branch Secretary',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Base Area
                TextField(
                  controller: areaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Primary Work Area / Vicinity',
                    hintText: 'e.g. Tilak Chowk, Sector 3, Vitthal Nagar',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // If Candidate: Show Constituency & Candidacy Status
                if (isCandidate) ...[
                  TextField(
                    controller: constCtrl,
                    decoration: InputDecoration(
                      labelText: 'Constituency / Ward',
                      filled: true,
                      fillColor: const Color(0xFFF0F9FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: oppCtrl,
                          decoration: InputDecoration(
                            labelText: 'Opposing Candidate',
                            filled: true,
                            fillColor: const Color(0xFFF0F9FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: candidacyStatus,
                          decoration: InputDecoration(
                            labelText: 'Candidacy Status',
                            filled: true,
                            fillColor: const Color(0xFFF0F9FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Declared', child: Text('Declared')),
                            DropdownMenuItem(value: 'Contesting', child: Text('Contesting')),
                            DropdownMenuItem(value: 'Withdrawn', child: Text('Withdrawn')),
                            DropdownMenuItem(value: 'Won', child: Text('Won')),
                            DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => candidacyStatus = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  // If Worker: Option to link to candidate
                  if (candidatesList.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedCandidateId,
                      decoration: InputDecoration(
                        labelText: 'Link to Candidate (Optional)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Not linked to any candidate')),
                        ...candidatesList.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.party})'))),
                      ],
                      onChanged: (val) => setModalState(() => selectedCandidateId = val),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],

                // Strongholds
                TextField(
                  controller: strongholdsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Strongholds / Active Areas (comma separated)',
                    hintText: 'e.g. Tilak Chowk, Shanti Nagar, Booth 4-6',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Notes / Strategy
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes & Strategy',
                    hintText: 'Local influence, outreach, and political observations...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter opposition member name.')),
                        );
                        return;
                      }

                      final strongholdsList = strongholdsCtrl.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();

                      final newMember = OppositionMemberModel(
                        id: memberToEdit?.id ?? 'opp-${isCandidate ? "cand" : "wrk"}-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        mobile: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                        party: party,
                        role: roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : null,
                        area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : null,
                        strongholds: strongholdsList,
                        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                        isCandidate: isCandidate,
                        constituency: isCandidate ? constCtrl.text.trim() : null,
                        opposingCandidate: isCandidate ? oppCtrl.text.trim() : null,
                        candidacyStatus: isCandidate ? candidacyStatus : null,
                        candidateId: !isCandidate ? selectedCandidateId : null,
                        activities: memberToEdit?.activities ?? [],
                        negativeStories: memberToEdit?.negativeStories ?? [],
                        createdAt: memberToEdit?.createdAt ?? DateTime.now(),
                      );

                      if (memberToEdit == null) {
                        await repo.addMember(newMember);
                      } else {
                        await repo.updateMember(newMember);
                      }

                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _loadOppositionData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(memberToEdit == null ? 'Opposition member added successfully!' : 'Details updated!'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      memberToEdit == null ? 'Add Member' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DELETE CONFIRMATION DIALOG
  // ===========================================================================
  void _confirmDeleteMember(OppositionMemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Opposition Record?'),
        content: Text('Are you sure you want to delete record for "${member.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(oppositionRepoProvider);
              await repo.deleteMember(member.id);
              _loadOppositionData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Record deleted successfully!'), backgroundColor: Color(0xFFDC2626)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(oppositionRepoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBarLeadingNavButton(),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Opposition Information',
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
              'Opposition candidate profiles, past records and public claims',
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
      body: RefreshIndicator(
        onRefresh: _loadOppositionData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. KPI STAT CARDS
              // ==========================================
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Total Records',
                      value: _stats['total']?.toString() ?? '0',
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF0284C7),
                      bg: const Color(0xFFF0F9FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Candidates',
                      value: _stats['candidates']?.toString() ?? '0',
                      icon: Icons.how_to_vote_rounded,
                      color: const Color(0xFF4338CA),
                      bg: const Color(0xFFEEF2FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Cadre',
                      value: _stats['workers']?.toString() ?? '0',
                      icon: Icons.person_search_rounded,
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFFFFBEB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Controversies',
                      value: _stats['controversies']?.toString() ?? '0',
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEF2F2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==========================================
              // 2. SEARCH & VIEW TOGGLE
              // ==========================================
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _loadOppositionData(),
                        decoration: InputDecoration(
                          hintText: 'Search name, role, strongholds or keywords...',
                          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadOppositionData();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // View & Export Controls
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.grid_view_rounded, size: 20, color: _viewMode == 0 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _viewMode = 0),
                          tooltip: 'Card View',
                        ),
                        IconButton(
                          icon: Icon(Icons.table_rows_rounded, size: 20, color: _viewMode == 1 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _viewMode = 1),
                          tooltip: 'Table View',
                        ),
                        Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFFDC2626)),
                          tooltip: 'Download PDF Report',
                          onPressed: () {
                            OppositionReportGenerator.generateAndPrintReport(
                              members: _members,
                              getCandidateName: repo.getCandidateName,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==========================================
              // 3. FILTER TABS: RECORD TYPE & PARTY
              // ==========================================
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All (${_stats['total']})', 'all', _selectedType, (val) {
                      setState(() => _selectedType = val);
                      _loadOppositionData();
                    }),
                    const SizedBox(width: 6),
                    _buildFilterChip('Candidates (${_stats['candidates']})', 'candidate', _selectedType, (val) {
                      setState(() => _selectedType = val);
                      _loadOppositionData();
                    }),
                    const SizedBox(width: 6),
                    _buildFilterChip('Cadre (${_stats['workers']})', 'worker', _selectedType, (val) {
                      setState(() => _selectedType = val);
                      _loadOppositionData();
                    }),
                    const SizedBox(width: 14),

                    // Party Filters
                    Container(height: 18, width: 1, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 14),
                    _buildPartyFilterChip('All Parties', 'all'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip('Congress', 'INC'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip('NCP', 'NCP'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip('Shiv Sena (UBT)', 'UBT'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip('MNS', 'MNS'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip('BJP', 'BJP'),
                    const SizedBox(width: 6),
                    _buildPartyFilterChip('Independent', 'Independent'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================
              // 4. MAIN CONTENT (CARDS OR TABLE)
              // ==========================================
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_members.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_off_outlined, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No opposition members found.',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Use the "+ Add Member" button above to create a record.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showMemberForm(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Opposition Member'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_viewMode == 0)
                // CARDS VIEW
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final member = _members[idx];
                    return _buildMemberCard(member, repo);
                  },
                )
              else
                // SPREADSHEET TABLE VIEW
                _buildSpreadsheetTable(repo),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMemberForm(),
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ===========================================================================
  // WIDGET HELPERS
  // ===========================================================================
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, ValueChanged<String> onSelect) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildPartyFilterChip(String label, String partyCode) {
    final isSelected = _selectedParty == partyCode;
    return InkWell(
      onTap: () {
        setState(() => _selectedParty = partyCode);
        _loadOppositionData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(OppositionMemberModel member, OppositionRepository repo) {
    final partyColor = _getPartyColor(member.party);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OppositionDetailScreen(member: member)),
        );
        _loadOppositionData();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: member.isCandidate ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
            width: member.isCandidate ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Edit/Delete Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: partyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: partyColor.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Icon(
                      member.isCandidate ? Icons.campaign_rounded : Icons.person_outline_rounded,
                      color: partyColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                          if (member.isCandidate)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.role ?? (member.isCandidate ? 'Candidate' : 'Cadre'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),

                      // Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: partyColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: partyColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              member.partyFullLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: partyColor),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: member.isCandidate ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              member.typeLabelMarathi,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: member.isCandidate ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          if (member.isCandidate && member.candidacyStatus != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getCandidacyStatusColor(member.candidacyStatus).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                member.candidacyStatusLabelMarathi,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getCandidacyStatusColor(member.candidacyStatus),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Edit/Delete Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showMemberForm(memberToEdit: member);
                    } else if (val == 'delete') {
                      _confirmDeleteMember(member);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Middle Row: Contact & Base Area
            Row(
              children: [
                if (member.mobile != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(member.mobile!, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _makePhoneCall(member.mobile),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.phone, size: 13, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _openWhatsApp(member.mobile),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (member.area != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            member.area!,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Strongholds chips
            if (member.strongholds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: member.strongholds.take(3).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 10),

            // Bottom Action Bar: Activities count, Controversies badge & View details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (member.negativeStories.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Text(
                              '${member.negativeStories.length} Controversies',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (member.activities.isNotEmpty)
                      Text(
                        '${member.activities.length} Activities',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'Detailed Profile',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0284C7)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SPREADSHEET TABLE VIEW
  // ===========================================================================
  Widget _buildSpreadsheetTable(OppositionRepository repo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              DataColumn(label: Text('Party', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Role / Designation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Work Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Strongholds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Status / Candidate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Issues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: List.generate(_members.length, (index) {
              final m = _members[index];
              final partyColor = _getPartyColor(m.party);

              String statusOrCand = '-';
              if (m.isCandidate) {
                statusOrCand = m.candidacyStatusLabelMarathi;
              } else if (m.candidateId != null && m.candidateId!.isNotEmpty) {
                statusOrCand = repo.getCandidateName(m.candidateId!);
              }

              return DataRow(
                cells: [
                  DataCell(Text((index + 1).toString(), style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Text(
                      m.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: partyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(m.party, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: partyColor)),
                    ),
                  ),
                  DataCell(
                    Text(
                      m.typeLabelMarathi,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: m.isCandidate ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  DataCell(Text(m.role ?? '-', style: const TextStyle(fontSize: 11))),
                  DataCell(Text(m.area ?? '-', style: const TextStyle(fontSize: 11))),
                  DataCell(Text(m.strongholds.take(2).join(', '), style: const TextStyle(fontSize: 11))),
                  DataCell(Text(statusOrCand, style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Text(
                      m.negativeStories.length.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: m.negativeStories.isNotEmpty ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OppositionDetailScreen(member: m)),
                        );
                        _loadOppositionData();
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

