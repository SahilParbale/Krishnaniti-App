import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/survey_model.dart';

class SurveyReportGenerator {
  SurveyReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<SurveyModel> surveys,
    required Map<String, int> responseCounts,
    int totalVoters = 42560,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalCount = surveys.length;
    final activeCount = surveys.where((s) => s.status == 'Active').length;
    final closedCount = surveys.where((s) => s.status == 'Closed').length;
    final totalResponses = responseCounts.values.fold<int>(0, (sum, c) => sum + c);
    final targetSampleSize = (totalVoters * 0.01).ceil();

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
                        'PUNE MUNICIPAL CORPORATION - CIVIC POLLS & STRATEGY CELL',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Public Opinion Polls & Sample Survey Official Report • Citizen Feedback Summary',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.cyan900,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'Prabhag Ward 12 (Kasba-Vishrambaug Wada) • Public Opinion Surveys & Constituent Pulse',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
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
                          'SAMPLE SURVEY ANALYTICS',
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
                    'Nagarsevak Mobile Suite • Sample Surveys & Citizen Opinion Registry',
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
                  'TOTAL SURVEYS',
                  '$totalCount',
                  'Total Registered Surveys',
                  PdfColors.blue800,
                  PdfColors.blue50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'ACTIVE POLLS',
                  '$activeCount',
                  '$closedCount Completed / Closed',
                  PdfColors.green800,
                  PdfColors.green50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'RESPONSES COLLECTED',
                  '$totalResponses',
                  'Citizen Feedback Collected',
                  PdfColors.purple800,
                  PdfColors.purple50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'TARGET 1% SAMPLE SIZE',
                  '$targetSampleSize',
                  'Out of total ${NumberFormat('#,##,###').format(totalVoters)} voters',
                  PdfColors.cyan800,
                  PdfColors.cyan50,
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Table Header Title
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
                    'WARD PUBLIC SURVEY REGISTER',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                  ),
                  pw.Text(
                    'Total Surveys: ${surveys.length}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),

            // Data Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  children: [
                    _tableHeaderCell('Sr.', flex: 1),
                    _tableHeaderCell('Survey Title & Details', flex: 4),
                    _tableHeaderCell('Area / Ward', flex: 2),
                    _tableHeaderCell('Status', flex: 1),
                    _tableHeaderCell('Questions', flex: 1),
                    _tableHeaderCell('Responses / Target', flex: 2),
                    _tableHeaderCell('Created Date', flex: 2),
                  ],
                ),
                ...surveys.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final isEven = entry.key % 2 == 0;
                  final rowBg = isEven ? PdfColors.white : PdfColors.grey50;
                  final count = responseCounts[item.id] ?? 0;
                  final dateFormatted = DateFormat('dd/MM/yyyy').format(item.createdAt);

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
                              item.title,
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              item.description,
                              style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      _tableDataCell(item.area ?? 'Entire Ward 12'),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: pw.Center(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: item.status == 'Active' ? PdfColors.green50 : PdfColors.grey100,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text(
                              item.status == 'Active' ? 'Active' : 'Closed',
                              style: pw.TextStyle(
                                fontSize: 6.5,
                                fontWeight: pw.FontWeight.bold,
                                color: item.status == 'Active' ? PdfColors.green800 : PdfColors.grey700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _tableDataCell('${item.questions.length}', align: pw.TextAlign.center),
                      _tableDataCell('$count / ${item.targetSampleSize}', align: pw.TextAlign.center, isBold: true),
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
      name: 'Prabhag_12_Surveys_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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

