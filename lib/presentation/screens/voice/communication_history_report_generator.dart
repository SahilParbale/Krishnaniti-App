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

class CommunicationHistoryReportGenerator {
  CommunicationHistoryReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<WhatsAppBroadcastModel> logs,
    String title = 'Public Communication History',
    String subtitle = 'Report of all broadcasted campaigns and voice logs',
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);

    final total = logs.length;
    final totalRecipients = logs.fold<int>(0, (sum, l) => sum + l.recipients);
    final totalDelivered = logs.fold<int>(0, (sum, l) => sum + l.deliveredCount);
    final totalFailed = logs.fold<int>(0, (sum, l) => sum + l.failedCount);

    final textItems = <String?>[
      if (!_isKnownTitle(title)) title,
      if (!_isKnownSubtitle(subtitle)) subtitle,
    ];
    final nameItems = <String?>[];
    for (final log in logs) {
      final trimmedTitle = log.title.trim();
      if (trimmedTitle.startsWith('Manual Voice Call - ')) {
        nameItems.add(trimmedTitle.substring('Manual Voice Call - '.length).trim());
      } else if (trimmedTitle.startsWith('WhatsApp Call - ')) {
        nameItems.add(trimmedTitle.substring('WhatsApp Call - '.length).trim());
      } else {
        textItems.add(trimmedTitle);
      }
      textItems.add(log.message);
      textItems.add(log.channel);
      textItems.add(log.status);
    }

    final caches = await Future.wait([
      PdfTranslationHelper.batchText(textItems, activeLang),
      PdfTranslationHelper.batchNames(nameItems, activeLang),
    ]);
    final textCache = caches[0];
    final nameCache = caches[1];

    final resolvedTitle = _resolveHeaderTitle(title, activeLang, textCache);
    final resolvedSubtitle = _resolveHeaderSubtitle(subtitle, activeLang, textCache);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: resolvedTitle,
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
              title: resolvedTitle,
              subtitle: resolvedSubtitle,
              dateFormatted: formattedDate,
              totalCount: total,
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary row
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
                      en: 'Total Campaigns',
                      mr: 'एकूण मोहिमा',
                      hi: 'कुल अभियान',
                    ),
                    PdfTranslationHelper.formatNumber(total, activeLang),
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

            if (logs.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No communication history records found.',
                    mr: 'कोणत्याही जनसंवाद नोंदी आढळल्या नाहीत.',
                    hi: 'कोई जनसंचार इतिहास रिकॉर्ड नहीं मिला।',
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
                  6: pw.FlexColumnWidth(1.2),
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
                    en: 'Channel',
                    mr: 'माध्यम',
                    hi: 'माध्यम',
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
                data: logs.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final log = entry.value;
                  final logTitle = _resolveLogTitle(
                    log.title,
                    activeLang,
                    textCache,
                    nameCache,
                  );
                  final logMsg = PdfTranslationHelper.resolve(
                    textCache,
                    log.message,
                    activeLang,
                  );

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    PdfTranslationHelper.formatDateTime(log.sentAt, activeLang),
                    '$logTitle\n$logMsg',
                    _resolveChannel(log.channel, activeLang, textCache),
                    PdfTranslationHelper.formatNumber(log.recipients, activeLang),
                    PdfTranslationHelper.formatNumber(log.deliveredCount, activeLang),
                    _resolveStatus(log.status, activeLang, textCache),
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Communication_History_Report_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: resolvedTitle,
        subtitle: resolvedSubtitle,
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

  static bool _isKnownTitle(String title) {
    final t = title.trim();
    return t == 'Public Communication History' ||
        t == 'AI Voice Call History & Citizen Feedback' ||
        t == 'Public Voice Call History & Broadcast Report';
  }

  static bool _isKnownSubtitle(String subtitle) {
    final s = subtitle.trim();
    return s == 'Report of all broadcasted campaigns and voice logs' ||
        s == 'Automated AI Voice Call Broadcast Register - Prabhag 12';
  }

  static String _resolveHeaderTitle(
    String title,
    String lang,
    Map<String, String> textCache,
  ) {
    switch (title.trim()) {
      case 'Public Communication History':
        return AppTranslations.pick(
          lang,
          en: 'Public Communication History',
          mr: 'जनसंवाद प्रसारण इतिहास',
          hi: 'जनसंचार प्रसारण इतिहास',
        );
      case 'AI Voice Call History & Citizen Feedback':
        return AppTranslations.pick(
          lang,
          en: 'AI Voice Call History & Citizen Feedback',
          mr: 'AI व्हॉइस कॉल इतिहास व नागरिक अभिप्राय',
          hi: 'एआई वॉयस कॉल इतिहास एवं नागरिक प्रतिक्रिया',
        );
      case 'Public Voice Call History & Broadcast Report':
        return AppTranslations.pick(
          lang,
          en: 'Public Voice Call History & Broadcast Report',
          mr: 'सार्वजनिक व्हॉइस कॉल इतिहास व प्रसारण अहवाल',
          hi: 'सार्वजनिक वॉयस कॉल इतिहास एवं प्रसारण रिपोर्ट',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, title, lang);
    }
  }

  static String _resolveHeaderSubtitle(
    String subtitle,
    String lang,
    Map<String, String> textCache,
  ) {
    switch (subtitle.trim()) {
      case 'Report of all broadcasted campaigns and voice logs':
        return AppTranslations.pick(
          lang,
          en: 'Report of all broadcasted campaigns and voice logs',
          mr: 'सर्व प्रसारित मोहिमा व व्हॉइस कॉल नोंदींचा अहवाल',
          hi: 'सभी प्रसारित अभियानों और वॉयस कॉल लॉग की रिपोर्ट',
        );
      case 'Automated AI Voice Call Broadcast Register - Prabhag 12':
        return AppTranslations.pick(
          lang,
          en: 'Automated AI Voice Call Broadcast Register - Prabhag 12',
          mr: 'स्वयंचलित AI व्हॉइस कॉल प्रसारण नोंदवही - प्रभाग १२',
          hi: 'स्वचालित एआई वॉयस कॉल प्रसारण रजिस्टर - प्रभाग १२',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, subtitle, lang);
    }
  }

  static String _resolveLogTitle(
    String rawTitle,
    String lang,
    Map<String, String> textCache,
    Map<String, String> nameCache,
  ) {
    final trimmed = rawTitle.trim();
    if (trimmed.startsWith('Manual Voice Call - ')) {
      final rawName = trimmed.substring('Manual Voice Call - '.length).trim();
      final prefix = AppTranslations.pick(
        lang,
        en: 'Manual Voice Call',
        mr: 'मॅन्युअल व्हॉइस कॉल',
        hi: 'मैनुअल वॉयस कॉल',
      );
      return '$prefix - ${PdfTranslationHelper.resolveName(nameCache, rawName, lang)}';
    }
    if (trimmed.startsWith('WhatsApp Call - ')) {
      final rawName = trimmed.substring('WhatsApp Call - '.length).trim();
      final prefix = AppTranslations.pick(
        lang,
        en: 'WhatsApp Call',
        mr: 'व्हॉट्सॲप कॉल',
        hi: 'व्हाट्सएप कॉल',
      );
      return '$prefix - ${PdfTranslationHelper.resolveName(nameCache, rawName, lang)}';
    }
    return PdfTranslationHelper.resolve(textCache, trimmed, lang);
  }

  static String _resolveChannel(
    String channel,
    String lang,
    Map<String, String> textCache,
  ) {
    final trimmed = channel.trim();
    if (trimmed.isEmpty) return '-';
    switch (trimmed.toLowerCase()) {
      case 'whatsapp':
        return AppTranslations.pick(lang, en: 'WHATSAPP', mr: 'व्हॉट्सॲप', hi: 'व्हाट्सएप');
      case 'wa_call':
        return AppTranslations.pick(lang, en: 'WA CALL', mr: 'व्हॉट्सॲप कॉल', hi: 'व्हाट्सएप कॉल');
      case 'sms':
        return AppTranslations.pick(lang, en: 'SMS', mr: 'SMS', hi: 'एसएमएस');
      case 'call':
      case 'voice':
        return AppTranslations.pick(lang, en: 'VOICE CALL', mr: 'व्हॉइस कॉल', hi: 'वॉयस कॉल');
      case 'ai_call':
        return AppTranslations.pick(lang, en: 'AI CALL', mr: 'AI कॉल', hi: 'एआई कॉल');
      default:
        return PdfTranslationHelper.resolve(textCache, trimmed, lang).toUpperCase();
    }
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
