import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'voter_profile_screen.dart';
import 'voter_slip_generator.dart';
import '../../widgets/app_dropdown.dart';

class VotersScreen extends ConsumerStatefulWidget {
  const VotersScreen({super.key});

  @override
  ConsumerState<VotersScreen> createState() => _VotersScreenState();
}

class _VotersScreenState extends ConsumerState<VotersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<VoterModel> _allVoters = [];
  Map<String, int> _voterStats = {};
  List<String> _boothsList = [];

  int _currentPage = 1;
  final int _pageSize = 25;
  int _totalItems = 0;

  String _selectedBooth = 'All';
  String _selectedFavour = 'All'; // 'All', 'Favourable', 'Neutral', 'Against', 'Swing'
  String _selectedGender = 'All'; // 'All', 'M', 'F', 'O'
  String _selectedAgeRange = 'All'; // 'All', '18-25', '26-40', '41-60', '60+'
  bool _friendsOnly = false;
  String _viewMode = 'cards'; // 'cards', 'family', 'table'

  @override
  void initState() {
    super.initState();
    _loadVoters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVoters({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final repo = ref.read(votersRepoProvider);

    final result = await repo.getPaginatedVoters(
      page: _currentPage,
      pageSize: _pageSize,
      query: AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim()),
      boothFilter: _selectedBooth != 'All' ? _selectedBooth : null,
      favourFilter: _selectedFavour != 'All' ? _selectedFavour : null,
      genderFilter: _selectedGender != 'All' ? _selectedGender : null,
      ageRangeFilter: _selectedAgeRange != 'All' ? _selectedAgeRange : null,
      isFriendOnly: _friendsOnly,
    );
    final stats = await repo.getVotersStats();
    final booths = await repo.getBoothsList();

    if (mounted) {
      setState(() {
        _allVoters = result.items;
        _totalItems = result.totalCount;
        _voterStats = stats;
        _boothsList = booths;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreVoters() async {
    if (_isLoadingMore || _allVoters.length >= _totalItems) return;
    setState(() => _isLoadingMore = true);
    final repo = ref.read(votersRepoProvider);
    final nextPage = _currentPage + 1;

    final result = await repo.getPaginatedVoters(
      page: nextPage,
      pageSize: _pageSize,
      query: AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim()),
      boothFilter: _selectedBooth != 'All' ? _selectedBooth : null,
      favourFilter: _selectedFavour != 'All' ? _selectedFavour : null,
      genderFilter: _selectedGender != 'All' ? _selectedGender : null,
      ageRangeFilter: _selectedAgeRange != 'All' ? _selectedAgeRange : null,
      isFriendOnly: _friendsOnly,
    );

    if (mounted) {
      setState(() {
        _currentPage = nextPage;
        _allVoters.addAll(result.items);
        _totalItems = result.totalCount;
        _isLoadingMore = false;
      });
    }
  }

  String _formatIndianInt(int value, String lang) {
    final s = value.toString();
    final formatted = s.length <= 3
        ? s
        : () {
            final last3 = s.substring(s.length - 3);
            var rest = s.substring(0, s.length - 3);
            final parts = <String>[];
            while (rest.length > 2) {
              parts.insert(0, rest.substring(rest.length - 2));
              rest = rest.substring(0, rest.length - 2);
            }
            if (rest.isNotEmpty) parts.insert(0, rest);
            return '${parts.join(',')},$last3';
          }();
    return AppTranslations.formatDigits(formatted, lang);
  }

  List<VoterModel> get _filteredVoters {
    final lang = ref.read(appLanguageProvider);
    var list = List<VoterModel>.from(_allVoters);
    final q = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim().toLowerCase());
    if (q.isNotEmpty) {
      list = list.where((v) {
        final tName = (DynamicTranslationService.getCachedTranslation(
                  v.displayNameFor(lang),
                  lang,
                  isName: true,
                ) ??
                '')
            .toLowerCase();
        final tAddr = (DynamicTranslationService.getCachedTranslation(v.address, lang) ?? '').toLowerCase();
        return v.nameMarathi.toLowerCase().contains(q) ||
            v.nameEnglish.toLowerCase().contains(q) ||
            tName.contains(q) ||
            v.epicNo.toLowerCase().contains(q) ||
            v.address.toLowerCase().contains(q) ||
            tAddr.contains(q) ||
            (AppTranslations.normalizeAsciiDigits(v.mobile ?? '').contains(q)) ||
            (v.serialNo?.toString().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  /// Groups voters by houseNo and booth
  Map<String, List<VoterModel>> get _groupedFamilies {
    final Map<String, List<VoterModel>> map = {};
    for (final v in _filteredVoters) {
      final key = '${v.houseNo ?? "Unknown"}_${v.booth}';
      map.putIfAbsent(key, () => []).add(v);
    }
    return map;
  }

  void _callVoter(String? mobile, String lang) async {
    if (mobile == null || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Mobile number not available for this voter',
              mr: 'या मतदाराचा मोबाईल नंबर उपलब्ध नाही',
              hi: 'इस मतदाता का मोबाइल नंबर उपलब्ध नहीं है',
            ),
          ),
        ),
      );
      return;
    }
    final clean = AppTranslations.normalizeAsciiDigits(mobile).replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:+91$clean');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  void _shareSlipOnWhatsApp(VoterModel voter, String lang) async {
    final mobile = voter.mobile != null
        ? AppTranslations.normalizeAsciiDigits(voter.mobile!).replaceAll(RegExp(r'\D'), '')
        : '';
    final tName = await DynamicTranslationService.translateOrRaw(
      voter.displayNameFor(lang),
      lang,
      isName: true,
    );
    final tStation = await DynamicTranslationService.translateOrRaw(
      voter.displayPollingStationFor(lang),
      lang,
    );
    final tAddress = await DynamicTranslationService.translateOrRaw(voter.address, lang);
    final tBooth = await DynamicTranslationService.translateOrRaw(voter.booth, lang);
    final epicStr = AppTranslations.formatDigits(voter.epicNo, lang);
    final serialStr = AppTranslations.formatDigits(voter.serialNo?.toString() ?? '-', lang);
    final body = AppTranslations.pick(
      lang,
      en: 'Greetings $tName,\n\n'
          'Your official Ward 12 voter slip details:\n\n'
          '*Voter Name:* $tName\n'
          '*EPIC No:* $epicStr\n'
          '*Booth / Part No:* $tBooth\n'
          '*Serial No in Roll:* #$serialStr\n'
          '*Polling Station:* $tStation\n'
          '*Address:* $tAddress\n\n'
          'Please carry an identity card (EPIC or Aadhaar Card) on voting day.\n\n'
          '- Office of Corporator, Ward 12',
      mr: 'नमस्कार $tName,\n\n'
          'आपली प्रभाग १२ मधील अधिकृत मतदान पावती माहिती:\n\n'
          '*मतदाराचे नाव:* $tName\n'
          '*मतदार ओळखपत्र क्र. (EPIC):* $epicStr\n'
          '*बूथ / भाग क्र.:* $tBooth\n'
          '*यादीतील अनुक्रमांक:* #$serialStr\n'
          '*मतदान केंद्र:* $tStation\n'
          '*पत्ता:* $tAddress\n\n'
          'कृपया मतदानाच्या दिवशी ओळखपत्र (मतदार कार्ड किंवा आधार कार्ड) सोबत आणावे.\n\n'
          '- नगरसेवक कार्यालय, प्रभाग १२',
      hi: 'नमस्ते $tName,\n\n'
          'वार्ड १२ में आपकी आधिकारिक मतदाता पर्ची विवरण:\n\n'
          '*मतदाता का नाम:* $tName\n'
          '*पहचान पत्र क्र. (EPIC):* $epicStr\n'
          '*बूथ / भाग सं.:* $tBooth\n'
          '*सूची में क्रमांक:* #$serialStr\n'
          '*मतदान केंद्र:* $tStation\n'
          '*पता:* $tAddress\n\n'
          'कृपया मतदान के दिन एक पहचान पत्र (EPIC या आधार कार्ड) साथ लाएं।\n\n'
          '- नगरसेवक कार्यालय, वार्ड १२',
    );
    final msg = Uri.encodeComponent(body);

    Uri url;
    if (mobile.isNotEmpty) {
      url = Uri.parse('https://wa.me/91$mobile?text=$msg');
    } else {
      url = Uri.parse('https://wa.me/?text=$msg');
    }

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showHelpGuide(String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(bottom: 24),
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
              icon: Icons.person_search_rounded,
              title: AppTranslations.pick(
                lang,
                en: 'Voter Search & Management',
                mr: 'मतदार शोध आणि व्यवस्थापन',
                hi: 'मतदाता खोज और प्रबंधन',
              ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Ward 12 Digital Electoral Roll System',
                mr: 'प्रभाग १२ डिजिटल मतदार यादी प्रणाली',
                hi: 'वार्ड १२ डिजिटल मतदाता सूची प्रणाली',
              ),
              onClose: () => Navigator.pop(ctx),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  _buildHelpPoint(
                    icon: Icons.search_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Instant Multi-Search',
                      mr: 'त्वरित बहु-शोध सुविधा',
                      hi: 'त्वरित मल्टी-सर्च',
                    ),
                    desc: AppTranslations.pick(
                      lang,
                      en: 'Search instantly by name, EPIC number, address, mobile, or roll serial number.',
                      mr: 'नाव, EPIC क्रमांक, पत्ता, मोबाईल किंवा यादीतील अनुक्रमांकाद्वारे त्वरित शोधा.',
                      hi: 'नाम, EPIC नंबर, पता, मोबाइल या सूची क्रमांक से तुरंत खोजें।',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHelpPoint(
                    icon: Icons.badge_outlined,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Official Voter Slip',
                      mr: 'अधिकृत मतदान पावती',
                      hi: 'आधिकारिक मतदाता पर्ची',
                    ),
                    desc: AppTranslations.pick(
                      lang,
                      en: 'Send official slip via WhatsApp in 1-tap or print PDF directly.',
                      mr: 'एका क्लिकवर व्हॉट्सअॅपवर अधिकृत पावती पाठवा किंवा थेट PDF प्रिंट करा.',
                      hi: 'एक टैप में व्हाट्सऐप पर आधिकारिक पर्ची भेजें या सीधे PDF प्रिंट करें।',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHelpPoint(
                    icon: Icons.family_restroom_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Family Grouping',
                      mr: 'कुटुंबनिहाय गटवारी',
                      hi: 'परिवार समूह दृश्य',
                    ),
                    desc: AppTranslations.pick(
                      lang,
                      en: 'Group all voters by house number and view household relationships.',
                      mr: 'घर क्रमांकानुसार सर्व मतदारांचे गट पहा आणि कौटुंबिक नातेसंबंध तपासा.',
                      hi: 'मकान नंबर के अनुसार सभी मतदाताओं को समूहित करें और पारिवारिक संबंध देखें।',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHelpPoint(
                    icon: Icons.how_to_vote_outlined,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Political Stance Tagging',
                      mr: 'राजकीय भूमिका नोंदणी',
                      hi: 'राजनीतिक रुझान टैगिंग',
                    ),
                    desc: AppTranslations.pick(
                      lang,
                      en: 'Tag voter stance as Favourable, Neutral, Against, or Undecided for ward strategy.',
                      mr: 'प्रभाग रणनीतीसाठी मतदाराची भूमिका अनुकूल, तटस्थ, प्रतिकूल किंवा अनिश्चित अशी नोंदवा.',
                      hi: 'वार्ड रणनीति के लिए मतदाता का रुझान अनुकूल, तटस्थ, प्रतिकूल या अनिश्चित के रूप में टैग करें।',
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

  void _showFilterSheet(String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.pick(lang, en: 'Filters', mr: 'फिल्टर', hi: 'फ़िल्टर'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBooth = 'All';
                          _selectedFavour = 'All';
                          _selectedGender = 'All';
                          _selectedAgeRange = 'All';
                          _friendsOnly = false;
                          _currentPage = 1;
                        });
                        Navigator.pop(ctx);
                        _loadVoters();
                      },
                      child: Text(AppTranslations.pick(lang, en: 'Reset', mr: 'रीसेट करा', hi: 'रीसेट करें')),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Gender
                Text(
                  AppTranslations.pick(lang, en: 'Gender', mr: 'लिंग', hi: 'लिंग'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    {'key': 'All', 'label': AppTranslations.getAll(lang)},
                    {'key': 'M', 'label': AppTranslations.getGender('M', lang)},
                    {'key': 'F', 'label': AppTranslations.getGender('F', lang)},
                  ].map((g) {
                    final sel = _selectedGender == g['key'];
                    return ChoiceChip(
                      label: Text(g['label']!),
                      selected: sel,
                      onSelected: (_) {
                        setModalState(() => _selectedGender = g['key']!);
                        setState(() => _selectedGender = g['key']!);
                      },
                      selectedColor: const Color(0xFF0284C7),
                      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontSize: 12),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Age Brackets
                Text(
                  AppTranslations.pick(lang, en: 'Age Range', mr: 'वयोगट', hi: 'आयु वर्ग'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    {'key': 'All', 'label': AppTranslations.getAll(lang)},
                    {
                      'key': '18-25',
                      'label': AppTranslations.pick(lang, en: '18-25 (Youth)', mr: '१८-२५ (युवा)', hi: '१८-२५ (युवा)'),
                    },
                    {
                      'key': '26-40',
                      'label': AppTranslations.formatDigits('26-40', lang),
                    },
                    {
                      'key': '41-60',
                      'label': AppTranslations.formatDigits('41-60', lang),
                    },
                    {
                      'key': '60+',
                      'label': AppTranslations.pick(lang, en: '60+ (Senior)', mr: '६०+ (ज्येष्ठ)', hi: '६०+ (वरिष्ठ)'),
                    },
                  ].map((a) {
                    final sel = _selectedAgeRange == a['key'];
                    return ChoiceChip(
                      label: Text(a['label']!),
                      selected: sel,
                      onSelected: (_) {
                        setModalState(() => _selectedAgeRange = a['key']!);
                        setState(() => _selectedAgeRange = a['key']!);
                      },
                      selectedColor: const Color(0xFF0284C7),
                      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontSize: 12),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Friends only toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Only Friends & Relatives',
                      mr: 'फक्त मित्र आणि नातेवाईक',
                      hi: 'केवल मित्र और रिश्तेदार',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  value: _friendsOnly,
                  activeColor: const Color(0xFF0284C7),
                  onChanged: (val) {
                    setModalState(() => _friendsOnly = val);
                    setState(() => _friendsOnly = val);
                  },
                ),

                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _currentPage = 1);
                      Navigator.pop(ctx);
                      _loadVoters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      AppTranslations.pick(lang, en: 'Apply Filters', mr: 'फिल्टर लागू करा', hi: 'फ़िल्टर लागू करें'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddVoterModal() {
    final lang = ref.read(appLanguageProvider);
    final epicNoCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final nameMrCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String gender = 'M';
    final casteCtrl = TextEditingController();
    final addressEnCtrl = TextEditingController();
    final addressMrCtrl = TextEditingController();
    final houseCtrl = TextEditingController();
    final wardCtrl = TextEditingController(text: '12');
    final acCtrl = TextEditingController(text: '214');
    final boothCtrl = TextEditingController(
      text: _selectedBooth != 'All'
          ? _selectedBooth
          : AppTranslations.pick(lang, en: '28/Shaniwar Peth', mr: '२८/शनिवार पेठ', hi: '२८/शनिवार पेठ'),
    );
    final serialCtrl = TextEditingController();

    InputDecoration inputDec({String? hintText, Widget? prefixIcon, String? prefixText}) {
      return InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
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
                AppModalHeader(
                  icon: Icons.person_add_rounded,
                  title: AppTranslations.pick(
                    lang,
                    en: 'Add New Voter',
                    mr: 'नवीन मतदार नोंदवा',
                    hi: 'नया मतदाता जोड़ें',
                  ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Ward 12 Voter Registration',
                    mr: 'प्रभाग १२ मतदार यादी नोंदणी',
                    hi: 'वार्ड १२ मतदाता पंजीकरण',
                  ),
                  onClose: () => Navigator.pop(ctx),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Section 1: Basic Information
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
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Basic Information',
                                mr: 'प्राथमिक माहिती',
                                hi: 'बुनियादी जानकारी',
                              ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // EPIC No & Mobile
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
                                          en: 'EPIC No',
                                          mr: 'ओळखपत्र क्र. (EPIC No)',
                                          hi: 'पहचान पत्र क्र. (EPIC No)',
                                        ),
                                        isRequired: true,
                                      ),
                                      TextField(
                                        controller: epicNoCtrl,
                                        textCapitalization: TextCapitalization.characters,
                                        decoration: inputDec(hintText: 'MH/12/042/102941'),
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
                                          en: 'Mobile Number',
                                          mr: 'मोबाईल नंबर',
                                          hi: 'मोबाइल नंबर',
                                        ),
                                      ),
                                      TextField(
                                        controller: mobileCtrl,
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                        decoration: inputDec(
                                          prefixText: AppTranslations.formatDigits('+91 ', lang),
                                          hintText: AppTranslations.formatDigits('98220xxxxx', lang),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Name English & Marathi
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
                                          en: 'Full Name (English)',
                                          mr: 'पूर्ण नाव (इंग्रजी)',
                                          hi: 'पूरा नाम (अंग्रेज़ी)',
                                        ),
                                        isRequired: true,
                                      ),
                                      TextField(
                                        controller: nameEnCtrl,
                                        decoration: inputDec(hintText: 'e.g. Ramesh Kadam'),
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
                                          en: 'Full Name (Local)',
                                          mr: 'पूर्ण नाव (मराठी)',
                                          hi: 'पूरा नाम (हिंदी/मराठी)',
                                        ),
                                      ),
                                      TextField(
                                        controller: nameMrCtrl,
                                        decoration: inputDec(
                                          hintText: AppTranslations.pick(
                                            lang,
                                            en: 'e.g. रमेश कदम',
                                            mr: 'उदा. रमेश कदम',
                                            hi: 'उदा. रमेश कदम',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Age & Gender
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppFieldLabel(
                                        label: AppTranslations.pick(lang, en: 'Age', mr: 'वय', hi: 'उम्र'),
                                        isRequired: true,
                                      ),
                                      TextField(
                                        controller: ageCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: inputDec(
                                          hintText: AppTranslations.pick(lang, en: 'e.g. 35', mr: 'उदा. ३५', hi: 'उदा. ३५'),
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
                                        label: AppTranslations.pick(lang, en: 'Gender', mr: 'लिंग', hi: 'लिंग'),
                                        isRequired: true,
                                        value: gender,
                                        items: [
                                          DropdownMenuItem(value: 'M', child: Text(AppTranslations.getGender('M', lang))),
                                          DropdownMenuItem(value: 'F', child: Text(AppTranslations.getGender('F', lang))),
                                          DropdownMenuItem(value: 'O', child: Text(AppTranslations.getGender('O', lang))),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) setModalState(() => gender = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Caste
                            AppFieldLabel(
                              label: AppTranslations.pick(
                                lang,
                                en: 'Caste / Category',
                                mr: 'जात / प्रवर्ग',
                                hi: 'जाति / वर्ग',
                              ),
                            ),
                            TextField(
                              controller: casteCtrl,
                              decoration: inputDec(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Open, OBC, SC, etc.',
                                  mr: 'उदा. मराठा, ब्राह्मण, ओबीसी, इ.',
                                  hi: 'उदा. सामान्य, ओबीसी, एससी आदि।',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Address & Booth Details
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
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Address & Booth Details',
                                mr: 'पत्ता व मतदान केंद्र तपशील',
                                hi: 'पता और मतदान केंद्र विवरण',
                              ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppFieldLabel(
                              label: AppTranslations.pick(
                                lang,
                                en: 'Address (English)',
                                mr: 'पत्ता (इंग्रजी)',
                                hi: 'पता (अंग्रेज़ी)',
                              ),
                            ),
                            TextField(
                              controller: addressEnCtrl,
                              maxLines: 2,
                              decoration: inputDec(hintText: 'e.g. Sadashiv Sadan, Shaniwar Peth, Pune'),
                            ),
                            const SizedBox(height: 12),
                            AppFieldLabel(
                              label: AppTranslations.pick(
                                lang,
                                en: 'Address (Local)',
                                mr: 'पत्ता (मराठी)',
                                hi: 'पता (हिंदी/मराठी)',
                              ),
                            ),
                            TextField(
                              controller: addressMrCtrl,
                              maxLines: 2,
                              decoration: inputDec(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. सदाशिव सदन, शनिवार पेठ, पुणे - ४११०३०',
                                  mr: 'उदा. सदाशिव सदन, शनिवार पेठ, पुणे - ४११०३०',
                                  hi: 'उदा. सदाशिव सदन, शनिवार पेठ, पुणे - ४११०३०',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppFieldLabel(
                                        label: AppTranslations.pick(lang, en: 'House No', mr: 'घर क्र.', hi: 'मकान नं.'),
                                      ),
                                      TextField(
                                        controller: houseCtrl,
                                        decoration: inputDec(
                                          hintText: AppTranslations.pick(lang, en: 'e.g. 42', mr: 'उदा. ४२', hi: 'उदा. ४२'),
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
                                        label: AppTranslations.pick(lang, en: 'Ward No', mr: 'प्रभाग क्र.', hi: 'वार्ड क्र.'),
                                      ),
                                      TextField(
                                        controller: wardCtrl,
                                        decoration: inputDec(
                                          hintText: AppTranslations.pick(lang, en: 'e.g. 12', mr: 'उदा. १२', hi: 'उदा. १२'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppFieldLabel(
                                        label: AppTranslations.pick(lang, en: 'AC No', mr: 'विधानसभा क्र.', hi: 'विधानसभा क्र.'),
                                      ),
                                      TextField(
                                        controller: acCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: inputDec(hintText: AppTranslations.formatDigits('214', lang)),
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
                                          en: 'Part / Booth No',
                                          mr: 'यादी भाग / केंद्र',
                                          hi: 'भाग / बूथ नं.',
                                        ),
                                      ),
                                      TextField(
                                        controller: boothCtrl,
                                        decoration: inputDec(
                                          hintText: AppTranslations.pick(
                                            lang,
                                            en: '28/Shaniwar Peth',
                                            mr: '२८/शनिवार पेठ',
                                            hi: '२८/शनिवार पेठ',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AppFieldLabel(
                              label: AppTranslations.pick(
                                lang,
                                en: 'Serial No in Electoral Roll',
                                mr: 'यादीतील अनुक्रमांक',
                                hi: 'मतदाता सूची क्रमांक',
                              ),
                            ),
                            TextField(
                              controller: serialCtrl,
                              keyboardType: TextInputType.number,
                              decoration: inputDec(
                                hintText: AppTranslations.pick(lang, en: 'e.g. 145', mr: 'उदा. १४५', hi: 'उदा. १४५'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit & Cancel Buttons
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
                                AppTranslations.pick(lang, en: 'Save Voter', mr: 'मतदार जतन करा', hi: 'मतदाता सहेजें'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              onPressed: () async {
                                if (epicNoCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Please enter EPIC No.',
                                          mr: 'कृपया ओळखपत्र क्र. (EPIC No) प्रविष्ट करा.',
                                          hi: 'कृपया EPIC नंबर दर्ज करें।',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (nameEnCtrl.text.trim().isEmpty && nameMrCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Please enter voter name.',
                                          mr: 'कृपया मतदाराचे नाव प्रविष्ट करा.',
                                          hi: 'कृपया मतदाता का नाम दर्ज करें।',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (ageCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Please enter age.',
                                          mr: 'कृपया वय प्रविष्ट करा.',
                                          hi: 'कृपया उम्र दर्ज करें।',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final epic = AppTranslations.normalizeAsciiDigits(epicNoCtrl.text.trim()).toUpperCase();
                                final nameEn = nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : nameMrCtrl.text.trim();
                                final nameMr = nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : nameEn;
                                final age = int.tryParse(AppTranslations.normalizeAsciiDigits(ageCtrl.text.trim())) ?? 18;
                                final booth = boothCtrl.text.trim().isNotEmpty ? boothCtrl.text.trim() : '२८/शनिवार पेठ';
                                final address = addressMrCtrl.text.trim().isNotEmpty
                                    ? addressMrCtrl.text.trim()
                                    : (addressEnCtrl.text.trim().isNotEmpty ? addressEnCtrl.text.trim() : 'शनिवार पेठ, पुणे');
                                final serial = int.tryParse(AppTranslations.normalizeAsciiDigits(serialCtrl.text.trim()));
                                final house = AppTranslations.normalizeAsciiDigits(houseCtrl.text.trim());
                                final mobile = AppTranslations.normalizeAsciiDigits(mobileCtrl.text.trim());

                                final newVoter = VoterModel(
                                  id: 'vtr-${DateTime.now().millisecondsSinceEpoch}',
                                  nameMarathi: nameMr,
                                  nameEnglish: nameEn,
                                  epicNo: epic,
                                  booth: booth,
                                  serialNo: serial,
                                  address: address,
                                  houseNo: house.isNotEmpty ? house : null,
                                  age: age,
                                  gender: gender,
                                  mobile: mobile.isNotEmpty ? mobile : null,
                                  caste: casteCtrl.text.trim().isNotEmpty ? casteCtrl.text.trim() : null,
                                  favour: 'Neutral',
                                  isFriendRelative: false,
                                  relationType: 'Self',
                                );

                                final messenger = ScaffoldMessenger.of(context);
                                await ref.read(votersRepoProvider).addVoter(newVoter);

                                if (ctx.mounted) Navigator.pop(ctx);
                                if (!mounted) return;
                                _loadVoters();

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Voter added successfully!',
                                        mr: 'नवीन मतदार यशस्वीरित्या जोडला गेला!',
                                        hi: 'नया मतदाता सफलतापूर्वक जोड़ा गया!',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              },
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final filtered = _filteredVoters;
    final totalRoll = _voterStats['total'] ?? 42560;
    final favCount = _voterStats['favourable'] ?? 0;
    final neutralCount = _voterStats['neutral'] ?? 0;
    final boothsCount = _voterStats['booths'] ?? 28;

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
            tooltip: AppTranslations.pick(
              lang,
              en: 'Open Menu Drawer',
              mr: 'मेनू ड्रॉवर उघडा',
              hi: 'मेनू ड्रॉवर खोलें',
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
                en: 'Voter Search',
                mr: 'मतदार शोध',
                hi: 'मतदाता खोज',
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
                en: 'Voter directory & booth lookup',
                mr: 'मतदार यादी आणि बूथ तपशील',
                hi: 'मतदाता निर्देशिका और बूथ जानकारी',
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
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Voter Search Guide',
              mr: 'मतदार शोध मार्गदर्शक',
              hi: 'मतदाता खोज गाइड',
            ),
            onPressed: () => _showHelpGuide(lang),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Add Voter',
              mr: 'मतदार जोडा',
              hi: 'मतदाता जोड़ें',
            ),
            onPressed: _showAddVoterModal,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVoters,
        color: const Color(0xFF0284C7),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // KPI Stats Header Row
            _buildKpiStrip(totalRoll, favCount, neutralCount, boothsCount, lang),
            const SizedBox(height: 14),

            // Search & Booth Filter Bar
            _buildSearchBar(lang),
            const SizedBox(height: 10),

            // Political Stance Filter Chips Row
            _buildStanceFilterChips(lang),
            const SizedBox(height: 10),

            // View Mode & Result Count Row
            _buildViewModeBar(filtered, _totalItems > 0 ? _totalItems : totalRoll, lang),
            const SizedBox(height: 14),

            // Render Voters by Selected View Mode
            if (_isLoading)
              const AppShimmerList(count: 6)
            else if (filtered.isEmpty)
              _buildEmptyState(lang)
            else if (_viewMode == 'family')
              ..._buildFamilyGroupedCards(lang)
            else if (_viewMode == 'table')
              _buildTableView(filtered, lang)
            else
              ...filtered.map((v) => _buildVoterCard(v, lang)),

            if (!_isLoading && filtered.isNotEmpty)
              AppLoadMoreFooter(
                currentCount: _allVoters.length,
                totalCount: _totalItems,
                isLoading: _isLoadingMore,
                pageSize: _pageSize,
                onLoadMore: _loadMoreVoters,
                label: AppTranslations.pick(
                  lang,
                  en: 'voters',
                  mr: 'मतदार',
                  hi: 'मतदाता',
                ),
                isMarathi: lang == 'mr',
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          AppTranslations.pick(
            lang,
            en: 'Add Voter',
            mr: 'मतदार जोडा',
            hi: 'मतदाता जोड़ें',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: _showAddVoterModal,
      ),
    );
  }

  Widget _buildKpiStrip(int total, int fav, int neutral, int booths, String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: AppTranslations.pick(lang, en: 'Total Voters', mr: 'एकूण मतदार', hi: 'कुल मतदाता'),
            value: _formatIndianInt(total, lang),
            subtitle: AppTranslations.pick(lang, en: 'Ward 12 Roll', mr: 'प्रभाग १२ यादी', hi: 'वार्ड १२ सूची'),
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: AppTranslations.pick(lang, en: 'Favourable Voters', mr: 'अनुकूल मतदार', hi: 'अनुकूल मतदाता'),
            value: AppTranslations.formatDigits(fav, lang),
            subtitle: AppTranslations.pick(lang, en: 'Aligned with Party', mr: 'पक्षाशी संलग्न', hi: 'पार्टी से जुड़े'),
            icon: Icons.thumb_up_alt_rounded,
            color: const Color(0xFF16A34A),
            bg: const Color(0xFFDCFCE7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: AppTranslations.pick(lang, en: 'Neutral / Undecided', mr: 'तटस्थ / अनिश्चित', hi: 'तटस्थ / अनिश्चित'),
            value: AppTranslations.formatDigits(neutral, lang),
            subtitle: AppTranslations.pick(lang, en: 'Follow-up Required', mr: 'पाठपुरावा आवश्यक', hi: 'संपर्क आवश्यक'),
            icon: Icons.change_circle_outlined,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            title: AppTranslations.pick(lang, en: 'Polling Stations', mr: 'मतदान केंद्रे', hi: 'मतदान केंद्र'),
            value: AppTranslations.formatDigits(booths, lang),
            subtitle: AppTranslations.pick(lang, en: 'Total Booths', mr: 'एकूण बूथ', hi: 'कुल बूथ'),
            icon: Icons.location_city_rounded,
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

  Widget _buildSearchBar(String lang) {
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
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                setState(() => _currentPage = 1);
                _loadVoters();
              },
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search name, EPIC, address, mobile or serial no...',
                  mr: 'नाव, EPIC, पत्ता, मोबाईल किंवा अनुक्रमांक शोधा...',
                  hi: 'नाम, EPIC, पता, मोबाइल या क्रमांक खोजें...',
                ),
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _currentPage = 1);
                          _loadVoters();
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade200),

          // Booth Filter Dropdown (Themed Component)
          AppDropdown<String>(
            title: AppTranslations.pick(lang, en: 'Filter by Booth', mr: 'बूथनुसार निवडा', hi: 'बूथ से फ़िल्टर करें'),
            value: _selectedBooth,
            height: 36,
            isExpanded: false,
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            hintText: AppTranslations.pick(lang, en: 'Select Booth', mr: 'बूथ निवडा', hi: 'बूथ चुनें'),
            prefixIcon: Icon(
              Icons.how_to_vote_outlined,
              size: 16,
              color: _selectedBooth != 'All' ? const Color(0xFF0284C7) : Colors.grey.shade600,
            ),
            items: [
              DropdownMenuItem(
                value: 'All',
                child: Text(AppTranslations.pick(lang, en: 'All Booths', mr: 'सर्व बूथ', hi: 'सभी बूथ')),
              ),
              ..._boothsList.map(
                (b) => DropdownMenuItem(
                  value: b,
                  child: AppTranslatedText(b, targetLanguage: lang),
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedBooth = val;
                  _currentPage = 1;
                });
                _loadVoters();
              }
            },
          ),

          // Filter Button
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              size: 20,
              color: (_selectedGender != 'All' || _selectedAgeRange != 'All' || _friendsOnly)
                  ? const Color(0xFF0284C7)
                  : Colors.grey.shade600,
            ),
            tooltip: AppTranslations.pick(lang, en: 'More Filters', mr: 'अधिक फिल्टर', hi: 'अधिक फ़िल्टर'),
            onPressed: () => _showFilterSheet(lang),
          ),
        ],
      ),
    );
  }

  Widget _buildStanceFilterChips(String lang) {
    final chips = [
      {
        'key': 'All',
        'label': AppTranslations.pick(lang, en: 'All Voters', mr: 'सर्व मतदार', hi: 'सभी मतदाता'),
      },
      {
        'key': 'Favourable',
        'label': AppTranslations.pick(lang, en: 'Favourable', mr: 'अनुकूल', hi: 'अनुकूल'),
        'color': const Color(0xFF16A34A),
      },
      {
        'key': 'Neutral',
        'label': AppTranslations.pick(lang, en: 'Neutral', mr: 'तटस्थ', hi: 'तटस्थ'),
        'color': const Color(0xFF0284C7),
      },
      {
        'key': 'Against',
        'label': AppTranslations.pick(lang, en: 'Against', mr: 'प्रतिकूल', hi: 'प्रतिकूल'),
        'color': const Color(0xFFDC2626),
      },
      {
        'key': 'Swing',
        'label': AppTranslations.pick(lang, en: 'Undecided', mr: 'अनिश्चित', hi: 'अनिश्चित'),
        'color': const Color(0xFFD97706),
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final isSel = _selectedFavour.toLowerCase() == c['key']!.toString().toLowerCase();
          final clr = c['color'] as Color? ?? const Color(0xFF0284C7);

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(c['label']!.toString()),
              selected: isSel,
              onSelected: (_) {
                setState(() {
                  _selectedFavour = c['key']!.toString();
                  _currentPage = 1;
                });
                _loadVoters();
              },
              selectedColor: clr,
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? Colors.white : Colors.grey.shade700,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(color: isSel ? clr : Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewModeBar(List<VoterModel> filtered, int totalRoll, String lang) {
    final cntStr = AppTranslations.formatDigits(filtered.length, lang);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            AppTranslations.pick(
              lang,
              en: '$cntStr voters found',
              mr: '$cntStr मतदार आढळले',
              hi: '$cntStr मतदाता मिले',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    icon: Icon(Icons.family_restroom_rounded, size: 17, color: _viewMode == 'family' ? const Color(0xFF0284C7) : Colors.grey),
                    tooltip: AppTranslations.pick(lang, en: 'Family Group View', mr: 'कुटुंब गट दृश्य', hi: 'परिवार समूह दृश्य'),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _viewMode = 'family'),
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
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppPdfButton.icon(
                    tooltip: AppTranslations.getDownloadReport(lang),
                    onPressed: () => VoterSlipGenerator.downloadVotersListReport(
                      voters: filtered,
                      totalCount: totalRoll,
                      currentFilterSummary: _selectedBooth != 'All'
                          ? '${AppTranslations.pick(lang, en: "Booth", mr: "बूथ", hi: "बूथ")}: $_selectedBooth'
                          : null,
                      lang: lang,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoterCard(VoterModel voter, String lang) {
    Color favourColor = const Color(0xFF64748B);
    Color favourBg = const Color(0xFFF1F5F9);

    switch (voter.favour?.toLowerCase()) {
      case 'favourable':
        favourColor = const Color(0xFF16A34A);
        favourBg = const Color(0xFFDCFCE7);
        break;
      case 'against':
        favourColor = const Color(0xFFDC2626);
        favourBg = const Color(0xFFFEE2E2);
        break;
      case 'neutral':
        favourColor = const Color(0xFF0284C7);
        favourBg = const Color(0xFFE0F2FE);
        break;
      case 'swing':
        favourColor = const Color(0xFFD97706);
        favourBg = const Color(0xFFFEF3C7);
        break;
    }

    final displayName = voter.displayNameFor(lang);
    final ageStr = AppTranslations.formatDigits(voter.age, lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
            MaterialPageRoute(builder: (_) => VoterProfileScreen(voter: voter)),
          ).then((res) {
            if (res == true) _loadVoters(showLoading: false);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar, Names, Serial, Stance
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(
                      displayName.isNotEmpty ? displayName.substring(0, 1) : 'V',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTranslatedText(
                                displayName,
                                targetLanguage: lang,
                                isName: true,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                            if (voter.isFriendRelative)
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'EPIC: ${AppTranslations.formatDigits(voter.epicNo, lang)}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ),
                            if (voter.serialNo != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '#${AppTranslations.formatDigits(voter.serialNo, lang)}',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: favourBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: favourColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      voter.favourLabel(lang),
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: favourColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Address & Booth info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppTranslatedText(
                      '${voter.houseNo != null ? "#${voter.houseNo}, " : ""}${voter.address}',
                      targetLanguage: lang,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.how_to_vote_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.pick(lang, en: 'Booth: ', mr: 'बूथ: ', hi: 'बूथ: '),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      Flexible(
                        child: AppTranslatedText(
                          voter.booth,
                          targetLanguage: lang,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text('•', style: TextStyle(color: Colors.grey.shade400)),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Age: $ageStr Yrs (${voter.genderLabel(lang)})',
                      mr: 'वय: $ageStr वर्षे (${voter.genderLabel(lang)})',
                      hi: 'उम्र: $ageStr वर्ष (${voter.genderLabel(lang)})',
                    ),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print, size: 14, color: Color(0xFF0284C7)),
                    label: Text(
                      AppTranslations.pick(lang, en: 'Slip', mr: 'पावती', hi: 'पर्ची'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => VoterSlipGenerator.printVoterSlip(voter, lang: lang),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 13, color: Colors.white),
                    label: Text(
                      AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सअॅप', hi: 'व्हाट्सऐप'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _shareSlipOnWhatsApp(voter, lang),
                  ),
                  if (voter.mobile != null && voter.mobile!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.phone, size: 18, color: Color(0xFF0284C7)),
                      tooltip: AppTranslations.pick(lang, en: 'Call', mr: 'कॉल', hi: 'कॉल'),
                      onPressed: () => _callVoter(voter.mobile, lang),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFamilyGroupedCards(String lang) {
    final families = _groupedFamilies;

    return families.entries.map((entry) {
      final members = entry.value;
      final first = members.first;
      final houseNo = first.houseNo ?? AppTranslations.pick(lang, en: 'N/A', mr: 'उपलब्ध नाही', hi: 'उपलब्ध नहीं');
      final booth = first.booth;
      final countStr = AppTranslations.formatDigits(members.length, lang);

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Family Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home_rounded, size: 16, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'House No. #${AppTranslations.formatDigits(houseNo, lang)} • ',
                                mr: 'घर क्र. #${AppTranslations.formatDigits(houseNo, lang)} • ',
                                hi: 'मकान नं. #${AppTranslations.formatDigits(houseNo, lang)} • ',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            Expanded(
                              child: AppTranslatedText(
                                booth,
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                        AppTranslatedText(
                          first.address,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: '$countStr Voters',
                        mr: '$countStr मतदार',
                        hi: '$countStr मतदाता',
                      ),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ),

            // Family Members List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: members.length,
              separatorBuilder: (_, _) => const Divider(height: 8),
              itemBuilder: (ctx, idx) {
                final m = members[idx];
                final mName = m.displayNameFor(lang);
                final mAge = AppTranslations.formatDigits(m.age, lang);
                final mEpic = AppTranslations.formatDigits(m.epicNo, lang);
                final mSerial = m.serialNo != null ? ' • #${AppTranslations.formatDigits(m.serialNo, lang)}' : '';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VoterProfileScreen(voter: m)),
                    ).then((res) {
                      if (res == true) _loadVoters(showLoading: false);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: Text(
                            mName.isNotEmpty ? mName.substring(0, 1) : 'V',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTranslatedText(
                                mName,
                                targetLanguage: lang,
                                isName: true,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Age: $mAge • ${m.genderLabel(lang)} • EPIC: $mEpic$mSerial',
                                  mr: 'वय: $mAge • ${m.genderLabel(lang)} • EPIC: $mEpic$mSerial',
                                  hi: 'उम्र: $mAge • ${m.genderLabel(lang)} • EPIC: $mEpic$mSerial',
                                ),
                                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        if (m.favour != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: m.favour == 'Favourable'
                                  ? const Color(0xFFDCFCE7)
                                  : (m.favour == 'Against' ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.favourLabel(lang),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: m.favour == 'Favourable'
                                    ? const Color(0xFF16A34A)
                                    : (m.favour == 'Against' ? const Color(0xFFDC2626) : const Color(0xFF0284C7)),
                              ),
                            ),
                          ),
                        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTableView(List<VoterModel> list, String lang) {
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
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Name', mr: 'नाव', hi: 'नाम'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'EPIC No.', mr: 'ओळखपत्र क्र.', hi: 'EPIC नं.'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Age/Gender', mr: 'वय/लिंग', hi: 'उम्र/लिंग'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Address', mr: 'पत्ता', hi: 'पता'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Booth', mr: 'बूथ', hi: 'बूथ'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Political Stance', mr: 'राजकीय भूमिका', hi: 'राजनीतिक रुझान'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  AppTranslations.pick(lang, en: 'Action', mr: 'कृती', hi: 'कार्रवाई'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
            rows: list.asMap().entries.map((entry) {
              final idx = entry.key;
              final v = entry.value;

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      AppTranslations.formatDigits(v.serialNo ?? (idx + 1), lang),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VoterProfileScreen(voter: v)),
                        ).then((res) {
                          if (res == true) _loadVoters(showLoading: false);
                        });
                      },
                      child: AppTranslatedText(
                        v.displayNameFor(lang),
                        targetLanguage: lang,
                        isName: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      AppTranslations.formatDigits(v.epicNo, lang),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${AppTranslations.formatDigits(v.age, lang)} / ${v.genderLabel(lang)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: AppTranslatedText(
                        '${v.houseNo != null ? "#${v.houseNo}, " : ""}${v.address}',
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    AppTranslatedText(
                      v.booth,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      v.favourLabel(lang),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: v.favour == 'Favourable'
                            ? const Color(0xFF16A34A)
                            : (v.favour == 'Against' ? const Color(0xFFDC2626) : const Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print, size: 16, color: Color(0xFF0284C7)),
                          tooltip: AppTranslations.pick(lang, en: 'Slip', mr: 'पावती', hi: 'पर्ची'),
                          onPressed: () => VoterSlipGenerator.printVoterSlip(v, lang: lang),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, size: 15, color: Color(0xFF25D366)),
                          tooltip: AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सअॅप', hi: 'व्हाट्सऐप'),
                          onPressed: () => _shareSlipOnWhatsApp(v, lang),
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
          Icon(Icons.person_search_outlined, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No voters found',
              mr: 'मतदार आढळले नाहीत',
              hi: 'कोई मतदाता नहीं मिला',
            ),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Please check the spelling of name, EPIC number or address and search again.',
              mr: 'कृपया नाव, ओळखपत्र क्र. किंवा पत्त्याची खात्री करून पुन्हा शोधा.',
              hi: 'कृपया नाम, EPIC नंबर या पते की जांच करें और पुनः खोजें।',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() {
                _selectedBooth = 'All';
                _selectedFavour = 'All';
                _selectedGender = 'All';
                _selectedAgeRange = 'All';
                _friendsOnly = false;
              });
              _loadVoters();
            },
            child: Text(
              AppTranslations.pick(lang, en: 'Show All Voters', mr: 'सर्व मतदार पहा', hi: 'सभी मतदाता देखें'),
            ),
          ),
        ],
      ),
    );
  }
}
