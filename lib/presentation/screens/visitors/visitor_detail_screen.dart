import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/visitor_model.dart';
import '../../../data/repositories/visitors_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import 'visitor_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class VisitorDetailScreen extends ConsumerStatefulWidget {
  final VisitorModel visitor;
  final VoidCallback? onVisitorUpdated;

  const VisitorDetailScreen({
    super.key,
    required this.visitor,
    this.onVisitorUpdated,
  });

  @override
  ConsumerState<VisitorDetailScreen> createState() => _VisitorDetailScreenState();
}

class _VisitorDetailScreenState extends ConsumerState<VisitorDetailScreen> {
  late VisitorModel _visitor;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _visitor = widget.visitor;
  }

  Future<void> _makePhoneCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    final fullNumber = clean.length == 10 ? '91$clean' : clean;
    final uri = Uri.parse('https://wa.me/$fullNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _localizedPurpose(String purpose, String lang) {
    switch (purpose) {
      case 'Complaint':
        return AppTranslations.pick(lang, en: 'Complaint', mr: 'तक्रार (Complaint)', hi: 'शिकायत');
      case 'Meeting':
        return AppTranslations.pick(lang, en: 'Meeting', mr: 'भेट / चर्चा (Meeting)', hi: 'बैठक / चर्चा');
      case 'Greeting':
      case 'Invitation':
        return AppTranslations.pick(lang, en: 'Greeting / Invite', mr: 'निमंत्रण / सत्कार', hi: 'निमंत्रण / सम्मान');
      case 'Help':
        return AppTranslations.pick(lang, en: 'Help / Relief', mr: 'वैयक्तिक मदत (Help)', hi: 'व्यक्तिगत सहायता');
      case 'Donation':
        return AppTranslations.pick(lang, en: 'Donation', mr: 'देणगी / निधी (Donation)', hi: 'दान / निधि');
      case 'Other':
        return AppTranslations.pick(lang, en: 'Other', mr: 'इतर (Other)', hi: 'अन्य');
      default:
        return purpose;
    }
  }

  void _showDeleteDialog() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Delete Visitor Log?',
                  mr: 'अभ्यागत नोंद हटवायची का?',
                  hi: 'आगंतुक रिकॉर्ड हटाएँ?',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: AppTranslatedText(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to remove the visit record for "${_visitor.name}"? This action cannot be undone.',
            mr: '"${_visitor.name}" यांची भेट नोंद कायमची काढायची का? ही कृती पूर्ववत करता येणार नाही.',
            hi: 'क्या आप "${_visitor.name}" का आगंतुक रिकॉर्ड स्थायी रूप से हटाना चाहते हैं? यह कार्रवाई पूर्ववत नहीं की जा सकती।',
          ),
          targetLanguage: lang,
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
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
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isUpdating = true);
              try {
                final repo = ref.read(visitorsRepoProvider);
                await repo.deleteVisitor(_visitor.id);
                widget.onVisitorUpdated?.call();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Visitor log deleted',
                          mr: 'अभ्यागत नोंद हटवली',
                          hi: 'आगंतुक रिकॉर्ड हटाया गया',
                        ),
                      ),
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  final prefix = AppTranslations.pick(
                    lang,
                    en: 'Failed to delete: ',
                    mr: 'हटवताना त्रुटी: ',
                    hi: 'हटाने में विफल: ',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AppTranslatedText('$prefix$e', targetLanguage: lang, style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isUpdating = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ')),
          ),
        ],
      ),
    );
  }

  void _showEditSheet() {
    final lang = ref.read(appLanguageProvider);
    final nameCtrl = TextEditingController(text: _visitor.name);
    final mobileCtrl = TextEditingController(text: _visitor.mobile);
    final areaCtrl = TextEditingController(text: _visitor.area ?? '');
    final refCtrl = TextEditingController(text: _visitor.reference ?? '');
    final remarksCtrl = TextEditingController(text: _visitor.remarks ?? '');
    final amountCtrl = TextEditingController(text: _visitor.amount ?? '');
    final eventDateCtrl = TextEditingController(text: _visitor.eventDate ?? '');
    final eventTimeCtrl = TextEditingController(text: _visitor.eventTime ?? '');

    String selectedPurpose = _visitor.purpose;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isGreeting = selectedPurpose == 'Greeting' || selectedPurpose == 'Invitation';
          final isDonation = selectedPurpose == 'Donation' || selectedPurpose == 'Help';

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
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
                  title: AppTranslations.pick(
                    lang,
                    en: 'Edit Visitor Details',
                    mr: 'अभ्यागत माहिती संपादित करा',
                    hi: 'आगंतुक विवरण संपादित करें',
                  ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Update visitor details',
                    mr: 'अभ्यागताचे तपशील अद्यतनित करा',
                    hi: 'आगंतुक विवरण अपडेट करें',
                  ),
                  onClose: () => Navigator.pop(ctx),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    children: [
                      AppFieldLabel(
                        label: AppTranslations.pick(
                          lang,
                          en: 'Visitor Full Name',
                          mr: 'अभ्यागताचे पूर्ण नाव',
                          hi: 'आगंतुक का पूरा नाम',
                        ),
                        isRequired: true,
                      ),
                      TextField(
                        controller: nameCtrl,
                        decoration: appInputDecoration(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Ramesh Patil',
                            mr: 'उदा. रमेश पाटील',
                            hi: 'उदा. रमेश पाटिल',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Side-by-side: Contact Mobile & Purpose Dropdown
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Mobile (+91)',
                                    mr: 'मोबाईल (+91)',
                                    hi: 'मोबाइल (+91)',
                                  ),
                                ),
                                TextField(
                                  controller: mobileCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: appInputDecoration(
                                    prefixText: '+91 ',
                                    hint: '9876543210',
                                  ),
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
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Visit Purpose',
                                    mr: 'भेटीचे कारण / स्वरूप',
                                    hi: 'भेंट का उद्देश्य',
                                  ),
                                  isRequired: true,
                                  value: ['Complaint', 'Meeting', 'Greeting', 'Donation', 'Help', 'Other'].contains(selectedPurpose)
                                      ? selectedPurpose
                                      : 'Meeting',
                                  items: [
                                    for (final code in const ['Complaint', 'Meeting', 'Greeting', 'Help', 'Donation', 'Other'])
                                      DropdownMenuItem(
                                        value: code,
                                        child: Text(_localizedPurpose(code, lang)),
                                      ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedPurpose = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Side-by-side: Area / Locality (or Venue) & Reference / Leader
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFieldLabel(
                                  label: isGreeting
                                      ? AppTranslations.pick(
                                          lang,
                                          en: 'Event Venue / Address',
                                          mr: 'कार्यक्रमाचे ठिकाण / पत्ता',
                                          hi: 'कार्यक्रम स्थल / पता',
                                        )
                                      : AppTranslations.pick(
                                          lang,
                                          en: 'Area / Locality',
                                          mr: 'क्षेत्र / परिसर',
                                          hi: 'क्षेत्र / इलाका',
                                        ),
                                ),
                                TextField(
                                  controller: areaCtrl,
                                  decoration: appInputDecoration(
                                    hint: isGreeting
                                        ? AppTranslations.pick(
                                            lang,
                                            en: 'e.g. Shivaji Chowk Hall',
                                            mr: 'उदा. शिवाजी चौक सभागृह',
                                            hi: 'उदा. शिवाजी चौक हॉल',
                                          )
                                        : AppTranslations.formatDigits(
                                            AppTranslations.pick(
                                              lang,
                                              en: 'e.g. Lane 4, Ward 12',
                                              mr: 'उदा. गल्ली क्र. 4, प्रभाग 12',
                                              hi: 'उदा. गली नं. 4, वार्ड 12',
                                            ),
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
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Reference / Leader',
                                    mr: 'संदर्भ / नेता (ऐच्छिक)',
                                    hi: 'संदर्भ / नेता (वैकल्पिक)',
                                  ),
                                ),
                                TextField(
                                  controller: refCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Sunil Shinde',
                                      mr: 'उदा. सुनील शिंदे',
                                      hi: 'उदा. सुनील शिंदे',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (isGreeting) ...[
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Event Date',
                                      mr: 'कार्यक्रमाची तारीख',
                                      hi: 'कार्यक्रम की तिथि',
                                    ),
                                  ),
                                  TextField(
                                    controller: eventDateCtrl,
                                    decoration: appInputDecoration(hint: 'YYYY-MM-DD'),
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
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Event Time',
                                      mr: 'कार्यक्रमाची वेळ',
                                      hi: 'कार्यक्रम का समय',
                                    ),
                                  ),
                                  TextField(
                                    controller: eventTimeCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. 18:30',
                                        mr: 'उदा. 18:30',
                                        hi: 'उदा. 18:30',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (isDonation) ...[
                        const SizedBox(height: 14),
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Requested Amount (₹)',
                            mr: 'अपेक्षित रक्कम (₹)',
                            hi: 'अनुरोधित राशि (₹)',
                          ),
                        ),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: appInputDecoration(
                            prefixText: '₹ ',
                            hint: '5000',
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Discussion Remarks
                      AppFieldLabel(
                        label: AppTranslations.pick(
                          lang,
                          en: 'Discussion Notes & Remarks',
                          mr: 'चर्चा नोंदी व शेरा',
                          hi: 'चर्चा नोट्स और टिप्पणी',
                        ),
                      ),
                      TextField(
                        controller: remarksCtrl,
                        maxLines: 3,
                        decoration: appInputDecoration(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'Discussion summary, citizen grievance details...',
                            mr: 'चर्चेचा गोषवारा, तक्रार तपशील...',
                            hi: 'चर्चा का सारांश, नागरिक शिकायत विवरण...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Please enter visitor name',
                                      mr: 'कृपया अभ्यागताचे नाव प्रविष्ट करा',
                                      hi: 'कृपया आगंतुक का नाम दर्ज करें',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            setState(() => _isUpdating = true);
                            try {
                              final updates = {
                                'name': name,
                                'mobile': mobileCtrl.text.trim(),
                                'purpose': selectedPurpose,
                                'area': areaCtrl.text.trim(),
                                'reference': refCtrl.text.trim(),
                                'remarks': remarksCtrl.text.trim(),
                                'metadata': {
                                  if (eventDateCtrl.text.trim().isNotEmpty) 'event_date': eventDateCtrl.text.trim(),
                                  if (eventTimeCtrl.text.trim().isNotEmpty) 'event_time': eventTimeCtrl.text.trim(),
                                  if (amountCtrl.text.trim().isNotEmpty) 'amount': amountCtrl.text.trim(),
                                },
                              };

                              final repo = ref.read(visitorsRepoProvider);
                              await repo.updateVisitor(_visitor.id, updates);
                              setState(() {
                                _visitor = _visitor.copyWith(
                                  name: name,
                                  mobile: mobileCtrl.text.trim(),
                                  purpose: selectedPurpose,
                                  area: areaCtrl.text.trim(),
                                  reference: refCtrl.text.trim(),
                                  remarks: remarksCtrl.text.trim(),
                                  eventDate: eventDateCtrl.text.trim(),
                                  eventTime: eventTimeCtrl.text.trim(),
                                  amount: amountCtrl.text.trim(),
                                );
                              });
                              widget.onVisitorUpdated?.call();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Visitor updated successfully',
                                        mr: 'अभ्यागत माहिती यशस्वीरित्या अद्यतनित केली!',
                                        hi: 'आगंतुक विवरण सफलतापूर्वक अपडेट किया गया!',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF0F766E),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                final prefix = AppTranslations.pick(
                                  lang,
                                  en: 'Failed to update: ',
                                  mr: 'अद्यतनित करताना त्रुटी: ',
                                  hi: 'अपडेट करने में विफल: ',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: AppTranslatedText(
                                      '$prefix$e',
                                      targetLanguage: lang,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isUpdating = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Save Changes',
                              mr: 'बदल जतन करा',
                              hi: 'परिवर्तन सहेजें',
                            ),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final localizedDate = AppTranslations.formatDate(_visitor.visitDate, lang, pattern: 'dd MMM yyyy');
    final localizedTime = AppTranslations.formatTime(_visitor.visitDate, lang);
    final dateTimeDisplay = AppTranslations.pick(
      lang,
      en: '$localizedDate at $localizedTime',
      mr: '$localizedDate • $localizedTime',
      hi: '$localizedDate • $localizedTime',
    );

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
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Visitor Details',
                  mr: 'भेट देणारा तपशील',
                  hi: 'आगंतुक विवरण',
                ),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                localizedDate,
                style: TextStyle(
                  fontSize: 11,
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
                  tooltip: AppTranslations.getDownloadReport(lang),
                  onPressed: () {
                    VisitorReportGenerator.generateAndPrintVisitorSlip(_visitor, lang: lang);
                  },
                ),
              ),
            ),
            IconButton(
              tooltip: AppTranslations.pick(lang, en: 'Edit Visitor', mr: 'माहिती संपादित करा', hi: 'विवरण संपादित करें'),
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: _showEditSheet,
            ),
            IconButton(
              tooltip: AppTranslations.pick(lang, en: 'Delete Log', mr: 'नोंद हटवा', hi: 'रिकॉर्ड हटाएँ'),
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _showDeleteDialog,
            ),
          ],
        ),
        body: _isUpdating
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Profile Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: _visitor.purposeBgColor,
                                child: Text(
                                  _visitor.name.isNotEmpty ? _visitor.name[0].toUpperCase() : 'V',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _visitor.purposeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppTranslatedText(
                                      _visitor.name,
                                      isName: true,
                                      targetLanguage: lang,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _visitor.mobile.isNotEmpty
                                          ? AppTranslations.formatDigits('+91 ${_visitor.mobile}', lang)
                                          : AppTranslations.pick(
                                              lang,
                                              en: 'No Mobile Added',
                                              mr: 'मोबाईल क्रमांक नाही',
                                              hi: 'मोबाइल नंबर उपलब्ध नहीं',
                                            ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _visitor.purposeBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _visitor.purposeColor.withValues(alpha: 0.3)),
                                ),
                                child: AppTranslatedText(
                                  _localizedPurpose(_visitor.purpose, lang),
                                  targetLanguage: lang,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _visitor.purposeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_visitor.mobile.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _makePhoneCall(_visitor.mobile),
                                    icon: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF0284C7)),
                                    label: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Call Citizen',
                                        mr: 'कॉल करा',
                                        hi: 'कॉल करें',
                                      ),
                                      style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF0284C7)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openWhatsApp(_visitor.mobile),
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                                    label: Text(
                                      AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सॲप', hi: 'व्हाट्सऐप'),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Visit Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(lang, en: 'Visit Details', mr: 'भेटीचा तपशील', hi: 'भेंट विवरण'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.calendar_today_outlined,
                            AppTranslations.pick(lang, en: 'Visit Date & Time', mr: 'भेटीची तारीख व वेळ', hi: 'भेंट की तिथि व समय'),
                            dateTimeDisplay,
                            lang,
                            translateValue: false,
                          ),
                          if (_visitor.area != null && _visitor.area!.isNotEmpty)
                            _buildDetailRow(
                              Icons.location_on_outlined,
                              AppTranslations.pick(
                                lang,
                                en: 'Citizen Area / Ward Address',
                                mr: 'नागरिकाचा परिसर / प्रभाग पत्ता',
                                hi: 'नागरिक क्षेत्र / वार्ड पता',
                              ),
                              AppTranslations.getAreaName(_visitor.area!, lang),
                              lang,
                            ),
                          if (_visitor.reference != null && _visitor.reference!.isNotEmpty)
                            _buildDetailRow(
                              Icons.person_pin_circle_outlined,
                              AppTranslations.pick(
                                lang,
                                en: 'Reference / Recommendation',
                                mr: 'संदर्भ / शिफारस',
                                hi: 'संदर्भ / सिफारिश',
                              ),
                              _visitor.reference!,
                              lang,
                              isName: true,
                            ),
                          if (_visitor.amount != null && _visitor.amount!.isNotEmpty)
                            _buildDetailRow(
                              Icons.currency_rupee_rounded,
                              AppTranslations.pick(
                                lang,
                                en: 'Requested Financial Assistance',
                                mr: 'अपेक्षित आर्थिक मदत',
                                hi: 'अनुरोधित वित्तीय सहायता',
                              ),
                              AppTranslations.formatCurrency(_visitor.amount!, lang),
                              lang,
                              translateValue: false,
                            ),
                          if (_visitor.eventDate != null && _visitor.eventDate!.isNotEmpty)
                            _buildDetailRow(
                              Icons.celebration_outlined,
                              AppTranslations.pick(
                                lang,
                                en: 'Event / Invitation Schedule',
                                mr: 'कार्यक्रम / निमंत्रण वेळापत्रक',
                                hi: 'कार्यक्रम / निमंत्रण समय-सारणी',
                              ),
                              AppTranslations.formatDigits(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Date: ${_visitor.eventDate} | Time: ${_visitor.eventTime ?? "Flexible"}',
                                  mr: 'तारीख: ${_visitor.eventDate} | वेळ: ${_visitor.eventTime ?? "लवचिक"}',
                                  hi: 'तिथि: ${_visitor.eventDate} | समय: ${_visitor.eventTime ?? "सुविधाजनक"}',
                                ),
                                lang,
                              ),
                              lang,
                              translateValue: false,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Remarks / Notes
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Discussion Notes & Action Taken',
                              mr: 'चर्चा नोंदी व कार्यवाही',
                              hi: 'चर्चा नोट्स और की गई कार्रवाई',
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          if (_visitor.remarks != null && _visitor.remarks!.isNotEmpty)
                            AppTranslatedText(
                              _visitor.remarks!,
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.5),
                            )
                          else
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'No notes or special remarks logged for this visit.',
                                mr: 'या भेटीसाठी कोणताही विशेष शेरा नोंदवलेला नाही.',
                                hi: 'इस भेंट के लिए कोई नोट्स या विशेष टिप्पणी दर्ज नहीं की गई है।',
                              ),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.5),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value,
    String lang, {
    bool isName = false,
    bool translateValue = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0284C7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                if (translateValue)
                  AppTranslatedText(
                    value,
                    isName: isName,
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

