import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/complaint_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class WardProblemsReportGenerator {
  WardProblemsReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<ComplaintModel> problems,
    String? areaFilter,
    String? statusFilter,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDateTime(now, activeLang);

    final hasAreaFilter = areaFilter != null &&
        areaFilter.trim().isNotEmpty &&
        areaFilter != 'All' &&
        areaFilter != 'All Areas';
    final hasStatusFilter = statusFilter != null &&
        statusFilter.trim().isNotEmpty &&
        statusFilter != 'All';

    final textCache = await PdfTranslationHelper.batchText(
      [
        if (hasAreaFilter) areaFilter,
        if (hasStatusFilter) statusFilter,
        for (final p in problems) ...[
          p.title,
          p.description,
          p.category,
          p.area,
          p.location,
          p.ward,
          p.status,
        ],
      ],
      activeLang,
    );
    final nameCache = await PdfTranslationHelper.batchNames(
      [
        for (final p in problems) ...[p.citizenName, p.assignedStaffName],
      ],
      activeLang,
    );

    final total = problems.length;
    final pending = problems.where((p) => p.isPending).length;
    final inProgress =
        problems.where((p) => p.isInProgress || p.isAssigned).length;
    final resolved = problems.where((p) => p.isResolved).length;

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Ward Civic Issues',
      mr: 'प्रभाग नागरी समस्या',
      hi: 'वार्ड नागरिक समस्याएं',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Ward-wise Civic Issues & Problem Resolution Dossier',
      mr: 'प्रभागनिहाय नागरी समस्या आणि निराकरण अहवाल',
      hi: 'वार्ड-वार नागरिक समस्याएं एवं समाधान रिपोर्ट',
    );
    final dateLabel = AppTranslations.pick(
      activeLang,
      en: 'Date',
      mr: 'दिनांक',
      hi: 'दिनांक',
    );
    final foundLabel = AppTranslations.pick(
      activeLang,
      en: 'Found',
      mr: 'एकूण',
      hi: 'कुल',
    );
    final areaLabel = AppTranslations.pick(
      activeLang,
      en: 'Area',
      mr: 'परिसर',
      hi: 'क्षेत्र',
    );
    final statusLabel = AppTranslations.pick(
      activeLang,
      en: 'Status',
      mr: 'स्थिती',
      hi: 'स्थिति',
    );
    final categoryPrefix = AppTranslations.pick(
      activeLang,
      en: 'Category',
      mr: 'वर्गवारी',
      hi: 'श्रेणी',
    );
    final anonymousLabel = AppTranslations.pick(
      activeLang,
      en: 'Anonymous',
      mr: 'निनावी',
      hi: 'अनाम',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: reportTitle,
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
                '$dateLabel: $nowStr',
                '$foundLabel: ${PdfTranslationHelper.formatNumber(total, activeLang)}',
                if (hasAreaFilter)
                  '$areaLabel: ${_resolveArea(areaFilter, textCache, activeLang)}',
                if (hasStatusFilter)
                  '$statusLabel: ${_resolveStatus(statusFilter, textCache, activeLang)}',
              ],
            ),
            pw.SizedBox(height: 12),

            // Overview summary bar
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
                      en: 'Total Problems',
                      mr: 'एकूण समस्या',
                      hi: 'कुल समस्याएं',
                    ),
                    PdfTranslationHelper.formatNumber(total, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Pending',
                      mr: 'प्रलंबित',
                      hi: 'लंबित',
                    ),
                    PdfTranslationHelper.formatNumber(pending, activeLang),
                    highlightColor: PdfColors.amber800,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'In Progress',
                      mr: 'काम चालू',
                      hi: 'प्रगति पर',
                    ),
                    PdfTranslationHelper.formatNumber(inProgress, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Resolved',
                      mr: 'सोडवलेले',
                      hi: 'समाधान हुआ',
                    ),
                    PdfTranslationHelper.formatNumber(resolved, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (problems.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No ward problem records found for the selected view.',
                    mr: 'निवडलेल्या पर्यायासाठी प्रभाग समस्यांच्या नोंदी आढळल्या नाहीत.',
                    hi: 'चयनित दृश्य के लिए कोई वार्ड समस्या रिकॉर्ड नहीं मिला।',
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
                  1: pw.FlexColumnWidth(3.2),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(2.2),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.6),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Issue Title & Category',
                    mr: 'समस्येचे शीर्षक आणि वर्गवारी',
                    hi: 'समस्या शीर्षक और श्रेणी',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Location / Area',
                    mr: 'ठिकाण / परिसर',
                    hi: 'स्थान / क्षेत्र',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Citizen / Reporter',
                    mr: 'नागरिक / तक्रारदार',
                    hi: 'नागरिक / रिपोर्टकर्ता',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Status',
                    mr: 'स्थिती',
                    hi: 'स्थिति',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Date',
                    mr: 'दिनांक',
                    hi: 'दिनांक',
                  ),
                ],
                data: List.generate(problems.length, (index) {
                  final p = problems[index];
                  final titleStr =
                      PdfTranslationHelper.resolve(textCache, p.title, activeLang);
                  final catStr = p.category.trim().isNotEmpty
                      ? '\n$categoryPrefix: ${_resolveCategory(p.category, textCache, activeLang)}'
                      : '';
                  final rawArea = (p.area != null && p.area!.trim().isNotEmpty)
                      ? p.area!
                      : (p.location != null && p.location!.trim().isNotEmpty
                          ? p.location!
                          : (p.ward != null && p.ward!.trim().isNotEmpty
                              ? p.ward!
                              : ''));
                  final areaStr = rawArea.isNotEmpty
                      ? _resolveArea(rawArea, textCache, activeLang)
                      : '-';

                  final citizenName = (p.citizenName != null &&
                          p.citizenName!.trim().isNotEmpty)
                      ? PdfTranslationHelper.resolveName(
                          nameCache,
                          p.citizenName,
                          activeLang,
                          fallback: anonymousLabel,
                        )
                      : anonymousLabel;
                  final phoneStr = (p.citizenMobile != null &&
                          p.citizenMobile!.trim().isNotEmpty)
                      ? '\n${PdfTranslationHelper.formatNumber(p.citizenMobile!.trim(), activeLang)}'
                      : '';
                  final dateStr =
                      PdfTranslationHelper.formatDate(p.createdAt, activeLang);

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$titleStr$catStr',
                    areaStr,
                    '$citizenName$phoneStr',
                    _resolveStatus(p.status, textCache, activeLang),
                    dateStr,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName =
        'Ward_Problems_Report_${DateFormat('yyyyMMdd').format(now)}';
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

  static String _resolveCategory(
    String raw,
    Map<String, String> textCache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final staticType = AppTranslations.getComplaintType(trimmed, lang);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(staticType);
    if (staticType != AppTranslations.formatDigits(trimmed, lang)) {
      return AppTranslations.formatDigits(staticType, lang);
    }
    if (lang == 'en' && !hasDevanagari) {
      return AppTranslations.formatDigits(staticType, lang);
    }
    return PdfTranslationHelper.resolve(textCache, trimmed, lang);
  }

  static String _resolveStatus(
    String raw,
    Map<String, String> textCache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final staticStatus = AppTranslations.getStatus(trimmed, lang);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(staticStatus);
    if (staticStatus != trimmed &&
        !(lang != 'en' && !hasDevanagari)) {
      return PdfTranslationHelper.formatNumber(staticStatus, lang);
    }
    if (lang == 'en' && !hasDevanagari) {
      return PdfTranslationHelper.formatNumber(staticStatus, lang);
    }
    return PdfTranslationHelper.resolve(textCache, trimmed, lang);
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
