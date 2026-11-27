import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../common/desktop_modal_dialog.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/language_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/services/supabase_service.dart';

/// Language state notifier for desktop UI
class DesktopLanguageNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(appLanguageProvider);
  }

  void setLanguage(String lang) {
    ref.read(appLanguageProvider.notifier).setLanguage(lang);
    state = lang;
  }
}

final desktopLanguageProvider = NotifierProvider<DesktopLanguageNotifier, String>(DesktopLanguageNotifier.new);

class NavItemData {
  final String key;
  final String label;
  final String labelMr;
  final String? labelHi;
  final IconData icon;
  final String? permission;

  const NavItemData({
    required this.key,
    required this.label,
    required this.labelMr,
    this.labelHi,
    required this.icon,
    this.permission,
  });
}

class NavGroupData {
  final String id;
  final String label;
  final String labelMr;
  final String? labelHi;
  final IconData icon;
  final List<NavItemData> items;

  const NavGroupData({
    required this.id,
    required this.label,
    required this.labelMr,
    this.labelHi,
    required this.icon,
    required this.items,
  });
}

class DesktopSidebar extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const DesktopSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  ConsumerState<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends ConsumerState<DesktopSidebar> {
  final Map<String, bool> _openGroups = {
    'daily_work': true,
    'ward_info': false,
    'municipal': false,
    'media': false,
    'programs': false,
    'political': false,
    'communication': false,
  };

  // 1) Daily Work
  static const NavGroupData _dailyWorkGroup = NavGroupData(
    id: 'daily_work',
    label: 'Daily Work',
    labelMr: 'Daily Work',
    icon: Icons.work_outline_rounded,
    items: [
      NavItemData(key: 'complaints', label: 'Requests & Complaints', labelMr: 'Requests & Complaints', icon: Icons.newspaper_rounded, permission: 'complaints'),
      NavItemData(key: 'letters', label: 'Letters', labelMr: 'Letters', icon: Icons.description_outlined, permission: 'letters'),
      NavItemData(key: 'diary', label: 'Task Management', labelMr: 'Task Management', icon: Icons.check_box_outlined, permission: 'tasks'),
      NavItemData(key: 'visitors', label: 'Visitor Log', labelMr: 'Visitor Log', icon: Icons.people_outline_rounded, permission: 'visitors'),
      NavItemData(key: 'schemes', label: 'Govt Schemes', labelMr: 'Govt Schemes', icon: Icons.assignment_turned_in_outlined, permission: 'schemes'),
    ],
  );

  // 2) Ward Information
  static const NavGroupData _wardInfoGroup = NavGroupData(
    id: 'ward_info',
    label: 'Ward Information',
    labelMr: 'Ward Information',
    icon: Icons.info_outline_rounded,
    items: [
      NavItemData(key: 'ward_problems', label: 'Ward Problems', labelMr: 'Ward Problems', icon: Icons.warning_amber_rounded, permission: 'ward_problems'),
      NavItemData(key: 'ward_map', label: 'Ward Map', labelMr: 'Ward Map', icon: Icons.map_outlined, permission: 'ward_info'),
      NavItemData(key: 'work_history', label: 'Work History', labelMr: 'Work History', icon: Icons.history_rounded, permission: 'work_history'),
      NavItemData(key: 'improvements', label: 'Possible Improvements', labelMr: 'Possible Improvements', icon: Icons.trending_up_rounded, permission: 'improvements'),
      NavItemData(key: 'provisions', label: 'Ward Wise Provision', labelMr: 'Ward Wise Provision', icon: Icons.currency_rupee_rounded, permission: 'provision'),
    ],
  );

  // 3) Municipal Work
  static const NavGroupData _municipalGroup = NavGroupData(
    id: 'municipal',
    label: 'Municipal Work',
    labelMr: 'Municipal Work',
    icon: Icons.apartment_rounded,
    items: [
      NavItemData(key: 'gb_register', label: 'GB Register', labelMr: 'GB Register', icon: Icons.menu_book_rounded, permission: 'gb_register'),
      NavItemData(key: 'ward_budget', label: 'Ward Budget', labelMr: 'Ward Budget', icon: Icons.account_balance_wallet_outlined, permission: 'budget'),
    ],
  );

  // 4) Media & Promotion
  static const NavGroupData _mediaGroup = NavGroupData(
    id: 'media',
    label: 'Media & Promotion',
    labelMr: 'Media & Promotion',
    icon: Icons.campaign_outlined,
    items: [
      NavItemData(key: 'social_analytics', label: 'Social Analytics', labelMr: 'Social Analytics', icon: Icons.insights_rounded, permission: 'social'),
      NavItemData(key: 'newspaper', label: 'Newspaper Clipping', labelMr: 'Newspaper Clipping', icon: Icons.feed_outlined, permission: 'newspaper'),
      NavItemData(key: 'media_tracking', label: 'Media Tracking', labelMr: 'Media Tracking', icon: Icons.public_rounded, permission: 'media_tracking'),
      NavItemData(key: 'ai_content', label: 'AI Content Studio', labelMr: 'AI Content Studio', icon: Icons.auto_awesome_rounded, permission: 'ai_content'),
    ],
  );

