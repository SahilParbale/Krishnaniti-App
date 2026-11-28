import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/gb_register_entry_model.dart';
import '../../../data/repositories/gb_register_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_dropdown.dart';

class GbRegisterDetailScreen extends ConsumerStatefulWidget {
  final GbRegisterEntryModel entry;

  const GbRegisterDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<GbRegisterDetailScreen> createState() => _GbRegisterDetailScreenState();
}

class _GbRegisterDetailScreenState extends ConsumerState<GbRegisterDetailScreen> {
  late GbRegisterEntryModel _currentEntry;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }

  String _meetingTypeLabel(String type, String lang) {
    switch (type.trim()) {
      case 'GB':
        return AppTranslations.pick(lang, en: 'General Body (GB)', mr: 'सर्वसाधारण सभा (GB)', hi: 'साधारण सभा (GB)');
      case 'Standing Committee':
        return AppTranslations.pick(lang, en: 'Standing Committee', mr: 'स्थायी समिती', hi: 'स्थायी समिति');
      case 'Ward Committee':
        return AppTranslations.pick(lang, en: 'Ward Committee', mr: 'प्रभाग समिती', hi: 'वार्ड समिति');
      case 'Special GB':
        return AppTranslations.pick(lang, en: 'Special GB', mr: 'विशेष सर्वसाधारण सभा', hi: 'विशेष साधारण सभा');
      case 'Other':
        return AppTranslations.pick(lang, en: 'Other', mr: 'इतर', hi: 'अन्य');
      default:
        return AppTranslations.translateDirect(type, lang: lang);
    }
  }

  Future<void> _handleQuickStatusChange(String newStatus) async {
    if (_currentEntry.status == newStatus) return;
    final lang = ref.read(appLanguageProvider);
    final updated = _currentEntry.copyWith(status: newStatus);
    final repo = ref.read(gbRegisterRepoProvider);
    await repo.updateEntry(updated);
    if (mounted) {
      setState(() => _currentEntry = updated);
      final locSt = AppTranslations.getStatus(newStatus, lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Motion status updated to $locSt',
              mr: 'ठराव स्थिती अद्यतनित केली: $locSt',
              hi: 'प्रस्ताव स्थिति अपडेट की गई: $locSt',
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
                AppTranslations.pick(lang, en: 'Delete Motion Entry', mr: 'सभेचा ठराव हटवायचा का?', hi: 'प्रस्ताव प्रविष्टि हटाएँ?'),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to remove this assembly record from the GB Register? This action cannot be undone.',
            mr: 'तुम्हाला ही सभेची नोंद जीबी नोंदवहीतून काढायची आहे का? ही कृती पूर्ववत करता येणार नाही.',
            hi: 'क्या आप वाकई इस सभा रिकॉर्ड को जीबी रजिस्टर से हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।',
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
              final repo = ref.read(gbRegisterRepoProvider);
              await repo.deleteEntry(_currentEntry.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'GB Register record deleted successfully',
                        mr: 'जीबी नोंद यशस्वीरित्या हटवली',
                        hi: 'जीबी रजिस्टर रिकॉर्ड सफलतापूर्वक हटाया गया',
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
    final subjectCtrl = TextEditingController(text: _currentEntry.subject);
    final descCtrl = TextEditingController(text: _currentEntry.description);
    final deptCtrl = TextEditingController(text: _currentEntry.department);
    final areaCtrl = TextEditingController(text: _currentEntry.area);
    final dateCtrl = TextEditingController(text: _currentEntry.meetingDate);
    final benCtrl = TextEditingController(text: _currentEntry.beneficiaries ?? '');
    final respCtrl = TextEditingController(text: _currentEntry.response ?? '');

    String selectedMeetingType = _currentEntry.meetingType;
    String selectedStatus = _currentEntry.status;

    final meetingTypes = ['GB', 'Standing Committee', 'Ward Committee', 'Special GB', 'Other'];
    final statusList = ['Raised', 'In Discussion', 'Resolved', 'Action Taken'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            Future<void> pickDate() async {
              DateTime initial;
              try {
                initial = DateTime.parse(dateCtrl.text.trim());
              } catch (_) {
                initial = DateTime.now();
              }
              final picked = await showThemedDatePicker(
                context: sheetCtx,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setModalState(() {
                  dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppModalHeader(
                    icon: Icons.edit_note_rounded,
                    title: AppTranslations.pick(lang, en: 'Edit GB Register Entry', mr: 'GB नोंद संपादित करा', hi: 'जीबी प्रविष्टि संपादित करें'),
                    subtitle: AppTranslations.pick(lang, en: 'Update entry details and status', mr: 'नोंद तपशील व सद्यस्थिती अद्यतनित करा', hi: 'प्रविष्टि विवरण और स्थिति अपडेट करें'),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                      children: [
                        // 1. Meeting Date & Meeting Type (Side-by-Side)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Meeting Date', mr: 'बैठक तारीख', hi: 'बैठक तिथि'), isRequired: true),
                                  TextField(
                                    controller: dateCtrl,
                                    readOnly: true,
                                    onTap: pickDate,
                                    decoration: appInputDecoration(
                                      hint: 'YYYY-MM-DD',
                                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
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
                                  AppDropdownFormField<String>(
                                    label: AppTranslations.pick(lang, en: 'Meeting Type', mr: 'बैठक प्रकार', hi: 'बैठक प्रकार'),
                                    isRequired: true,
                                    value: meetingTypes.contains(selectedMeetingType) ? selectedMeetingType : 'GB',
                                    hintText: AppTranslations.pick(lang, en: 'Select Type', mr: 'प्रकार निवडा', hi: 'प्रकार चुनें'),
                                    items: meetingTypes
                                        .map((t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(_meetingTypeLabel(t, lang), style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedMeetingType = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 2. Subject / Issue (Full Width)
                        AppFieldLabel(label: AppTranslations.pick(lang, en: 'Subject / Issue', mr: 'विषय / मुद्दा', hi: 'विषय / मुद्दा'), isRequired: true),
                        TextField(
                          controller: subjectCtrl,
                          decoration: appInputDecoration(
                            hint: AppTranslations.formatDigits(
                              AppTranslations.pick(
                                lang,
                                en: 'e.g. Water shortage in Ward 12',
                                mr: 'उदा. प्रभाग 12 मध्ये पाण्याची टंचाई',
                                hi: 'उदा. वार्ड 12 में पानी की समस्या',
                              ),
                              lang,
                            ),
                            prefixIcon: const Icon(Icons.title_rounded, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. Description (Full Width)
                        AppFieldLabel(label: AppTranslations.pick(lang, en: 'Description', mr: 'वर्णन', hi: 'विवरण')),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: appInputDecoration(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Detailed description of the issue raised...',
                              mr: 'मांडलेल्या मुद्द्याचे सविस्तर वर्णन...',
                              hi: 'उठाए गए मुद्दे का विस्तृत विवरण...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Area & Beneficiaries (Side-by-Side)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Area', mr: 'क्षेत्र / भाग', hi: 'क्षेत्र / वार्ड')),
                                  TextField(
                                    controller: areaCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. Ward 12', mr: 'उदा. प्रभाग 12', hi: 'उदा. वार्ड 12'),
                                        lang,
                                      ),
                                      prefixIcon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFF64748B)),
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
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'People Benefited', mr: 'लाभार्थी', hi: 'लाभान्वित नागरिक')),
                                  TextField(
                                    controller: benCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.formatDigits(
                                        AppTranslations.pick(lang, en: 'e.g. 500+ residents', mr: 'उदा. 500+ नागरिक', hi: 'उदा. 500+ निवासी'),
                                        lang,
                                      ),
                                      prefixIcon: const Icon(Icons.people_outline_rounded, size: 18, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 5. Department & Outcome / Status (Side-by-Side)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(label: AppTranslations.pick(lang, en: 'Department', mr: 'विभाग', hi: 'विभाग')),
                                  TextField(
                                    controller: deptCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.pick(lang, en: 'e.g. Water Supply', mr: 'उदा. पाणी पुरवठा', hi: 'उदा. जल आपूर्ति'),
                                      prefixIcon: const Icon(Icons.business_outlined, size: 18, color: Color(0xFF64748B)),
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
                                  AppDropdownFormField<String>(
                                    label: AppTranslations.pick(lang, en: 'Outcome / Status', mr: 'निकाल / स्थिती', hi: 'परिणाम / स्थिति'),
                                    isRequired: true,
                                    value: statusList.contains(selectedStatus) ? selectedStatus : 'Raised',
                                    hintText: AppTranslations.pick(lang, en: 'Select Status', mr: 'स्थिती निवडा', hi: 'स्थिति चुनें'),
                                    items: statusList
                                        .map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(AppTranslations.getStatus(s, lang), style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedStatus = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 6. Administrative Response (Full Width)
                        AppFieldLabel(label: AppTranslations.pick(lang, en: 'Administrative Response', mr: 'प्रशासकीय उत्तर', hi: 'प्रशासनिक उत्तर')),
                        TextField(
                          controller: respCtrl,
                          maxLines: 2,
                          decoration: appInputDecoration(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Response received from administration...',
                              mr: 'प्रशासनाकडून मिळालेले उत्तर...',
                              hi: 'प्रशासन से प्राप्त उत्तर...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Button (Scrolls together with form)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                            onPressed: () async {
                              if (subjectCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(lang, en: 'Subject is required', mr: 'कृपया विषय प्रविष्ट करा', hi: 'विषय आवश्यक है'),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final updated = _currentEntry.copyWith(
                                meetingType: selectedMeetingType,
                                meetingDate: dateCtrl.text.trim().isNotEmpty ? dateCtrl.text.trim() : _currentEntry.meetingDate,
                                subject: subjectCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                department: deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : _currentEntry.department,
                                area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : _currentEntry.area,
                                status: selectedStatus,
                                beneficiaries: benCtrl.text.trim().isNotEmpty ? benCtrl.text.trim() : null,
                                response: respCtrl.text.trim().isNotEmpty ? respCtrl.text.trim() : null,
                              );

                              final repo = ref.read(gbRegisterRepoProvider);
                              await repo.updateEntry(updated);
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (mounted) {
                                setState(() => _currentEntry = updated);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'GB Register entry updated successfully',
                                        mr: 'नोंद यशस्वीरित्या अद्यतनित केली!',
                                        hi: 'जीबी प्रविष्टि सफलतापूर्वक अपडेट की गई!',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            label: Text(
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final entry = _currentEntry;

    final statusTabs = [
      {'key': 'Raised', 'label': AppTranslations.getStatus('Raised', lang)},
      {'key': 'In Discussion', 'label': AppTranslations.getStatus('In Discussion', lang)},
      {'key': 'Action Taken', 'label': AppTranslations.getStatus('Action Taken', lang)},
      {'key': 'Rejected', 'label': AppTranslations.getStatus('Rejected', lang)},
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
                AppTranslations.pick(lang, en: 'GB Motion Details', mr: 'महासभा ठराव तपशील', hi: 'महासभा प्रस्ताव विवरण'),
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
                AppTranslations.formatDigits('${_meetingTypeLabel(entry.meetingType, lang)} • ${AppTranslations.getAreaName(entry.area, lang)}', lang),
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
              tooltip: AppTranslations.pick(lang, en: 'Edit Entry', mr: 'नोंद संपादित करा', hi: 'प्रविष्टि संपादित करें'),
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: AppTranslations.pick(lang, en: 'Delete Entry', mr: 'नोंद हटवा', hi: 'प्रविष्टि हटाएँ'),
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
                    // Header card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                              // Meeting badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: entry.meetingTypeBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: entry.meetingTypeColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  lang == 'mr' ? entry.meetingTypeDisplayMr : _meetingTypeLabel(entry.meetingType, lang),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: entry.meetingTypeColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: entry.statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: entry.statusBorderColor),
                                ),
                                child: Text(
                                  AppTranslations.getStatus(entry.status, lang),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: entry.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AppTranslatedText(
                            entry.subject,
                            targetLanguage: lang,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.event_outlined, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                '${AppTranslations.pick(lang, en: "Meeting Date", mr: "सभेचा दिनांक", hi: "बैठक तिथि")}: ${_formatDate(entry.meetingDate, lang)}',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              if (entry.resolutionNo != null) ...[
                                const SizedBox(width: 14),
                                const Icon(Icons.bookmark_border_rounded, size: 16, color: Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                Text(
                                  AppTranslations.formatDigits(entry.resolutionNo!, lang),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick status change selector
                    Text(
                      AppTranslations.pick(lang, en: 'Update Motion Status', mr: 'सभेची स्थिती बदला', hi: 'प्रस्ताव स्थिति बदलें'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: statusTabs.map((tab) {
                          final isSelected = entry.status.toLowerCase() == tab['key']!.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => _handleQuickStatusChange(tab['key']!),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  tab['label']!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Motion description card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                              const Icon(Icons.description_outlined, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(lang, en: 'Motion Details & Public Demands', mr: 'सभेत मांडलेला तपशील', hi: 'प्रस्ताव विवरण और जन मांगें'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          entry.description.isNotEmpty
                              ? AppTranslatedText(
                                  entry.description,
                                  targetLanguage: lang,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF334155),
                                    height: 1.5,
                                  ),
                                )
                              : Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'No detailed motion description recorded.',
                                    mr: 'या सभेच्या विषयाबाबत विस्तृत नोंद उपलब्ध नाही.',
                                    hi: 'इस सभा विषय का विस्तृत विवरण दर्ज नहीं है।',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF334155),
                                    height: 1.5,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Official response card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: entry.response != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: entry.response != null ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                entry.response != null ? Icons.verified_rounded : Icons.pending_actions_rounded,
                                size: 20,
                                color: entry.response != null ? const Color(0xFF16A34A) : const Color(0xFFCA8A04),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Official Administration Reply',
                                    mr: 'प्रशासकीय अभिप्राय / कार्यवाही उत्तर',
                                    hi: 'आधिकारिक प्रशासनिक उत्तर',
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: entry.response != null ? const Color(0xFF14532D) : const Color(0xFF713F12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          if (entry.response != null) ...[
                            AppTranslatedText(
                              entry.response!,
                              targetLanguage: lang,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF166534),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (entry.resolutionNo != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                AppTranslations.formatDigits(
                                  '${AppTranslations.pick(lang, en: "Resolution Ref", mr: "ठराव संदर्भ", hi: "प्रस्ताव संदर्भ")}: ${entry.resolutionNo}',
                                  lang,
                                ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                              ),
                            ],
                          ] else ...[
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Awaiting formal reply on the assembly floor from Municipal Administration.',
                                mr: 'या प्रश्नावर अजून मनपा प्रशासनाकडून औपचारिक उत्तर आलेले नाही.',
                                hi: 'नगर निगम प्रशासन से औपचारिक उत्तर की प्रतीक्षा है।',
                              ),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Information details grid
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(lang, en: 'Administrative Context', mr: 'विभागीय आणि स्थानिक माहिती', hi: 'विभागीय एवं स्थानीय जानकारी'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Divider(height: 20),
                          _infoRow(
                            icon: Icons.business_rounded,
                            label: AppTranslations.pick(lang, en: 'Department', mr: 'खाते / विभाग', hi: 'विभाग'),
                            value: entry.department,
                            lang: lang,
                            translate: true,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.location_on_outlined,
                            label: AppTranslations.pick(lang, en: 'Area / Prabhag', mr: 'परिसर / प्रभाग', hi: 'क्षेत्र / वार्ड'),
                            value: entry.area.isNotEmpty
                                ? entry.area
                                : AppTranslations.pick(lang, en: 'Entire Prabhag', mr: 'सर्व प्रभाग', hi: 'संपूर्ण वार्ड'),
                            lang: lang,
                            translate: entry.area.isNotEmpty,
                          ),
                          if (entry.beneficiaries != null) ...[
                            const SizedBox(height: 12),
                            _infoRow(
                              icon: Icons.people_outline_rounded,
                              label: AppTranslations.pick(lang, en: 'Beneficiaries Impacted', mr: 'प्रभावित लाभार्थी', hi: 'लाभान्वित नागरिक'),
                              value: entry.beneficiaries!,
                              lang: lang,
                              translate: true,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.access_time_rounded,
                            label: AppTranslations.pick(lang, en: 'Recorded At', mr: 'नोंदणी तारीख', hi: 'दर्ज तिथि'),
                            value: _formatDate(entry.createdAt.isNotEmpty ? entry.createdAt : entry.meetingDate, lang),
                            lang: lang,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    if (entry.tags.isNotEmpty) ...[
                      Text(
                        AppTranslations.pick(lang, en: 'Tags', mr: 'विषय टॅग्ज', hi: 'विषय टैग'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.tags.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: AppTranslatedText(
                              '#$t',
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
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
