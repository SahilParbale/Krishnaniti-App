import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/social_post_model.dart';
import '../../../data/repositories/social_analytics_repository.dart';
import '../../widgets/app_pdf_report_theme.dart';

class SocialAnalyticsReportGenerator {
  SocialAnalyticsReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<SocialPostModel> posts,
    required SocialAnalyticsSummary summary,
    required List<VoterBirthdayModel> birthdays,
    String? platformFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Social Media Analytics (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Social Media Analytics',
              subtitle: 'Social Media Reach & Voter Engagement Audit Report',
              dateFormatted: nowStr,
              totalCount: posts.length,
              foundLabel: 'Posts',
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
                  _buildSummaryItem('Total Reach', summary.totalReach.toLocaleString()),
                  _buildSummaryItem('Total Likes', summary.totalLikes.toLocaleString(), highlightColor: PdfColors.pink700),
                  _buildSummaryItem('Comments', summary.totalComments.toLocaleString(), highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Shares', summary.totalShares.toLocaleString(), highlightColor: PdfColors.green700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (posts.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No social media post records found.',
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
                  2: pw.FlexColumnWidth(1.6),
                  3: pw.FlexColumnWidth(4.2),
                  4: pw.FlexColumnWidth(1.6),
                  5: pw.FlexColumnWidth(1.6),
                },
                headers: const [
                  '#',
                  'Date',
                  'Platform',
                  'Post Content & Updates',
                  'Reach',
                  'Eng. %',
                ],
                data: posts.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final p = entry.value;

                  return [
                    '$idx',
                    p.date,
                    p.platform.toUpperCase(),
                    p.content,
                    p.reach.toLocaleString(),
                    '${p.engagementRate.toStringAsFixed(1)}%',
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
      name: 'Social_Analytics_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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
