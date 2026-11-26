import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/diary_task_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Tasks & Daily Work Diary Report Generator matching Nagarsevak-Managment
/// (TaskReportGenerator.tsx).
class DiaryReportGenerator {
  DiaryReportGenerator._();

  static Future<void> generateAndPrintTasksReport({
    BuildContext? context,
    required List<DiaryTaskModel> tasks,
    String? filterTitle,
    String title = 'Daily Work Diary & Tasks Report',
    String subtitle = 'Executive Itinerary & Scheduled Field Tasks',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final total = tasks.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: title,
            );
          }
          return WebReportTheme.buildHeader(
            title: title,
            subtitle: subtitle,
            dateFormatted: formattedDate,
            totalCount: total,
            foundLabel: 'Total Tasks',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              border: WebReportTheme.tableBorder,
              headerStyle: WebReportTheme.tableHeaderStyle,
              headerDecoration: WebReportTheme.tableHeaderDecoration,
              headerHeight: 22,
              cellHeight: 20,
              cellStyle: WebReportTheme.tableCellStyle,
              headerCount: 1,
              oddRowDecoration: WebReportTheme.oddRowDecoration,
              columnWidths: const {
                0: pw.FlexColumnWidth(0.6), // #
                1: pw.FlexColumnWidth(2.8), // Task Title & Description
                2: pw.FlexColumnWidth(1.2), // Priority
                3: pw.FlexColumnWidth(1.6), // Due Date & Time
                4: pw.FlexColumnWidth(2.2), // Location & Contact
                5: pw.FlexColumnWidth(1.2), // Status
              },
              headers: [
                '#',
                'Task Title & Details',
                'Priority',
                'Due Date / Time',
                'Location / Contact',
                'Status',
              ],
              data: List.generate(tasks.length, (index) {
                final t = tasks[index];
                final dateStr = t.dueDate != null ? DateFormat('dd/MM/yyyy').format(t.dueDate!) : '-';
                final timeStr = t.dueTime ?? '';
                final due = timeStr.isNotEmpty ? '$dateStr\n$timeStr' : dateStr;

                final desc = (t.description != null && t.description!.isNotEmpty)
                    ? '${t.title}\n${t.description!}'
                    : t.title;

                final loc = t.address != null && t.address!.isNotEmpty
                    ? t.address!
                    : (t.officeName ?? '-');
                final meet = t.meetPersonName != null && t.meetPersonName!.isNotEmpty
                    ? '\nMeet: ${t.meetPersonName}'
                    : '';

                return [
                  '${index + 1}',
                  desc,
                  t.priority.toUpperCase(),
                  due,
                  '$loc$meet',
                  t.status.toUpperCase(),
                ];
              }),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    final fileName = 'Task_Report_${DateFormat('yyyy-MM-dd').format(now)}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: title,
        subtitle: subtitle,
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

  /// Generates a single Task / Diary docket
  static Future<void> generateAndPrintSingleTask(
    DiaryTaskModel task, {
    BuildContext? context,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final taskDueDateStr = task.dueDate != null
        ? DateFormat('dd/MM/yyyy').format(task.dueDate!)
        : 'Not scheduled';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: 'Task Docket • ${task.id}',
            );
          }
          return WebReportTheme.buildHeader(
            title: 'Task / Diary Docket',
            subtitle: 'Office of Nagarsevak • Executive Schedule & Action Item',
            dateFormatted: formattedDate,
            totalCount: 1,
            foundLabel: 'Task ID: ${task.id}',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            // Status and priority strip
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const pw.BoxDecoration(
                color: WebReportTheme.slate50,
                border: pw.Border(
                  left: pw.BorderSide(color: WebReportTheme.brand600, width: 3),
                  top: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                  right: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                  bottom: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'STATUS: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate700,
                        ),
                      ),
                      pw.Text(
                        task.status.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.brand700,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        'PRIORITY: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate700,
                        ),
                      ),
                      pw.Text(
                        task.priority.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: task.priority.toLowerCase() == 'urgent' || task.priority.toLowerCase() == 'high'
                              ? PdfColors.red800
                              : WebReportTheme.slate800,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        'ASSIGNED TO: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate700,
                        ),
                      ),
                      pw.Text(
                        (task.assignedStaffName ?? 'Unassigned').toUpperCase(),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: WebReportTheme.slate800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Task Title & Description Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TASK TITLE',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.slate500,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    task.title,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.slate900,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'DESCRIPTION / NOTES',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.slate500,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      task.description!,
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        color: WebReportTheme.slate800,
                        lineSpacing: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Details Grid
            pw.Table(
              border: WebReportTheme.tableBorder,
              children: [
                _buildTableRow('Due Date', taskDueDateStr, 'Due Time', task.dueTime ?? '-'),
                _buildTableRow('Location / Address', task.address ?? '-', 'Office', task.officeName ?? '-'),
                _buildTableRow('Person to Meet', task.meetPersonName ?? '-', 'Assigned Staff', task.assignedStaffName ?? '-'),
              ],
            ),
          ];
        },
      ),
    );

    final fileName = 'Task_Docket_${task.id}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Task Docket',
        subtitle: 'ID: ${task.id}',
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

  static pw.TableRow _buildTableRow(String l1, String v1, String l2, String v2) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: WebReportTheme.slate50,
          child: pw.Text(
            l1,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: WebReportTheme.slate700,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            v1,
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: WebReportTheme.slate800,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: WebReportTheme.slate50,
          child: pw.Text(
            l2,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: WebReportTheme.slate700,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            v2,
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: WebReportTheme.slate800,
            ),
          ),
        ),
      ],
    );
  }
}
