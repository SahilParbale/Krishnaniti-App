import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/sadasya_model.dart';

class SadasyaReportGenerator {
  SadasyaReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<SadasyaModel> members,
    String? areaFilter,
    String? typeFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalCount = members.length;
    final voterCount = members.where((m) => m.isVoter).length;
    final nonVoterCount = totalCount - voterCount;
    final areasCount = members.map((m) => m.area).where((a) => a != null && a.isNotEmpty).toSet().length;

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
                        'PUNE MUNICIPAL CORPORATION - NAGARSEVAK PUBLIC OFFICE',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'पक्ष सदस्य (सदस्य नोंदणी) अधिकृत अहवाल • प्रभागातील नोंदणीकृत कार्यकर्त्यांची यादी',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.cyan900,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'Prabhag Ward 12 (Kasba-Vishrambaug Wada) • Registered Party Members & Cadre Directory',
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
                      pw.Text(
                        'Generated: $nowStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                        ),
                        child: pw.Text(
                          'OFFICIAL CADRE REGISTER',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Nagarsevak Mobile Suite • Party Cadre & Volunteer Database',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Row(
              children: [
                _buildKpiCard(
                  'एकूण सदस्य (TOTAL CADRE)',
                  '$totalCount',
                  'नोंदणीकृत पक्ष कार्यकर्ते',
                  PdfColors.blue800,
                  PdfColors.blue50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'मतदार सदस्य (VOTERS)',
                  '$voterCount',
                  'प्रभागातील मतदार नोंद असलेले',
                  PdfColors.green800,
                  PdfColors.green50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'इतर सदस्य (MEMBERS)',
                  '$nonVoterCount',
                  'थेट पक्ष सदस्य नोंदणी',
                  PdfColors.purple800,
                  PdfColors.purple50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'सक्रिय परिसर (AREAS)',
                  '$areasCount',
                  'शनिवार, कसबा, नारायण पेठ इ.',
                  PdfColors.cyan800,
                  PdfColors.cyan50,
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Table Title
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'पक्ष कार्यकर्ते व सदस्य तपशील सूची (PARTY MEMBERS & CADRE DIRECTORY)',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                  ),
                  pw.Text(
                    'नोंद संख्या: ${members.length}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),

            // Data Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  children: [
                    _tableHeaderCell('अ.क्र.', flex: 1),
                    _tableHeaderCell('कार्यकर्त्याचे नाव', flex: 3),
                    _tableHeaderCell('मोबाईल क्रमांक', flex: 2),
                    _tableHeaderCell('परिसर / वॉर्ड', flex: 2),
                    _tableHeaderCell('पत्ता / निवासस्थान', flex: 3),
                    _tableHeaderCell('प्रकार / जबाबदारी', flex: 2),
                    _tableHeaderCell('नोंदणी दिनांक', flex: 2),
                  ],
                ),
                // Data Rows
                ...members.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final isEven = entry.key % 2 == 0;
                  final rowBg = isEven ? PdfColors.white : PdfColors.grey50;
                  final dateFormatted = DateFormat('dd/MM/yyyy').format(item.registeredAt);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _tableDataCell('$idx', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.displayName,
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                            ),
                            if (item.nameEnglish != null && item.nameEnglish != item.displayName)
                              pw.Text(
                                item.nameEnglish!,
                                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                              ),
                          ],
                        ),
                      ),
                      _tableDataCell(item.mobile, align: pw.TextAlign.center),
                      _tableDataCell(item.area ?? item.ward ?? '-'),
                      _tableDataCell(item.displayAddress),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                              decoration: pw.BoxDecoration(
                                color: item.isVoter ? PdfColors.green50 : PdfColors.blue50,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                              child: pw.Text(
                                item.isVoter ? 'मतदार सदस्य' : 'पक्ष सदस्य',
                                style: pw.TextStyle(
                                  fontSize: 6.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: item.isVoter ? PdfColors.green800 : PdfColors.blue800,
                                ),
                              ),
                            ),
                            if (item.role != null) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                item.role!,
                                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _tableDataCell(dateFormatted, align: pw.TextAlign.center),
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
      name: 'Party_Members_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildKpiCard(
      String title, String value, String subtitle, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 7, color: textColor, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text, {int flex = 1}) {
    return pw.Container(
      color: PdfColors.blueGrey800,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableDataCell(String text,
      {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }
}

