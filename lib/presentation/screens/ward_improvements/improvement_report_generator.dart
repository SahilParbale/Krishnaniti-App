import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/improvement_model.dart';

class ImprovementReportGenerator {
  ImprovementReportGenerator._();

  static Future<void> generateAndPrintImprovementReport({
    required List<ImprovementModel> improvements,
    String? statusFilter,
    String? areaFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final total = improvements.length;
    final complete = improvements.where((i) => i.status.toLowerCase() == 'complete').length;
    final inProgress = improvements.where((i) => i.status.toLowerCase().contains('progress')).length;
    final planned = improvements.where((i) => i.status.toLowerCase() == 'planned').length;
    final pending = improvements.where((i) => i.status.toLowerCase() == 'pending').length;

    final totalVotes = improvements.fold<int>(0, (sum, i) => sum + i.votes);
    final totalBudget = improvements.fold<double>(0, (sum, i) => sum + (i.estimatedBudget ?? 0));
    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WARD POSSIBLE IMPROVEMENTS & CITIZEN PROPOSALS DOSSIER',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 - Crowdsourced Civic Suggestions, Urban Infrastructure & Community Priorities',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated: $nowStr',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                      if (statusFilter != null && statusFilter != 'All')
                        pw.Text('Status: $statusFilter', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800)),
                      if (areaFilter != null && areaFilter.isNotEmpty)
                        pw.Text('Area: $areaFilter', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Executive Summary Strip
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _statPill('Total Proposals', '$total', PdfColors.blue900),
                    _statPill('Citizen Votes', NumberFormat.decimalPattern().format(totalVotes), PdfColors.blue800),
                    _statPill('Complete', '$complete', PdfColors.green800),
                    _statPill('In Progress', '$inProgress', PdfColors.blue800),
                    _statPill('Planned', '$planned', PdfColors.purple800),
                    _statPill('Pending Review', '$pending', PdfColors.orange800),
                    _statPill('Est. Budget', numFormat.format(totalBudget), PdfColors.green900),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Nagarsevak Ward Administration System - Democratic Citizen Proposal Register',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),  // Sr No
                1: const pw.FlexColumnWidth(3.0), // Proposal Title & Details
                2: const pw.FlexColumnWidth(2.0), // Location & Area
                3: const pw.FixedColumnWidth(65), // Status
                4: const pw.FixedColumnWidth(55), // Votes
                5: const pw.FixedColumnWidth(65), // Target Date
                6: const pw.FixedColumnWidth(65), // Benefited
                7: const pw.FixedColumnWidth(75), // Est. Budget
              },
              headers: [
                '#',
                'Proposed Civic Improvement / Scope',
                'Location & Prabhag Area',
                'Status',
                'Votes',
                'Date',
                'Benefited',
                'Est. Budget',
              ],
              data: List.generate(improvements.length, (index) {
                final imp = improvements[index];
                final budgetStr = imp.estimatedBudget != null ? numFormat.format(imp.estimatedBudget) : '--';
                final benStr = imp.peopleBenefited != null ? NumberFormat.decimalPattern().format(imp.peopleBenefited) : '--';

                return [
                  '${index + 1}',
                  '${imp.title}\n${imp.description}',
                  '${imp.location}\nArea: ${imp.area}',
                  imp.statusDisplayEn,
                  '${imp.votes} Votes',
                  imp.completionDate ?? imp.createdAt,
                  benStr,
                  budgetStr,
                ];
              }),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Prabhag12_Possible_Improvements_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _statPill(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }
}

