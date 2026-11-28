import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/media_tracking_model.dart';
import '../../../data/models/social_post_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class MediaTrackingReportGenerator {
  MediaTrackingReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<MediaTrackingArticleModel> articles,
    String? profileFilter,
    String? sentimentFilter,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDateTime(DateTime.now(), activeLang);

    final toTranslate = <String>[];
    final namesToTransliterate = <String>[];

    for (final a in articles) {
      if (a.source.trim().isNotEmpty) toTranslate.add(a.source);
      if (a.time.trim().isNotEmpty) toTranslate.add(a.time);
      if (!_hasDirectMarathi(a.titleMarathi, activeLang)) {
        final rawTitle = a.title.trim().isNotEmpty ? a.title : a.titleMarathi;
        if (rawTitle.trim().isNotEmpty) toTranslate.add(rawTitle);
      }
      if (!_hasDirectMarathi(a.summaryMarathi, activeLang)) {
        final rawSummary =
            a.summary.trim().isNotEmpty ? a.summary : a.summaryMarathi;
        if (rawSummary.trim().isNotEmpty) toTranslate.add(rawSummary);
      }
      if (a.personTracked.trim().isNotEmpty &&
          _knownSubjectLabel(a.personTracked, activeLang) == null) {
        if (_isSubjectPhrase(a.personTracked)) {
          toTranslate.add(a.personTracked);
        } else {
          namesToTransliterate.add(a.personTracked);
        }
      }
      if (_knownSourceType(a.sourceType, activeLang) == null &&
          a.sourceType.trim().isNotEmpty) {
        toTranslate.add(a.sourceType);
      }
    }
    if (profileFilter != null &&
        profileFilter.trim().isNotEmpty &&
        profileFilter.trim().toLowerCase() != 'all') {
      toTranslate.add(profileFilter);
    }

    final results = await Future.wait([
      PdfTranslationHelper.batchText(toTranslate, activeLang),
      PdfTranslationHelper.batchNames(namesToTransliterate, activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final totalCount = articles.length;
    final positiveCount = articles.where((a) => a.isPositive).length;
    final negativeCount = articles.where((a) => a.isNegative).length;
    final totalReach = articles.fold<int>(0, (acc, a) => acc + a.reachEstimate);

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Digital Media Monitoring',
      mr: 'डिजिटल माध्यम मागोवा',
      hi: 'डिजिटल मीडिया ट्रैकिंग',
    );
    final contTitle = AppTranslations.pick(
      activeLang,
      en: 'Media Monitoring',
      mr: 'माध्यम मागोवा',
      hi: 'मीडिया ट्रैकिंग',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Live Online News Portals & Press Mentions Tracker',
      mr: 'ऑनलाइन बातम्या पोर्टल्स व प्रसिद्धी उल्लेख मागोवा अहवाल',
      hi: 'ऑनलाइन समाचार पोर्टल एवं प्रेस उल्लेख ट्रैकर रिपोर्ट',
    );
    final foundLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Mentions',
      mr: 'एकूण उल्लेख',
      hi: 'कुल उल्लेख',
    );

    final metaLines = <String>[];
    final hasProfile = profileFilter != null &&
        profileFilter.trim().isNotEmpty &&
        profileFilter.trim().toLowerCase() != 'all';
    final hasSentiment = sentimentFilter != null &&
        sentimentFilter.trim().isNotEmpty &&
        sentimentFilter.trim().toLowerCase() != 'all';
    if (hasProfile || hasSentiment) {
      final datePrefix =
          AppTranslations.pick(activeLang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:');
      metaLines.add('$datePrefix $nowStr');
      if (hasProfile) {
        final profPrefix =
            AppTranslations.pick(activeLang, en: 'Profile:', mr: 'प्रोफाईल:', hi: 'प्रोफ़ाइल:');
        metaLines.add('$profPrefix ${_resolveProfileFilter(profileFilter, textCache, activeLang)}');
      }
      if (hasSentiment) {
        final sentPrefix =
            AppTranslations.pick(activeLang, en: 'Sentiment:', mr: 'भाव:', hi: 'भावना:');
        metaLines.add('$sentPrefix ${_sentimentLabel(sentimentFilter, activeLang)}');
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
            title: contTitle,
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
                    AppTranslations.pick(activeLang, en: 'Total Mentions', mr: 'एकूण उल्लेख', hi: 'कुल उल्लेख'),
                    PdfTranslationHelper.formatNumber(totalCount, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Positive Press', mr: 'सकारात्मक कव्हरेज', hi: 'सकारात्मक कवरेज'),
                    PdfTranslationHelper.formatNumber(positiveCount, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Critical Issues', mr: 'दखलपात्र समस्या', hi: 'गंभीर मुद्दे'),
                    PdfTranslationHelper.formatNumber(negativeCount, activeLang),
                    highlightColor: PdfColors.red700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Est. Digital Reach', mr: 'अंदाजे डिजिटल पोहोच', hi: 'अनुमानित डिजिटल पहुंच'),
                    PdfTranslationHelper.formatNumber(totalReach.toLocaleString(), activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (articles.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No media mentions or tracked articles found.',
                    mr: 'कोणतेही माध्यम उल्लेख किंवा बातम्या आढळल्या नाहीत.',
                    hi: 'कोई मीडिया उल्लेख या ट्रैक किया गया लेख नहीं मिला।',
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
                  1: pw.FlexColumnWidth(1.8),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(1.8),
                  4: pw.FlexColumnWidth(3.8),
                  5: pw.FlexColumnWidth(1.4),
                },
                headers: [
                  '#',
                  AppTranslations.getReportColumn('date', activeLang),
                  AppTranslations.pick(activeLang, en: 'News Source', mr: 'बातमीचे माध्यम', hi: 'समाचार स्रोत'),
                  AppTranslations.pick(activeLang, en: 'Tracked Subject', mr: 'संबंधित विषय / व्यक्ती', hi: 'ट्रैक किया गया विषय'),
                  AppTranslations.pick(activeLang, en: 'Headline & Summary', mr: 'मथळा व सारांश', hi: 'शीर्षक एवं सारांश'),
                  AppTranslations.pick(activeLang, en: 'Sentiment', mr: 'सूर / भाव', hi: 'भावना'),
                ],
                data: articles.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final a = entry.value;

                  final dateStr =
                      PdfTranslationHelper.parseAndFormatDateString(a.date, activeLang);
                  final timeStr = a.time.trim().isNotEmpty
                      ? '\n${PdfTranslationHelper.resolve(textCache, a.time, activeLang)}'
                      : '';
                  final sourceStr =
                      PdfTranslationHelper.resolve(textCache, a.source, activeLang);
                  final sourceTypeLabel = _knownSourceType(a.sourceType, activeLang) ??
                      PdfTranslationHelper.resolve(textCache, a.sourceType, activeLang);

                  final subjectStr = _knownSubjectLabel(a.personTracked, activeLang) ??
                      (_isSubjectPhrase(a.personTracked)
                          ? PdfTranslationHelper.resolve(
                              textCache, a.personTracked, activeLang)
                          : PdfTranslationHelper.resolveName(
                              nameCache, a.personTracked, activeLang));

                  final titleText = _hasDirectMarathi(a.titleMarathi, activeLang)
                      ? AppTranslations.formatDigits(a.titleMarathi.trim(), activeLang)
                      : PdfTranslationHelper.resolve(
                          textCache,
                          a.title.trim().isNotEmpty ? a.title : a.titleMarathi,
                          activeLang,
                        );
                  final summaryText = _hasDirectMarathi(a.summaryMarathi, activeLang)
                      ? AppTranslations.formatDigits(a.summaryMarathi.trim(), activeLang)
                      : (a.summary.trim().isNotEmpty || a.summaryMarathi.trim().isNotEmpty)
                          ? PdfTranslationHelper.resolve(
                              textCache,
                              a.summary.trim().isNotEmpty
                                  ? a.summary
                                  : a.summaryMarathi,
                              activeLang,
                            )
                          : '';

                  final headlineSummary = summaryText.isNotEmpty && summaryText != '-'
                      ? '$titleText\n$summaryText'
                      : titleText;

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    '$dateStr$timeStr',
                    '$sourceStr\n($sourceTypeLabel)',
                    subjectStr,
                    headlineSummary,
                    _sentimentLabel(a.sentiment, activeLang),
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Media_Tracking_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
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

  static String? _knownSourceType(String sourceType, String lang) {
    switch (sourceType.trim().toLowerCase()) {
      case 'portal':
        return AppTranslations.pick(lang, en: 'Web Portal', mr: 'वेब पोर्टल', hi: 'वेब पोर्टल');
      case 'tv_web':
        return AppTranslations.pick(lang, en: 'TV News Web', mr: 'टीव्ही न्यूज वेब', hi: 'टीवी न्यूज़ वेब');
      case 'social_web':
        return AppTranslations.pick(lang, en: 'Social Media', mr: 'सोशल मीडिया', hi: 'सोशल मीडिया');
      case 'e_paper':
        return AppTranslations.pick(lang, en: 'E-Paper', mr: 'ई-पेपर', hi: 'ई-पेपर');
      default:
        return null;
    }
  }

  static String? _knownSubjectLabel(String subject, String lang) {
    final lower = subject.trim().toLowerCase();
    if (lower == 'ward corporator' || lower == 'corporator') {
      return AppTranslations.pick(lang, en: 'Ward Corporator', mr: 'प्रभाग नगरसेवक', hi: 'वार्ड नगरसेवक');
    }
    if (lower == 'nagarsevak office') {
      return AppTranslations.pick(lang, en: 'Nagarsevak Office', mr: 'नगरसेवक कार्यालय', hi: 'नगरसेवक कार्यालय');
    }
    if (lower == 'ward development works' || lower == 'prabhag 12 development') {
      return AppTranslations.pick(lang, en: 'Ward Development Works', mr: 'प्रभाग विकासकामे', hi: 'वार्ड विकास कार्य');
    }
    return null;
  }

  static bool _isSubjectPhrase(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('corporator') ||
        lower.contains('prabhag') ||
        lower.contains('ward') ||
        lower.contains('development') ||
        lower.contains('office') ||
        lower.contains('प्रभाग') ||
        lower.contains('विकास') ||
        lower.contains('कार्यालय');
  }

  static String _resolveProfileFilter(
    String raw,
    Map<String, String> cache,
    String lang,
  ) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'prof_01') {
      return AppTranslations.pick(lang, en: 'Nagarsevak Office', mr: 'नगरसेवक कार्यालय', hi: 'नगरसेवक कार्यालय');
    }
    if (lower == 'prof_02') {
      return AppTranslations.pick(lang, en: 'Ward Development Works', mr: 'प्रभाग विकासकामे', hi: 'वार्ड विकास कार्य');
    }
    return PdfTranslationHelper.resolve(cache, raw, lang);
  }

  static String _sentimentLabel(String sentiment, String lang) {
    final lower = sentiment.trim().toLowerCase();
    if (lower == 'positive') {
      return AppTranslations.pick(lang, en: 'Positive', mr: 'सकारात्मक', hi: 'सकारात्मक');
    }
    if (lower == 'negative' || lower == 'critical') {
      return AppTranslations.pick(lang, en: 'Critical', mr: 'दखलपात्र समस्या', hi: 'गंभीर मुद्दा');
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
