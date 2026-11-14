import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
// 1. Bottom Bar Customizable Slots (3 slots: Tab 0, Tab 1, Tab 2. Tab 3 is fixed)
// ─────────────────────────────────────────────────────────────────────────────
const List<String> kDefaultBottomBarSlots = [
  'dashboard',   // Tab 0
  'complaints',  // Tab 1
  'letters',     // Tab 2
];

class CustomBottomBarNotifier extends Notifier<List<String>> {
  static const String _prefKey = 'custom_bottom_bar_slots';

  @override
  List<String> build() {
    _loadFromPrefs();
    return List.from(kDefaultBottomBarSlots);
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefKey);
      if (saved != null && saved.length == 3) {
        state = List.from(saved);
      }
    } catch (_) {}
  }

  Future<void> setSlot(int slotIndex, String moduleKey) async {
    if (slotIndex < 0 || slotIndex >= 3) return;
    final updated = List<String>.from(state);
    updated[slotIndex] = moduleKey;
    state = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, updated);
    } catch (_) {}
  }

  Future<void> resetToDefaults() async {
    state = List.from(kDefaultBottomBarSlots);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, kDefaultBottomBarSlots);
    } catch (_) {}
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
  static const String _prefKey = 'custom_quick_action_slots_v5';

  @override
  List<String> build() {
    _loadFromPrefs();
    return List.from(kDefaultQuickActionSlots);
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefKey);
      if (saved != null && saved.length == 5) {
        state = List.from(saved);
      }
    } catch (_) {}
  }

  Future<void> setSlot(int slotIndex, String moduleKey) async {
    if (slotIndex < 0 || slotIndex >= 5) return;
    final updated = List<String>.from(state);
    updated[slotIndex] = moduleKey;
    state = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, updated);
    } catch (_) {}
  }

  Future<void> resetToDefaults() async {
    state = List.from(kDefaultQuickActionSlots);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, kDefaultQuickActionSlots);
    } catch (_) {}
  }
}

final customQuickActionsProvider =
    NotifierProvider<CustomQuickActionsNotifier, List<String>>(CustomQuickActionsNotifier.new);
