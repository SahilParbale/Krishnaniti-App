import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/team_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class TeamReportGenerator {
  TeamReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<TeamMemberModel> staffList,
    String activeCategory = 'All',
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final officeCount = staffList.where((s) => s.category == 'Office').length;
    final partyCount = staffList.where((s) => s.category == 'Party').length;
    final coopCount = staffList.where((s) => s.category == 'Cooperative').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Staff & Team Directory (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Staff & Team Directory',
              subtitle: 'Prabhag Ward 12 Staff, Executives & Cadre Directory',
              dateFormatted: nowStr,
              totalCount: staffList.length,
            ),
            pw.SizedBox(height: 12),

            // Summary strip
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Team', '${staffList.length}'),
                  _buildSummaryItem('Office Staff', '$officeCount', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Party Cadre', '$partyCount', highlightColor: PdfColors.indigo700),
                  _buildSummaryItem('Cooperative', '$coopCount', highlightColor: PdfColors.teal700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (staffList.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No team members found for the selected view.',
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
                  1: pw.FlexColumnWidth(3.0),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(3.0),
                },
                headers: const [
                  '#',
                  'Name & Role',
                  'Contact',
                  'Area',
                  'Keywords / Scope',
                ],
                data: staffList.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final member = entry.value;
                  final keywordsStr = member.keywords.isNotEmpty ? member.keywords.join(', ') : '-';
                  final roleStr = member.role.isNotEmpty ? '\n${member.role}' : '';

                  return [
                    '$index',
                    '${member.displayName}$roleStr',
                    member.mobile.isNotEmpty ? member.mobile : '-',
                    member.area?.isNotEmpty == true ? member.area! : '-',
                    keywordsStr,
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Team_Staff_Directory_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Staff & Team Directory',
        subtitle: 'Prabhag Ward 12 Staff, Executives & Cadre Directory',
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
