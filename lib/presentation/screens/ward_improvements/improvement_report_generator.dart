import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/improvement_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class ImprovementReportGenerator {
  ImprovementReportGenerator._();

  static Future<void> generateAndPrintImprovementReport({
    BuildContext? context,
    required List<ImprovementModel> improvements,
    String? statusFilter,
    String? areaFilter,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDateTime(now, activeLang);

    final hasStatusFilter = statusFilter != null &&
        statusFilter.trim().isNotEmpty &&
        statusFilter != 'All';
    final hasAreaFilter = areaFilter != null &&
        areaFilter.trim().isNotEmpty &&
        areaFilter != 'All' &&
        areaFilter != 'All Areas';

    final textCache = await PdfTranslationHelper.batchText(
      [
        if (hasStatusFilter) statusFilter,
        if (hasAreaFilter) areaFilter,
        for (final item in improvements) ...[
          item.title,
          item.description,
          item.location,
          item.area,
          item.status,
        ],
      ],
      activeLang,
    );

    final total = improvements.length;
    final complete =
        improvements.where((i) => i.status.toLowerCase() == 'complete').length;
    final inProgress = improvements
        .where((i) => i.status.toLowerCase().contains('progress'))
        .length;
    final planned =
        improvements.where((i) => i.status.toLowerCase() == 'planned').length;
    final pending =
        improvements.where((i) => i.status.toLowerCase() == 'pending').length;

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Ward Improvements',
      mr: 'प्रभाग सुधारणा',
      hi: 'वार्ड सुधार',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Identified ward improvement proposals and development scope',
      mr: 'प्रभागातील ओळखलेल्या सुधारणांचे प्रस्ताव आणि विकास कामे',
      hi: 'वार्ड में चिन्हित सुधार प्रस्ताव और विकास कार्य विवरण',
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
    final filterLabel = AppTranslations.pick(
      activeLang,
      en: 'Filter',
      mr: 'स्थिती',
      hi: 'स्थिति',
    );
    final areaLabel = AppTranslations.pick(
      activeLang,
      en: 'Area',
      mr: 'परिसर',
      hi: 'क्षेत्र',
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
                  '$filterLabel: ${_resolveStatus(statusFilter, textCache, activeLang)}',
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
                      en: 'Total Proposals',
                      mr: 'एकूण प्रस्ताव',
                      hi: 'कुल प्रस्ताव',
                    ),
                    PdfTranslationHelper.formatNumber(total, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Completed',
                      mr: 'पूर्ण',
                      hi: 'पूर्ण',
                    ),
                    PdfTranslationHelper.formatNumber(complete, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'In Progress',
                      mr: 'प्रगतीपथावर',
                      hi: 'प्रगति पर',
                    ),
                    PdfTranslationHelper.formatNumber(inProgress, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Planned',
                      mr: 'नियोजित',
                      hi: 'योजनाबद्ध',
                    ),
                    PdfTranslationHelper.formatNumber(planned, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Pending',
                      mr: 'प्रलंबित',
                      hi: 'लंबित',
                    ),
                    PdfTranslationHelper.formatNumber(pending, activeLang),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (improvements.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No ward improvement records found for the selected view.',
                    mr: 'निवडलेल्या पर्यायासाठी प्रभाग सुधारणांच्या नोंदी आढळल्या नाहीत.',
                    hi: 'चयनित दृश्य के लिए कोई वार्ड सुधार रिकॉर्ड नहीं मिला।',
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
                  1: pw.FlexColumnWidth(3.5),
                  2: pw.FlexColumnWidth(2.5),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(1.5),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Proposal Title & Description',
                    mr: 'प्रस्ताव शीर्षक आणि तपशील',
                    hi: 'प्रस्ताव शीर्षक और विवरण',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Location / Area',
                    mr: 'ठिकाण / परिसर',
                    hi: 'स्थान / क्षेत्र',
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
                data: List.generate(improvements.length, (index) {
                  final item = improvements[index];
                  final titleStr =
                      PdfTranslationHelper.resolve(textCache, item.title, activeLang);
                  final descPart = item.description.trim().isNotEmpty
                      ? '\n${PdfTranslationHelper.resolve(textCache, item.description, activeLang)}'
                      : '';
                  final locStr = item.location.trim().isNotEmpty
                      ? PdfTranslationHelper.resolve(
                          textCache,
                          item.location,
                          activeLang,
                        )
                      : '';
                  final areaStr = item.area.trim().isNotEmpty
                      ? _resolveArea(item.area, textCache, activeLang)
                      : '';
                  final locAreaStr = locStr.isNotEmpty && areaStr.isNotEmpty
                      ? '$locStr ($areaStr)'
                      : (locStr.isNotEmpty
                          ? locStr
                          : (areaStr.isNotEmpty ? areaStr : '-'));

                  String dateStr = '-';
                  if (item.createdAt.trim().isNotEmpty) {
                    final dt = DateTime.tryParse(item.createdAt.trim());
                    dateStr = dt != null
                        ? PdfTranslationHelper.formatDate(
                            dt,
                            activeLang,
                            pattern: 'MMM d, yyyy',
                          )
                        : PdfTranslationHelper.parseAndFormatDateString(
                            item.createdAt,
                            activeLang,
                          );
                  }

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$titleStr$descPart',
                    locAreaStr,
                    _resolveStatus(item.status, textCache, activeLang),
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
        'Ward_Improvements_Report_${DateFormat('yyyyMMdd').format(now)}';
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
      case 'complete':
      case 'completed':
        return AppTranslations.pick(
          lang,
          en: 'Complete',
          mr: 'पूर्ण झाले',
          hi: 'पूर्ण',
        );
      case 'in progress':
      case 'inprogress':
        return AppTranslations.pick(
          lang,
          en: 'In Progress',
          mr: 'प्रगतीपथावर',
          hi: 'प्रगति पर',
        );
      case 'planned':
        return AppTranslations.pick(
          lang,
          en: 'Planned',
          mr: 'नियोजित',
          hi: 'योजनाबद्ध',
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
