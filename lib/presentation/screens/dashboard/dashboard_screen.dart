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
  String _localizedBriefing(String lang) {
    final pending = _complaintStats['pending'] ?? 0;
    final resolved = _complaintStats['resolved'] ?? 0;
    final total = _complaintStats['total'] ?? 0;
    final pendingFmt = AppTranslations.formatDigits(pending, lang);
    final resolvedFmt = AppTranslations.formatDigits(resolved, lang);
    if (total == 0) {
      return AppTranslations.pick(
        lang,
        en: 'Welcome to Nagarsevak Management Dashboard. All live civic grievance feeds, voter records, and requests are synced with the centralized municipal database.',
        mr: 'नगरसेवक व्यवस्थापन डॅशबोर्डवर आपले स्वागत आहे. सर्व तक्रारी आणि मतदार नोंदी महापालिका प्रणालीशी जोडलेल्या आहेत.',
        hi: 'नगरसेवक प्रबंधन डैशबोर्ड में आपका स्वागत है। सभी शिकायतें और मतदाता रिकॉर्ड जुड़े हुए हैं।',
      );
    }
    return AppTranslations.pick(
      lang,
      en: 'Ward Summary: $pendingFmt pending citizen requests require priority attention. $resolvedFmt works have been resolved successfully with active monitoring.',
      mr: 'प्रभाग सारांश: $pendingFmt प्रलंबित नागरिक तक्रारींवर प्राधान्याने लक्ष देणे आवश्यक आहे. $resolvedFmt कामे यशस्वीरीत्या पूर्ण झाली आहेत.',
      hi: 'वार्ड सारांश: $pendingFmt लंबित नागरिक शिकायतों पर प्राथमिकता से ध्यान देने की आवश्यकता है। $resolvedFmt कार्य सफलतापूर्वक पूर्ण हुए हैं।',
    );
  }

  Widget _localizedAreaText(
    String rawArea,
    String lang, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
    String suffix = '',
  }) {
    final mapped = AppTranslations.getAreaName(rawArea, lang);
    final formattedRaw = AppTranslations.formatDigits(rawArea, lang);
    if (mapped != formattedRaw) {
      return Text(
        '$mapped$suffix',
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    return AppTranslatedText(
      rawArea,
      targetLanguage: lang,
      suffix: suffix,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
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
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final lang = modalRef.watch(appLanguageProvider);
          final rawLocation = (complaint.area != null && complaint.area!.trim().isNotEmpty)
              ? complaint.area!.trim()
              : (complaint.location != null && complaint.location!.trim().isNotEmpty
                  ? complaint.location!.trim()
                  : null);

          return Container(
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
                  title: AppTranslations.formatDigits(complaint.id, lang),
                  subtitle: '${AppTranslations.getCommon("status", lang)}: ${AppTranslations.getStatus(complaint.status, lang)}',
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
                            AppTranslations.pick(
                              lang,
                              en: 'Category & Priority',
                              mr: 'वर्ग आणि प्राधान्य',
                              hi: 'श्रेणी और प्राथमिकता',
                            ),
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
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              AppTranslations.getStatus(complaint.status, lang),
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
                      AppTranslatedText(
                        complaint.title,
                        targetLanguage: lang,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.25,
                        ),
                      ),
                      if (complaint.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        AppTranslatedText(
                          complaint.description,
                          targetLanguage: lang,
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
                              child: rawLocation != null
                                  ? _localizedAreaText(
                                      rawLocation,
                                      lang,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    )
                                  : Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Ward No. 12, Prabhag 12',
                                        mr: 'प्रभाग १२',
                                        hi: 'वार्ड १२',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                            ),
                            if (complaint.citizenName != null && complaint.citizenName!.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: AppTranslatedText(
                                  complaint.citizenName!,
                                  isName: true,
                                  targetLanguage: lang,
                                  prefix: '• ',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
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
                              child: Text(
                                AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
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
                              child: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Open in Requests',
                                  mr: 'तक्रारींमध्ये उघडा',
                                  hi: 'शिकायतों में खोलें',
                                ),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
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
    super.build(context);
    final lang = ref.watch(appLanguageProvider);
    final totalVal = _complaintStats['total'] ?? 0;
    final pendingVal = _complaintStats['pending'] ?? 0;
    final inProgressVal = _complaintStats['inProgress'] ?? 0;
    final resolvedVal = _complaintStats['resolved'] ?? 0;

    final localizedBriefing = _localizedBriefing(lang);

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
              tooltip: AppTranslations.pick(lang, en: 'Open Menu Drawer', mr: 'मेनू उघडा', hi: 'मेनू खोलें'),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
                      AppTranslations.pick(
                        lang,
                        en: 'Civic Grievances & Ward Management',
                        mr: 'नागरी तक्रारी आणि मतदार व्यवस्थापन',
                        hi: 'नागरिक शिकायतें और वार्ड प्रबंधन',
                      ),
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
                                AppTranslations.pick(
                                  lang,
                                  en: 'Welcome back, Nagar Sevak',
                                  mr: 'आपले स्वागत आहे, नगरसेवक',
                                  hi: 'वापसी पर स्वागत है, नगरसेवक',
                                ),
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
                              AppTranslations.pick(
                                lang,
                                en: '+ New Request',
                                mr: '+ नवीन तक्रार',
                                hi: '+ नया अनुरोध',
                              ),
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
                                  AppTranslations.pick(
                                    lang,
                                    en: 'AI Daily Insight',
                                    mr: 'AI दैनिक माहिती',
                                    hi: 'AI दैनिक जानकारी',
                                  ),
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
                            title: AppTranslations.pick(lang, en: 'Total Citizens', mr: 'एकूण नागरिक', hi: 'कुल नागरिक'),
                            value: AppTranslations.formatDigits(NumberFormat.decimalPattern().format(_voterCount), lang),
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
                            title: AppTranslations.pick(lang, en: 'Pending Issues', mr: 'प्रलंबित तक्रारी', hi: 'लंबित मुद्दे'),
                            value: AppTranslations.formatDigits(NumberFormat.decimalPattern().format(pendingVal), lang),
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
                            title: AppTranslations.pick(lang, en: 'In Progress', mr: 'काम चालू', hi: 'कार्य प्रगति पर'),
                            value: AppTranslations.formatDigits(NumberFormat.decimalPattern().format(inProgressVal), lang),
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
                            title: AppTranslations.pick(lang, en: 'Resolved', mr: 'सोडवलेले', hi: 'हल किया गया'),
                            value: AppTranslations.formatDigits(NumberFormat.decimalPattern().format(resolvedVal), lang),
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
                          Text(
                            AppTranslations.pick(lang, en: 'Quick actions:', mr: 'त्वरित क्रिया:', hi: 'त्वरित कार्रवाई:'),
                            style: const TextStyle(
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
                                  label: AppTranslations.pick(lang, en: 'Search Voter', mr: 'मतदार शोधा', hi: 'मतदाता खोजें'),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    ref.read(activeScreenProvider.notifier).setScreen('voters');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.groups_rounded,
                                  label: AppTranslations.pick(lang, en: 'Staff / Team', mr: 'स्टाफ व्यवस्थापन', hi: 'कर्मचारी प्रबंधन'),
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
                                  label: AppTranslations.pick(lang, en: 'Complaints', mr: 'तक्रारी पहा', hi: 'शिकायतें देखें'),
                                  onTap: () => widget.onTabChange(1),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.mark_email_unread_outlined,
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Letters (${AppTranslations.formatDigits(_lettersCount, lang)})',
                                    mr: 'पत्र व्यवहार (${AppTranslations.formatDigits(_lettersCount, lang)})',
                                    hi: 'पत्र व्यवहार (${AppTranslations.formatDigits(_lettersCount, lang)})',
                                  ),
                                  onTap: () => widget.onTabChange(2),
                                ),
                                const SizedBox(width: 8),
                                _QuickActionPill(
                                  icon: Icons.event_note_outlined,
                                  label: AppTranslations.pick(lang, en: 'Diary', mr: 'दैनंदिनी (डायरी)', hi: 'दैनिक डायरी'),
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
                                  label: AppTranslations.pick(lang, en: 'Visitor Log', mr: 'भेट देणारे नागरिक', hi: 'आगंतुक रजिस्टर'),
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
                                  label: AppTranslations.pick(lang, en: 'Ward Map', mr: 'प्रभाग नकाशा', hi: 'वार्ड नक्शा'),
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
                                  label: AppTranslations.pick(lang, en: 'Work History', mr: 'विकास कामे इतिहास', hi: 'कार्य इतिहास'),
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
                                  label: AppTranslations.pick(lang, en: 'Possible Improvements', mr: 'संभाव्य सुधारणा', hi: 'संभावित सुधार'),
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
                                  label: AppTranslations.pick(lang, en: 'Ward Wise Provision', mr: 'प्रभाग तरतूद', hi: 'वार्ड प्रावधान'),
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
                                  label: AppTranslations.pick(lang, en: 'GB Register', mr: 'जीबी रजिस्टर', hi: 'जीबी रजिस्टर'),
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
                                  label: AppTranslations.pick(lang, en: 'Ward Budget', mr: 'प्रभाग अंदाजपत्रक', hi: 'वार्ड बजट'),
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
                                  label: AppTranslations.pick(lang, en: 'Government office', mr: 'शासकीय कार्यालये', hi: 'सरकारी कार्यालय'),
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
                                  label: AppTranslations.pick(lang, en: 'Social Analytics', mr: 'सोशल मीडिया विश्लेषण', hi: 'सोशल मीडिया विश्लेषण'),
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
                                  label: AppTranslations.pick(lang, en: 'Newspaper Clipping', mr: 'वृत्तपत्र कात्रणे', hi: 'अखबार की कतरनें'),
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
                                  label: AppTranslations.pick(lang, en: 'Media Tracking', mr: 'मीडिया ट्रॅकिंग', hi: 'मीडिया ट्रैकिंग'),
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
                                  label: AppTranslations.pick(lang, en: 'AI Content Studio', mr: 'एआय कंटेंट स्टुडिओ', hi: 'एआई कंटेंट स्टूडियो'),
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
                                  label: AppTranslations.pick(lang, en: 'Events & Invites', mr: 'कार्यक्रम व निमंत्रणे', hi: 'कार्यक्रम और निमंत्रण'),
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
                                  label: AppTranslations.pick(lang, en: 'Gallery & Media', mr: 'गॅलरी आणि मीडिया', hi: 'गैलरी और मीडिया'),
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
                                  label: AppTranslations.pick(lang, en: 'Result Analysis', mr: 'निवडणूक निकाल विश्लेषण', hi: 'चुनाव परिणाम विश्लेषण'),
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
                                  label: AppTranslations.pick(lang, en: 'Sadasya (Members)', mr: 'सदस्य व्यवस्थापन', hi: 'सदस्य प्रबंधन'),
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
                                  label: AppTranslations.pick(lang, en: 'Sample Surveys', mr: 'मतदार सर्वेक्षण', hi: 'मतदाता सर्वेक्षण'),
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
                                  label: AppTranslations.pick(lang, en: 'Opposition Information', mr: 'विरोधी पक्ष माहिती', hi: 'विपक्षी जानकारी'),
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
                                  label: AppTranslations.pick(lang, en: 'NGO & Mandals Info', mr: 'मंडळे आणि संस्था', hi: 'मंडल और गैर-सरकारी संगठन'),
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
                                  label: AppTranslations.pick(lang, en: 'Societies', mr: 'गृहनिर्माण सोसायट्या', hi: 'हाउसिंग सोसायटियां'),
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
                                  label: AppTranslations.pick(lang, en: 'Duplicates', mr: 'दुबार मतदार', hi: 'डुप्लीकेट मतदाता'),
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
                                  label: AppTranslations.pick(lang, en: 'Voter Forms', mr: 'मतदार अर्ज (६, ७, ८)', hi: 'मतदाता फॉर्म (६, ७, ८)'),
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
                                  label: AppTranslations.pick(lang, en: 'Karyakarta Work', mr: 'कार्यकर्ता कार्य', hi: 'कार्यकर्ता कार्य'),
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
                                  label: AppTranslations.pick(lang, en: 'Send SMS', mr: 'एसएमएस पाठवा', hi: 'एसएमएस भेजें'),
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
                                  label: AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सअ‍ॅप संदेश', hi: 'व्हाट्सएप संदेश'),
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
                                AppTranslations.pick(
                                  lang,
                                  en: 'Complaint Status Overview',
                                  mr: 'तक्रार स्थिती',
                                  hi: 'शिकायत स्थिति',
                                ),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              InkWell(
                                onTap: () => widget.onTabChange(1),
                                child: Text(
                                  AppTranslations.pick(lang, en: 'View All', mr: 'सर्व पहा', hi: 'सभी देखें'),
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
                            lang: lang,
                          ),
                          const SizedBox(height: 10),
                          _buildStatusBar(
                            label: AppTranslations.getStatus('in_progress', lang),
                            count: inProgressVal,
                            total: totalVal,
                            color: const Color(0xFFF59E0B),
                            lang: lang,
                          ),
                          const SizedBox(height: 10),
                          _buildStatusBar(
                            label: AppTranslations.getStatus('resolved', lang),
                            count: resolvedVal,
                            total: totalVal,
                            color: const Color(0xFF10B981),
                            lang: lang,
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
                                        AppTranslations.pick(
                                          lang,
                                          en: 'CLEARANCE RATE',
                                          mr: 'निकालाचे प्रमाण',
                                          hi: 'निपटान दर',
                                        ),
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${AppTranslations.formatDigits(totalVal > 0 ? ((resolvedVal / totalVal) * 100).round() : 0, lang)}%',
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
                                        AppTranslations.pick(
                                          lang,
                                          en: 'AVG. RESPONSE',
                                          mr: 'सरासरी प्रतिसाद वेळ',
                                          hi: 'औसत प्रतिक्रिया समय',
                                        ),
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
                                        AppTranslations.pick(
                                          lang,
                                          en: 'SATISFACTION',
                                          mr: 'समाधान',
                                          hi: 'संतोष',
                                        ),
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
                                AppTranslations.pick(lang, en: 'Live Activity', mr: 'अलीकडील घडामोडी', hi: 'हाल की गतिविधियां'),
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
                                  '${AppTranslations.formatDigits(pendingVal, lang)} ${AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित')}',
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
                                      label: AppTranslations.pick(lang, en: 'All', mr: 'सर्व', hi: 'सभी'),
                                      isSelected: _activityFilter == 'all',
                                      onTap: () => setState(() => _activityFilter = 'all'),
                                    ),
                                    _buildFilterTab(
                                      label: '${AppTranslations.pick(lang, en: 'Pending', mr: 'प्रलंबित', hi: 'लंबित')} (${AppTranslations.formatDigits(pendingVal, lang)})',
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
                                  AppTranslations.pick(
                                    lang,
                                    en: 'No recent activity matching filter',
                                    mr: 'काहीही नवीन नाही.',
                                    hi: 'कोई हालिया गतिविधि नहीं।',
                                  ),
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
                                              targetLanguage: lang,
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
                                                  child: (activity.area != null && activity.area!.trim().isNotEmpty)
                                                      ? _localizedAreaText(
                                                          activity.area!.trim(),
                                                          lang,
                                                          suffix: ' • ${AppTranslations.pick(lang, en: 'Today', mr: 'आज', hi: 'आज')}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                                        )
                                                      : Text(
                                                          AppTranslations.pick(
                                                            lang,
                                                            en: 'Ward No. 12',
                                                            mr: 'प्रभाग १२',
                                                            hi: 'वार्ड १२',
                                                          ),
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
                                AppTranslations.pick(lang, en: 'View Full Log', mr: 'संपूर्ण यादी पहा', hi: 'पूरी सूची देखें'),
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
    required String lang,
  }) {
    final double pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            Text(
              AppTranslations.formatDigits(count, lang),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
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
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))]
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
                  Text(
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
            Text(
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
