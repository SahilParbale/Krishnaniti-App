import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/ward_budget_model.dart';
import '../../../data/repositories/ward_budget_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
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
  int _displayedLimit = 20;

  bool _isLoading = true;
  List<WardBudgetModel> _allBudgets = [];

  List<WardBudgetModel> get _visibleBudgets =>
      _filteredBudgets.take(_displayedLimit).toList();

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
        _displayedLimit = 20;
      });
    }
  }

  List<String> get _areas {
    final list = _allBudgets.map((b) => b.area.trim()).where((a) => a.isNotEmpty).toSet().toList();
    list.sort();
    return ['All', ...list];
  }

  List<WardBudgetModel> get _filteredBudgets {
    final query = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim()).toLowerCase();

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
    final lang = ref.read(appLanguageProvider);
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                children: [
                  // 1. FIXED HEADER
                  AppModalHeader(
                    icon: Icons.account_balance_wallet_outlined,
                    title: AppTranslations.pick(lang, en: 'New Budget Allocation', mr: 'नवीन बजेट तरतूद', hi: 'नया बजट आवंटन'),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Record sanctioned budget and expenditure allocations',
                      mr: 'प्रभागासाठी मंजूर बजेट आणि खर्च नोंदवा',
                      hi: 'वार्ड के लिए स्वीकृत बजट और व्यय दर्ज करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),

                  // 2. SCROLLABLE FORM BODY & SUBMIT BUTTON
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(
                        18,
                        14,
                        18,
                        MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
                      ),
                      children: [
                        // Side-by-side: Financial Year & Category Head
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppDropdownFormField<String>(
                                    label: AppTranslations.pick(lang, en: 'Financial Year', mr: 'आर्थिक वर्ष', hi: 'वित्तीय वर्ष'),
                                    isRequired: true,
                                    value: fy,
                                    items: ['2024-2025', '2023-2024', '2022-2023']
                                        .map((y) => DropdownMenuItem(value: y, child: Text(AppTranslations.formatDigits(y, lang))))
                                        .toList(),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Category Head', mr: 'वर्गवारी / बजेट शीर्ष', hi: 'श्रेणी / बजट शीर्ष'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: catCtrl,
                                    decoration: inputDec(
                                      hint: AppTranslations.pick(lang, en: 'e.g. Road Maintenance', mr: 'उदा. रस्ते देखभाल', hi: 'उदा. सड़क रखरखाव'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Area / Location
                        AppFieldLabel(
                          label: AppTranslations.pick(lang, en: 'Area / Location', mr: 'क्षेत्र / ठिकाण', hi: 'क्षेत्र / स्थान'),
                        ),
                        TextField(
                          controller: areaCtrl,
                          decoration: inputDec(
                            hint: AppTranslations.pick(lang, en: 'e.g. Shivaji Nagar', mr: 'उदा. शिवाजी नगर', hi: 'उदा. शिवाजी नगर'),
                          ),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Total Allocation (₹)', mr: 'एकूण तरतूद रक्कम (₹)', hi: 'कुल आवंटन राशि (₹)'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: allocCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: inputDec(hint: AppTranslations.formatDigits('0', lang), prefixText: '₹ '),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Initial Utilized (₹)', mr: 'सुरुवातीचा खर्च निधी (₹)', hi: 'प्रारंभिक व्यय राशि (₹)'),
                                  ),
                                  TextField(
                                    controller: utilCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: inputDec(hint: AppTranslations.formatDigits('0', lang), prefixText: '₹ '),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Submit Button (Scrolls with form)
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
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Please enter category head',
                                        mr: 'कृपया वर्गवारी / बजेट शीर्ष प्रविष्ट करा',
                                        hi: 'कृपया श्रेणी / बजट शीर्ष दर्ज करें',
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }
                              final alloc = double.tryParse(AppTranslations.normalizeAsciiDigits(allocCtrl.text.trim()));
                              if (alloc == null || alloc <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Please enter a valid total allocation amount',
                                        mr: 'कृपया वैध एकूण तरतूद रक्कम प्रविष्ट करा',
                                        hi: 'कृपया मान्य कुल आवंटन राशि दर्ज करें',
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }
                              final util = double.tryParse(AppTranslations.normalizeAsciiDigits(utilCtrl.text.trim())) ?? 0.0;

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
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Budget allocation added successfully!',
                                        mr: 'बजेट तरतूद यशस्वीरित्या जोडली गेली!',
                                        hi: 'बजट आवंटन सफलतापूर्वक जोड़ा गया!',
                                      ),
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
                                  AppTranslations.pick(lang, en: 'Save Allocation', mr: 'तरतूद जतन करा', hi: 'आवंटन सहेजें'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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

  void _showQuickUpdateModal(WardBudgetModel item) {
    final lang = ref.read(appLanguageProvider);
    final utilCtrl = TextEditingController(text: item.utilizedAmount.toInt().toString());
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
    final subtitleCat = DynamicTranslationService.getCachedTranslation(item.category, lang) ??
        AppTranslations.formatDigits(item.category, lang);

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
              AppModalHeader(
                icon: Icons.edit_note_rounded,
                title: AppTranslations.pick(lang, en: 'Update Expenditure', mr: 'खर्च अपडेट करा', hi: 'व्यय अपडेट करें'),
                subtitle: subtitleCat,
                onClose: () => Navigator.pop(sheetCtx),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          AppTranslatedText(
                            item.category,
                            targetLanguage: lang,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTranslations.formatDigits(
                              '${AppTranslations.pick(lang, en: 'Current Utilized Amount', mr: 'सध्याचा खर्च झालेला निधी', hi: 'वर्तमान व्यय राशि')}: ${numFormat.format(item.utilizedAmount)}',
                              lang,
                            ),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                          ),
                          Text(
                            AppTranslations.formatDigits(
                              '${AppTranslations.pick(lang, en: 'Total Sanctioned', mr: 'एकूण मंजूर', hi: 'कुल स्वीकृत')}: ${numFormat.format(item.totalAllocation)} | ${AppTranslations.pick(lang, en: 'Area', mr: 'क्षेत्र', hi: 'क्षेत्र')}: ${AppTranslations.getAreaName(item.area, lang)}',
                              lang,
                            ),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppFieldLabel(
                      label: AppTranslations.pick(lang, en: 'New Total Utilized Amount (₹)', mr: 'नवीन एकूण खर्च (₹)', hi: 'नई कुल व्यय राशि (₹)'),
                      isRequired: true,
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
                          final newUtil = double.tryParse(AppTranslations.normalizeAsciiDigits(utilCtrl.text.trim()));
                          if (newUtil == null || newUtil < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppTranslations.pick(lang, en: 'Please enter a valid amount', mr: 'कृपया वैध रक्कम प्रविष्ट करा', hi: 'कृपया मान्य राशि दर्ज करें')),
                              ),
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
                                content: Text(AppTranslations.pick(lang, en: 'Expenditure updated successfully!', mr: 'खर्च यशस्वीरित्या अपडेट केला!', hi: 'व्यय सफलतापूर्वक अपडेट किया गया!')),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        child: Text(
                          AppTranslations.pick(lang, en: 'Update', mr: 'अपडेट करा', hi: 'अपडेट करें'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(WardBudgetModel item) {
    final lang = ref.read(appLanguageProvider);
    final catTitle = DynamicTranslationService.getCachedTranslation(item.category, lang) ??
        AppTranslations.formatDigits(item.category, lang);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(lang, en: 'Delete Budget Head', mr: 'बजेट खाते हटवायचे का?', hi: 'बजट शीर्ष हटाएँ?'),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to delete "$catTitle"? This cannot be undone.',
            mr: 'तुम्हाला "$catTitle" हे बजेट खाते कायमचे हटवायचे आहे का? ही कृती पूर्ववत करता येणार नाही.',
            hi: 'क्या आप वाकई "$catTitle" को हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।',
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
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
                  SnackBar(
                    content: Text(AppTranslations.pick(lang, en: 'Budget head deleted', mr: 'बजेट खाते हटवले', hi: 'बजट शीर्ष हटाया गया')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
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
              tooltip: AppTranslations.pick(lang, en: 'Open Menu Drawer', mr: 'मेनू उघडा', hi: 'मेनू खोलें'),
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
                AppTranslations.getNavTitle('budget', lang),
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
                lang == 'mr'
                    ? 'प्रभाग निधी आणि अंदाजपत्रक'
                    : (lang == 'hi'
                        ? 'वार्ड निधि और बजट ट्रैकिंग'
                        : 'Ward funds & budget tracking'),
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            AppTranslations.t('budget.add_allocation', lang: lang),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _showAddModal,
        ),
        body: _isLoading
            ? const AppShimmerList(count: 6)
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
                                    title: AppTranslations.t('budget.allocated', lang: lang),
                                    amount: AppTranslations.formatDigits(numFormat.format(totalAllocated), lang),
                                    icon: Icons.account_balance_wallet_outlined,
                                    iconColor: const Color(0xFF0284C7),
                                    iconBgColor: const Color(0xFFEFF6FF),
                                    footerWidget: Row(
                                      children: [
                                        const Icon(Icons.trending_up, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppTranslations.formatDigits(
                                            lang == 'mr'
                                                ? 'आर्थिक वर्ष $_selectedYear'
                                                : (lang == 'hi' ? 'वित्तीय वर्ष $_selectedYear' : 'Financial Year $_selectedYear'),
                                            lang,
                                          ),
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
                                    title: AppTranslations.t('budget.utilized', lang: lang),
                                    amount: AppTranslations.formatDigits(numFormat.format(totalUtilized), lang),
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
                                          AppTranslations.formatDigits(
                                            lang == 'mr'
                                                ? '${utilizationPercentage.toStringAsFixed(1)}% वापरले'
                                                : (lang == 'hi' ? '${utilizationPercentage.toStringAsFixed(1)}% उपयोग हुआ' : '${utilizationPercentage.toStringAsFixed(1)}% utilized'),
                                            lang,
                                          ),
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
                                    title: AppTranslations.t('budget.remaining', lang: lang),
                                    amount: AppTranslations.formatDigits(numFormat.format(totalRemaining), lang),
                                    icon: Icons.savings_outlined,
                                    iconColor: const Color(0xFF16A34A),
                                    iconBgColor: const Color(0xFFF0FDF4),
                                    footerWidget: Text(
                                      lang == 'mr' ? 'पुढील प्रभाग विकास कामांसाठी उपलब्ध' : (lang == 'hi' ? 'आगे के वार्ड विकास कार्यों के लिए उपलब्ध' : 'Available for ward works'),
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
                                onChanged: (_) => setState(() => _displayedLimit = 20),
                                decoration: InputDecoration(
                                  hintText: AppTranslations.t('budget.search_placeholder', lang: lang),
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                                  suffixIcon: _searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() => _displayedLimit = 20);
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
                              child: AppDropdown<String>(
                                title: AppTranslations.t('budget.filter_area', lang: lang),
                                value: _areas.contains(_selectedArea) ? _selectedArea : 'All',
                                height: 48,
                                items: _areas.map((a) {
                                  if (a == 'All') {
                                    return DropdownMenuItem(
                                      value: a,
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'All Areas', mr: 'सर्व परिसर', hi: 'सभी क्षेत्र'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }
                                  return DropdownMenuItem(
                                    value: a,
                                    child: AppTranslatedText(
                                      a,
                                      targetLanguage: lang,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                            const SizedBox(width: 8),
                            // Financial Year Selector
                            AppDropdown<String>(
                              title: lang == 'mr' ? 'आर्थिक वर्ष निवडा' : (lang == 'hi' ? 'वित्तीय वर्ष चुनें' : 'Select Financial Year'),
                              value: _selectedYear,
                              height: 48,
                              isExpanded: false,
                              prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0284C7), size: 18),
                              items: _years.map((y) {
                                return DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    y == 'All'
                                        ? AppTranslations.pick(lang, en: 'All FY', mr: 'सर्व वर्षे', hi: 'सभी वर्ष')
                                        : AppTranslations.formatDigits(
                                            AppTranslations.pick(lang, en: 'FY $y', mr: 'आ.व. $y', hi: 'वि.व. $y'),
                                            lang,
                                          ),
                                    style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedYear = val;
                                    _displayedLimit = 20;
                                  });
                                  _loadData();
                                }
                              },
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
                            AppPdfButton.icon(
                              tooltip: lang == 'mr' ? 'अहवाल डाउनलोड करा' : (lang == 'hi' ? 'रिपोर्ट डाउनलोड करें' : 'Download Report'),
                              onPressed: () {
                                WardBudgetReportGenerator.generateAndPrintBudgetReport(
                                  budgets: displayed,
                                  year: _selectedYear,
                                  areaFilter: _selectedArea != 'All' ? _selectedArea : null,
                                  lang: lang,
                                );
                              },
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
                                lang == 'mr'
                                    ? 'कोणतेही बजेट खाते सापडले नाही'
                                    : (lang == 'hi' ? 'कोई बजट रिकॉर्ड नहीं मिला' : 'No Budget Records Found'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang == 'mr'
                                    ? 'कृपया शोध निकष बदला किंवा नवीन बजेट वाटप जोडा.'
                                    : (lang == 'hi'
                                        ? 'कृपया अपने फ़िल्टर समायोजित करें या नया आवंटन जोड़ें।'
                                        : 'Try adjusting your filters or add a new allocation.'),
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else ...[
                        if (_viewMode == 'grid')
                          _buildGridCardView(_visibleBudgets, lang, numFormat)
                        else
                          _buildTableView(_visibleBudgets, lang, numFormat),
                        AppLoadMoreFooter(
                          currentCount: _visibleBudgets.length,
                          totalCount: displayed.length,
                          pageSize: 20,
                          onLoadMore: () => setState(() => _displayedLimit += 20),
                          label: lang == 'mr' ? 'बजेट नोंदी' : (lang == 'hi' ? 'बजट प्रविष्टियां' : 'budgets'),
                          isMarathi: lang == 'mr',
                        ),
                      ],
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

  Widget _buildGridCardView(List<WardBudgetModel> items, String lang, NumberFormat numFormat) {
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
                        AppTranslations.formatDigits(item.financialYear, lang),
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
                          AppTranslatedText(item.area,
                            targetLanguage: lang,
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
                        AppTranslations.getStatus(item.status, lang),
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: item.statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category Title
                AppTranslatedText(item.category,
                  targetLanguage: lang,
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
                      _miniAmountPill(AppTranslations.t('budget.allocated', lang: lang), AppTranslations.formatDigits(numFormat.format(item.totalAllocation), lang), const Color(0xFF0F172A)),
                      _miniAmountPill(AppTranslations.t('budget.utilized', lang: lang), AppTranslations.formatDigits(numFormat.format(item.utilizedAmount), lang), const Color(0xFF0284C7)),
                      _miniAmountPill(AppTranslations.t('budget.remaining', lang: lang), AppTranslations.formatDigits(numFormat.format(item.remainingAmount), lang), const Color(0xFF16A34A)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.formatDigits(
                        '${percent.toStringAsFixed(0)}% ${lang == 'mr' ? 'वापरले' : (lang == 'hi' ? 'उपयोग' : 'utilized')}',
                        lang,
                      ),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.progressColor),
                    ),
                    Text(
                      AppTranslations.formatDigits(
                        '${AppTranslations.t('budget.remaining', lang: lang)}: ${numFormat.format(item.remainingAmount)}',
                        lang,
                      ),
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
                        lang == 'mr' ? 'खर्च अपडेट' : (lang == 'hi' ? 'व्यय अपडेट' : 'Update Utilized'),
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
                                lang == 'mr' ? 'तपशील' : (lang == 'hi' ? 'विवरण' : 'Details'),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF475569)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                          tooltip: AppTranslations.getCommon('delete', lang),
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

  Widget _buildTableView(List<WardBudgetModel> items, String lang, NumberFormat numFormat) {
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
              DataColumn(label: Text(AppTranslations.getReportColumn('#', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.getReportColumn('category', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.getReportColumn('area', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.t('budget.allocated', lang: lang), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.t('budget.utilized', lang: lang), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(lang == 'mr' ? 'प्रगती' : (lang == 'hi' ? 'प्रगति' : 'Progress'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.getReportColumn('actions', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              final percent = item.utilizationPercentage;

              return DataRow(
                cells: [
                  DataCell(Text(AppTranslations.formatDigits('$idx', lang))),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppTranslatedText(item.category,
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(AppTranslations.formatDigits(item.financialYear, lang), style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                  DataCell(AppTranslatedText(item.area, targetLanguage: lang, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(AppTranslations.formatDigits(numFormat.format(item.totalAllocation), lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                  DataCell(Text(AppTranslations.formatDigits(numFormat.format(item.utilizedAmount), lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
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
                            AppTranslations.formatDigits('${percent.toStringAsFixed(0)}%', lang),
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
                          tooltip: AppTranslations.pick(lang, en: 'Update Utilized', mr: 'खर्च अपडेट करा', hi: 'व्यय अपडेट करें'),
                          onPressed: () => _showQuickUpdateModal(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF475569)),
                          tooltip: AppTranslations.pick(lang, en: 'View Details', mr: 'तपशील पहा', hi: 'विवरण देखें'),
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
