import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/ward_provision_model.dart';
import '../../../../data/repositories/ward_provisions_repository.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/ward_provisions/ward_provision_report_generator.dart';
import '../../../widgets/app_date_picker.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';
import '../../common/desktop_modal_dialog.dart';

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

  String _formatCurrency(double amount, String lang) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return AppTranslations.formatDigits(format.format(amount), lang);
  }

  String _formatDate(String raw, String lang) {
    if (raw.isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      return AppTranslations.formatDate(dt, lang, pattern: 'dd/MM/yyyy');
    }
    return AppTranslations.formatDigits(raw, lang);
  }

  String _localizedStatus(String status, String lang) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTranslations.pick(lang, en: 'Approved', mr: 'मंजूर', hi: 'स्वीकृत');
      case 'partially approved':
      case 'partially_approved':
      case 'partial':
        return AppTranslations.pick(lang, en: 'Partially Approved', mr: 'अंशतः मंजूर', hi: 'आंशिक स्वीकृत');
      case 'rejected':
        return AppTranslations.pick(lang, en: 'Rejected', mr: 'नाकारले', hi: 'अस्वीकृत');
      case 'pending':
      default:
        return AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित');
    }
  }

  void _showAddModal() {
    final titleController = TextEditingController();
    final reqAmountController = TextEditingController();
    final catController = TextEditingController();
    final areaController = TextEditingController(text: 'Ward 12');
    final refController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final lang = modalRef.watch(desktopLanguageProvider);
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              final dateStr =
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
              return DesktopModalDialog(
                title: AppTranslations.pick(
                  lang,
                  en: 'Add Provision Request',
                  mr: 'तरतूद मागणी जोडा',
                  hi: 'प्रावधान मांग जोड़ें',
                ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Municipal provisions, ward works and sanctioned projects',
                  mr: 'महापालिका तरतुदी, प्रभाग कामे आणि मंजूर प्रकल्प',
                  hi: 'नगर निगम प्रावधान, वार्ड कार्य और स्वीकृत परियोजनाएं',
                ),
                icon: Icons.handshake_outlined,
                width: 560,
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
                      if (titleController.text.trim().isEmpty) return;
                      final newProvision = WardProvisionModel(
                        id: 'prov-${DateTime.now().millisecondsSinceEpoch}',
                        title: titleController.text.trim(),
                        requestedAmount: double.tryParse(
                              AppTranslations.normalizeAsciiDigits(reqAmountController.text.trim()),
                            ) ??
                            0,
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
                    Text(
                      AppTranslations.pick(lang, en: 'Project Title *', mr: 'प्रकल्पाचे शीर्षक *', hi: 'परियोजना शीर्षक *'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: desktopInputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. Ward road concretization...',
                          mr: 'उदा. प्रभाग रस्ते काँक्रीटीकरण...',
                          hi: 'उदा. वार्ड सड़क कंक्रीटीकरण...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Requested Amount & Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Requested Amount (₹) *',
                                  mr: 'मागितलेली रक्कम (₹) *',
                                  hi: 'मांगी गई राशि (₹) *',
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: reqAmountController,
                                keyboardType: TextInputType.number,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.formatDigits('500000', lang),
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
                                AppTranslations.pick(lang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showThemedDatePicker(
                                    context: ctx,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.all(color: AppColors.slate200),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppTranslations.formatDate(selectedDate, lang, pattern: 'dd/MM/yyyy'),
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                      const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
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
                              Text(
                                AppTranslations.pick(lang, en: 'Category *', mr: 'वर्गवारी *', hi: 'श्रेणी *'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: catController,
                                decoration: desktopInputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Roads, Water Supply, Drainage',
                                    mr: 'उदा. रस्ते, पाणी पुरवठा, ड्रेनेज',
                                    hi: 'उदा. सड़क, जल आपूर्ति, ड्रेनेज',
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

                    // Letter Reference
                    Text(
                      AppTranslations.pick(lang, en: 'Letter Reference', mr: 'पत्र संदर्भ क्र.', hi: 'पत्र संदर्भ संख्या'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: refController,
                      decoration: desktopInputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. Letter Ref PMC/2024/782',
                          mr: 'उदा. पत्र क्र. PMC/२०२४/७८२',
                          hi: 'उदा. पत्र सं. PMC/२०२४/७८२',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUpdateModal(WardProvisionModel item) {
    final sancAmountController = TextEditingController(
      text: item.sanctionedAmount != null ? item.sanctionedAmount!.toInt().toString() : item.requestedAmount.toInt().toString(),
    );
    String selectedStatus = item.status == 'Pending' ? 'Approved' : item.status;
    final String sancDate = item.sanctionedDate ?? DateTime.now().toIso8601String().split('T')[0];

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final lang = modalRef.watch(desktopLanguageProvider);
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return DesktopModalDialog(
                title: AppTranslations.pick(
                  lang,
                  en: 'Update Sanction Details',
                  mr: 'मंजुरी तपशील अद्ययावत करा',
                  hi: 'स्वीकृति विवरण अपडेट करें',
                ),
                subtitle: item.title,
                icon: Icons.edit_note_rounded,
                width: 500,
                onClose: () => Navigator.pop(ctx),
                actions: [
                  DesktopModalDialog.cancelButton(ctx),
                  const SizedBox(width: 12),
                  DesktopModalDialog.primaryButton(
                    text: AppTranslations.pick(lang, en: 'Update', mr: 'अद्ययावत करा', hi: 'अपडेट करें'),
                    onPressed: () async {
                      final updated = item.copyWith(
                        sanctionedAmount: double.tryParse(
                              AppTranslations.normalizeAsciiDigits(sancAmountController.text.trim()),
                            ) ??
                            item.requestedAmount,
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
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Sanctioned Amount (₹) *',
                        mr: 'मंजूर रक्कम (₹) *',
                        hi: 'स्वीकृत राशि (₹) *',
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: sancAmountController,
                      keyboardType: TextInputType.number,
                      decoration: desktopInputDecoration(
                        hintText: AppTranslations.pick(lang, en: 'Enter amount', mr: 'रक्कम प्रविष्ट करा', hi: 'राशि दर्ज करें'),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14, right: 6),
                          child: Text('₹ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status
                    Text(
                      AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: selectedStatus,
                      height: 44,
                      backgroundColor: const Color(0xFFF8FAFC),
                      borderColor: const Color(0xFFE2E8F0),
                      items: [
                        DropdownMenuItem(value: 'Approved', child: Text(_localizedStatus('Approved', lang))),
                        DropdownMenuItem(value: 'Partially Approved', child: Text(_localizedStatus('Partially Approved', lang))),
                        DropdownMenuItem(value: 'Rejected', child: Text(_localizedStatus('Rejected', lang))),
                        DropdownMenuItem(value: 'Pending', child: Text(_localizedStatus('Pending', lang))),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedStatus = val);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(WardProvisionModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final lang = modalRef.watch(desktopLanguageProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              AppTranslations.pick(lang, en: 'Delete Provision', mr: 'तरतूद हटवा', hi: 'प्रावधान हटाएं'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Are you sure you want to delete this provision?',
                    mr: 'तुम्हाला ही तरतूद नक्की हटवायची आहे का?',
                    hi: 'क्या आप वाकई इस प्रावधान को हटाना चाहते हैं?',
                  ),
                ),
                const SizedBox(height: 6),
                AppTranslatedText(
                  '"${item.title}"',
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
                  final repo = ref.read(wardProvisionsRepoProvider);
                  await repo.deleteProvision(item.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadProvisions();
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
    final successRate = _totalRequested > 0 ? (_totalSanctioned / _totalRequested) * 100 : 0.0;
    final demandsCount = AppTranslations.formatDigits(_provisions.length, lang);
    final rateStr = AppTranslations.formatDigits(successRate.toStringAsFixed(1), lang);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(lang),
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
                          Expanded(
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Total Demanded Amount',
                                mr: 'एकूण मागितलेली रक्कम',
                                hi: 'कुल मांगी गई राशि',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ),
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
                        _formatCurrency(_totalRequested, lang),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: '$demandsCount budget demands registered',
                                mr: '$demandsCount अंदाजपत्रक मागण्या नोंदवल्या',
                                hi: '$demandsCount बजट मांगें दर्ज',
                              ),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
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
                          Expanded(
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Total Sanctioned Amount',
                                mr: 'एकूण मंजूर रक्कम',
                                hi: 'कुल स्वीकृत राशि',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ),
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
                        _formatCurrency(_totalSanctioned, lang),
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
                        AppTranslations.pick(
                          lang,
                          en: '$rateStr% Approval Rate',
                          mr: '$rateStr% मंजुरी दर',
                          hi: '$rateStr% स्वीकृति दर',
                        ),
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
          _buildTableCard(lang),

          if (!_loading && _provisions.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: _visibleProvisions.length,
              totalCount: _provisions.length,
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
              Row(
                children: [
                  const Icon(Icons.currency_rupee_rounded, size: 26, color: Color(0xFF0369A1)),
                  const SizedBox(width: 10),
                  Text(
                    AppTranslations.getNavTitle('provisions', lang),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Ward budget demands, approvals and sanction tracking',
                  mr: 'प्रभाग निधी मागण्या, मंजुरी आणि पाठपुरावा',
                  hi: 'वार्ड बजट मांग, स्वीकृति और ट्रैकिंग',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Year select & action buttons
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white), // Plus w-4 h-4
                  const SizedBox(width: 8), // gap-2
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Add Provision Request',
                      mr: 'तरतूद मागणी जोडा',
                      hi: 'प्रावधान मांग जोड़ें',
                    ),
                    style: const TextStyle(
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

  Widget _buildTableCard(String lang) {
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
                  children: [
                    const Icon(Icons.folder_open_outlined, size: 48, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'No provision records found',
                        mr: 'कोणत्याही तरतुदी आढळल्या नाहीत',
                        hi: 'कोई प्रावधान रिकॉर्ड नहीं मिला',
                      ),
                      style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
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
                  columns: [
                    DataColumn(label: Text(AppTranslations.pick(lang, en: 'Project Title / Ref', mr: 'प्रकल्प शीर्षक / संदर्भ', hi: 'परियोजना शीर्षक / संदर्भ'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text(AppTranslations.pick(lang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text(AppTranslations.pick(lang, en: 'Sanctioned / Demanded', mr: 'मंजूर / मागितलेले', hi: 'स्वीकृत / मांगी गई'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text(AppTranslations.pick(lang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text(AppTranslations.pick(lang, en: 'Actions', mr: 'कृती', hi: 'कार्रवाई'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
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
                              AppTranslatedText(
                                item.title,
                                targetLanguage: lang,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: AppTranslatedText(
                                      lang == 'en' ? item.category.toUpperCase() : item.category,
                                      targetLanguage: lang,
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  if (item.letterReference.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${AppTranslations.pick(lang, en: 'Ref', mr: 'संदर्भ', hi: 'संदर्भ')}: ${AppTranslations.formatDigits(item.letterReference, lang)}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          AppTranslatedText(
                            AppTranslations.getAreaName(item.area, lang),
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_formatCurrency(displayAmount, lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              if (item.sanctionedAmount != null && item.sanctionedAmount! < item.requestedAmount)
                                Text(
                                  '${AppTranslations.pick(lang, en: 'Demanded', mr: 'मागितलेले', hi: 'मांगी गई')}: ${_formatCurrency(item.requestedAmount, lang)}',
                                  style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Color(0xFF94A3B8)),
                                ),
                            ],
                          ),
                        ),
                        DataCell(_buildStatusBadge(item.status, lang)),
                        DataCell(Text(_formatDate(item.sanctionedDate ?? item.requestedDate, lang), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                tooltip: AppTranslations.pick(lang, en: 'Update Sanction', mr: 'मंजुरी अद्ययावत करा', hi: 'स्वीकृति अपडेट करें'),
                                onPressed: () => _showUpdateModal(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                tooltip: AppTranslations.getCommon('delete', lang),
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

  Widget _buildStatusBadge(String status, String lang) {
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
          Text(_localizedStatus(status, lang), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
        ],
      ),
    );
  }
}
