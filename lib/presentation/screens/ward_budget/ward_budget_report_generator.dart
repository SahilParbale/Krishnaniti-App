import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/ward_budget_model.dart';

class WardBudgetReportGenerator {
  WardBudgetReportGenerator._();

  static Future<void> generateAndPrintBudgetReport({
    required List<WardBudgetModel> budgets,
    required String year,
    String? areaFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalCount = budgets.length;
    final totalAllocated = budgets.fold<double>(0, (sum, b) => sum + b.totalAllocation);
    final totalUtilized = budgets.fold<double>(0, (sum, b) => sum + b.utilizedAmount);
    final totalRemaining = (totalAllocated - totalUtilized).clamp(0.0, double.infinity);
    final overallPercentage = totalAllocated > 0 ? (totalUtilized / totalAllocated) * 100 : 0.0;
    final activeCount = budgets.where((b) => b.status == 'Active').length;

    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

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
                        'PUNE MUNICIPAL CORPORATION - WARD BUDGET & EXPENDITURE AUDIT REPORT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 - Development Fund Sanctions, Departmental Expenditure & Unspent Balances ($year)',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
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
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'Financial Year: $year',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      if (areaFilter != null && areaFilter != 'All')
                        pw.Text('Area: $areaFilter', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blue800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Financial Summary Strip
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _statPill('Budget Heads', '$totalCount', PdfColors.blue900),
                    _statPill('Total Allocated', numFormat.format(totalAllocated), PdfColors.blue800),
                    _statPill('Total Utilized', numFormat.format(totalUtilized), PdfColors.indigo900),
                    _statPill('Remaining Balance', numFormat.format(totalRemaining), PdfColors.green900),
                    _statPill('Utilization %', '${overallPercentage.toStringAsFixed(1)}%', _getPdfPctColor(overallPercentage)),
                    _statPill('Active Heads', '$activeCount', PdfColors.blue900),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Pune Municipal Corporation - Ward Budget Administration Dossier | Official Nagarsevak Accounts Record',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),  // #
                1: pw.FlexColumnWidth(3.2), // Category / Head
                2: pw.FlexColumnWidth(2.0), // Area
                3: pw.FlexColumnWidth(1.8), // Allocated
                4: pw.FlexColumnWidth(1.8), // Utilized
                5: pw.FlexColumnWidth(1.8), // Remaining
                6: pw.FixedColumnWidth(75),  // Progress %
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _tableHeader('#', alignCenter: true),
                    _tableHeader('Category / Budget Head'),
                    _tableHeader('Area / Location'),
                    _tableHeader('Allocated (INR)', alignRight: true),
                    _tableHeader('Utilized (INR)', alignRight: true),
                    _tableHeader('Remaining (INR)', alignRight: true),
                    _tableHeader('Progress %', alignCenter: true),
                  ],
                ),
                ...budgets.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final pct = item.utilizationPercentage;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.category,
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(item.area, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          numFormat.format(item.totalAllocation),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          numFormat.format(item.utilizedAmount),
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          numFormat.format(item.remainingAmount),
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: _getPdfPctBg(pct),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _getPdfPctColor(pct)),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
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
      name: 'Ward_Budget_Report_${year}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _statPill(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 1),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text, {bool alignRight = false, bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
        textAlign: alignRight ? pw.TextAlign.right : (alignCenter ? pw.TextAlign.center : pw.TextAlign.left),
      ),
    );
  }

  static PdfColor _getPdfPctColor(double pct) {
    if (pct >= 80) return PdfColors.green800;
    if (pct >= 50) return PdfColors.orange900;
    return PdfColors.red800;
  }

  static PdfColor _getPdfPctBg(double pct) {
    if (pct >= 80) return PdfColors.green50;
    if (pct >= 50) return PdfColors.yellow50;
    return PdfColors.red50;
  }
}

