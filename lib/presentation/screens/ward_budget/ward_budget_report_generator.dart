import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/ward_budget_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

/// Official Ward Budget Report Generator matching Nagarsevak-Managment
/// (pages/budget/BudgetReportGenerator.tsx).
class WardBudgetReportGenerator {
  WardBudgetReportGenerator._();

  static Future<void> generateAndPrintBudgetReport({
    required List<WardBudgetModel> budgets,
    required String year,
    String? areaFilter,
    String title = 'Ward Budget & Provision Report',
    String subtitle = 'Financial Planning & Allocation Audit',
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final totalCount = budgets.length;
    final totalAllocated = budgets.fold<double>(0, (sum, b) => sum + b.totalAllocation);
    final totalUtilized = budgets.fold<double>(0, (sum, b) => sum + b.utilizedAmount);
    final totalRemaining = (totalAllocated - totalUtilized).clamp(0.0, double.infinity);
    final utilizationPercentage = totalAllocated > 0 ? (totalUtilized / totalAllocated) * 100 : 0.0;

    String formatCurrency(double val) {
      return 'Rs. ${NumberFormat.decimalPattern().format(val.toInt())}';
    }

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
          return pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2),
              ),
            ),
            padding: const pw.EdgeInsets.only(bottom: 12),
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.brand700,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        subtitle,
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: WebReportTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Financial Year: $year',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: WebReportTheme.slate400,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'Date: $nowStr',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: WebReportTheme.slate400,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'Total Heads: $totalCount',
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
            // Summary Overview (3-card grid matching BudgetReportGenerator.tsx)
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: WebReportTheme.slate50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: WebReportTheme.slate200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL ALLOCATED', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate500)),
                        pw.SizedBox(height: 3),
                        pw.Text(formatCurrency(totalAllocated), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: WebReportTheme.brand50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL UTILIZED', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand600)),
                        pw.SizedBox(height: 3),
                        pw.Text(formatCurrency(totalUtilized), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand900)),
                        pw.SizedBox(height: 1),
                        pw.Text('${utilizationPercentage.toStringAsFixed(1)}% utilized', style: const pw.TextStyle(fontSize: 7, color: WebReportTheme.brand700)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF0FDF4),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFBBF7D0), width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('REMAINING BALANCE', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF15803D))),
                        pw.SizedBox(height: 3),
                        pw.Text(formatCurrency(totalRemaining), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF14532D))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Table matching BudgetReportGenerator.tsx
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
                1: pw.FlexColumnWidth(3.5), // Category / Head (35%)
                2: pw.FlexColumnWidth(2.0), // Allocated (20%)
                3: pw.FlexColumnWidth(2.0), // Utilized (20%)
                4: pw.FlexColumnWidth(1.9), // Progress (20%)
              },
              headers: [
                '#',
                'Category / Head',
                'Allocated',
                'Utilized',
                'Progress',
              ],
              data: List.generate(budgets.length, (index) {
                final b = budgets[index];
                final percent = b.totalAllocation > 0
                    ? (b.utilizedAmount / b.totalAllocation) * 100
                    : 0.0;
                final areaStr = b.area.isNotEmpty ? '\n${b.area}' : '';

                return [
                  '${index + 1}',
                  '${b.category}$areaStr',
                  formatCurrency(b.totalAllocation),
                  formatCurrency(b.utilizedAmount),
                  '${percent.toStringAsFixed(0)}% Utilized',
                ];
              }),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Budget_Report_${year}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
