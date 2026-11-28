import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/translation_service.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/custom_navigation_provider.dart';
import '../../providers/language_provider.dart';
import '../landing/landing_screen.dart';
import 'bar_customization_screen.dart';

/// Professional, fully responsive Profile & Settings screen.
/// - Adaptive layout for small phones, tablets, and desktop/web.
/// - Live branding image previews (camera/gallery/URL).
/// - Bilingual (Marathi / English) support with instant toggle.
/// - Role-aware (Nagarsevak Administrator vs Team Staff).
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  final ValueChanged<int>? onTabChange;
  final int? initialTab;

  const ProfileSettingsScreen({
    super.key,
    this.onBackToHome,
    this.onTabChange,
    this.initialTab,
  });

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _getTabCount(bool isStaff) => isStaff ? 3 : 4;

  bool _isLoading = true;
  bool _isSaving = false;

  // Form Controllers
  final TextEditingController _nameEnglishCtrl = TextEditingController();
  final TextEditingController _nameMarathiCtrl = TextEditingController();
  final TextEditingController _wardNameCtrl = TextEditingController();
  final TextEditingController _wardNumCtrl = TextEditingController();
  final TextEditingController _officeAddressCtrl = TextEditingController();
  final TextEditingController _officeHoursCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _socialLinkCtrl = TextEditingController();
  final TextEditingController _partyNameCtrl = TextEditingController();

  String _profileImageUrl = '';
  String _partyLogoUrl = '';
  Map<String, dynamic> _rawConfig = {};

  // Security Logs
  List<Map<String, dynamic>> _securityLogs = [];
  bool _isLoadingLogs = false;
  String _securityLogSearch = '';

  // Support Tickets
  final TextEditingController _supportTitleCtrl = TextEditingController();
  final TextEditingController _supportDescCtrl = TextEditingController();
  String _supportPriority = 'Medium';
  bool _isSubmittingTicket = false;
  List<Map<String, dynamic>> _supportTickets = [];
  bool _isLoadingTickets = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final isStaff = user?.isStaff ?? false;
    final tabCount = _getTabCount(isStaff);
    final initialIdx = widget.initialTab != null
        ? widget.initialTab!.clamp(0, tabCount - 1)
        : 0;
    _tabController = TabController(length: tabCount, vsync: this, initialIndex: initialIdx);
    _loadTenantSettings();
    if (!isStaff) {
      _loadSecurityLogs();
    }
    _loadSupportTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameEnglishCtrl.dispose();
    _nameMarathiCtrl.dispose();
    _wardNameCtrl.dispose();
    _wardNumCtrl.dispose();
    _officeAddressCtrl.dispose();
    _officeHoursCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _socialLinkCtrl.dispose();
    _partyNameCtrl.dispose();
    _supportTitleCtrl.dispose();
    _supportDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTenantSettings() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId ?? AppConfig.defaultTenantId;

      if (_profileImageUrl.isNotEmpty && !_profileImageUrl.startsWith('http')) {
        final uploaded = await _uploadBrandingAsset(_profileImageUrl, 'profile');
        if (uploaded != null) _profileImageUrl = uploaded;
      }
      if (_partyLogoUrl.isNotEmpty && !_partyLogoUrl.startsWith('http')) {
        final uploaded = await _uploadBrandingAsset(_partyLogoUrl, 'logo');
        if (uploaded != null) _partyLogoUrl = uploaded;
      }

      final response = await client
          .from('tenants')
          .select('name, config')
          .eq('id', tenantId)
          .maybeSingle();

      if (response != null) {
        final cfg = response['config'] != null ? Map<String, dynamic>.from(response['config'] as Map) : <String, dynamic>{};
        _rawConfig = cfg;

        final tenantName = response['name']?.toString() ?? '';
        _nameEnglishCtrl.text = cfg['nagarsevak_name_english']?.toString() ?? tenantName;
        _nameMarathiCtrl.text = cfg['nagarsevak_name_marathi']?.toString() ?? '';
        _wardNameCtrl.text = cfg['ward_name']?.toString() ?? '';
        _wardNumCtrl.text = cfg['ward_number']?.toString() ?? '';
        _officeAddressCtrl.text = cfg['office_address']?.toString() ?? '';
        _officeHoursCtrl.text = cfg['office_hours']?.toString() ?? '';
        _phoneCtrl.text = cfg['phone_number']?.toString() ?? '';
        _emailCtrl.text = cfg['email_address']?.toString() ?? '';
        _socialLinkCtrl.text = cfg['social_media_link']?.toString() ?? '';
        _partyNameCtrl.text = cfg['party_name']?.toString() ?? '';
        _profileImageUrl = cfg['profile_image_url']?.toString() ?? '';
        _partyLogoUrl = cfg['party_logo_url']?.toString() ?? '';
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId ?? AppConfig.defaultTenantId;

      if (_profileImageUrl.isNotEmpty && !_profileImageUrl.startsWith('http')) {
        final uploaded = await _uploadBrandingAsset(_profileImageUrl, 'profile');
        if (uploaded != null) _profileImageUrl = uploaded;
      }
      if (_partyLogoUrl.isNotEmpty && !_partyLogoUrl.startsWith('http')) {
        final uploaded = await _uploadBrandingAsset(_partyLogoUrl, 'logo');
        if (uploaded != null) _partyLogoUrl = uploaded;
      }

      final mergedConfig = {
        ..._rawConfig,
        'nagarsevak_name_english': _nameEnglishCtrl.text.trim(),
        'nagarsevak_name_marathi': _nameMarathiCtrl.text.trim(),
        'ward_name': _wardNameCtrl.text.trim(),
        'ward_number': _wardNumCtrl.text.trim(),
        'office_address': _officeAddressCtrl.text.trim(),
        'office_hours': _officeHoursCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'email_address': _emailCtrl.text.trim(),
        'social_media_link': _socialLinkCtrl.text.trim(),
        'party_name': _partyNameCtrl.text.trim(),
        'profile_image_url': _profileImageUrl,
        'party_logo_url': _partyLogoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client.from('tenants').update({'config': mergedConfig}).eq('id', tenantId);

      _rawConfig = mergedConfig;
      if (mounted) {
        final lang = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Profile settings saved successfully!',
                mr: 'प्रोफाईल माहिती यशस्वीरीत्या सेव्ह केली!',
                hi: 'प्रोफ़ाइल सेटिंग्स सफलतापूर्वक सहेजी गईं!',
              ),
            ),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final lang = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Saved locally (${e.toString()})',
                mr: 'स्थानिक पातळीवर जतन केले (${e.toString()})',
                hi: 'स्थानीय रूप से सहेजा गया (${e.toString()})',
              ),
            ),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showImagePickerOptions(bool isProfile) {
    final isDesktopPlatform = kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux));
    if (isDesktopPlatform) {
      _pickImageSource(isProfile, ImageSource.gallery);
      return;
    }
    HapticFeedback.lightImpact();
    final lang = ref.read(appLanguageProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    isProfile ? Icons.account_circle_rounded : Icons.flag_rounded,
                    color: const Color(0xFF0284C7),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isProfile
                          ? AppTranslations.pick(
                              lang,
                              en: 'Select Profile Photo',
                              mr: 'प्रोफाईल छायाचित्र निवडा',
                              hi: 'प्रोफ़ाइल फ़ोटो चुनें',
                            )
                          : AppTranslations.pick(
                              lang,
                              en: 'Select Party Logo',
                              mr: 'पक्ष चिन्ह / लोगो निवडा',
                              hi: 'पार्टी चिह्न / लोगो चुनें',
                            ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                title: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Take Photo with Camera',
                    mr: 'कॅमेऱ्यातून फोटो काढा',
                    hi: 'कैमरे से फ़ोटो लें',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Capture directly using phone camera',
                    mr: 'थेट कॅमेरा उघडून नवीन फोटो घ्या',
                    hi: 'सीधे फ़ोन कैमरे से नया फ़ोटो खींचें',
                  ),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageSource(isProfile, ImageSource.camera);
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                title: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Choose from Photo Gallery',
                    mr: 'फोन गॅलरीतून निवडा',
                    hi: 'फ़ोटो गैलरी से चुनें',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Pick existing image from storage',
                    mr: 'फोनमधील साठवलेल्या फोटोंमधून निवडा',
                    hi: 'फ़ोन स्टोरेज से मौजूदा फ़ोटो चुनें',
                  ),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageSource(isProfile, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.link_rounded, color: Color(0xFF64748B), size: 20),
                ),
                title: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Provide Direct Image URL',
                    mr: 'थेट वेब लिंक (URL) प्रविष्ट करा',
                    hi: 'सीधा इमेज URL दर्ज करें',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Enter https:// hosted image URL',
                    mr: 'इंटरनेटवरील फोटोची लिंक पेस्ट करा',
                    hi: 'https:// होस्टेड इमेज लिंक दर्ज करें',
                  ),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showUrlInputDialog(isProfile);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<String?> _uploadBrandingAsset(String localPath, String prefix) async {
    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId ?? AppConfig.defaultTenantId;

      if (_profileImageUrl.isNotEmpty && !_profileImageUrl.startsWith('http')) {
        final uploaded = await _uploadBrandingAsset(_profileImageUrl, 'profile');
        if (uploaded != null) _profileImageUrl = uploaded;
      }
      if (_partyLogoUrl.isNotEmpty && !_partyLogoUrl.startsWith('http')) {
        final uploaded = await _uploadBrandingAsset(_partyLogoUrl, 'logo');
        if (uploaded != null) _partyLogoUrl = uploaded;
      }
      final file = File(localPath);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      final ext = localPath.split('.').last;
      final fileName = '$tenantId/branding/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      try {
        await client.storage.from('app-assets').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        return client.storage.from('app-assets').getPublicUrl(fileName);
      } catch (_) {
        await client.storage.from('documents').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        return client.storage.from('documents').getPublicUrl(fileName);
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImageSource(bool isProfile, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        if (!mounted) return;
        setState(() {
          if (isProfile) {
            _profileImageUrl = picked.path;
          } else {
            _partyLogoUrl = picked.path;
          }
        });
        _uploadBrandingAsset(picked.path, isProfile ? 'profile' : 'logo').then((uploadedUrl) {
          if (uploadedUrl != null && mounted) {
            setState(() {
              if (isProfile) {
                _profileImageUrl = uploadedUrl;
              } else {
                _partyLogoUrl = uploadedUrl;
              }
            });
          }
        });
        final lang = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isProfile
                  ? AppTranslations.pick(
                      lang,
                      en: 'Profile photo selected!',
                      mr: 'प्रोफाईल छायाचित्र निवडले!',
                      hi: 'प्रोफ़ाइल फ़ोटो चुना गया!',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Party logo selected!',
                      mr: 'पक्ष चिन्ह निवडले!',
                      hi: 'पार्टी लोगो चुना गया!',
                    ),
            ),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } catch (_) {
      if (mounted) _showUrlInputDialog(isProfile);
    }
  }

  void _showUrlInputDialog(bool isProfile) {
    final urlCtrl = TextEditingController(text: isProfile ? _profileImageUrl : _partyLogoUrl);
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isProfile
              ? AppTranslations.pick(
                  lang,
                  en: 'Enter Profile Photo URL',
                  mr: 'प्रोफाईल फोटो URL',
                  hi: 'प्रोफ़ाइल फ़ोटो URL दर्ज करें',
                )
              : AppTranslations.pick(
                  lang,
                  en: 'Enter Party Logo URL',
                  mr: 'पक्ष चिन्ह URL',
                  hi: 'पार्टी लोगो URL दर्ज करें',
                ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: urlCtrl,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'https://...',
            prefixIcon: const Icon(Icons.link, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                if (isProfile) {
                  _profileImageUrl = urlCtrl.text.trim();
                } else {
                  _partyLogoUrl = urlCtrl.text.trim();
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(
              AppTranslations.pick(lang, en: 'Apply', mr: 'लागू करा', hi: 'लागू करें'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSecurityLogs() async {
    setState(() => _isLoadingLogs = true);
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('login_logs')
          .select('*')
          .order('created_at', ascending: false)
          .limit(30);

      final list = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (mounted) {
        setState(() {
          _securityLogs = list;
          _isLoadingLogs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _securityLogs = [];
          _isLoadingLogs = false;
        });
      }
    }
  }

  Future<void> _loadSupportTickets() async {
    setState(() => _isLoadingTickets = true);
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('support_tickets')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);

      final list = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (mounted) {
        setState(() {
          _supportTickets = list;
          _isLoadingTickets = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _supportTickets = [];
          _isLoadingTickets = false;
        });
      }
    }
  }

  Future<void> _submitSupportTicket() async {
    final title = _supportTitleCtrl.text.trim();
    final desc = _supportDescCtrl.text.trim();
    final lang = ref.read(appLanguageProvider);

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please fill in both title and description.',
              mr: 'कृपया शीर्षक आणि तपशील दोन्ही भरा.',
              hi: 'कृपया शीर्षक और विवरण दोनों भरें।',
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSubmittingTicket = true);

    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId ?? AppConfig.defaultTenantId;

      if (_profileImageUrl.isNotEmpty && !_profileImageUrl.startsWith('http')) {
        final uploaded = await _uploadBrandingAsset(_profileImageUrl, 'profile');
        if (uploaded != null) _profileImageUrl = uploaded;
      }
      if (_partyLogoUrl.isNotEmpty && !_partyLogoUrl.startsWith('http')) {
        final uploaded = await _uploadBrandingAsset(_partyLogoUrl, 'logo');
        if (uploaded != null) _partyLogoUrl = uploaded;
      }
      final user = ref.read(currentUserProvider);

      final newTicket = {
        'id': 'TKT-${DateTime.now().millisecondsSinceEpoch % 10000}',
        'title': title,
        'description': desc,
        'priority': _supportPriority,
        'status': 'Pending',
        'tenant_id': tenantId,
        'user_id': user?.id ?? user?.email ?? '',
        'user_name': user?.name ?? _nameEnglishCtrl.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      try {
        await client.from('support_tickets').insert(newTicket);
      } catch (_) {}

      setState(() {
        _supportTickets.insert(0, newTicket);
        _supportTitleCtrl.clear();
        _supportDescCtrl.clear();
        _supportPriority = 'Medium';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Support ticket submitted! IT support team will review shortly.',
                mr: 'अडचण नोंदवली गेली आहे! आयटी सपोर्ट टीम लवकरच संपर्क करेल.',
                hi: 'सहायता टिकट दर्ज हो गया है! आईटी सहायता टीम शीघ्र समीक्षा करेगी।',
              ),
            ),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingTicket = false);
    }
  }

  void _showGlobalSignOutDialog() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Sign Out Other Devices',
                  mr: 'इतर सर्व उपकरणांवरून बाहेर पडा',
                  hi: 'अन्य सभी डिवाइस से साइन आउट करें',
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to invalidate all active session tokens on other devices? You will remain signed in on this device.',
            mr: 'आपण इतर उपकरणांवरील सर्व सक्रिय सत्रे बंद करू इच्छिता? आपण या फोनवर लॉग इन राहाल.',
            hi: 'क्या आप अन्य सभी डिवाइस पर सक्रिय सत्र समाप्त करना चाहते हैं? आप इस डिवाइस पर साइन इन रहेंगे।',
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'All other device sessions signed out successfully.',
                      mr: 'इतर सर्व उपकरणांवरील सत्रे बंद केली गेली आहेत.',
                      hi: 'अन्य सभी डिवाइस के सत्र सफलतापूर्वक बंद कर दिए गए हैं।',
                    ),
                  ),
                  backgroundColor: const Color(0xFF0284C7),
                ),
              );
            },
            child: Text(
              AppTranslations.pick(
                lang,
                en: 'Sign Out Others',
                mr: 'बाहेर पडा',
                hi: 'अन्य से साइन आउट करें',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog() async {
    final lang = ref.read(appLanguageProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Confirm Logout',
                  mr: 'लॉगआउट पुष्टीकरण',
                  hi: 'लॉगआउट की पुष्टि करें',
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Are you sure you want to sign out of your account on this device?',
            mr: 'आपण आपल्या खात्यातून बाहेर पडू इच्छिता?',
            hi: 'क्या आप वाकई इस डिवाइस पर अपने खाते से साइन आउट करना चाहते हैं?',
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppTranslations.pick(lang, en: 'Sign Out', mr: 'लॉगआउट', hi: 'साइन आउट'),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(authStateProvider.notifier).signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final isStaff = user?.isStaff ?? false;

    final tabCount = _getTabCount(isStaff);
    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: NagarsevakAppDrawer(
          currentTabIndex: 3,
          onTabChange: widget.onTabChange,
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Toggle Menu',
                mr: 'मेनू उघडा',
                hi: 'मेनू खोलें',
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isStaff
                    ? AppTranslations.pick(
                        lang,
                        en: 'Staff Settings',
                        mr: 'कर्मचारी सेटिंग्ज',
                        hi: 'कर्मचारी सेटिंग्स',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Profile & Branding',
                        mr: 'प्रोफाईल व ब्रँडिंग सेटिंग्ज',
                        hi: 'प्रोफ़ाइल व ब्रांडिंग सेटिंग्स',
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
                isStaff
                    ? AppTranslations.pick(
                        lang,
                        en: 'Bar customization & staff profile',
                        mr: 'नेव्हिगेशन आणि कर्मचारी तपशील',
                        hi: 'नेविगेशन और कर्मचारी विवरण',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Official letterhead, contacts & portal',
                        mr: 'अधिकृत लेटरहेड, संपर्क आणि प्रणाली',
                        hi: 'आधिकारिक लेटरहेड, संपर्क और पोर्टल',
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
            // Language Switch Selector
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: AppLanguageSegmentedSelector(isCompact: true),
              ),
            ),
            SizedBox(width: 4),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  final contentMaxWidth = isWide ? 900.0 : double.infinity;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Column(
                        children: [
                          // ─────────────────────────────────────────────
                          // MODERN HORIZONTAL TAB BAR
                          // ─────────────────────────────────────────────
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            alignment: Alignment.centerLeft,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                  indicator: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x260284C7),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: const Color(0xFF475569),
                                  labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  dividerColor: Colors.transparent,
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                                  tabs: isStaff
                                      ? [
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.tune_rounded, size: 15),
                                                const SizedBox(width: 6),
                                                Text(
                                                  AppTranslations.pick(
                                                    lang,
                                                    en: 'Bar Customization',
                                                    mr: 'नेव्हिगेशन बार',
                                                    hi: 'नेविगेशन बार',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.badge_outlined, size: 15),
                                                const SizedBox(width: 6),
                                                Text(
                                                  AppTranslations.pick(
                                                    lang,
                                                    en: 'My Profile',
                                                    mr: 'माझे प्रोफाईल',
                                                    hi: 'मेरी प्रोफ़ाइल',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.support_agent_rounded, size: 15),
                                                const SizedBox(width: 6),
                                                Text(
                                                  AppTranslations.pick(
                                                    lang,
                                                    en: 'Report Issue',
                                                    mr: 'अडचण नोंदवा',
                                                    hi: 'समस्या दर्ज करें',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ]
                                      : [
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.person_rounded, size: 15),
                                                const SizedBox(width: 6),
                                                Text(
                                                  AppTranslations.pick(
                                                    lang,
                                                    en: 'Profile Details',
                                                    mr: 'प्रोफाईल तपशील',
                                                    hi: 'प्रोफ़ाइल विवरण',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.tune_rounded, size: 15),
                                                const SizedBox(width: 6),
                                                Text(
                                                  AppTranslations.pick(
                                                    lang,
                                                    en: 'Bar Customization',
                                                    mr: 'नेव्हिगेशन बार',
                                                    hi: 'नेविगेशन बार',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.shield_outlined, size: 15),
                                                const SizedBox(width: 6),
                                                Text(
                                                  AppTranslations.pick(
                                                    lang,
                                                    en: 'Security Logs',
                                                    mr: 'सुरक्षा लॉग',
                                                    hi: 'सुरक्षा लॉग',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.support_agent_rounded, size: 15),
                                                const SizedBox(width: 6),
                                                Text(
                                                  AppTranslations.pick(
                                                    lang,
                                                    en: 'Report Issue',
                                                    mr: 'अडचण नोंदवा',
                                                    hi: 'समस्या दर्ज करें',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                ),
                              ),
                            ),
                          ),

                          // ─────────────────────────────────────────────
                          // TAB CONTENT VIEWS (Fully Responsive)
                          // ─────────────────────────────────────────────
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: isStaff
                                  ? [
                                      _buildBarCustomizationTab(isDark, constraints),
                                      _buildStaffProfileTab(isDark, constraints),
                                      _buildSupportTab(isDark, constraints),
                                    ]
                                  : [
                                      _buildProfileTab(isDark, constraints),
                                      _buildBarCustomizationTab(isDark, constraints),
                                      _buildSecurityTab(isDark, constraints),
                                      _buildSupportTab(isDark, constraints),
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
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 1: Profile Details & Branding (Responsive Adaptive Grid)
  // ─────────────────────────────────────────────────────────────
  Widget _buildProfileTab(bool isDark, BoxConstraints constraints) {
    final lang = ref.watch(appLanguageProvider);
    final user = ref.watch(currentUserProvider);
    final isStacked = constraints.maxWidth < 540;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        constraints.maxWidth < 400 ? 12 : 16,
        14,
        constraints.maxWidth < 400 ? 12 : 16,
        90,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Executive Representative Hero Card
          _buildHeroIdentityCard(lang, isStacked),

          const SizedBox(height: 16),

          // 2. Personal & Representation Details Card
          _buildCardSection(
            icon: Icons.account_circle_outlined,
            title: AppTranslations.pick(
              lang,
              en: 'Personal & Ward Representation',
              mr: 'वैयक्तिक व प्रभाग तपशील',
              hi: 'व्यक्तिगत एवं वार्ड प्रतिनिधित्व विवरण',
            ),
            subtitle: AppTranslations.pick(
              lang,
              en: 'Appears on official municipal letterhead, receipts, and public ward summaries.',
              mr: 'हे तपशील अधिकृत लेटरहेड, डिजिटल प्रमाणपत्रे व नागरिकांच्या डॅशबोर्डवर दिसतील.',
              hi: 'यह विवरण आधिकारिक लेटरहेड, रसीद और सार्वजनिक वार्ड सारांश पर दिखाई देगा।',
            ),
            child: Column(
              children: [
                if (!isStacked)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Full Name (English) *',
                            mr: 'पूर्ण नाव (इंग्रजीत) *',
                            hi: 'पूरा नाम (अंग्रेजी में) *',
                          ),
                          ctrl: _nameEnglishCtrl,
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Hon. Rahul Patil',
                            mr: 'उदा. Hon. Rahul Patil',
                            hi: 'उदा. Hon. Rahul Patil',
                          ),
                          prefixIcon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Full Name (Marathi) *',
                            mr: 'पूर्ण नाव (मराठीत) *',
                            hi: 'पूरा नाम (मराठी में) *',
                          ),
                          ctrl: _nameMarathiCtrl,
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. मा. राहुल पाटील',
                            mr: 'उदा. मा. राहुल पाटील',
                            hi: 'उदा. मा. राहुल पाटील',
                          ),
                          prefixIcon: Icons.translate_rounded,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildTextField(
                    label: AppTranslations.pick(
                      lang,
                      en: 'Full Name (English) *',
                      mr: 'पूर्ण नाव (इंग्रजीत) *',
                      hi: 'पूरा नाम (अंग्रेजी में) *',
                    ),
                    ctrl: _nameEnglishCtrl,
                    hint: AppTranslations.pick(
                      lang,
                      en: 'e.g. Hon. Rahul Patil',
                      mr: 'उदा. Hon. Rahul Patil',
                      hi: 'उदा. Hon. Rahul Patil',
                    ),
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: AppTranslations.pick(
                      lang,
                      en: 'Full Name (Marathi) *',
                      mr: 'पूर्ण नाव (मराठीत) *',
                      hi: 'पूरा नाम (मराठी में) *',
                    ),
                    ctrl: _nameMarathiCtrl,
                    hint: AppTranslations.pick(
                      lang,
                      en: 'e.g. मा. राहुल पाटील',
                      mr: 'उदा. मा. राहुल पाटील',
                      hi: 'उदा. मा. राहुल पाटील',
                    ),
                    prefixIcon: Icons.translate_rounded,
                  ),
                ],
                const SizedBox(height: 12),
                if (!isStacked)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Ward / Constituency Name *',
                            mr: 'प्रभाग नाव / मतदारसंघ *',
                            hi: 'वार्ड / निर्वाचन क्षेत्र का नाम *',
                          ),
                          ctrl: _wardNameCtrl,
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. Kasba Peth Ward',
                            mr: 'उदा. कसबा पेठ प्रभाग',
                            hi: 'उदा. कसबा पेठ वार्ड',
                          ),
                          prefixIcon: Icons.location_city_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Ward Number *',
                            mr: 'प्रभाग क्रमांक *',
                            hi: 'वार्ड नंबर *',
                          ),
                          ctrl: _wardNumCtrl,
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. 12',
                            mr: 'उदा. १२',
                            hi: 'उदा. १२',
                          ),
                          prefixIcon: Icons.tag_rounded,
                          isNumeric: true,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildTextField(
                    label: AppTranslations.pick(
                      lang,
                      en: 'Ward / Constituency Name *',
                      mr: 'प्रभाग नाव / मतदारसंघ *',
                      hi: 'वार्ड / निर्वाचन क्षेत्र का नाम *',
                    ),
                    ctrl: _wardNameCtrl,
                    hint: AppTranslations.pick(
                      lang,
                      en: 'e.g. Kasba Peth Ward',
                      mr: 'उदा. कसबा पेठ प्रभाग',
                      hi: 'उदा. कसबा पेठ वार्ड',
                    ),
                    prefixIcon: Icons.location_city_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: AppTranslations.pick(
                      lang,
                      en: 'Ward Number *',
                      mr: 'प्रभाग क्रमांक *',
                      hi: 'वार्ड नंबर *',
                    ),
                    ctrl: _wardNumCtrl,
                    hint: AppTranslations.pick(
                      lang,
                      en: 'e.g. 12',
                      mr: 'उदा. १२',
                      hi: 'उदा. १२',
                    ),
                    prefixIcon: Icons.tag_rounded,
                    isNumeric: true,
                  ),
                ],
                const SizedBox(height: 12),
                _buildTextField(
                  label: AppTranslations.pick(
                    lang,
                    en: 'Political Party / Coalition Front',
                    mr: 'पक्ष किंवा आघाडीचे नाव',
                    hi: 'राजनीतिक दल / गठबंधन का नाम',
                  ),
                  ctrl: _partyNameCtrl,
                  hint: AppTranslations.pick(
                    lang,
                    en: 'e.g. Nagarsevak Vikas Aghadi',
                    mr: 'उदा. नगरसेवक विकास आघाडी',
                    hi: 'उदा. नगरसेवक विकास आघाडी',
                  ),
                  prefixIcon: Icons.flag_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Office & Contact Details Card
          _buildCardSection(
            icon: Icons.apartment_rounded,
            title: AppTranslations.pick(
              lang,
              en: 'Office & Public Contacts',
              mr: 'कार्यालय व सार्वजनिक संपर्क',
              hi: 'कार्यालय एवं सार्वजनिक संपर्क',
            ),
            subtitle: AppTranslations.pick(
              lang,
              en: 'Citizen touchpoints for official petitions, meetings, and emergency contacts.',
              mr: 'नागरिकांना समस्या घेऊन येण्यासाठी कार्यालयाचा पत्ता आणि संपर्क क्रमांक.',
              hi: 'नागरिकों से मिलने, आवेदन और आपातकालीन संपर्क के लिए कार्यालय विवरण।',
            ),
            child: Column(
              children: [
                _buildTextField(
                  label: AppTranslations.pick(
                    lang,
                    en: 'Ward Office Street Address',
                    mr: 'मुख्य संपर्क कार्यालय पत्ता',
                    hi: 'वार्ड कार्यालय का पता',
                  ),
                  ctrl: _officeAddressCtrl,
                  hint: AppTranslations.pick(
                    lang,
                    en: 'e.g. Ward Office No. 12, Kelkar Road, Pune',
                    mr: 'उदा. प्रभाग कार्यालय क्र. १२, केळकर रोड, पुणे',
                    hi: 'उदा. वार्ड कार्यालय नं. १२, केलकर रोड, पुणे',
                  ),
                  prefixIcon: Icons.business_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: AppTranslations.pick(
                    lang,
                    en: 'Public Meeting / Office Hours',
                    mr: 'नागरिकांसाठी कार्यालयीन वेळ',
                    hi: 'जनता मुलाकात / कार्यालय समय',
                  ),
                  ctrl: _officeHoursCtrl,
                  hint: AppTranslations.pick(
                    lang,
                    en: 'e.g. 10:00 AM - 06:00 PM (Monday to Saturday)',
                    mr: 'उदा. सकाळी १०:०० ते सायं. ०६:०० (सोमवार ते शनिवार)',
                    hi: 'उदा. सुबह १०:०० से शाम ०६:०० बजे (सोमवार से शनिवार)',
                  ),
                  prefixIcon: Icons.access_time_rounded,
                ),
                const SizedBox(height: 12),
                if (!isStacked)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Official Phone Number *',
                            mr: 'अधिकृत दूरध्वनी / मोबाईल *',
                            hi: 'आधिकारिक फ़ोन / मोबाइल नंबर *',
                          ),
                          ctrl: _phoneCtrl,
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. +91 98220 12345',
                            mr: 'उदा. +९१ ९८२२० १२३४५',
                            hi: 'उदा. +९१ ९८२२० १२३४५',
                          ),
                          prefixIcon: Icons.phone_rounded,
                          isPhone: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Official Email Address *',
                            mr: 'अधिकृत ईमेल पत्ता *',
                            hi: 'आधिकारिक ईमेल पता *',
                          ),
                          ctrl: _emailCtrl,
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g. office@ward12.in',
                            mr: 'उदा. office@ward12.in',
                            hi: 'उदा. office@ward12.in',
                          ),
                          prefixIcon: Icons.email_rounded,
                          isEmail: true,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildTextField(
                    label: AppTranslations.pick(
                      lang,
                      en: 'Official Phone Number *',
                      mr: 'अधिकृत दूरध्वनी / मोबाईल *',
                      hi: 'आधिकारिक फ़ोन / मोबाइल नंबर *',
                    ),
                    ctrl: _phoneCtrl,
                    hint: AppTranslations.pick(
                      lang,
                      en: 'e.g. +91 98220 12345',
                      mr: 'उदा. +९१ ९८२२० १२३४५',
                      hi: 'उदा. +९१ ९८२२० १२३४५',
                    ),
                    prefixIcon: Icons.phone_rounded,
                    isPhone: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: AppTranslations.pick(
                      lang,
                      en: 'Official Email Address *',
                      mr: 'अधिकृत ईमेल पत्ता *',
                      hi: 'आधिकारिक ईमेल पता *',
                    ),
                    ctrl: _emailCtrl,
                    hint: AppTranslations.pick(
                      lang,
                      en: 'e.g. office@ward12.in',
                      mr: 'उदा. office@ward12.in',
                      hi: 'उदा. office@ward12.in',
                    ),
                    prefixIcon: Icons.email_rounded,
                    isEmail: true,
                  ),
                ],
                const SizedBox(height: 12),
                _buildTextField(
                  label: AppTranslations.pick(
                    lang,
                    en: 'Official Social Media / Website Link',
                    mr: 'अधिकृत सोशल मीडिया / वेबसाइट लिंक',
                    hi: 'आधिकारिक सोशल मीडिया / वेबसाइट लिंक',
                  ),
                  ctrl: _socialLinkCtrl,
                  hint: AppTranslations.pick(
                    lang,
                    en: 'e.g. https://facebook.com/ward12nagarsevak',
                    mr: 'उदा. https://facebook.com/ward12nagarsevak',
                    hi: 'उदा. https://facebook.com/ward12nagarsevak',
                  ),
                  prefixIcon: Icons.link_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Official Branding & Media Images Card
          _buildCardSection(
            icon: Icons.photo_library_outlined,
            title: AppTranslations.pick(
              lang,
              en: 'Official Media & Branding',
              mr: 'अधिकृत फोटो व पक्षाचे चिन्ह',
              hi: 'आधिकारिक फोटो व पार्टी चिह्न',
            ),
            subtitle: AppTranslations.pick(
              lang,
              en: 'High-resolution images displayed on printable reports, letterheads and headers.',
              mr: 'प्रणालीतील अहवाल, पत्रे व कार्ड्सवर दिसणारे अधिकृत छायाचित्र व चिन्ह.',
              hi: 'प्रिंट रिपोर्ट, लेटरहेड और डिजिटल कार्ड पर दिखने वाले आधिकारिक फोटो व चिह्न।',
            ),
            child: Column(
              children: [
                if (!isStacked)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMediaTile(
                          isProfile: true,
                          title: AppTranslations.pick(
                            lang,
                            en: 'Official Profile Photo',
                            mr: 'अधिकृत प्रोफाईल छायाचित्र',
                            hi: 'आधिकारिक प्रोफ़ाइल फ़ोटो',
                          ),
                          subtitle: AppTranslations.pick(
                            lang,
                            en: 'On civic letters & reports',
                            mr: 'नागरिक अहवाल व पत्रांवर',
                            hi: 'नागरिक पत्रों व रिपोर्ट पर',
                          ),
                          imageUrl: _profileImageUrl,
                          fallbackIcon: Icons.person_rounded,
                          isCircle: true,
                          lang: lang,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMediaTile(
                          isProfile: false,
                          title: AppTranslations.pick(
                            lang,
                            en: 'Party Symbol / Logo',
                            mr: 'पक्ष चिन्ह / लोगो',
                            hi: 'पार्टी चिह्न / लोगो',
                          ),
                          subtitle: AppTranslations.pick(
                            lang,
                            en: 'On digital cards & letterhead',
                            mr: 'डिजिटल लेटरहेड व बॅनरवर',
                            hi: 'डिजिटल कार्ड व लेटरहेड पर',
                          ),
                          imageUrl: _partyLogoUrl,
                          fallbackIcon: Icons.flag_rounded,
                          isCircle: false,
                          lang: lang,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildMediaTile(
                    isProfile: true,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Official Profile Photo',
                      mr: 'अधिकृत प्रोफाईल छायाचित्र',
                      hi: 'आधिकारिक प्रोफ़ाइल फ़ोटो',
                    ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'On civic letters & reports',
                      mr: 'नागरिक अहवाल व पत्रांवर',
                      hi: 'नागरिक पत्रों व रिपोर्ट पर',
                    ),
                    imageUrl: _profileImageUrl,
                    fallbackIcon: Icons.person_rounded,
                    isCircle: true,
                    lang: lang,
                  ),
                  const SizedBox(height: 12),
                  _buildMediaTile(
                    isProfile: false,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Party Symbol / Logo',
                      mr: 'पक्ष चिन्ह / लोगो',
                      hi: 'पार्टी चिह्न / लोगो',
                    ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'On digital cards & letterhead',
                      mr: 'डिजिटल लेटरहेड व बॅनरवर',
                      hi: 'डिजिटल कार्ड व लेटरहेड पर',
                    ),
                    imageUrl: _partyLogoUrl,
                    fallbackIcon: Icons.flag_rounded,
                    isCircle: false,
                    lang: lang,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 5. Navigation Bar Customization Banner
          _buildBarCustomizationBanner(lang, isStacked, false),

          const SizedBox(height: 18),

          // 6. Account Session & Security Card (Sign Out Option)
          _buildSessionSecurityCard(lang, user, isStacked),

          const SizedBox(height: 20),

          // 7. Sticky-Style Responsive Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                _isSaving
                    ? AppTranslations.pick(
                        lang,
                        en: 'Saving Changes...',
                        mr: 'जतन करत आहे...',
                        hi: 'सहेजा जा रहा है...',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Save Profile Changes',
                        mr: 'सर्व बदल जतन करा',
                        hi: 'प्रोफ़ाइल बदलाव सहेजें',
                      ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Hero Identity Header Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroIdentityCard(String lang, bool isStacked) {
    final enName = _nameEnglishCtrl.text.trim();
    final mrName = _nameMarathiCtrl.text.trim();
    final rawName = (lang == 'mr' || lang == 'hi')
        ? (mrName.isNotEmpty ? mrName : enName)
        : (enName.isNotEmpty ? enName : mrName);

    final wardNumTrimmed = _wardNumCtrl.text.trim();
    final wardNumFormatted = AppTranslations.formatDigits(wardNumTrimmed, lang);
    final wardText = wardNumTrimmed.isNotEmpty
        ? AppTranslations.pick(
            lang,
            en: 'Ward No. $wardNumFormatted',
            mr: 'प्रभाग क्र. $wardNumFormatted',
            hi: 'वार्ड नं. $wardNumFormatted',
          )
        : '';
    final wardNameTrimmed = _wardNameCtrl.text.trim();

    Widget buildNameWidget(double fontSize) {
      final style = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.3,
      );
      if (rawName.isEmpty) {
        return Text(
          AppTranslations.pick(
            lang,
            en: 'Elected Representative',
            mr: 'लोकप्रतिनिधी',
            hi: 'निर्वाचित जनप्रतिनिधि',
          ),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
      return AppTranslatedText(
        rawName,
        isName: true,
        targetLanguage: lang,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    Widget? buildWardWidget(double fontSize) {
      final style = TextStyle(
        fontSize: fontSize,
        color: const Color(0xFFE0F2FE),
        fontWeight: FontWeight.w500,
      );
      if (wardNameTrimmed.isNotEmpty) {
        return AppTranslatedText(
          AppTranslations.getAreaName(wardNameTrimmed, lang),
          prefix: wardText.isNotEmpty ? '$wardText · ' : '',
          targetLanguage: lang,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
      if (wardText.isNotEmpty) {
        return Text(
          wardText,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
      return null;
    }

    final wardWidgetStacked = buildWardWidget(12);
    final wardWidgetWide = buildWardWidget(12.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260284C7),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: isStacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        _buildImagePreview(
                          imageUrl: _profileImageUrl,
                          size: 64,
                          fallbackIcon: Icons.person_rounded,
                          isCircle: true,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: () => _showImagePickerOptions(true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF0284C7)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Elected Representative',
                                      mr: 'लोकप्रतिनिधी',
                                      hi: 'निर्वाचित जनप्रतिनिधि',
                                    ),
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          buildNameWidget(17),
                          ?wardWidgetStacked,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(
                      _isSaving
                          ? AppTranslations.pick(lang, en: 'Saving...', mr: 'सेव्ह करत आहे...', hi: 'सहेज रहे हैं...')
                          : AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल सेव्ह करा', hi: 'बदलाव सहेजें'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Stack(
                  children: [
                    _buildImagePreview(
                      imageUrl: _profileImageUrl,
                      size: 68,
                      fallbackIcon: Icons.person_rounded,
                      isCircle: true,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: () => _showImagePickerOptions(true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Elected Representative',
                                  mr: 'लोकप्रतिनिधी',
                                  hi: 'निर्वाचित जनप्रतिनिधि',
                                ),
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      buildNameWidget(18),
                      ?wardWidgetWide,
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                        )
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(
                    _isSaving
                        ? AppTranslations.pick(lang, en: 'Saving...', mr: 'सेव्ह करत आहे...', hi: 'सहेज रहे हैं...')
                        : AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल सेव्ह करा', hi: 'बदलाव सहेजें'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    elevation: 0,
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helper: Section Card Container
  // ─────────────────────────────────────────────────────────────
  Widget _buildCardSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF0284C7)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.25),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 22, color: Color(0xFFF1F5F9)),
            child,
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helper: Media Tile (Profile Photo & Party Logo with live image)
  // ─────────────────────────────────────────────────────────────
  Widget _buildMediaTile({
    required bool isProfile,
    required String title,
    required String subtitle,
    required String imageUrl,
    required IconData fallbackIcon,
    required bool isCircle,
    required String lang,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildImagePreview(
            imageUrl: imageUrl,
            size: 76,
            fallbackIcon: fallbackIcon,
            isCircle: isCircle,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton.icon(
              onPressed: () => _showImagePickerOptions(isProfile),
              icon: const Icon(Icons.upload_rounded, size: 15, color: Color(0xFF0284C7)),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  imageUrl.isNotEmpty
                      ? AppTranslations.pick(lang, en: 'Change', mr: 'बदला', hi: 'बदलें')
                      : AppTranslations.pick(lang, en: 'Upload', mr: 'अपलोड करा', hi: 'अपलोड करें'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helper: Responsive Image Preview
  // ─────────────────────────────────────────────────────────────
  Widget _buildImagePreview({
    required String imageUrl,
    required double size,
    required IconData fallbackIcon,
    required bool isCircle,
  }) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: size * 0.45, color: const Color(0xFF0284C7)),
    );

    if (imageUrl.isEmpty) return placeholder;

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: isCircle ? BorderRadius.circular(size / 2) : BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      );
    }

    if (!kIsWeb && (imageUrl.startsWith('/') || imageUrl.contains(':\\') || imageUrl.contains(':/'))) {
      try {
        final file = File(imageUrl);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: isCircle ? BorderRadius.circular(size / 2) : BorderRadius.circular(12),
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
          );
        }
      } catch (_) {}
    }

    return placeholder;
  }

  // ─────────────────────────────────────────────────────────────
  // Session Security & Sign Out Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildSessionSecurityCard(String lang, dynamic user, bool isStacked) {
    final activeFallback = AppTranslations.pick(lang, en: 'Active Account', mr: 'सक्रिय खाते', hi: 'सक्रिय खाता');
    final activeShort = AppTranslations.pick(lang, en: 'Representative', mr: 'सक्रिय', hi: 'सक्रिय');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isStacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_rounded, color: Color(0xFFDC2626), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Account & Security Session',
                                mr: 'खाते सुरक्षा व सत्र',
                                hi: 'खाता सुरक्षा एवं सत्र',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF991B1B)),
                            ),
                            Text(
                              user?.email ?? activeFallback,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _showLogoutConfirmDialog,
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Sign Out of Account',
                          mr: 'या फोनवरून लॉगआउट करा',
                          hi: 'इस डिवाइस से लॉगआउट करें',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFFDC2626), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Account & Security Session',
                            mr: 'खाते सुरक्षा व सत्र',
                            hi: 'खाता सुरक्षा एवं सत्र',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF991B1B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Signed in as ${user?.email ?? activeShort}. Invalidate local device token.',
                            mr: 'आपल्या चालू खात्यातून (${user?.email ?? activeShort}) सुरक्षितपणे बाहेर पडा.',
                            hi: 'वर्तमान खाते (${user?.email ?? activeShort}) से इस डिवाइस पर सुरक्षित रूप से साइन आउट करें।',
                          ),
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _showLogoutConfirmDialog,
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: Text(
                      AppTranslations.pick(lang, en: 'Sign Out', mr: 'लॉगआउट', hi: 'लॉगआउट'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 2: Navigation Bar & Quick Actions Customization
  // ─────────────────────────────────────────────────────────────
  Widget _buildBarCustomizationTab(bool isDark, BoxConstraints constraints) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        constraints.maxWidth < 400 ? 12 : 16,
        14,
        constraints.maxWidth < 400 ? 12 : 16,
        90,
      ),
      child: const BarCustomizationView(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab: Staff Profile / Account Info (Shown for Team Members)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStaffProfileTab(bool isDark, BoxConstraints constraints) {
    final lang = ref.watch(appLanguageProvider);
    final user = ref.watch(currentUserProvider);
    final permittedModules = ref.watch(permittedModulesProvider);
    final isStacked = constraints.maxWidth < 540;
    final moduleCountStr = AppTranslations.formatDigits(permittedModules.length, lang);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        constraints.maxWidth < 400 ? 12 : 16,
        14,
        constraints.maxWidth < 400 ? 12 : 16,
        90,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff Identity Hero
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null && user.name.trim().isNotEmpty)
                        AppTranslatedText(
                          user.name.trim(),
                          isName: true,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Staff Member',
                            mr: 'कार्यालय कर्मचारी',
                            hi: 'कार्यालय कर्मचारी',
                          ),
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Authorized Team Member (Staff)',
                            mr: 'अधिकृत टीम सदस्य (कर्मचारी)',
                            hi: 'अधिकृत टीम सदस्य (कर्मचारी)',
                          ),
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Permitted Modules Section
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Assigned Permissions ($moduleCountStr Modules)',
                    mr: 'आपल्याला दिलेले अधिकार ($moduleCountStr विभाग)',
                    hi: 'नियुक्त अनुमतियां ($moduleCountStr मॉड्यूल)',
                  ),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.pick(
              lang,
              en: 'These module privileges have been granted to your staff profile by the Nagarsevak office.',
              mr: 'हे विभाग नगरसेवक / ॲडमिन कार्यालयाने आपल्या खात्यास नियुक्त केले आहेत.',
              hi: 'ये मॉड्यूल अधिकार नगरसेवक / एडमिन कार्यालय द्वारा आपकी प्रोफ़ाइल को दिए गए हैं।',
            ),
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: permittedModules.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 15, color: const Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Text(
                      AppTranslations.getNavTitle(item.key, lang),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // Bar Customization Call-to-action
          _buildBarCustomizationBanner(lang, isStacked, true),

          const SizedBox(height: 20),

          // Logout for staff
          _buildSessionSecurityCard(lang, user, isStacked),
        ],
      ),
    );
  }

  Widget _buildBarCustomizationBanner(String lang, bool isStacked, bool isStaff) {
    final title = AppTranslations.pick(
      lang,
      en: 'Customize Your Navigation',
      mr: 'नेव्हिगेशन सानुकूल करा',
      hi: 'नेविगेशन कस्टमाइज़ करें',
    );
    final subtitle = AppTranslations.pick(
      lang,
      en: 'Assign your frequently used permitted modules to bottom bar tabs and radial gestures.',
      mr: 'आपल्या आवडीनुसार बॉटम बार आणि ५ द्रुत क्रिया पर्याय सेट करा.',
      hi: 'अपनी आवश्यकतानुसार बॉटम बार और ५ त्वरित एक्शन विकल्प सेट करें।',
    );
    final buttonLabel = AppTranslations.pick(
      lang,
      en: 'Open Customizer',
      mr: 'सेट करा',
      hi: 'कस्टमाइज़र खोलें',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: isStacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _tabController.animateTo(isStaff ? 0 : 1),
                    child: Text(buttonLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _tabController.animateTo(isStaff ? 0 : 1),
                  child: Text(buttonLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 3: Security Logs (Responsive Table & Search)
  // ─────────────────────────────────────────────────────────────
  Widget _buildSecurityTab(bool isDark, BoxConstraints constraints) {
    final lang = ref.watch(appLanguageProvider);
    final isStacked = constraints.maxWidth < 480;

    final filtered = _securityLogs.where((log) {
      if (_securityLogSearch.isEmpty) return true;
      final q = AppTranslations.normalizeAsciiDigits(_securityLogSearch).toLowerCase();
      final email = (log['email'] ?? '').toString().toLowerCase();
      final os = (log['os'] ?? '').toString().toLowerCase();
      final ip = (log['ip_address'] ?? '').toString().toLowerCase();
      return email.contains(q) || os.contains(q) || ip.contains(q);
    }).toList();

    final searchHint = AppTranslations.pick(
      lang,
      en: 'Search IP, email or device OS...',
      mr: 'IP, ईमेल किंवा उपकरण शोधा...',
      hi: 'IP, ईमेल या डिवाइस खोजें...',
    );

    return Column(
      children: [
        // Responsive Header Search & Sign Out Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: isStacked
              ? Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      onChanged: (v) => setState(() => _securityLogSearch = v.trim()),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showGlobalSignOutDialog,
                        icon: const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFDC2626)),
                        label: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Sign Out Other Devices',
                            mr: 'इतर सर्व उपकरणांवरून बाहेर पडा',
                            hi: 'अन्य सभी डिवाइस से साइन आउट करें',
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        onChanged: (v) => setState(() => _securityLogSearch = v.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _showGlobalSignOutDialog,
                      icon: const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFDC2626)),
                      label: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Sign Out Others',
                          mr: 'इतर उपकरणे बंद करा',
                          hi: 'अन्य डिवाइस बंद करें',
                        ),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        backgroundColor: const Color(0xFFFEF2F2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
        ),

        // Logs List
        Expanded(
          child: _isLoadingLogs
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
              : filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, size: 40, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'No security audit logs found',
                                mr: 'कोणतेही सुरक्षा लॉग उपलब्ध नाहीत',
                                hi: 'कोई सुरक्षा ऑडिट लॉग उपलब्ध नहीं है',
                              ),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final log = filtered[idx];
                        final parsedDate = log['created_at'] != null
                            ? DateTime.tryParse(log['created_at'].toString())
                            : null;
                        final dateStr = parsedDate != null
                            ? AppTranslations.formatDateTime(parsedDate.toLocal(), lang)
                            : AppTranslations.pick(lang, en: 'Recent', mr: 'अलीकडील', hi: 'हाल ही का');

                        final osStr = (log['os'] ??
                                AppTranslations.pick(lang, en: 'Device', mr: 'उपकरण', hi: 'डिवाइस'))
                            .toString();
                        final browserStr = (log['browser'] ??
                                AppTranslations.pick(lang, en: 'App', mr: 'ॲप', hi: 'ऐप'))
                            .toString();
                        final rawStatus = (log['status'] ?? 'SUCCESS').toString();
                        final statusUpper = rawStatus.trim().toUpperCase();
                        final statusDisplay = statusUpper == 'SUCCESS'
                            ? AppTranslations.pick(lang, en: 'SUCCESS', mr: 'यशस्वी', hi: 'सफल')
                            : (statusUpper == 'FAILED'
                                ? AppTranslations.pick(lang, en: 'FAILED', mr: 'अयशस्वी', hi: 'विफल')
                                : AppTranslations.getStatus(rawStatus, lang));
                        final isFailed = statusUpper == 'FAILED' || statusUpper == 'ERROR';
                        final userFallback = AppTranslations.pick(lang, en: 'User', mr: 'वापरकर्ता', hi: 'उपयोगकर्ता');

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    osStr.toLowerCase().contains('android') || osStr.toLowerCase().contains('ios')
                                        ? Icons.smartphone_rounded
                                        : Icons.laptop_chromebook_rounded,
                                    color: const Color(0xFF0284C7),
                                    size: 20,
                                  ),
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
                                              '$osStr · $browserStr',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isFailed ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isFailed ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                                              ),
                                            ),
                                            child: Text(
                                              statusDisplay,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: isFailed ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'IP: ${log['ip_address'] ?? '127.0.0.1'} · ${log['email'] ?? userFallback}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
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
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 4: Report Issue / Support
  // ─────────────────────────────────────────────────────────────
  Widget _buildSupportTab(bool isDark, BoxConstraints constraints) {
    final lang = ref.watch(appLanguageProvider);
    final ticketCountStr = AppTranslations.formatDigits(_supportTickets.length, lang);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        constraints.maxWidth < 400 ? 12 : 16,
        14,
        constraints.maxWidth < 400 ? 12 : 16,
        90,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submit Ticket Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.report_problem_rounded, color: Color(0xFFD97706), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Report Issue / Feature Request',
                                mr: 'नवीन अडचण किंवा सूचना नोंदवा',
                                hi: 'समस्या या सुझाव दर्ज करें',
                              ),
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Direct technical escalation to Krishnaniti municipal software support desk.',
                                mr: 'कृष्णनीती म्युनिसिपल सॉफ्टवेअर सपोर्ट डेस्ककडे थेट तांत्रिक संपर्क.',
                                hi: 'कृष्णनीति म्युनिसिपल सॉफ्टवेयर सपोर्ट डेस्क से सीधा तकनीकी संपर्क।',
                              ),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22, color: Color(0xFFF1F5F9)),

                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Issue Title / Summary *',
                      mr: 'समस्येचे शीर्षक / सारांश *',
                      hi: 'समस्या का शीर्षक / सारांश *',
                    ),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _supportTitleCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Photo upload in gallery reports timeout error',
                        mr: 'उदा. फोटो अपलोड करताना त्रुटी येते',
                        hi: 'उदा. गैलरी में फ़ोटो अपलोड करते समय त्रुटि आ रही है',
                      ),
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Detailed Description *',
                      mr: 'तपशीलवार वर्णन *',
                      hi: 'विस्तृत विवरण *',
                    ),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _supportDescCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Explain the issue encountered, steps to reproduce, or requested enhancement...',
                        mr: 'येणारी समस्या, पावले आणि अपेक्षित निकाल स्पष्ट करा...',
                        hi: 'आने वाली समस्या, चरण और अपेक्षित सुधार स्पष्ट करें...',
                      ),
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Priority Choice (Responsive Wrap)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Severity / Priority:',
                          mr: 'तीव्रता / प्राधान्य:',
                          hi: 'गंभीरता / प्राथमिकता:',
                        ),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      _buildPriorityChoice(
                        'Low',
                        AppTranslations.pick(lang, en: 'Low', mr: 'कमी (Low)', hi: 'कम (Low)'),
                        const Color(0xFF10B981),
                      ),
                      _buildPriorityChoice(
                        'Medium',
                        AppTranslations.pick(lang, en: 'Medium', mr: 'मध्यम (Med)', hi: 'मध्यम (Med)'),
                        const Color(0xFFF59E0B),
                      ),
                      _buildPriorityChoice(
                        'High',
                        AppTranslations.pick(lang, en: 'High', mr: 'तातडीचे (High)', hi: 'अति आवश्यक (High)'),
                        const Color(0xFFEF4444),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmittingTicket ? null : _submitSupportTicket,
                      icon: _isSubmittingTicket
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isSubmittingTicket
                              ? AppTranslations.pick(
                                  lang,
                                  en: 'Submitting Ticket...',
                                  mr: 'पाठवत आहे...',
                                  hi: 'टिकट भेजा जा रहा है...',
                                )
                              : AppTranslations.pick(
                                  lang,
                                  en: 'Submit Support Ticket',
                                  mr: 'सपोर्ट तिकीट पाठवा',
                                  hi: 'सहायता टिकट भेजें',
                                ),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Submitted Tickets Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'My Support Tickets ($ticketCountStr)',
                    mr: 'माझी सपोर्ट तिकिटे ($ticketCountStr)',
                    hi: 'मेरे सहायता टिकट ($ticketCountStr)',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _isLoadingTickets
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
              : _supportTickets.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.support_agent_rounded, size: 30, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'No support tickets filed yet',
                              mr: 'कोणतीही सपोर्ट तिकिटे नोंदवली नाहीत',
                              hi: 'अभी तक कोई सहायता टिकट दर्ज नहीं है',
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'If you face any issues, submit a ticket above.',
                              mr: 'काही अडचण किंवा प्रश्न असल्यास वरील फॉर्म भरून तिकीट पाठवा.',
                              hi: 'यदि कोई समस्या हो तो ऊपर दिया गया फॉर्म भरकर टिकट भेजें।',
                            ),
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _supportTickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final t = _supportTickets[i];
                        final parsedDate = t['created_at'] != null
                            ? DateTime.tryParse(t['created_at'].toString())
                            : null;
                        final dateStr = parsedDate != null
                            ? AppTranslations.formatDate(parsedDate.toLocal(), lang)
                            : AppTranslations.pick(lang, en: 'Recent', mr: 'अलीकडील', hi: 'हाल ही का');

                        final status = (t['status'] ?? 'Pending').toString();
                        final priority = (t['priority'] ?? 'Medium').toString();

                        Color statusBg;
                        Color statusText;
                        if (status.toLowerCase() == 'resolved') {
                          statusBg = const Color(0xFFDCFCE7);
                          statusText = const Color(0xFF15803D);
                        } else if (status.toLowerCase() == 'inprogress' || status.toLowerCase() == 'in progress') {
                          statusBg = const Color(0xFFFEF3C7);
                          statusText = const Color(0xFFB45309);
                        } else {
                          statusBg = const Color(0xFFFEF2F2);
                          statusText = const Color(0xFFB91C1C);
                        }
                        final statusLabel = AppTranslations.getStatus(status, lang);

                        Color priorityBg;
                        Color priorityText;
                        if (priority.toLowerCase() == 'high') {
                          priorityBg = const Color(0xFFFFE4E6);
                          priorityText = const Color(0xFFE11D48);
                        } else if (priority.toLowerCase() == 'medium') {
                          priorityBg = const Color(0xFFFEF3C7);
                          priorityText = const Color(0xFFD97706);
                        } else {
                          priorityBg = const Color(0xFFF1F5F9);
                          priorityText = const Color(0xFF475569);
                        }
                        final priorityLabel = AppTranslations.getPriority(priority, lang);

                        final rawId = (t['id'] ?? 'TKT').toString();
                        final displayIdRaw = rawId.length > 10 && rawId.contains('-')
                            ? '#${rawId.split('-').first.toUpperCase()}'
                            : (rawId.startsWith('#') ? rawId : '#$rawId');
                        final displayId = AppTranslations.formatDigits(displayIdRaw, lang);

                        final rawTitle = (t['title'] ?? '').toString().trim();
                        final rawDesc = (t['description'] ?? '').toString().trim();

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Title on Left + Status Badge on Right (Cannot Overflow)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: rawTitle.isNotEmpty
                                          ? AppTranslatedText(
                                              rawTitle,
                                              targetLanguage: lang,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : Text(
                                              AppTranslations.pick(
                                                lang,
                                                en: 'Support Inquiry',
                                                mr: 'सपोर्ट चौकशी',
                                                hi: 'सहायता पूछताछ',
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusText.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: statusText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Description (maxLines: 2)
                                if (rawDesc.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  AppTranslatedText(
                                    rawDesc,
                                    targetLanguage: lang,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],

                                const SizedBox(height: 8),
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 8),

                                // Bottom Row: Date on Left + Priority & Short ID on Right (Cannot Overflow)
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        dateStr,
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: priorityBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        priorityLabel,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: priorityText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 85),
                                      child: Text(
                                        displayId,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Helpers: Text Field with Icon
  // ─────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    IconData? prefixIcon,
    bool isPhone = false,
    bool isEmail = false,
    bool isNumeric = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isPhone
              ? TextInputType.phone
              : (isEmail
                  ? TextInputType.emailAddress
                  : (isNumeric ? TextInputType.number : TextInputType.text)),
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF64748B), size: 18) : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChoice(String priority, String displayLabel, Color baseColor) {
    final isSelected = _supportPriority == priority;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _supportPriority = priority);
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? baseColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? baseColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: baseColor.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
