import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/housing_society_model.dart';
import '../../../data/repositories/housing_society_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'housing_society_detail_screen.dart';
import 'housing_society_report_generator.dart';

class HousingSocietiesScreen extends ConsumerStatefulWidget {
  const HousingSocietiesScreen({super.key});

  @override
  ConsumerState<HousingSocietiesScreen> createState() => _HousingSocietiesScreenState();
}

class _HousingSocietiesScreenState extends ConsumerState<HousingSocietiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedArea = 'all';
  String _selectedStatus = 'all';
  int _viewMode = 0; // 0 = Cards, 1 = Table

  bool _isLoading = true;
  List<HousingSocietyModel> _societies = [];
  List<String> _areas = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'voters': 0,
    'favourable': 0,
    'supportPercentage': 0,
  };

  int _displayedLimit = 20;

  List<HousingSocietyModel> get _visibleSocieties =>
      _societies.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final repo = ref.read(housingSocietyRepoProvider);

    final normalizedSearch = AppTranslations.normalizeAsciiDigits(_searchController.text);
    final list = await repo.getSocieties(
      searchQuery: normalizedSearch,
      area: (_selectedArea == 'all' || _selectedArea == 'All') ? 'All' : _selectedArea,
      status: _selectedStatus,
    );
    final filteredList = _selectedStatus == 'all'
        ? list
        : list.where((s) => s.status.toLowerCase() == _selectedStatus.toLowerCase()).toList();
    final stats = await repo.getStatistics();
    final areas = await repo.getUniqueAreas();

    if (mounted) {
      setState(() {
        _societies = filteredList;
        _stats = stats;
        _areas = areas;
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

  void _openAddEditModal([HousingSocietyModel? societyToEdit]) {
    final lang = ref.read(appLanguageProvider);
    final nameEnCtrl = TextEditingController(text: societyToEdit?.nameEnglish ?? societyToEdit?.name ?? '');
    final nameMrCtrl = TextEditingController(text: societyToEdit?.nameMarathi ?? societyToEdit?.name ?? '');
    final areaCtrl = TextEditingController(text: societyToEdit?.area ?? '');
    final addressCtrl = TextEditingController(text: societyToEdit?.address ?? '');
    final chairmanNameCtrl = TextEditingController(text: societyToEdit?.chairmanName ?? '');
    final chairmanPhoneCtrl = TextEditingController(text: societyToEdit?.chairmanMobile ?? '');
    final secretaryNameCtrl = TextEditingController(text: societyToEdit?.secretaryName ?? '');
    final secretaryPhoneCtrl = TextEditingController(text: societyToEdit?.secretaryMobile ?? '');
    final votersCtrl = TextEditingController(text: (societyToEdit != null && societyToEdit.voterCount > 0) ? societyToEdit.voterCount.toString() : '');
    final favVotersCtrl = TextEditingController(text: (societyToEdit != null && societyToEdit.favourableVoterCount > 0) ? societyToEdit.favourableVoterCount.toString() : '');
    final notesCtrl = TextEditingController(text: societyToEdit?.notes ?? '');
    String status = societyToEdit?.status ?? 'Active';

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

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return AppFieldLabel(label: text, isRequired: isRequired);
    }

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
                // 1. FIXED HEADER
                AppModalHeader(
                  icon: Icons.home_work_rounded,
                  title: societyToEdit == null
                      ? AppTranslations.pick(
                          lang,
                          en: 'Log New Housing Society',
                          mr: 'नवीन सोसायटी नोंदवा',
                          hi: 'नई हाउसिंग सोसायटी दर्ज करें',
                        )
                      : AppTranslations.pick(
                          lang,
                          en: 'Edit Society Info',
                          mr: 'सोसायटी माहिती सुधारा',
                          hi: 'सोसायटी जानकारी संपादित करें',
                        ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Register society committee details, chairman and voter base.',
                    mr: 'प्रभागातील सोसायटी चेअरमन, सेक्रेटरी व मतदारांची नोंद',
                    hi: 'वार्ड में सोसायटी समिति, चेयरमैन और मतदाता विवरण दर्ज करें।',
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
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    children: [
                      // Row 1: Society Name (English) & Society Name (Marathi)
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
                                    en: 'Society Name (English)',
                                    mr: 'सोसायटीचे नाव (इंग्रजी)',
                                    hi: 'सोसायटी का नाम (अंग्रेजी)',
                                  ),
                                ),
                                TextField(
                                  controller: nameEnCtrl,
                                  decoration: inputDec(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Gokuldham CHS',
                                      mr: 'उदा. Gokuldham CHS',
                                      hi: 'उदा. Gokuldham CHS',
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
                                fieldLabel(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Society Name (Marathi)',
                                    mr: 'सोसायटीचे नाव (मराठी)',
                                    hi: 'सोसायटी का नाम (मराठी)',
                                  ),
                                  isRequired: true,
                                ),
                                TextField(
                                  controller: nameMrCtrl,
                                  decoration: inputDec(
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
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 2: Area / Neighborhood & Detailed Address
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
                                    en: 'Area / Neighborhood',
                                    mr: 'परिसर / गल्ली भाग',
                                    hi: 'क्षेत्र / मोहल्ला',
                                  ),
                                ),
                                TextField(
                                  controller: areaCtrl,
                                  decoration: inputDec(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Shanti Nagar',
                                      mr: 'उदा. शांती नगर',
                                      hi: 'उदा. शांति नगर',
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
                                fieldLabel(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Detailed Address',
                                    mr: 'सोसायटी पत्ता',
                                    hi: 'विस्तृत पता',
                                  ),
                                ),
                                TextField(
                                  controller: addressCtrl,
                                  decoration: inputDec(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Plot 12, Road 5',
                                      mr: 'उदा. प्लॉट १२, रोड ५',
                                      hi: 'उदा. प्लॉट १२, रोड ५',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 3: Chairman Name & Chairman Mobile
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
                                    en: 'Chairman Name',
                                    mr: 'चेअरमन नाव',
                                    hi: 'चेयरमैन का नाम',
                                  ),
                                ),
                                TextField(
                                  controller: chairmanNameCtrl,
                                  decoration: inputDec(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Ashok Bhide',
                                      mr: 'उदा. अशोक भिडे',
                                      hi: 'उदा. अशोक भिड़े',
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
                                fieldLabel(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Chairman Mobile',
                                    mr: 'चेअरमन मोबाईल',
                                    hi: 'चेयरमैन मोबाइल',
                                  ),
                                ),
                                TextField(
                                  controller: chairmanPhoneCtrl,
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
                      const SizedBox(height: 14),

                      // Row 4: Secretary Name & Secretary Mobile
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
                                    en: 'Secretary Name',
                                    mr: 'सेक्रेटरी नाव',
                                    hi: 'सचिव का नाम',
                                  ),
                                ),
                                TextField(
                                  controller: secretaryNameCtrl,
                                  decoration: inputDec(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g. Aatmaram Bhide',
                                      mr: 'उदा. आत्माराम भिडे',
                                      hi: 'उदा. आत्माराम भिड़े',
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
                                fieldLabel(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Secretary Mobile',
                                    mr: 'सेक्रेटरी मोबाईल',
                                    hi: 'सचिव मोबाइल',
                                  ),
                                ),
                                TextField(
                                  controller: secretaryPhoneCtrl,
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
                      const SizedBox(height: 14),

                      // Row 5: Total Voters & Favourable Voters
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
                                    en: 'Total Voters Count',
                                    mr: 'एकूण मतदार संख्या',
                                    hi: 'कुल मतदाता संख्या',
                                  ),
                                ),
                                TextField(
                                  controller: votersCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: inputDec(
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
                                fieldLabel(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Favourable Voters Count',
                                    mr: 'फेवर मतदार संख्या (आपले समर्थक)',
                                    hi: 'अनुकूल मतदाता संख्या (समर्थक)',
                                  ),
                                ),
                                TextField(
                                  controller: favVotersCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: inputDec(
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

                      // Notes / Grievances textarea
                      fieldLabel(
                        AppTranslations.pick(
                          lang,
                          en: 'Society Grievances / Special Notes',
                          mr: 'सोसायटीमधील प्रमुख समस्या / विशेष नोंदी',
                          hi: 'सोसायटी की प्रमुख समस्याएं / विशेष नोट्स',
                        ),
                      ),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: inputDec(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Potholes on entryway, streetlights non-functional, water line needs work...',
                            mr: 'उदा. कचरा समस्या, पाणी वेळेवर न मिळणे, रस्ते खराब असणे...',
                            hi: 'उदा. कचरा समस्या, समय पर पानी न मिलना, सड़क मरम्मत...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status Radio Selection
                      fieldLabel(
                        AppTranslations.pick(
                          lang,
                          en: 'Status',
                          mr: 'सोसायटी स्थिती',
                          hi: 'सोसायटी की स्थिति',
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
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Active',
                                    mr: 'सक्रिय',
                                    hi: 'सक्रिय',
                                  ),
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
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Inactive',
                                    mr: 'निष्क्रिय',
                                    hi: 'निष्क्रिय',
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons: Cancel & Save Details
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
                                AppTranslations.pick(
                                  lang,
                                  en: 'Cancel',
                                  mr: 'रद्द करा',
                                  hi: 'रद्द करें',
                                ),
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

                                final model = HousingSocietyModel(
                                  id: societyToEdit?.id ?? 'soc-${DateTime.now().millisecondsSinceEpoch}',
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
                                  createdAt: societyToEdit?.createdAt ?? DateTime.now(),
                                );

                                final messenger = ScaffoldMessenger.of(context);
                                final repo = ref.read(housingSocietyRepoProvider);
                                if (societyToEdit == null) {
                                  await repo.addSociety(model);
                                } else {
                                  await repo.updateSociety(model);
                                }

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (!mounted) return;
                                _loadData();

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      societyToEdit == null
                                          ? AppTranslations.pick(
                                              lang,
                                              en: 'Society registered successfully!',
                                              mr: 'नवीन सोसायटी नोंदणी यशस्वी झाली!',
                                              hi: 'सोसायटी सफलतापूर्वक पंजीकृत हो गई!',
                                            )
                                          : AppTranslations.pick(
                                              lang,
                                              en: 'Details updated successfully!',
                                              mr: 'माहिती जतन केली!',
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
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                societyToEdit == null
                                    ? AppTranslations.pick(
                                        lang,
                                        en: 'Save Details',
                                        mr: 'माहिती जतन करा',
                                        hi: 'विवरण सहेजें',
                                      )
                                    : AppTranslations.pick(
                                        lang,
                                        en: 'Save Changes',
                                        mr: 'बदल जतन करा',
                                        hi: 'बदलाव सहेजें',
                                      ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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

  void _confirmDelete(HousingSocietyModel soc) {
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
          soc.displayNameFor(lang),
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
              await repo.deleteSociety(soc.id);
              if (!mounted) return;
              _loadData();
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
    final totalFormatted = AppTranslations.formatDigits(_societies.length, lang);

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
                en: 'Housing Societies',
                mr: 'सोसायटी चेअरमन व मतदार',
                hi: 'हाउसिंग सोसायटियां',
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
                en: 'Housing societies & RWA directory',
                mr: 'सहकारी गृहनिर्माण संस्था व आरडब्ल्यूए निर्देशिका',
                hi: 'आवासीय सोसायटियां और आरडब्ल्यूए निर्देशिका',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          AppTranslations.pick(
            lang,
            en: 'New Society',
            mr: 'नवीन सोसायटी',
            hi: 'नई सोसायटी',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 4 KPI Summary Widgets
              _buildStatsGrid(lang),

              const SizedBox(height: 16),

              // Search & Filter Box
              _buildSearchAndFilters(lang),

              const SizedBox(height: 16),

              // Mode Toggle & Result Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Total Societies: $totalFormatted',
                        mr: 'एकूण सोसायट्या: $totalFormatted',
                        hi: 'कुल सोसायटियां: $totalFormatted',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.grid_view_rounded,
                            size: 20,
                            color: _viewMode == 0 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                          ),
                          tooltip: AppTranslations.pick(lang, en: 'Card View', mr: 'कार्ड दृश्य', hi: 'कार्ड दृश्य'),
                          onPressed: () => setState(() => _viewMode = 0),
                        ),
                        Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                        IconButton(
                          icon: Icon(
                            Icons.table_chart_outlined,
                            size: 20,
                            color: _viewMode == 1 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                          ),
                          tooltip: AppTranslations.pick(lang, en: 'Table View', mr: 'तक्ता दृश्य', hi: 'तालिका दृश्य'),
                          onPressed: () => setState(() => _viewMode = 1),
                        ),
                        Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                        const SizedBox(width: 4),
                        AppPdfButton.icon(
                          tooltip: AppTranslations.getDownloadReport(lang),
                          onPressed: () => HousingSocietyReportGenerator.generateAndPrintReport(
                            context: context,
                            societies: _societies,
                            lang: lang,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Content View
              if (_isLoading)
                const AppShimmerList(count: 6)
              else if (_societies.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.apartment_outlined, size: 54, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No societies found.',
                          mr: 'कोणतीही सोसायटी आढळली नाही.',
                          hi: 'कोई सोसायटी नहीं मिली।',
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Change search filters or register a new society.',
                          mr: 'शोध फिल्टर बदला किंवा नवीन सोसायटी नोंदवा.',
                          hi: 'खोज फ़िल्टर बदलें या नई सोसायटी पंजीकृत करें।',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openAddEditModal(),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Register Society',
                            mr: 'सोसायटी नोंदवा',
                            hi: 'सोसायटी पंजीकृत करें',
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
                  _buildCardsView(lang)
                else
                  _buildTableView(lang),
                AppLoadMoreFooter(
                  currentCount: _visibleSocieties.length,
                  totalCount: _societies.length,
                  pageSize: 20,
                  onLoadMore: () => setState(() => _displayedLimit += 20),
                  label: AppTranslations.pick(
                    lang,
                    en: 'societies',
                    mr: 'सोसायट्या',
                    hi: 'सोसायटियां',
                  ),
                  isMarathi: lang == 'mr',
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(String lang) {
    final total = _stats['total'] ?? 0;
    final voters = _stats['voters'] ?? 0;
    final fav = _stats['favourable'] ?? 0;
    final pct = _stats['supportPercentage'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 1.7 : 1.45,
          children: [
            _buildStatCard(
              title: AppTranslations.pick(lang, en: 'Total Societies', mr: 'एकूण सोसायट्या', hi: 'कुल सोसायटियां'),
              count: AppTranslations.formatDigits(total, lang),
              icon: Icons.apartment_rounded,
              color: const Color(0xFF4F46E5),
              bgColor: const Color(0xFFEEF2FF),
            ),
            _buildStatCard(
              title: AppTranslations.pick(lang, en: 'Total Voters', mr: 'एकूण मतदार', hi: 'कुल मतदाता'),
              count: AppTranslations.formatDigits(voters, lang),
              icon: Icons.groups_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
            ),
            _buildStatCard(
              title: AppTranslations.pick(lang, en: 'Favourable Voters', mr: 'अनुकूल मतदार', hi: 'अनुकूल मतदाता'),
              count: AppTranslations.formatDigits(fav, lang),
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              bgColor: const Color(0xFFECFDF5),
            ),
            _buildStatCard(
              title: AppTranslations.pick(lang, en: 'Estimated Support', mr: 'अंदाजे समर्थन', hi: 'अनुमानित समर्थन'),
              count: '${AppTranslations.formatDigits(pct, lang)}%',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    count,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() => _displayedLimit = 20);
              _loadData();
            },
            decoration: InputDecoration(
              hintText: AppTranslations.pick(
                lang,
                en: 'Search society name, chairman, secretary or area...',
                mr: 'सोसायटीचे नाव, चेअरमन, सेक्रेटरी किंवा परिसर शोधा...',
                hi: 'सोसायटी का नाम, चेयरमैन, सचिव या क्षेत्र खोजें...',
              ),
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _displayedLimit = 20);
                        _loadData();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Area Filter Dropdown
              Expanded(
                child: AppDropdown<String>(
                  title: AppTranslations.pick(
                    lang,
                    en: 'Filter by Area',
                    mr: 'परिसरानुसार फिल्टर',
                    hi: 'क्षेत्र के अनुसार फ़िल्टर',
                  ),
                  value: _selectedArea,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(AppTranslations.getAllAreas(lang))),
                    ..._areas.where((a) => a.toLowerCase() != 'all').map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(AppTranslations.getAreaName(a, lang), overflow: TextOverflow.ellipsis),
                          ),
                        ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedArea = val;
                        _displayedLimit = 20;
                      });
                      _loadData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Status Filter Dropdown
              Expanded(
                child: AppDropdown<String>(
                  title: AppTranslations.pick(
                    lang,
                    en: 'Filter by Status',
                    mr: 'स्थितीनुसार फिल्टर',
                    hi: 'स्थिति के अनुसार फ़िल्टर',
                  ),
                  value: _selectedStatus,
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(AppTranslations.pick(lang, en: 'All Status', mr: 'सर्व स्थिती', hi: 'सभी स्थिति')),
                    ),
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
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                        _displayedLimit = 20;
                      });
                      _loadData();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView(String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoCol = constraints.maxWidth > 700;
        if (isTwoCol) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: _visibleSocieties.length,
            itemBuilder: (context, index) => _buildSocietyCard(_visibleSocieties[index], lang),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _visibleSocieties.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) => _buildSocietyCard(_visibleSocieties[index], lang),
        );
      },
    );
  }

  Widget _buildSocietyCard(HousingSocietyModel soc, String lang) {
    final supportPct = soc.supportPercentage;
    final chairmanCopyLabel = AppTranslations.pick(lang, en: 'Chairman Mobile', mr: 'चेअरमन मोबाईल', hi: 'चेयरमैन मोबाइल');
    final secretaryCopyLabel = AppTranslations.pick(lang, en: 'Secretary Mobile', mr: 'सेक्रेटरी मोबाईल', hi: 'सचिव मोबाइल');
    final isActive = soc.status == 'Active';
    final statusLabel = isActive
        ? AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय')
        : AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HousingSocietyDetailScreen(society: soc),
            ),
          ).then((res) { if (res == true) _loadData(showLoading: false); });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title & Action Icons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTranslatedText(
                          soc.displayNameFor(lang),
                          isName: true,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Cooperative Housing Society',
                            mr: 'सहकारी गृहनिर्माण संस्था',
                            hi: 'सहकारी आवास समिति',
                          ),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                        tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _openAddEditModal(soc),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                        tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmDelete(soc),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Chairman & Secretary Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Chairman
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Chairman: ', mr: 'चेअरमन: ', hi: 'चेयरमैन: '),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                              Flexible(
                                child: soc.chairmanName.isNotEmpty
                                    ? AppTranslatedText(
                                        soc.chairmanName,
                                        isName: true,
                                        targetLanguage: lang,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      )
                                    : const Text(
                                        '-',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (soc.chairmanMobile.isNotEmpty)
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _makePhoneCall(soc.chairmanMobile),
                                child: Text(
                                  AppTranslations.formatDigits(soc.chairmanMobile, lang),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copyToClipboard(soc.chairmanMobile, chairmanCopyLabel),
                                child: const Icon(Icons.copy, size: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          )
                        else
                          const Text('-', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    const Divider(height: 12),
                    // Secretary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                AppTranslations.pick(lang, en: 'Secretary: ', mr: 'सेक्रेटरी: ', hi: 'सचिव: '),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                              Flexible(
                                child: soc.secretaryName.isNotEmpty
                                    ? AppTranslatedText(
                                        soc.secretaryName,
                                        isName: true,
                                        targetLanguage: lang,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      )
                                    : const Text(
                                        '-',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (soc.secretaryMobile.isNotEmpty)
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _makePhoneCall(soc.secretaryMobile),
                                child: Text(
                                  AppTranslations.formatDigits(soc.secretaryMobile, lang),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copyToClipboard(soc.secretaryMobile, secretaryCopyLabel),
                                child: const Icon(Icons.copy, size: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          )
                        else
                          const Text('-', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Voter Support Bar & Counts
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Total Voters: ${AppTranslations.formatDigits(soc.voterCount, lang)}',
                              mr: 'एकूण मतदार: ${AppTranslations.formatDigits(soc.voterCount, lang)}',
                              hi: 'कुल मतदाता: ${AppTranslations.formatDigits(soc.voterCount, lang)}',
                            ),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Favourable: ${AppTranslations.formatDigits(soc.favourableVoterCount, lang)}',
                              mr: 'अनुकूल: ${AppTranslations.formatDigits(soc.favourableVoterCount, lang)}',
                              hi: 'अनुकूल: ${AppTranslations.formatDigits(soc.favourableVoterCount, lang)}',
                            ),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: '${AppTranslations.formatDigits(supportPct, lang)}% Support',
                            mr: '${AppTranslations.formatDigits(supportPct, lang)}% समर्थन',
                            hi: '${AppTranslations.formatDigits(supportPct, lang)}% समर्थन',
                          ),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: soc.voterCount > 0 ? (soc.favourableVoterCount / soc.voterCount).clamp(0.0, 1.0) : 0.0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Area & Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppTranslatedText(
                            soc.area.isNotEmpty
                                ? AppTranslations.getAreaName(soc.area, lang)
                                : AppTranslations.getAreaName('Ward 12', lang),
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
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
                ],
              ),

              // Notes alert preview if present
              if (soc.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 13, color: Color(0xFFB45309)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AppTranslatedText(
                          soc.notes,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF0284C7)),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            columns: [
              DataColumn(label: Text(AppTranslations.pick(lang, en: '#', mr: 'क्र.', hi: 'क्र.'))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Society Name', mr: 'सोसायटीचे नाव', hi: 'सोसायटी का नाम'))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र'))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Chairman & Mobile', mr: 'चेअरमन व मोबाईल', hi: 'चेयरमैन और मोबाइल'))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Secretary & Mobile', mr: 'सेक्रेटरी व मोबाईल', hi: 'सचिव और मोबाइल'))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Total Voters', mr: 'एकूण मतदार', hi: 'कुल मतदाता'))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Favourable Voters', mr: 'अनुकूल मतदार', hi: 'अनुकूल मतदाता'))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Support %', mr: 'समर्थन %', hi: 'समर्थन %'))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Action', mr: 'कृती', hi: 'कार्रवाई'))),
            ],
            rows: List.generate(_visibleSocieties.length, (index) {
              final soc = _visibleSocieties[index];
              final isActive = soc.status == 'Active';
              final statusLabel = isActive
                  ? AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय')
                  : AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय');

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                  return index.isEven ? const Color(0xFFF8FAFC) : Colors.white;
                }),
                cells: [
                  DataCell(Text(AppTranslations.formatDigits(index + 1, lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HousingSocietyDetailScreen(society: soc),
                          ),
                        ).then((res) { if (res == true) _loadData(showLoading: false); });
                      },
                      child: AppTranslatedText(
                        soc.displayNameFor(lang),
                        isName: true,
                        targetLanguage: lang,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  DataCell(
                    soc.area.isNotEmpty
                        ? AppTranslatedText(
                            AppTranslations.getAreaName(soc.area, lang),
                            targetLanguage: lang,
                          )
                        : const Text('-'),
                  ),
                  DataCell(
                    soc.chairmanMobile.isNotEmpty
                        ? InkWell(
                            onTap: () => _makePhoneCall(soc.chairmanMobile),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (soc.chairmanName.isNotEmpty) ...[
                                  AppTranslatedText(
                                    soc.chairmanName,
                                    isName: true,
                                    targetLanguage: lang,
                                    style: const TextStyle(color: Color(0xFF0284C7), decoration: TextDecoration.underline),
                                  ),
                                  const Text(' ', style: TextStyle(color: Color(0xFF0284C7))),
                                ],
                                Text(
                                  '(${AppTranslations.formatDigits(soc.chairmanMobile, lang)})',
                                  style: const TextStyle(color: Color(0xFF0284C7), decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          )
                        : (soc.chairmanName.isNotEmpty
                            ? AppTranslatedText(soc.chairmanName, isName: true, targetLanguage: lang)
                            : const Text('-')),
                  ),
                  DataCell(
                    soc.secretaryMobile.isNotEmpty
                        ? InkWell(
                            onTap: () => _makePhoneCall(soc.secretaryMobile),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (soc.secretaryName.isNotEmpty) ...[
                                  AppTranslatedText(
                                    soc.secretaryName,
                                    isName: true,
                                    targetLanguage: lang,
                                    style: const TextStyle(color: Color(0xFF0284C7), decoration: TextDecoration.underline),
                                  ),
                                  const Text(' ', style: TextStyle(color: Color(0xFF0284C7))),
                                ],
                                Text(
                                  '(${AppTranslations.formatDigits(soc.secretaryMobile, lang)})',
                                  style: const TextStyle(color: Color(0xFF0284C7), decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          )
                        : (soc.secretaryName.isNotEmpty
                            ? AppTranslatedText(soc.secretaryName, isName: true, targetLanguage: lang)
                            : const Text('-')),
                  ),
                  DataCell(Text(AppTranslations.formatDigits(soc.voterCount, lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(AppTranslations.formatDigits(soc.favourableVoterCount, lang), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${AppTranslations.formatDigits(soc.supportPercentage, lang)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
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
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0284C7)),
                          tooltip: AppTranslations.pick(lang, en: 'View Details', mr: 'तपशील पहा', hi: 'विवरण देखें'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HousingSocietyDetailScreen(society: soc),
                              ),
                            ).then((res) { if (res == true) _loadData(showLoading: false); });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                          tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                          onPressed: () => _openAddEditModal(soc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                          onPressed: () => _confirmDelete(soc),
                        ),
                      ],
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

