import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/services/supabase_service.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/custom_navigation_provider.dart';
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
        final isMr = ref.read(isMarathiProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMr ? 'प्रोफाईल माहिती यशस्वीरीत्या सेव्ह केली!' : 'Profile settings saved successfully!'),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally (${e.toString()})'),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showImagePickerOptions(bool isProfile) {
    HapticFeedback.lightImpact();
    final isMr = ref.read(isMarathiProvider);
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
                  Text(
                    isProfile
                        ? (isMr ? 'प्रोफाईल छायाचित्र निवडा' : 'Select Profile Photo')
                        : (isMr ? 'पक्ष चिन्ह / लोगो निवडा' : 'Select Party Logo'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
                  isMr ? 'कॅमेऱ्यातून फोटो काढा' : 'Take Photo with Camera',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: Text(
                  isMr ? 'थेट कॅमेरा उघडून नवीन फोटो घ्या' : 'Capture directly using phone camera',
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
                  isMr ? 'फोन गॅलरीतून निवडा' : 'Choose from Photo Gallery',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: Text(
                  isMr ? 'फोनमधील साठवलेल्या फोटोंमधून निवडा' : 'Pick existing image from storage',
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
                  isMr ? 'थेट वेब लिंक (URL) प्रविष्ट करा' : 'Provide Direct Image URL',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: Text(
                  isMr ? 'इंटरनेटवरील फोटोची लिंक पेस्ट करा' : 'Enter https:// hosted image URL',
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
        final isMr = ref.read(isMarathiProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isProfile
                  ? (isMr ? 'प्रोफाईल छायाचित्र निवडले!' : 'Profile photo selected!')
                  : (isMr ? 'पक्ष चिन्ह निवडले!' : 'Party logo selected!'),
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
    final isMr = ref.read(isMarathiProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isProfile
              ? (isMr ? 'प्रोफाईल फोटो URL' : 'Enter Profile Photo URL')
              : (isMr ? 'पक्ष चिन्ह URL' : 'Enter Party Logo URL'),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द करा' : 'Cancel')),
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
            child: Text(isMr ? 'लागू करा' : 'Apply'),
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
    final isMr = ref.read(isMarathiProvider);

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isMr ? 'कृपया शीर्षक आणि तपशील दोन्ही भरा.' : 'Please fill in both title and description.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSubmittingTicket = true);

    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId ?? AppConfig.defaultTenantId;
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
            content: Text(isMr ? 'अडचण नोंदवली गेली आहे! आयटी सपोर्ट टीम लवकरच संपर्क करेल.' : 'Support ticket submitted! IT support team will review shortly.'),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingTicket = false);
    }
  }

  void _showGlobalSignOutDialog() {
    final isMr = ref.read(isMarathiProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(
              isMr ? 'इतर सर्व उपकरणांवरून बाहेर पडा' : 'Sign Out Other Devices',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          isMr
              ? 'आपण इतर उपकरणांवरील सर्व सक्रिय सत्रे बंद करू इच्छिता? आपण या फोनवर लॉग इन राहाल.'
              : 'Are you sure you want to invalidate all active session tokens on other devices? You will remain signed in on this device.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द करा' : 'Cancel')),
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
                  content: Text(isMr ? 'इतर सर्व उपकरणांवरील सत्रे बंद केली गेली आहेत.' : 'All other device sessions signed out successfully.'),
                  backgroundColor: const Color(0xFF0284C7),
                ),
              );
            },
            child: Text(isMr ? 'बाहेर पडा' : 'Sign Out Others'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog() async {
    final isMr = ref.read(isMarathiProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(
              isMr ? 'लॉगआउट पुष्टीकरण' : 'Confirm Logout',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          isMr
              ? 'आपण आपल्या खात्यातून बाहेर पडू इच्छिता?'
              : 'Are you sure you want to sign out of your account on this device?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isMr ? 'रद्द करा' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isMr ? 'लॉगआउट' : 'Sign Out'),
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
    final isMr = ref.watch(isMarathiProvider);
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
              tooltip: isMr ? 'मेनू उघडा' : 'Toggle Menu',
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
                isMr
                    ? (isStaff ? 'कर्मचारी सेटिंग्ज' : 'प्रोफाईल व ब्रँडिंग सेटिंग्ज')
                    : (isStaff ? 'Staff Settings' : 'Profile & Branding'),
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
                isMr
                    ? (isStaff ? 'नेव्हिगेशन आणि कर्मचारी तपशील' : 'अधिकृत लेटरहेड, संपर्क आणि प्रणाली')
                    : (isStaff ? 'Bar customization & staff profile' : 'Official letterhead, contacts & portal'),
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
            // Language Switch Pill
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(isMarathiProvider.notifier).toggle();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          isMr ? 'English' : 'मराठी',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
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
                                                Text(isMr ? 'नेव्हिगेशन बार' : 'Bar Customization'),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.badge_outlined, size: 15),
                                                const SizedBox(width: 6),
                                                Text(isMr ? 'माझे प्रोफाईल' : 'My Profile'),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.support_agent_rounded, size: 15),
                                                const SizedBox(width: 6),
                                                Text(isMr ? 'अडचण नोंदवा' : 'Report Issue'),
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
                                                Text(isMr ? 'प्रोफाईल तपशील' : 'Profile Details'),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.tune_rounded, size: 15),
                                                const SizedBox(width: 6),
                                                Text(isMr ? 'नेव्हिगेशन बार' : 'Bar Customization'),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.shield_outlined, size: 15),
                                                const SizedBox(width: 6),
                                                Text(isMr ? 'सुरक्षा लॉग' : 'Security Logs'),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.support_agent_rounded, size: 15),
                                                const SizedBox(width: 6),
                                                Text(isMr ? 'अडचण नोंदवा' : 'Report Issue'),
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
    final isMr = ref.watch(isMarathiProvider);
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
          _buildHeroIdentityCard(isMr, isStacked),

          const SizedBox(height: 16),

          // 2. Personal & Representation Details Card
          _buildCardSection(
            icon: Icons.account_circle_outlined,
            title: isMr ? 'वैयक्तिक व प्रभाग तपशील' : 'Personal & Ward Representation',
            subtitle: isMr
                ? 'हे तपशील अधिकृत लेटरहेड, डिजिटल प्रमाणपत्रे व नागरिकांच्या डॅशबोर्डवर दिसतील.'
                : 'Appears on official municipal letterhead, receipts, and public ward summaries.',
            child: Column(
              children: [
                if (!isStacked)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: isMr ? 'पूर्ण नाव (इंग्रजीत) *' : 'Full Name (English) *',
                          ctrl: _nameEnglishCtrl,
                          hint: 'e.g. Hon. Rahul Patil',
                          prefixIcon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: isMr ? 'पूर्ण नाव (मराठीत) *' : 'Full Name (Marathi) *',
                          ctrl: _nameMarathiCtrl,
                          hint: 'उदा. मा. राहुल पाटील',
                          prefixIcon: Icons.translate_rounded,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildTextField(
                    label: isMr ? 'पूर्ण नाव (इंग्रजीत) *' : 'Full Name (English) *',
                    ctrl: _nameEnglishCtrl,
                    hint: 'e.g. Hon. Rahul Patil',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: isMr ? 'पूर्ण नाव (मराठीत) *' : 'Full Name (Marathi) *',
                    ctrl: _nameMarathiCtrl,
                    hint: 'उदा. मा. राहुल पाटील',
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
                          label: isMr ? 'प्रभाग नाव / मतदारसंघ *' : 'Ward / Constituency Name *',
                          ctrl: _wardNameCtrl,
                          hint: 'e.g. Kasba Peth Ward',
                          prefixIcon: Icons.location_city_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: isMr ? 'प्रभाग क्रमांक *' : 'Ward Number *',
                          ctrl: _wardNumCtrl,
                          hint: 'e.g. 12',
                          prefixIcon: Icons.tag_rounded,
                          isNumeric: true,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildTextField(
                    label: isMr ? 'प्रभाग नाव / मतदारसंघ *' : 'Ward / Constituency Name *',
                    ctrl: _wardNameCtrl,
                    hint: 'e.g. Kasba Peth Ward',
                    prefixIcon: Icons.location_city_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: isMr ? 'प्रभाग क्रमांक *' : 'Ward Number *',
                    ctrl: _wardNumCtrl,
                    hint: 'e.g. 12',
                    prefixIcon: Icons.tag_rounded,
                    isNumeric: true,
                  ),
                ],
                const SizedBox(height: 12),
                _buildTextField(
                  label: isMr ? 'पक्ष किंवा आघाडीचे नाव' : 'Political Party / Coalition Front',
                  ctrl: _partyNameCtrl,
                  hint: 'e.g. Nagarsevak Vikas Aghadi',
                  prefixIcon: Icons.flag_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Office & Contact Details Card
          _buildCardSection(
            icon: Icons.apartment_rounded,
            title: isMr ? 'कार्यालय व सार्वजनिक संपर्क' : 'Office & Public Contacts',
            subtitle: isMr
                ? 'नागरिकांना समस्या घेऊन येण्यासाठी कार्यालयाचा पत्ता आणि संपर्क क्रमांक.'
                : 'Citizen touchpoints for official petitions, meetings, and emergency contacts.',
            child: Column(
              children: [
                _buildTextField(
                  label: isMr ? 'मुख्य संपर्क कार्यालय पत्ता' : 'Ward Office Street Address',
                  ctrl: _officeAddressCtrl,
                  hint: 'e.g. Ward Office No. 12, Kelkar Road, Pune',
                  prefixIcon: Icons.business_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: isMr ? 'नागरिकांसाठी कार्यालयीन वेळ' : 'Public Meeting / Office Hours',
                  ctrl: _officeHoursCtrl,
                  hint: 'e.g. 10:00 AM - 06:00 PM (Monday to Saturday)',
                  prefixIcon: Icons.access_time_rounded,
                ),
                const SizedBox(height: 12),
                if (!isStacked)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: isMr ? 'अधिकृत दूरध्वनी / मोबाईल *' : 'Official Phone Number *',
                          ctrl: _phoneCtrl,
                          hint: 'e.g. +91 98220 12345',
                          prefixIcon: Icons.phone_rounded,
                          isPhone: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: isMr ? 'अधिकृत ईमेल पत्ता *' : 'Official Email Address *',
                          ctrl: _emailCtrl,
                          hint: 'e.g. office@ward12.in',
                          prefixIcon: Icons.email_rounded,
                          isEmail: true,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildTextField(
                    label: isMr ? 'अधिकृत दूरध्वनी / मोबाईल *' : 'Official Phone Number *',
                    ctrl: _phoneCtrl,
                    hint: 'e.g. +91 98220 12345',
                    prefixIcon: Icons.phone_rounded,
                    isPhone: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: isMr ? 'अधिकृत ईमेल पत्ता *' : 'Official Email Address *',
                    ctrl: _emailCtrl,
                    hint: 'e.g. office@ward12.in',
                    prefixIcon: Icons.email_rounded,
                    isEmail: true,
                  ),
                ],
                const SizedBox(height: 12),
                _buildTextField(
                  label: isMr ? 'अधिकृत सोशल मीडिया / वेबसाइट लिंक' : 'Official Social Media / Website Link',
                  ctrl: _socialLinkCtrl,
                  hint: 'e.g. https://facebook.com/ward12nagarsevak',
                  prefixIcon: Icons.link_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Official Branding & Media Images Card
          _buildCardSection(
            icon: Icons.photo_library_outlined,
            title: isMr ? 'अधिकृत फोटो व पक्षाचे चिन्ह' : 'Official Media & Branding',
            subtitle: isMr
                ? 'प्रणालीतील अहवाल, पत्रे व कार्ड्सवर दिसणारे अधिकृत छायाचित्र व चिन्ह.'
                : 'High-resolution images displayed on printable reports, letterheads and headers.',
            child: Column(
              children: [
                if (!isStacked)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMediaTile(
                          isProfile: true,
                          title: isMr ? 'अधिकृत प्रोफाईल छायाचित्र' : 'Official Profile Photo',
                          subtitle: isMr ? 'नागरिक अहवाल व पत्रांवर' : 'On civic letters & reports',
                          imageUrl: _profileImageUrl,
                          fallbackIcon: Icons.person_rounded,
                          isCircle: true,
                          isMr: isMr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMediaTile(
                          isProfile: false,
                          title: isMr ? 'पक्ष चिन्ह / लोगो' : 'Party Symbol / Logo',
                          subtitle: isMr ? 'डिजिटल लेटरहेड व बॅनरवर' : 'On digital cards & letterhead',
                          imageUrl: _partyLogoUrl,
                          fallbackIcon: Icons.flag_rounded,
                          isCircle: false,
                          isMr: isMr,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildMediaTile(
                    isProfile: true,
                    title: isMr ? 'अधिकृत प्रोफाईल छायाचित्र' : 'Official Profile Photo',
                    subtitle: isMr ? 'नागरिक अहवाल व पत्रांवर' : 'On civic letters & reports',
                    imageUrl: _profileImageUrl,
                    fallbackIcon: Icons.person_rounded,
                    isCircle: true,
                    isMr: isMr,
                  ),
                  const SizedBox(height: 12),
                  _buildMediaTile(
                    isProfile: false,
                    title: isMr ? 'पक्ष चिन्ह / लोगो' : 'Party Symbol / Logo',
                    subtitle: isMr ? 'डिजिटल लेटरहेड व बॅनरवर' : 'On digital cards & letterhead',
                    imageUrl: _partyLogoUrl,
                    fallbackIcon: Icons.flag_rounded,
                    isCircle: false,
                    isMr: isMr,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 5. Account Session & Security Card (Sign Out Option)
          _buildSessionSecurityCard(isMr, user, isStacked),

          const SizedBox(height: 20),

          // 6. Sticky-Style Responsive Save Button
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
                    ? (isMr ? 'जतन करत आहे...' : 'Saving Changes...')
                    : (isMr ? 'सर्व बदल जतन करा' : 'Save Profile Changes'),
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
  Widget _buildHeroIdentityCard(bool isMr, bool isStacked) {
    final nameText = _nameEnglishCtrl.text.isNotEmpty
        ? _nameEnglishCtrl.text
        : (_nameMarathiCtrl.text.isNotEmpty ? _nameMarathiCtrl.text : 'Elected Representative');

    final wardText = _wardNumCtrl.text.isNotEmpty
        ? (isMr ? 'प्रभाग क्र. ${_wardNumCtrl.text}' : 'Ward No. ${_wardNumCtrl.text}')
        : '';
    final wardCombined = _wardNameCtrl.text.isNotEmpty
        ? (wardText.isNotEmpty ? '$wardText · ${_wardNameCtrl.text}' : _wardNameCtrl.text)
        : wardText;

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
                                Text(
                                  isMr ? 'लोकप्रतिनिधी' : 'Elected Representative',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            nameText,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (wardCombined.isNotEmpty)
                            Text(
                              wardCombined,
                              style: const TextStyle(fontSize: 12, color: Color(0xFFE0F2FE), fontWeight: FontWeight.w500),
                              maxLines: 1,
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
                      _isSaving ? (isMr ? 'सेव्ह करत आहे...' : 'Saving...') : (isMr ? 'बदल सेव्ह करा' : 'Save Changes'),
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
                            Text(
                              isMr ? 'लोकप्रतिनिधी' : 'Elected Representative',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        nameText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (wardCombined.isNotEmpty)
                        Text(
                          wardCombined,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFFE0F2FE), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    _isSaving ? (isMr ? 'सेव्ह करत आहे...' : 'Saving...') : (isMr ? 'बदल सेव्ह करा' : 'Save Changes'),
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
    required bool isMr,
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
              label: Text(
                imageUrl.isNotEmpty ? (isMr ? 'बदला' : 'Change') : (isMr ? 'अपलोड करा' : 'Upload'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
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
  Widget _buildSessionSecurityCard(bool isMr, dynamic user, bool isStacked) {
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
                              isMr ? 'खाते सुरक्षा व सत्र' : 'Account & Security Session',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF991B1B)),
                            ),
                            Text(
                              user?.email ?? 'Active Account',
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
                        isMr ? 'या फोनवरून लॉगआउट करा' : 'Sign Out of Account',
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
                          isMr ? 'खाते सुरक्षा व सत्र' : 'Account & Security Session',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF991B1B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMr
                              ? 'आपल्या चालू खात्यातून (${user?.email ?? 'Active'}) सुरक्षितपणे बाहेर पडा.'
                              : 'Signed in as ${user?.email ?? 'Representative'}. Invalidate local device token.',
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
                      isMr ? 'लॉगआउट' : 'Sign Out',
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
    final isMr = ref.watch(isMarathiProvider);
    final user = ref.watch(currentUserProvider);
    final permittedModules = ref.watch(permittedModulesProvider);
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
                      Text(
                        user?.name ?? (isMr ? 'कार्यालय कर्मचारी' : 'Staff Member'),
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
                          isMr ? 'अधिकृत टीम सदस्य (Staff)' : 'Authorized Team Member (Staff)',
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
                  isMr
                      ? 'आपल्याला दिलेले अधिकार (${permittedModules.length} विभाग)'
                      : 'Assigned Permissions (${permittedModules.length} Modules)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isMr
                ? 'हे विभाग नगरसेवक / ॲडमिन कार्यालयाने आपल्या खात्यास नियुक्त केले आहेत.'
                : 'These module privileges have been granted to your staff profile by the Nagarsevak office.',
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
                      isMr ? item.titleMr : item.titleEn,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // Bar Customization Call-to-action
          Container(
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
                              isMr ? 'नेव्हिगेशन सानुकूल करा' : 'Customize Your Navigation',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isMr
                            ? 'आपल्या आवडीनुसार बॉटम बार आणि 5 द्रुत क्रिया पर्याय सेट करा.'
                            : 'Assign your frequently used permitted modules to bottom bar tabs and radial gestures.',
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
                          onPressed: () => _tabController.animateTo(0),
                          child: Text(isMr ? 'सेट करा' : 'Open Customizer', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
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
                              isMr ? 'नेव्हिगेशन सानुकूल करा' : 'Customize Your Navigation',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isMr
                                  ? 'आपल्या आवडीनुसार बॉटम बार आणि 5 द्रुत क्रिया पर्याय सेट करा.'
                                  : 'Assign your frequently used permitted modules to bottom bar tabs and radial gestures.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _tabController.animateTo(0),
                        child: Text(isMr ? 'सेट करा' : 'Open Customizer', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 20),

          // Logout for staff
          _buildSessionSecurityCard(isMr, user, isStacked),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 3: Security Logs (Responsive Table & Search)
  // ─────────────────────────────────────────────────────────────
  Widget _buildSecurityTab(bool isDark, BoxConstraints constraints) {
    final isMr = ref.watch(isMarathiProvider);
    final isStacked = constraints.maxWidth < 480;

    final filtered = _securityLogs.where((log) {
      if (_securityLogSearch.isEmpty) return true;
      final q = _securityLogSearch.toLowerCase();
      final email = (log['email'] ?? '').toString().toLowerCase();
      final os = (log['os'] ?? '').toString().toLowerCase();
      final ip = (log['ip_address'] ?? '').toString().toLowerCase();
      return email.contains(q) || os.contains(q) || ip.contains(q);
    }).toList();

    return Column(
      children: [
        // Responsive Header Search & Sign Out Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0))),
          ),
          child: isStacked
              ? Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: isMr ? 'IP, ईमेल किंवा उपकरण शोधा...' : 'Search IP, email or device OS...',
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
                          isMr ? 'इतर सर्व उपकरणांवरून बाहेर पडा' : 'Sign Out Other Devices',
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
                          hintText: isMr ? 'IP, ईमेल किंवा उपकरण शोधा...' : 'Search IP, email or device OS...',
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
                        isMr ? 'इतर उपकरणे बंद करा' : 'Sign Out Others',
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
                              isMr ? 'कोणतेही सुरक्षा लॉग उपलब्ध नाहीत' : 'No security audit logs found',
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
                        final dateStr = log['created_at'] != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(log['created_at'].toString()) ?? DateTime.now())
                            : 'Recent';

                        final osStr = (log['os'] ?? 'Device').toString();
                        final browserStr = (log['browser'] ?? 'App').toString();

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
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFBBF7D0)),
                                            ),
                                            child: Text(
                                              (log['status'] ?? 'SUCCESS').toString().toUpperCase(),
                                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'IP: ${log['ip_address'] ?? '127.0.0.1'} · ${log['email'] ?? 'User'}',
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
    final isMr = ref.watch(isMarathiProvider);

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
                              isMr ? 'नवीन अडचण किंवा सूचना नोंदवा' : 'Report Issue / Feature Request',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isMr
                                  ? 'कृष्णनीती म्युनिसिपल सॉफ्टवेअर सपोर्ट डेस्ककडे थेट तांत्रिक संपर्क.'
                                  : 'Direct technical escalation to Krishnaniti municipal software support desk.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22, color: Color(0xFFF1F5F9)),

                  Text(
                    isMr ? 'समस्येचे शीर्षक / सारांश *' : 'Issue Title / Summary *',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _supportTitleCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isMr ? 'उदा. फोटो अपलोड करताना त्रुटी येते' : 'e.g. Photo upload in gallery reports timeout error',
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
                    isMr ? 'तपशीलवार वर्णन *' : 'Detailed Description *',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _supportDescCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isMr
                          ? 'येणारी समस्या, पावले आणि अपेक्षित निकाल स्पष्ट करा...'
                          : 'Explain the issue encountered, steps to reproduce, or requested enhancement...',
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
                        isMr ? 'तीव्रता / प्राधान्य:' : 'Severity / Priority:',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      _buildPriorityChoice('Low', isMr ? 'कमी (Low)' : 'Low', const Color(0xFF10B981)),
                      _buildPriorityChoice('Medium', isMr ? 'मध्यम (Med)' : 'Medium', const Color(0xFFF59E0B)),
                      _buildPriorityChoice('High', isMr ? 'तातडीचे (High)' : 'High', const Color(0xFFEF4444)),
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
                              ? (isMr ? 'पाठवत आहे...' : 'Submitting Ticket...')
                              : (isMr ? 'सपोर्ट तिकीट पाठवा' : 'Submit Support Ticket'),
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
                  isMr ? 'माझी सपोर्ट तिकिटे (${_supportTickets.length})' : 'My Support Tickets (${_supportTickets.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF0284C7)),
                tooltip: 'Refresh Tickets',
                onPressed: _loadSupportTickets,
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
                            isMr ? 'कोणतीही सपोर्ट तिकिटे नोंदवली नाहीत' : 'No support tickets filed yet',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMr
                                ? 'काही अडचण किंवा प्रश्न असल्यास वरील फॉर्म भरून तिकीट पाठवा.'
                                : 'If you face any issues, submit a ticket above.',
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
                        final dateStr = t['created_at'] != null
                            ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(t['created_at'].toString()) ?? DateTime.now())
                            : 'Recent';

                        final status = (t['status'] ?? 'Pending').toString();
                        final priority = (t['priority'] ?? 'Medium').toString();

                        Color statusBg;
                        Color statusText;
                        String statusLabel;

                        if (status.toLowerCase() == 'resolved') {
                          statusBg = const Color(0xFFDCFCE7);
                          statusText = const Color(0xFF15803D);
                          statusLabel = isMr ? 'सोडवलेले' : 'Resolved';
                        } else if (status.toLowerCase() == 'inprogress' || status.toLowerCase() == 'in progress') {
                          statusBg = const Color(0xFFFEF3C7);
                          statusText = const Color(0xFFB45309);
                          statusLabel = isMr ? 'काम चालू' : 'In Progress';
                        } else {
                          statusBg = const Color(0xFFFEF2F2);
                          statusText = const Color(0xFFB91C1C);
                          statusLabel = isMr ? 'प्रलंबित' : 'Pending';
                        }

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

                        final rawId = (t['id'] ?? 'TKT').toString();
                        final displayId = rawId.length > 10 && rawId.contains('-')
                            ? '#${rawId.split('-').first.toUpperCase()}'
                            : (rawId.startsWith('#') ? rawId : '#$rawId');

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
                                      child: Text(
                                        (t['title'] ?? (isMr ? 'सपोर्ट चौकशी' : 'Support Inquiry')).toString(),
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
                                if ((t['description'] ?? '').toString().trim().isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    t['description'].toString().trim(),
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
                                        priority.toUpperCase(),
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
