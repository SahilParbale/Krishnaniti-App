import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/media_tracking_model.dart';
import '../../../data/models/social_post_model.dart'; // for IntFormatting

class MediaTrackingReportGenerator {
  MediaTrackingReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<MediaTrackingArticleModel> articles,
    String? profileFilter,
    String? sentimentFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalCount = articles.length;
    final positiveCount = articles.where((a) => a.isPositive).length;
    final negativeCount = articles.where((a) => a.isNegative).length;
    final totalReach = articles.fold<int>(0, (acc, a) => acc + a.reachEstimate);
    final positiveRatio = totalCount > 0 ? (positiveCount / totalCount) * 100 : 0.0;

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
                        'PUNE MUNICIPAL CORPORATION - DIGITAL & WEB MEDIA MONITORING CELL',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 (Kasba-Vishrambaug Wada) • Live Online News Portals & Press Mentions Tracker',
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
                          'Profile: ${profileFilter ?? 'All Profiles'} • $totalCount Mentions',
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
                    'Nagarsevak Office Management System • Prabhag 12 • Digital Media Tracking Audit',
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
            // KPI Summary Row
            pw.Row(
              children: [
                _buildKpiCard('Total Mentions (एकूण बातम्या)', '$totalCount', 'Portals & Media Outlets', PdfColors.blue700, PdfColors.blue50),
                pw.SizedBox(width: 8),
                _buildKpiCard('Sentiment Ratio (भावना गुणोत्तर)', '${positiveRatio.toStringAsFixed(1)}%', 'Positive Press Share', PdfColors.green700, PdfColors.green50),
                pw.SizedBox(width: 8),
                _buildKpiCard('Critical Issues (दखलपात्र बातम्या)', '$negativeCount', 'Requires Administrative Action', PdfColors.red700, PdfColors.red50),
                pw.SizedBox(width: 8),
                _buildKpiCard('Est. Digital Reach (एकूण पोहोच)', totalReach.toLocaleString(), 'Combined Portal Impressions', PdfColors.purple700, PdfColors.purple50),
              ],
            ),
            pw.SizedBox(height: 12),

            // Articles Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),  // Sr
                1: const pw.FixedColumnWidth(65),  // Date & Time
                2: const pw.FixedColumnWidth(85),  // Portal Source
                3: const pw.FixedColumnWidth(80),  // Tracked Profile
                4: const pw.FlexColumnWidth(3.8), // Headline & Summary
                5: const pw.FixedColumnWidth(60),  // Sentiment
                6: const pw.FixedColumnWidth(55),  // Reach
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeaderCell('#'),
                    _tableHeaderCell('Date & Time'),
                    _tableHeaderCell('News Source'),
                    _tableHeaderCell('Tracked Subject'),
                    _tableHeaderCell('News Headline & Coverage Summary'),
                    _tableHeaderCell('Sentiment'),
                    _tableHeaderCell('Est. Reach'),
                  ],
                ),
                // Rows
                ...articles.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final a = entry.value;
                  final isEven = idx % 2 == 0;
                  final rowBg = isEven ? PdfColors.grey50 : PdfColors.white;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _tableDataCell('$idx', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(a.date, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black)),
                            pw.SizedBox(height: 2),
                            pw.Text(a.time, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(a.source, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.SizedBox(height: 2),
                            pw.Text(a.sourceType.toUpperCase(), style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: pw.Text(
                          a.personTracked,
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(a.title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            pw.SizedBox(height: 2),
                            pw.Text(a.summary, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      _tableSentimentCell(a.sentiment),
                      _tableDataCell(a.reachEstimate.toLocaleString(), align: pw.TextAlign.right),
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
                    pw.Text('Digital Media & Public Relations Cell • Ward 12', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
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
      name: 'Prabhag_12_Media_Tracking_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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

  static pw.Widget _tableSentimentCell(String sentiment) {
    PdfColor color = PdfColors.blue800;
    PdfColor bg = PdfColors.blue50;
    String label = 'Neutral';

    if (sentiment.toLowerCase() == 'positive') {
      color = PdfColors.green800;
      bg = PdfColors.green50;
      label = 'Positive';
    } else if (sentiment.toLowerCase() == 'negative') {
      color = PdfColors.red800;
      bg = PdfColors.red50;
      label = 'Critical';
    }

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
            label,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }
}

