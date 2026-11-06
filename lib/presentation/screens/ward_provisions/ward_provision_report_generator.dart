import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/ward_provision_model.dart';

class WardProvisionReportGenerator {
  WardProvisionReportGenerator._();

  static Future<void> generateAndPrintProvisionReport({
    required List<WardProvisionModel> provisions,
    required String year,
    String? categoryFilter,
    String? statusFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalCount = provisions.length;
    final totalRequested = provisions.fold<double>(0, (sum, p) => sum + p.requestedAmount);
    final totalSanctioned = provisions.fold<double>(0, (sum, p) => sum + (p.sanctionedAmount ?? 0));
    final successRate = totalRequested > 0 ? ((totalSanctioned / totalRequested) * 100).toStringAsFixed(1) : '0';

    final approvedCount = provisions.where((p) => p.status.toLowerCase() == 'approved').length;
    final partialCount = provisions.where((p) => p.status.toLowerCase().contains('partially')).length;
    final pendingCount = provisions.where((p) => p.status.toLowerCase() == 'pending').length;

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
                        'PUNE MUNICIPAL CORPORATION - WARD PROVISIONS & SANCTIONS DOSSIER',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 - Capital Budget Allocations, Departmental Requests & Sanction Audit ($year)',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
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
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                      pw.Text('FY: $year', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      if (statusFilter != null && statusFilter != 'All')
                        pw.Text('Status: $statusFilter', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blue800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Financial Summary Strip
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
                    _statPill('Total Requests', '$totalCount', PdfColors.blue900),
                    _statPill('Total Requested', numFormat.format(totalRequested), PdfColors.blue800),
                    _statPill('Total Sanctioned', numFormat.format(totalSanctioned), PdfColors.green900),
                    _statPill('Success Rate', '$successRate%', PdfColors.orange900),
                    _statPill('Approved', '$approvedCount', PdfColors.green800),
                    _statPill('Partially Approved', '$partialCount', PdfColors.blue700),
                    _statPill('Pending Review', '$pendingCount', PdfColors.orange800),
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
                'Nagarsevak Ward Municipal Finance & Sanction Tracker',
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
                0: const pw.FixedColumnWidth(26),  // #
                1: const pw.FlexColumnWidth(3.0), // Project Title & Description
                2: const pw.FixedColumnWidth(85), // Category
                3: const pw.FixedColumnWidth(85), // Area
                4: const pw.FixedColumnWidth(85), // Letter Ref
                5: const pw.FixedColumnWidth(75), // Requested
                6: const pw.FixedColumnWidth(75), // Sanctioned
                7: const pw.FixedColumnWidth(65), // Status
                8: const pw.FixedColumnWidth(60), // Date
              },
              headers: [
                '#',
                'Project Title & Purpose',
                'Category',
                'Area',
                'Letter Ref',
                'Requested',
                'Sanctioned',
                'Status',
                'Date',
              ],
              data: List.generate(provisions.length, (index) {
                final p = provisions[index];
                final reqStr = numFormat.format(p.requestedAmount);
                final sancStr = p.sanctionedAmount != null ? numFormat.format(p.sanctionedAmount) : '--';

                return [
                  '${index + 1}',
                  '${p.title}\n${p.description}',
                  p.category,
                  p.area,
                  p.letterReference,
                  reqStr,
                  sancStr,
                  p.statusDisplayEn,
                  p.sanctionedDate ?? p.requestedDate,
                ];
              }),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ward12_Provisions_Report_${year}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _statPill(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11.5,
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

