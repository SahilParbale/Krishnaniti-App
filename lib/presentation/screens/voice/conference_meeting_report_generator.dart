import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';
import 'conference_room_screen.dart';

class ConferenceMeetingReportGenerator {
  ConferenceMeetingReportGenerator._();

  static Future<void> generateAndPrintMeetingReport({
    BuildContext? context,
    required List<ConferenceMeetingModel> meetings,
    String? statusFilter,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final total = meetings.length;
    final scheduled = meetings.where((m) => m.status.toLowerCase() == 'scheduled').length;
    final active = meetings.where((m) => m.status.toLowerCase() == 'active').length;
    final ended = meetings.where((m) => m.status.toLowerCase() == 'ended').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Virtual Meetings Report (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Virtual Meetings Report',
              subtitle: 'Online Consultations & Deliberation Records',
              dateFormatted: formattedDate,
              totalCount: total,
            ),
            pw.SizedBox(height: 12),

            // Statistics Row matching web
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Meetings', '$total'),
                  _buildSummaryItem('Scheduled', '$scheduled', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Active', '$active', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Ended', '$ended', highlightColor: WebReportTheme.slate600),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (meetings.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No conference meetings found.',
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerCount: 1,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(2.0),
                  2: pw.FlexColumnWidth(3.0),
                  3: pw.FlexColumnWidth(1.2),
                  4: pw.FlexColumnWidth(1.6),
                  5: pw.FlexColumnWidth(2.0),
                },
                headers: const [
                  '#',
                  'Scheduled Date & Time',
                  'Title / Purpose',
                  'Status',
                  'Invited',
                  'Conference Link',
                ],
                data: List.generate(meetings.length, (index) {
                  final m = meetings[index];
                  final dateStr = DateFormat('dd/MM/yyyy, hh:mm a').format(m.scheduledAt);
                  final notesPart = m.notes != null && m.notes!.isNotEmpty ? '\n${m.notes}' : '';

                  return [
                    '${index + 1}',
                    dateStr,
                    '${m.title}$notesPart',
                    m.status.toUpperCase(),
                    '${m.invitedCount}',
                    m.meetLink,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Conference_Meetings_Report_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Virtual Meetings Report',
        subtitle: 'Online Consultations & Deliberation Records',
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
