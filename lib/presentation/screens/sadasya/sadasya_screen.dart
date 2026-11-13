import '../../navigation/app_bar_leading_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/sadasya_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/sadasya_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../navigation/app_drawer.dart';
import 'sadasya_profile_screen.dart';
import 'sadasya_report_generator.dart';

class SadasyaScreen extends ConsumerStatefulWidget {
  const SadasyaScreen({super.key});

  @override
  ConsumerState<SadasyaScreen> createState() => _SadasyaScreenState();
}

class _SadasyaScreenState extends ConsumerState<SadasyaScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  List<SadasyaModel> _allMembers = [];
  String _selectedArea = 'All';
  String _voterFilter = 'all'; // 'all', 'voter', 'non-voter'
  String _displayMode = 'cards'; // 'cards' or 'table'
  Map<String, int> _areaCounts = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final repo = ref.read(sadasyaRepoProvider);

    final members = await repo.getSadasyas();
    final areas = await repo.getAreasWithCount();

    if (mounted) {
      setState(() {
        _allMembers = members;
        _areaCounts = areas;
        _isLoading = false;
      });
    }
  }

  List<SadasyaModel> get _filteredMembers {
    var list = List<SadasyaModel>.from(_allMembers);

    // Search query filter
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((m) {
        return m.name.toLowerCase().contains(q) ||
            (m.nameMarathi?.toLowerCase().contains(q) ?? false) ||
            (m.nameEnglish?.toLowerCase().contains(q) ?? false) ||
            m.mobile.replaceAll(' ', '').contains(q.replaceAll(' ', '')) ||
            (m.voterId?.toLowerCase().contains(q) ?? false) ||
            m.displayAddress.toLowerCase().contains(q);
      }).toList();
    }

    // Area filter
    if (_selectedArea != 'All') {
      list = list.where((m) => m.area == _selectedArea).toList();
    }

    // Voter filter
    if (_voterFilter == 'voter') {
      list = list.where((m) => m.isVoter).toList();
    } else if (_voterFilter == 'non-voter') {
      list = list.where((m) => !m.isVoter).toList();
    }

    return list;
  }

  Future<void> _makeCall(String number) async {
    final clean = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String number, String name) async {
    final clean = number.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$clean?text=Hello $name,');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final totalCount = _allMembers.length;
    final voterCount = _allMembers.where((m) => m.isVoter).length;
    final nonVoterCount = totalCount - voterCount;
    final activeAreasCount = _areaCounts.keys.length;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NagarsevakAppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF0284C7)),
                  SizedBox(height: 16),
                  Text(
                    'Loading party members...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMembers,
              color: const Color(0xFF0284C7),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Summary Banner
                    _buildHeaderBanner(totalCount),

                    const SizedBox(height: 14),

                    // 4 KPI Summary Cards
                    _buildKpiStatsGrid(totalCount, voterCount, nonVoterCount, activeAreasCount),

                    const SizedBox(height: 16),

                    // Controls: Search, Area Pills & View Switcher
                    _buildSearchAndFilters(),

                    const SizedBox(height: 12),

                    // List / Table
                    if (_filteredMembers.isEmpty)
                      _buildEmptyState()
                    else if (_displayMode == 'table' || isDesktop)
                      _buildTableView()
                    else
                      _buildCardsView(),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMemberDialog,
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Member',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0284C7),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: const AppBarLeadingNavButton(),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Sadasya (Members)',
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
            'Party workers, active booth members and volunteer register',
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
    );
  }

  Widget _buildHeaderBanner(int totalCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFF0284C7), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ward 12 Party Organization & Cadre',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Booth in-charges, ward coordinators & registered members',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Text(
              'Total: $totalCount',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 20),
            tooltip: 'Help Guide',
            visualDensity: VisualDensity.compact,
            onPressed: _showHelpGuide,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
            tooltip: 'Download PDF Report',
            visualDensity: VisualDensity.compact,
            onPressed: _exportPdfReport,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStatsGrid(int total, int voters, int nonVoters, int areas) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final cardTotal = _buildKpiCard(
          'Total Cadre',
          '$total',
          'Registered Cadre',
          Icons.group_rounded,
          const Color(0xFF0284C7),
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
        );

        final cardVoters = _buildKpiCard(
          'Voter Members',
          '$voters',
          'Registered Voters',
          Icons.how_to_vote_rounded,
          const Color(0xFF16A34A),
          const Color(0xFFF0FDF4),
          const Color(0xFFBBF7D0),
        );

        final cardNonVoters = _buildKpiCard(
          'Other Members',
          '$nonVoters',
          'Direct Cadre',
          Icons.person_outline_rounded,
          const Color(0xFFA855F7),
          const Color(0xFFFAF5FF),
          const Color(0xFFE9D5FF),
        );

        final cardAreas = _buildKpiCard(
          'Active Areas',
          '$areas',
          'Shaniwar, Kasba, etc.',
          Icons.location_city_rounded,
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cardTotal),
              const SizedBox(width: 10),
              Expanded(child: cardVoters),
              const SizedBox(width: 10),
              Expanded(child: cardNonVoters),
              const SizedBox(width: 10),
              Expanded(child: cardAreas),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cardTotal),
                const SizedBox(width: 10),
                Expanded(child: cardVoters),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: cardNonVoters),
                const SizedBox(width: 10),
                Expanded(child: cardAreas),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(
      String title, String value, String subtitle, IconData icon, Color iconColor, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: iconColor),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search Bar & View Mode Toggle
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name, mobile, or address...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Card / Table toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildViewButton(
                    icon: Icons.view_agenda_outlined,
                    tooltip: 'Card View',
                    isSelected: _displayMode == 'cards',
                    onTap: () => setState(() => _displayMode = 'cards'),
                  ),
                  _buildViewButton(
                    icon: Icons.table_chart_outlined,
                    tooltip: 'Table View',
                    isSelected: _displayMode == 'table',
                    onTap: () => setState(() => _displayMode = 'table'),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Voter Type Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTypeFilterChip('all', 'All Members (${_allMembers.length})'),
              const SizedBox(width: 8),
              _buildTypeFilterChip('voter', 'Registered Voters (${_allMembers.where((m) => m.isVoter).length})'),
              const SizedBox(width: 8),
              _buildTypeFilterChip('non-voter', 'Party Members Only (${_allMembers.where((m) => !m.isVoter).length})'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Area Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAreaChip('All', 'All Areas'),
              ..._areaCounts.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _buildAreaChip(entry.key, '${entry.key} (${entry.value})'),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String key, String label) {
    final isSelected = _voterFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _voterFilter = key),
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    );
  }

  Widget _buildAreaChip(String areaKey, String label) {
    final isSelected = _selectedArea == areaKey;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? const Color(0xFF0369A1) : const Color(0xFF64748B),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedArea = areaKey),
      selectedColor: const Color(0xFFE0F2FE),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildCardsView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredMembers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = _filteredMembers[index];

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: InkWell(
            onTap: () => _openProfileScreen(member),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFE0F2FE),
                        child: Text(
                          member.initials,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (member.nameEnglish != null && member.nameEnglish != member.displayName)
                              Text(
                                member.nameEnglish!,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: member.isVoter ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: member.isVoter ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    member.isVoter ? 'Registered Voter' : 'Party Member',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: member.isVoter ? const Color(0xFF15803D) : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                if (member.role != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      member.role!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val == 'profile') {
                            _openProfileScreen(member);
                          } else if (val == 'edit') {
                            _openEditMemberDialog(member);
                          } else if (val == 'delete') {
                            _confirmDeleteMember(member);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.account_circle_outlined, size: 18, color: Color(0xFF0284C7)),
                                SizedBox(width: 8),
                                Text('View Profile', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                                SizedBox(width: 8),
                                Text('Edit Member', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                SizedBox(width: 8),
                                Text('Remove', style: TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

                  // Area & Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        member.area ?? member.ward ?? 'Shaniwar Peth',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          member.displayAddress,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Contact Quick Action Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF0284C7)),
                          const SizedBox(width: 4),
                          Text(
                            member.mobile,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _makeCall(member.mobile),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.call_rounded, size: 13, color: Color(0xFF0284C7)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Call',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _openWhatsApp(member.mobile, member.displayName),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'WhatsApp',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 16,
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _filteredMembers.map((m) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => _openProfileScreen(m),
                  ),
                  DataCell(Text(m.mobile)),
                  DataCell(Text(m.area ?? m.ward ?? '-')),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(m.displayAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.isVoter ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m.isVoter ? 'Voter' : 'Member',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: m.isVoter ? const Color(0xFF15803D) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(m.role ?? '-')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call_rounded, size: 16, color: Color(0xFF0284C7)),
                          onPressed: () => _makeCall(m.mobile),
                          tooltip: 'Call',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                          onPressed: () => _openEditMemberDialog(m),
                          tooltip: 'Edit',
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No party members found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adjust your filters or click "Add Member" button',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _openProfileScreen(SadasyaModel member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SadasyaProfileScreen(
          member: member,
          onEdit: () {
            Navigator.pop(context);
            _openEditMemberDialog(member);
          },
          onDelete: () async {
            Navigator.pop(context);
            final repo = ref.read(sadasyaRepoProvider);
            await repo.deleteSadasya(member.id);
            await _loadMembers();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.displayName} removed from members list.')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showHelpGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Party Members Management Guide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Member Registration from Voter List:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'Click "Add Member" and find voters in the ward from the first tab to register them directly as party members.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              SizedBox(height: 12),
              Text(
                '2. Direct New Member Registration:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'In the second tab, fill in name, mobile, ward, and address to directly register a new party worker.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              SizedBox(height: 12),
              Text(
                '3. Direct Contact (Call / WhatsApp):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'Direct calling and WhatsApp messaging options are available on each member card.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              SizedBox(height: 12),
              Text(
                '4. Official PDF Report:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'Click the "PDF Report" icon above to generate and export the official ward report.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdfReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating party cadre official PDF report...'),
          duration: Duration(seconds: 2),
        ),
      );

      await SadasyaReportGenerator.generateAndPrintReport(
        members: _filteredMembers,
        areaFilter: _selectedArea,
        typeFilter: _voterFilter,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openAddMemberDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddSadasyaModal(
        onMemberAdded: () async {
          await _loadMembers();
        },
      ),
    );
  }

  void _openEditMemberDialog(SadasyaModel member) {
    final nameCtrl = TextEditingController(text: member.name);
    final mobileCtrl = TextEditingController(text: member.mobile);
    final ageCtrl = TextEditingController(text: member.age > 0 ? member.age.toString() : '');
    final areaCtrl = TextEditingController(text: member.area ?? 'Shaniwar Peth');
    final addressCtrl = TextEditingController(text: member.displayAddress);
    final roleCtrl = TextEditingController(text: member.role ?? 'Active Member');
    String gender = member.gender;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Member Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: gender,
                        decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                          DropdownMenuItem(value: 'O', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => gender = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: areaCtrl,
                  decoration: const InputDecoration(labelText: 'Area / Region', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(labelText: 'Role / Designation', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final mobile = mobileCtrl.text.trim();
                if (name.isEmpty || mobile.isEmpty) return;

                final updated = member.copyWith(
                  name: name,
                  nameMarathi: name,
                  mobile: mobile,
                  age: int.tryParse(ageCtrl.text.trim()) ?? member.age,
                  gender: gender,
                  area: areaCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  addressMarathi: addressCtrl.text.trim(),
                  role: roleCtrl.text.trim(),
                );

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final repo = ref.read(sadasyaRepoProvider);
                await repo.updateSadasya(updated);
                await _loadMembers();

                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Member details updated successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMember(SadasyaModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Remove Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${member.displayName}" from members list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final repo = ref.read(sadasyaRepoProvider);
              await repo.deleteSadasya(member.id);
              await _loadMembers();

              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('${member.displayName} removed from members list.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Modal Sheet with Dual Tabs (Search Voter / Direct Entry) matching SadasyaList.tsx
class _AddSadasyaModal extends ConsumerStatefulWidget {
  final Future<void> Function() onMemberAdded;

  const _AddSadasyaModal({required this.onMemberAdded});

  @override
  ConsumerState<_AddSadasyaModal> createState() => _AddSadasyaModalState();
}

class _AddSadasyaModalState extends ConsumerState<_AddSadasyaModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Voter Search Tab State
  final TextEditingController _voterSearchCtrl = TextEditingController();
  List<VoterModel> _voterResults = [];
  bool _isSearchingVoters = false;
  VoterModel? _selectedVoter;
  final TextEditingController _confirmMobileCtrl = TextEditingController(text: '+91 ');
  final TextEditingController _confirmAreaCtrl = TextEditingController(text: 'Shaniwar Peth');
  final TextEditingController _confirmRoleCtrl = TextEditingController(text: 'Booth Cadre');

  // Manual Tab State
  final TextEditingController _manualNameCtrl = TextEditingController();
  final TextEditingController _manualMobileCtrl = TextEditingController(text: '+91 ');
  final TextEditingController _manualAgeCtrl = TextEditingController();
  final TextEditingController _manualAreaCtrl = TextEditingController(text: 'Shaniwar Peth');
  final TextEditingController _manualAddressCtrl = TextEditingController();
  final TextEditingController _manualRoleCtrl = TextEditingController(text: 'Active Member');
  String _manualGender = 'M';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voterSearchCtrl.dispose();
    _confirmMobileCtrl.dispose();
    _confirmAreaCtrl.dispose();
    _confirmRoleCtrl.dispose();
    _manualNameCtrl.dispose();
    _manualMobileCtrl.dispose();
    _manualAgeCtrl.dispose();
    _manualAreaCtrl.dispose();
    _manualAddressCtrl.dispose();
    _manualRoleCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchVoters(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _voterResults = []);
      return;
    }

    setState(() => _isSearchingVoters = true);
    final repo = ref.read(votersRepoProvider);

    try {
      final results = await repo.searchVoters(query: query.trim(), pageSize: 20);
      if (mounted) {
        setState(() {
          _voterResults = results;
          _isSearchingVoters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearchingVoters = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Party Member',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0284C7),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0284C7),
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.how_to_vote_rounded, size: 18),
                text: 'Add from Voter List',
              ),
              Tab(
                icon: Icon(Icons.edit_note_rounded, size: 18),
                text: 'Direct Registration',
              ),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVoterSearchTab(),
                _buildManualEntryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoterSearchTab() {
    if (_selectedVoter != null) {
      // Step 2: Confirm selected voter
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _selectedVoter = null),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Confirm Member Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedVoter!.displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                  const SizedBox(height: 4),
                  Text('EPIC: ${_selectedVoter!.epicNo} • Age: ${_selectedVoter!.age} • Booth: ${_selectedVoter!.booth}'),
                  const SizedBox(height: 2),
                  Text('Address: ${_selectedVoter!.address}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmMobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmAreaCtrl,
              decoration: const InputDecoration(
                labelText: 'Area / Region *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmRoleCtrl,
              decoration: const InputDecoration(
                labelText: 'Role / Designation (e.g. Booth Head)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSelectedVoterAsMember,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add as Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _voterSearchCtrl,
            onChanged: _searchVoters,
            decoration: InputDecoration(
              hintText: 'Search by voter name, EPIC No. or mobile...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          if (_isSearchingVoters)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_voterResults.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Type voter name or EPIC number above to search voters',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _voterResults.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final v = _voterResults[idx];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE0F2FE),
                      child: Text(
                        v.displayName.isNotEmpty ? v.displayName.characters.first : 'M',
                        style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(v.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('EPIC: ${v.epicNo} • Booth: ${v.booth} • Age: ${v.age}'),
                    trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7)),
                    onTap: () {
                      setState(() {
                        _selectedVoter = v;
                        if (v.mobile != null && v.mobile!.isNotEmpty) {
                          _confirmMobileCtrl.text = v.mobile!;
                        }
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _manualNameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manualMobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualAgeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _manualGender,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Male')),
                    DropdownMenuItem(value: 'F', child: Text('Female')),
                    DropdownMenuItem(value: 'O', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _manualGender = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manualAreaCtrl,
            decoration: const InputDecoration(labelText: 'Area / Region (e.g. Shaniwar Peth) *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manualAddressCtrl,
            decoration: const InputDecoration(labelText: 'Residential Address *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manualRoleCtrl,
            decoration: const InputDecoration(labelText: 'Role / Designation', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveManualMember,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Register Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelectedVoterAsMember() async {
    final voter = _selectedVoter;
    if (voter == null) return;

    final mobile = _confirmMobileCtrl.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter mobile number')));
      return;
    }

    final newMember = SadasyaModel(
      id: 'sad-${DateTime.now().millisecondsSinceEpoch}',
      name: voter.displayName,
      nameMarathi: voter.nameMarathi,
      nameEnglish: voter.nameEnglish,
      mobile: mobile,
      age: voter.age,
      gender: voter.gender,
      ward: 'Ward 12',
      area: _confirmAreaCtrl.text.trim().isNotEmpty ? _confirmAreaCtrl.text.trim() : 'Shaniwar Peth',
      address: voter.address,
      addressMarathi: voter.address,
      addressEnglish: voter.address,
      isVoter: true,
      voterId: voter.epicNo,
      linkedVoterId: voter.id,
      status: 'Active',
      role: _confirmRoleCtrl.text.trim().isNotEmpty ? _confirmRoleCtrl.text.trim() : 'Active Member',
      registeredAt: DateTime.now(),
    );

    final repo = ref.read(sadasyaRepoProvider);
    await repo.addSadasya(newMember);

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      await widget.onMemberAdded();
      messenger.showSnackBar(
        SnackBar(content: Text('${voter.displayName} registered as party member!')),
      );
    }
  }

  Future<void> _saveManualMember() async {
    final name = _manualNameCtrl.text.trim();
    final mobile = _manualMobileCtrl.text.trim();
    final address = _manualAddressCtrl.text.trim();
    final area = _manualAreaCtrl.text.trim();

    if (name.isEmpty || mobile.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name, mobile and address')));
      return;
    }

    final newMember = SadasyaModel(
      id: 'sad-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      nameMarathi: name,
      mobile: mobile,
      age: int.tryParse(_manualAgeCtrl.text.trim()) ?? 0,
      gender: _manualGender,
      ward: 'Ward 12',
      area: area.isNotEmpty ? area : 'Shaniwar Peth',
      address: address,
      addressMarathi: address,
      isVoter: false,
      status: 'Active',
      role: _manualRoleCtrl.text.trim().isNotEmpty ? _manualRoleCtrl.text.trim() : 'Active Member',
      registeredAt: DateTime.now(),
    );

    final repo = ref.read(sadasyaRepoProvider);
    await repo.addSadasya(newMember);

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      await widget.onMemberAdded();
      messenger.showSnackBar(
        SnackBar(content: Text('$name registered as new party member!')),
      );
    }
  }
}
