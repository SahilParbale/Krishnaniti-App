import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/improvement_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class ImprovementReportGenerator {
  ImprovementReportGenerator._();

  static Future<void> generateAndPrintImprovementReport({
    BuildContext? context,
    required List<ImprovementModel> improvements,
    String? statusFilter,
    String? areaFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final total = improvements.length;
    final complete = improvements.where((i) => i.status.toLowerCase() == 'complete').length;
    final inProgress = improvements.where((i) => i.status.toLowerCase().contains('progress')).length;
    final planned = improvements.where((i) => i.status.toLowerCase() == 'planned').length;
    final pending = improvements.where((i) => i.status.toLowerCase() == 'pending').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Ward Improvements (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Ward Improvements',
              subtitle: 'Identified ward improvement proposals and development scope',
              metaLines: [
                'Date: $nowStr',
                'Found: $total',
                if (statusFilter != null && statusFilter != 'All') 'Filter: $statusFilter',
              ],
            ),
            pw.SizedBox(height: 12),

            // Overview summary bar
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Proposals', '$total'),
                  _buildSummaryItem('Completed', '$complete', highlightColor: PdfColors.green700),
                  _buildSummaryItem('In Progress', '$inProgress', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Planned', '$planned'),
                  _buildSummaryItem('Pending', '$pending'),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (improvements.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No ward improvement records found for the selected view.',
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(3.5),
                  2: pw.FlexColumnWidth(2.5),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(1.5),
                },
                headers: const [
                  '#',
                  'Proposal Title & Description',
                  'Location / Area',
                  'Status',
                  'Date',
                ],
                data: List.generate(improvements.length, (index) {
                  final item = improvements[index];
                  final descPart = item.description.isNotEmpty ? '\n${item.description}' : '';
                  final areaPart = item.area.isNotEmpty ? ' (${item.area})' : '';
                  String dateStr = '-';
                  if (item.createdAt.isNotEmpty) {
                    try {
                      final dt = DateTime.parse(item.createdAt);
                      dateStr = DateFormat('MMM d, yyyy').format(dt);
                    } catch (_) {
                      dateStr = item.createdAt;
                    }
                  }

                  return [
                    '${index + 1}',
                    '${item.title}$descPart',
                    '${item.location}$areaPart',
                    item.status,
                    dateStr,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Ward_Improvements_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Ward Improvements',
        subtitle: 'Identified ward improvement proposals and development scope',
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
