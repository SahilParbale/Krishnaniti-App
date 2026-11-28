import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../../../data/models/event_model.dart';
import '../../../../data/repositories/events_repository.dart';
import '../../common/desktop_modal_dialog.dart';
import '../../../screens/events/event_invite_modal.dart';
import '../../../screens/events/event_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

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
  String _selectedArea = 'All';
  String _selectedDate = 'All';
  String _viewMode = 'grid'; // 'grid' | 'table'
  int _displayedLimit = 20;

  List<EventModel> get _visibleEvents =>
      _filteredEvents.take(_displayedLimit).toList();

  List<String> get _uniqueAreas {
    final areas = _events
        .map((e) => e.area.trim())
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...areas];
  }

  List<String> get _uniqueDates {
    final dates = _events
        .map((e) => DateFormat('yyyy-MM-dd').format(e.eventDate))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return ['All', ...dates];
  }

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
    final q = AppTranslations.normalizeAsciiDigits(_searchTerm.trim()).toLowerCase();
    return _events.where((e) {
      final matchesSearch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.titleMr.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q) ||
          e.locationMr.toLowerCase().contains(q) ||
          e.area.toLowerCase().contains(q);

      final matchesType = _selectedType == 'All' ||
          e.type.id.toLowerCase() == _selectedType.toLowerCase() ||
          e.type.titleMr.toLowerCase() == _selectedType.toLowerCase() ||
          e.type.titleHi.toLowerCase() == _selectedType.toLowerCase();

      final matchesArea = _selectedArea == 'All' ||
          e.area.toLowerCase().trim() == _selectedArea.toLowerCase().trim();

      final matchesDate = _selectedDate == 'All' ||
          DateFormat('yyyy-MM-dd').format(e.eventDate) == _selectedDate;

      return matchesSearch && matchesType && matchesArea && matchesDate;
    }).toList();
  }

  String _localizeEventStatus(String status, String lang) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return AppTranslations.pick(lang, en: 'Completed', mr: 'पूर्ण', hi: 'पूर्ण');
      case 'cancelled':
        return AppTranslations.pick(lang, en: 'Cancelled', mr: 'रद्द', hi: 'रद्द');
      case 'planned':
      default:
        return AppTranslations.pick(lang, en: 'Planned', mr: 'नियोजित', hi: 'नियोजित');
    }
  }

  void _showAddEventModal({EventModel? item}) {
    final titleController = TextEditingController(text: item?.title ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final locationController = TextEditingController(text: item?.location ?? '');
    final areaController = TextEditingController(text: item?.area ?? 'Ward 12');
    EventType selectedType = item?.type ?? EventType.publicMeeting;
    String dateStr = item != null
        ? DateFormat('yyyy-MM-dd').format(item.eventDate)
        : DateTime.now().toIso8601String().split('T')[0];
    String timeStr = item?.eventTime ?? '10:00 AM';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => StatefulBuilder(
          builder: (ctx, setModalState) {
            final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
            return DesktopModalDialog(
              title: item == null
                  ? AppTranslations.pick(
                      lang,
                      en: 'Schedule New Event',
                      mr: 'नवीन कार्यक्रम नियोजित करा',
                      hi: 'नया कार्यक्रम निर्धारित करें',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Edit Event',
                      mr: 'कार्यक्रम संपादित करा',
                      hi: 'कार्यक्रम संपादित करें',
                    ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Plan meetings, rallies, camps and ward public gatherings',
                mr: 'सभा, रॅली, शिबिरे आणि प्रभागातील सार्वजनिक कार्यक्रमांचे नियोजन करा',
                hi: 'बैठकें, रैलियां, शिविर और वार्ड की सार्वजनिक सभाओं की योजना बनाएं',
              ),
              icon: Icons.event_rounded,
              width: 580,
              onClose: () => Navigator.pop(ctx),
              actions: [
                DesktopModalDialog.cancelButton(ctx),
                const SizedBox(width: 12),
                DesktopModalDialog.primaryButton(
                  text: item == null
                      ? AppTranslations.pick(
                          lang,
                          en: 'Schedule Event',
                          mr: 'कार्यक्रम जोडा',
                          hi: 'कार्यक्रम निर्धारित करें',
                        )
                      : AppTranslations.pick(
                          lang,
                          en: 'Save Changes',
                          mr: 'बदल जतन करा',
                          hi: 'परिवर्तन सहेजें',
                        ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final newEvt = EventModel(
                      id: item?.id ?? 'evt-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      titleMr: titleController.text.trim(),
                      description: descController.text.trim(),
                      location: locationController.text.trim().isEmpty
                          ? 'Ward 12'
                          : locationController.text.trim(),
                      locationMr: locationController.text.trim().isEmpty
                          ? 'Ward 12'
                          : locationController.text.trim(),
                      area: areaController.text.trim().isEmpty
                          ? 'Ward 12'
                          : areaController.text.trim(),
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
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Event Title *',
                      mr: 'कार्यक्रमाचे शीर्षक *',
                      hi: 'कार्यक्रम का शीर्षक *',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: desktopInputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Ward 12 Community Health Camp...',
                        mr: 'उदा. प्रभाग १२ सार्वजनिक आरोग्य शिबिर...',
                        hi: 'जैसे वार्ड १२ सामुदायिक स्वास्थ्य शिविर...',
                      ),
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
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Event Type *',
                                mr: 'कार्यक्रमाचा प्रकार *',
                                hi: 'कार्यक्रम का प्रकार *',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<EventType>(
                              value: selectedType,
                              height: 44,
                              backgroundColor: const Color(0xFFF8FAFC),
                              borderColor: const Color(0xFFE2E8F0),
                              items: EventType.values.map((t) {
                                return DropdownMenuItem(value: t, child: Text(t.title(lang)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedType = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Date *',
                                mr: 'दिनांक *',
                                hi: 'दिनांक *',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: parsedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => dateStr = DateFormat('yyyy-MM-dd').format(picked));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: AppColors.slate200),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppTranslations.formatDate(parsedDate, lang, pattern: 'dd/MM/yyyy'),
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
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
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Time',
                                mr: 'वेळ',
                                hi: 'समय',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(hour: 10, minute: 0),
                                );
                                if (picked != null) {
                                  final dt = DateTime(2026, 1, 1, picked.hour, picked.minute);
                                  setModalState(() => timeStr = DateFormat('hh:mm a').format(dt));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: AppColors.slate200),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppTranslations.formatDigits(timeStr, lang),
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                    const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
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
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Location *',
                                mr: 'ठिकाण *',
                                hi: 'स्थान *',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: locationController,
                              decoration: desktopInputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Community Center Hall',
                                  mr: 'उदा. समाज मंदिर सभागृह',
                                  hi: 'जैसे सामुदायिक भवन हॉल',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Description *',
                      mr: 'तपशील *',
                      hi: 'विवरण *',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: desktopInputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Event agenda and details...',
                        mr: 'कार्यक्रमाची रूपरेषा आणि तपशील...',
                        hi: 'कार्यक्रम की कार्यसूची और विवरण...',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirm(EventModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppTranslations.pick(
              lang,
              en: 'Delete Event',
              mr: 'कार्यक्रम हटवा',
              hi: 'कार्यक्रम हटाएं',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Are you sure you want to delete this event?',
                  mr: 'तुम्हाला खात्री आहे की तुम्ही हा कार्यक्रम हटवू इच्छिता?',
                  hi: 'क्या आप वाकई इस कार्यक्रम को हटाना चाहते हैं?',
                ),
              ),
              const SizedBox(height: 6),
              AppTranslatedText(
                (lang == 'mr' && item.titleMr.trim().isNotEmpty) ? item.titleMr : item.title,
                targetLanguage: lang,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(eventsRepoProvider);
                await repo.deleteEvent(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchEvents();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: Text(
                AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredEvents;
    final visible = _visibleEvents;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length, lang),
          const SizedBox(height: 20),

          // Search & Filter Row
          _buildFilterRow(lang),
          const SizedBox(height: 16),

          // Event Type Pills
          _buildTypePills(lang),
          const SizedBox(height: 24),

          // Content Grid or Table
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildReportTable(visible, lang)
          else
            _buildCardGrid(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: 'events',
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Events & Invites',
                    mr: 'कार्यक्रम आणि निमंत्रणे',
                    hi: 'कार्यक्रम और निमंत्रण',
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text(
                    '${AppTranslations.pick(lang, en: 'Total:', mr: 'एकूण:', hi: 'कुल:')} ${AppTranslations.formatDigits(count, lang)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.pick(
                lang,
                en: 'Plan ward meetings, community events and dispatch digital invitations',
                mr: 'प्रभाग बैठका, सार्वजनिक कार्यक्रम नियोजन आणि डिजिटल निमंत्रणे पाठवा',
                hi: 'वार्ड बैठकों, सामुदायिक कार्यक्रमों की योजना बनाएं और डिजिटल निमंत्रण भेजें',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Schedule Event
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                EventReportGenerator.generateAndPrintReport(
                  context: context,
                  events: _filteredEvents,
                  areaFilter: _selectedArea,
                  typeFilter: _selectedType,
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.getDownloadReport(lang),
                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),

            // Add Event
            ElevatedButton(
              onPressed: () => _showAddEventModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Schedule Event',
                      mr: 'कार्यक्रम जोडा',
                      hi: 'कार्यक्रम जोड़ें',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String lang) {
    return Row(
      children: [
        // Main Search (Col 6)
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _searchTerm = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search event by title, venue or description...',
                  mr: 'शीर्षक, ठिकाण किंवा वर्णनानुसार कार्यक्रम शोधा...',
                  hi: 'शीर्षक, स्थान या विवरण से कार्यक्रम खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        tooltip: AppTranslations.pick(lang, en: 'Clear', mr: 'साफ करा', hi: 'साफ़ करें'),
                        onPressed: () => setState(() => _searchTerm = ''),
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Area Filter (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedArea,
            height: 44,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueAreas.map((area) {
              return DropdownMenuItem(
                value: area,
                child: Text(
                  area == 'All'
                      ? AppTranslations.getAllAreas(lang)
                      : AppTranslations.getAreaName(area, lang),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedArea = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 14),

        // Date Filter (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _selectedDate,
            height: 44,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: _uniqueDates.map((date) {
              final label = date == 'All'
                  ? AppTranslations.pick(lang, en: 'All Dates', mr: 'सर्व तारखा', hi: 'सभी तिथियां')
                  : AppTranslations.formatDate(
                      DateTime.tryParse(date) ?? DateTime.now(),
                      lang,
                      pattern: 'dd MMM yyyy',
                    );
              return DropdownMenuItem(
                value: date,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDate = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 14),

        // View Mode Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildViewToggleButton(
                icon: Icons.grid_view_rounded,
                label: AppTranslations.pick(lang, en: 'Grid', mr: 'ग्रिड', hi: 'ग्रिड'),
                isActive: _viewMode == 'grid',
                onTap: () => setState(() => _viewMode = 'grid'),
              ),
              const SizedBox(width: 4),
              _buildViewToggleButton(
                icon: Icons.table_rows_rounded,
                label: AppTranslations.pick(lang, en: 'Table', mr: 'तक्ता', hi: 'तालिका'),
                isActive: _viewMode == 'table',
                onTap: () => setState(() => _viewMode = 'table'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypePills(String lang) {
    final types = [
      {'key': 'All', 'label': AppTranslations.getAll(lang)},
      {'key': 'Public Meeting', 'label': EventType.publicMeeting.title(lang)},
      {'key': 'Inauguration', 'label': EventType.inauguration.title(lang)},
      {'key': 'Rally', 'label': EventType.rally.title(lang)},
      {'key': 'Health Camp', 'label': EventType.healthCamp.title(lang)},
      {'key': 'Door-to-Door', 'label': EventType.doorToDoor.title(lang)},
      {'key': 'Cultural', 'label': EventType.cultural.title(lang)},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final key = t['key']!;
        final label = t['label']!;
        final isSelected = _selectedType == key;

        return InkWell(
          onTap: () => setState(() {
            _selectedType = key;
            _displayedLimit = 20;
          }),
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

  Widget _buildCardGrid(List<EventModel> items, String lang) {
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
          children: [
            const Icon(Icons.event_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No events found',
                mr: 'कोणतेही कार्यक्रम आढळले नाहीत',
                hi: 'कोई कार्यक्रम नहीं मिला',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

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
            final displayTitle = (lang == 'mr' && item.titleMr.trim().isNotEmpty)
                ? item.titleMr
                : item.title;
            final displayLocation = (lang == 'mr' && item.locationMr.trim().isNotEmpty)
                ? item.locationMr
                : item.location;
            final displayArea = AppTranslations.getAreaName(
              item.area.isEmpty ? 'Ward 12' : item.area,
              lang,
            );

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
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.type.icon, size: 12, color: const Color(0xFF0369A1)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.type.title(lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: AppTranslatedText(
                          displayArea,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  AppTranslatedText(
                    displayTitle,
                    targetLanguage: lang,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Expanded(
                    child: AppTranslatedText(
                      item.description,
                      targetLanguage: lang,
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
                            Text(
                              AppTranslations.formatDate(item.eventDate, lang),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              AppTranslations.formatDigits(item.eventTime, lang),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: AppTranslatedText(
                                displayLocation,
                                targetLanguage: lang,
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
                        label: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Send Invites',
                            mr: 'निमंत्रणे पाठवा',
                            hi: 'निमंत्रण भेजें',
                          ),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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
                            tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                            onPressed: () => _showDeleteConfirm(item),
                            tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
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

  Widget _buildReportTable(List<EventModel> items, String lang) {
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
          columns: [
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Date & Time', mr: 'दिनांक व वेळ', hi: 'तिथि और समय'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Event Title & Details', mr: 'कार्यक्रमाचे नाव व तपशील', hi: 'कार्यक्रम का नाम और विवरण'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Category', mr: 'प्रकार', hi: 'श्रेणी'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Location', mr: 'ठिकाण', hi: 'स्थान'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
          ],
          rows: items.map((item) {
            final displayTitle = (lang == 'mr' && item.titleMr.trim().isNotEmpty)
                ? item.titleMr
                : item.title;
            final displayLocation = (lang == 'mr' && item.locationMr.trim().isNotEmpty)
                ? item.locationMr
                : item.location;
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${AppTranslations.formatDate(item.eventDate, lang)}\n${AppTranslations.formatDigits(item.eventTime, lang)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppTranslatedText(
                        displayTitle,
                        targetLanguage: lang,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      AppTranslatedText(
                        item.description,
                        targetLanguage: lang,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    item.type.title(lang),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
                DataCell(
                  AppTranslatedText(
                    displayLocation,
                    targetLanguage: lang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(100)),
                    child: Text(
                      _localizeEventStatus(item.status, lang),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
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

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
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