  // 5) Programs & Activities
  static const NavGroupData _programsGroup = NavGroupData(
    id: 'programs',
    label: 'Programs & Activities',
    labelMr: 'Programs & Activities',
    icon: Icons.event_note_rounded,
    items: [
      NavItemData(key: 'events', label: 'Events & Invites', labelMr: 'Events & Invites', icon: Icons.calendar_today_rounded, permission: 'events'),
      NavItemData(key: 'gallery', label: 'Gallery & Media', labelMr: 'Gallery & Media', icon: Icons.collections_outlined, permission: 'gallery'),
    ],
  );

  // 6) Political
  static const NavGroupData _politicalGroup = NavGroupData(
    id: 'political',
    label: 'Political',
    labelMr: 'Political',
    icon: Icons.flag_outlined,
    items: [
      NavItemData(key: 'result_analysis', label: 'Result Analysis', labelMr: 'Result Analysis', icon: Icons.bar_chart_rounded, permission: 'results'),
      NavItemData(key: 'sadasya', label: 'Sadasya (Members)', labelMr: 'Sadasya (Members)', icon: Icons.group_add_rounded, permission: 'sadasya'),
      NavItemData(key: 'surveys', label: 'Sample Surveys', labelMr: 'Sample Surveys', icon: Icons.ballot_outlined, permission: 'surveys'),
      NavItemData(key: 'voters', label: 'Voter Search', labelMr: 'Voter Search', icon: Icons.person_search_rounded, permission: 'voters'),
      NavItemData(key: 'team', label: 'My Team', labelMr: 'My Team', icon: Icons.supervised_user_circle_outlined, permission: 'staff'),
      NavItemData(key: 'opposition', label: 'Opposition Info', labelMr: 'Opposition Info', icon: Icons.visibility_outlined, permission: 'opposition'),
      NavItemData(key: 'ngo_mandals', label: 'NGO & Mandals Info', labelMr: 'NGO & Mandals Info', icon: Icons.corporate_fare_rounded, permission: 'social_organizations'),
      NavItemData(key: 'housing_societies', label: 'Housing Societies', labelMr: 'Housing Societies', icon: Icons.home_work_outlined, permission: 'housing_societies'),
      NavItemData(key: 'duplicate_voters', label: 'Duplicate Voters', labelMr: 'Duplicate Voters', icon: Icons.copy_all_rounded, permission: 'voters'),
      NavItemData(key: 'voter_forms', label: 'Voter Forms', labelMr: 'Voter Forms', icon: Icons.description_outlined, permission: 'voter_forms'),
      NavItemData(key: 'karyakarta_work', label: 'Karyakarta Work Management', labelMr: 'Karyakarta Work Management', icon: Icons.assignment_ind_outlined, permission: 'karyakarta_work'),
    ],
  );

  // 7) Public Communication
  static const NavGroupData _communicationGroup = NavGroupData(
    id: 'communication',
    label: 'Public Communication',
    labelMr: 'Public Communication',
    icon: Icons.forum_outlined,
    items: [
      NavItemData(key: 'sms', label: 'Send SMS', labelMr: 'Send SMS', icon: Icons.sms_outlined, permission: 'sms'),
      NavItemData(key: 'whatsapp_message', label: 'WhatsApp Message', labelMr: 'WhatsApp Message', icon: Icons.chat_bubble_outline_rounded, permission: 'whatsapp'),
      NavItemData(key: 'voice_call', label: 'Voice Call', labelMr: 'Voice Call', icon: Icons.phone_in_talk_rounded, permission: 'voice_call'),
      NavItemData(key: 'ai_voice_call', label: 'AI Voice Call', labelMr: 'AI Voice Call', icon: Icons.support_agent_rounded, permission: 'ai_voice_call'),
      NavItemData(key: 'conference_room', label: 'Conference Room', labelMr: 'Conference Room', icon: Icons.video_call_rounded, permission: 'conference_room'),
      NavItemData(key: 'whatsapp_call', label: 'WhatsApp Call', labelMr: 'WhatsApp Call', icon: Icons.phone_forwarded_rounded, permission: 'whatsapp_call'),
    ],
  );

