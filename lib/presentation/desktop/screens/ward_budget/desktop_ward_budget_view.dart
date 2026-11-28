import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
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

  String _formatCurrency(double amount, String lang) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return AppTranslations.formatDigits(format.format(amount), lang);
  }

  List<WardBudgetModel> get _filteredBudgets {
    final q = AppTranslations.normalizeAsciiDigits(_searchTerm.trim()).toLowerCase();
    return _budgets.where((b) {
      final matchesSearch = q.isEmpty ||
          AppTranslations.normalizeAsciiDigits(b.category).toLowerCase().contains(q) ||
          AppTranslations.normalizeAsciiDigits(b.area).toLowerCase().contains(q);

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
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final lang = modalRef.watch(desktopLanguageProvider);
          return DesktopModalDialog(
            title: AppTranslations.pick(
              lang,
              en: 'Add New Budget Provision',
              mr: 'नवीन बजेट तरतूद जोडा',
              hi: 'नया बजट प्रावधान जोड़ें',
            ),
            subtitle: AppTranslations.pick(
              lang,
              en: 'Sanction and track municipal budget allocations across ward sectors',
              mr: 'प्रभाग क्षेत्रांमधील महापालिका बजेट वाटप मंजूर करा आणि ट्रॅक करा',
              hi: 'वार्ड क्षेत्रों में नगर निगम बजट आवंटन स्वीकृत और ट्रैक करें',
            ),
            icon: Icons.account_balance_wallet_rounded,
            width: 540,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: AppTranslations.pick(
                  lang,
                  en: 'Save Provision',
                  mr: 'तरतूद जतन करा',
                  hi: 'प्रावधान सहेजें',
                ),
                onPressed: () async {
                  if (catController.text.trim().isEmpty) return;
                  final newBudget = WardBudgetModel(
                    id: 'budget-${DateTime.now().millisecondsSinceEpoch}',
                    financialYear: _year,
                    category: catController.text.trim(),
                    totalAllocation: double.tryParse(
                          AppTranslations.normalizeAsciiDigits(totalController.text.trim()),
                        ) ??
                        0,
                    utilizedAmount: double.tryParse(
                          AppTranslations.normalizeAsciiDigits(utilizedController.text.trim()),
                        ) ??
                        0,
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
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Category / Work Title *',
                    mr: 'वर्गवारी / कामाचे शीर्षक *',
                    hi: 'श्रेणी / कार्य शीर्षक *',
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: catController,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'e.g. Road maintenance, Park development',
                      mr: 'उदा. रस्ते देखभाल, उद्यान विकास',
                      hi: 'उदा. सड़क रखरखाव, उद्यान विकास',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Sanctioned Allocation (₹) *',
                              mr: 'मंजूर तरतूद (₹) *',
                              hi: 'स्वीकृत आवंटन (₹) *',
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: totalController,
                            keyboardType: TextInputType.number,
                            decoration: desktopInputDecoration(
                              hintText: AppTranslations.formatDigits('1000000', lang),
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
                          Text(
                            AppTranslations.pick(lang, en: 'Ward / Area', mr: 'प्रभाग / परिसर', hi: 'वार्ड / क्षेत्र'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: areaController,
                            decoration: desktopInputDecoration(
                              hintText: AppTranslations.pick(lang, en: 'Ward 12', mr: 'प्रभाग १२', hi: 'वार्ड १२'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Initial Utilized Amount (₹)',
                    mr: 'प्रारंभिक खर्च रक्कम (₹)',
                    hi: 'प्रारंभिक उपयोग की गई राशि (₹)',
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: utilizedController,
                  keyboardType: TextInputType.number,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.formatDigits('0', lang),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 6),
                      child: Text('₹ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUpdateUtilizationModal(WardBudgetModel item) {
    final controller = TextEditingController(text: item.utilizedAmount.toInt().toString());

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final lang = modalRef.watch(desktopLanguageProvider);
          return DesktopModalDialog(
            title: AppTranslations.pick(
              lang,
              en: 'Update Utilized Expenditure',
              mr: 'खर्च अद्ययावत करा',
              hi: 'उपयोग किया गया व्यय अपडेट करें',
            ),
            subtitle: item.category,
            icon: Icons.edit_note_rounded,
            width: 480,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(ctx),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: AppTranslations.pick(lang, en: 'Save Update', mr: 'बदल जतन करा', hi: 'अपडेट सहेजें'),
                onPressed: () async {
                  final val = double.tryParse(
                        AppTranslations.normalizeAsciiDigits(controller.text.trim()),
                      ) ??
                      item.utilizedAmount;
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
                      Text(
                        AppTranslations.pick(lang, en: 'Total Sanctioned:', mr: 'एकूण मंजूर:', hi: 'कुल स्वीकृत:'),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      Text(
                        _formatCurrency(item.totalAllocation, lang),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'New Utilized Amount (₹) *',
                    mr: 'नवीन खर्च रक्कम (₹) *',
                    hi: 'नई उपयोग की गई राशि (₹) *',
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: desktopInputDecoration(
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Enter new amount',
                      mr: 'नवीन रक्कम प्रविष्ट करा',
                      hi: 'नई राशि दर्ज करें',
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 6),
                      child: Text('₹ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(WardBudgetModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final lang = modalRef.watch(desktopLanguageProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              AppTranslations.pick(
                lang,
                en: 'Delete Budget Provision',
                mr: 'बजेट तरतूद हटवा',
                hi: 'बजेट प्रावधान हटाएं',
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Are you sure you want to delete this budget provision?',
                    mr: 'तुम्हाला ही बजेट तरतूद नक्की हटवायची आहे का?',
                    hi: 'क्या आप वाकई इस बजट प्रावधान को हटाना चाहते हैं?',
                  ),
                ),
                const SizedBox(height: 6),
                AppTranslatedText(
                  '"${item.category}"',
                  targetLanguage: lang,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppTranslations.getCommon('cancel', lang)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final repo = ref.read(wardBudgetRepoProvider);
                  await repo.deleteBudget(item.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadBudgets();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                child: Text(
                  AppTranslations.getCommon('delete', lang),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredBudgets;
    final visible = _visibleBudgets;

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
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
              label: AppTranslations.pick(lang, en: 'provisions', mr: 'तरतुदी', hi: 'प्रावधान'),
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
        Expanded(
          child: Column(
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
                AppTranslations.pick(
                  lang,
                  en: 'Municipal budget allocation, expenditure and remaining fund tracking',
                  mr: 'प्रभाग विकास निधी वाटप, खर्च आणि शिल्लक निधी व्यवस्थापन',
                  hi: 'वार्ड विकास निधि आवंटन, व्यय और शेष निधि प्रबंधन',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions
        Row(
          children: [
            // Year Selector
            AppDropdown<String>(
              value: _year,
              height: 40,
              width: 175,
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF94A3B8)),
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
              items: [
                DropdownMenuItem(
                  value: '2024-2025',
                  child: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'FY 2024-2025',
                      mr: 'आर्थिक वर्ष २०२४-२०२५',
                      hi: 'वित्त वर्ष २०२४-२०२५',
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: '2023-2024',
                  child: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'FY 2023-2024',
                      mr: 'आर्थिक वर्ष २०२३-२०२४',
                      hi: 'वित्त वर्ष २०२३-२०२४',
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _year = val;
                    _displayedLimit = 20;
                  });
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
                  budgets: _filteredBudgets,
                  year: _year,
                  areaFilter: _selectedArea,
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.getDownloadReport(lang),
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
                    AppTranslations.pick(
                      lang,
                      en: 'Add Budget Provision',
                      mr: 'नवीन तरतूद जोडा',
                      hi: 'नई निधि जोड़ें',
                    ),
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
              amount: _formatCurrency(_totalAllocated, lang),
              subtitle: AppTranslations.pick(lang, en: 'Ward No 12', mr: 'प्रभाग क्र. १२', hi: 'वार्ड नं. १२'),
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFF0F9FF),
            ),

            // Card 2: Total Utilized
            _statCard(
              title: AppTranslations.t('budget.utilized', lang: lang),
              amount: _formatCurrency(_totalUtilized, lang),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Ongoing and completed works',
                mr: 'प्रगतीपथावर आणि पूर्ण झालेली कामे',
                hi: 'जारी और पूर्ण हुए कार्य',
              ),
              icon: Icons.trending_up,
              iconColor: const Color(0xFF16A34A),
              iconBgColor: const Color(0xFFF0FDF4),
            ),

            // Card 3: Remaining Balance
            _statCard(
              title: AppTranslations.t('budget.remaining', lang: lang),
              amount: _formatCurrency(_totalRemaining, lang),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Available for planned works',
                mr: 'नियोजित कामांसाठी उपलब्ध',
                hi: 'योजनाबद्ध कार्यों के लिए उपलब्ध',
              ),
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
                      Expanded(
                        child: Text(
                          AppTranslations.pick(lang, en: 'Utilization Rate', mr: 'वापर दर', hi: 'उपयोग दर'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.pie_chart_outline, size: 16, color: Color(0xFF7E22CE)),
                      ),
                    ],
                  ),
                  Text(
                    AppTranslations.formatDigits('${_utilizationRate.toStringAsFixed(1)}%', lang),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Text(amount, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  ? AppTranslations.getAllAreas(lang)
                  : AppTranslations.getAreaName(area, lang);
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
              AppTranslations.pick(
                lang,
                en: 'No budget allocations found',
                mr: 'कोणतीही तरतूद सापडली नाही',
                hi: 'कोई बजट आवंटन नहीं मिला',
              ),
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
                        child: AppTranslatedText(
                          item.category,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: AppTranslatedText(
                          AppTranslations.getAreaName(item.area, lang),
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
                          Text(_formatCurrency(item.totalAllocation, lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppTranslations.t('budget.utilized', lang: lang), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(_formatCurrency(item.utilizedAmount, lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppTranslations.t('budget.remaining', lang: lang), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(_formatCurrency(item.remainingAmount, lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
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
                        AppTranslations.pick(lang, en: 'Usage', mr: 'वापर', hi: 'उपयोग'),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      Text(
                        AppTranslations.formatDigits('${pct.toStringAsFixed(1)}%', lang),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.progressColor),
                      ),
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
                            AppTranslations.pick(
                              lang,
                              en: 'Update Utilized',
                              mr: 'खर्च अद्ययावत करा',
                              hi: 'व्यय अपडेट करें',
                            ),
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
