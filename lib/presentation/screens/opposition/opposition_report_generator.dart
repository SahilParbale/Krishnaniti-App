import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/opposition_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class OppositionReportGenerator {
  OppositionReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<OppositionMemberModel> members,
    required String Function(String) getCandidateName,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(now);

    final totalMembers = members.length;
    final totalCandidates = members.where((m) => m.isCandidate).length;
    final totalWorkers = members.where((m) => !m.isCandidate).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Opposition Intelligence (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Opposition Information',
              subtitle: 'Track and monitor opposition workers, strongholds, and key public campaigns',
              dateFormatted: formattedDate,
              totalCount: totalMembers,
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
                  _buildSummaryItem('Total Members', '$totalMembers'),
                  _buildSummaryItem('Candidates', '$totalCandidates', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Workers', '$totalWorkers', highlightColor: WebReportTheme.slate700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (members.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No opposition members found.',
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
                  2: pw.FlexColumnWidth(1.6),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(1.8),
                  5: pw.FlexColumnWidth(2.6),
                },
                headers: const [
                  '#',
                  'Name & Party',
                  'Role / Designation',
                  'Type',
                  'Mobile',
                  'Area & Strongholds',
                ],
                data: List.generate(members.length, (index) {
                  final m = members[index];
                  final partyStr = m.party.isNotEmpty ? '\nParty: ${m.party}' : '';
                  final strongholdsStr = m.strongholds.isNotEmpty ? '\nStrongholds: ${m.strongholds.take(2).join(", ")}' : '';
                  final areaStr = m.area?.isNotEmpty == true ? m.area! : '-';

                  return [
                    '${index + 1}',
                    '${m.name}$partyStr',
                    m.role ?? '-',
                    m.isCandidate ? 'Candidate' : 'Worker',
                    m.mobile ?? '-',
                    '$areaStr$strongholdsStr',
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
      name: 'Opposition_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
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
