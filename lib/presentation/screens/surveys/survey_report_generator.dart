import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/survey_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class SurveyReportGenerator {
  SurveyReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<SurveyModel> surveys,
    required Map<String, int> responseCounts,
    int totalVoters = 42560,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final totalCount = surveys.length;
    final activeCount = surveys.where((s) => s.status == 'Active').length;
    final closedCount = surveys.where((s) => s.status == 'Closed').length;
    final totalResponses = responseCounts.values.fold<int>(0, (sum, c) => sum + c);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Public Surveys & Polls (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Public Surveys',
              subtitle: 'Civic Polls & Citizen Opinion Analytics',
              dateFormatted: nowStr,
              totalCount: totalCount,
            ),
            pw.SizedBox(height: 12),

            // Summary metrics matching web style
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Surveys', '$totalCount'),
                  _buildSummaryItem('Active', '$activeCount', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Closed', '$closedCount', highlightColor: WebReportTheme.slate600),
                  _buildSummaryItem('Responses Logged', '$totalResponses', highlightColor: WebReportTheme.brand700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (surveys.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No public surveys found.',
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerCount: 1,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(3.8),
                  2: pw.FlexColumnWidth(1.4),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(1.6),
                },
                headers: const [
                  '#',
                  'Survey Title & Scope',
                  'Status',
                  'Questions',
                  'Responses',
                ],
                data: surveys.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final s = entry.value;
                  final resp = responseCounts[s.id] ?? 0;
                  final descPart = s.description.isNotEmpty ? '\n${s.description}' : '';
                  final areaPart = s.area != null && s.area!.isNotEmpty ? '\nArea: ${s.area}' : '';

                  return [
                    '$idx',
                    '${s.title}$descPart$areaPart',
                    s.status,
                    '${s.questions.length} Qs',
                    '$resp responses',
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Public_Surveys_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Public Surveys',
        subtitle: 'Civic Polls & Citizen Opinion Analytics',
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
}
