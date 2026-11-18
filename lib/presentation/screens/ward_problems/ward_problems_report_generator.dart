import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/complaint_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class WardProblemsReportGenerator {
  WardProblemsReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<ComplaintModel> problems,
    String? areaFilter,
    String? statusFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final total = problems.length;
    final pending = problems.where((p) => p.isPending).length;
    final inProgress = problems.where((p) => p.isInProgress || p.isAssigned).length;
    final resolved = problems.where((p) => p.isResolved).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Ward Problems & Civic Issues (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Ward Civic Issues',
              subtitle: 'Ward-wise Civic Issues & Problem Resolution Dossier',
              metaLines: [
                'Date: $nowStr',
                'Found: $total',
                if (areaFilter != null && areaFilter != 'All') 'Area: $areaFilter',
                if (statusFilter != null && statusFilter != 'All') 'Status: $statusFilter',
              ],
            ),
            pw.SizedBox(height: 12),

            // Overview summary bar
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Problems', '$total'),
                  _buildSummaryItem('Pending', '$pending', highlightColor: PdfColors.amber800),
                  _buildSummaryItem('In Progress', '$inProgress', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Resolved', '$resolved', highlightColor: PdfColors.green700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (problems.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No ward problem records found for the selected view.',
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(3.2),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(2.2),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.6),
                },
                headers: const [
                  '#',
                  'Issue Title & Category',
                  'Location / Area',
                  'Citizen / Reporter',
                  'Status',
                  'Date',
                ],
                data: List.generate(problems.length, (index) {
                  final p = problems[index];
                  final catStr = p.category.isNotEmpty ? '\nCategory: ${p.category}' : '';
                  final phoneStr = (p.citizenMobile != null && p.citizenMobile!.isNotEmpty) ? '\n${p.citizenMobile}' : '';
                  final dateStr = DateFormat('dd/MM/yyyy').format(p.createdAt);
                  final areaStr = (p.area != null && p.area!.isNotEmpty) ? p.area! : '-';

                  return [
                    '${index + 1}',
                    '${p.title}$catStr',
                    areaStr,
                    '${p.citizenName}$phoneStr',
                    p.status,
                    dateStr,
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
      name: 'Ward_Problems_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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
