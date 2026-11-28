import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/scheme_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class SchemeReportGenerator {
  SchemeReportGenerator._();

  static String _pickRawForLang(String raw, String lang) {
    if (raw.trim().isEmpty) return '';
    final extracted = SchemeModel.extractLocalized(raw, lang == 'mr');
    if (extracted.trim().isNotEmpty) return extracted.trim();
    return raw.trim();
  }

  static String _resolveStatus(Map<String, String> cache, String? raw, String lang) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final clean = raw.trim();
    final domain = AppTranslations.getStatus(clean, lang);
    final plainDigits = AppTranslations.formatDigits(clean, lang);
    if (domain.toLowerCase() != clean.toLowerCase() && domain != plainDigits) {
      return AppTranslations.formatDigits(domain, lang);
    }
    if (lang == 'en' && !RegExp(r'[\u0900-\u097F]').hasMatch(clean)) {
      return AppTranslations.formatDigits(domain, lang);
    }
    return PdfTranslationHelper.resolve(cache, clean, lang);
  }

  /// Multi-page PDF directory of all government schemes
  static Future<void> generateAndPrintListReport({
    BuildContext? context,
    required List<SchemeModel> schemes,
    bool? isMarathi,
    String? lang,
    String? categoryFilter,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : (isMarathi == true ? 'mr' : appLanguageValueNotifier.value);
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDateTime(now, activeLang);
    final total = schemes.length;

    final rawNames = <String>[];
    final rawDescs = <String>[];
    final rawBenefits = <String>[];
    for (final item in schemes) {
      rawNames.add(_pickRawForLang(item.name, activeLang));
      rawDescs.add(_pickRawForLang(item.description, activeLang));
      rawBenefits.add(_pickRawForLang(item.benefits, activeLang));
    }

    final textCache = await PdfTranslationHelper.batchText([
      categoryFilter,
      ...rawNames,
      ...rawDescs,
      ...rawBenefits,
      for (final item in schemes) item.category,
    ], activeLang);

    final title = AppTranslations.pick(
      activeLang,
      en: 'Government Schemes',
      mr: 'शासकीय योजना',
      hi: 'सरकारी योजनाएं',
    );
    final subtitle = AppTranslations.pick(
      activeLang,
      en: 'Official Directory of State & Central Welfare Schemes',
      mr: 'राज्य व केंद्र शासकीय कल्याणकारी योजनांची अधिकृत सूची',
      hi: 'राज्य व केंद्र सरकारी कल्याणकारी योजनाओं की आधिकारिक सूची',
    );

    final hasCategoryFilter = categoryFilter != null &&
        categoryFilter.trim().isNotEmpty &&
        categoryFilter.trim().toLowerCase() != 'all';
    final filterText = hasCategoryFilter
        ? '${AppTranslations.getReportColumn('category', activeLang)}: ${PdfTranslationHelper.resolve(textCache, categoryFilter, activeLang)}'
        : '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: title,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: title,
              subtitle: subtitle,
              dateFormatted: nowStr,
              totalCount: total,
              foundLabel: AppTranslations.pick(
                activeLang,
                en: 'Found',
                mr: 'एकूण आढळले',
                hi: 'कुल मिले',
              ),
              lang: activeLang,
            ),
            if (filterText.isNotEmpty) ...[
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.slate50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
                ),
                child: pw.Text(
                  filterText,
                  style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600),
                ),
              ),
            ] else
              pw.SizedBox(height: 12),

            if (schemes.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No government schemes found for the selected view.',
                    mr: 'कोणत्याही शासकीय योजना सापडल्या नाहीत.',
                    hi: 'कोई सरकारी योजना नहीं मिली।',
                  ),
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
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(2.5),
                  2: pw.FlexColumnWidth(3.5),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(3.0),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(activeLang, en: 'Scheme Name', mr: 'योजनेचे नाव', hi: 'योजना का नाम'),
                  AppTranslations.getReportColumn('description', activeLang),
                  AppTranslations.getReportColumn('category', activeLang),
                  AppTranslations.pick(activeLang, en: 'Benefits', mr: 'लाभ', hi: 'लाभ'),
                ],
                data: List.generate(schemes.length, (index) {
                  final item = schemes[index];
                  final nameStr = PdfTranslationHelper.resolve(textCache, rawNames[index], activeLang);
                  final descStr = PdfTranslationHelper.resolve(textCache, rawDescs[index], activeLang);
                  final catStr = PdfTranslationHelper.resolve(textCache, item.category, activeLang);
                  final benStr = PdfTranslationHelper.resolve(textCache, rawBenefits[index], activeLang);

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    nameStr,
                    descStr,
                    catStr,
                    benStr,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Government_Schemes_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: title,
        subtitle: subtitle,
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

  /// Single Scheme Official Guideline Slip / Public Flyer
  static Future<void> generateAndPrintSingleSchemeFlyer({
    BuildContext? context,
    required SchemeModel scheme,
    bool? isMarathi,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : (isMarathi == true ? 'mr' : appLanguageValueNotifier.value);
    final pdf = await WebReportTheme.createDocument(lang: activeLang);

    final rawName = _pickRawForLang(scheme.name, activeLang);
    final rawDesc = _pickRawForLang(scheme.description, activeLang);
    final rawElig = _pickRawForLang(scheme.eligibility, activeLang);
    final rawBen = _pickRawForLang(scheme.benefits, activeLang);
    final rawDoc = _pickRawForLang(scheme.documents, activeLang);

    final textCache = await PdfTranslationHelper.batchText([
      rawName,
      rawDesc,
      rawElig,
      rawBen,
      rawDoc,
      scheme.category,
    ], activeLang);

    final resolvedName = PdfTranslationHelper.resolve(textCache, rawName, activeLang);
    final resolvedDesc = PdfTranslationHelper.resolve(textCache, rawDesc, activeLang);
    final resolvedElig = PdfTranslationHelper.resolve(textCache, rawElig, activeLang);
    final resolvedBen = PdfTranslationHelper.resolve(textCache, rawBen, activeLang);
    final resolvedDoc = PdfTranslationHelper.resolve(textCache, rawDoc, activeLang);
    final defaultCat = AppTranslations.pick(
      activeLang,
      en: 'Government Scheme',
      mr: 'शासकीय योजना',
      hi: 'सरकारी योजना',
    );
    final resolvedCategory = scheme.category.trim().isNotEmpty
        ? PdfTranslationHelper.resolve(textCache, scheme.category, activeLang, fallback: defaultCat)
        : defaultCat;

    final flyerSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Scheme Guide & Eligibility Slip',
      mr: 'योजना मार्गदर्शक व पात्रता पत्रक',
      hi: 'योजना मार्गदर्शिका व पात्रता पत्र',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    resolvedName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.brand700,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: WebReportTheme.brand50,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      resolvedCategory,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Description Box
            _buildFlyerSection(
              title: AppTranslations.pick(activeLang, en: 'Description', mr: 'माहिती / वर्णन', hi: 'विवरण / जानकारी'),
              accentColor: WebReportTheme.brand600,
              content: resolvedDesc,
            ),
            pw.SizedBox(height: 12),

            // Eligibility Box
            _buildFlyerSection(
              title: AppTranslations.pick(activeLang, en: 'Eligibility', mr: 'पात्रता', hi: 'पात्रता'),
              accentColor: PdfColors.green700,
              content: resolvedElig,
            ),
            pw.SizedBox(height: 12),

            // Benefits Box
            _buildFlyerSection(
              title: AppTranslations.pick(activeLang, en: 'Benefits', mr: 'फायदे / लाभ', hi: 'लाभ / फायदे'),
              accentColor: PdfColors.amber700,
              content: resolvedBen,
            ),
            pw.SizedBox(height: 12),

            // Required Documents Box
            _buildFlyerSection(
              title: AppTranslations.pick(activeLang, en: 'Required Documents', mr: 'आवश्यक कागदपत्रे', hi: 'आवश्यक दस्तावेज़'),
              accentColor: PdfColors.purple700,
              content: resolvedDoc,
            ),
          ];
        },
      ),
    );

    final fileName = 'Scheme_${scheme.id}_Flyer';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: resolvedName,
        subtitle: flyerSubtitle,
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

  /// Beneficiary / Applications List PDF Report
  static Future<void> generateAndPrintBeneficiaryReport({
    BuildContext? context,
    required List<SchemeApplicationModel> applications,
    bool? isMarathi,
    String? lang,
  }) async {
    final effectiveLang = (lang != null && lang.isNotEmpty)
        ? lang
        : (isMarathi == true ? 'mr' : appLanguageValueNotifier.value);
    final pdf = await WebReportTheme.createDocument(lang: effectiveLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDateTime(now, effectiveLang);

    final rawSchemes = applications
        .map((a) => a.schemeName != null ? _pickRawForLang(a.schemeName!, effectiveLang) : '')
        .toList();

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        ...rawSchemes,
        for (final app in applications) ...[
          app.address,
          app.benefit,
          app.rejectionReason,
          app.status,
        ],
      ], effectiveLang),
      PdfTranslationHelper.batchNames([
        for (final app in applications) app.applicantName,
      ], effectiveLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final total = applications.length;
    final approved = applications.where((a) => a.isApproved).length;
    final pending = applications.where((a) => a.isPending).length;
    final rejected = applications.where((a) => a.isRejected).length;

    final title = AppTranslations.pick(
      effectiveLang,
      en: 'Government Schemes',
      mr: 'शासकीय योजना',
      hi: 'सरकारी योजनाएं',
    );
    final subtitle = AppTranslations.pick(
      effectiveLang,
      en: 'Application & Beneficiary Dossier',
      mr: 'अर्ज व लाभार्थी अहवाल',
      hi: 'आवेदन व लाभार्थी रिपोर्ट',
    );
    final contTitle = AppTranslations.pick(
      effectiveLang,
      en: 'Scheme Beneficiaries',
      mr: 'योजना लाभार्थी',
      hi: 'योजना लाभार्थी',
    );
    final totalAppsLabel = AppTranslations.pick(
      effectiveLang,
      en: 'Total Applications',
      mr: 'एकूण अर्ज',
      hi: 'कुल आवेदन',
    );
    final approvedLabel = AppTranslations.getStatus('Approved', effectiveLang);
    final pendingLabel = AppTranslations.getStatus('Pending', effectiveLang);
    final rejectedLabel = AppTranslations.getStatus('Rejected', effectiveLang);
    final datePrefix = AppTranslations.pick(effectiveLang, en: 'Date', mr: 'तारीख', hi: 'दिनांक');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: contTitle,
            lang: effectiveLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: effectiveLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: title,
              subtitle: subtitle,
              metaLines: [
                '$datePrefix: $nowStr',
                '$totalAppsLabel: ${PdfTranslationHelper.formatNumber(total, effectiveLang)}',
              ],
              lang: effectiveLang,
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
                  _buildSummaryItem(totalAppsLabel, PdfTranslationHelper.formatNumber(total, effectiveLang)),
                  _buildSummaryItem(approvedLabel, PdfTranslationHelper.formatNumber(approved, effectiveLang), highlightColor: PdfColors.green700),
                  _buildSummaryItem(pendingLabel, PdfTranslationHelper.formatNumber(pending, effectiveLang), highlightColor: PdfColors.amber800),
                  _buildSummaryItem(rejectedLabel, PdfTranslationHelper.formatNumber(rejected, effectiveLang), highlightColor: PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (applications.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    effectiveLang,
                    en: 'No scheme application records found for the selected view.',
                    mr: 'निवडलेल्या दृश्यासाठी कोणतीही योजना अर्ज नोंद आढळली नाही.',
                    hi: 'चयनित दृश्य के लिए कोई योजना आवेदन रिकॉर्ड नहीं मिला।',
                  ),
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
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(2.0),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(2.6),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.2),
                  6: pw.FlexColumnWidth(2.2),
                },
                headers: [
                  AppTranslations.pick(effectiveLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(effectiveLang, en: 'Applicant Name', mr: 'अर्जदाराचे नाव', hi: 'आवेदक का नाम'),
                  AppTranslations.pick(effectiveLang, en: 'Mobile / Address', mr: 'मोबाईल / पत्ता', hi: 'मोबाइल / पता'),
                  AppTranslations.getReportColumn('scheme_name', effectiveLang),
                  AppTranslations.getReportColumn('date', effectiveLang),
                  AppTranslations.getReportColumn('status', effectiveLang),
                  AppTranslations.pick(effectiveLang, en: 'Benefit / Reason', mr: 'लाभ / कारण', hi: 'लाभ / कारण'),
                ],
                data: List.generate(applications.length, (index) {
                  final app = applications[index];
                  final mobilePart = app.mobile.trim().isNotEmpty
                      ? PdfTranslationHelper.formatNumber(app.mobile.trim(), effectiveLang)
                      : '';
                  final addressPart = app.address.trim().isNotEmpty
                      ? PdfTranslationHelper.resolve(textCache, app.address, effectiveLang)
                      : '';
                  final contactPart = [mobilePart, addressPart].where((s) => s.isNotEmpty).join('\n');
                  final dateStr = PdfTranslationHelper.formatDate(
                    app.createdAt,
                    effectiveLang,
                    pattern: 'dd/MM/yyyy',
                  );
                  final rawNote = app.isRejected ? app.rejectionReason : app.benefit;
                  final notePart = PdfTranslationHelper.resolve(textCache, rawNote, effectiveLang);
                  final schemeStr = rawSchemes[index].isNotEmpty
                      ? PdfTranslationHelper.resolve(textCache, rawSchemes[index], effectiveLang)
                      : '-';

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, effectiveLang),
                    PdfTranslationHelper.resolveName(nameCache, app.applicantName, effectiveLang),
                    contactPart.isNotEmpty ? contactPart : '-',
                    schemeStr,
                    dateStr,
                    _resolveStatus(textCache, app.status, effectiveLang),
                    notePart,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final modalTitle = AppTranslations.pick(
      effectiveLang,
      en: 'Scheme Applications Report',
      mr: 'योजना अर्ज व लाभार्थी अहवाल',
      hi: 'योजना आवेदन एवं लाभार्थी रिपोर्ट',
    );
    final modalSubtitle = AppTranslations.pick(
      effectiveLang,
      en: 'Beneficiary & Application Audit',
      mr: 'लाभार्थी व अर्ज तपासणी अहवाल',
      hi: 'लाभार्थी एवं आवेदन लेखापरीक्षा',
    );
    final fileName = 'Scheme_Applications_Report_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: modalTitle,
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

  static pw.Widget _buildFlyerSection({
    required String title,
    required PdfColor accentColor,
    required String content,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: WebReportTheme.slate50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border(
          left: pw.BorderSide(color: accentColor, width: 3),
          top: const pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
          right: const pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
          bottom: const pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: WebReportTheme.slate800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            content.isNotEmpty ? content : '-',
            style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2, color: WebReportTheme.slate700),
          ),
        ],
      ),
    );
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
