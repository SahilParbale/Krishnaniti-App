import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/whatsapp_broadcast_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class WhatsAppHistoryReportGenerator {
  WhatsAppHistoryReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<WhatsAppBroadcastModel> broadcasts,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final totalBroadcasts = broadcasts.length;
    final totalRecipients = broadcasts.fold<int>(0, (sum, b) => sum + b.recipients);
    final totalDelivered = broadcasts.fold<int>(0, (sum, b) => sum + b.deliveredCount);
    final totalFailed = broadcasts.fold<int>(0, (sum, b) => sum + b.failedCount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'WhatsApp Broadcast Campaigns (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'WhatsApp Broadcast History',
              subtitle: 'Official WhatsApp Public Outreach & Campaign Dispatches',
              dateFormatted: nowStr,
              totalCount: totalBroadcasts,
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
                  _buildSummaryItem('Total Broadcasts', '$totalBroadcasts'),
                  _buildSummaryItem('Targeted', '$totalRecipients', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Delivered', '$totalDelivered', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Failed', '$totalFailed', highlightColor: PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (broadcasts.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No WhatsApp broadcast dispatches found.',
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
                headers: const [
                  '#',
                  'Dispatched Time',
                  'Campaign & Message',
                  'Targeted',
                  'Delivered',
                  'Status',
                ],
                data: broadcasts.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final b = entry.value;

                  return [
                    '$idx',
                    b.formattedDate,
                    '${b.title}\n${b.message}',
                    '${b.recipients}',
                    '${b.deliveredCount}',
                    b.status,
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
      name: 'WhatsApp_Broadcast_History_${DateFormat('yyyyMMdd').format(now)}.pdf',
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
