import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/event_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class EventReportGenerator {
  EventReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<EventModel> events,
    String? areaFilter,
    String? typeFilter,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDate(DateTime.now(), activeLang);

    final toTranslate = <String>[];
    for (final e in events) {
      if (!_hasDirectMarathi(e.titleMr, activeLang)) {
        final rawTitle = e.title.trim().isNotEmpty ? e.title : e.titleMr;
        if (rawTitle.trim().isNotEmpty) toTranslate.add(rawTitle);
      }
      if (!_hasDirectMarathi(e.locationMr, activeLang)) {
        final rawLoc = e.location.trim().isNotEmpty ? e.location : e.locationMr;
        if (rawLoc.trim().isNotEmpty) toTranslate.add(rawLoc);
      }
      if (e.eventTime.trim().isNotEmpty) toTranslate.add(e.eventTime);
      if (e.area.trim().isNotEmpty) toTranslate.add(e.area);
      if (e.targetAudience.trim().isNotEmpty &&
          _knownAudience(e.targetAudience, activeLang) == null) {
        toTranslate.add(e.targetAudience);
      }
    }
    if (areaFilter != null &&
        areaFilter.trim().isNotEmpty &&
        areaFilter.trim().toLowerCase() != 'all') {
      toTranslate.add(areaFilter);
    }
    if (typeFilter != null &&
        typeFilter.trim().isNotEmpty &&
        typeFilter.trim().toLowerCase() != 'all') {
      toTranslate.add(typeFilter);
    }

    final textCache = await PdfTranslationHelper.batchText(toTranslate, activeLang);

    final totalEvents = events.length;
    final upcomingEvents = events.where((e) => e.isUpcoming).length;
    final completedEvents = events.where((e) => e.isCompleted).length;
    final totalRsvps = events.fold<int>(0, (sum, e) => sum + e.totalRsvps);

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Events & Community Programs',
      mr: 'कार्यक्रम व सामुदायिक उपक्रम',
      hi: 'कार्यक्रम एवं सामुदायिक गतिविधियां',
    );
    final contTitle = AppTranslations.pick(
      activeLang,
      en: 'Events & Programs',
      mr: 'कार्यक्रम व उपक्रम',
      hi: 'कार्यक्रम एवं गतिविधियां',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Public Events & Community Engagement Directory',
      mr: 'सार्वजनिक कार्यक्रम व जनसंपर्क उपक्रम नोंदवही',
      hi: 'सार्वजनिक कार्यक्रम एवं जनसंपर्क निर्देशिका',
    );
    final foundLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Events',
      mr: 'एकूण कार्यक्रम',
      hi: 'कुल कार्यक्रम',
    );

    final metaLines = <String>[];
    final hasAreaFilter = areaFilter != null &&
        areaFilter.trim().isNotEmpty &&
        areaFilter.trim().toLowerCase() != 'all';
    final hasTypeFilter = typeFilter != null &&
        typeFilter.trim().isNotEmpty &&
        typeFilter.trim().toLowerCase() != 'all';
    if (hasAreaFilter || hasTypeFilter) {
      final datePrefix = AppTranslations.pick(activeLang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:');
      metaLines.add('$datePrefix $nowStr');
      if (hasAreaFilter) {
        final areaPrefix = AppTranslations.pick(activeLang, en: 'Area:', mr: 'परिसर:', hi: 'क्षेत्र:');
        metaLines.add('$areaPrefix ${_resolveArea(areaFilter, textCache, activeLang)}');
      }
      if (hasTypeFilter) {
        final typePrefix = AppTranslations.pick(activeLang, en: 'Type:', mr: 'प्रकार:', hi: 'प्रकार:');
        metaLines.add('$typePrefix ${_resolveTypeFilter(typeFilter, textCache, activeLang)}');
      }
      metaLines.add('$foundLabel: ${PdfTranslationHelper.formatNumber(totalEvents, activeLang)}');
    }

    final typeLabelPrefix = AppTranslations.pick(
      activeLang,
      en: 'Type:',
      mr: 'प्रकार:',
      hi: 'प्रकार:',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: contTitle,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) =>
            WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: reportTitle,
              subtitle: reportSubtitle,
              dateFormatted: metaLines.isEmpty ? nowStr : null,
              totalCount: metaLines.isEmpty ? totalEvents : null,
              foundLabel: foundLabel,
              metaLines: metaLines.isNotEmpty ? metaLines : null,
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary metrics
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Total Events', mr: 'एकूण कार्यक्रम', hi: 'कुल कार्यक्रम'),
                    PdfTranslationHelper.formatNumber(totalEvents, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Upcoming', mr: 'आगामी', hi: 'आगामी'),
                    PdfTranslationHelper.formatNumber(upcomingEvents, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Completed', mr: 'पूर्ण झालेले', hi: 'पूर्ण'),
                    PdfTranslationHelper.formatNumber(completedEvents, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Total RSVPs', mr: 'एकूण नोंदणी (RSVP)', hi: 'कुल पंजीकरण (RSVP)'),
                    PdfTranslationHelper.formatNumber(totalRsvps, activeLang),
                    highlightColor: WebReportTheme.slate700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (events.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No public events or programs found.',
                    mr: 'कोणतेही सार्वजनिक कार्यक्रम किंवा उपक्रम आढळले नाहीत.',
                    hi: 'कोई सार्वजनिक कार्यक्रम या गतिविधि नहीं मिली।',
                  ),
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerCount: 1,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(2.0),
                  2: pw.FlexColumnWidth(3.2),
                  3: pw.FlexColumnWidth(2.6),
                  4: pw.FlexColumnWidth(1.8),
                },
                headers: [
                  '#',
                  AppTranslations.getReportColumn('date_time', activeLang),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Event Title & Type',
                    mr: 'कार्यक्रमाचे नाव व प्रकार',
                    hi: 'कार्यक्रम शीर्षक व प्रकार',
                  ),
                  AppTranslations.getReportColumn('location_area', activeLang),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Audience',
                    mr: 'लक्ष्य गट / नागरिक',
                    hi: 'लक्षित दर्शक',
                  ),
                ],
                data: events.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final event = entry.value;

                  final formattedEventDate = PdfTranslationHelper.formatDate(
                    event.eventDate,
                    activeLang,
                    pattern: 'd MMM yyyy',
                  );
                  final timeResolved = event.eventTime.trim().isNotEmpty
                      ? '\n${PdfTranslationHelper.resolve(textCache, event.eventTime, activeLang)}'
                      : '';

                  final titleText = _hasDirectMarathi(event.titleMr, activeLang)
                      ? AppTranslations.formatDigits(event.titleMr.trim(), activeLang)
                      : PdfTranslationHelper.resolve(
                          textCache,
                          event.title.trim().isNotEmpty ? event.title : event.titleMr,
                          activeLang,
                        );
                  final typeLabel = _eventTypeLabel(event.type, activeLang);

                  final areaText = event.area.trim().isNotEmpty
                      ? _resolveArea(event.area, textCache, activeLang)
                      : '';
                  final locText = _hasDirectMarathi(event.locationMr, activeLang)
                      ? AppTranslations.formatDigits(event.locationMr.trim(), activeLang)
                      : (event.location.trim().isNotEmpty || event.locationMr.trim().isNotEmpty)
                          ? PdfTranslationHelper.resolve(
                              textCache,
                              event.location.trim().isNotEmpty ? event.location : event.locationMr,
                              activeLang,
                            )
                          : '';

                  final areaLocJoined = [areaText, locText]
                      .where((s) => s.isNotEmpty && s != '-')
                      .join('\n');

                  final audienceStr = _resolveAudience(
                    event.targetAudience,
                    textCache,
                    activeLang,
                  );

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    '$formattedEventDate$timeResolved',
                    '$titleText\n$typeLabelPrefix $typeLabel',
                    areaLocJoined.isNotEmpty ? areaLocJoined : '-',
                    audienceStr,
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Events_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: contTitle,
        subtitle: reportSubtitle,
        fileName: fileName,
        onBuildPdf: () async => pdf.save(),
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '$fileName.pdf',
      );
    }
  }

  static bool _hasDirectMarathi(String? text, String lang) {
    if (lang != 'mr' || text == null || text.trim().isEmpty) return false;
    return DynamicTranslationService.containsDevanagari(text.trim());
  }

  static String _eventTypeLabel(EventType type, String lang) {
    switch (type) {
      case EventType.publicMeeting:
        return AppTranslations.pick(lang, en: 'Public Meeting', mr: 'सार्वजनिक सभा', hi: 'जनसभा');
      case EventType.inauguration:
        return AppTranslations.pick(lang, en: 'Inauguration', mr: 'उद्घाटन', hi: 'उद्घाटन');
      case EventType.rally:
        return AppTranslations.pick(lang, en: 'Rally', mr: 'रॅली / मोर्चा', hi: 'रैली / मार्च');
      case EventType.healthCamp:
        return AppTranslations.pick(lang, en: 'Health Camp', mr: 'आरोग्य शिबिर', hi: 'स्वास्थ्य शिविर');
      case EventType.doorToDoor:
        return AppTranslations.pick(lang, en: 'Door-to-Door', mr: 'गाठीभेटी (डोअर-टू-डोअर)', hi: 'डोर-टू-डोर संपर्क');
      case EventType.cultural:
        return AppTranslations.pick(lang, en: 'Cultural', mr: 'सांस्कृतिक महोत्सव', hi: 'सांस्कृतिक कार्यक्रम');
      case EventType.other:
        return AppTranslations.pick(lang, en: 'Other', mr: 'इतर', hi: 'अन्य');
    }
  }

  static String _resolveTypeFilter(
    String raw,
    Map<String, String> cache,
    String lang,
  ) {
    final lower = raw.trim().toLowerCase();
    for (final t in EventType.values) {
      if (t.id.toLowerCase() == lower || t.name.toLowerCase() == lower) {
        return _eventTypeLabel(t, lang);
      }
    }
    return PdfTranslationHelper.resolve(cache, raw, lang);
  }

  static String _resolveArea(
    String raw,
    Map<String, String> cache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final dictArea = AppTranslations.getAreaName(trimmed, lang);
    if (AppTranslations.normalizeAsciiDigits(dictArea) !=
        AppTranslations.normalizeAsciiDigits(trimmed)) {
      return dictArea;
    }
    return PdfTranslationHelper.resolve(cache, trimmed, lang);
  }

  static String? _knownAudience(String raw, String lang) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty || lower == 'all' || lower == 'all citizens') {
      return AppTranslations.pick(lang, en: 'All Citizens', mr: 'सर्व नागरिक', hi: 'सभी नागरिक');
    }
    if (lower == 'senior citizens' || lower == 'senior citizen') {
      return AppTranslations.pick(lang, en: 'Senior Citizens', mr: 'ज्येष्ठ नागरिक', hi: 'वरिष्ठ नागरिक');
    }
    if (lower == 'women' || lower == 'ladies') {
      return AppTranslations.pick(lang, en: 'Women', mr: 'महिला', hi: 'महिलाएं');
    }
    if (lower == 'youth') {
      return AppTranslations.pick(lang, en: 'Youth', mr: 'युवा', hi: 'युवा');
    }
    if (lower == 'students' || lower == 'student') {
      return AppTranslations.pick(lang, en: 'Students', mr: 'विद्यार्थी', hi: 'छात्र');
    }
    if (lower == 'farmers' || lower == 'farmer') {
      return AppTranslations.pick(lang, en: 'Farmers', mr: 'शेतकरी', hi: 'किसान');
    }
    return null;
  }

  static String _resolveAudience(
    String raw,
    Map<String, String> cache,
    String lang,
  ) {
    final known = _knownAudience(raw, lang);
    if (known != null) return known;
    return PdfTranslationHelper.resolve(cache, raw, lang);
  }

  static pw.Widget _buildSummaryItem(String label, String value, {PdfColor? highlightColor}) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: highlightColor ?? WebReportTheme.slate800,
            ),
          ),
        ],
      ),
    );
  }
}
