import '../../navigation/app_bar_leading_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/social_organization_model.dart';
import '../../../data/repositories/social_organization_repository.dart';
import '../../navigation/app_drawer.dart';
import 'social_org_detail_screen.dart';
import 'social_org_report_generator.dart';

class SocialOrganizationsScreen extends ConsumerStatefulWidget {
  const SocialOrganizationsScreen({super.key});

  @override
  ConsumerState<SocialOrganizationsScreen> createState() => _SocialOrganizationsScreenState();
}

class _SocialOrganizationsScreenState extends ConsumerState<SocialOrganizationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'all';
  final String _selectedStatus = 'all';
  int _viewMode = 0; // 0 = Cards, 1 = Table
  String? _expandedOrgId;

  bool _isLoading = true;
  List<SocialOrganizationModel> _organizations = [];
  Map<String, int> _stats = {
    'total': 0,
    'ngos': 0,
    'sports': 0,
    'mandals': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
    setState(() => _isLoading = true);
    final repo = ref.read(socialOrgRepoProvider);

    final orgs = await repo.getOrganizations(
      type: _selectedType == 'all' ? null : _selectedType,
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      query: _searchController.text.trim(),
    );

    final stats = await repo.getOrganizationStats();

    if (mounted) {
      setState(() {
        _organizations = orgs;
        _stats = stats;
        _isLoading = false;
      });
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
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mobile number copied!'), duration: Duration(seconds: 2)),
    );
  }

  Map<String, dynamic> _getTheme(String type) {
    switch (type) {
      case 'ngo':
        return {
          'color': const Color(0xFF0284C7),
          'bg': const Color(0xFFF0F9FF),
          'border': const Color(0xFFBAE6FD),
          'icon': Icons.apartment_rounded,
        };
      case 'sports_cricket':
        return {
          'color': const Color(0xFF059669),
          'bg': const Color(0xFFECFDF5),
          'border': const Color(0xFFA7F3D0),
          'icon': Icons.sports_cricket_rounded,
        };
      case 'ganpati_mandal':
        return {
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFFFBEB),
          'border': const Color(0xFFFDE68A),
          'icon': Icons.auto_awesome_rounded,
        };
      case 'navratri_mandal':
        return {
          'color': const Color(0xFFE11D48),
          'bg': const Color(0xFFFFF1F2),
          'border': const Color(0xFFFECDD3),
          'icon': Icons.festival_rounded,
        };
      default:
        return {
          'color': const Color(0xFF64748B),
          'bg': const Color(0xFFF8FAFC),
          'border': const Color(0xFFE2E8F0),
          'icon': Icons.groups_rounded,
        };
    }
  }

  // ===========================================================================
  // ADD / EDIT ORGANIZATION MODAL
  // ===========================================================================
  void _showOrgForm({SocialOrganizationModel? orgToEdit}) {
    final nameMrCtrl = TextEditingController(text: orgToEdit?.nameMarathi ?? orgToEdit?.name ?? '');
    final nameEnCtrl = TextEditingController(text: orgToEdit?.nameEnglish ?? orgToEdit?.name ?? '');
    String type = orgToEdit?.type ?? 'ganpati_mandal';
    final presNameCtrl = TextEditingController(text: orgToEdit?.presidentName ?? '');
    final presPhoneCtrl = TextEditingController(text: orgToEdit?.presidentMobile ?? '');
    final membersCtrl = TextEditingController(text: orgToEdit != null ? orgToEdit.membersCount.toString() : '50');
    final areaCtrl = TextEditingController(text: orgToEdit?.area ?? '');
    final estCtrl = TextEditingController(text: orgToEdit?.establishedYear ?? DateTime.now().year.toString());
    final supportCtrl = TextEditingController(text: orgToEdit?.supportReceived ?? '');
    final descCtrl = TextEditingController(text: orgToEdit?.description ?? '');
    String status = orgToEdit?.status ?? 'Active';

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
                    const Icon(Icons.apartment_rounded, color: Color(0xFF0284C7), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      orgToEdit == null ? 'Register New Organization / Mandal' : 'Edit Organization Details',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name (Marathi)
                TextField(
                  controller: nameMrCtrl,
                  decoration: InputDecoration(
                    labelText: 'Organization Name *',
                    hintText: 'e.g. Bal Ganesh Tarun Mandal',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Name (English)
                TextField(
                  controller: nameEnCtrl,
                  decoration: InputDecoration(
                    labelText: 'Alternate Name (English)',
                    hintText: 'Bal Ganesh Tarun Mandal',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: InputDecoration(
                    labelText: 'Organization Type *',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ganpati_mandal', child: Text('Ganesh Mandal')),
                    DropdownMenuItem(value: 'navratri_mandal', child: Text('Navratri Mandal')),
                    DropdownMenuItem(value: 'sports_cricket', child: Text('Sports & Cricket Club')),
                    DropdownMenuItem(value: 'ngo', child: Text('NGO / Trust')),
                    DropdownMenuItem(value: 'other', child: Text('Other Mandals')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => type = val);
                  },
                ),
                const SizedBox(height: 10),

                // President Name & Mobile Row
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: presNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'President Name *',
                          hintText: 'e.g. Ganesh Jadhav',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: presPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile *',
                          hintText: '98221xxxxx',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Members & Established Year Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: membersCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Total Members',
                          hintText: '50',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: estCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Established Year',
                          hintText: '2015',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Area / Location
                TextField(
                  controller: areaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Area / Vicinity *',
                    hintText: 'e.g. Sector 3, Main Chowk',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Nagarsevak Support Received Notes
                TextField(
                  controller: supportCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Corporator Support & Sponsorship History',
                    hintText: 'e.g. Stage setup, sound permissions, trophy sponsorship...',
                    filled: true,
                    fillColor: const Color(0xFFF5F3FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'About Organization & Objectives',
                    hintText: 'Social initiatives, community outreach & contributions...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Status
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => status = val);
                  },
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : nameEnCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter organization name.')),
                        );
                        return;
                      }

                      final newOrg = SocialOrganizationModel(
                        id: orgToEdit?.id ?? 'org-${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : name,
                        nameEnglish: nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : name,
                        type: type,
                        presidentName: presNameCtrl.text.trim(),
                        presidentMobile: presPhoneCtrl.text.trim(),
                        membersCount: int.tryParse(membersCtrl.text.trim()) ?? 0,
                        area: areaCtrl.text.trim(),
                        establishedYear: estCtrl.text.trim(),
                        supportReceived: supportCtrl.text.trim(),
                        eventsConducted: orgToEdit?.eventsConducted ?? [],
                        description: descCtrl.text.trim(),
                        status: status,
                        createdAt: orgToEdit?.createdAt ?? DateTime.now(),
                      );

                      final repo = ref.read(socialOrgRepoProvider);
                      if (orgToEdit == null) {
                        await repo.addOrganization(newOrg);
                      } else {
                        await repo.updateOrganization(newOrg);
                      }

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (!mounted) return;
                      _loadOrganizations();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(orgToEdit == null ? 'Organization registered successfully!' : 'Details updated!'),
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
                      orgToEdit == null ? 'Add Organization' : 'Save Changes',
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
  void _confirmDeleteOrg(SocialOrganizationModel org) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Organization?'),
        content: Text('Are you sure you want to delete record for "${org.displayName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(socialOrgRepoProvider);
              await repo.deleteOrganization(org.id);
              _loadOrganizations();
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
              'NGO & Mandals Info',
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
              'Social organizations, youth mandals and trust directory',
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
        onRefresh: _loadOrganizations,
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
                      title: 'Total Registered',
                      value: _stats['total']?.toString() ?? '0',
                      icon: Icons.layers_rounded,
                      color: const Color(0xFF0284C7),
                      bg: const Color(0xFFF0F9FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'NGOs',
                      value: _stats['ngos']?.toString() ?? '0',
                      icon: Icons.apartment_rounded,
                      color: const Color(0xFF4338CA),
                      bg: const Color(0xFFEEF2FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Sports Clubs',
                      value: _stats['sports']?.toString() ?? '0',
                      icon: Icons.sports_cricket_rounded,
                      color: const Color(0xFF059669),
                      bg: const Color(0xFFECFDF5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Festival Mandals',
                      value: _stats['mandals']?.toString() ?? '0',
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFFFFBEB),
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
                        onChanged: (_) => _loadOrganizations(),
                        decoration: InputDecoration(
                          hintText: 'Search by name, president, or area...',
                          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadOrganizations();
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
                            SocialOrgReportGenerator.generateAndPrintReport(
                              organizations: _organizations,
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
              // 3. FILTER TABS: TYPE
              // ==========================================
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Types (${_stats['total']})', 'all', _selectedType, (val) {
                      setState(() => _selectedType = val);
                      _loadOrganizations();
                    }),
                    const SizedBox(width: 6),
                    _buildFilterChip('Ganesh Mandals', 'ganpati_mandal', _selectedType, (val) {
                      setState(() => _selectedType = val);
                      _loadOrganizations();
                    }),
                    const SizedBox(width: 6),
                    _buildFilterChip('Navratri Mandals', 'navratri_mandal', _selectedType, (val) {
                      setState(() => _selectedType = val);
                      _loadOrganizations();
                    }),
                    const SizedBox(width: 6),
                    _buildFilterChip('Sports Clubs', 'sports_cricket', _selectedType, (val) {
                      setState(() => _selectedType = val);
                      _loadOrganizations();
                    }),
                    const SizedBox(width: 6),
                    _buildFilterChip('NGOs & Trusts', 'ngo', _selectedType, (val) {
                      setState(() => _selectedType = val);
                      _loadOrganizations();
                    }),
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
              else if (_organizations.isEmpty)
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
                      const Icon(Icons.apartment_outlined, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No organizations or mandals found.',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Use the "+ Add Organization" button above to register.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showOrgForm(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Register Organization'),
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
                  itemCount: _organizations.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final org = _organizations[idx];
                    return _buildOrgCard(org);
                  },
                )
              else
                // SPREADSHEET TABLE VIEW
                _buildSpreadsheetTable(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOrgForm(),
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Organization', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
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

  Widget _buildOrgCard(SocialOrganizationModel org) {
    final theme = _getTheme(org.type);
    final isExpanded = _expandedOrgId == org.id;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SocialOrgDetailScreen(organization: org)),
        );
        _loadOrganizations();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme['border'] as Color),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (theme['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (theme['color'] as Color).withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Icon(theme['icon'] as IconData, color: theme['color'] as Color, size: 22),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org.displayName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        org.typeLabelMarathi,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme['color'] as Color),
                      ),
                      const SizedBox(height: 6),

                      // Status & Members Chip
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: org.status == 'Active' ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: org.status == 'Active' ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              org.status == 'Active' ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: org.status == 'Active' ? const Color(0xFF047857) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${org.membersCount} Members',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                          if (org.establishedYear.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Est: ${org.establishedYear}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showOrgForm(orgToEdit: org);
                    } else if (val == 'delete') {
                      _confirmDeleteOrg(org);
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

            // President & Mobile Bar
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          org.presidentName.isNotEmpty ? org.presidentName : '-',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (org.presidentMobile.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _makePhoneCall(org.presidentMobile),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                      child: const Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Color(0xFF0284C7)),
                          SizedBox(width: 4),
                          Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _openWhatsApp(org.presidentMobile),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _copyToClipboard(org.presidentMobile),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ],
            ),

            if (org.area.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      org.area,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Support received snippet
            if (org.supportReceived.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 13, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        org.supportReceived,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF5B21B6), fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Expandable Events Accordion
            if (org.eventsConducted.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => setState(() => _expandedOrgId = isExpanded ? null : org.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_note_rounded, size: 14, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Text(
                            'Key Events / Festivals (${org.eventsConducted.length})',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.only(left: 10),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Color(0xFFCBD5E1), width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: org.eventsConducted.map((evt) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  evt.displayTitle,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(3)),
                                  child: Text(evt.year.toString(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            if (evt.displayDescription.isNotEmpty)
                              Text(
                                evt.displayDescription,
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 10),

            // Bottom action
            const Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Detailed Profile',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0284C7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SPREADSHEET TABLE VIEW
  // ===========================================================================
  Widget _buildSpreadsheetTable() {
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
              DataColumn(label: Text('Organization Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('President', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Area / Vicinity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Members', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Established', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Support History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Activities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: List.generate(_organizations.length, (index) {
              final o = _organizations[index];
              final theme = _getTheme(o.type);

              return DataRow(
                cells: [
                  DataCell(Text((index + 1).toString(), style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Text(
                      o.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (theme['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        o.typeLabelMarathi,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: theme['color'] as Color),
                      ),
                    ),
                  ),
                  DataCell(Text(o.presidentName.isNotEmpty ? o.presidentName : '-', style: const TextStyle(fontSize: 11))),
                  DataCell(Text(o.presidentMobile.isNotEmpty ? o.presidentMobile : '-', style: const TextStyle(fontSize: 11))),
                  DataCell(Text(o.area.isNotEmpty ? o.area : '-', style: const TextStyle(fontSize: 11))),
                  DataCell(Text(o.membersCount.toString(), style: const TextStyle(fontSize: 11))),
                  DataCell(Text(o.establishedYear.isNotEmpty ? o.establishedYear : '-', style: const TextStyle(fontSize: 11))),
                  DataCell(Text(o.supportReceived.isNotEmpty ? o.supportReceived : '-', style: const TextStyle(fontSize: 11))),
                  DataCell(Text(o.eventsConducted.length.toString(), style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Text(
                      o.status == 'Active' ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: o.status == 'Active' ? const Color(0xFF047857) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SocialOrgDetailScreen(organization: o)),
                        );
                        _loadOrganizations();
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
