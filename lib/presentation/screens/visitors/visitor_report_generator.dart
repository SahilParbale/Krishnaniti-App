import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/visitor_model.dart';

class VisitorReportGenerator {
  VisitorReportGenerator._();

  static Future<void> generateAndPrintListReport({
    required List<VisitorModel> visitors,
    String? filterTitle,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final total = visitors.length;
    final todayCount = visitors.where((v) => v.isToday).length;
    final complaintCount = visitors.where((v) => v.purpose.toLowerCase() == 'complaint').length;
    final helpCount = visitors.where((v) => v.purpose.toLowerCase() == 'help' || v.purpose.toLowerCase() == 'donation').length;

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
                        'OFFICE VISITOR LOG - CONSTITUENT VISIT REGISTER',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 - Nagarsevak Public Grievance & Office Register',
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
                      if (filterTitle != null && filterTitle.isNotEmpty)
                        pw.Text(
                          'Filter: $filterTitle',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              // Summary row
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryPill('Total Visitors', '$total', PdfColors.blue800),
                    _buildSummaryPill('Today', '$todayCount', PdfColors.amber800),
                    _buildSummaryPill('Complaints', '$complaintCount', PdfColors.red800),
                    _buildSummaryPill('Help / Requests', '$helpCount', PdfColors.green800),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          if (visitors.isEmpty) {
            return [
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No visitor records found for the selected view.',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ),
            ];
          }

          final headers = [
            'Sr.',
            'Visit Date & Time',
            'Visitor Name',
            'Mobile',
            'Area / Locality',
            'Purpose',
            'Reference & Notes',
          ];

          final rows = <List<String>>[];
          for (var i = 0; i < visitors.length; i++) {
            final v = visitors[i];
            final dateTimeStr = '${DateFormat('dd/MM/yyyy').format(v.visitDate)}\n${DateFormat('hh:mm a').format(v.visitDate)}';
            final refPart = (v.reference != null && v.reference!.isNotEmpty) ? 'Ref: ${v.reference!}\n' : '';
            final notesPart = (v.remarks != null && v.remarks!.isNotEmpty) ? v.remarks! : '';
            final amountPart = (v.amount != null && v.amount!.isNotEmpty) ? ' [₹${v.amount}]' : '';

            rows.add([
              '${i + 1}',
              dateTimeStr,
              v.name,
              v.mobile.isNotEmpty ? v.mobile : '-',
              v.area != null && v.area!.isNotEmpty ? v.area! : '-',
              '${v.purpose}$amountPart',
              '$refPart$notesPart'.trim().isNotEmpty ? '$refPart$notesPart'.trim() : '-',
            ]);
          }

          return [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FixedColumnWidth(75),
                2: const pw.FixedColumnWidth(110),
                3: const pw.FixedColumnWidth(75),
                4: const pw.FixedColumnWidth(100),
                5: const pw.FixedColumnWidth(75),
                6: const pw.FlexColumnWidth(3),
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Visitor_Log_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildSummaryPill(String label, String value, PdfColor color) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static Future<void> generateAndPrintVisitorSlip(VisitorModel visitor) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy, hh:mm a').format(visitor.visitDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'OFFICE VISITOR PASS / SLIP',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Nagarsevak Office - Prabhag 12 Public Relations Desk',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        border: pw.Border.all(color: PdfColors.blue300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        visitor.purpose,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Overview Grid
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFieldCol('Visitor Name', visitor.name),
                        _buildFieldCol('Contact Mobile', visitor.mobile.isNotEmpty ? visitor.mobile : 'N/A'),
                        _buildFieldCol('Check-in Date & Time', dateStr),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFieldCol('Area / Address', visitor.area ?? 'Ward 12'),
                        _buildFieldCol('Reference / Leader', visitor.reference ?? 'Self'),
                        if (visitor.amount != null && visitor.amount!.isNotEmpty)
                          _buildFieldCol('Requested Amount', '₹${visitor.amount}')
                        else
                          _buildFieldCol('Status', 'Logged / Checked In'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Discussion Notes
              pw.Text(
                'PURPOSE & DISCUSSION REMARKS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  visitor.remarks != null && visitor.remarks!.isNotEmpty
                      ? visitor.remarks!
                      : 'No additional notes provided.',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey900, lineSpacing: 1.4),
                ),
              ),

              if (visitor.eventDate != null && visitor.eventDate!.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'EVENT / INVITATION DETAILS',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple50,
                    border: pw.Border.all(color: PdfColors.purple200),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    'Event Date: ${visitor.eventDate} | Time: ${visitor.eventTime ?? "TBD"} | Venue: ${visitor.area ?? "Local"}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900),
                  ),
                ),
              ],

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Visitor Signature', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Desk Officer / Reception', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Visitor_Slip_${visitor.id}.pdf',
    );
  }

  static pw.Widget _buildFieldCol(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}

