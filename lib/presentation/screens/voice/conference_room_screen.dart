import 'dart:math';
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

  ConferenceMeetingModel copyWith({
    String? id,
    String? title,
    String? meetLink,
    DateTime? scheduledAt,
    DateTime? createdAt,
    String? status,
    int? invitedCount,
    String? notes,
  }) {
    return ConferenceMeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      meetLink: meetLink ?? this.meetLink,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      invitedCount: invitedCount ?? this.invitedCount,
      notes: notes ?? this.notes,
    );
  }

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
        ...?tenantId != null ? {'tenant_id': tenantId} : null,
        'title': title,
        'meet_link': meetLink,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status,
        'invited_count': invitedCount,
        ...?notes != null ? {'notes': notes} : null,
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
  String _viewMode = 'grid'; // 'grid' | 'report'
  String? _copiedMeetingId;
  List<ConferenceMeetingModel> _meetings = [];

  // Seed data matching Nagarsevak-Managment
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
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadMeetings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _generateMeetLink(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    final cleanSlug = slug.isEmpty ? 'meeting' : (slug.length > 30 ? slug.substring(0, 30) : slug);
    final rand = (Random().nextInt(900000) + 100000).toRadixString(36);
    return 'https://meet.jit.si/nagarsevak-$cleanSlug-$rand';
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseService.instance.client;
      final tenantId = SupabaseService.instance.activeTenantId;

      List<ConferenceMeetingModel> list = [];
      try {
        var query = client.from('conference_rooms').select('*');
        if (tenantId != null && tenantId.isNotEmpty) {
          query = query.eq('tenant_id', tenantId);
        }
        final response = await query.order('scheduled_at', ascending: false).limit(50);
        list = (response as List<dynamic>)
            .map((item) => ConferenceMeetingModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Fallback to conference_meetings table
        try {
          var query2 = client.from('conference_meetings').select('*');
          if (tenantId != null && tenantId.isNotEmpty) {
            query2 = query2.eq('tenant_id', tenantId);
          }
          final response2 = await query2.order('scheduled_at', ascending: false).limit(50);
          list = (response2 as List<dynamic>)
              .map((item) => ConferenceMeetingModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

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

  void _copyLink(String link, {String? meetingId}) {
    Clipboard.setData(ClipboardData(text: link));
    if (meetingId != null) {
      setState(() => _copiedMeetingId = meetingId);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _copiedMeetingId == meetingId) {
          setState(() => _copiedMeetingId = null);
        }
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting link copied to clipboard!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF0284C7),
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
      padding: const EdgeInsets.only(bottom: 6),
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

  InputDecoration _inputDec({String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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

  // ─────────────────────────────────────────────────────────────
  // 1. Create Meeting Modal (2-Step Flow matching ConferenceRoom.tsx)
  // ─────────────────────────────────────────────────────────────
  void _showCreateMeetingDialog() {
    final isMr = ref.read(isMarathiProvider);
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 2));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    String currentStep = 'form'; // 'form' | 'link'
    String generatedLink = '';
    bool isCopied = false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (modalCtx, setDlgState) {
          final bottomInset = MediaQuery.of(modalCtx).viewInsets.bottom;

          return Container(
            height: MediaQuery.of(modalCtx).size.height * 0.76 + (bottomInset > 0 ? 40 : 0),
            padding: EdgeInsets.only(bottom: bottomInset),
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
                // Drag handle
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

                // Modal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMr ? 'व्हिडिओ बैठक तयार करा' : 'Create Video Meeting',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                isMr ? 'बैठकीचा विषय व वेळ निश्चित करा' : 'Set meeting topic, date & time',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Modal Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      if (currentStep == 'form') ...[
                        // Step 1: Form details
                        _fieldLabel(
                          isMr ? 'बैठकीचा विषय / शीर्षक' : 'Meeting Title / Topic',
                          isRequired: true,
                        ),
                        TextField(
                          controller: titleController,
                          decoration: _inputDec(
                            hint: isMr
                                ? 'उदा. प्रभाग पाणी समस्या चर्चा'
                                : 'e.g. Ward Development Discussion',
                            prefixIcon: const Icon(Icons.title_rounded, size: 18, color: Color(0xFF64748B)),
                          ),
                          onChanged: (_) => setDlgState(() {}),
                        ),
                        const SizedBox(height: 14),

                        // Date & Time Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Picker
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(isMr ? 'तारीख' : 'Schedule Date', isRequired: true),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: modalCtx,
                                        initialDate: selectedDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
                                          Expanded(
                                            child: Text(
                                              DateFormat('dd MMM yyyy').format(selectedDate),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Time Picker
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(isMr ? 'वेळ' : 'Schedule Time', isRequired: true),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: modalCtx,
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
                                          Expanded(
                                            child: Text(
                                              selectedTime.format(modalCtx),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
                        _fieldLabel(isMr ? 'अजेंडा / टिपणी (ऐच्छिक)' : 'Notes / Agenda (Optional)'),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: _inputDec(
                            hint: isMr
                                ? 'बैठकीतील महत्त्वाचे मुद्दे किंवा टिपणी...'
                                : 'Optional agenda details or notes...',
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Step 1 Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  isMr ? 'रद्द करा' : 'Cancel',
                                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: titleController.text.trim().isEmpty
                                    ? null
                                    : () {
                                        setDlgState(() {
                                          generatedLink = _generateMeetLink(titleController.text.trim());
                                          currentStep = 'link';
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.link_rounded, size: 18),
                                label: Text(
                                  isMr ? 'लिंक तयार करा' : 'Generate Link',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Step 2: Link generation & Preview
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    isMr ? 'बैठक लिंक तयार झाली' : 'LINK GENERATED',
                                    style: const TextStyle(
                                      color: Color(0xFF15803D),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFDCFCE7)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        generatedLink,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isCopied ? Icons.check_rounded : Icons.copy_rounded,
                                        size: 18,
                                        color: isCopied ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                      ),
                                      tooltip: 'Copy Link',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: generatedLink));
                                        setDlgState(() => isCopied = true);
                                        Future.delayed(const Duration(seconds: 2), () {
                                          if (modalCtx.mounted) {
                                            setDlgState(() => isCopied = false);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Meeting Summary Preview Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleController.text.trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 5),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(selectedDate),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 5),
                                  Text(
                                    selectedTime.format(modalCtx),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (notesController.text.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  notesController.text.trim(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Step 2 Action Buttons
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                setDlgState(() => currentStep = 'form');
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                              label: Text(
                                isMr ? 'मागे' : 'Back',
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        setDlgState(() => isSaving = true);
                                        final scheduled = DateTime(
                                          selectedDate.year,
                                          selectedDate.month,
                                          selectedDate.day,
                                          selectedTime.hour,
                                          selectedTime.minute,
                                        );

                                        final newMeeting = ConferenceMeetingModel(
                                          id: 'conf-${DateTime.now().millisecondsSinceEpoch}',
                                          title: titleController.text.trim(),
                                          meetLink: generatedLink,
                                          scheduledAt: scheduled,
                                          createdAt: DateTime.now(),
                                          status: 'scheduled',
                                          invitedCount: 0,
                                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                        );

                                        try {
                                          final client = SupabaseService.instance.client;
                                          final tenantId = SupabaseService.instance.activeTenantId;
                                          try {
                                            await client.from('conference_rooms').insert(newMeeting.toJson(tenantId: tenantId));
                                          } catch (_) {
                                            await client.from('conference_meetings').insert(newMeeting.toJson(tenantId: tenantId));
                                          }
                                        } catch (_) {}

                                        if (mounted) {
                                          setState(() {
                                            _meetings.insert(0, newMeeting);
                                          });
                                        }

                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }

                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isMr ? 'कॉन्फरन्स बैठक यशस्वीरित्या सेव्ह केली!' : 'Conference meeting created successfully!',
                                              ),
                                              backgroundColor: const Color(0xFF0284C7),
                                            ),
                                          );
                                          // Immediately open Invite Voters modal just like web app
                                          _showInviteVoterModal(newMeeting);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_rounded, size: 18),
                                label: Text(
                                  isMr ? 'बैठक सेव्ह करा' : 'Save Meeting',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Voter Invite Modal (Matching ConferenceRoom.tsx)
  // ─────────────────────────────────────────────────────────────
  void _showInviteVoterModal(ConferenceMeetingModel meeting) {
    final isMr = ref.read(isMarathiProvider);
    final nameSearchController = TextEditingController();
    final addressSearchController = TextEditingController();
    final ageMinController = TextEditingController();
    final ageMaxController = TextEditingController();

    List<VoterModel> allVoters = [];
    List<VoterModel> filteredVoters = [];
    List<String> addressSuggestions = [];
    final Set<String> selectedIds = {};

    bool isLoadingVoters = true;
    bool isSending = false;
    bool showAddrSuggestions = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (modalCtx, setSheetState) {
          final bottomInset = MediaQuery.of(modalCtx).viewInsets.bottom;

          void applyFilters() {
            final nameQ = nameSearchController.text.trim().toLowerCase();
            final addrQ = addressSearchController.text.trim().toLowerCase();
            final minAge = int.tryParse(ageMinController.text.trim());
            final maxAge = int.tryParse(ageMaxController.text.trim());

            final result = allVoters.where((v) {
              final nameM = v.nameMarathi.toLowerCase();
              final nameE = v.nameEnglish.toLowerCase();
              final addr = v.address.toLowerCase();

              if (nameQ.isNotEmpty && !nameM.contains(nameQ) && !nameE.contains(nameQ)) return false;
              if (addrQ.isNotEmpty && !addr.contains(addrQ)) return false;
              if (minAge != null && v.age < minAge) return false;
              if (maxAge != null && v.age > maxAge) return false;
              return true;
            }).toList();

            setSheetState(() {
              filteredVoters = result;
            });
          }

          if (allVoters.isEmpty && isLoadingVoters) {
            ref.read(smsRepoProvider).getVotersWithMobile().then((list) {
              if (modalCtx.mounted) {
                final uniqueAddrs = list
                    .map((v) => v.address.trim())
                    .where((a) => a.isNotEmpty)
                    .toSet()
                    .toList();

                setSheetState(() {
                  allVoters = list;
                  filteredVoters = list;
                  addressSuggestions = uniqueAddrs;
                  isLoadingVoters = false;
                });
              }
            }).catchError((_) {
              if (modalCtx.mounted) {
                setSheetState(() => isLoadingVoters = false);
              }
            });
          }

          final allSelected = filteredVoters.isNotEmpty &&
              filteredVoters.every((v) => selectedIds.contains(v.id));

          return Container(
            height: MediaQuery.of(modalCtx).size.height * 0.85 + (bottomInset > 0 ? 30 : 0),
            padding: EdgeInsets.only(bottom: bottomInset),
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
                // Drag handle
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

                // Modal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Color(0xFF0284C7),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMr ? 'मतदारांना आमंत्रणे पाठवा' : 'Send Meeting Invites',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.5,
                                    ),
                                  ),
                                  Text(
                                    '${meeting.title} — ${meeting.meetLink}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Filters Box (bg-slate-50)
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      // Name Search
                      TextField(
                        controller: nameSearchController,
                        onChanged: (_) => applyFilters(),
                        decoration: _inputDec(
                          hint: isMr ? 'मतदाराचे नाव शोधा...' : 'Search voter by name...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Address Search & Age Range Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Address Search
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: addressSearchController,
                              onChanged: (val) {
                                setSheetState(() {
                                  showAddrSuggestions = val.trim().isNotEmpty;
                                });
                                applyFilters();
                              },
                              decoration: _inputDec(
                                hint: isMr ? 'पत्ता / परिसर शोधा...' : 'Search address/area...',
                                prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Age Min
                          Expanded(
                            child: TextField(
                              controller: ageMinController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (_) => applyFilters(),
                              decoration: _inputDec(hint: isMr ? 'वय Min' : 'Age Min'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text('–', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 4),

                          // Age Max
                          Expanded(
                            child: TextField(
                              controller: ageMaxController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (_) => applyFilters(),
                              decoration: _inputDec(hint: isMr ? 'वय Max' : 'Age Max'),
                            ),
                          ),
                        ],
                      ),

                      // Address Suggestions Dropdown Chips
                      if (showAddrSuggestions) ...[
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: addressSuggestions
                                .where((a) => a.toLowerCase().contains(addressSearchController.text.toLowerCase()))
                                .take(6)
                                .map(
                                  (addr) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: const Color(0xFFEFF6FF),
                                      label: Text(
                                        addr,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8)),
                                      ),
                                      onPressed: () {
                                        addressSearchController.text = addr;
                                        setSheetState(() => showAddrSuggestions = false);
                                        applyFilters();
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Select All Bar
                if (!isLoadingVoters && filteredVoters.isNotEmpty)
                  InkWell(
                    onTap: () {
                      setSheetState(() {
                        if (allSelected) {
                          for (final v in filteredVoters) {
                            selectedIds.remove(v.id);
                          }
                        } else {
                          for (final v in filteredVoters) {
                            selectedIds.add(v.id);
                          }
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: allSelected,
                            activeColor: const Color(0xFF0284C7),
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  for (final v in filteredVoters) {
                                    selectedIds.add(v.id);
                                  }
                                } else {
                                  for (final v in filteredVoters) {
                                    selectedIds.remove(v.id);
                                  }
                                }
                              });
                            },
                          ),
                          Text(
                            isMr
                                ? 'सर्व निवडा (${filteredVoters.length})'
                                : 'Select All (${filteredVoters.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Voter List
                Expanded(
                  child: isLoadingVoters
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                      : filteredVoters.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    isMr ? 'कोणतेही मतदार आढळले नाहीत' : 'No citizens found',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              itemCount: filteredVoters.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final v = filteredVoters[idx];
                                final isSel = selectedIds.contains(v.id);
                                return CheckboxListTile(
                                  value: isSel,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  activeColor: const Color(0xFF0284C7),
                                  onChanged: (val) {
                                    setSheetState(() {
                                      if (val == true) {
                                        selectedIds.add(v.id);
                                      } else {
                                        selectedIds.remove(v.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    v.displayName,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${v.address} · वय: ${v.age}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                  secondary: Text(
                                    '+91 ${v.mobile ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  dense: true,
                                );
                              },
                            ),
                ),

                // Modal Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isMr ? '${selectedIds.length} निवडले' : '${selectedIds.length} Selected',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isMr ? 'रद्द करा' : 'Cancel',
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: selectedIds.isEmpty || isSending
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setSheetState(() => isSending = true);
                                final count = selectedIds.length;
                                final targets = filteredVoters.where((v) => selectedIds.contains(v.id)).toList();

                                final dateStr = DateFormat('dd MMM yyyy').format(meeting.scheduledAt);
                                final timeStr = DateFormat('hh:mm a').format(meeting.scheduledAt);
                                final waMsg = isMr
                                    ? '🎥 आपणास व्हिडिओ मीटिंगसाठी आमंत्रित केले आहे: *${meeting.title}*\n📅 तारीख: $dateStr\n⏰ वेळ: $timeStr\n🔗 इथे सामील व्हा: ${meeting.meetLink}\n\nकृपया वेळेवर सामील व्हा.'
                                    : '🎥 You are invited to a video meeting: *${meeting.title}*\n📅 Date: $dateStr\n⏰ Time: $timeStr\n🔗 Join here: ${meeting.meetLink}\n\nPlease join on time.';

                                final encoded = Uri.encodeComponent(waMsg);
                                if (targets.isNotEmpty) {
                                  final firstMobile = targets.first.mobile?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                                  final clean = firstMobile.startsWith('91') ? firstMobile : '91$firstMobile';
                                  final uri = Uri.parse('https://wa.me/$clean?text=$encoded');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                }

                                try {
                                  final client = SupabaseService.instance.client;
                                  final newCount = meeting.invitedCount + count;
                                  try {
                                    await client.from('conference_rooms').update({'invited_count': newCount}).eq('id', meeting.id);
                                  } catch (_) {
                                    await client.from('conference_meetings').update({'invited_count': newCount}).eq('id', meeting.id);
                                  }
                                } catch (_) {}

                                if (mounted) {
                                  setState(() {
                                    final idx = _meetings.indexWhere((m) => m.id == meeting.id);
                                    if (idx != -1) {
                                      _meetings[idx] = _meetings[idx].copyWith(
                                        invitedCount: _meetings[idx].invitedCount + count,
                                      );
                                    }
                                  });
                                }

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }

                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isMr
                                            ? '✅ $count मतदारांना बैठकीचे आमंत्रण पाठवले!'
                                            : '✅ Sent conference invites to $count citizens!',
                                      ),
                                      backgroundColor: const Color(0xFF16A34A),
                                    ),
                                  );
                                }
                              },
                        icon: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(
                          isMr ? 'WhatsApp वर पाठवा' : 'Send via WhatsApp',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Status Styling Helper
  // ─────────────────────────────────────────────────────────────
  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFFDCFCE7);
      case 'ended':
        return const Color(0xFFF1F5F9);
      case 'scheduled':
      default:
        return const Color(0xFFE0F2FE);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF15803D);
      case 'ended':
        return const Color(0xFF475569);
      case 'scheduled':
      default:
        return const Color(0xFF0369A1);
    }
  }

  String _getStatusText(String status, bool isMr) {
    switch (status.toLowerCase()) {
      case 'active':
        return isMr ? 'सक्रिय' : 'ACTIVE';
      case 'ended':
        return isMr ? 'पूर्ण' : 'ENDED';
      case 'scheduled':
      default:
        return isMr ? 'नियोजित' : 'SCHEDULED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final now = DateTime.now();
    final upcomingMeetings = _meetings.where((m) => m.scheduledAt.isAfter(now) || m.status == 'active').toList();
    final pastMeetings = _meetings.where((m) => m.scheduledAt.isBefore(now) && m.status != 'active').toList();
    final displayMeetings = _tabController.index == 0 ? upcomingMeetings : pastMeetings;

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
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      isMr ? 'व्हिडिओ कॉन्फरन्स रूम' : 'Conference Room',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${displayMeetings.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  isMr
                      ? 'नागरिक व कार्यकर्त्यांशी सुरक्षित डिजिटल बैठक व्यवस्था'
                      : 'Multi-party teleconference bridges',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE0F2FE),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _loadMeetings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header TabBar + View Mode Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Tabs
                Expanded(
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
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      labelColor: const Color(0xFF0284C7),
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.calendar_today_rounded, size: 14),
                          text: isMr
                              ? 'सक्रिय / आगामी (${upcomingMeetings.length})'
                              : 'Upcoming (${upcomingMeetings.length})',
                        ),
                        Tab(
                          icon: const Icon(Icons.history_rounded, size: 14),
                          text: isMr
                              ? 'मागील बैठका (${pastMeetings.length})'
                              : 'Past (${pastMeetings.length})',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // View Mode Toggle (Grid vs Report)
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _viewMode = 'grid'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == 'grid' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            size: 18,
                            color: _viewMode == 'grid' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _viewMode = 'report'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == 'report' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 18,
                            color: _viewMode == 'report' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading && _meetings.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                : RefreshIndicator(
                    onRefresh: _loadMeetings,
                    color: const Color(0xFF0284C7),
                    child: _viewMode == 'grid'
                        ? _buildGridView(displayMeetings, isMr)
                        : _buildReportView(displayMeetings, isMr),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateMeetingDialog,
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          isMr ? 'नवीन रूम तयार करा' : 'New Room',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. Grid View Layout (matching ConferenceRoom.tsx)
  // ─────────────────────────────────────────────────────────────
  Widget _buildGridView(List<ConferenceMeetingModel> list, bool isMr) {
    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videocam_outlined, size: 54, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              Text(
                isMr ? 'कोणतीही बैठक उपलब्ध नाही' : 'No conference rooms active',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMr
                    ? 'नवीन व्हिडिओ रूम तयार करण्यासाठी खालील बटण दाबा'
                    : 'Create a room to start video conferencing with citizens',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _showCreateMeetingDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(isMr ? 'पहिली बैठक आयोजित करा' : 'Schedule First Meeting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final meeting = list[index];
        final dateStr = DateFormat('dd MMM yyyy').format(meeting.scheduledAt);
        final timeStr = DateFormat('hh:mm a').format(meeting.scheduledAt);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: const Border(
              left: BorderSide(color: Color(0xFF0284C7), width: 4),
              top: BorderSide(color: Color(0xFFE2E8F0)),
              right: BorderSide(color: Color(0xFFE2E8F0)),
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status Badge & Scheduled Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusBg(meeting.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(meeting.status, isMr),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(meeting.status),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12.5, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                meeting.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
              ),

              // Notes / Agenda
              if (meeting.notes != null && meeting.notes!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  meeting.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Info Row: Time & Invited Count
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${meeting.invitedCount} ${isMr ? 'आमंत्रित' : 'Invited'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Meet Link Container with Copy Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 15, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meeting.meetLink,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          color: Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _copyLink(meeting.meetLink, meetingId: meeting.id),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _copiedMeetingId == meeting.id ? Icons.check_rounded : Icons.copy_rounded,
                          size: 15,
                          color: _copiedMeetingId == meeting.id ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons: Join Room & Send Invites
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _joinMeeting(meeting.meetLink),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.videocam_rounded, size: 16),
                      label: Text(
                        isMr ? 'सामील व्हा' : 'Join Room',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showInviteVoterModal(meeting),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: Text(
                        isMr ? 'आमंत्रण पाठवा' : 'Send Invites',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. Report / Table View Layout (matching ConferenceRoom.tsx)
  // ─────────────────────────────────────────────────────────────
  Widget _buildReportView(List<ConferenceMeetingModel> list, bool isMr) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        // Table Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${isMr ? "बैठकांचा रिपोर्ट" : "Meetings Report"} (${list.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        Clipboard.setData(ClipboardData(
                          text: list
                              .map((m) =>
                                  '${DateFormat('dd/MM/yyyy HH:mm').format(m.scheduledAt)} | ${m.title} | ${m.status} | Invited: ${m.invitedCount} | ${m.meetLink}')
                              .join('\n'),
                        ));
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(isMr ? 'रिपोर्ट कॉपी केला!' : 'Report data copied!'),
                            backgroundColor: const Color(0xFF0284C7),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.copy_all_rounded, size: 14, color: Color(0xFF0284C7)),
                      label: Text(
                        isMr ? 'कॉपी करा' : 'Copy Report',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Data Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: [
                    DataColumn(
                      label: Text(
                        isMr ? 'तारीख व वेळ' : 'Date & Time',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        isMr ? 'बैठकीचा विषय' : 'Meeting Title',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        isMr ? 'स्थिती' : 'Status',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        isMr ? 'आमंत्रित' : 'Invited',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        isMr ? 'मीटिंग लिंक' : 'Meet Link',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        isMr ? 'पर्याय' : 'Options',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                  rows: list.map((meeting) {
                    final dateStr = DateFormat('dd MMM yyyy').format(meeting.scheduledAt);
                    final timeStr = DateFormat('hh:mm a').format(meeting.scheduledAt);

                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(timeStr, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meeting.title,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (meeting.notes != null)
                                  Text(
                                    meeting.notes!,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusBg(meeting.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(meeting.status, isMr),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusTextColor(meeting.status),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text('${meeting.invitedCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  meeting.meetLink.replaceFirst('https://', ''),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Color(0xFF0284C7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _copiedMeetingId == meeting.id ? Icons.check_rounded : Icons.copy_rounded,
                                  size: 14,
                                  color: _copiedMeetingId == meeting.id ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                ),
                                onPressed: () => _copyLink(meeting.meetLink, meetingId: meeting.id),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.videocam_rounded, size: 18, color: Color(0xFF0284C7)),
                                tooltip: 'Join',
                                onPressed: () => _joinMeeting(meeting.meetLink),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF25D366)),
                                tooltip: 'Invite Voters',
                                onPressed: () => _showInviteVoterModal(meeting),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
