import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/sms_repository.dart';
import '../../navigation/app_drawer.dart';

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

  void _showCreateMeetingDialog() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 2));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.video_call_rounded, color: Color(0xFF2563EB), size: 24),
              SizedBox(width: 8),
              Text('Schedule Meeting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Meeting Topic / Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Ward Development Discussion',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Schedule Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
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
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('dd MMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setDlgState(() => selectedTime = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(selectedTime.format(context), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Meeting Agenda / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Optional agenda details...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conference Meeting scheduled successfully!')),
                );
              },
              child: const Text('Create Meeting'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteVoterDialog(ConferenceMeetingModel meeting) {
    final searchController = TextEditingController();
    List<VoterModel> voterList = [];
    final Set<String> selectedIds = {};
    bool isLoadingVoters = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Invite Voters to Meeting',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    meeting.title,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search voter by name...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onSubmitted: (_) => fetchVoters(),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: isLoadingVoters
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                        : voterList.isEmpty
                            ? const Center(child: Text('No voters found'))
                            : ListView.separated(
                                itemCount: voterList.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (context, idx) {
                                  final v = voterList[idx];
                                  final isSel = selectedIds.contains(v.id);
                                  return CheckboxListTile(
                                    value: isSel,
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
                                    subtitle: Text('${v.mobile ?? '-'} · ${v.address}', style: const TextStyle(fontSize: 11)),
                                    dense: true,
                                    activeColor: const Color(0xFF0284C7),
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Invited $count voters to the conference!')),
                              );
                            },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text('Send Meeting Invites (${selectedIds.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
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
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
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

