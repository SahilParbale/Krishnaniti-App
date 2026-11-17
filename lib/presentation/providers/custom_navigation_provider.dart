import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/bar_customization_repository.dart';
import 'auth_provider.dart';

class NavItemConfig {
  final String key;
  final String titleEn;
  final String titleMr;
  final IconData icon;
  final String category;

  const NavItemConfig({
    required this.key,
    required this.titleEn,
    required this.titleMr,
    required this.icon,
    required this.category,
  });
}

/// All available selectable modules in the application (excluding fixed profile_settings)
const List<NavItemConfig> kAllAvailableModules = [
  NavItemConfig(
    key: 'dashboard',
    titleEn: 'Dashboard',
    titleMr: 'डॅशबोर्ड',
    icon: Icons.dashboard_rounded,
    category: 'Overview',
  ),
  NavItemConfig(
    key: 'complaints',
    titleEn: 'Requests & Complaints',
    titleMr: 'तक्रारी आणि विनंती',
    icon: Icons.add_task_rounded,
    category: 'Daily work',
  ),
  NavItemConfig(
    key: 'letters',
    titleEn: 'Letters',
    titleMr: 'पत्र व्यवहार',
    icon: Icons.mark_email_unread_rounded,
    category: 'Daily work',
  ),
  NavItemConfig(
    key: 'diary',
    titleEn: 'Diary',
    titleMr: 'दैनंदिनी नोंद',
    icon: Icons.event_note_rounded,
    category: 'Daily work',
  ),
  NavItemConfig(
    key: 'visitors',
    titleEn: 'Visitor Log',
    titleMr: 'कार्यालय भेट',
    icon: Icons.badge_rounded,
    category: 'Daily work',
  ),
  NavItemConfig(
    key: 'schemes',
    titleEn: 'Govt Schemes',
    titleMr: 'शासकीय योजना',
    icon: Icons.account_balance_rounded,
    category: 'Daily work',
  ),
  NavItemConfig(
    key: 'ward_problems',
    titleEn: 'Ward Problems',
    titleMr: 'प्रभाग समस्या',
    icon: Icons.report_problem_rounded,
    category: 'Ward management',
  ),
  NavItemConfig(
    key: 'ward_map',
    titleEn: 'Ward Map',
    titleMr: 'प्रभाग नकाशा',
    icon: Icons.map_rounded,
    category: 'Ward management',
  ),
  NavItemConfig(
    key: 'work_history',
    titleEn: 'Work History',
    titleMr: 'विकास कामे',
    icon: Icons.engineering_rounded,
    category: 'Ward management',
  ),
  NavItemConfig(
    key: 'improvements',
    titleEn: 'Ward Improvements',
    titleMr: 'विकास कामे सुधारणा',
    icon: Icons.trending_up_rounded,
    category: 'Ward management',
  ),
  NavItemConfig(
    key: 'provisions',
    titleEn: 'Ward Wise Provision',
    titleMr: 'प्रभागनिहाय तरतूद',
    icon: Icons.account_tree_rounded,
    category: 'Ward management',
  ),
  NavItemConfig(
    key: 'gb_register',
    titleEn: 'GB Register',
    titleMr: 'महासभा नोंदवही',
    icon: Icons.menu_book_rounded,
    category: 'Office & Records',
  ),
  NavItemConfig(
    key: 'ward_budget',
    titleEn: 'Ward Budget',
    titleMr: 'प्रभाग अंदाजपत्रक',
    icon: Icons.pie_chart_rounded,
    category: 'Office & Records',
  ),
  NavItemConfig(
    key: 'gov_office',
    titleEn: 'Government office',
    titleMr: 'शासकीय कार्यालये',
    icon: Icons.location_city_rounded,
    category: 'Office & Records',
  ),
  NavItemConfig(
    key: 'social_analytics',
    titleEn: 'Social Analytics',
    titleMr: 'सोशल मीडिया विश्लेषण',
    icon: Icons.analytics_rounded,
    category: 'Media & PR',
  ),
  NavItemConfig(
    key: 'newspaper',
    titleEn: 'Newspaper Clipping',
    titleMr: 'वृत्तपत्र कात्रणे',
    icon: Icons.newspaper_rounded,
    category: 'Media & PR',
  ),
  NavItemConfig(
    key: 'media_tracking',
    titleEn: 'Media Tracking',
    titleMr: 'माध्यम मागोवा',
    icon: Icons.tv_rounded,
    category: 'Media & PR',
  ),
  NavItemConfig(
    key: 'ai_content',
    titleEn: 'AI Content Studio',
    titleMr: 'AI प्रसिद्धी',
    icon: Icons.auto_awesome_rounded,
    category: 'Media & PR',
  ),
  NavItemConfig(
    key: 'events',
    titleEn: 'Events & Invites',
    titleMr: 'कार्यक्रम आणि आमंत्रणे',
    icon: Icons.celebration_rounded,
    category: 'Media & PR',
  ),
  NavItemConfig(
    key: 'gallery',
    titleEn: 'Gallery & Media',
    titleMr: 'छायाचित्रे व व्हिडिओ',
    icon: Icons.photo_library_rounded,
    category: 'Media & PR',
  ),
  NavItemConfig(
    key: 'result_analysis',
    titleEn: 'Result Analysis',
    titleMr: 'निवडणूक निकाल विश्लेषण',
    icon: Icons.how_to_vote_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'sadasya',
    titleEn: 'Sadasya (Members)',
    titleMr: 'पक्ष सदस्य नोंदणी',
    icon: Icons.card_membership_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'surveys',
    titleEn: 'Surveys',
    titleMr: 'जनमत चाचण्या',
    icon: Icons.poll_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'voters',
    titleEn: 'Voter Search',
    titleMr: 'मतदार शोध',
    icon: Icons.person_search_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'team',
    titleEn: 'My Team',
    titleMr: 'माझा कार्यसंघ',
    icon: Icons.groups_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'opposition',
    titleEn: 'Opposition Information',
    titleMr: 'विरोधी पक्षाची माहिती',
    icon: Icons.visibility_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'ngo_mandals',
    titleEn: 'NGO & Mandals Info',
    titleMr: 'मंडळे व सामाजिक संस्था',
    icon: Icons.diversity_3_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'housing_societies',
    titleEn: 'Housing Societies',
    titleMr: 'गृहनिर्माण संस्था',
    icon: Icons.apartment_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'duplicate_voters',
    titleEn: 'Duplicate Voters',
    titleMr: 'ड्युप्लिकेट मतदार',
    icon: Icons.copy_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'voter_forms',
    titleEn: 'Voter Forms',
    titleMr: 'मतदार अर्ज',
    icon: Icons.edit_note_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'karyakarta_work',
    titleEn: 'Karyakarta Work',
    titleMr: 'कार्यकर्ता काम वाटप',
    icon: Icons.assignment_ind_rounded,
    category: 'Electoral & Field',
  ),
  NavItemConfig(
    key: 'sms',
    titleEn: 'Send SMS',
    titleMr: 'SMS पाठवा',
    icon: Icons.sms_rounded,
    category: 'Communication',
  ),
  NavItemConfig(
    key: 'whatsapp_message',
    titleEn: 'WhatsApp Message',
    titleMr: 'व्हॉट्सॲप मेसेज',
    icon: Icons.chat_rounded,
    category: 'Communication',
  ),
  NavItemConfig(
    key: 'whatsapp_call',
    titleEn: 'WhatsApp Calling',
    titleMr: 'व्हॉट्सॲप कॉलिंग',
    icon: Icons.phone_in_talk_rounded,
    category: 'Communication',
  ),
  NavItemConfig(
    key: 'voice_call',
    titleEn: 'Voice Call',
    titleMr: 'व्हॉईस कॉल',
    icon: Icons.call_rounded,
    category: 'Communication',
  ),
  NavItemConfig(
    key: 'ai_voice_call',
    titleEn: 'AI Voice Call',
    titleMr: 'AI व्हॉईस कॉल',
    icon: Icons.record_voice_over_rounded,
    category: 'Communication',
  ),
  NavItemConfig(
    key: 'conference_room',
    titleEn: 'Conference Room',
    titleMr: 'कॉन्फरन्स रूम',
    icon: Icons.video_call_rounded,
    category: 'Communication',
  ),
  NavItemConfig(
    key: 'analysis_strategy',
    titleEn: 'Analysis Strategy',
    titleMr: 'विश्लेषण आणि धोरण',
    icon: Icons.psychology_rounded,
    category: 'Communication',
  ),
];

