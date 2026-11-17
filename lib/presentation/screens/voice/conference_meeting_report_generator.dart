import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'conference_room_screen.dart';

/// Official Conference Room & Virtual Meetings Report Generator matching Nagarsevak-Managment
/// (MeetingReportGenerator.tsx).
class ConferenceMeetingReportGenerator {
  ConferenceMeetingReportGenerator._();

  static Future<void> generateAndPrintMeetingReport({
    required List<ConferenceMeetingModel> meetings,
    String? statusFilter,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);

    final total = meetings.length;
    final scheduled = meetings.where((m) => m.status.toLowerCase() == 'scheduled').length;
    final active = meetings.where((m) => m.status.toLowerCase() == 'active').length;
    final ended = meetings.where((m) => m.status.toLowerCase() == 'ended').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Official PMC Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - PRABHAG 12',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Virtual Conference & Citizen Deliberation Schedule',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A)),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Online Ward Consultations, Cadre Reviews & Citizen Assembly Records',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                        ),
                        child: pw.Text(
                          'OFFICIAL RECORD',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Generated: $formattedDate', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Statistics Row
            pw.Row(
              children: [
                _buildPdfKpiCard('Total Meetings', '$total', PdfColors.blue50, PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Upcoming Scheduled', '$scheduled', PdfColors.indigo50, PdfColors.indigo900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Currently Live', '$active', PdfColors.green50, PdfColors.green900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Concluded', '$ended', PdfColors.grey100, PdfColors.grey800),
              ],
            ),
            pw.SizedBox(height: 14),

            // Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0284C7)),
              headerHeight: 24,
              cellHeight: 22,
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey900),
              headers: [
                '#',
                'Scheduled Date & Time',
                'Meeting Title / Purpose',
                'Status',
                'Invited Attendees',
                'Conference Link / Notes',
              ],
              columnWidths: const {
                0: pw.FixedColumnWidth(25),
                1: pw.FixedColumnWidth(85),
                2: pw.FlexColumnWidth(2.5),
                3: pw.FixedColumnWidth(65),
                4: pw.FixedColumnWidth(75),
                5: pw.FlexColumnWidth(2.0),
              },
              data: List.generate(meetings.length, (index) {
                final m = meetings[index];
                final dateStr = DateFormat('dd/MM/yyyy, hh:mm a').format(m.scheduledAt);
                final linkNotes = '${m.meetLink}\n${m.notes ?? ""}';
                return [
                  '${index + 1}',
                  dateStr,
                  m.title,
                  m.status.toUpperCase(),
                  '${m.invitedCount} Citizens/Staff',
                  linkNotes,
                ];
              }),
            ),
            pw.SizedBox(height: 18),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Krishnaniti Virtual Conference Console', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Conference_Meetings_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildPdfKpiCard(String label, String value, PdfColor bg, PdfColor text) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: text)),
          ],
        ),
      ),
    );
  }
}
