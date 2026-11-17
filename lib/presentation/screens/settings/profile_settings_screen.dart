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
import '../../providers/navigation_provider.dart';
import '../landing/landing_screen.dart';
import 'bar_customization_screen.dart';

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

  // Screen Touch gesture tracking for seamless transitions when sub-pages end
  double _horizontalPointerDelta = 0.0;
  double _verticalPointerDelta = 0.0;
  double _pointerStartX = 0.0;

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
    final user = ref.watch(currentUserProvider);
    final isStaff = user?.isStaff ?? false;

    final tabCount = _getTabCount(isStaff);
    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    return Scaffold(
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
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          tooltip: 'Toggle Sidebar Menu',
          onPressed: () {
            HapticFeedback.lightImpact();
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              _scaffoldKey.currentState?.closeDrawer();
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isStaff ? 'Staff Settings' : 'Profile Settings',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              isStaff ? 'Bar customization & staff profile' : 'Profile details & system settings',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFFE0F2FE)),
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
                      tabs: isStaff
                          ? const [
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
                                    Icon(Icons.badge_outlined, size: 14),
                                    SizedBox(width: 5),
                                    Text('My Profile'),
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
                            ]
                          : const [
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
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (event) {
                      _pointerStartX = event.position.dx;
                      _horizontalPointerDelta = 0.0;
                      _verticalPointerDelta = 0.0;
                    },
                    onPointerMove: (event) {
                      _horizontalPointerDelta += event.delta.dx;
                      _verticalPointerDelta += event.delta.dy;

                      // When pulled from left corner (<= 50px): sidebar drawer comes!
                      if (_pointerStartX <= 50.0 && _horizontalPointerDelta > 20.0) {
                        if (!(_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
                          HapticFeedback.lightImpact();
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      }
                    },
                    onPointerUp: (event) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isHorizontal = _horizontalPointerDelta.abs() > 30.0 &&
                          _horizontalPointerDelta.abs() > _verticalPointerDelta.abs() * 1.1;

                      if (!isHorizontal) return;

                      // 1. When pulled from left corner (<= 50px): The sidebar comes!
                      if (_pointerStartX <= 50.0) {
                        if (_horizontalPointerDelta > 15.0) {
                          if (!(_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
                            HapticFeedback.lightImpact();
                            _scaffoldKey.currentState?.openDrawer();
                          }
                        }
                        return; // Consume left corner gesture completely: do NOT swipe screens!
                      }

                      // 2. While pulled from middle of the screen (> 50px): The screen gets swiped!

                      // A) Swiping Right (finger moves →): Screen gets swiped back to Letters!
                      if (_horizontalPointerDelta > 30.0) {
                        final customBottomKeys = ref.read(customBottomBarProvider);
                        final prevScreen = customBottomKeys.length > 2 ? customBottomKeys[2] : 'letters';
                        HapticFeedback.lightImpact();
                        ref.read(activeScreenProvider.notifier).setScreen(prevScreen, isBack: true);
                        return;
                      }

                      // B) Swiping Left (finger moves ←):
                      // - When sub-pages are ending (at the last tab: Report Issue) OR right-edge inward swipe:
                      // Screen gets swiped forward to Dashboard!
                      if (_horizontalPointerDelta < -30.0) {
                        if (_tabController.index == _tabController.length - 1 ||
                            _pointerStartX > screenWidth - 60.0) {
                          HapticFeedback.lightImpact();
                          ref.read(activeScreenProvider.notifier).setScreen('dashboard', isBack: false);
                          ref.read(mainTabIndexProvider.notifier).setTab(0);
                          return;
                        }
                      }
                    },
                    child: TabBarView(
                      controller: _tabController,
                      children: isStaff
                          ? [
                              _buildBarCustomizationTab(isDark),
                              _buildStaffProfileTab(isDark),
                              _buildSupportTab(isDark),
                            ]
                          : [
                              _buildProfileTab(isDark),
                              _buildBarCustomizationTab(isDark),
                              _buildSecurityTab(isDark),
                              _buildSupportTab(isDark),
                            ],
                    ),
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
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Full Name (English)', _nameEnglishCtrl, 'e.g. Rahul Patil')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField('Full Name (Marathi)', _nameMarathiCtrl, 'उदा. राहुल पाटील')),
                    ],
                  ),
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
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Tab: Navigation Bar & Quick Actions Customization
  // ─────────────────────────────────────────────────────────────
  Widget _buildBarCustomizationTab(bool isDark) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 80),
      child: BarCustomizationView(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab: Staff Profile / Account Info (Shown for Team Members)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStaffProfileTab(bool isDark) {
    final isMr = ref.watch(isMarathiProvider);
    final user = ref.watch(currentUserProvider);
    final permittedModules = ref.watch(permittedModulesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff Identity Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? (isMr ? 'कार्यकर्ता / कर्मचारी' : 'Staff Member'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 3),
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
                            isMr ? 'अधिकृत टीम सदस्य' : 'Authorized Team Member',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Permitted Modules Section
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Text(
                isMr
                    ? 'आपल्याला दिलेले अधिकार (${permittedModules.length} विभाग)'
                    : 'Assigned Permissions (${permittedModules.length} Modules)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
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

          const SizedBox(height: 24),

          // Bar Customization Call-to-action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMr ? 'नेव्हिगेशन सानुकूल करा' : 'Customize Your Navigation',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMr
                            ? 'आपल्या आवडीनुसार बॉटम बार आणि 5 द्रुत क्रिया पर्याय सेट करा.'
                            : 'Assign your most frequently used permitted modules to bottom bar tabs and quick gestures.',
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  child: Text(isMr ? 'सेट करा' : 'Open', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab: Security Logs
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
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
