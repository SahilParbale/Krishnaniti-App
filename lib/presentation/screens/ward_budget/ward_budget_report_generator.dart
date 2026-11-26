import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/ward_budget_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Ward Budget Report Generator matching Nagarsevak-Managment
/// (pages/budget/BudgetReportGenerator.tsx).
class WardBudgetReportGenerator {
  WardBudgetReportGenerator._();

  static Future<void> generateAndPrintBudgetReport({
    BuildContext? context,
    required List<WardBudgetModel> budgets,
    required String year,
    String? areaFilter,
    String title = 'Ward Budget & Provision Report',
    String subtitle = 'Financial Planning & Allocation Audit',
    String lang = 'en',
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final totalCount = budgets.length;
    final totalAllocated = budgets.fold<double>(0, (sum, b) => sum + b.totalAllocation);
    final totalUtilized = budgets.fold<double>(0, (sum, b) => sum + b.utilizedAmount);
    final totalRemaining = (totalAllocated - totalUtilized).clamp(0.0, double.infinity);
    final utilizationPercentage = totalAllocated > 0 ? (totalUtilized / totalAllocated) * 100 : 0.0;

    final effectiveTitle = title != 'Ward Budget & Provision Report'
        ? title
        : (lang == 'mr'
            ? 'प्रभाग अंदाजपत्रक आणि तरतूद अहवाल'
            : (lang == 'hi' ? 'वार्ड बजट और प्रावधान रिपोर्ट' : 'Ward Budget & Provision Report'));
    final effectiveSubtitle = subtitle != 'Financial Planning & Allocation Audit'
        ? subtitle
        : (lang == 'mr'
            ? 'आर्थिक नियोजन आणि तरतूद लेखापरीक्षण'
            : (lang == 'hi' ? 'वित्तीय योजना और आवंटन ऑडिट' : 'Financial Planning & Allocation Audit'));

    final yearLabel = lang == 'mr' ? 'आर्थिक वर्ष' : (lang == 'hi' ? 'वित्तीय वर्ष' : 'Financial Year');
    final dateLabel = lang == 'mr' ? 'तारीख' : (lang == 'hi' ? 'दिनांक' : 'Date');
    final headsLabel = lang == 'mr' ? 'एकूण शीर्ष' : (lang == 'hi' ? 'कुल शीर्ष' : 'Total Heads');
    final allocatedLabel = lang == 'mr' ? 'एकूण तरतूद' : (lang == 'hi' ? 'कुल आवंटित' : 'TOTAL ALLOCATED');
    final utilizedLabel = lang == 'mr' ? 'एकूण खर्च' : (lang == 'hi' ? 'कुल उपयोग' : 'TOTAL UTILIZED');
    final remainingLabel = lang == 'mr' ? 'शिल्लक निधी' : (lang == 'hi' ? 'शेष राशि' : 'REMAINING BALANCE');
    final utilizedSuffix = lang == 'mr' ? 'खर्च' : (lang == 'hi' ? 'उपयोग' : 'utilized');

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
              title: effectiveTitle,
              lang: lang,
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
                        effectiveTitle,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.brand700,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        effectiveSubtitle,
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
                      '$yearLabel: $year',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: WebReportTheme.slate400,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      '$dateLabel: $nowStr',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: WebReportTheme.slate400,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      '$headsLabel: $totalCount',
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
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: lang),
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
                        pw.Text(allocatedLabel, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate500)),
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
                        pw.Text(utilizedLabel, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand600)),
                        pw.SizedBox(height: 3),
                        pw.Text(formatCurrency(totalUtilized), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand900)),
                        pw.SizedBox(height: 1),
                        pw.Text('${utilizationPercentage.toStringAsFixed(1)}% $utilizedSuffix', style: const pw.TextStyle(fontSize: 7, color: WebReportTheme.brand700)),
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
                        pw.Text(remainingLabel, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF15803D))),
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
                lang == 'mr' ? 'वर्गवारी / शीर्ष' : (lang == 'hi' ? 'श्रेणी / शीर्ष' : 'Category / Head'),
                lang == 'mr' ? 'तरतूद' : (lang == 'hi' ? 'आवंटित' : 'Allocated'),
                lang == 'mr' ? 'खर्च' : (lang == 'hi' ? 'उपयोग' : 'Utilized'),
                lang == 'mr' ? 'प्रगती' : (lang == 'hi' ? 'प्रगति' : 'Progress'),
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
                  '${percent.toStringAsFixed(0)}% $utilizedSuffix',
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

    final fileName = 'Budget_Report_${year}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
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
