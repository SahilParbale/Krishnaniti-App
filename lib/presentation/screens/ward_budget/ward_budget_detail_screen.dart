import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ward_budget_model.dart';
import '../../../data/repositories/ward_budget_repository.dart';
import '../../providers/language_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';

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
    final lang = ref.read(appLanguageProvider);
    final newAmount = double.tryParse(AppTranslations.normalizeAsciiDigits(_utilizeCtrl.text.trim()));
    if (newAmount == null || newAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.pick(lang, en: 'Please enter a valid amount', mr: 'कृपया वैध रक्कम प्रविष्ट करा', hi: 'कृपया मान्य राशि दर्ज करें')),
          backgroundColor: const Color(0xFFDC2626),
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
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Budget utilization updated successfully!',
              mr: 'बजेट खर्च यशस्वीरित्या अद्यतनित केला!',
              hi: 'बजट व्यय सफलतापूर्वक अपडेट किया गया!',
            ),
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    final lang = ref.read(appLanguageProvider);
    final catTitle = DynamicTranslationService.getCachedTranslation(_currentBudget.category, lang) ??
        AppTranslations.formatDigits(_currentBudget.category, lang);
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
            en: 'Are you sure you want to remove "$catTitle" from the Ward Budget? This action cannot be undone.',
            mr: 'तुम्हाला "$catTitle" हे बजेट खाते प्रभाग बजेटमधून काढायचे आहे का? ही कृती पूर्ववत करता येणार नाही.',
            hi: 'क्या आप वाकई "$catTitle" को वार्ड बजट से हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।',
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
              setState(() => _isDeleting = true);
              final repo = ref.read(wardBudgetRepoProvider);
              await repo.deleteBudget(_currentBudget.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Budget allocation deleted successfully',
                        mr: 'बजेट तरतूद यशस्वीरित्या हटवली',
                        hi: 'बजट आवंटन सफलतापूर्वक हटाया गया',
                      ),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ')),
          ),
        ],
      ),
    );
  }

  void _showEditModal() {
    final lang = ref.read(appLanguageProvider);
    final catCtrl = TextEditingController(text: _currentBudget.category);
    final areaCtrl = TextEditingController(text: _currentBudget.area);
    final allocCtrl = TextEditingController(text: _currentBudget.totalAllocation.toInt().toString());
    final utilCtrl = TextEditingController(text: _currentBudget.utilizedAmount.toInt().toString());
    String fy = _currentBudget.financialYear;
    String status = _currentBudget.status;

    final years = ['2024-2025', '2023-2024', '2022-2023'];
    final statusOptions = ['Active', 'Closed'];

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
                children: [
                  AppModalHeader(
                    icon: Icons.edit_note_rounded,
                    title: AppTranslations.pick(lang, en: 'Edit Budget Allocation', mr: 'बजेट तरतूद संपादित करा', hi: 'बजट आवंटन संपादित करें'),
                    subtitle: AppTranslations.pick(lang, en: 'Update ward budget allocation details', mr: 'बजेट तरतुदीचे तपशील अद्यतनित करा', hi: 'वार्ड बजट आवंटन विवरण अपडेट करें'),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 16,
                        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      children: [
                        // Side-by-side: Financial Year & Status
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppDropdownFormField<String>(
                                    label: AppTranslations.pick(lang, en: 'Financial Year', mr: 'आर्थिक वर्ष', hi: 'वित्तीय वर्ष'),
                                    isRequired: true,
                                    value: fy,
                                    items: years.map((y) => DropdownMenuItem(value: y, child: Text(AppTranslations.formatDigits(y, lang)))).toList(),
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
                                  AppDropdownFormField<String>(
                                    label: AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                                    isRequired: true,
                                    value: status,
                                    items: statusOptions
                                        .map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(AppTranslations.getStatus(s, lang)),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Category Head', mr: 'वर्गवारी / बजेट शीर्ष', hi: 'श्रेणी / बजट शीर्ष'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: catCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.pick(lang, en: 'e.g. Road Maintenance', mr: 'उदा. रस्ते देखभाल', hi: 'उदा. सड़क रखरखाव'),
                                    ),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Area / Location', mr: 'क्षेत्र / ठिकाण', hi: 'क्षेत्र / स्थान'),
                                  ),
                                  TextField(
                                    controller: areaCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.pick(lang, en: 'e.g. Shivaji Nagar', mr: 'उदा. शिवाजी नगर', hi: 'उदा. शिवाजी नगर'),
                                    ),
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
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Total Allocation (₹)', mr: 'एकूण तरतूद रक्कम (₹)', hi: 'कुल आवंटन राशि (₹)'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: allocCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: appInputDecoration(hint: AppTranslations.formatDigits('0', lang), prefixText: '₹ '),
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
                                    label: AppTranslations.pick(lang, en: 'Utilized Amount (₹)', mr: 'खर्च झालेला निधी (₹)', hi: 'व्यय राशि (₹)'),
                                  ),
                                  TextField(
                                    controller: utilCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: appInputDecoration(hint: AppTranslations.formatDigits('0', lang), prefixText: '₹ '),
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
                                  SnackBar(
                                    content: Text(AppTranslations.pick(lang, en: 'Category head is required', mr: 'कृपया वर्गवारी / बजेट शीर्ष प्रविष्ट करा', hi: 'श्रेणी / बजट शीर्ष आवश्यक है')),
                                  ),
                                );
                                return;
                              }

                              final totalAlloc = double.tryParse(AppTranslations.normalizeAsciiDigits(allocCtrl.text.trim())) ?? _currentBudget.totalAllocation;
                              final utilized = double.tryParse(AppTranslations.normalizeAsciiDigits(utilCtrl.text.trim())) ?? _currentBudget.utilizedAmount;

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
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Budget allocation updated successfully',
                                        mr: 'बजेट तरतूद यशस्वीरित्या अद्यतनित केली!',
                                        hi: 'बजट आवंटन सफलतापूर्वक अपडेट किया गया!',
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
                                  AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'परिवर्तन सहेजें'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
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
            tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'पीछे'),
            onPressed: () => Navigator.pop(context, true),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.pick(lang, en: 'Budget Head Details', mr: 'अंदाजपत्रक तपशील', hi: 'बजट विवरण'),
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
                AppTranslations.formatDigits('${budget.financialYear} • ${AppTranslations.getAreaName(budget.area, lang)}', lang),
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
              tooltip: AppTranslations.pick(lang, en: 'Edit Budget', mr: 'बजेट संपादित करा', hi: 'बजट संपादित करें'),
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: AppTranslations.pick(lang, en: 'Delete Budget', mr: 'बजेट हटवा', hi: 'बजट हटाएँ'),
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
                                  AppTranslations.formatDigits(budget.financialYear, lang),
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
                                  AppTranslations.getStatus(budget.status, lang),
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
                          AppTranslatedText(
                            budget.category,
                            targetLanguage: lang,
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
                              AppTranslatedText(
                                budget.area,
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Divider(height: 28),

                          // 3 Financial KPIs
                          Row(
                            children: [
                              _kpiPill(
                                label: AppTranslations.t('budget.allocated', lang: lang),
                                amount: AppTranslations.formatDigits(numFormat.format(budget.totalAllocation), lang),
                                color: const Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 8),
                              _kpiPill(
                                label: AppTranslations.t('budget.utilized', lang: lang),
                                amount: AppTranslations.formatDigits(numFormat.format(budget.utilizedAmount), lang),
                                color: const Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 8),
                              _kpiPill(
                                label: AppTranslations.t('budget.remaining', lang: lang),
                                amount: AppTranslations.formatDigits(numFormat.format(budget.remainingAmount), lang),
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
                                AppTranslations.pick(lang, en: 'Fund Utilization Progress', mr: 'निधी वापर प्रगती', hi: 'निधि उपयोग प्रगति'),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                              Text(
                                AppTranslations.formatDigits('${percent.toStringAsFixed(1)}%', lang),
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
                                AppTranslations.pick(lang, en: 'Update Utilization', mr: 'खर्च अद्ययावत करा', hi: 'व्यय अपडेट करें'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Enter updated cumulative expenditure for this budget head:',
                              mr: 'नवीन झालेला एकूण खर्च प्रविष्ट करा:',
                              hi: 'इस बजट शीर्ष के लिए अद्यतन कुल व्यय दर्ज करें:',
                            ),
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
                                    hintText: AppTranslations.pick(lang, en: 'Enter amount', mr: 'रक्कम प्रविष्ट करा', hi: 'राशि दर्ज करें'),
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
                                child: Text(
                                  AppTranslations.pick(lang, en: 'Update', mr: 'अपडेट करा', hi: 'अपडेट करें'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
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
                            AppTranslations.pick(lang, en: 'Administrative Context', mr: 'प्रशासकीय माहिती', hi: 'प्रशासनिक विवरण'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Divider(height: 20),
                          _infoRow(
                            icon: Icons.account_balance_rounded,
                            label: AppTranslations.pick(lang, en: 'Budget Head', mr: 'बजेट खाते', hi: 'बजट शीर्ष'),
                            value: budget.category,
                            lang: lang,
                            translate: true,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.calendar_today_rounded,
                            label: AppTranslations.pick(lang, en: 'Financial Year', mr: 'आर्थिक वर्ष', hi: 'वित्तीय वर्ष'),
                            value: AppTranslations.formatDigits(budget.financialYear, lang),
                            lang: lang,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.location_on_outlined,
                            label: AppTranslations.pick(lang, en: 'Prabhag Area', mr: 'परिसर / प्रभाग', hi: 'वार्ड / क्षेत्र'),
                            value: budget.area,
                            lang: lang,
                            translate: true,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: AppTranslations.pick(lang, en: 'Account Status', mr: 'सध्याची स्थिती', hi: 'खाता स्थिति'),
                            value: AppTranslations.getStatus(budget.status, lang),
                            lang: lang,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.access_time_rounded,
                            label: AppTranslations.pick(lang, en: 'Created Date', mr: 'नोंदणी तारीख', hi: 'निर्मित तिथि'),
                            value: _formatDate(budget.createdAt, lang),
                            lang: lang,
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

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required String lang,
    bool translate = false,
  }) {
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
          child: translate
              ? AppTranslatedText(
                  value,
                  targetLanguage: lang,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                )
              : Text(
                  value,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }

  static String _formatDate(String dateStr, String lang) {
    try {
      final dt = DateTime.parse(dateStr);
      return AppTranslations.formatDate(dt, lang, pattern: 'dd MMM yyyy');
    } catch (_) {
      return AppTranslations.formatDigits(dateStr, lang);
    }
  }
}

