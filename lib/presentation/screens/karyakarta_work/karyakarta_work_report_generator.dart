import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/karyakarta_work_model.dart';

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
    final nowStr = DateFormat('dd/MM/yyyy, hh:mm a').format(now);

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
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - NAGARSEVAK OFFICE PRABHAG 12',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Cadre Work & Workload Performance Report',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0F172A),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Team Category: $activeTabLabel · Prabhag No. 12 (Kasba - Shaniwar - Raviwar - Somwar Peth)',
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
                          color: const PdfColor.fromInt(0xFFEFF6FF),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                        ),
                        child: pw.Text(
                          'Page ${context.pageNumber} of ${context.pagesCount}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: $nowStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'Central Command System',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.blue900, thickness: 1.5),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Cards in a row
            pw.Row(
              children: [
                _buildKpiCard('Total Workload', '$totalLoad', '$totalTasks Tasks · $totalComplaints Complaints', PdfColors.blue50, PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildKpiCard('Pending Workload', '$pendingLoad', 'Needs Attention', PdfColors.amber50, PdfColors.amber800),
                pw.SizedBox(width: 8),
                _buildKpiCard('In Progress', '$inProgressLoad', 'Being Worked On', const PdfColor.fromInt(0xFFEFF6FF), const PdfColor.fromInt(0xFF1D4ED8)),
                pw.SizedBox(width: 8),
                _buildKpiCard('Completed', '$completedLoad', 'Resolved & Closed', const PdfColor.fromInt(0xFFECFDF5), const PdfColor.fromInt(0xFF047857)),
              ],
            ),

            pw.SizedBox(height: 12),

            // Staff Workload Matrix Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26), // Sr No
                1: const pw.FlexColumnWidth(2.6), // Member & Mobile
                2: const pw.FlexColumnWidth(2.0), // Role & Area
                3: const pw.FlexColumnWidth(1.2), // Tasks (P/T)
                4: const pw.FlexColumnWidth(1.2), // Complaints (P/T)
                5: const pw.FlexColumnWidth(1.1), // Pending Load
                6: const pw.FlexColumnWidth(1.0), // Done
                7: const pw.FlexColumnWidth(1.3), // Progress %
                8: const pw.FlexColumnWidth(1.2), // Status
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildCell('Sr.', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Cadre / Staff Member', isHeader: true),
                    _buildCell('Role & Area', isHeader: true),
                    _buildCell('Tasks (P/T)', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Complaints (P/T)', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Pending', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Completed', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Progress %', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Status', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                // Data Rows
                ...staffList.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final member = entry.value;

                  final mTasks = tasks.where((t) => t.assignedStaffId == member.id).toList();
                  final mComplaints = complaints.where((c) => c.assignedTo == member.id).toList();

                  final mT_pending = mTasks.where((t) => t.isPending || t.isInProgress).length;
                  final mC_pending = mComplaints.where((c) => c.isPending || c.isInProgress).length;

                  final totalAssigned = mTasks.length + mComplaints.length;
                  final totalCompleted =
                      mTasks.where((t) => t.isCompleted).length +
                      mComplaints.where((c) => c.isResolved).length;

                  final totalPending = mT_pending + mC_pending;
                  final progressPct = totalAssigned > 0 ? ((totalCompleted / totalAssigned) * 100).round() : 0;

                  final isEven = entry.key % 2 == 0;
                  final rowBg = isEven ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFC);

                  String perfStatus = 'Active';
                  PdfColor statusColor = PdfColors.blue800;
                  if (progressPct >= 80) {
                    perfStatus = 'Excellent';
                    statusColor = const PdfColor.fromInt(0xFF047857);
                  } else if (totalPending > 3) {
                    perfStatus = 'High Load';
                    statusColor = PdfColors.amber800;
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _buildCell('$index', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              member.displayName,
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                            pw.Text(
                              'Ph: ${member.mobile}',
                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              member.role,
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                            ),
                            if (member.area != null && member.area!.isNotEmpty)
                              pw.Text(
                                'Area: ${member.area}',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                              ),
                          ],
                        ),
                      ),
                      _buildCell('$mT_pending / ${mTasks.length}', align: pw.TextAlign.center, bold: mT_pending > 0),
                      _buildCell('$mC_pending / ${mComplaints.length}', align: pw.TextAlign.center, bold: mC_pending > 0),
                      _buildCell('$totalPending', align: pw.TextAlign.center, bold: true, textColor: totalPending > 0 ? PdfColors.amber800 : PdfColors.grey600),
                      _buildCell('$totalCompleted', align: pw.TextAlign.center, bold: true, textColor: const PdfColor.fromInt(0xFF047857)),
                      _buildCell('$progressPct%', align: pw.TextAlign.center, bold: true),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                        child: pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: statusColor == const PdfColor.fromInt(0xFF047857) ? const PdfColor.fromInt(0xFFECFDF5) : PdfColors.amber50,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Text(
                            perfStatus,
                            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 16),

            // Summary notes & Signature block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  width: 320,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF8FAFC),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Important Instructions:',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '1. Pending tasks and complaints must be addressed within 3 days.\n'
                        '2. Verify resolution directly with citizens after grievance redressal.\n'
                        '3. Submit daily workload report to the office every evening.',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Corporator / Ward Committee Chairman',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(
                      'Ward 12, Pune Municipal Corporation',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
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

  static pw.Widget _buildKpiCard(String title, String value, String sub, PdfColor bg, PdfColor textColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: textColor),
            ),
            pw.SizedBox(height: 1),
            pw.Text(sub, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7.5,
          fontWeight: (isHeader || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColors.grey800 : PdfColors.grey800),
        ),
      ),
    );
  }
}

