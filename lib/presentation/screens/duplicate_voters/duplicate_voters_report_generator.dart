import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/duplicate_voter_group_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class DuplicateVotersReportGenerator {
  DuplicateVotersReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<DuplicateVoterGroupModel> duplicateGroups,
    required int totalAffectedVoters,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final estExtraRecords = duplicateGroups.fold<int>(0, (sum, g) => sum + g.extraRecordsCount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Duplicate Voters Audit (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Duplicate Voters Report',
              subtitle: 'Identification of duplicated voter registrations across electoral rolls',
              metaLines: [
                'Date: $formattedDate',
                'Affected Voters: $totalAffectedVoters',
                'Extra Records: $estExtraRecords',
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary KPI boxes matching web layout
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Duplicate Groups', '${duplicateGroups.length}'),
                  _buildSummaryItem('Total Affected', '$totalAffectedVoters', highlightColor: PdfColors.red700),
                  _buildSummaryItem('Est. Extra Records', '$estExtraRecords', highlightColor: WebReportTheme.brand700),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            if (duplicateGroups.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(32),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'No duplicate voters found. All voter records are unique.',
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              ...duplicateGroups.map((group) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Group Header Banner
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: const pw.BoxDecoration(
                          color: WebReportTheme.brand50,
                          borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(5)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${group.displayName} (${group.recordsCount} records)',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: WebReportTheme.brand900,
                              ),
                            ),
                            pw.Text(
                              '${group.extraRecordsCount} extra records (Form 7)',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.red700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table of Voters in Group
                      pw.TableHelper.fromTextArray(
                        headerCount: 1,
                        border: WebReportTheme.tableBorder,
                        headerStyle: WebReportTheme.tableHeaderStyle,
                        headerDecoration: WebReportTheme.tableHeaderDecoration,
                        headerHeight: 20,
                        cellHeight: 18,
                        cellAlignment: pw.Alignment.centerLeft,
                        cellStyle: WebReportTheme.tableCellStyle,
                        columnWidths: const {
                          0: pw.FixedColumnWidth(22),
                          1: pw.FlexColumnWidth(2.6),
                          2: pw.FlexColumnWidth(1.8),
                          3: pw.FlexColumnWidth(1.0),
                          4: pw.FlexColumnWidth(1.0),
                          5: pw.FlexColumnWidth(1.2),
                          6: pw.FlexColumnWidth(1.2),
                          7: pw.FlexColumnWidth(2.4),
                        },
                        headers: const [
                          '#',
                          'Voter Name',
                          'EPIC No.',
                          'Serial',
                          'Age',
                          'Gender',
                          'Booth',
                          'Address / Area',
                        ],
                        data: List.generate(group.voters.length, (idx) {
                          final v = group.voters[idx];
                          final namePart = [v.nameEnglish, v.nameMarathi]
                              .where((s) => s.isNotEmpty)
                              .join('\n');

                          return [
                            '${idx + 1}',
                            namePart,
                            v.epicNo.isNotEmpty ? v.epicNo : '-',
                            v.serialNo != null ? '${v.serialNo}' : '-',
                            '${v.age}',
                            v.gender.isNotEmpty ? v.gender : '-',
                            v.booth.isNotEmpty ? v.booth : '-',
                            v.address.isNotEmpty ? v.address : '-',
                          ];
                        }),
                        oddRowDecoration: WebReportTheme.oddRowDecoration,
                      ),
                    ],
                  ),
                );
              }),
          ];
        },
      ),
    );

    final fileName = 'Duplicate_Voters_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Duplicate Voters Report',
        subtitle: 'Identification of duplicated voter registrations across electoral rolls',
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
