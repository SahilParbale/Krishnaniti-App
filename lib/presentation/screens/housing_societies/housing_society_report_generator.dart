import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/housing_society_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class HousingSocietyReportGenerator {
  HousingSocietyReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<HousingSocietyModel> societies,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(now);

    final totalSocieties = societies.length;
    final totalVoters = societies.fold<int>(0, (sum, s) => sum + s.voterCount);
    final totalFavourable = societies.fold<int>(0, (sum, s) => sum + s.favourableVoterCount);
    final supportPercentage = totalVoters > 0 ? ((totalFavourable / totalVoters) * 100).round() : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Housing Societies Registry (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Housing Societies Registry',
              subtitle: 'List of Co-operative Housing Societies & Executive Contacts',
              dateFormatted: formattedDate,
              totalCount: totalSocieties,
            ),
            pw.SizedBox(height: 12),

            // Summary row matching web layout
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Societies', '$totalSocieties'),
                  _buildSummaryItem('Total Voters', '$totalVoters', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Favourable', '$totalFavourable', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Support Rating', '$supportPercentage%', highlightColor: WebReportTheme.brand600),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (societies.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No housing societies found.',
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
                  1: pw.FlexColumnWidth(2.8),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(2.2),
                  4: pw.FlexColumnWidth(1.6),
                  5: pw.FlexColumnWidth(1.2),
                  6: pw.FlexColumnWidth(1.2),
                },
                headers: const [
                  '#',
                  'Society & Area',
                  'Chairman',
                  'Secretary',
                  'Voters (Tot/Fav)',
                  'Support',
                  'Status',
                ],
                data: List.generate(societies.length, (index) {
                  final s = societies[index];
                  final areaStr = s.area.isNotEmpty ? '\nArea: ${s.area}' : '';
                  final chairmanStr = s.chairmanName.isNotEmpty
                      ? (s.chairmanMobile.isNotEmpty ? '${s.chairmanName}\n(${s.chairmanMobile})' : s.chairmanName)
                      : '-';
                  final secStr = s.secretaryName.isNotEmpty
                      ? (s.secretaryMobile.isNotEmpty ? '${s.secretaryName}\n(${s.secretaryMobile})' : s.secretaryName)
                      : '-';

                  return [
                    '${index + 1}',
                    '${s.displayName(true)}$areaStr',
                    chairmanStr,
                    secStr,
                    '${s.voterCount} / ${s.favourableVoterCount}',
                    '${s.supportPercentage}%',
                    s.status,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Housing_Societies_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
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
