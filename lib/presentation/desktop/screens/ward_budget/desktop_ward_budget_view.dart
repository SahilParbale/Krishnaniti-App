import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../../../data/models/ward_budget_model.dart';
import '../../../../data/repositories/ward_budget_repository.dart';
import '../../common/desktop_modal_dialog.dart';
import '../../../screens/ward_budget/ward_budget_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopWardBudgetView extends ConsumerStatefulWidget {
  const DesktopWardBudgetView({super.key});

  @override
  ConsumerState<DesktopWardBudgetView> createState() => _DesktopWardBudgetViewState();
}

class _DesktopWardBudgetViewState extends ConsumerState<DesktopWardBudgetView> {
  String _year = '2024-2025';
  bool _loading = true;
  List<WardBudgetModel> _budgets = [];
  String _searchTerm = '';
  String _selectedArea = 'All';
  int _displayedLimit = 20;

  List<WardBudgetModel> get _visibleBudgets =>
      _filteredBudgets.take(_displayedLimit).toList();

  List<String> get _uniqueAreas {
    final areas = _budgets
        .map((b) => (b.area).trim())
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...areas];
  }

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(wardBudgetRepoProvider);
      final data = await repo.getBudgets(year: _year);
      if (mounted) {
        setState(() {
          _budgets = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _budgets = [];
          _loading = false;
        });
      }
    }
  }

  double get _totalAllocated => _budgets.fold(0.0, (sum, b) => sum + b.totalAllocation);
  double get _totalUtilized => _budgets.fold(0.0, (sum, b) => sum + b.utilizedAmount);
  double get _totalRemaining => (_totalAllocated - _totalUtilized).clamp(0.0, double.infinity);
  double get _utilizationRate => _totalAllocated > 0 ? (_totalUtilized / _totalAllocated) * 100 : 0.0;

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(amount);
  }

  List<WardBudgetModel> get _filteredBudgets {
    return _budgets.where((b) {
      final matchesSearch = _searchTerm.isEmpty ||
          b.category.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          b.area.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesArea = _selectedArea == 'All' ||
          b.area.toLowerCase().trim() == _selectedArea.toLowerCase().trim();

      return matchesSearch && matchesArea;
    }).toList();
  }

  void _showAddBudgetModal() {
    final catController = TextEditingController();
    final totalController = TextEditingController();
    final utilizedController = TextEditingController(text: '0');
    final areaController = TextEditingController(text: 'Ward 12');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => DesktopModalDialog(
        title: 'Add New Budget Provision',
        subtitle: 'Sanction and track municipal budget allocations across ward sectors',
        icon: Icons.account_balance_wallet_rounded,
        width: 540,
        onClose: () => Navigator.pop(ctx),
        actions: [
          DesktopModalDialog.cancelButton(ctx),
          const SizedBox(width: 12),
          DesktopModalDialog.primaryButton(
            text: 'Save Provision',
            onPressed: () async {
              if (catController.text.trim().isEmpty) return;
              final newBudget = WardBudgetModel(
                id: 'budget-${DateTime.now().millisecondsSinceEpoch}',
                financialYear: _year,
                category: catController.text.trim(),
                totalAllocation: double.tryParse(totalController.text.trim()) ?? 0,
                utilizedAmount: double.tryParse(utilizedController.text.trim()) ?? 0,
                area: areaController.text.trim().isEmpty ? 'Ward 12' : areaController.text.trim(),
                createdAt: DateTime.now().toIso8601String(),
                updatedAt: DateTime.now().toIso8601String(),
              );

              final repo = ref.read(wardBudgetRepoProvider);
              await repo.addBudget(newBudget);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadBudgets();
            },
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category / Work Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: catController,
              decoration: desktopInputDecoration(hintText: 'e.g. Road maintenance, Park development'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sanctioned Allocation (₹) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: totalController,
                        keyboardType: TextInputType.number,
                        decoration: desktopInputDecoration(
                          hintText: '1000000',
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
            const Text('Initial Utilized Amount (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: utilizedController,
              keyboardType: TextInputType.number,
              decoration: desktopInputDecoration(
                hintText: '0',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 6),
                  child: Text('₹ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateUtilizationModal(WardBudgetModel item) {
    final controller = TextEditingController(text: item.utilizedAmount.toInt().toString());

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => DesktopModalDialog(
        title: 'Update Utilized Expenditure',
        subtitle: item.category,
        icon: Icons.edit_note_rounded,
        width: 480,
        onClose: () => Navigator.pop(ctx),
        actions: [
          DesktopModalDialog.cancelButton(ctx),
          const SizedBox(width: 12),
          DesktopModalDialog.primaryButton(
            text: 'Save Update',
            onPressed: () async {
              final val = double.tryParse(controller.text.trim()) ?? item.utilizedAmount;
              final repo = ref.read(wardBudgetRepoProvider);
              await repo.updateUtilization(item.id, val);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadBudgets();
            },
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Sanctioned:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  Text(_formatCurrency(item.totalAllocation), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('New Utilized Amount (₹) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: desktopInputDecoration(
                hintText: 'Enter new amount',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 6),
                  child: Text('₹ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(WardBudgetModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Budget Provision'),
        content: Text('Are you sure you want to delete "${item.category}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(wardBudgetRepoProvider);
              await repo.deleteBudget(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadBudgets();
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
    final lang = ref.watch(appLanguageProvider);
    final filtered = _filteredBudgets;
    final visible = _visibleBudgets;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(lang),
          const SizedBox(height: 24),

          // 4 Stat Cards
          _buildStatCards(lang),
          const SizedBox(height: 24),

          // Filters Row
          _buildFilterRow(lang),
          const SizedBox(height: 24),

          // Content Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildCardGrid(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: lang == 'mr' ? 'तरतुदी' : (lang == 'hi' ? 'प्रावधान' : 'provisions'),
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.getNavTitle('budget', lang),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lang == 'mr'
                  ? 'प्रभाग विकास निधी वाटप, खर्च आणि शिल्लक निधी व्यवस्थापन'
                  : (lang == 'hi'
                      ? 'वार्ड विकास निधि आवंटन, व्यय और शेष निधि प्रबंधन'
                      : 'Municipal budget allocation, expenditure and remaining fund tracking'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions
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
                  setState(() => _year = val);
                  _loadBudgets();
                }
              },
            ),
            const SizedBox(width: 12),

            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                WardBudgetReportGenerator.generateAndPrintBudgetReport(
                  context: context,
                  budgets: _budgets,
                  year: _year,
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                lang == 'mr' ? 'अहवाल डाउनलोड करा' : (lang == 'hi' ? 'रिपोर्ट डाउनलोड करें' : 'Download Report'),
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

            // Add Budget Allocation (ns-btn-primary matching BudgetDashboard.tsx)
            ElevatedButton(
              onPressed: _showAddBudgetModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    lang == 'mr' ? 'नवीन तरतूद जोडा' : (lang == 'hi' ? 'नई निधि जोड़ें' : 'Add Budget Provision'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildStatCards(String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            // Card 1: Total Allocated
            _statCard(
              title: AppTranslations.t('budget.allocated', lang: lang),
              amount: _formatCurrency(_totalAllocated),
              subtitle: lang == 'mr' ? 'प्रभाग क्र. १२' : (lang == 'hi' ? 'वार्ड नं. १२' : 'Ward No 12'),
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFF0F9FF),
            ),

            // Card 2: Total Utilized
            _statCard(
              title: AppTranslations.t('budget.utilized', lang: lang),
              amount: _formatCurrency(_totalUtilized),
              subtitle: lang == 'mr' ? 'प्रगतीपथावर आणि पूर्ण झालेली कामे' : (lang == 'hi' ? 'जारी और पूर्ण हुए कार्य' : 'Ongoing and completed works'),
              icon: Icons.trending_up,
              iconColor: const Color(0xFF16A34A),
              iconBgColor: const Color(0xFFF0FDF4),
            ),

            // Card 3: Remaining Balance
            _statCard(
              title: AppTranslations.t('budget.remaining', lang: lang),
              amount: _formatCurrency(_totalRemaining),
              subtitle: lang == 'mr' ? 'नियोजित कामांसाठी उपलब्ध' : (lang == 'hi' ? 'योजनाबद्ध कार्यों के लिए उपलब्ध' : 'Available for planned works'),
              icon: Icons.currency_rupee,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFFFBEB),
            ),

            // Card 4: Utilization Rate
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'mr' ? 'वापर दर' : (lang == 'hi' ? 'उपयोग दर' : 'Utilization Rate'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.pie_chart_outline, size: 16, color: Color(0xFF7E22CE)),
                      ),
                    ],
                  ),
                  Text(
                    '${_utilizationRate.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: (_utilizationRate / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _utilizationRate >= 80 ? const Color(0xFF16A34A) : (_utilizationRate >= 50 ? const Color(0xFFCA8A04) : const Color(0xFFDC2626)),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Text(amount, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildFilterRow(String lang) {
    return Row(
      children: [
        // Category Search (Col 8)
        Expanded(
          flex: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _searchTerm = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.t('budget.search_placeholder', lang: lang),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Area Filter (Col 4)
        Expanded(
          flex: 4,
          child: AppDropdown<String>(
            value: _selectedArea,
            height: 44,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueAreas.map((area) {
              final label = area == 'All'
                  ? (lang == 'mr' ? 'सर्व क्षेत्रे' : (lang == 'hi' ? 'सभी क्षेत्र' : 'All Areas'))
                  : area;
              return DropdownMenuItem(
                value: area,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedArea = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<WardBudgetModel> items, String lang) {
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
          children: [
            const Icon(Icons.account_balance_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              lang == 'mr'
                  ? 'कोणतीही तरतूद सापडली नाही'
                  : (lang == 'hi' ? 'कोई बजट आवंटन नहीं मिला' : 'No budget allocations found'),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
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
            final pct = item.utilizationPercentage;

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
                  // Top: Category title + Area badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AppTranslatedText(item.category,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: AppTranslatedText(item.area,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Numbers: Allocation, Utilized, Remaining
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppTranslations.t('budget.allocated', lang: lang), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(_formatCurrency(item.totalAllocation), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppTranslations.t('budget.utilized', lang: lang), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(_formatCurrency(item.utilizedAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppTranslations.t('budget.remaining', lang: lang), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(_formatCurrency(item.remainingAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar & Percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'mr' ? 'वापर' : (lang == 'hi' ? 'उपयोग' : 'Usage'),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.progressColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(item.progressColor),
                      minHeight: 6,
                    ),
                  ),
                  const Spacer(),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showUpdateUtilizationModal(item),
                          icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0284C7)),
                          label: Text(
                            lang == 'mr' ? 'खर्च अद्ययावत करा' : (lang == 'hi' ? 'व्यय अपडेट करें' : 'Update Utilized'),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBAE6FD)),
                            backgroundColor: const Color(0xFFF0F9FF),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                          onPressed: () => _showDeleteConfirm(item),
                          tooltip: AppTranslations.getCommon('delete', lang),
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
