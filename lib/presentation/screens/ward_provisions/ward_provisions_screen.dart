import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ward_provision_model.dart';
import '../../../data/repositories/ward_provisions_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'ward_provision_report_generator.dart';

class WardProvisionsScreen extends ConsumerStatefulWidget {
  const WardProvisionsScreen({super.key});

  @override
  ConsumerState<WardProvisionsScreen> createState() => _WardProvisionsScreenState();
}

class _WardProvisionsScreenState extends ConsumerState<WardProvisionsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedYear = '2024-2025'; // '2024-2025' or '2023-2024' or 'All'
  String _viewMode = 'grid'; // 'grid' or 'report'
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // 'All', 'Approved', 'Partially Approved', 'Pending', 'Rejected'

  bool _isLoading = true;
  List<WardProvisionModel> _allProvisions = [];

  final List<String> _years = ['2024-2025', '2023-2024', 'All'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(wardProvisionsRepoProvider);
    final items = await repo.getProvisions(year: _selectedYear != 'All' ? _selectedYear : null);
    if (mounted) {
      setState(() {
        _allProvisions = items;
        _isLoading = false;
      });
    }
  }

  List<String> get _categories {
    final cats = _allProvisions.map((p) => p.category.trim()).where((c) => c.isNotEmpty).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<WardProvisionModel> get _filteredProvisions {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allProvisions.where((p) {
      if (_selectedYear != 'All' && p.financialYear != _selectedYear) {
        return false;
      }
      if (_selectedCategory != 'All' && p.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (_selectedStatus != 'All' && p.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        final titleMatch = p.title.toLowerCase().contains(query);
        final descMatch = p.description.toLowerCase().contains(query);
        final catMatch = p.category.toLowerCase().contains(query);
        final areaMatch = p.area.toLowerCase().contains(query);
        final refMatch = p.letterReference.toLowerCase().contains(query);
        if (!titleMatch && !descMatch && !catMatch && !areaMatch && !refMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showAddModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Roads & Civil');
    final areaCtrl = TextEditingController(text: 'Ward 12');
    final refCtrl = TextEditingController(text: 'PMC/W12/${DateFormat('yyyy').format(DateTime.now())}/');
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String fy = _selectedYear != 'All' ? _selectedYear : '2024-2025';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Ward Funding Request',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Project Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. CC Road Concreting, Water Mainline...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Requested Amount (₹) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: amtCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 2500000',
                                  prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
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
                              const Text('Financial Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: fy,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: '2024-2025', child: Text('FY 2024-2025')),
                                  DropdownMenuItem(value: '2023-2024', child: Text('FY 2023-2024')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => fy = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: catCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Roads & Civil, Water Supply',
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
                              const Text('Area / Sector *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Shaniwar Peth',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Letter Reference No *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: refCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. PMC/RDS/2024/1042',
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
                              const Text('Request Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: dateCtrl,
                                decoration: InputDecoration(
                                  hintText: 'YYYY-MM-DD',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Purpose / Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Brief details about the technical requirement and urgency...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || amtCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter project title and requested amount')),
                            );
                            return;
                          }

                          final newProv = WardProvisionModel(
                            id: 'prov-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            requestedAmount: double.tryParse(amtCtrl.text.trim()) ?? 0,
                            sanctionedAmount: null,
                            requestedDate: dateCtrl.text.trim(),
                            status: 'Pending',
                            financialYear: fy,
                            category: catCtrl.text.trim().isNotEmpty ? catCtrl.text.trim() : 'General',
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                            letterReference: refCtrl.text.trim().isNotEmpty ? refCtrl.text.trim() : 'PMC/W12/REF',
                          );

                          final repo = ref.read(wardProvisionsRepoProvider);
                          await repo.addProvision(newProv);
                          await _loadData();

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Provision request submitted successfully!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Funding Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUpdateSanctionModal(WardProvisionModel item) {
    final amtCtrl = TextEditingController(
      text: (item.sanctionedAmount ?? item.requestedAmount).toInt().toString(),
    );
    final dateCtrl = TextEditingController(
      text: item.sanctionedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final areaCtrl = TextEditingController(text: item.area);
    String status = item.status == 'Pending' ? 'Approved' : item.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Update Sanction Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Project Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Requested: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0).format(item.requestedAmount)}   •   Ref: ${item.letterReference}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('Sanctioned Amount (₹) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sanction Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: status,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                                DropdownMenuItem(value: 'Partially Approved', child: Text('Partially Approved')),
                                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => status = val);
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
                            const Text('Sanction Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: dateCtrl,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                hintText: 'YYYY-MM-DD',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Text('Area / Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: areaCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final updated = item.copyWith(
                          sanctionedAmount: double.tryParse(amtCtrl.text.trim()),
                          sanctionedDate: dateCtrl.text.trim(),
                          status: status,
                          area: areaCtrl.text.trim(),
                        );

                        final repo = ref.read(wardProvisionsRepoProvider);
                        await repo.updateProvision(updated);
                        await _loadData();

                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sanction updated successfully!'),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                        }
                      },
                      child: const Text('Save Sanction Update', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showDeleteConfirmation(WardProvisionModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Request'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(wardProvisionsRepoProvider);
              await repo.deleteProvision(item.id);
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Provision record deleted'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final displayed = _filteredProvisions;
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    final totalRequested = displayed.fold<double>(0, (sum, p) => sum + p.requestedAmount);
    final totalSanctioned = displayed.fold<double>(0, (sum, p) => sum + (p.sanctionedAmount ?? 0));
    final successRate = totalRequested > 0 ? (totalSanctioned / totalRequested) * 100 : 0.0;
    final pendingCount = displayed.where((p) => p.status.toLowerCase() == 'pending').length;

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
        drawer: const NagarsevakAppDrawer(currentTabIndex: 0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
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
                'Ward Provisions',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Track funding requests & sanctions',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: [
            // Financial Year Selector
            Theme(
              data: Theme.of(context).copyWith(canvasColor: const Color(0xFF0369A1)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedYear,
                  icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                  dropdownColor: const Color(0xFF0369A1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  items: _years.map((y) {
                    return DropdownMenuItem(
                      value: y,
                      child: Text(y == 'All' ? (isMr ? 'सर्व वर्षे' : 'All FY') : 'FY $y'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                      _loadData();
                    }
                  },
                ),
              ),
            ),
            // Download PDF
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              tooltip: isMr ? 'अहवाल डाउनलोड करा' : 'Download Report',
              onPressed: () {
                WardProvisionReportGenerator.generateAndPrintProvisionReport(
                  provisions: displayed,
                  year: _selectedYear,
                  categoryFilter: _selectedCategory != 'All' ? _selectedCategory : null,
                  statusFilter: _selectedStatus != 'All' ? _selectedStatus : null,
                );
              },
            ),
            // Refresh
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: _loadData,
            ),
          ],
        ),
        body: Column(
          children: [
            // Top Overview Budget Cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  // Total Requested Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isMr ? 'एकूण मागणी' : 'Total Requested',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            numFormat.format(totalRequested),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$pendingCount ${isMr ? "प्रलंबित मागण्या" : "Pending requests"}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Total Sanctioned Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isMr ? 'एकूण मंजूर' : 'Total Sanctioned',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.currency_rupee_rounded, size: 14, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            numFormat.format(totalSanctioned),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (successRate / 100).clamp(0.0, 1.0),
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${successRate.toStringAsFixed(1)}% success rate',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search & Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: isMr ? 'प्रकल्प, पत्र क्रमांक किंवा क्षेत्र शोधा...' : 'Search projects, letter ref, area...',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                      const SizedBox(width: 8),
                      // View Mode Toggle
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.grid_view_rounded,
                                size: 19,
                                color: _viewMode == 'grid' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              tooltip: 'Grid View',
                              onPressed: () => setState(() => _viewMode = 'grid'),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.table_chart_outlined,
                                size: 19,
                                color: _viewMode == 'report' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              tooltip: 'Report Table View',
                              onPressed: () => setState(() => _viewMode = 'report'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Category & Status Filter Row
                  Row(
                    children: [
                      // Category Dropdown
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat == 'All' ? (isMr ? 'सर्व वर्ग (All Categories)' : 'All Categories') : cat),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Dropdown
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                              items: [
                                DropdownMenuItem(value: 'All', child: Text(isMr ? 'सर्व स्थिती' : 'All Status')),
                                DropdownMenuItem(value: 'Approved', child: Text(isMr ? 'मंजूर' : 'Approved')),
                                DropdownMenuItem(value: 'Partially Approved', child: Text(isMr ? 'अंशतः मंजूर' : 'Partially Approved')),
                                DropdownMenuItem(value: 'Pending', child: Text(isMr ? 'प्रलंबित' : 'Pending')),
                                DropdownMenuItem(value: 'Rejected', child: Text(isMr ? 'नाकारले' : 'Rejected')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedStatus = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayed.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.currency_rupee_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isMr ? 'कोणत्याही तरतूद नोंदी आढळल्या नाहीत' : 'No ward provision records found matching filters',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : _viewMode == 'report'
                          ? _buildReportTableView(displayed, isMr)
                          : _buildGridView(displayed, isMr),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            isMr ? 'निधी मागणी जोडा' : 'Add Request',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          ),
          onPressed: _showAddModal,
        ),
      ),
    );
  }

  Widget _buildGridView(List<WardProvisionModel> list, bool isMr) {
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final p = list[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.statusBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Chip, Letter Ref & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.category.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ref: ${p.letterReference}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.statusBorderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(p.statusIcon, size: 12, color: p.statusColor),
                          const SizedBox(width: 4),
                          Text(
                            isMr ? p.statusDisplayMr : p.statusDisplayEn,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: p.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  p.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.35),
                  ),
                ],
                const SizedBox(height: 12),

                // Area & Date Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          p.area,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          p.sanctionedDate ?? p.requestedDate,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),

                // Bottom Amount & Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          numFormat.format(p.sanctionedAmount ?? p.requestedAmount),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: p.sanctionedAmount != null ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                          ),
                        ),
                        if (p.sanctionedAmount != null && p.sanctionedAmount! < p.requestedAmount)
                          Text(
                            'Requested: ${numFormat.format(p.requestedAmount)}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    // Quick Action Buttons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                          tooltip: 'Update Sanction',
                          onPressed: () => _showUpdateSanctionModal(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _showDeleteConfirmation(p),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportTableView(List<WardProvisionModel> list, bool isMr) {
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: [
              DataColumn(label: Text(isMr ? 'क्र.' : '#', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'प्रकल्प / उद्देश' : 'Project Title & Ref', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'क्षेत्र' : 'Area', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'रक्कम' : 'Amount', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'स्थिती' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'तारीख' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(list.length, (index) {
              final p = list[index];
              return DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    SizedBox(
                      width: 190,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${p.category} • Ref: ${p.letterReference}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(p.area, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          numFormat.format(p.sanctionedAmount ?? p.requestedAmount),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: p.sanctionedAmount != null ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                          ),
                        ),
                        if (p.sanctionedAmount != null && p.sanctionedAmount! < p.requestedAmount)
                          Text('req: ${numFormat.format(p.requestedAmount)}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.statusBgColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: p.statusBorderColor),
                      ),
                      child: Text(
                        isMr ? p.statusDisplayMr : p.statusDisplayEn,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: p.statusColor),
                      ),
                    ),
                  ),
                  DataCell(Text(p.sanctionedDate ?? p.requestedDate, style: const TextStyle(fontSize: 11.5))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                          onPressed: () => _showUpdateSanctionModal(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(p),
                        ),
                      ],
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

