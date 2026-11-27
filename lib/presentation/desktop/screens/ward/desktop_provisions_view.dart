import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_translations.dart';
import '../../shell/desktop_sidebar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/ward_provision_model.dart';
import '../../../../data/repositories/ward_provisions_repository.dart';
import '../../common/desktop_modal_dialog.dart';
import '../../../screens/ward_provisions/ward_provision_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopProvisionsView extends ConsumerStatefulWidget {
  const DesktopProvisionsView({super.key});

  @override
  ConsumerState<DesktopProvisionsView> createState() => _DesktopProvisionsViewState();
}

class _DesktopProvisionsViewState extends ConsumerState<DesktopProvisionsView> {
  String _year = '2024-2025';
  bool _loading = true;
  List<WardProvisionModel> _provisions = [];
  int _displayedLimit = 20;

  List<WardProvisionModel> get _visibleProvisions =>
      _provisions.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadProvisions();
  }

  Future<void> _loadProvisions() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(wardProvisionsRepoProvider);
      final list = await repo.getProvisions(year: _year);
      if (mounted) {
        setState(() {
          _provisions = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _provisions = [];
          _loading = false;
        });
      }
    }
  }

  double get _totalRequested =>
      _provisions.fold(0.0, (sum, p) => sum + p.requestedAmount);

  double get _totalSanctioned =>
      _provisions.fold(0.0, (sum, p) => sum + (p.sanctionedAmount ?? 0.0));

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(amount);
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  void _showAddModal() {
    final titleController = TextEditingController();
    final reqAmountController = TextEditingController();
    final catController = TextEditingController();
    final areaController = TextEditingController(text: 'Ward 12');
    final refController = TextEditingController();
    String dateStr = DateTime.now().toIso8601String().split('T')[0];

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => DesktopModalDialog(
        title: 'Add Provision Request',
        subtitle: 'Municipal provisions, ward works and sanctioned projects',
        icon: Icons.handshake_outlined,
        width: 560,
        onClose: () => Navigator.pop(ctx),
        actions: [
          DesktopModalDialog.cancelButton(ctx),
          const SizedBox(width: 12),
          DesktopModalDialog.primaryButton(
            text: 'Save Provision',
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              final newProvision = WardProvisionModel(
                id: 'prov-${DateTime.now().millisecondsSinceEpoch}',
                title: titleController.text.trim(),
                requestedAmount: double.tryParse(reqAmountController.text.trim()) ?? 0,
                requestedDate: dateStr,
                category: catController.text.trim().isEmpty ? 'General' : catController.text.trim(),
                area: areaController.text.trim().isEmpty ? 'Ward 12' : areaController.text.trim(),
                letterReference: refController.text.trim(),
                financialYear: _year,
              );

              final repo = ref.read(wardProvisionsRepoProvider);
              await repo.addProvision(newProvision);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadProvisions();
            },
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text('Project Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: titleController,
              decoration: desktopInputDecoration(hintText: 'e.g. Ward road concretization...'),
            ),
            const SizedBox(height: 16),

            // Requested Amount & Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Requested Amount (₹) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reqAmountController,
                        keyboardType: TextInputType.number,
                        decoration: desktopInputDecoration(
                          hintText: '500000',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 14, right: 6),
                            child: Text('₹ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          ),
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
                      const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: AppColors.slate200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateStr, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category & Area
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: catController,
                        decoration: desktopInputDecoration(hintText: 'e.g. Roads, Water Supply, Drainage'),
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
                        decoration: desktopInputDecoration(hintText: 'Ward 12'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Letter Reference
            const Text('Letter Reference', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: refController,
              decoration: desktopInputDecoration(hintText: 'e.g. Letter Ref PMC/2024/782'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateModal(WardProvisionModel item) {
    final sancAmountController = TextEditingController(
      text: item.sanctionedAmount != null ? item.sanctionedAmount!.toInt().toString() : item.requestedAmount.toInt().toString(),
    );
    String selectedStatus = item.status == 'Pending' ? 'Approved' : item.status;
    String sancDate = item.sanctionedDate ?? DateTime.now().toIso8601String().split('T')[0];

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DesktopModalDialog(
            title: 'Update Sanction Details',
            subtitle: item.title,
            icon: Icons.edit_note_rounded,
            width: 500,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: 'Update',
                onPressed: () async {
                  final updated = item.copyWith(
                    sanctionedAmount: double.tryParse(sancAmountController.text.trim()) ?? item.requestedAmount,
                    sanctionedDate: sancDate,
                    status: selectedStatus,
                  );

                  final repo = ref.read(wardProvisionsRepoProvider);
                  await repo.updateProvision(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadProvisions();
                },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sanctioned Amount
                const Text('Sanctioned Amount (₹) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: sancAmountController,
                  keyboardType: TextInputType.number,
                  decoration: desktopInputDecoration(
                    hintText: 'Enter amount',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 6),
                      child: Text('₹ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status
                const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                AppDropdown<String>(
                  value: selectedStatus,
                  height: 44,
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  items: const [
                    DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'Partially Approved', child: Text('Partially Approved')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedStatus = val);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(WardProvisionModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Provision'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(wardProvisionsRepoProvider);
              await repo.deleteProvision(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadProvisions();
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
    final successRate = _totalRequested > 0 ? (_totalSanctioned / _totalRequested) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(),
          const SizedBox(height: 24),

          // Overview 2-Card Row
          Row(
            children: [
              // Total Requested Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Demanded Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: const Icon(Icons.access_time_filled, size: 20, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatCurrency(_totalRequested),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text('${_provisions.length} budget demands registered', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Total Sanctioned Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Sanctioned Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: const Icon(Icons.currency_rupee, size: 20, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatCurrency(_totalSanctioned),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 12),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: _totalRequested > 0 ? (_totalSanctioned / _totalRequested).clamp(0.0, 1.0) : 0.0,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${successRate.toStringAsFixed(1)}% Approval Rate',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Provisions Table Card
          _buildTableCard(),

          if (!_loading && _provisions.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: _visibleProvisions.length,
              totalCount: _provisions.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: 'तरतुदी',
              isMarathi: true,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ward Wise Provision',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ward budget demands, approvals and sanction tracking',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),

        // Year select & action buttons
        Row(
          children: [
            // Year Selector
            AppDropdown<String>(
              value: _year,
              height: 40,
              width: 160,
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF94A3B8)),
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
              items: const [
                DropdownMenuItem(value: '2024-2025', child: Text('FY 2024-2025')),
                DropdownMenuItem(value: '2023-2024', child: Text('FY 2023-2024')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _year = val;
                    _displayedLimit = 20;
                  });
                  _loadProvisions();
                }
              },
            ),
            const SizedBox(width: 12),

            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                WardProvisionReportGenerator.generateAndPrintProvisionReport(
                  context: context,
                  provisions: _provisions,
                  year: _year,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.getDownloadReport(ref.watch(desktopLanguageProvider)),
                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),

            // Add Request Button (ns-btn-primary matching WardProvisions.tsx)
            ElevatedButton(
              onPressed: _showAddModal,
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
                    'Add Provision Request',
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

  Widget _buildTableCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_provisions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: const [
                    Icon(Icons.folder_open_outlined, size: 48, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 12),
                    const Text('No provision records found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columnSpacing: 28,
                  horizontalMargin: 24,
                  columns: const [
                    const DataColumn(label: Text('Project Title / Ref', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    const DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    const DataColumn(label: Text('Sanctioned / Demanded', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                  ],
                  rows: _visibleProvisions.map((item) {
                    final displayAmount = item.sanctionedAmount ?? item.requestedAmount;
                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.category.toUpperCase(),
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  if (item.letterReference.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text('Ref: ${item.letterReference}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(item.area, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_formatCurrency(displayAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              if (item.sanctionedAmount != null && item.sanctionedAmount! < item.requestedAmount)
                                Text(
                                  'Demanded: ${_formatCurrency(item.requestedAmount)}',
                                  style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Color(0xFF94A3B8)),
                                ),
                            ],
                          ),
                        ),
                        DataCell(_buildStatusBadge(item.status)),
                        DataCell(Text(_formatDate(item.sanctionedDate ?? item.requestedDate), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                tooltip: 'Update Sanction',
                                onPressed: () => _showUpdateModal(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                tooltip: 'Delete',
                                onPressed: () => _showDeleteConfirm(item),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    Color border;
    IconData icon;

    if (status == 'Approved') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF15803D);
      border = const Color(0xFFBBF7D0);
      icon = Icons.check_circle_outline;
    } else if (status == 'Partially Approved') {
      bg = const Color(0xFFF0F9FF);
      text = const Color(0xFF0369A1);
      border = const Color(0xFFBAE6FD);
      icon = Icons.check_circle_outline;
    } else if (status == 'Rejected') {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFB91C1C);
      border = const Color(0xFFFECACA);
      icon = Icons.cancel_outlined;
    } else {
      bg = const Color(0xFFFEFCE8);
      text = const Color(0xFFA16207);
      border = const Color(0xFFFEF08A);
      icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
        ],
      ),
    );
  }
}
