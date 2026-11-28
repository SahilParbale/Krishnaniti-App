import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/housing_society_model.dart';
import '../../../data/repositories/housing_society_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';

class HousingSocietyDetailScreen extends ConsumerStatefulWidget {
  final HousingSocietyModel society;

  const HousingSocietyDetailScreen({super.key, required this.society});

  @override
  ConsumerState<HousingSocietyDetailScreen> createState() => _HousingSocietyDetailScreenState();
}

class _HousingSocietyDetailScreenState extends ConsumerState<HousingSocietyDetailScreen> {
  late HousingSocietyModel _society;

  @override
  void initState() {
    super.initState();
    _society = widget.society;
  }

  Future<void> _refreshSociety() async {
    final repo = ref.read(housingSocietyRepoProvider);
    final soc = await repo.getSocietyById(_society.id);
    if (soc != null && mounted) {
      setState(() => _society = soc);
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

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    final lang = ref.read(appLanguageProvider);
    final clean = AppTranslations.normalizeAsciiDigits(text);
    Clipboard.setData(ClipboardData(text: clean));
    final formatted = AppTranslations.formatDigits(clean, lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Copied $label: $formatted',
            mr: '$label कॉपी केले: $formatted',
            hi: '$label कॉपी किया गया: $formatted',
          ),
        ),
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openEditModal() {
    final lang = ref.read(appLanguageProvider);
    final nameMrCtrl = TextEditingController(text: _society.nameMarathi ?? _society.name);
    final nameEnCtrl = TextEditingController(text: _society.nameEnglish ?? _society.name);
    final chairmanNameCtrl = TextEditingController(text: _society.chairmanName);
    final chairmanPhoneCtrl = TextEditingController(text: _society.chairmanMobile);
    final secretaryNameCtrl = TextEditingController(text: _society.secretaryName);
    final secretaryPhoneCtrl = TextEditingController(text: _society.secretaryMobile);
    final votersCtrl = TextEditingController(text: _society.voterCount > 0 ? _society.voterCount.toString() : '');
    final favVotersCtrl = TextEditingController(text: _society.favourableVoterCount > 0 ? _society.favourableVoterCount.toString() : '');
    final areaCtrl = TextEditingController(text: _society.area);
    final addressCtrl = TextEditingController(text: _society.address);
    final notesCtrl = TextEditingController(text: _society.notes);
    String status = _society.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
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
              children: [
                AppModalHeader(
                  icon: Icons.apartment_rounded,
                  title: AppTranslations.pick(
                    lang,
                    en: 'Edit Society Details',
                    mr: 'सोसायटी माहिती संपादित करा',
                    hi: 'सोसायटी विवरण संपादित करें',
                  ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Update housing society details',
                    mr: 'सोसायटीचे तपशील अद्यतनित करा',
                    hi: 'हाउसिंग सोसायटी विवरण अपडेट करें',
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
                      // Side-by-side: Society Name (Marathi) & Society Name (English)
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
                                    en: 'Society Name (Marathi)',
                                    mr: 'सोसायटीचे नाव (मराठी)',
                                    hi: 'सोसायटी का नाम (मराठी)',
                                  ),
                                  isRequired: true,
                                ),
                                TextField(
                                  controller: nameMrCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Gokuldham Society',
                                      mr: 'उदा. गोकुळधाम सोसायटी',
                                      hi: 'उदा. गोकुलधाम सोसायटी',
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
                                    en: 'Society Name (English)',
                                    mr: 'सोसायटीचे नाव (इंग्रजी)',
                                    hi: 'सोसायटी का नाम (अंग्रेजी)',
                                  ),
                                ),
                                TextField(
                                  controller: nameEnCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Gokuldham Co-op Society',
                                      mr: 'उदा. Gokuldham Co-op Society',
                                      hi: 'उदा. Gokuldham Co-op Society',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Side-by-side: Chairman Name & Chairman Mobile
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
                                    en: 'Chairman Name',
                                    mr: 'अध्यक्षांचे नाव',
                                    hi: 'चेयरमैन का नाम',
                                  ),
                                ),
                                TextField(
                                  controller: chairmanNameCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Ramesh Kadam',
                                      mr: 'उदा. रमेश कदम',
                                      hi: 'उदा. रमेश कदम',
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
                                    en: 'Chairman Mobile (+91)',
                                    mr: 'अध्यक्ष मोबाईल (+९१)',
                                    hi: 'चेयरमैन मोबाइल (+९१)',
                                  ),
                                ),
                                TextField(
                                  controller: chairmanPhoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: appInputDecoration(
                                    prefixText: AppTranslations.formatDigits('+91 ', lang),
                                    hint: AppTranslations.formatDigits('9876543210', lang),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Side-by-side: Secretary Name & Secretary Mobile
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
                                    en: 'Secretary Name',
                                    mr: 'सचिवांचे नाव',
                                    hi: 'सचिव का नाम',
                                  ),
                                ),
                                TextField(
                                  controller: secretaryNameCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Sachin Joshi',
                                      mr: 'उदा. सचिन जोशी',
                                      hi: 'उदा. सचिन जोशी',
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
                                    en: 'Secretary Mobile (+91)',
                                    mr: 'सचिव मोबाईल (+९१)',
                                    hi: 'सचिव मोबाइल (+९१)',
                                  ),
                                ),
                                TextField(
                                  controller: secretaryPhoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: appInputDecoration(
                                    prefixText: AppTranslations.formatDigits('+91 ', lang),
                                    hint: AppTranslations.formatDigits('9876543210', lang),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Side-by-side: Total Voters & Favourable Voters
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
                                    en: 'Total Voters Count',
                                    mr: 'एकूण मतदार संख्या',
                                    hi: 'कुल मतदाता संख्या',
                                  ),
                                ),
                                TextField(
                                  controller: votersCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. 150',
                                      mr: 'उदा. १५०',
                                      hi: 'उदा. १५०',
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
                                    en: 'Favourable Voters Count',
                                    mr: 'अनुकूल मतदार संख्या',
                                    hi: 'अनुकूल मतदाता संख्या',
                                  ),
                                ),
                                TextField(
                                  controller: favVotersCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. 100',
                                      mr: 'उदा. १००',
                                      hi: 'उदा. १००',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Side-by-side: Area & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFieldLabel(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Area / Lane / Ward',
                                    mr: 'परिसर / गल्ली / प्रभाग',
                                    hi: 'क्षेत्र / गली / वार्ड',
                                  ),
                                ),
                                TextField(
                                  controller: areaCtrl,
                                  decoration: appInputDecoration(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Shanti Nagar, Ward 12',
                                      mr: 'उदा. शांती नगर, प्रभाग १२',
                                      hi: 'उदा. शांति नगर, वार्ड १२',
                                    ),
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

                      AppFieldLabel(
                        label: AppTranslations.pick(
                          lang,
                          en: 'Full Address',
                          mr: 'पूर्ण पत्ता',
                          hi: 'पूरा पता',
                        ),
                      ),
                      TextField(
                        controller: addressCtrl,
                        decoration: appInputDecoration(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Plot 12, Shanti Nagar',
                            mr: 'उदा. प्लॉट १२, शांती नगर',
                            hi: 'उदा. प्लॉट १२, शांति नगर',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      AppFieldLabel(
                        label: AppTranslations.pick(
                          lang,
                          en: 'Key Issues / Demands / Notes',
                          mr: 'महत्त्वाच्या समस्या / मागण्या / शेरा',
                          hi: 'प्रमुख समस्याएं / मांगें / नोट्स',
                        ),
                      ),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: appInputDecoration(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Road tarring, water supply, streetlights...',
                            mr: 'उदा. रस्ते डांबरीकरण, पाणीपुरवठा, पथदिवे...',
                            hi: 'उदा. सड़क डामरीकरण, जल आपूर्ति, स्ट्रीट लाइट...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

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
                                      en: 'Please enter society name.',
                                      mr: 'कृपया सोसायटीचे नाव प्रविष्ट करा.',
                                      hi: 'कृपया सोसायटी का नाम दर्ज करें।',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }

                            final vCount = int.tryParse(AppTranslations.normalizeAsciiDigits(votersCtrl.text.trim())) ?? 0;
                            final favCount = int.tryParse(AppTranslations.normalizeAsciiDigits(favVotersCtrl.text.trim())) ?? 0;

                            if (favCount > vCount && vCount > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Favourable voters cannot exceed total voters!',
                                      mr: 'अनुकूल मतदार एकूण मतदारांपेक्षा जास्त असू शकत नाहीत!',
                                      hi: 'अनुकूल मतदाता कुल मतदाताओं से अधिक नहीं हो सकते!',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }

                            final updated = _society.copyWith(
                              name: name,
                              nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : name,
                              nameEnglish: nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : name,
                              chairmanName: chairmanNameCtrl.text.trim(),
                              chairmanMobile: AppTranslations.normalizeAsciiDigits(chairmanPhoneCtrl.text.trim()),
                              secretaryName: secretaryNameCtrl.text.trim(),
                              secretaryMobile: AppTranslations.normalizeAsciiDigits(secretaryPhoneCtrl.text.trim()),
                              voterCount: vCount,
                              favourableVoterCount: favCount,
                              area: areaCtrl.text.trim(),
                              address: addressCtrl.text.trim(),
                              notes: notesCtrl.text.trim(),
                              status: status,
                            );

                            final messenger = ScaffoldMessenger.of(context);
                            final repo = ref.read(housingSocietyRepoProvider);
                            await repo.updateSociety(updated);

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (!mounted) return;
                            _refreshSociety();

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Society details updated successfully!',
                                    mr: 'सोसायटी माहिती अद्यतनित केली!',
                                    hi: 'सोसायटी विवरण सफलतापूर्वक अपडेट किया गया!',
                                  ),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Save Changes',
                                  mr: 'बदल जतन करा',
                                  hi: 'बदलाव सहेजें',
                                ),
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
      ),
    );
  }

  void _confirmDelete() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppTranslations.pick(
            lang,
            en: 'Delete Society',
            mr: 'सोसायटी हटवा',
            hi: 'सोसायटी हटाएं',
          ),
        ),
        content: AppTranslatedText(
          _society.displayNameFor(lang),
          isName: true,
          targetLanguage: lang,
          builder: (context, translatedName) => Text(
            AppTranslations.pick(
              lang,
              en: 'Are you sure you want to delete $translatedName?',
              mr: 'तुम्ही $translatedName ही सोसायटी हटवू इच्छिता का?',
              hi: 'क्या आप वाकई $translatedName को हटाना चाहते हैं?',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(housingSocietyRepoProvider);
              await repo.deleteSociety(_society.id);
              if (!mounted) return;
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Society deleted successfully.',
                      mr: 'सोसायटी यशस्वीरित्या हटवली.',
                      hi: 'सोसायटी सफलतापूर्वक हटा दी गई।',
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(
              AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final supportPct = _society.supportPercentage;
    final isActive = _society.status == 'Active';
    final statusLabel = isActive
        ? AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय')
        : AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय');
    final chairmanRole = AppTranslations.pick(lang, en: 'Chairman', mr: 'चेअरमन', hi: 'चेयरमैन');
    final secretaryRole = AppTranslations.pick(lang, en: 'Secretary', mr: 'सेक्रेटरी', hi: 'सचिव');
    final secondaryName = _society.secondaryNameFor(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: AppTranslatedText(
          _society.displayNameFor(lang),
          isName: true,
          targetLanguage: lang,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
            onPressed: _openEditModal,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSociety,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: Color(0xFF0284C7), size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTranslatedText(
                                _society.displayNameFor(lang),
                                isName: true,
                                targetLanguage: lang,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (secondaryName != null) ...[
                                const SizedBox(height: 2),
                                AppTranslatedText(
                                  secondaryName,
                                  isName: true,
                                  targetLanguage: lang,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: AppTranslatedText(
                                      _society.area.isNotEmpty
                                          ? AppTranslations.getAreaName(_society.area, lang)
                                          : AppTranslations.getAreaName('Ward 12', lang),
                                      targetLanguage: lang,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
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

              const SizedBox(height: 16),

              // Voter Support Analytics Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
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
                              const Icon(Icons.how_to_vote_outlined, color: Color(0xFF0284C7), size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Voter Support Meter',
                                    mr: 'मतदार समर्थन मापक',
                                    hi: 'मतदाता समर्थन मीटर',
                                  ),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up, size: 14, color: Color(0xFF059669)),
                              const SizedBox(width: 4),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: '${AppTranslations.formatDigits(supportPct, lang)}% Support',
                                  mr: '${AppTranslations.formatDigits(supportPct, lang)}% समर्थन',
                                  hi: '${AppTranslations.formatDigits(supportPct, lang)}% समर्थन',
                                ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _society.voterCount > 0 ? (_society.favourableVoterCount / _society.voterCount).clamp(0.0, 1.0) : 0.0,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricBlock(
                            title: AppTranslations.pick(lang, en: 'Total Voters', mr: 'एकूण मतदार', hi: 'कुल मतदाता'),
                            count: AppTranslations.formatDigits(_society.voterCount, lang),
                            icon: Icons.groups_outlined,
                            color: const Color(0xFF0284C7),
                            bgColor: const Color(0xFFF0F9FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricBlock(
                            title: AppTranslations.pick(lang, en: 'Favourable Voters', mr: 'अनुकूल मतदार', hi: 'अनुकूल मतदाता'),
                            count: AppTranslations.formatDigits(_society.favourableVoterCount, lang),
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF16A34A),
                            bgColor: const Color(0xFFF0FDF4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricBlock(
                            title: AppTranslations.pick(lang, en: 'Other / Neutral', mr: 'इतर / तटस्थ', hi: 'अन्य / तटस्थ'),
                            count: AppTranslations.formatDigits(_society.otherVotersCount, lang),
                            icon: Icons.pending_outlined,
                            color: const Color(0xFFD97706),
                            bgColor: const Color(0xFFFFFBEB),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Executive Contacts Card (Chairman & Secretary)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, color: Color(0xFF0284C7), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Society Executive Contacts',
                              mr: 'सोसायटी कार्यकारिणी संपर्क',
                              hi: 'सोसायटी कार्यकारिणी संपर्क',
                            ),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Chairman Box
                    _buildExecutiveCard(
                      lang: lang,
                      role: chairmanRole,
                      name: _society.chairmanName,
                      phone: _society.chairmanMobile,
                      roleColor: const Color(0xFF4F46E5),
                      roleBg: const Color(0xFFEEF2FF),
                    ),

                    const SizedBox(height: 12),

                    // Secretary Box
                    _buildExecutiveCard(
                      lang: lang,
                      role: secretaryRole,
                      name: _society.secretaryName,
                      phone: _society.secretaryMobile,
                      roleColor: const Color(0xFF0284C7),
                      roleBg: const Color(0xFFF0F9FF),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Address & Location Card
              if (_society.address.isNotEmpty || _society.area.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.map_outlined, color: Color(0xFF0284C7), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Address & Location',
                                mr: 'पत्ता आणि ठिकाण',
                                hi: 'पता और स्थान',
                              ),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_society.address.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.home_outlined, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppTranslatedText(
                                _society.address,
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      if (_society.address.isNotEmpty && _society.area.isNotEmpty)
                        const SizedBox(height: 6),
                      if (_society.area.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.near_me_outlined, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppTranslatedText(
                                AppTranslations.getAreaName(_society.area, lang),
                                prefix: AppTranslations.pick(lang, en: 'Area: ', mr: 'परिसर: ', hi: 'क्षेत्र: '),
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Key Issues & Notes Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.report_problem_outlined, color: Color(0xFFB45309), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Key Issues / Demands / Notes',
                              mr: 'महत्त्वाच्या समस्या / मागण्या / नोंदी',
                              hi: 'प्रमुख समस्याएं / मांगें / नोट्स',
                            ),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_society.notes.isNotEmpty)
                      AppTranslatedText(
                        _society.notes,
                        targetLanguage: lang,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78350F),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No pending issues recorded currently.',
                          mr: 'सध्या कोणत्याही प्रलंबित समस्या नोंदवलेल्या नाहीत.',
                          hi: 'वर्तमान में कोई लंबित समस्या दर्ज नहीं है।',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78350F),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildMetricBlock({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveCard({
    required String lang,
    required String role,
    required String name,
    required String phone,
    required Color roleColor,
    required Color roleBg,
  }) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
                ),
              ),
              if (phone.isNotEmpty)
                Text(
                  AppTranslations.formatDigits(phone, lang),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (name.trim().isNotEmpty)
            AppTranslatedText(
              name,
              isName: true,
              targetLanguage: lang,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            )
          else
            Text(
              AppTranslations.pick(
                lang,
                en: 'Not Registered',
                mr: 'नोंदणीकृत नाही',
                hi: 'पंजीकृत नहीं',
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(phone),
                    icon: const Icon(Icons.phone, size: 14),
                    label: Text(
                      AppTranslations.pick(lang, en: 'Call', mr: 'कॉल', hi: 'कॉल'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWhatsApp(phone),
                    icon: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: Text(
                      AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सॲप', hi: 'व्हाट्सएप'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFFBBF7D0)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _copyToClipboard(phone, role),
                  icon: const Icon(Icons.copy, size: 16, color: Color(0xFF64748B)),
                  tooltip: AppTranslations.pick(lang, en: 'Copy Number', mr: 'नंबर कॉपी करा', hi: 'नंबर कॉपी करें'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

