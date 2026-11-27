import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/repositories/complaints_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../../data/repositories/letters_repository.dart';
import '../complaints/new_complaint_screen.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/language_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';

final lettersRepoProvider = Provider((ref) => LettersRepository());

class DashboardScreen extends ConsumerStatefulWidget {
  final Function(int) onTabChange;

  const DashboardScreen({super.key, required this.onTabChange});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  Map<String, int> _complaintStats = {'total': 0, 'pending': 0, 'inProgress': 0, 'resolved': 0};
  int _voterCount = 0;
  int _lettersCount = 0;
  List<ComplaintModel> _recentActivity = [];
  String _activityFilter = 'all'; // 'all' or 'pending' matching Dashboard.tsx
  String get _dailyBriefing {
    final pending = _complaintStats['pending'] ?? 0;
    final resolved = _complaintStats['resolved'] ?? 0;
    final total = _complaintStats['total'] ?? 0;
    if (total == 0) {
      return 'Welcome to Nagarsevak Management Dashboard. All live civic grievance feeds, voter records, and requests are synced with the centralized municipal database.';
    }
    return 'Ward Summary: $pending pending citizen requests require priority attention. $resolved works have been resolved successfully with active monitoring.';
  }

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      try {
        SupabaseService.instance.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
    }
    super.dispose();
  }

  void _subscribeRealtime() {
    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId ?? AppConfig.defaultTenantId;

      _realtimeChannel = client
          .channel('dashboard-realtime-$tenantId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'complaints',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'tenant_id',
              value: tenantId,
            ),
            callback: (payload) => _loadDashboardData(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tasks',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'tenant_id',
              value: tenantId,
            ),
            callback: (payload) => _loadDashboardData(),
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final cRepo = ref.read(complaintsRepoProvider);
      final vRepo = ref.read(votersRepoProvider);
      final lRepo = ref.read(lettersRepoProvider);

      final results = await Future.wait([
        cRepo.getComplaintStats().catchError((e) {
          debugPrint('Error loading complaint stats: $e');
          return {'total': 0, 'pending': 0, 'inProgress': 0, 'resolved': 0};
        }),
        vRepo.getVotersCount().catchError((e) {
          debugPrint('Error loading voters count: $e');
          return 0;
        }),
        lRepo.getLettersCount().catchError((e) {
          debugPrint('Error loading letters count: $e');
          return 0;
        }),
        cRepo.getComplaints(limit: 10).catchError((e) {
          debugPrint('Error loading recent complaints: $e');
          return <ComplaintModel>[];
        }),
      ]);

      if (mounted) {
        setState(() {
          _complaintStats = results[0] as Map<String, int>;
          _voterCount = results[1] as int;
          _lettersCount = results[2] as int;
          _recentActivity = results[3] as List<ComplaintModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard data load exception: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDashboardHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.70,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. FIXED HEADER
            AppModalHeader(
              icon: Icons.help_outline_rounded,
              title: 'Dashboard Overview & Help',
              subtitle: 'Central command guide and navigation hints',
              onClose: () => Navigator.pop(ctx),
            ),

            // 2. SCROLLABLE CONTENT & BUTTON
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHelpStep(
                    icon: Icons.dashboard_rounded,
                    title: 'Central Command Hub',
                    desc: 'Gives a quick summary of citizen requests, municipal letters, and ward voter count.',
                  ),
                  _buildHelpStep(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Create a New Request',
                    desc: 'Tap "+ New Request" to log a citizen civic grievance or departmental petition.',
                  ),
                  _buildHelpStep(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Daily Briefing',
                    desc: 'AI synthesized ward pulse identifying urgent bottlenecks and pending issues.',
                  ),
                  _buildHelpStep(
                    icon: Icons.bar_chart_rounded,
                    title: 'Status Overview & Clearance',
                    desc: 'Visual breakdown of pending, in-progress, and resolved issues with clearance rate.',
                  ),
                  _buildHelpStep(
                    icon: Icons.notifications_active_outlined,
                    title: 'Live Activity Feed',
                    desc: 'Real-time updates of citizen complaints with instant filtering by Pending status.',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Got it!', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpStep({required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF0284C7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 1.5),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openModuleDetail(String title, String subtitle, String category, IconData icon, List<String> highlights) {
    final key = resolveScreenKey(title) ?? resolveScreenKey(category) ?? resolveScreenKey(subtitle);
    if (key != null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      ref.read(activeScreenProvider.notifier).setScreen(key);
      if (key == 'dashboard') ref.read(mainTabIndexProvider.notifier).setTab(0);
      if (key == 'complaints') ref.read(mainTabIndexProvider.notifier).setTab(1);
      if (key == 'letters') ref.read(mainTabIndexProvider.notifier).setTab(2);
      if (key == 'profile_settings') ref.read(mainTabIndexProvider.notifier).setTab(3);
      if (key == 'complaints') widget.onTabChange(1);
      if (key == 'letters') widget.onTabChange(2);
      if (key == 'profile_settings') widget.onTabChange(3);
    }
  }

  void _showComplaintDetailsModal(ComplaintModel complaint) {
    final isPending = complaint.status.toLowerCase() == 'pending';
    final isResolved = complaint.status.toLowerCase() == 'resolved';
    final statusColor = isPending
        ? const Color(0xFFDC2626)
        : (isResolved ? const Color(0xFF16A34A) : const Color(0xFFD97706));
    final statusBg = isPending
        ? const Color(0xFFFEF2F2)
        : (isResolved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. FIXED HEADER
            AppModalHeader(
              icon: Icons.assignment_outlined,
              title: complaint.id,
              subtitle: 'Status: ${complaint.status}',
              onClose: () => Navigator.pop(ctx),
            ),

            // 2. SCROLLABLE DETAILS & ACTIONS
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category & Priority',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          complaint.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    complaint.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                  if (complaint.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      complaint.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            complaint.area ?? complaint.location ?? 'Ward No. 12, Prabhag 12',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ),
                        if (complaint.citizenName != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${complaint.citizenName}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onTabChange(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('Open in Requests', style: TextStyle(fontWeight: FontWeight.w700)),
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = ref.watch(appLanguageProvider);
    final totalVal = _complaintStats['total'] ?? 0;
    final pendingVal = _complaintStats['pending'] ?? 0;
    final inProgressVal = _complaintStats['inProgress'] ?? 0;
    final resolvedVal = _complaintStats['resolved'] ?? 0;

    final localizedBriefing = lang == 'mr'
        ? (totalVal == 0
            ? 'नगरसेवक व्यवस्थापन डॅशबोर्डवर आपले स्वागत आहे. सर्व तक्रारी आणि मतदार नोंदी महापालिका प्रणालीशी जोडलेल्या आहेत.'
            : 'प्रभाग सारांश: $pendingVal प्रलंबित नागरिक तक्रारींवर प्राधान्याने लक्ष देणे आवश्यक आहे. $resolvedVal कामे यशस्वीरीत्या पूर्ण झाली आहेत.')
        : (lang == 'hi'
            ? (totalVal == 0
                ? 'नगरसेवक प्रबंधन डैशबोर्ड में आपका स्वागत है। सभी शिकायतें और मतदाता रिकॉर्ड जुड़े हुए हैं।'
                : 'वार्ड सारांश: $pendingVal लंबित नागरिक शिकायतों पर प्राथमिकता से ध्यान देने की आवश्यकता है। $resolvedVal कार्य सफलतापूर्वक पूर्ण हुए हैं।')
            : _dailyBriefing);

    final displayedActivities = _activityFilter == 'pending'
        ? _recentActivity.where((a) => a.status.toLowerCase() == 'pending').toList()
        : _recentActivity;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: NagarsevakAppDrawer(
          currentTabIndex: 0,
          onTabChange: widget.onTabChange,
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: lang == 'mr' ? 'मेनू उघडा' : (lang == 'hi' ? 'मेनू खोलें' : 'Open Menu Drawer'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppTranslations.t('dashboard.title', lang: lang),
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
                      AppTranslations.t('dashboard.subtitle', lang: lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE0F2FE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: const [],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
              )
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // ==========================================
                    // 1) HEADER SECTION
                    // ==========================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0284C7), width: 1.8),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Color(0xFF0284C7), size: 20),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppTranslations.t('dashboard.title', lang: lang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                lang == 'mr'
                                    ? 'स्वागत आहे, सन्माननीय नगरसेवक'
                                    : (lang == 'hi' ? 'स्वागत है, माननीय नगरसेवक' : 'Welcome back, Hon. Nagarsevak'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NewComplaintScreen()),
                              );
                            },
                            icon: const Icon(Icons.add_rounded, size: 15),
                            label: Text(
                              lang == 'mr' ? '+ नवीन तक्रार' : (lang == 'hi' ? '+ नया अनुरोध' : '+ New Request'),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ==========================================
                    // 2) AI INSIGHT BANNER
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang == 'mr'
                                      ? 'एआय दैनिक सारांश आणि प्रभाग आढावा'
                                      : (lang == 'hi' ? 'एआई दैनिक सारांश और वार्ड समीक्षा' : 'AI Daily Briefing & Ward Pulse'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  localizedBriefing,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==========================================
                    // 3) 4 STAT CARDS
                    // ==========================================
                    Row(
                      children: [
                        Expanded(
                          child: _StatCardItem(
                            title: lang == 'mr' ? 'एकूण मतदार' : (lang == 'hi' ? 'कुल मतदाता' : 'Total Citizens'),
                            value: NumberFormat.decimalPattern().format(_voterCount),
                            icon: Icons.people_alt_rounded,
                            iconColor: const Color(0xFF0284C7),
                            badgeColor: const Color(0xFFE0F2FE),
                            borderColor: const Color(0xFFBAE6FD),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(activeScreenProvider.notifier).setScreen('voters');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCardItem(
                            title: lang == 'mr' ? 'प्रलंबित समस्या' : (lang == 'hi' ? 'लंबित मुद्दे' : 'Pending Issues'),
                            value: NumberFormat.decimalPattern().format(pendingVal),
                            icon: Icons.error_outline_rounded,
                            iconColor: const Color(0xFFDC2626),
                            badgeColor: const Color(0xFFFEF2F2),
                            borderColor: const Color(0xFFFECACA),
                            onTap: () {
                              setState(() => _activityFilter = 'pending');
                              widget.onTabChange(1);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCardItem(
                            title: lang == 'mr' ? 'काम चालू' : (lang == 'hi' ? 'प्रगति पर' : 'In Progress'),
                            value: NumberFormat.decimalPattern().format(inProgressVal),
                            icon: Icons.timelapse_rounded,
                            iconColor: const Color(0xFFD97706),
                            badgeColor: const Color(0xFFFFFBEB),
                            borderColor: const Color(0xFFFDE68A),
                            onTap: () => widget.onTabChange(1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCardItem(
                            title: lang == 'mr' ? 'पूर्ण कामे' : (lang == 'hi' ? 'पूर्ण कार्य' : 'Resolved'),
                            value: NumberFormat.decimalPattern().format(resolvedVal),
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: const Color(0xFF16A34A),
                            badgeColor: const Color(0xFFF0FDF4),
                            borderColor: const Color(0xFFBBF7D0),
                            onTap: () => widget.onTabChange(1),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ==========================================
                    // 4) QUICK ACTIONS ROW (tutorial-quick-actions)
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick actions:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _QuickActionPill(
                                  icon: Icons.search_rounded,
                                  label: 'Search Voter',
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    ref.read(activeScreenProvider.notifier).setScreen('voters');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.groups_rounded,
                                  label: 'Staff / Team',
                                  onTap: () => _openModuleDetail(
                                    'My Team',
                                    'Staff & coordinator team members',
                                    'Political',
                                    Icons.groups_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.campaign_outlined,
                                  label: 'Complaints',
                                  onTap: () => widget.onTabChange(1),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.mark_email_unread_outlined,
                                  label: 'Letters ($_lettersCount)',
                                  onTap: () => widget.onTabChange(2),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.event_note_outlined,
                                  label: 'Diary',
                                  onTap: () => _openModuleDetail(
                                    'Diary',
                                    'Task management, daily visits and itinerary',
                                    'Daily work',
                                    Icons.check_box_outlined,
                                    ['4 appointments today', 'Inspection at 4:00 PM', 'GB agenda prep'],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.badge_outlined,
                                  label: 'Visitor Log',
                                  onTap: () => _openModuleDetail(
                                    'Visitor Log',
                                    'Track daily citizen visits & appointments',
                                    'Daily work',
                                    Icons.badge_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.map_outlined,
                                  label: 'Ward Map',
                                  onTap: () => _openModuleDetail(
                                    'Ward Map',
                                    'Geographic boundaries, booths & civil works',
                                    'Ward Info',
                                    Icons.map_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.history_rounded,
                                  label: 'Work History',
                                  onTap: () => _openModuleDetail(
                                    'Work History',
                                    'Development works, grievances & welfare',
                                    'Ward Info',
                                    Icons.history_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.lightbulb_outline_rounded,
                                  label: 'Possible Improvements',
                                  onTap: () => _openModuleDetail(
                                    'Possible Improvements',
                                    'Propose and track future development works',
                                    'Ward Info',
                                    Icons.lightbulb_outline_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.currency_rupee_rounded,
                                  label: 'Ward Wise Provision',
                                  onTap: () => _openModuleDetail(
                                    'Ward Wise Provision',
                                    'Budget provisions and funding proposals',
                                    'Ward Info',
                                    Icons.currency_rupee_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.menu_book_outlined,
                                  label: 'GB Register',
                                  onTap: () => _openModuleDetail(
                                    'GB Register',
                                    'General Body motions and civic resolutions',
                                    'Municipal',
                                    Icons.menu_book_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: 'Ward Budget',
                                  onTap: () => _openModuleDetail(
                                    'Ward Budget',
                                    'Track development funds & expenditure',
                                    'Municipal',
                                    Icons.account_balance_wallet_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.location_city_outlined,
                                  label: 'Government office',
                                  onTap: () => _openModuleDetail(
                                    'Government office',
                                    'Ward municipal offices & emergency directory',
                                    'Municipal',
                                    Icons.location_city_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.trending_up_rounded,
                                  label: 'Social Analytics',
                                  onTap: () => _openModuleDetail(
                                    'Social Analytics',
                                    'Social media engagement and public interaction',
                                    'Media',
                                    Icons.trending_up_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.newspaper_outlined,
                                  label: 'Newspaper Clipping',
                                  onTap: () => _openModuleDetail(
                                    'Newspaper Clipping',
                                    'Print news coverage and press clippings',
                                    'Media',
                                    Icons.newspaper_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.language_rounded,
                                  label: 'Media Tracking',
                                  onTap: () => _openModuleDetail(
                                    'Media Tracking',
                                    'Broadcast news channels and press monitors',
                                    'Media',
                                    Icons.language_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'AI Content Studio',
                                  onTap: () => _openModuleDetail(
                                    'AI Content Studio',
                                    'Social media post generation & PR copy',
                                    'Media',
                                    Icons.auto_awesome_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.event_available_rounded,
                                  label: 'Events & Invites',
                                  onTap: () => _openModuleDetail(
                                    'Events & Invites',
                                    'Public programs, rallies & inauguration events',
                                    'Programs',
                                    Icons.event_available_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.photo_library_outlined,
                                  label: 'Gallery & Media',
                                  onTap: () => _openModuleDetail(
                                    'Gallery & Media',
                                    'Event photos, project images & public press',
                                    'Programs',
                                    Icons.photo_library_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.bar_chart_rounded,
                                  label: 'Result Analysis',
                                  onTap: () => _openModuleDetail(
                                    'Result Analysis',
                                    'Past election results, booth margins & turnout',
                                    'Programs',
                                    Icons.bar_chart_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.group_add_outlined,
                                  label: 'Sadasya (Members)',
                                  onTap: () => _openModuleDetail(
                                    'Sadasya (Members)',
                                    'Active party cadre & booth coordinators',
                                    'Political',
                                    Icons.group_add_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.fact_check_outlined,
                                  label: 'Sample Surveys',
                                  onTap: () => _openModuleDetail(
                                    'Sample Surveys',
                                    'Opinion polls, field surveys and voter sentiment data',
                                    'Political',
                                    Icons.fact_check_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.groups_2_outlined,
                                  label: 'Opposition Information',
                                  onTap: () => _openModuleDetail(
                                    'Opposition Information',
                                    'Opposition candidate profiles & past records',
                                    'Political',
                                    Icons.groups_2_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.apartment_outlined,
                                  label: 'NGO & Mandals Info',
                                  onTap: () => _openModuleDetail(
                                    'NGO & Mandals Info',
                                    'Youth mandals, festival committees & NGOs',
                                    'Political',
                                    Icons.apartment_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.home_work_outlined,
                                  label: 'Societies',
                                  onTap: () => _openModuleDetail(
                                    'Housing Societies',
                                    'Apartments & resident welfare associations',
                                    'Political',
                                    Icons.home_work_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.warning_amber_rounded,
                                  label: 'Duplicates',
                                  onTap: () => _openModuleDetail(
                                    'Duplicate Voters',
                                    'Identify and filter duplicate entries',
                                    'Political',
                                    Icons.warning_amber_rounded,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.description_outlined,
                                  label: 'Voter Forms',
                                  onTap: () => _openModuleDetail(
                                    'Voter Forms',
                                    'Form 6, 7 & 8 electoral applications',
                                    'Political',
                                    Icons.description_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.assignment_ind_outlined,
                                  label: 'Karyakarta Work',
                                  onTap: () => _openModuleDetail(
                                    'Karyakarta Work Management',
                                    'Assign field tasks & track metrics',
                                    'Political',
                                    Icons.assignment_ind_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.sms_outlined,
                                  label: 'Send SMS',
                                  onTap: () => _openModuleDetail(
                                    'Send SMS',
                                    'Send notifications & updates to voters',
                                    'Public Communication',
                                    Icons.sms_outlined,
                                    const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.chat_rounded,
                                  label: 'WhatsApp',
                                  onTap: () => _openModuleDetail(
                                    'WhatsApp Message',
                                    'Direct messaging & voter broadcast',
                                    'Public Communication',
                                    Icons.chat_rounded,
                                    const [],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==========================================
                    // 5) STATUS OVERVIEW CHART (tutorial-status-chart)
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang == 'mr' ? 'स्थिती आढावा आणि निवारण' : (lang == 'hi' ? 'स्थिति समीक्षा और निवारण' : 'Status Overview'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              InkWell(
                                onTap: () => widget.onTabChange(1),
                                child: Text(
                                  lang == 'mr' ? 'सर्व पहा' : (lang == 'hi' ? 'सभी देखें' : 'View All'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Visual Bars
                          _buildStatusBar(
                            label: AppTranslations.getStatus('pending', lang),
                            count: pendingVal,
                            total: totalVal,
                            color: const Color(0xFFEF4444),
                          ),
                          const SizedBox(height: 10),
                          _buildStatusBar(
                            label: AppTranslations.getStatus('in_progress', lang),
                            count: inProgressVal,
                            total: totalVal,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 10),
                          _buildStatusBar(
                            label: AppTranslations.getStatus('resolved', lang),
                            count: resolvedVal,
                            total: totalVal,
                            color: const Color(0xFF10B981),
                          ),

                          const SizedBox(height: 18),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 14),

                          // 3-column KPIs: Clearance Rate, Avg Response, Satisfaction
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        lang == 'mr' ? 'निवारण दर' : (lang == 'hi' ? 'समाधान दर' : 'CLEARANCE RATE'),
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${totalVal > 0 ? ((resolvedVal / totalVal) * 100).round() : 0}%',
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                              Expanded(
                                child: Column(
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        lang == 'mr' ? 'सरासरी प्रतिसाद' : (lang == 'hi' ? 'औसत प्रतिक्रिया' : 'AVG. RESPONSE'),
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '—',
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                              Expanded(
                                child: Column(
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        lang == 'mr' ? 'नागरिक समाधान' : (lang == 'hi' ? 'नागरिक संतुष्टि' : 'SATISFACTION'),
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '—',
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==========================================
                    // 6) LIVE ACTIVITY FEED (tutorial-live-activity)
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                lang == 'mr' ? 'थेट तक्रार नोंद' : (lang == 'hi' ? 'लाइव शिकायत फ़ीड' : 'Live Activity'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Text(
                                  '$pendingVal ${AppTranslations.getStatus('pending', lang)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // All / Pending filter toggle
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    _buildFilterTab(
                                      label: lang == 'mr' ? 'सर्व' : (lang == 'hi' ? 'सभी' : 'All'),
                                      isSelected: _activityFilter == 'all',
                                      onTap: () => setState(() => _activityFilter = 'all'),
                                    ),
                                    _buildFilterTab(
                                      label: AppTranslations.getStatus('pending', lang),
                                      isSelected: _activityFilter == 'pending',
                                      isAlert: true,
                                      onTap: () => setState(() => _activityFilter = 'pending'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Activity List
                          if (displayedActivities.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  lang == 'mr' ? 'कोणतीही ताजी नोंद नाही' : (lang == 'hi' ? 'कोई हालिया गतिविधि नहीं' : 'No recent activity matching filter'),
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ),
                            )
                          else
                            ...displayedActivities.take(5).map((activity) {
                              final isPending = activity.status.toLowerCase() == 'pending';
                              final isResolved = activity.status.toLowerCase() == 'resolved';

                              return InkWell(
                                onTap: () => _showComplaintDetailsModal(activity),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPending ? const Color(0xFFFFF9F9) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isPending ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isPending
                                              ? const Color(0xFFEF4444)
                                              : (isResolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                          boxShadow: isPending
                                              ? const [BoxShadow(color: Color(0x66EF4444), blurRadius: 4)]
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AppTranslatedText(
                                              activity.title,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: isPending ? FontWeight.w700 : FontWeight.w600,
                                                color: const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.schedule_rounded, size: 11, color: Color(0xFF94A3B8)),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: AppTranslatedText(
                                                    activity.area != null ? '${activity.area} • Today' : 'Ward No. 12',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isPending
                                              ? const Color(0xFFFEE2E2)
                                              : (isResolved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          AppTranslations.getStatus(activity.status, lang),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: isPending
                                                ? const Color(0xFFDC2626)
                                                : (isResolved ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => widget.onTabChange(1),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0284C7),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                              ),
                              child: Text(
                                lang == 'mr' ? 'सर्व तक्रारी पहा' : (lang == 'hi' ? 'पूरी सूची देखें' : 'View Full Log'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final double pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    bool isAlert = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isAlert ? const Color(0xFFEF4444) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isAlert ? Colors.white : const Color(0xFF0F172A))
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

/// Stat Card widget matching StatCard in Dashboard.tsx
class _StatCardItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color badgeColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _StatCardItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.badgeColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTranslatedText(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill Quick Action Button
class _QuickActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF475569)),
            const SizedBox(width: 5),
            AppTranslatedText(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
