import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/event_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class EventReportGenerator {
  EventReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<EventModel> events,
    String? areaFilter,
    String? typeFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final totalEvents = events.length;
    final upcomingEvents = events.where((e) => e.isUpcoming).length;
    final completedEvents = events.where((e) => e.isCompleted).length;
    final totalRsvps = events.fold<int>(0, (sum, e) => sum + e.totalRsvps);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Events & Programs (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Events & Community Programs',
              subtitle: 'Public Events & Community Engagement Directory',
              dateFormatted: nowStr,
              totalCount: totalEvents,
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
                  _buildSummaryItem('Total Events', '$totalEvents'),
                  _buildSummaryItem('Upcoming', '$upcomingEvents', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Completed', '$completedEvents', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Total RSVPs', '$totalRsvps', highlightColor: WebReportTheme.slate700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (events.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No public events or programs found.',
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
                  1: pw.FlexColumnWidth(2.0),
                  2: pw.FlexColumnWidth(3.2),
                  3: pw.FlexColumnWidth(2.6),
                  4: pw.FlexColumnWidth(1.8),
                },
                headers: const [
                  '#',
                  'Date & Time',
                  'Event Title & Type',
                  'Location & Area',
                  'Audience',
                ],
                data: events.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final event = entry.value;
                  final timeStr = event.eventTime.isNotEmpty ? '\n${event.eventTime}' : '';
                  final typeStr = '\nType: ${event.type.id}';
                  final locStr = event.location.isNotEmpty ? '\n${event.location}' : '';
                  final audienceStr = event.targetAudience.isNotEmpty ? event.targetAudience : 'All Citizens';

                  return [
                    '$idx',
                    '${event.formattedDate}$timeStr',
                    '${event.title}$typeStr',
                    '${event.area}$locStr',
                    audienceStr,
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Events_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Events & Programs',
        subtitle: 'Public Events & Community Engagement Directory',
        fileName: fileName,
        onBuildPdf: () async => pdf.save(),
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '$fileName.pdf',
      );
    }
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
