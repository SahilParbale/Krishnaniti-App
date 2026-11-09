import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lazy_indexed_stack.dart';
import 'curved_bottom_bar.dart';
import 'radial_quick_access_menu.dart';
import '../providers/navigation_provider.dart';
import '../screens/complaints/new_complaint_screen.dart';

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

  bool _isRadialOpen = false;
  Offset? _currentDragPosition;
  Offset _fabCenterOffset = Offset.zero;

  void _onTabChange(int index) {
    ref.read(mainTabIndexProvider.notifier).setTab(index);
    if (index >= 0 && index < 4) {
      ref.read(activeScreenProvider.notifier).setScreen(screenKeys[index]);
    }
  }

  void _onFabPointerDown(PointerDownEvent event) {
    final media = MediaQuery.of(context);
    final cx = media.size.width / 2;
    final cy = media.size.height - media.padding.bottom - 63.0;

    setState(() {
      _fabCenterOffset = Offset(cx, cy);
      _currentDragPosition = event.position;
      _isRadialOpen = true;
    });
  }

  void _onFabPointerMove(PointerMoveEvent event) {
    if (_isRadialOpen) {
      setState(() {
        _currentDragPosition = event.position;
      });
    }
  }

  int _findClosestItemIndex(Offset pos) {
    final centerDist = (pos - _fabCenterOffset).distance;
    if (centerDist < 38.0) return -1;

    int closestIdx = -1;
    double minDist = 999999.0;
    for (int i = 0; i < RadialQuickAccessMenu.items.length; i++) {
      final itemPos = RadialQuickAccessMenu.items[i].getPosition(
        _fabCenterOffset,
        RadialQuickAccessMenu.kArcRadius,
      );
      final dist = (pos - itemPos).distance;
      if (dist < minDist) {
        minDist = dist;
        closestIdx = i;
      }
    }

    if (minDist <= 50.0) {
      return closestIdx;
    }
    return -1;
  }

  void _onFabPointerUp(PointerUpEvent event) {
    if (_isRadialOpen) {
      final idx = _findClosestItemIndex(event.position);
      if (idx != -1) {
        final selectedItem = RadialQuickAccessMenu.items[idx];
        HapticFeedback.mediumImpact();
        _handleRadialSelect(selectedItem.id);
        return;
      }

      // User removed their finger without selecting an item: close immediately by default
      setState(() {
        _isRadialOpen = false;
        _currentDragPosition = null;
      });
    }
  }

  void _onFabPointerCancel() {
    if (_isRadialOpen) {
      setState(() {
        _isRadialOpen = false;
        _currentDragPosition = null;
      });
    }
  }

  void _openRadialMenu() {
    HapticFeedback.heavyImpact();
    final media = MediaQuery.of(context);
    final cx = media.size.width / 2;
    final cy = media.size.height - media.padding.bottom - 63.0;
    setState(() {
      _fabCenterOffset = Offset(cx, cy);
      _currentDragPosition = null;
      _isRadialOpen = true;
    });
  }

  void _handleRadialSelect(String id) {
    setState(() {
      _isRadialOpen = false;
      _currentDragPosition = null;
    });

    switch (id) {
      case 'works':
        ref.read(activeScreenProvider.notifier).setScreen('work_history');
        break;
      case 'request':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewComplaintScreen()),
        );
        break;
      case 'letters':
        _onTabChange(2);
        break;
      case 'voters':
        ref.read(activeScreenProvider.notifier).setScreen('voters');
        break;
      case 'diary':
        ref.read(activeScreenProvider.notifier).setScreen('diary');
        break;
      case 'visitors':
        ref.read(activeScreenProvider.notifier).setScreen('visitors');
        break;
      case 'ai_content':
        ref.read(activeScreenProvider.notifier).setScreen('ai_content');
        break;
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
      canPop: activeScreen == 'dashboard' && !_isRadialOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (_isRadialOpen) {
          setState(() {
            _isRadialOpen = false;
            _currentDragPosition = null;
          });
          return;
        }
        if (!didPop) {
          ref.read(activeScreenProvider.notifier).setScreen('dashboard');
          ref.read(mainTabIndexProvider.notifier).setTab(0);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: LazyIndexedStack(
              index: index,
              builders: _builders,
            ),
            bottomNavigationBar: isMainTab
                ? CurvedBottomBar(
                    currentIndex: bottomBarIndex,
                    onTap: _onTabChange,
                    onFabTap: _openRadialMenu,
                    onFabPointerDown: _onFabPointerDown,
                    onFabPointerMove: _onFabPointerMove,
                    onFabPointerUp: _onFabPointerUp,
                    onFabPointerCancel: _onFabPointerCancel,
                  )
                : null,
          ),

          // Semicircular Gesture-Driven Radial Quick Access Overlay
          if (_isRadialOpen)
            RadialQuickAccessMenu(
              centerOffset: _fabCenterOffset,
              dragPosition: _currentDragPosition,
              onSelect: _handleRadialSelect,
              onClose: () {
                setState(() {
                  _isRadialOpen = false;
                  _currentDragPosition = null;
                });
              },
            ),
        ],
      ),
    );
  }
}
