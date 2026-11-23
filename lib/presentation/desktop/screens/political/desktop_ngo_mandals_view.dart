import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/social_organization_model.dart';
import '../../../../data/repositories/social_organization_repository.dart';

class DesktopNgoMandalsView extends ConsumerStatefulWidget {
  const DesktopNgoMandalsView({super.key});

  @override
  ConsumerState<DesktopNgoMandalsView> createState() => _DesktopNgoMandalsViewState();
}

class _DesktopNgoMandalsViewState extends ConsumerState<DesktopNgoMandalsView> {
  bool _loading = true;
  List<SocialOrganizationModel> _orgs = [];
  String _selectedType = 'All';
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
  }

  Future<void> _fetchOrganizations() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(socialOrgRepoProvider);
      final list = await repo.getOrganizations(type: _selectedType);
      if (mounted) {
        setState(() {
          _orgs = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _orgs = [];
          _loading = false;
        });
      }
    }
  }

  List<SocialOrganizationModel> get _filteredOrgs {
    return _orgs.where((o) {
      final matchesSearch = _searchTerm.isEmpty ||
          o.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          o.presidentName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          o.presidentMobile.contains(_searchTerm) ||
          o.area.toLowerCase().contains(_searchTerm.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  void _showAddOrgModal({SocialOrganizationModel? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final presNameController = TextEditingController(text: item?.presidentName ?? '');
    final presMobileController = TextEditingController(text: item?.presidentMobile ?? '');
    final areaController = TextEditingController(text: item?.area ?? 'Ward 12');
    final membersCountController = TextEditingController(text: (item?.membersCount ?? 25).toString());
    final establishedController = TextEditingController(text: item?.establishedYear ?? '2015');
    final supportController = TextEditingController(text: item?.supportReceived ?? '');
    String type = item?.type ?? 'ngo';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 580,
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item == null ? 'Add Organization' : 'Edit Organization',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Organization Name
                    const Text('Organization Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Navtarun Youth Club...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type & Area
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Type *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: type,
                                items: const [
                                  DropdownMenuItem(value: 'ngo', child: Text('NGO / Foundation')),
                                  DropdownMenuItem(value: 'sports_cricket', child: Text('Sports & Cricket Club')),
                                  DropdownMenuItem(value: 'ganpati_mandal', child: Text('Festival Mandal')),
                                  DropdownMenuItem(value: 'navratri_mandal', child: Text('Cultural Group')),
                                  DropdownMenuItem(value: 'other', child: Text('Other Organization')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => type = val);
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ward / Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Main Street',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // President Name & Mobile
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('President / Head', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: presNameController,
                                decoration: InputDecoration(
                                  hintText: 'Name of President...',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mobile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: presMobileController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '98XXXXXXXX',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Support Notes
                    const Text('Support Provided', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: supportController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Assistance provided, equipment, stage setup, civic support...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;
                            final newOrg = SocialOrganizationModel(
                              id: item?.id ?? 'soc-${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text.trim(),
                              type: type,
                              area: areaController.text.trim(),
                              presidentName: presNameController.text.trim(),
                              presidentMobile: presMobileController.text.trim(),
                              membersCount: int.tryParse(membersCountController.text.trim()) ?? 25,
                              establishedYear: establishedController.text.trim(),
                              supportReceived: supportController.text.trim(),
                              createdAt: item?.createdAt ?? DateTime.now(),
                            );

                            final repo = ref.read(socialOrgRepoProvider);
                            if (item == null) {
                              await repo.addOrganization(newOrg);
                            } else {
                              await repo.updateOrganization(newOrg);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchOrganizations();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          ),
                          child: Text(item == null ? 'Register Organization' : 'Save Changes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
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

  void _showDeleteConfirm(SocialOrganizationModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Organization'),
        content: Text('Are you sure you want to delete "${item.displayName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(socialOrgRepoProvider);
              await repo.deleteOrganization(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchOrganizations();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrgs;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length),
          const SizedBox(height: 20),

          // Type Pills Row
          _buildTypePills(),
          const SizedBox(height: 16),

          // Search Row
          _buildSearchRow(),
          const SizedBox(height: 24),

          // Content Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildCardGrid(filtered),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'NGO & Mandals Info',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text('Total: $count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Directory of NGOs, sports clubs, festival organizations and community trusts',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Add Button
        ElevatedButton.icon(
          onPressed: () => _showAddOrgModal(),
          icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
          label: const Text('+ Add Organization', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildTypePills() {
    final types = [
      {'key': 'All', 'label': 'All'},
      {'key': 'ngo', 'label': 'NGO / Social Trust'},
      {'key': 'sports_cricket', 'label': 'Sports Club'},
      {'key': 'ganpati_mandal', 'label': 'Festival Committee'},
      {'key': 'navratri_mandal', 'label': 'Cultural Association'},
    ];

    return Wrap(
      spacing: 8,
      children: types.map((t) {
        final key = t['key']!;
        final label = t['label']!;
        final isSelected = _selectedType == key;

        return InkWell(
          onTap: () {
            setState(() => _selectedType = key);
            _fetchOrganizations();
          },
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0284C7) : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchTerm = val),
        decoration: const InputDecoration(
          hintText: 'Search organization by name, president or area...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCardGrid(List<SocialOrganizationModel> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: const [
            Icon(Icons.corporate_fare_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No organizations found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 250,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Text(item.typeLabelMarathi, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                      ),
                      Text('Est: ${item.establishedYear}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),

                  // Area
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(item.area.isNotEmpty ? item.area : 'Ward 12', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // President
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text('President: ${item.presidentName.isNotEmpty ? item.presidentName : "Not recorded"}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      if (item.presidentMobile.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text('(${item.presidentMobile})', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  const Spacer(),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Members: ${item.membersCount}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showAddOrgModal(item: item)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)), onPressed: () => _showDeleteConfirm(item)),
                          ],
                        ),
                      ],
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

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 240,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
