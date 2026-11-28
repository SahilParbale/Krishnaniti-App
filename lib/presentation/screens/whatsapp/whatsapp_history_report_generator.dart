import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class WhatsAppHistoryReportGenerator {
  WhatsAppHistoryReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<WhatsAppBroadcastModel> broadcasts,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDateTime(now, activeLang);

    final totalBroadcasts = broadcasts.length;
    final totalRecipients = broadcasts.fold<int>(0, (sum, b) => sum + b.recipients);
    final totalDelivered = broadcasts.fold<int>(0, (sum, b) => sum + b.deliveredCount);
    final totalFailed = broadcasts.fold<int>(0, (sum, b) => sum + b.failedCount);

    final textItems = <String?>[];
    final nameItems = <String?>[];
    for (final b in broadcasts) {
      final trimmedTitle = b.title.trim();
      if (trimmedTitle.startsWith('WhatsApp Call - ')) {
        nameItems.add(trimmedTitle.substring('WhatsApp Call - '.length).trim());
      } else {
        textItems.add(trimmedTitle);
      }
      textItems.add(b.message);
      textItems.add(b.status);
    }

    final caches = await Future.wait([
      PdfTranslationHelper.batchText(textItems, activeLang),
      PdfTranslationHelper.batchNames(nameItems, activeLang),
    ]);
    final textCache = caches[0];
    final nameCache = caches[1];

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'WhatsApp Broadcast History',
      mr: 'व्हॉट्सॲप प्रसारण इतिहास',
      hi: 'व्हाट्सएप प्रसारण इतिहास',
    );
    final continuationTitle = AppTranslations.pick(
      activeLang,
      en: 'WhatsApp Broadcast Campaigns',
      mr: 'व्हॉट्सॲप प्रसारण मोहिमा',
      hi: 'व्हाट्सएप प्रसारण अभियान',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Official WhatsApp Public Outreach & Campaign Dispatches',
      mr: 'अधिकृत व्हॉट्सॲप जनसंपर्क व मोहीम पाठवणी नोंदवही',
      hi: 'आधिकारिक व्हाट्सएप जनसंपर्क एवं अभियान प्रेषण',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: continuationTitle,
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
              dateFormatted: nowStr,
              totalCount: totalBroadcasts,
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
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Broadcasts',
                      mr: 'एकूण प्रसारण',
                      hi: 'कुल प्रसारण',
                    ),
                    PdfTranslationHelper.formatNumber(totalBroadcasts, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Targeted',
                      mr: 'लक्ष्यित',
                      hi: 'लक्षित',
                    ),
                    PdfTranslationHelper.formatNumber(totalRecipients, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Delivered',
                      mr: 'वितरित',
                      hi: 'वितरित',
                    ),
                    PdfTranslationHelper.formatNumber(totalDelivered, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Failed',
                      mr: 'अयशस्वी',
                      hi: 'विफल',
                    ),
                    PdfTranslationHelper.formatNumber(totalFailed, activeLang),
                    highlightColor: PdfColors.red700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (broadcasts.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No WhatsApp broadcast dispatches found.',
                    mr: 'कोणतीही व्हॉट्सॲप प्रसारण नोंद आढळली नाही.',
                    hi: 'कोई व्हाट्सएप प्रसारण रिकॉर्ड नहीं मिला।',
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
                  2: pw.FlexColumnWidth(3.4),
                  3: pw.FlexColumnWidth(1.2),
                  4: pw.FlexColumnWidth(1.2),
                  5: pw.FlexColumnWidth(1.2),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Dispatched Time',
                    mr: 'पाठवण्याची वेळ',
                    hi: 'प्रेषण समय',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Campaign & Message',
                    mr: 'मोहीम व संदेश',
                    hi: 'अभियान और संदेश',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Targeted',
                    mr: 'लक्ष्यित',
                    hi: 'लक्षित',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Delivered',
                    mr: 'वितरित',
                    hi: 'वितरित',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Status',
                    mr: 'स्थिती',
                    hi: 'स्थिति',
                  ),
                ],
                data: broadcasts.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final b = entry.value;

                  final resolvedTitle = _resolveBroadcastTitle(
                    b.title,
                    activeLang,
                    textCache,
                    nameCache,
                  );
                  final resolvedMsg = PdfTranslationHelper.resolve(
                    textCache,
                    b.message,
                    activeLang,
                  );

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    PdfTranslationHelper.formatDateTime(b.sentAt, activeLang),
                    '$resolvedTitle\n$resolvedMsg',
                    PdfTranslationHelper.formatNumber(b.recipients, activeLang),
                    PdfTranslationHelper.formatNumber(b.deliveredCount, activeLang),
                    _resolveStatus(b.status, activeLang, textCache),
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'WhatsApp_Broadcast_History_${DateFormat('yyyyMMdd').format(now)}';
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

  static String _resolveBroadcastTitle(
    String rawTitle,
    String lang,
    Map<String, String> textCache,
    Map<String, String> nameCache,
  ) {
    final trimmed = rawTitle.trim();
    if (trimmed.startsWith('WhatsApp Call - ')) {
      final rawName = trimmed.substring('WhatsApp Call - '.length).trim();
      final prefix = AppTranslations.pick(
        lang,
        en: 'WhatsApp Call',
        mr: 'व्हॉट्सॲप कॉल',
        hi: 'व्हाट्सएप कॉल',
      );
      final resolvedName = PdfTranslationHelper.resolveName(nameCache, rawName, lang);
      return '$prefix - $resolvedName';
    }
    return PdfTranslationHelper.resolve(textCache, trimmed, lang);
  }

  static String _resolveStatus(
    String status,
    String lang,
    Map<String, String> textCache,
  ) {
    final trimmed = status.trim();
    if (trimmed.isEmpty) return '-';
    switch (trimmed.toLowerCase()) {
      case 'completed':
        return AppTranslations.pick(lang, en: 'Completed', mr: 'पूर्ण', hi: 'पूर्ण');
      case 'sending':
        return AppTranslations.pick(lang, en: 'Sending', mr: 'पाठवत आहे', hi: 'भेज रहा है');
      case 'queued':
        return AppTranslations.pick(lang, en: 'Queued', mr: 'रांगेत', hi: 'कतार में');
      case 'sent':
        return AppTranslations.pick(lang, en: 'Sent', mr: 'पाठवले', hi: 'भेजा गया');
      case 'delivered':
        return AppTranslations.pick(lang, en: 'Delivered', mr: 'वितरित', hi: 'वितरित');
      case 'failed':
        return AppTranslations.pick(lang, en: 'Failed', mr: 'अयशस्वी', hi: 'विफल');
      case 'cancelled':
        return AppTranslations.pick(lang, en: 'Cancelled', mr: 'रद्द', hi: 'रद्द');
      default:
        final translated = AppTranslations.getStatus(trimmed, lang);
        if (AppTranslations.normalizeAsciiDigits(translated) ==
            AppTranslations.normalizeAsciiDigits(trimmed)) {
          return PdfTranslationHelper.resolve(textCache, trimmed, lang);
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
