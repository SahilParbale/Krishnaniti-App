import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/visitor_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Visitor Log Report Generator matching Nagarsevak-Managment
/// (VisitorReportGenerator.tsx).
class VisitorReportGenerator {
  VisitorReportGenerator._();

  static String _resolveArea(Map<String, String> cache, String? raw, String lang, {String fallback = '-'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final clean = raw.trim();
    final domain = AppTranslations.getAreaName(clean, lang);
    final plainDigits = AppTranslations.formatDigits(clean, lang);
    if (domain != clean && domain != plainDigits) return domain;
    return PdfTranslationHelper.resolve(cache, clean, lang, fallback: fallback);
  }

  static Future<void> generateAndPrintListReport({
    BuildContext? context,
    required List<VisitorModel> visitors,
    String? filterTitle,
    String title = 'Visitor Log Report',
    String subtitle = 'Visitor Records Report',
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);
    final total = visitors.length;

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        if (title != 'Visitor Log Report') title,
        if (subtitle != 'Visitor Records Report') subtitle,
        filterTitle,
        for (final v in visitors) ...[
          v.area,
          v.purpose,
          v.remarks,
        ],
      ], activeLang),
      PdfTranslationHelper.batchNames([
        for (final v in visitors) ...[
          v.name,
          v.reference,
        ],
      ], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final resolvedTitle = (title == 'Visitor Log Report')
        ? AppTranslations.pick(
            activeLang,
            en: 'Visitor Log Report',
            mr: 'कार्यालय भेट नोंदवही अहवाल',
            hi: 'कार्यालय आगंतुक लॉग रिपोर्ट',
          )
        : PdfTranslationHelper.resolve(textCache, title, activeLang, fallback: title);
    final resolvedSubtitle = (subtitle == 'Visitor Records Report')
        ? AppTranslations.pick(
            activeLang,
            en: 'Visitor Records Report',
            mr: 'प्रभाग कार्यालय नागरिक व शिष्टमंडळ भेट नोंद',
            hi: 'वार्ड कार्यालय नागरिक एवं शिष्टमंडल भेंट रिकॉर्ड',
          )
        : PdfTranslationHelper.resolve(textCache, subtitle, activeLang, fallback: subtitle);

    final resolvedFilter = (filterTitle != null && filterTitle.trim().isNotEmpty)
        ? PdfTranslationHelper.resolve(textCache, filterTitle, activeLang)
        : '';
    final emptyMsg = AppTranslations.pick(
      activeLang,
      en: 'No visitor records found.',
      mr: 'भेट देणाऱ्यांच्या कोणत्याही नोंदी आढळल्या नाहीत.',
      hi: 'कोई आगंतुक रिकॉर्ड नहीं मिला।',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: resolvedTitle,
              lang: activeLang,
            );
          }
          return WebReportTheme.buildHeader(
            title: resolvedTitle,
            subtitle: resolvedSubtitle,
            dateFormatted: formattedDate,
            totalCount: total,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            if (resolvedFilter.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.slate50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
                ),
                child: pw.Text(
                  resolvedFilter,
                  style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600),
                ),
              ),
            if (visitors.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  emptyMsg,
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
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
                  0: pw.FlexColumnWidth(1.5), // Date & Time (15%)
                  1: pw.FlexColumnWidth(2.0), // Full Name (20%)
                  2: pw.FlexColumnWidth(1.5), // Mobile (15%)
                  3: pw.FlexColumnWidth(2.0), // Area (20%)
                  4: pw.FlexColumnWidth(1.5), // Purpose (15%)
                  5: pw.FlexColumnWidth(1.5), // Reference (15%)
                },
                headers: [
                  AppTranslations.getReportColumn('date_time', activeLang),
                  AppTranslations.getReportColumn('name', activeLang),
                  AppTranslations.pick(activeLang, en: 'Mobile', mr: 'मोबाईल', hi: 'मोबाइल'),
                  AppTranslations.getReportColumn('area', activeLang),
                  AppTranslations.pick(activeLang, en: 'Purpose', mr: 'उद्दिष्ट', hi: 'उद्देश्य'),
                  AppTranslations.pick(activeLang, en: 'Reference', mr: 'संदर्भ', hi: 'संदर्भ'),
                ],
                data: visitors.map((v) {
                  final dateStr = PdfTranslationHelper.formatDate(
                    v.visitDate,
                    activeLang,
                    pattern: 'dd/MM/yyyy',
                  );
                  final timeStr = AppTranslations.formatTime(v.visitDate, activeLang);

                  return [
                    '$dateStr\n$timeStr',
                    PdfTranslationHelper.resolveName(nameCache, v.name, activeLang),
                    v.mobile.trim().isNotEmpty
                        ? PdfTranslationHelper.formatNumber(v.mobile.trim(), activeLang)
                        : '-',
                    _resolveArea(textCache, v.area, activeLang),
                    PdfTranslationHelper.resolve(textCache, v.purpose, activeLang),
                    PdfTranslationHelper.resolveName(nameCache, v.reference, activeLang),
                  ];
                }).toList(),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerLeft,
                },
              ),
          ];
        },
      ),
    );

    final fileName = 'Visitor_Log_Report_${DateFormat('yyyy-MM-dd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: resolvedTitle,
        subtitle: resolvedSubtitle,
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

  /// Generates and prints single visitor pass / gate slip
  static Future<void> generateAndPrintVisitorSlip(
    VisitorModel visitor, {
    BuildContext? context,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        visitor.purpose,
        visitor.area,
        visitor.remarks,
        visitor.status,
      ], activeLang),
      PdfTranslationHelper.batchNames([
        visitor.name,
        visitor.reference,
      ], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final rawShortId = visitor.id.length >= 6 ? visitor.id.substring(0, 6).toUpperCase() : visitor.id;
    final shortId = PdfTranslationHelper.formatNumber(rawShortId, activeLang);
    final passNumberText = AppTranslations.pick(
      activeLang,
      en: 'PASS #$shortId',
      mr: 'पास क्र. #$shortId',
      hi: 'पास सं. #$shortId',
    );
    final modalSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Pass #$shortId',
      mr: 'पास क्र. #$shortId',
      hi: 'पास सं. #$shortId',
    );

    final systemTitle = AppTranslations.pick(
      activeLang,
      en: 'Nagarsevak Office Management System',
      mr: 'नगरसेवक कार्यालय व्यवस्थापन प्रणाली',
      hi: 'नगरसेवक कार्यालय प्रबंधन प्रणाली',
    );
    final passTitle = AppTranslations.pick(
      activeLang,
      en: 'VISITOR ENTRY PASS',
      mr: 'अभ्यागत प्रवेश पास',
      hi: 'आगंतुक प्रवेश पास',
    );
    final visitorNameLabel = AppTranslations.pick(
      activeLang,
      en: 'VISITOR NAME',
      mr: 'अभ्यागताचे नाव',
      hi: 'आगंतुक का नाम',
    );
    final contactLabel = AppTranslations.pick(
      activeLang,
      en: 'CONTACT NUMBER',
      mr: 'संपर्क क्रमांक',
      hi: 'संपर्क नंबर',
    );
    final purposeLabel = AppTranslations.pick(
      activeLang,
      en: 'PURPOSE OF VISIT',
      mr: 'भेटीचे कारण / उद्दिष्ट',
      hi: 'भेंट का उद्देश्य',
    );
    final areaLabel = AppTranslations.pick(
      activeLang,
      en: 'AREA / LOCALITY',
      mr: 'परिसर / भाग',
      hi: 'क्षेत्र / मोहल्ला',
    );
    final refLabel = AppTranslations.pick(
      activeLang,
      en: 'REFERENCE:',
      mr: 'संदर्भ:',
      hi: 'संदर्भ:',
    );
    final securityLabel = AppTranslations.pick(
      activeLang,
      en: 'Security / Desk In-Charge',
      mr: 'सुरक्षा / स्वागत कक्ष प्रमुख',
      hi: 'सुरक्षा / स्वागत डेस्क प्रभारी',
    );
    final officerLabel = AppTranslations.pick(
      activeLang,
      en: 'Officer / PA Signature',
      mr: 'अधिकारी / स्वीय सहायक स्वाक्षरी',
      hi: 'अधिकारी / पीए हस्ताक्षर',
    );
    final generatedByText = AppTranslations.formatDigits(
      AppTranslations.t('common.generated_by', lang: activeLang),
      activeLang,
    );
    final datePrefix = AppTranslations.pick(activeLang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:');

    final resolvedName = PdfTranslationHelper.resolveName(nameCache, visitor.name, activeLang);
    final resolvedMobile = visitor.mobile.trim().isNotEmpty
        ? PdfTranslationHelper.formatNumber(visitor.mobile.trim(), activeLang)
        : '-';
    final resolvedPurpose = PdfTranslationHelper.resolve(textCache, visitor.purpose, activeLang);
    final defaultPrabhag = AppTranslations.pick(activeLang, en: 'Prabhag 12', mr: 'प्रभाग १२', hi: 'प्रभाग १२');
    final resolvedArea = _resolveArea(textCache, visitor.area, activeLang, fallback: defaultPrabhag);
    final resolvedRef = (visitor.reference != null && visitor.reference!.trim().isNotEmpty)
        ? PdfTranslationHelper.resolveName(nameCache, visitor.reference, activeLang)
        : '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            systemTitle,
                            style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate500),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            passTitle,
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: WebReportTheme.brand50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
                      ),
                      child: pw.Text(
                        passNumberText,
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(visitorNameLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                              pw.SizedBox(height: 2),
                              pw.Text(resolvedName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                            ],
                          ),
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(contactLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                            pw.SizedBox(height: 2),
                            pw.Text(resolvedMobile, style: const pw.TextStyle(fontSize: 10, color: WebReportTheme.slate800)),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: WebReportTheme.slate200, thickness: 0.5),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(purposeLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                              pw.SizedBox(height: 2),
                              pw.Text(resolvedPurpose, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(areaLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                              pw.SizedBox(height: 2),
                              pw.Text(resolvedArea, style: const pw.TextStyle(fontSize: 9.5, color: WebReportTheme.slate800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (resolvedRef.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Text('$refLabel $resolvedRef', style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600)),
                    ],
                  ],
                ),
              ),

              pw.Spacer(),

              // Signature strip
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(securityLabel, style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate500)),
                      pw.SizedBox(height: 20),
                      pw.Container(width: 100, height: 1, color: WebReportTheme.slate400),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(officerLabel, style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate500)),
                      pw.SizedBox(height: 20),
                      pw.Container(width: 100, height: 1, color: WebReportTheme.slate400),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: WebReportTheme.slate100, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(generatedByText, style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: WebReportTheme.slate400)),
                    pw.Text('$datePrefix $formattedDate', style: const pw.TextStyle(fontSize: 7, color: WebReportTheme.slate400)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final fileName = 'Visitor_Pass_${visitor.id}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: AppTranslations.pick(
          activeLang,
          en: 'Visitor Entry Pass',
          mr: 'अभ्यागत प्रवेश पास',
          hi: 'आगंतुक प्रवेश पास',
        ),
        subtitle: modalSubtitle,
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
}
