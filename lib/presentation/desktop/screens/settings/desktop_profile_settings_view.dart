import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/navigation_provider.dart';
import 'desktop_bot_dashboard_view.dart';

class DesktopProfileSettingsView extends ConsumerStatefulWidget {
  final String? initialTab;
  const DesktopProfileSettingsView({super.key, this.initialTab});

  @override
  ConsumerState<DesktopProfileSettingsView> createState() => _DesktopProfileSettingsViewState();
}

class _DesktopProfileSettingsViewState extends ConsumerState<DesktopProfileSettingsView> {
  String _activeTab = 'profile'; // 'profile' | 'bot' | 'sms' | 'security' | 'support'

  // Profile Form Controllers
  final _nameEnCtrl = TextEditingController(text: 'Ramesh Patil');
  final _nameMrCtrl = TextEditingController(text: 'Ramesh Patil');
  final _wardNameCtrl = TextEditingController(text: 'Kasba - Vishrambaug');
  final _wardNoCtrl = TextEditingController(text: '12');
  final _partyCtrl = TextEditingController(text: 'Nationalist Congress Party');
  final _addressCtrl = TextEditingController(text: 'Shaniwar Peth, Bajirao Road, Pune - 411030');
  final _hoursCtrl = TextEditingController(text: 'Morning 9:00 AM - 1:00 PM, Evening 5:00 PM - 8:00 PM');
  final _phoneCtrl = TextEditingController(text: '+91 98220 12345');
  final _emailCtrl = TextEditingController(text: 'ramesh.patil.corporator@gmail.com');
  bool _isSavingProfile = false;

  // SMS Gateway state
  bool _isSmsConnected = true;
  final _apiKeyCtrl = TextEditingController(text: 'sec_sms_gateway_live_prod_8829');

