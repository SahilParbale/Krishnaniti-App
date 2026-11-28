import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'team_member_profile_screen.dart';
import 'team_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  List<TeamMemberModel> _allMembers = [];
  Map<String, int> _teamStats = {};
  String _selectedCategory = 'All'; // 'All', 'Office', 'Party', 'Cooperative'
  String _viewMode = 'cards'; // 'cards' or 'table'
  int _displayedLimit = 20;

  List<TeamMemberModel> get _visibleMembers =>
      _filteredMembers.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeam({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final repo = ref.read(teamRepoProvider);

    final members = await repo.getTeamMembers(
      category: _selectedCategory != 'All' ? _selectedCategory : null,
      query: _searchCtrl.text.trim(),
    );
    final stats = await repo.getTeamStats();

    if (mounted) {
      setState(() {
        _allMembers = members;
        _teamStats = stats;
        _isLoading = false;
        _displayedLimit = 20;
      });
    }
  }

  List<TeamMemberModel> get _filteredMembers {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allMembers;
    final normQ = AppTranslations.normalizeAsciiDigits(q);

    return _allMembers.where((m) {
      final inKeywords = m.keywords.any((k) => k.toLowerCase().contains(q));
      return m.name.toLowerCase().contains(q) ||
          (m.nameMarathi?.toLowerCase().contains(q) ?? false) ||
          m.role.toLowerCase().contains(q) ||
          m.mobile.contains(normQ) ||
          (m.area?.toLowerCase().contains(q) ?? false) ||
          (m.partyWing?.toLowerCase().contains(q) ?? false) ||
          (m.societyName?.toLowerCase().contains(q) ?? false) ||
          inKeywords;
    }).toList();
  }

  void _callMember(String mobile) async {
    final clean = AppTranslations.normalizeAsciiDigits(mobile).replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:+91$clean');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  void _messageOnWhatsApp(TeamMemberModel member, String lang) async {
    final translatedName = await DynamicTranslationService.translateOrRaw(
      member.displayNameFor(lang),
      lang,
      isName: true,
    );
    final greeting = AppTranslations.pick(
      lang,
      en: 'Greetings $translatedName,\nContacting you from Ward 12 Corporator Office.',
      mr: 'नमस्कार $translatedName,\nप्रभाग १२ नगरसेवक कार्यालयातून संपर्क साधत आहोत.',
      hi: 'नमस्ते $translatedName,\nवार्ड १२ पार्षद कार्यालय से आपसे संपर्क कर रहे हैं।',
    );
    final cleanPhone = AppTranslations.normalizeAsciiDigits(member.mobile).replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(greeting);
    final url = Uri.parse('https://wa.me/91$cleanPhone?text=$msg');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showHelpGuide() {
    final lang = ref.read(appLanguageProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.pick(lang, en: 'My Team Guide', mr: 'माझी टीम मार्गदर्शिका', hi: 'मेरी टीम गाइड'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        AppTranslations.pick(lang, en: 'Staff and Task Allocation System', mr: 'कर्मचारी आणि काम वाटप प्रणाली', hi: 'कर्मचारी और कार्य आवंटन प्रणाली'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildHelpPoint(
              icon: Icons.business_rounded,
              title: AppTranslations.pick(lang, en: '1. Office Team', mr: '१. कार्यालयीन टीम', hi: '१. कार्यालय टीम'),
              desc: AppTranslations.pick(
                lang,
                en: 'Office admin, PR officer, driver, peon, and assistants.',
                mr: 'कार्यालय प्रशासक, जनसंपर्क अधिकारी, चालक, शिपाई आणि सहाय्यक.',
                hi: 'कार्यालय प्रशासक, जनसंपर्क अधिकारी, चालक, चपरासी और सहायक।',
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.flag_rounded,
              title: AppTranslations.pick(lang, en: '2. Party & Organization Cadre', mr: '२. पक्ष आणि संघटना कार्यकर्ते', hi: '२. पार्टी और संगठन कार्यकर्ता'),
              desc: AppTranslations.pick(
                lang,
                en: 'Youth wing, women wing, social media cell, and senior citizens cell functionaries.',
                mr: 'युवक आघाडी, महिला आघाडी, सोशल मीडिया सेल आणि ज्येष्ठ नागरिक सेलचे पदाधिकारी.',
                hi: 'युवा मोर्चा, महिला मोर्चा, सोशल मीडिया सेल और वरिष्ठ नागरिक प्रकोष्ठ के पदाधिकारी।',
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.handshake_rounded,
              title: AppTranslations.pick(lang, en: '3. Municipal & Cooperative Staff', mr: '३. महापालिका व सहकारी कर्मचारी', hi: '३. नगर निगम और सहकारी कर्मचारी'),
              desc: AppTranslations.pick(
                lang,
                en: 'Municipal drainage, water supply, electricity utility staff, and society chairman representatives.',
                mr: 'महापालिकेचे ड्रेनेज, पाणीपुरवठा, वीज कर्मचारी आणि सोसायटी अध्यक्ष प्रतिनिधी.',
                hi: 'नगर निगम के ड्रेनेज, जल आपूर्ति, बिजली कर्मचारी और सोसायटी अध्यक्ष प्रतिनिधि।',
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              icon: Icons.auto_fix_high_rounded,
              title: AppTranslations.pick(lang, en: '4. Auto Assignment Rules', mr: '४. स्वयंचलित कार्य वाटप नियम', hi: '४. स्वचालित कार्य आवंटन नियम'),
              desc: AppTranslations.pick(
                lang,
                en: 'Citizen complaints automatically route to the relevant staff based on topic keywords (water, light, waste, etc.).',
                mr: 'विषय कीवर्ड्सनुसार (पाणी, वीज, कचरा इ.) नागरिकांच्या तक्रारी संबंधित कर्मचाऱ्यांकडे आपोआप पाठवल्या जातात.',
                hi: 'विषय कीवर्ड (पानी, बिजली, कचरा आदि) के आधार पर नागरिक शिकायतें स्वतः संबंधित कर्मचारियों को भेजी जाती हैं।',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  AppTranslations.pick(lang, en: 'Got it', mr: 'समजले', hi: 'समझ गया'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpPoint({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0284C7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddMemberModal() => _showMemberModal();

  void _showMemberModal({TeamMemberModel? memberToEdit}) {
    final lang = ref.read(appLanguageProvider);
    final nameCtrl = TextEditingController(text: memberToEdit?.name ?? '');
    final mobileCtrl = TextEditingController(text: memberToEdit?.mobile ?? '');
    final emailCtrl = TextEditingController(text: memberToEdit?.email ?? '');
    final passwordCtrl = TextEditingController();
    bool showPassword = false;
    final roleCtrl = TextEditingController(text: memberToEdit?.role ?? '');
    final areaCtrl = TextEditingController(
      text: memberToEdit?.area ??
          AppTranslations.pick(lang, en: 'Ward 12, Shaniwar Peth', mr: 'प्रभाग १२, शनिवार पेठ', hi: 'वार्ड १२, शनिवार पेठ'),
    );
    final societyCtrl = TextEditingController(text: memberToEdit?.societyName ?? '');
    final keywordsCtrl = TextEditingController(text: memberToEdit?.keywords.join(', ') ?? '');

    String category = memberToEdit?.category ?? 'Office';
    String paksh = memberToEdit?.paksh ?? '';
    String partyWing = memberToEdit?.partyWing ?? '';
    String pad = memberToEdit?.pad ?? '';
    bool canAssignWork = memberToEdit?.canAssignWork ?? true;

    final complaintCategories = [
      {'id': 'Road', 'label': AppTranslations.pick(lang, en: 'Roads', mr: 'रस्ते (Roads)', hi: 'सड़कें (Roads)')},
      {'id': 'Water', 'label': AppTranslations.pick(lang, en: 'Water Supply', mr: 'पाणीपुरवठा', hi: 'जल आपूर्ति')},
      {'id': 'StreetLight', 'label': AppTranslations.pick(lang, en: 'Electricity / Street Lights', mr: 'वीज / पथदिवे', hi: 'बिजली / स्ट्रीट लाइट')},
      {'id': 'Cleaning', 'label': AppTranslations.pick(lang, en: 'Cleaning / Waste', mr: 'कचरा / स्वच्छता', hi: 'सफाई / कचरा')},
      {'id': 'Drainage', 'label': AppTranslations.pick(lang, en: 'Drainage', mr: 'गटार / ड्रेनेज', hi: 'नाली / ड्रेनेज')},
      {'id': 'Other', 'label': AppTranslations.pick(lang, en: 'Other', mr: 'इतर', hi: 'अन्य')},
    ];

    List<String> selectedCategories = (memberToEdit?.keywords ?? [])
        .where((k) => complaintCategories.any((c) => c['id'] == k))
        .toList();

    final availablePermissions = [
      {'id': 'complaints', 'label': AppTranslations.pick(lang, en: 'Complaints & Requests', mr: 'तक्रारी व विनंत्या', hi: 'शिकायतें और अनुरोध')},
      {'id': 'letters', 'label': AppTranslations.pick(lang, en: 'Letters & Applications', mr: 'पत्रव्यवहार व अर्ज', hi: 'पत्र और आवेदन')},
      {'id': 'tasks', 'label': AppTranslations.pick(lang, en: 'Task Management', mr: 'कामे व कार्ये', hi: 'कार्य प्रबंधन')},
      {'id': 'visitors', 'label': AppTranslations.pick(lang, en: 'Visitor Log', mr: 'अभ्यागत नोंद', hi: 'आगंतुक रजिस्टर')},
      {'id': 'schemes', 'label': AppTranslations.pick(lang, en: 'Government Schemes', mr: 'शासकीय योजना', hi: 'सरकारी योजनाएं')},
      {'id': 'ward_problems', 'label': AppTranslations.pick(lang, en: 'Ward Problems', mr: 'प्रभाग समस्या', hi: 'वार्ड समस्याएं')},
      {'id': 'ward_info', 'label': AppTranslations.pick(lang, en: 'Ward Map', mr: 'प्रभाग नकाशा', hi: 'वार्ड मानचित्र')},
      {'id': 'work_history', 'label': AppTranslations.pick(lang, en: 'Work History', mr: 'कामांचा इतिहास', hi: 'कार्य इतिहास')},
      {'id': 'improvements', 'label': AppTranslations.pick(lang, en: 'Ward Improvements', mr: 'प्रभाग सुधारणा', hi: 'वार्ड सुधार')},
      {'id': 'provision', 'label': AppTranslations.pick(lang, en: 'Ward Provision', mr: 'प्रभाग तरतूद', hi: 'वार्ड प्रावधान')},
      {'id': 'gb_register', 'label': AppTranslations.pick(lang, en: 'GB Register / Diary', mr: 'जीबी रजिस्टर', hi: 'जीबी रजिस्टर / डायरी')},
      {'id': 'budget', 'label': AppTranslations.pick(lang, en: 'Ward Budget', mr: 'प्रभाग अंदाजपत्रक', hi: 'वार्ड बजट')},
      {'id': 'gov_office', 'label': AppTranslations.pick(lang, en: 'Government Offices', mr: 'शासकीय कार्यालये', hi: 'सरकारी कार्यालय')},
      {'id': 'social', 'label': AppTranslations.pick(lang, en: 'Social Media Analytics', mr: 'सोशल मीडिया ॲनालिटिक्स', hi: 'सोशल मीडिया एनालिटिक्स')},
      {'id': 'newspaper', 'label': AppTranslations.pick(lang, en: 'Newspaper Clippings', mr: 'वर्तमानपत्र कात्रणे', hi: 'समाचार पत्र कतरनें')},
      {'id': 'media_tracking', 'label': AppTranslations.pick(lang, en: 'Media Tracking', mr: 'मीडिया ट्रॅकिंग', hi: 'मीडिया ट्रैकिंग')},
      {'id': 'bot', 'label': AppTranslations.pick(lang, en: 'WhatsApp Bot', mr: 'व्हॉट्सॲप बॉट', hi: 'व्हाट्सएप बॉट')},
      {'id': 'ai_content', 'label': AppTranslations.pick(lang, en: 'AI Content Studio', mr: 'एआय कंटेंट स्टुडिओ', hi: 'एआई कंटेंट स्टूडियो')},
      {'id': 'events', 'label': AppTranslations.pick(lang, en: 'Events & Invites', mr: 'कार्यक्रम व निमंत्रणे', hi: 'कार्यक्रम और निमंत्रण')},
      {'id': 'gallery', 'label': AppTranslations.pick(lang, en: 'Media Gallery', mr: 'फोटो गॅलरी', hi: 'मीडिया गैलरी')},
      {'id': 'results', 'label': AppTranslations.pick(lang, en: 'Election Results', mr: 'निवडणूक निकाल', hi: 'चुनाव परिणाम')},
      {'id': 'sadasya', 'label': AppTranslations.pick(lang, en: 'Party Members (Sadasya)', mr: 'पक्ष सदस्य', hi: 'पार्टी सदस्य')},
      {'id': 'surveys', 'label': AppTranslations.pick(lang, en: 'Surveys', mr: 'जनमत चाचण्या', hi: 'सर्वेक्षण')},
      {'id': 'voters', 'label': AppTranslations.pick(lang, en: 'Voter Search', mr: 'मतदार यादी शोध', hi: 'मतदाता खोज')},
      {'id': 'social_organizations', 'label': AppTranslations.pick(lang, en: 'NGO & Mandals Info', mr: 'मंडळ व संस्था', hi: 'एनजीओ व मंडल जानकारी')},
      {'id': 'staff', 'label': AppTranslations.pick(lang, en: 'Staff Management', mr: 'संघ व्यवस्थापन', hi: 'टीम प्रबंधन')},
    ];

    List<String> selectedPermissions = memberToEdit?.permissions != null
        ? List<String>.from(memberToEdit!.permissions!)
        : ['complaints', 'letters', 'tasks', 'visitors', 'ward_problems'];

    final partyWingsOptions = [
      (val: 'युवक आघाडी', en: 'Youth Wing', mr: 'युवक आघाडी', hi: 'युवा मोर्चा'),
      (val: 'महिला आघाडी', en: 'Women Wing', mr: 'महिला आघाडी', hi: 'महिला मोर्चा'),
      (val: 'विद्यार्थी आघाडी', en: 'Student Wing', mr: 'विद्यार्थी आघाडी', hi: 'छात्र मोर्चा'),
      (val: 'शेतकरी आघाडी', en: 'Farmers Wing', mr: 'शेतकरी आघाडी', hi: 'किसान मोर्चा'),
      (val: 'कामगार आघाडी', en: 'Labour Wing', mr: 'कामगार आघाडी', hi: 'मजदूर मोर्चा'),
      (val: 'व्यापारी आघाडी', en: 'Traders Wing', mr: 'व्यापारी आघाडी', hi: 'व्यापारी प्रकोष्ठ'),
      (val: 'अल्पसंख्याक आघाडी', en: 'Minority Wing', mr: 'अल्पसंख्याक आघाडी', hi: 'अल्पसंख्यक मोर्चा'),
      (val: 'ओबीसी आघाडी', en: 'OBC Wing', mr: 'ओबीसी आघाडी', hi: 'ओबीसी मोर्चा'),
      (val: 'ज्येष्ठ नागरिक आघाडी', en: 'Senior Citizens Wing', mr: 'ज्येष्ठ नागरिक आघाडी', hi: 'वरिष्ठ नागरिक प्रकोष्ठ'),
      (val: 'क्रीडा आघाडी', en: 'Sports Wing', mr: 'क्रीडा आघाडी', hi: 'खेल प्रकोष्ठ'),
      (val: 'आयटी सेल', en: 'IT Cell', mr: 'आयटी सेल', hi: 'आईटी सेल'),
      (val: 'सोशल मीडिया सेल', en: 'Social Media Cell', mr: 'सोशल मीडिया सेल', hi: 'सोशल मीडिया सेल'),
      (val: 'जनसंपर्क विभाग', en: 'Public Relations Dept', mr: 'जनसंपर्क विभाग', hi: 'जनसंपर्क विभाग'),
      (val: 'स्वयंसेवक संघटना', en: 'Volunteers Organization', mr: 'स्वयंसेवक संघटना', hi: 'स्वयंसेवक संगठन'),
    ];

    final partyPostsOptions = [
      (code: 'अध्यक्ष', en: 'President', mr: 'अध्यक्ष', hi: 'अध्यक्ष'),
      (code: 'उपाध्यक्ष', en: 'Vice President', mr: 'उपाध्यक्ष', hi: 'उपाध्यक्ष'),
      (code: 'सचिव', en: 'Secretary', mr: 'सचिव', hi: 'सचिव'),
      (code: 'सहसचिव', en: 'Joint Secretary', mr: 'सहसचिव', hi: 'सह-सचिव'),
      (code: 'कोषाध्यक्ष', en: 'Treasurer', mr: 'कोषाध्यक्ष', hi: 'कोषाध्यक्ष'),
      (code: 'संघटक', en: 'Organizer', mr: 'संघटक', hi: 'संगठक'),
      (code: 'सदस्य', en: 'Member', mr: 'सदस्य', hi: 'सदस्य'),
    ];

    final roleSuggestions = [
      (val: 'Office Admin', en: 'Office Admin', mr: 'कार्यालय प्रशासक', hi: 'कार्यालय प्रशासक'),
      (val: 'Personal Assistant', en: 'Personal Assistant', mr: 'स्वीय सहाय्यक', hi: 'निजी सहायक'),
      (val: 'Ward President', en: 'Ward President', mr: 'प्रभाग अध्यक्ष', hi: 'वार्ड अध्यक्ष'),
      (val: 'Booth Pramukh', en: 'Booth Pramukh', mr: 'बूथ प्रमुख', hi: 'बूथ प्रमुख'),
      (val: 'Electrician', en: 'Electrician', mr: 'इलेक्ट्रिशियन', hi: 'इलेक्ट्रीशियन'),
      (val: 'Plumber', en: 'Plumber', mr: 'प्लंबर', hi: 'प्लंबर'),
      (val: 'Sanitation Worker', en: 'Sanitation Worker', mr: 'स्वच्छता कर्मचारी', hi: 'सफाई कर्मचारी'),
    ];

    Widget fieldLabel(String text, {bool isRequired = false, String? optionalNote}) {
      return AppFieldLabel(label: text, isRequired: isRequired, optionalHint: optionalNote);
    }

    InputDecoration inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon, String? prefixText}) {
      return InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
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
                  icon: memberToEdit != null ? Icons.edit_rounded : Icons.person_add_rounded,
                  title: memberToEdit != null
                      ? AppTranslations.pick(lang, en: 'Edit Staff Member', mr: 'सदस्याची माहिती सुधारा', hi: 'सदस्य की जानकारी संपादित करें')
                      : AppTranslations.pick(lang, en: 'Add Staff Member', mr: 'नवीन कर्मचारी / कार्यकर्ता जोडा', hi: 'नया कर्मचारी / कार्यकर्ता जोड़ें'),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Ward team staff, office coordinators and political cadre',
                    mr: 'प्रभागातील टीम सदस्य, कार्यालयीन कर्मचारी व पक्ष पदाधिकारी',
                    hi: 'वार्ड टीम कर्मचारी, कार्यालय समन्वयक और पार्टी कार्यकर्ता',
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
                      // Row 1: Category & Political Party
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(lang, en: 'Category', mr: 'श्रेणी / विभाग', hi: 'श्रेणी / विभाग'),
                                  isRequired: true,
                                  value: category,
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Office',
                                      child: Text(AppTranslations.pick(lang, en: 'Office Team', mr: 'कार्यालयीन कर्मचारी', hi: 'कार्यालय टीम'), style: const TextStyle(fontSize: 12.5)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Party',
                                      child: Text(AppTranslations.pick(lang, en: 'Party Cadre', mr: 'पक्ष पदाधिकारी / कार्यकर्ते', hi: 'पार्टी कार्यकर्ता'), style: const TextStyle(fontSize: 12.5)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Cooperative',
                                      child: Text(AppTranslations.pick(lang, en: 'Municipal / Co-op', mr: 'महापालिका / इतर संस्था', hi: 'नगर निगम / सहकारी'), style: const TextStyle(fontSize: 12.5)),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => category = val);
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
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(lang, en: 'Political Party', mr: 'राजकीय पक्ष (पक्ष)', hi: 'राजनीतिक दल'),
                                  value: paksh,
                                  items: [
                                    DropdownMenuItem(value: '', child: Text(AppTranslations.pick(lang, en: 'Select Party', mr: 'पक्ष निवडा', hi: 'पार्टी चुनें'), style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'BJP', child: Text(AppTranslations.pick(lang, en: 'BJP (Bharatiya Janata Party)', mr: 'भाजप (भारतीय जनता पक्ष)', hi: 'भाजपा (भारतीय जनता पार्टी)'), style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'INC', child: Text(AppTranslations.pick(lang, en: 'INC (Congress)', mr: 'काँग्रेस (आय)', hi: 'कांग्रेस (INC)'), style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'NCP', child: Text(AppTranslations.pick(lang, en: 'NCP (Nationalist Congress Party)', mr: 'राष्ट्रवादी काँग्रेस', hi: 'राकांपा (NCP)'), style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'SHS', child: Text(AppTranslations.pick(lang, en: 'Shiv Sena', mr: 'शिवसेना', hi: 'शिवसेना'), style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'UBT', child: Text(AppTranslations.pick(lang, en: 'Shivsena (UBT)', mr: 'शिवसेना (UBT)', hi: 'शिवसेना (UBT)'), style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'MNS', child: Text(AppTranslations.pick(lang, en: 'MNS', mr: 'मनसे (MNS)', hi: 'मनसे (MNS)'), style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'AAP', child: Text(AppTranslations.pick(lang, en: 'AAP', mr: 'आप (Aam Aadmi Party)', hi: 'आप (AAP)'), style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'Independent', child: Text(AppTranslations.pick(lang, en: 'Independent', mr: 'अपक्ष', hi: 'निर्दलीय'), style: const TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'Other', child: Text(AppTranslations.pick(lang, en: 'Other / None', mr: 'इतर / कोणताही नाही', hi: 'अन्य / कोई नहीं'), style: const TextStyle(fontSize: 12.5))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => paksh = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Full Name
                      fieldLabel(AppTranslations.pick(lang, en: 'Full Name', mr: 'पूर्ण नाव', hi: 'पूरा नाम'), isRequired: true),
                      TextField(
                        controller: nameCtrl,
                        decoration: inputDec(
                          hintText: AppTranslations.pick(lang, en: 'e.g. Ramesh Balasaheb Kadam', mr: 'उदा. रमेश बाळासाहेब कदम', hi: 'उदा. रमेश बालासाहेब कदम'),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mobile Number (+91 prefix)
                      fieldLabel(AppTranslations.pick(lang, en: 'Mobile Number', mr: 'मोबाईल नंबर', hi: 'मोबाइल नंबर'), isRequired: true),
                      TextField(
                        controller: mobileCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: inputDec(
                          prefixText: AppTranslations.formatDigits('+91 ', lang),
                          hintText: AppTranslations.formatDigits('9876543210', lang),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email & Password (Login ID & Password)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(AppTranslations.pick(lang, en: 'Email (Login ID)', mr: 'ईमेल (Login ID)', hi: 'ईमेल (Login ID)')),
                                TextField(
                                  controller: emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: inputDec(
                                    hintText: 'staff@example.com',
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
                                fieldLabel(AppTranslations.pick(lang, en: 'Password', mr: 'पासवर्ड', hi: 'पासवर्ड')),
                                TextField(
                                  controller: passwordCtrl,
                                  obscureText: !showPassword,
                                  decoration: inputDec(
                                    hintText: '••••••••',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        size: 18,
                                        color: const Color(0xFF64748B),
                                      ),
                                      onPressed: () => setModalState(() => showPassword = !showPassword),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Role / Designation with quick suggestion chips
                      fieldLabel(AppTranslations.pick(lang, en: 'Role / Designation', mr: 'पद / हुद्दा', hi: 'पद / भूमिका'), isRequired: true),
                      TextField(
                        controller: roleCtrl,
                        decoration: inputDec(
                          hintText: AppTranslations.pick(lang, en: 'e.g. Office Admin, Ward President...', mr: 'उदा. कार्यालय प्रशासक, प्रभाग अध्यक्ष...', hi: 'उदा. कार्यालय प्रशासक, वार्ड अध्यक्ष...'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: roleSuggestions.map((r) {
                          return ActionChip(
                            label: Text(
                              AppTranslations.pick(lang, en: r.en, mr: r.mr, hi: r.hi),
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onPressed: () => setModalState(() => roleCtrl.text = r.val),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Work Area & Society Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(AppTranslations.pick(lang, en: 'Work Area', mr: 'कार्यक्षेत्र / परिसर', hi: 'कार्यक्षेत्र / क्षेत्र')),
                                TextField(
                                  controller: areaCtrl,
                                  decoration: inputDec(
                                    hintText: AppTranslations.pick(lang, en: 'e.g. Shaniwar Peth', mr: 'उदा. शनिवार पेठ', hi: 'उदा. शनिवार पेठ'),
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
                                  AppTranslations.pick(lang, en: 'Society Name', mr: 'सोसायटीचे नाव', hi: 'सोसायटी का नाम'),
                                  optionalNote: AppTranslations.pick(lang, en: 'Optional', mr: 'ऐच्छिक', hi: 'वैकल्पिक'),
                                ),
                                TextField(
                                  controller: societyCtrl,
                                  decoration: inputDec(
                                    hintText: AppTranslations.pick(lang, en: 'e.g. Royal Heights', mr: 'उदा. रॉयल हाईट्स', hi: 'उदा. रॉयल हाइट्स'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Party Wing & Designation/Post (Pad)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(lang, en: 'Party Wing', mr: 'पक्ष आघाडी / सेल', hi: 'पार्टी प्रकोष्ठ / सेल'),
                                  value: partyWingsOptions.any((w) => w.val == partyWing) ? partyWing : '',
                                  items: [
                                    DropdownMenuItem(value: '', child: Text(AppTranslations.pick(lang, en: 'Select Wing', mr: 'आघाडी निवडा', hi: 'प्रकोष्ठ चुनें'), style: const TextStyle(fontSize: 12.5))),
                                    ...partyWingsOptions.map((w) => DropdownMenuItem(
                                          value: w.val,
                                          child: Text(AppTranslations.pick(lang, en: w.en, mr: w.mr, hi: w.hi), style: const TextStyle(fontSize: 12.5)),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => partyWing = val);
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
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(lang, en: 'Designation / Post', mr: 'पद (आघाडीतील पद)', hi: 'पद (प्रकोष्ठ पद)'),
                                  value: partyPostsOptions.any((p) => p.code == pad) ? pad : '',
                                  items: [
                                    DropdownMenuItem(value: '', child: Text(AppTranslations.pick(lang, en: 'Select Post', mr: 'पद निवडा', hi: 'पद चुनें'), style: const TextStyle(fontSize: 12.5))),
                                    ...partyPostsOptions.map((p) => DropdownMenuItem(
                                          value: p.code,
                                          child: Text(AppTranslations.pick(lang, en: p.en, mr: p.mr, hi: p.hi), style: const TextStyle(fontSize: 12.5)),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => pad = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Auto Keywords
                      fieldLabel(
                        AppTranslations.pick(lang, en: 'Auto Keywords', mr: 'ऑटो कीवर्ड्स', hi: 'ऑटो कीवर्ड'),
                        optionalNote: AppTranslations.pick(lang, en: 'Optional', mr: 'ऐच्छिक', hi: 'वैकल्पिक'),
                      ),
                      TextField(
                        controller: keywordsCtrl,
                        decoration: inputDec(
                          hintText: AppTranslations.pick(lang, en: 'water, drainage, electricity, waste', mr: 'पाणी, ड्रेनेज, वीज, कचरा', hi: 'पानी, ड्रेनेज, बिजली, कचरा'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 14),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Keywords used to auto-assign incoming citizen complaints',
                            mr: 'तक्रारींचे स्वयंचलित वाटप करण्यासाठी कीवर्ड्स (स्वल्पविरामाने वेगळे करा)',
                            hi: 'नागरिक शिकायतों को स्वतः आवंटित करने के लिए कीवर्ड (अल्पविराम से अलग करें)',
                          ),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),

                      // Complaint Categories (Auto-Assign)
                      fieldLabel(AppTranslations.pick(lang, en: 'Complaint Categories (Auto-Assign)', mr: 'तक्रार श्रेणी (स्वयंचलित वाटप)', hi: 'शिकायत श्रेणियां (स्वतः आवंटन)')),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: complaintCategories.map((cat) {
                            final catId = cat['id']!;
                            final isChecked = selectedCategories.contains(catId);
                            return FilterChip(
                              label: Text(cat['label']!, style: TextStyle(fontSize: 12, color: isChecked ? Colors.indigo.shade900 : const Color(0xFF334155))),
                              selected: isChecked,
                              selectedColor: const Color(0xFFC7D2FE),
                              checkmarkColor: Colors.indigo.shade900,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedCategories.add(catId);
                                  } else {
                                    selectedCategories.remove(catId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Permissions (Access Control)
                      fieldLabel(AppTranslations.pick(lang, en: 'Permissions (Access Control)', mr: 'परवानग्या व अधिकार (Access Control)', hi: 'अनुमतियाँ और अधिकार (Access Control)')),
                      Container(
                        padding: const EdgeInsets.all(10),
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
                                Text(
                                  '${AppTranslations.formatDigits('${selectedPermissions.length}', lang)} / ${AppTranslations.formatDigits('${availablePermissions.length}', lang)} ${AppTranslations.pick(lang, en: 'selected', mr: 'अधिकार निवडले', hi: 'चयनित')}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      if (selectedPermissions.length == availablePermissions.length) {
                                        selectedPermissions.clear();
                                      } else {
                                        selectedPermissions = availablePermissions.map((p) => p['id']!).toList();
                                      }
                                    });
                                  },
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  child: Text(
                                    selectedPermissions.length == availablePermissions.length
                                        ? AppTranslations.pick(lang, en: 'Deselect All', mr: 'सर्व काढा', hi: 'सभी हटाएँ')
                                        : AppTranslations.pick(lang, en: 'Select All', mr: 'सर्व निवडा', hi: 'सभी चुनें'),
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 8, color: Color(0xFFE2E8F0)),
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: availablePermissions.length,
                                itemBuilder: (context, idx) {
                                  final perm = availablePermissions[idx];
                                  final permId = perm['id']!;
                                  final isChecked = selectedPermissions.contains(permId);
                                  return CheckboxListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: const Color(0xFF0284C7),
                                    title: Text(perm['label']!, style: const TextStyle(fontSize: 12.5)),
                                    value: isChecked,
                                    onChanged: (val) {
                                      setModalState(() {
                                        if (val == true) {
                                          selectedPermissions.add(permId);
                                        } else {
                                          selectedPermissions.remove(permId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Management Access: Assign Work to Other Staff
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFEF08A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: canAssignWork,
                              activeColor: const Color(0xFF0284C7),
                              onChanged: (val) => setModalState(() => canAssignWork = val ?? true),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.pick(lang, en: 'Assign Work to Other Staff', mr: 'इतर कर्मचाऱ्यांना काम सोपवण्याची परवानगी द्या', hi: 'अन्य कर्मचारियों को कार्य सौंपने की अनुमति दें'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF713F12)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Allow this user to delegate tasks and citizen complaints to other staff members.',
                                      mr: 'या युझरला इतर कर्मचाऱ्यांना तक्रारी व कार्ये वाटप करण्याचे अधिकार मिळतील.',
                                      hi: 'इस उपयोगकर्ता को अन्य कर्मचारियों को शिकायतें और कार्य आवंटित करने की अनुमति मिलेगी।',
                                    ),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF854D0E)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Buttons: Cancel & Save Member
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
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                              label: Text(
                                memberToEdit != null
                                    ? AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'बदलाव सहेजें')
                                    : AppTranslations.pick(lang, en: 'Save Member', mr: 'सदस्य जतन करा', hi: 'सदस्य सहेजें'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              onPressed: () async {
                                if (nameCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppTranslations.pick(lang, en: 'Please enter member name.', mr: 'कृपया सदस्याचे नाव प्रविष्ट करा.', hi: 'कृपया सदस्य का नाम दर्ज करें।')),
                                    ),
                                  );
                                  return;
                                }
                                final cleanMobile = AppTranslations.normalizeAsciiDigits(mobileCtrl.text.trim());
                                if (cleanMobile.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppTranslations.pick(lang, en: 'Please enter mobile number.', mr: 'कृपया मोबाईल नंबर प्रविष्ट करा.', hi: 'कृपया मोबाइल नंबर दर्ज करें।')),
                                    ),
                                  );
                                  return;
                                }

                                final manualKw = keywordsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                final combinedKw = {...manualKw, ...selectedCategories}.toList();

                                final member = TeamMemberModel(
                                  id: memberToEdit?.id ?? 'stf-${DateTime.now().millisecondsSinceEpoch}',
                                  name: nameCtrl.text.trim(),
                                  nameMarathi: nameCtrl.text.trim(),
                                  mobile: cleanMobile,
                                  email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                                  role: roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : 'Staff',
                                  category: category,
                                  area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                                  partyWing: partyWing.isNotEmpty ? partyWing : null,
                                  paksh: paksh.isNotEmpty ? paksh : null,
                                  pad: pad.isNotEmpty ? pad : null,
                                  societyName: societyCtrl.text.trim().isNotEmpty ? societyCtrl.text.trim() : null,
                                  keywords: combinedKw,
                                  permissions: selectedPermissions,
                                  canAssignWork: canAssignWork,
                                  joinedDate: memberToEdit?.joinedDate ?? DateTime.now(),
                                );

                                final messenger = ScaffoldMessenger.of(context);
                                final repo = ref.read(teamRepoProvider);
                                if (memberToEdit != null) {
                                  await repo.updateTeamMember(member);
                                } else {
                                  await repo.addTeamMember(member);
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                if (!mounted) return;
                                _loadTeam();

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      memberToEdit != null
                                          ? AppTranslations.pick(lang, en: 'Member updated successfully!', mr: 'सदस्याची माहिती अद्यतनित केली!', hi: 'सदस्य की जानकारी अपडेट की गई!')
                                          : AppTranslations.pick(lang, en: 'New member added successfully!', mr: 'नवीन सदस्य यशस्वीरित्या जोडला गेला!', hi: 'नया सदस्य सफलतापूर्वक जोड़ा गया!'),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
    final filtered = _filteredMembers;
    final totalMembers = _teamStats['total'] ?? _allMembers.length;
    final officeCount = _teamStats['office'] ?? 0;
    final partyCount = _teamStats['party'] ?? 0;
    final coopCount = _teamStats['cooperative'] ?? 0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const NagarsevakAppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            tooltip: AppTranslations.pick(lang, en: 'Open Menu Drawer', mr: 'मेनू उघडा', hi: 'मेनू खोलें'),
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
              AppTranslations.pick(lang, en: 'My Team', mr: 'माझी टीम', hi: 'मेरी टीम'),
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
                en: 'Nagarsevak office staff, field coordinators and roles',
                mr: 'नगरसेवक कार्यालयीन कर्मचारी, समन्वयक आणि जबाबदाऱ्या',
                hi: 'पार्षद कार्यालय कर्मचारी, क्षेत्रीय समन्वयक और भूमिकाएं',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
            tooltip: AppTranslations.pick(lang, en: 'Team Guide', mr: 'टीम मार्गदर्शिका', hi: 'टीम गाइड'),
            onPressed: _showHelpGuide,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: AppLanguageSegmentedSelector(isCompact: true),
          ),
        ],
      ),
      body: _isLoading
          ? const AppShimmerList(count: 6)
          : RefreshIndicator(
              onRefresh: _loadTeam,
              color: const Color(0xFF0284C7),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // KPI Header Strip
                  _buildKpiStrip(totalMembers, officeCount, partyCount, coopCount, lang),
                  const SizedBox(height: 14),

                  // Search Bar
                  _buildSearchBar(filtered, lang),
                  const SizedBox(height: 10),

                  // Category Tabs & View Mode Row
                  _buildCategoryTabsBar(filtered.length, lang),
                  const SizedBox(height: 14),

                  // Team Members List (Cards or Table)
                  if (filtered.isEmpty)
                    _buildEmptyState(lang)
                  else if (_viewMode == 'table')
                    _buildTableView(_visibleMembers, lang)
                  else
                    ..._visibleMembers.map((m) => _buildTeamCard(m, lang)),

                  if (!_isLoading && filtered.isNotEmpty)
                    AppLoadMoreFooter(
                      currentCount: _visibleMembers.length,
                      totalCount: filtered.length,
                      pageSize: 20,
                      onLoadMore: () {
                        setState(() => _displayedLimit += 20);
                      },
                      label: AppTranslations.pick(lang, en: 'members', mr: 'सदस्य', hi: 'सदस्य'),
                      isMarathi: lang == 'mr',
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          AppTranslations.pick(lang, en: 'New Member', mr: 'नवीन सदस्य', hi: 'नया सदस्य'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _showAddMemberModal,
      ),
    );
  }

  Widget _buildKpiStrip(int total, int office, int party, int coop, String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: AppTranslations.pick(lang, en: 'Total Members', mr: 'एकूण सदस्य', hi: 'कुल सदस्य'),
            value: AppTranslations.formatDigits('$total', lang),
            subtitle: AppTranslations.pick(lang, en: 'My Team', mr: 'माझी टीम', hi: 'मेरी टीम'),
            icon: Icons.groups_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: AppTranslations.pick(lang, en: 'Office Team', mr: 'कार्यालयीन टीम', hi: 'कार्यालय टीम'),
            value: AppTranslations.formatDigits('$office', lang),
            subtitle: AppTranslations.pick(lang, en: 'Office Staff', mr: 'कार्यालयीन कर्मचारी', hi: 'कार्यालय कर्मचारी'),
            icon: Icons.business_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: AppTranslations.pick(lang, en: 'Party Cadre', mr: 'पक्ष कार्यकर्ते', hi: 'पार्टी कार्यकर्ता'),
            value: AppTranslations.formatDigits('$party', lang),
            subtitle: AppTranslations.pick(lang, en: 'Wings & Cells', mr: 'आघाडी व सेल', hi: 'प्रकोष्ठ व सेल'),
            icon: Icons.flag_rounded,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: AppTranslations.pick(lang, en: 'Municipal / Coop', mr: 'महापालिका / सहकार', hi: 'नगर निगम / सहकार'),
            value: AppTranslations.formatDigits('$coop', lang),
            subtitle: AppTranslations.pick(lang, en: 'Municipal & Orgs', mr: 'महापालिका व संस्था', hi: 'नगर निगम व संस्थाएं'),
            icon: Icons.handshake_rounded,
            color: const Color(0xFF7C3AED),
            bg: const Color(0xFFEDE9FE),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(List<TeamMemberModel> filtered, String lang) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() => _displayedLimit = 20),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search name, role, wing, area, or keyword...',
                  mr: 'नाव, पद, आघाडी, परिसर किंवा कीवर्ड शोधा...',
                  hi: 'नाम, पद, प्रकोष्ठ, क्षेत्र या कीवर्ड खोजें...',
                ),
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _displayedLimit = 20);
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),

          AppPdfButton.icon(
            tooltip: AppTranslations.pick(lang, en: 'Download Team Report', mr: 'टीम अहवाल डाउनलोड करा', hi: 'टीम रिपोर्ट डाउनलोड करें'),
            onPressed: () => TeamReportGenerator.generateAndPrintReport(
              context: context,
              staffList: filtered,
              activeCategory: _selectedCategory == 'All' ? 'All Team' : _selectedCategory,
              lang: lang,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabsBar(int resultCount, String lang) {
    final categories = [
      {'key': 'All', 'label': AppTranslations.pick(lang, en: 'All Team', mr: 'सर्व टीम', hi: 'पूरी टीम')},
      {'key': 'Office', 'label': AppTranslations.pick(lang, en: 'Office Team', mr: 'कार्यालयीन टीम', hi: 'कार्यालय टीम')},
      {'key': 'Party', 'label': AppTranslations.pick(lang, en: 'Party Cadre', mr: 'पक्ष कार्यकर्ते', hi: 'पार्टी कार्यकर्ता')},
      {'key': 'Cooperative', 'label': AppTranslations.pick(lang, en: 'Municipal / Coop', mr: 'महापालिका / सहकार', hi: 'नगर निगम / सहकारी')},
    ];

    return Row(
      children: [
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSel = _selectedCategory == cat['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSel,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat['key']!;
                        _displayedLimit = 20;
                      });
                      _loadTeam();
                    },
                    selectedColor: const Color(0xFF0284C7),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? Colors.white : Colors.grey.shade700,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSel ? const Color(0xFF0284C7) : Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Toggle view
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.grid_view_rounded, size: 17, color: _viewMode == 'cards' ? const Color(0xFF0284C7) : Colors.grey),
                tooltip: AppTranslations.pick(lang, en: 'Card View', mr: 'कार्ड दृश्य', hi: 'कार्ड दृश्य'),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _viewMode = 'cards'),
              ),
              Container(width: 1, height: 18, color: Colors.grey.shade200),
              IconButton(
                icon: Icon(Icons.table_rows_rounded, size: 17, color: _viewMode == 'table' ? const Color(0xFF0284C7) : Colors.grey),
                tooltip: AppTranslations.pick(lang, en: 'Table View', mr: 'तक्ता दृश्य', hi: 'तालिका दृश्य'),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _viewMode = 'table'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(TeamMemberModel member, String lang) {
    Color catColor = const Color(0xFF0284C7);
    Color catBg = const Color(0xFFE0F2FE);

    if (member.category == 'Party') {
      catColor = const Color(0xFFD97706);
      catBg = const Color(0xFFFEF3C7);
    } else if (member.category == 'Cooperative') {
      catColor = const Color(0xFF7C3AED);
      catBg = const Color(0xFFEDE9FE);
    }

    final primaryName = member.displayNameFor(lang);
    final roleLabel = member.roleLabel(lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TeamMemberProfileScreen(member: member)),
          ).then((res) { if (res == true) _loadTeam(showLoading: false); });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Avatar, Name, Category pill, Role
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: catBg,
                    child: AppTranslatedText(
                      primaryName.isNotEmpty ? primaryName : 'S',
                      targetLanguage: lang,
                      isName: true,
                      builder: (ctx, translated) => Text(
                        translated.trim().isNotEmpty ? translated.trim().substring(0, 1).toUpperCase() : 'S',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: catColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTranslatedText(
                          primaryName,
                          targetLanguage: lang,
                          isName: true,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        if (member.name != primaryName && member.name.trim().isNotEmpty)
                          AppTranslatedText(
                            member.name,
                            targetLanguage: lang,
                            isName: true,
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                          ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: catBg,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: catColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                member.categoryLabel(lang),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: catColor),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: AppTranslatedText(
                                roleLabel,
                                targetLanguage: lang,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    tooltip: AppTranslations.pick(lang, en: 'Edit Member', mr: 'माहिती सुधारा', hi: 'जानकारी संपादित करें'),
                    onPressed: () => _showMemberModal(memberToEdit: member),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 10),

              // Sub-info: Wing or Society or Area
              if (member.partyWing != null && member.partyWing!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 13, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppTranslatedText(
                          '${member.partyWing!} ${member.pad != null ? "• ${member.pad}" : ""}',
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              if (member.societyName != null && member.societyName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment_rounded, size: 13, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppTranslatedText(
                          member.societyName!,
                          targetLanguage: lang,
                          isName: true,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF5B21B6)),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Flexible(
                    child: AppTranslatedText(
                      AppTranslations.getAreaName(member.area ?? 'Ward 12', lang),
                      targetLanguage: lang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(width: 8),
                  Icon(Icons.phone_iphone_rounded, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text(
                    AppTranslations.formatDigits('+91 ${member.mobile}', lang),
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Keywords Chips
              if (member.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: member.keywords.take(4).map((k) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: AppTranslatedText(
                        k,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Quick Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.assignment_add, size: 14, color: Color(0xFF0284C7)),
                    label: Text(
                      AppTranslations.pick(lang, en: 'Assign Task', mr: 'काम सोपवा', hi: 'कार्य सौंपें'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TeamMemberProfileScreen(member: member)),
                      ).then((res) { if (res == true) _loadTeam(showLoading: false); });
                    },
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 13, color: Colors.white),
                    label: Text(
                      AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सॲप', hi: 'व्हाट्सएप'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _messageOnWhatsApp(member, lang),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.phone, size: 18, color: Color(0xFF0284C7)),
                    tooltip: AppTranslations.pick(lang, en: 'Call', mr: 'कॉल करा', hi: 'कॉल करें'),
                    onPressed: () => _callMember(member.mobile),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(List<TeamMemberModel> list, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columns: [
              DataColumn(label: Text(AppTranslations.pick(lang, en: '#', mr: 'क्र.', hi: 'क्र.'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Name', mr: 'नाव', hi: 'नाम'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Role / Designation', mr: 'पद / हुद्दा', hi: 'पद / भूमिका'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Category', mr: 'श्रेणी', hi: 'श्रेणी'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Wing / Organization', mr: 'आघाडी / संस्था', hi: 'प्रकोष्ठ / संस्था'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Work Area', mr: 'कार्यक्षेत्र', hi: 'कार्यक्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Action', mr: 'कृती', hi: 'कार्रवाई'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: list.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;

              String sub = '-';
              if (m.category == 'Party' && m.partyWing != null) {
                sub = m.partyWing!;
              } else if (m.category == 'Cooperative' && m.societyName != null) {
                sub = m.societyName!;
              }

              return DataRow(
                cells: [
                  DataCell(Text(AppTranslations.formatDigits('${idx + 1}', lang), style: const TextStyle(fontSize: 11))),
                  DataCell(
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TeamMemberProfileScreen(member: m)),
                        ).then((res) { if (res == true) _loadTeam(showLoading: false); });
                      },
                      child: AppTranslatedText(
                        m.displayNameFor(lang),
                        targetLanguage: lang,
                        isName: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  DataCell(
                    AppTranslatedText(
                      m.roleLabel(lang),
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.category == 'Office'
                            ? const Color(0xFFE0F2FE)
                            : (m.category == 'Party' ? const Color(0xFFFEF3C7) : const Color(0xFFEDE9FE)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m.categoryLabel(lang),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: m.category == 'Office'
                              ? const Color(0xFF0284C7)
                              : (m.category == 'Party' ? const Color(0xFFD97706) : const Color(0xFF7C3AED)),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    sub == '-'
                        ? const Text('-', style: TextStyle(fontSize: 11))
                        : AppTranslatedText(sub, targetLanguage: lang, isName: m.category == 'Cooperative', style: const TextStyle(fontSize: 11)),
                  ),
                  DataCell(
                    AppTranslatedText(
                      AppTranslations.getAreaName(m.area ?? 'Ward 12', lang),
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(Text(AppTranslations.formatDigits('+91 ${m.mobile}', lang), style: const TextStyle(fontSize: 11))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone, size: 16, color: Color(0xFF0284C7)),
                          onPressed: () => _callMember(m.mobile),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, size: 15, color: Color(0xFF25D366)),
                          onPressed: () => _messageOnWhatsApp(m, lang),
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

  Widget _buildEmptyState(String lang) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            AppTranslations.pick(lang, en: 'No team members found', mr: 'कोणतेही टीम सदस्य आढळले नाहीत', hi: 'कोई टीम सदस्य नहीं मिला'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Check your search terms or add a new team member.',
              mr: 'तुमचा शोध तपासा किंवा नवीन टीम सदस्य जोडा.',
              hi: 'अपने खोज शब्द जांचें या नया टीम सदस्य जोड़ें।',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: Text(
              AppTranslations.pick(lang, en: 'Add New Member', mr: 'नवीन सदस्य जोडा', hi: 'नया सदस्य जोड़ें'),
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _showAddMemberModal,
          ),
        ],
      ),
    );
  }
}
