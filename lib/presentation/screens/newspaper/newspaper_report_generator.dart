import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/newspaper_clipping_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class NewspaperReportGenerator {
  NewspaperReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<NewspaperClippingModel> clippings,
    String? sentimentFilter,
    String? newspaperFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final totalCount = clippings.length;
    final positiveCount = clippings.where((c) => c.isPositive).length;
    final negativeCount = clippings.where((c) => !c.isPositive).length;
    final uniquePapers = clippings.map((c) => c.newspaper).toSet().length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Newspaper Clippings (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Newspaper Clippings',
              subtitle: 'Report of Newspaper Clippings & Media Coverage',
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
                  _buildSummaryItem('Total Clippings', '$totalCount'),
                  _buildSummaryItem('Positive Coverage', '$positiveCount', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Critical Issues', '$negativeCount', highlightColor: PdfColors.red700),
                  _buildSummaryItem('Dailies Tracked', '$uniquePapers', highlightColor: WebReportTheme.brand700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (clippings.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No newspaper clippings found.',
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
                  1: pw.FlexColumnWidth(1.6),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(4.2),
                  4: pw.FlexColumnWidth(1.4),
                },
                headers: const [
                  '#',
                  'Date',
                  'Newspaper & Page',
                  'Title & Coverage Summary',
                  'Sentiment',
                ],
                data: clippings.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final c = entry.value;
                  final pageStr = c.pageNumber != null && c.pageNumber!.isNotEmpty ? ' (${c.pageNumber})' : '';
                  final descPart = c.description.isNotEmpty ? '\n${c.description}' : '';

                  return [
                    '$idx',
                    c.date,
                    '${c.newspaper}$pageStr',
                    '${c.title}$descPart',
                    c.isPositive ? 'Positive' : 'Critical',
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
      name: 'Newspaper_Clippings_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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
