import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/ai_content_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class AiContentReportGenerator {
  AiContentReportGenerator._();

  /// Generates a single official letterhead document (Speech, Press Release, Letter, etc.)
  static Future<void> printDocument(
    AiContentHistoryItem item, {
    BuildContext? context,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);

    final textCache = await PdfTranslationHelper.batchText(
      [item.title, item.generatedContent],
      activeLang,
    );
    final nameCache = await PdfTranslationHelper.batchNames(
      ['Amit Chougale'],
      activeLang,
    );

    final dateStr = PdfTranslationHelper.formatDate(
      item.createdAt,
      activeLang,
      pattern: 'dd MMM yyyy',
    );
    final typeLabel = _contentTypeLabel(item.contentType, activeLang);
    final toneLabel = _toneLabel(item.tone, activeLang);
    final docLangLabel = _contentLanguageLabel(item.language, activeLang);
    final resolvedTitle =
        PdfTranslationHelper.resolve(textCache, item.title, activeLang);
    final resolvedContent = PdfTranslationHelper.resolve(
      textCache,
      item.generatedContent,
      activeLang,
    );
    final personName =
        PdfTranslationHelper.resolveName(nameCache, 'Amit Chougale', activeLang);
    final displaySignName =
        activeLang == 'en' ? personName.toUpperCase() : personName;

    final refPrefix = AppTranslations.pick(
      activeLang,
      en: 'Ref',
      mr: 'संदर्भ क्र.',
      hi: 'संदर्भ सं.',
    );
    final refCode =
        '$refPrefix: PMC/W12/CS/${PdfTranslationHelper.formatNumber(item.id.toUpperCase(), activeLang)}';
    final typePrefix = AppTranslations.pick(
      activeLang,
      en: 'Type',
      mr: 'प्रकार',
      hi: 'प्रकार',
    );
    final tonePrefix = AppTranslations.pick(
      activeLang,
      en: 'Tone',
      mr: 'शैली',
      hi: 'शैली',
    );
    final datePrefix = AppTranslations.pick(
      activeLang,
      en: 'Date',
      mr: 'दिनांक',
      hi: 'दिनांक',
    );
    final langPrefix = AppTranslations.pick(
      activeLang,
      en: 'Language',
      mr: 'भाषा',
      hi: 'भाषा',
    );
    final subjectHeading = AppTranslations.pick(
      activeLang,
      en: 'SUBJECT / TOPIC:',
      mr: 'विषय / संदर्भ:',
      hi: 'विषय / प्रसंग:',
    );
    final wordsLabel = PdfTranslationHelper.formatNumber(item.wordCount, activeLang);
    final readTimeStr = _formatReadingTime(item.readingTimeMinutes, activeLang);
    final metaStatsLine = AppTranslations.pick(
      activeLang,
      en: 'Words: $wordsLabel | Est. Reading Time: $readTimeStr',
      mr: 'शब्दसंख्या: $wordsLabel | अंदाजे वाचन वेळ: $readTimeStr',
      hi: 'शब्द संख्या: $wordsLabel | अनुमानित पठन समय: $readTimeStr',
    );
    final studioFootNote = AppTranslations.pick(
      activeLang,
      en: 'Generated via PMC Nagar Sevak AI Content Studio',
      mr: 'पुणे मनपा नगरसेवक AI कंटेंट स्टुडिओद्वारे तयार केलेले',
      hi: 'पुणे नगर निगम नगरसेवक AI कंटेंट स्टूडियो द्वारा निर्मित',
    );
    final corporatorDesignation = AppTranslations.pick(
      activeLang,
      en: 'Corporator (Nagarsevak) • Ward 12',
      mr: 'नगरसेवक • प्रभाग क्र. १२',
      hi: 'नगरसेवक • वार्ड क्र. १२',
    );
    final corpOrgName = AppTranslations.pick(
      activeLang,
      en: 'Pune Municipal Corporation',
      mr: 'पुणे महानगरपालिका',
      hi: 'पुणे नगर निगम',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: activeLang == 'en' ? typeLabel.toUpperCase() : typeLabel,
              lang: activeLang,
            );
          }
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildLetterhead(
                item,
                lang: activeLang,
                personName: personName,
                typeLabel: typeLabel,
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return WebReportTheme.buildFooter(context, lang: activeLang);
        },
        build: (pw.Context context) {
          return [
            // Document Metadata Strip
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const pw.BoxDecoration(
                color: WebReportTheme.slate50,
                border: pw.Border(
                  left: pw.BorderSide(color: WebReportTheme.brand600, width: 3),
                  top: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                  right: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                  bottom: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        refCode,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '$typePrefix: $typeLabel • $tonePrefix: $toneLabel',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: WebReportTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '$datePrefix: $dateStr',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '$langPrefix: $docLangLabel',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: WebReportTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Title / Subject Banner
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.brand50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    subjectHeading,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.brand700,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    resolvedTitle,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.slate900,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Content Body
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
              ),
              child: pw.Text(
                resolvedContent,
                style: const pw.TextStyle(
                  fontSize: 10,
                  lineSpacing: 4,
                  color: WebReportTheme.slate800,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            // Footer & Official Sign Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      metaStatsLine,
                      style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      studioFootNote,
                      style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate400),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 140,
                      padding: const pw.EdgeInsets.only(top: 20),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: WebReportTheme.slate400, width: 0.8)),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            displaySignName,
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            corporatorDesignation,
                            style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate600),
                          ),
                          pw.Text(
                            corpOrgName,
                            style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final fileName = 'Content_${item.contentType.id}_${item.id}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: typeLabel,
        subtitle: resolvedTitle,
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

  /// Generates a comprehensive summary dossier of all generated AI content
  static Future<void> generateDossier({
    BuildContext? context,
    required List<AiContentHistoryItem> items,
    String? categoryFilter,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDateTime(DateTime.now(), activeLang);

    final snippets = items.map((item) {
      final cleaned = item.generatedContent.replaceAll(RegExp(r'\s+'), ' ').trim();
      return cleaned.length > 160 ? '${cleaned.substring(0, 160)}...' : cleaned;
    }).toList();

    final textCache = await PdfTranslationHelper.batchText(
      [
        ...items.map((i) => i.title),
        ...snippets,
        if (categoryFilter != null &&
            categoryFilter.trim().isNotEmpty &&
            categoryFilter.trim().toLowerCase() != 'all')
          categoryFilter,
      ],
      activeLang,
    );

    final speechCount = items.where((i) => i.contentType == AiContentType.speech).length;
    final captionCount = items.where((i) => i.contentType == AiContentType.socialMediaCaption).length;
    final noticeCount = items.where((i) => i.contentType == AiContentType.letterNotice).length;
    final pressCount = items.where((i) => i.contentType == AiContentType.pressRelease).length;

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'AI Content Studio Dossier',
      mr: 'AI कंटेंट स्टुडिओ संकलित अहवाल',
      hi: 'AI कंटेंट स्टूडियो संकलित रिपोर्ट',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Speeches, Notices, Press Releases & Citizen Outreach',
      mr: 'भाषणे, सूचना, प्रेस रिलीज व नागरिक जनसंपर्क मसुदे',
      hi: 'भाषण, सूचनाएं, प्रेस विज्ञप्तियां एवं नागरिक जनसंपर्क प्रारूप',
    );
    final foundLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Drafts',
      mr: 'एकूण मसुदे',
      hi: 'कुल प्रारूप',
    );
    final datePrefix = AppTranslations.pick(
      activeLang,
      en: 'Date:',
      mr: 'दिनांक:',
      hi: 'दिनांक:',
    );
    final filterText = (categoryFilter != null &&
            categoryFilter.trim().isNotEmpty &&
            categoryFilter.trim().toLowerCase() != 'all')
        ? _resolveCategoryFilter(categoryFilter, textCache, activeLang)
        : null;
    final filterPrefix = AppTranslations.pick(
      activeLang,
      en: 'Category:',
      mr: 'प्रकार:',
      hi: 'श्रेणी:',
    );

    final totalLabel = AppTranslations.pick(activeLang, en: 'Total', mr: 'एकूण', hi: 'कुल');
    final speechesLabel = AppTranslations.pick(activeLang, en: 'Speeches', mr: 'भाषणे', hi: 'भाषण');
    final captionsLabel = AppTranslations.pick(activeLang, en: 'Social Captions', mr: 'सोशल कॅप्शन', hi: 'सोशल कैप्शन');
    final noticesLabel = AppTranslations.pick(activeLang, en: 'Notices', mr: 'पत्र / सूचना', hi: 'पत्र / सूचना');
    final pressLabel = AppTranslations.pick(activeLang, en: 'Press Releases', mr: 'प्रेस रिलीज', hi: 'प्रेस विज्ञप्ति');
    final emptyMsg = AppTranslations.pick(
      activeLang,
      en: 'No generated AI content drafts found.',
      mr: 'कोणतेही AI कंटेंट मसुदे सापडले नाहीत.',
      hi: 'कोई AI कंटेंट प्रारूप नहीं मिला।',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: reportTitle,
              lang: activeLang,
            );
          }
          return WebReportTheme.buildHeader(
            title: reportTitle,
            subtitle: reportSubtitle,
            dateFormatted: filterText == null ? nowStr : null,
            totalCount: filterText == null ? items.length : null,
            foundLabel: foundLabel,
            metaLines: filterText != null
                ? [
                    '$datePrefix $nowStr',
                    '$filterPrefix $filterText',
                    '$foundLabel: ${PdfTranslationHelper.formatNumber(items.length, activeLang)}',
                  ]
                : null,
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
                  _statItem(totalLabel, PdfTranslationHelper.formatNumber(items.length, activeLang)),
                  _statItem(speechesLabel, PdfTranslationHelper.formatNumber(speechCount, activeLang)),
                  _statItem(captionsLabel, PdfTranslationHelper.formatNumber(captionCount, activeLang)),
                  _statItem(noticesLabel, PdfTranslationHelper.formatNumber(noticeCount, activeLang)),
                  _statItem(pressLabel, PdfTranslationHelper.formatNumber(pressCount, activeLang)),
                ],
              ),
            ),

            if (items.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  emptyMsg,
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              // Content Table
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
                  1: pw.FixedColumnWidth(55),  // Date
                  2: pw.FixedColumnWidth(70),  // Type
                  3: pw.FixedColumnWidth(60),  // Tone / Lang
                  4: pw.FlexColumnWidth(2.5),  // Topic
                  5: pw.FlexColumnWidth(3.5),  // Content Excerpt
                  6: pw.FixedColumnWidth(36),  // Words
                },
                headers: [
                  '#',
                  AppTranslations.getReportColumn('date', activeLang),
                  AppTranslations.getReportColumn('type', activeLang),
                  AppTranslations.pick(activeLang, en: 'Tone / Lang', mr: 'शैली / भाषा', hi: 'शैली / भाषा'),
                  AppTranslations.pick(activeLang, en: 'Topic / Context', mr: 'विषय / संदर्भ', hi: 'विषय / प्रसंग'),
                  AppTranslations.pick(activeLang, en: 'Generated Content Excerpt', mr: 'मसुद्याचा सारांश', hi: 'निर्मित सामग्री अंश'),
                  AppTranslations.pick(activeLang, en: 'Words', mr: 'शब्द', hi: 'शब्द'),
                ],
                data: items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final dateFormatted = PdfTranslationHelper.formatDate(
                    item.createdAt,
                    activeLang,
                    pattern: 'dd/MM/yyyy',
                  );
                  final resolvedTopic = PdfTranslationHelper.resolve(
                    textCache,
                    item.title,
                    activeLang,
                  );
                  final resolvedExcerpt = PdfTranslationHelper.resolve(
                    textCache,
                    snippets[entry.key],
                    activeLang,
                  );
                  final displayExcerpt = resolvedExcerpt.length > 135
                      ? '${resolvedExcerpt.substring(0, 135)}...'
                      : resolvedExcerpt;

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    dateFormatted,
                    _contentTypeLabel(item.contentType, activeLang),
                    '${_toneLabel(item.tone, activeLang)}\n${_contentLanguageLabel(item.language, activeLang)}',
                    resolvedTopic,
                    displayExcerpt,
                    PdfTranslationHelper.formatNumber(item.wordCount, activeLang),
                  ];
                }).toList(),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
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
      en: 'AI Content Dossier',
      mr: 'AI कंटेंट संकलित अहवाल',
      hi: 'AI कंटेंट संकलित रिपोर्ट',
    );
    final previewSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Official Archive of Speeches, Press Releases & Social Media Content',
      mr: 'भाषणे, प्रेस रिलीज व सोशल मीडिया मसुद्यांचे अधिकृत संकलन',
      hi: 'भाषण, प्रेस विज्ञप्ति और सोशल मीडिया सामग्री का आधिकारिक संग्रह',
    );

    final fileName = 'AI_Content_Dossier_Ward12_${DateFormat('yyyyMMdd').format(DateTime.now())}';
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

  static pw.Widget _buildLetterhead(
    AiContentHistoryItem item, {
    required String lang,
    required String personName,
    required String typeLabel,
  }) {
    final officeTitle = AppTranslations.pick(
      lang,
      en: 'Office: Nagarsevak $personName',
      mr: 'कार्यालय: नगरसेवक $personName',
      hi: 'कार्यालय: नगरसेवक $personName',
    );
    final wardLine = AppTranslations.pick(
      lang,
      en: 'Ward No. 12 (Kasba-Vishrambaug Wada) • Pune Municipal Corporation',
      mr: 'प्रभाग क्र. १२ (कसबा-विश्रामबाग वाडा) • पुणे महानगरपालिका',
      hi: 'वार्ड क्र. १२ (कसबा-विश्रामबाग वाडा) • पुणे नगर निगम',
    );
    final addressLine = AppTranslations.pick(
      lang,
      en: 'Public Relations Office: 1002, Shaniwar Peth, Pune - 411 030 | Phone: 020-25501234',
      mr: 'जनसंपर्क कार्यालय: १००२, शनिवार पेठ, पुणे - ४११ ०३० | दूरध्वनी: ०२०-२५५०१२३४',
      hi: 'जनसंपर्क कार्यालय: १००२, शनिवार पेठ, पुणे - ४११ ०३० | फ़ोन: ०२०-२५५०१२३४',
    );
    final draftBadge = AppTranslations.pick(
      lang,
      en: 'OFFICIAL DRAFT',
      mr: 'अधिकृत मसुदा',
      hi: 'आधिकारिक प्रारूप',
    );

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                officeTitle,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: WebReportTheme.brand700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                wardLine,
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: WebReportTheme.slate600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                addressLine,
                style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate400),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              color: WebReportTheme.brand50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  draftBadge,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: WebReportTheme.brand700,
                  ),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  lang == 'en' ? typeLabel.toUpperCase() : typeLabel,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: WebReportTheme.slate600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _contentTypeLabel(AiContentType type, String lang) {
    switch (type) {
      case AiContentType.speech:
        return AppTranslations.pick(lang, en: 'Speech', mr: 'भाषण', hi: 'भाषण');
      case AiContentType.socialMediaCaption:
        return AppTranslations.pick(lang, en: 'Social Media Caption', mr: 'सोशल मीडिया कॅप्शन', hi: 'सोशल मीडिया कैप्शन');
      case AiContentType.pressRelease:
        return AppTranslations.pick(lang, en: 'Press Release', mr: 'प्रेस रिलीज', hi: 'प्रेस विज्ञप्ति');
      case AiContentType.letterNotice:
        return AppTranslations.pick(lang, en: 'Letter / Notice', mr: 'पत्र / सूचना', hi: 'पत्र / सूचना');
      case AiContentType.email:
        return AppTranslations.pick(lang, en: 'Email', mr: 'ईमेल', hi: 'ईमेल');
      case AiContentType.workReport:
        return AppTranslations.pick(lang, en: 'Work Report', mr: 'कामाचा अहवाल', hi: 'कार्य रिपोर्ट');
    }
  }

  static String _toneLabel(AiToneType tone, String lang) {
    switch (tone) {
      case AiToneType.enthusiastic:
        return AppTranslations.pick(lang, en: 'Enthusiastic', mr: 'उत्साही', hi: 'उत्साही');
      case AiToneType.formal:
        return AppTranslations.pick(lang, en: 'Formal', mr: 'औपचारिक', hi: 'औपचारिक');
      case AiToneType.professional:
        return AppTranslations.pick(lang, en: 'Professional', mr: 'व्यावसायिक', hi: 'व्यावसायिक');
      case AiToneType.emotional:
        return AppTranslations.pick(lang, en: 'Emotional', mr: 'भावनिक', hi: 'भावनात्मक');
      case AiToneType.urgent:
        return AppTranslations.pick(lang, en: 'Urgent', mr: 'तात्काळ', hi: 'तत्काल');
    }
  }

  static String _contentLanguageLabel(AiLanguageType docLang, String lang) {
    switch (docLang) {
      case AiLanguageType.marathi:
        return AppTranslations.pick(lang, en: 'Marathi', mr: 'मराठी', hi: 'मराठी');
      case AiLanguageType.english:
        return AppTranslations.pick(lang, en: 'English', mr: 'इंग्रजी', hi: 'अंग्रेजी');
      case AiLanguageType.hindi:
        return AppTranslations.pick(lang, en: 'Hindi', mr: 'हिंदी', hi: 'हिंदी');
    }
  }

  static String _formatReadingTime(double mins, String lang) {
    if (mins < 1) {
      final secs = PdfTranslationHelper.formatNumber((mins * 60).round(), lang);
      return AppTranslations.pick(lang, en: '$secs sec', mr: '$secs सेकंद', hi: '$secs सेकंड');
    }
    final mStr = PdfTranslationHelper.formatNumber(mins.toStringAsFixed(1), lang);
    return AppTranslations.pick(lang, en: '$mStr min', mr: '$mStr मिनिटे', hi: '$mStr मिनट');
  }

  static String _resolveCategoryFilter(
    String raw,
    Map<String, String> cache,
    String lang,
  ) {
    final lower = raw.trim().toLowerCase();
    for (final t in AiContentType.values) {
      if (t.id.toLowerCase() == lower || t.titleEn.toLowerCase() == lower) {
        return _contentTypeLabel(t, lang);
      }
    }
    return PdfTranslationHelper.resolve(cache, raw, lang);
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
