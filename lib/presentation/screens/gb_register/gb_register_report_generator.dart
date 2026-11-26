import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/gb_register_entry_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official General Body (GB) Register Report Generator matching Nagarsevak-Managment
/// (pages/diary/DiaryReportGenerator.tsx).
class GbRegisterReportGenerator {
  GbRegisterReportGenerator._();

  static Future<void> generateAndPrintGbReport({
    BuildContext? context,
    required List<GbRegisterEntryModel> entries,
    String? meetingTypeFilter,
    String? statusFilter,
    String title = 'GB Register Report',
    String subtitle = 'Meeting Records, Resolutions & Outcomes',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final total = entries.length;

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
            foundLabel: 'Total Records',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
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
                1: pw.FlexColumnWidth(1.2), // Date (12%)
                2: pw.FlexColumnWidth(1.2), // Meeting Type (12%)
                3: pw.FlexColumnWidth(2.7), // Subject (27%)
                4: pw.FlexColumnWidth(1.5), // Department (15%)
                5: pw.FlexColumnWidth(1.4), // Outcome (14%)
                6: pw.FlexColumnWidth(1.4), // Area (15%)
              },
              headers: [
                '#',
                'Date',
                'Meeting Type',
                'Subject / Resolution',
                'Department',
                'Outcome / Status',
                'Area',
              ],
              data: List.generate(entries.length, (index) {
                final e = entries[index];
                final outcomeStr = e.response != null && e.response!.isNotEmpty
                    ? '${e.status}\n${e.response}'
                    : e.status;

                return [
                  '${index + 1}',
                  e.meetingDate,
                  e.meetingType,
                  e.subject,
                  e.department,
                  outcomeStr,
                  e.area.isNotEmpty ? e.area : 'Prabhag 12',
                ];
              }),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerLeft,
                6: pw.Alignment.centerLeft,
              },
            ),
          ];
        },
      ),
    );

    final fileName = 'GB_Register_Report_${DateFormat('yyyyMMdd').format(now)}';
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
