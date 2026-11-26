import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/work_history_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Political Work Report (Ahwal) Generator matching Nagarsevak-Managment
/// (AhwalReportGenerator.tsx).
class AhwalReportGenerator {
  AhwalReportGenerator._();

  static Future<void> generateAndPrintAhwal({
    BuildContext? context,
    required List<WorkHistoryModel> selectedWorks,
    String? nagarsevakName = 'Nagarsevak Office',
    String? wardName = 'Ward No. 12 (Prabhag 12)',
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final totalCount = selectedWorks.length;
    final totalAmount = selectedWorks.fold<double>(0, (sum, w) => sum + (w.amount ?? 0));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: 'Political Work Report (Ahwal)',
            );
          }
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Political Work Report',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Development Works & Achievements Summary',
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        color: WebReportTheme.slate500,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Date: $nowStr',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: WebReportTheme.slate400,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Total Works: $totalCount',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: WebReportTheme.slate400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            // Report Summary Box (matching web AhwalReportGenerator.tsx)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              margin: const pw.EdgeInsets.only(bottom: 16),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.brand50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TOTAL WORKS',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '$totalCount',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand900),
                      ),
                    ],
                  ),
                  if (totalAmount > 0)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL ESTIMATED AMOUNT',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Rs. ${NumberFormat.decimalPattern().format(totalAmount.toInt())}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF15803D)),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Works List Cards (matching web AhwalReportGenerator.tsx)
            ...selectedWorks.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final work = entry.value;
              final amountStr = work.amount != null && work.amount! > 0
                  ? 'Rs. ${NumberFormat.decimalPattern().format(work.amount!.toInt())}'
                  : null;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '$idx. ${work.title}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: WebReportTheme.slate900,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: WebReportTheme.slate50,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
                          ),
                          child: pw.Text(
                            work.date,
                            style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate600),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Location: ${work.location}${work.area.isNotEmpty ? " (${work.area})" : ""}',
                      style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate700),
                    ),
                    if (work.description.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        work.description,
                        style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate800, lineSpacing: 1.5),
                      ),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Status: ${work.status}',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                        ),
                        if (amountStr != null)
                          pw.Text(
                            amountStr,
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF15803D)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Signature Block
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 160,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 40,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: WebReportTheme.slate400, width: 0.8),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Office Seal & Signature',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700),
                      ),
                      pw.Text(
                        '$nagarsevakName • $wardName',
                        style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final fileName = 'Ahwal_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Political Work Report (Ahwal)',
        subtitle: 'Development Works & Achievements Summary',
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
}
