import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/government_office_model.dart';

class GovOfficeReportGenerator {
  GovOfficeReportGenerator._();

  static Future<void> generateAndPrintOfficeReport({
    required List<GovernmentOfficeModel> offices,
    String? categoryFilter,
    String? areaFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalCount = offices.length;
    final emergencyCount = offices.where((o) => o.isEmergency).length;
    final municipalCount = offices.where((o) => o.category.toLowerCase().contains('municipal')).length;
    final policeCount = offices.where((o) => o.category.toLowerCase().contains('police')).length;

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
                        'PUNE MUNICIPAL CORPORATION - CIVIC AUTHORITIES & GOVERNMENT OFFICES DIRECTORY',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 - Municipal Administration, Police Stations, Emergency Helplines & Utility Offices',
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
                      if (categoryFilter != null && categoryFilter != 'All')
                        pw.Text(
                          'Category: $categoryFilter',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                      if (areaFilter != null && areaFilter != 'All')
                        pw.Text('Area: $areaFilter', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blue800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Summary Strip
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
                    _statPill('Total Offices & Helplines', '$totalCount', PdfColors.blue900),
                    _statPill('24x7 Emergency Services', '$emergencyCount', PdfColors.red900),
                    _statPill('Municipal PMC Centers', '$municipalCount', PdfColors.blue800),
                    _statPill('Police & Security Desks', '$policeCount', PdfColors.indigo900),
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
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Pune Municipal Corporation - Nagarsevak Citizen Services Portal | Official Emergency & Administrative Directory',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),  // #
                1: pw.FlexColumnWidth(3.0), // Office Name
                2: pw.FlexColumnWidth(2.2), // Officer In-Charge
                3: pw.FlexColumnWidth(1.8), // Contact / Helpline
                4: pw.FlexColumnWidth(1.6), // Category
                5: pw.FlexColumnWidth(2.6), // Address & Area
                6: pw.FlexColumnWidth(1.8), // Timings
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _tableHeader('#', alignCenter: true),
                    _tableHeader('Office / Authority Name'),
                    _tableHeader('Officer In-Charge'),
                    _tableHeader('Contact / Helpline'),
                    _tableHeader('Category'),
                    _tableHeader('Address & Location'),
                    _tableHeader('Working Hours'),
                  ],
                ),
                ...offices.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.name,
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                            ),
                            if (item.isEmergency)
                              pw.Container(
                                margin: const pw.EdgeInsets.only(top: 2),
                                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.red50,
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                                child: pw.Text('24x7 Emergency', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.red900)),
                              ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(item.officerName, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.contactNumber,
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                            if (item.secondaryContact != null)
                              pw.Text(
                                item.secondaryContact!,
                                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                              ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(item.category, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.address, style: const pw.TextStyle(fontSize: 7.5)),
                            pw.Text(item.area, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(item.timing, style: const pw.TextStyle(fontSize: 7.5)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Government_Offices_Directory_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _statPill(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 1),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text, {bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}

