import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/events_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
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

  int _displayedLimit = 20;

  List<EventModel> get _visibleEvents =>
      _filteredEvents.take(_displayedLimit).toList();

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
    final q = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim())
        .toLowerCase();
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
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'Shaniwar Peth');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    EventType selectedType = EventType.publicMeeting;
    String targetAudience = 'All';

    InputDecoration inputDec({String? hint, String? prefixText}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    Widget fieldLabel(String text, {bool isRequired = false}) {
      return AppFieldLabel(label: text, isRequired: isRequired);
    }

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
                // 1. FIXED HEADER
                AppModalHeader(
                  icon: Icons.event_available_rounded,
                  title: AppTranslations.pick(
                    lang,
                    en: 'Create New Event',
                    mr: 'नवीन कार्यक्रम तयार करा',
                    hi: 'नया कार्यक्रम बनाएं',
                  ),
                  subtitle: AppTranslations.pick(
                    lang,
                    en: 'Organize ward events, citizen gatherings and health camps',
                    mr: 'नागरिक मेळावे, सभा, आरोग्य शिबिरे व इतर कार्यक्रम',
                    hi: 'वार्ड कार्यक्रम, नागरिक सभाएं, स्वास्थ्य शिविर और अन्य आयोजन',
                  ),
                  onClose: () => Navigator.pop(ctx),
                ),

                // 2. SCROLLABLE FORM BODY & BUTTONS
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      14,
                      18,
                      MediaQuery.of(ctx).viewInsets.bottom + 24,
                    ),
                    children: [
                      // Title
                      fieldLabel(
                        AppTranslations.pick(
                          lang,
                          en: 'Event Title',
                          mr: 'कार्यक्रमाचे नाव / शीर्षक',
                          hi: 'कार्यक्रम का शीर्षक',
                        ),
                        isRequired: true,
                      ),
                      TextField(
                        controller: titleCtrl,
                        decoration: inputDec(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'e.g., Ward 12 Citizen Meeting',
                            mr: 'उदा. प्रभाग १२ नागरिक सभा',
                            hi: 'उदा. वार्ड १२ नागरिक सभा',
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Description with AI Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          fieldLabel(
                            AppTranslations.pick(
                              lang,
                              en: 'Description',
                              mr: 'तपशील / वर्णन',
                              hi: 'विवरण',
                            ),
                            isRequired: true,
                          ),
                          InkWell(
                            onTap: () {
                              if (titleCtrl.text.isNotEmpty) {
                                descCtrl.text = AppTranslations.pick(
                                  lang,
                                  en: 'You are cordially invited to attend the event organized for the citizens of Ward 12. Please join us on time.',
                                  mr: 'प्रभाग १२ मधील नागरिकांसाठी आयोजित कार्यक्रमात सहभागी होण्यासाठी हे निमंत्रण. कृपया वेळेवर उपस्थित राहावे.',
                                  hi: 'वार्ड १२ के नागरिकों के लिए आयोजित कार्यक्रम में शामिल होने के लिए आपका स्वागत है। कृपया समय पर पधारें।',
                                );
                                setModalState(() {});
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'AI Draft Assistant',
                                    mr: 'AI मसुदा सहाय्यक',
                                    hi: 'AI ड्राफ्ट सहायक',
                                  ),
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: inputDec(
                          hint: AppTranslations.pick(
                            lang,
                            en: 'Detailed event description...',
                            mr: 'कार्यक्रमाचा सविस्तर तपशील...',
                            hi: 'कार्यक्रम का विस्तृत विवरण...',
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Side-by-side: Date & Time pickers
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Date',
                                    mr: 'तारीख',
                                    hi: 'दिनांक',
                                  ),
                                  isRequired: true,
                                ),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showThemedDatePicker(
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppTranslations.formatDate(
                                            selectedDate,
                                            lang,
                                            pattern: 'dd/MM/yyyy',
                                          ),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Time',
                                    mr: 'वेळ',
                                    hi: 'समय',
                                  ),
                                  isRequired: true,
                                ),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppTranslations.formatDigits(selectedTime.format(ctx), lang),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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

                      // Side-by-side: Location & Area
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Location / Venue',
                                    mr: 'स्थान / हॉल',
                                    hi: 'स्थान / स्थल',
                                  ),
                                  isRequired: true,
                                ),
                                TextField(
                                  controller: locCtrl,
                                  decoration: inputDec(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g., Community Hall',
                                      mr: 'उदा. समाज मंदिर सभागृह',
                                      hi: 'उदा. सामुदायिक भवन',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Area / Locality',
                                    mr: 'परिसर / प्रभाग',
                                    hi: 'क्षेत्र / इलाका',
                                  ),
                                ),
                                TextField(
                                  controller: areaCtrl,
                                  decoration: inputDec(
                                    hint: AppTranslations.pick(
                                      lang,
                                      en: 'e.g., Shaniwar Peth',
                                      mr: 'उदा. शनिवार पेठ',
                                      hi: 'उदा. शनिवार पेठ',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Side-by-side: Event Type & Target Audience
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppDropdownFormField<EventType>(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Event Type',
                                    mr: 'कार्यक्रमाचा प्रकार',
                                    hi: 'कार्यक्रम का प्रकार',
                                  ),
                                  isRequired: true,
                                  value: selectedType,
                                  isExpanded: true,
                                  items: EventType.values.map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Row(
                                        children: [
                                          Icon(t.icon, size: 16, color: t.color),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              t.title(lang),
                                              style: const TextStyle(fontSize: 12.5),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedType = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppDropdownFormField<String>(
                                  label: AppTranslations.pick(
                                    lang,
                                    en: 'Target Audience',
                                    mr: 'लक्षित वर्ग / समाज',
                                    hi: 'लक्षित वर्ग',
                                  ),
                                  isRequired: true,
                                  value: targetAudience,
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'All',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'All Citizens',
                                          mr: 'सर्व नागरिक',
                                          hi: 'सभी नागरिक',
                                        ),
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'OPEN',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'OPEN',
                                          mr: 'OPEN (खुला)',
                                          hi: 'OPEN (सामान्य)',
                                        ),
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'OBC',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'OBC',
                                          mr: 'OBC (इ.मा.व.)',
                                          hi: 'OBC (अन्य पिछड़ा वर्ग)',
                                        ),
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'SC',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'SC',
                                          mr: 'SC (अनु. जाती)',
                                          hi: 'SC (अनु. जाति)',
                                        ),
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ST',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'ST',
                                          mr: 'ST (अनु. जमाती)',
                                          hi: 'ST (अनु. जनजाति)',
                                        ),
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'VJNT',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'VJNT',
                                          mr: 'VJNT (वि.जा.भ.ज.)',
                                          hi: 'VJNT',
                                        ),
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'SBC',
                                      child: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'SBC',
                                          mr: 'SBC (वि.मा.प्र.)',
                                          hi: 'SBC',
                                        ),
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => targetAudience = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

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
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'New event created successfully!',
                                      mr: 'नवीन कार्यक्रम यशस्वीरित्या तयार केला!',
                                      hi: 'नया कार्यक्रम सफलतापूर्वक बनाया गया!',
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_available_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Create Event',
                                  mr: 'कार्यक्रम तयार करा',
                                  hi: 'कार्यक्रम बनाएं',
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final filtered = _filteredEvents;

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
              tooltip: AppTranslations.pick(
                lang,
                en: 'Open Menu Drawer',
                mr: 'मेनू उघडा',
                hi: 'मेनू खोलें',
              ),
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
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Events & Invites',
                  mr: 'कार्यक्रम व निमंत्रणे',
                  hi: 'कार्यक्रम एवं निमंत्रण',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Public programs, festival pandal visits and invitations',
                  mr: 'सार्वजनिक कार्यक्रम, उत्सव भेटी व निमंत्रण व्यवस्थापन',
                  hi: 'सार्वजनिक कार्यक्रम, उत्सव भेंट और निमंत्रण प्रबंधन',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: AppShimmerList(count: 6),
              )
            : RefreshIndicator(
                onRefresh: _loadEvents,
                color: const Color(0xFF0284C7),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and Filters Card
                      _buildSearchAndFiltersCard(filtered, lang),

                      const SizedBox(height: 16),

                      // Events Content (Grid or Report Table)
                      if (_viewMode == 'grid')
                        _buildGridCardsView(_visibleEvents, lang)
                      else
                        _buildReportTableView(_visibleEvents, lang),

                      if (!_isLoading && filtered.isNotEmpty)
                        AppLoadMoreFooter(
                          currentCount: _visibleEvents.length,
                          totalCount: filtered.length,
                          pageSize: 20,
                          onLoadMore: () {
                            setState(() => _displayedLimit += 20);
                          },
                          label: AppTranslations.pick(
                            lang,
                            en: 'events',
                            mr: 'कार्यक्रम',
                            hi: 'कार्यक्रम',
                          ),
                          isMarathi: lang == 'mr',
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateEventDialog,
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            AppTranslations.pick(
              lang,
              en: 'New Event',
              mr: 'नवीन कार्यक्रम',
              hi: 'नया कार्यक्रम',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFiltersCard(List<EventModel> filtered, String lang) {
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
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Search by title, location or description...',
                      mr: 'शीर्षक, ठिकाण किंवा वर्णनाने शोधा...',
                      hi: 'शीर्षक, स्थान या विवरण से खोजें...',
                    ),
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _displayedLimit = 20;
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  onChanged: (_) => setState(() => _displayedLimit = 20),
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
                      tooltip: _viewMode == 'grid'
                          ? AppTranslations.pick(
                              lang,
                              en: 'Table View',
                              mr: 'तक्ता दृश्य',
                              hi: 'तालिका दृश्य',
                            )
                          : AppTranslations.pick(
                              lang,
                              en: 'Grid View',
                              mr: 'ग्रिड दृश्य',
                              hi: 'ग्रिड दृश्य',
                            ),
                      onPressed: () {
                        setState(() {
                          _viewMode = _viewMode == 'grid' ? 'report' : 'grid';
                        });
                      },
                    ),
                    AppPdfButton.icon(
                      tooltip: AppTranslations.getDownloadReport(lang),
                      onPressed: () => EventReportGenerator.generateAndPrintReport(
                        events: filtered,
                        lang: lang,
                      ),
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
                child: AppDropdown<String>(
                  title: AppTranslations.pick(
                    lang,
                    en: 'Filter by Area',
                    mr: 'परिसर निवडा',
                    hi: 'क्षेत्र चुनें',
                  ),
                  value: _selectedArea,
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(
                        AppTranslations.getAllAreas(lang),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    ..._allAreas.map(
                      (a) => DropdownMenuItem(
                        value: a,
                        child: AppTranslatedText(
                          AppTranslations.getAreaName(a, lang),
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
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
            ],
          ),

          const SizedBox(height: 8),

          // Event Types Horizontal Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(
                  '${AppTranslations.getAll(lang)} (${AppTranslations.formatDigits(_allEvents.length, lang)})',
                  'all',
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(EventType.publicMeeting.title(lang), 'Public Meeting'),
                const SizedBox(width: 6),
                _buildCategoryChip(EventType.inauguration.title(lang), 'Inauguration'),
                const SizedBox(width: 6),
                _buildCategoryChip(EventType.healthCamp.title(lang), 'Health Camp'),
                const SizedBox(width: 6),
                _buildCategoryChip(EventType.rally.title(lang), 'Rally'),
                const SizedBox(width: 6),
                _buildCategoryChip(EventType.doorToDoor.title(lang), 'Door-to-Door'),
                const SizedBox(width: 6),
                _buildCategoryChip(EventType.cultural.title(lang), 'Cultural'),
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
      onSelected: (_) => setState(() {
        _selectedCategory = value;
        _displayedLimit = 20;
      }),
    );
  }

  // ==========================================
  // VIEW MODE 1: GRID / STREAM CARDS
  // ==========================================
  Widget _buildGridCardsView(List<EventModel> events, String lang) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No events found.',
                mr: 'कोणतेही कार्यक्रम आढळले नाहीत.',
                hi: 'कोई कार्यक्रम नहीं मिला।',
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
        return _buildEventCard(event, lang);
      },
    );
  }

  Widget _buildEventCard(EventModel event, String lang) {
    final rawTitle =
        lang == 'mr' && event.titleMr.isNotEmpty ? event.titleMr : event.title;
    final rawLoc =
        lang == 'mr' && event.locationMr.isNotEmpty ? event.locationMr : event.location;
    final goingLabel = AppTranslations.pick(
      lang,
      en: 'Going',
      mr: 'येणार',
      hi: 'उपस्थित',
    );
    final responsesLabel = AppTranslations.pick(
      lang,
      en: 'Responses',
      mr: 'प्रतिसाद',
      hi: 'प्रतिक्रियाएं',
    );
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
                        event.monthShortFor(lang),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: event.type.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.dayNumFor(lang),
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
                                  event.type.title(lang),
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
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: AppTranslatedText(
                                AppTranslations.getAreaName(event.area, lang),
                                targetLanguage: lang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            event.isCompleted
                                ? AppTranslations.getStatus('Completed', lang)
                                : AppTranslations.pick(
                                    lang,
                                    en: 'Upcoming',
                                    mr: 'आगामी',
                                    hi: 'आगामी',
                                  ),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: event.isCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AppTranslatedText(
                        rawTitle,
                        targetLanguage: lang,
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
                AppTranslatedText(
                  AppTranslations.formatDigits(event.eventTime, lang),
                  targetLanguage: lang,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: AppTranslatedText(
                    rawLoc,
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Description Snippet
            AppTranslatedText(
              event.description,
              targetLanguage: lang,
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
                    '${AppTranslations.formatDigits(event.goingCount, lang)} $goingLabel • ${AppTranslations.formatDigits(event.totalRsvps, lang)} $responsesLabel',
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
                  label: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Send Invites',
                      mr: 'निमंत्रण पाठवा',
                      hi: 'निमंत्रण भेजें',
                    ),
                    style: const TextStyle(fontSize: 11.5),
                  ),
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
                  label: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'View RSVPs',
                      mr: 'उपस्थिती पहा',
                      hi: 'RSVP देखें',
                    ),
                    style: const TextStyle(fontSize: 11.5),
                  ),
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
  Widget _buildReportTableView(List<EventModel> events, String lang) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          AppTranslations.pick(
            lang,
            en: 'No events available.',
            mr: 'कोणतेही कार्यक्रम उपलब्ध नाहीत.',
            hi: 'कोई कार्यक्रम उपलब्ध नहीं है।',
          ),
        ),
      );
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
          columns: [
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Date & Time', mr: 'तारीख व वेळ', hi: 'दिनांक व समय'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Event Title', mr: 'कार्यक्रम शीर्षक', hi: 'कार्यक्रम शीर्षक'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Type', mr: 'प्रकार', hi: 'प्रकार'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Venue', mr: 'ठिकाण', hi: 'स्थान'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'RSVP (Going/Total)', mr: 'उपस्थिती (येणार/एकूण)', hi: 'RSVP (उपस्थित/कुल)'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
          rows: events.map((event) {
            final rawTitle =
                lang == 'mr' && event.titleMr.isNotEmpty ? event.titleMr : event.title;
            final rawLoc =
                lang == 'mr' && event.locationMr.isNotEmpty ? event.locationMr : event.location;
            return DataRow(
              onSelectChanged: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                );
              },
              cells: [
                DataCell(
                  Text(
                    '${event.formattedDateShortFor(lang)}\n${AppTranslations.formatDigits(event.eventTime, lang)}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: AppTranslatedText(
                      rawTitle,
                      targetLanguage: lang,
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
                      event.type.title(lang),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: event.type.color),
                    ),
                  ),
                ),
                DataCell(
                  AppTranslatedText(
                    AppTranslations.getAreaName(event.area, lang),
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 140,
                    child: AppTranslatedText(
                      rawLoc,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${AppTranslations.formatDigits(event.goingCount, lang)} / ${AppTranslations.formatDigits(event.totalRsvps, lang)}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.isCompleted
                          ? AppTranslations.getStatus('Completed', lang)
                          : AppTranslations.pick(
                              lang,
                              en: 'Upcoming',
                              mr: 'आगामी',
                              hi: 'आगामी',
                            ),
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
