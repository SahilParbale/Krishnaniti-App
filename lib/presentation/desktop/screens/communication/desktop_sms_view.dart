import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../common/desktop_modal_dialog.dart';
import '../../../../data/models/voter_model.dart';
import '../../../../data/models/sms_campaign_model.dart';
import '../../../../data/repositories/sms_repository.dart';
import '../../shell/desktop_sidebar.dart';
import '../../../screens/sms/sms_history_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopSmsView extends ConsumerStatefulWidget {
  const DesktopSmsView({super.key});

  @override
  ConsumerState<DesktopSmsView> createState() => _DesktopSmsViewState();
}

class _DesktopSmsViewState extends ConsumerState<DesktopSmsView> {
  String _activeTab = 'send'; // 'send' | 'history'
  
  // Filters
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = '';
  final _casteController = TextEditingController();

  // Selection & Message
  final Set<String> _selectedVoterIds = {};
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isSending = false;

  List<VoterModel> _voters = [];
  int _displayedLimit = 20;
  List<VoterModel> get _visibleVoters =>
      _voters.take(_displayedLimit).toList();

  List<SmsCampaignModel> _campaignHistory = [];
  int _historyLimit = 20;
  List<SmsCampaignModel> get _visibleHistory =>
      _campaignHistory.take(_historyLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadVoters();
    _loadHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _houseNoController.dispose();
    _ageController.dispose();
    _casteController.dispose();
    _messageController.dispose();
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
      final normalizedHouseNo = AppTranslations.normalizeAsciiDigits(_houseNoController.text.trim());
      final voters = await repo.getVotersWithMobile(
        name: normalizedName.isEmpty ? null : normalizedName,
        address: normalizedAddress.isEmpty ? null : normalizedAddress,
        houseNo: normalizedHouseNo.isEmpty ? null : normalizedHouseNo,
        gender: _selectedGender.isEmpty ? null : _selectedGender,
        caste: _casteController.text.trim().isEmpty ? null : _casteController.text.trim(),
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

  Future<void> _loadHistory() async {
    setState(() => _historyLimit = 20);
    try {
      final repo = ref.read(smsRepoProvider);
      final history = await repo.getCampaigns();
      if (mounted) {
        setState(() => _campaignHistory = history);
      }
    } catch (_) {}
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

  void _confirmAndSend(String lang) {
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
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please enter message content',
              mr: 'कृपया संदेशाचा मजकूर लिहा',
              hi: 'कृपया संदेश लिखें',
            ),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (ctx, dialogRef, _) {
          final dLang = dialogRef.watch(desktopLanguageProvider);
          final selectedCount = AppTranslations.formatDigits(_selectedVoterIds.length, dLang);
          return DesktopModalDialog(
            title: AppTranslations.pick(
              dLang,
              en: 'Confirm SMS Campaign',
              mr: 'SMS मोहीम निश्चित करा',
              hi: 'एसएमएस अभियान की पुष्टि करें',
            ),
            subtitle: AppTranslations.pick(
              dLang,
              en: 'Review and confirm campaign details before dispatching',
              mr: 'पाठवण्यापूर्वी मोहिमेचा तपशील तपासा आणि निश्चित करा',
              hi: 'भेजने से पहले अभियान का विवरण जांचें और पुष्टि करें',
            ),
            icon: Icons.sms_rounded,
            width: 520,
            onClose: () => Navigator.pop(ctx),
            actions: [
              DesktopModalDialog.cancelButton(
                ctx,
                text: AppTranslations.pick(dLang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
              ),
              const SizedBox(width: 12),
              DesktopModalDialog.primaryButton(
                text: AppTranslations.pick(dLang, en: 'Send Campaign', mr: 'मोहीम पाठवा', hi: 'अभियान भेजें'),
                icon: Icons.send_rounded,
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() => _isSending = true);
                  try {
                    final repo = ref.read(smsRepoProvider);
                    final selectedVoters = _voters.where((v) => _selectedVoterIds.contains(v.id)).toList();
                    await repo.sendSmsCampaign(
                      campaignName: 'SMS Broadcast ${AppTranslations.formatDateTime(DateTime.now(), 'en')}',
                      recipients: selectedVoters,
                      message: _messageController.text,
                    );
                    if (mounted) {
                      final activeLang = ref.read(desktopLanguageProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppTranslations.pick(
                              activeLang,
                              en: 'SMS campaign sent successfully!',
                              mr: 'SMS मोहीम यशस्वीरित्या पाठवली गेली!',
                              hi: 'एसएमएस अभियान सफलतापूर्वक भेजा गया!',
                            ),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _messageController.clear();
                      _selectedVoterIds.clear();
                      _loadHistory();
                    }
                  } catch (e) {
                    if (mounted) {
                      final activeLang = ref.read(desktopLanguageProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppTranslations.pick(
                              activeLang,
                              en: 'Error: $e',
                              mr: 'त्रुटी: $e',
                              hi: 'त्रुटि: $e',
                            ),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSending = false);
                  }
                },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.pick(
                    dLang,
                    en: 'Are you sure you want to dispatch this SMS campaign to $selectedCount voters?',
                    mr: 'तुम्हाला ही SMS मोहीम $selectedCount मतदारांना पाठवायची आहे का?',
                    hi: 'क्या आप वाकई यह एसएमएस अभियान $selectedCount मतदाताओं को भेजना चाहते हैं?',
                  ),
                  style: const TextStyle(fontSize: 14, color: AppColors.slate700),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.pick(
                          dLang,
                          en: 'Message Preview:',
                          mr: 'संदेश पूर्वावलोकन:',
                          hi: 'संदेश पूर्वावलोकन:',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate500),
                      ),
                      const SizedBox(height: 6),
                      Text(_messageController.text, style: const TextStyle(fontSize: 13, color: AppColors.slate800)),
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
    final lang = ref.watch(desktopLanguageProvider);
    final charCount = AppTranslations.formatDigits(_messageController.text.length, lang);
    final smsParts = AppTranslations.formatDigits((_messageController.text.length / 160).floor() + 1, lang);

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
                          color: AppColors.brandPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.sms_rounded, color: AppColors.brandPrimary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(lang, en: 'Send SMS', mr: 'SMS पाठवा', hi: 'एसएमएस भेजें'),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Broadcast official updates directly to voters via SMS',
                                mr: 'मतदारांना SMS द्वारे थेट अधिकृत सूचना पाठवा',
                                hi: 'मतदाताओं को एसएमएस के माध्यम से सीधे आधिकारिक सूचनाएं भेजें',
                              ),
                              style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Download Report matching SMSCommunication.tsx
                OutlinedButton.icon(
                  onPressed: () {
                    SmsHistoryReportGenerator.generateAndPrintReport(
                      context: context,
                      campaigns: _campaignHistory,
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
                    'send',
                    AppTranslations.pick(lang, en: 'Send SMS', mr: 'SMS पाठवा', hi: 'एसएमएस भेजें'),
                    Icons.send_rounded,
                  ),
                  _buildTabButton(
                    'history',
                    AppTranslations.pick(lang, en: 'SMS History', mr: 'SMS इतिहास', hi: 'एसएमएस इतिहास'),
                    Icons.history_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_activeTab == 'send') ...[
              // Filters Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  children: [
                    Row(
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
                        const SizedBox(width: 12),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _houseNoController,
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(lang, en: 'House No.', mr: 'घर क्र.', hi: 'मकान नं.'),
                              prefixIcon: const Icon(Icons.home_outlined, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 150,
                          child: AppDropdown<String>(
                            value: _selectedGender,
                            height: 40,
                            prefixIcon: const Icon(Icons.people_outline, size: 16, color: Color(0xFF94A3B8)),
                            backgroundColor: Colors.white,
                            borderColor: const Color(0xFFE2E8F0),
                            items: [
                              DropdownMenuItem(
                                value: '',
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Text(
                                    AppTranslations.pick(lang, en: 'All Genders', mr: 'सर्व लिंग', hi: 'सभी लिंग'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'M',
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Text(AppTranslations.getGender('M', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'F',
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Text(AppTranslations.getGender('F', lang), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedGender = v ?? '');
                              _loadVoters();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _casteController,
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(lang, en: 'Caste...', mr: 'जात...', hi: 'जाति...'),
                              prefixIcon: const Icon(Icons.group_outlined, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => _loadVoters(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Bar (Select all & selected count)
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
                            color: AppColors.brandPrimary,
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
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: '${AppTranslations.formatDigits(_selectedVoterIds.length, lang)} Selected',
                        mr: '${AppTranslations.formatDigits(_selectedVoterIds.length, lang)} निवडले',
                        hi: '${AppTranslations.formatDigits(_selectedVoterIds.length, lang)} चयनित',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brandPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main 2-Column Area
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Voters list
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
                                    AppTranslations.pick(
                                      lang,
                                      en: 'No voters found with mobile number',
                                      mr: 'मोबाईल नंबर असलेले मतदार आढळले नाहीत',
                                      hi: 'मोबाइल नंबर वाले कोई मतदाता नहीं मिले',
                                    ),
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
                                                color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.05) : Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isSelected ? AppColors.brandPrimary : AppColors.slate200,
                                                  width: isSelected ? 1.5 : 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                                    color: isSelected ? AppColors.brandPrimary : AppColors.slate400,
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
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.slate100,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${v.genderLabel(lang)} / ${AppTranslations.formatDigits(v.age, lang)}',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate600),
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

                  // Right: Compose Message
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
                              const Icon(Icons.edit_note_rounded, color: AppColors.brandPrimary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.pick(lang, en: 'Compose Message', mr: 'संदेश लिहा', hi: 'संदेश लिखें'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _messageController,
                            maxLines: 10,
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'Type your official SMS announcement here...',
                                mr: 'तुमची अधिकृत SMS सूचना येथे टाइप करा...',
                                hi: 'अपनी आधिकारिक एसएमएस घोषणा यहाँ लिखें...',
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              fillColor: const Color(0xFFF8FAFC),
                              filled: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: '$charCount characters',
                                  mr: '$charCount अक्षरे',
                                  hi: '$charCount अक्षर',
                                ),
                                style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                              ),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: '$smsParts SMS',
                                  mr: '$smsParts SMS',
                                  hi: '$smsParts एसएमएस',
                                ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isSending ? null : () => _confirmAndSend(lang),
                              icon: _isSending
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                _isSending
                                    ? AppTranslations.pick(lang, en: 'Sending...', mr: 'पाठवत आहे...', hi: 'भेजा जा रहा है...')
                                    : AppTranslations.pick(lang, en: 'Send SMS Broadcast', mr: 'SMS प्रसारण पाठवा', hi: 'एसएमएस प्रसारण भेजें'),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.pick(lang, en: 'SMS Campaign History', mr: 'SMS मोहीम इतिहास', hi: 'एसएमएस अभियान इतिहास'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_campaignHistory.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'No SMS campaign history found',
                              mr: 'SMS मोहिमेचा इतिहास आढळला नाही',
                              hi: 'कोई एसएमएस अभियान इतिहास नहीं मिला',
                            ),
                            style: const TextStyle(color: AppColors.slate400),
                          ),
                        ),
                      )
                    else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _visibleHistory.length,
                        separatorBuilder: (_, _) => const Divider(color: AppColors.slate100),
                        itemBuilder: (ctx, i) {
                          final item = _visibleHistory[i];
                          final recipientCount = AppTranslations.formatDigits(item.totalRecipients, lang);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.mark_email_read_outlined, color: AppColors.brandPrimary, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppTranslatedText(
                                        item.name,
                                        targetLanguage: lang,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppTranslations.formatDateTime(item.createdAt, lang),
                                        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.status.toLowerCase() == 'completed' || item.status.toLowerCase() == 'sent'
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    AppTranslations.getStatus(item.status, lang).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: item.status.toLowerCase() == 'completed' || item.status.toLowerCase() == 'sent'
                                          ? Colors.green
                                          : Colors.amber.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: '$recipientCount recipients',
                                    mr: '$recipientCount प्राप्तकर्ते',
                                    hi: '$recipientCount प्राप्तकर्ता',
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate700),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      AppLoadMoreFooter(
                        currentCount: _visibleHistory.length,
                        totalCount: _campaignHistory.length,
                        pageSize: 20,
                        onLoadMore: () {
                          setState(() => _historyLimit += 20);
                        },
                        label: AppTranslations.pick(lang, en: 'campaigns', mr: 'मोहिमा', hi: 'अभियान'),
                        isMarathi: lang == 'mr',
                      ),
                    ],
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
          color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.brandPrimary : AppColors.slate500),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.brandPrimary : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
