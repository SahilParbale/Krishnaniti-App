import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/ward_budget_model.dart';
import '../../providers/language_provider.dart';
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
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDateTime(now, activeLang);

    final hasCustomTitle = title != 'Ward Budget & Provision Report';
    final hasCustomSubtitle = subtitle != 'Financial Planning & Allocation Audit';
    final hasAreaFilter = areaFilter != null &&
        areaFilter.trim().isNotEmpty &&
        areaFilter != 'All' &&
        areaFilter != 'All Areas';

    final textCache = await PdfTranslationHelper.batchText(
      [
        if (hasCustomTitle) title,
        if (hasCustomSubtitle) subtitle,
        if (hasAreaFilter) areaFilter,
        for (final b in budgets) ...[b.category, b.area, b.status],
      ],
      activeLang,
    );

    final totalCount = budgets.length;
    final totalAllocated = budgets.fold<double>(0, (sum, b) => sum + b.totalAllocation);
    final totalUtilized = budgets.fold<double>(0, (sum, b) => sum + b.utilizedAmount);
    final totalRemaining = (totalAllocated - totalUtilized).clamp(0.0, double.infinity);
    final utilizationPercentage =
        totalAllocated > 0 ? (totalUtilized / totalAllocated) * 100 : 0.0;

    final effectiveTitle = hasCustomTitle
        ? PdfTranslationHelper.resolve(textCache, title, activeLang)
        : AppTranslations.pick(
            activeLang,
            en: 'Ward Budget & Provision Report',
            mr: 'प्रभाग अंदाजपत्रक आणि तरतूद अहवाल',
            hi: 'वार्ड बजट और प्रावधान रिपोर्ट',
          );
    final effectiveSubtitle = hasCustomSubtitle
        ? PdfTranslationHelper.resolve(textCache, subtitle, activeLang)
        : AppTranslations.pick(
            activeLang,
            en: 'Financial Planning & Allocation Audit',
            mr: 'आर्थिक नियोजन आणि तरतूद लेखापरीक्षण',
            hi: 'वित्तीय योजना और आवंटन ऑडिट',
          );

    final yearLabel = AppTranslations.pick(
      activeLang,
      en: 'Financial Year',
      mr: 'आर्थिक वर्ष',
      hi: 'वित्तीय वर्ष',
    );
    final dateLabel = AppTranslations.pick(
      activeLang,
      en: 'Date',
      mr: 'दिनांक',
      hi: 'दिनांक',
    );
    final headsLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Heads',
      mr: 'एकूण शीर्ष',
      hi: 'कुल शीर्ष',
    );
    final areaLabel = AppTranslations.pick(
      activeLang,
      en: 'Area',
      mr: 'परिसर',
      hi: 'क्षेत्र',
    );
    final allocatedLabel = AppTranslations.pick(
      activeLang,
      en: 'TOTAL ALLOCATED',
      mr: 'एकूण तरतूद',
      hi: 'कुल आवंटित',
    );
    final utilizedLabel = AppTranslations.pick(
      activeLang,
      en: 'TOTAL UTILIZED',
      mr: 'एकूण खर्च',
      hi: 'कुल उपयोग',
    );
    final remainingLabel = AppTranslations.pick(
      activeLang,
      en: 'REMAINING BALANCE',
      mr: 'शिल्लक निधी',
      hi: 'शेष राशि',
    );
    final utilizedSuffix = AppTranslations.pick(
      activeLang,
      en: 'utilized',
      mr: 'खर्च',
      hi: 'उपयोग',
    );
    final emptyMsg = AppTranslations.pick(
      activeLang,
      en: 'No ward budget records found for the selected year.',
      mr: 'निवडलेल्या वर्षासाठी प्रभाग अंदाजपत्रकाच्या नोंदी आढळल्या नाहीत.',
      hi: 'चयनित वर्ष के लिए कोई वार्ड बजट रिकॉर्ड नहीं मिला।',
    );

    String formatCurrency(double val) {
      final formatted = NumberFormat.decimalPattern('en_IN').format(val.round());
      return PdfTranslationHelper.formatCurrency(formatted, activeLang);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: effectiveTitle,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: effectiveTitle,
              subtitle: effectiveSubtitle,
              lang: activeLang,
              metaLines: [
                '$yearLabel: ${PdfTranslationHelper.formatNumber(year, activeLang)}',
                '$dateLabel: $nowStr',
                '$headsLabel: ${PdfTranslationHelper.formatNumber(totalCount, activeLang)}',
                if (hasAreaFilter)
                  '$areaLabel: ${_resolveArea(areaFilter, textCache, activeLang)}',
              ],
            ),

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
                        pw.Text(
                          allocatedLabel,
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: WebReportTheme.slate500,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          formatCurrency(totalAllocated),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: WebReportTheme.slate900,
                          ),
                        ),
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
                        pw.Text(
                          utilizedLabel,
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: WebReportTheme.brand600,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          formatCurrency(totalUtilized),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: WebReportTheme.brand900,
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          '${PdfTranslationHelper.formatNumber(utilizationPercentage.toStringAsFixed(1), activeLang)}% $utilizedSuffix',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: WebReportTheme.brand700,
                          ),
                        ),
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
                      border: pw.Border.all(
                        color: const PdfColor.fromInt(0xFFBBF7D0),
                        width: 0.5,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          remainingLabel,
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF15803D),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          formatCurrency(totalRemaining),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            if (budgets.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  emptyMsg,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: WebReportTheme.slate500,
                  ),
                ),
              )
            else
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
                  0: pw.FlexColumnWidth(0.7), // #
                  1: pw.FlexColumnWidth(3.4), // Category / Head
                  2: pw.FlexColumnWidth(2.0), // Allocated
                  3: pw.FlexColumnWidth(2.0), // Utilized
                  4: pw.FlexColumnWidth(1.9), // Progress
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Category / Head',
                    mr: 'वर्गवारी / शीर्ष',
                    hi: 'श्रेणी / शीर्ष',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Allocated',
                    mr: 'तरतूद',
                    hi: 'आवंटित',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Utilized',
                    mr: 'खर्च',
                    hi: 'उपयोग',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Progress',
                    mr: 'प्रगती',
                    hi: 'प्रगति',
                  ),
                ],
                data: List.generate(budgets.length, (index) {
                  final b = budgets[index];
                  final percent = b.totalAllocation > 0
                      ? (b.utilizedAmount / b.totalAllocation) * 100
                      : 0.0;
                  final categoryStr =
                      PdfTranslationHelper.resolve(textCache, b.category, activeLang);
                  final areaStr = b.area.trim().isNotEmpty
                      ? '\n${_resolveArea(b.area, textCache, activeLang)}'
                      : '';

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$categoryStr$areaStr',
                    formatCurrency(b.totalAllocation),
                    formatCurrency(b.utilizedAmount),
                    '${PdfTranslationHelper.formatNumber(percent.toStringAsFixed(0), activeLang)}% $utilizedSuffix',
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

    final asciiYear = AppTranslations.normalizeAsciiDigits(year);
    final fileName = 'Budget_Report_${asciiYear}_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: effectiveTitle,
        subtitle: effectiveSubtitle,
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

  static String _resolveArea(
    String? raw,
    Map<String, String> textCache,
    String lang,
  ) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final trimmed = raw.trim();
    final staticArea = AppTranslations.getAreaName(trimmed, lang);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(staticArea);
    if (staticArea != AppTranslations.formatDigits(trimmed, lang)) {
      return staticArea;
    }
    if (lang == 'en' && !hasDevanagari) {
      return staticArea;
    }
    return PdfTranslationHelper.resolve(textCache, trimmed, lang);
  }
}
