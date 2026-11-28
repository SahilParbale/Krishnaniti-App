import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/social_organization_model.dart';
import '../../../data/repositories/social_organization_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pagination_bar.dart';

class SocialOrgDetailScreen extends ConsumerStatefulWidget {
  final SocialOrganizationModel organization;

  const SocialOrgDetailScreen({super.key, required this.organization});

  @override
  ConsumerState<SocialOrgDetailScreen> createState() => _SocialOrgDetailScreenState();
}

class _SocialOrgDetailScreenState extends ConsumerState<SocialOrgDetailScreen> {
  late SocialOrganizationModel _org;
  int _eventsPage = 1;
  static const int _eventsPageSize = 5;

  @override
  void initState() {
    super.initState();
    _org = widget.organization;
  }

  String _pickOrgName(SocialOrganizationModel org, String lang) {
    if (lang == 'en') {
      if (org.nameEnglish != null && org.nameEnglish!.trim().isNotEmpty) {
        return org.nameEnglish!.trim();
      }
      return org.name.trim();
    }
    if (org.nameMarathi != null && org.nameMarathi!.trim().isNotEmpty) {
      return org.nameMarathi!.trim();
    }
    if (org.nameEnglish != null && org.nameEnglish!.trim().isNotEmpty) {
      return org.nameEnglish!.trim();
    }
    return org.name.trim();
  }

  String _pickOrgTypeLabel(String type, String lang) {
    switch (type) {
      case 'ngo':
        return AppTranslations.pick(
          lang,
          en: 'NGO / Social Foundation',
          mr: 'एन.जी.ओ / सामाजिक संस्था',
          hi: 'एनजीओ / सामाजिक संस्था',
        );
      case 'sports_cricket':
        return AppTranslations.pick(
          lang,
          en: 'Cricket & Sports Club',
          mr: 'क्रीडा व क्रिकेट क्लब',
          hi: 'क्रिकेट एवं स्पोर्ट्स क्लब',
        );
      case 'ganpati_mandal':
        return AppTranslations.pick(
          lang,
          en: 'Ganpati Mandal',
          mr: 'गणपती मंडळ',
          hi: 'गणपति मंडल',
        );
      case 'navratri_mandal':
        return AppTranslations.pick(
          lang,
          en: 'Navratri Mandal',
          mr: 'नवरात्रौत्सव मंडळ',
          hi: 'नवरात्रोत्सव मंडल',
        );
      default:
        return AppTranslations.pick(
          lang,
          en: 'Other Organization',
          mr: 'इतर संस्था व मंडळ',
          hi: 'अन्य संगठन एवं मंडल',
        );
    }
  }

  String _pickEventTitle(SocialOrgEventModel evt, String lang) {
    if (lang == 'en') {
      return evt.title.trim().isNotEmpty ? evt.title.trim() : (evt.titleMr?.trim() ?? '');
    }
    return (evt.titleMr != null && evt.titleMr!.trim().isNotEmpty)
        ? evt.titleMr!.trim()
        : evt.title.trim();
  }

  String _pickEventDescription(SocialOrgEventModel evt, String lang) {
    if (lang == 'en') {
      return evt.description.trim().isNotEmpty
          ? evt.description.trim()
          : (evt.descriptionMr?.trim() ?? '');
    }
    return (evt.descriptionMr != null && evt.descriptionMr!.trim().isNotEmpty)
        ? evt.descriptionMr!.trim()
        : evt.description.trim();
  }

