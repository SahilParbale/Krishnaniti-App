import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/work_history_model.dart';

class WorkReportGenerator {
  WorkReportGenerator._();

  static Future<void> generateAndPrintWorkReport({
    required List<WorkHistoryModel> works,
    String? statusFilter,
    String? areaFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final total = works.length;
    final completed = works.where((w) => w.status.toLowerCase() == 'completed').length;
    final inProgress = works.where((w) => w.status.toLowerCase().contains('progress')).length;
    final planned = works.where((w) => w.status.toLowerCase() == 'planned').length;

    final totalSpend = works.fold<double>(0, (sum, w) => sum + (w.amount ?? 0));
    final totalBenefited = works.fold<int>(0, (sum, w) => sum + (w.peopleBenefited ?? 0));

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
                        'WARD DEVELOPMENT WORKS & EXPENDITURE AUDIT REPORT',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward No. 12 - Comprehensive Historical Register of Municipal Projects & Assistance',
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
                    _statPill('Total Projects', '$total', PdfColors.blue900),
                    _statPill('Completed', '$completed', PdfColors.green800),
                    _statPill('In Progress', '$inProgress', PdfColors.orange800),
                    _statPill('Planned', '$planned', PdfColors.grey700),
                    _statPill('Total Citizens Benefited', NumberFormat.decimalPattern().format(totalBenefited), PdfColors.blue800),
                    _statPill('Total Expenditure', numFormat.format(totalSpend), PdfColors.green900),
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
                'Nagarsevak Ward Management System - Official Public Transparency Archive',
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
                1: const pw.FlexColumnWidth(3.0), // Project Title & Details
                2: const pw.FlexColumnWidth(2.0), // Location & Area
                3: const pw.FixedColumnWidth(65), // Status
                4: const pw.FixedColumnWidth(65), // Category / Source
                5: const pw.FixedColumnWidth(65), // Date
                6: const pw.FixedColumnWidth(65), // Benefited
                7: const pw.FixedColumnWidth(75), // Amount
              },
              headers: [
                '#',
                'Development Work / Project Scope',
                'Location & Prabhag Area',
                'Status',
                'Source',
                'Date',
                'Benefited',
                'Expenditure',
              ],
              data: List.generate(works.length, (index) {
                final w = works[index];
                final amtStr = w.amount != null ? numFormat.format(w.amount) : '--';
                final benStr = w.peopleBenefited != null ? NumberFormat.decimalPattern().format(w.peopleBenefited) : '--';

                return [
                  '${index + 1}',
                  '${w.title}\n${w.description}',
                  '${w.location}\nArea: ${w.area}',
                  w.statusDisplayEn,
                  w.sourceDisplayEn,
                  w.date,
                  benStr,
                  amtStr,
                ];
              }),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ward12_Work_History_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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

