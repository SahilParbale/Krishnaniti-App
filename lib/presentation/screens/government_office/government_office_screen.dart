import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/government_office_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/government_office_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'gov_office_report_generator.dart';
import 'government_office_detail_screen.dart';
import 'file_tracker_tab_view.dart';

class GovernmentOfficeScreen extends ConsumerStatefulWidget {
  const GovernmentOfficeScreen({super.key});

  @override
  ConsumerState<GovernmentOfficeScreen> createState() => _GovernmentOfficeScreenState();
}

class _GovernmentOfficeScreenState extends ConsumerState<GovernmentOfficeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _activeTab = 'Offices'; // 'Offices' | 'Cooperative'
  String _viewMode = 'grid'; // 'grid' | 'table'

  bool _isLoading = true;
  List<GovernmentOfficeModel> _allOffices = [];
  List<TeamMemberModel> _allStaff = [];

  int _displayedLimit = 20;

  List<GovernmentOfficeModel> get _visibleOffices =>
      _filteredOffices.take(_displayedLimit).toList();

  List<TeamMemberModel> get _visibleStaff =>
      _filteredStaff.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final officeRepo = ref.read(governmentOfficeRepoProvider);
      final teamRepo = ref.read(teamRepoProvider);
      final offices = await officeRepo.getOffices();
      final staff = await teamRepo.getTeamMembers(category: 'Cooperative');
      if (mounted) {
        setState(() {
          _allOffices = offices;
          _allStaff = staff;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<GovernmentOfficeModel> get _filteredOffices {
    final query = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim())
        .toLowerCase();
    if (query.isEmpty) return _allOffices;

    return _allOffices.where((o) {
      return o.name.toLowerCase().contains(query) ||
          o.officerName.toLowerCase().contains(query) ||
          o.contactNumber.toLowerCase().contains(query) ||
          o.address.toLowerCase().contains(query) ||
          o.area.toLowerCase().contains(query);
    }).toList();
  }

  List<TeamMemberModel> get _filteredStaff {
    final query = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim())
        .toLowerCase();
    if (query.isEmpty) return _allStaff;

    return _allStaff.where((s) {
      final inKeywords = s.keywords.any((k) => k.toLowerCase().contains(query));
      return s.name.toLowerCase().contains(query) ||
          (s.nameMarathi?.toLowerCase().contains(query) ?? false) ||
          s.mobile.contains(query) ||
          (s.area?.toLowerCase().contains(query) ?? false) ||
          s.role.toLowerCase().contains(query) ||
          inKeywords;
    }).toList();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final lang = ref.read(appLanguageProvider);
    final cleanNumber = AppTranslations.normalizeAsciiDigits(phoneNumber)
        .replaceAll(RegExp(r'[^0-9+]'), '');
    final formattedNum = AppTranslations.formatDigits(phoneNumber, lang);
    final callingMsg = AppTranslations.pick(
      lang,
      en: 'Calling $formattedNum...',
      mr: '$formattedNum वर कॉल करत आहे...',
      hi: '$formattedNum पर कॉल कर रहे हैं...',
    );
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(callingMsg)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(callingMsg)),
        );
      }
    }
  }

  Future<void> _openMaps(GovernmentOfficeModel office) async {
    final query = Uri.encodeComponent('${office.name}, ${office.address}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  static Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return AppFieldLabel(label: label, isRequired: isRequired);
  }

  static InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
      prefix: prefix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
    );
  }

  /// Unified Modal Bottom Sheet styled identically to Requests & Complaints, Letters, and Diary.
  /// Allows switching between Government Office and Cooperative Worker side-by-side so the user
  /// is not forced to exit the page to go to the second entity.
  void _showAddModal({String? initialTab, TeamMemberModel? editingStaff}) {
    final lang = ref.read(appLanguageProvider);
    String modalTab = editingStaff != null ? 'Cooperative' : (initialTab ?? _activeTab);

    // Office Form Controllers
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final officerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final areaCtrl = TextEditingController();

    // Staff Form Controllers
    final staffNameCtrl = TextEditingController(text: editingStaff?.name ?? '');
    String initMobile = editingStaff?.mobile ?? '';
    initMobile = initMobile.replaceAll('+91', '').trim();
    final staffMobileCtrl = TextEditingController(
      text: AppTranslations.formatDigits(initMobile, lang),
    );
    final staffRoleCtrl = TextEditingController(text: editingStaff?.role ?? '');
    final staffAreaCtrl = TextEditingController(text: editingStaff?.area ?? '');
    final staffKeywordsCtrl = TextEditingController(text: editingStaff?.keywords.join(', ') ?? '');

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. FIXED HEADER
                  AppModalHeader(
                    icon: Icons.account_balance_rounded,
                    title: editingStaff != null
                        ? AppTranslations.pick(
                            lang,
                            en: 'Edit Worker',
                            mr: 'कर्मचारी बदल करा',
                            hi: 'कर्मचारी संपादित करें',
                          )
                        : AppTranslations.pick(
                            lang,
                            en: 'Add New Entry',
                            mr: 'नवीन नोंद जोडा',
                            hi: 'नई प्रविष्टि जोड़ें',
                          ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Record government departments, ward offices and workers',
                      mr: 'प्रभागातील शासकीय कार्यालये व सहकारी कर्मचारी नोंदवा',
                      hi: 'सरकारी विभाग, वार्ड कार्यालय और सहयोगी कर्मचारी दर्ज करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),

                  // 2. SCROLLABLE BODY & BUTTONS
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: 14,
                        left: 18,
                        right: 18,
                        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tab Pills
                          if (editingStaff == null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _TabPill(
                                      label: AppTranslations.pick(
                                        lang,
                                        en: 'Government Office',
                                        mr: 'सरकारी कार्यालय',
                                        hi: 'सरकारी कार्यालय',
                                      ),
                                      icon: Icons.apartment_rounded,
                                      isActive: modalTab == 'Offices',
                                      onTap: () => setModalState(() => modalTab = 'Offices'),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _TabPill(
                                      label: AppTranslations.pick(
                                        lang,
                                        en: 'Cooperative Worker',
                                        mr: 'सहकारी कर्मचारी',
                                        hi: 'सहयोगी कर्मचारी',
                                      ),
                                      icon: Icons.handyman_rounded,
                                      isActive: modalTab == 'Cooperative',
                                      onTap: () => setModalState(() => modalTab = 'Cooperative'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // FORM A: Government Office
                          if (modalTab == 'Offices') ...[
                            _buildFieldLabel(
                              AppTranslations.pick(
                                lang,
                                en: 'Office Name',
                                mr: 'कार्यालयाचे नाव',
                                hi: 'कार्यालय का नाम',
                              ),
                              isRequired: true,
                            ),
                            TextField(
                              controller: nameCtrl,
                              decoration: _inputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. PMC Ward Office No. 12',
                                  mr: 'उदा. प्रभाग कार्यालय क्र. १२',
                                  hi: 'उदा. वार्ड कार्यालय क्र. १२',
                                ),
                                prefixIcon: Icons.apartment_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel(
                              AppTranslations.pick(
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
                              decoration: _inputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Near Shaniwar Wada, Pune - 411030',
                                  mr: 'उदा. शनिवार वाड्यासमोर, पुणे - ४११०३०',
                                  hi: 'उदा. शनिवार वाड़ा के पास, पुणे - ४११०३०',
                                ),
                                prefixIcon: Icons.location_on_outlined,
                              ),
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Officer In-charge',
                                          mr: 'अधिकारी / प्रमुख',
                                          hi: 'प्रभारी अधिकारी',
                                        ),
                                        isRequired: true,
                                      ),
                                      TextField(
                                        controller: officerCtrl,
                                        decoration: _inputDecoration(
                                          hintText: AppTranslations.pick(
                                            lang,
                                            en: 'e.g. Shri. Ramesh Gaikwad',
                                            mr: 'उदा. श्री. रमेश गायकवाड',
                                            hi: 'उदा. श्री रमेश गायकवाड़',
                                          ),
                                          prefixIcon: Icons.person_outline_rounded,
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
                                      _buildFieldLabel(
                                        AppTranslations.pick(
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
                                        decoration: _inputDecoration(
                                          hintText: AppTranslations.pick(
                                            lang,
                                            en: 'e.g. 020-25501140',
                                            mr: 'उदा. ०२०-२५५०११४०',
                                            hi: 'उदा. ०२०-२५५०११४०',
                                          ),
                                          prefixIcon: Icons.phone_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel(
                              AppTranslations.pick(
                                lang,
                                en: 'Location / Area',
                                mr: 'ठिकाण',
                                hi: 'स्थान / क्षेत्र',
                              ),
                              isRequired: true,
                            ),
                            TextField(
                              controller: areaCtrl,
                              decoration: _inputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Shaniwar Peth',
                                  mr: 'उदा. शनिवार पेठ',
                                  hi: 'उदा. शनिवार पेठ',
                                ),
                                prefixIcon: Icons.map_outlined,
                              ),
                            ),
                            const SizedBox(height: 24),

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

                                  final newOffice = GovernmentOfficeModel(
                                    id: 'gov-${DateTime.now().millisecondsSinceEpoch}',
                                    name: nameCtrl.text.trim(),
                                    officerName: officerCtrl.text.trim().isNotEmpty ? officerCtrl.text.trim() : 'Officer In-Charge',
                                    contactNumber: cleanPhone,
                                    address: addrCtrl.text.trim(),
                                    area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                                    createdAt: DateTime.now().toIso8601String(),
                                  );

                                  final repo = ref.read(governmentOfficeRepoProvider);
                                  await repo.addOffice(newOffice);
                                  await _loadData();

                                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Office added successfully!',
                                            mr: 'सरकारी कार्यालय यशस्वीरित्या जोडले गेले!',
                                            hi: 'सरकारी कार्यालय सफलतापूर्वक जोड़ा गया!',
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
                          ]

                          // FORM B: Cooperative Staff
                          else ...[
                            _buildFieldLabel(
                              AppTranslations.pick(
                                lang,
                                en: 'Name',
                                mr: 'नाव',
                                hi: 'नाम',
                              ),
                              isRequired: true,
                            ),
                            TextField(
                              controller: staffNameCtrl,
                              decoration: _inputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Ramesh Patil',
                                  mr: 'उदा. रमेश पाटील',
                                  hi: 'उदा. रमेश पाटिल',
                                ),
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Mobile Number',
                                          mr: 'मोबाइल नंबर',
                                          hi: 'मोबाइल नंबर',
                                        ),
                                        isRequired: true,
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            height: 44,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              border: Border.all(color: const Color(0xFFCBD5E1)),
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                            ),
                                            child: Text(
                                              '+${AppTranslations.formatDigits("91", lang)}',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                            ),
                                          ),
                                          Expanded(
                                            child: SizedBox(
                                              height: 44,
                                              child: TextField(
                                                controller: staffMobileCtrl,
                                                keyboardType: TextInputType.phone,
                                                maxLength: 10,
                                                decoration: InputDecoration(
                                                  counterText: '',
                                                  hintText: AppTranslations.formatDigits('9876543210', lang),
                                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                  enabledBorder: const OutlineInputBorder(
                                                    borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                                                    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                                  ),
                                                  focusedBorder: const OutlineInputBorder(
                                                    borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                                                    borderSide: BorderSide(color: Color(0xFF0284C7), width: 1.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Role / Designation',
                                          mr: 'भूमिका / पद',
                                          hi: 'भूमिका / पद',
                                        ),
                                        isRequired: true,
                                      ),
                                      SizedBox(
                                        height: 44,
                                        child: TextField(
                                          controller: staffRoleCtrl,
                                          decoration: _inputDecoration(
                                            hintText: AppTranslations.pick(
                                              lang,
                                              en: 'e.g. Electrician',
                                              mr: 'उदा. वायरमन',
                                              hi: 'उदा. इलेक्ट्रीशियन',
                                            ),
                                            prefixIcon: Icons.badge_outlined,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Area / Ward',
                                          mr: 'क्षेत्र / प्रभाग',
                                          hi: 'क्षेत्र / वार्ड',
                                        ),
                                      ),
                                      TextField(
                                        controller: staffAreaCtrl,
                                        decoration: _inputDecoration(
                                          hintText: AppTranslations.pick(
                                            lang,
                                            en: 'e.g. Ward 12',
                                            mr: 'उदा. प्रभाग १२',
                                            hi: 'उदा. वार्ड १२',
                                          ),
                                          prefixIcon: Icons.map_outlined,
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
                                      _buildFieldLabel(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Keywords',
                                          mr: 'ऑटो-कीवर्ड',
                                          hi: 'कीवर्ड',
                                        ),
                                      ),
                                      TextField(
                                        controller: staffKeywordsCtrl,
                                        decoration: _inputDecoration(
                                          hintText: AppTranslations.pick(
                                            lang,
                                            en: 'e.g. water, electric',
                                            mr: 'उदा. पाणी, वीज',
                                            hi: 'उदा. पानी, बिजली',
                                          ),
                                          prefixIcon: Icons.tag_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.handyman_rounded, size: 18),
                                onPressed: () async {
                                  if (staffNameCtrl.text.trim().isEmpty || staffRoleCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Please fill name and role',
                                            mr: 'कृपया नाव आणि पद प्रविष्ट करा',
                                            hi: 'कृपया नाम और पद दर्ज करें',
                                          ),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  final cleanMobile = AppTranslations.normalizeAsciiDigits(
                                    staffMobileCtrl.text.trim(),
                                  ).replaceAll(RegExp(r'[^0-9]'), '');
                                  if (cleanMobile.length != 10) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Please enter valid 10-digit mobile number',
                                            mr: 'कृपया वैध १० अंकी मोबाइल क्रमांक प्रविष्ट करा',
                                            hi: 'कृपया मान्य १० अंकों का मोबाइल नंबर दर्ज करें',
                                          ),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  final fullMobile = '+91$cleanMobile';
                                  final keywordsList = staffKeywordsCtrl.text
                                      .split(',')
                                      .map((k) => k.trim())
                                      .where((k) => k.isNotEmpty)
                                      .toList();

                                  final teamRepo = ref.read(teamRepoProvider);

                                  if (editingStaff != null) {
                                    final updated = editingStaff.copyWith(
                                      name: staffNameCtrl.text.trim(),
                                      mobile: fullMobile,
                                      role: staffRoleCtrl.text.trim(),
                                      area: staffAreaCtrl.text.trim().isNotEmpty ? staffAreaCtrl.text.trim() : null,
                                      category: 'Cooperative',
                                      keywords: keywordsList,
                                    );
                                    await teamRepo.updateTeamMember(updated);
                                  } else {
                                    final newStaff = TeamMemberModel(
                                      id: 'stf-${DateTime.now().millisecondsSinceEpoch}',
                                      name: staffNameCtrl.text.trim(),
                                      mobile: fullMobile,
                                      role: staffRoleCtrl.text.trim(),
                                      area: staffAreaCtrl.text.trim().isNotEmpty ? staffAreaCtrl.text.trim() : null,
                                      category: 'Cooperative',
                                      keywords: keywordsList,
                                      joinedDate: DateTime.now(),
                                      canAssignWork: false,
                                    );
                                    await teamRepo.addTeamMember(newStaff);
                                  }

                                  await _loadData();

                                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          editingStaff != null
                                              ? AppTranslations.pick(
                                                  lang,
                                                  en: 'Worker updated successfully!',
                                                  mr: 'कर्मचारी माहिती अद्यतनित केली!',
                                                  hi: 'कर्मचारी जानकारी अपडेट की गई!',
                                                )
                                              : AppTranslations.pick(
                                                  lang,
                                                  en: 'Worker added successfully!',
                                                  mr: 'कर्मचारी यशस्वीरित्या जोडला गेला!',
                                                  hi: 'कर्मचारी सफलतापूर्वक जोड़ा गया!',
                                                ),
                                        ),
                                        backgroundColor: const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                label: Text(
                                  editingStaff != null
                                      ? AppTranslations.pick(
                                          lang,
                                          en: 'Update',
                                          mr: 'अपडेट करा',
                                          hi: 'अपडेट करें',
                                        )
                                      : AppTranslations.pick(
                                          lang,
                                          en: 'Save',
                                          mr: 'जतन करा',
                                          hi: 'सहेजें',
                                        ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
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

  void _showDeleteConfirmation(GovernmentOfficeModel item) {
    final lang = ref.read(appLanguageProvider);
    final displayName =
        DynamicTranslationService.getCachedTranslation(item.name, lang) ?? item.name;
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
                  en: 'Delete Office Entry',
                  mr: 'कार्यालय हटवा',
                  hi: 'कार्यालय प्रविष्टि हटाएं',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to delete "$displayName"? This cannot be undone.',
            mr: 'आपण खात्रीपूर्वक "$displayName" हे कार्यालय हटवू इच्छिता? ही क्रिया पूर्ववत करता येणार नाही.',
            hi: 'क्या आप वाकई "$displayName" को हटाना चाहते हैं? यह पूर्ववत नहीं किया जा सकता।',
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
              final repo = ref.read(governmentOfficeRepoProvider);
              await repo.deleteOffice(item.id);
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Office entry deleted',
                        mr: 'कार्यालय हटवले गेले',
                        hi: 'कार्यालय हटाया गया',
                      ),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

  void _showDeleteStaffConfirmation(TeamMemberModel member) {
    final lang = ref.read(appLanguageProvider);
    final rawMemberName = member.displayName;
    final displayName = DynamicTranslationService.getCachedTranslation(
          rawMemberName,
          lang,
          isName: true,
        ) ??
        rawMemberName;
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
                  en: 'Delete Worker',
                  mr: 'कर्मचारी हटवा',
                  hi: 'कर्मचारी हटाएं',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to delete "$displayName"? This action cannot be undone.',
            mr: 'आपण खात्रीपूर्वक "$displayName" यांना यादीतून हटवू इच्छिता?',
            hi: 'क्या आप वाकई "$displayName" को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
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
              final teamRepo = ref.read(teamRepoProvider);
              await teamRepo.deleteTeamMember(member.id);
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Worker deleted successfully',
                        mr: 'कर्मचारी हटवला गेला',
                        hi: 'कर्मचारी सफलतापूर्वक हटाया गया',
                      ),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final displayedOffices = _filteredOffices;
    final displayedStaff = _filteredStaff;

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
        drawer: const NagarsevakAppDrawer(currentTabIndex: 0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
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
                _activeTab == 'Offices'
                    ? AppTranslations.pick(
                        lang,
                        en: 'Government Offices',
                        mr: 'सरकारी कार्यालये',
                        hi: 'सरकारी कार्यालय',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Government Employees',
                        mr: 'शासकीय कर्मचारी',
                        hi: 'सरकारी कर्मचारी',
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
                  en: 'Directory of important government offices and contacts',
                  mr: 'महत्वाच्या सरकारी कार्यालयांची व संपर्काची यादी',
                  hi: 'महत्वपूर्ण सरकारी कार्यालयों और संपर्कों की निर्देशिका',
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
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: Icon(_activeTab == 'Offices' ? Icons.add_business_rounded : Icons.person_add_alt_1_rounded),
          label: Text(
            _activeTab == 'Offices'
                ? AppTranslations.pick(
                    lang,
                    en: 'Add Office',
                    mr: 'नवीन कार्यालय',
                    hi: 'कार्यालय जोड़ें',
                  )
                : AppTranslations.pick(
                    lang,
                    en: 'Add Staff',
                    mr: 'नवीन कर्मचारी',
                    hi: 'कर्मचारी जोड़ें',
                  ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => _showAddModal(initialTab: _activeTab),
        ),
        body: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: AppShimmerList(count: 6),
              )
            : Column(
                children: [
                  _buildTabBar(lang),
                  Expanded(
                    child: _activeTab == 'Files'
                        ? const FileTrackerTabView()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Search Bar & Action Buttons
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _searchCtrl,
                                            onChanged: (_) => setState(() => _displayedLimit = 20),
                                            decoration: InputDecoration(
                                              hintText: _activeTab == 'Offices'
                                                  ? AppTranslations.pick(
                                                      lang,
                                                      en: 'Search by office, officer or area...',
                                                      mr: 'कार्यालय, अधिकारी किंवा विभाग शोधा...',
                                                      hi: 'कार्यालय, अधिकारी या क्षेत्र खोजें...',
                                                    )
                                                  : AppTranslations.pick(
                                                      lang,
                                                      en: 'Search Name or Mobile...',
                                                      mr: 'नाव किंवा मोबाइल नंबर शोधा...',
                                                      hi: 'नाम या मोबाइल नंबर खोजें...',
                                                    ),
                                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                                              suffixIcon: _searchCtrl.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(Icons.clear, size: 18),
                                                      onPressed: () {
                                                        _searchCtrl.clear();
                                                        setState(() => _displayedLimit = 20);
                                                      },
                                                    )
                                                  : null,
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_activeTab == 'Offices') ...[
                                          const SizedBox(width: 8),
                                          Tooltip(
                                            message: _viewMode == 'grid'
                                                ? AppTranslations.pick(
                                                    lang,
                                                    en: 'Table View',
                                                    mr: 'तक्ता दृश्य',
                                                    hi: 'तालिका दृश्य',
                                                  )
                                                : AppTranslations.pick(
                                                    lang,
                                                    en: 'Grid View',
                                                    mr: 'ग्रिड दृश्य',
                                                    hi: 'ग्रिड दृश्य',
                                                  ),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _viewMode = _viewMode == 'grid' ? 'table' : 'grid';
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                height: 48,
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                ),
                                                child: Icon(
                                                  _viewMode == 'grid' ? Icons.table_chart_rounded : Icons.grid_view_rounded,
                                                  size: 20,
                                                  color: const Color(0xFF0284C7),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          AppPdfButton.icon(
                                            tooltip: AppTranslations.getDownloadReport(lang),
                                            onPressed: () {
                                              GovOfficeReportGenerator.generateAndPrintOfficeReport(
                                                offices: displayedOffices,
                                                lang: lang,
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Content Views
                                  if (_activeTab == 'Offices') ...[
                                    if (displayedOffices.isEmpty)
                                      _buildEmptyState(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'No Government Offices Found',
                                          mr: 'कोणतेही कार्यालय सापडले नाही',
                                          hi: 'कोई सरकारी कार्यालय नहीं मिला',
                                        ),
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Try adjusting your search terms or add an office.',
                                          mr: 'कृपया शोध निकष बदला किंवा नवीन कार्यालय जोडा.',
                                          hi: 'कृपया खोज शब्द बदलें या नया कार्यालय जोड़ें।',
                                        ),
                                      )
                                    else ...[
                                      if (_viewMode == 'grid')
                                        _buildOfficeGrid(_visibleOffices, lang)
                                      else
                                        _buildOfficeTable(_visibleOffices, lang),
                                      AppLoadMoreFooter(
                                        currentCount: _visibleOffices.length,
                                        totalCount: displayedOffices.length,
                                        pageSize: 20,
                                        onLoadMore: () => setState(() => _displayedLimit += 20),
                                        label: AppTranslations.pick(
                                          lang,
                                          en: 'offices',
                                          mr: 'कार्यालये',
                                          hi: 'कार्यालय',
                                        ),
                                        isMarathi: lang == 'mr',
                                      ),
                                    ],
                                  ] else ...[
                                    if (displayedStaff.isEmpty)
                                      _buildEmptyState(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'No Cooperative Workers Found',
                                          mr: 'कोणतेही सहकारी कर्मचारी आढळले नाहीत',
                                          hi: 'कोई सहयोगी कर्मचारी नहीं मिला',
                                        ),
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Start by adding workers to this category.',
                                          mr: 'कृपया या श्रेणीमध्ये नवीन कर्मचारी जोडा.',
                                          hi: 'कृपया इस श्रेणी में नए कर्मचारी जोड़ें।',
                                        ),
                                      )
                                    else ...[
                                      _buildStaffGrid(_visibleStaff, lang),
                                      AppLoadMoreFooter(
                                        currentCount: _visibleStaff.length,
                                        totalCount: displayedStaff.length,
                                        pageSize: 20,
                                        onLoadMore: () => setState(() => _displayedLimit += 20),
                                        label: AppTranslations.pick(
                                          lang,
                                          en: 'workers',
                                          mr: 'कर्मचारी',
                                          hi: 'कर्मचारी',
                                        ),
                                        isMarathi: lang == 'mr',
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBar(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _activeTab = 'Offices';
                _searchCtrl.clear();
                _displayedLimit = 20;
              }),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'Offices' ? const Color(0xFFE0F2FE) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 18,
                      color: _activeTab == 'Offices' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Offices',
                        mr: 'कार्यालये',
                        hi: 'कार्यालय',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _activeTab == 'Offices' ? FontWeight.bold : FontWeight.w600,
                        color: _activeTab == 'Offices' ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _activeTab = 'Cooperative';
                _searchCtrl.clear();
                _displayedLimit = 20;
              }),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'Cooperative' ? const Color(0xFFE0F2FE) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.handyman_rounded,
                      size: 18,
                      color: _activeTab == 'Cooperative' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Cooperative',
                        mr: 'सहकारी कर्मचारी',
                        hi: 'सहयोगी कर्मचारी',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _activeTab == 'Cooperative' ? FontWeight.bold : FontWeight.w600,
                        color: _activeTab == 'Cooperative' ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String desc) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_city_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeGrid(List<GovernmentOfficeModel> items, String lang) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = items[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Icon(Icons.apartment_rounded, size: 22, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTranslatedText(
                          item.name,
                          targetLanguage: lang,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppTranslatedText(
                            AppTranslations.getAreaName(item.area, lang),
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                    tooltip: AppTranslations.pick(
                      lang,
                      en: 'Delete',
                      mr: 'हटवा',
                      hi: 'हटाएं',
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showDeleteConfirmation(item),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Officer In-Charge
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AppTranslatedText(
                      item.officerName,
                      isName: true,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AppTranslatedText(
                      item.address,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Contact
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    AppTranslations.formatDigits(item.contactNumber, lang),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Actions: Call Now & Maps & Details
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.call, size: 16),
                      label: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Call Now',
                          mr: 'कॉल करा',
                          hi: 'कॉल करें',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _makePhoneCall(item.contactNumber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: AppTranslations.pick(
                      lang,
                      en: 'Directions',
                      mr: 'नकाशा / मार्ग',
                      hi: 'दिशा-निर्देश',
                    ),
                    child: InkWell(
                      onTap: () => _openMaps(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(Icons.directions_outlined, size: 18, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: AppTranslations.getDetails(lang),
                    child: InkWell(
                      onTap: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GovernmentOfficeDetailScreen(office: item)),
                        );
                        if (res == true) _loadData();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffGrid(List<TeamMemberModel> items, String lang) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final member = items[index];
        final rawName = lang == 'mr' &&
                member.nameMarathi != null &&
                member.nameMarathi!.isNotEmpty
            ? member.nameMarathi!
            : member.displayName;
        final rawRole = lang == 'mr'
            ? member.roleLabelMarathi
            : AppTranslations.getRoleName(member.role, lang);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Icon(Icons.handyman_rounded, size: 22, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTranslatedText(
                          rawName,
                          isName: true,
                          targetLanguage: lang,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AppTranslatedText(
                          rawRole,
                          targetLanguage: lang,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                        tooltip: AppTranslations.pick(
                          lang,
                          en: 'Edit',
                          mr: 'बदल करा',
                          hi: 'संपादित करें',
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showAddModal(editingStaff: member),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                        tooltip: AppTranslations.pick(
                          lang,
                          en: 'Delete',
                          mr: 'हटवा',
                          hi: 'हटाएं',
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showDeleteStaffConfirmation(member),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Mobile
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    AppTranslations.formatDigits(member.mobile, lang),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ],
              ),

              // Area (if present)
              if (member.area != null && member.area!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AppTranslatedText(
                        AppTranslations.getAreaName(member.area!, lang),
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],

              // Keywords chips (if present)
              if (member.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: member.keywords.map((k) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: AppTranslatedText(
                        k,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),

              // Call Now Button
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.call, size: 16),
                  label: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Call Now',
                      mr: 'कॉल करा',
                      hi: 'कॉल करें',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _makePhoneCall(member.mobile),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfficeTable(List<GovernmentOfficeModel> items, String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: [
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Office Name', mr: 'कार्यालय नाव', hi: 'कार्यालय नाम'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Address', mr: 'पत्ता', hi: 'पता'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Officer In-Charge', mr: 'अधिकारी', hi: 'प्रभारी अधिकारी'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Contact No', mr: 'संपर्क क्रमांक', hi: 'संपर्क नंबर'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Location', mr: 'ठिकाण', hi: 'स्थान'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Actions', mr: 'कृती', hi: 'कार्रवाई'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;

              return DataRow(
                cells: [
                  DataCell(Text(AppTranslations.formatDigits(idx, lang))),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: AppTranslatedText(
                        item.name,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: AppTranslatedText(
                        item.address,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    AppTranslatedText(
                      item.officerName,
                      isName: true,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    InkWell(
                      onTap: () => _makePhoneCall(item.contactNumber),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.call, size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            AppTranslations.formatDigits(item.contactNumber, lang),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    AppTranslatedText(
                      AppTranslations.getAreaName(item.area, lang),
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone_forwarded, size: 16, color: Color(0xFF16A34A)),
                          tooltip: AppTranslations.pick(lang, en: 'Call', mr: 'कॉल करा', hi: 'कॉल करें'),
                          onPressed: () => _makePhoneCall(item.contactNumber),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0284C7)),
                          tooltip: AppTranslations.pick(lang, en: 'View Details', mr: 'तपशील पहा', hi: 'विवरण देखें'),
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GovernmentOfficeDetailScreen(office: item)),
                            );
                            if (res == true) _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}