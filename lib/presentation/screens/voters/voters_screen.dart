import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/voter_model.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../navigation/app_bar_leading_nav_button.dart';
import 'voter_profile_screen.dart';
import 'voter_slip_generator.dart';

class VotersScreen extends ConsumerStatefulWidget {
  const VotersScreen({super.key});

  @override
  ConsumerState<VotersScreen> createState() => _VotersScreenState();
}

class _VotersScreenState extends ConsumerState<VotersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  List<VoterModel> _allVoters = [];
  Map<String, int> _voterStats = {};
  List<String> _boothsList = [];

  String _selectedBooth = 'All';
  String _selectedFavour = 'All'; // 'All', 'Favourable', 'Neutral', 'Against', 'Swing'
  String _selectedGender = 'All'; // 'All', 'M', 'F', 'O'
  String _selectedAgeRange = 'All'; // 'All', '18-25', '26-40', '41-60', '60+'
  bool _friendsOnly = false;
  String _viewMode = 'cards'; // 'cards', 'family', 'table'

  @override
  void initState() {
    super.initState();
    _loadVoters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoading = true);
    final repo = ref.read(votersRepoProvider);

    final voters = await repo.searchVoters(
      query: _searchCtrl.text.trim(),
      boothFilter: _selectedBooth != 'All' ? _selectedBooth : null,
      favourFilter: _selectedFavour != 'All' ? _selectedFavour : null,
      genderFilter: _selectedGender != 'All' ? _selectedGender : null,
      ageRangeFilter: _selectedAgeRange != 'All' ? _selectedAgeRange : null,
      isFriendOnly: _friendsOnly,
      pageSize: 100,
    );
    final stats = await repo.getVotersStats();
    final booths = await repo.getBoothsList();

    if (mounted) {
      setState(() {
        _allVoters = voters;
        _voterStats = stats;
        _boothsList = booths;
        _isLoading = false;
      });
    }
  }

  List<VoterModel> get _filteredVoters {
    var list = List<VoterModel>.from(_allVoters);
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((v) {
        return v.nameMarathi.toLowerCase().contains(q) ||
            v.nameEnglish.toLowerCase().contains(q) ||
            v.epicNo.toLowerCase().contains(q) ||
            v.address.toLowerCase().contains(q) ||
            (v.mobile?.contains(q) ?? false) ||
            (v.serialNo?.toString().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  /// Groups voters by houseNo and booth
  Map<String, List<VoterModel>> get _groupedFamilies {
    final Map<String, List<VoterModel>> map = {};
    for (final v in _filteredVoters) {
      final key = '${v.houseNo ?? "Unknown"}_${v.booth}';
      map.putIfAbsent(key, () => []).add(v);
    }
    return map;
  }

  void _callVoter(String? mobile) async {
    if (mobile == null || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number not available for this voter')),
      );
      return;
    }
    final url = Uri.parse('tel:+91$mobile');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  void _shareSlipOnWhatsApp(VoterModel voter) async {
    final mobile = voter.mobile != null ? voter.mobile!.replaceAll(RegExp(r'\D'), '') : '';
    final msg = Uri.encodeComponent(
      'Greetings ${voter.displayName},\n\n'
      'Your official Ward 12 voter slip details:\n\n'
      '*Voter Name:* ${voter.displayName}\n'
      '*EPIC No:* ${voter.epicNo}\n'
      '*Booth / Part No:* ${voter.booth}\n'
      '*Serial No in Roll:* #${voter.serialNo ?? "-"}\n'
      '*Polling Station:* ${voter.displayPollingStation}\n'
      '*Address:* ${voter.address}\n\n'
      'Please carry an identity card (EPIC or Aadhaar Card) on voting day.\n\n'
      '- Office of Corporator, Ward 12',
    );

    Uri url;
    if (mobile.isNotEmpty) {
      url = Uri.parse('https://wa.me/91$mobile?text=$msg');
    } else {
      url = Uri.parse('https://wa.me/?text=$msg');
    }

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
                  child: const Icon(Icons.person_search_rounded, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voter Search & Management',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ward 12 Digital Electoral Roll System',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildHelpPoint(
              icon: Icons.search_rounded,
              title: 'Instant Multi-Search',
              desc:
                  'Search instantly by name, EPIC number, address, mobile, or roll serial number.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.badge_outlined,
              title: 'Official Voter Slip',
              desc:
                  'Send official slip via WhatsApp in 1-tap or print PDF directly.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.family_restroom_rounded,
              title: 'Family Grouping',
              desc:
                  'Group all voters by house number and view household relationships.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.how_to_vote_outlined,
              title: 'Political Stance Tagging',
              desc:
                  'Tag voter stance as Favourable, Neutral, Against, or Undecided for ward strategy.',
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBooth = 'All';
                          _selectedFavour = 'All';
                          _selectedGender = 'All';
                          _selectedAgeRange = 'All';
                          _friendsOnly = false;
                        });
                        Navigator.pop(ctx);
                        _loadVoters();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Gender
                const Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    {'key': 'All', 'label': 'All'},
                    {'key': 'M', 'label': 'Male'},
                    {'key': 'F', 'label': 'Female'},
                  ].map((g) {
                    final sel = _selectedGender == g['key'];
                    return ChoiceChip(
                      label: Text(g['label']!),
                      selected: sel,
                      onSelected: (_) {
                        setModalState(() => _selectedGender = g['key']!);
                        setState(() => _selectedGender = g['key']!);
                      },
                      selectedColor: const Color(0xFF0284C7),
                      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontSize: 12),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Age Brackets
                const Text('Age Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    {'key': 'All', 'label': 'All'},
                    {'key': '18-25', 'label': '18-25 (Youth)'},
                    {'key': '26-40', 'label': '26-40'},
                    {'key': '41-60', 'label': '41-60'},
                    {'key': '60+', 'label': '60+ (Senior)'},
                  ].map((a) {
                    final sel = _selectedAgeRange == a['key'];
                    return ChoiceChip(
                      label: Text(a['label']!),
                      selected: sel,
                      onSelected: (_) {
                        setModalState(() => _selectedAgeRange = a['key']!);
                        setState(() => _selectedAgeRange = a['key']!);
                      },
                      selectedColor: const Color(0xFF0284C7),
                      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontSize: 12),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Friends only toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only Friends & Relatives', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  value: _friendsOnly,
                  activeColor: const Color(0xFF0284C7),
                  onChanged: (val) {
                    setModalState(() => _friendsOnly = val);
                    setState(() => _friendsOnly = val);
                  },
                ),

                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _loadVoters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final filtered = _filteredVoters;
    final totalRoll = _voterStats['total'] ?? 42560;
    final favCount = _voterStats['favourable'] ?? 0;
    final neutralCount = _voterStats['neutral'] ?? 0;
    final boothsCount = _voterStats['booths'] ?? 28;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NagarsevakAppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
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
              'Voter Search',
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
              'Voter directory & booth lookup',
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
              onRefresh: _loadVoters,
              color: const Color(0xFF0284C7),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // KPI Stats Header Row
                  _buildKpiStrip(totalRoll, favCount, neutralCount, boothsCount),
                  const SizedBox(height: 14),

                  // Search & Booth Filter Bar
                  _buildSearchBar(),
                  const SizedBox(height: 10),

                  // Political Stance Filter Chips Row
                  _buildStanceFilterChips(),
                  const SizedBox(height: 10),

                  // View Mode & Result Count Row
                  _buildViewModeBar(filtered, totalRoll),
                  const SizedBox(height: 14),

                  // Render Voters by Selected View Mode
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else if (_viewMode == 'family')
                    ..._buildFamilyGroupedCards()
                  else if (_viewMode == 'table')
                    _buildTableView(filtered)
                  else
                    ...filtered.map((v) => _buildVoterCard(v)),

                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiStrip(int total, int fav, int neutral, int booths) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'Total Voters',
            value: NumberFormat('#,##,###').format(total),
            subtitle: 'Ward 12 Roll',
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'Favourable Voters',
            value: '$fav',
            subtitle: 'Aligned with Party',
            icon: Icons.thumb_up_alt_rounded,
            color: const Color(0xFF16A34A),
            bg: const Color(0xFFDCFCE7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'Neutral / Undecided',
            value: '$neutral',
            subtitle: 'Follow-up Required',
            icon: Icons.change_circle_outlined,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: 'Polling Stations',
            value: '$booths',
            subtitle: 'Total Booths',
            icon: Icons.location_city_rounded,
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search name, EPIC, address, mobile or serial no...',
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
          Container(height: 24, width: 1, color: Colors.grey.shade200),

          // Booth Filter Popup
          PopupMenuButton<String>(
            tooltip: 'Select Booth',
            initialValue: _selectedBooth,
            onSelected: (val) {
              setState(() => _selectedBooth = val);
              _loadVoters();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'All', child: Text('All Booths')),
              ..._boothsList.map((b) => PopupMenuItem(value: b, child: Text(b))),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.how_to_vote_outlined,
                    size: 16,
                    color: _selectedBooth != 'All' ? const Color(0xFF0284C7) : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedBooth == 'All' ? 'All Booths' : _selectedBooth.split('/').first,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _selectedBooth != 'All' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedBooth != 'All' ? const Color(0xFF0284C7) : Colors.grey.shade700,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),

          // Filter Button
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              size: 20,
              color: (_selectedGender != 'All' || _selectedAgeRange != 'All' || _friendsOnly)
                  ? const Color(0xFF0284C7)
                  : Colors.grey.shade600,
            ),
            tooltip: 'More Filters',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildStanceFilterChips() {
    final chips = [
      {'key': 'All', 'label': 'All Voters'},
      {'key': 'Favourable', 'label': 'Favourable', 'color': const Color(0xFF16A34A)},
      {'key': 'Neutral', 'label': 'Neutral', 'color': const Color(0xFF0284C7)},
      {'key': 'Against', 'label': 'Against', 'color': const Color(0xFFDC2626)},
      {'key': 'Swing', 'label': 'Undecided', 'color': const Color(0xFFD97706)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final isSel = _selectedFavour.toLowerCase() == c['key']!.toString().toLowerCase();
          final clr = c['color'] as Color? ?? const Color(0xFF0284C7);

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(c['label']!.toString()),
              selected: isSel,
              onSelected: (_) {
                setState(() => _selectedFavour = c['key']!.toString());
                _loadVoters();
              },
              selectedColor: clr,
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? Colors.white : Colors.grey.shade700,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(color: isSel ? clr : Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewModeBar(List<VoterModel> filtered, int totalRoll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${filtered.length} voters found',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    icon: Icon(Icons.family_restroom_rounded, size: 17, color: _viewMode == 'family' ? const Color(0xFF0284C7) : Colors.grey),
                    tooltip: 'Family Group View',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _viewMode = 'family'),
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
            const SizedBox(width: 8),
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
                    icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 17),
                    tooltip: 'Help Guide',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: _showHelpGuide,
                  ),
                  Container(width: 1, height: 18, color: Colors.grey.shade200),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 17),
                    tooltip: 'Download Electoral Roll Report',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () => VoterSlipGenerator.downloadVotersListReport(
                      voters: filtered,
                      totalCount: totalRoll,
                      currentFilterSummary: _selectedBooth != 'All' ? 'Booth: $_selectedBooth' : null,
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

  Widget _buildVoterCard(VoterModel voter) {
    Color favourColor = const Color(0xFF64748B);
    Color favourBg = const Color(0xFFF1F5F9);

    switch (voter.favour?.toLowerCase()) {
      case 'favourable':
        favourColor = const Color(0xFF16A34A);
        favourBg = const Color(0xFFDCFCE7);
        break;
      case 'against':
        favourColor = const Color(0xFFDC2626);
        favourBg = const Color(0xFFFEE2E2);
        break;
      case 'neutral':
        favourColor = const Color(0xFF0284C7);
        favourBg = const Color(0xFFE0F2FE);
        break;
      case 'swing':
        favourColor = const Color(0xFFD97706);
        favourBg = const Color(0xFFFEF3C7);
        break;
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
            MaterialPageRoute(builder: (_) => VoterProfileScreen(voter: voter)),
          ).then((_) => _loadVoters());
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar, Names, Serial, Stance
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(
                      voter.displayName.isNotEmpty ? voter.displayName.substring(0, 1) : 'V',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                voter.displayName,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                            if (voter.isFriendRelative)
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          ],
                        ),
                        if (voter.nameEnglish.isNotEmpty && voter.nameEnglish != voter.displayName)
                          Text(
                            voter.nameEnglish,
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                          ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'EPIC: ${voter.epicNo}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ),
                            if (voter.serialNo != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '#${voter.serialNo}',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: favourBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: favourColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      voter.favourLabelMarathi,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: favourColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Address & Booth info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${voter.houseNo != null ? "#${voter.houseNo}, " : ""}${voter.address}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Icon(Icons.how_to_vote_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Booth: ${voter.booth}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(width: 8),
                  Text(
                    'Age: ${voter.age} Yrs (${voter.gender})',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print, size: 14, color: Color(0xFF0284C7)),
                    label: const Text('Slip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => VoterSlipGenerator.printVoterSlip(voter),
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
                    onPressed: () => _shareSlipOnWhatsApp(voter),
                  ),
                  if (voter.mobile != null && voter.mobile!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.phone, size: 18, color: Color(0xFF0284C7)),
                      tooltip: 'Call',
                      onPressed: () => _callVoter(voter.mobile),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFamilyGroupedCards() {
    final families = _groupedFamilies;

    return families.entries.map((entry) {
      final members = entry.value;
      final first = members.first;
      final houseNo = first.houseNo ?? 'N/A';
      final booth = first.booth;

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Family Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home_rounded, size: 16, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'House No. #$houseNo • $booth',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          first.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${members.length} Voters',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ),

            // Family Members List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: members.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (ctx, idx) {
                final m = members[idx];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VoterProfileScreen(voter: m)),
                    ).then((_) => _loadVoters());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: Text(
                            m.displayName.isNotEmpty ? m.displayName.substring(0, 1) : 'V',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              Text(
                                'Age: ${m.age} • ${m.gender} • EPIC: ${m.epicNo} ${m.serialNo != null ? "• #${m.serialNo}" : ""}',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        if (m.favour != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: m.favour == 'Favourable'
                                  ? const Color(0xFFDCFCE7)
                                  : (m.favour == 'Against' ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.favourLabelMarathi,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: m.favour == 'Favourable'
                                    ? const Color(0xFF16A34A)
                                    : (m.favour == 'Against' ? const Color(0xFFDC2626) : const Color(0xFF0284C7)),
                              ),
                            ),
                          ),
                        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTableView(List<VoterModel> list) {
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
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F5F9)),
            columns: const [
              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('EPIC No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Age/Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Booth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Political Stance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: list.asMap().entries.map((entry) {
              final idx = entry.key;
              final v = entry.value;

              return DataRow(
                cells: [
                  DataCell(Text('${v.serialNo ?? (idx + 1)}', style: const TextStyle(fontSize: 11))),
                  DataCell(
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VoterProfileScreen(voter: v)),
                        ).then((_) => _loadVoters());
                      },
                      child: Text(
                        v.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  DataCell(Text(v.epicNo, style: const TextStyle(fontSize: 11))),
                  DataCell(Text('${v.age} / ${v.gender}', style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Text(
                      '${v.houseNo != null ? "#${v.houseNo}, " : ""}${v.address}',
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(Text(v.booth, style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Text(
                      v.favourLabelMarathi,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: v.favour == 'Favourable'
                            ? const Color(0xFF16A34A)
                            : (v.favour == 'Against' ? const Color(0xFFDC2626) : const Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print, size: 16, color: Color(0xFF0284C7)),
                          tooltip: 'Slip',
                          onPressed: () => VoterSlipGenerator.printVoterSlip(v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, size: 15, color: Color(0xFF25D366)),
                          tooltip: 'WhatsApp',
                          onPressed: () => _shareSlipOnWhatsApp(v),
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
          Icon(Icons.person_search_outlined, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No voters found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            'Please check the spelling of name, EPIC number or address and search again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() {
                _selectedBooth = 'All';
                _selectedFavour = 'All';
                _selectedGender = 'All';
                _selectedAgeRange = 'All';
                _friendsOnly = false;
              });
              _loadVoters();
            },
            child: const Text('Show All Voters'),
          ),
        ],
      ),
    );
  }
}