/// Helper to find a module config by its key
NavItemConfig getModuleConfig(String key) {
  for (final item in kAllAvailableModules) {
    if (item.key == key) return item;
  }
  if (key == 'profile_settings') {
    return const NavItemConfig(
      key: 'profile_settings',
      titleEn: 'Profile Settings',
      titleMr: 'प्रोफाईल सेटिंग्ज',
      icon: Icons.person_rounded,
      category: 'System',
    );
  }
  // Default fallback
  return const NavItemConfig(
    key: 'dashboard',
    titleEn: 'Dashboard',
    titleMr: 'डॅशबोर्ड',
    icon: Icons.dashboard_rounded,
    category: 'Overview',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 0. Permission Evaluation for Team Members
// ─────────────────────────────────────────────────────────────────────────────

/// Checks if a user has permission to access and configure a specific module.
/// Admins have full access to all modules. Team members (staff) only have access
/// to modules matching their assigned permissions list.
bool userHasModulePermission(UserModel? user, String moduleKey) {
  if (user == null || user.isAdmin) return true;
  if (!user.isStaff) return true;

  // Overview and system settings are always accessible
  if (moduleKey == 'dashboard' || moduleKey == 'profile_settings') return true;

  final perms = user.permissions;
  if (perms.isEmpty) return false;

  switch (moduleKey) {
    case 'complaints':
      return perms.contains('complaints');
    case 'letters':
      return perms.contains('letters');
    case 'diary':
      return perms.contains('tasks') || perms.contains('diary');
    case 'visitors':
      return perms.contains('visitors');
    case 'schemes':
      return perms.contains('schemes');
    case 'ward_problems':
      return perms.contains('ward_problems');
    case 'ward_map':
      return perms.contains('ward_info') || perms.contains('ward_map');
    case 'work_history':
      return perms.contains('work_history');
    case 'improvements':
      return perms.contains('improvements');
    case 'provisions':
      return perms.contains('provision') || perms.contains('provisions');
    case 'gb_register':
      return perms.contains('gb_register');
    case 'ward_budget':
      return perms.contains('budget') || perms.contains('ward_budget');
    case 'gov_office':
      return perms.contains('gov_office');
    case 'social_analytics':
      return perms.contains('social') || perms.contains('social_analytics');
    case 'newspaper':
      return perms.contains('newspaper');
    case 'media_tracking':
      return perms.contains('media_tracking');
    case 'ai_content':
      return perms.contains('ai_content');
    case 'events':
      return perms.contains('events');
    case 'gallery':
      return perms.contains('gallery');
    case 'result_analysis':
      return perms.contains('results') || perms.contains('result_analysis');
    case 'sadasya':
      return perms.contains('sadasya');
    case 'surveys':
      return perms.contains('surveys');
    case 'voters':
      return perms.contains('voters');
    case 'team':
      return perms.contains('staff') || perms.contains('team');
    case 'opposition':
      return perms.contains('opposition');
    case 'ngo_mandals':
      return perms.contains('social_organizations') || perms.contains('ngo_mandals');
    case 'housing_societies':
      return perms.contains('housing_societies');
    case 'duplicate_voters':
      return perms.contains('voters') || perms.contains('duplicate_voters');
    case 'voter_forms':
      return perms.contains('voter_forms');
    case 'karyakarta_work':
      return perms.contains('karyakarta_work');
    case 'sms':
      return perms.contains('public_comm') || perms.contains('sms');
    case 'whatsapp_message':
      return perms.contains('public_comm') || perms.contains('whatsapp') || perms.contains('whatsapp_message');
    case 'whatsapp_call':
      return perms.contains('public_comm') || perms.contains('whatsapp_call');
    case 'voice_call':
      return perms.contains('public_comm') || perms.contains('voice_call');
    case 'ai_voice_call':
      return perms.contains('public_comm') || perms.contains('ai_voice_call');
    case 'conference_room':
      return perms.contains('public_comm') || perms.contains('conference_room');
    case 'analysis_strategy':
      return perms.contains('analysis') || perms.contains('analysis_strategy');
    default:
      return perms.contains(moduleKey);
  }
}

/// Returns the selectable modules available for the current user.
/// For team members, this filters out any restricted modules so only allowed
/// features are visible in the customization picker.
final permittedModulesProvider = Provider<List<NavItemConfig>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.isAdmin) {
    return kAllAvailableModules;
  }
  return kAllAvailableModules.where((item) => userHasModulePermission(user, item.key)).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// 1. Bottom Bar Customizable Slots (3 slots: Tab 0, Tab 1, Tab 2. Tab 3 is fixed)
// ─────────────────────────────────────────────────────────────────────────────
const List<String> kDefaultBottomBarSlots = [
  'dashboard',   // Tab 0
  'complaints',  // Tab 1
  'letters',     // Tab 2
];

class CustomBottomBarNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    // 1. Start with defaults or cached local slots
    _initSlots();
    return List.from(kDefaultBottomBarSlots);
  }

  Future<void> _initSlots() async {
    final repo = ref.read(barCustomizationRepoProvider);
    final user = ref.read(currentUserProvider);

    // Load from local storage cache first for instant UI
    final cached = await repo.getLocalBottomSlots();
    if (cached != null && cached.length == 3) {
      state = _sanitizeForUser(cached, user);
    }

    // Then pull latest from Supabase Database
    final dbResult = await repo.loadFromDatabase(
      userId: user?.id,
      isStaff: user?.isStaff ?? false,
    );
    if (dbResult.bottomSlots != null && dbResult.bottomSlots!.length == 3) {
      state = _sanitizeForUser(dbResult.bottomSlots!, user);
    }
  }

  List<String> _sanitizeForUser(List<String> rawSlots, UserModel? user) {
    if (user == null || user.isAdmin) return List.from(rawSlots);
    final permitted = kAllAvailableModules
        .where((m) => userHasModulePermission(user, m.key))
        .map((m) => m.key)
        .toList();

    final sanitized = <String>[];
    for (int i = 0; i < 3; i++) {
      if (i < rawSlots.length && (rawSlots[i] == 'dashboard' || permitted.contains(rawSlots[i]))) {
        sanitized.add(rawSlots[i]);
      } else {
        // Fallback to first available permitted module not already chosen
        final fallback = permitted.firstWhere(
          (k) => !sanitized.contains(k),
          orElse: () => 'dashboard',
        );
        sanitized.add(fallback);
      }
    }
    return sanitized;
  }

  Future<void> setSlot(int slotIndex, String moduleKey) async {
    if (slotIndex < 0 || slotIndex >= 3) return;
    final updated = List<String>.from(state);
    updated[slotIndex] = moduleKey;
    state = updated;

    final repo = ref.read(barCustomizationRepoProvider);
    final user = ref.read(currentUserProvider);
    await repo.saveToDatabase(
      bottomSlots: updated,
      userId: user?.id,
      isStaff: user?.isStaff ?? false,
    );
  }

  Future<void> resetToDefaults() async {
    final user = ref.read(currentUserProvider);
    final reset = _sanitizeForUser(kDefaultBottomBarSlots, user);
    state = reset;

    final repo = ref.read(barCustomizationRepoProvider);
    await repo.saveToDatabase(
      bottomSlots: reset,
      userId: user?.id,
      isStaff: user?.isStaff ?? false,
    );
  }
}

