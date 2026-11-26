import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';
import 'analysis_strategy_screen.dart';

class AnalysisStrategyReportGenerator {
  AnalysisStrategyReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required AreaMetrics reportData,
    required String generatedBrief,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Area Intelligence - ${reportData.areaName} (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Area Intelligence & Strategy Docket',
              subtitle: 'Area: ${reportData.areaName} - Field Strategy & Analytics',
              dateFormatted: formattedDate,
              totalCount: reportData.totalVoters,
              foundLabel: 'Total Voters',
            ),
            pw.SizedBox(height: 12),

            // Key KPI Stats Row matching web
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Voters', NumberFormat('#,##,###').format(reportData.totalVoters)),
                  _buildSummaryItem('Karyakartas', '${reportData.staffCount}', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Supporters', '${reportData.supportersCount}', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Mobile Reach', '${reportData.mobileReach}%', highlightColor: WebReportTheme.brand600),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Demographics & Population Analysis
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VOTER DEMOGRAPHICS & POPULATION ANALYSIS',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.brand700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Age Group Distribution:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                            pw.SizedBox(height: 4),
                            _buildDataRow('Youth (18-35 yrs)', '${reportData.age18_35}'),
                            _buildDataRow('Middle-aged (36-60 yrs)', '${reportData.age36_60}'),
                            _buildDataRow('Senior Citizens (60+ yrs)', '${reportData.age61Plus}'),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Gender Ratio:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                            pw.SizedBox(height: 4),
                            _buildDataRow('Male Voters', '${reportData.genderMale}'),
                            _buildDataRow('Female Voters', '${reportData.genderFemale}'),
                            _buildDataRow('Other / Unspecified', '${reportData.genderOther}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // Caste Distribution Table
            if (reportData.casteDistribution.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ESTIMATED COMMUNITY / CASTE BREAKDOWN',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.TableHelper.fromTextArray(
                      border: WebReportTheme.tableBorder,
                      headerCount: 1,
                      headers: ['Community / Caste Segment', 'Estimated Voter Count'],
                      data: reportData.casteDistribution.entries
                          .map((e) => [e.key, '${e.value}'])
                          .toList(),
                      headerStyle: WebReportTheme.tableHeaderStyle,
                      headerDecoration: WebReportTheme.tableHeaderDecoration,
                      oddRowDecoration: WebReportTheme.oddRowDecoration,
                      cellStyle: WebReportTheme.tableCellStyle,
                      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // Civic Problems & Personal Requests Row
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CIVIC GRIEVANCES & WORKS', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate800)),
                        pw.SizedBox(height: 6),
                        _buildDataRow('Solved Complaints', '${reportData.solvedComplaints}'),
                        _buildDataRow('Ongoing Complaints', '${reportData.ongoingComplaints}'),
                        _buildDataRow('Total Registered', '${reportData.totalComplaints}'),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('OFFICE ASSISTANCE REQUESTS', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate800)),
                        pw.SizedBox(height: 6),
                        _buildDataRow('Completed Requests', '${reportData.solvedRequests}'),
                        _buildDataRow('Pending Requests', '${reportData.pendingRequests}'),
                        _buildDataRow('Total Requests', '${reportData.totalRequests}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // Past Election Performance
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PAST ELECTION PERFORMANCE & MARGIN', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate800)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(child: _buildDataRow('Winner Candidate', reportData.winnerName)),
                      pw.SizedBox(width: 12),
                      pw.Expanded(child: _buildDataRow('Winning Margin', '+${reportData.winningMargin}')),
                      pw.SizedBox(width: 12),
                      pw.Expanded(child: _buildDataRow('Total Votes Cast', '${reportData.totalElectionVotes}')),
                    ],
                  ),
                ],
              ),
            ),

            if (generatedBrief.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.brand50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: WebReportTheme.brand600, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AI FIELD VISIT BRIEFING & STRATEGIC ADVISORY',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      generatedBrief,
                      style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate800, lineSpacing: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    final fileName = 'Area_Intelligence_${reportData.areaName.replaceAll(' ', '_')}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Area Intelligence & Strategy Docket',
        subtitle: 'Area: ${reportData.areaName} - Field Strategy & Analytics',
        fileName: fileName,
        onBuildPdf: () async => pdf.save(),
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '$fileName.pdf',
      );
    }
  }

  static pw.Widget _buildSummaryItem(String label, String value, {PdfColor? highlightColor}) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: highlightColor ?? WebReportTheme.slate800,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDataRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
        ],
      ),
    );
  }
}
