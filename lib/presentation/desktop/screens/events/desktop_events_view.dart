import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/event_model.dart';
import '../../../../data/repositories/events_repository.dart';
import '../../../screens/events/event_invite_modal.dart';
import '../../../screens/events/event_report_generator.dart';

class DesktopEventsView extends ConsumerStatefulWidget {
  const DesktopEventsView({super.key});

  @override
  ConsumerState<DesktopEventsView> createState() => _DesktopEventsViewState();
}

class _DesktopEventsViewState extends ConsumerState<DesktopEventsView> {
  bool _loading = true;
  List<EventModel> _events = [];
  String _searchTerm = '';
  String _selectedType = 'All';
  String _viewMode = 'grid'; // 'grid' | 'report'

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(eventsRepoProvider);
      final list = await repo.getEvents();
      if (mounted) {
        setState(() {
          _events = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _events = [];
          _loading = false;
        });
      }
    }
  }

  List<EventModel> get _filteredEvents {
    return _events.where((e) {
      final matchesSearch = _searchTerm.isEmpty ||
          e.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          e.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          e.location.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesType = _selectedType == 'All' ||
          e.type.id.toLowerCase() == _selectedType.toLowerCase() ||
          e.type.titleMr.toLowerCase() == _selectedType.toLowerCase();

      return matchesSearch && matchesType;
    }).toList();
  }

  void _showAddEventModal({EventModel? item}) {
    final titleController = TextEditingController(text: item?.title ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final locationController = TextEditingController(text: item?.location ?? '');
    final areaController = TextEditingController(text: item?.area ?? 'Ward 12');
    EventType selectedType = item?.type ?? EventType.publicMeeting;
    String dateStr = item != null ? DateFormat('yyyy-MM-dd').format(item.eventDate) : DateTime.now().toIso8601String().split('T')[0];
    String timeStr = item?.eventTime ?? '10:00 AM';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 580,
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item == null ? 'Schedule New Event' : 'Edit Event',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text('Event Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Ward 12 Community Health Camp...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type & Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Event Type *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<EventType>(
                                value: selectedType,
                                items: EventType.values.map((t) {
                                  return DropdownMenuItem(value: t, child: Text(t.titleMr));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedType = val);
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dateStr, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Time & Location
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(timeStr, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                                    const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: locationController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Community Center Hall',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Text('Description *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Event agenda and details...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty) return;
                            final newEvt = EventModel(
                              id: item?.id ?? 'evt-${DateTime.now().millisecondsSinceEpoch}',
                              title: titleController.text.trim(),
                              titleMr: titleController.text.trim(),
                              description: descController.text.trim(),
                              location: locationController.text.trim().isEmpty ? 'Ward 12' : locationController.text.trim(),
                              locationMr: locationController.text.trim().isEmpty ? 'Ward 12' : locationController.text.trim(),
                              area: areaController.text.trim().isEmpty ? 'Ward 12' : areaController.text.trim(),
                              eventDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
                              eventTime: timeStr,
                              type: selectedType,
                              status: item?.status ?? 'Planned',
                              createdAt: item?.createdAt ?? DateTime.now(),
                            );

                            final repo = ref.read(eventsRepoProvider);
                            if (item == null) {
                              await repo.createEvent(newEvt);
                            } else {
                              await repo.updateEvent(newEvt);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchEvents();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          ),
                          child: Text(item == null ? 'Schedule Event' : 'Save Changes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(EventModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(eventsRepoProvider);
              await repo.deleteEvent(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchEvents();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length),
          const SizedBox(height: 20),

          // Search & Filter Row
          _buildFilterRow(),
          const SizedBox(height: 16),

          // Event Type Pills
          _buildTypePills(),
          const SizedBox(height: 24),

          // Content Grid or Report
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'report')
            _buildReportTable(filtered)
          else
            _buildCardGrid(filtered),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Events & Invites',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text('Total: $count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Plan ward meetings, community events and dispatch digital invitations',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions
        Row(
          children: [
            // View Mode
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _viewModeButton('Grid', Icons.grid_view_rounded, _viewMode == 'grid', () => setState(() => _viewMode = 'grid')),
                  _viewModeButton('Report', Icons.table_chart_outlined, _viewMode == 'report', () => setState(() => _viewMode = 'report')),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                EventReportGenerator.generateAndPrintReport(events: _filteredEvents);
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: const Text('Download Report', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),

            // Add Event
            ElevatedButton.icon(
              onPressed: () => _showAddEventModal(),
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text('+ Schedule Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _viewModeButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0F9FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchTerm = val),
        decoration: InputDecoration(
          hintText: 'Search event by title, venue or description...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _searchTerm = ''))
              : null,
        ),
      ),
    );
  }

  Widget _buildTypePills() {
    final types = [
      {'key': 'All', 'label': 'All'},
      {'key': 'Public Meeting', 'label': 'Public Meeting'},
      {'key': 'Inauguration', 'label': 'Inauguration'},
      {'key': 'Rally', 'label': 'Rally'},
      {'key': 'Health Camp', 'label': 'Health Camp'},
      {'key': 'Door-to-Door', 'label': 'Door-to-Door Outreach'},
      {'key': 'Cultural', 'label': 'Cultural'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final key = t['key']!;
        final label = t['label']!;
        final isSelected = _selectedType == key;

        return InkWell(
          onTap: () => setState(() => _selectedType = key),
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0284C7) : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardGrid(List<EventModel> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: const [
            Icon(Icons.event_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No events found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 310,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Type badge + Area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Row(
                          children: [
                            Icon(item.type.icon, size: 12, color: const Color(0xFF0369A1)),
                            const SizedBox(width: 4),
                            Text(item.type.titleMr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: Text(item.area.isEmpty ? 'Ward 12' : item.area, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Expanded(
                    child: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ),

                  // Date, Time & Location
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(item.formattedDate, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(item.eventTime, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => EventInviteModal(event: item),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
                        label: const Text('Send Invites', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                            onPressed: () => _showAddEventModal(item: item),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                            onPressed: () => _showDeleteConfirm(item),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportTable(List<EventModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: const [
            const DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Event Title & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
          ],
          rows: items.map((item) {
            return DataRow(
              cells: [
                DataCell(Text('${item.formattedDate}\n${item.eventTime}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                DataCell(Text(item.type.titleMr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)))),
                DataCell(Text(item.location, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(100)),
                    child: Text(item.status == 'Completed' ? 'Completed' : (item.status == 'Cancelled' ? 'Cancelled' : 'Planned'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 280,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
