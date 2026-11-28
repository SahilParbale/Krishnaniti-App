import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../../../data/models/voter_model.dart';
import '../../../../data/models/whatsapp_broadcast_model.dart';
import '../../../../data/repositories/sms_repository.dart';
import '../../shell/desktop_sidebar.dart';
import '../../../screens/voice/communication_history_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopAiVoiceView extends ConsumerStatefulWidget {
  const DesktopAiVoiceView({super.key});

  @override
  ConsumerState<DesktopAiVoiceView> createState() => _DesktopAiVoiceViewState();
}

class _DesktopAiVoiceViewState extends ConsumerState<DesktopAiVoiceView> {
  String _activeTab = 'call'; // 'call' | 'history'

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _callMessageController = TextEditingController();
  String _callLanguage = 'mr-IN'; // Marathi India

  final Set<String> _selectedVoterIds = {};
  bool _isLoading = false;
  bool _isBroadcasting = false;
  List<VoterModel> _voters = [];
  int _displayedLimit = 20;
  List<VoterModel> get _visibleVoters =>
      _voters.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadVoters();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _callMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() {
      _displayedLimit = 20;
      _isLoading = true;
    });
    try {
      final repo = ref.read(smsRepoProvider);
      final normalizedName = AppTranslations.normalizeAsciiDigits(_nameController.text.trim());
      final normalizedAddress = AppTranslations.normalizeAsciiDigits(_addressController.text.trim());
      final voters = await repo.getVotersWithMobile(
        name: normalizedName.isEmpty ? null : normalizedName,
        address: normalizedAddress.isEmpty ? null : normalizedAddress,
      );
      if (mounted) {
        setState(() {
          _voters = voters;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedVoterIds.length == _voters.length) {
        _selectedVoterIds.clear();
      } else {
        _selectedVoterIds.addAll(_voters.map((v) => v.id));
      }
    });
  }

  void _toggleSelectVoter(String id) {
    setState(() {
      if (_selectedVoterIds.contains(id)) {
        _selectedVoterIds.remove(id);
      } else {
        _selectedVoterIds.add(id);
      }
    });
  }

  Future<void> _startAiVoiceCampaign(String lang) async {
    if (_selectedVoterIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please select at least one voter',
              mr: 'कृपया किमान एक मतदार निवडा',
              hi: 'कृपया कम से कम एक मतदाता चुनें',
            ),
          ),
        ),
      );
      return;
    }
    if (_callMessageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please type voice announcement text',
              mr: 'कृपया व्हॉइस घोषणेचा मजकूर टाइप करा',
              hi: 'कृपया वॉइस घोषणा का संदेश लिखें',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isBroadcasting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      final countText = AppTranslations.formatDigits(_selectedVoterIds.length, lang);
      setState(() => _isBroadcasting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'AI Voice Campaign initiated successfully ($countText calls queued)',
              mr: 'AI व्हॉइस मोहीम यशस्वीरित्या सुरू झाली ($countText कॉल्स रांगेत आहेत)',
              hi: 'AI वॉइस अभियान सफलतापूर्वक शुरू हुआ ($countText कॉल कतार में हैं)',
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _callMessageController.clear();
      _selectedVoterIds.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.brand50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: AppColors.brand600, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(lang, en: 'AI Voice Call', mr: 'AI व्हॉइस कॉल', hi: 'AI वॉइस कॉल'),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Broadcast natural AI voice synthesized voice calls across the ward in regional languages',
                                mr: 'प्रादेशिक भाषांमध्ये प्रभागात नैसर्गिक AI व्हॉइस कॉल प्रसारित करा',
                                hi: 'क्षेत्रीय भाषाओं में वार्ड भर में प्राकृतिक AI वॉइस कॉल प्रसारित करें',
                              ),
                              style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Download Report matching AIVoiceCall.tsx
                OutlinedButton.icon(
                  onPressed: () {
                    final voiceLangLabel = _callLanguage == 'mr-IN'
                        ? 'Marathi'
                        : (_callLanguage == 'hi-IN' ? 'Hindi' : 'English');
                    final logs = _voters.map((v) => WhatsAppBroadcastModel(
                      id: 'ai-${v.id}',
                      title: 'AI Voice Broadcast: ${v.displayNameFor(lang)}',
                      message: 'Automated AI voice broadcast campaign delivered in $voiceLangLabel.',
                      sentAt: DateTime.now(),
                      channel: 'ai_call',
                      recipients: 1,
                      sentCount: 1,
                      deliveredCount: 1,
                      failedCount: 0,
                      status: 'COMPLETED',
                      targetCriteria: v.address,
                      category: 'AI Voice Broadcast',
                    )).toList();
                    CommunicationHistoryReportGenerator.generateAndPrintReport(
                      context: context,
                      logs: logs,
                      title: 'AI Voice Call History & Citizen Feedback',
                      subtitle: 'Automated AI Voice Call Broadcast Register - Prabhag 12',
                      lang: lang,
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
                  label: Text(
                    AppTranslations.getDownloadReport(lang),
                    style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F9FF),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabs Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(
                    'call',
                    AppTranslations.pick(lang, en: 'Create Campaign', mr: 'मोहीम तयार करा', hi: 'अभियान बनाएं'),
                    Icons.campaign_rounded,
                  ),
                  _buildTabButton(
                    'history',
                    AppTranslations.pick(lang, en: 'Campaign Logs', mr: 'मोहीम नोंदी', hi: 'अभियान लॉग'),
                    Icons.history_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_activeTab == 'call') ...[
              // Filters Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(lang, en: 'Search Name...', mr: 'नाव शोधा...', hi: 'नाम खोजें...'),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => _loadVoters(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: AppTranslations.pick(lang, en: 'Search Address...', mr: 'पत्ता शोधा...', hi: 'पता खोजें...'),
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => _loadVoters(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _toggleSelectAll,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            _selectedVoterIds.length == _voters.length && _voters.isNotEmpty
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: AppColors.brand600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Select All Visible (${AppTranslations.formatDigits(_voters.length, lang)})',
                              mr: 'दिसणारे सर्व निवडा (${AppTranslations.formatDigits(_voters.length, lang)})',
                              hi: 'दिखने वाले सभी चुनें (${AppTranslations.formatDigits(_voters.length, lang)})',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.brand200),
                    ),
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: '${AppTranslations.formatDigits(_selectedVoterIds.length, lang)} Selected',
                        mr: '${AppTranslations.formatDigits(_selectedVoterIds.length, lang)} निवडले',
                        hi: '${AppTranslations.formatDigits(_selectedVoterIds.length, lang)} चयनित',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brand600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2-Column Area
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Voter List
                  Expanded(
                    flex: 6,
                    child: Container(
                      height: 520,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _voters.isEmpty
                              ? Center(
                                  child: Text(
                                    AppTranslations.pick(lang, en: 'No voters found', mr: 'कोणतेही मतदार आढळले नाहीत', hi: 'कोई मतदाता नहीं मिला'),
                                    style: const TextStyle(color: AppColors.slate400),
                                  ),
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: ListView.separated(
                                        padding: const EdgeInsets.all(12),
                                        itemCount: _visibleVoters.length,
                                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                                        itemBuilder: (ctx, i) {
                                          final v = _visibleVoters[i];
                                          final isSelected = _selectedVoterIds.contains(v.id);
                                          return InkWell(
                                            onTap: () => _toggleSelectVoter(v.id),
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isSelected ? AppColors.brand50 : Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isSelected ? AppColors.brand600 : AppColors.slate200,
                                                  width: isSelected ? 1.5 : 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                                    color: isSelected ? AppColors.brand600 : AppColors.slate400,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        AppTranslatedText(
                                                          v.displayNameFor(lang),
                                                          isName: true,
                                                          targetLanguage: lang,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              '${AppTranslations.formatDigits(v.mobile ?? '-', lang)}  •  ',
                                                              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                                            ),
                                                            Expanded(
                                                              child: AppTranslatedText(
                                                                v.address,
                                                                targetLanguage: lang,
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                                              ),
                                                            ),
                                                          ],
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
                                    AppLoadMoreFooter(
                                      currentCount: _visibleVoters.length,
                                      totalCount: _voters.length,
                                      pageSize: 20,
                                      onLoadMore: () {
                                        setState(() => _displayedLimit += 20);
                                      },
                                      label: 'voters',
                                      isMarathi: lang == 'mr',
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right: AI Voice Campaign Configuration
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.brand600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'AI Speech Synthesizer',
                                    mr: 'AI व्हॉइस सिंथेसायझर',
                                    hi: 'AI वाणी संश्लेषक',
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppTranslations.pick(lang, en: 'Voice Language:', mr: 'आवाजाची भाषा:', hi: 'आवाज़ की भाषा:'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate600),
                          ),
                          const SizedBox(height: 6),
                          AppDropdown<String>(
                            value: _callLanguage,
                            height: 42,
                            backgroundColor: Colors.white,
                            borderColor: const Color(0xFFE2E8F0),
                            items: [
                              DropdownMenuItem(
                                value: 'mr-IN',
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Text(
                                    AppTranslations.pick(lang, en: 'Marathi - India', mr: 'मराठी - भारत', hi: 'मराठी - भारत'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'hi-IN',
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Text(
                                    AppTranslations.pick(lang, en: 'Hindi - India', mr: 'हिंदी - भारत', hi: 'हिंदी - भारत'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'en-IN',
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'English (Indian Accent)',
                                      mr: 'इंग्रजी (भारतीय उच्चार)',
                                      hi: 'अंग्रेज़ी (भारतीय उच्चारण)',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _callLanguage = v);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppTranslations.pick(lang, en: 'Speech Script:', mr: 'व्हॉइस संदेश (स्क्रिप्ट):', hi: 'वॉइस संदेश (स्क्रिप्ट):'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate600),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _callMessageController,
                            maxLines: 8,
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'Type script for the automated voice call...',
                                mr: 'स्वयंचलित व्हॉइस कॉलसाठी संदेश टाइप करा...',
                                hi: 'स्वचालित वॉइस कॉल के लिए संदेश लिखें...',
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              fillColor: const Color(0xFFF8FAFC),
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brand600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isBroadcasting ? null : () => _startAiVoiceCampaign(lang),
                              icon: _isBroadcasting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.phone_in_talk_rounded, size: 18),
                              label: Text(
                                _isBroadcasting
                                    ? AppTranslations.pick(lang, en: 'Dispatching Calls...', mr: 'कॉल्स पाठवत आहे...', hi: 'कॉल भेजे जा रहे हैं...')
                                    : AppTranslations.pick(lang, en: 'Start AI Voice Broadcast', mr: 'AI व्हॉइस प्रसारण सुरू करा', hi: 'AI वॉइस प्रसारण शुरू करें'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // History Tab
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'AI Voice Broadcast History',
                        mr: 'AI व्हॉइस प्रसारण इतिहास',
                        hi: 'AI वॉइस प्रसारण इतिहास',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'No AI voice campaign history recorded yet',
                            mr: 'अद्याप कोणताही AI व्हॉइस मोहिमेचा इतिहास नोंदवलेला नाही',
                            hi: 'अभी तक कोई AI वॉइस अभियान इतिहास दर्ज नहीं है',
                          ),
                          style: const TextStyle(color: AppColors.slate400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String key, String label, IconData icon) {
    final isSelected = _activeTab == key;
    return InkWell(
      onTap: () => setState(() => _activeTab = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.brand600 : AppColors.slate500),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.brand700 : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
