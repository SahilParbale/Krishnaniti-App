import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/election_result_model.dart';

class ResultAnalysisReportGenerator {
  ResultAnalysisReportGenerator._();

  static Future<void> generateAndPrintReport({
    required String ward,
    required String selectedCandidate,
    required List<ElectionResultModel> results,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

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

    // Get list of candidates
    final candidates = results.isNotEmpty
        ? results.first.candidateVotes.keys.toList()
        : <String>[];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - ELECTION CELL',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Pune Municipal Corporation Election Results & Booth-wise Analysis Report',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.cyan900,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        '$ward • Candidate Analysis: $selectedCandidate',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated: $nowStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                        ),
                        child: pw.Text(
                          'CONFIDENTIAL & VERIFIED',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Nagarsevak Mobile Suite • Analytical Election Intelligence',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Row(
              children: [
                _buildKpiCard(
                  'TOTAL VOTES',
                  NumberFormat('#,##,###').format(ourVotes),
                  'Out of ${NumberFormat('#,##,###').format(totalVotes)} Total',
                  PdfColors.blue800,
                  PdfColors.blue50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'VOTE SHARE',
                  '${voteShare.toStringAsFixed(1)}%',
                  'Percentage of Total Ward Votes',
                  PdfColors.purple800,
                  PdfColors.purple50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'WINNING BOOTHS',
                  '$winningBooths',
                  'Strongholds',
                  PdfColors.green800,
                  PdfColors.green50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'LOSING BOOTHS',
                  '$losingBooths',
                  'Needs Work / Trailing',
                  PdfColors.red800,
                  PdfColors.red50,
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Table Title
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'BOOTH-WISE PERFORMANCE BREAKDOWN',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                  ),
                  pw.Text(
                    'Total Booths: ${boothList.length}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),

            // Data Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  children: [
                    _tableHeaderCell('Booth No.', flex: 1),
                    _tableHeaderCell('Booth Location / School', flex: 3),
                    ...candidates.map((c) {
                      final isSelected = c == selectedCandidate;
                      return _tableHeaderCell(
                        isSelected ? '$c ★' : c,
                        flex: 2,
                        isHighlight: isSelected,
                      );
                    }),
                    _tableHeaderCell('Total Votes', flex: 1),
                    _tableHeaderCell('Winner Candidate', flex: 2),
                    _tableHeaderCell('Margin', flex: 1),
                  ],
                ),
                // Data Rows
                ...boothList.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isEven = entry.key % 2 == 0;
                  final rowBg = isEven ? PdfColors.white : PdfColors.grey50;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _tableDataCell(item.boothNumber, align: pw.TextAlign.center, isBold: true),
                      _tableDataCell(item.boothName),
                      ...candidates.map((c) {
                        final votes = item.votesFor(c);
                        final isWinner = item.isWinner(c);
                        final isSelected = c == selectedCandidate;

                        PdfColor cellBg = PdfColors.white;
                        PdfColor textColor = PdfColors.black;
                        bool bold = false;

                        if (isWinner) {
                          cellBg = PdfColors.green50;
                          textColor = PdfColors.green800;
                          bold = true;
                        } else if (isSelected) {
                          cellBg = PdfColors.blue50;
                          textColor = PdfColors.blue800;
                          bold = true;
                        }

                        return pw.Container(
                          color: cellBg,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: pw.Text(
                            '$votes',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        );
                      }),
                      _tableDataCell('${item.totalVotesCasted}', align: pw.TextAlign.center, isBold: true),
                      pw.Container(
                        color: item.isWinner(selectedCandidate) ? PdfColors.green50 : PdfColors.white,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: pw.Text(
                          item.winner,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: item.isWinner(selectedCandidate) ? PdfColors.green800 : PdfColors.black,
                          ),
                        ),
                      ),
                      _tableDataCell('+${item.margin}', align: pw.TextAlign.center, isBold: true),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Election_Result_Analysis_${ward.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildKpiCard(
      String title, String value, String subtitle, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 7, color: textColor, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text, {int flex = 1, bool isHighlight = false}) {
    return pw.Container(
      color: isHighlight ? PdfColors.blue700 : PdfColors.blueGrey800,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableDataCell(String text,
      {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }
}

