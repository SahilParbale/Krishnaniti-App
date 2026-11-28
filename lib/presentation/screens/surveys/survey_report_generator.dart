import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/survey_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class SurveyReportGenerator {
  SurveyReportGenerator._();

  static String _resolveArea(
    String? area,
    String lang,
    Map<String, String> textCache,
  ) {
    if (area == null || area.trim().isEmpty) return '-';
    final clean = area.trim();
    final staticArea = AppTranslations.getAreaName(clean, lang);
    final hasDev = RegExp(r'[\u0900-\u097F]').hasMatch(staticArea);
    final hasLat = RegExp(r'[A-Za-z]').hasMatch(staticArea);
    if (lang == 'en' && !hasDev) return staticArea;
    if ((lang == 'mr' || lang == 'hi') && hasDev && !hasLat) return staticArea;
    return PdfTranslationHelper.resolve(textCache, clean, lang);
  }

  static String _localizeSurveyStatus(
    String status,
    String lang,
    Map<String, String> textCache,
  ) {
    final lower = status.trim().toLowerCase();
    switch (lower) {
      case 'active':
        return AppTranslations.getStatus('Active', lang);
      case 'closed':
        return AppTranslations.getStatus('Closed', lang);
      case 'draft':
        return AppTranslations.pick(
          lang,
          en: 'Draft',
          mr: 'मसुदा',
          hi: 'ड्राफ्ट',
        );
      default:
        final mapped = AppTranslations.getStatus(status, lang);
        if (mapped.toLowerCase() != lower) return mapped;
        return PdfTranslationHelper.resolve(textCache, status, lang);
    }
  }

  static String _localizeQuestionType(SurveyQuestionType type, String lang) {
    switch (type) {
      case SurveyQuestionType.yesNo:
        return AppTranslations.pick(
          lang,
          en: 'Yes / No',
          mr: 'होय / नाही',
          hi: 'हाँ / नहीं',
        );
      case SurveyQuestionType.mcq:
        return AppTranslations.pick(
          lang,
          en: 'Multiple Choice',
          mr: 'बहुपर्यायी',
          hi: 'बहुविकल्पीय',
        );
      case SurveyQuestionType.rating:
        return AppTranslations.pick(
          lang,
          en: 'Rating (1-5)',
          mr: 'रेटिंग (१-५)',
          hi: 'रेटिंग (१-५)',
        );
    }
  }

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<SurveyModel> surveys,
    required Map<String, int> responseCounts,
    int totalVoters = 42560,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDate(DateTime.now(), activeLang);

    final totalCount = surveys.length;
    final activeCount =
        surveys.where((s) => s.status.toLowerCase() == 'active').length;
    final closedCount =
        surveys.where((s) => s.status.toLowerCase() == 'closed').length;
    final totalResponses = responseCounts.values.fold<int>(0, (sum, c) => sum + c);

    final textCache = await PdfTranslationHelper.batchText(
      [
        for (final s in surveys) ...[
          s.title,
          s.description,
          s.area,
          s.status,
          for (final q in s.questions) ...[
            q.text,
            ...q.options,
          ],
        ],
      ],
      activeLang,
    );

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Public Surveys',
      mr: 'सार्वजनिक सर्वेक्षणे',
      hi: 'सार्वजनिक सर्वेक्षण',
    );
    final continuationTitle = AppTranslations.pick(
      activeLang,
      en: 'Public Surveys & Polls',
      mr: 'सार्वजनिक सर्वेक्षणे व जनमत चाचणी',
      hi: 'सार्वजनिक सर्वेक्षण एवं जनमत',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Civic Polls & Citizen Opinion Analytics',
      mr: 'नागरी जनमत चाचणी आणि नागरिक मत विश्लेषण',
      hi: 'नागरिक सर्वेक्षण एवं जनमत विश्लेषण',
    );

    final hasQuestions = surveys.any((s) => s.questions.isNotEmpty);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
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
              dateFormatted: nowStr,
              totalCount: totalCount,
              lang: activeLang,
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
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Surveys',
                      mr: 'एकूण सर्वेक्षणे',
                      hi: 'कुल सर्वेक्षण',
                    ),
                    PdfTranslationHelper.formatNumber(totalCount, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.getStatus('Active', activeLang),
                    PdfTranslationHelper.formatNumber(activeCount, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.getStatus('Closed', activeLang),
                    PdfTranslationHelper.formatNumber(closedCount, activeLang),
                    highlightColor: WebReportTheme.slate600,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Responses Logged',
                      mr: 'नोंदवलेले प्रतिसाद',
                      hi: 'दर्ज प्रतिक्रियाएं',
                    ),
                    PdfTranslationHelper.formatNumber(totalResponses, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (surveys.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No public surveys found.',
                    mr: 'कोणतीही सार्वजनिक सर्वेक्षणे आढळली नाहीत.',
                    hi: 'कोई सार्वजनिक सर्वेक्षण नहीं मिला।',
                  ),
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: WebReportTheme.slate500,
                  ),
                ),
              )
            else ...[
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
                  1: pw.FlexColumnWidth(3.8),
                  2: pw.FlexColumnWidth(1.4),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(1.6),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Survey Title & Scope',
                    mr: 'सर्वेक्षण शीर्षक आणि कार्यक्षेत्र',
                    hi: 'सर्वेक्षण शीर्षक एवं कार्यक्षेत्र',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Status',
                    mr: 'स्थिती',
                    hi: 'स्थिति',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Questions',
                    mr: 'प्रश्न',
                    hi: 'प्रश्न',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Responses',
                    mr: 'प्रतिसाद',
                    hi: 'प्रतिक्रियाएं',
                  ),
                ],
                data: surveys.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final s = entry.value;
                  final resp = responseCounts[s.id] ?? 0;

                  final resolvedTitle = PdfTranslationHelper.resolve(
                    textCache,
                    s.title,
                    activeLang,
                  );
                  final descPart = s.description.trim().isNotEmpty
                      ? '\n${PdfTranslationHelper.resolve(textCache, s.description, activeLang)}'
                      : '';
                  final areaLabel = AppTranslations.pick(
                    activeLang,
                    en: 'Area',
                    mr: 'परिसर',
                    hi: 'क्षेत्र',
                  );
                  final areaPart = (s.area != null && s.area!.trim().isNotEmpty)
                      ? '\n$areaLabel: ${_resolveArea(s.area, activeLang, textCache)}'
                      : '';

                  final qsUnit = AppTranslations.pick(
                    activeLang,
                    en: 'Qs',
                    mr: 'प्रश्न',
                    hi: 'प्रश्न',
                  );
                  final respUnit = AppTranslations.pick(
                    activeLang,
                    en: 'responses',
                    mr: 'प्रतिसाद',
                    hi: 'प्रतिक्रियाएं',
                  );

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    '$resolvedTitle$descPart$areaPart',
                    _localizeSurveyStatus(s.status, activeLang, textCache),
                    '${PdfTranslationHelper.formatNumber(s.questions.length, activeLang)} $qsUnit',
                    '${PdfTranslationHelper.formatNumber(resp, activeLang)} $respUnit',
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
              if (hasQuestions) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'Survey Questions Breakdown',
                    mr: 'सर्वेक्षण प्रश्न तपशील',
                    hi: 'सर्वेक्षण प्रश्न विवरण',
                  ),
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: WebReportTheme.brand700,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...surveys.where((s) => s.questions.isNotEmpty).map((s) {
                  final sTitle = PdfTranslationHelper.resolve(
                    textCache,
                    s.title,
                    activeLang,
                  );
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: WebReportTheme.slate50,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(
                        color: WebReportTheme.slate200,
                        width: 0.6,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          sTitle,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: WebReportTheme.slate900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        ...s.questions.asMap().entries.map((qEntry) {
                          final qIdx = qEntry.key + 1;
                          final q = qEntry.value;
                          final qPrefix = AppTranslations.pick(
                            activeLang,
                            en: 'Q',
                            mr: 'प्र.',
                            hi: 'प्र.',
                          );
                          final qText = PdfTranslationHelper.resolve(
                            textCache,
                            q.text,
                            activeLang,
                          );
                          final qType = _localizeQuestionType(q.type, activeLang);
                          final optsText = q.options.isNotEmpty
                              ? q.options
                                  .map((o) => PdfTranslationHelper.resolve(
                                        textCache,
                                        o,
                                        activeLang,
                                      ))
                                  .join(', ')
                              : '';
                          final optsLabel = AppTranslations.pick(
                            activeLang,
                            en: 'Options',
                            mr: 'पर्याय',
                            hi: 'विकल्प',
                          );
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 3),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  '$qPrefix${PdfTranslationHelper.formatNumber(qIdx, activeLang)}. $qText ($qType)',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: WebReportTheme.slate800,
                                  ),
                                ),
                                if (optsText.isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(left: 10, top: 1),
                                    child: pw.Text(
                                      '$optsLabel: $optsText',
                                      style: const pw.TextStyle(
                                        fontSize: 7.5,
                                        color: WebReportTheme.slate500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ];
        },
      ),
    );

    final fileName =
        'Public_Surveys_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
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
