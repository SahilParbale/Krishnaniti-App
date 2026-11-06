import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/complaint_model.dart';

class WardProblemsReportGenerator {
  WardProblemsReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<ComplaintModel> problems,
    String? areaFilter,
    String? statusFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final total = problems.length;
    final pending = problems.where((p) => p.isPending).length;
    final inProgress = problems.where((p) => p.isInProgress || p.isAssigned).length;
    final resolved = problems.where((p) => p.isResolved).length;

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
                        'WARD PROBLEMS & CIVIC ISSUES REGISTER',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 - Self-Identified & Ward-Level Infrastructure Pain Points',
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
                      if (areaFilter != null && areaFilter != 'All')
                        pw.Text('Area: $areaFilter', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800)),
                      if (statusFilter != null && statusFilter != 'All')
                        pw.Text('Status: $statusFilter', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
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
                    _statPill('Total Logged', '$total', PdfColors.blue900),
                    _statPill('Pending', '$pending', PdfColors.red800),
                    _statPill('Under Resolution', '$inProgress', PdfColors.amber800),
                    _statPill('Resolved', '$resolved', PdfColors.green800),
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
                'Nagarsevak Ward Public Grievance Management System',
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
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26), // Sr
                1: const pw.FlexColumnWidth(2.0), // Area & Location
                2: const pw.FlexColumnWidth(3.2), // Title & Description
                3: const pw.FlexColumnWidth(1.2), // Category
                4: const pw.FlexColumnWidth(1.2), // Status
                5: const pw.FlexColumnWidth(2.0), // Citizen / Submitter
                6: const pw.FlexColumnWidth(2.0), // Assigned Staff
                7: const pw.FlexColumnWidth(1.4), // Date
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _cellHeader('Sr', align: pw.TextAlign.center),
                    _cellHeader('Area / Location'),
                    _cellHeader('Problem Title & Description'),
                    _cellHeader('Category'),
                    _cellHeader('Status'),
                    _cellHeader('Citizen / Spotter'),
                    _cellHeader('Assigned Officer'),
                    _cellHeader('Logged Date'),
                  ],
                ),
                // Rows
                ...problems.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final p = entry.value;
                  final isEven = idx % 2 == 0;
                  final dateFormatted = DateFormat('dd MMM yyyy').format(p.createdAt);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _cellText('$idx', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(p.area ?? 'Ward 12', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            if (p.location != null && p.location!.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(p.location!, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            ],
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(p.title, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text(p.description, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700), maxLines: 3),
                          ],
                        ),
                      ),
                      _cellText(p.category),
                      _cellText(p.status, isBold: true),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(p.citizenName ?? 'Ward Spotter', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900)),
                            if (p.citizenMobile != null && p.citizenMobile!.isNotEmpty)
                              pw.Text(p.citizenMobile!, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(p.assignedStaffName ?? 'Unassigned', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900)),
                            if (p.assignedStaffMobile != null && p.assignedStaffMobile!.isNotEmpty)
                              pw.Text(p.assignedStaffMobile!, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                      _cellText(dateFormatted),
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
      name: 'Ward_Problems_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _statPill(String label, String val, PdfColor col) {
    return pw.Row(
      children: [
        pw.Text('$label: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.Text(val, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: col)),
      ],
    );
  }

  static pw.Widget _cellHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.blue900),
      ),
    );
  }

  static pw.Widget _cellText(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }
}

