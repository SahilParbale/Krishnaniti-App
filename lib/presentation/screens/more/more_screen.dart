import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../ward_map/ward_map_screen.dart';
import '../schemes/government_schemes_screen.dart';
import '../diary/diary_screen.dart';
import '../visitors/visitors_screen.dart';
import '../ward_problems/ward_problems_screen.dart';
import '../works/work_history_screen.dart';
import '../ward_improvements/possible_improvements_screen.dart';
import '../ward_provisions/ward_provisions_screen.dart';
import '../gb_register/gb_register_screen.dart';
import '../ward_budget/ward_budget_screen.dart';
import '../government_office/government_office_screen.dart';
import '../social/social_analytics_screen.dart';
import '../newspaper/newspaper_clippings_screen.dart';
import '../media_tracking/media_tracking_screen.dart';
import '../content_studio/ai_content_studio_screen.dart';
import '../events/events_screen.dart';
import '../gallery/gallery_screen.dart';
import '../results/result_analysis_screen.dart';
import '../sadasya/sadasya_screen.dart';
import '../surveys/surveys_screen.dart';
import '../voters/voters_screen.dart';
import '../team/team_screen.dart';
import '../opposition/opposition_screen.dart';
import '../social_organizations/social_organizations_screen.dart';
import '../housing_societies/housing_societies_screen.dart';
import '../duplicate_voters/duplicate_voters_screen.dart';
import '../voter_forms/voter_forms_screen.dart';
import '../karyakarta_work/karyakarta_work_management_screen.dart';
import '../sms/sms_communication_screen.dart';
import '../whatsapp/whatsapp_communication_screen.dart';
import '../../navigation/app_drawer.dart';
import 'module_detail_screen.dart';

class MoreScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  final Function(int)? onTabChange;

  const MoreScreen({
    super.key,
    this.onBackToHome,
    this.onTabChange,
  });

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  String _selectedCategory = 'All'; // 'All', 'Ward Works', 'Office Admin', 'Govt & Schemes'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // All 12 Modules from Batch 1 in exact order
  final List<_MoreModuleItem> _allModules = const [
    _MoreModuleItem(
      title: 'Diary',
      subtitle: 'Daily meeting schedule, ward visits & event itinerary',
      category: 'Office Admin',
      icon: Icons.event_note_outlined,
      description:
          'Track daily scheduled meetings with officials, citizen appointments, site visits, and inauguration programs across Prabhag 12.',
      highlights: [
        'Today: 4 scheduled appointments',
        'Prabhag inspection at 4:00 PM',
        'GB agenda preparation sync',
      ],
    ),
    _MoreModuleItem(
      title: 'GB Register',
      subtitle: 'General Body questions raised, resolutions & committee records',
      category: 'Office Admin',
      icon: Icons.assignment_outlined,
      description:
          'Municipal Corporation General Body (GB) Register. Record and track official questions raised, committee motions, and approved ward resolutions.',
      highlights: [
        '18 Questions raised this term',
        '12 Ward resolutions approved',
        'Next GB meeting: 15 Feb 2025',
      ],
    ),
    _MoreModuleItem(
      title: 'Government Offices',
      subtitle: 'Ward municipal offices, police stations, MSEDCL & helpline directory',
      category: 'Govt & Schemes',
      icon: Icons.account_balance_outlined,
      description:
          'Comprehensive directory of civic authorities, ward municipal engineers, health inspectors, MSEDCL electrical offices, and police stations with direct contact numbers.',
      highlights: [
        'Prabhag 12 Ward Office • Sector 4',
        'MSEDCL Division Office • Lane 2',
        'City Water Supply Dept • MG Road',
      ],
    ),
    _MoreModuleItem(
      title: 'Government Schemes',
      subtitle: 'Central & state welfare schemes, criteria & beneficiary tracker',
      category: 'Govt & Schemes',
      icon: Icons.assured_workload_outlined,
      description:
          'Official welfare schemes database including Majhi Ladki Bahin Yojana, Sanjay Gandhi Niradhar Yojana, PM Awas, and Ayushman Bharat. Assist constituents with applications.',
      highlights: [
        '24 Active Welfare Schemes',
        '1,420 Ward beneficiaries enrolled',
        'Download Marathi eligibility forms',
      ],
    ),
    _MoreModuleItem(
      title: 'Letters',
      subtitle: 'Inward and outward official government correspondence',
      category: 'Office Admin',
      icon: Icons.mail_outline_rounded,
      description:
          'Scan and register official inward citizen petitions and dispatch outward letters to the Municipal Commissioner, departments, and government ministries.',
      highlights: [
        '14 Inward letters received this week',
        '8 Outward follow-up memorandums sent',
        'PDF scanner with digital inward seal',
      ],
    ),
    _MoreModuleItem(
      title: 'Visitor Log',
      subtitle: 'Daily constituent office meeting register & time log',
      category: 'Office Admin',
      icon: Icons.badge_outlined,
      description:
          'Maintain an accurate register of citizens, housing society delegations, and visitors visiting the Nagarsevak office with visit purpose and follow-up status.',
      highlights: [
        'Today: 26 constituent visits recorded',
        'Follow-up pending for 6 delegations',
        'Export monthly visitor report',
      ],
    ),
    _MoreModuleItem(
      title: 'Ward Map',
      subtitle: 'Interactive Prabhag boundary, developmental works & GIS layers',
      category: 'Ward Works',
      icon: Icons.map_outlined,
      description:
          'Interactive digital Prabhag 12 boundary demarcation showing roads, electoral booths, public gardens, civic water tanks, and ongoing municipal civil works.',
      highlights: [
        'Ward boundary: Prabhag 12 (North & South)',
        '28 Polling booth locations tagged',
        'Civil development project sites live map',
      ],
    ),
    _MoreModuleItem(
      title: 'Ward Problems',
      subtitle: 'Chronic civic issues, garbage spots & infrastructure pain points',
      category: 'Ward Works',
      icon: Icons.report_problem_outlined,
      description:
          'Geo-tagged tracking of persistent civic issues including chronic garbage dumping spots, water pressure drop zones, low-hanging electrical cables, and traffic bottlenecks.',
      highlights: [
        '8 Chronic garbage spots identified',
        '3 Low water pressure zones flagged',
        'Streetlight replacement drive underway',
      ],
    ),
    _MoreModuleItem(
      title: 'Ward Budget',
      subtitle: 'Municipal corporation fund allocation, spending & balances',
      category: 'Ward Works',
      icon: Icons.business_center_outlined,
      description:
          'Annual municipal development budget tracker. Monitor sanctioned Nagarsevak funds, tender allocations, work order expenditure, and remaining unspent balances.',
      highlights: [
        'FY 2024-25 Budget: ₹2.50 Cr Sanctioned',
        'Utilized / In Progress: ₹1.82 Cr',
        'Unallocated Balance: ₹68 Lakhs',
      ],
    ),
    _MoreModuleItem(
      title: 'Ward-wise Provision',
      subtitle: 'Yearly municipal provisions & capital development allocations',
      category: 'Ward Works',
      icon: Icons.storefront_outlined,
      description:
          'Municipal corporation budget provisions earmarked for road resurfacing, gutter concrete covering, garden maintenance, and municipal school infrastructure.',
      highlights: [
        'Roads & Footpaths: ₹95 Lakhs allocated',
        'Sanitation & Drainage: ₹60 Lakhs',
        'Public Gardens & Lights: ₹35 Lakhs',
      ],
    ),
    _MoreModuleItem(
      title: 'Possible Improvements',
      subtitle: 'Citizen proposals, infrastructure ideas & future project plans',
      category: 'Ward Works',
      icon: Icons.trending_up_rounded,
      description:
          'Crowdsourced citizen suggestions, urban planning proposals, and future capital improvement recommendations submitted by Prabhag 12 residents.',
      highlights: [
        'Pedestrian foot-over-bridge proposal',
        'Underground electrical cable ducting plan',
        'Senior citizen walking track expansion',
      ],
    ),
    _MoreModuleItem(
      title: 'Work History',
      subtitle: 'Historical archive of completed municipal projects & tenders',
      category: 'Ward Works',
      icon: Icons.history_rounded,
      description:
          'Comprehensive archive of all completed development works over the 5-year tenure. Includes contractor details, completion photos, and public expenditure verification.',
      highlights: [
        '142 Completed development works',
        'Official completion certificates verified',
        'Public transparency audit report',
      ],
    ),
    _MoreModuleItem(
      title: 'Social Analytics',
      subtitle: 'Social media reach, constituent engagement & birthday connect',
      category: 'Media & Promotion',
      icon: Icons.trending_up_rounded,
      description:
          'Monitor public reach across Facebook, Instagram, and Twitter. Track engagement rates and celebrate constituent birthdays with WhatsApp greetings.',
      highlights: [
        '45.2K Total Reach across platforms',
        '+12% Monthly reach growth',
        'Direct WhatsApp birthday wishes',
      ],
    ),
    _MoreModuleItem(
      title: 'Newspaper Clipping',
      subtitle: 'Print news media coverage archive and press releases',
      category: 'Media & Promotion',
      icon: Icons.newspaper_outlined,
      description:
          'Comprehensive archive of local Marathi and English daily press coverage, developmental achievements, and civic grievances.',
      highlights: [
        '8 Positive Development features',
        '2 Resolved Civic issues',
        'Sakal, Lokmat & Pudhari coverage',
      ],
    ),
    _MoreModuleItem(
      title: 'Media Tracking',
      subtitle: 'Track digital news portals, web channels & online press mentions',
      category: 'Media & Promotion',
      icon: Icons.language_rounded,
      description:
          'Monitor real-time mentions of the Nagarsevak, opposition leaders, and Prabhag 12 development works across regional portals. Export stories to newspaper clippings.',
      highlights: [
        '8 Active News Portals Scanned',
        '88% Positive Coverage Ratio',
        'Direct Export to Clippings',
      ],
    ),
    _MoreModuleItem(
      title: 'AI Content Studio',
      subtitle: 'Draft Marathi speeches, social posts, letters & press releases',
      category: 'Media & Promotion',
      icon: Icons.auto_awesome_rounded,
      description:
          'Generate high-impact Marathi and English speeches, social media captions, public notices, press notes, and work completion reports powered by AI.',
      highlights: [
        'Marathi Speech & Address Generator',
        'Direct Letterhead PDF Export',
        'Social Media Captions & Hashtags',
      ],
    ),
    _MoreModuleItem(
      title: 'Events & Invites',
      subtitle: 'Ward cultural events, health camps, rallies and public RSVPs',
      category: 'Programs and activities',
      icon: Icons.event_available_rounded,
      description:
          'Plan community gatherings, health camps, and developmental inaugurations. Send instant WhatsApp invitations to ward voters and track real-time attendance RSVPs.',
      highlights: [
        'WhatsApp Broadcast Invites',
        'Real-time RSVP Tracking',
        'Official Event PDF Reports',
      ],
    ),
    _MoreModuleItem(
      title: 'Gallery & Media',
      subtitle: 'High-resolution photo and video archive of developmental works',
      category: 'Programs and activities',
      icon: Icons.photo_library_outlined,
      description:
          'Categorized photographic archive of developmental works, community gatherings, civic award ceremonies, and public rallies across Prabhag 12.',
      highlights: [
        '10 HD Civic Photos & Videos',
        'Direct WhatsApp Photo Share',
        'Official Media PDF Catalog',
      ],
    ),
    _MoreModuleItem(
      title: 'Result Analysis',
      subtitle: 'Booth-wise past municipal and assembly election vote analysis',
      category: 'Programs and activities',
      icon: Icons.bar_chart_rounded,
      description:
          'Detailed polling booth trend analytics, vote share breakdown, strongholds (बालेकिल्ले), and improvement areas for Prabhag 12.',
      highlights: [
        '14 Polling Booths Analyzed',
        'Winning Margin & Vote Share %',
        'Official Landscape A4 PDF Report',
      ],
    ),
    _MoreModuleItem(
      title: 'Sadasya (Members)',
      subtitle: 'Party workers, active booth members and volunteer register',
      category: 'Programs and activities',
      icon: Icons.group_add_outlined,
      description:
          'Directory of ward booth in-charges, verified party karyakartas, and active volunteers across Prabhag 12.',
      highlights: [
        '12 Registered Cadre Members',
        'Direct Call & WhatsApp Connect',
        'Official Party Members PDF Register',
      ],
    ),
    _MoreModuleItem(
      title: 'Sample Surveys',
      subtitle: 'Citizen feedback, development satisfaction & opinion polls',
      category: 'Programs and activities',
      icon: Icons.poll_outlined,
      description:
          'Digital polling system for gathering public feedback on water supply, roads, sanitation, and pending civil amenities in Prabhag 12.',
      highlights: [
        'Active Feedback Polls',
        'Direct Share Survey Link',
        'Official Summary Analytics PDF',
      ],
    ),
    _MoreModuleItem(
      title: 'Voter Search',
      subtitle: 'Search electoral roll by EPIC, name, booth or society',
      category: 'Programs and activities',
      icon: Icons.person_search_outlined,
      description:
          'Search voter list for Prabhag 12 by EPIC number, Marathi/English name, or building name with instant voting slip printing.',
      highlights: [
        '42,560 Registered Voters',
        '28 Booths Mapped',
        'Instant Slip Print & Share',
      ],
    ),
    _MoreModuleItem(
      title: 'My Team',
      subtitle: 'Office staff, party wing coordinators & cooperative contacts',
      category: 'Programs and activities',
      icon: Icons.groups_rounded,
      description:
          'Comprehensive staff directory with auto-assign complaint tags, direct task dispatching, attendance tracking, and duty rosters.',
      highlights: [
        '12 Active Team Members',
        'Direct Task Assignment & Tracking',
        'Auto-Assign Complaint Routing',
      ],
    ),
    _MoreModuleItem(
      title: 'Opposition Information',
      subtitle: 'Opposition candidates, workers, strongholds and campaigns',
      category: 'Programs and activities',
      icon: Icons.groups_2_outlined,
      description:
          'Track and monitor opposition candidates, workers, strongholds, election status, controversies and public campaigns across Prabhag 12.',
      highlights: [
        'Opposition Candidate Profiles',
        'Controversies & Public Incidents Log',
        'Campaign Timeline & Team Intel',
      ],
    ),
    _MoreModuleItem(
      title: 'NGO & Mandals Info',
      subtitle: 'Social organizations, youth mandals and cricket club directory',
      category: 'Programs and activities',
      icon: Icons.apartment_rounded,
      description:
          'Contact register of Ganesh mandals, Navratri groups, sports & cricket clubs, and social welfare NGOs across Prabhag 12.',
      highlights: [
        'Mandals & Clubs Directory',
        'Direct Call/WhatsApp to Presidents',
        'Support History & Event Log',
      ],
    ),
    _MoreModuleItem(
      title: 'Housing Societies',
      subtitle: 'Co-op housing society chairmen, secretaries and voter counts',
      category: 'Programs and activities',
      icon: Icons.home_work_outlined,
      description:
          'Directory of housing societies across Prabhag 12 with executive contact numbers, voter counts, and key ward issues.',
      highlights: [
        '86 Housing Societies',
        'Chairman & Secretary Contacts',
        'Voter Support & Demand Tracker',
      ],
    ),
    _MoreModuleItem(
      title: 'Duplicate Voters',
      subtitle: 'Identify and clean up duplicate voter records with matching names',
      category: 'Programs and activities',
      icon: Icons.warning_amber_rounded,
      description:
          'Identify and clean up duplicate voter records across electoral rolls and booths using side-by-side comparison.',
      highlights: [
        'Matching Full Names Audit',
        'Side-by-Side Comparison',
        'Form 7 Deletion Desk',
      ],
    ),
    _MoreModuleItem(
      title: 'Voter Forms',
      subtitle: 'Official ECI Form 6, Form 7, Form 8 registration & tracking',
      category: 'Programs and activities',
      icon: Icons.description_outlined,
      description:
          'Comprehensive voter service helpdesk for new voter registration (Form 6), deletion (Form 7), and details update (Form 8).',
      highlights: [
        'Official ECI Forms Portal',
        'Application Status Tracking',
        'Constituent Direct Assistance',
      ],
    ),
    _MoreModuleItem(
      title: 'Karyakarta Work Management',
      subtitle: 'Monitor workload & assign tasks across Office, Government & Party teams',
      category: 'Programs and activities',
      icon: Icons.assignment_ind_outlined,
      description:
          'Monitor team workload across Office, Government & Party workers. Assign tasks and complaints with real-time status updates and official PDF workload reports.',
      highlights: [
        'Team Workload Monitor & Metrics',
        'Office, Government & Party Tabs',
        'Quick Task Assignment & PDF Report',
      ],
    ),
    _MoreModuleItem(
      title: 'Send SMS',
      subtitle: 'Bulk SMS broadcast for ward alerts, water supply notices and greetings',
      category: 'Public Communication',
      icon: Icons.sms_outlined,
      description:
          'Send targeted municipal water shutdown notices, vaccination alerts, and festive greetings to verified voters in Prabhag 12.',
      highlights: [
        'Registered TRAI DLT Templates',
        'Voter Filters & Multi-Select',
        'Detailed Delivery Reports & PDF',
      ],
    ),
    _MoreModuleItem(
      title: 'WhatsApp Message',
      subtitle: 'Direct WhatsApp broadcast to ward voters via official bot',
      category: 'Public Communication',
      icon: Icons.chat_rounded,
      description:
          'Send richly formatted WhatsApp messages with emojis and bold text to Prabhag 12 voters. Direct 1-tap WA chat per voter, bulk broadcast with bot status monitoring, and PDF history report.',
      highlights: [
        'Bot Connected Status Indicator',
        'Direct 1-tap WhatsApp Chat per Voter',
        'Bulk Broadcast & PDF Report',
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openModuleDetail(_MoreModuleItem item) {
    if (item.title == 'Letters' && widget.onTabChange != null) {
      widget.onTabChange!(2); // Switch to Work/Letters tab
      return;
    }
    if (item.title.toLowerCase().contains('ward map')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WardMapScreen()),
      );
      return;
    }
    if (item.title.toLowerCase().contains('government schemes') ||
        item.title.toLowerCase().contains('scheme')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GovernmentSchemesScreen(
            onBackToHome: widget.onBackToHome,
            onTabChange: widget.onTabChange,
          ),
        ),
      );
      return;
    }

    if (item.title.toLowerCase() == 'gb register' || item.title.toLowerCase().contains('gb register')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GbRegisterScreen()),
      );
      return;
    }

    if (item.title.toLowerCase() == 'diary' || (item.title.toLowerCase().contains('diary') && !item.title.toLowerCase().contains('gb'))) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DiaryScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('visitor')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VisitorsScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('ward problem')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WardProblemsScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('work history')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkHistoryScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('improvement')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PossibleImprovementsScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('provision')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WardProvisionsScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('budget')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WardBudgetScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('government office') ||
        (item.title.toLowerCase().contains('office') &&
            !item.title.toLowerCase().contains('visitor') &&
            !item.title.toLowerCase().contains('diary'))) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GovernmentOfficeScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('social analytics') ||
        item.title.toLowerCase() == 'social') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SocialAnalyticsScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('newspaper') ||
        item.title.toLowerCase().contains('clipping') ||
        item.title.toLowerCase().contains('वृत्तपत्र')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewspaperClippingsScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('media tracking') ||
        (item.title.toLowerCase().contains('tracking') &&
            !item.title.toLowerCase().contains('visitor')) ||
        item.title.toLowerCase().contains('माध्यम मागोवा')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MediaTrackingScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('ai content') ||
        item.title.toLowerCase().contains('content studio') ||
        item.title.toLowerCase().contains('कंटेंट स्टुडिओ')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiContentStudioScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('event') ||
        item.title.toLowerCase().contains('invite') ||
        item.title.toLowerCase().contains('कार्यक्रम')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EventsScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('gallery') ||
        item.title.toLowerCase().contains('गॅलरी') ||
        item.title.toLowerCase().contains('फोटो')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GalleryScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('result') ||
        item.title.toLowerCase().contains('election') ||
        item.title.toLowerCase().contains('निकाल')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultAnalysisScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('sadasya') ||
        item.title.toLowerCase().contains('सदस्य') ||
        item.title.toLowerCase().contains('party member')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SadasyaScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('survey') ||
        item.title.toLowerCase().contains('सर्वेक्षण') ||
        item.title.toLowerCase().contains('चाचण्या') ||
        item.title.toLowerCase() == 'sample surveys') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SurveysScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('voter search') ||
        item.title.toLowerCase().contains('मतदार शोध') ||
        item.title.toLowerCase() == 'voter search' ||
        item.title.toLowerCase() == 'voters') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VotersScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('team') ||
        item.title.toLowerCase().contains('staff') ||
        item.title.toLowerCase().contains('कार्यसंघ') ||
        item.title.toLowerCase().contains('कर्मचारी') ||
        item.title.toLowerCase() == 'my team') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeamScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('opposition') ||
        item.title.toLowerCase().contains('विरोध') ||
        item.title.toLowerCase().contains('विरोधी') ||
        item.title.toLowerCase() == 'opposition information') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OppositionScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('mandal') ||
        item.title.toLowerCase().contains('ngo') ||
        item.title.toLowerCase().contains('मंडळ') ||
        item.title.toLowerCase().contains('संस्था') ||
        item.title.toLowerCase() == 'ngo & mandals info') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SocialOrganizationsScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('societ') ||
        item.title.toLowerCase().contains('सोसायटी') ||
        item.title.toLowerCase() == 'housing societies') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HousingSocietiesScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('duplicate') ||
        item.title.toLowerCase().contains('ड्युप्लिकेट') ||
        item.title.toLowerCase() == 'duplicate voters') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DuplicateVotersScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('form') ||
        item.title.toLowerCase().contains('अर्ज') ||
        item.title.toLowerCase() == 'voter forms') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VoterFormsScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('karyakarta work') ||
        item.title.toLowerCase().contains('कार्यकर्ता काम') ||
        item.title.toLowerCase() == 'karyakarta work management') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KaryakartaWorkManagementScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('send sms') ||
        item.title.toLowerCase().contains('sms पाठवा') ||
        item.title.toLowerCase().contains('एसएमएस') ||
        item.title.toLowerCase() == 'send sms' ||
        item.title.toLowerCase() == 'sms') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmsCommunicationScreen()),
      );
      return;
    }

    if (item.title.toLowerCase().contains('whatsapp message') ||
        item.title.toLowerCase().contains('व्हॉट्सॲप') ||
        item.title.toLowerCase() == 'whatsapp message') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WhatsAppCommunicationScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleDetailScreen(
          title: item.title,
          subtitle: item.subtitle,
          category: item.category,
          icon: item.icon,
          description: item.description,
          highlights: item.highlights,
        ),
      ),
    );
  }

  void _showSignOutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out of the Nagarsevak Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter list based on selected category & search query
    final filteredList = _allModules.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: NagarsevakAppDrawer(
          currentTabIndex: 3,
          onTabChange: widget.onTabChange,
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              tooltip: 'Open Menu Drawer',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'More Menu',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Modules in Batch 1',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFD6E8FA),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search 12 batch modules...',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                  ),
                ),
              ),
            ),

            // Category Filter Pills
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryFilterChip(
                    label: 'All (12)',
                    isSelected: _selectedCategory == 'All',
                    onTap: () => setState(() => _selectedCategory = 'All'),
                  ),
                  _CategoryFilterChip(
                    label: 'Ward Works (6)',
                    isSelected: _selectedCategory == 'Ward Works',
                    onTap: () => setState(() => _selectedCategory = 'Ward Works'),
                  ),
                  _CategoryFilterChip(
                    label: 'Office Admin (4)',
                    isSelected: _selectedCategory == 'Office Admin',
                    onTap: () => setState(() => _selectedCategory = 'Office Admin'),
                  ),
                  _CategoryFilterChip(
                    label: 'Govt & Schemes (2)',
                    isSelected: _selectedCategory == 'Govt & Schemes',
                    onTap: () => setState(() => _selectedCategory = 'Govt & Schemes'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Modules List
            Expanded(
              child: filteredList.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching modules found',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filteredList.length + 1, // +1 for the Sign Out section at bottom
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == filteredList.length) {
                          // Sign Out Card at bottom
                          return Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 20),
                            child: OutlinedButton.icon(
                              onPressed: _showSignOutConfirm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 19),
                              label: const Text(
                                'Sign Out of Office Portal',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        final item = filteredList[index];
                        return _ModuleListCard(
                          item: item,
                          onTap: () => _openModuleDetail(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Module Card item
class _ModuleListCard extends StatelessWidget {
  final _MoreModuleItem item;
  final VoidCallback onTap;

  const _ModuleListCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Blue Icon Container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFF0284C7),
                size: 23,
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron Right Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Category Pill Chip
class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for More Menu items
class _MoreModuleItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final String description;
  final List<String> highlights;

  const _MoreModuleItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.description,
    required this.highlights,
  });
}
