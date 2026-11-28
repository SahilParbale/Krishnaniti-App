import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/events_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pagination_bar.dart';
import 'event_invite_modal.dart';
import 'event_report_generator.dart';
import '../../widgets/app_pdf_button.dart';

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
  int _rsvpPage = 1;
  static const int _rsvpPageSize = 8;

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

  String _rawTitle(String lang) =>
      lang == 'mr' && _event.titleMr.isNotEmpty ? _event.titleMr : _event.title;

  String _rawLoc(String lang) =>
      lang == 'mr' && _event.locationMr.isNotEmpty
          ? _event.locationMr
          : _event.location;

  Future<void> _handleShare() async {
    final lang = ref.read(appLanguageProvider);
    final rTitle = _rawTitle(lang);
    final rLoc = _rawLoc(lang);
    final titleText =
        DynamicTranslationService.getCachedTranslation(rTitle, lang) ?? rTitle;
    final locText =
        DynamicTranslationService.getCachedTranslation(rLoc, lang) ?? rLoc;
    final descText =
        DynamicTranslationService.getCachedTranslation(_event.description, lang) ??
            _event.description;
    final dateLabel =
        AppTranslations.pick(lang, en: 'Date', mr: 'तारीख', hi: 'दिनांक');
    final timeLabel =
        AppTranslations.pick(lang, en: 'Time', mr: 'वेळ', hi: 'समय');
    final venueLabel =
        AppTranslations.pick(lang, en: 'Venue', mr: 'ठिकाण', hi: 'स्थान');
    final footer = AppTranslations.pick(
      lang,
      en: '— Nagarsevak Amit Chougale PR Office, Ward 12, PMC',
      mr: '— नगरसेवक अमित चौगुले जनसंपर्क कार्यालय, प्रभाग १२, मनपा',
      hi: '— नगरसेवक अमित चौगुले जनसंपर्क कार्यालय, वार्ड १२, मनपा',
    );
    final text =
        '*$titleText*\n\n'
        '$dateLabel: ${_event.formattedDateFor(lang)}\n'
        '$timeLabel: ${AppTranslations.formatDigits(_event.eventTime, lang)}\n'
        '$venueLabel: $locText\n\n'
        '$descText\n\n'
        '$footer';

    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Event details copied to clipboard!',
                  mr: 'कार्यक्रमाचा तपशील क्लिपबोर्डवर कॉपी केला!',
                  hi: 'कार्यक्रम का विवरण क्लिपबोर्ड पर कॉपी किया गया!',
                ),
              ),
            ),
          );
        }
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: text));
    }
  }

  Future<void> _handleCall(String mobile) async {
    final cleanMobile = AppTranslations.normalizeAsciiDigits(mobile);
    final uri = Uri.parse('tel:$cleanMobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _handleWhatsApp(String mobile, String name) async {
    final lang = ref.read(appLanguageProvider);
    final cleanMobile = AppTranslations.normalizeAsciiDigits(mobile);
    final rTitle = _rawTitle(lang);
    final rLoc = _rawLoc(lang);
    final titleText =
        DynamicTranslationService.getCachedTranslation(rTitle, lang) ?? rTitle;
    final locText =
        DynamicTranslationService.getCachedTranslation(rLoc, lang) ?? rLoc;
    final voterName =
        DynamicTranslationService.getCachedTranslation(name, lang, isName: true) ??
            name;
    final dateStr = _event.formattedDateFor(lang);
    final timeStr = AppTranslations.formatDigits(_event.eventTime, lang);

    final rawMsg = lang == 'mr'
        ? 'नमस्कार $voterName,\n\nआपणास *$titleText* कार्यक्रमास सस्नेह निमंत्रित करण्यात येत आहे.\nतारीख: $dateStr, वेळ: $timeStr.\nठिकाण: $locText.\nआपण उपस्थित राहणार का?\n\n— नगरसेवक अमित चौगुले कार्यालय'
        : (lang == 'hi'
            ? 'नमस्ते $voterName,\n\nआपको *$titleText* कार्यक्रम में सादर आमंत्रित किया जाता है।\nदिनांक: $dateStr, समय: $timeStr.\nस्थान: $locText.\nक्या आप उपस्थित रहेंगे?\n\n— नगरसेवक अमित चौगुले कार्यालय'
            : 'Hello $voterName,\n\nYou are cordially invited to the *$titleText* program.\nDate: $dateStr, Time: $timeStr.\nVenue: $locText.\nWill you be attending?\n\n— Nagarsevak Amit Chougale Office');
    final msg = Uri.encodeComponent(rawMsg);
    final uri = Uri.parse('https://wa.me/91$cleanMobile?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<EventRsvpModel> get _filteredRsvps {
    final q = AppTranslations.normalizeAsciiDigits(_rsvpSearchCtrl.text.trim())
        .toLowerCase();
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
    final lang = ref.watch(appLanguageProvider);
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
            tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'वापस'),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _event.type.title(lang),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AppPdfButton.icon(
                  tooltip: AppTranslations.getDownloadReport(lang),
                  onPressed: () => EventReportGenerator.generateAndPrintReport(
                    events: [_event],
                    lang: lang,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Share',
                mr: 'शेअर करा',
                hi: 'साझा करें',
              ),
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
                _buildHeroCard(lang),

                const SizedBox(height: 16),

                // 3-way RSVP Response Strip
                _buildRsvpStatsRow(lang),

                const SizedBox(height: 16),

                // Description Card
                _buildDescriptionCard(lang),

                const SizedBox(height: 16),

                // RSVP Attendees Header & Search
                _buildAttendeesSection(filteredRsvps, lang),

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
                  label: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Send Invites',
                      mr: 'निमंत्रण पाठवा',
                      hi: 'निमंत्रण भेजें',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildHeroCard(String lang) {
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
                      _event.monthShortFor(lang),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _event.type.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _event.dayNumFor(lang),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
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
                                _event.type.title(lang),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _event.type.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _event.isCompleted
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _event.isCompleted
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
                              color: _event.isCompleted
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppTranslatedText(
                      _rawTitle(lang),
                      targetLanguage: lang,
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
              AppTranslatedText(
                AppTranslations.formatDigits(_event.eventTime, lang),
                targetLanguage: lang,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: AppTranslatedText(
                  _rawLoc(lang),
                  targetLanguage: lang,
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
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppTranslations.pick(lang, en: "Area", mr: "परिसर", hi: "क्षेत्र")}: ',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    Flexible(
                      child: AppTranslatedText(
                        AppTranslations.getAreaName(_event.area, lang),
                        targetLanguage: lang,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.group_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: AppTranslatedText(
                  '${AppTranslations.pick(lang, en: "Target Audience", mr: "लक्षित वर्ग", hi: "लक्षित वर्ग")}: ${AppTranslations.translateDirect(_event.targetAudience, lang: lang)}',
                  targetLanguage: lang,
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

  Widget _buildRsvpStatsRow(String lang) {
    return Row(
      children: [
        _buildStatBox(
          RsvpStatus.going.title(lang),
          AppTranslations.formatDigits(_event.goingCount, lang),
          '${AppTranslations.formatDigits(_event.goingPercentage.toStringAsFixed(0), lang)}% ${AppTranslations.pick(lang, en: "response", mr: "प्रतिसाद", hi: "प्रतिक्रिया")}',
          const Color(0xFF16A34A),
          const Color(0xFFDCFCE7),
          Icons.check_circle_rounded,
        ),
        const SizedBox(width: 8),
        _buildStatBox(
          RsvpStatus.maybe.title(lang),
          AppTranslations.formatDigits(_event.maybeCount, lang),
          AppTranslations.pick(
            lang,
            en: 'Expected Attendance',
            mr: 'संभाव्य उपस्थिती',
            hi: 'संभावित उपस्थिति',
          ),
          const Color(0xFFD97706),
          const Color(0xFFFEF3C7),
          Icons.help_rounded,
        ),
        const SizedBox(width: 8),
        _buildStatBox(
          RsvpStatus.notGoing.title(lang),
          AppTranslations.formatDigits(_event.notGoingCount, lang),
          AppTranslations.pick(
            lang,
            en: 'Absent',
            mr: 'अनुपस्थित',
            hi: 'अनुपस्थित',
          ),
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

  Widget _buildDescriptionCard(String lang) {
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
            children: [
              const Icon(Icons.notes_rounded, size: 18, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'About Event',
                  mr: 'कार्यक्रमाविषयी',
                  hi: 'कार्यक्रम के बारे में',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTranslatedText(
            _event.description,
            targetLanguage: lang,
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

  Widget _buildAttendeesSection(List<EventRsvpModel> filteredRsvps, String lang) {
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
                '${AppTranslations.pick(lang, en: "RSVP List", mr: "उपस्थिती यादी (RSVP)", hi: "उपस्थिति सूची (RSVP)")} (${AppTranslations.formatDigits(_event.totalRsvps, lang)})',
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
              hintText: AppTranslations.pick(
                lang,
                en: 'Search by name or mobile...',
                mr: 'नाव किंवा मोबाइल क्रमांकाने शोधा...',
                hi: 'नाम या मोबाइल नंबर से खोजें...',
              ),
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
              suffixIcon: _rsvpSearchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () => setState(() {
                        _rsvpSearchCtrl.clear();
                        _rsvpPage = 1;
                      }),
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
            onChanged: (_) => setState(() => _rsvpPage = 1),
          ),

          const SizedBox(height: 10),

          // Filter status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip(
                  '${AppTranslations.getAll(lang)} (${AppTranslations.formatDigits(_event.totalRsvps, lang)})',
                  'all',
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  '${RsvpStatus.going.title(lang)} (${AppTranslations.formatDigits(_event.goingCount, lang)})',
                  'Going',
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  '${RsvpStatus.maybe.title(lang)} (${AppTranslations.formatDigits(_event.maybeCount, lang)})',
                  'Maybe',
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  '${RsvpStatus.notGoing.title(lang)} (${AppTranslations.formatDigits(_event.notGoingCount, lang)})',
                  'Not Going',
                ),
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
                      ? AppTranslations.pick(
                          lang,
                          en: 'No RSVPs received yet.\nUse the button below to send invitations.',
                          mr: 'अद्याप कोणताही प्रतिसाद आलेला नाही.\nनिमंत्रण पाठवण्यासाठी खालील बटण वापरा.',
                          hi: 'अभी तक कोई प्रतिक्रिया प्राप्त नहीं हुई है।\nनिमंत्रण भेजने के लिए नीचे दिए बटन का उपयोग करें।',
                        )
                      : AppTranslations.pick(
                          lang,
                          en: 'No matching responses found.',
                          mr: 'जुळणारे प्रतिसाद आढळले नाहीत.',
                          hi: 'कोई मेल खाने वाली प्रतिक्रिया नहीं मिली।',
                        ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            )
          else ...[
            Builder(
              builder: (context) {
                final totalRsvpPages = (filteredRsvps.length / _rsvpPageSize).ceil() < 1 ? 1 : (filteredRsvps.length / _rsvpPageSize).ceil();
                final startIndex = (_rsvpPage - 1) * _rsvpPageSize;
                final pagedRsvps = startIndex >= filteredRsvps.length
                    ? <EventRsvpModel>[]
                    : filteredRsvps.sublist(startIndex, min(startIndex + _rsvpPageSize, filteredRsvps.length));

                return Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pagedRsvps.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, idx) {
                        final rsvp = pagedRsvps[idx];
                        final rsvpName =
                            lang == 'mr' && rsvp.voterNameMr.isNotEmpty
                                ? rsvp.voterNameMr
                                : rsvp.voterName;
                        final srcLabel =
                            AppTranslations.translateDirect(rsvp.responseSource, lang: lang);
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
                                    AppTranslatedText(
                                      rsvpName,
                                      isName: true,
                                      targetLanguage: lang,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: AppTranslatedText(
                                            rsvp.address,
                                            targetLanguage: lang,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          ' • $srcLabel',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Call & WhatsApp Action Buttons
                              IconButton(
                                icon: const Icon(Icons.call_outlined, size: 18, color: Color(0xFF0284C7)),
                                onPressed: () => _handleCall(rsvp.mobile),
                                tooltip: AppTranslations.pick(
                                  lang,
                                  en: 'Call',
                                  mr: 'कॉल करा',
                                  hi: 'कॉल करें',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF16A34A)),
                                onPressed: () => _handleWhatsApp(rsvp.mobile, rsvpName),
                                tooltip: AppTranslations.pick(
                                  lang,
                                  en: 'WhatsApp Message',
                                  mr: 'WhatsApp संदेश',
                                  hi: 'WhatsApp संदेश',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    AppInlinePagination(
                      currentPage: _rsvpPage,
                      totalPages: totalRsvpPages,
                      totalItems: filteredRsvps.length,
                      pageSize: _rsvpPageSize,
                      label: AppTranslations.pick(
                        lang,
                        en: 'RSVPs',
                        mr: 'प्रतिसाद',
                        hi: 'प्रतिक्रियाएं',
                      ),
                      onPageChanged: (page) => setState(() => _rsvpPage = page),
                    ),
                  ],
                );
              },
            ),
          ],
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
      onSelected: (_) => setState(() {
        _rsvpStatusFilter = value;
        _rsvpPage = 1;
      }),
    );
  }
}

