import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/social_post_model.dart';
import '../../../data/repositories/social_analytics_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class SocialAnalyticsReportGenerator {
  SocialAnalyticsReportGenerator._();

  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
    unicode: true,
  );

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<SocialPostModel> posts,
    required SocialAnalyticsSummary summary,
    required List<VoterBirthdayModel> birthdays,
    String? platformFilter,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDateTime(DateTime.now(), activeLang);

    final toTranslate = <String>[];
    final namesToTransliterate = <String>[];

    for (final p in posts) {
      if (_knownPlatform(p.platform, activeLang) == null &&
          p.platform.trim().isNotEmpty) {
        toTranslate.add(p.platform);
      }
      if (!_hasDirectMarathi(p.contentMarathi, activeLang)) {
        final rawContent =
            p.content.trim().isNotEmpty ? p.content : p.contentMarathi;
        final cleaned = _sanitizeForPdf(rawContent);
        if (cleaned.isNotEmpty) toTranslate.add(cleaned);
      }
    }

    for (final b in birthdays) {
      if (!_hasDirectMarathi(b.nameMarathi, activeLang)) {
        final rawName = b.displayName.trim();
        if (rawName.isNotEmpty) namesToTransliterate.add(rawName);
      }
      if (b.area.trim().isNotEmpty) toTranslate.add(b.area);
    }

    if (platformFilter != null &&
        platformFilter.trim().isNotEmpty &&
        platformFilter.trim().toLowerCase() != 'all' &&
        _knownPlatform(platformFilter, activeLang) == null) {
      toTranslate.add(platformFilter);
    }

    final results = await Future.wait([
      PdfTranslationHelper.batchText(toTranslate, activeLang),
      PdfTranslationHelper.batchNames(namesToTransliterate, activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Social Media Analytics',
      mr: 'सोशल मीडिया विश्लेषण',
      hi: 'सोशल मीडिया विश्लेषण',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Social Media Reach & Voter Engagement Audit Report',
      mr: 'सोशल मीडिया पोहोच व मतदार प्रतिसाद विश्लेषण अहवाल',
      hi: 'सोशल मीडिया पहुंच एवं मतदाता सहभागिता ऑडिट रिपोर्ट',
    );
    final foundLabel = AppTranslations.pick(
      activeLang,
      en: 'Posts',
      mr: 'एकूण पोस्ट',
      hi: 'कुल पोस्ट',
    );

    final hasPlatformFilter = platformFilter != null &&
        platformFilter.trim().isNotEmpty &&
        platformFilter.trim().toLowerCase() != 'all';
    final metaLines = <String>[];
    if (hasPlatformFilter) {
      final datePrefix =
          AppTranslations.pick(activeLang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:');
      final platformPrefix = AppTranslations.pick(
        activeLang,
        en: 'Platform:',
        mr: 'माध्यम:',
        hi: 'प्लेटफ़ॉर्म:',
      );
      final resolvedPlatform = _knownPlatform(platformFilter, activeLang) ??
          PdfTranslationHelper.resolve(textCache, platformFilter, activeLang);
      metaLines.add('$datePrefix $nowStr');
      metaLines.add('$platformPrefix $resolvedPlatform');
      metaLines.add('$foundLabel: ${PdfTranslationHelper.formatNumber(posts.length, activeLang)}');
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
              totalCount: metaLines.isEmpty ? posts.length : null,
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
                    AppTranslations.pick(activeLang, en: 'Total Reach', mr: 'एकूण पोहोच (Reach)', hi: 'कुल पहुंच (Reach)'),
                    PdfTranslationHelper.formatNumber(summary.totalReach.toLocaleString(), activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Total Likes', mr: 'एकूण लाईक्स', hi: 'कुल लाइक्स'),
                    PdfTranslationHelper.formatNumber(summary.totalLikes.toLocaleString(), activeLang),
                    highlightColor: PdfColors.pink700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Comments', mr: 'प्रतिक्रिया (Comments)', hi: 'टिप्पणियां (Comments)'),
                    PdfTranslationHelper.formatNumber(summary.totalComments.toLocaleString(), activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Shares', mr: 'शेअर्स', hi: 'शेयर'),
                    PdfTranslationHelper.formatNumber(summary.totalShares.toLocaleString(), activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (posts.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No social media post records found.',
                    mr: 'कोणत्याही सोशल मीडिया पोस्टची नोंद आढळली नाही.',
                    hi: 'कोई सोशल मीडिया पोस्ट रिकॉर्ड नहीं मिला।',
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
                  2: pw.FlexColumnWidth(1.6),
                  3: pw.FlexColumnWidth(4.2),
                  4: pw.FlexColumnWidth(1.6),
                  5: pw.FlexColumnWidth(1.6),
                },
                headers: [
                  '#',
                  AppTranslations.getReportColumn('date', activeLang),
                  AppTranslations.pick(activeLang, en: 'Platform', mr: 'माध्यम', hi: 'प्लेटफ़ॉर्म'),
                  AppTranslations.pick(activeLang, en: 'Post Content & Updates', mr: 'पोस्ट मजकूर व माहिती', hi: 'पोस्ट सामग्री एवं अपडेट'),
                  AppTranslations.pick(activeLang, en: 'Reach', mr: 'पोहोच', hi: 'पहुंच'),
                  AppTranslations.pick(activeLang, en: 'Eng. %', mr: 'प्रतिसाद %', hi: 'सहभागिता %'),
                ],
                data: posts.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final p = entry.value;

                  final dateStr =
                      PdfTranslationHelper.parseAndFormatDateString(p.date, activeLang);
                  final platformStr = _knownPlatform(p.platform, activeLang) ??
                      PdfTranslationHelper.resolve(textCache, p.platform, activeLang);

                  final contentStr = _hasDirectMarathi(p.contentMarathi, activeLang)
                      ? AppTranslations.formatDigits(
                          _sanitizeForPdf(p.contentMarathi),
                          activeLang,
                        )
                      : PdfTranslationHelper.resolve(
                          textCache,
                          _sanitizeForPdf(
                            p.content.trim().isNotEmpty ? p.content : p.contentMarathi,
                          ),
                          activeLang,
                        );

                  final reachStr = PdfTranslationHelper.formatNumber(
                    p.reach.toLocaleString(),
                    activeLang,
                  );
                  final engStr =
                      '${PdfTranslationHelper.formatNumber(p.engagementRate.toStringAsFixed(1), activeLang)}%';

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    dateStr,
                    platformStr,
                    contentStr,
                    reachStr,
                    engStr,
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),

            if (birthdays.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                AppTranslations.pick(
                  activeLang,
                  en: 'UPCOMING VOTER BIRTHDAYS',
                  mr: 'आगामी मतदार वाढदिवस सूची',
                  hi: 'आगामी मतदाता जन्मदिन सूची',
                ),
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: WebReportTheme.brand700,
                ),
              ),
              pw.SizedBox(height: 6),
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
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(1.8),
                  3: pw.FlexColumnWidth(2.4),
                  4: pw.FlexColumnWidth(1.8),
                },
                headers: [
                  '#',
                  AppTranslations.getReportColumn('name', activeLang),
                  AppTranslations.getReportColumn('mobile', activeLang),
                  AppTranslations.getReportColumn('area', activeLang),
                  AppTranslations.pick(activeLang, en: 'Booth / Age', mr: 'बूथ / वय', hi: 'बूथ / आयु'),
                ],
                data: birthdays.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final b = entry.value;
                  final voterName = _hasDirectMarathi(b.nameMarathi, activeLang)
                      ? AppTranslations.formatDigits(b.nameMarathi.trim(), activeLang)
                      : PdfTranslationHelper.resolveName(
                          nameCache,
                          b.displayName,
                          activeLang,
                        );
                  final mobileStr = b.mobile.trim().isNotEmpty
                      ? PdfTranslationHelper.formatNumber(b.mobile.trim(), activeLang)
                      : '-';
                  final areaStr = _resolveArea(b.area, textCache, activeLang);
                  final boothPrefix =
                      AppTranslations.pick(activeLang, en: 'Booth', mr: 'बूथ', hi: 'बूथ');
                  final ageSuffix =
                      AppTranslations.pick(activeLang, en: 'yrs', mr: 'वर्षे', hi: 'वर्ष');
                  final boothAge =
                      '$boothPrefix ${PdfTranslationHelper.formatNumber(b.boothNumber, activeLang)} • ${PdfTranslationHelper.formatNumber(b.age, activeLang)} $ageSuffix';

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    voterName,
                    mobileStr,
                    areaStr,
                    boothAge,
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
            ],
          ];
        },
      ),
    );

    final fileName = 'Social_Analytics_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
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

  static String _sanitizeForPdf(String raw) {
    return raw.replaceAll(_emojiRegex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _knownPlatform(String raw, String lang) {
    switch (raw.trim().toLowerCase()) {
      case 'facebook':
        return AppTranslations.pick(lang, en: 'Facebook', mr: 'फेसबुक', hi: 'फेसबुक');
      case 'instagram':
        return AppTranslations.pick(lang, en: 'Instagram', mr: 'इन्स्टाग्राम', hi: 'इंस्टाग्राम');
      case 'twitter':
      case 'x':
        return AppTranslations.pick(lang, en: 'Twitter (X)', mr: 'ट्विटर (X)', hi: 'ट्विटर (X)');
      case 'youtube':
        return AppTranslations.pick(lang, en: 'YouTube', mr: 'यूट्यूब', hi: 'यूट्यूब');
      case 'whatsapp':
        return AppTranslations.pick(lang, en: 'WhatsApp', mr: 'व्हॉट्सॲप', hi: 'व्हाट्सएप');
      default:
        return null;
    }
  }

  static String _resolveArea(
    String raw,
    Map<String, String> cache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final dictArea = AppTranslations.getAreaName(trimmed, lang);
    if (AppTranslations.normalizeAsciiDigits(dictArea) !=
        AppTranslations.normalizeAsciiDigits(trimmed)) {
      return dictArea;
    }
    return PdfTranslationHelper.resolve(cache, trimmed, lang);
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
