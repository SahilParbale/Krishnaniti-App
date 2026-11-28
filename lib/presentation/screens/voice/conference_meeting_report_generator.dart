import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';
import 'conference_room_screen.dart';

class ConferenceMeetingReportGenerator {
  ConferenceMeetingReportGenerator._();

  static Future<void> generateAndPrintMeetingReport({
    BuildContext? context,
    required List<ConferenceMeetingModel> meetings,
    String? statusFilter,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);

    final total = meetings.length;
    final scheduled = meetings.where((m) => m.status.toLowerCase() == 'scheduled').length;
    final active = meetings.where((m) => m.status.toLowerCase() == 'active').length;
    final ended = meetings.where((m) => m.status.toLowerCase() == 'ended').length;

    final textItems = <String?>[
      statusFilter,
    ];
    for (final m in meetings) {
      textItems.add(m.title);
      textItems.add(m.notes);
      textItems.add(m.status);
    }
    final textCache = await PdfTranslationHelper.batchText(textItems, activeLang);

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Virtual Meetings Report',
      mr: 'ऑनलाईन सभा अहवाल',
      hi: 'वर्चुअल मीटिंग रिपोर्ट',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Online Consultations & Deliberation Records',
      mr: 'ऑनलाईन सल्लामसलत व चर्चासत्र नोंदी',
      hi: 'ऑनलाइन परामर्श और विचार-विमर्श रिकॉर्ड',
    );

    final hasStatusFilter = statusFilter != null &&
        statusFilter.trim().isNotEmpty &&
        statusFilter.trim().toLowerCase() != 'all';
    final List<String>? metaLines = hasStatusFilter
        ? [
            '${AppTranslations.pick(activeLang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:')} $formattedDate',
            '${AppTranslations.pick(activeLang, en: 'Found:', mr: 'एकूण:', hi: 'कुल:')} ${PdfTranslationHelper.formatNumber(total, activeLang)}',
            '${AppTranslations.pick(activeLang, en: 'Status:', mr: 'स्थिती:', hi: 'स्थिति:')} ${_resolveMeetingStatus(statusFilter, activeLang, textCache)}',
          ]
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: reportTitle,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(
          context,
          lang: activeLang,
        ),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: reportTitle,
              subtitle: reportSubtitle,
              dateFormatted: formattedDate,
              totalCount: total,
              metaLines: metaLines,
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Statistics Row matching web
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
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Meetings',
                      mr: 'एकूण सभा',
                      hi: 'कुल बैठकें',
                    ),
                    PdfTranslationHelper.formatNumber(total, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Scheduled',
                      mr: 'नियोजित',
                      hi: 'निर्धारित',
                    ),
                    PdfTranslationHelper.formatNumber(scheduled, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Active',
                      mr: 'सक्रिय',
                      hi: 'सक्रिय',
                    ),
                    PdfTranslationHelper.formatNumber(active, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Ended',
                      mr: 'संपन्न',
                      hi: 'समाप्त',
                    ),
                    PdfTranslationHelper.formatNumber(ended, activeLang),
                    highlightColor: WebReportTheme.slate600,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (meetings.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No conference meetings found.',
                    mr: 'कोणत्याही कॉन्फरन्स सभा आढळल्या नाहीत.',
                    hi: 'कोई कॉन्फ्रेंस मीटिंग नहीं मिली।',
                  ),
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerCount: 1,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(2.0),
                  2: pw.FlexColumnWidth(3.0),
                  3: pw.FlexColumnWidth(1.2),
                  4: pw.FlexColumnWidth(1.6),
                  5: pw.FlexColumnWidth(2.0),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Scheduled Date & Time',
                    mr: 'नियोजित दिनांक व वेळ',
                    hi: 'निर्धारित दिनांक और समय',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Title / Purpose',
                    mr: 'शीर्षक / उद्देश',
                    hi: 'शीर्षक / उद्देश्य',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Status',
                    mr: 'स्थिती',
                    hi: 'स्थिति',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Invited',
                    mr: 'निमंत्रित',
                    hi: 'आमंत्रित',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Conference Link',
                    mr: 'मीटिंग लिंक',
                    hi: 'कॉन्फ्रेंस लिंक',
                  ),
                ],
                data: List.generate(meetings.length, (index) {
                  final m = meetings[index];
                  final dateStr = PdfTranslationHelper.formatDateTime(m.scheduledAt, activeLang);
                  final meetingTitle = PdfTranslationHelper.resolve(
                    textCache,
                    m.title,
                    activeLang,
                  );
                  final notesPart = (m.notes != null && m.notes!.trim().isNotEmpty)
                      ? '\n${PdfTranslationHelper.resolve(textCache, m.notes, activeLang)}'
                      : '';
                  final meetLinkStr = m.meetLink.trim().isNotEmpty ? m.meetLink.trim() : '-';

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    dateStr,
                    '$meetingTitle$notesPart',
                    _resolveMeetingStatus(m.status, activeLang, textCache),
                    PdfTranslationHelper.formatNumber(m.invitedCount, activeLang),
                    meetLinkStr,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Conference_Meetings_Report_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: reportTitle,
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

  static String _resolveMeetingStatus(
    String status,
    String lang,
    Map<String, String> textCache,
  ) {
    final trimmed = status.trim();
    if (trimmed.isEmpty) return '-';
    switch (trimmed.toLowerCase()) {
      case 'scheduled':
        return AppTranslations.pick(lang, en: 'SCHEDULED', mr: 'नियोजित', hi: 'निर्धारित');
      case 'active':
        return AppTranslations.pick(lang, en: 'ACTIVE', mr: 'सक्रिय', hi: 'सक्रिय');
      case 'ended':
        return AppTranslations.pick(lang, en: 'ENDED', mr: 'संपन्न', hi: 'समाप्त');
      case 'completed':
        return AppTranslations.pick(lang, en: 'COMPLETED', mr: 'पूर्ण', hi: 'पूर्ण');
      case 'cancelled':
        return AppTranslations.pick(lang, en: 'CANCELLED', mr: 'रद्द', hi: 'रद्द');
      default:
        final translated = AppTranslations.getStatus(trimmed, lang);
        if (AppTranslations.normalizeAsciiDigits(translated) ==
            AppTranslations.normalizeAsciiDigits(trimmed)) {
          return PdfTranslationHelper.resolve(textCache, trimmed, lang).toUpperCase();
        }
        return AppTranslations.formatDigits(translated, lang);
    }
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
