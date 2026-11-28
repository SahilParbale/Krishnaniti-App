import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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

class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];
  int _displayedVotersLimit = 20;

  List<VoterModel> get _visibleVoters => _voters.take(_displayedVotersLimit).toList();

  // History state
  bool _isLoadingHistory = false;
  List<WhatsAppBroadcastModel> _callHistory = [];
  int _displayedHistoryLimit = 20;

  List<WhatsAppBroadcastModel> get _visibleHistory => _callHistory.take(_displayedHistoryLimit).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _callHistory.isEmpty) {
        _loadHistory();
      }
    });

    _loadVoters();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
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
          _callHistory = list;
          _isLoadingHistory = false;
          _displayedHistoryLimit = 20;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _callHistory = [];
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _makeCall(VoterModel voter) async {
    final lang = ref.read(appLanguageProvider);
    final phone = AppTranslations.normalizeAsciiDigits(voter.mobile ?? '')
        .replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) {
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

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);

      // Log manual call into message_logs (channel: call) matching web
      final voterName = voter.nameMarathi.isNotEmpty ? voter.nameMarathi : voter.nameEnglish;
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;

      final newLog = WhatsAppBroadcastModel(
        id: 'call-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Manual Voice Call - $voterName',
        message: 'Direct phone call placed to $voterName ($phone)',
        sentAt: DateTime.now(),
        channel: 'call',
        recipients: 1,
        sentCount: 1,
        deliveredCount: 1,
        failedCount: 0,
        status: 'COMPLETED',
      );

      try {
        await client.from('message_logs').insert({
          'tenant_id': tenantId,
          'channel': 'call',
          'message': 'Direct phone call placed to $voterName ($phone)',
          'recipients': 1,
          'sent_count': 1,
          'failed_count': 0,
          'sent_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      setState(() {
        _callHistory.insert(0, newLog);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Could not open dialer',
                mr: 'डायलर उघडता आला नाही',
                hi: 'डायलर खोला नहीं जा सका',
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
                en: 'Voice Call',
                mr: 'व्हॉइस कॉल',
                hi: 'वॉयस कॉल',
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
                en: 'Audio broadcasts in your voice',
                mr: 'आपल्या आवाजात ऑडिओ प्रसारण व थेट कॉल',
                hi: 'आपकी आवाज़ में ऑडियो प्रसारण व सीधी कॉल',
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
          if (_callHistory.isNotEmpty) ...[
            AppPdfButton(
              label: AppTranslations.pick(lang, en: 'Reports', mr: 'अहवाल', hi: 'रिपोर्ट'),
              tooltip: AppTranslations.getDownloadReport(lang),
              style: AppPdfButtonStyle.outlined,
              onPressed: () {
                CommunicationHistoryReportGenerator.generateAndPrintReport(
                  logs: _callHistory,
                  title: 'Public Voice Call History & Broadcast Report',
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
                        const Icon(Icons.phone, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Voice Call',
                              mr: 'व्हॉइस कॉल',
                              hi: 'वॉयस कॉल',
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
                _buildCallTab(theme, isDark, lang),
                _buildHistoryTab(theme, isDark, lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallTab(ThemeData theme, bool isDark, String lang) {
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
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Search voter by name...',
                          mr: 'मतदाराचे नाव शोधा...',
                          hi: 'मतदाता का नाम खोजें...',
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
                    en: 'Filter by address / area...',
                    mr: 'पत्ता / परिसरानुसार शोधा...',
                    hi: 'पता / क्षेत्र से फ़िल्टर करें...',
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

        // Voter count info
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),

        // Voter List
        Expanded(
          child: _isLoadingVoters && _voters.isEmpty
              ? const AppShimmerList(count: 6)
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
                              en: 'No voters with valid phone numbers found',
                              mr: 'वैध मोबाईल क्रमांक असलेले मतदार आढळले नाहीत',
                              hi: 'मान्य फ़ोन नंबर वाले कोई मतदाता नहीं मिले',
                            ),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVoters,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _visibleVoters.length + (_voters.isNotEmpty ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == _visibleVoters.length) {
                            return AppLoadMoreFooter(
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
                            );
                          }
                          final voter = _visibleVoters[index];
                          final hasPhone = (voter.mobile != null && voter.mobile!.isNotEmpty);
                          final hasName = voter.nameMarathi.isNotEmpty || voter.nameEnglish.isNotEmpty;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                                    child: const Icon(Icons.person),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (hasName)
                                          AppTranslatedText(
                                            voter.displayNameFor(lang),
                                            isName: true,
                                            targetLanguage: lang,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          )
                                        else
                                          Text(
                                            AppTranslations.pick(
                                              lang,
                                              en: 'Unnamed Voter',
                                              mr: 'निनावी मतदार',
                                              hi: 'अनाम मतदाता',
                                            ),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.call, size: 14, color: Colors.grey[600]),
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
                                                color: hasPhone ? Colors.green[700] : Colors.grey,
                                                fontWeight: FontWeight.w500,
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
                                    onPressed: hasPhone ? () => _makeCall(voter) : null,
                                    icon: const Icon(Icons.phone, size: 16),
                                    label: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Call',
                                        mr: 'कॉल करा',
                                        hi: 'कॉल करें',
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    if (_isLoadingHistory && _callHistory.isEmpty) {
      return const AppShimmerList(count: 6);
    }

    if (_callHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No voice call history found',
                mr: 'व्हॉइस कॉल इतिहास आढळला नाही',
                hi: 'वॉयस कॉल इतिहास नहीं मिला',
              ),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _visibleHistory.length + (_callHistory.isNotEmpty ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == _visibleHistory.length) {
                  return AppLoadMoreFooter(
                    currentCount: _visibleHistory.length,
                    totalCount: _callHistory.length,
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
                        CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.15),
                          child: const Icon(Icons.phone_forwarded, color: Colors.green, size: 20),
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
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'VOICE CALL',
                                        mr: 'व्हॉइस कॉल',
                                        hi: 'वॉयस कॉल',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
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
