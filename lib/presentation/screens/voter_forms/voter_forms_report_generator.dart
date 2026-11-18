import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/voter_application_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class VoterFormsReportGenerator {
  VoterFormsReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<VoterApplicationModel> applications,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final total = applications.length;
    final approved = applications.where((a) => a.status.toLowerCase() == 'approved').length;
    final pending = applications.where((a) => a.status.toLowerCase() == 'pending').length;
    final submitted = applications.where((a) => a.status.toLowerCase() == 'submitted').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Voter Applications (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Voter Applications History',
              subtitle: 'List of all logged voter form applications (Form 6, 7, 8)',
              dateFormatted: formattedDate,
              totalCount: total,
            ),
            pw.SizedBox(height: 12),

            // Summary KPI Row matching web
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Applications', '$total'),
                  _buildSummaryItem('Approved', '$approved', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Pending', '$pending', highlightColor: PdfColors.amber800),
                  _buildSummaryItem('Submitted', '$submitted', highlightColor: WebReportTheme.brand700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (applications.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No voter form applications found.',
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
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(1.8),
                  3: pw.FlexColumnWidth(2.0),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.4),
                  6: pw.FlexColumnWidth(2.8),
                },
                headers: const [
                  '#',
                  'Applicant Name',
                  'Mobile',
                  'Form Type',
                  'Status',
                  'Date',
                  'Notes / Purpose',
                ],
                data: List.generate(applications.length, (index) {
                  final app = applications[index];
                  final dateStr = DateFormat('dd/MM/yyyy').format(app.createdAt);

                  return [
                    '${index + 1}',
                    app.applicantName,
                    app.applicantMobile ?? '-',
                    app.formTypeMarathi,
                    app.statusMarathi,
                    dateStr,
                    app.notes?.isNotEmpty == true ? app.notes! : '-',
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
      name: 'Voter_Forms_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
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
