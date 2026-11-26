import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/presentation/providers/navigation_provider.dart';
import 'desktop_sidebar.dart';
import 'desktop_command_palette.dart';
import '../screens/dashboard/desktop_dashboard_view.dart';
import '../screens/complaints/desktop_complaints_view.dart';
import '../screens/letters/desktop_letters_view.dart';
import '../screens/tasks/desktop_tasks_view.dart';
import '../screens/visitors/desktop_visitors_view.dart';
import '../screens/schemes/desktop_schemes_view.dart';
import '../screens/ward_problems/desktop_ward_problems_view.dart';
import '../screens/ward_map/desktop_ward_map_view.dart';
import '../screens/works/desktop_work_history_view.dart';
import '../screens/ward/desktop_improvements_view.dart';
import '../screens/ward/desktop_provisions_view.dart';
import '../screens/gb_register/desktop_gb_register_view.dart';
import '../screens/ward_budget/desktop_ward_budget_view.dart';
import '../screens/government_office/desktop_government_office_view.dart';
import '../screens/social/desktop_social_analytics_view.dart';
import '../screens/newspaper/desktop_newspaper_view.dart';
import '../screens/media_tracking/desktop_media_tracking_view.dart';
import '../screens/content_studio/desktop_ai_content_view.dart';
import '../screens/events/desktop_events_view.dart';
import '../screens/gallery/desktop_gallery_view.dart';
import '../screens/results/desktop_result_analysis_view.dart';
import '../screens/sadasya/desktop_sadasya_view.dart';
import '../screens/surveys/desktop_surveys_view.dart';
import '../screens/voters/desktop_voters_view.dart';
import '../screens/team/desktop_team_view.dart';
import '../screens/political/desktop_opposition_view.dart';
import '../screens/political/desktop_ngo_mandals_view.dart';
import '../screens/political/desktop_housing_societies_view.dart';
import '../screens/political/desktop_duplicate_voters_view.dart';
import '../screens/political/desktop_voter_forms_view.dart';
import '../screens/political/desktop_karyakarta_work_view.dart';
import '../screens/political/desktop_analysis_strategy_view.dart';
import '../screens/communication/desktop_sms_view.dart';
import '../screens/communication/desktop_whatsapp_view.dart';
import '../screens/communication/desktop_whatsapp_calling_view.dart';
import '../screens/communication/desktop_voice_call_view.dart';
import '../screens/communication/desktop_ai_voice_view.dart';
import '../screens/communication/desktop_conference_view.dart';
import '../screens/settings/desktop_profile_settings_view.dart';
import '../../screens/complaints/new_complaint_screen.dart';

// Standalone fallback
import '../../screens/settings/bar_customization_screen.dart';

/// Desktop Scaffold matching Nagarsevak-Managment AppLayout.tsx exactly:
/// Fixed/collapsible left sidebar (280px / 80px) + full-bleed main content viewport
class DesktopScaffold extends ConsumerStatefulWidget {
  const DesktopScaffold({super.key});

