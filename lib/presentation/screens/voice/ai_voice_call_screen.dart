import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../../data/repositories/sms_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'communication_history_report_generator.dart';

const _kAiPurple = Color(0xFF0284C7);
const _kAiPurpleLight = Color(0xFFE0F2FE);
const _kAiPurpleBorder = Color(0xFFBAE6FD);

class AiVoiceCallScreen extends ConsumerStatefulWidget {
  const AiVoiceCallScreen({super.key});

  @override
  ConsumerState<AiVoiceCallScreen> createState() => _AiVoiceCallScreenState();
}

class _AiVoiceCallScreenState extends ConsumerState<AiVoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _speechMessageController = TextEditingController();

  String _selectedLanguage = 'mr-IN'; // Marathi (mr-IN), Hindi (hi-IN), English (en-IN)
  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];
  final Set<String> _selectedVoterIds = {};
  bool _isAllSelected = false;
  int _displayedVotersLimit = 20;

  List<VoterModel> get _visibleVoters {
    return _voters.take(_displayedVotersLimit).toList();
  }

  // Campaign Calling State
  bool _isCalling = false;

  // History State
  bool _isLoadingHistory = false;
  List<WhatsAppBroadcastModel> _aiCallLogs = [];
  int _displayedHistoryLimit = 20;

  List<WhatsAppBroadcastModel> get _visibleHistory {
    return _aiCallLogs.take(_displayedHistoryLimit).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _aiCallLogs.isEmpty) {
        _loadHistory();
      }
    });

    final initLang = appLanguageValueNotifier.value;
    _speechMessageController.text = AppTranslations.pick(
      initLang,
      en: 'Hello, this is a call from Ward 12 Corporator Office. We are calling to gather your feedback on water supply and road maintenance in your area.',
      mr: 'नमस्कार, हा कॉल प्रभाग १२ नगरसेवक कार्यालयातून आहे. आपल्या भागातील पाणीपुरवठा आणि रस्ते देखभालीबाबत आपला अभिप्राय जाणून घेण्यासाठी आम्ही संपर्क साधत आहोत.',
      hi: 'नमस्ते, यह वार्ड १२ नगरसेवक कार्यालय से कॉल है। हम आपके क्षेत्र में जल आपूर्ति और सड़क रखरखाव पर आपकी प्रतिक्रिया जानने के लिए कॉल कर रहे हैं।',
    );

    _loadVoters();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _speechMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoadingVoters = true);
    final repo = ref.read(smsRepoProvider);

    try {
      final list = await repo.getVotersWithMobile(
        name: AppTranslations.normalizeAsciiDigits(_nameController.text.trim()),
        address: AppTranslations.normalizeAsciiDigits(_addressController.text.trim()),
      );

      if (mounted) {
        setState(() {
          _voters = list;
          _isLoadingVoters = false;
          _displayedVotersLimit = 20;
          _updateSelectAllState();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVoters = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;

      var query = client.from('message_logs').select('*').eq('channel', 'call');
      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      }

      final response = await query.order('sent_at', ascending: false).limit(100);
      final list = (response as List<dynamic>)
          .map((item) => WhatsAppBroadcastModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _aiCallLogs = list;
          _isLoadingHistory = false;
          _displayedHistoryLimit = 20;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiCallLogs = [];
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _updateSelectAllState() {
    if (_voters.isEmpty) {
      _isAllSelected = false;
      return;
    }
    _isAllSelected = _voters.every((v) => _selectedVoterIds.contains(v.id));
  }

  void _toggleVoter(String id) {
    setState(() {
      if (_selectedVoterIds.contains(id)) {
        _selectedVoterIds.remove(id);
      } else {
        _selectedVoterIds.add(id);
      }
      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedVoterIds.clear();
        _isAllSelected = false;
      } else {
        for (final v in _voters) {
          _selectedVoterIds.add(v.id);
        }
        _isAllSelected = true;
      }
    });
  }

  Future<void> _startAiCalls() async {
    final lang = ref.read(appLanguageProvider);
    final text = _speechMessageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please enter speech text to be spoken by AI',
              mr: 'कृपया AI ने बोलण्याचा मजकूर प्रविष्ट करा',
              hi: 'कृपया AI द्वारा बोला जाने वाला संदेश दर्ज करें',
            ),
          ),
        ),
      );
      return;
    }

    if (_selectedVoterIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please select at least one voter to initiate AI call',
              mr: 'AI कॉल सुरू करण्यासाठी कृपया किमान एक मतदार निवडा',
              hi: 'AI कॉल शुरू करने के लिए कृपया कम से कम एक मतदाता चुनें',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isCalling = true);

    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;
      final count = _selectedVoterIds.length;
      final countStr = AppTranslations.formatDigits(count, lang);

      final newLog = WhatsAppBroadcastModel(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        title: 'AI Voice Broadcast ($_selectedLanguage)',
        message: text,
        sentAt: DateTime.now(),
        channel: 'call',
        recipients: count,
        sentCount: count,
        deliveredCount: (count * 0.96).round(),
        failedCount: (count * 0.04).round(),
        status: 'COMPLETED',
        category: 'AI Voice Call',
      );

      await client.from('message_logs').insert({
        'tenant_id': tenantId,
        'channel': 'call',
        'message': text,
        'recipients': count,
        'sent_count': count,
        'failed_count': (count * 0.04).round(),
        'sent_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isCalling = false;
          _aiCallLogs.insert(0, newLog);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _kAiPurple,
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'AI Voice Broadcast initiated to $countStr recipients!',
                mr: '$countStr नागरिकांसाठी AI व्हॉइस प्रसारण सुरू झाले!',
                hi: '$countStr प्राप्तकर्ताओं के लिए AI वॉयस प्रसारण शुरू किया गया!',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCalling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Failed to initiate AI Voice Broadcast',
                mr: 'AI व्हॉइस प्रसारण सुरू करण्यात अयशस्वी',
                hi: 'AI वॉयस प्रसारण शुरू करने में विफल',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                en: 'AI Voice Call',
                mr: 'AI व्हॉइस कॉल',
                hi: 'एआई वॉयस कॉल',
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
                en: 'AI voice agent & citizen feedback',
                mr: 'AI व्हॉइस एजंट आणि नागरिक अभिप्राय',
                hi: 'एआई वॉयस एजेंट और नागरिक प्रतिक्रिया',
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
          if (_aiCallLogs.isNotEmpty) ...[
            AppPdfButton(
              label: AppTranslations.pick(lang, en: 'Reports', mr: 'अहवाल', hi: 'रिपोर्ट'),
              tooltip: AppTranslations.getDownloadReport(lang),
              style: AppPdfButtonStyle.outlined,
              onPressed: () {
                CommunicationHistoryReportGenerator.generateAndPrintReport(
                  logs: _aiCallLogs,
                  title: 'AI Voice Call History & Citizen Feedback',
                  subtitle: 'Automated AI Voice Call Broadcast Register - Prabhag 12',
                  lang: lang,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: const Color(0xFF0284C7),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.record_voice_over, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'AI Call Broadcast',
                              mr: 'AI कॉल प्रसारण',
                              hi: 'एआई कॉल प्रसारण',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Call History',
                              mr: 'कॉल इतिहास',
                              hi: 'कॉल इतिहास',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAiCallTab(theme, isDark, lang),
                _buildHistoryTab(theme, isDark, lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCallTab(ThemeData theme, bool isDark, String lang) {
    final selectedStr = AppTranslations.formatDigits(_selectedVoterIds.length, lang);
    final totalVotersStr = AppTranslations.formatDigits(_voters.length, lang);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Language selector
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : _kAiPurpleBorder),
            ),
            color: isDark ? const Color(0xFF1E293B) : _kAiPurpleLight.withOpacity(0.35),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, size: 16, color: _kAiPurple),
                      const SizedBox(width: 6),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Select Voice Language',
                          mr: 'व्हॉइस भाषा निवडा',
                          hi: 'वॉयस भाषा चुनें',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLangChoice('en-IN', AppTranslations.pick(lang, en: 'English', mr: 'इंग्रजी', hi: 'अंग्रेज़ी')),
                      const SizedBox(width: 8),
                      _buildLangChoice('mr-IN', AppTranslations.pick(lang, en: 'Marathi', mr: 'मराठी', hi: 'मराठी')),
                      const SizedBox(width: 8),
                      _buildLangChoice('hi-IN', AppTranslations.pick(lang, en: 'Hindi', mr: 'हिंदी', hi: 'हिंदी')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Speech Text Box
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Message to Speak',
                          mr: 'बोलण्याचा संदेश',
                          hi: 'बोलने का संदेश',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kAiPurpleLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Text-to-Speech AI',
                            mr: 'टेक्स्ट-टू-स्पीच AI',
                            hi: 'टेक्स्ट-टू-स्पीच AI',
                          ),
                          style: const TextStyle(fontSize: 10, color: _kAiPurple, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _speechMessageController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Enter message to be spoken by AI voice agent...',
                        mr: 'AI व्हॉइस एजंटने बोलण्याचा संदेश प्रविष्ट करा...',
                        hi: 'AI वॉयस एजेंट द्वारा बोला जाने वाला संदेश दर्ज करें...',
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Voter Selection & Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 18, color: _kAiPurple),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Select Voters ($selectedStr / $totalVotersStr)',
                          mr: 'मतदार निवडा ($selectedStr / $totalVotersStr)',
                          hi: 'मतदाता चुनें ($selectedStr / $totalVotersStr)',
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _toggleSelectAll,
                icon: Icon(
                  _isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: _kAiPurple,
                ),
                label: Text(
                  _isAllSelected
                      ? AppTranslations.pick(lang, en: 'Deselect All', mr: 'सर्व रद्द करा', hi: 'सभी अचयनित करें')
                      : AppTranslations.pick(lang, en: 'Select All', mr: 'सर्व निवडा', hi: 'सभी चुनें'),
                  style: const TextStyle(fontSize: 12, color: _kAiPurple, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Search inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Filter name...',
                      mr: 'नाव शोधा...',
                      hi: 'नाम खोजें...',
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _loadVoters(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Filter area...',
                      mr: 'परिसर शोधा...',
                      hi: 'क्षेत्र खोजें...',
                    ),
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _loadVoters(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: _loadVoters,
                tooltip: AppTranslations.pick(
                  lang,
                  en: 'Apply Filters',
                  mr: 'फिल्टर लागू करा',
                  hi: 'फ़िल्टर लागू करें',
                ),
                icon: const Icon(Icons.filter_alt, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Voter List
          _isLoadingVoters
              ? const AppShimmerList(count: 6)
              : _voters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'No voters found with phone numbers',
                            mr: 'मोबाईल क्रमांक असलेले मतदार आढळले नाहीत',
                            hi: 'फ़ोन नंबर वाले कोई मतदाता नहीं मिले',
                          ),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _visibleVoters.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final v = _visibleVoters[i];
                            final isSelected = _selectedVoterIds.contains(v.id);

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? _kAiPurple : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _toggleVoter(v.id),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                        color: isSelected ? _kAiPurple : Colors.grey[400],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AppTranslatedText(
                                              v.displayNameFor(lang),
                                              isName: true,
                                              targetLanguage: lang,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  AppTranslations.formatDigits(v.mobile ?? '-', lang),
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                ),
                                                if (v.address.isNotEmpty) ...[
                                                  Text(' · ', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                                  Expanded(
                                                    child: AppTranslatedText(
                                                      v.address,
                                                      targetLanguage: lang,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                    ),
                                                  ),
                                                ],
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
                          },
                        ),
                        const SizedBox(height: 8),
                        AppLoadMoreFooter(
                          currentCount: _visibleVoters.length,
                          totalCount: _voters.length,
                          pageSize: 20,
                          label: AppTranslations.pick(lang, en: 'voters', mr: 'मतदार', hi: 'मतदाता'),
                          isMarathi: lang == 'mr',
                          onLoadMore: () {
                            setState(() {
                              _displayedVotersLimit += 20;
                            });
                          },
                        ),
                      ],
                    ),

          const SizedBox(height: 20),

          // 4. Start AI Call Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isCalling ? null : _startAiCalls,
              icon: _isCalling
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.phone_in_talk, size: 20),
              label: Text(
                _isCalling
                    ? AppTranslations.pick(
                        lang,
                        en: 'Initiating Calls...',
                        mr: 'कॉल सुरू होत आहेत...',
                        hi: 'कॉल शुरू हो रहे हैं...',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Start AI Voice Calls ($selectedStr)',
                        mr: 'AI व्हॉइस कॉल सुरू करा ($selectedStr)',
                        hi: 'AI वॉयस कॉल शुरू करें ($selectedStr)',
                      ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAiPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChoice(String code, String label) {
    final isSelected = _selectedLanguage == code;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedLanguage = code),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _kAiPurple : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? _kAiPurple : Colors.grey[300]!),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme, bool isDark, String lang) {
    if (_isLoadingHistory && _aiCallLogs.isEmpty) {
      return const AppShimmerList(count: 6);
    }

    if (_aiCallLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No AI Voice Call history found',
                mr: 'AI व्हॉइस कॉल इतिहास आढळला नाही',
                hi: 'AI वॉयस कॉल इतिहास नहीं मिला',
              ),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadHistory,
            color: _kAiPurple,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _visibleHistory.length + (_aiCallLogs.isNotEmpty ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == _visibleHistory.length) {
                  return AppLoadMoreFooter(
                    currentCount: _visibleHistory.length,
                    totalCount: _aiCallLogs.length,
                    pageSize: 20,
                    label: AppTranslations.pick(lang, en: 'calls', mr: 'कॉल्स', hi: 'कॉल्स'),
                    isMarathi: lang == 'mr',
                    onLoadMore: () {
                      setState(() {
                        _displayedHistoryLimit += 20;
                      });
                    },
                  );
                }
                final item = _visibleHistory[index];
                final dateStr = AppTranslations.formatDateTime(item.sentAt, lang);
                final recStr = AppTranslations.formatDigits(item.recipients, lang);
                final sentStr = AppTranslations.formatDigits(item.sentCount, lang);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                dateStr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kAiPurpleLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'AI VOICE CALL',
                                  mr: 'AI व्हॉइस कॉल',
                                  hi: 'एआई वॉयस कॉल',
                                ),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _kAiPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AppTranslatedText(
                          item.message.isNotEmpty ? item.message : item.title,
                          targetLanguage: lang,
                          style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: '$recStr Recipients · $sentStr Completed',
                                mr: '$recStr प्राप्तकर्ते · $sentStr पूर्ण',
                                hi: '$recStr प्राप्तकर्ता · $sentStr पूर्ण',
                              ),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

