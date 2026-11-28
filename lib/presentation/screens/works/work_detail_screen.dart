import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/work_history_model.dart';
import '../../../data/repositories/work_history_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_pagination_bar.dart';
import 'ahwal_report_generator.dart';

class WorkDetailScreen extends ConsumerStatefulWidget {
  final WorkHistoryModel work;

  const WorkDetailScreen({super.key, required this.work});

  @override
  ConsumerState<WorkDetailScreen> createState() => _WorkDetailScreenState();
}

class _WorkDetailScreenState extends ConsumerState<WorkDetailScreen> {
  late WorkHistoryModel _currentWork;
  bool _isDeleting = false;
  int _feedbackPage = 1;
  static const int _feedbackPageSize = 4;

  int get _totalFeedbackPages {
    final count = _currentWork.feedbacks.length;
    return (count / _feedbackPageSize).ceil() < 1 ? 1 : (count / _feedbackPageSize).ceil();
  }

  List<WorkFeedbackModel> get _pagedFeedbacks {
    final list = _currentWork.feedbacks;
    final startIndex = (_feedbackPage - 1) * _feedbackPageSize;
    if (startIndex >= list.length) return [];
    final endIndex = min(startIndex + _feedbackPageSize, list.length);
    return list.sublist(startIndex, endIndex);
  }

  @override
  void initState() {
    super.initState();
    _currentWork = widget.work;
  }

