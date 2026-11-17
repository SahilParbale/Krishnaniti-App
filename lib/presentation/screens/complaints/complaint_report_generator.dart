import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/complaint_model.dart';

/// Official Complaints & Grievances Report Generator matching Nagarsevak-Managment
/// (ComplaintReportGenerator.tsx).
class ComplaintReportGenerator {
  ComplaintReportGenerator._();

  /// Generates and prints multi-complaint ledger report (Landscape A4)
  static Future<void> generateAndPrintReport({
    required List<ComplaintModel> complaints,
    String? categoryFilter,
    String? statusFilter,
    String? areaFilter,
    String title = 'Citizen Grievance & Complaints Register',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);

    final total = complaints.length;
    final resolved = complaints.where((c) => c.status.toLowerCase() == 'resolved' || c.status.toLowerCase() == 'closed').length;
    final inProgress = complaints.where((c) => c.status.toLowerCase() == 'inprogress').length;
    final pending = complaints.where((c) => c.status.toLowerCase() == 'pending' || c.status.toLowerCase() == 'assigned').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Official PMC & Office Header
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
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0F172A),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Nagarsevak Central Secretariat • Citizen Redressal & Field Audit System',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
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
                          'CONFIDENTIAL • WARD AUDIT',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: $formattedDate',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      if (areaFilter != null && areaFilter != 'All')
                        pw.Text(
                          'Area: $areaFilter',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // KPI Summary Statistics
            pw.Row(
              children: [
                _buildPdfKpiCard('Total Logged', '$total', PdfColors.blue50, PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Resolved / Closed', '$resolved', PdfColors.green50, PdfColors.green900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Work In Progress', '$inProgress', PdfColors.amber50, PdfColors.amber900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Pending Action', '$pending', PdfColors.red50, PdfColors.red900),
              ],
            ),
            pw.SizedBox(height: 14),

            // Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0284C7)),
              headerHeight: 24,
              cellHeight: 22,
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey900),
              headers: [
                '#',
                'Ticket ID',
                'Date',
                'Citizen Name & Mobile',
                'Category & Subject',
                'Area / Location',
                'Assigned Staff',
                'Status',
              ],
              columnWidths: const {
                0: pw.FixedColumnWidth(20),
                1: pw.FixedColumnWidth(55),
                2: pw.FixedColumnWidth(48),
                3: pw.FixedColumnWidth(95),
                4: pw.FlexColumnWidth(2.2),
                5: pw.FlexColumnWidth(1.4),
                6: pw.FixedColumnWidth(80),
                7: pw.FixedColumnWidth(55),
              },
              data: List.generate(complaints.length, (index) {
                final c = complaints[index];
                final ticketId = c.id.length >= 8 ? '#TKT-${c.id.substring(0, 8).toUpperCase()}' : '#${c.id}';
                final dateStr = DateFormat('dd/MM/yyyy').format(c.createdAt);
                final citizenInfo = '${c.citizenName ?? "Anonymous"}\n${c.citizenMobile ?? "-"}';
                final subject = '${c.category}\n${c.title}';
                final location = '${c.area ?? "-"}\n${c.location ?? ""}';
                final staff = c.assignedStaffName ?? 'Unassigned';
                return [
                  '${index + 1}',
                  ticketId,
                  dateStr,
                  citizenInfo,
                  subject,
                  location,
                  staff,
                  c.status,
                ];
              }),
            ),
            pw.SizedBox(height: 18),

            // Footer Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Note: Official computerized report of Nagarsevak Citizen Redressal Cell.',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Authorized Signatory / Ward Officer',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
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
      name: 'Complaints_Register_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  /// Generates and prints a single grievance official action-taken docket (Portrait A4)
  static Future<void> generateAndPrintSingleComplaintDocket(ComplaintModel complaint) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);
    final ticketId = complaint.id.length >= 8
        ? '#TKT-${complaint.id.substring(0, 8).toUpperCase()}'
        : '#${complaint.id}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PUNE MUNICIPAL CORPORATION - PRABHAG 12',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'OFFICIAL CITIZEN GRIEVANCE DOCKET',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A)),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Nagarsevak Office Public Services Redressal Record',
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
                            border: pw.Border.all(color: PdfColors.blue300),
                          ),
                          child: pw.Text(
                            ticketId,
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('Date: ${DateFormat('dd MMM yyyy').format(complaint.createdAt)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
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
                  color: complaint.status.toLowerCase() == 'resolved' ? PdfColors.green50 : PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color: complaint.status.toLowerCase() == 'resolved' ? PdfColors.green300 : PdfColors.amber300,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'STATUS: ${complaint.status.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: complaint.status.toLowerCase() == 'resolved' ? PdfColors.green900 : PdfColors.amber900,
                      ),
                    ),
                    pw.Text(
                      'Category: ${complaint.category}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Citizen Information Box
              pw.Text('CITIZEN & LOCATION DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Citizen Name:', complaint.citizenName ?? 'Anonymous Citizen'),
                    pw.SizedBox(height: 4),
                    _buildRow('Contact Mobile:', complaint.citizenMobile ?? 'N/A'),
                    pw.SizedBox(height: 4),
                    _buildRow('Ward / Area:', '${complaint.ward ?? "Prabhag 12"} • ${complaint.area ?? "General Area"}'),
                    if (complaint.location != null && complaint.location!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      _buildRow('Specific Landmark:', complaint.location!),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Grievance Details Box
              pw.Text('GRIEVANCE DESCRIPTION & SUBJECT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(complaint.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                    pw.SizedBox(height: 6),
                    pw.Text(complaint.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800, lineSpacing: 1.3)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Staff Assignment & Progress Updates
              pw.Text('OFFICE DELEGATION & ACTION TAKEN', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Assigned Staff / Officer:', complaint.assignedStaffName ?? 'Unassigned'),
                    if (complaint.assignedStaffMobile != null) ...[
                      pw.SizedBox(height: 4),
                      _buildRow('Staff Contact:', complaint.assignedStaffMobile!),
                    ],
                    if (complaint.resolutionDetails != null) ...[
                      pw.SizedBox(height: 6),
                      _buildRow('Resolution Note:', complaint.resolutionDetails!.note),
                    ],
                  ],
                ),
              ),
              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Printed: $formattedDate', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                      pw.Text('Record generated via Krishnaniti Mobile Console', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 3),
                      pw.Text('Office Seal & Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
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
      name: 'Complaint_Docket_${complaint.id}.pdf',
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 130,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
        ),
      ],
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
