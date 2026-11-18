import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/social_organization_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class SocialOrgReportGenerator {
  SocialOrgReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<SocialOrganizationModel> organizations,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(now);

    final total = organizations.length;
    final ngos = organizations.where((o) => o.type == 'ngo').length;
    final sports = organizations.where((o) => o.type == 'sports_cricket').length;
    final mandals = organizations.where((o) => o.type == 'ganpati_mandal' || o.type == 'navratri_mandal').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'NGO & Mandal Registry (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'NGO & Mandal Registry',
              subtitle: 'List of NGOs, Clubs and Mandals in the ward',
              dateFormatted: formattedDate,
              totalCount: total,
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
                  _buildSummaryItem('Total NGOs', '$ngos', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Sports Clubs', '$sports', highlightColor: PdfColors.teal700),
                  _buildSummaryItem('Mandals', '$mandals', highlightColor: PdfColors.amber800),
                  _buildSummaryItem('Total Registered', '$total'),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (organizations.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No social organizations or mandals found.',
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
                  1: pw.FlexColumnWidth(3.0),
                  2: pw.FlexColumnWidth(2.4),
                  3: pw.FlexColumnWidth(1.8),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.2),
                },
                headers: const [
                  '#',
                  'Organization Name & Type',
                  'President & Mobile',
                  'Area',
                  'Members & Est.',
                  'Status',
                ],
                data: List.generate(organizations.length, (index) {
                  final o = organizations[index];
                  final typeStr = '\nType: ${o.typeLabelEnglish}';
                  final presStr = o.presidentName.isNotEmpty
                      ? (o.presidentMobile.isNotEmpty ? '${o.presidentName}\n${o.presidentMobile}' : o.presidentName)
                      : '-';
                  final memStr = o.membersCount > 0 ? '${o.membersCount} members' : '-';
                  final estStr = o.establishedYear.isNotEmpty ? '\nEst: ${o.establishedYear}' : '';

                  return [
                    '${index + 1}',
                    '${o.displayName}$typeStr',
                    presStr,
                    o.area.isNotEmpty ? o.area : '-',
                    '$memStr$estStr',
                    o.status,
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
      name: 'Mandal_NGO_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
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
