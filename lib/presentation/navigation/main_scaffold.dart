import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lazy_indexed_stack.dart';
import '../providers/navigation_provider.dart';

// All 39 Screens
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/complaints/complaints_screen.dart';
import '../screens/letters/letters_screen.dart';
import '../screens/settings/profile_settings_screen.dart';
import '../screens/diary/diary_screen.dart';
import '../screens/visitors/visitors_screen.dart';
import '../screens/schemes/government_schemes_screen.dart';
import '../screens/ward_problems/ward_problems_screen.dart';
import '../screens/ward_map/ward_map_screen.dart';
import '../screens/works/work_history_screen.dart';
import '../screens/ward_improvements/possible_improvements_screen.dart';
import '../screens/ward_provisions/ward_provisions_screen.dart';
import '../screens/gb_register/gb_register_screen.dart';
import '../screens/ward_budget/ward_budget_screen.dart';
import '../screens/government_office/government_office_screen.dart';
import '../screens/social/social_analytics_screen.dart';
import '../screens/newspaper/newspaper_clippings_screen.dart';
import '../screens/media_tracking/media_tracking_screen.dart';
import '../screens/content_studio/ai_content_studio_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/results/result_analysis_screen.dart';
import '../screens/sadasya/sadasya_screen.dart';
import '../screens/surveys/surveys_screen.dart';
import '../screens/voters/voters_screen.dart';
import '../screens/team/team_screen.dart';
import '../screens/opposition/opposition_screen.dart';
import '../screens/social_organizations/social_organizations_screen.dart';
import '../screens/housing_societies/housing_societies_screen.dart';
import '../screens/duplicate_voters/duplicate_voters_screen.dart';
import '../screens/voter_forms/voter_forms_screen.dart';
import '../screens/karyakarta_work/karyakarta_work_management_screen.dart';
import '../screens/sms/sms_communication_screen.dart';
import '../screens/whatsapp/whatsapp_communication_screen.dart';
import '../screens/whatsapp/whatsapp_calling_screen.dart';
import '../screens/voice/voice_call_screen.dart';
import '../screens/voice/ai_voice_call_screen.dart';
import '../screens/voice/conference_room_screen.dart';
import '../screens/analysis_strategy/analysis_strategy_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  static const List<String> screenKeys = [
    'dashboard',           // 0
    'complaints',          // 1
    'letters',             // 2
    'profile_settings',    // 3
    'diary',               // 4
    'visitors',            // 5
    'schemes',             // 6
    'ward_problems',       // 7
    'ward_map',            // 8
    'work_history',        // 9
    'improvements',        // 10
    'provisions',          // 11
    'gb_register',         // 12
    'ward_budget',         // 13
    'gov_office',          // 14
    'social_analytics',    // 15
    'newspaper',           // 16
    'media_tracking',      // 17
    'ai_content',          // 18
    'events',              // 19
    'gallery',             // 20
    'result_analysis',     // 21
    'sadasya',             // 22
    'surveys',             // 23
    'voters',              // 24
    'team',                // 25
    'opposition',          // 26
    'ngo_mandals',         // 27
    'housing_societies',   // 28
    'duplicate_voters',    // 29
    'voter_forms',         // 30
    'karyakarta_work',     // 31
    'sms',                 // 32
    'whatsapp_message',    // 33
    'whatsapp_call',       // 34
    'voice_call',          // 35
    'ai_voice_call',       // 36
    'conference_room',     // 37
    'analysis_strategy',   // 38
  ];

  late final List<WidgetBuilder> _builders;

  @override
  void initState() {
    super.initState();
    _builders = [
      (BuildContext ctx) => DashboardScreen(onTabChange: _onTabChange),
      (BuildContext ctx) => ComplaintsScreen(
            onBackToHome: () => _onTabChange(0),
            onTabChange: _onTabChange,
          ),
      (BuildContext ctx) => LettersScreen(onTabChange: _onTabChange),
      (BuildContext ctx) => ProfileSettingsScreen(
            onBackToHome: () => _onTabChange(0),
            onTabChange: _onTabChange,
          ),
      (BuildContext ctx) => const DiaryScreen(),
      (BuildContext ctx) => const VisitorsScreen(),
      (BuildContext ctx) => GovernmentSchemesScreen(onTabChange: _onTabChange),
      (BuildContext ctx) => const WardProblemsScreen(),
      (BuildContext ctx) => const WardMapScreen(),
      (BuildContext ctx) => const WorkHistoryScreen(),
      (BuildContext ctx) => const PossibleImprovementsScreen(),
      (BuildContext ctx) => const WardProvisionsScreen(),
      (BuildContext ctx) => const GbRegisterScreen(),
      (BuildContext ctx) => const WardBudgetScreen(),
      (BuildContext ctx) => const GovernmentOfficeScreen(),
      (BuildContext ctx) => const SocialAnalyticsScreen(),
      (BuildContext ctx) => const NewspaperClippingsScreen(),
      (BuildContext ctx) => const MediaTrackingScreen(),
      (BuildContext ctx) => const AiContentStudioScreen(),
      (BuildContext ctx) => const EventsScreen(),
      (BuildContext ctx) => const GalleryScreen(),
      (BuildContext ctx) => const ResultAnalysisScreen(),
      (BuildContext ctx) => const SadasyaScreen(),
      (BuildContext ctx) => const SurveysScreen(),
      (BuildContext ctx) => const VotersScreen(),
      (BuildContext ctx) => const TeamScreen(),
      (BuildContext ctx) => const OppositionScreen(),
      (BuildContext ctx) => const SocialOrganizationsScreen(),
      (BuildContext ctx) => const HousingSocietiesScreen(),
      (BuildContext ctx) => const DuplicateVotersScreen(),
      (BuildContext ctx) => const VoterFormsScreen(),
      (BuildContext ctx) => const KaryakartaWorkManagementScreen(),
      (BuildContext ctx) => const SmsCommunicationScreen(),
      (BuildContext ctx) => const WhatsAppCommunicationScreen(),
      (BuildContext ctx) => const WhatsAppCallingScreen(),
      (BuildContext ctx) => const VoiceCallScreen(),
      (BuildContext ctx) => const AiVoiceCallScreen(),
      (BuildContext ctx) => const ConferenceRoomScreen(),
      (BuildContext ctx) => const AnalysisStrategyScreen(),
    ];
  }

  void _onTabChange(int index) {
    ref.read(mainTabIndexProvider.notifier).setTab(index);
    if (index >= 0 && index < 4) {
      ref.read(activeScreenProvider.notifier).setScreen(screenKeys[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeScreen = ref.watch(activeScreenProvider);
    var index = screenKeys.indexOf(activeScreen);
    if (index == -1) index = 0;

    final isMainTab = index < 4;
    final bottomBarIndex = isMainTab ? index : 0;

    return PopScope(
      canPop: activeScreen == 'dashboard',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(activeScreenProvider.notifier).setScreen('dashboard');
          ref.read(mainTabIndexProvider.notifier).setTab(0);
        }
      },
      child: Scaffold(
        body: LazyIndexedStack(
          index: index,
          builders: _builders,
        ),
        bottomNavigationBar: isMainTab
            ? Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: bottomBarIndex,
                  onTap: _onTabChange,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: const Color(0xFF0284C7),
                  unselectedItemColor: const Color(0xFF64748B),
                  selectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      activeIcon: Icon(Icons.dashboard_rounded),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.assignment_outlined),
                      activeIcon: Icon(Icons.assignment_rounded),
                      label: 'Requests',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.mail_outline_rounded),
                      activeIcon: Icon(Icons.mail_rounded),
                      label: 'Letters',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      activeIcon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