  @override
  ConsumerState<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends ConsumerState<DesktopScaffold> {
  bool _isSidebarCollapsed = false;
  final Set<String> _visitedScreens = {'dashboard'};
  final Map<String, Widget> _cachedScreens = {};

  static const List<String> _screenKeyList = [
    'dashboard', 'complaints', 'letters', 'profile_settings', 'diary',
    'visitors', 'schemes', 'ward_problems', 'ward_map', 'work_history',
    'improvements', 'provisions', 'gb_register', 'ward_budget', 'gov_office',
    'social_analytics', 'newspaper', 'media_tracking', 'ai_content', 'events',
    'gallery', 'result_analysis', 'sadasya', 'surveys', 'voters', 'team',
    'opposition', 'ngo_mandals', 'housing_societies', 'duplicate_voters',
    'voter_forms', 'karyakarta_work', 'sms', 'whatsapp_message', 'whatsapp_call',
    'voice_call', 'ai_voice_call', 'conference_room', 'analysis_strategy', 'bar_customization',
  ];

  void _openCommandPalette() {
    DesktopCommandPalette.show(context, (key) {
      if (key == 'whatsapp_bot') {
        ref.read(desktopSettingsTabProvider.notifier).setTab('bot');
        ref.read(activeScreenProvider.notifier).setScreen('profile_settings');
      } else {
        ref.read(activeScreenProvider.notifier).setScreen(key);
      }
    });
  }

  void _openNewComplaintModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Container(
          width: 680,
          constraints: const BoxConstraints(maxHeight: 720),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const NewComplaintScreen(),
        ),
      ),
    );
  }

  void _navigateToIndex(int index) {
    if (index >= 0 && index < _screenKeyList.length) {
      ref.read(activeScreenProvider.notifier).setScreen(_screenKeyList[index]);
    }
  }

  Widget _buildContent(String activeKey) {
    switch (activeKey) {
      case 'dashboard':
        return const DesktopDashboardView();
      case 'complaints':
        return const DesktopComplaintsView();
      case 'letters':
        return const DesktopLettersView();
      case 'profile_settings':
        return const DesktopProfileSettingsView();
      case 'diary':
      case 'tasks':
        return const DesktopTasksView();
      case 'visitors':
        return const DesktopVisitorsView();
      case 'schemes':
        return const DesktopSchemesView();
      case 'ward_problems':
        return const DesktopWardProblemsView();
      case 'ward_map':
        return const DesktopWardMapView();
      case 'work_history':
        return const DesktopWorkHistoryView();
      case 'improvements':
        return const DesktopImprovementsView();
      case 'provisions':
        return const DesktopProvisionsView();
      case 'gb_register':
        return const DesktopGbRegisterView();
      case 'ward_budget':
        return const DesktopWardBudgetView();
      case 'gov_office':
        return const DesktopGovernmentOfficeView();
      case 'social_analytics':
        return const DesktopSocialAnalyticsView();
      case 'newspaper':
        return const DesktopNewspaperView();
      case 'media_tracking':
        return const DesktopMediaTrackingView();
      case 'ai_content':
        return const DesktopAiContentView();
      case 'events':
        return const DesktopEventsView();
      case 'gallery':
        return const DesktopGalleryView();
      case 'result_analysis':
        return const DesktopResultAnalysisView();
      case 'sadasya':
        return const DesktopSadasyaView();
      case 'surveys':
        return const DesktopSurveysView();
      case 'voters':
        return const DesktopVotersView();
      case 'team':
        return const DesktopTeamView();
      case 'opposition':
        return const DesktopOppositionView();
      case 'ngo_mandals':
        return const DesktopNgoMandalsView();
      case 'housing_societies':
        return const DesktopHousingSocietiesView();
      case 'duplicate_voters':
        return const DesktopDuplicateVotersView();
      case 'voter_forms':
        return const DesktopVoterFormsView();
      case 'karyakarta_work':
        return const DesktopKaryakartaWorkView();
      case 'sms':
        return const DesktopSmsView();
      case 'whatsapp_message':
        return const DesktopWhatsappView();
      case 'whatsapp_call':
        return const DesktopWhatsappCallingView();
      case 'voice_call':
        return const DesktopVoiceCallView();
      case 'ai_voice_call':
        return const DesktopAiVoiceView();
      case 'conference_room':
        return const DesktopConferenceView();
      case 'analysis_strategy':
        return const DesktopAnalysisStrategyView();
      case 'bar_customization':
        return BarCustomizationScreen(onTabChange: _navigateToIndex);
      default:
        return const DesktopDashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeKey = ref.watch(activeScreenProvider);
    _visitedScreens.add(activeKey);

    int activeIndex = _screenKeyList.indexOf(activeKey);
    if (activeIndex == -1) {
      if (activeKey == 'tasks') {
        activeIndex = _screenKeyList.indexOf('diary');
      } else {
        activeIndex = 0;
      }
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _openNewComplaintModal,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC), // slate-50 exactly matching AppLayout.tsx
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Collapsible Desktop Sidebar matching AppLayout.tsx (280px / 80px)
              DesktopSidebar(
                isCollapsed: _isSidebarCollapsed,
                onToggleCollapse: () {
                  setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                },
              ),

              // 2. Main Viewport matching AppLayout.tsx <main className="flex-1 mx-auto max-w-7xl">
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC), // slate-50
                  height: double.infinity,
                  child: IndexedStack(
                    index: activeIndex,
                    children: _screenKeyList.map((k) {
                      final isVisited = _visitedScreens.contains(k) || (k == 'diary' && _visitedScreens.contains('tasks'));
                      if (isVisited) {
                        return _cachedScreens.putIfAbsent(k, () => _buildContent(k));
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
