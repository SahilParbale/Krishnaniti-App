import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/events_repository.dart';
import '../../navigation/app_drawer.dart';
import 'event_detail_screen.dart';
import 'event_invite_modal.dart';
import 'event_report_generator.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'all'; // 'all' or EventType.id
  String _selectedArea = 'all';
  String _viewMode = 'grid'; // 'grid' | 'report'
  bool _isLoading = true;

  List<EventModel> _allEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final repo = ref.read(eventsRepoProvider);
    final events = await repo.getEvents();
    if (mounted) {
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    }
  }

  List<EventModel> get _filteredEvents {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allEvents.where((e) {
      final matchesSearch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.titleMr.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q) ||
          e.locationMr.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);

      final matchesCategory = _selectedCategory == 'all' ||
          e.type.id.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesArea =
          _selectedArea == 'all' || e.area.toLowerCase() == _selectedArea.toLowerCase();

      return matchesSearch && matchesCategory && matchesArea;
    }).toList();
  }

  List<String> get _allAreas {
    final areas = <String>{};
    for (final e in _allEvents) {
      if (e.area.isNotEmpty) areas.add(e.area);
    }
    return areas.toList();
  }

  void _showCreateEventDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'Shaniwar Peth');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    EventType selectedType = EventType.publicMeeting;
    String targetAudience = 'All Citizens';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.event_available_rounded,
                          color: Color(0xFF0284C7),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Create New Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),

                  // Title
                  const Text(
                    'Event Title*',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g., Ward 12 Citizen Meeting',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description with AI Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Description*',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      InkWell(
                        onTap: () {
                          if (titleCtrl.text.isNotEmpty) {
                            descCtrl.text =
                                'You are cordially invited to attend the event organized for the citizens of Ward 12. Please join us on time.';
                            setModalState(() {});
                          }
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF0284C7)),
                            SizedBox(width: 4),
                            Text(
                              'AI Draft Assistant',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Detailed event description...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Date & Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 180)),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(selectedDate),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                            const Text('Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setModalState(() => selectedTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedTime.format(ctx),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

                  const SizedBox(height: 12),

                  // Location & Area
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Location / Venue*', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: locCtrl,
                              decoration: InputDecoration(
                                hintText: 'e.g., Community Hall',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.all(10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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
                            const Text('Area / Ward Section', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: areaCtrl,
                              decoration: InputDecoration(
                                hintText: 'e.g., Shaniwar Peth',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.all(10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Event Type Dropdown
                  const Text('Event Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<EventType>(
                        value: selectedType,
                        isExpanded: true,
                        items: EventType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(t.icon, size: 14, color: t.color),
                                const SizedBox(width: 6),
                                Text(t.titleMr, style: const TextStyle(fontSize: 12.5)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedType = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        final newEvent = EventModel(
                          id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
                          title: titleCtrl.text.trim(),
                          titleMr: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isNotEmpty
                              ? descCtrl.text.trim()
                              : 'Event organized for Ward 12 citizens.',
                          eventDate: selectedDate,
                          eventTime: selectedTime.format(ctx),
                          location: locCtrl.text.trim().isNotEmpty ? locCtrl.text.trim() : 'Ward 12 Office',
                          locationMr: locCtrl.text.trim().isNotEmpty ? locCtrl.text.trim() : 'Ward 12 Office',
                          type: selectedType,
                          status: 'Planned',
                          area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Shaniwar Peth',
                          targetAudience: targetAudience,
                          createdAt: DateTime.now(),
                        );

                        final repo = ref.read(eventsRepoProvider);
                        await repo.createEvent(newEvent);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          _loadEvents();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('New event created successfully!'),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
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
    final filtered = _filteredEvents;
    final totalEvents = _allEvents.length;
    final upcomingEvents = _allEvents.where((e) => e.isUpcoming).length;
    final totalRsvps = _allEvents.fold<int>(0, (sum, e) => sum + e.totalRsvps);
    final totalGoing = _allEvents.fold<int>(0, (sum, e) => sum + e.goingCount);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const NagarsevakAppDrawer(),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
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
                'Events & Invites',
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
                'Public programs, festival pandal visits and invitations',
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : RefreshIndicator(
                onRefresh: _loadEvents,
                color: const Color(0xFF0284C7),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4 Executive KPI Cards
                      _buildKpiSummaryRow(totalEvents, upcomingEvents, totalRsvps, totalGoing),

                      const SizedBox(height: 16),

                      // Search and Filters Card
                      _buildSearchAndFiltersCard(filtered),

                      const SizedBox(height: 16),

                      // Events Content (Grid or Report Table)
                      if (_viewMode == 'grid')
                        _buildGridCardsView(filtered)
                      else
                        _buildReportTableView(filtered),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateEventDialog,
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'New Event',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSummaryRow(int total, int upcoming, int rsvps, int going) {
    return Row(
      children: [
        _buildKpiCard('Total Events', '$total', 'All Events', const Color(0xFF0284C7), Icons.calendar_month_rounded),
        const SizedBox(width: 8),
        _buildKpiCard('Upcoming', '$upcoming', 'Upcoming Events', const Color(0xFF8B5CF6), Icons.access_time_rounded),
        const SizedBox(width: 8),
        _buildKpiCard('Total RSVPs', '$rsvps', 'Citizen Responses', const Color(0xFFD97706), Icons.people_alt_rounded),
        const SizedBox(width: 8),
        _buildKpiCard('Confirmed', '$going', 'Going Attendees', const Color(0xFF16A34A), Icons.check_circle_rounded),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String sub, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFiltersCard(List<EventModel> filtered) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Search Input & Action Controls
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by title, location or description...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _searchCtrl.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _viewMode == 'grid' ? Icons.table_rows_rounded : Icons.grid_view_rounded,
                        color: const Color(0xFF0284C7),
                        size: 20,
                      ),
                      tooltip: _viewMode == 'grid' ? 'Table View' : 'Grid View',
                      onPressed: () {
                        setState(() {
                          _viewMode = _viewMode == 'grid' ? 'report' : 'grid';
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
                      tooltip: 'Official PDF Report',
                      onPressed: () => EventReportGenerator.generateAndPrintReport(events: filtered),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Area & Type Filters Row
          Row(
            children: [
              // Area Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedArea,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Areas', style: TextStyle(fontSize: 12))),
                        ..._allAreas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12)))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedArea = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Event Types Horizontal Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All (${_allEvents.length})', 'all'),
                const SizedBox(width: 6),
                _buildCategoryChip('Public Meetings', 'Public Meeting'),
                const SizedBox(width: 6),
                _buildCategoryChip('Inaugurations', 'Inauguration'),
                const SizedBox(width: 6),
                _buildCategoryChip('Health Camps', 'Health Camp'),
                const SizedBox(width: 6),
                _buildCategoryChip('Rallies', 'Rally'),
                const SizedBox(width: 6),
                _buildCategoryChip('Door-to-Door Visits', 'Door-to-Door'),
                const SizedBox(width: 6),
                _buildCategoryChip('Cultural Programs', 'Cultural'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
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
      onSelected: (_) => setState(() => _selectedCategory = value),
    );
  }

  // ==========================================
  // VIEW MODE 1: GRID / STREAM CARDS
  // ==========================================
  Widget _buildGridCardsView(List<EventModel> events) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No events found.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final event = events[idx];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(EventModel event) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
        );
        _loadEvents();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
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
            // Top Row: Date Block + Title & Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Block
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: event.type.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: event.type.color.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        event.monthShortMr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: event.type.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.dayNum,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: event.type.color,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Tags
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: event.type.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(event.type.icon, size: 10, color: event.type.color),
                                const SizedBox(width: 3),
                                Text(
                                  event.type.titleMr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: event.type.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              event.area,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            event.isCompleted ? 'Completed' : 'Upcoming',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: event.isCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.titleMr,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Time & Location Row
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  event.eventTime,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.locationMr.isNotEmpty ? event.locationMr : event.location,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Description Snippet
            Text(
              event.description,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Action Buttons: Send Invites & View RSVPs
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${event.goingCount} Going • ${event.totalRsvps} Responses',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                const Spacer(),
                // Send Invites Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await EventInviteModal.show(context, event);
                    _loadEvents();
                  },
                  icon: const Icon(Icons.send_rounded, size: 13),
                  label: const Text('Send Invites', style: TextStyle(fontSize: 11.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 8),
                // View RSVPs Button
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                    );
                    _loadEvents();
                  },
                  icon: const Icon(Icons.people_outline_rounded, size: 13),
                  label: const Text('View RSVPs', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW MODE 2: MULTI-COLUMN REPORT TABLE
  // ==========================================
  Widget _buildReportTableView(List<EventModel> events) {
    if (events.isEmpty) {
      return const Center(child: Text('No events available.'));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
          horizontalMargin: 12,
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Event Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Venue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('RSVP (Going/Total)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: events.map((event) {
            return DataRow(
              onSelectChanged: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                );
              },
              cells: [
                DataCell(Text('${event.formattedDateShort}\n${event.eventTime}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      event.titleMr,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.type.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.type.titleMr,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: event.type.color),
                    ),
                  ),
                ),
                DataCell(Text(event.area, style: const TextStyle(fontSize: 11.5))),
                DataCell(
                  SizedBox(
                    width: 140,
                    child: Text(
                      event.locationMr.isNotEmpty ? event.locationMr : event.location,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text('${event.goingCount} / ${event.totalRsvps}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.isCompleted ? 'Completed' : 'Upcoming',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: event.isCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
