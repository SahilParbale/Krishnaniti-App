import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/media_tracking_model.dart';
import '../../../data/models/social_post_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class MediaTrackingReportGenerator {
  MediaTrackingReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<MediaTrackingArticleModel> articles,
    String? profileFilter,
    String? sentimentFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final totalCount = articles.length;
    final positiveCount = articles.where((a) => a.isPositive).length;
    final negativeCount = articles.where((a) => a.isNegative).length;
    final totalReach = articles.fold<int>(0, (acc, a) => acc + a.reachEstimate);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Media Monitoring (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Digital Media Monitoring',
              subtitle: 'Live Online News Portals & Press Mentions Tracker',
              dateFormatted: nowStr,
              totalCount: totalCount,
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
                  _buildSummaryItem('Total Mentions', '$totalCount'),
                  _buildSummaryItem('Positive Press', '$positiveCount', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Critical Issues', '$negativeCount', highlightColor: PdfColors.red700),
                  _buildSummaryItem('Est. Digital Reach', totalReach.toLocaleString(), highlightColor: WebReportTheme.brand700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (articles.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No media mentions or tracked articles found.',
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
                  1: pw.FlexColumnWidth(1.8),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(1.8),
                  4: pw.FlexColumnWidth(3.8),
                  5: pw.FlexColumnWidth(1.4),
                },
                headers: const [
                  '#',
                  'Date',
                  'News Source',
                  'Tracked Subject',
                  'Headline & Summary',
                  'Sentiment',
                ],
                data: articles.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final a = entry.value;

                  return [
                    '$idx',
                    '${a.date}\n${a.time}',
                    '${a.source}\n(${a.sourceType.toUpperCase()})',
                    a.personTracked,
                    '${a.title}\n${a.summary}',
                    a.sentiment.toUpperCase(),
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
      name: 'Media_Tracking_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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
