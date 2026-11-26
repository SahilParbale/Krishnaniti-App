import '../../../../core/theme/app_colors.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/government_office_model.dart';
import '../../../../data/repositories/government_office_repository.dart';
import '../../../screens/government_office/gov_office_report_generator.dart';

class DesktopGovernmentOfficeView extends ConsumerStatefulWidget {
  const DesktopGovernmentOfficeView({super.key});

  @override
  ConsumerState<DesktopGovernmentOfficeView> createState() => _DesktopGovernmentOfficeViewState();
}

class _DesktopGovernmentOfficeViewState extends ConsumerState<DesktopGovernmentOfficeView> {
  String _activeTab = 'Offices'; // 'Offices' | 'Cooperative'
  bool _loading = true;
  List<GovernmentOfficeModel> _offices = [];
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _fetchOffices();
  }

  Future<void> _fetchOffices() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(governmentOfficeRepoProvider);
      final list = await repo.getOffices();
      if (mounted) {
        setState(() {
          _offices = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _offices = [];
          _loading = false;
        });
      }
    }
  }

  List<GovernmentOfficeModel> get _filteredOffices {
    return _offices.where((o) {
      final matchesSearch = _searchTerm.isEmpty ||
          o.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          o.officerName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          o.area.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          o.category.toLowerCase().contains(_searchTerm.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  void _showAddOfficeModal() {
    final nameController = TextEditingController();
    final officerController = TextEditingController();
    final contactController = TextEditingController();
    final addressController = TextEditingController();
    final areaController = TextEditingController(text: 'Ward 12');
    String selectedCategory = 'Municipal PMC';
    bool isEmergency = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: 'Add Government Office',
            subtitle: 'Directory of public and civic administrative offices',
            icon: Icons.account_balance_rounded,
            width: 600,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: 'Save Office',
                onPressed: () async {
                            if (nameController.text.trim().isEmpty || contactController.text.trim().isEmpty) return;
                            final newOffice = GovernmentOfficeModel(
                              id: 'office-${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text.trim(),
                              officerName: officerController.text.trim(),
                              contactNumber: contactController.text.trim(),
                              address: addressController.text.trim(),
                              area: areaController.text.trim(),
                              category: selectedCategory,
                              isEmergency: isEmergency,
                              createdAt: DateTime.now().toIso8601String(),
                            );

                            final repo = ref.read(governmentOfficeRepoProvider);
                            await repo.addOffice(newOffice);
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchOffices();
                          },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Office Name
                    const Text('Office Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Municipal Ward Office No. 12',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category & Area
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Department / Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                items: const [
                                  DropdownMenuItem(value: 'Municipal PMC', child: Text('Municipal Corporation (PMC)')),
                                  DropdownMenuItem(value: 'Police', child: Text('Police Station')),
                                  DropdownMenuItem(value: 'MSEDCL Electricity', child: Text('MSEDCL Electricity')),
                                  DropdownMenuItem(value: 'Water Supply', child: Text('Water Supply Department')),
                                  DropdownMenuItem(value: 'Health & Hospital', child: Text('Health & Hospital')),
                                  DropdownMenuItem(value: 'Fire & Disaster', child: Text('Fire & Disaster Response')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedCategory = val);
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
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
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Officer Name & Contact
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Officer In-Charge *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: officerController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Mr. R. K. Patil',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
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
                              const Text('Contact Number *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: contactController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 020-25501000',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    const Text('Address *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Full office address...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Emergency Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: isEmergency,
                          onChanged: (val) => setModalState(() => isEmergency = val ?? false),
                        ),
                        const Text('Emergency Service', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                      ],
                    ),
                                      ],
            ),
          );
        },
      ),
    );  }

  void _showDeleteConfirm(GovernmentOfficeModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Office'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(governmentOfficeRepoProvider);
              await repo.deleteOffice(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchOffices();
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
    final filtered = _filteredOffices;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 24),

          // Content Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildOfficeGrid(filtered),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Government Offices',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Government departments, officers in-charge and emergency contact numbers',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                GovOfficeReportGenerator.generateAndPrintOfficeReport(
                  context: context,
                  offices: _filteredOffices,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: const Text('Download Report', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),

            // Add Office (ns-btn-primary matching GovtOffices.tsx)
            ElevatedButton(
              onPressed: _showAddOfficeModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7), // bg-brand-600
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // rounded-xl
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white), // Plus w-4 h-4
                  SizedBox(width: 8), // gap-2
                  Text(
                    'Add Office',
                    style: TextStyle(
                      fontSize: 14, // text-sm
                      fontWeight: FontWeight.w600, // font-semibold
                      color: Colors.white,
                      letterSpacing: -0.1,
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchTerm = val),
        decoration: InputDecoration(
          hintText: 'Search office by name, department, officer or area...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _searchTerm = ''))
              : null,
        ),
      ),
    );
  }

  Widget _buildOfficeGrid(List<GovernmentOfficeModel> items) {
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
            Icon(Icons.business_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No offices found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 280,
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
                  // Top Row: Category badge & Area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isEmergency ? const Color(0xFFFEF2F2) : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: item.isEmergency ? const Color(0xFFFECACA) : const Color(0xFFBAE6FD)),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.isEmergency ? const Color(0xFFB91C1C) : const Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: Text(item.area, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Office Name
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                  ),
                  const SizedBox(height: 12),

                  // Officer In-Charge
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.officerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Bottom Action: Call button & Delete
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () async {
                            final uri = Uri.parse('tel:${item.contactNumber}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.phone, size: 13, color: Color(0xFF16A34A)),
                                const SizedBox(width: 6),
                                Text(
                                  item.contactNumber,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                          onPressed: () => _showDeleteConfirm(item),
                          tooltip: 'Delete',
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
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 260,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
