import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModuleDetailItem {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String meta;
  final IconData icon;
  final String? actionLabel;

  const ModuleDetailItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.meta,
    required this.icon,
    this.actionLabel,
  });
}

class ModuleDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final String description;
  final List<String> highlights;

  const ModuleDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.description,
    required this.highlights,
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ModuleDetailItem> _getMockRecords() {
    final lowerTitle = widget.title.toLowerCase();

    if (lowerTitle.contains('diary')) {
      return const [
        ModuleDetailItem(
          title: 'Prabhag Drainage Line Inspection',
          subtitle: 'Site visit with Junior Engineer Shri Deshmukh at Sector 4.',
          status: '10:30 AM',
          statusColor: Color(0xFF0284C7),
          meta: 'Today • Sector 4 Market Road',
          icon: Icons.location_on_rounded,
          actionLabel: 'View Location',
        ),
        ModuleDetailItem(
          title: 'Housing Society Delegation Meeting',
          subtitle: 'Discussion on borewell permission and garbage segregation.',
          status: '02:00 PM',
          statusColor: Color(0xFF0284C7),
          meta: 'Today • Ward Central Office',
          icon: Icons.people_alt_rounded,
          actionLabel: 'Call Secretary',
        ),
        ModuleDetailItem(
          title: 'Municipal General Body Agenda Prep',
          subtitle: 'Reviewing 4 submitted ward resolutions with party whip.',
          status: '04:30 PM',
          statusColor: Color(0xFFD97706),
          meta: 'Today • PMC Headquarters',
          icon: Icons.assignment_turned_in_rounded,
          actionLabel: 'View Agenda',
        ),
        ModuleDetailItem(
          title: 'Senior Citizen Health Camp Inauguration',
          subtitle: 'Free eye and blood sugar checkup organized with Rotary Club.',
          status: 'Upcoming',
          statusColor: Color(0xFF10B981),
          meta: 'Tomorrow • Community Hall',
          icon: Icons.health_and_safety_rounded,
          actionLabel: 'Invite List',
        ),
      ];
    } else if (lowerTitle.contains('gb register') || lowerTitle.contains('register')) {
      return const [
        ModuleDetailItem(
          title: 'Motion #142: Sector 4 Concrete Road Widening',
          subtitle: 'Proposal to sanction ₹45 Lakhs for internal lane concretization.',
          status: 'Approved',
          statusColor: Color(0xFF10B981),
          meta: 'GB Meeting 18 Jan 2025 • Resolution #88',
          icon: Icons.check_circle_rounded,
          actionLabel: 'Work Order',
        ),
        ModuleDetailItem(
          title: 'Question #91: Low Water Pressure in Prabhag 12',
          subtitle: 'Starred question submitted to Municipal Water Works Engineer.',
          status: 'Replied',
          statusColor: Color(0xFF0284C7),
          meta: 'GB Meeting 04 Jan 2025 • Dept Reply Recd',
          icon: Icons.chat_bubble_outline_rounded,
          actionLabel: 'Read Reply',
        ),
        ModuleDetailItem(
          title: 'Motion #156: New Public Gymnasium in Sector 3 Park',
          subtitle: 'Allocation of Nagarsevak development fund of ₹25 Lakhs.',
          status: 'Under Review',
          statusColor: Color(0xFFD97706),
          meta: 'Standing Committee • Pending Finance NOC',
          icon: Icons.pending_rounded,
          actionLabel: 'Follow Up',
        ),
      ];
    } else if (lowerTitle.contains('office')) {
      return const [
        ModuleDetailItem(
          title: 'Prabhag 12 Ward Municipal Office',
          subtitle: 'Ward Officer: Shri Ravindra Patil (Mo: 98220-XXXXX)',
          status: 'Open (9am - 6pm)',
          statusColor: Color(0xFF10B981),
          meta: 'Sector 4, Near Municipal School • 020-2550XXXX',
          icon: Icons.account_balance_rounded,
          actionLabel: 'Call Office',
        ),
        ModuleDetailItem(
          title: 'MSEDCL Electrical Division Office',
          subtitle: 'Junior Engineer: Smt. Anjali Joshi (Mo: 94220-XXXXX)',
          status: '24x7 Helpline',
          statusColor: Color(0xFF0284C7),
          meta: 'Substation Lane 2, Prabhag 12 • 1912',
          icon: Icons.electric_bolt_rounded,
          actionLabel: 'Call Helpline',
        ),
        ModuleDetailItem(
          title: 'Prabhag Police Chowki / Station',
          subtitle: 'Senior Police Inspector: Shri Sachin Shinde',
          status: 'Emergency 112',
          statusColor: Color(0xFFEF4444),
          meta: 'Main Chowk, Sector 3 • 020-2444XXXX',
          icon: Icons.local_police_rounded,
          actionLabel: 'Emergency Call',
        ),
        ModuleDetailItem(
          title: 'Municipal Urban Health & Wellness Center',
          subtitle: 'Medical Officer: Dr. Smita Kulkarni (Mo: 98230-XXXXX)',
          status: 'Open (8am - 2pm)',
          statusColor: Color(0xFF10B981),
          meta: 'Near Garden Gate, Prabhag 12',
          icon: Icons.local_hospital_rounded,
          actionLabel: 'Call Clinic',
        ),
      ];
    } else if (lowerTitle.contains('visitor')) {
      return const [
        ModuleDetailItem(
          title: 'Mr. Ramesh Shinde & 4 Residents',
          subtitle: 'Issue: Stormwater drain clogging in Lane 4 during rains.',
          status: 'Logged',
          statusColor: Color(0xFF0284C7),
          meta: 'Token #01 • 10:15 AM • Sector 2',
          icon: Icons.badge_rounded,
          actionLabel: 'Forward to JE',
        ),
        ModuleDetailItem(
          title: 'Shivaji Chowk Traders Association',
          subtitle: 'Issue: Request for additional streetlights and CCTV camera installation.',
          status: 'Letter Drafted',
          statusColor: Color(0xFF10B981),
          meta: 'Token #02 • 11:30 AM • Commercial Zone',
          icon: Icons.store_rounded,
          actionLabel: 'View Letter',
        ),
        ModuleDetailItem(
          title: 'Mrs. Sunita Jadhav',
          subtitle: 'Issue: Help needed with Ladki Bahin Yojana DBT verification.',
          status: 'Resolved',
          statusColor: Color(0xFF10B981),
          meta: 'Token #03 • 12:10 PM • EWS Colony',
          icon: Icons.check_circle_rounded,
          actionLabel: 'Completed',
        ),
      ];
    } else if (lowerTitle.contains('problem')) {
      return const [
        ModuleDetailItem(
          title: 'Chronic Garbage Dumping Spot at Sector 3 Corner',
          subtitle: 'Citizens dump household waste daily. Requires garbage bin & CCTV.',
          status: 'High Priority',
          statusColor: Color(0xFFEF4444),
          meta: 'Prabhag 12 • 45 Citizen Complaints',
          icon: Icons.delete_outline_rounded,
          actionLabel: 'Dispatch Van',
        ),
        ModuleDetailItem(
          title: 'Low Water Pressure During Morning Hours',
          subtitle: 'Affecting 3 Housing Societies at Sector 4 end.',
          status: 'In Progress',
          statusColor: Color(0xFFD97706),
          meta: 'Water Dept • Pipeline Booster Needed',
          icon: Icons.water_drop_outlined,
          actionLabel: 'Track Ticket',
        ),
        ModuleDetailItem(
          title: 'Damaged Manhole Cover on Main DP Road',
          subtitle: 'Traffic hazard in front of municipal school gate.',
          status: 'Action Taken',
          statusColor: Color(0xFF10B981),
          meta: 'Replaced with heavy-duty ductile iron cover',
          icon: Icons.check_circle_rounded,
          actionLabel: 'View Photo',
        ),
      ];
    } else if (lowerTitle.contains('budget') || lowerTitle.contains('provision')) {
      return const [
        ModuleDetailItem(
          title: 'Internal Road Concreting & Paver Blocks',
          subtitle: 'Sanctioned: ₹95.00 Lakhs • Spent: ₹72.50 Lakhs',
          status: '76% Spent',
          statusColor: Color(0xFF0284C7),
          meta: 'Head 42-Roads • Balance: ₹22.50 L',
          icon: Icons.add_road_rounded,
          actionLabel: 'View Tenders',
        ),
        ModuleDetailItem(
          title: 'Stormwater Drainage & Gutter Covering',
          subtitle: 'Sanctioned: ₹60.00 Lakhs • Spent: ₹51.20 Lakhs',
          status: '85% Spent',
          statusColor: Color(0xFF10B981),
          meta: 'Head 45-Drainage • Balance: ₹8.80 L',
          icon: Icons.water_damage_rounded,
          actionLabel: 'Audit Sheet',
        ),
        ModuleDetailItem(
          title: 'LED Streetlighting & Solar High Mast Lamps',
          subtitle: 'Sanctioned: ₹35.00 Lakhs • Spent: ₹21.00 Lakhs',
          status: '60% Spent',
          statusColor: Color(0xFFD97706),
          meta: 'Head 48-Electrical • Balance: ₹14.00 L',
          icon: Icons.lightbulb_rounded,
          actionLabel: 'Work Progress',
        ),
      ];
    } else if (lowerTitle.contains('improvement')) {
      return const [
        ModuleDetailItem(
          title: 'Pedestrian Skywalk at Shivaji Chowk Junction',
          subtitle: 'Citizen petition with 420 signatures to prevent pedestrian accidents.',
          status: 'Feasibility Study',
          statusColor: Color(0xFF0284C7),
          meta: 'Proposed Budget: ₹1.2 Cr • Urban Planning Dept',
          icon: Icons.directions_walk_rounded,
          actionLabel: 'View Survey',
        ),
        ModuleDetailItem(
          title: 'Underground Electrical Ducting across Prabhag 12',
          subtitle: 'Replace dangerous dangling overhead wires with neat underground cables.',
          status: 'Sanctioned in GB',
          statusColor: Color(0xFF10B981),
          meta: 'Joint Project with MSEDCL & PMC',
          icon: Icons.cable_rounded,
          actionLabel: 'Project Plan',
        ),
      ];
    } else if (lowerTitle.contains('sms') || lowerTitle.contains('whatsapp') || lowerTitle.contains('voice') || lowerTitle.contains('conference') || lowerTitle.contains('communication')) {
      return const [
        ModuleDetailItem(
          title: 'Prabhag 12 Water Shutdown Alert Broadcast',
          subtitle: 'Scheduled maintenance notification sent to 8,420 registered numbers.',
          status: 'Delivered (98%)',
          statusColor: Color(0xFF10B981),
          meta: 'Sent 02 Feb • Sector 2, 3, 4',
          icon: Icons.sms_rounded,
          actionLabel: 'Report',
        ),
        ModuleDetailItem(
          title: 'Ladki Bahin Yojana Helpdesk Invitation',
          subtitle: 'WhatsApp template broadcast with form download PDF link.',
          status: 'Sent (14,200)',
          statusColor: Color(0xFF0284C7),
          meta: 'Delivered to Women Beneficiaries',
          icon: Icons.chat_rounded,
          actionLabel: 'Analytics',
        ),
        ModuleDetailItem(
          title: 'Ganesh Festival Greetings Voice Broadcast',
          subtitle: '30-second personalized Marathi audio in Hon. Nagarsevak voice.',
          status: 'Completed',
          statusColor: Color(0xFF10B981),
          meta: '12,500 Connected Calls • 82% Listen Rate',
          icon: Icons.phone_in_talk_rounded,
          actionLabel: 'Play Audio',
        ),
      ];
    } else if (lowerTitle.contains('social') || lowerTitle.contains('newspaper') || lowerTitle.contains('media') || lowerTitle.contains('content')) {
      return const [
        ModuleDetailItem(
          title: 'Sakal Daily: "Prabhag 12 Model Drainage Work Praised"',
          subtitle: 'Front page local edition coverage highlighting flood prevention.',
          status: 'Published',
          statusColor: Color(0xFF10B981),
          meta: 'Sakal Pune • 28 Jan 2025 • Page 3',
          icon: Icons.newspaper_rounded,
          actionLabel: 'View Clipping',
        ),
        ModuleDetailItem(
          title: 'Facebook & Instagram Road Inundation Relief Reel',
          subtitle: 'Short video reaching 24.5K views with 1,200 shares and positive comments.',
          status: 'Viral (24.5K Views)',
          statusColor: Color(0xFF0284C7),
          meta: 'Instagram • 94% Positive Sentiment',
          icon: Icons.trending_up_rounded,
          actionLabel: 'View Reel',
        ),
        ModuleDetailItem(
          title: 'AI Marathi Speech Draft: "Ward Development Vision 2025"',
          subtitle: 'Speech drafted for upcoming Housing Society Chairmen Annual Meet.',
          status: 'Draft Ready',
          statusColor: Color(0xFFD97706),
          meta: 'AI Content Studio • Marathi Formal',
          icon: Icons.auto_awesome_rounded,
          actionLabel: 'Read Speech',
        ),
      ];
    } else if (lowerTitle.contains('event') || lowerTitle.contains('gallery')) {
      return const [
        ModuleDetailItem(
          title: 'Free Mega Health & Eye Checkup Camp',
          subtitle: 'Joint initiative with Rotary Club & Sancheti Hospital at Community Hall.',
          status: 'This Sunday',
          statusColor: Color(0xFF0284C7),
          meta: '09:00 AM - 03:00 PM • 450 RSVPs',
          icon: Icons.event_rounded,
          actionLabel: 'Attendee List',
        ),
        ModuleDetailItem(
          title: 'Inauguration of Sector 4 Solar Streetlight Grid',
          subtitle: 'Ceremony by Hon. Minister with 200+ local residents attending.',
          status: 'Completed',
          statusColor: Color(0xFF10B981),
          meta: '18 Jan 2025 • 42 Photos in Gallery',
          icon: Icons.photo_library_rounded,
          actionLabel: 'View Album',
        ),
      ];
    } else if (lowerTitle.contains('voter') || lowerTitle.contains('sadasya') || lowerTitle.contains('political') || lowerTitle.contains('survey') || lowerTitle.contains('housing') || lowerTitle.contains('team') || lowerTitle.contains('karyakarta') || lowerTitle.contains('opposition') || lowerTitle.contains('ngo')) {
      return const [
        ModuleDetailItem(
          title: 'Booth #14 & #15 Active Volunteer Roster',
          subtitle: 'Karyakarta team lead: Shri Sandeep More (98224-XXXXX)',
          status: '18 Active Workers',
          statusColor: Color(0xFF10B981),
          meta: 'Prabhag 12 • 1,420 Target Families Mapped',
          icon: Icons.groups_rounded,
          actionLabel: 'Contact Team',
        ),
        ModuleDetailItem(
          title: 'Shree Sai Co-Op Housing Society (120 Flats)',
          subtitle: 'Chairman: Shri V. K. Deshpande • Gutter overflow issue resolved.',
          status: 'Strong Support',
          statusColor: Color(0xFF0284C7),
          meta: 'Sector 3 • 248 Registered Voters',
          icon: Icons.home_work_rounded,
          actionLabel: 'Society Card',
        ),
        ModuleDetailItem(
          title: 'ECI Form 6 Voter Registration Camp Drive',
          subtitle: '45 New college students enrolled in official electoral roll.',
          status: 'Processed',
          statusColor: Color(0xFF10B981),
          meta: 'Booth 12 • EPIC Cards Dispatched',
          icon: Icons.description_rounded,
          actionLabel: 'View Forms',
        ),
      ];
    } else if (lowerTitle.contains('analysis') || lowerTitle.contains('strategy')) {
      return const [
        ModuleDetailItem(
          title: 'Prabhag 12 Booth Demographic Trend Report',
          subtitle: 'Analysis of 28 polling booths, age distribution and developmental priorities.',
          status: 'Comprehensive Audit',
          statusColor: Color(0xFF0284C7),
          meta: '42,560 Registered Voters • 28 Polling Stations',
          icon: Icons.timeline_rounded,
          actionLabel: 'View Insights',
        ),
        ModuleDetailItem(
          title: 'Civic Issue Resolution Efficiency Score: 84.6%',
          subtitle: 'Benchmarked across Pune Municipal Corporation ward tenures.',
          status: 'Top Ranked',
          statusColor: Color(0xFF10B981),
          meta: '128 Logged • Average Turnaround 4.2 Days',
          icon: Icons.trending_up_rounded,
          actionLabel: 'Benchmark',
        ),
      ];
    } else {
      // Work History / General
      return const [
        ModuleDetailItem(
          title: 'Construction of Prabhag 12 Senior Citizen Park',
          subtitle: 'Complete landscaping, jogging track, open gym and lighting.',
          status: 'Completed',
          statusColor: Color(0xFF10B981),
          meta: 'Cost: ₹38.5 Lakhs • Inaugurated Oct 2024',
          icon: Icons.park_rounded,
          actionLabel: 'Certificate',
        ),
        ModuleDetailItem(
          title: 'Resurfacing of Sector 3 & 4 Main Arterial Road',
          subtitle: '1.8 km asphalt resurfacing with thermoplastic road marking.',
          status: 'Completed',
          statusColor: Color(0xFF10B981),
          meta: 'Cost: ₹62.0 Lakhs • Completed Aug 2024',
          icon: Icons.verified_rounded,
          actionLabel: 'Audit Passed',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = _getMockRecords();
    final query = _searchController.text.trim().toLowerCase();
    final filtered = records.where((r) {
      if (query.isEmpty) return true;
      return r.title.toLowerCase().contains(query) ||
          r.subtitle.toLowerCase().contains(query) ||
          r.meta.toLowerCase().contains(query);
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 21),
              tooltip: 'Share Report',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exporting ${widget.title} summary...')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 21),
              tooltip: 'Filters',
              onPressed: () {},
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Top Highlights Banner
            Container(
              width: double.infinity,
              color: const Color(0xFF0284C7),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(widget.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFBAE6FD),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.highlights.map((h) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 13),
                              const SizedBox(width: 5),
                              Text(
                                h,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Search & Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() {}),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Search ${widget.title.toLowerCase()} records...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                      ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Records List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.icon, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No records found',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: item.statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(item.icon, color: item.statusColor, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.subtitle,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF64748B),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: item.statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.meta,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.actionLabel != null)
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Action: ${item.actionLabel} for "${item.title}"'),
                                            backgroundColor: const Color(0xFF0284C7),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.actionLabel!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0284C7),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF0284C7)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 3,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening new entry form for ${widget.title}...'),
                backgroundColor: const Color(0xFF0284C7),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text('New ${widget.title.split(' ').first} Entry', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
