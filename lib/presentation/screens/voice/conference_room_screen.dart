import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/sms_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/auth_provider.dart';

class ConferenceMeetingModel {
  final String id;
  final String title;
  final String meetLink;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final String status; // 'scheduled' | 'active' | 'ended'
  final int invitedCount;
  final String? notes;

  ConferenceMeetingModel({
    required this.id,
    required this.title,
    required this.meetLink,
    required this.scheduledAt,
    required this.createdAt,
    this.status = 'scheduled',
    this.invitedCount = 0,
    this.notes,
  });

  factory ConferenceMeetingModel.fromJson(Map<String, dynamic> json) {
    return ConferenceMeetingModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Ward Conference Meeting',
      meetLink: json['meet_link']?.toString() ?? '',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'scheduled',
      invitedCount: (json['invited_count'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) => {
        if (tenantId != null) 'tenant_id': tenantId,
        'title': title,
        'meet_link': meetLink,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status,
        'invited_count': invitedCount,
        if (notes != null) 'notes': notes,
      };
}

class ConferenceRoomScreen extends ConsumerStatefulWidget {
  const ConferenceRoomScreen({super.key});

  @override
  ConsumerState<ConferenceRoomScreen> createState() => _ConferenceRoomScreenState();
}

class _ConferenceRoomScreenState extends ConsumerState<ConferenceRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = false;
  List<ConferenceMeetingModel> _meetings = [];

  // Seed data
  final List<ConferenceMeetingModel> _seedMeetings = [
    ConferenceMeetingModel(
      id: 'conf-101',
      title: 'Ward 12 Water Supply & Road Infrastructure Review Meeting',
      meetLink: 'https://meet.jit.si/nagarsevak-water-review-782a',
      scheduledAt: DateTime.now().add(const Duration(hours: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'scheduled',
      invitedCount: 35,
      notes: 'Direct citizen grievance review with Shaniwar Peth and Kasba Peth residents.',
    ),
    ConferenceMeetingModel(
      id: 'conf-102',
      title: 'Housing Society Chairman & Secretary Digital Conference',
      meetLink: 'https://meet.jit.si/nagarsevak-society-sync-941b',
      scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'scheduled',
      invitedCount: 48,
      notes: 'Discussion with society executives on waste management and solar power subsidies.',
    ),
    ConferenceMeetingModel(
      id: 'conf-103',
      title: 'Youth Club & Festival Security Coordination Meeting',
      meetLink: 'https://meet.jit.si/nagarsevak-mandal-security-23c',
      scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      status: 'ended',
      invitedCount: 62,
      notes: 'Online coordination conference held successfully with festival mandal committees.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeetings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;

      var query = client.from('conference_meetings').select('*');
      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      }

      final response = await query.order('scheduled_at', ascending: false).limit(50);
      final list = (response as List<dynamic>)
          .map((item) => ConferenceMeetingModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _meetings = list.isNotEmpty ? list : List.from(_seedMeetings);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _meetings = List.from(_seedMeetings);
          _isLoading = false;
        });
      }
    }
  }

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _joinMeeting(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video meeting link')),
        );
      }
    }
  }

  Widget _fieldLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          if (isRequired)
            const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  InputDecoration _inputDec({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
    );
  }

  void _showCreateMeetingDialog() {
    final isMr = ref.read(isMarathiProvider);
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 2));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setDlgState) => Container(
          height: MediaQuery.of(context).size.height * 0.72,
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
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.video_call_rounded,
                            color: Color(0xFF0284C7),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMr ? 'व्हिडिओ बैठक आयोजित करा' : 'Schedule Video Meeting',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 17.5,
                              ),
                            ),
                            Text(
                              isMr ? 'बैठकीचा विषय व वेळ निश्चित करा' : 'Set meeting topic, date & time',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _fieldLabel(isMr ? 'बैठकीचा विषय / शीर्षक' : 'Meeting Topic / Title', isRequired: true),
                    TextField(
                      controller: titleController,
                      decoration: _inputDec(
                        hint: isMr ? 'उदा. प्रभाग विकास चर्चा' : 'e.g. Ward Development Discussion',
                        prefixIcon: const Icon(Icons.title_rounded, size: 18, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date & Time Side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel(isMr ? 'तारीख' : 'Meeting Date', isRequired: true),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setDlgState(() => selectedDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(selectedDate),
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel(isMr ? 'वेळ' : 'Meeting Time', isRequired: true),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setDlgState(() => selectedTime = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedTime.format(context),
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Meeting Agenda / Notes
                    _fieldLabel(isMr ? 'अजेंडा / टिपणी (ऐच्छिक)' : 'Meeting Agenda / Notes (Optional)'),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: _inputDec(
                        hint: isMr ? 'बैठकीतील महत्त्वाचे मुद्दे...' : 'Optional agenda details or notes...',
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          isMr ? 'बैठक आयोजित करा' : 'Schedule Meeting',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final scheduled = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-');
                          final rand = DateTime.now().millisecondsSinceEpoch % 10000;
                          final link = 'https://meet.jit.si/nagarsevak-$slug-$rand';

                          final newMeeting = ConferenceMeetingModel(
                            id: 'conf-${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            meetLink: link,
                            scheduledAt: scheduled,
                            createdAt: DateTime.now(),
                            status: 'scheduled',
                            invitedCount: 0,
                            notes: notesController.text.trim(),
                          );

                          try {
                            final client = SupabaseService.instance.client;
                            final tenantId = SupabaseService.instance.activeTenantId;
                            await client.from('conference_meetings').insert(newMeeting.toJson(tenantId: tenantId));
                          } catch (_) {}

                          setState(() {
                            _meetings.insert(0, newMeeting);
                          });

                          Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isMr ? 'कॉन्फरन्स बैठक यशस्वीरित्या नियोजित केली!' : 'Conference Meeting scheduled successfully!'),
                                backgroundColor: const Color(0xFF0284C7),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteVoterDialog(ConferenceMeetingModel meeting) {
    final isMr = ref.read(isMarathiProvider);
    final searchController = TextEditingController();
    List<VoterModel> voterList = [];
    final Set<String> selectedIds = {};
    bool isLoadingVoters = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          void fetchVoters() async {
            setSheetState(() => isLoadingVoters = true);
            try {
              final list = await ref.read(smsRepoProvider).getVotersWithMobile(
                name: searchController.text.trim(),
              );
              setSheetState(() {
                voterList = list;
                isLoadingVoters = false;
              });
            } catch (_) {
              setSheetState(() => isLoadingVoters = false);
            }
          }

          if (voterList.isEmpty && !isLoadingVoters) {
            fetchVoters();
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.80,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Color(0xFF0284C7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMr ? 'मतदारांना आमंत्रित करा' : 'Invite Voters to Meeting',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17.5,
                                ),
                              ),
                              Text(
                                meeting.title,
                                style: const TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: searchController,
                    decoration: _inputDec(
                      hint: isMr ? 'मतदाराचे नाव शोधा...' : 'Search voter by name...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                    onSubmitted: (_) => fetchVoters(),
                  ),
                ),

                // Voter List
                Expanded(
                  child: isLoadingVoters
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                      : voterList.isEmpty
                          ? Center(
                              child: Text(
                                isMr ? 'कोणतेही मतदार आढळले नाहीत' : 'No voters found',
                                style: const TextStyle(color: Color(0xFF64748B)),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: voterList.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final v = voterList[idx];
                                final isSel = selectedIds.contains(v.id);
                                return CheckboxListTile(
                                  value: isSel,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  onChanged: (val) {
                                    setSheetState(() {
                                      if (val == true) {
                                        selectedIds.add(v.id);
                                      } else {
                                        selectedIds.remove(v.id);
                                      }
                                    });
                                  },
                                  title: Text(v.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  subtitle: Text('${v.mobile ?? '-'} · ${v.address}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  dense: true,
                                  activeColor: const Color(0xFF0284C7),
                                );
                              },
                            ),
                ),

                // Footer button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () async {
                              final count = selectedIds.length;
                              try {
                                final client = SupabaseService.instance.client;
                                await client.from('conference_meetings').update({
                                  'invited_count': meeting.invitedCount + count,
                                }).eq('id', meeting.id);
                              } catch (_) {}

                              setState(() {
                                final idx = _meetings.indexWhere((m) => m.id == meeting.id);
                                if (idx != -1) {
                                  _meetings[idx] = ConferenceMeetingModel(
                                    id: meeting.id,
                                    title: meeting.title,
                                    meetLink: meeting.meetLink,
                                    scheduledAt: meeting.scheduledAt,
                                    createdAt: meeting.createdAt,
                                    status: meeting.status,
                                    invitedCount: meeting.invitedCount + count,
                                    notes: meeting.notes,
                                  );
                                }
                              });

                              Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isMr ? '$count मतदारांना बैठकीचे आमंत्रण पाठवले!' : 'Invited $count voters to the conference!'),
                                    backgroundColor: const Color(0xFF0284C7),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        isMr ? 'आमंत्रण पाठवा (${selectedIds.length})' : 'Send Meeting Invites (${selectedIds.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final upcoming = _meetings.where((m) => m.status != 'ended').toList();
    final past = _meetings.where((m) => m.status == 'ended').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const NagarsevakAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
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
              'Conference Room',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Multi-party teleconference bridges',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFFE0F2FE),
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: const Color(0xFF0284C7),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(icon: const Icon(Icons.videocam_outlined, size: 16), text: 'Upcoming (${upcoming.length})'),
                  Tab(icon: const Icon(Icons.history_outlined, size: 16), text: 'Past Meetings (${past.length})'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMeetingsList(upcoming, theme, isDark, isUpcoming: true),
                _buildMeetingsList(past, theme, isDark, isUpcoming: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateMeetingDialog,
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.video_call),
        label: const Text('New Meeting'),
      ),
    );
  }

  Widget _buildMeetingsList(
    List<ConferenceMeetingModel> list,
    ThemeData theme,
    bool isDark, {
    required bool isUpcoming,
  }) {
    if (_isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_camera_back_outlined, size: 54, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              isUpcoming ? 'No upcoming conference meetings' : 'No past meetings archive',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (isUpcoming)
              ElevatedButton.icon(
                onPressed: _showCreateMeetingDialog,
                icon: const Icon(Icons.add),
                label: const Text('Schedule First Meeting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMeetings,
      color: const Color(0xFF0284C7),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final meeting = list[index];
          final dateStr = DateFormat('dd MMM yyyy').format(meeting.scheduledAt);
          final timeStr = DateFormat('hh:mm a').format(meeting.scheduledAt);

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: meeting.status == 'ended'
                              ? Colors.grey.withOpacity(0.15)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meeting.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: meeting.status == 'ended' ? Colors.grey[700] : const Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            '${meeting.invitedCount} Invited',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meeting.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  if (meeting.notes != null && meeting.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      meeting.notes!,
                      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(timeStr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _copyLink(meeting.meetLink),
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy Link',
                      ),
                      IconButton(
                        onPressed: () => _showInviteVoterDialog(meeting),
                        icon: const Icon(Icons.person_add_alt_1, size: 18, color: Color(0xFF0284C7)),
                        tooltip: 'Invite Voters',
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _joinMeeting(meeting.meetLink),
                        icon: const Icon(Icons.videocam, size: 16),
                        label: const Text('Join Room'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

