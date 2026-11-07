import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/newspaper_clipping_model.dart';

class NewspaperReportGenerator {
  NewspaperReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<NewspaperClippingModel> clippings,
    String? sentimentFilter,
    String? newspaperFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalCount = clippings.length;
    final positiveCount = clippings.where((c) => c.isPositive).length;
    final negativeCount = clippings.where((c) => !c.isPositive).length;
    final uniquePapers = clippings.map((c) => c.newspaper).toSet().length;

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
                        'PUNE MUNICIPAL CORPORATION - MEDIA & PUBLIC RELATIONS DEPARTMENT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 (Kasba-Vishrambaug Wada) • Newspaper Clippings & Print Media Coverage Archive',
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
                      pw.SizedBox(height: 2),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
                        ),
                        child: pw.Text(
                          'Category: ${sentimentFilter ?? 'All News'} • $totalCount Records',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
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
                    'Nagarsevak Office Management System • Prabhag 12 • Print Media Monitoring Record',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Strip
            pw.Row(
              children: [
                _buildKpiCard('Total Clippings', '$totalCount', 'Print Media Coverage', PdfColors.blue700, PdfColors.blue50),
                pw.SizedBox(width: 8),
                _buildKpiCard('Positive News', '$positiveCount', '${((positiveCount / (totalCount > 0 ? totalCount : 1)) * 100).toStringAsFixed(0)}% Public Appreciation', PdfColors.green700, PdfColors.green50),
                pw.SizedBox(width: 8),
                _buildKpiCard('Civic Issues / Complaints', '$negativeCount', 'Issues Resolved by PMC', PdfColors.red700, PdfColors.red50),
                pw.SizedBox(width: 8),
                _buildKpiCard('Newspapers Tracked', '$uniquePapers', 'Leading Dailies Covered', PdfColors.purple700, PdfColors.purple50),
              ],
            ),
            pw.SizedBox(height: 12),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),  // Sr
                1: const pw.FixedColumnWidth(60),  // Date
                2: const pw.FixedColumnWidth(90),  // Newspaper & Edition
                3: const pw.FlexColumnWidth(3.2), // Headline & Summary
                4: const pw.FixedColumnWidth(65),  // Type / Sentiment
                5: const pw.FlexColumnWidth(2.6), // Action Taken
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeaderCell('#'),
                    _tableHeaderCell('Date'),
                    _tableHeaderCell('Newspaper & Page'),
                    _tableHeaderCell('News Headline & Coverage Summary'),
                    _tableHeaderCell('Type'),
                    _tableHeaderCell('Civic Action Taken'),
                  ],
                ),
                // Rows
                ...clippings.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final c = entry.value;
                  final isEven = idx % 2 == 0;
                  final rowBg = isEven ? PdfColors.grey50 : PdfColors.white;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _tableDataCell('$idx', align: pw.TextAlign.center),
                      _tableDataCell(c.date, align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(c.newspaper, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.SizedBox(height: 2),
                            pw.Text(c.pageNumber ?? 'Page 3', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                            if (c.journalistName != null) ...[
                              pw.SizedBox(height: 1),
                              pw.Text(c.journalistName!, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                            ],
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(c.title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            pw.SizedBox(height: 2),
                            pw.Text(c.description, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      _tableSentimentCell(c.isPositive),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: pw.Text(
                          c.actionTaken ?? 'Immediate field inspection and redressal completed with ward authorities.',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 18),

            // Official Signature Strip
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Report Compiled By: ___________________________', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('Media & Public Relations Coordinator • Ward 12', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Verified by: ___________________________', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('Nagarsevak / Municipal Corporator • Prabhag 12', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
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
      name: 'Prabhag_12_Newspaper_Clippings_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildKpiCard(String title, String value, String subtitle, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 7.5, color: textColor, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textColor)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableDataCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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

  static pw.Widget _tableSentimentCell(bool isPositive) {
    final color = isPositive ? PdfColors.green800 : PdfColors.red800;
    final bg = isPositive ? PdfColors.green50 : PdfColors.red50;
    final text = isPositive ? 'Positive' : 'Critical Issue';

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: bg,
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border.all(color: color, width: 0.5),
          ),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }
}

