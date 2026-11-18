import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/karyakarta_work_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class KaryakartaWorkReportGenerator {
  KaryakartaWorkReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<KaryakartaWorkStaff> staffList,
    required List<KaryakartaWorkTask> tasks,
    required List<KaryakartaWorkComplaint> complaints,
    required String activeTabLabel,
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final staffIds = staffList.map((s) => s.id).toSet();
    final tabTasks = tasks.where((t) => t.assignedStaffId != null && staffIds.contains(t.assignedStaffId)).toList();
    final tabComplaints = complaints.where((c) => c.assignedTo != null && staffIds.contains(c.assignedTo)).toList();

    final totalTasks = tabTasks.length;
    final completedTasks = tabTasks.where((t) => t.isCompleted).length;
    final inProgressTasks = tabTasks.where((t) => t.isInProgress).length;
    final pendingTasks = tabTasks.where((t) => t.isPending).length;

    final totalComplaints = tabComplaints.length;
    final resolvedComplaints = tabComplaints.where((c) => c.isResolved).length;
    final inProgressComplaints = tabComplaints.where((c) => c.isInProgress).length;
    final pendingComplaints = tabComplaints.where((c) => c.isPending).length;

    final totalLoad = totalTasks + totalComplaints;
    final pendingLoad = pendingTasks + pendingComplaints;
    final inProgressLoad = inProgressTasks + inProgressComplaints;
    final completedLoad = completedTasks + resolvedComplaints;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Team Workload Monitor (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Team Workload Monitor',
              subtitle: 'Department: $activeTabLabel',
              dateFormatted: nowStr,
              totalCount: staffList.length,
              foundLabel: 'Members',
            ),
            pw.SizedBox(height: 12),

            // Summary KPI strip matching web style
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Workload', '$totalLoad'),
                  _buildSummaryItem('Pending', '$pendingLoad', highlightColor: PdfColors.amber800),
                  _buildSummaryItem('In Progress', '$inProgressLoad', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Completed', '$completedLoad', highlightColor: PdfColors.green700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (staffList.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No team members found for the selected category.',
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
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(1.4),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.1),
                  6: pw.FlexColumnWidth(1.1),
                  7: pw.FlexColumnWidth(1.2),
                },
                headers: const [
                  '#',
                  'Member & Mobile',
                  'Role & Area',
                  'Tasks',
                  'Complaints',
                  'Pending',
                  'Done',
                  'Progress',
                ],
                data: staffList.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final member = entry.value;

                  final mTasks = tasks.where((t) => t.assignedStaffId == member.id).toList();
                  final mComplaints = complaints.where((c) => c.assignedTo == member.id).toList();

                  final mTPending = mTasks.where((t) => t.isPending || t.isInProgress).length;
                  final mCPending = mComplaints.where((c) => c.isPending || c.isInProgress).length;

                  final totalAssigned = mTasks.length + mComplaints.length;
                  final totalCompleted =
                      mTasks.where((t) => t.isCompleted).length +
                      mComplaints.where((c) => c.isResolved).length;

                  final totalPending = mTPending + mCPending;
                  final progressPct = totalAssigned > 0 ? ((totalCompleted / totalAssigned) * 100).round() : 0;
                  final phoneStr = member.mobile.isNotEmpty ? '\n${member.mobile}' : '';
                  final areaStr = (member.area != null && member.area!.isNotEmpty) ? '\n${member.area}' : '';

                  return [
                    '$index',
                    '${member.displayName}$phoneStr',
                    '${member.role}$areaStr',
                    '$mTPending / ${mTasks.length}',
                    '$mCPending / ${mComplaints.length}',
                    '$totalPending',
                    '$totalCompleted',
                    '$progressPct%',
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Karyakarta_Workload_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
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
