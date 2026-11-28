import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/whatsapp_repository.dart';
import 'whatsapp_history_report_generator.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';

// WhatsApp brand colors
const _kWaGreen = Color(0xFF25D366);
const _kWaDark = Color(0xFF075E54);
const _kWaLight = Color(0xFFE8F5E9);
const _kWaLightBorder = Color(0xFFA5D6A7);

class WhatsAppCommunicationScreen extends ConsumerStatefulWidget {
  const WhatsAppCommunicationScreen({super.key});

  @override
  ConsumerState<WhatsAppCommunicationScreen> createState() => _WhatsAppCommunicationScreenState();
}

class _WhatsAppCommunicationScreenState
    extends ConsumerState<WhatsAppCommunicationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Filter controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _casteController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _ageFilter = 'All';
  String _genderFilter = 'All';
  String _boothFilter = 'All';

  // Voter state
  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];
  final Set<String> _selectedVoterIds = {};
  bool _isAllVisibleSelected = false;
  int _voterLimit = 20;

  List<VoterModel> get _visibleVoters =>
      _voters.take(_voterLimit).toList();

  // History state
  bool _isLoadingHistory = false;
  List<WhatsAppBroadcastModel> _broadcastHistory = [];
  int _historyLimit = 10;

  List<WhatsAppBroadcastModel> get _visibleHistory =>
      _broadcastHistory.take(_historyLimit).toList();

  // Compose state
  bool _isSending = false;
  WhatsAppTemplateModel? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _broadcastHistory.isEmpty) {
        _loadHistory();
      }
      setState(() {});
    });

    _loadVoters();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _houseNoController.dispose();
    _casteController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoadingVoters = true);
    final repo = ref.read(whatsAppRepoProvider);
    try {
      final list = await repo.getVotersWithMobile(
        name: AppTranslations.normalizeAsciiDigits(_nameController.text.trim()),
        address: AppTranslations.normalizeAsciiDigits(_addressController.text.trim()),
        houseNo: AppTranslations.normalizeAsciiDigits(_houseNoController.text.trim()),
        ageRange: _ageFilter,
        gender: _genderFilter,
        caste: AppTranslations.normalizeAsciiDigits(_casteController.text.trim()),
        booth: _boothFilter,
      );
      if (mounted) {
        setState(() {
          _voters = list;
          _isLoadingVoters = false;
          _voterLimit = 20;
          _updateSelectAllStatus();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVoters = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final repo = ref.read(whatsAppRepoProvider);
    try {
      final logs = await repo.getBroadcastHistory();
      if (mounted) {
        setState(() {
          _broadcastHistory = logs;
          _isLoadingHistory = false;
          _historyLimit = 10;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _updateSelectAllStatus() {
    if (_voters.isEmpty) {
      _isAllVisibleSelected = false;
      return;
    }
    _isAllVisibleSelected = _voters.every((v) => _selectedVoterIds.contains(v.id));
  }

  void _toggleSelectVoter(String voterId) {
    setState(() {
      if (_selectedVoterIds.contains(voterId)) {
        _selectedVoterIds.remove(voterId);
      } else {
        _selectedVoterIds.add(voterId);
      }
      _updateSelectAllStatus();
    });
  }

  void _handleSelectAllVisible() {
    setState(() {
      if (_isAllVisibleSelected) {
        for (final v in _voters) {
          _selectedVoterIds.remove(v.id);
        }
        _isAllVisibleSelected = false;
      } else {
        for (final v in _voters) {
          _selectedVoterIds.add(v.id);
        }
        _isAllVisibleSelected = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedVoterIds.clear();
      _isAllVisibleSelected = false;
    });
  }

  void _applyTemplate(WhatsAppTemplateModel template) {
    setState(() {
      _selectedTemplate = template;
      _messageController.text = template.text;
    });
  }

  Future<void> _openDirectWhatsApp(VoterModel voter) async {
    if (voter.mobile == null || voter.mobile!.isEmpty) return;
    final lang = ref.read(appLanguageProvider);
    final repo = ref.read(whatsAppRepoProvider);
    final voterName = await DynamicTranslationService.translateOrRaw(
      voter.displayNameFor(lang),
      lang,
      isName: true,
    );
    final greetText = AppTranslations.pick(
      lang,
      en: 'Greetings $voterName! Contacting you from Ward 12 Corporator Office.',
      mr: 'नमस्कार $voterName! प्रभाग १२ नगरसेवक कार्यालयातून संपर्क साधत आहोत.',
      hi: 'नमस्कार $voterName! वार्ड १२ नगरसेवक कार्यालय से संपर्क कर रहे हैं।',
    );
    await repo.launchDirectWhatsApp(
      mobile: AppTranslations.normalizeAsciiDigits(voter.mobile!),
      text: greetText,
    );
  }

  void _showConfirmationDialog() {
    final lang = ref.read(appLanguageProvider);
    if (_selectedVoterIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please select at least one voter.',
              mr: 'कृपया किमान एक मतदार निवडा.',
              hi: 'कृपया कम से कम एक मतदाता चुनें।',
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please enter message text.',
              mr: 'कृपया संदेशाचा मजकूर प्रविष्ट करा.',
              hi: 'कृपया संदेश लिखें।',
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    final selectedCountStr = AppTranslations.formatDigits(_selectedVoterIds.length, lang);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.send_rounded, color: _kWaGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Confirm WhatsApp Broadcast',
                  mr: 'व्हॉट्सॲप प्रसारणाची खात्री करा',
                  hi: 'व्हाट्सएप प्रसारण की पुष्टि करें',
                ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.pick(
                lang,
                en: 'I confirm that I have reviewed the recipient list and message content and wish to send this official WhatsApp broadcast.',
                mr: 'मी खात्री करतो की मी लाभार्थी यादी आणि संदेश तपासला आहे आणि हे अधिकृत व्हॉट्सॲप प्रसारण पाठवू इच्छितो.',
                hi: 'मैं पुष्टि करता हूँ कि मैंने प्राप्तकर्ता सूची और संदेश सामग्री की समीक्षा कर ली है और यह आधिकारिक व्हाट्सएप प्रसारण भेजना चाहता हूँ।',
              ),
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
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
                        AppTranslations.pick(
                          lang,
                          en: 'Selected Voters:',
                          mr: 'निवडलेले मतदार:',
                          hi: 'चयनित मतदाता:',
                        ),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: '$selectedCountStr Voters',
                          mr: '$selectedCountStr मतदार',
                          hi: '$selectedCountStr मतदाता',
                        ),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kWaDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.pick(lang, en: 'Channel:', mr: 'माध्यम:', hi: 'माध्यम:'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Official WhatsApp (wa.me)',
                          mr: 'अधिकृत व्हॉट्सॲप (wa.me)',
                          hi: 'आधिकारिक व्हाट्सएप (wa.me)',
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Message Preview:',
                      mr: 'संदेश पूर्वावलोकन:',
                      hi: 'संदेश पूर्वावलोकन:',
                    ),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kWaLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _kWaLightBorder),
                    ),
                    child: AppTranslatedText(
                      _messageController.text.trim(),
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kWaGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeSendWhatsApp();
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(
              AppTranslations.pick(
                lang,
                en: 'Confirm & Send',
                mr: 'खात्री करा व पाठवा',
                hi: 'पुष्टि करें व भेजें',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSendWhatsApp() async {
    setState(() => _isSending = true);
    final lang = ref.read(appLanguageProvider);
    final repo = ref.read(whatsAppRepoProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final selectedVotersList = _voters.where((v) => _selectedVoterIds.contains(v.id)).toList();
      final now = DateTime.now();
      final timePart = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final title = _selectedTemplate != null
          ? _selectedTemplate!.title
          : 'WhatsApp Broadcast ${AppTranslations.formatDate(now, 'en', pattern: 'dd MMM')} $timePart';

      final broadcast = await repo.sendBulkWhatsApp(
        title: title,
        message: _messageController.text.trim(),
        recipients: selectedVotersList,
        category: _selectedTemplate?.category,
        targetCriteria: '${selectedVotersList.length} Selected Voters · Ward 12',
      );

      if (mounted) {
        setState(() {
          _isSending = false;
          _selectedVoterIds.clear();
          _isAllVisibleSelected = false;
          _messageController.clear();
          _selectedTemplate = null;
          _broadcastHistory.insert(0, broadcast);
        });

        final recStr = AppTranslations.formatDigits(broadcast.recipients, lang);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'WhatsApp message queued for $recStr voters.',
                mr: '$recStr मतदारांसाठी व्हॉट्सॲप संदेश रांगेत जोडला आहे.',
                hi: '$recStr मतदाताओं के लिए व्हाट्सएप संदेश कतार में जोड़ा गया।',
              ),
            ),
            backgroundColor: _kWaDark,
            duration: const Duration(seconds: 3),
          ),
        );

        _tabController.animateTo(1);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Error sending WhatsApp message. Please try again.',
                mr: 'व्हॉट्सॲप संदेश पाठवताना त्रुटी आली. कृपया पुन्हा प्रयत्न करा.',
                hi: 'व्हाट्सएप संदेश भेजने में त्रुटि हुई। कृपया पुनः प्रयास करें।',
              ),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _generatePdfReport() async {
    final lang = ref.read(appLanguageProvider);
    if (_broadcastHistory.isEmpty) await _loadHistory();
    await WhatsAppHistoryReportGenerator.generateAndPrintReport(
      broadcasts: _broadcastHistory,
      lang: lang,
    );
  }

  void _showHelpTutorialDialog() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: _kWaDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'WhatsApp Communication Guide',
                  mr: 'व्हॉट्सॲप जनसंवाद मार्गदर्शिका',
                  hi: 'व्हाट्सएप संचार गाइड',
                ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTutorialStep(
                step: AppTranslations.formatDigits('1', lang),
                title: AppTranslations.pick(
                  lang,
                  en: 'Select Voters',
                  mr: 'मतदार निवडा',
                  hi: 'मतदाता चुनें',
                ),
                desc: AppTranslations.pick(
                  lang,
                  en: 'Filter and select voters from your directory to prepare targeted WhatsApp communications.',
                  mr: 'लक्ष्यित व्हॉट्सॲप संदेशासाठी आपल्या यादीतून मतदार शोधा व निवडा.',
                  hi: 'लक्षित व्हाट्सएप संदेश भेजने के लिए अपनी सूची से मतदाताओं को फ़िल्टर करें और चुनें।',
                ),
              ),
              _buildTutorialStep(
                step: AppTranslations.formatDigits('2', lang),
                title: AppTranslations.pick(
                  lang,
                  en: 'Filters & Voter Search',
                  mr: 'फिल्टर व मतदार शोध',
                  hi: 'फ़िल्टर और मतदाता खोज',
                ),
                desc: AppTranslations.pick(
                  lang,
                  en: 'Search and filter voters by name, area, house no., age, gender, or community.',
                  mr: 'नाव, परिसर, घर क्र., वय, लिंग किंवा समुदायानुसार मतदार शोधा व फिल्टर करा.',
                  hi: 'नाम, क्षेत्र, मकान नं., आयु, लिंग या समुदाय के अनुसार मतदाताओं को खोजें और फ़िल्टर करें।',
                ),
              ),
              _buildTutorialStep(
                step: AppTranslations.formatDigits('3', lang),
                title: AppTranslations.pick(
                  lang,
                  en: 'Quick Templates or Custom Text',
                  mr: 'त्वरित टेम्प्लेट्स किंवा स्वतःचा मजकूर',
                  hi: 'त्वरित टेम्पलेट्स या कस्टम संदेश',
                ),
                desc: AppTranslations.pick(
                  lang,
                  en: 'Select pre-approved templates for water notices, govt schemes, or festivals in 1-tap, or type your own text.',
                  mr: 'पाणी सूचना, शासकीय योजना किंवा सणांसाठी पूर्व-मंजूर टेम्प्लेट्स १-टॅपमध्ये निवडा किंवा स्वतःचा संदेश टाइप करा.',
                  hi: 'पानी की सूचना, सरकारी योजनाओं या त्योहारों के लिए पूर्व-अनुमोदित टेम्पलेट १-टैप में चुनें या अपना संदेश लिखें।',
                ),
              ),
              _buildTutorialStep(
                step: AppTranslations.formatDigits('4', lang),
                title: AppTranslations.pick(
                  lang,
                  en: '1-Tap Personal WhatsApp',
                  mr: '१-टॅप वैयक्तिक व्हॉट्सॲप',
                  hi: '१-टैप व्यक्तिगत व्हाट्सएप',
                ),
                desc: AppTranslations.pick(
                  lang,
                  en: 'Tap the green WhatsApp icon on any voter card to open a direct 1-on-1 chat in the official WhatsApp app.',
                  mr: 'अधिकृत व्हॉट्सॲप ॲपमध्ये थेट संवादासाठी मतदार कार्डवरील हिरव्या व्हॉट्सॲप चिन्हावर टॅप करा.',
                  hi: 'आधिकारिक व्हाट्सएप ऐप में सीधी चैट खोलने के लिए किसी भी मतदाता कार्ड पर हरे व्हाट्सएप आइकन पर टैप करें।',
                ),
              ),
              _buildTutorialStep(
                step: AppTranslations.formatDigits('5', lang),
                title: AppTranslations.pick(
                  lang,
                  en: 'History & Official Reports',
                  mr: 'इतिहास व अधिकृत अहवाल',
                  hi: 'इतिहास एवं आधिकारिक रिपोर्ट',
                ),
                desc: AppTranslations.pick(
                  lang,
                  en: 'Track delivery metrics across all sent broadcasts and download landscape A4 PDF reports for official records.',
                  mr: 'पाठवलेल्या सर्व प्रसारणांची आकडेवारी पहा आणि अधिकृत नोंदीसाठी A4 PDF अहवाल डाउनलोड करा.',
                  hi: 'सभी भेजे गए प्रसारणों के आंकड़े ट्रैक करें और आधिकारिक रिकॉर्ड के लिए A4 PDF रिपोर्ट डाउनलोड करें।',
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kWaGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Got it', mr: 'समजले', hi: 'समझ गया'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep({required String step, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: _kWaLight, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kWaDark),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
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
                en: 'WhatsApp Message',
                mr: 'व्हॉट्सॲप संदेश',
                hi: 'व्हाट्सएप संदेश',
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
                en: 'WhatsApp broadcasts & campaign reports',
                mr: 'व्हॉट्सॲप प्रसारण व मोहीम अहवाल',
                hi: 'व्हाट्सएप प्रसारण एवं अभियान रिपोर्ट',
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
            tooltip: AppTranslations.pick(lang, en: 'Guide', mr: 'मार्गदर्शिका', hi: 'गाइड'),
            onPressed: _showHelpTutorialDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 13),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Send Message',
                                    mr: 'संदेश पाठवा',
                                    hi: 'संदेश भेजें',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_rounded, size: 13),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'History',
                                    mr: 'इतिहास',
                                    hi: 'इतिहास',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppPdfButton.outlined(
                  label: AppTranslations.pick(lang, en: 'Reports', mr: 'अहवाल', hi: 'रिपोर्ट'),
                  tooltip: AppTranslations.getDownloadReport(lang),
                  onPressed: _generatePdfReport,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendTab(lang),
                _buildHistoryTab(lang),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _tabController.index == 0 && _selectedVoterIds.isNotEmpty ? _buildStickySendBar(lang) : null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 1: Send WhatsApp
  // ─────────────────────────────────────────────────────────────
  Widget _buildSendTab(String lang) {
    final templates = ref.read(whatsAppRepoProvider).getTemplates();
    final charCountStr = AppTranslations.formatDigits(_messageController.text.length, lang);
    final totalVotersStr = AppTranslations.formatDigits(_voters.length, lang);
    final selectedCountStr = AppTranslations.formatDigits(_selectedVoterIds.length, lang);

    return RefreshIndicator(
      onRefresh: _loadVoters,
      color: _kWaGreen,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Quick Templates Strip
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 15, color: _kWaGreen),
                const SizedBox(width: 5),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Quick WhatsApp Templates',
                    mr: 'त्वरित व्हॉट्सॲप टेम्प्लेट्स',
                    hi: 'त्वरित व्हाट्सएप टेम्पलेट्स',
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final t = templates[i];
                  final isSelected = _selectedTemplate?.id == t.id;
                  return InkWell(
                    onTap: () => _applyTemplate(t),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          AppTranslatedText(
                            t.title,
                            targetLanguage: lang,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // 2. WhatsApp Compose Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kWaLightBorder),
                boxShadow: [BoxShadow(color: _kWaGreen.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 14, color: _kWaGreen),
                          const SizedBox(width: 5),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Compose Message *',
                              mr: 'संदेश लिहा *',
                              hi: 'संदेश लिखें *',
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      if (_selectedTemplate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kWaLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _kWaLightBorder),
                          ),
                          child: AppTranslatedText(
                            _selectedTemplate!.category,
                            targetLanguage: lang,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: _kWaDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // WhatsApp bubble-style compose area
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kWaLightBorder),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Type your WhatsApp message here...\n*bold* _italic_ ~strikethrough~',
                          mr: 'तुमचा व्हॉट्सॲप संदेश येथे लिहा...\n*ठळक* _तिरके_ ~खोडलेले~',
                          hi: 'अपना व्हाट्सएप संदेश यहाँ लिखें...\n*बोल्ड* _इटैलिक_ ~स्ट्राइकथ्रू~',
                        ),
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: '*bold* _italic_ ~strikethrough~ - WA Formatting',
                                  mr: '*ठळक* _तिरके_ ~खोडलेले~ - WA फॉरमॅटिंग',
                                  hi: '*बोल्ड* _इटैलिक_ ~स्ट्राइकथ्रू~ - WA फॉर्मेटिंग',
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: '$charCountStr characters',
                          mr: '$charCountStr अक्षरे',
                          hi: '$charCountStr अक्षर',
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kWaGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Filters
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Voter Filters & Search',
                          mr: 'मतदार फिल्टर आणि शोध',
                          hi: 'मतदाता फ़िल्टर और खोज',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          _nameController.clear();
                          _addressController.clear();
                          _houseNoController.clear();
                          _casteController.clear();
                          setState(() {
                            _ageFilter = 'All';
                            _genderFilter = 'All';
                            _boothFilter = 'All';
                          });
                          _loadVoters();
                        },
                        child: Text(
                          AppTranslations.pick(lang, en: 'Reset', mr: 'रीसेट करा', hi: 'रीसेट करें'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 1: Name & Address
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'Search name...',
                                mr: 'नाव शोधा...',
                                hi: 'नाम खोजें...',
                              ),
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _addressController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'Address / Area...',
                                mr: 'पत्ता / परिसर...',
                                hi: 'पता / क्षेत्र...',
                              ),
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 2: HouseNo & Caste (text)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _houseNoController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'House No...',
                                mr: 'घर क्र...',
                                hi: 'मकान नं...',
                              ),
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.home_outlined, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _casteController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'Community / Group...',
                                mr: 'समुदाय / गट...',
                                hi: 'समुदाय / वर्ग...',
                              ),
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.people_outline, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 3: Age, Gender, Booth dropdowns
                  Row(
                    children: [
                      // Age
                      Expanded(
                        child: _buildDropdownFilter(
                          title: AppTranslations.pick(
                            lang,
                            en: 'Filter by Age',
                            mr: 'वयानुसार निवडा',
                            hi: 'आयु के अनुसार चुनें',
                          ),
                          value: _ageFilter,
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(AppTranslations.pick(lang, en: 'All Ages', mr: 'सर्व वयोगट', hi: 'सभी आयु वर्ग')),
                            ),
                            DropdownMenuItem(
                              value: '18-25',
                              child: Text(AppTranslations.pick(lang, en: 'Age 18-25', mr: 'वय १८-२५', hi: 'आयु १८-२५')),
                            ),
                            DropdownMenuItem(
                              value: '26-40',
                              child: Text(AppTranslations.pick(lang, en: 'Age 26-40', mr: 'वय २६-४०', hi: 'आयु २६-४०')),
                            ),
                            DropdownMenuItem(
                              value: '41-60',
                              child: Text(AppTranslations.pick(lang, en: 'Age 41-60', mr: 'वय ४१-६०', hi: 'आयु ४१-६०')),
                            ),
                            DropdownMenuItem(
                              value: '60+',
                              child: Text(AppTranslations.pick(lang, en: 'Age 60+', mr: 'वय ६०+', hi: 'आयु ६०+')),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _ageFilter = v);
                              _loadVoters();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Gender
                      Expanded(
                        child: _buildDropdownFilter(
                          title: AppTranslations.pick(
                            lang,
                            en: 'Filter by Gender',
                            mr: 'लिंगानुसार निवडा',
                            hi: 'लिंग के अनुसार चुनें',
                          ),
                          value: _genderFilter,
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(AppTranslations.pick(lang, en: 'All Genders', mr: 'सर्व लिंग', hi: 'सभी लिंग')),
                            ),
                            DropdownMenuItem(
                              value: 'M',
                              child: Text(AppTranslations.pick(lang, en: 'Male', mr: 'पुरुष', hi: 'पुरुष')),
                            ),
                            DropdownMenuItem(
                              value: 'F',
                              child: Text(AppTranslations.pick(lang, en: 'Female', mr: 'महिला', hi: 'महिला')),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _genderFilter = v);
                              _loadVoters();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Booth
                      Expanded(
                        child: _buildDropdownFilter(
                          title: AppTranslations.pick(
                            lang,
                            en: 'Filter by Booth',
                            mr: 'बूथनुसार निवडा',
                            hi: 'बूथ के अनुसार चुनें',
                          ),
                          value: _boothFilter,
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(AppTranslations.pick(lang, en: 'All Booths', mr: 'सर्व बूथ', hi: 'सभी बूथ')),
                            ),
                            DropdownMenuItem(
                              value: '28',
                              child: Text(AppTranslations.pick(
                                lang,
                                en: 'Booth 28 (Shaniwar Peth)',
                                mr: 'बूथ २८ (शनिवार पेठ)',
                                hi: 'बूथ २८ (शनिवार पेठ)',
                              )),
                            ),
                            DropdownMenuItem(
                              value: '29',
                              child: Text(AppTranslations.pick(
                                lang,
                                en: 'Booth 29 (Kasba Peth)',
                                mr: 'बूथ २९ (कसबा पेठ)',
                                hi: 'बूथ २९ (कसबा पेठ)',
                              )),
                            ),
                            DropdownMenuItem(
                              value: '30',
                              child: Text(AppTranslations.pick(
                                lang,
                                en: 'Booth 30 (Raviwar Peth)',
                                mr: 'बूथ ३० (रविवार पेठ)',
                                hi: 'बूथ ३० (रविवार पेठ)',
                              )),
                            ),
                            DropdownMenuItem(
                              value: '31',
                              child: Text(AppTranslations.pick(
                                lang,
                                en: 'Booth 31 (Somwar Peth)',
                                mr: 'बूथ ३१ (सोमवार पेठ)',
                                hi: 'बूथ ३१ (सोमवार पेठ)',
                              )),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _boothFilter = v);
                              _loadVoters();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4. Selection Control Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: _handleSelectAllVisible,
                    child: Row(
                      children: [
                        Icon(
                          _isAllVisibleSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: _isAllVisibleSelected ? _kWaGreen : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Select All (Visible) ($totalVotersStr voters)',
                              mr: 'सर्व निवडा ($totalVotersStr मतदार)',
                              hi: 'सभी चुनें ($totalVotersStr मतदाता)',
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kWaLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kWaLightBorder),
                      ),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: '$selectedCountStr Selected',
                          mr: '$selectedCountStr निवडले',
                          hi: '$selectedCountStr चयनित',
                        ),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kWaDark),
                      ),
                    ),
                    if (_selectedVoterIds.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _clearSelection,
                        child: Text(
                          AppTranslations.pick(lang, en: 'Clear', mr: 'साफ करा', hi: 'हटाएं'),
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 5. Voter Cards
            if (_isLoadingVoters)
              const AppShimmerList(count: 6)
            else if (_voters.isEmpty)
              _buildEmptyVotersState(lang)
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _visibleVoters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final voter = _visibleVoters[idx];
                  final isSelected = _selectedVoterIds.contains(voter.id);
                  final ageStr = AppTranslations.formatDigits(voter.age, lang);

                  return InkWell(
                    onTap: () => _toggleSelectVoter(voter.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _kWaGreen : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox
                          Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelected ? _kWaGreen : const Color(0xFFCBD5E1),
                            size: 20,
                          ),
                          const SizedBox(width: 10),

                          // Voter info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppTranslatedText(
                                        voter.displayNameFor(lang),
                                        isName: true,
                                        targetLanguage: lang,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    // Mobile chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _kWaLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _kWaLightBorder),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone, size: 10, color: _kWaDark),
                                          const SizedBox(width: 3),
                                          Text(
                                            AppTranslations.formatDigits(voter.mobile ?? '-', lang),
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: _kWaDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: '${voter.genderLabel(lang)} · Age $ageStr',
                                        mr: '${voter.genderLabel(lang)} · वय $ageStr',
                                        hi: '${voter.genderLabel(lang)} · आयु $ageStr',
                                      ),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    if (voter.booth.isNotEmpty) ...[
                                      const Text(' · ', style: TextStyle(color: Color(0xFFCBD5E1))),
                                      Flexible(
                                        child: AppTranslatedText(
                                          voter.booth,
                                          targetLanguage: lang,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (voter.address.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  AppTranslatedText(
                                    voter.address,
                                    targetLanguage: lang,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 1-tap direct WA chat button
                          if (voter.mobile != null && voter.mobile!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () => _openDirectWhatsApp(voter),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: _kWaGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chat_rounded, size: 17, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppLoadMoreFooter(
                currentCount: _visibleVoters.length,
                totalCount: _voters.length,
                pageSize: 20,
                onLoadMore: () => setState(() => _voterLimit += 20),
                label: AppTranslations.pick(lang, en: 'voters', mr: 'मतदार', hi: 'मतदाता'),
                isMarathi: lang == 'mr',
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 2: History & Reports
  // ─────────────────────────────────────────────────────────────
  Widget _buildHistoryTab(String lang) {
    final histCountStr = AppTranslations.formatDigits(_broadcastHistory.length, lang);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadHistory,
            color: _kWaGreen,
            child: _isLoadingHistory
                ? const AppShimmerList(count: 6)
                : _broadcastHistory.isEmpty
                    ? _buildEmptyHistoryState(lang)
                    : CustomScrollView(
                        slivers: [
                          // Stats summary header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppTranslations.pick(
                                              lang,
                                              en: 'History & Reports',
                                              mr: 'इतिहास व अहवाल',
                                              hi: 'इतिहास और रिपोर्ट',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            AppTranslations.pick(
                                              lang,
                                              en: '$histCountStr WhatsApp broadcasts',
                                              mr: '$histCountStr व्हॉट्सॲप प्रसारण',
                                              hi: '$histCountStr व्हाट्सएप प्रसारण',
                                            ),
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                      AppPdfButton.outlined(
                                        label: AppTranslations.pick(lang, en: 'Reports', mr: 'अहवाल', hi: 'रिपोर्ट'),
                                        tooltip: AppTranslations.getDownloadReport(lang),
                                        onPressed: _generatePdfReport,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // KPI Summary Row
                                  _buildKpiSummary(lang),
                                ],
                              ),
                            ),
                          ),

                          // Broadcast cards
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, idx) {
                                  if (idx == _visibleHistory.length) {
                                    return AppLoadMoreFooter(
                                      currentCount: _visibleHistory.length,
                                      totalCount: _broadcastHistory.length,
                                      pageSize: 10,
                                      onLoadMore: () => setState(() => _historyLimit += 10),
                                      label: AppTranslations.pick(
                                        lang,
                                        en: 'records',
                                        mr: 'इतिहास नोंदी',
                                        hi: 'इतिहास रिकॉर्ड',
                                      ),
                                      isMarathi: lang == 'mr',
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildBroadcastHistoryCard(_visibleHistory[idx], lang),
                                  );
                                },
                                childCount: _visibleHistory.length + (_broadcastHistory.isNotEmpty ? 1 : 0),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiSummary(String lang) {
    final totalRecipients = _broadcastHistory.fold<int>(0, (s, b) => s + b.recipients);
    final totalDelivered = _broadcastHistory.fold<int>(0, (s, b) => s + b.deliveredCount);
    final rate = totalRecipients > 0 ? ((totalDelivered / totalRecipients) * 100).toStringAsFixed(1) : '98.5';

    return Row(
      children: [
        _buildKpiCard(
          AppTranslations.pick(lang, en: 'Broadcasts', mr: 'प्रसारण', hi: 'प्रसारण'),
          AppTranslations.formatDigits(_broadcastHistory.length, lang),
          Icons.campaign_rounded,
          _kWaDark,
        ),
        const SizedBox(width: 8),
        _buildKpiCard(
          AppTranslations.pick(lang, en: 'Voters', mr: 'मतदार', hi: 'मतदाता'),
          AppTranslations.formatDigits(totalRecipients, lang),
          Icons.people_rounded,
          const Color(0xFF0369A1),
        ),
        const SizedBox(width: 8),
        _buildKpiCard(
          AppTranslations.pick(lang, en: 'Delivered', mr: 'वितरित', hi: 'वितरित'),
          AppTranslations.formatDigits(totalDelivered, lang),
          Icons.check_circle_rounded,
          const Color(0xFF047857),
        ),
        const SizedBox(width: 8),
        _buildKpiCard(
          AppTranslations.pick(lang, en: 'Delivery Rate', mr: 'वितरण दर', hi: 'डिलीवरी दर'),
          AppTranslations.formatDigits('$rate%', lang),
          Icons.trending_up_rounded,
          _kWaGreen,
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizedBroadcastStatus(String status, String lang) {
    switch (status.trim().toUpperCase()) {
      case 'COMPLETED':
        return AppTranslations.pick(lang, en: 'COMPLETED', mr: 'पूर्ण', hi: 'पूर्ण');
      case 'SENDING':
        return AppTranslations.pick(lang, en: 'SENDING', mr: 'पाठवत आहे', hi: 'भेज रहा है');
      case 'QUEUED':
        return AppTranslations.pick(lang, en: 'QUEUED', mr: 'रांगेत', hi: 'कतार में');
      case 'FAILED':
        return AppTranslations.pick(lang, en: 'FAILED', mr: 'अयशस्वी', hi: 'विफल');
      default:
        return AppTranslations.getStatus(status, lang);
    }
  }

  Widget _buildBroadcastHistoryCard(WhatsAppBroadcastModel broadcast, String lang) {
    Color statusBg = _kWaLight;
    Color statusColor = _kWaDark;
    if (broadcast.isFailed) {
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFDC2626);
    } else if (broadcast.isSending) {
      statusBg = const Color(0xFFFFFBEB);
      statusColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WA icon
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: _kWaGreen, shape: BoxShape.circle),
                child: const Icon(Icons.chat_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTranslatedText(
                      broadcast.title,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          AppTranslations.formatDateTime(broadcast.sentAt, lang),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        if (broadcast.targetCriteria != null) ...[
                          const Text(' · ', style: TextStyle(color: Color(0xFFCBD5E1))),
                          Expanded(
                            child: AppTranslatedText(
                              broadcast.targetCriteria!,
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  _localizedBroadcastStatus(broadcast.status, lang),
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Message preview (WhatsApp bubble)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border.all(color: _kWaLightBorder),
            ),
            child: AppTranslatedText(
              broadcast.message,
              targetLanguage: lang,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 10),

          // Stats row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildMiniStat(
                AppTranslations.pick(lang, en: 'Recipients', mr: 'प्राप्तकर्ते', hi: 'प्राप्तकर्ता'),
                AppTranslations.formatDigits(broadcast.recipients, lang),
                const Color(0xFF0369A1),
              ),
              _buildMiniStat(
                AppTranslations.pick(lang, en: 'Sent', mr: 'पाठवले', hi: 'भेजा गया'),
                AppTranslations.formatDigits(broadcast.sentCount, lang),
                _kWaGreen,
              ),
              _buildMiniStat(
                AppTranslations.pick(lang, en: 'Delivered', mr: 'वितरित', hi: 'वितरित'),
                AppTranslations.formatDigits(broadcast.deliveredCount, lang),
                const Color(0xFF047857),
              ),
              _buildMiniStat(
                AppTranslations.pick(lang, en: 'Failed', mr: 'अयशस्वी', hi: 'विफल'),
                AppTranslations.formatDigits(broadcast.failedCount, lang),
                broadcast.failedCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
              ),
              if (broadcast.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kWaLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kWaLightBorder),
                  ),
                  child: AppTranslatedText(
                    broadcast.category!,
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _kWaDark),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Sticky Bottom Send Bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildStickySendBar(String lang) {
    final selectedStr = AppTranslations.formatDigits(_selectedVoterIds.length, lang);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: _kWaGreen.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: '$selectedStr voters selected',
                      mr: '$selectedStr मतदार निवडले',
                      hi: '$selectedStr मतदाता चयनित',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Dispatched via official WhatsApp',
                      mr: 'अधिकृत व्हॉट्सॲपद्वारे पाठवले जाईल',
                      hi: 'आधिकारिक व्हाट्सएप द्वारा भेजा जाएगा',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kWaGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: _isSending ? null : _showConfirmationDialog,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSending
                    ? AppTranslations.pick(lang, en: 'Sending...', mr: 'पाठवत आहे...', hi: 'भेज रहे हैं...')
                    : AppTranslations.pick(lang, en: 'Send WhatsApp', mr: 'व्हॉट्सॲप पाठवा', hi: 'व्हाट्सएप भेजें'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
  Widget _buildDropdownFilter({
    String? title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return AppDropdown<String>(
      title: title,
      value: value,
      height: 38,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyVotersState(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 44, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No voters found matching current filters.',
              mr: 'सध्याच्या फिल्टरनुसार कोणतेही मतदार आढळले नाहीत.',
              hi: 'वर्तमान फ़िल्टर से मेल खाने वाले कोई मतदाता नहीं मिले।',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Only voters with registered mobile numbers are displayed.',
              mr: 'फक्त नोंदणीकृत मोबाईल क्रमांक असलेले मतदारच येथे दिसतील.',
              hi: 'केवल पंजीकृत मोबाइल नंबर वाले मतदाता ही दिखाए जाते हैं।',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 52, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 10),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No WhatsApp broadcasts sent yet.',
                mr: 'अद्याप कोणतेही व्हॉट्सॲप प्रसारण पाठवलेले नाही.',
                hi: 'अभी तक कोई व्हाट्सएप प्रसारण नहीं भेजा गया है।',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.pick(
                lang,
                en: 'Switch to "Send WhatsApp" tab to dispatch your first broadcast!',
                mr: 'पहिले प्रसारण पाठवण्यासाठी "संदेश पाठवा" टॅबवर जा!',
                hi: 'अपना पहला प्रसारण भेजने के लिए "संदेश भेजें" टैब पर जाएं!',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

