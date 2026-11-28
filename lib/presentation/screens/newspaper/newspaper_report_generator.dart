import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/newspaper_clipping_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class NewspaperReportGenerator {
  NewspaperReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<NewspaperClippingModel> clippings,
    String? sentimentFilter,
    String? newspaperFilter,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDateTime(DateTime.now(), activeLang);

    final toTranslate = <String>[];
    for (final c in clippings) {
      if (_knownNewspaper(c.newspaper, activeLang) == null &&
          c.newspaper.trim().isNotEmpty) {
        toTranslate.add(c.newspaper);
      }
      if (c.pageNumber != null &&
          c.pageNumber!.trim().isNotEmpty &&
          _formatPageLabel(c.pageNumber!, activeLang) == null) {
        toTranslate.add(c.pageNumber!);
      }
      if (!_hasDirectMarathi(c.titleMarathi, activeLang)) {
        final rawTitle = c.title.trim().isNotEmpty ? c.title : c.titleMarathi;
        if (rawTitle.trim().isNotEmpty) toTranslate.add(rawTitle);
      }
      if (!_hasDirectMarathi(c.descriptionMarathi, activeLang)) {
        final rawDesc =
            c.description.trim().isNotEmpty ? c.description : c.descriptionMarathi;
        if (rawDesc.trim().isNotEmpty) toTranslate.add(rawDesc);
      }
    }
    if (newspaperFilter != null &&
        newspaperFilter.trim().isNotEmpty &&
        newspaperFilter.trim().toLowerCase() != 'all' &&
        _knownNewspaper(newspaperFilter, activeLang) == null) {
      toTranslate.add(newspaperFilter);
    }

    final textCache = await PdfTranslationHelper.batchText(toTranslate, activeLang);

    final totalCount = clippings.length;
    final positiveCount = clippings.where((c) => c.isPositive).length;
    final negativeCount = clippings.where((c) => !c.isPositive).length;
    final uniquePapers = clippings.map((c) => c.newspaper).toSet().length;

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Newspaper Clippings',
      mr: 'वृत्तपत्र कात्रणे',
      hi: 'समाचार पत्र कतरनें',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Report of Newspaper Clippings & Media Coverage',
      mr: 'वृत्तपत्र कात्रणे व प्रसिद्धी अहवाल',
      hi: 'समाचार पत्र कतरनों एवं मीडिया कवरेज की रिपोर्ट',
    );
    final foundLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Clippings',
      mr: 'एकूण कात्रणे',
      hi: 'कुल कतरनें',
    );

    final hasSent = sentimentFilter != null &&
        sentimentFilter.trim().isNotEmpty &&
        sentimentFilter.trim().toLowerCase() != 'all';
    final hasPaper = newspaperFilter != null &&
        newspaperFilter.trim().isNotEmpty &&
        newspaperFilter.trim().toLowerCase() != 'all';
    final metaLines = <String>[];
    if (hasSent || hasPaper) {
      final datePrefix =
          AppTranslations.pick(activeLang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:');
      metaLines.add('$datePrefix $nowStr');
      if (hasPaper) {
        final paperPrefix = AppTranslations.pick(
          activeLang,
          en: 'Newspaper:',
          mr: 'वृत्तपत्र:',
          hi: 'समाचार पत्र:',
        );
        final resolvedPaper = _knownNewspaper(newspaperFilter, activeLang) ??
            PdfTranslationHelper.resolve(textCache, newspaperFilter, activeLang);
        metaLines.add('$paperPrefix $resolvedPaper');
      }
      if (hasSent) {
        final sentPrefix = AppTranslations.pick(
          activeLang,
          en: 'Sentiment:',
          mr: 'भाव:',
          hi: 'भावना:',
        );
        metaLines.add('$sentPrefix ${_sentimentFromFilter(sentimentFilter, activeLang)}');
      }
      metaLines.add('$foundLabel: ${PdfTranslationHelper.formatNumber(totalCount, activeLang)}');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
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
              dateFormatted: metaLines.isEmpty ? nowStr : null,
              totalCount: metaLines.isEmpty ? totalCount : null,
              foundLabel: foundLabel,
              metaLines: metaLines.isNotEmpty ? metaLines : null,
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary metrics
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
                    AppTranslations.pick(activeLang, en: 'Total Clippings', mr: 'एकूण कात्रणे', hi: 'कुल कतरनें'),
                    PdfTranslationHelper.formatNumber(totalCount, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Positive Coverage', mr: 'सकारात्मक बातम्या', hi: 'सकारात्मक कवरेज'),
                    PdfTranslationHelper.formatNumber(positiveCount, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Critical Issues', mr: 'दखलपात्र समस्या', hi: 'गंभीर मुद्दे'),
                    PdfTranslationHelper.formatNumber(negativeCount, activeLang),
                    highlightColor: PdfColors.red700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Dailies Tracked', mr: 'नोंदवलेली वृत्तपत्रे', hi: 'ट्रैक किए गए अखबार'),
                    PdfTranslationHelper.formatNumber(uniquePapers, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (clippings.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No newspaper clippings found.',
                    mr: 'कोणतीही वृत्तपत्र कात्रणे सापडली नाहीत.',
                    hi: 'कोई समाचार पत्र कतरन नहीं मिली।',
                  ),
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
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(1.6),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(4.2),
                  4: pw.FlexColumnWidth(1.4),
                },
                headers: [
                  '#',
                  AppTranslations.getReportColumn('date', activeLang),
                  AppTranslations.pick(activeLang, en: 'Newspaper & Page', mr: 'वृत्तपत्र व पान क्र.', hi: 'समाचार पत्र एवं पृष्ठ'),
                  AppTranslations.pick(activeLang, en: 'Title & Coverage Summary', mr: 'मथळा व बातमीचा गोषवारा', hi: 'शीर्षक एवं कवरेज सारांश'),
                  AppTranslations.pick(activeLang, en: 'Sentiment', mr: 'सूर / भाव', hi: 'भावना'),
                ],
                data: clippings.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final c = entry.value;

                  final dateStr =
                      PdfTranslationHelper.parseAndFormatDateString(c.date, activeLang);
                  final newspaperStr = _knownNewspaper(c.newspaper, activeLang) ??
                      PdfTranslationHelper.resolve(textCache, c.newspaper, activeLang);

                  String pageStr = '';
                  if (c.pageNumber != null && c.pageNumber!.trim().isNotEmpty) {
                    final formattedPage = _formatPageLabel(c.pageNumber!, activeLang) ??
                        PdfTranslationHelper.resolve(textCache, c.pageNumber!, activeLang);
                    pageStr = ' ($formattedPage)';
                  }

                  final titleText = _hasDirectMarathi(c.titleMarathi, activeLang)
                      ? AppTranslations.formatDigits(c.titleMarathi.trim(), activeLang)
                      : PdfTranslationHelper.resolve(
                          textCache,
                          c.title.trim().isNotEmpty ? c.title : c.titleMarathi,
                          activeLang,
                        );
                  final descText = _hasDirectMarathi(c.descriptionMarathi, activeLang)
                      ? AppTranslations.formatDigits(c.descriptionMarathi.trim(), activeLang)
                      : (c.description.trim().isNotEmpty ||
                              c.descriptionMarathi.trim().isNotEmpty)
                          ? PdfTranslationHelper.resolve(
                              textCache,
                              c.description.trim().isNotEmpty
                                  ? c.description
                                  : c.descriptionMarathi,
                              activeLang,
                            )
                          : '';
                  final descPart =
                      (descText.isNotEmpty && descText != '-') ? '\n$descText' : '';

                  final sentimentLabel = c.isPositive
                      ? AppTranslations.pick(activeLang, en: 'Positive', mr: 'सकारात्मक', hi: 'सकारात्मक')
                      : AppTranslations.pick(activeLang, en: 'Critical', mr: 'दखलपात्र / नकारात्मक', hi: 'गंभीर / नकारात्मक');

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    dateStr,
                    '$newspaperStr$pageStr',
                    '$titleText$descPart',
                    sentimentLabel,
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Newspaper_Clippings_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
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

  static bool _hasDirectMarathi(String? text, String lang) {
    if (lang != 'mr' || text == null || text.trim().isEmpty) return false;
    return DynamicTranslationService.containsDevanagari(text.trim());
  }

  static String? _knownNewspaper(String raw, String lang) {
    switch (raw.trim().toLowerCase()) {
      case 'sakal':
      case 'सकाळ':
        return AppTranslations.pick(lang, en: 'Sakal', mr: 'सकाळ', hi: 'सकाल');
      case 'lokmat':
      case 'लोकमत':
        return AppTranslations.pick(lang, en: 'Lokmat', mr: 'लोकमत', hi: 'लोकमत');
      case 'maharashtra times':
      case 'महाराष्ट्र टाइम्स':
        return AppTranslations.pick(lang, en: 'Maharashtra Times', mr: 'महाराष्ट्र टाइम्स', hi: 'महाराष्ट्र टाइम्स');
      case 'pudhari':
      case 'पुढारी':
        return AppTranslations.pick(lang, en: 'Pudhari', mr: 'पुढारी', hi: 'पुढारी');
      case 'loksatta':
      case 'लोकसत्ता':
        return AppTranslations.pick(lang, en: 'Loksatta', mr: 'लोकसत्ता', hi: 'लोकसत्ता');
      case 'the indian express':
      case 'indian express':
        return AppTranslations.pick(lang, en: 'The Indian Express', mr: 'द इंडियन एक्स्प्रेस', hi: 'द इंडियन एक्सप्रेस');
      case 'kesari':
      case 'केसरी':
        return AppTranslations.pick(lang, en: 'Kesari', mr: 'केसरी', hi: 'केसरी');
      case 'prabhat':
      case 'प्रभात':
        return AppTranslations.pick(lang, en: 'Prabhat', mr: 'प्रभात', hi: 'प्रभात');
      case 'punyanagari':
      case 'पुण्यनगरी':
        return AppTranslations.pick(lang, en: 'Punyanagari', mr: 'पुण्यनगरी', hi: 'पुण्यनगरी');
      case 'saamana':
      case 'सामना':
        return AppTranslations.pick(lang, en: 'Saamana', mr: 'सामना', hi: 'सामना');
      default:
        return null;
    }
  }

  static String? _formatPageLabel(String raw, String lang) {
    final ascii = AppTranslations.normalizeAsciiDigits(raw.trim());
    final match = RegExp(
      r'^(?:Page|Pg\.?|पान|पृष्ठ)\s*(?:क्र\.|नं\.|No\.?)?\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(ascii);
    if (match != null) {
      final numStr = PdfTranslationHelper.formatNumber(match.group(1)!, lang);
      return AppTranslations.pick(
        lang,
        en: 'Page $numStr',
        mr: 'पान $numStr',
        hi: 'पृष्ठ $numStr',
      );
    }
    return null;
  }

  static String _sentimentFromFilter(String raw, String lang) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'positive') {
      return AppTranslations.pick(lang, en: 'Positive', mr: 'सकारात्मक', hi: 'सकारात्मक');
    }
    if (lower == 'negative' || lower == 'critical') {
      return AppTranslations.pick(lang, en: 'Critical', mr: 'दखलपात्र / नकारात्मक', hi: 'गंभीर / नकारात्मक');
    }
    return AppTranslations.pick(lang, en: 'Neutral', mr: 'तटस्थ', hi: 'तटस्थ');
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