  Future<void> _refreshOrg() async {
    final repo = ref.read(socialOrgRepoProvider);
    final orgs = await repo.getOrganizations();
    final updated = orgs.where((o) => o.id == _org.id).firstOrNull;
    if (updated != null && mounted) {
      setState(() {
        _org = updated;
        final totalPages = (_org.eventsConducted.length / _eventsPageSize).ceil().clamp(1, 9999);
        if (_eventsPage > totalPages) _eventsPage = totalPages;
      });
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final clean = AppTranslations.normalizeAsciiDigits(phone).replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    var clean = AppTranslations.normalizeAsciiDigits(phone).replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) clean = '91$clean';
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text) {
    final lang = ref.read(appLanguageProvider);
    final clean = AppTranslations.normalizeAsciiDigits(text);
    Clipboard.setData(ClipboardData(text: clean));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Mobile number copied!',
            mr: 'मोबाईल क्रमांक कॉपी केला!',
            hi: 'मोबाइल नंबर कॉपी किया गया!',
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, dynamic> _getTheme(String type) {
    switch (type) {
      case 'ngo':
        return {
          'color': const Color(0xFF0284C7),
          'bg': const Color(0xFFF0F9FF),
          'border': const Color(0xFFBAE6FD),
          'icon': Icons.apartment_rounded,
        };
      case 'sports_cricket':
        return {
          'color': const Color(0xFF059669),
          'bg': const Color(0xFFECFDF5),
          'border': const Color(0xFFA7F3D0),
          'icon': Icons.sports_cricket_rounded,
        };
      case 'ganpati_mandal':
        return {
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFFFBEB),
          'border': const Color(0xFFFDE68A),
          'icon': Icons.auto_awesome_rounded,
        };
      case 'navratri_mandal':
        return {
          'color': const Color(0xFFE11D48),
          'bg': const Color(0xFFFFF1F2),
          'border': const Color(0xFFFECDD3),
          'icon': Icons.festival_rounded,
        };
      default:
        return {
          'color': const Color(0xFF64748B),
          'bg': const Color(0xFFF8FAFC),
          'border': const Color(0xFFE2E8F0),
          'icon': Icons.groups_rounded,
        };
    }
  }

