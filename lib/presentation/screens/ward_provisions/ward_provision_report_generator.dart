import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/ward_provision_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class WardProvisionReportGenerator {
  WardProvisionReportGenerator._();

  static Future<void> generateAndPrintProvisionReport({
    BuildContext? context,
    required List<WardProvisionModel> provisions,
    required String year,
    String? categoryFilter,
    String? statusFilter,
  }) async {
    final pdf = pw.Document();

    final totalCount = provisions.length;
    final totalRequested = provisions.fold<double>(0, (sum, p) => sum + p.requestedAmount);
    final totalSanctioned = provisions.fold<double>(0, (sum, p) => sum + (p.sanctionedAmount ?? 0));

    final approvedCount = provisions.where((p) => p.status.toLowerCase() == 'approved').length;
    final partialCount = provisions.where((p) => p.status.toLowerCase().contains('partially')).length;
    final pendingCount = provisions.where((p) => p.status.toLowerCase() == 'pending').length;

    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Ward Provisions & Budget Allocations (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Ward Provisions',
              subtitle: 'Capital Budget Allocations & Sanctions Dossier',
              metaLines: [
                'Financial Year: $year',
                'Total Records: $totalCount',
                'Req: ${numFormat.format(totalRequested)} | Sanc: ${numFormat.format(totalSanctioned)}',
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary KPIs matching web styling
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Proposals', '$totalCount'),
                  _buildSummaryItem('Requested', numFormat.format(totalRequested)),
                  _buildSummaryItem('Sanctioned', numFormat.format(totalSanctioned), highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Approved', '$approvedCount'),
                  _buildSummaryItem('Partial / Pending', '${partialCount + pendingCount}'),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (provisions.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No ward provision records found for the selected view.',
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
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(1.8),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(1.8),
                  5: pw.FlexColumnWidth(1.8),
                  6: pw.FlexColumnWidth(1.4),
                },
                headers: const [
                  '#',
                  'Project Title & Category',
                  'Area',
                  'Letter Ref',
                  'Requested',
                  'Sanctioned',
                  'Status',
                ],
                data: List.generate(provisions.length, (index) {
                  final p = provisions[index];
                  final reqStr = numFormat.format(p.requestedAmount);
                  final sancStr = p.sanctionedAmount != null ? numFormat.format(p.sanctionedAmount) : '--';
                  final catStr = p.category.isNotEmpty ? '\nCategory: ${p.category}' : '';

                  return [
                    '${index + 1}',
                    '${p.title}$catStr',
                    p.area.isNotEmpty ? p.area : '-',
                    p.letterReference.isNotEmpty ? p.letterReference : '-',
                    reqStr,
                    sancStr,
                    p.statusDisplayEn,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Ward_Provisions_Report_${year}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Ward Provisions',
        subtitle: 'Capital Budget Allocations & Sanctions Dossier',
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
