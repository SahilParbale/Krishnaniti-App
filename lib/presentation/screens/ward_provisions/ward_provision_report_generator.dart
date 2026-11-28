import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/ward_provision_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class WardProvisionReportGenerator {
  WardProvisionReportGenerator._();

  static Future<void> generateAndPrintProvisionReport({
    BuildContext? context,
    required List<WardProvisionModel> provisions,
    required String year,
    String? categoryFilter,
    String? statusFilter,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);

    final hasCategoryFilter = categoryFilter != null &&
        categoryFilter.trim().isNotEmpty &&
        categoryFilter != 'All';
    final hasStatusFilter = statusFilter != null &&
        statusFilter.trim().isNotEmpty &&
        statusFilter != 'All';

    final textCache = await PdfTranslationHelper.batchText(
      [
        if (hasCategoryFilter) categoryFilter,
        if (hasStatusFilter) statusFilter,
        for (final p in provisions) ...[
          p.title,
          p.description,
          p.category,
          p.area,
          p.status,
        ],
      ],
      activeLang,
    );

    final totalCount = provisions.length;
    final totalRequested =
        provisions.fold<double>(0, (sum, p) => sum + p.requestedAmount);
    final totalSanctioned =
        provisions.fold<double>(0, (sum, p) => sum + (p.sanctionedAmount ?? 0));

    final approvedCount =
        provisions.where((p) => p.status.toLowerCase() == 'approved').length;
    final partialCount = provisions
        .where((p) => p.status.toLowerCase().contains('partially'))
        .length;
    final pendingCount =
        provisions.where((p) => p.status.toLowerCase() == 'pending').length;

    String fmtCurrency(double amount) {
      final formatted = NumberFormat.decimalPattern('en_IN').format(amount.round());
      return PdfTranslationHelper.formatCurrency(formatted, activeLang);
    }

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Ward Provisions',
      mr: 'प्रभागनिहाय तरतूद',
      hi: 'वार्ड वार प्रावधान',
    );
    final continuationTitle = AppTranslations.pick(
      activeLang,
      en: 'Ward Provisions & Budget Allocations',
      mr: 'प्रभागनिहाय तरतूद आणि निधी वाटप',
      hi: 'वार्ड प्रावधान और बजट आवंटन',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Capital Budget Allocations & Sanctions Dossier',
      mr: 'भांडवली निधी तरतूद आणि मंजुरी अहवाल',
      hi: 'पूंजीगत बजट आवंटन और स्वीकृति विवरण',
    );
    final yearLabel = AppTranslations.pick(
      activeLang,
      en: 'Financial Year',
      mr: 'आर्थिक वर्ष',
      hi: 'वित्तीय वर्ष',
    );
    final totalRecordsLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Records',
      mr: 'एकूण नोंदी',
      hi: 'कुल रिकॉर्ड',
    );
    final reqShortLabel = AppTranslations.pick(
      activeLang,
      en: 'Req',
      mr: 'मागणी',
      hi: 'मांग',
    );
    final sancShortLabel = AppTranslations.pick(
      activeLang,
      en: 'Sanc',
      mr: 'मंजूर',
      hi: 'स्वीकृत',
    );
    final categoryLabel = AppTranslations.pick(
      activeLang,
      en: 'Category',
      mr: 'वर्गवारी',
      hi: 'श्रेणी',
    );
    final statusLabel = AppTranslations.pick(
      activeLang,
      en: 'Status',
      mr: 'स्थिती',
      hi: 'स्थिति',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: continuationTitle,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) =>
            WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: reportTitle,
              subtitle: reportSubtitle,
              lang: activeLang,
              metaLines: [
                '$yearLabel: ${PdfTranslationHelper.formatNumber(year, activeLang)}',
                '$totalRecordsLabel: ${PdfTranslationHelper.formatNumber(totalCount, activeLang)}',
                '$reqShortLabel: ${fmtCurrency(totalRequested)} | $sancShortLabel: ${fmtCurrency(totalSanctioned)}',
                if (hasCategoryFilter)
                  '$categoryLabel: ${PdfTranslationHelper.resolve(textCache, categoryFilter, activeLang)}',
                if (hasStatusFilter)
                  '$statusLabel: ${_resolveStatus(statusFilter, textCache, activeLang)}',
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary KPIs matching web styling
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Proposals',
                      mr: 'एकूण प्रस्ताव',
                      hi: 'कुल प्रस्ताव',
                    ),
                    PdfTranslationHelper.formatNumber(totalCount, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Requested',
                      mr: 'मागणी रक्कम',
                      hi: 'मांगी गई राशि',
                    ),
                    fmtCurrency(totalRequested),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Sanctioned',
                      mr: 'मंजूर रक्कम',
                      hi: 'स्वीकृत राशि',
                    ),
                    fmtCurrency(totalSanctioned),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Approved',
                      mr: 'मंजूर',
                      hi: 'स्वीकृत',
                    ),
                    PdfTranslationHelper.formatNumber(approvedCount, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Partial / Pending',
                      mr: 'अंशतः / प्रलंबित',
                      hi: 'आंशिक / लंबित',
                    ),
                    PdfTranslationHelper.formatNumber(
                      partialCount + pendingCount,
                      activeLang,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (provisions.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No ward provision records found for the selected view.',
                    mr: 'निवडलेल्या पर्यायासाठी प्रभाग तरतुदीच्या नोंदी आढळल्या नाहीत.',
                    hi: 'चयनित दृश्य के लिए कोई वार्ड प्रावधान रिकॉर्ड नहीं मिला।',
                  ),
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: WebReportTheme.slate500,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(1.8),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(1.8),
                  5: pw.FlexColumnWidth(1.8),
                  6: pw.FlexColumnWidth(1.4),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Project Title & Category',
                    mr: 'प्रकल्प शीर्षक आणि वर्गवारी',
                    hi: 'परियोजना शीर्षक और श्रेणी',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Area',
                    mr: 'परिसर',
                    hi: 'क्षेत्र',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Letter Ref',
                    mr: 'पत्र संदर्भ',
                    hi: 'पत्र संदर्भ',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Requested',
                    mr: 'मागणी',
                    hi: 'मांग',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Sanctioned',
                    mr: 'मंजूर',
                    hi: 'स्वीकृत',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Status',
                    mr: 'स्थिती',
                    hi: 'स्थिति',
                  ),
                ],
                data: List.generate(provisions.length, (index) {
                  final p = provisions[index];
                  final titleStr =
                      PdfTranslationHelper.resolve(textCache, p.title, activeLang);
                  final catStr = p.category.trim().isNotEmpty
                      ? '\n$categoryLabel: ${PdfTranslationHelper.resolve(textCache, p.category, activeLang)}'
                      : '';
                  final reqStr = fmtCurrency(p.requestedAmount);
                  final sancStr = p.sanctionedAmount != null
                      ? fmtCurrency(p.sanctionedAmount!)
                      : '--';
                  final areaStr = p.area.trim().isNotEmpty
                      ? _resolveArea(p.area, textCache, activeLang)
                      : '-';
                  final letterRefStr = p.letterReference.trim().isNotEmpty
                      ? PdfTranslationHelper.formatNumber(
                          p.letterReference.trim(),
                          activeLang,
                        )
                      : '-';

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$titleStr$catStr',
                    areaStr,
                    letterRefStr,
                    reqStr,
                    sancStr,
                    _resolveStatus(p.status, textCache, activeLang),
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final asciiYear = AppTranslations.normalizeAsciiDigits(year);
    final fileName =
        'Ward_Provisions_Report_${asciiYear}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: reportTitle,
        subtitle: reportSubtitle,
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

  static String _resolveStatus(
    String raw,
    Map<String, String> textCache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    switch (trimmed.toLowerCase()) {
      case 'approved':
        return AppTranslations.pick(
          lang,
          en: 'Approved',
          mr: 'मंजूर',
          hi: 'स्वीकृत',
        );
      case 'partially approved':
      case 'partially_approved':
      case 'partial':
        return AppTranslations.pick(
          lang,
          en: 'Partially Approved',
          mr: 'अंशतः मंजूर',
          hi: 'आंशिक रूप से स्वीकृत',
        );
      case 'rejected':
        return AppTranslations.pick(
          lang,
          en: 'Rejected',
          mr: 'नाकारले',
          hi: 'अस्वीकृत',
        );
      case 'pending':
        return AppTranslations.pick(
          lang,
          en: 'Pending',
          mr: 'प्रलंबित',
          hi: 'लंबित',
        );
      default:
        final staticMatch = AppTranslations.getStatus(trimmed, lang);
        if (staticMatch != trimmed) {
          return PdfTranslationHelper.formatNumber(staticMatch, lang);
        }
        return PdfTranslationHelper.resolve(textCache, trimmed, lang);
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

  static pw.Widget _buildSummaryItem(
    String label,
    String value, {
    PdfColor? highlightColor,
  }) {
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