  // ===========================================================================
  // ADD EVENT BOTTOM SHEET
  // ===========================================================================
  void _showAddEventModal() {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: DateTime.now().year.toString());
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.70,
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
              icon: Icons.event_available_rounded,
              title: AppTranslations.pick(
                lang,
                en: 'Add New Event / Activity',
                mr: 'नवीन कार्यक्रम / उपक्रम जोडा',
                hi: 'नया कार्यक्रम / गतिविधि जोड़ें',
              ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Record organization event or activity',
                mr: 'मंडळाचा उपक्रम किंवा कार्यक्रम नोंदवा',
                hi: 'संगठन का कार्यक्रम या गतिविधि दर्ज करें',
              ),
              onClose: () => Navigator.pop(ctx),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                children: [
                  // Event Title & Year side-by-side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppFieldLabel(
                              label: AppTranslations.pick(
                                lang,
                                en: 'Event Name',
                                mr: 'कार्यक्रमाचे नाव',
                                hi: 'कार्यक्रम का नाम',
                              ),
                              isRequired: true,
                            ),
                            TextField(
                              controller: titleCtrl,
                              decoration: appInputDecoration(
                                hint: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Free Health Camp, Dahi Handi',
                                  mr: 'उदा. मोफत आरोग्य शिबीर, शिवजयंती',
                                  hi: 'उदा. मुफ्त स्वास्थ्य शिविर, दही हांडी',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppFieldLabel(
                              label: AppTranslations.pick(lang, en: 'Year', mr: 'वर्ष', hi: 'वर्ष'),
                              isRequired: true,
                            ),
                            TextField(
                              controller: yearCtrl,
                              keyboardType: TextInputType.number,
                              decoration: appInputDecoration(
                                hint: AppTranslations.formatDigits('2026', lang),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description
                  AppFieldLabel(
                    label: AppTranslations.pick(
                      lang,
                      en: 'Detailed Event Notes',
                      mr: 'तपशीलवार माहिती व योगदान',
                      hi: 'विस्तृत कार्यक्रम नोट्स',
                    ),
                  ),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: appInputDecoration(
                      hint: AppTranslations.pick(
                        lang,
                        en: 'Participants, chief guests, awards, and social impact...',
                        mr: 'सहभागी, प्रमुख पाहुणे, पुरस्कार व सामाजिक प्रभाव...',
                        hi: 'प्रतिभागी, मुख्य अतिथि, पुरस्कार और सामाजिक प्रभाव...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Please enter event name.',
                                  mr: 'कृपया कार्यक्रमाचे नाव टाका.',
                                  hi: 'कृपया कार्यक्रम का नाम दर्ज करें।',
                                ),
                              ),
                            ),
                          );
                          return;
                        }

                        final newEvent = SocialOrgEventModel(
                          id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
                          title: titleCtrl.text.trim(),
                          titleMr: titleCtrl.text.trim(),
                          year: int.tryParse(AppTranslations.normalizeAsciiDigits(yearCtrl.text.trim())) ?? DateTime.now().year,
                          description: descCtrl.text.trim(),
                          descriptionMr: descCtrl.text.trim(),
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        final repo = ref.read(socialOrgRepoProvider);
                        await repo.addEvent(_org.id, newEvent);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (!mounted) return;
                        _refreshOrg();

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Event added successfully!',
                                mr: 'कार्यक्रम यशस्वीरित्या जोडला!',
                                hi: 'कार्यक्रम सफलतापूर्वक जोड़ा गया!',
                              ),
                            ),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Save Event',
                          mr: 'कार्यक्रम जतन करा',
                          hi: 'कार्यक्रम सहेजें',
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
      ),
    );
  }

  // ===========================================================================
  // EDIT ORGANIZATION MODAL
  // ===========================================================================
  void _showEditOrgModal() {
    final lang = ref.read(appLanguageProvider);
    final nameMrCtrl = TextEditingController(text: _org.nameMarathi ?? _org.name);
    final nameEnCtrl = TextEditingController(text: _org.nameEnglish ?? _org.name);
    String type = _org.type;
    final presNameCtrl = TextEditingController(text: _org.presidentName);
    final presPhoneCtrl = TextEditingController(text: _org.presidentMobile);
    final membersCtrl = TextEditingController(text: _org.membersCount > 0 ? _org.membersCount.toString() : '');
    final areaCtrl = TextEditingController(text: _org.area);
    final estCtrl = TextEditingController(text: _org.establishedYear);
    final supportCtrl = TextEditingController(text: _org.supportReceived);
    final descCtrl = TextEditingController(text: _org.description);
    String status = _org.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.90,
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
                icon: Icons.apartment_rounded,
                title: AppTranslations.pick(
                  lang,
                  en: 'Edit Organization Details',
                  mr: 'संस्थेची माहिती सुधारा',
                  hi: 'संगठन विवरण संपादित करें',
                ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Update organization details and office bearers',
                  mr: 'मंडळाची माहिती व पदाधिकारी तपशील अद्यतनित करा',
                  hi: 'संगठन विवरण और पदाधिकारियों की जानकारी अपडेट करें',
                ),
                onClose: () => Navigator.pop(ctx),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  children: [
                    // Name Marathi & Name English side-by-side
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
                                  en: 'Organization Name (Marathi)',
                                  mr: 'संस्थेचे नाव (मराठी)',
                                  hi: 'संगठन का नाम (मराठी)',
                                ),
                                isRequired: true,
                              ),
                              TextField(
                                controller: nameMrCtrl,
                                decoration: appInputDecoration(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Bal Ganesh Mandal',
                                    mr: 'उदा. बाळ गणेश मंडळ',
                                    hi: 'उदा. बाल गणेश मंडल',
                                  ),
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
                              AppFieldLabel(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Organization Name (English)',
                                  mr: 'संस्थेचे नाव (इंग्रजी)',
                                  hi: 'संगठन का नाम (अंग्रेजी)',
                                ),
                              ),
                              TextField(
                                controller: nameEnCtrl,
                                decoration: appInputDecoration(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Bal Ganesh Mandal',
                                    mr: 'उदा. Bal Ganesh Mandal',
                                    hi: 'उदा. Bal Ganesh Mandal',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Organization Type & Status side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppDropdownFormField<String>(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Organization Type',
                                  mr: 'संस्थेचा प्रकार',
                                  hi: 'संगठन का प्रकार',
                                ),
                                isRequired: true,
                                value: type,
                                items: [
                                  DropdownMenuItem(
                                    value: 'ganpati_mandal',
                                    child: Text(AppTranslations.pick(lang, en: 'Ganesh Mandal', mr: 'गणेश मंडळ', hi: 'गणेश मंडल')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'navratri_mandal',
                                    child: Text(AppTranslations.pick(lang, en: 'Navratri Mandal', mr: 'नवरात्र मंडळ', hi: 'नवरात्र मंडल')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sports_cricket',
                                    child: Text(AppTranslations.pick(lang, en: 'Cricket / Sports', mr: 'क्रीडा क्लब', hi: 'क्रिकेट / खेल क्लब')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ngo',
                                    child: Text(AppTranslations.pick(lang, en: 'NGO / Trust', mr: 'एन.जी.ओ / ट्रस्ट', hi: 'एनजीओ / ट्रस्ट')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'other',
                                    child: Text(AppTranslations.pick(lang, en: 'Other Mandals', mr: 'इतर मंडळ', hi: 'अन्य मंडल')),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => type = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppDropdownFormField<String>(
                                label: AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                                value: status,
                                items: [
                                  DropdownMenuItem(
                                    value: 'Active',
                                    child: Text(AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Inactive',
                                    child: Text(AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय')),
                                  ),
                                ],
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

                    // President Name & Mobile (+91) side-by-side
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
                                  en: 'President Name',
                                  mr: 'प्रमुख व्यक्ती / अध्यक्ष नाव',
                                  hi: 'अध्यक्ष का नाम',
                                ),
                                isRequired: true,
                              ),
                              TextField(
                                controller: presNameCtrl,
                                decoration: appInputDecoration(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Ganesh Jadhav',
                                    mr: 'उदा. गणेश जाधव',
                                    hi: 'उदा. गणेश जाधव',
                                  ),
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
                              AppFieldLabel(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Mobile (+91)',
                                  mr: 'मोबाईल नंबर (+९१)',
                                  hi: 'मोबाइल नंबर (+९१)',
                                ),
                                isRequired: true,
                              ),
                              TextField(
                                controller: presPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                decoration: appInputDecoration(
                                  prefixText: AppTranslations.formatDigits('+91 ', lang),
                                  hint: AppTranslations.formatDigits('98221xxxxx', lang),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Total Members & Established Year side-by-side
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
                                  en: 'Total Members (Approx)',
                                  mr: 'सदस्य संख्या (अंदाजे)',
                                  hi: 'कुल सदस्य (अनुमानित)',
                                ),
                              ),
                              TextField(
                                controller: membersCtrl,
                                keyboardType: TextInputType.number,
                                decoration: appInputDecoration(
                                  hint: AppTranslations.formatDigits('50', lang),
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
                              AppFieldLabel(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Established Year',
                                  mr: 'स्थापना वर्ष',
                                  hi: 'स्थापना वर्ष',
                                ),
                              ),
                              TextField(
                                controller: estCtrl,
                                keyboardType: TextInputType.number,
                                decoration: appInputDecoration(
                                  hint: AppTranslations.formatDigits('2015', lang),
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
                      label: AppTranslations.pick(
                        lang,
                        en: 'Area / Vicinity',
                        mr: 'परिसर / प्रभाग क्षेत्र',
                        hi: 'क्षेत्र / मोहल्ला',
                      ),
                      isRequired: true,
                    ),
                    TextField(
                      controller: areaCtrl,
                      decoration: appInputDecoration(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'e.g. Sector 3, Main Chowk',
                          mr: 'उदा. सेक्टर ३, मुख्य चौक',
                          hi: 'उदा. सेक्टर ३, मुख्य चौक',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nagarsevak Support Received Notes
                    AppFieldLabel(
                      label: AppTranslations.pick(
                        lang,
                        en: 'Corporator Support & Sponsorship History',
                        mr: 'आपल्या वतीने मिळालेली मदत / प्रायोजकत्व',
                        hi: 'नगरसेवक सहायता एवं प्रायोजन इतिहास',
                      ),
                    ),
                    TextField(
                      controller: supportCtrl,
                      maxLines: 2,
                      decoration: appInputDecoration(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'e.g. Stage setup, sound permissions, trophy sponsorship...',
                          mr: 'उदा. स्टेज उभारणी, साऊंड परवानगी, चषक प्रायोजकत्व...',
                          hi: 'उदा. मंच व्यवस्था, साउंड अनुमति, ट्रॉफी प्रायोजन...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    AppFieldLabel(
                      label: AppTranslations.pick(
                        lang,
                        en: 'About Organization & Objectives',
                        mr: 'संस्थेबद्दल माहिती व उद्दिष्टे',
                        hi: 'संगठन के बारे में और उद्देश्य',
                      ),
                    ),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: appInputDecoration(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'Social initiatives, community outreach & contributions...',
                          mr: 'सामाजिक उपक्रम, समाजकार्य व योगदान...',
                          hi: 'सामाजिक पहल, सामुदायिक सेवा और योगदान...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : nameEnCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Please enter organization name.',
                                    mr: 'कृपया संस्थेचे नाव टाका.',
                                    hi: 'कृपया संगठन का नाम दर्ज करें।',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          final updated = _org.copyWith(
                            name: name,
                            nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : name,
                            nameEnglish: nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : name,
                            type: type,
                            presidentName: presNameCtrl.text.trim(),
                            presidentMobile: AppTranslations.normalizeAsciiDigits(presPhoneCtrl.text.trim()),
                            membersCount: int.tryParse(AppTranslations.normalizeAsciiDigits(membersCtrl.text.trim())) ?? 0,
                            area: areaCtrl.text.trim(),
                            establishedYear: AppTranslations.normalizeAsciiDigits(estCtrl.text.trim()),
                            supportReceived: supportCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            status: status,
                          );

                          final messenger = ScaffoldMessenger.of(context);
                          final repo = ref.read(socialOrgRepoProvider);
                          await repo.updateOrganization(updated);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (!mounted) return;
                          _refreshOrg();

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Details updated!',
                                  mr: 'माहिती अद्यतनित केली!',
                                  hi: 'विवरण अपडेट किया गया!',
                                ),
                              ),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'बदलाव सहेजें'),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final theme = _getTheme(_org.type);
    final repo = ref.read(socialOrgRepoProvider);
    final isActive = _org.status == 'Active';
    final statusLabel = isActive
        ? AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय')
        : AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: AppTranslatedText(
          _pickOrgName(_org, lang),
          isName: true,
          targetLanguage: lang,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: _showEditOrgModal,
            tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
          ),
          if (_org.presidentMobile.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.phone_rounded, color: Colors.white),
              onPressed: () => _makePhoneCall(_org.presidentMobile),
              tooltip: AppTranslations.pick(lang, en: 'Call', mr: 'कॉल', hi: 'कॉल'),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
              onPressed: () => _openWhatsApp(_org.presidentMobile),
              tooltip: AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सॲप', hi: 'व्हाट्सएप'),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrg,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. ORGANIZATION HERO CARD
              // ==========================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme['border'] as Color),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: (theme['color'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: (theme['color'] as Color).withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Icon(
                              theme['icon'] as IconData,
                              color: theme['color'] as Color,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name & Badges
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTranslatedText(
                                _pickOrgName(_org, lang),
                                isName: true,
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (theme['color'] as Color).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: (theme['color'] as Color).withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      _pickOrgTypeLabel(_org.type, lang),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme['color'] as Color),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? const Color(0xFF047857) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_org.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      AppTranslatedText(
                        _org.description,
                        prefix: '"',
                        suffix: '"',
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Color(0xFF64748B), height: 1.4),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Key Details 2x2 Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.pick(lang, en: 'President', mr: 'अध्यक्ष', hi: 'अध्यक्ष'),
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    _org.presidentName.isNotEmpty
                                        ? AppTranslatedText(
                                            _org.presidentName,
                                            isName: true,
                                            targetLanguage: lang,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                          )
                                        : const Text(
                                            '-',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                          ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'),
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    if (_org.presidentMobile.isNotEmpty)
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () => _makePhoneCall(_org.presidentMobile),
                                            child: Text(
                                              AppTranslations.formatDigits(_org.presidentMobile, lang),
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () => _copyToClipboard(_org.presidentMobile),
                                            child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      )
                                    else
                                      const Text('-', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.pick(lang, en: 'Total Members', mr: 'एकूण सदस्य', hi: 'कुल सदस्य'),
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: '${AppTranslations.formatDigits(_org.membersCount, lang)} Members',
                                        mr: '${AppTranslations.formatDigits(_org.membersCount, lang)} सदस्य',
                                        hi: '${AppTranslations.formatDigits(_org.membersCount, lang)} सदस्य',
                                      ),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.pick(lang, en: 'Established Year', mr: 'स्थापना वर्ष', hi: 'स्थापना वर्ष'),
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _org.establishedYear.isNotEmpty
                                          ? AppTranslations.formatDigits(_org.establishedYear, lang)
                                          : '-',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Area Row
                    if (_org.area.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: AppTranslatedText(
                              AppTranslations.getAreaName(_org.area, lang),
                              prefix: AppTranslations.pick(lang, en: 'Area: ', mr: 'परिसर: ', hi: 'क्षेत्र: '),
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ==========================================
              // 2. NAGARSEVAK SUPPORT & SPONSORSHIP HISTORY
              // ==========================================
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 20, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Corporator Support & Sponsorship History',
                              mr: 'नगरसेवक मदत व प्रायोजकत्व नोंद',
                              hi: 'नगरसेवक सहायता एवं प्रायोजन इतिहास',
                            ),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_org.supportReceived.isNotEmpty)
                      AppTranslatedText(
                        _org.supportReceived,
                        targetLanguage: lang,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4C1D95),
                          height: 1.4,
                        ),
                      )
                    else
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No official support recorded for this organization yet.',
                          mr: 'या संस्थेसाठी अद्याप कोणतीही अधिकृत मदत नोंदवलेली नाही.',
                          hi: 'इस संगठन के लिए अभी तक कोई आधिकारिक सहायता दर्ज नहीं की गई है।',
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),

              // ==========================================
              // 3. KEY EVENTS & FESTIVALS SECTION
              // ==========================================
              const SizedBox(height: 16),
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              const Icon(Icons.event_available_rounded, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Key Events & Activities (${AppTranslations.formatDigits(_org.eventsConducted.length, lang)})',
                                    mr: 'प्रमुख उपक्रम व कार्यक्रम (${AppTranslations.formatDigits(_org.eventsConducted.length, lang)})',
                                    hi: 'प्रमुख कार्यक्रम और गतिविधियां (${AppTranslations.formatDigits(_org.eventsConducted.length, lang)})',
                                  ),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showAddEventModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 14, color: Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Add Event',
                                    mr: 'कार्यक्रम जोडा',
                                    hi: 'कार्यक्रम जोड़ें',
                                  ),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_org.eventsConducted.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'No events recorded for this organization yet.\nClick "+ Add Event" to add festivals or sports tournaments.',
                            mr: 'या संस्थेसाठी अद्याप कोणतेही कार्यक्रम नोंदवलेले नाहीत.\nउत्सव किंवा क्रीडा स्पर्धा जोडण्यासाठी "+ कार्यक्रम जोडा" वर क्लिक करा.',
                            hi: 'इस संगठन के लिए अभी तक कोई कार्यक्रम दर्ज नहीं है।\nउत्सव या खेल प्रतियोगिता जोड़ने के लिए "+ कार्यक्रम जोड़ें" पर क्लिक करें।',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      )
                    else ...[
                      Builder(
                        builder: (context) {
                          final pagedEvents = _org.eventsConducted
                              .skip((_eventsPage - 1) * _eventsPageSize)
                              .take(_eventsPageSize)
                              .toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pagedEvents.length,
                                separatorBuilder: (context, index) => const Divider(height: 16),
                                itemBuilder: (ctx, idx) {
                                  final evt = pagedEvents[idx];
                                  final evtTitle = _pickEventTitle(evt, lang);
                                  final evtDesc = _pickEventDescription(evt, lang);
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0284C7),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: AppTranslatedText(
                                                    evtTitle,
                                                    targetLanguage: lang,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    AppTranslations.formatDigits(evt.year, lang),
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                                                  onPressed: () async {
                                                    await repo.deleteEvent(_org.id, evt.id);
                                                    _refreshOrg();
                                                  },
                                                ),
                                              ],
                                            ),
                                            if (evtDesc.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              AppTranslatedText(
                                                evtDesc,
                                                targetLanguage: lang,
                                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              AppInlinePagination(
                                currentPage: _eventsPage,
                                totalItems: _org.eventsConducted.length,
                                pageSize: _eventsPageSize,
                                onPageChanged: (p) => setState(() => _eventsPage = p),
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'events',
                                  mr: 'कार्यक्रम',
                                  hi: 'कार्यक्रम',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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
}
