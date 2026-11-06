import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/diary_task_model.dart';

class DiaryReportGenerator {
  DiaryReportGenerator._();

  static Future<void> generateAndPrintTasksReport({
    required List<DiaryTaskModel> tasks,
    String? filterTitle,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final pending = tasks.where((t) => t.isPending).length;
    final highPriority = tasks.where((t) => t.isHighPriority).length;

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
                        'DIARY - DAILY SCHEDULE & TASK ITINERARY',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 - Nagarsevak Executive Work Diary',
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
                    _buildSummaryPill('Total Items', '$total', PdfColors.blue800),
                    _buildSummaryPill('Pending', '$pending', PdfColors.amber800),
                    _buildSummaryPill('Completed', '$completed', PdfColors.green800),
                    _buildSummaryPill('High Priority', '$highPriority', PdfColors.red800),
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
          if (tasks.isEmpty) {
            return [
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No diary tasks found for the selected view.',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ),
            ];
          }

          final headers = [
            'Sr.',
            'Date & Time',
            'Task Title & Details',
            'Priority',
            'Status',
            'Location / Office',
            'Person to Meet / Assigned',
          ];

          final rows = <List<String>>[];
          for (var i = 0; i < tasks.length; i++) {
            final t = tasks[i];
            final dateStr = t.dueDate != null ? DateFormat('dd/MM/yyyy').format(t.dueDate!) : '-';
            final timeStr = t.dueTime != null && t.dueTime!.isNotEmpty ? ' (${t.formattedTime})' : '';
            final descPart = (t.description != null && t.description!.isNotEmpty) ? '\n${t.description!}' : '';
            final locPart = [t.address, t.officeName].where((s) => s != null && s.isNotEmpty).join(' | ');
            final personPart = [t.meetPersonName, t.assignedStaffName].where((s) => s != null && s.isNotEmpty).join(' / ');

            rows.add([
              '${i + 1}',
              '$dateStr$timeStr',
              '${t.title}$descPart',
              t.priority,
              t.status,
              locPart.isNotEmpty ? locPart : '-',
              personPart.isNotEmpty ? personPart : '-',
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
                1: const pw.FixedColumnWidth(80),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(55),
                4: const pw.FixedColumnWidth(65),
                5: const pw.FixedColumnWidth(110),
                6: const pw.FixedColumnWidth(100),
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Diary_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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

  static Future<void> generateAndPrintSingleTask(DiaryTaskModel task) async {
    final pdf = pw.Document();
    final dateStr = task.dueDate != null ? DateFormat('dd MMMM yyyy').format(task.dueDate!) : 'Not scheduled';

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
                          'DAILY WORK DIARY - TASK SLIP',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Nagarsevak Ward Administrative Office - Official Diary Itinerary',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: task.isCompleted ? PdfColors.green50 : PdfColors.amber50,
                        border: pw.Border.all(
                          color: task.isCompleted ? PdfColors.green300 : PdfColors.amber300,
                        ),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        task.status,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: task.isCompleted ? PdfColors.green900 : PdfColors.amber900,
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
                        _buildFieldCol('Scheduled Date', dateStr),
                        _buildFieldCol('Scheduled Time', task.formattedTime.isNotEmpty ? task.formattedTime : 'Flexible'),
                        _buildFieldCol('Priority', task.priority),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFieldCol('Location / Ward Area', task.address ?? 'Ward 12'),
                        _buildFieldCol('Government Office / Dept', task.officeName ?? 'N/A'),
                        _buildFieldCol('Person to Meet', task.meetPersonName ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Title
              pw.Text(
                'TASK TITLE / PURPOSE',
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
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  task.title,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),

              pw.SizedBox(height: 16),

              // Description
              pw.Text(
                'DETAILED INSTRUCTIONS & NOTES',
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
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  task.description != null && task.description!.isNotEmpty
                      ? task.description!
                      : 'No specific notes recorded.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900, lineSpacing: 1.4),
                ),
              ),

              pw.SizedBox(height: 16),

              // Assigned Staff
              if (task.assignedStaffName != null && task.assignedStaffName!.isNotEmpty) ...[
                pw.Text(
                  'ASSIGNED TO',
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
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    task.assignedStaffName!,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ),
              ],

              pw.Spacer(),

              // Signature Line
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Generated by: Nagarsevak Mobile Office', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Nagarsevak / Authority', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
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
      name: 'Diary_Task_${task.id}.pdf',
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
