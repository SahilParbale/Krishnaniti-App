import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/events_repository.dart';
import 'event_invite_modal.dart';
import 'event_report_generator.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late EventModel _event;
  final TextEditingController _rsvpSearchCtrl = TextEditingController();
  String _rsvpStatusFilter = 'all'; // 'all' | 'Going' | 'Maybe' | 'Not Going'

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  @override
  void dispose() {
    _rsvpSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshEvent() async {
    final repo = ref.read(eventsRepoProvider);
    final updated = await repo.getEventById(_event.id);
    if (updated != null && mounted) {
      setState(() => _event = updated);
    }
  }

  Future<void> _handleShare() async {
    final text =
        '📌 *${_event.titleMr}*\n\n'
        '📅 Date: ${_event.formattedDate}\n'
        '⏰ Time: ${_event.eventTime}\n'
        '📍 Venue: ${_event.location}\n\n'
        '${_event.description}\n\n'
        '— Nagarsevak Amit Chougale PR Office, Ward 12, PMC';

    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event details copied to clipboard!')),
          );
        }
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: text));
    }
  }

  Future<void> _handleCall(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _handleWhatsApp(String mobile, String name) async {
    final msg = Uri.encodeComponent(
      'Hello $name,\n\n'
      'You are cordially invited to the *${_event.title}* program.\n'
      'Date: ${_event.formattedDate}, Time: ${_event.eventTime}.\n'
      'Venue: ${_event.location}.\n'
      'Will you be attending?\n\n'
      '— Nagarsevak Amit Chougale Office',
    );
    final uri = Uri.parse('https://wa.me/91$mobile?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<EventRsvpModel> get _filteredRsvps {
    final q = _rsvpSearchCtrl.text.trim().toLowerCase();
    return _event.rsvps.where((r) {
      final matchesSearch = q.isEmpty ||
          r.voterName.toLowerCase().contains(q) ||
          r.voterNameMr.toLowerCase().contains(q) ||
          r.mobile.contains(q);

      final matchesStatus = _rsvpStatusFilter == 'all' ||
          r.status.id.toLowerCase() == _rsvpStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRsvps = _filteredRsvps;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _event.type.titleMr,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              tooltip: 'Official PDF Report',
              onPressed: () => EventReportGenerator.generateAndPrintReport(events: [_event]),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: 'Share',
              onPressed: _handleShare,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshEvent,
          color: const Color(0xFF0284C7),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Hero Card
                _buildHeroCard(),

                const SizedBox(height: 16),

                // 3-way RSVP Response Strip
                _buildRsvpStatsRow(),

                const SizedBox(height: 16),

                // Description Card
                _buildDescriptionCard(),

                const SizedBox(height: 16),

                // RSVP Attendees Header & Search
                _buildAttendeesSection(filteredRsvps),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await EventInviteModal.show(context, _event);
                    _refreshEvent();
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Send Invites',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge
              Container(
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _event.type.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _event.type.color.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _event.monthShortMr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _event.type.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _event.dayNum,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _event.type.color,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Titles & Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _event.type.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_event.type.icon, size: 12, color: _event.type.color),
                              const SizedBox(width: 4),
                              Text(
                                _event.type.titleMr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _event.type.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _event.isCompleted
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _event.isCompleted ? 'Completed' : 'Upcoming',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: _event.isCompleted
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _event.titleMr,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Time, Location, Area, Audience
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                _event.eventTime,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _event.locationMr.isNotEmpty ? _event.locationMr : _event.location,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Area: ${_event.area}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.group_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Target Audience: ${_event.targetAudience}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRsvpStatsRow() {
    return Row(
      children: [
        _buildStatBox(
          'Going',
          '${_event.goingCount}',
          '${_event.goingPercentage.toStringAsFixed(0)}% response',
          const Color(0xFF16A34A),
          const Color(0xFFDCFCE7),
          Icons.check_circle_rounded,
        ),
        const SizedBox(width: 8),
        _buildStatBox(
          'Maybe',
          '${_event.maybeCount}',
          'Expected Attendance',
          const Color(0xFFD97706),
          const Color(0xFFFEF3C7),
          Icons.help_rounded,
        ),
        const SizedBox(width: 8),
        _buildStatBox(
          'Not Going',
          '${_event.notGoingCount}',
          'Absent',
          const Color(0xFFDC2626),
          const Color(0xFFFEE2E2),
          Icons.cancel_rounded,
        ),
      ],
    );
  }

  Widget _buildStatBox(
    String title,
    String value,
    String sub,
    Color textCol,
    Color bgCol,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textCol.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: textCol),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              style: TextStyle(
                fontSize: 9.5,
                color: textCol.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notes_rounded, size: 18, color: Color(0xFF0284C7)),
              SizedBox(width: 6),
              Text(
                'About Event',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _event.description,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeesSection(List<EventRsvpModel> filteredRsvps) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 18, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text(
                'RSVP List (${_event.totalRsvps})',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search in RSVPs
          TextField(
            controller: _rsvpSearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name or mobile...',
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
              suffixIcon: _rsvpSearchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () => setState(() => _rsvpSearchCtrl.clear()),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 10),

          // Filter status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('All (${_event.totalRsvps})', 'all'),
                const SizedBox(width: 6),
                _buildStatusFilterChip('Going (${_event.goingCount})', 'Going'),
                const SizedBox(width: 6),
                _buildStatusFilterChip('Maybe (${_event.maybeCount})', 'Maybe'),
                const SizedBox(width: 6),
                _buildStatusFilterChip('Not Going (${_event.notGoingCount})', 'Not Going'),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // List of RSVPs
          if (filteredRsvps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _event.rsvps.isEmpty
                      ? 'No RSVPs received yet.\nUse the button below to send invitations.'
                      : 'No matching responses found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRsvps.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, idx) {
                final rsvp = filteredRsvps[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // Status Icon
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: rsvp.status.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(rsvp.status.icon, size: 16, color: rsvp.status.color),
                      ),
                      const SizedBox(width: 12),
                      // Voter Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rsvp.voterNameMr,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${rsvp.address} • ${rsvp.responseSource}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Call & WhatsApp Action Buttons
                      IconButton(
                        icon: const Icon(Icons.call_outlined, size: 18, color: Color(0xFF0284C7)),
                        onPressed: () => _handleCall(rsvp.mobile),
                        tooltip: 'Call',
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF16A34A)),
                        onPressed: () => _handleWhatsApp(rsvp.mobile, rsvp.voterNameMr),
                        tooltip: 'WhatsApp Message',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value) {
    final isSelected = _rsvpStatusFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFF334155),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      onSelected: (_) => setState(() => _rsvpStatusFilter = value),
    );
  }
}

