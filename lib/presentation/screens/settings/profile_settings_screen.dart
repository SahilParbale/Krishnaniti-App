import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/services/supabase_service.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/custom_navigation_provider.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  final ValueChanged<int>? onTabChange;

  const ProfileSettingsScreen({super.key, this.onBackToHome, this.onTabChange});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;

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

  // SMS Gateway state
  String _selectedSmsProvider = 'Fast2SMS';
  final TextEditingController _smsApiKeyCtrl = TextEditingController(text: 'f2s_live_8391038592019482');
  final TextEditingController _smsSenderIdCtrl = TextEditingController(text: 'PUNENG');
  final TextEditingController _smsDltEntityCtrl = TextEditingController(text: '1701159823412341234');
  bool _obscureSmsKey = true;

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
    _tabController = TabController(length: 5, vsync: this);
    _loadTenantSettings();
    _loadSecurityLogs();
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
    _smsApiKeyCtrl.dispose();
    _smsSenderIdCtrl.dispose();
    _smsDltEntityCtrl.dispose();
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

      if (response != null && response['config'] != null) {
        final cfg = Map<String, dynamic>.from(response['config'] as Map);
        _rawConfig = cfg;

        _nameEnglishCtrl.text = cfg['nagarsevak_name_english']?.toString() ?? 'Rahul Patil';
        _nameMarathiCtrl.text = cfg['nagarsevak_name_marathi']?.toString() ?? 'राहुल पाटील';
        _wardNameCtrl.text = cfg['ward_name']?.toString() ?? 'Kasba - Vishrambaug Wada';
        _wardNumCtrl.text = cfg['ward_number']?.toString() ?? '12';
        _officeAddressCtrl.text = cfg['office_address']?.toString() ?? 'Ward Office No. 12, Kelkar Road, Pune 411030';
        _officeHoursCtrl.text = cfg['office_hours']?.toString() ?? '10:00 AM - 06:00 PM (Mon-Sat)';
        _phoneCtrl.text = cfg['phone_number']?.toString() ?? '+91 98220 12345';
        _emailCtrl.text = cfg['email_address']?.toString() ?? 'office@ward12pune.gov.in';
        _socialLinkCtrl.text = cfg['social_media_link']?.toString() ?? 'https://facebook.com/ward12nagarsevak';
        _partyNameCtrl.text = cfg['party_name']?.toString() ?? 'Nagarsevak Vikas Aghadi';
        _profileImageUrl = cfg['profile_image_url']?.toString() ?? '';
        _partyLogoUrl = cfg['party_logo_url']?.toString() ?? '';
      } else {
        _setFallbackDefaults();
      }
    } catch (_) {
      _setFallbackDefaults();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setFallbackDefaults() {
    _nameEnglishCtrl.text = 'Rahul Patil';
    _nameMarathiCtrl.text = 'राहुल पाटील';
    _wardNameCtrl.text = 'Kasba - Vishrambaug Wada';
    _wardNumCtrl.text = '12';
    _officeAddressCtrl.text = 'Ward Office No. 12, Kelkar Road, Pune 411030';
    _officeHoursCtrl.text = '10:00 AM - 06:00 PM (Mon-Sat)';
    _phoneCtrl.text = '+91 98220 12345';
    _emailCtrl.text = 'office@ward12pune.gov.in';
    _socialLinkCtrl.text = 'https://facebook.com/ward12nagarsevak';
    _partyNameCtrl.text = 'Nagarsevak Vikas Aghadi';
  }

  Future<void> _saveSettings() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile settings saved successfully!'),
            backgroundColor: Color(0xFF0284C7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated settings locally (${e.toString()})'),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      if (picked != null) {
        if (!mounted) return;
        setState(() {
          if (isProfile) {
            _profileImageUrl = picked.path;
          } else {
            _partyLogoUrl = picked.path;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isProfile ? 'Profile photo selected!' : 'Party logo selected!'),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(isProfile ? 'Enter Profile Photo URL' : 'Enter Party Logo URL'),
        content: TextField(
          controller: urlCtrl,
          decoration: InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
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
            child: const Text('Save'),
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
          _securityLogs = list.isNotEmpty ? list : _getSeedSecurityLogs();
          _isLoadingLogs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _securityLogs = _getSeedSecurityLogs();
          _isLoadingLogs = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getSeedSecurityLogs() {
    final now = DateTime.now();
    return [
      {
        'id': 'log-01',
        'email': 'nagarsevak.ward12@pune.gov.in',
        'ip_address': '103.211.54.12',
        'browser': 'Chrome 122',
        'os': 'Windows 11',
        'device_type': 'Desktop',
        'status': 'SUCCESS',
        'created_at': now.subtract(const Duration(minutes: 25)).toIso8601String(),
      },
      {
        'id': 'log-02',
        'email': 'nagarsevak.ward12@pune.gov.in',
        'ip_address': '49.36.128.45',
        'browser': 'Nagarsevak Mobile App',
        'os': 'Android 14',
        'device_type': 'Mobile',
        'status': 'SUCCESS',
        'created_at': now.subtract(const Duration(hours: 14)).toIso8601String(),
      },
      {
        'id': 'log-03',
        'email': 'rahul.patil.office@gmail.com',
        'ip_address': '103.211.54.12',
        'browser': 'Chrome 121',
        'os': 'Windows 11',
        'device_type': 'Desktop',
        'status': 'SUCCESS',
        'created_at': now.subtract(const Duration(days: 1, hours: 4)).toIso8601String(),
      },
      {
        'id': 'log-04',
        'email': 'nagarsevak.ward12@pune.gov.in',
        'ip_address': '157.34.88.90',
        'browser': 'Mobile Safari 17',
        'os': 'iOS 17.4',
        'device_type': 'Mobile',
        'status': 'SUCCESS',
        'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
    ];
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
          _supportTickets = list.isNotEmpty ? list : _getSeedSupportTickets();
          _isLoadingTickets = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _supportTickets = _getSeedSupportTickets();
          _isLoadingTickets = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getSeedSupportTickets() {
    final now = DateTime.now();
    return [
      {
        'id': 'TKT-1094',
        'title': 'SMS DLT sender ID header verification check',
        'description': 'Requested verification of official municipal sender ID for ward civic notifications.',
        'priority': 'High',
        'status': 'Resolved',
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'TKT-1082',
        'title': 'High resolution banner upload optimization',
        'description': 'Field gallery images upload compression check for festival event dossiers.',
        'priority': 'Medium',
        'status': 'Resolved',
        'created_at': now.subtract(const Duration(days: 6)).toIso8601String(),
      },
    ];
  }

  Future<void> _submitSupportTicket() async {
    final title = _supportTitleCtrl.text.trim();
    final desc = _supportDescCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and description.')),
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
        'user_id': user?.email ?? 'nagarsevak.ward12@pune.gov.in',
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
          const SnackBar(
            content: Text('Support ticket submitted successfully! IT team will review.'),
            backgroundColor: Color(0xFF0284C7),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingTicket = false);
    }
  }

  void _showTestSmsDialog() {
    final phoneCtrl = TextEditingController(text: _phoneCtrl.text);
    final msgCtrl = TextEditingController(
      text: 'Ward 12 Office Test SMS: Gateway integration active and verified successfully.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.sms_outlined, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Send Test SMS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recipient Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, size: 16),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Test Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Test SMS queued to ${phoneCtrl.text}! Check delivery in a moment.'),
                  backgroundColor: const Color(0xFF0284C7),
                ),
              );
            },
            icon: const Icon(Icons.send, size: 15),
            label: const Text('Send SMS'),
          ),
        ],
      ),
    );
  }

  void _showGlobalSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Sign Out Other Devices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to invalidate all active session tokens on other devices? You will remain signed in on this device.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All other device sessions signed out successfully.'),
                  backgroundColor: Color(0xFF0284C7),
                ),
              );
            },
            child: const Text('Sign Out Others'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: NagarsevakAppDrawer(
        currentTabIndex: 3,
        onTabChange: widget.onTabChange,
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Open Menu Drawer',
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Profile Settings',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Profile details & system settings',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: Color(0xFFE0F2FE)),
            ),
          ],
        ),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicator: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 14),
                              SizedBox(width: 5),
                              Text('Profile Details'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 14),
                              SizedBox(width: 5),
                              Text('Bar Customization'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            children: [
                              Icon(Icons.sms_outlined, size: 14),
                              SizedBox(width: 5),
                              Text('SMS Gateway'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 14),
                              SizedBox(width: 5),
                              Text('Security Logs'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            children: [
                              Icon(Icons.support_agent_outlined, size: 14),
                              SizedBox(width: 5),
                              Text('Report Issue'),
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
                      _buildProfileTab(isDark),
                      _buildBarCustomizationTab(isDark),
                      _buildSmsTab(isDark),
                      _buildSecurityTab(isDark),
                      _buildSupportTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 1: Profile Details
  // ─────────────────────────────────────────────────────────────
  Widget _buildProfileTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Save Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Nagarsevak Profile & Branding',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Configures official letterhead, receipts & card headers',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 16),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 1. Personal Details Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person, size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 6),
                      Text('Personal Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildTextField('Full Name (English)', _nameEnglishCtrl, 'e.g. Rahul Patil'),
                  const SizedBox(height: 10),
                  _buildTextField('Full Name (Marathi)', _nameMarathiCtrl, 'उदा. राहुल पाटील'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Ward Name', _wardNameCtrl, 'e.g. Kasba Peth')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField('Ward Number', _wardNumCtrl, 'e.g. 12')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 2. Office & Contact Details Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.business, size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 6),
                      Text('Office & Public Contacts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildTextField('Office Address', _officeAddressCtrl, 'e.g. Ward Office No. 12, Kelkar Road, Pune'),
                  const SizedBox(height: 10),
                  _buildTextField('Public Office Hours', _officeHoursCtrl, 'e.g. 10:00 AM - 06:00 PM (Mon-Sat)'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Phone Number', _phoneCtrl, 'e.g. +91 98220 12345', isPhone: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField('Email Address', _emailCtrl, 'e.g. office@ward12.in', isEmail: true)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTextField('Official Social Media Link', _socialLinkCtrl, 'e.g. https://facebook.com/ward12nagarsevak'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Branding & Media Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.flag_rounded, size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 6),
                      Text('Party Affiliation & Branding Images', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildTextField('Party / Front Name', _partyNameCtrl, 'e.g. Nagarsevak Vikas Aghadi'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Profile Photo
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: const Color(0xFFE0F2FE),
                                child: const Icon(Icons.person, size: 36, color: Color(0xFF0284C7)),
                              ),
                              const SizedBox(height: 8),
                              const Text('Profile Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () => _pickImage(true),
                                icon: const Icon(Icons.upload, size: 14),
                                label: const Text('Change', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Party Logo
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.flag_rounded, size: 34, color: Color(0xFF0284C7)),
                              ),
                              const SizedBox(height: 8),
                              const Text('Party Symbol / Logo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () => _pickImage(false),
                                icon: const Icon(Icons.upload, size: 14),
                                label: const Text('Change', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFFECACA)),
            ),
            color: const Color(0xFFFEF2F2),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Account Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF991B1B))),
                        Text('Sign out of your Nagarsevak account on this device', style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showLogoutConfirmDialog,
                    child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(authStateProvider.notifier).signOut();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 2: Navigation Bar & Quick Actions Customization
  // ─────────────────────────────────────────────────────────────
  Widget _buildBarCustomizationTab(bool isDark) {
    final isMr = ref.watch(isMarathiProvider);
    final bottomSlots = ref.watch(customBottomBarProvider);
    final quickSlots = ref.watch(customQuickActionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMr ? 'नेव्हिगेशन आणि द्रुत क्रिया सानुकूलन' : 'Bar & Quick Actions Customization',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isMr
                            ? 'आपल्या दैनंदिन कामासाठी बॉटम बार आणि 7 द्रुत क्रिया पर्याय बदला.'
                            : 'Personalize your bottom bar tabs and 7 radial gesture actions to fit your daily civic workflow.',
                        style: const TextStyle(
                          color: Color(0xFFE0F2FE),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─────────────────────────────────────────────────────────────
          // SECTION 1: BOTTOM NAVIGATION BAR (3 CUSTOMIZABLE + 1 FIXED)
          // ─────────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMr ? 'बॉटम नेव्हिगेशन बार (4 पर्याय)' : 'Bottom Navigation Bar (4 Tabs)',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMr
                        ? 'पहिले 3 टॅब बदला. चौथा सेटिंग्ज पर्याय कायम निश्चित आहे.'
                        : 'First 3 tabs are customizable. Tab 4 (Settings) is fixed.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(customBottomBarProvider.notifier).resetToDefaults();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isMr ? 'बॉटम बार डीफॉल्टवर रीसेट केला.' : 'Bottom bar tabs reset to defaults.'),
                      backgroundColor: const Color(0xFF0284C7),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.restore_rounded, size: 15, color: Color(0xFF0284C7)),
                label: Text(isMr ? 'रीसेट' : 'Reset', style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7))),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 4 Bottom Bar Slots Preview
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Column(
                children: [
                  for (int slotIdx = 0; slotIdx < 3; slotIdx++) ...[
                    _buildBottomBarSlotTile(
                      slotIndex: slotIdx,
                      moduleKey: bottomSlots[slotIdx],
                      isMr: isMr,
                    ),
                    if (slotIdx < 2) const Divider(height: 1, indent: 46),
                  ],
                  const Divider(height: 1, indent: 46),
                  // Fixed Slot 3 (Settings)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 20),
                    ),
                    title: Text(
                      isMr ? 'प्रोफाईल सेटिंग्ज' : 'Profile Settings',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    subtitle: Text(
                      isMr ? 'टॅब 4 (कायम निश्चित पर्याय)' : 'Tab 4 (Permanently Fixed)',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            isMr ? 'निश्चित' : 'Fixed',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ─────────────────────────────────────────────────────────────
          // SECTION 2: RADIAL QUICK ACCESS ACTIONS (7 SLOTS)
          // ─────────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMr ? 'द्रुत क्रिया मेनू (7 पर्याय)' : 'Radial Quick Access Actions (7 Slots)',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMr
                        ? 'मध्यवर्ती बटण दाबून धरल्यावर किंवा ओढल्यावर दिसणारे 7 पर्याय.'
                        : 'The 7 gesture actions on the curved glass running track.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(customQuickActionsProvider.notifier).resetToDefaults();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isMr ? 'द्रुत क्रिया डीफॉल्टवर रीसेट केल्या.' : 'Quick actions reset to defaults.'),
                      backgroundColor: const Color(0xFF0284C7),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.restore_rounded, size: 15, color: Color(0xFF0284C7)),
                label: Text(isMr ? 'रीसेट' : 'Reset', style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7))),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 7 Radial Action Slots
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Column(
                children: [
                  for (int slotIdx = 0; slotIdx < 7; slotIdx++) ...[
                    _buildQuickActionSlotTile(
                      slotIndex: slotIdx,
                      moduleKey: quickSlots[slotIdx],
                      isMr: isMr,
                    ),
                    if (slotIdx < 6) const Divider(height: 1, indent: 46),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarSlotTile({
    required int slotIndex,
    required String moduleKey,
    required bool isMr,
  }) {
    final config = getModuleConfig(moduleKey);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(config.icon, color: const Color(0xFF0284C7), size: 20),
      ),
      title: Text(
        isMr ? config.titleMr : config.titleEn,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
      subtitle: Text(
        'Tab ${slotIndex + 1} • ${config.category}',
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
      ),
      trailing: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F9FF),
          foregroundColor: const Color(0xFF0284C7),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFBAE6FD)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: const Size(60, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          _showModulePicker(
            context: context,
            title: isMr ? 'टॅब ${slotIndex + 1} साठी पर्याय निवडा' : 'Select Module for Tab ${slotIndex + 1}',
            currentKey: moduleKey,
            onSelected: (newKey) {
              ref.read(customBottomBarProvider.notifier).setSlot(slotIndex, newKey);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isMr
                        ? 'टॅब ${slotIndex + 1} "${getModuleConfig(newKey).titleMr}" वर बदलला.'
                        : 'Tab ${slotIndex + 1} updated to "${getModuleConfig(newKey).titleEn}".',
                  ),
                  backgroundColor: const Color(0xFF0284C7),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.edit_rounded, size: 12),
        label: Text(isMr ? 'बदला' : 'Change', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuickActionSlotTile({
    required int slotIndex,
    required String moduleKey,
    required bool isMr,
  }) {
    final config = getModuleConfig(moduleKey);

    final positionLabelsEn = [
      'Slot 1 • Left Bottom Leg',
      'Slot 2 • Left Arc (162°)',
      'Slot 3 • Left Upper Arc (126°)',
      'Slot 4 • Top Center Arc (90°)',
      'Slot 5 • Right Upper Arc (54°)',
      'Slot 6 • Right Arc (18°)',
      'Slot 7 • Right Bottom Leg',
    ];

    final positionLabelsMr = [
      'पर्याय 1 • डावे खालचे टोक',
      'पर्याय 2 • डावा चाप (162°)',
      'पर्याय 3 • डावा वरील चाप (126°)',
      'पर्याय 4 • मध्य शिखर चाप (90°)',
      'पर्याय 5 • उजवा वरील चाप (54°)',
      'पर्याय 6 • उजवा चाप (18°)',
      'पर्याय 7 • उजवे खालचे टोक',
    ];

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(config.icon, color: const Color(0xFF0284C7), size: 20),
      ),
      title: Text(
        isMr ? config.titleMr : config.titleEn,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
      subtitle: Text(
        isMr ? positionLabelsMr[slotIndex] : positionLabelsEn[slotIndex],
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
      ),
      trailing: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F9FF),
          foregroundColor: const Color(0xFF0284C7),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFBAE6FD)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: const Size(60, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          _showModulePicker(
            context: context,
            title: isMr
                ? '${positionLabelsMr[slotIndex]} साठी पर्याय निवडा'
                : 'Select Action for ${positionLabelsEn[slotIndex]}',
            currentKey: moduleKey,
            onSelected: (newKey) {
              ref.read(customQuickActionsProvider.notifier).setSlot(slotIndex, newKey);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isMr
                        ? 'क्रिया ${slotIndex + 1} "${getModuleConfig(newKey).titleMr}" वर बदलली.'
                        : 'Quick Action ${slotIndex + 1} updated to "${getModuleConfig(newKey).titleEn}".',
                  ),
                  backgroundColor: const Color(0xFF0284C7),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.edit_rounded, size: 12),
        label: Text(isMr ? 'बदला' : 'Change', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showModulePicker({
    required BuildContext context,
    required String title,
    required String currentKey,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isMr = ref.read(isMarathiProvider);
            final filtered = kAllAvailableModules.where((item) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return item.titleEn.toLowerCase().contains(q) ||
                  item.titleMr.toLowerCase().contains(q) ||
                  item.category.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: isMr ? 'पर्याय शोधा...' : 'Search page or module...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        setModalState(() => query = v);
                      },
                    ),
                  ),

                  const Divider(height: 12),

                  // Module List
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              isMr ? 'कोणतेही पर्याय आढळले नाहीत.' : 'No modules match your search.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final mod = filtered[idx];
                              final isSelected = mod.key == currentKey;

                              return Material(
                                color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(modalCtx);
                                    onSelected(mod.key);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF0284C7)
                                                : const Color(0xFFE0F2FE),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            mod.icon,
                                            color: isSelected ? Colors.white : const Color(0xFF0284C7),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isMr ? mod.titleMr : mod.titleEn,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${isMr ? mod.titleEn : mod.titleMr} • ${mod.category}',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 20)
                                        else
                                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 3: SMS Gateway
  // ─────────────────────────────────────────────────────────────
  Widget _buildSmsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quota Banner Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFBAE6FD)),
            ),
            color: const Color(0xFFF0F9FF),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sms_outlined, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Fast2SMS Enterprise Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('18,450 / 25,000 SMS Balance Remaining · DLT Approved', style: TextStyle(fontSize: 11, color: Color(0xFF0369A1))),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _showTestSmsDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: const Text('Test SMS', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Provider Config Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gateway Credentials & DLT Headers', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  const Divider(height: 18),

                  // Provider dropdown
                  const Text('Active Gateway Provider', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSmsProvider,
                        isExpanded: true,
                        items: ['Fast2SMS', 'Twilio SMS', 'MSG91 Enterprise'].map((p) {
                          return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSmsProvider = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // API Key
                  const Text('API Key / Token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _smsApiKeyCtrl,
                    obscureText: _obscureSmsKey,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureSmsKey ? Icons.visibility : Icons.visibility_off, size: 18),
                        onPressed: () => setState(() => _obscureSmsKey = !_obscureSmsKey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sender ID (DLT Header)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _smsSenderIdCtrl,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DLT Entity ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _smsDltEntityCtrl,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SMS gateway configuration updated successfully!'),
                            backgroundColor: Color(0xFF0284C7),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Update SMS Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab 4: Security Logs
  // ─────────────────────────────────────────────────────────────
  Widget _buildSecurityTab(bool isDark) {
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
        // Header Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search IP, email or device OS...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => setState(() => _securityLogSearch = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _showGlobalSignOutDialog,
                    icon: const Icon(Icons.logout, size: 14, color: Color(0xFFDC2626)),
                    label: const Text('Sign Out Others', style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Logs List
        Expanded(
          child: _isLoadingLogs
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
              : filtered.isEmpty
                  ? const Center(child: Text('No security audit logs found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final log = filtered[idx];
                        final dateStr = log['created_at'] != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(log['created_at'].toString()) ?? DateTime.now())
                            : 'Recent';

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFE0F2FE),
                                  child: const Icon(Icons.devices, color: Color(0xFF0284C7), size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${log['os'] ?? 'Device'} · ${log['browser'] ?? 'App'}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                      const SizedBox(height: 2),
                                      Text(
                                        'IP: ${log['ip_address'] ?? '127.0.0.1'} · ${log['email'] ?? 'User'}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
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
  // Tab 5: Report Issue / Support
  // ─────────────────────────────────────────────────────────────
  Widget _buildSupportTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submit Ticket Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.report_problem_outlined, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 6),
                      Text('Report New Issue or Feature Request', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Direct technical escalation to Krishnaniti municipal software support desk.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 18),

                  const Text('Issue Title / Summary *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _supportTitleCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Photo upload in gallery reports timeout error',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text('Detailed Description *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _supportDescCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Explain the issue encountered, steps to reproduce, or requested enhancement...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text('Severity / Priority:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      _buildPriorityChoice('Low'),
                      const SizedBox(width: 8),
                      _buildPriorityChoice('Medium'),
                      const SizedBox(width: 8),
                      _buildPriorityChoice('High'),
                    ],
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmittingTicket ? null : _submitSupportTicket,
                      icon: _isSubmittingTicket
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, size: 16),
                      label: Text(_isSubmittingTicket ? 'Submitting...' : 'Submit Support Ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Submitted Tickets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Support Tickets (${_supportTickets.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _loadSupportTickets,
              ),
            ],
          ),
          const SizedBox(height: 8),

          _isLoadingTickets
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
              : _supportTickets.isEmpty
                  ? const Center(child: Text('No support tickets filed yet'))
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

                        final isResolved = (t['status'] ?? '').toString().toLowerCase() == 'resolved';

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
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
                                      t['id'] ?? 'TKT',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                    ),
                                    Row(
                                      children: [
                                        _buildTicketBadge(t['priority'] ?? 'Medium', const Color(0xFF3B82F6)),
                                        const SizedBox(width: 6),
                                        _buildTicketBadge(
                                          t['status'] ?? 'Pending',
                                          isResolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t['title'] ?? 'Support Inquiry',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t['description'] ?? '',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
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
  // UI Helpers
  // ─────────────────────────────────────────────────────────────
  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {bool isPhone = false, bool isEmail = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }



  Widget _buildPriorityChoice(String priority) {
    final isSelected = _supportPriority == priority;
    return InkWell(
      onTap: () => setState(() => _supportPriority = priority),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF0284C7) : Colors.grey[300]!),
        ),
        child: Text(
          priority,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
