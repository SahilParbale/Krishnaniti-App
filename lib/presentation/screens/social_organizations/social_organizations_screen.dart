import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/social_organization_model.dart';
import '../../../data/repositories/social_organization_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'social_org_detail_screen.dart';
import 'social_org_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class SocialOrganizationsScreen extends ConsumerStatefulWidget {
  const SocialOrganizationsScreen({super.key});

  @override
  ConsumerState<SocialOrganizationsScreen> createState() => _SocialOrganizationsScreenState();
}

class _SocialOrganizationsScreenState extends ConsumerState<SocialOrganizationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'all';
  final String _selectedStatus = 'all';
  int _viewMode = 0; // 0 = Cards, 1 = Table
  String? _expandedOrgId;

  bool _isLoading = true;
  List<SocialOrganizationModel> _organizations = [];
  Map<String, int> _stats = {
    'total': 0,
    'ngos': 0,
    'sports': 0,
    'mandals': 0,
  };

  int _displayedLimit = 20;

  List<SocialOrganizationModel> get _visibleOrgs =>
      _organizations.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadOrganizations() async {
    setState(() => _isLoading = true);
    final repo = ref.read(socialOrgRepoProvider);

    final orgs = await repo.getOrganizations(
      type: _selectedType == 'all' ? null : _selectedType,
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      query: AppTranslations.normalizeAsciiDigits(_searchController.text.trim()),
    );

    final stats = await repo.getOrganizationStats();

    if (mounted) {
      setState(() {
        _organizations = orgs;
        _stats = stats;
        _isLoading = false;
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
  // ADD / EDIT ORGANIZATION MODAL
  // ===========================================================================
  void _showOrgForm({SocialOrganizationModel? orgToEdit}) {
    final lang = ref.read(appLanguageProvider);
    final nameEnCtrl = TextEditingController(text: orgToEdit?.nameEnglish ?? orgToEdit?.name ?? '');
    final nameMrCtrl = TextEditingController(text: orgToEdit?.nameMarathi ?? orgToEdit?.name ?? '');
    String type = orgToEdit?.type ?? 'ngo';
    final areaCtrl = TextEditingController(text: orgToEdit?.area ?? '');
    final presNameCtrl = TextEditingController(text: orgToEdit?.presidentName ?? '');
    final presPhoneCtrl = TextEditingController(text: orgToEdit?.presidentMobile ?? '');
    final membersCtrl = TextEditingController(text: orgToEdit != null && orgToEdit.membersCount > 0 ? orgToEdit.membersCount.toString() : '');
    final estCtrl = TextEditingController(text: orgToEdit?.establishedYear ?? '');
    final supportCtrl = TextEditingController(text: orgToEdit?.supportReceived ?? '');
    final descCtrl = TextEditingController(text: orgToEdit?.description ?? '');
    String status = orgToEdit?.status ?? 'Active';

    List<SocialOrgEventModel> tempEvents = List.from(orgToEdit?.eventsConducted ?? []);
    final evtTitleEnCtrl = TextEditingController();
    final evtTitleMrCtrl = TextEditingController();
    final evtYearCtrl = TextEditingController(text: DateTime.now().year.toString());
    final evtDescCtrl = TextEditingController();

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

    Widget fieldLabel(String text, {bool isRequired = false, String? optionalNote}) {
      return AppFieldLabel(label: text, isRequired: isRequired, optionalHint: optionalNote);
    }

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
              // 1. FIXED HEADER
              AppModalHeader(
                icon: Icons.apartment_rounded,
                title: orgToEdit == null
                    ? AppTranslations.pick(
                        lang,
                        en: 'Log New Organization / Mandal',
                        mr: 'नवीन संस्था / मंडळ नोंदवा',
                        hi: 'नया संगठन / मंडल दर्ज करें',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Edit Organization Info',
                        mr: 'संस्थेची माहिती सुधारा',
                        hi: 'संगठन जानकारी संपादित करें',
                      ),
                subtitle: AppTranslations.pick(
                  lang,
                  en: 'Register mandals, sports clubs and social NGOs',
                  mr: 'प्रभागातील गणेश मंडळे, क्रीडा क्लब व एनजीओ नोंदवा',
                  hi: 'वार्ड में मंडल, खेल क्लब और सामाजिक एनजीओ दर्ज करें',
                ),
                onClose: () => Navigator.pop(ctx),
              ),

              // 2. SCROLLABLE FORM BODY & BUTTONS
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  children: [
                    // Row 1: Name English & Name Marathi
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Organization Name (English)',
                                  mr: 'संस्थेचे नाव (इंग्रजी)',
                                  hi: 'संगठन का नाम (अंग्रेजी)',
                                ),
                              ),
                              TextField(
                                controller: nameEnCtrl,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Shivtej Sports Club',
                                    mr: 'उदा. Shivtej Sports Club',
                                    hi: 'उदा. Shivtej Sports Club',
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
                              fieldLabel(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Organization Name (Marathi)',
                                  mr: 'संस्थेचे नाव (मराठी)',
                                  hi: 'संगठन का नाम (मराठी)',
                                ),
                                isRequired: true,
                              ),
                              TextField(
                                controller: nameMrCtrl,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. शिवतेज क्रीडा मंडळ',
                                    mr: 'उदा. शिवतेज क्रीडा मंडळ',
                                    hi: 'उदा. शिवतेज खेल मंडल',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Organization Type & Area
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
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(
                                    value: 'ngo',
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'NGO / Social Foundation',
                                        mr: 'एन.जी.ओ / सामाजिक संस्था',
                                        hi: 'एनजीओ / सामाजिक संस्था',
                                      ),
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sports_cricket',
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Cricket & Sports Club',
                                        mr: 'क्रीडा व क्रिकेट क्लब',
                                        hi: 'क्रिकेट एवं स्पोर्ट्स क्लब',
                                      ),
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ganpati_mandal',
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Ganpati Mandal',
                                        mr: 'सार्वजनिक गणेश उत्सव मंडळ',
                                        hi: 'सार्वजनिक गणेश उत्सव मंडल',
                                      ),
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'navratri_mandal',
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Navratri Mandal',
                                        mr: 'सार्वजनिक नवरात्र उत्सव मंडळ',
                                        hi: 'सार्वजनिक नवरात्र उत्सव मंडल',
                                      ),
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'other',
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Other',
                                        mr: 'इतर संस्था व मंडळ',
                                        hi: 'अन्य संगठन एवं मंडल',
                                      ),
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
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
                              fieldLabel(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Area / Ward',
                                  mr: 'परिसर / प्रभाग क्षेत्र',
                                  hi: 'क्षेत्र / वार्ड',
                                ),
                                isRequired: true,
                              ),
                              TextField(
                                controller: areaCtrl,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Nehru Chowk',
                                    mr: 'उदा. नेहरू चौक',
                                    hi: 'उदा. नेहरू चौक',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 3: President / Contact Person & Mobile Number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(
                                AppTranslations.pick(
                                  lang,
                                  en: 'President / Contact Person',
                                  mr: 'प्रमुख व्यक्ती / अध्यक्ष नाव',
                                  hi: 'प्रमुख व्यक्ति / अध्यक्ष का नाम',
                                ),
                                isRequired: true,
                              ),
                              TextField(
                                controller: presNameCtrl,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(
                                    lang,
                                    en: 'e.g. Sachin Kadam',
                                    mr: 'उदा. सचिन कदम',
                                    hi: 'उदा. सचिन कदम',
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
                              fieldLabel(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Mobile Number',
                                  mr: 'मोबाईल नंबर',
                                  hi: 'मोबाइल नंबर',
                                ),
                                isRequired: true,
                              ),
                              TextField(
                                controller: presPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                decoration: inputDec(
                                  prefixText: AppTranslations.formatDigits('+91 ', lang),
                                  hint: AppTranslations.formatDigits('98xxxxxxxx', lang),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 4: Members Count & Established Year
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Members Count (Approx)',
                                  mr: 'सदस्य संख्या (अंदाजे)',
                                  hi: 'सदस्य संख्या (अनुमानित)',
                                ),
                              ),
                              TextField(
                                controller: membersCtrl,
                                keyboardType: TextInputType.number,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(lang, en: 'e.g. 50', mr: 'उदा. ५०', hi: 'उदा. ५०'),
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
                              fieldLabel(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Established Year',
                                  mr: 'स्थापना वर्ष',
                                  hi: 'स्थापना वर्ष',
                                ),
                              ),
                              TextField(
                                controller: estCtrl,
                                keyboardType: TextInputType.number,
                                decoration: inputDec(
                                  hint: AppTranslations.pick(lang, en: 'e.g. 2020', mr: 'उदा. २०२०', hi: 'उदा. २०२०'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Support Provided by You (Nagar Sevak Support)
                    fieldLabel(
                      AppTranslations.pick(
                        lang,
                        en: 'Support Provided by You (Nagar Sevak Support)',
                        mr: 'आपल्या वतीने मिळालेली मदत / प्रायोजकत्व',
                        hi: 'आपकी ओर से दी गई सहायता / प्रायोजन',
                      ),
                    ),
                    TextField(
                      controller: supportCtrl,
                      maxLines: 2,
                      decoration: inputDec(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'e.g. Funded Ganesh pandal sound system, distributed cricket kits, etc.',
                          mr: 'उदा. क्रिकेट किट वाटप केले किंवा मंडप घालण्यास आर्थिक मदत पुरवली...',
                          hi: 'उदा. क्रिकेट किट वितरित की या मंडप के लिए आर्थिक सहायता दी...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // General Notes / Description
                    fieldLabel(
                      AppTranslations.pick(
                        lang,
                        en: 'General Notes / Description',
                        mr: 'संस्थेची थोडक्यात माहिती / टिपण',
                        hi: 'संगठन के बारे में संक्षिप्त जानकारी / विवरण',
                      ),
                    ),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: inputDec(
                        hint: AppTranslations.pick(
                          lang,
                          en: 'A brief description of goals, works or comments...',
                          mr: 'संस्थेचे सामाजिक उद्देश किंवा इतर माहिती...',
                          hi: 'संगठन के सामाजिक उद्देश्य, कार्य या टिप्पणी...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Status Radio Selection
                    fieldLabel(
                      AppTranslations.pick(
                        lang,
                        en: 'Status',
                        mr: 'संस्थेची स्थिती',
                        hi: 'संगठन की स्थिति',
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => setModalState(() => status = 'Active'),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'Active',
                                groupValue: status,
                                activeColor: const Color(0xFF0284C7),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => status = val);
                                },
                              ),
                              Text(
                                AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        InkWell(
                          onTap: () => setModalState(() => status = 'Inactive'),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'Inactive',
                                groupValue: status,
                                activeColor: const Color(0xFF0284C7),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => status = val);
                                },
                              ),
                              Text(
                                AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Log Major Events & Programs (Events Conducted)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Log Major Events & Programs',
                                    mr: 'प्रमुख उपक्रम / उत्सव नोंदवा',
                                    hi: 'प्रमुख कार्यक्रम / उत्सव दर्ज करें',
                                  ),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // List of already logged events
                          if (tempEvents.isNotEmpty) ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tempEvents.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 6),
                              itemBuilder: (context, idx) {
                                final evt = tempEvents[idx];
                                final evtTitle = _pickEventTitle(evt, lang);
                                final evtDesc = _pickEventDescription(evt, lang);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: AppTranslatedText(
                                                    evtTitle,
                                                    targetLanguage: lang,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    AppTranslations.formatDigits(evt.year, lang),
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (evtDesc.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              AppTranslatedText(
                                                evtDesc,
                                                targetLanguage: lang,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                                        onPressed: () {
                                          setModalState(() {
                                            tempEvents.removeAt(idx);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Add Event Input Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: evtTitleEnCtrl,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: inputDec(
                                          hint: AppTranslations.pick(
                                            lang,
                                            en: 'Event Title (Eng)',
                                            mr: 'कार्यक्रमाचे नाव (इंग्रजी)',
                                            hi: 'कार्यक्रम का नाम (अंग्रेजी)',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: evtTitleMrCtrl,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: inputDec(
                                          hint: AppTranslations.pick(
                                            lang,
                                            en: 'Event Title (Mar)',
                                            mr: 'कार्यक्रमाचे नाव (मराठी)',
                                            hi: 'कार्यक्रम का नाम (मराठी)',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 70,
                                      child: TextField(
                                        controller: evtYearCtrl,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: inputDec(
                                          hint: AppTranslations.pick(lang, en: 'Year', mr: 'वर्ष', hi: 'वर्ष'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: evtDescCtrl,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: inputDec(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'Brief description of program...',
                                      mr: 'उदा. ५० संघांचा सहभाग, स्थानिक चषक...',
                                      hi: 'उदा. ५० टीमों की भागीदारी, स्थानीय टूर्नामेंट...',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Add Event',
                                        mr: 'हा कार्यक्रम जोडा',
                                        hi: 'कार्यक्रम जोड़ें',
                                      ),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      final titleEn = evtTitleEnCtrl.text.trim();
                                      final titleMr = evtTitleMrCtrl.text.trim();
                                      if (titleEn.isEmpty && titleMr.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppTranslations.pick(
                                                lang,
                                                en: 'Please enter event title',
                                                mr: 'कृपया कार्यक्रमाचे नाव टाका',
                                                hi: 'कृपया कार्यक्रम का नाम दर्ज करें',
                                              ),
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      final year = int.tryParse(AppTranslations.normalizeAsciiDigits(evtYearCtrl.text.trim())) ?? DateTime.now().year;
                                      final desc = evtDescCtrl.text.trim();
                                      setModalState(() {
                                        tempEvents.add(
                                          SocialOrgEventModel(
                                            id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
                                            title: titleEn.isNotEmpty ? titleEn : titleMr,
                                            titleMr: titleMr.isNotEmpty ? titleMr : titleEn,
                                            year: year,
                                            description: desc,
                                            descriptionMr: desc,
                                          ),
                                        );
                                        evtTitleEnCtrl.clear();
                                        evtTitleMrCtrl.clear();
                                        evtDescCtrl.clear();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Action Buttons: Cancel & Save Details
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
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

                              final newOrg = SocialOrganizationModel(
                                id: orgToEdit?.id ?? 'org-${DateTime.now().millisecondsSinceEpoch}',
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
                                eventsConducted: tempEvents,
                                description: descCtrl.text.trim(),
                                status: status,
                                createdAt: orgToEdit?.createdAt ?? DateTime.now(),
                              );

                              final messenger = ScaffoldMessenger.of(context);
                              final repo = ref.read(socialOrgRepoProvider);
                              if (orgToEdit == null) {
                                await repo.addOrganization(newOrg);
                              } else {
                                await repo.updateOrganization(newOrg);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (!mounted) return;
                              _loadOrganizations();

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    orgToEdit == null
                                        ? AppTranslations.pick(
                                            lang,
                                            en: 'Organization registered successfully!',
                                            mr: 'नवीन संस्था नोंदणी यशस्वी झाली!',
                                            hi: 'संगठन सफलतापूर्वक पंजीकृत हो गया!',
                                          )
                                        : AppTranslations.pick(
                                            lang,
                                            en: 'Details updated successfully!',
                                            mr: 'संस्थेची माहिती अद्यतनित केली!',
                                            hi: 'विवरण सफलतापूर्वक अपडेट किया गया!',
                                          ),
                                  ),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text(
                              orgToEdit == null
                                  ? AppTranslations.pick(lang, en: 'Save Details', mr: 'माहिती जतन करा', hi: 'विवरण सहेजें')
                                  : AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'बदलाव सहेजें'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
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

  // ===========================================================================
  // DELETE CONFIRMATION DIALOG
  // ===========================================================================
  void _confirmDeleteOrg(SocialOrganizationModel org) {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppTranslations.pick(
            lang,
            en: 'Delete Organization?',
            mr: 'संस्था हटवायची का?',
            hi: 'संगठन हटाएं?',
          ),
        ),
        content: AppTranslatedText(
          _pickOrgName(org, lang),
          isName: true,
          targetLanguage: lang,
          builder: (context, translatedName) => Text(
            AppTranslations.pick(
              lang,
              en: 'Are you sure you want to delete record for "$translatedName"? This action cannot be undone.',
              mr: 'तुम्ही "$translatedName" ची नोंद हटवू इच्छिता का? ही कृती पूर्ववत करता येणार नाही.',
              hi: 'क्या आप वाकई "$translatedName" का रिकॉर्ड हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(socialOrgRepoProvider);
              await repo.deleteOrganization(org.id);
              _loadOrganizations();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Record deleted successfully!',
                        mr: 'नोंद यशस्वीरित्या हटवली!',
                        hi: 'रिकॉर्ड सफलतापूर्वक हटा दिया गया!',
                      ),
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final totalFmt = AppTranslations.formatDigits(_stats['total'] ?? 0, lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Open Menu Drawer',
              mr: 'मेनू उघडा',
              hi: 'मेनू खोलें',
            ),
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
              AppTranslations.pick(
                lang,
                en: 'NGO & Mandals Info',
                mr: 'NGO व मंडळ माहिती',
                hi: 'एनजीओ और मंडल जानकारी',
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
            Text(
              AppTranslations.pick(
                lang,
                en: 'Social organizations, youth mandals and trust directory',
                mr: 'सामाजिक संस्था, युवक मंडळे व ट्रस्ट निर्देशिका',
                hi: 'सामाजिक संगठन, युवा मंडल और ट्रस्ट निर्देशिका',
              ),
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: AppLanguageSegmentedSelector(isCompact: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrganizations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. KPI STAT CARDS
              // ==========================================
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: AppTranslations.pick(lang, en: 'Total Registered', mr: 'एकूण नोंदणी', hi: 'कुल पंजीकृत'),
                      value: AppTranslations.formatDigits(_stats['total'] ?? 0, lang),
                      icon: Icons.layers_rounded,
                      color: const Color(0xFF0284C7),
                      bg: const Color(0xFFF0F9FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: AppTranslations.pick(lang, en: 'NGOs', mr: 'एनजीओ', hi: 'एनजीओ'),
                      value: AppTranslations.formatDigits(_stats['ngos'] ?? 0, lang),
                      icon: Icons.apartment_rounded,
                      color: const Color(0xFF4338CA),
                      bg: const Color(0xFFEEF2FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: AppTranslations.pick(lang, en: 'Sports Clubs', mr: 'क्रीडा क्लब', hi: 'खेल क्लब'),
                      value: AppTranslations.formatDigits(_stats['sports'] ?? 0, lang),
                      icon: Icons.sports_cricket_rounded,
                      color: const Color(0xFF059669),
                      bg: const Color(0xFFECFDF5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: AppTranslations.pick(lang, en: 'Festival Mandals', mr: 'उत्सव मंडळे', hi: 'उत्सव मंडल'),
                      value: AppTranslations.formatDigits(_stats['mandals'] ?? 0, lang),
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFFFFBEB),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==========================================
              // 2. SEARCH & VIEW TOGGLE
              // ==========================================
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) {
                          setState(() => _displayedLimit = 20);
                          _loadOrganizations();
                        },
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(
                            lang,
                            en: 'Search by name, president, or area...',
                            mr: 'नाव, अध्यक्ष किंवा परिसरावरून शोधा...',
                            hi: 'नाम, अध्यक्ष या क्षेत्र से खोजें...',
                          ),
                          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _displayedLimit = 20);
                                    _loadOrganizations();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // View & Export Controls
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.grid_view_rounded, size: 20, color: _viewMode == 0 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _viewMode = 0),
                          tooltip: AppTranslations.pick(lang, en: 'Card View', mr: 'कार्ड दृश्य', hi: 'कार्ड दृश्य'),
                        ),
                        IconButton(
                          icon: Icon(Icons.table_rows_rounded, size: 20, color: _viewMode == 1 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _viewMode = 1),
                          tooltip: AppTranslations.pick(lang, en: 'Table View', mr: 'तक्ता दृश्य', hi: 'तालिका दृश्य'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppPdfButton.icon(
                    tooltip: AppTranslations.getDownloadReport(lang),
                    onPressed: () {
                      SocialOrgReportGenerator.generateAndPrintReport(
                        context: context,
                        organizations: _organizations,
                        lang: lang,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==========================================
              // 3. FILTER TABS: TYPE
              // ==========================================
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      AppTranslations.pick(
                        lang,
                        en: 'All Types ($totalFmt)',
                        mr: 'सर्व प्रकार ($totalFmt)',
                        hi: 'सभी प्रकार ($totalFmt)',
                      ),
                      'all',
                      _selectedType,
                      (val) {
                        setState(() {
                          _selectedType = val;
                          _displayedLimit = 20;
                        });
                        _loadOrganizations();
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      AppTranslations.pick(lang, en: 'Ganesh Mandals', mr: 'गणेश मंडळे', hi: 'गणेश मंडल'),
                      'ganpati_mandal',
                      _selectedType,
                      (val) {
                        setState(() {
                          _selectedType = val;
                          _displayedLimit = 20;
                        });
                        _loadOrganizations();
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      AppTranslations.pick(lang, en: 'Navratri Mandals', mr: 'नवरात्र मंडळे', hi: 'नवरात्र मंडल'),
                      'navratri_mandal',
                      _selectedType,
                      (val) {
                        setState(() {
                          _selectedType = val;
                          _displayedLimit = 20;
                        });
                        _loadOrganizations();
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      AppTranslations.pick(lang, en: 'Sports Clubs', mr: 'क्रीडा क्लब', hi: 'खेल क्लब'),
                      'sports_cricket',
                      _selectedType,
                      (val) {
                        setState(() {
                          _selectedType = val;
                          _displayedLimit = 20;
                        });
                        _loadOrganizations();
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      AppTranslations.pick(lang, en: 'NGOs & Trusts', mr: 'एनजीओ व ट्रस्ट', hi: 'एनजीओ और ट्रस्ट'),
                      'ngo',
                      _selectedType,
                      (val) {
                        setState(() {
                          _selectedType = val;
                          _displayedLimit = 20;
                        });
                        _loadOrganizations();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================
              // 4. MAIN CONTENT (CARDS OR TABLE)
              // ==========================================
              if (_isLoading)
                const AppShimmerList(count: 6)
              else if (_organizations.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.apartment_outlined, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No organizations or mandals found.',
                          mr: 'कोणत्याही संस्था किंवा मंडळे आढळली नाहीत.',
                          hi: 'कोई संगठन या मंडल नहीं मिला।',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Use the "+ Add Organization" button below to register.',
                          mr: 'नोंदणी करण्यासाठी खालील "+ संस्था जोडा" बटण वापरा.',
                          hi: 'पंजीकरण के लिए नीचे "+ संगठन जोड़ें" बटन का उपयोग करें।',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showOrgForm(),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Register Organization',
                            mr: 'संस्था नोंदवा',
                            hi: 'संगठन पंजीकृत करें',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (_viewMode == 0)
                  // CARDS VIEW
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _visibleOrgs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final org = _visibleOrgs[idx];
                      return _buildOrgCard(org, lang);
                    },
                  )
                else
                  // SPREADSHEET TABLE VIEW
                  _buildSpreadsheetTable(lang),
                AppLoadMoreFooter(
                  currentCount: _visibleOrgs.length,
                  totalCount: _organizations.length,
                  pageSize: 20,
                  onLoadMore: () => setState(() => _displayedLimit += 20),
                  label: AppTranslations.pick(
                    lang,
                    en: 'organizations',
                    mr: 'संस्था',
                    hi: 'संगठन',
                  ),
                  isMarathi: lang == 'mr',
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOrgForm(),
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          AppTranslations.pick(
            lang,
            en: 'Add Organization',
            mr: 'संस्था जोडा',
            hi: 'संगठन जोड़ें',
          ),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET HELPERS
  // ===========================================================================
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, ValueChanged<String> onSelect) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildOrgCard(SocialOrganizationModel org, String lang) {
    final theme = _getTheme(org.type);
    final isExpanded = _expandedOrgId == org.id;
    final isActive = org.status == 'Active';
    final statusLabel = isActive
        ? AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय')
        : AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय');

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SocialOrgDetailScreen(organization: org)),
        );
        _loadOrganizations();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme['border'] as Color),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (theme['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (theme['color'] as Color).withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Icon(theme['icon'] as IconData, color: theme['color'] as Color, size: 22),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTranslatedText(
                        _pickOrgName(org, lang),
                        isName: true,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pickOrgTypeLabel(org.type, lang),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme['color'] as Color),
                      ),
                      const SizedBox(height: 6),

                      // Status & Members Chip
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive ? const Color(0xFF047857) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: '${AppTranslations.formatDigits(org.membersCount, lang)} Members',
                                mr: '${AppTranslations.formatDigits(org.membersCount, lang)} सदस्य',
                                hi: '${AppTranslations.formatDigits(org.membersCount, lang)} सदस्य',
                              ),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                          if (org.establishedYear.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Est: ${AppTranslations.formatDigits(org.establishedYear, lang)}',
                                  mr: 'स्थापना: ${AppTranslations.formatDigits(org.establishedYear, lang)}',
                                  hi: 'स्थापना: ${AppTranslations.formatDigits(org.establishedYear, lang)}',
                                ),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showOrgForm(orgToEdit: org);
                    } else if (val == 'delete') {
                      _confirmDeleteOrg(org);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Text(AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Text(
                            AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                            style: const TextStyle(color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // President & Mobile Bar
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: org.presidentName.isNotEmpty
                            ? AppTranslatedText(
                                org.presidentName,
                                isName: true,
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              )
                            : const Text(
                                '-',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                      ),
                    ],
                  ),
                ),
                if (org.presidentMobile.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _makePhoneCall(org.presidentMobile),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 12, color: Color(0xFF0284C7)),
                          const SizedBox(width: 4),
                          Text(
                            AppTranslations.pick(lang, en: 'Call', mr: 'कॉल', hi: 'कॉल'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _openWhatsApp(org.presidentMobile),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _copyToClipboard(org.presidentMobile),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ],
            ),

            if (org.area.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppTranslatedText(
                      AppTranslations.getAreaName(org.area, lang),
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Support received snippet
            if (org.supportReceived.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 13, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AppTranslatedText(
                        org.supportReceived,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF5B21B6), fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Expandable Events Accordion
            if (org.eventsConducted.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => setState(() => _expandedOrgId = isExpanded ? null : org.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(Icons.event_note_rounded, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Key Events / Festivals (${AppTranslations.formatDigits(org.eventsConducted.length, lang)})',
                                  mr: 'प्रमुख उपक्रम / उत्सव (${AppTranslations.formatDigits(org.eventsConducted.length, lang)})',
                                  hi: 'प्रमुख कार्यक्रम / उत्सव (${AppTranslations.formatDigits(org.eventsConducted.length, lang)})',
                                ),
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.only(left: 10),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Color(0xFFCBD5E1), width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: org.eventsConducted.map((evt) {
                      final evtTitle = _pickEventTitle(evt, lang);
                      final evtDesc = _pickEventDescription(evt, lang);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: AppTranslatedText(
                                    evtTitle,
                                    targetLanguage: lang,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(3)),
                                  child: Text(
                                    AppTranslations.formatDigits(evt.year, lang),
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            if (evtDesc.isNotEmpty)
                              AppTranslatedText(
                                evtDesc,
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 10),

            // Bottom action
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'View Detailed Profile',
                      mr: 'सविस्तर माहिती पहा',
                      hi: 'विस्तृत प्रोफ़ाइल देखें',
                    ),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0284C7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SPREADSHEET TABLE VIEW
  // ===========================================================================
  Widget _buildSpreadsheetTable(String lang) {
    return Container(
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
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columns: [
              DataColumn(label: Text(AppTranslations.pick(lang, en: '#', mr: 'क्र.', hi: 'क्र.'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Organization Name', mr: 'संस्थेचे नाव', hi: 'संगठन का नाम'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Type', mr: 'प्रकार', hi: 'प्रकार'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'President', mr: 'अध्यक्ष', hi: 'अध्यक्ष'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Area / Vicinity', mr: 'परिसर / भाग', hi: 'क्षेत्र / मोहल्ला'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Members', mr: 'सदस्य', hi: 'सदस्य'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Established', mr: 'स्थापना', hi: 'स्थापना'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Support History', mr: 'मदत नोंद', hi: 'सहायता इतिहास'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Activities', mr: 'उपक्रम', hi: 'गतिविधियां'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Action', mr: 'कृती', hi: 'कार्रवाई'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: List.generate(_visibleOrgs.length, (index) {
              final o = _visibleOrgs[index];
              final theme = _getTheme(o.type);
              final isActive = o.status == 'Active';
              final statusLabel = isActive
                  ? AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय')
                  : AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय');

              return DataRow(
                cells: [
                  DataCell(Text(AppTranslations.formatDigits(index + 1, lang), style: const TextStyle(fontSize: 11))),
                  DataCell(
                    AppTranslatedText(
                      _pickOrgName(o, lang),
                      isName: true,
                      targetLanguage: lang,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (theme['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _pickOrgTypeLabel(o.type, lang),
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: theme['color'] as Color),
                      ),
                    ),
                  ),
                  DataCell(
                    o.presidentName.isNotEmpty
                        ? AppTranslatedText(
                            o.presidentName,
                            isName: true,
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 11),
                          )
                        : const Text('-', style: TextStyle(fontSize: 11)),
                  ),
                  DataCell(
                    Text(
                      o.presidentMobile.isNotEmpty
                          ? AppTranslations.formatDigits(o.presidentMobile, lang)
                          : '-',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    o.area.isNotEmpty
                        ? AppTranslatedText(
                            AppTranslations.getAreaName(o.area, lang),
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 11),
                          )
                        : const Text('-', style: TextStyle(fontSize: 11)),
                  ),
                  DataCell(Text(AppTranslations.formatDigits(o.membersCount, lang), style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Text(
                      o.establishedYear.isNotEmpty
                          ? AppTranslations.formatDigits(o.establishedYear, lang)
                          : '-',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    o.supportReceived.isNotEmpty
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: AppTranslatedText(
                              o.supportReceived,
                              targetLanguage: lang,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          )
                        : const Text('-', style: TextStyle(fontSize: 11)),
                  ),
                  DataCell(Text(AppTranslations.formatDigits(o.eventsConducted.length, lang), style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? const Color(0xFF047857) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
                      tooltip: AppTranslations.pick(lang, en: 'View Details', mr: 'तपशील पहा', hi: 'विवरण देखें'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SocialOrgDetailScreen(organization: o)),
                        );
                        _loadOrganizations();
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
