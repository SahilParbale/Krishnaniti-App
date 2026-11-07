import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/team_model.dart';

class TeamReportGenerator {
  TeamReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<TeamMemberModel> staffList,
    String activeCategory = 'All',
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final officeCount = staffList.where((s) => s.category == 'Office').length;
    final partyCount = staffList.where((s) => s.category == 'Party').length;
    final coopCount = staffList.where((s) => s.category == 'Cooperative').length;

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
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - NAGARSEVAK OFFICE PRABHAG 12',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'MY TEAM & STAFF DIRECTORY REPORT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.Text(
                        'Prabhag No. 12 (Kasba Peth - Shaniwar Peth - Raviwar Peth - Somwar Peth)',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          'Page ${context.pageNumber} of ${context.pagesCount}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Date: $nowStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.blue900, thickness: 1.2),
              pw.SizedBox(height: 4),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Strip
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildKpiItem('Total Team', '${staffList.length}'),
                  _buildKpiItem('Office Team', '$officeCount'),
                  _buildKpiItem('Party Cadre', '$partyCount'),
                  _buildKpiItem('Municipal & Coop', '$coopCount'),
                  _buildKpiItem('Active Filter', activeCategory),
                ],
              ),
            ),

            // Team Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(24), // #
                1: const pw.FlexColumnWidth(2.6), // Name
                2: const pw.FlexColumnWidth(1.8), // Role
                3: const pw.FlexColumnWidth(1.4), // Category
                4: const pw.FlexColumnWidth(1.8), // Wing/Society
                5: const pw.FlexColumnWidth(1.4), // Area
                6: const pw.FlexColumnWidth(1.6), // Mobile
                7: const pw.FlexColumnWidth(2.4), // Keywords
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _buildHeaderCell('#'),
                    _buildHeaderCell('Staff / Cadre Name'),
                    _buildHeaderCell('Role / Designation'),
                    _buildHeaderCell('Category'),
                    _buildHeaderCell('Wing / Organization'),
                    _buildHeaderCell('Work Area'),
                    _buildHeaderCell('Mobile Number'),
                    _buildHeaderCell('Auto-Assign Keywords'),
                  ],
                ),
                ...staffList.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final isEven = idx % 2 == 0;

                  String subInfo = '-';
                  if (s.category == 'Party' && s.partyWing != null) {
                    subInfo = '${s.partyWing!} ${s.pad != null ? "(${s.pad})" : ""}';
                  } else if (s.category == 'Cooperative' && s.societyName != null) {
                    subInfo = s.societyName!;
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey50),
                    children: [
                      _buildCell('${idx + 1}', alignCenter: true),
                      _buildCell(s.displayName, isBold: true),
                      _buildCell(s.roleLabelMarathi),
                      _buildCell(s.categoryLabelMarathi,
                          textColor: s.category == 'Office'
                              ? PdfColors.blue800
                              : (s.category == 'Party' ? PdfColors.orange800 : PdfColors.purple800)),
                      _buildCell(subInfo),
                      _buildCell(s.area ?? 'Ward 12'),
                      _buildCell('+91 ${s.mobile}'),
                      _buildCell(s.keywords.isNotEmpty ? s.keywords.join(', ') : 'All Tasks'),
                    ],
                  );
                }),
              ],
            ),
          ];
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
                pw.Text('Nagarsevak Team Management Suite â€¢ Confidential Official Roster',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                pw.Text('Pune Municipal Corporation â€¢ Prabhag 12',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'My_Team_Directory_Prabhag12.pdf',
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isBold = false,
    bool alignCenter = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7.8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildKpiItem(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 1),
        pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
      ],
    );
  }
}

