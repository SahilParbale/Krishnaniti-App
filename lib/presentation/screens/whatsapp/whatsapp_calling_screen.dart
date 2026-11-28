import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../../data/repositories/whatsapp_repository.dart';
import 'whatsapp_history_report_generator.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_button.dart';

const _kWaGreen = Color(0xFF25D366);
const _kWaDark = Color(0xFF075E54);
const _kWaLight = Color(0xFFE8F5E9);

class WhatsAppCallingScreen extends ConsumerStatefulWidget {
  const WhatsAppCallingScreen({super.key});

  @override
  ConsumerState<WhatsAppCallingScreen> createState() => _WhatsAppCallingScreenState();
}

class _WhatsAppCallingScreenState extends ConsumerState<WhatsAppCallingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];

  bool _isLoadingHistory = false;
  List<WhatsAppBroadcastModel> _callLogs = [];
  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _callLogs.isEmpty) {
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
    _searchController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoadingVoters = true);
    final repo = ref.read(whatsAppRepoProvider);

    try {
      final list = await repo.getVotersWithMobile(
        name: AppTranslations.normalizeAsciiDigits(_searchController.text.trim()),
        address: AppTranslations.normalizeAsciiDigits(_addressController.text.trim()),
      );

      if (mounted) {
        setState(() {
          _voters = list;
          _isLoadingVoters = false;
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

      var query = client.from('message_logs').select('*').eq('channel', 'wa_call');
      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      }

      final response = await query.order('sent_at', ascending: false).limit(100);
      final list = (response as List<dynamic>)
          .map((item) => WhatsAppBroadcastModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _callLogs = list;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _callLogs = [];
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _initiateWhatsAppCall(VoterModel voter) async {
    final lang = ref.read(appLanguageProvider);
    final rawNumber = AppTranslations.normalizeAsciiDigits(voter.mobile ?? '')
        .replaceAll(RegExp(r'\D'), '');
    if (rawNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'No mobile number available for this voter',
              mr: 'या मतदाराचा मोबाईल क्रमांक उपलब्ध नाही',
              hi: 'इस मतदाता का मोबाइल नंबर उपलब्ध नहीं है',
            ),
          ),
        ),
      );
      return;
    }

    String phone = rawNumber;
    if (phone.length == 10) phone = '91$phone';

    // Direct WhatsApp dial link
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Log into message_logs with channel: wa_call
      final voterName = voter.displayName;
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;

      final newLog = WhatsAppBroadcastModel(
        id: 'wacall-${DateTime.now().millisecondsSinceEpoch}',
        title: 'WhatsApp Call - $voterName',
        message: 'WhatsApp Call initiated to $voterName (+$phone)',
        sentAt: DateTime.now(),
        channel: 'wa_call',
        recipients: 1,
        sentCount: 1,
        deliveredCount: 1,
        failedCount: 0,
        status: 'COMPLETED',
        category: 'WhatsApp Call',
      );

      try {
        await client.from('message_logs').insert({
          'tenant_id': tenantId,
          'channel': 'wa_call',
          'message': 'WhatsApp Call initiated to $voterName (+$phone)',
          'recipients': 1,
          'sent_count': 1,
          'failed_count': 0,
          'sent_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      setState(() {
        _callLogs.insert(0, newLog);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Could not open WhatsApp',
                mr: 'व्हॉट्सॲप उघडता आले नाही',
                hi: 'व्हाट्सएप खोला नहीं जा सका',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportPdfReport() async {
    final lang = ref.read(appLanguageProvider);
    if (_callLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'No call logs to export.',
              mr: 'निर्यात करण्यासाठी कॉल नोंदी नाहीत.',
              hi: 'निर्यात करने के लिए कोई कॉल लॉग नहीं है।',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      await WhatsAppHistoryReportGenerator.generateAndPrintReport(
        broadcasts: _callLogs,
        lang: lang,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Failed to generate PDF report.',
                mr: 'PDF अहवाल तयार करण्यात अयशस्वी.',
                hi: 'PDF रिपोर्ट बनाने में विफल।',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  void _showTutorialDialog() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: _kWaGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'WhatsApp Call Guide',
                  mr: 'व्हॉट्सॲप कॉल मार्गदर्शिका',
                  hi: 'व्हाट्सएप कॉल गाइड',
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  en: 'Select Recipient',
                  mr: 'संपर्क निवडा',
                  hi: 'संपर्क चुनें',
                ),
                desc: AppTranslations.pick(
                  lang,
                  en: 'Browse or search voter directory by name, mobile, or address to connect.',
                  mr: 'संपर्क साधण्यासाठी नाव, मोबाईल किंवा पत्त्यानुसार मतदार यादी शोधा.',
                  hi: 'संपर्क करने के लिए नाम, मोबाइल या पते से मतदाता सूची खोजें।',
                ),
              ),
              _buildTutorialStep(
                step: AppTranslations.formatDigits('2', lang),
                title: AppTranslations.pick(
                  lang,
                  en: 'Voter Search & Filters',
                  mr: 'मतदार शोध व फिल्टर',
                  hi: 'मतदाता खोज एवं फ़िल्टर',
                ),
                desc: AppTranslations.pick(
                  lang,
                  en: 'Search specific voters by name, mobile number, or address.',
                  mr: 'नाव, मोबाईल क्रमांक किंवा पत्त्यानुसार विशिष्ट मतदार शोधा.',
                  hi: 'नाम, मोबाइल नंबर या पते से विशिष्ट मतदाताओं को खोजें।',
                ),
              ),
              _buildTutorialStep(
                step: AppTranslations.formatDigits('3', lang),
                title: AppTranslations.pick(
                  lang,
                  en: '1-Tap Direct WhatsApp Call',
                  mr: '१-टॅप थेट व्हॉट्सॲप कॉल',
                  hi: '१-टैप सीधा व्हाट्सएप कॉल',
                ),
                desc: AppTranslations.pick(
                  lang,
                  en: 'Tap "WA Call" on each voter card to launch the WhatsApp dialer and initiate the call.',
                  mr: 'कॉल सुरू करण्यासाठी मतदार कार्डवरील "WA कॉल" बटणावर टॅप करा.',
                  hi: 'कॉल शुरू करने के लिए मतदाता कार्ड पर "WA कॉल" बटन पर टैप करें।',
                ),
              ),
              _buildTutorialStep(
                step: AppTranslations.formatDigits('4', lang),
                title: AppTranslations.pick(
                  lang,
                  en: 'Call Logs & Reports',
                  mr: 'कॉल नोंदी व अहवाल',
                  hi: 'कॉल लॉग एवं रिपोर्ट',
                ),
                desc: AppTranslations.pick(
                  lang,
                  en: 'All placed calls are recorded with timestamps in the Call History tab. Download official A4 PDF reports in 1-tap.',
                  mr: 'सर्व कॉल्सच्या नोंदी वेळेसह कॉल इतिहास टॅबमध्ये जतन केल्या जातात. १-टॅपमध्ये अधिकृत A4 PDF अहवाल डाउनलोड करा.',
                  hi: 'किए गए सभी कॉल समय के साथ कॉल इतिहास टैब में दर्ज होते हैं। १-टैप में आधिकारिक A4 PDF रिपोर्ट डाउनलोड करें।',
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
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _kWaGreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
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
                en: 'WhatsApp Call',
                mr: 'व्हॉट्सॲप कॉल',
                hi: 'व्हाट्सएप कॉल',
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
                en: 'Direct WhatsApp voice calling',
                mr: 'थेट व्हॉट्सॲप व्हॉइस कॉलिंग',
                hi: 'सीधी व्हाट्सएप वॉयस कॉलिंग',
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
            onPressed: _showTutorialDialog,
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
                              const Icon(Icons.phone, size: 14),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Make Call',
                                    mr: 'कॉल करा',
                                    hi: 'कॉल करें',
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
                              const Icon(Icons.history, size: 14),
                              const SizedBox(width: 5),
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
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCallingTab(theme, isDark, lang),
                _buildHistoryTab(theme, isDark, lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallingTab(ThemeData theme, bool isDark, String lang) {
    final contactsCountStr = AppTranslations.formatDigits(_voters.length, lang);

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Search name or mobile number...',
                          mr: 'नाव किंवा मोबाईल क्रमांक शोधा...',
                          hi: 'नाम या मोबाइल नंबर खोजें...',
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: (_) => _loadVoters(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _loadVoters,
                    icon: const Icon(Icons.filter_alt, size: 20),
                    tooltip: AppTranslations.pick(
                      lang,
                      en: 'Apply Filters',
                      mr: 'फिल्टर लागू करा',
                      hi: 'फ़िल्टर लागू करें',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: AppTranslations.pick(
                    lang,
                    en: 'Filter address / area...',
                    mr: 'पत्ता / परिसरानुसार शोधा...',
                    hi: 'पता / क्षेत्र फ़िल्टर करें...',
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (_) => _loadVoters(),
              ),
            ],
          ),
        ),

        // Count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Available Contacts: $contactsCountStr',
                  mr: 'उपलब्ध संपर्क: $contactsCountStr',
                  hi: 'उपलब्ध संपर्क: $contactsCountStr',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              if (_isLoadingVoters)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kWaGreen),
                ),
            ],
          ),
        ),

        // Voter list / grid
        Expanded(
          child: _isLoadingVoters && _voters.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kWaGreen))
              : _voters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_disabled_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'No voters with valid mobile numbers found',
                              mr: 'वैध मोबाईल क्रमांक असलेले मतदार आढळले नाहीत',
                              hi: 'मान्य मोबाइल नंबर वाले कोई मतदाता नहीं मिले',
                            ),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVoters,
                      color: _kWaGreen,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _voters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final voter = _voters[index];
                          final hasPhone = (voter.mobile != null && voter.mobile!.isNotEmpty);

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFE0F2FE),
                                    foregroundColor: Color(0xFF0284C7),
                                    child: Icon(Icons.person),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppTranslatedText(
                                          voter.displayNameFor(lang),
                                          isName: true,
                                          targetLanguage: lang,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 13, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 4),
                                            Text(
                                              hasPhone
                                                  ? AppTranslations.formatDigits(voter.mobile!, lang)
                                                  : AppTranslations.pick(
                                                      lang,
                                                      en: 'No mobile',
                                                      mr: 'मोबाईल नाही',
                                                      hi: 'मोबाइल नहीं',
                                                    ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: hasPhone ? const Color(0xFF0284C7) : Colors.grey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (voter.address.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          AppTranslatedText(
                                            voter.address,
                                            targetLanguage: lang,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: hasPhone ? () => _initiateWhatsAppCall(voter) : null,
                                    icon: const Icon(Icons.phone_in_talk, size: 16),
                                    label: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'WA Call',
                                        mr: 'WA कॉल',
                                        hi: 'WA कॉल',
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kWaGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
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

  Widget _buildHistoryTab(ThemeData theme, bool isDark, String lang) {
    if (_isLoadingHistory && _callLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kWaGreen));
    }

    final logsCountStr = AppTranslations.formatDigits(_callLogs.length, lang);

    return Column(
      children: [
        // History sub-header with count and PDF action button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: '$logsCountStr WhatsApp Calls',
                  mr: '$logsCountStr व्हॉट्सॲप कॉल्स',
                  hi: '$logsCountStr व्हाट्सएप कॉल्स',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Row(
                children: [
                  AppPdfButton.outlined(
                    label: AppTranslations.pick(lang, en: 'Reports', mr: 'अहवाल', hi: 'रिपोर्ट'),
                    tooltip: AppTranslations.getDownloadReport(lang),
                    isLoading: _isExportingPdf,
                    onPressed: _exportPdfReport,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),

        // Logs list or Empty state
        Expanded(
          child: _callLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'No WhatsApp call logs yet',
                          mr: 'अद्याप कोणतेही व्हॉट्सॲप कॉल लॉग नाहीत',
                          hi: 'अभी तक कोई व्हाट्सएप कॉल लॉग नहीं है',
                        ),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: _kWaGreen,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _callLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _callLogs[index];
                      final dateStr = AppTranslations.formatDateTime(item.sentAt, lang);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                backgroundColor: _kWaLight,
                                child: Icon(Icons.phone_in_talk, color: _kWaGreen, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
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
                                            color: _kWaLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            AppTranslations.pick(
                                              lang,
                                              en: 'WHATSAPP CALL',
                                              mr: 'व्हॉट्सॲप कॉल',
                                              hi: 'व्हाट्सएप कॉल',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _kWaDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    AppTranslatedText(
                                      item.message.isNotEmpty ? item.message : item.title,
                                      targetLanguage: lang,
                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                    ),
                                  ],
                                ),
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
