import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ward_budget_model.dart';
import '../../../data/repositories/ward_budget_repository.dart';
import '../../providers/auth_provider.dart';

class WardBudgetDetailScreen extends ConsumerStatefulWidget {
  final WardBudgetModel budget;

  const WardBudgetDetailScreen({super.key, required this.budget});

  @override
  ConsumerState<WardBudgetDetailScreen> createState() => _WardBudgetDetailScreenState();
}

class _WardBudgetDetailScreenState extends ConsumerState<WardBudgetDetailScreen> {
  late WardBudgetModel _currentBudget;
  bool _isDeleting = false;
  final TextEditingController _utilizeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentBudget = widget.budget;
    _utilizeCtrl.text = _currentBudget.utilizedAmount.toInt().toString();
  }

  @override
  void dispose() {
    _utilizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateUtilization() async {
    final newAmount = double.tryParse(_utilizeCtrl.text.trim());
    if (newAmount == null || newAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final repo = ref.read(wardBudgetRepoProvider);
    await repo.updateUtilization(_currentBudget.id, newAmount);
    final updated = _currentBudget.copyWith(
      utilizedAmount: newAmount,
      updatedAt: DateTime.now().toIso8601String(),
    );

    if (mounted) {
      setState(() => _currentBudget = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget utilization updated successfully!'),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Budget Head'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${_currentBudget.category}" from the Ward Budget? This action cannot be undone.',
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
              setState(() => _isDeleting = true);
              final repo = ref.read(wardBudgetRepoProvider);
              await repo.deleteBudget(_currentBudget.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Budget allocation deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditModal() {
    final isMr = ref.read(isMarathiProvider);
    final catCtrl = TextEditingController(text: _currentBudget.category);
    final areaCtrl = TextEditingController(text: _currentBudget.area);
    final allocCtrl = TextEditingController(text: _currentBudget.totalAllocation.toInt().toString());
    final utilCtrl = TextEditingController(text: _currentBudget.utilizedAmount.toInt().toString());
    String fy = _currentBudget.financialYear;
    String status = _currentBudget.status;

    final years = ['2024-2025', '2023-2024', '2022-2023'];
    final statusOptions = ['Active', 'Closed'];

    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
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
              padding: EdgeInsets.only(
                top: 8,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(top: 6, bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isMr ? 'बजेट तरतूद संपादित करा' : 'Edit Budget Allocation',
                            style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 6),

                    // Side-by-side: Financial Year & Status
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(isMr ? 'आर्थिक वर्ष' : 'Financial Year', isRequired: true),
                              DropdownButtonFormField<String>(
                                initialValue: fy,
                                decoration: inputDec(),
                                items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => fy = val);
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
                              fieldLabel(isMr ? 'स्थिती' : 'Status', isRequired: true),
                              DropdownButtonFormField<String>(
                                initialValue: status,
                                decoration: inputDec(),
                                items: statusOptions
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s == 'Active' ? (isMr ? 'सक्रिय' : 'Active') : (isMr ? 'बंद' : 'Closed')),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => status = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Side-by-side: Category Head & Area / Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(isMr ? 'वर्गवारी / बजेट शीर्ष' : 'Category Head', isRequired: true),
                              TextField(
                                controller: catCtrl,
                                decoration: inputDec(hint: isMr ? 'उदा. रस्ते देखभाल' : 'e.g. Road Maintenance'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(isMr ? 'क्षेत्र / ठिकाण' : 'Area / Location'),
                              TextField(
                                controller: areaCtrl,
                                decoration: inputDec(hint: isMr ? 'उदा. शिवाजी नगर' : 'e.g. Shivaji Nagar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Side-by-side: Total Allocation Amount & Utilized Amount
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(isMr ? 'एकूण तरतूद रक्कम (₹)' : 'Total Allocation (₹)', isRequired: true),
                              TextField(
                                controller: allocCtrl,
                                keyboardType: TextInputType.number,
                                decoration: inputDec(hint: '0', prefixText: '₹ '),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(isMr ? 'खर्च झालेला निधी (₹)' : 'Utilized Amount (₹)'),
                              TextField(
                                controller: utilCtrl,
                                keyboardType: TextInputType.number,
                                decoration: inputDec(hint: '0', prefixText: '₹ '),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (catCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isMr ? 'कृपया वर्गवारी / बजेट शीर्ष प्रविष्ट करा' : 'Category head is required')),
                            );
                            return;
                          }

                          final totalAlloc = double.tryParse(allocCtrl.text.trim()) ?? _currentBudget.totalAllocation;
                          final utilized = double.tryParse(utilCtrl.text.trim()) ?? _currentBudget.utilizedAmount;

                          final updated = _currentBudget.copyWith(
                            financialYear: fy,
                            category: catCtrl.text.trim(),
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : _currentBudget.area,
                            totalAllocation: totalAlloc,
                            utilizedAmount: utilized,
                            status: status,
                            updatedAt: DateTime.now().toIso8601String(),
                          );

                          final repo = ref.read(wardBudgetRepoProvider);
                          await repo.updateBudget(updated);
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            setState(() {
                              _currentBudget = updated;
                              _utilizeCtrl.text = updated.utilizedAmount.toInt().toString();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isMr ? 'बजेट तरतूद यशस्वीरित्या अद्यतनित केली!' : 'Budget allocation updated successfully'),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(isMr ? 'बदल जतन करा' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
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

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final budget = _currentBudget;
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    final percent = budget.utilizationPercentage;

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
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context, true),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMr ? 'अंदाजपत्रक तपशील' : 'Budget Head Details',
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
                '${budget.financialYear} • ${budget.area}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit Budget',
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: 'Delete Budget',
              onPressed: _showDeleteConfirmation,
            ),
          ],
        ),
        body: _isDeleting
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Financial Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  budget.financialYear,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: budget.statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: budget.statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  budget.status,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: budget.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            budget.category,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                budget.area,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Divider(height: 28),

                          // 3 Financial KPIs
                          Row(
                            children: [
                              _kpiPill(
                                label: isMr ? 'एकूण वाटप' : 'Total Allocated',
                                amount: numFormat.format(budget.totalAllocation),
                                color: const Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 8),
                              _kpiPill(
                                label: isMr ? 'खर्च झालेला' : 'Utilized',
                                amount: numFormat.format(budget.utilizedAmount),
                                color: const Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 8),
                              _kpiPill(
                                label: isMr ? 'शिल्लक निधी' : 'Remaining',
                                amount: numFormat.format(budget.remainingAmount),
                                color: const Color(0xFF16A34A),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Progress bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isMr ? 'निधी वापर प्रगती' : 'Fund Utilization Progress',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                              Text(
                                '${percent.toStringAsFixed(1)}%',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: budget.progressColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (percent / 100).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(budget.progressColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Update Utilization Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_note_rounded, size: 22, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text(
                                isMr ? 'खर्च अद्ययावत करा (Update Utilization)' : 'Update Utilization',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            isMr
                                ? 'नवीन झालेला एकूण खर्च प्रविष्ट करा:'
                                : 'Enter updated cumulative expenditure for this budget head:',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _utilizeCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    prefixText: '₹ ',
                                    prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                    hintText: isMr ? 'रक्कम प्रविष्ट करा' : 'Enter amount',
                                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _handleUpdateUtilization,
                                child: Text(isMr ? 'अपडेट करा' : 'Update', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Administrative Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMr ? 'प्रशासकीय माहिती' : 'Administrative Context',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Divider(height: 20),
                          _infoRow(
                            icon: Icons.account_balance_rounded,
                            label: isMr ? 'बजेट खाते' : 'Budget Head',
                            value: budget.category,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.calendar_today_rounded,
                            label: isMr ? 'आर्थिक वर्ष' : 'Financial Year',
                            value: budget.financialYear,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.location_on_outlined,
                            label: isMr ? 'परिसर / प्रभाग' : 'Prabhag Area',
                            value: budget.area,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: isMr ? 'सध्याची स्थिती' : 'Account Status',
                            value: budget.status,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.access_time_rounded,
                            label: isMr ? 'नोंदणी तारीख' : 'Created Date',
                            value: _formatDate(budget.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _kpiPill({required String label, required String amount, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  static String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

