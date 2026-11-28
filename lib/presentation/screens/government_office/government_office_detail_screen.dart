import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/government_office_model.dart';
import '../../../data/repositories/government_office_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';

class GovernmentOfficeDetailScreen extends ConsumerStatefulWidget {
  final GovernmentOfficeModel office;

  const GovernmentOfficeDetailScreen({super.key, required this.office});

  @override
  ConsumerState<GovernmentOfficeDetailScreen> createState() => _GovernmentOfficeDetailScreenState();
}

class _GovernmentOfficeDetailScreenState extends ConsumerState<GovernmentOfficeDetailScreen> {
  late GovernmentOfficeModel _currentOffice;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentOffice = widget.office;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final lang = ref.read(appLanguageProvider);
    final cleanNumber = AppTranslations.normalizeAsciiDigits(phoneNumber)
        .replaceAll(RegExp(r'[^0-9+]'), '');
    final formattedNum = AppTranslations.formatDigits(phoneNumber, lang);
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Could not initiate call to $formattedNum',
                  mr: '$formattedNum वर कॉल करता आला नाही',
                  hi: '$formattedNum पर कॉल नहीं किया जा सका',
                ),
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Calling $formattedNum',
                mr: '$formattedNum वर कॉल करत आहे',
                hi: '$formattedNum पर कॉल कर रहे हैं',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openMaps() async {
    final lang = ref.read(appLanguageProvider);
    final query = Uri.encodeComponent('${_currentOffice.name}, ${_currentOffice.address}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Could not open map navigation',
                  mr: 'नकाशा नेव्हिगेशन उघडता आले नाही',
                  hi: 'मानचित्र नेविगेशन नहीं खुल सका',
                ),
              ),
            ),
          );
        }
      }
    } catch (_) {
      // Fallback
    }
  }

  void _showDeleteConfirmation() {
    final lang = ref.read(appLanguageProvider);
    final displayName =
        DynamicTranslationService.getCachedTranslation(_currentOffice.name, lang) ??
            _currentOffice.name;
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
                AppTranslations.pick(
                  lang,
                  en: 'Delete Government Office',
                  mr: 'सरकारी कार्यालय हटवा',
                  hi: 'सरकारी कार्यालय हटाएं',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to remove "$displayName" from the civic directory? This action cannot be undone.',
            mr: 'तुम्हाला "$displayName" हे नागरी निर्देशिकेतून नक्की काढायचे आहे का? ही कृती पूर्ववत करता येणार नाही.',
            hi: 'क्या आप वाकई "$displayName" को नागरिक निर्देशिका से हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
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
              final repo = ref.read(governmentOfficeRepoProvider);
              await repo.deleteOffice(_currentOffice.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Office entry deleted successfully',
                        mr: 'कार्यालयाची नोंद यशस्वीरित्या हटवली',
                        hi: 'कार्यालय प्रविष्टि सफलतापूर्वक हटाई गई',
                      ),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            child: Text(
              AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditModal() {
    final lang = ref.read(appLanguageProvider);
    final nameCtrl = TextEditingController(text: _currentOffice.name);
    final addrCtrl = TextEditingController(text: _currentOffice.address);
    final officerCtrl = TextEditingController(text: _currentOffice.officerName);
    final phoneCtrl = TextEditingController(
      text: AppTranslations.formatDigits(_currentOffice.contactNumber, lang),
    );
    final areaCtrl = TextEditingController(text: _currentOffice.area);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
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
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  AppModalHeader(
                    icon: Icons.edit_note_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Edit Government Office',
                      mr: 'सरकारी कार्यालय बदला',
                      hi: 'सरकारी कार्यालय संपादित करें',
                    ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Update government office details',
                      mr: 'शासकीय कार्यालयाचे तपशील अद्यतनित करा',
                      hi: 'सरकारी कार्यालय का विवरण अपडेट करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        top: 16,
                        left: 18,
                        right: 18,
                        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                      ),
                      children: [
                        // 1. Office Name (Full Width)
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Office Name',
                            mr: 'कार्यालयाचे नाव',
                            hi: 'कार्यालय का नाम',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: nameCtrl,
                          decoration: appInputDecoration(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'e.g. PMC Ward Office No. 12',
                              mr: 'उदा. प्रभाग कार्यालय क्र. १२',
                              hi: 'उदा. वार्ड कार्यालय क्र. १२',
                            ),
                            prefixIcon: const Icon(Icons.apartment_rounded, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. Address (Full Width)
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Address',
                            mr: 'पत्ता',
                            hi: 'पता',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: addrCtrl,
                          maxLines: 2,
                          decoration: appInputDecoration(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'e.g. Near Shaniwar Wada, Pune - 411030',
                              mr: 'उदा. शनिवार वाड्यासमोर, पुणे - ४११०३०',
                              hi: 'उदा. शनिवार वाड़ा के पास, पुणे - ४११०३०',
                            ),
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3 & 4. Officer In-Charge + Contact Number (Side-by-Side)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Officer In-charge',
                                      mr: 'अधिकारी / प्रमुख',
                                      hi: 'प्रभारी अधिकारी',
                                    ),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: officerCtrl,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. Shri. Ramesh Gaikwad',
                                        mr: 'उदा. श्री. रमेश गायकवाड',
                                        hi: 'उदा. श्री रमेश गायकवाड़',
                                      ),
                                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
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
                                      en: 'Contact',
                                      mr: 'संपर्क',
                                      hi: 'संपर्क नंबर',
                                    ),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: appInputDecoration(
                                      hint: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. 020-25501140',
                                        mr: 'उदा. ०२०-२५५०११४०',
                                        hi: 'उदा. ०२०-२५५०११४०',
                                      ),
                                      prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 5. Location / Area (Full Width)
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Location / Area',
                            mr: 'ठिकाण',
                            hi: 'स्थान / क्षेत्र',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: areaCtrl,
                          decoration: appInputDecoration(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'e.g. Shaniwar Peth',
                              mr: 'उदा. शनिवार पेठ',
                              hi: 'उदा. शनिवार पेठ',
                            ),
                            prefixIcon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.business_rounded, size: 18),
                            onPressed: () async {
                              final cleanPhone =
                                  AppTranslations.normalizeAsciiDigits(phoneCtrl.text.trim());
                              if (nameCtrl.text.trim().isEmpty || cleanPhone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Please fill required fields',
                                        mr: 'कृपया सर्व आवश्यक माहिती भरा',
                                        hi: 'कृपया सभी आवश्यक फ़ील्ड भरें',
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final updated = _currentOffice.copyWith(
                                name: nameCtrl.text.trim(),
                                address: addrCtrl.text.trim(),
                                officerName: officerCtrl.text.trim().isNotEmpty
                                    ? officerCtrl.text.trim()
                                    : _currentOffice.officerName,
                                contactNumber: cleanPhone,
                                area: areaCtrl.text.trim().isNotEmpty
                                    ? areaCtrl.text.trim()
                                    : _currentOffice.area,
                              );

                              final repo = ref.read(governmentOfficeRepoProvider);
                              await repo.updateOffice(updated);

                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (mounted) {
                                setState(() => _currentOffice = updated);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Office details updated successfully!',
                                        mr: 'कार्यालय माहिती यशस्वीरित्या अद्यतनित केली!',
                                        hi: 'कार्यालय विवरण सफलतापूर्वक अपडेट किया गया!',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            label: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Save Office',
                                mr: 'कार्यालय जतन करा',
                                hi: 'कार्यालय सहेजें',
                              ),
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
    final office = _currentOffice;

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
            tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'वापस'),
            onPressed: () => Navigator.pop(context, true),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Office Details',
                  mr: 'कार्यालय तपशील',
                  hi: 'कार्यालय विवरण',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              AppTranslatedText(
                '${office.categoryDisplay(lang)} • ${AppTranslations.getAreaName(office.area, lang)}',
                targetLanguage: lang,
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
              tooltip: AppTranslations.pick(
                lang,
                en: 'Edit Office',
                mr: 'कार्यालय संपादित करा',
                hi: 'कार्यालय संपादित करें',
              ),
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Delete Office',
                mr: 'कार्यालय हटवा',
                hi: 'कार्यालय हटाएं',
              ),
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
                    // Main Office Card
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
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: office.categoryBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(office.categoryIcon, size: 24, color: office.categoryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: office.categoryBgColor,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: office.categoryColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            office.categoryDisplay(lang),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: office.categoryColor,
                                            ),
                                          ),
                                        ),
                                        if (office.isEmergency)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFECACA)),
                                            ),
                                            child: Text(
                                              AppTranslations.pick(
                                                lang,
                                                en: '24x7 Helpline',
                                                mr: '२४x७ हेल्पलाईन',
                                                hi: '२४x७ हेल्पलाइन',
                                              ),
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    AppTranslatedText(
                                      office.name,
                                      targetLanguage: lang,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Direct Quick Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.phone_forwarded_rounded, size: 18),
                                  label: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Call Now',
                                      mr: 'कॉल करा',
                                      hi: 'कॉल करें',
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  onPressed: () => _makePhoneCall(office.contactNumber),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0284C7),
                                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.directions_outlined, size: 18),
                                  label: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Directions',
                                      mr: 'नकाशा / मार्ग',
                                      hi: 'दिशा-निर्देश',
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  onPressed: _openMaps,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Officer In-Charge Card
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
                              const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Officer In-Charge',
                                    mr: 'कार्यालय प्रमुख / जबाबदार अधिकारी',
                                    hi: 'कार्यालय प्रमुख / प्रभारी अधिकारी',
                                  ),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          AppTranslatedText(
                            office.officerName,
                            isName: true,
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.phone_in_talk_outlined, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                AppTranslations.formatDigits(office.contactNumber, lang),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                                tooltip: AppTranslations.pick(
                                  lang,
                                  en: 'Copy Phone',
                                  mr: 'संपर्क कॉपी करा',
                                  hi: 'फ़ोन कॉपी करें',
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: office.contactNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Contact copied to clipboard',
                                          mr: 'संपर्क क्रमांक कॉपी केला',
                                          hi: 'संपर्क नंबर क्लिपबोर्ड पर कॉपी किया गया',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (office.secondaryContact != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.support_agent_rounded, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${AppTranslations.pick(lang, en: "Alternate Helpline", mr: "पर्यायी / हेल्पलाईन", hi: "वैकल्पिक हेल्पलाइन")}: ${AppTranslations.formatDigits(office.secondaryContact!, lang)}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timings and Working Hours Card
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
                              const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Working Hours & Communication',
                                    mr: 'कामकाजाची वेळ व संपर्क',
                                    hi: 'कार्य समय एवं संपर्क',
                                  ),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _infoRow(
                            icon: Icons.schedule_rounded,
                            label: AppTranslations.pick(
                              lang,
                              en: 'Hours',
                              mr: 'कार्यालयीन वेळ',
                              hi: 'कार्यालय समय',
                            ),
                            value: AppTranslations.formatDigits(office.timing, lang),
                            lang: lang,
                            translateValue: true,
                          ),
                          if (office.email != null) ...[
                            const SizedBox(height: 12),
                            _infoRow(
                              icon: Icons.alternate_email_rounded,
                              label: AppTranslations.pick(
                                lang,
                                en: 'Email Address',
                                mr: 'अधिकृत ईमेल',
                                hi: 'आधिकारिक ईमेल',
                              ),
                              value: office.email!,
                              lang: lang,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address & Location Card
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
                              const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Location & Address',
                                    mr: 'पत्ता आणि परिसर',
                                    hi: 'स्थान और पता',
                                  ),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          AppTranslatedText(
                            office.address,
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.pin_drop_rounded, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: AppTranslatedText(
                                  '${AppTranslations.pick(lang, en: "Prabhag Area", mr: "प्रभाग क्षेत्र", hi: "प्रभाग क्षेत्र")}: ${AppTranslations.getAreaName(office.area, lang)}',
                                  targetLanguage: lang,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                icon: const Icon(Icons.content_copy_rounded, size: 14),
                                label: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Copy Address',
                                    mr: 'पत्ता कॉपी करा',
                                    hi: 'पता कॉपी करें',
                                  ),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: office.address));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Address copied to clipboard',
                                          mr: 'पत्ता कॉपी केला',
                                          hi: 'पता क्लिपबोर्ड पर कॉपी किया गया',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
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

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required String lang,
    bool translateValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: translateValue
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
}

