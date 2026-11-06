import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/gb_register_entry_model.dart';

class GbRegisterReportGenerator {
  GbRegisterReportGenerator._();

  static Future<void> generateAndPrintGbReport({
    required List<GbRegisterEntryModel> entries,
    String? meetingTypeFilter,
    String? statusFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalCount = entries.length;
    final actionTakenCount = entries.where((e) => e.status.toLowerCase() == 'action taken' || e.status.toLowerCase() == 'sanctioned').length;
    final inDiscussionCount = entries.where((e) => e.status.toLowerCase() == 'in discussion').length;
    final raisedCount = entries.where((e) => e.status.toLowerCase() == 'raised').length;
    final gbCount = entries.where((e) => e.meetingType.toLowerCase() == 'gb' || e.meetingType.toLowerCase() == 'special gb').length;
    final committeeCount = entries.where((e) => e.meetingType.toLowerCase().contains('committee')).length;

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
                        'PUNE MUNICIPAL CORPORATION - GENERAL BODY & COMMITTEE REGISTER (GB नोंदवही)',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Ward 12 - Official Assembly Motions, Starred Questions, Calling Attention & Sanctions Report',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
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
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                      if (meetingTypeFilter != null && meetingTypeFilter != 'All')
                        pw.Text('Meeting: $meetingTypeFilter', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      if (statusFilter != null && statusFilter != 'All')
                        pw.Text('Status: $statusFilter', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blue800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Executive Summary Strip
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _statPill('Total Motions', '$totalCount', PdfColors.blue900),
                    _statPill('Action Taken', '$actionTakenCount', PdfColors.green900),
                    _statPill('In Discussion', '$inDiscussionCount', PdfColors.blue800),
                    _statPill('Under Review / Raised', '$raisedCount', PdfColors.orange900),
                    _statPill('General Body (GB)', '$gbCount', PdfColors.indigo900),
                    _statPill('Committees', '$committeeCount', PdfColors.purple900),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Pune Municipal Corporation - Nagarsevak Ward Administration System | Confidential Assembly Record',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),  // Sr
                1: pw.FixedColumnWidth(55),  // Date
                2: pw.FixedColumnWidth(70),  // Meeting Type
                3: pw.FlexColumnWidth(3.0), // Subject & Details
                4: pw.FlexColumnWidth(1.6), // Department
                5: pw.FlexColumnWidth(1.2), // Area
                6: pw.FixedColumnWidth(70),  // Status
                7: pw.FlexColumnWidth(1.5), // Resolution / Remarks
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _tableHeader('#'),
                    _tableHeader('Date'),
                    _tableHeader('Meeting'),
                    _tableHeader('Subject & Motion Details'),
                    _tableHeader('Department'),
                    _tableHeader('Area'),
                    _tableHeader('Status'),
                    _tableHeader('Resolution / Remarks'),
                  ],
                ),
                ...entries.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          _formatDate(item.meetingDate),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.meetingTypeDisplayEn,
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _getPdfMeetingColor(item.meetingType)),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.subject,
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              item.description,
                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(item.department, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(item.area, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: _getPdfStatusBg(item.status),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(
                            item.statusDisplayEn,
                            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _getPdfStatusColor(item.status)),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (item.resolutionNo != null) ...[
                              pw.Text(
                                item.resolutionNo!,
                                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                              ),
                              pw.SizedBox(height: 2),
                            ],
                            if (item.response != null)
                              pw.Text(
                                item.response!,
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                                maxLines: 2,
                              )
                            else
                              pw.Text('-', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                          ],
                        ),
                      ),
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
      name: 'GB_Register_Dossier_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _statPill(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 1),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  static String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static PdfColor _getPdfMeetingColor(String meetingType) {
    switch (meetingType.toLowerCase()) {
      case 'gb':
      case 'special gb':
        return PdfColors.indigo900;
      case 'standing committee':
      case 'standing':
        return PdfColors.purple900;
      case 'ward committee':
      case 'ward':
        return PdfColors.blue800;
      default:
        return PdfColors.grey800;
    }
  }

  static PdfColor _getPdfStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'action taken':
      case 'sanctioned':
        return PdfColors.green800;
      case 'in discussion':
        return PdfColors.blue800;
      case 'rejected':
        return PdfColors.red800;
      case 'raised':
      default:
        return PdfColors.orange900;
    }
  }

  static PdfColor _getPdfStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'action taken':
      case 'sanctioned':
        return PdfColors.green50;
      case 'in discussion':
        return PdfColors.blue50;
      case 'rejected':
        return PdfColors.red50;
      case 'raised':
      default:
        return PdfColors.yellow50;
    }
  }
}

