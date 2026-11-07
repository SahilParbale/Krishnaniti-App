
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/voter_model.dart';

class VoterSlipGenerator {
  VoterSlipGenerator._();

  /// Generate and print single official voter information slip
  static Future<void> printVoterSlip(VoterModel voter) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - GENERAL ELECTION',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'OFFICIAL VOTER INFORMATION SLIP',
                        style: pw.TextStyle(
                          color: PdfColors.amber200,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        '214 - Kasba Peth Assembly Constituency | Ward No. 12',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // Serial & Part Number Highlight Box
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Serial No. in Electoral Roll',
                                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            pw.Text('#${voter.serialNo ?? "-"}',
                                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Booth / Part No.',
                                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            pw.Text(voter.booth,
                                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),

                // Voter Data Grid
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(5),
                    },
                    children: [
                      _buildTableRow('Voter Full Name', voter.displayName),
                      _buildTableRow('English Name', voter.nameEnglish),
                      _buildTableRow('EPIC No.', voter.epicNo),
                      _buildTableRow('Age / Gender', '${voter.age} Yrs / ${voter.gender}'),
                      _buildTableRow('House No.', voter.houseNo != null ? '#${voter.houseNo}' : '-'),
                      _buildTableRow('Residential Address', voter.address),
                      _buildTableRow('Mobile Number', voter.mobile != null ? '+91 ${voter.mobile}' : 'Not Registered'),
                      _buildTableRow('Polling Station', voter.displayPollingStation),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // Important Note Box
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    border: pw.Border.all(color: PdfColors.amber300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Important Guidelines:',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '1. This slip is for finding polling station and serial number. Carrying voter ID (EPIC) or Aadhaar is required for voting.\n'
                        '2. Voting Hours: 7:00 AM to 6:00 PM.',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Nagarsevak Election Assistance Portal â€¢ Ward 12',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                    pw.Text('Generated: $nowStr',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Voter_Slip_${voter.epicNo.replaceAll('/', '_')}.pdf',
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black)),
        ),
      ],
    );
  }

  /// Generate and download complete filtered voter list in landscape A4
  static Future<void> downloadVotersListReport({
    required List<VoterModel> voters,
    String? currentFilterSummary,
    int totalCount = 42560,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
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
                        'PUNE MUNICIPAL CORPORATION - ELECTORAL SERVICES & PULSE CELL',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        'VOTER SEARCH DIRECTORY & ELECTORAL ROLL',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                      pw.Text(
                        'Prabhag No. 12 (Kasba Peth - Shaniwar Peth - Raviwar Peth)',
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
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Report Date: $nowStr', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              if (currentFilterSummary != null && currentFilterSummary.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('Applied Filters: $currentFilterSummary',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue700)),
              ],
              pw.Divider(color: PdfColors.blue900, thickness: 1.2),
              pw.SizedBox(height: 4),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildKpiItem('Total Ward Roll', NumberFormat('#,##,###').format(totalCount)),
                  _buildKpiItem('Results Shown', '${voters.length}'),
                  _buildKpiItem('Favourable Voters', '${voters.where((v) => v.favour == "Favourable").length}'),
                  _buildKpiItem('Neutral Voters', '${voters.where((v) => v.favour == "Neutral").length}'),
                  _buildKpiItem('Against Voters', '${voters.where((v) => v.favour == "Against").length}'),
                ],
              ),
            ),

            // Table of Voters
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26), // Sr.
                1: const pw.FlexColumnWidth(3.0), // Name
                2: const pw.FlexColumnWidth(1.8), // EPIC
                3: const pw.FixedColumnWidth(44), // Age/Sex
                4: const pw.FlexColumnWidth(3.0), // Address
                5: const pw.FlexColumnWidth(1.6), // Booth
                6: const pw.FlexColumnWidth(1.5), // Mobile
                7: const pw.FlexColumnWidth(1.2), // Favour
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _buildHeaderCell('#'),
                    _buildHeaderCell('Voter Name'),
                    _buildHeaderCell('EPIC No.'),
                    _buildHeaderCell('Age / Gender'),
                    _buildHeaderCell('Residential Address'),
                    _buildHeaderCell('Booth / Part'),
                    _buildHeaderCell('Mobile'),
                    _buildHeaderCell('Political Stance'),
                  ],
                ),
                ...voters.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final v = entry.value;
                  final isEven = idx % 2 == 0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey50),
                    children: [
                      _buildCell('${v.serialNo ?? (idx + 1)}', alignCenter: true),
                      _buildCell(v.displayName, isBold: true),
                      _buildCell(v.epicNo),
                      _buildCell('${v.age} / ${v.gender}', alignCenter: true),
                      _buildCell('${v.houseNo != null ? "#${v.houseNo}, " : ""}${v.address}'),
                      _buildCell(v.booth),
                      _buildCell(v.mobile != null ? '+91 ${v.mobile}' : '-'),
                      _buildCell(v.favourLabelMarathi,
                          textColor: v.favour == 'Favourable'
                              ? PdfColors.green800
                              : (v.favour == 'Against' ? PdfColors.red800 : PdfColors.blue800),
                          isBold: true),
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
                pw.Text('Nagarsevak Election Management Suite â€¢ Confidential Ward Roll Document',
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
      name: 'Voter_Directory_Prabhag12.pdf',
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
          fontSize: 8,
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

