import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ward_budget_model.dart';
import '../../../data/repositories/ward_budget_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'ward_budget_detail_screen.dart';
import 'ward_budget_report_generator.dart';

class WardBudgetScreen extends ConsumerStatefulWidget {
  const WardBudgetScreen({super.key});

  @override
  ConsumerState<WardBudgetScreen> createState() => _WardBudgetScreenState();
}

class _WardBudgetScreenState extends ConsumerState<WardBudgetScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedYear = '2024-2025'; // '2024-2025' | '2023-2024' | 'All'
  String _selectedArea = 'All';
  String _viewMode = 'grid'; // 'grid' | 'table'

  bool _isLoading = true;
  List<WardBudgetModel> _allBudgets = [];

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
    final repo = ref.read(wardBudgetRepoProvider);
    final items = await repo.getBudgets(
      year: _selectedYear != 'All' ? _selectedYear : null,
    );
    if (mounted) {
      setState(() {
        _allBudgets = items;
        _isLoading = false;
      });
    }
  }

  List<String> get _areas {
    final list = _allBudgets.map((b) => b.area.trim()).where((a) => a.isNotEmpty).toSet().toList();
    list.sort();
    return ['All', ...list];
  }

  List<WardBudgetModel> get _filteredBudgets {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allBudgets.where((b) {
      if (_selectedYear != 'All' && b.financialYear != _selectedYear) {
        return false;
      }
      if (_selectedArea != 'All' && !b.area.toLowerCase().contains(_selectedArea.toLowerCase())) {
        return false;
      }
      if (query.isNotEmpty) {
        final catMatch = b.category.toLowerCase().contains(query);
        final areaMatch = b.area.toLowerCase().contains(query);
        final fyMatch = b.financialYear.toLowerCase().contains(query);
        if (!catMatch && !areaMatch && !fyMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showAddModal() {
    final isMr = ref.read(isMarathiProvider);
    final catCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final allocCtrl = TextEditingController();
    final utilCtrl = TextEditingController(text: '0');
    String fy = _selectedYear != 'All' ? _selectedYear : '2024-2025';

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
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF0284C7), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isMr ? 'नवीन बजेट तरतूद' : 'New Budget Allocation',
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

                    // Side-by-side: Financial Year & Category Head
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(isMr ? 'आर्थिक वर्ष' : 'Financial Year', isRequired: true),
                              DropdownButtonFormField<String>(
                                initialValue: fy,
                                decoration: inputDec(),
                                items: const [
                                  DropdownMenuItem(value: '2024-2025', child: Text('2024-2025')),
                                  DropdownMenuItem(value: '2023-2024', child: Text('2023-2024')),
                                  DropdownMenuItem(value: '2022-2023', child: Text('2022-2023')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => fy = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
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
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Area / Location
                    fieldLabel(isMr ? 'क्षेत्र / ठिकाण' : 'Area / Location'),
                    TextField(
                      controller: areaCtrl,
                      decoration: inputDec(hint: isMr ? 'उदा. शिवाजी नगर' : 'e.g. Shivaji Nagar'),
                    ),
                    const SizedBox(height: 14),

                    // Side-by-side: Total Allocation Amount (₹) & Initial Utilized Amount (₹)
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
                              fieldLabel(isMr ? 'सुरुवातीचा खर्च निधी (₹)' : 'Initial Utilized (₹)'),
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

                    // Submit Button (Existing button - wired directly)
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
                              SnackBar(
                                content: Text(isMr ? 'कृपया वर्गवारी / बजेट शीर्ष प्रविष्ट करा' : 'Please enter category head'),
                              ),
                            );
                            return;
                          }
                          final alloc = double.tryParse(allocCtrl.text.trim());
                          if (alloc == null || alloc <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isMr ? 'कृपया वैध एकूण तरतूद रक्कम प्रविष्ट करा' : 'Please enter a valid total allocation amount'),
                              ),
                            );
                            return;
                          }
                          final util = double.tryParse(utilCtrl.text.trim()) ?? 0.0;

                          final newBudget = WardBudgetModel(
                            id: 'bdg-${DateTime.now().millisecondsSinceEpoch}',
                            financialYear: fy,
                            category: catCtrl.text.trim(),
                            totalAllocation: alloc,
                            utilizedAmount: util,
                            area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                            status: 'Active',
                            createdAt: DateTime.now().toIso8601String(),
                            updatedAt: DateTime.now().toIso8601String(),
                          );

                          final repo = ref.read(wardBudgetRepoProvider);
                          await repo.addBudget(newBudget);
                          await _loadData();

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isMr ? 'बजेट तरतूद यशस्वीरित्या जोडली गेली!' : 'Budget allocation added successfully!',
                                ),
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
                            Text(
                              isMr ? 'तरतूद जतन करा' : 'Save Allocation',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
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

  void _showQuickUpdateModal(WardBudgetModel item) {
    final isMr = ref.read(isMarathiProvider);
    final utilCtrl = TextEditingController(text: item.utilizedAmount.toInt().toString());
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: EdgeInsets.only(
            top: 8,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
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
            mainAxisSize: MainAxisSize.min,
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
                      isMr ? 'खर्च अपडेट करा' : 'Update Expenditure',
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

              // Head info box
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
                    Text(item.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${isMr ? "सध्याचा खर्च झालेला निधी" : "Current Utilized Amount"}: ${numFormat.format(item.utilizedAmount)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                    ),
                    Text(
                      '${isMr ? "एकूण मंजूर" : "Total Sanctioned"}: ${numFormat.format(item.totalAllocation)} | ${isMr ? "क्षेत्र" : "Area"}: ${item.area}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: RichText(
                  text: TextSpan(
                    text: isMr ? 'नवीन एकूण खर्च (₹)' : 'New Total Utilized Amount (₹)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              TextField(
                controller: utilCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: inputDec(prefixText: '₹ '),
              ),
              const SizedBox(height: 20),

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
                    final newUtil = double.tryParse(utilCtrl.text.trim());
                    if (newUtil == null || newUtil < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isMr ? 'कृपया वैध रक्कम प्रविष्ट करा' : 'Please enter a valid amount')),
                      );
                      return;
                    }

                    final repo = ref.read(wardBudgetRepoProvider);
                    await repo.updateUtilization(item.id, newUtil);
                    await _loadData();

                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isMr ? 'खर्च यशस्वीरित्या अपडेट केला!' : 'Expenditure updated successfully!'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    }
                  },
                  child: Text(isMr ? 'अपडेट करा' : 'Update', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(WardBudgetModel item) {
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
          'Are you sure you want to delete "${item.category}"? This cannot be undone.',
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
              final repo = ref.read(wardBudgetRepoProvider);
              await repo.deleteBudget(item.id);
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget head deleted'), backgroundColor: Colors.red),
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
    final displayed = _filteredBudgets;
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    final totalAllocated = displayed.fold<double>(0, (sum, b) => sum + b.totalAllocation);
    final totalUtilized = displayed.fold<double>(0, (sum, b) => sum + b.utilizedAmount);
    final totalRemaining = (totalAllocated - totalUtilized).clamp(0.0, double.infinity);
    final utilizationPercentage = totalAllocated > 0 ? (totalUtilized / totalAllocated) * 100 : 0.0;

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
            children: const [
              Text(
                'Ward Budget',
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
                'Ward funds & budget tracking',
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            isMr ? 'नवीन बजेट वाटप' : 'Add Allocation',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _showAddModal,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3 Overview KPI Summary Cards matching web BudgetDashboard
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 600;
                            return Flex(
                              direction: isWide ? Axis.horizontal : Axis.vertical,
                              children: [
                                // Allocated Card
                                Expanded(
                                  flex: isWide ? 1 : 0,
                                  child: _overviewCard(
                                    title: isMr ? 'एकूण वाटप' : 'Total Allocated',
                                    amount: numFormat.format(totalAllocated),
                                    icon: Icons.account_balance_wallet_outlined,
                                    iconColor: const Color(0xFF0284C7),
                                    iconBgColor: const Color(0xFFEFF6FF),
                                    footerWidget: Row(
                                      children: [
                                        const Icon(Icons.trending_up, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Financial Year $_selectedYear',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),

                                // Utilized Card
                                Expanded(
                                  flex: isWide ? 1 : 0,
                                  child: _overviewCard(
                                    title: isMr ? 'खर्च झालेला निधी' : 'Total Utilized',
                                    amount: numFormat.format(totalUtilized),
                                    icon: Icons.pie_chart_outline_rounded,
                                    iconColor: const Color(0xFF6366F1),
                                    iconBgColor: const Color(0xFFEEF2FF),
                                    footerWidget: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: (utilizationPercentage / 100).clamp(0.0, 1.0),
                                            minHeight: 6,
                                            backgroundColor: const Color(0xFFE2E8F0),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              _getPctColor(utilizationPercentage),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${utilizationPercentage.toStringAsFixed(1)}% utilized',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),

                                // Remaining Card
                                Expanded(
                                  flex: isWide ? 1 : 0,
                                  child: _overviewCard(
                                    title: isMr ? 'शिल्लक उपलब्ध निधी' : 'Remaining Available',
                                    amount: numFormat.format(totalRemaining),
                                    icon: Icons.savings_outlined,
                                    iconColor: const Color(0xFF16A34A),
                                    iconBgColor: const Color(0xFFF0FDF4),
                                    footerWidget: Text(
                                      isMr ? 'पुढील प्रभाग विकास कामांसाठी उपलब्ध' : 'Available for ward works',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Search & Area Filter Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Search field
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: isMr ? 'बजेट खाते किंवा परिसर शोधा...' : 'Search budget head or area...',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                                  suffixIcon: _searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Area Dropdown
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _areas.contains(_selectedArea) ? _selectedArea : 'All',
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                                    items: _areas.map((a) {
                                      return DropdownMenuItem(
                                        value: a,
                                        child: Text(
                                          a == 'All' ? (isMr ? 'सर्व परिसर' : 'All Areas') : a,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedArea = val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Financial Year Selector
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedYear,
                                  icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0284C7), size: 18),
                                  style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12),
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
                            const SizedBox(width: 8),
                            // View Mode Switcher
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _viewMode = _viewMode == 'grid' ? 'table' : 'grid';
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Icon(
                                  _viewMode == 'grid' ? Icons.table_chart_rounded : Icons.grid_view_rounded,
                                  size: 20,
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Download PDF
                            InkWell(
                              onTap: () {
                                WardBudgetReportGenerator.generateAndPrintBudgetReport(
                                  budgets: displayed,
                                  year: _selectedYear,
                                  areaFilter: _selectedArea != 'All' ? _selectedArea : null,
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.download_rounded, size: 20, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Content Section
                      if (displayed.isEmpty)
                        Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isMr ? 'कोणतेही बजेट खाते सापडले नाही' : 'No Budget Records Found',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isMr ? 'कृपया शोध निकष बदला किंवा नवीन बजेट वाटप जोडा.' : 'Try adjusting your filters or add a new allocation.',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else if (_viewMode == 'grid')
                        _buildGridCardView(displayed, isMr, numFormat)
                      else
                        _buildTableView(displayed, isMr, numFormat),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _overviewCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Widget footerWidget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          footerWidget,
        ],
      ),
    );
  }

  Widget _buildGridCardView(List<WardBudgetModel> items, bool isMr, NumberFormat numFormat) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = items[index];
        final percent = item.utilizationPercentage;

        return InkWell(
          onTap: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WardBudgetDetailScreen(budget: item)),
            );
            if (res == true) _loadData();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                // Top chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.financialYear,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 2),
                          Text(
                            item.area,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: item.statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category Title
                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Amounts strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      _miniAmountPill('Allocated', numFormat.format(item.totalAllocation), const Color(0xFF0F172A)),
                      _miniAmountPill('Utilized', numFormat.format(item.utilizedAmount), const Color(0xFF0284C7)),
                      _miniAmountPill('Remaining', numFormat.format(item.remainingAmount), const Color(0xFF16A34A)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${percent.toStringAsFixed(0)}% utilized',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.progressColor),
                    ),
                    Text(
                      'Balance: ${numFormat.format(item.remainingAmount)}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(item.progressColor),
                  ),
                ),
                const Divider(height: 24),

                // Actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quick update expenditure
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF0284C7)),
                      label: Text(
                        isMr ? 'खर्च अपडेट' : 'Update Utilized',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                      onPressed: () => _showQuickUpdateModal(item),
                    ),

                    Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => WardBudgetDetailScreen(budget: item)),
                            );
                            if (res == true) _loadData();
                          },
                          child: Row(
                            children: [
                              Text(
                                isMr ? 'तपशील' : 'Details',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF475569)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showDeleteConfirmation(item),
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

  Widget _miniAmountPill(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(List<WardBudgetModel> items, bool isMr, NumberFormat numFormat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: [
              DataColumn(label: Text(isMr ? 'अ.क्र.' : '#', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'बजेट खाते' : 'Category / Head', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'परिसर' : 'Area', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'मंजूर वाटप' : 'Allocated', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'झालेला खर्च' : 'Utilized', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'प्रगती' : 'Progress', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(isMr ? 'कृती' : 'Actions', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              final percent = item.utilizationPercentage;

              return DataRow(
                cells: [
                  DataCell(Text('$idx')),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.category,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(item.financialYear, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(item.area, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(numFormat.format(item.totalAllocation), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                  DataCell(Text(numFormat.format(item.utilizedAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                  DataCell(
                    SizedBox(
                      width: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (percent / 100).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(item.progressColor),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${percent.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: item.progressColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF0284C7)),
                          tooltip: 'Update Utilized',
                          onPressed: () => _showQuickUpdateModal(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF475569)),
                          tooltip: 'View Details',
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => WardBudgetDetailScreen(budget: item)),
                            );
                            if (res == true) _loadData();
                          },
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

  static Color _getPctColor(double pct) {
    if (pct >= 80) return const Color(0xFF16A34A);
    if (pct >= 50) return const Color(0xFFCA8A04);
    return const Color(0xFFDC2626);
  }
}
