import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ward_provision_model.dart';
import '../../../data/repositories/ward_provisions_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'ward_provision_report_generator.dart';

/// WardProvisions Screen matching EXACTLY the web page:
/// Nagarsevak-Managment/src/pages/ward/WardProvisions.tsx
class WardProvisionsScreen extends ConsumerStatefulWidget {
  const WardProvisionsScreen({super.key});

  @override
  ConsumerState<WardProvisionsScreen> createState() => _WardProvisionsScreenState();
}

class _WardProvisionsScreenState extends ConsumerState<WardProvisionsScreen> {
  String _year = '2024-2025';
  bool _loading = true;
  List<WardProvisionModel> _provisions = [];

  // Delete modal confirmation target
  WardProvisionModel? _deleteTarget;

  @override
  void initState() {
    super.initState();
    _loadProvisions();
  }

  Future<void> _loadProvisions() async {
    setState(() => _loading = true);
    final repo = ref.read(wardProvisionsRepoProvider);
    final data = await repo.getProvisions(year: _year);
    if (mounted) {
      setState(() {
        _provisions = data;
        _loading = false;
      });
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '₹0';
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFFF0FDF4);
      case 'Partially Approved':
        return const Color(0xFFEFF6FF);
      case 'Rejected':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFFEFCE8);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF15803D);
      case 'Partially Approved':
        return const Color(0xFF1D4ED8);
      case 'Rejected':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFA16207);
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFFBBF7D0);
      case 'Partially Approved':
        return const Color(0xFFBFDBFE);
      case 'Rejected':
        return const Color(0xFFFECACA);
      default:
        return const Color(0xFFFEF08A);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
      case 'Partially Approved':
        return Icons.check_circle_outline_rounded;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _getStatusText(String status, bool isMr) {
    switch (status) {
      case 'Approved':
        return isMr ? 'मंजूर' : 'Approved';
      case 'Partially Approved':
        return isMr ? 'अंशतः मंजूर' : 'Partially Approved';
      case 'Rejected':
        return isMr ? 'नाकारले' : 'Rejected';
      default:
        return isMr ? 'प्रलंबित' : 'Pending';
    }
  }

  // Add Provision Request Modal matching WardProvisions.tsx lines 347-456
  void _openAddModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final reqAmtCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Roads & Civil');
    final areaCtrl = TextEditingController(text: 'Ward 12');
    final refCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String finYear = _year;

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
                          'Add Provision Request',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(height: 20),

                    // Title
                    const Text('Provision Proposal Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'Enter project name / provision title...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Requested Amount & Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Requested Amount (₹) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: reqAmtCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  hintText: 'e.g. 2500000',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                              const Text('Requested Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

                    // Category & Area
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
                                  hintText: 'e.g. Roads, Water, Health',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                              const Text('Area / Locality *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: areaCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Enter Area / Ward Sector',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Financial Year & Letter Reference
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Financial Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: finYear,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: '2024-2025', child: Text('FY 2024-2025')),
                                  DropdownMenuItem(value: '2023-2024', child: Text('FY 2023-2024')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => finYear = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Letter Ref No *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: refCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. PMC/RDS/1042',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Description
                    const Text('Detailed Scope / Justification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Brief details about the civic requirement...',
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
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter proposal title')),
                            );
                            return;
                          }

                          final newProv = WardProvisionModel(
                            id: 'prov-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            requestedAmount: double.tryParse(reqAmtCtrl.text.trim()) ?? 0,
                            sanctionedAmount: null,
                            requestedDate: dateCtrl.text.trim(),
                            sanctionedDate: null,
                            status: 'Pending',
                            financialYear: finYear,
                            category: catCtrl.text.trim().isNotEmpty ? catCtrl.text.trim() : 'General',
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                            letterReference: refCtrl.text.trim().isNotEmpty ? refCtrl.text.trim() : 'PMC/GEN/001',
                          );

                          final repo = ref.read(wardProvisionsRepoProvider);
                          await repo.addProvision(newProv);
                          await _loadProvisions();

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Provision request added successfully!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Provision Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  // Update Sanction Modal matching WardProvisions.tsx lines 460-540
  void _openUpdateModal(WardProvisionModel item) {
    final sancAmtCtrl = TextEditingController(text: (item.sanctionedAmount ?? item.requestedAmount).toStringAsFixed(0));
    final areaCtrl = TextEditingController(text: item.area);
    final sancDateCtrl = TextEditingController(text: item.sanctionedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String status = item.status == 'Pending' ? 'Approved' : item.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
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
                          'Update Sanction Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Divider(height: 16),

                    // Project overview card matching line 471
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROJECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 3),
                          Text(item.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text('Requested: ${_formatCurrency(item.requestedAmount)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sanctioned Amount
                    const Text('Sanctioned Amount (₹) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: sancAmtCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Area
                    const Text('Area / Ward Sector *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: areaCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sanctioned Date
                    const Text('Sanctioned Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: sancDateCtrl,
                      decoration: InputDecoration(
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Status Choices matching lines 511-526
                    const Text('Approval Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.8,
                      children: ['Approved', 'Partially Approved', 'Pending', 'Rejected'].map((s) {
                        final isSel = status == s;
                        return InkWell(
                          onTap: () => setModalState(() => status = s),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF0284C7) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                          final updated = item.copyWith(
                            sanctionedAmount: double.tryParse(sancAmtCtrl.text.trim()),
                            area: areaCtrl.text.trim(),
                            sanctionedDate: sancDateCtrl.text.trim(),
                            status: status,
                          );

                          final repo = ref.read(wardProvisionsRepoProvider);
                          await repo.updateProvision(updated);
                          await _loadProvisions();

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sanction details updated successfully!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: const Text('Update Sanction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  // Delete target modal matching lines 542-570
  void _confirmDelete(WardProvisionModel item) {
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Provision?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text('Are you sure you want to delete "${item.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(dCtx);
                final repo = ref.read(wardProvisionsRepoProvider);
                await repo.deleteProvision(item.id);
                await _loadProvisions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Provision deleted successfully')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);

    final totalRequested = _provisions.fold<double>(0, (sum, p) => sum + p.requestedAmount);
    final totalSanctioned = _provisions.fold<double>(0, (sum, p) => sum + (p.sanctionedAmount ?? 0));
    final successRate = totalRequested > 0 ? ((totalSanctioned / totalRequested) * 100).toStringAsFixed(1) : '0';

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
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          titleSpacing: 0,
          title: Text(
            isMr ? 'प्रभागनिहाय तरतूद' : 'Ward Wise Provision',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 22),
              tooltip: isMr ? 'PDF अहवाल' : 'Download PDF',
              onPressed: () {
                WardProvisionReportGenerator.generateAndPrintProvisionReport(
                  provisions: _provisions,
                  year: _year,
                );
              },
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : RefreshIndicator(
                onRefresh: _loadProvisions,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Sticky Header Section matching WardProvisions.tsx lines 157-206
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMr ? 'प्रभागनिहाय तरतूद' : 'Ward Wise Provision',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isMr ? 'वार्षिक बजेट तरतुदी आणि निधी वाटप' : 'Yearly municipal provisions & capital development allocations',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // FY Selector & PDF Download Bar matching lines 173-190
                          Row(
                            children: [
                              // FY Selector
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    DropdownButton<String>(
                                      value: _year,
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                      items: const [
                                        DropdownMenuItem(value: '2024-2025', child: Text('FY 2024-2025')),
                                        DropdownMenuItem(value: '2023-2024', child: Text('FY 2023-2024')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _year = val);
                                          _loadProvisions();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Download Report
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    WardProvisionReportGenerator.generateAndPrintProvisionReport(
                                      provisions: _provisions,
                                      year: _year,
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF0F9FF),
                                    foregroundColor: const Color(0xFF0284C7),
                                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.download_rounded, size: 16),
                                  label: Text(
                                    isMr ? 'PDF अहवाल' : 'Download PDF',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Overview Cards matching WardProvisions.tsx lines 208-242
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Total Requested Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFF0F9FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
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
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F9FF),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFBAE6FD)),
                                        ),
                                        child: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCurrency(totalRequested),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_provisions.length} ${isMr ? "प्रस्तावित कामे" : "pending requests"}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Total Sanctioned Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFF0FDF4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
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
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFBBF7D0)),
                                        ),
                                        child: const Icon(Icons.currency_rupee_rounded, size: 16, color: Color(0xFF16A34A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCurrency(totalSanctioned),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: totalRequested > 0 ? (totalSanctioned / totalRequested) : 0,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      color: const Color(0xFF0284C7),
                                      minHeight: 5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$successRate% success rate',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Provisions Table matching WardProvisions.tsx lines 245-344
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: _provisions.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  const Icon(Icons.description_outlined, size: 48, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 12),
                                  Text(
                                    isMr ? 'कोणतेही तरतूद रेकॉर्ड आढळले नाही' : 'No provision records found',
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                columnSpacing: 18,
                                columns: [
                                  DataColumn(label: Text(isMr ? 'प्रकल्प शीर्षक' : 'Title / Scope', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text(isMr ? 'परिसर' : 'Area', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text(isMr ? 'रक्कम' : 'Amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text(isMr ? 'स्थिती' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text(isMr ? 'तारीख' : 'Date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                                rows: _provisions.map((item) {
                                  return DataRow(
                                    cells: [
                                      // Title & Category + Reference matching lines 282-291
                                      DataCell(
                                        SizedBox(
                                          width: 180,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      item.category,
                                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      'Ref: ${item.letterReference}',
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Area matching line 293
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            item.area.isNotEmpty ? item.area : '-',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                          ),
                                        ),
                                      ),

                                      // Amount with Strikethrough if partial matching lines 296-300
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatCurrency(item.sanctionedAmount ?? item.requestedAmount),
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            ),
                                            if (item.sanctionedAmount != null && item.sanctionedAmount! < item.requestedAmount) ...[
                                              Text(
                                                'req: ${_formatCurrency(item.requestedAmount)}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF94A3B8),
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Status Badge matching lines 302-307
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _getStatusBg(item.status),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: _getStatusBorderColor(item.status)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_getStatusIcon(item.status), size: 12, color: _getStatusTextColor(item.status)),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getStatusText(item.status, isMr),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusTextColor(item.status),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Date matching line 309
                                      DataCell(
                                        Text(
                                          item.sanctionedDate ?? item.requestedDate,
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                        ),
                                      ),

                                      // Action Buttons matching lines 312-337
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                                              tooltip: 'Update Sanction',
                                              onPressed: () => _openUpdateModal(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                              tooltip: 'Delete',
                                              onPressed: () => _confirmDelete(item),
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

                    const SizedBox(height: 80),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: _openAddModal,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            isMr ? 'नवीन मागणी' : 'New Provision',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
