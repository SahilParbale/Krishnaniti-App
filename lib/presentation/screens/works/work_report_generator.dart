import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/work_history_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Work History Report Generator matching Nagarsevak-Managment
/// (WorkReportGenerator.tsx).
class WorkReportGenerator {
  WorkReportGenerator._();

  static Future<void> generateAndPrintWorkReport({
    BuildContext? context,
    required List<WorkHistoryModel> works,
    String? statusFilter,
    String? areaFilter,
    String title = 'Work History Report',
    String subtitle = 'Historical Register of Development Works & Municipal Projects',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final total = works.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: title,
            );
          }
          return WebReportTheme.buildHeader(
            title: title,
            subtitle: subtitle,
            dateFormatted: formattedDate,
            totalCount: total,
            foundLabel: 'Found',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          if (works.isEmpty) {
            return [
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No development work records found.',
                  style: const pw.TextStyle(fontSize: 12, color: WebReportTheme.slate400),
                ),
              ),
            ];
          }

          return [
            pw.TableHelper.fromTextArray(
              border: WebReportTheme.tableBorder,
              headerStyle: WebReportTheme.tableHeaderStyle,
              headerDecoration: WebReportTheme.tableHeaderDecoration,
              headerHeight: 22,
              cellHeight: 20,
              cellStyle: WebReportTheme.tableCellStyle,
              headerCount: 1,
              oddRowDecoration: WebReportTheme.oddRowDecoration,
              columnWidths: const {
                0: pw.FlexColumnWidth(0.6), // # (5%)
                1: pw.FlexColumnWidth(3.5), // Complaint / Subject (35%)
                2: pw.FlexColumnWidth(2.5), // Location / Area (25%)
                3: pw.FlexColumnWidth(1.5), // Status (15%)
                4: pw.FlexColumnWidth(1.9), // Amount (20%)
              },
              headers: [
                '#',
                'Complaint / Subject',
                'Location / Area',
                'Status',
                'Amount',
              ],
              data: List.generate(works.length, (index) {
                final w = works[index];
                final dateStr = w.date;
                final locationStr = w.area.isNotEmpty ? '${w.location} (${w.area})' : w.location;
                final amountStr = w.amount != null && w.amount! > 0
                    ? 'Rs. ${NumberFormat.decimalPattern().format(w.amount!.toInt())}'
                    : '--';

                final subjectDesc = w.description.isNotEmpty
                    ? '${w.title}\n${w.description}'
                    : w.title;

                final statusWithDate = dateStr.isNotEmpty
                    ? '${w.status}\n$dateStr'
                    : w.status;

                return [
                  '${index + 1}',
                  subjectDesc,
                  locationStr,
                  statusWithDate,
                  amountStr,
                ];
              }),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    final fileName = 'Work_History_Report_${DateFormat('yyyy-MM-dd').format(now)}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: title,
        subtitle: subtitle,
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
