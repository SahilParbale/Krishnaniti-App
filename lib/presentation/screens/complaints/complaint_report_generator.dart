import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/complaint_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

/// Official Complaints Report Generator matching Nagarsevak-Managment (ComplaintReportGenerator.tsx)
class ComplaintReportGenerator {
  ComplaintReportGenerator._();

  /// Generates and prints multi-complaint ledger report matching web ComplaintReportGenerator.tsx
  static Future<void> generateAndPrintReport({
    required List<ComplaintModel> complaints,
    String? categoryFilter,
    String? statusFilter,
    String? areaFilter,
    String title = 'Complaints Report',
    String subtitle = 'Detailed Ward Complaints Register',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final total = complaints.length;

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
            foundLabel: 'Found',
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
                0: pw.FlexColumnWidth(1.5), // Date & Time (15%)
                1: pw.FlexColumnWidth(1.8), // Citizen Info (18%)
                2: pw.FlexColumnWidth(2.2), // Title & Type (22%)
                3: pw.FlexColumnWidth(1.8), // Location / Area (18%)
                4: pw.FlexColumnWidth(1.6), // Staff (16%)
                5: pw.FlexColumnWidth(1.1), // Status (11%)
              },
              headers: [
                'Date & Time',
                'Citizen Info',
                'Title & Type',
                'Location / Area',
                'Staff',
                'Status',
              ],
              data: complaints.map((c) {
                final dateStr = DateFormat('dd/MM/yyyy').format(c.createdAt);
                final timeStr = DateFormat('hh:mm a').format(c.createdAt);

                final citizenName = c.citizenName?.trim().isNotEmpty == true
                    ? c.citizenName!
                    : 'Anonymous';
                final citizenMobile = c.citizenMobile ?? '';
                final citizenInfo = citizenMobile.isNotEmpty
                    ? '$citizenName\n$citizenMobile'
                    : citizenName;

                final typeStr = c.category;
                final titleType = typeStr.isNotEmpty ? '${c.title}\n($typeStr)' : c.title;

                final area = c.area ?? '';
                final location = c.location ?? '';
                final locationArea = area.isNotEmpty && location.isNotEmpty
                    ? '$area\n$location'
                    : (area.isNotEmpty ? area : (location.isNotEmpty ? location : '-'));

                final staff = c.assignedStaffName ?? 'Unassigned';

                return [
                  '$dateStr\n$timeStr',
                  citizenInfo,
                  titleType,
                  locationArea,
                  staff,
                  c.status,
                ];
              }).toList(),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Complaints_Report_${DateFormat('yyyy-MM-dd').format(now)}.pdf',
    );
  }

  /// Generates and prints a single grievance docket (Portrait A4)
  static Future<void> generateAndPrintSingleComplaintDocket(ComplaintModel complaint) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);
    final ticketId = complaint.id.length >= 8
        ? '#TKT-${complaint.id.substring(0, 8).toUpperCase()}'
        : '#${complaint.id}';

    pdf.addPage(
      pw.Page(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Nagarsevak Office Management System',
                          style: const pw.TextStyle(fontSize: 9, color: WebReportTheme.slate500),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'CITIZEN GRIEVANCE DOCKET',
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Public Services Redressal Record',
                          style: const pw.TextStyle(fontSize: 9, color: WebReportTheme.slate500),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: WebReportTheme.brand50,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
                          ),
                          child: pw.Text(
                            ticketId,
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('Date: ${DateFormat('dd MMM yyyy').format(complaint.createdAt)}', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Status Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.slate50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: WebReportTheme.slate200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'STATUS: ${complaint.status.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                    pw.Text(
                      'CATEGORY: ${complaint.category.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Citizen & Grievance Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CITIZEN INFORMATION',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('Name: ${complaint.citizenName ?? "Anonymous"}', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Expanded(
                          child: pw.Text('Mobile: ${complaint.citizenMobile ?? "-"}', style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Location: ${complaint.area ?? ""}, ${complaint.location ?? ""}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Complaint description
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COMPLAINT SUBJECT & DESCRIPTION',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(complaint.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                    pw.SizedBox(height: 4),
                    pw.Text(complaint.description, style: const pw.TextStyle(fontSize: 9, lineSpacing: 2, color: WebReportTheme.slate800)),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: WebReportTheme.slate100, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated by Nagarsevak Management System',
                      style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: WebReportTheme.slate400),
                    ),
                    pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Complaint_Docket_${complaint.id}.pdf',
    );
  }
}
