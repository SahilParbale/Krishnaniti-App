import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/sadasya_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class SadasyaReportGenerator {
  SadasyaReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<SadasyaModel> members,
    String? areaFilter,
    String? typeFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final totalCount = members.length;
    final voterCount = members.where((m) => m.isVoter).length;
    final nonVoterCount = totalCount - voterCount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Party Members Directory (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Party Members Directory',
              subtitle: 'Registered party members, volunteers and booth level workers',
              dateFormatted: nowStr,
              totalCount: totalCount,
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
                  _buildSummaryItem('Total Members', '$totalCount'),
                  _buildSummaryItem('Voter Members', '$voterCount', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Party Cadre', '$nonVoterCount', highlightColor: WebReportTheme.brand700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (members.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No party members found for the selected view.',
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
                  0: pw.FixedColumnWidth(26),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(1.6),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(2.4),
                  5: pw.FlexColumnWidth(1.4),
                  6: pw.FlexColumnWidth(1.2),
                },
                headers: const [
                  '#',
                  'Member Name',
                  'Mobile No.',
                  'Area / Ward',
                  'Address',
                  'Type',
                  'Joined Date',
                ],
                data: members.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final dateFormatted = DateFormat('MMM d, yyyy').format(item.registeredAt);

                  return [
                    '$idx',
                    item.displayName,
                    item.mobile.isNotEmpty ? item.mobile : '-',
                    item.area ?? item.ward ?? '-',
                    item.displayAddress.isNotEmpty ? item.displayAddress : '-',
                    item.isVoter ? 'Voter Member' : 'Party Member',
                    dateFormatted,
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
      name: 'Party_Members_Report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
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
