import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/sms_campaign_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/sms_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import 'sms_history_report_generator.dart';

class SmsCommunicationScreen extends ConsumerStatefulWidget {
  const SmsCommunicationScreen({super.key});

  @override
  ConsumerState<SmsCommunicationScreen> createState() => _SmsCommunicationScreenState();
}

class _SmsCommunicationScreenState extends ConsumerState<SmsCommunicationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter state
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _casteController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _ageFilter = 'All';
  String _genderFilter = 'All';
  String _boothFilter = 'All';

  bool _isLoadingVoters = false;
  List<VoterModel> _voters = [];
  final Set<String> _selectedVoterIds = {};
  bool _isAllVisibleSelected = false;

  // History state
  bool _isLoadingHistory = false;
  List<SmsCampaignModel> _campaignHistory = [];

  // Compose state
  bool _isSending = false;
  SmsTemplateModel? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _campaignHistory.isEmpty) {
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
    _houseNoController.dispose();
    _casteController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoadingVoters = true);
    final repo = ref.read(smsRepoProvider);

    try {
      final list = await repo.getVotersWithMobile(
        name: _nameController.text.trim(),
        address: AppTranslations.normalizeAsciiDigits(_addressController.text.trim()),
        houseNo: AppTranslations.normalizeAsciiDigits(_houseNoController.text.trim()),
        ageRange: _ageFilter,
        gender: _genderFilter,
        caste: _casteController.text.trim(),
        booth: _boothFilter,
      );

      if (mounted) {
        setState(() {
          _voters = list;
          _isLoadingVoters = false;
          _updateSelectAllStatus();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVoters = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final repo = ref.read(smsRepoProvider);

    try {
      final logs = await repo.getCampaigns();
      if (mounted) {
        setState(() {
          _campaignHistory = logs;
          _isLoadingHistory = false;
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

  void _applyTemplate(SmsTemplateModel template) {
    setState(() {
      _selectedTemplate = template;
      _messageController.text = template.text;
    });
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
              mr: 'कृपया संदेश मजकूर टाका.',
              hi: 'कृपया संदेश पाठ दर्ज करें।',
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, dialogRef, _) {
          final dialogLang = dialogRef.watch(appLanguageProvider);
          final selectedCountStr = AppTranslations.formatDigits(_selectedVoterIds.length, dialogLang);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.sms_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppTranslations.pick(
                      dialogLang,
                      en: 'Confirm SMS Campaign',
                      mr: 'SMS मोहीम निश्चित करा',
                      hi: 'एसएमएस अभियान की पुष्टि करें',
                    ),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    dialogLang,
                    en: 'I confirm that I have reviewed the recipients and message and wish to send this official SMS.',
                    mr: 'मी प्राप्तकर्ते आणि संदेश तपासला असून हा अधिकृत SMS पाठवू इच्छितो याची पुष्टी करतो.',
                    hi: 'मैं पुष्टि करता हूँ कि मैंने प्राप्तकर्ताओं और संदेश की समीक्षा कर ली है और यह आधिकारिक एसएमएस भेजना चाहता हूँ।',
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
                              dialogLang,
                              en: 'Selected Voters:',
                              mr: 'निवडलेले मतदार:',
                              hi: 'चयनित मतदाता:',
                            ),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          Text(
                            AppTranslations.pick(
                              dialogLang,
                              en: '$selectedCountStr Voters',
                              mr: '$selectedCountStr मतदार',
                              hi: '$selectedCountStr मतदाता',
                            ),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppTranslations.pick(
                              dialogLang,
                              en: 'Route / Channel:',
                              mr: 'मार्ग / चॅनेल:',
                              hi: 'रूट / चैनल:',
                            ),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          Flexible(
                            child: Text(
                              AppTranslations.pick(
                                dialogLang,
                                en: 'DLT Government Header (SMS)',
                                mr: 'DLT शासकीय हेडर (SMS)',
                                hi: 'DLT सरकारी हेडर (SMS)',
                              ),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      Text(
                        AppTranslations.pick(
                          dialogLang,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: AppTranslatedText(
                          _messageController.text.trim(),
                          targetLanguage: dialogLang,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
                          maxLines: 4,
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
                  AppTranslations.pick(dialogLang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _executeSendSms();
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  AppTranslations.pick(dialogLang, en: 'Confirm & Send', mr: 'निश्चित करा व पाठवा', hi: 'पुष्टि करें और भेजें'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeSendSms() async {
    setState(() => _isSending = true);
    final repo = ref.read(smsRepoProvider);
    final lang = ref.read(appLanguageProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final selectedVotersList = _voters.where((v) => _selectedVoterIds.contains(v.id)).toList();
      final campaignName = _selectedTemplate != null
          ? _selectedTemplate!.title
          : 'SMS Campaign ${AppTranslations.formatDate(DateTime.now(), 'en', pattern: 'dd MMM HH:mm')}';

      final campaign = await repo.sendSmsCampaign(
        campaignName: campaignName,
        message: _messageController.text.trim(),
        recipients: selectedVotersList,
        dltTemplateId: _selectedTemplate?.dltTeId,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
          _selectedVoterIds.clear();
          _isAllVisibleSelected = false;
          _messageController.clear();
          _selectedTemplate = null;
          _campaignHistory.insert(0, campaign);
        });

        final countStr = AppTranslations.formatDigits(campaign.totalRecipients, lang);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'SMS broadcast queued for $countStr voters!',
                mr: '$countStr मतदारांसाठी SMS प्रसारण रांगेत ठेवले आहे!',
                hi: '$countStr मतदाताओं के लिए एसएमएस प्रसारण कतार में लगाया गया है!',
              ),
            ),
            backgroundColor: const Color(0xFF047857),
            duration: const Duration(seconds: 3),
          ),
        );

        // Switch to history tab to view campaign progress
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
                en: 'Error sending SMS. Please try again.',
                mr: 'SMS पाठवताना त्रुटी आली. कृपया पुन्हा प्रयत्न करा.',
                hi: 'एसएमएस भेजने में त्रुटि। कृपया पुनः प्रयास करें।',
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
    if (_campaignHistory.isEmpty) await _loadHistory();
    await SmsHistoryReportGenerator.generateAndPrintReport(
      context: mounted ? context : null,
      campaigns: _campaignHistory,
      lang: lang,
    );
  }

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
              AppTranslations.pick(lang, en: 'Send SMS', mr: 'SMS पाठवा', hi: 'एसएमएस भेजें'),
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
                en: 'SMS broadcasts & campaign delivery',
                mr: 'SMS प्रसारण आणि मोहीम वितरण',
                hi: 'एसएमएस प्रसारण और अभियान वितरण',
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
                      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 15),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(lang, en: 'Send SMS', mr: 'SMS पाठवा', hi: 'एसएमएस भेजें'),
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
                              const Icon(Icons.history_rounded, size: 15),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'History & Reports',
                                    mr: 'इतिहास व अहवाल',
                                    hi: 'इतिहास और रिपोर्ट',
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
                AppPdfButton.outlined(
                  label: AppTranslations.pick(lang, en: 'Report', mr: 'अहवाल', hi: 'रिपोर्ट'),
                  onPressed: _generatePdfReport,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendSmsTab(lang),
                _buildHistoryTab(lang),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _tabController.index == 0 && _selectedVoterIds.isNotEmpty
          ? _buildStickySendBar(lang)
          : null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: Send SMS Tab
  // ─────────────────────────────────────────────────────────────
  Widget _buildSendSmsTab(String lang) {
    final templates = ref.read(smsRepoProvider).getSmsTemplates();
    final charCount = AppTranslations.formatDigits(_messageController.text.length, lang);
    final smsCount = AppTranslations.formatDigits(
      (_messageController.text.length / 160).ceil().clamp(1, 10),
      lang,
    );
    final visibleVotersCount = AppTranslations.formatDigits(_voters.length, lang);
    final selectedVotersCount = AppTranslations.formatDigits(_selectedVoterIds.length, lang);

    return RefreshIndicator(
      onRefresh: _loadVoters,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DLT Registered Templates Strip
            Row(
              children: [
                const Icon(Icons.star_outline_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Registered DLT Templates (Quick Templates)',
                      mr: 'नोंदणीकृत DLT टेम्पलेट्स (जलद टेम्पलेट्स)',
                      hi: 'पंजीकृत DLT टेम्प्लेट्स (त्वरित टेम्प्लेट्स)',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final t = templates[i];
                  final isSelected = _selectedTemplate?.id == t.id;
                  return InkWell(
                    onTap: () => _applyTemplate(t),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: AppTranslatedText(
                        t.title,
                        targetLanguage: lang,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // 2. Compose Message Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
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
                          en: 'Compose Message *',
                          mr: 'संदेश लिहा *',
                          hi: 'संदेश लिखें *',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (_selectedTemplate != null)
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'DLT ID: ${_selectedTemplate!.dltTeId}',
                            mr: 'DLT आयडी: ${_selectedTemplate!.dltTeId}',
                            hi: 'DLT आईडी: ${_selectedTemplate!.dltTeId}',
                          ),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Type your message here...',
                        mr: 'येथे तुमचा संदेश टाइप करा...',
                        hi: 'यहाँ अपना संदेश लिखें...',
                      ),
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(10),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFFCBD5E1)),
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
                                  en: 'Note: SMS will be delivered only to voters with registered mobile numbers.',
                                  mr: 'टीप: फक्त नोंदणीकृत मोबाइल क्रमांक असलेल्या मतदारांनाच SMS पाठवला जाईल.',
                                  hi: 'नोट: केवल पंजीकृत मोबाइल नंबर वाले मतदाताओं को ही एसएमएस भेजा जाएगा।',
                                ),
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: '$charCount chars · $smsCount SMS',
                          mr: '$charCount अक्षरे · $smsCount SMS',
                          hi: '$charCount अक्षर · $smsCount SMS',
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Filters Section
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
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
                          AppTranslations.pick(lang, en: 'Reset', mr: 'रीसेट', hi: 'रीसेट'),
                          style: const TextStyle(fontSize: 11, color: Colors.white),
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
                              hintText: AppTranslations.pick(lang, en: 'Search name...', mr: 'नाव शोधा...', hi: 'नाम खोजें...'),
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
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
                              hintText: AppTranslations.pick(lang, en: 'Address / Area...', mr: 'पत्ता / परिसर...', hi: 'पता / क्षेत्र...'),
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 2: Age, Gender, Booth
                  Row(
                    children: [
                      // Age Filter
                      Expanded(
                        child: AppDropdown<String>(
                          title: AppTranslations.pick(lang, en: 'Filter by Age', mr: 'वयानुसार फिल्टर करा', hi: 'आयु के अनुसार फ़िल्टर करें'),
                          value: _ageFilter,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(AppTranslations.pick(lang, en: 'All Ages', mr: 'सर्व वयोगट', hi: 'सभी आयु वर्ग'), style: const TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: '18-25',
                              child: Text(AppTranslations.pick(lang, en: 'Age 18-25', mr: 'वय १८-२५', hi: 'आयु १८-२५'), style: const TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: '26-40',
                              child: Text(AppTranslations.pick(lang, en: 'Age 26-40', mr: 'वय २६-४०', hi: 'आयु २६-४०'), style: const TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: '41-60',
                              child: Text(AppTranslations.pick(lang, en: 'Age 41-60', mr: 'वय ४१-६०', hi: 'आयु ४१-६०'), style: const TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: '60+',
                              child: Text(AppTranslations.pick(lang, en: 'Age 60+', mr: 'वय ६०+', hi: 'आयु ६०+'), style: const TextStyle(fontSize: 12)),
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

                      // Gender Filter
                      Expanded(
                        child: AppDropdown<String>(
                          title: AppTranslations.pick(lang, en: 'Filter by Gender', mr: 'लिंगानुसार फिल्टर करा', hi: 'लिंग के अनुसार फ़िल्टर करें'),
                          value: _genderFilter,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(AppTranslations.pick(lang, en: 'All Genders', mr: 'सर्व लिंग', hi: 'सभी लिंग'), style: const TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: 'M',
                              child: Text(AppTranslations.getGender('M', lang), style: const TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: 'F',
                              child: Text(AppTranslations.getGender('F', lang), style: const TextStyle(fontSize: 12)),
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

                      // Booth Filter
                      Expanded(
                        child: AppDropdown<String>(
                          title: AppTranslations.pick(lang, en: 'Filter by Booth', mr: 'बूथनुसार फिल्टर करा', hi: 'बूथ के अनुसार फ़िल्टर करें'),
                          value: _boothFilter,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(AppTranslations.pick(lang, en: 'All Booths', mr: 'सर्व बूथ', hi: 'सभी बूथ'), style: const TextStyle(fontSize: 12)),
                            ),
                            ...['28', '29', '30', '31'].map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Booth $b',
                                    mr: 'बूथ ${AppTranslations.formatDigits(b, lang)}',
                                    hi: 'बूथ ${AppTranslations.formatDigits(b, lang)}',
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
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
                InkWell(
                  onTap: _handleSelectAllVisible,
                  child: Row(
                    children: [
                      Icon(
                        _isAllVisibleSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: _isAllVisibleSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Select All ($visibleVotersCount voters)',
                          mr: 'सर्व निवडा ($visibleVotersCount मतदार)',
                          hi: 'सभी चुनें ($visibleVotersCount मतदाता)',
                        ),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: '$selectedVotersCount Selected',
                          mr: '$selectedVotersCount निवडले',
                          hi: '$selectedVotersCount चयनित',
                        ),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    if (_selectedVoterIds.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _clearSelection,
                        child: Text(
                          AppTranslations.pick(lang, en: 'Clear', mr: 'रद्द करा', hi: 'साफ़ करें'),
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 5. Voter Cards List
            if (_isLoadingVoters)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_voters.isEmpty)
              _buildEmptyVotersState(lang)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _voters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final voter = _voters[idx];
                  final isSelected = _selectedVoterIds.contains(voter.id);
                  final genderText = voter.genderLabel(lang);
                  final ageText = AppTranslations.formatDigits(voter.age, lang);

                  return InkWell(
                    onTap: () => _toggleSelectVoter(voter.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                            size: 20,
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
                                        voter.displayNameFor(lang),
                                        isName: true,
                                        targetLanguage: lang,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone, size: 10, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            voter.mobile != null && voter.mobile!.isNotEmpty
                                                ? AppTranslations.formatDigits(voter.mobile!, lang)
                                                : '-',
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
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
                                        en: '$genderText · Age $ageText',
                                        mr: '$genderText · वय $ageText',
                                        hi: '$genderText · आयु $ageText',
                                      ),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    if (voter.booth.isNotEmpty) ...[
                                      const Text(' · ', style: TextStyle(color: Color(0xFFCBD5E1))),
                                      Flexible(
                                        child: AppTranslatedText(
                                          voter.booth,
                                          targetLanguage: lang,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                          overflow: TextOverflow.ellipsis,
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
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Builder: History Tab
  // ─────────────────────────────────────────────────────────────
  Widget _buildHistoryTab(String lang) {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : _campaignHistory.isEmpty
              ? _buildEmptyHistoryState(lang)
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: _campaignHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final campaign = _campaignHistory[idx];
                    return _buildCampaignHistoryCard(campaign, lang);
                  },
                ),
    );
  }

  Widget _buildCampaignHistoryCard(SmsCampaignModel campaign, String lang) {
    Color statusBg = const Color(0xFFECFDF5);
    Color statusColor = const Color(0xFF047857);
    if (campaign.isFailed) {
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFDC2626);
    } else if (campaign.isSending) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTranslatedText(
                      campaign.name,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppTranslations.formatDateTime(campaign.createdAt, lang),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  AppTranslations.getStatus(campaign.status, lang),
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: AppTranslatedText(
              campaign.message,
              targetLanguage: lang,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
            ),
          ),

          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              _buildMiniHistoryStat(
                AppTranslations.pick(lang, en: 'Recipients', mr: 'प्राप्तकर्ते', hi: 'प्राप्तकर्ता'),
                AppTranslations.formatDigits(campaign.totalRecipients, lang),
                const Color(0xFF0284C7),
              ),
              const SizedBox(width: 8),
              _buildMiniHistoryStat(
                AppTranslations.pick(lang, en: 'Delivered', mr: 'वितरित', hi: 'वितरित'),
                AppTranslations.formatDigits(campaign.stats.delivered, lang),
                const Color(0xFF047857),
              ),
              const SizedBox(width: 8),
              _buildMiniHistoryStat(
                AppTranslations.pick(lang, en: 'Failed', mr: 'अयशस्वी', hi: 'विफल'),
                AppTranslations.formatDigits(campaign.stats.failed, lang),
                campaign.stats.failed > 0 ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
              ),
              const Spacer(),
              if (campaign.dltTemplateId != null)
                Text(
                  campaign.dltTemplateId!,
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniHistoryStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStickySendBar(String lang) {
    final selectedCountStr = AppTranslations.formatDigits(_selectedVoterIds.length, lang);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, -2))],
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
                      en: '$selectedCountStr voters selected',
                      mr: '$selectedCountStr मतदार निवडले आहेत',
                      hi: '$selectedCountStr मतदाता चयनित',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Dispatched via official DLT registered SMS gateway',
                      mr: 'अधिकृत DLT नोंदणीकृत SMS गेटवेद्वारे पाठवले जाईल',
                      hi: 'आधिकारिक DLT पंजीकृत एसएमएस गेटवे के माध्यम से भेजा जाएगा',
                    ),
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: _isSending ? null : _showConfirmationDialog,
              icon: _isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSending
                    ? AppTranslations.pick(lang, en: 'Sending...', mr: 'पाठवत आहे...', hi: 'भेजा जा रहा है...')
                    : AppTranslations.pick(lang, en: 'Send SMS', mr: 'SMS पाठवा', hi: 'एसएमएस भेजें'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
              mr: 'सध्याच्या फिल्टरनुसार कोणतेही मतदार सापडले नाहीत.',
              hi: 'वर्तमान फ़िल्टर से मेल खाने वाला कोई मतदाता नहीं मिला।',
            ),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.pick(
              lang,
              en: 'Modify search query or click Reset.',
              mr: 'शोध मजकूर बदला किंवा रीसेट वर क्लिक करा.',
              hi: 'खोज बदलें या रीसेट पर क्लिक करें।',
            ),
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sms_failed_outlined, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 8),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No SMS campaigns sent yet.',
              mr: 'अद्याप कोणतीही SMS मोहीम पाठवलेली नाही.',
              hi: 'अभी तक कोई एसएमएस अभियान नहीं भेजा गया है।',
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