  Future<void> _refreshWorkDetails() async {
    final repo = ref.read(workHistoryRepoProvider);
    final updated = await repo.getWorkById(_currentWork.id);
    if (updated != null && mounted) {
      setState(() {
        _currentWork = updated;
        _feedbackPage = 1;
      });
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
                AppTranslations.pick(lang, en: 'Delete Work Record', mr: 'कामाची नोंद हटवायची का?', hi: 'कार्य रिकॉर्ड हटाएँ?'),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to delete this development work record? This action cannot be undone.',
            mr: 'तुम्हाला ही विकास कामाची नोंद कायमची हटवायची आहे का? ही कृती पूर्ववत करता येणार नाही.',
            hi: 'क्या आप वाकई इस विकास कार्य रिकॉर्ड को हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।',
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
              final repo = ref.read(workHistoryRepoProvider);
              await repo.deleteWork(_currentWork.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Work record deleted successfully',
                        mr: 'कामाची नोंद यशस्वीरित्या हटवली',
                        hi: 'कार्य रिकॉर्ड सफलतापूर्वक हटाया गया',
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
    final titleCtrl = TextEditingController(text: _currentWork.title);
    final descCtrl = TextEditingController(text: _currentWork.description);
    final locCtrl = TextEditingController(text: _currentWork.location);
    final areaCtrl = TextEditingController(text: _currentWork.area);
    final benCtrl = TextEditingController(text: _currentWork.peopleBenefited?.toString() ?? '');
    final amtCtrl = TextEditingController(text: _currentWork.amount != null ? _currentWork.amount!.toInt().toString() : '');
    final dateCtrl = TextEditingController(text: _currentWork.date);
    String status = _currentWork.status;

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
                maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                  AppModalHeader(
                    icon: Icons.edit_note_rounded,
                    title: AppTranslations.pick(lang, en: 'Edit Development Project', mr: 'विकास प्रकल्प संपादित करा', hi: 'विकास परियोजना संपादित करें'),
                    subtitle: AppTranslations.pick(lang, en: 'Project Information & Status Update', mr: 'प्रकल्प माहिती व स्थिती अद्यतन', hi: 'परियोजना जानकारी और स्थिति अपडेट'),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(18, 14, 18, 16 + MediaQuery.of(sheetCtx).viewInsets.bottom),
                      children: [
                        // Project Title
                        AppFieldLabel(
                          label: AppTranslations.pick(lang, en: 'Project Title', mr: 'कामाचे नाव / प्रकल्प शीर्षक', hi: 'कार्य का नाम / परियोजना शीर्षक'),
                          isRequired: true,
                        ),
                        TextField(
                          controller: titleCtrl,
                          decoration: inputDec(hint: AppTranslations.pick(lang, en: 'Project Title...', mr: 'उदा. मुख्य रस्ता डांबरीकरण', hi: 'परियोजना का नाम...')),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        AppFieldLabel(label: AppTranslations.pick(lang, en: 'Description', mr: 'कामाचा तपशील / वर्णन', hi: 'कार्य का विवरण')),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: inputDec(hint: AppTranslations.pick(lang, en: 'Description...', mr: 'कामाचे सविस्तर वर्णन...', hi: 'विस्तृत विवरण...')),
                        ),
                        const SizedBox(height: 14),

                        // Side-by-side: Location & Area
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Location / Landmark', mr: 'स्थान / लँडमार्क', hi: 'स्थान / लैंडमार्क')),
                                  TextField(
                                    controller: locCtrl,
                                    decoration: inputDec(hint: AppTranslations.pick(lang, en: 'Location...', mr: 'उदा. मुख्य चौक', hi: 'स्थान...')),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Area / Locality', mr: 'परिसर / प्रभाग', hi: 'क्षेत्र / वार्ड')),
                                  TextField(
                                    controller: areaCtrl,
                                    decoration: inputDec(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'Area...', mr: 'उदा. प्रभाग 12', hi: 'उदा. वार्ड 12'),
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

                        // Side-by-side: Status & Completion Date
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppDropdownFormField<String>(
                                    label: AppTranslations.pick(lang, en: 'Work Status', mr: 'कामाची स्थिती', hi: 'कार्य स्थिति'),
                                    isRequired: true,
                                    value: status,
                                    items: [
                                      DropdownMenuItem(value: 'Planned', child: Text(AppTranslations.getStatus('Planned', lang))),
                                      DropdownMenuItem(value: 'InProgress', child: Text(AppTranslations.getStatus('In Progress', lang))),
                                      DropdownMenuItem(value: 'Completed', child: Text(AppTranslations.getStatus('Completed', lang))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => status = val);
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
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Completion Date', mr: 'अंदाजित / पूर्ण तारीख', hi: 'पूर्ण होने की तिथि')),
                                  TextField(
                                    controller: dateCtrl,
                                    decoration: inputDec(hint: 'YYYY-MM-DD'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Side-by-side: Citizens Benefited & Expenditure
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Citizens Benefited', mr: 'लाभार्थी संख्या', hi: 'लाभान्वित नागरिक')),
                                  TextField(
                                    controller: benCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: inputDec(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. 5000', mr: 'उदा. 5000', hi: 'उदा. 5000'),
                                        lang,
                                      ),
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
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Expenditure (₹)', mr: 'खर्च झालेली रक्कम (₹)', hi: 'व्यय राशि (₹)')),
                                  TextField(
                                    controller: amtCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: inputDec(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. 850000', mr: 'उदा. 850000', hi: 'उदा. 850000'),
                                        lang,
                                      ),
                                      prefixText: '₹ ',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Save Button (Scrolls together with form)
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
                              final updated = _currentWork.copyWith(
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                location: locCtrl.text.trim(),
                                area: areaCtrl.text.trim(),
                                status: status,
                                date: AppTranslations.normalizeAsciiDigits(dateCtrl.text.trim()),
                                peopleBenefited: int.tryParse(AppTranslations.normalizeAsciiDigits(benCtrl.text.trim())),
                                amount: double.tryParse(AppTranslations.normalizeAsciiDigits(amtCtrl.text.trim())),
                              );

                              final repo = ref.read(workHistoryRepoProvider);
                              await repo.updateWork(updated);
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (mounted) {
                                setState(() => _currentWork = updated);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Project updated successfully',
                                        mr: 'प्रकल्प यशस्वीरित्या अद्यतनित केला!',
                                        hi: 'परियोजना सफलतापूर्वक अपडेट की गई!',
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

  void _showAddFeedbackModal() {
    final lang = ref.read(appLanguageProvider);
    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    int rating = 5;

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
                maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  AppModalHeader(
                    icon: Icons.rate_review_outlined,
                    title: AppTranslations.pick(lang, en: 'Add Citizen Feedback', mr: 'नागरिक प्रतिक्रिया जोडा', hi: 'नागरिक प्रतिक्रिया जोड़ें'),
                    subtitle: AppTranslations.pick(lang, en: 'Citizen remarks on project quality', mr: 'प्रकल्पाबाबत नागरिकांचा अभिप्राय', hi: 'परियोजना गुणवत्ता पर नागरिक टिप्पणी'),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + MediaQuery.of(sheetCtx).viewInsets.bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppFieldLabel(label: AppTranslations.pick(lang, en: 'Citizen Name', mr: 'नागरिकाचे नाव', hi: 'नागरिक का नाम'), isRequired: true),
                          TextField(
                            controller: nameCtrl,
                            decoration: inputDec(hint: AppTranslations.pick(lang, en: 'e.g. Suresh Shinde', mr: 'उदा. सुरेश शिंदे', hi: 'उदा. सुरेश शिंदे')),
                          ),
                          const SizedBox(height: 12),

                          AppFieldLabel(label: AppTranslations.pick(lang, en: 'Rating', mr: 'रेटिंग (गुणवत्ता दर्जा)', hi: 'रेटिंग (गुणवत्ता स्तर)'), isRequired: true),
                          Row(
                            children: List.generate(5, (index) {
                              final starIndex = index + 1;
                              return IconButton(
                                icon: Icon(
                                  starIndex <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 32,
                                ),
                                onPressed: () => setModalState(() => rating = starIndex),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),

                          AppFieldLabel(label: AppTranslations.pick(lang, en: 'Review / Comment', mr: 'अभिप्राय / शेरा', hi: 'समीक्षा / टिप्पणी'), isRequired: true),
                          TextField(
                            controller: commentCtrl,
                            maxLines: 3,
                            decoration: inputDec(
                              hint: AppTranslations.pick(
                                lang,
                                en: 'Share remarks on the quality and durability of this work...',
                                mr: 'कामाच्या गुणवत्तेबाबत आणि उपयुक्ततेबाबत शेरा...',
                                hi: 'इस कार्य की गुणवत्ता और उपयोगिता पर टिप्पणी साझा करें...',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Submit Button (Scrolls together with form)
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
                                if (nameCtrl.text.trim().isEmpty || commentCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Please enter citizen name and comment',
                                          mr: 'कृपया नागरिकाचे नाव आणि शेरा प्रविष्ट करा',
                                          hi: 'कृपया नागरिक का नाम और टिप्पणी दर्ज करें',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final fb = WorkFeedbackModel(
                                  id: 'fb-${DateTime.now().millisecondsSinceEpoch}',
                                  citizenName: nameCtrl.text.trim(),
                                  rating: rating,
                                  comment: commentCtrl.text.trim(),
                                  createdAt: DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now()),
                                );

                                final repo = ref.read(workHistoryRepoProvider);
                                await repo.addFeedback(_currentWork.id, fb);
                                await _refreshWorkDetails();
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Feedback added successfully!',
                                          mr: 'प्रतिक्रिया यशस्वीरित्या जोडली गेली!',
                                          hi: 'प्रतिक्रिया सफलतापूर्वक जोड़ी गई!',
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFF16A34A),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                AppTranslations.pick(lang, en: 'Submit Feedback', mr: 'प्रतिक्रिया जतन करा', hi: 'प्रतिक्रिया सहेजें'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
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

  String _formatWorkDate(String raw, String lang) {
    if (raw.trim().isEmpty) return AppTranslations.getStatus('In Progress', lang);
    final dt = DateTime.tryParse(raw.trim());
    if (dt != null) {
      return AppTranslations.formatDate(dt, lang, pattern: 'dd MMM yyyy');
    }
    return AppTranslations.formatDigits(raw, lang);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final w = _currentWork;
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

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
                AppTranslations.pick(lang, en: 'Work Details', mr: 'कामाचा तपशील', hi: 'कार्य विवरण'),
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                AppTranslations.formatDigits(
                  w.area.isNotEmpty
                      ? '${AppTranslations.getAreaName(w.area, lang)} • ${AppTranslations.pick(lang, en: "Ward No. 12", mr: "प्रभाग क्र. 12", hi: "वार्ड नं. 12")}'
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
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AppPdfButton.icon(
                  tooltip: AppTranslations.pick(lang, en: 'Download Report', mr: 'अहवाल डाउनलोड करा', hi: 'रिपोर्ट डाउनलोड करें'),
                  onPressed: () => AhwalReportGenerator.generateAndPrintAhwal(
                    selectedWorks: [_currentWork],
                    lang: lang,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: AppTranslations.pick(lang, en: 'Edit Project', mr: 'प्रकल्प संपादित करा', hi: 'परियोजना संपादित करें'),
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: AppTranslations.pick(lang, en: 'Delete Project', mr: 'प्रकल्प हटवा', hi: 'परियोजना हटाएँ'),
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
                    // Main Project Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: w.status.toLowerCase() == 'completed'
                              ? const Color(0xFFBBF7D0)
                              : w.status.toLowerCase().contains('progress')
                                  ? const Color(0xFFBAE6FD)
                                  : const Color(0xFFE2E8F0),
                        ),
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(w.sourceIcon, size: 13, color: const Color(0xFF1D4ED8)),
                                        const SizedBox(width: 4),
                                        Text(
                                          lang == 'mr'
                                              ? w.sourceDisplayMr
                                              : (lang == 'hi' ? AppTranslations.translateDirect(w.sourceDisplayEn, lang: lang) : w.sourceDisplayEn),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (w.area.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: AppTranslatedText(
                                        w.area,
                                        targetLanguage: lang,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: w.statusBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  AppTranslations.getStatus(w.status, lang),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: w.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AppTranslatedText(w.title,
                            targetLanguage: lang,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppTranslatedText(w.description,
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
                                  value: w.location.isNotEmpty
                                      ? w.location
                                      : (w.area.isNotEmpty
                                          ? w.area
                                          : AppTranslations.pick(lang, en: 'Prabhag Area', mr: 'प्रभाग परिसर', hi: 'वार्ड क्षेत्र')),
                                  lang: lang,
                                  translateValue: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _metaInfoTile(
                                  icon: Icons.calendar_today_outlined,
                                  iconColor: const Color(0xFF0284C7),
                                  label: AppTranslations.pick(lang, en: 'Completion Date', mr: 'पूर्ण झालेली तारीख', hi: 'पूर्ण होने की तिथि'),
                                  value: _formatWorkDate(w.date, lang),
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
                                  label: AppTranslations.pick(lang, en: 'Benefited Citizens', mr: 'लाभार्थी नागरिक', hi: 'लाभान्वित नागरिक'),
                                  value: w.peopleBenefited != null
                                      ? AppTranslations.formatDigits(NumberFormat.decimalPattern().format(w.peopleBenefited), lang)
                                      : AppTranslations.pick(lang, en: 'All Prabhag Citizens', mr: 'सर्व प्रभाग नागरिक', hi: 'सभी वार्ड नागरिक'),
                                  lang: lang,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _metaInfoTile(
                                  icon: Icons.currency_rupee_rounded,
                                  iconColor: const Color(0xFF16A34A),
                                  label: AppTranslations.pick(lang, en: 'Expenditure', mr: 'सार्वजनिक खर्च', hi: 'सार्वजनिक व्यय'),
                                  value: w.amount != null
                                      ? AppTranslations.formatDigits(numFormat.format(w.amount), lang)
                                      : AppTranslations.pick(lang, en: 'PMC Ward Fund', mr: 'महानगरपालिका प्रभाग निधी', hi: 'नगर निगम वार्ड निधि'),
                                  lang: lang,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Feedback & AI Sentiment Section
                    Container(
                      padding: const EdgeInsets.all(18),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        AppTranslations.pick(lang, en: 'Citizen Feedback & Ratings', mr: 'नागरिक प्रतिसाद व रेटिंग', hi: 'नागरिक प्रतिक्रिया और रेटिंग'),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add_comment_outlined, size: 16),
                                label: Text(AppTranslations.pick(lang, en: '+ Review', mr: '+ मत नोंदवा', hi: '+ समीक्षा')),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0284C7),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: _showAddFeedbackModal,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Rating Summary Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF0F9FF), Color(0xFFFFFFFF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppTranslations.formatDigits(w.feedbackRating > 0 ? '${w.feedbackRating}' : '4.8', lang),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0369A1),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return const Icon(Icons.star_rounded, color: Colors.amber, size: 16);
                                      }),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppTranslations.formatDigits(
                                        '${w.feedbackCount} ${AppTranslations.pick(lang, en: 'Reviews', mr: 'प्रतिक्रिया', hi: 'समीक्षाएं')}',
                                        lang,
                                      ),
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.auto_awesome, size: 14, color: Colors.purple),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                AppTranslations.pick(lang, en: 'AI Citizen Sentiment', mr: 'AI नागरिक प्रतिसाद विश्लेषण', hi: 'AI नागरिक भावना विश्लेषण'),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF6B21A8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          w.feedbackCount > 0
                                              ? AppTranslations.formatDigits(
                                                  AppTranslations.pick(
                                                    lang,
                                                    en: 'Strong public approval (94%) praising durable construction, reliable drainage, and prompt delivery by the ward committee.',
                                                    mr: 'प्रभाग समितीच्या टिकाऊ बांधकामास व वेगवान कामास नागरिकांचा 94% सकारात्मक प्रतिसाद.',
                                                    hi: 'वार्ड समिति के टिकाऊ निर्माण और समय पर कार्य निष्पादन पर नागरिकों का 94% सकारात्मक समर्थन।',
                                                  ),
                                                  lang,
                                                )
                                              : AppTranslations.pick(
                                                  lang,
                                                  en: 'Early feedback positive. Verified project scope has received constructive appreciation from local residents.',
                                                  mr: 'प्राथमिक प्रतिसाद सकारात्मक. स्थानिक रहिवाशांकडून कामाचे स्वागत.',
                                                  hi: 'प्रारंभिक प्रतिक्रिया सकारात्मक। स्थानीय निवासियों द्वारा कार्य की सराहना की गई है।',
                                                ),
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Feedback Items
                          if (w.feedbacks.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Center(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'No citizen feedback registered yet.',
                                    mr: 'कोणतीही प्रतिक्रिया अद्याप नोंदवली नाही',
                                    hi: 'अभी तक कोई नागरिक प्रतिक्रिया दर्ज नहीं की गई है।',
                                  ),
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                              ),
                            )
                          else ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _pagedFeedbacks.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final fb = _pagedFeedbacks[i];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: AppTranslatedText(
                                              fb.citizenName,
                                              isName: true,
                                              targetLanguage: lang,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(fb.rating, (_) {
                                              return const Icon(Icons.star_rounded, color: Colors.amber, size: 14);
                                            }),
                                          ),
                                        ],
                                      ),
                                      if (fb.createdAt.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          AppTranslations.formatDigits(fb.createdAt, lang),
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      AppTranslatedText(
                                        fb.comment,
                                        targetLanguage: lang,
                                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            AppInlinePagination(
                              currentPage: _feedbackPage,
                              totalPages: _totalFeedbackPages,
                              totalItems: w.feedbacks.length,
                              pageSize: _feedbackPageSize,
                              label: AppTranslations.pick(lang, en: 'feedbacks', mr: 'प्रतिक्रिया', hi: 'प्रतिक्रियाएं'),
                              onPageChanged: (page) => setState(() => _feedbackPage = page),
                            ),
                          ],
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