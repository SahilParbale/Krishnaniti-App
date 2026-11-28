import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/gallery_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class GalleryReportGenerator {
  GalleryReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<GalleryItemModel> items,
    String? categoryFilter,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDateTime(DateTime.now(), activeLang);

    final toTranslate = <String>[];
    for (final item in items) {
      if (!_hasDirectMarathi(item.titleMr, activeLang)) {
        final rawTitle = item.title.trim().isNotEmpty ? item.title : item.titleMr;
        if (rawTitle.trim().isNotEmpty) toTranslate.add(rawTitle);
      }
      if (!_hasDirectMarathi(item.descriptionMr, activeLang)) {
        final rawDesc =
            item.description.trim().isNotEmpty ? item.description : item.descriptionMr;
        if (rawDesc.trim().isNotEmpty) toTranslate.add(rawDesc);
      }
      if (item.location.trim().isNotEmpty) toTranslate.add(item.location);
    }
    if (categoryFilter != null &&
        categoryFilter.trim().isNotEmpty &&
        categoryFilter.trim().toLowerCase() != 'all') {
      toTranslate.add(categoryFilter);
    }

    final textCache = await PdfTranslationHelper.batchText(toTranslate, activeLang);

    final totalItems = items.length;
    final eventCount = items.where((i) => i.category == GalleryCategory.event).length;
    final workCount = items.where((i) => i.category == GalleryCategory.work).length;
    final awardCount = items.where((i) => i.category == GalleryCategory.award).length;
    final campaignCount = items.where((i) => i.category == GalleryCategory.campaign).length;
    final totalViews = items.fold<int>(0, (sum, i) => sum + i.viewsCount);

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Media Gallery & Archive',
      mr: 'गॅलरी व छायाचित्र संग्रह',
      hi: 'मीडिया गैलरी एवं छायाचित्र संग्रह',
    );
    final contTitle = AppTranslations.pick(
      activeLang,
      en: 'Media Gallery & Photographic Archive',
      mr: 'गॅलरी व छायाचित्र संग्रह',
      hi: 'मीडिया गैलरी एवं छायाचित्र संग्रह',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Prabhag Ward 12 • High-Resolution Civic Photo & Event Media Register',
      mr: 'प्रभाग क्र. १२ • विकासकामे व कार्यक्रमांचे छायाचित्र अभिलेख',
      hi: 'प्रभाग वार्ड १२ • विकास कार्यों एवं कार्यक्रमों का छायाचित्र अभिलेख',
    );
    final foundLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Photos',
      mr: 'एकूण छायाचित्रे',
      hi: 'कुल फोटो',
    );

    final hasFilter = categoryFilter != null &&
        categoryFilter.trim().isNotEmpty &&
        categoryFilter.trim().toLowerCase() != 'all';
    final metaLines = <String>[];
    if (hasFilter) {
      final datePrefix = AppTranslations.pick(activeLang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:');
      final catPrefix = AppTranslations.pick(activeLang, en: 'Category:', mr: 'वर्गवारी:', hi: 'श्रेणी:');
      metaLines.add('$datePrefix $nowStr');
      metaLines.add('$catPrefix ${_resolveCategoryFilter(categoryFilter, textCache, activeLang)}');
      metaLines.add('$foundLabel: ${PdfTranslationHelper.formatNumber(totalItems, activeLang)}');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: contTitle,
              lang: activeLang,
            );
          }
          return WebReportTheme.buildHeader(
            title: reportTitle,
            subtitle: reportSubtitle,
            dateFormatted: metaLines.isEmpty ? nowStr : null,
            totalCount: metaLines.isEmpty ? totalItems : null,
            foundLabel: foundLabel,
            metaLines: metaLines.isNotEmpty ? metaLines : null,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) {
          return WebReportTheme.buildFooter(context, lang: activeLang);
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 14),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                    AppTranslations.pick(activeLang, en: 'Total Photos', mr: 'एकूण फोटो', hi: 'कुल फोटो'),
                    PdfTranslationHelper.formatNumber(totalItems, activeLang),
                  ),
                  _statItem(
                    AppTranslations.pick(activeLang, en: 'Events', mr: 'कार्यक्रम', hi: 'कार्यक्रम'),
                    PdfTranslationHelper.formatNumber(eventCount, activeLang),
                  ),
                  _statItem(
                    AppTranslations.pick(activeLang, en: 'Development', mr: 'विकासकामे', hi: 'विकास कार्य'),
                    PdfTranslationHelper.formatNumber(workCount, activeLang),
                  ),
                  _statItem(
                    AppTranslations.pick(activeLang, en: 'Awards', mr: 'पुरस्कार', hi: 'पुरस्कार'),
                    PdfTranslationHelper.formatNumber(awardCount, activeLang),
                  ),
                  _statItem(
                    AppTranslations.pick(activeLang, en: 'Campaigns', mr: 'मोहीम', hi: 'अभियान'),
                    PdfTranslationHelper.formatNumber(campaignCount, activeLang),
                  ),
                  _statItem(
                    AppTranslations.pick(activeLang, en: 'Total Views', mr: 'एकूण व्ह्यूज', hi: 'कुल व्यूज'),
                    PdfTranslationHelper.formatNumber(totalViews, activeLang),
                  ),
                ],
              ),
            ),

            if (items.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No gallery items or photographs found.',
                    mr: 'गॅलरीमध्ये कोणतेही फोटो किंवा नोंदी सापडल्या नाहीत.',
                    hi: 'गैलरी में कोई फ़ोटो या आइटम नहीं मिला।',
                  ),
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              // Media Catalog Table
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
                  0: pw.FixedColumnWidth(24),  // Sr
                  1: pw.FixedColumnWidth(60),  // Date
                  2: pw.FixedColumnWidth(65),  // Category
                  3: pw.FlexColumnWidth(2.5),  // Title
                  4: pw.FlexColumnWidth(1.8),  // Location
                  5: pw.FlexColumnWidth(2.8),  // Description
                  6: pw.FixedColumnWidth(40),  // Views
                },
                headers: [
                  '#',
                  AppTranslations.getReportColumn('date', activeLang),
                  AppTranslations.getReportColumn('category', activeLang),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Photo Title & Event',
                    mr: 'छायाचित्र शीर्षक व कार्यक्रम',
                    hi: 'फ़ोटो शीर्षक एवं कार्यक्रम',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Location / Venue',
                    mr: 'ठिकाण / स्थळ',
                    hi: 'स्थान / स्थल',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Description / Context',
                    mr: 'वर्णन / संदर्भ',
                    hi: 'विवरण / संदर्भ',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Views',
                    mr: 'व्ह्यूज',
                    hi: 'व्यूज',
                  ),
                ],
                data: items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final dateFormatted = PdfTranslationHelper.formatDate(
                    item.date,
                    activeLang,
                    pattern: 'dd/MM/yyyy',
                  );
                  final titleText = _hasDirectMarathi(item.titleMr, activeLang)
                      ? AppTranslations.formatDigits(item.titleMr.trim(), activeLang)
                      : PdfTranslationHelper.resolve(
                          textCache,
                          item.title.trim().isNotEmpty ? item.title : item.titleMr,
                          activeLang,
                        );
                  final descText = _hasDirectMarathi(item.descriptionMr, activeLang)
                      ? AppTranslations.formatDigits(item.descriptionMr.trim(), activeLang)
                      : PdfTranslationHelper.resolve(
                          textCache,
                          item.description.trim().isNotEmpty
                              ? item.description
                              : item.descriptionMr,
                          activeLang,
                        );
                  final locText = _resolveLocation(item.location, textCache, activeLang);

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    dateFormatted,
                    _categoryLabel(item.category, activeLang),
                    titleText,
                    locText,
                    descText,
                    PdfTranslationHelper.formatNumber(item.viewsCount, activeLang),
                  ];
                }).toList(),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerLeft,
                  6: pw.Alignment.center,
                },
              ),
          ];
        },
      ),
    );

    final previewTitle = AppTranslations.pick(
      activeLang,
      en: 'Media Gallery Report',
      mr: 'मीडिया गॅलरी अहवाल',
      hi: 'मीडिया गैलरी रिपोर्ट',
    );
    final previewSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Prabhag 12 Media Gallery & Public Campaign Assets',
      mr: 'प्रभाग १२ मीडिया गॅलरी व जनसंपर्क छायाचित्र संग्रह',
      hi: 'प्रभाग १२ मीडिया गैलरी एवं जनसंपर्क सामग्री',
    );

    final fileName = 'Prabhag_12_Media_Gallery_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: previewTitle,
        subtitle: previewSubtitle,
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

  static String _categoryLabel(GalleryCategory cat, String lang) {
    switch (cat) {
      case GalleryCategory.event:
        return AppTranslations.pick(lang, en: 'Events', mr: 'कार्यक्रम', hi: 'कार्यक्रम');
      case GalleryCategory.work:
        return AppTranslations.pick(lang, en: 'Development', mr: 'विकासकाम', hi: 'विकास कार्य');
      case GalleryCategory.award:
        return AppTranslations.pick(lang, en: 'Awards', mr: 'पुरस्कार', hi: 'पुरस्कार');
      case GalleryCategory.campaign:
        return AppTranslations.pick(lang, en: 'Campaigns', mr: 'मोहीम / जनसंपर्क', hi: 'अभियान / जनसंपर्क');
    }
  }

  static String _resolveCategoryFilter(
    String raw,
    Map<String, String> cache,
    String lang,
  ) {
    final lower = raw.trim().toLowerCase();
    for (final c in GalleryCategory.values) {
      if (c.id.toLowerCase() == lower ||
          c.titleEn.toLowerCase() == lower ||
          c.name.toLowerCase() == lower) {
        return _categoryLabel(c, lang);
      }
    }
    return PdfTranslationHelper.resolve(cache, raw, lang);
  }

  static String _resolveLocation(
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

  static pw.Widget _statItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: WebReportTheme.brand700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 7.5,
            color: WebReportTheme.slate600,
          ),
        ),
      ],
    );
  }
}