final customBottomBarProvider =
    NotifierProvider<CustomBottomBarNotifier, List<String>>(CustomBottomBarNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// 2. Radial Quick Actions 5 Slots (Semicircular Arc from Left to Right)
// ─────────────────────────────────────────────────────────────────────────────
const List<String> kDefaultQuickActionSlots = [
  'work_history', // 0: Left Arc 162°
  'complaints',   // 1: Left Upper Arc 126°
  'voters',       // 2: Top Center Arc 90°
  'letters',      // 3: Right Upper Arc 54°
  'diary',        // 4: Right Arc 18°
];

class CustomQuickActionsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    _initSlots();
    return List.from(kDefaultQuickActionSlots);
  }

  Future<void> _initSlots() async {
    final repo = ref.read(barCustomizationRepoProvider);
    final user = ref.read(currentUserProvider);

    // Load from local storage cache first
    final cached = await repo.getLocalQuickSlots();
    if (cached != null && cached.length == 5) {
      state = _sanitizeForUser(cached, user);
    }

    // Pull latest from Supabase Database
    final dbResult = await repo.loadFromDatabase(
      userId: user?.id,
      isStaff: user?.isStaff ?? false,
    );
    if (dbResult.quickSlots != null && dbResult.quickSlots!.length == 5) {
      state = _sanitizeForUser(dbResult.quickSlots!, user);
    }
  }

  List<String> _sanitizeForUser(List<String> rawSlots, UserModel? user) {
    if (user == null || user.isAdmin) return List.from(rawSlots);
    final permitted = kAllAvailableModules
        .where((m) => userHasModulePermission(user, m.key))
        .map((m) => m.key)
        .toList();

    final sanitized = <String>[];
    for (int i = 0; i < 5; i++) {
      if (i < rawSlots.length && permitted.contains(rawSlots[i])) {
        sanitized.add(rawSlots[i]);
      } else {
        final fallback = permitted.firstWhere(
          (k) => !sanitized.contains(k),
          orElse: () => permitted.isNotEmpty ? permitted.first : 'dashboard',
        );
        sanitized.add(fallback);
      }
    }
    return sanitized;
  }

  Future<void> setSlot(int slotIndex, String moduleKey) async {
    if (slotIndex < 0 || slotIndex >= 5) return;
    final updated = List<String>.from(state);
    updated[slotIndex] = moduleKey;
    state = updated;

    final repo = ref.read(barCustomizationRepoProvider);
    final user = ref.read(currentUserProvider);
    await repo.saveToDatabase(
      quickSlots: updated,
      userId: user?.id,
      isStaff: user?.isStaff ?? false,
    );
  }

  Future<void> resetToDefaults() async {
    final user = ref.read(currentUserProvider);
    final reset = _sanitizeForUser(kDefaultQuickActionSlots, user);
    state = reset;

    final repo = ref.read(barCustomizationRepoProvider);
    await repo.saveToDatabase(
      quickSlots: reset,
      userId: user?.id,
      isStaff: user?.isStaff ?? false,
    );
  }
}

final customQuickActionsProvider =
    NotifierProvider<CustomQuickActionsNotifier, List<String>>(CustomQuickActionsNotifier.new);
