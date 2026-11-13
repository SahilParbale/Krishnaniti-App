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

  Widget _fieldLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
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
    );
  }

  InputDecoration _inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon, String? prefixText}) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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

  // Add Provision Request Modal matching WardProvisions.tsx lines 347-456
  void _openAddModal() {
    final isMr = ref.read(isMarathiProvider);
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
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(0xFF0284C7),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isMr ? 'नवीन तरतूद मागणी जोडा' : 'Add Provision Request',
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
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Title
                        _fieldLabel(isMr ? 'प्रस्तावित कामाचे नाव / शीर्षक' : 'Provision Proposal Title', isRequired: true),
                        TextField(
                          controller: titleCtrl,
                          decoration: _inputDec(
                            hintText: isMr ? 'प्रकल्प / कामाचे नाव प्रविष्ट करा...' : 'Enter project name / provision title...',
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Requested Amount & Date side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(isMr ? 'मागणी केलेली रक्कम (₹)' : 'Requested Amount (₹)', isRequired: true),
                                  TextField(
                                    controller: reqAmtCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDec(
                                      prefixText: '₹ ',
                                      hintText: 'e.g. 2500000',
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
                                  _fieldLabel(isMr ? 'मागणी तारीख' : 'Requested Date', isRequired: true),
                                  TextField(
                                    controller: dateCtrl,
                                    decoration: _inputDec(
                                      hintText: 'YYYY-MM-DD',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Category & Area side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(isMr ? 'श्रेणी / विभाग' : 'Category', isRequired: true),
                                  TextField(
                                    controller: catCtrl,
                                    decoration: _inputDec(
                                      hintText: isMr ? 'उदा. रस्ते, पाणी, आरोग्य' : 'e.g. Roads, Water, Health',
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
                                  _fieldLabel(isMr ? 'परिसर / प्रभाग भाग' : 'Area / Locality', isRequired: true),
                                  TextField(
                                    controller: areaCtrl,
                                    decoration: _inputDec(
                                      hintText: isMr ? 'उदा. शनिवार पेठ' : 'Enter Area / Ward Sector',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Financial Year & Letter Reference side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(isMr ? 'आर्थिक वर्ष' : 'Financial Year'),
                                  DropdownButtonFormField<String>(
                                    value: finYear,
                                    decoration: _inputDec(),
                                    items: const [
                                      DropdownMenuItem(value: '2024-2025', child: Text('FY 2024-2025', style: TextStyle(fontSize: 13))),
                                      DropdownMenuItem(value: '2023-2024', child: Text('FY 2023-2024', style: TextStyle(fontSize: 13))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => finYear = val);
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
                                  _fieldLabel(isMr ? 'पत्र संदर्भ क्र.' : 'Letter Ref No', isRequired: true),
                                  TextField(
                                    controller: refCtrl,
                                    decoration: _inputDec(
                                      hintText: 'e.g. PMC/RDS/1042',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Description
                        _fieldLabel(isMr ? 'सविस्तर स्वरूप / औचित्य' : 'Detailed Scope / Justification'),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: _inputDec(
                            hintText: isMr ? 'नागरी गरजेचा थोडक्यात तपशील...' : 'Brief details about the civic requirement...',
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                            label: Text(
                              isMr ? 'तरतूद मागणी जतन करा' : 'Save Provision Request',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: () async {
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isMr ? 'कृपया कामाचे नाव प्रविष्ट करा.' : 'Please enter proposal title',
                                    ),
                                  ),
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
                                  SnackBar(
                                    content: Text(
                                      isMr
                                          ? 'तरतूद मागणी यशस्वीरित्या जोडली गेली!'
                                          : 'Provision request added successfully!',
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
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

  // Update Sanction Modal matching WardProvisions.tsx lines 460-540
  void _openUpdateModal(WardProvisionModel item) {
    final isMr = ref.read(isMarathiProvider);
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
                              child: const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF0284C7),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isMr ? 'मंजुरी तपशील अद्यतनित करा' : 'Update Sanction Details',
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
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Project overview card
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
                              Text(
                                isMr ? 'प्रकल्प / काम' : 'PROJECT',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 3),
                              Text(item.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              Text(
                                '${isMr ? "मागणी रक्कम" : "Requested"}: ${_formatCurrency(item.requestedAmount)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Sanctioned Amount & Sanctioned Date side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(isMr ? 'मंजूर रक्कम (₹)' : 'Sanctioned Amount (₹)', isRequired: true),
                                  TextField(
                                    controller: sancAmtCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                    decoration: _inputDec(
                                      prefixText: '₹ ',
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
                                  _fieldLabel(isMr ? 'मंजूर तारीख' : 'Sanctioned Date', isRequired: true),
                                  TextField(
                                    controller: sancDateCtrl,
                                    decoration: _inputDec(
                                      hintText: 'YYYY-MM-DD',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Area
                        _fieldLabel(isMr ? 'परिसर / प्रभाग भाग' : 'Area / Ward Sector', isRequired: true),
                        TextField(
                          controller: areaCtrl,
                          decoration: _inputDec(),
                        ),
                        const SizedBox(height: 14),

                        // Status Choices
                        _fieldLabel(isMr ? 'मंजुरी स्थिती' : 'Approval Status', isRequired: true),
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
                                  _getStatusText(s, isMr),
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
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                            label: Text(
                              isMr ? 'मंजुरी अद्यतनित करा' : 'Update Sanction',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                  SnackBar(
                                    content: Text(
                                      isMr
                                          ? 'मंजुरी तपशील यशस्वीरित्या अद्यतनित केले!'
                                          : 'Sanction details updated successfully!',
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMr ? 'प्रभागनिहाय तरतूद' : 'Ward Wise Provision',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                isMr ? 'वार्षिक बजेट तरतुदी आणि निधी वाटप' : 'Yearly municipal provisions & capital development allocations',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: const [],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : RefreshIndicator(
                onRefresh: _loadProvisions,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // FY Selector & PDF Download Bar
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
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
