import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/improvement_model.dart';
import '../../../data/repositories/improvements_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';

class ImprovementDetailScreen extends ConsumerStatefulWidget {
  final ImprovementModel improvement;

  const ImprovementDetailScreen({super.key, required this.improvement});

  @override
  ConsumerState<ImprovementDetailScreen> createState() => _ImprovementDetailScreenState();
}

class _ImprovementDetailScreenState extends ConsumerState<ImprovementDetailScreen> {
  late ImprovementModel _currentImp;
  bool _isDeleting = false;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _currentImp = widget.improvement;
  }

  Future<void> _handleVote() async {
    final lang = ref.read(appLanguageProvider);
    setState(() => _isVoting = true);
    final repo = ref.read(improvementsRepoProvider);
    final newVotes = await repo.voteImprovement(_currentImp.id);
    if (mounted) {
      setState(() {
        _currentImp = _currentImp.copyWith(votes: newVotes);
        _isVoting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Your vote has been counted successfully!',
              mr: 'तुमचे मत यशस्वीरित्या नोंदवले गेले!',
              hi: 'आपका मत सफलतापूर्वक दर्ज किया गया!',
            ),
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleQuickStatusChange(String newStatus) async {
    if (_currentImp.status == newStatus) return;
    final lang = ref.read(appLanguageProvider);
    final updated = _currentImp.copyWith(status: newStatus);
    final repo = ref.read(improvementsRepoProvider);
    await repo.updateImprovement(updated);
    if (mounted) {
      setState(() => _currentImp = updated);
      final locSt = AppTranslations.getStatus(newStatus, lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Status updated to $locSt',
              mr: 'स्थिती अद्यतनित केली: $locSt',
              hi: 'स्थिति अपडेट की गई: $locSt',
            ),
          ),
          backgroundColor: const Color(0xFF0284C7),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    final lang = ref.read(appLanguageProvider);
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
                AppTranslations.pick(lang, en: 'Delete Proposal', mr: 'सुधारणा प्रस्ताव हटवायचा का?', hi: 'प्रस्ताव हटाएँ?'),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to delete this civic improvement proposal? This action cannot be undone.',
            mr: 'तुम्हाला हा नागरी सुधारणा प्रस्ताव कायमचा हटवायचा आहे का? ही कृती पूर्ववत करता येणार नाही.',
            hi: 'क्या आप वाकई इस नागरिक सुधार प्रस्ताव को हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।',
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
              final repo = ref.read(improvementsRepoProvider);
              await repo.deleteImprovement(_currentImp.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Proposal deleted successfully',
                        mr: 'प्रस्ताव यशस्वीरित्या हटवला',
                        hi: 'प्रस्ताव सफलतापूर्वक हटाया गया',
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
    final titleCtrl = TextEditingController(text: _currentImp.title);
    final descCtrl = TextEditingController(text: _currentImp.description);
    final locCtrl = TextEditingController(text: _currentImp.location);
    final areaCtrl = TextEditingController(text: _currentImp.area);
    final benCtrl = TextEditingController(text: _currentImp.peopleBenefited?.toString() ?? '');
    final budgetCtrl = TextEditingController(
        text: _currentImp.estimatedBudget != null ? _currentImp.estimatedBudget!.toInt().toString() : '');
    final dateCtrl = TextEditingController(text: _currentImp.completionDate ?? '');
    String status = _currentImp.status;

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
                    title: AppTranslations.pick(lang, en: 'Edit Civic Improvement', mr: 'सुधारणा प्रस्ताव संपादन', hi: 'नागरिक सुधार संपादित करें'),
                    subtitle: AppTranslations.pick(lang, en: 'Update civic improvement proposal details', mr: 'प्रस्तावाचे तपशील अद्यतनित करा', hi: 'सुधार प्रस्ताव विवरण अपडेट करें'),
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
                        // Title & Status side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Proposal Title', mr: 'प्रस्तावित कामाचे नाव', hi: 'प्रस्तावित कार्य नाम'),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: titleCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.pick(lang, en: 'e.g. Pedestrian skywalk...', mr: 'उदा. पादचारी पूल, ओपन जिम...', hi: 'उदा. पैदल पुल, ओपन जिम...'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppDropdownFormField<String>(
                                    label: AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                                    value: status,
                                    items: ['Pending', 'Planned', 'In Progress', 'Complete']
                                        .map((s) => DropdownMenuItem(value: s, child: Text(AppTranslations.getStatus(s, lang))))
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

                        // Location & Area side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Location', mr: 'ठिकाण', hi: 'स्थान')),
                                  TextField(
                                    controller: locCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.pick(lang, en: 'e.g. Main Chowk...', mr: 'उदा. मुख्य चौक...', hi: 'उदा. मुख्य चौक...'),
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
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Area / Locality', mr: 'परिसर / प्रभाग', hi: 'क्षेत्र / वार्ड')),
                                  TextField(
                                    controller: areaCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. Sector 5...', mr: 'उदा. सेक्टर 5...', hi: 'उदा. सेक्टर 5...'),
                                        lang,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Target Date & Benefited side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Target Date', mr: 'अपेक्षित दिनांक', hi: 'लक्ष्य तिथि')),
                                  TextField(
                                    controller: dateCtrl,
                                    decoration: appInputDecoration(hint: 'YYYY-MM-DD'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Estimated Benefited', mr: 'अंदाजे लाभार्थी', hi: 'अनुमानित लाभार्थी')),
                                  TextField(
                                    controller: benCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: appInputDecoration(hint: AppTranslations.formatDigits('10000', lang)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Estimated Budget
                        AppFieldLabel(label: AppTranslations.pick(lang, en: 'Estimated Budget (₹)', mr: 'अंदाजे बजेट (₹)', hi: 'अनुमानित बजट (₹)')),
                        TextField(
                          controller: budgetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: appInputDecoration(prefixText: '₹ ', hint: AppTranslations.formatDigits('2500000', lang)),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        AppFieldLabel(label: AppTranslations.pick(lang, en: 'Detailed Scope / Description', mr: 'तपशीलवार माहिती व स्वरूप', hi: 'विस्तृत विवरण')),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: appInputDecoration(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Describe purpose and scope...',
                              mr: 'सुधारणा कामाचा उद्देश व स्वरूप...',
                              hi: 'सुधार कार्य का उद्देश्य और विवरण...',
                            ),
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
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final updated = _currentImp.copyWith(
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                location: locCtrl.text.trim(),
                                area: areaCtrl.text.trim(),
                                status: status,
                                completionDate: dateCtrl.text.trim().isNotEmpty
                                    ? AppTranslations.normalizeAsciiDigits(dateCtrl.text.trim())
                                    : null,
                                peopleBenefited: int.tryParse(AppTranslations.normalizeAsciiDigits(benCtrl.text.trim())),
                                estimatedBudget: double.tryParse(AppTranslations.normalizeAsciiDigits(budgetCtrl.text.trim())),
                              );

                              final repo = ref.read(improvementsRepoProvider);
                              await repo.updateImprovement(updated);
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (mounted) {
                                setState(() => _currentImp = updated);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Proposal updated successfully',
                                        mr: 'प्रस्ताव यशस्वीरित्या अद्यतनित केला!',
                                        hi: 'प्रस्ताव सफलतापूर्वक अपडेट किया गया!',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'परिवर्तन सहेजें'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  String _formatDateStr(String raw, String lang) {
    final dt = DateTime.tryParse(raw.trim());
    if (dt != null) {
      return AppTranslations.formatDate(dt, lang, pattern: 'dd MMM yyyy');
    }
    return AppTranslations.formatDigits(raw, lang);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final imp = _currentImp;
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

    final statusTabs = [
      {'key': 'Pending', 'label': AppTranslations.getStatus('Pending', lang)},
      {'key': 'Planned', 'label': AppTranslations.getStatus('Planned', lang)},
      {'key': 'In Progress', 'label': AppTranslations.getStatus('In Progress', lang)},
      {'key': 'Complete', 'label': AppTranslations.getStatus('Complete', lang)},
    ];

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
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.pick(lang, en: 'Improvement Details', mr: 'सुधारणा तपशील', hi: 'सुधार विवरण'),
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                AppTranslations.formatDigits(
                  imp.area.isNotEmpty
                      ? '${AppTranslations.getAreaName(imp.area, lang)} • ${AppTranslations.pick(lang, en: "Ward No. 12", mr: "प्रभाग क्र. 12", hi: "वार्ड नं. 12")}'
                      : AppTranslations.pick(lang, en: 'Ward No. 12', mr: 'प्रभाग क्र. 12', hi: 'वार्ड नं. 12'),
                  lang,
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: AppTranslations.pick(lang, en: 'Edit Proposal', mr: 'प्रस्ताव संपादित करा', hi: 'प्रस्ताव संपादित करें'),
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: AppTranslations.pick(lang, en: 'Delete Proposal', mr: 'प्रस्ताव हटवा', hi: 'प्रस्ताव हटाएँ'),
              onPressed: _showDeleteConfirmation,
            ),
          ],
        ),
        body: _isDeleting
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Status Tabs
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            AppTranslations.pick(lang, en: 'Mark as:', mr: 'स्थिती बदला:', hi: 'स्थिति बदलें:'),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: statusTabs.map((tab) {
                                  final isCurrent = imp.status == tab['key'];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      selected: isCurrent,
                                      selectedColor: const Color(0xFF0284C7),
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      labelStyle: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                        color: isCurrent ? Colors.white : const Color(0xFF475569),
                                      ),
                                      label: Text(tab['label']!),
                                      onSelected: (_) => _handleQuickStatusChange(tab['key']!),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Main Proposal Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: imp.statusBorderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: AppTranslatedText(
                                  imp.area,
                                  targetLanguage: lang,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: imp.statusBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  AppTranslations.getStatus(imp.status, lang),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: imp.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AppTranslatedText(
                            imp.title,
                            targetLanguage: lang,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppTranslatedText(
                            imp.description,
                            targetLanguage: lang,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF334155),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),

                          // Metadata Metrics Grid
                          Row(
                            children: [
                              Expanded(
                                child: _metaInfoTile(
                                  icon: Icons.place_outlined,
                                  iconColor: Colors.red.shade600,
                                  label: AppTranslations.pick(lang, en: 'Location', mr: 'ठिकाण', hi: 'स्थान'),
                                  value: imp.location,
                                  lang: lang,
                                  translateValue: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _metaInfoTile(
                                  icon: Icons.calendar_today_outlined,
                                  iconColor: const Color(0xFF0284C7),
                                  label: AppTranslations.pick(lang, en: 'Target Date', mr: 'अपेक्षित तारीख', hi: 'लक्ष्य तिथि'),
                                  value: _formatDateStr(imp.completionDate ?? imp.createdAt, lang),
                                  lang: lang,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _metaInfoTile(
                                  icon: Icons.people_alt_outlined,
                                  iconColor: Colors.purple.shade600,
                                  label: AppTranslations.pick(lang, en: 'Estimated Beneficiaries', mr: 'अपेक्षित लाभार्थी', hi: 'अनुमानित लाभार्थी'),
                                  value: imp.peopleBenefited != null
                                      ? AppTranslations.formatDigits(
                                          '${NumberFormat.decimalPattern().format(imp.peopleBenefited)} ${AppTranslations.pick(lang, en: 'Citizens', mr: 'नागरिक', hi: 'नागरिक')}',
                                          lang,
                                        )
                                      : AppTranslations.formatDigits(
                                          AppTranslations.pick(lang, en: 'Ward 12 Residents', mr: 'प्रभाग 12 रहिवासी', hi: 'वार्ड 12 निवासी'),
                                          lang,
                                        ),
                                  lang: lang,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _metaInfoTile(
                                  icon: Icons.currency_rupee_rounded,
                                  iconColor: const Color(0xFF16A34A),
                                  label: AppTranslations.pick(lang, en: 'Est. Budget', mr: 'अंदाजित निधी', hi: 'अनुमानित बजट'),
                                  value: imp.estimatedBudget != null
                                      ? AppTranslations.formatDigits(numFormat.format(imp.estimatedBudget), lang)
                                      : AppTranslations.pick(lang, en: 'To be estimated', mr: 'अंदाज निश्चित करायचा आहे', hi: 'अनुमान तय किया जाना है'),
                                  lang: lang,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Voting & AI Trend Analysis Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.how_to_vote_outlined, color: Color(0xFF0284C7), size: 22),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(lang, en: 'Community Voting & Support', mr: 'लोकसहभाग व मते', hi: 'सामुदायिक मतदान व समर्थन'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Voting Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF0F9FF), Color(0xFFFFFFFF)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  AppTranslations.formatDigits('${imp.votes}', lang),
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0284C7),
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  AppTranslations.pick(lang, en: 'TOTAL COMMUNITY VOTES', mr: 'एकूण नोंदवलेली मते', hi: 'कुल सामुदायिक मत'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: 200,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: _isVoting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Icon(Icons.thumb_up_alt_rounded, size: 18),
                                    label: Text(
                                      AppTranslations.pick(lang, en: 'Vote for Proposal', mr: 'या कामाला मत द्या', hi: 'प्रस्ताव के लिए वोट करें'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    onPressed: _isVoting ? null : _handleVote,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // AI Trend Analysis
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.trending_up_rounded, color: Color(0xFF16A34A), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppTranslations.pick(lang, en: 'AI Trend & Feasibility Analysis', mr: 'AI विश्लेषण व व्यवहार्यता', hi: 'AI रुझान और व्यवहार्यता विश्लेषण'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppTranslations.formatDigits(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'High community priority in Ward 12. Ranking within top 10 percentile for municipal capital budget allocation based on resident footfall and pedestrian safety benefits.',
                                            mr: 'प्रभाग 12 मध्ये नागरिकांची उच्च पसंती. पादचारी सुरक्षा व लोकसंख्येच्या दृष्टीने महापालिका बजेट प्राधान्यक्रमात शीर्ष 10% मध्ये स्थान.',
                                            hi: 'वार्ड 12 में उच्च सामुदायिक प्राथमिकता। पैदल सुरक्षा और नागरिक उपयोगिता के आधार पर नगर निगम पूंजी बजट आवंटन में शीर्ष 10% में रैंकिंग।',
                                          ),
                                          lang,
                                        ),
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Widget _metaInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String lang,
    bool translateValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                translateValue
                    ? AppTranslatedText(
                        value,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        value,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

