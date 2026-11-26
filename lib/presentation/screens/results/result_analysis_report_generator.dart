import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/election_result_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class ResultAnalysisReportGenerator {
  ResultAnalysisReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required String ward,
    required String selectedCandidate,
    required List<ElectionResultModel> results,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Calculate aggregated statistics
    final totalVotesRow = results.where((r) => r.boothNumber == 'एकूण मत').firstOrNull;
    final totalVotes = totalVotesRow != null
        ? totalVotesRow.totalVotesCasted
        : results.fold<int>(0, (sum, r) => sum + r.totalVotesCasted);

    final ourVotes = totalVotesRow != null
        ? totalVotesRow.votesFor(selectedCandidate)
        : results.fold<int>(0, (sum, r) => sum + r.votesFor(selectedCandidate));

    final voteShare = totalVotes > 0 ? (ourVotes / totalVotes) * 100 : 0.0;
    final winningBooths = results.where((r) => r.isWinner(selectedCandidate)).length;
    final losingBooths = results.length - winningBooths;

    // Filter out summary/postal rows for booth table
    final boothList = results
        .where((r) =>
            r.boothNumber != 'एकूण मत' &&
            r.boothNumber != 'टपाल मतदान' &&
            r.boothNumber != 'सर्व मतदान केंद्र नोंदवण्यात आलेली मते')
        .toList();

    // Sort booths numerically
    boothList.sort((a, b) {
      final aMatch = RegExp(r'\d+').firstMatch(a.boothNumber);
      final bMatch = RegExp(r'\d+').firstMatch(b.boothNumber);
      if (aMatch != null && bMatch != null) {
        return int.parse(aMatch.group(0)!).compareTo(int.parse(bMatch.group(0)!));
      }
      return a.boothNumber.compareTo(b.boothNumber);
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Election Results Analysis (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Election Results & Booth Analysis',
              subtitle: 'Performance report for $selectedCandidate',
              metaLines: [
                'Date: $nowStr',
                'Ward: $ward',
                'Total Booths: ${boothList.length}',
              ],
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
                  _buildSummaryItem('Total Votes', '$ourVotes / $totalVotes'),
                  _buildSummaryItem('Vote Share', '${voteShare.toStringAsFixed(1)}%', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Winning Booths', '$winningBooths', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Losing Booths', '$losingBooths', highlightColor: PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (boothList.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No election booth results available.',
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
                  0: pw.FixedColumnWidth(28),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(2.0),
                  4: pw.FlexColumnWidth(2.4),
                  5: pw.FlexColumnWidth(1.6),
                },
                headers: const [
                  '#',
                  'Booth / Centre',
                  'Candidate Votes',
                  'Total Cast',
                  'Winner',
                  'Margin',
                ],
                data: List.generate(boothList.length, (index) {
                  final r = boothList[index];
                  final candVotes = r.votesFor(selectedCandidate);
                  final isWinner = r.isWinner(selectedCandidate);
                  final margin = r.margin;

                  return [
                    '${index + 1}',
                    r.boothNumber,
                    '$candVotes votes',
                    '${r.totalVotesCasted}',
                    isWinner ? '$selectedCandidate (Won)' : r.winner,
                    '+$margin',
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Election_Results_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Election Results Analysis',
        subtitle: 'Ward $ward • Candidate Performance & Booth Analysis',
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
