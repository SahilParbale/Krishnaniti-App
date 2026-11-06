import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/event_model.dart';

class EventReportGenerator {
  EventReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<EventModel> events,
    String? areaFilter,
    String? typeFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalEvents = events.length;
    final upcomingEvents = events.where((e) => e.isUpcoming).length;
    final completedEvents = events.where((e) => e.isCompleted).length;
    final totalRsvps = events.fold<int>(0, (sum, e) => sum + e.totalRsvps);
    final totalGoing = events.fold<int>(0, (sum, e) => sum + e.goingCount);
    final overallGoingRate = totalRsvps > 0 ? (totalGoing / totalRsvps) * 100 : 0.0;

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
                        'PUNE MUNICIPAL CORPORATION - PUBLIC ENGAGEMENT & CONSTITUENCY CELL',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Prabhag Ward 12 (Kasba-Vishrambaug Wada) • Public Programs, Events & RSVPs Master Register',
                        style: const pw.TextStyle(
                          fontSize: 9,
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
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.blue800),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Office of Corporator Amit Chougale • Prabhag 12 • Official Civic Engagement Record',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Nagarsevak Mobile Suite',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Strip
            pw.Row(
              children: [
                _buildKpiCard('TOTAL EVENTS', '$totalEvents', 'Community Programs', PdfColors.blue900, PdfColors.blue50),
                pw.SizedBox(width: 8),
                _buildKpiCard('UPCOMING', '$upcomingEvents', 'Planned Activities', PdfColors.purple900, PdfColors.purple50),
                pw.SizedBox(width: 8),
                _buildKpiCard('COMPLETED', '$completedEvents', 'Successfully Executed', PdfColors.green900, PdfColors.green50),
                pw.SizedBox(width: 8),
                _buildKpiCard('TOTAL RSVPS', '$totalRsvps', 'Constituent Responses', PdfColors.amber900, PdfColors.amber50),
                pw.SizedBox(width: 8),
                _buildKpiCard('ATTENDANCE RATE', '${overallGoingRate.toStringAsFixed(0)}%', 'Confirmed Attendees', PdfColors.cyan900, PdfColors.cyan50),
              ],
            ),

            pw.SizedBox(height: 14),

            // Table of Events
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(25),  // Sr
                1: pw.FlexColumnWidth(1.4), // Date & Time
                2: pw.FlexColumnWidth(2.8), // Title & Description
                3: pw.FlexColumnWidth(1.2), // Type & Area
                4: pw.FlexColumnWidth(2.2), // Location / Venue
                5: pw.FlexColumnWidth(1.3), // Target Audience
                6: pw.FlexColumnWidth(1.4), // RSVPs
                7: pw.FixedColumnWidth(55), // Status
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeaderCell('#'),
                    _tableHeaderCell('Date & Time'),
                    _tableHeaderCell('Event Title & Purpose'),
                    _tableHeaderCell('Type & Area'),
                    _tableHeaderCell('Venue / Location'),
                    _tableHeaderCell('Target Audience'),
                    _tableHeaderCell('RSVPs (Going/Total)'),
                    _tableHeaderCell('Status'),
                  ],
                ),
                ...events.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final event = entry.value;
                  final bg = entry.key % 2 == 0 ? PdfColors.white : PdfColors.grey100;
                  final dateFormatted = DateFormat('dd MMM yyyy').format(event.eventDate);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _tableDataCell('$idx', align: pw.TextAlign.center),
                      _tableDataCell('$dateFormatted\n${event.eventTime}', isBold: true),
                      _tableDataCell('${event.titleMr}\n(${event.title})'),
                      _tableDataCell('${event.type.titleMr}\nArea: ${event.area}'),
                      _tableDataCell(event.locationMr.isNotEmpty ? event.locationMr : event.location),
                      _tableDataCell(event.targetAudience),
                      _tableDataCell('${event.goingCount} Going / ${event.totalRsvps} Total\n(${event.maybeCount} Maybe)', isBold: true),
                      _tableStatusCell(event.status),
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
      name: 'Prabhag_12_Events_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildKpiCard(String title, String value, String subtitle, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 7.5, color: textColor, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textColor)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableDataCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _tableStatusCell(String status) {
    PdfColor color = PdfColors.blue800;
    PdfColor bg = PdfColors.blue50;
    String label = status;

    if (status.toLowerCase() == 'completed') {
      color = PdfColors.green800;
      bg = PdfColors.green50;
      label = 'Completed';
    } else if (status.toLowerCase() == 'cancelled') {
      color = PdfColors.red800;
      bg = PdfColors.red50;
      label = 'Cancelled';
    } else {
      color = PdfColors.purple800;
      bg = PdfColors.purple50;
      label = 'Planned';
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: bg,
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border.all(color: color, width: 0.5),
          ),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }
}

