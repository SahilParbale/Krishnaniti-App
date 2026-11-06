import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/social_post_model.dart';
import '../../../data/repositories/social_analytics_repository.dart';

class SocialAnalyticsReportGenerator {
  SocialAnalyticsReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<SocialPostModel> posts,
    required SocialAnalyticsSummary summary,
    required List<VoterBirthdayModel> birthdays,
    String? platformFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // Calculate platform counts
    final fbPosts = posts.where((p) => p.platform.toLowerCase() == 'facebook').length;
    final igPosts = posts.where((p) => p.platform.toLowerCase() == 'instagram').length;
    final twPosts = posts.where((p) => p.platform.toLowerCase() == 'twitter').length;

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
                        'PUNE MUNICIPAL CORPORATION - PUBLIC RELATIONS & MEDIA DEPARTMENT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 (Kasba-Vishrambaug Wada) • Social Media Reach & Voter Engagement Audit Report',
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
                          'Platform Filter: ${platformFilter ?? 'All Platforms'} (${posts.length} Posts)',
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
                    'Nagarsevak Office Management System • Prabhag 12 • Social Media Analytics Audit',
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
                _buildKpiCard('Total Reach (एकूण पोहोच)', summary.totalReach.toLocaleString(), 'Impressions Across Platforms', PdfColors.blue700, PdfColors.blue50),
                pw.SizedBox(width: 8),
                _buildKpiCard('Total Likes (लाईक्स)', summary.totalLikes.toLocaleString(), 'Constituent Appreciations', PdfColors.pink700, PdfColors.pink50),
                pw.SizedBox(width: 8),
                _buildKpiCard('Comments (टिप्पण्या)', summary.totalComments.toLocaleString(), 'Citizen Feedback & Inquiries', PdfColors.purple700, PdfColors.purple50),
                pw.SizedBox(width: 8),
                _buildKpiCard('Shares (शेअर्स)', summary.totalShares.toLocaleString(), 'Public Information Amplification', PdfColors.green700, PdfColors.green50),
              ],
            ),
            pw.SizedBox(height: 12),

            // Performance Insight Strip
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.indigo200, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Performance Indicator: ',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                      ),
                      pw.Text(
                        'Monthly Growth: ${summary.monthlyGrowth}  |  Avg Engagement Rate: ${summary.averageEngagementRate.toStringAsFixed(1)}%',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.indigo900),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Facebook: $fbPosts posts  •  Instagram: $igPosts posts  •  Twitter: $twPosts posts',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Posts Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),  // Sr
                1: const pw.FixedColumnWidth(65),  // Date
                2: const pw.FixedColumnWidth(65),  // Platform
                3: const pw.FlexColumnWidth(3.8), // Content
                4: const pw.FixedColumnWidth(55),  // Reach
                5: const pw.FixedColumnWidth(48),  // Likes
                6: const pw.FixedColumnWidth(48),  // Comments
                7: const pw.FixedColumnWidth(48),  // Shares
                8: const pw.FixedColumnWidth(58),  // Eng Rate %
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeaderCell('#'),
                    _tableHeaderCell('Date'),
                    _tableHeaderCell('Platform'),
                    _tableHeaderCell('Post Content & Civic Updates (English / Marathi)'),
                    _tableHeaderCell('Reach'),
                    _tableHeaderCell('Likes'),
                    _tableHeaderCell('Comments'),
                    _tableHeaderCell('Shares'),
                    _tableHeaderCell('Eng. %'),
                  ],
                ),
                // Rows
                ...posts.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final p = entry.value;
                  final isEven = idx % 2 == 0;
                  final rowBg = isEven ? PdfColors.grey50 : PdfColors.white;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _tableDataCell('$idx', align: pw.TextAlign.center),
                      _tableDataCell(p.date, align: pw.TextAlign.center),
                      _tablePlatformCell(p.platform),
                      _tableDataCell(p.content, isBold: false),
                      _tableDataCell(p.reach.toLocaleString(), align: pw.TextAlign.right),
                      _tableDataCell(p.likes.toLocaleString(), align: pw.TextAlign.right),
                      _tableDataCell(p.comments.toString(), align: pw.TextAlign.right),
                      _tableDataCell(p.shares.toString(), align: pw.TextAlign.right),
                      _tableDataCell('${p.engagementRate.toStringAsFixed(1)}%', align: pw.TextAlign.center, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 14),

            // Constituent Birthdays Section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CONSTITUENCY ENGAGEMENT • TODAY\'S CONSTITUENT BIRTHDAY WISHES LOG (आजचे वाढदिवस)',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: birthdays.map((b) {
                      return pw.Expanded(
                        child: pw.Container(
                          margin: const pw.EdgeInsets.only(right: 6),
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(b.name, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 2),
                              pw.Text('${b.area} • Age: ${b.age}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                              pw.SizedBox(height: 2),
                              pw.Text('Mobile: ${b.mobile}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.blue800)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Official Signature Strip
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Report Verified By: ___________________________', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('Media & Public Relations Coordinator, Prabhag 12', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Authorized Signature: ___________________________', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('Nagarsevak / Municipal Corporator • Prabhag 12, Pune', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
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
      name: 'Prabhag_12_Social_Media_Analytics_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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

  static pw.Widget _tablePlatformCell(String platform) {
    PdfColor color = PdfColors.blue800;
    if (platform.toLowerCase() == 'instagram') color = PdfColors.pink800;
    if (platform.toLowerCase() == 'twitter') color = PdfColors.grey800;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border.all(color: color, width: 0.5),
          ),
          child: pw.Text(
            platform,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }
}