  // Support ticket form
  final _ticketTitleCtrl = TextEditingController();
  final _ticketDescCtrl = TextEditingController();
  String _ticketPriority = 'Medium';

  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 'TKT-101',
      'title': 'Voter roll import EPIC number mismatch error',
      'priority': 'High',
      'status': 'Resolved',
      'date': DateTime.now().subtract(const Duration(days: 4)),
    },
    {
      'id': 'TKT-102',
      'title': 'WhatsApp automated bot QR code reconnection request',
      'priority': 'Medium',
      'status': 'In Progress',
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _activeTab = widget.initialTab!;
    } else {
      _activeTab = ref.read(desktopSettingsTabProvider);
    }
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameMrCtrl.dispose();
    _wardNameCtrl.dispose();
    _wardNoCtrl.dispose();
    _partyCtrl.dispose();
    _addressCtrl.dispose();
    _hoursCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _apiKeyCtrl.dispose();
    _ticketTitleCtrl.dispose();
    _ticketDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      final lang = ref.read(desktopLanguageProvider);
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Profile details updated successfully!',
              mr: 'प्रोफाइल माहिती यशस्वीरित्या अद्यतनित केली!',
              hi: 'प्रोफ़ाइल विवरण सफलतापूर्वक अपडेट किया गया!',
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _submitSupportTicket() {
    final lang = ref.read(desktopLanguageProvider);
    if (_ticketTitleCtrl.text.trim().isEmpty || _ticketDescCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please fill title and description',
              mr: 'कृपया शीर्षक आणि वर्णन भरा',
              hi: 'कृपया शीर्षक और विवरण भरें',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _tickets.insert(0, {
        'id': 'TKT-${DateTime.now().millisecondsSinceEpoch % 1000}',
        'title': _ticketTitleCtrl.text.trim(),
        'priority': _ticketPriority,
        'status': 'Pending',
        'date': DateTime.now(),
      });
      _ticketTitleCtrl.clear();
      _ticketDescCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Support ticket submitted successfully.',
            mr: 'सपोर्ट तिकीट यशस्वीरित्या पाठवले.',
            hi: 'सहायता टिकट सफलतापूर्वक सबमिट किया गया।',
          ),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);

    ref.listen<String>(desktopSettingsTabProvider, (prev, next) {
      if (next != _activeTab && mounted) {
        setState(() => _activeTab = next);
      }
    });

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
                        child: const Icon(Icons.settings_rounded, color: AppColors.brandPrimary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getNavTitle('profile_settings', lang),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Manage corporator profile info, SMS connection gateway, security sessions, and support',
                                mr: 'नगरसेवक प्रोफाईल माहिती, एसएमएस गेटवे, सुरक्षा सत्रे आणि सपोर्ट व्यवस्थापन',
                                hi: 'नगरसेवक प्रोफाइल जानकारी, एसएमएस गेटवे, सुरक्षा सत्र और सहायता प्रबंधन',
                              ),
                              style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    ],
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton('profile', AppTranslations.pick(lang, en: 'Profile Details', mr: 'प्रोफाईल तपशील', hi: 'प्रोफाइल विवरण'), Icons.person_outline_rounded),
                    _buildTabButton('bot', AppTranslations.pick(lang, en: 'WhatsApp Bot', mr: 'व्हॉट्सॲप बॉट', hi: 'व्हाट्सएप बॉट'), Icons.smart_toy_outlined),
                    _buildTabButton('sms', AppTranslations.pick(lang, en: 'SMS Gateway', mr: 'एसएमएस गेटवे', hi: 'एसएमएस गेटवे'), Icons.phone_android_rounded),
                    _buildTabButton('security', AppTranslations.pick(lang, en: 'Security Logs', mr: 'सुरक्षा लॉग', hi: 'सुरक्षा लॉग'), Icons.shield_outlined),
                    _buildTabButton('support', AppTranslations.pick(lang, en: 'Support Tickets', mr: 'सपोर्ट तिकिटे', hi: 'सहायता टिकट'), Icons.support_agent_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_activeTab == 'profile') ...[
              // Profile Form Container
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
                    // Live Translated Profile Preview Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
                            child: const Icon(Icons.account_balance_rounded, color: AppColors.brandPrimary, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTranslatedText(
                                  _nameEnCtrl.text,
                                  isName: true,
                                  targetLanguage: lang,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                                ),
                                const SizedBox(height: 3),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    AppTranslatedText(
                                      _partyCtrl.text,
                                      targetLanguage: lang,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brandPrimary),
                                    ),
                                    const Text('•', style: TextStyle(color: AppColors.slate400)),
                                    Text(
                                      '${AppTranslations.pick(lang, en: 'Ward', mr: 'प्रभाग', hi: 'वार्ड')} ${AppTranslations.formatDigits(_wardNoCtrl.text, lang)}',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate700),
                                    ),
                                    AppTranslatedText(
                                      AppTranslations.getAreaName(_wardNameCtrl.text, lang),
                                      targetLanguage: lang,
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                AppTranslatedText(
                                  _addressCtrl.text,
                                  targetLanguage: lang,
                                  style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      AppTranslations.formatDigits(_phoneCtrl.text, lang),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate600),
                                    ),
                                    Text(
                                      _emailCtrl.text,
                                      style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                    ),
                                    AppTranslatedText(
                                      _hoursCtrl.text,
                                      targetLanguage: lang,
                                      style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppTranslations.pick(lang, en: 'Representative Information', mr: 'प्रतिनिधी माहिती', hi: 'प्रतिनिधि जानकारी'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            AppTranslations.pick(lang, en: 'Name (English):', mr: 'नाव (इंग्रजी):', hi: 'नाम (अंग्रेजी):'),
                            _nameEnCtrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            AppTranslations.pick(lang, en: 'Name (Regional):', mr: 'नाव (मराठी/हिंदी):', hi: 'नाम (क्षेत्रीय):'),
                            _nameMrCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            AppTranslations.pick(lang, en: 'Ward Name:', mr: 'प्रभाग नाव:', hi: 'वार्ड नाम:'),
                            _wardNameCtrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            AppTranslations.pick(lang, en: 'Ward Number:', mr: 'प्रभाग क्रमांक:', hi: 'वार्ड नंबर:'),
                            _wardNoCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      AppTranslations.pick(lang, en: 'Political Party:', mr: 'पक्ष:', hi: 'दल / पार्टी:'),
                      _partyCtrl,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      AppTranslations.pick(lang, en: 'Official Office Address:', mr: 'कार्यालय पत्ता:', hi: 'कार्यालय का पता:'),
                      _addressCtrl,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            AppTranslations.pick(lang, en: 'Contact Phone:', mr: 'मोबाईल नंबर:', hi: 'मोबाइल नंबर:'),
                            _phoneCtrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            AppTranslations.pick(lang, en: 'Official Email:', mr: 'ईमेल आयडी:', hi: 'ईमेल आईडी:'),
                            _emailCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      AppTranslations.pick(lang, en: 'Office Visiting Hours:', mr: 'कार्यालयीन वेळ:', hi: 'कार्यालय का समय:'),
                      _hoursCtrl,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 240,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSavingProfile ? null : () => _saveProfile(),
                        icon: _isSavingProfile
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          AppTranslations.pick(lang, en: 'Save Profile Details', mr: 'बदल जतन करा', hi: 'परिवर्तन सहेजें'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_activeTab == 'bot') ...[
              const DesktopBotDashboardView(),
            ] else if (_activeTab == 'sms') ...[
              // SMS Gateway Connection
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'SMS Gateway Connection Status',
                            mr: 'एसएमएस गेटवे कनेक्शन स्थिती',
                            hi: 'एसएमएस गेटवे कनेक्शन स्थिति',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isSmsConnected ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _isSmsConnected ? Colors.green : Colors.red),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isSmsConnected ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                                color: _isSmsConnected ? Colors.green : Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isSmsConnected
                                    ? AppTranslations.pick(lang, en: 'CONNECTED', mr: 'कनेक्टेड', hi: 'कनेक्टेड')
                                    : AppTranslations.pick(lang, en: 'DISCONNECTED', mr: 'डिस्कनेक्टेड', hi: 'डिस्कनेक्टेड'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isSmsConnected ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.smartphone_rounded, color: AppColors.brandPrimary, size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.formatDigits(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Samsung Galaxy M34 (Dedicated Ward SIM)',
                                      mr: 'Samsung Galaxy M34 (समर्पित प्रभाग सिम)',
                                      hi: 'Samsung Galaxy M34 (समर्पित वार्ड सिम)',
                                    ),
                                    lang,
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppTranslations.formatDigits(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Last active: 2 mins ago  •  Battery: 92%',
                                      mr: 'शेवटचे सक्रिय: २ मिनिटांपूर्वी  •  बॅटरी: ९२%',
                                      hi: 'अंतिम सक्रिय: २ मिनट पहले  •  बैटरी: ९२%',
                                    ),
                                    lang,
                                  ),
                                  style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSmsConnected ? Colors.red.shade50 : AppColors.brandPrimary,
                              foregroundColor: _isSmsConnected ? Colors.red : Colors.white,
                              elevation: 0,
                              side: BorderSide(color: _isSmsConnected ? Colors.red.shade200 : AppColors.brandPrimary),
                            ),
                            onPressed: () {
                              setState(() => _isSmsConnected = !_isSmsConnected);
                            },
                            child: Text(
                              _isSmsConnected
                                  ? AppTranslations.pick(lang, en: 'Disconnect', mr: 'डिस्कनेक्ट करा', hi: 'डिस्कनेक्ट करें')
                                  : AppTranslations.pick(lang, en: 'Connect Gateway', mr: 'गेटवे कनेक्ट करा', hi: 'गेटवे कनेक्ट करें'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_activeTab == 'security') ...[
              // Security Logs
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Recent Security & Device Sessions',
                            mr: 'अलीकडील सुरक्षा आणि डिव्हाइस सत्रे',
                            hi: 'हालिया सुरक्षा और डिवाइस सत्र',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Signed out other device sessions',
                                        mr: 'इतर उपकरणांची सत्रे लॉगआउट केली',
                                        hi: 'अन्य डिवाइस सत्र साइन आउट किए गए',
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.logout_rounded, size: 16),
                              label: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Sign Out Others',
                                  mr: 'इतर डिव्हाइस लॉगआउट करा',
                                  hi: 'अन्य डिवाइस साइन आउट करें',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSessionItem(
                      AppTranslations.formatDigits(
                        AppTranslations.pick(
                          lang,
                          en: 'Windows 11 PC (Current Session)',
                          mr: 'Windows 11 PC (सध्याचे सत्र)',
                          hi: 'Windows 11 PC (वर्तमान सत्र)',
                        ),
                        lang,
                      ),
                      AppTranslations.formatDigits('Chrome 122  •  IP: 49.36.120.45', lang),
                      AppTranslations.pick(lang, en: 'Active Now', mr: 'सध्या सक्रिय', hi: 'अभी सक्रिय'),
                      true,
                    ),
                    const Divider(color: AppColors.slate100),
                    _buildSessionItem(
                      AppTranslations.formatDigits('iPhone 15 Pro', lang),
                      AppTranslations.formatDigits('Safari Mobile  •  IP: 152.58.21.90', lang),
                      AppTranslations.formatDigits(
                        AppTranslations.pick(
                          lang,
                          en: 'Yesterday, 08:30 PM',
                          mr: 'काल, रात्री ०८:३० वा.',
                          hi: 'कल, रात ०८:३० बजे',
                        ),
                        lang,
                      ),
                      false,
                    ),
                    const Divider(color: AppColors.slate100),
                    _buildSessionItem(
                      'MacBook Pro',
                      AppTranslations.formatDigits('Chrome Desktop  •  IP: 114.143.78.12', lang),
                      AppTranslations.formatDigits(
                        AppTranslations.pick(
                          lang,
                          en: '3 days ago',
                          mr: '३ दिवसांपूर्वी',
                          hi: '३ दिन पहले',
                        ),
                        lang,
                      ),
                      false,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Support Tickets
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Create ticket form
                  Expanded(
                    flex: 5,
                    child: Container(
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
                              en: 'Raise New Support Ticket',
                              mr: 'नवीन सपोर्ट तिकीट नोंदवा',
                              hi: 'नया सहायता टिकट दर्ज करें',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            AppTranslations.pick(
                              lang,
                              en: 'Subject / Issue Title:',
                              mr: 'विषय / समस्येचे शीर्षक:',
                              hi: 'विषय / समस्या शीर्षक:',
                            ),
                            _ticketTitleCtrl,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppTranslations.pick(lang, en: 'Priority:', mr: 'प्राधान्य:', hi: 'प्राथमिकता:'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _ticketPriority,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: [
                              DropdownMenuItem(value: 'Low', child: Text(AppTranslations.getPriority('Low', lang))),
                              DropdownMenuItem(value: 'Medium', child: Text(AppTranslations.getPriority('Medium', lang))),
                              DropdownMenuItem(value: 'High', child: Text(AppTranslations.getPriority('High', lang))),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _ticketPriority = v);
                            },
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppTranslations.pick(lang, en: 'Description:', mr: 'तपशील / वर्णन:', hi: 'विवरण:'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _ticketDescCtrl,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'Describe the technical problem in detail...',
                                mr: 'तांत्रिक समस्येचे सविस्तर वर्णन लिहा...',
                                hi: 'तकनीकी समस्या का विस्तार से वर्णन करें...',
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _submitSupportTicket(),
                              child: Text(
                                AppTranslations.pick(lang, en: 'Submit Ticket', mr: 'तिकीट सबमिट करा', hi: 'टिकट सबमिट करें'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Tickets List
                  Expanded(
                    flex: 5,
                    child: Container(
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
                              en: 'Previous Support Tickets',
                              mr: 'मागील सपोर्ट तिकिटे',
                              hi: 'पिछले सहायता टिकट',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tickets.length,
                            separatorBuilder: (_, __) => const Divider(color: AppColors.slate100),
                            itemBuilder: (ctx, i) {
                              final t = _tickets[i];
                              final statusStr = t['status']?.toString() ?? 'Pending';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          AppTranslations.formatDigits(t['id']?.toString() ?? '', lang),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate500),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusStr == 'Resolved' ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            AppTranslations.getStatus(statusStr, lang),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: statusStr == 'Resolved' ? Colors.green : Colors.amber.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    AppTranslatedText(
                                      t['title']?.toString() ?? '',
                                      targetLanguage: lang,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppTranslations.formatDate(t['date'] as DateTime, lang),
                                      style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionItem(String device, String meta, String status, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.brandPrimary.withValues(alpha: 0.1) : AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCurrent ? Icons.computer_rounded : Icons.phone_iphone_rounded,
                  color: isCurrent ? AppColors.brandPrimary : AppColors.slate600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800)),
                  const SizedBox(height: 2),
                  Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.green.withValues(alpha: 0.1) : AppColors.slate100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.green : AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String key, String label, IconData icon) {
    final isSelected = _activeTab == key;
    return InkWell(
      onTap: () {
        setState(() => _activeTab = key);
        ref.read(desktopSettingsTabProvider.notifier).setTab(key);
      },
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