  bool _checkPermission(UserModel? user, TenantState tenantState, String? perm) {
    if (perm == null || perm.isEmpty) return true;
    if (!tenantState.hasFeature(perm)) return false;
    if (user != null && (user.isStaff || user.role == 'staff')) {
      final perms = user.permissions;
      if (perms.isEmpty) return false;
      const publicCommPerms = [
        'sms',
        'whatsapp',
        'voice_call',
        'ai_voice_call',
        'conference_room',
        'whatsapp_call'
      ];
      if (publicCommPerms.contains(perm) && perms.contains('public_comm')) {
        return true;
      }
      return perms.contains(perm);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final activeKey = ref.watch(activeScreenProvider);
    final user = ref.watch(authStateProvider).value;
    final tenantState = ref.watch(tenantProvider);
    final currentLang = ref.watch(desktopLanguageProvider);
    final isMr = currentLang == 'mr';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: widget.isCollapsed ? 80 : 288,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.slate200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Branding Header
          _buildHeader(tenantState, isMr),

          // Scrollable Navigation Menu in exact AppLayout.tsx sequence
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 8 : 12,
                vertical: 14,
              ),
              children: [
                // 1. Dashboard (Always on top)
                _buildNavItem(
                  key: 'dashboard',
                  label: AppTranslations.getNavTitle('dashboard', currentLang),
                  icon: Icons.dashboard_rounded,
                  isActive: activeKey == 'dashboard',
                ),
                const SizedBox(height: 4),

                // 2. Daily Work
                _buildNavGroup(_dailyWorkGroup, activeKey, currentLang, user, tenantState),
                const SizedBox(height: 4),

                // 3. Ward Information
                _buildNavGroup(_wardInfoGroup, activeKey, currentLang, user, tenantState),
                const SizedBox(height: 4),

                // 4. Municipal Work
                _buildNavGroup(_municipalGroup, activeKey, currentLang, user, tenantState),
                const SizedBox(height: 4),

                // 5. Government Office (Exactly between Municipal Work and Media)
                if (_checkPermission(user, tenantState, 'gov_office')) ...[
                  _buildNavItem(
                    key: 'gov_office',
                    label: AppTranslations.getNavTitle('gov_office', currentLang),
                    icon: Icons.account_balance_rounded,
                    isActive: activeKey == 'gov_office',
                  ),
                  const SizedBox(height: 4),
                ],

                // 6. Media & Promotion
                _buildNavGroup(_mediaGroup, activeKey, currentLang, user, tenantState),
                const SizedBox(height: 4),

                // 7. Programs & Activities
                _buildNavGroup(_programsGroup, activeKey, currentLang, user, tenantState),
                const SizedBox(height: 4),

                // 8. Political
                _buildNavGroup(_politicalGroup, activeKey, currentLang, user, tenantState),
                const SizedBox(height: 4),

                // 9. Public Communication
                _buildNavGroup(_communicationGroup, activeKey, currentLang, user, tenantState),
                const SizedBox(height: 4),

                // 10. Analysis & Strategy (Immediately following Public Communication)
                if (_checkPermission(user, tenantState, 'analysis')) ...[
                  _buildNavItem(
                    key: 'analysis_strategy',
                    label: AppTranslations.getNavTitle('analysis_strategy', currentLang),
                    icon: Icons.query_stats_rounded,
                    isActive: activeKey == 'analysis_strategy',
                  ),
                ],
              ],
            ),
          ),

          // Footer (Profile & Settings)
          _buildFooter(user),
        ],
      ),
    );
  }

  Widget _buildHeader(TenantState tenantState, bool isMr) {
    final tenant = tenantState.tenant;
    final headerTitle = isMr
        ? (tenant?.displayNameMarathi ?? 'नगरसेवक कार्यालय')
        : (tenant?.displayNameEnglish ?? 'Nagar Sevak');
    final headerSubtitle = tenant != null && tenant.partyName.isNotEmpty
        ? '${tenant.partyName} | ${tenant.wardName.isNotEmpty ? tenant.wardName : 'Operations & Staff'}'
        : (tenant?.wardName.isNotEmpty == true ? tenant!.wardName : 'Operations & Staff');

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 12 : 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.slate100)),
      ),
      child: Row(
        mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.isCollapsed) ...[
            Expanded(
              child: InkWell(
                onTap: () => ref.read(activeScreenProvider.notifier).resetToDashboard(),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand600.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          headerTitle.isNotEmpty ? headerTitle[0].toUpperCase() : 'N',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            headerSubtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onToggleCollapse,
              icon: const Icon(Icons.menu_open_rounded, size: 20, color: AppColors.slate500),
              tooltip: 'Collapse Sidebar',
              hoverColor: AppColors.slate100,
            ),
          ] else ...[
            InkWell(
              onTap: widget.onToggleCollapse,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    headerTitle.isNotEmpty ? headerTitle[0].toUpperCase() : 'N',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String key,
    required String label,
    required IconData icon,
    required bool isActive,
    bool isNested = false,
  }) {
    final content = InkWell(
      onTap: () => ref.read(activeScreenProvider.notifier).setScreen(key),
      borderRadius: BorderRadius.circular(10),
      hoverColor: AppColors.brand50.withValues(alpha: 0.6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCollapsed ? 0 : 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brand600 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.brand600.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 19,
              color: isActive ? Colors.white : AppColors.slate500,
            ),
            if (!widget.isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.white : AppColors.slate700,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.isCollapsed) {
      return Tooltip(
        message: label,
        preferBelow: false,
        verticalOffset: 20,
        child: content,
      );
    }
    return content;
  }

  String _getItemLabel(NavItemData item, String lang) {
    if (lang == 'en') return item.label;
    final nav = AppTranslations.getNavTitle(item.key, lang);
    if (nav != item.key && nav != 'nav.${item.key}') return nav;
    return AppTranslations.translateDirect(item.label, lang: lang);
  }

  String _getGroupLabel(NavGroupData group, String lang) {
    if (lang == 'en') return group.label;
    final nav = AppTranslations.getNavTitle(group.id, lang);
    if (nav != group.id && nav != 'nav.${group.id}') return nav;
    return AppTranslations.translateDirect(group.label, lang: lang);
  }

  Widget _buildNavGroup(NavGroupData group, String activeKey, String lang, UserModel? user, TenantState tenantState) {
    final visibleItems = group.items.where((item) => _checkPermission(user, tenantState, item.permission)).toList();
    if (visibleItems.isEmpty) return const SizedBox.shrink();

    final isOpen = _openGroups[group.id] ?? false;
    final hasActiveChild = visibleItems.any((item) => item.key == activeKey);

    if (widget.isCollapsed) {
      // In collapsed mode, render primary items directly or with hover popup
      final activeChild = visibleItems.cast<NavItemData?>().firstWhere(
            (i) => i?.key == activeKey,
            orElse: () => null,
          );
      final iconToUse = activeChild?.icon ?? group.icon;

      return Tooltip(
        message: _getGroupLabel(group, lang),
        child: InkWell(
          onTap: () {
            setState(() {
              _openGroups[group.id] = true;
            });
            widget.onToggleCollapse();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: hasActiveChild ? AppColors.brand50 : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                iconToUse,
                size: 20,
                color: hasActiveChild ? AppColors.brand600 : AppColors.slate500,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Header
        InkWell(
          onTap: () {
            setState(() {
              _openGroups[group.id] = !isOpen;
            });
          },
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.slate100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  group.icon,
                  size: 18,
                  color: hasActiveChild ? AppColors.brand600 : AppColors.slate500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getGroupLabel(group, lang),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasActiveChild ? FontWeight.w700 : FontWeight.w600,
                      color: hasActiveChild ? AppColors.brand700 : AppColors.slate700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: AppColors.slate400,
                ),
              ],
            ),
          ),
        ),

        // Expanded Children
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 2, bottom: 4),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.slate200, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: visibleItems.map((item) {
                  final isActive = item.key == activeKey;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: _buildNavItem(
                      key: item.key,
                      label: _getItemLabel(item, lang),
                      icon: item.icon,
                      isActive: isActive,
                      isNested: true,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(dynamic user) {
    return Container(
      padding: EdgeInsets.all(widget.isCollapsed ? 8 : 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate100)),
      ),
      child: Column(
        children: [
          if (!widget.isCollapsed) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: AppLanguageSegmentedSelector(isCompact: true),
            ),
            Row(
              children: [
                InkWell(
                  onTap: () => ref.read(activeScreenProvider.notifier).setScreen('profile_settings'),
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.brand100,
                    child: Text(
                      (user?.name?.isNotEmpty == true) ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.brand700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => ref.read(activeScreenProvider.notifier).setScreen('profile_settings'),
                    borderRadius: BorderRadius.circular(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Administrator',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.role?.toUpperCase() ?? 'OFFICE ADMIN',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Settings',
                  child: IconButton(
                    onPressed: () => ref.read(activeScreenProvider.notifier).setScreen('profile_settings'),
                    icon: const Icon(Icons.settings_outlined, size: 18, color: AppColors.slate400),
                    hoverColor: AppColors.brand50,
                  ),
                ),
                Tooltip(
                  message: 'Sign Out',
                  child: IconButton(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.slate400),
                    hoverColor: Colors.red.shade50,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Tooltip(
              message: 'Sign Out',
              child: IconButton(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.slate500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => DesktopModalDialog(
        title: 'Sign Out',
        subtitle: 'Are you sure you want to sign out from the administrative desktop portal?',
        icon: Icons.logout_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
        width: 480,
        onClose: () => Navigator.of(ctx).pop(),
        actions: [
          DesktopModalDialog.cancelButton(ctx),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await SupabaseService.instance.client.auth.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        child: const Text(
          'Your active session will be closed and you will be returned to the sign-in screen.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
        ),
      ),
    );
  }
}
