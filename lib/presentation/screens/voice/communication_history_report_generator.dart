import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class CommunicationHistoryReportGenerator {
  CommunicationHistoryReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<WhatsAppBroadcastModel> logs,
    String title = 'Public Communication History',
    String subtitle = 'Report of all broadcasted campaigns and voice logs',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final total = logs.length;
    final totalRecipients = logs.fold<int>(0, (sum, l) => sum + l.recipients);
    final totalDelivered = logs.fold<int>(0, (sum, l) => sum + l.deliveredCount);
    final totalFailed = logs.fold<int>(0, (sum, l) => sum + l.failedCount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: '$title (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: title,
              subtitle: subtitle,
              dateFormatted: formattedDate,
              totalCount: total,
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
                  _buildSummaryItem('Total Campaigns', '$total'),
                  _buildSummaryItem('Targeted', '$totalRecipients', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Delivered', '$totalDelivered', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Failed', '$totalFailed', highlightColor: PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (logs.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No communication history records found.',
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
                headers: const [
                  '#',
                  'Dispatched Time',
                  'Campaign & Message',
                  'Channel',
                  'Targeted',
                  'Delivered',
                  'Status',
                ],
                data: logs.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final log = entry.value;

                  return [
                    '$idx',
                    log.formattedDate,
                    '${log.title}\n${log.message}',
                    log.channel.toUpperCase(),
                    '${log.recipients}',
                    '${log.deliveredCount}',
                    log.status,
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Communication_History_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
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
