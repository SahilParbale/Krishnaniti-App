import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';

class NagarsevakAppDrawer extends ConsumerStatefulWidget {
  final int currentTabIndex;
  final ValueChanged<int>? onTabChange;

  const NagarsevakAppDrawer({
    super.key,
    this.currentTabIndex = 0,
    this.onTabChange,
  });

  @override
  ConsumerState<NagarsevakAppDrawer> createState() => _NagarsevakAppDrawerState();
}

class _NagarsevakAppDrawerState extends ConsumerState<NagarsevakAppDrawer> {
  // Accordion state matching React AppLayout.tsx
  late Map<String, bool> _openGroups;

  @override
  void initState() {
    super.initState();
    // Default open groups matching user workflow in Nagarsevak-Managment (only daily_work initially open for compact look)
    _openGroups = {
      'daily_work': true,
      'ward_info': true,
      'municipal': true,
      'media': false,
      'programs': false,
      'political': false,
      'public_comm': false,
    };
  }

  void _toggleGroup(String groupId) {
    setState(() {
      _openGroups[groupId] = !(_openGroups[groupId] ?? false);
    });
  }

  void _navigateToModule({
    required String title,
    required String subtitle,
    required String category,
    required IconData icon,
    required String description,
    required List<String> highlights,
  }) {
    // Automatically collapse/close the sidebar drawer immediately so the target page is visible
    Navigator.of(context).pop();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    final key = resolveScreenKey(title) ?? resolveScreenKey(category) ?? resolveScreenKey(subtitle);
    if (key != null) {
      ref.read(activeScreenProvider.notifier).setScreen(key);
      if (key == 'dashboard') ref.read(mainTabIndexProvider.notifier).setTab(0);
      if (key == 'complaints') ref.read(mainTabIndexProvider.notifier).setTab(1);
      if (key == 'letters') ref.read(mainTabIndexProvider.notifier).setTab(2);
      if (key == 'profile_settings') ref.read(mainTabIndexProvider.notifier).setTab(3);
      if (widget.onTabChange != null) {
        if (key == 'dashboard') widget.onTabChange!(0);
        if (key == 'complaints') widget.onTabChange!(1);
        if (key == 'letters') widget.onTabChange!(2);
        if (key == 'profile_settings') widget.onTabChange!(3);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 380 ? 285.0 : screenWidth * 0.78;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Clean Compact Header with Nagarsevak Profile (no numbers)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 14,
              right: 14,
              bottom: 12,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x29000000), blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(Icons.person, color: Color(0xFF0284C7), size: 22),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Hon. Nagarsevak',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.8),
                            ),
                            child: const Text(
                              'Ward 12',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Prabhag 12 • Pune Municipal Corp.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE0F2FE),
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

          // Scrollable Menu List exactly matching AppLayout.tsx sequence (Names only, no numbers/indexes)
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                top: 4,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              children: [
                // Top Dashboard / Home Item
                _DrawerSingleItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  onTap: () => _navigateToModule(
                    title: 'Dashboard',
                    subtitle: 'Overview, analytics & ward summary',
                    category: 'Overview',
                    icon: Icons.dashboard_rounded,
                    description: 'Prabhag 12 general summary and civic metrics.',
                    highlights: const [],
                  ),
                ),

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 1) DAILY WORK (nav.daily_work)
                // ==========================================
                _DrawerGroupHeader(
                  title: 'Daily work',
                  icon: Icons.business_center_outlined,
                  isOpen: _openGroups['daily_work'] ?? false,
                  onToggle: () => _toggleGroup('daily_work'),
                ),
                if (_openGroups['daily_work'] ?? false) ...[
                  _DrawerSubItem(
                    icon: Icons.assignment_outlined,
                    title: 'Requests & Complaints',
                    onTap: () => _navigateToModule(
                      title: 'Requests & Complaints',
                      subtitle: 'Civic grievances, issue tracking and status updates',
                      category: 'Daily work',
                      icon: Icons.assignment_outlined,
                      description: 'Register and monitor citizen civic complaints and ward maintenance work.',
                      highlights: ['128 Total requests', '32 Pending', '20 Resolved'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.description_outlined,
                    title: 'Letters',
                    onTap: () => _navigateToModule(
                      title: 'Letters',
                      subtitle: 'Inward and outward official municipal correspondence',
                      category: 'Daily work',
                      icon: Icons.description_outlined,
                      description: 'Scan and track inward citizen petitions and departmental dispatch letters.',
                      highlights: ['14 Inward letters', '8 Outward follow-ups', 'PDF inward seal'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.check_box_outlined,
                    title: 'Diary',
                    onTap: () => _navigateToModule(
                      title: 'Diary',
                      subtitle: 'Task management, daily visits and itinerary',
                      category: 'Daily work',
                      icon: Icons.check_box_outlined,
                      description: 'Daily ward itinerary, scheduled official meetings, and action items.',
                      highlights: ['4 appointments today', 'Inspection at 4:00 PM', 'GB agenda prep'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.people_outline_rounded,
                    title: 'Visitor Log',
                    onTap: () => _navigateToModule(
                      title: 'Visitor Log',
                      subtitle: 'Daily constituent office meeting register and time log',
                      category: 'Daily work',
                      icon: Icons.people_outline_rounded,
                      description: 'Log and track constituent visits, appointments, and office delegations.',
                      highlights: ['26 Constituent visits', '6 Follow-ups pending', 'Monthly report'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.assured_workload_outlined,
                    title: 'Govt Schemes',
                    onTap: () => _navigateToModule(
                      title: 'Govt Schemes',
                      subtitle: 'Central and state welfare schemes database',
                      category: 'Daily work',
                      icon: Icons.assured_workload_outlined,
                      description: 'Official welfare schemes database including Ladki Bahin, PM Awas, and Ayushman Bharat.',
                      highlights: ['24 Active Schemes', '1,420 Enrolled', 'Marathi Forms Available'],
                    ),
                  ),
                ],

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 2) WARD INFORMATION (nav.ward_info)
                // ==========================================
                _DrawerGroupHeader(
                  title: 'Ward information',
                  icon: Icons.info_outline_rounded,
                  isOpen: _openGroups['ward_info'] ?? false,
                  onToggle: () => _toggleGroup('ward_info'),
                ),
                if (_openGroups['ward_info'] ?? false) ...[
                  _DrawerSubItem(
                    icon: Icons.warning_amber_rounded,
                    title: 'Ward Problems',
                    onTap: () => _navigateToModule(
                      title: 'Ward Problems',
                      subtitle: 'Chronic civic issues, garbage spots and bottlenecks',
                      category: 'Ward information',
                      icon: Icons.warning_amber_rounded,
                      description: 'Geo-tagged tracking of chronic garbage spots, water drops, and infrastructure pain points.',
                      highlights: ['8 Chronic garbage spots', '3 Low pressure zones', 'Streetlights drive'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.map_outlined,
                    title: 'Ward Map',
                    onTap: () => _navigateToModule(
                      title: 'Ward Map',
                      subtitle: 'Interactive Prabhag boundary, developmental works and GIS layers',
                      category: 'Ward information',
                      icon: Icons.map_outlined,
                      description: 'Interactive digital Prabhag 12 boundary demarcation and project sites.',
                      highlights: ['Prabhag 12 Boundary', '28 Polling booths', 'Civil development project map'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.history_rounded,
                    title: 'Work History',
                    onTap: () => _navigateToModule(
                      title: 'Work History',
                      subtitle: 'Historical archive of completed municipal projects and tenders',
                      category: 'Ward information',
                      icon: Icons.history_rounded,
                      description: 'Archive of all completed development works over the tenure with verified certificates.',
                      highlights: ['142 Completed projects', 'Audited work orders', 'Public reports'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.trending_up_rounded,
                    title: 'Possible Improvements',
                    onTap: () => _navigateToModule(
                      title: 'Possible Improvements',
                      subtitle: 'Citizen proposals, infrastructure ideas and future project plans',
                      category: 'Ward information',
                      icon: Icons.trending_up_rounded,
                      description: 'Crowdsourced citizen suggestions and urban planning proposals.',
                      highlights: ['Skywalk proposal', 'Underground electrical cable plan', 'Walking track'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Ward Wise Provision',
                    onTap: () => _navigateToModule(
                      title: 'Ward Wise Provision',
                      subtitle: 'Yearly municipal provisions and capital development allocations',
                      category: 'Ward information',
                      icon: Icons.currency_rupee_rounded,
                      description: 'Municipal budget provisions earmarked for road, sanitation, and parks.',
                      highlights: ['Roads: ₹95 L', 'Drainage: ₹60 L', 'Gardens: ₹35 L'],
                    ),
                  ),
                ],

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 3) MUNICIPAL WORK (nav.municipal_work)
                // ==========================================
                _DrawerGroupHeader(
                  title: 'Municipal work',
                  icon: Icons.account_balance_outlined,
                  isOpen: _openGroups['municipal'] ?? false,
                  onToggle: () => _toggleGroup('municipal'),
                ),
                if (_openGroups['municipal'] ?? false) ...[
                  _DrawerSubItem(
                    icon: Icons.menu_book_outlined,
                    title: 'GB Register',
                    onTap: () => _navigateToModule(
                      title: 'GB Register',
                      subtitle: 'General Body questions raised, resolutions and committee records',
                      category: 'Municipal work',
                      icon: Icons.menu_book_outlined,
                      description: 'Municipal Corporation General Body (GB) Register and resolutions tracker.',
                      highlights: ['18 Questions raised', '12 Resolutions approved', 'Next GB: 15 Feb'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Ward Budget',
                    onTap: () => _navigateToModule(
                      title: 'Ward Budget',
                      subtitle: 'Municipal corporation fund allocation, spending and balances',
                      category: 'Municipal work',
                      icon: Icons.currency_rupee_rounded,
                      description: 'Annual municipal development budget tracker for Prabhag 12.',
                      highlights: ['₹2.50 Cr Sanctioned', '₹1.82 Cr Utilized', '₹68 Lakhs Balance'],
                    ),
                  ),
                ],

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 4) GOVERNMENT OFFICE (nav.gov_office) - Standalone Item
                // ==========================================
                _DrawerSingleItem(
                  icon: Icons.location_city_outlined,
                  title: 'Government office',
                  onTap: () => _navigateToModule(
                    title: 'Government office',
                    subtitle: 'Ward municipal offices, police stations, MSEDCL & helpline directory',
                    category: 'Civic & Administration',
                    icon: Icons.location_city_outlined,
                    description: 'Comprehensive directory of civic authorities and emergency helplines.',
                    highlights: ['Prabhag Ward Office', 'MSEDCL Division Office', 'City Water Supply Dept'],
                  ),
                ),

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 5) MEDIA & PROMOTION (nav.media_promotion)
                // ==========================================
                _DrawerGroupHeader(
                  title: 'Media & Promotion',
                  icon: Icons.campaign_outlined,
                  isOpen: _openGroups['media'] ?? false,
                  onToggle: () => _toggleGroup('media'),
                ),
                if (_openGroups['media'] ?? false) ...[
                  _DrawerSubItem(
                    icon: Icons.trending_up_rounded,
                    title: 'Social Analytics',
                    onTap: () => _navigateToModule(
                      title: 'Social Analytics',
                      subtitle: 'Social media reach, engagement, and constituent sentiment',
                      category: 'Media & Promotion',
                      icon: Icons.trending_up_rounded,
                      description: 'Track Facebook, Instagram, and Twitter reach for Prabhag 12 public updates.',
                      highlights: ['48K Monthly Impressions', '+24% Engagement', '85% Positive Sentiment'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.newspaper_outlined,
                    title: 'Newspaper Clipping',
                    onTap: () => _navigateToModule(
                      title: 'Newspaper Clipping',
                      subtitle: 'Print news media coverage archive and press releases',
                      category: 'Media & Promotion',
                      icon: Icons.newspaper_outlined,
                      description: 'Archive of local Marathi and English daily press mentions and developmental coverage.',
                      highlights: ['32 Press Clippings', 'Sakal & Lokmat Features', 'Press Releases Archive'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.language_rounded,
                    title: 'Media Tracking',
                    onTap: () => _navigateToModule(
                      title: 'Media Tracking',
                      subtitle: 'Digital news portals and TV news monitoring',
                      category: 'Media & Promotion',
                      icon: Icons.language_rounded,
                      description: 'Live alerts for municipal council news and Prabhag 12 development mentions.',
                      highlights: ['Daily News Alerts', '18 Digital Mentions', 'TV Byte Logs'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Content Studio',
                    onTap: () => _navigateToModule(
                      title: 'AI Content Studio',
                      subtitle: 'AI Marathi speechwriter, press releases and festive banners',
                      category: 'Media & Promotion',
                      icon: Icons.auto_awesome_rounded,
                      description: 'AI-assisted speech generator, social media captions, and press release drafts.',
                      highlights: ['Marathi Speechwriter', 'Festival Greetings', 'Press Release Drafts'],
                    ),
                  ),
                ],

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 6) PROGRAMS & ACTIVITIES (nav.programs_activities)
                // ==========================================
                _DrawerGroupHeader(
                  title: 'Programs and activities',
                  icon: Icons.event_available_outlined,
                  isOpen: _openGroups['programs'] ?? false,
                  onToggle: () => _toggleGroup('programs'),
                ),
                if (_openGroups['programs'] ?? false) ...[
                  _DrawerSubItem(
                    icon: Icons.event_outlined,
                    title: 'Events & Invites',
                    onTap: () => _navigateToModule(
                      title: 'Events & Invites',
                      subtitle: 'Public programs, festival pandal visits and invitations',
                      category: 'Programs and activities',
                      icon: Icons.event_outlined,
                      description: 'Calendar of ward events, guest invitations, and inauguration ceremonies.',
                      highlights: ['Ward Programs', 'Guest Invites', 'Protocol Directory'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.photo_library_outlined,
                    title: 'Gallery & Media',
                    onTap: () => _navigateToModule(
                      title: 'Gallery & Media',
                      subtitle: 'Official photo archive, development work images and press albums',
                      category: 'Programs and activities',
                      icon: Icons.photo_library_outlined,
                      description: 'Visual evidence repository of development works and festival celebrations.',
                      highlights: ['Project Photos', 'Press Albums', 'High-Res Downloads'],
                    ),
                  ),
                ],

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 7) POLITICAL (nav.political)
                // ==========================================
                _DrawerGroupHeader(
                  title: 'Political',
                  icon: Icons.flag_outlined,
                  isOpen: _openGroups['political'] ?? false,
                  onToggle: () => _toggleGroup('political'),
                ),
                if (_openGroups['political'] ?? false) ...[
                  _DrawerSubItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Result Analysis',
                    onTap: () => _navigateToModule(
                      title: 'Result Analysis',
                      subtitle: 'Booth-wise past municipal and assembly election vote analysis',
                      category: 'Political',
                      icon: Icons.bar_chart_rounded,
                      description: 'Detailed polling booth trend analytics, margin comparisons, and vote share breakdown.',
                      highlights: ['28 Booths analyzed', 'Winning margin +4,200', 'Swing booth identification'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.group_add_outlined,
                    title: 'Sadasya (Members)',
                    onTap: () => _navigateToModule(
                      title: 'Sadasya (Members)',
                      subtitle: 'Party workers, active booth members and volunteer register',
                      category: 'Political',
                      icon: Icons.group_add_outlined,
                      description: 'Directory of ward booth in-charges, verified party karyakartas, and active volunteers.',
                      highlights: ['1,240 Registered Members', '28 Booth In-charges', 'Active Member Badges'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.fact_check_outlined,
                    title: 'Sample Surveys',
                    onTap: () => _navigateToModule(
                      title: 'Sample Surveys',
                      subtitle: 'Public opinion surveys, constituent feedback and pulse',
                      category: 'Political',
                      icon: Icons.fact_check_outlined,
                      description: 'Statistical sample surveys measuring public satisfaction with roads, water, and ward office service.',
                      highlights: ['Latest Survey: Oct 2024', '1,500 Sample Size', '78% Citizen Satisfaction'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.person_search_outlined,
                    title: 'Voter Search',
                    onTap: () => _navigateToModule(
                      title: 'Voter Search',
                      subtitle: 'Digital electoral roll lookup by name, EPIC and address',
                      category: 'Political',
                      icon: Icons.person_search_outlined,
                      description: 'Search voter list for Prabhag 12 by EPIC number, Marathi/English name, or building name.',
                      highlights: ['42,560 Registered Voters', '28 Booths Mapped', 'Instant Slip Print/Share'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.groups_outlined,
                    title: 'My Team',
                    onTap: () => _navigateToModule(
                      title: 'My Team',
                      subtitle: 'Nagarsevak office staff, field coordinators and roles',
                      category: 'Political',
                      icon: Icons.groups_outlined,
                      description: 'Staff directory with access permissions, task assignments, and duty rosters.',
                      highlights: ['8 Office Staff', '12 Field Coordinators', 'Permission Controls'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.groups_2_outlined,
                    title: 'Opposition Information',
                    onTap: () => _navigateToModule(
                      title: 'Opposition Information',
                      subtitle: 'Opposition candidate profiles, past records and public claims',
                      category: 'Political',
                      icon: Icons.groups_2_outlined,
                      description: 'Factual repository of statements, public meetings, and political movements in the ward.',
                      highlights: ['Prabhag Political Profile', 'Booth Strengths/Weaknesses', 'Counter Strategy'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.apartment_outlined,
                    title: 'NGO & Mandals Info',
                    onTap: () => _navigateToModule(
                      title: 'NGO & Mandals Info',
                      subtitle: 'Social organizations, youth mandals and trust directory',
                      category: 'Political',
                      icon: Icons.apartment_outlined,
                      description: 'Contact register of Ganesh mandals, Navratri groups, sports clubs, and social welfare trusts.',
                      highlights: ['42 Registered Mandals', 'Key Office Bearers', 'Festival Grant Log'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.home_work_outlined,
                    title: 'Housing Societies',
                    onTap: () => _navigateToModule(
                      title: 'Housing Societies',
                      subtitle: 'Co-op housing society chairmen, secretaries and voter counts',
                      category: 'Political',
                      icon: Icons.home_work_outlined,
                      description: 'Directory of housing societies across Prabhag 12 with committee contact numbers and issues.',
                      highlights: ['86 Housing Societies', 'Chairman & Secretary Contacts', 'Water/Drainage Tickets'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.warning_amber_rounded,
                    title: 'Duplicate Voters',
                    onTap: () => _navigateToModule(
                      title: 'Duplicate Voters',
                      subtitle: 'Electoral roll duplicate detection and verification audit',
                      category: 'Political',
                      icon: Icons.warning_amber_rounded,
                      description: 'Automated algorithmic scan identifying duplicate names, photos, and EPICs in the ward roll.',
                      highlights: ['142 Suspected Duplicates', 'ECI Form 7 Deletion Desk', 'Clean Roll Audit'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.description_outlined,
                    title: 'Voter Forms',
                    onTap: () => _navigateToModule(
                      title: 'Voter Forms',
                      subtitle: 'ECI Form 6, Form 7, Form 8 registration helpdesk',
                      category: 'Political',
                      icon: Icons.description_outlined,
                      description: 'Direct citizen assistance desk for new voter additions, address corrections, and roll transfers.',
                      highlights: ['Form 6 New Registration', 'Form 8 Correction', 'Ward Electoral Helpdesk'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Karyakarta Work Management',
                    onTap: () => _navigateToModule(
                      title: 'Karyakarta Work Management',
                      subtitle: 'Assign booth duties, letter distribution and follow-ups',
                      category: 'Political',
                      icon: Icons.assignment_ind_outlined,
                      description: 'Work allocation tracker for party workers with completion verification and photo proof.',
                      highlights: ['24 Active Work Orders', 'Booth Distribution Status', 'Performance Tracker'],
                    ),
                  ),
                ],

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 8) PUBLIC COMMUNICATION (nav.public_communication)
                // ==========================================
                _DrawerGroupHeader(
                  title: 'Public Communication',
                  icon: Icons.record_voice_over_outlined,
                  isOpen: _openGroups['public_comm'] ?? false,
                  onToggle: () => _toggleGroup('public_comm'),
                ),
                if (_openGroups['public_comm'] ?? false) ...[
                  _DrawerSubItem(
                    icon: Icons.sms_outlined,
                    title: 'Send SMS',
                    onTap: () => _navigateToModule(
                      title: 'Send SMS',
                      subtitle: 'Bulk SMS dispatch for ward updates and emergency alerts',
                      category: 'Public Communication',
                      icon: Icons.sms_outlined,
                      description: 'Send municipal water shutdown notices, vaccination camp alerts, and festive greetings.',
                      highlights: ['DLT Registered Templates', 'Ward-wise Mobile Numbers', 'Delivery Reports'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'WhatsApp Message',
                    onTap: () => _navigateToModule(
                      title: 'WhatsApp Message',
                      subtitle: 'Official WhatsApp broadcast messages and society updates',
                      category: 'Public Communication',
                      icon: Icons.chat_bubble_outline_rounded,
                      description: 'Direct WhatsApp communication with society chairmen and active constituents.',
                      highlights: ['Meta Cloud API Verified', 'Rich Media & PDF Attachments', 'Automated Replies'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.phone_forwarded_rounded,
                    title: 'WhatsApp Call',
                    onTap: () => _navigateToModule(
                      title: 'WhatsApp Call',
                      subtitle: 'Direct WhatsApp internet voice calls to ward constituents',
                      category: 'Public Communication',
                      icon: Icons.phone_forwarded_rounded,
                      description: 'Initiate 1-tap WhatsApp voice calls to verified voters across Prabhag 12.',
                      highlights: ['Instant WhatsApp Dialer', 'Direct 1-on-1 Internet Calls', 'Call Activity Logs & PDF'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.phone_in_talk_outlined,
                    title: 'Voice Call',
                    onTap: () => _navigateToModule(
                      title: 'Voice Call',
                      subtitle: 'Outbound recorded voice broadcasts in Nagarsevak own voice',
                      category: 'Public Communication',
                      icon: Icons.phone_in_talk_outlined,
                      description: 'Broadcast personalized Marathi audio messages for major festival greetings and developmental news.',
                      highlights: ['High Call Connect Rate', 'Personal Audio Voice Note', 'Call Completion Analytics'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.record_voice_over_rounded,
                    title: 'AI Voice Call',
                    onTap: () => _navigateToModule(
                      title: 'AI Voice Call',
                      subtitle: 'Interactive AI voice agent for citizen feedback collection',
                      category: 'Public Communication',
                      icon: Icons.record_voice_over_rounded,
                      description: 'Automated conversational calling system to ask citizens about water and garbage satisfaction.',
                      highlights: ['Real-time Marathi AI Voice', 'Automated Survey Collection', 'Immediate Escalation'],
                    ),
                  ),
                  _DrawerSubItem(
                    icon: Icons.groups_outlined,
                    title: 'Conference Room',
                    onTap: () => _navigateToModule(
                      title: 'Conference Room',
                      subtitle: 'Multi-party bridge telephone calls with ward engineers and chairmen',
                      category: 'Public Communication',
                      icon: Icons.groups_outlined,
                      description: 'Instantly connect 50+ housing society secretaries on a single joint phone bridge call.',
                      highlights: ['Instant 50+ Line Bridge', 'No Internet Required on Phone', 'Live Call Recording'],
                    ),
                  ),
                ],

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 9) ANALYSIS STRATEGY (nav.analysis_strategy) - Standalone Item
                // ==========================================
                _DrawerSingleItem(
                  icon: Icons.timeline_rounded,
                  title: 'Analysis Strategy',
                  onTap: () => _navigateToModule(
                    title: 'Analysis Strategy',
                    subtitle: 'Electoral data intelligence, voter demographics and strategic insights',
                    category: 'Strategic Intelligence',
                    icon: Icons.timeline_rounded,
                    description: 'Predictive analytics, caste and demographic distribution, and developmental priority scoring.',
                    highlights: ['Demographic Breakdown', 'Priority Development Heatmap', 'Tenure Milestone Goals'],
                  ),
                ),

                const Divider(height: 6, thickness: 0.8, color: Color(0xFFF1F5F9)),

                // ==========================================
                // 10) PROFILE SETTINGS (Settings) - Standalone Item
                // ==========================================
                _DrawerSingleItem(
                  icon: Icons.settings_rounded,
                  title: 'Profile Settings',
                  onTap: () => _navigateToModule(
                    title: 'Profile Settings',
                    subtitle: 'Nagarsevak profile, branding, bot & SMS gateway configuration',
                    category: 'System Settings',
                    icon: Icons.settings_rounded,
                    description: 'Configure official Nagarsevak identity, party branding, WhatsApp & SMS integrations, and security audit logs.',
                    highlights: ['Profile Branding & Photo', 'WhatsApp Bot & SMS Gateway', 'Audit & Security Logs'],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible Group Header matching SidebarNavGroup in AppLayout.tsx
class _DrawerGroupHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isOpen;
  final VoidCallback onToggle;

  const _DrawerGroupHeader({
    required this.title,
    required this.icon,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isOpen ? const Color(0xFF0284C7) : const Color(0xFF475569),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isOpen ? FontWeight.w700 : FontWeight.w600,
                    color: isOpen ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Icon(
                isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sub Item inside a Collapsible Group (clean title & icon, compact size)
class _DrawerSubItem extends ConsumerWidget {
  final IconData icon;
  final String title;
  final bool? isSelected;
  final VoidCallback onTap;

  const _DrawerSubItem({
    super.key,
    required this.icon,
    required this.title,
    this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = isSelected ?? (ref.watch(activeScreenProvider) == resolveScreenKey(title));
    return Container(
      margin: const EdgeInsets.only(left: 18, right: 8, top: 1, bottom: 1),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF0F9FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: active ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
            width: active ? 2.5 : 1.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? const Color(0xFF0284C7) : const Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 9.5,
                  color: active ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Standalone Item (clean title & icon, compact size)
class _DrawerSingleItem extends ConsumerWidget {
  final IconData icon;
  final String title;
  final bool? isSelected;
  final VoidCallback onTap;

  const _DrawerSingleItem({
    super.key,
    required this.icon,
    required this.title,
    this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = isSelected ?? (ref.watch(activeScreenProvider) == resolveScreenKey(title));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF0F9FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? const Color(0xFF0284C7) : const Color(0xFF475569),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: active ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
