import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/letter_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Letter Registry & Documentation Report Generator matching Nagarsevak-Managment
/// (LetterReportGenerator.tsx).
class LetterReportGenerator {
  LetterReportGenerator._();

  static String _resolveArea(Map<String, String> cache, String? raw, String lang, {String fallback = '-'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final clean = raw.trim();
    final domain = AppTranslations.getAreaName(clean, lang);
    final plainDigits = AppTranslations.formatDigits(clean, lang);
    if (domain != clean && domain != plainDigits) return domain;
    return PdfTranslationHelper.resolve(cache, clean, lang, fallback: fallback);
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

  static Future<void> generateAndPrintLetterReport({
    BuildContext? context,
    required List<LetterModel> letters,
    String? statusFilter,
    String? typeFilter,
    String? areaFilter,
    String? title,
    String? subtitle,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);
    final total = letters.length;

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        title,
        subtitle,
        statusFilter,
        typeFilter,
        areaFilter,
        for (final l in letters) ...[
          l.title,
          l.letterType,
          l.subject,
          l.area,
          l.status,
          l.department,
        ],
      ], activeLang),
      PdfTranslationHelper.batchNames([
        for (final l in letters) ...[
          l.citizenName,
          l.sender,
          l.recipient,
        ],
      ], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final resolvedTitle = (title != null && title.trim().isNotEmpty)
        ? PdfTranslationHelper.resolve(textCache, title, activeLang, fallback: title)
        : AppTranslations.pick(
            activeLang,
            en: 'Letters Register Report',
            mr: 'पत्र नोंदवही अहवाल',
            hi: 'पत्र रजिस्टर रिपोर्ट',
          );
    final resolvedSubtitle = (subtitle != null && subtitle.trim().isNotEmpty)
        ? PdfTranslationHelper.resolve(textCache, subtitle, activeLang, fallback: subtitle)
        : AppTranslations.pick(
            activeLang,
            en: 'Inward & Outward Letters Official Register',
            mr: 'आवक आणि जावक अधिकृत पत्र नोंदवही',
            hi: 'आवक और जावक आधिकारिक पत्र रजिस्टर',
          );

    final activeFilters = <String>[];
    if (statusFilter != null && statusFilter.trim().isNotEmpty && statusFilter.trim().toLowerCase() != 'all') {
      final label = AppTranslations.pick(activeLang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति');
      activeFilters.add('$label: ${_resolveStatus(textCache, statusFilter, activeLang)}');
    }
    if (typeFilter != null && typeFilter.trim().isNotEmpty && typeFilter.trim().toLowerCase() != 'all') {
      final label = AppTranslations.pick(activeLang, en: 'Type', mr: 'प्रकार', hi: 'प्रकार');
      activeFilters.add('$label: ${PdfTranslationHelper.resolve(textCache, typeFilter, activeLang)}');
    }
    if (areaFilter != null && areaFilter.trim().isNotEmpty && areaFilter.trim().toLowerCase() != 'all' && areaFilter.trim().toLowerCase() != 'all areas') {
      final label = AppTranslations.pick(activeLang, en: 'Area', mr: 'भाग', hi: 'क्षेत्र');
      activeFilters.add('$label: ${_resolveArea(textCache, areaFilter, activeLang)}');
    }

    final defaultPrabhag = AppTranslations.pick(
      activeLang,
      en: 'Prabhag 12',
      mr: 'प्रभाग १२',
      hi: 'प्रभाग १२',
    );
    final emptyMsg = AppTranslations.pick(
      activeLang,
      en: 'No letter records found for the selected view.',
      mr: 'निवडलेल्या निकषांनुसार पत्रांच्या कोणत्याही नोंदी आढळल्या नाहीत.',
      hi: 'चयनित दृश्य के लिए कोई पत्र रिकॉर्ड नहीं मिला।',
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
            foundLabel: AppTranslations.pick(
              activeLang,
              en: 'Found',
              mr: 'एकूण आढळले',
              hi: 'कुल मिले',
            ),
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            if (activeFilters.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.slate50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
                ),
                child: pw.Text(
                  activeFilters.join('  |  '),
                  style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600),
                ),
              ),
            if (letters.isEmpty)
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
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(activeLang, en: 'Ref / Date', mr: 'संदर्भ / दिनांक', hi: 'संदर्भ / दिनांक'),
                  AppTranslations.pick(activeLang, en: 'Flow', mr: 'प्रवाह', hi: 'प्रवाह'),
                  AppTranslations.pick(activeLang, en: 'Citizen', mr: 'नागरिक', hi: 'नागरिक'),
                  AppTranslations.getReportColumn('subject', activeLang),
                  AppTranslations.getReportColumn('area', activeLang),
                  AppTranslations.getReportColumn('status', activeLang),
                ],
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(1.4),
                  2: pw.FlexColumnWidth(1.0),
                  3: pw.FlexColumnWidth(1.8),
                  4: pw.FlexColumnWidth(2.2),
                  5: pw.FlexColumnWidth(1.4),
                  6: pw.FlexColumnWidth(1.0),
                },
                data: List.generate(letters.length, (index) {
                  final l = letters[index];
                  final dateStr = PdfTranslationHelper.formatDate(
                    l.receivedDate ?? l.createdAt,
                    activeLang,
                    pattern: 'dd/MM/yyyy',
                  );
                  final rawRefNo = l.details['letter_ref']?.toString() ??
                      (l.id.length >= 8 ? l.id.substring(0, 8).toUpperCase() : l.id);
                  final refNo = PdfTranslationHelper.formatNumber(rawRefNo, activeLang);
                  final flow = l.isIncoming
                      ? AppTranslations.pick(activeLang, en: 'INWARD', mr: 'आवक', hi: 'आवक')
                      : AppTranslations.pick(activeLang, en: 'OUTWARD', mr: 'जावक', hi: 'जावक');
                  final rawRecipient = l.isIncoming ? (l.sender ?? l.citizenName) : l.citizenName;
                  final recipient = PdfTranslationHelper.resolveName(nameCache, rawRecipient, activeLang);
                  final resolvedType = PdfTranslationHelper.resolve(
                    textCache,
                    l.letterType ?? l.title,
                    activeLang,
                  );
                  final resolvedSubject = PdfTranslationHelper.resolve(
                    textCache,
                    l.subject,
                    activeLang,
                  );
                  final typeSubject = resolvedType != resolvedSubject
                      ? '$resolvedType\n$resolvedSubject'
                      : resolvedSubject;
                  final area = _resolveArea(
                    textCache,
                    l.area,
                    activeLang,
                    fallback: defaultPrabhag,
                  );
                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$refNo\n$dateStr',
                    flow,
                    recipient,
                    typeSubject,
                    area,
                    _resolveStatus(textCache, l.status, activeLang),
                  ];
                }),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
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

    final fileName = 'Letters_Register_${DateFormat('yyyyMMdd').format(now)}';
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

  /// Generates and prints a single official letter / request docket (Portrait A4)
  static Future<void> generateAndPrintSingleLetter({
    BuildContext? context,
    required LetterModel letter,
    String? letterBody,
    String? nagarsevakName,
    String? wardName,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);

    final rawBody = (letterBody != null && letterBody.trim().isNotEmpty)
        ? letterBody
        : (letter.description != null && letter.description!.trim().isNotEmpty)
            ? letter.description!
            : (letter.details['text']?.toString().trim().isNotEmpty == true)
                ? letter.details['text'].toString()
                : (letter.details['details']?.toString().trim().isNotEmpty == true)
                    ? letter.details['details'].toString()
                    : AppTranslations.pick(
                        activeLang,
                        en: 'Official letter representation recorded for civic administration and department follow-up.',
                        mr: 'नागरी प्रशासन आणि विभागाच्या पाठपुराव्यासाठी अधिकृत पत्र नोंदवले आहे.',
                        hi: 'नागरिक प्रशासन और विभाग की कार्यवाही के लिए आधिकारिक पत्र दर्ज किया गया है।',
                      );

    final effectiveWardInput = (wardName != null && wardName.trim().isNotEmpty && wardName != 'Ward No. 12 (Prabhag 12)')
        ? wardName
        : null;
    final effectiveOfficeInput = (nagarsevakName != null && nagarsevakName.trim().isNotEmpty && nagarsevakName != 'Nagarsevak Office')
        ? nagarsevakName
        : null;

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        rawBody,
        letter.letterType,
        letter.title,
        letter.subject,
        letter.area,
        letter.status,
        effectiveWardInput,
      ], activeLang),
      PdfTranslationHelper.batchNames([
        letter.sender,
        letter.recipient,
        letter.citizenName,
        effectiveOfficeInput,
      ], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final dateStr = PdfTranslationHelper.formatDate(
      letter.createdAt,
      activeLang,
      pattern: 'dd MMMM yyyy',
    );
    final rawShortId = letter.id.length >= 8 ? letter.id.substring(0, 8).toUpperCase() : letter.id;
    final rawRefNo = letter.isIncoming ? 'INW-$rawShortId' : 'OUT-$rawShortId';
    final refNo = PdfTranslationHelper.formatNumber(rawRefNo, activeLang);

    final resolvedWard = effectiveWardInput != null
        ? _resolveArea(textCache, effectiveWardInput, activeLang)
        : AppTranslations.pick(
            activeLang,
            en: 'Ward No. 12 (Prabhag 12)',
            mr: 'प्रभाग क्र. १२',
            hi: 'वार्ड नं. १२ (प्रभाग १२)',
          );
    final resolvedOffice = effectiveOfficeInput != null
        ? PdfTranslationHelper.resolveName(nameCache, effectiveOfficeInput, activeLang)
        : AppTranslations.pick(
            activeLang,
            en: 'Office of Nagarsevak',
            mr: 'नगरसेवक कार्यालय',
            hi: 'नगरसेवक कार्यालय',
          );

    final flowText = letter.isIncoming
        ? AppTranslations.pick(activeLang, en: 'INWARD / RECEIVED', mr: 'आवक / प्राप्त', hi: 'आवक / प्राप्त')
        : AppTranslations.pick(activeLang, en: 'OUTWARD / DISPATCHED', mr: 'जावक / पाठवले', hi: 'जावक / भेजा गया');
    final statusText = _resolveStatus(textCache, letter.status, activeLang);
    final fromLabel = letter.isIncoming
        ? AppTranslations.pick(activeLang, en: 'FROM (SENDER)', mr: 'प्रेषक (पाठवणारा)', hi: 'प्रेषक (भेजने वाला)')
        : AppTranslations.pick(activeLang, en: 'CITIZEN / APPLICANT', mr: 'नागरिक / अर्जदार', hi: 'नागरिक / आवेदक');
    final typeLabel = AppTranslations.pick(
      activeLang,
      en: 'TYPE & JURISDICTION',
      mr: 'प्रकार आणि अधिकारक्षेत्र',
      hi: 'प्रकार और अधिकार क्षेत्र',
    );
    final subjectHeader = AppTranslations.pick(
      activeLang,
      en: 'LETTER SUBJECT & SUBMISSION DETAILS',
      mr: 'पत्राचा विषय आणि तपशील',
      hi: 'पत्र विषय और विवरण',
    );

    final resolvedPerson = PdfTranslationHelper.resolveName(
      nameCache,
      letter.isIncoming ? (letter.sender ?? letter.citizenName) : letter.citizenName,
      activeLang,
    );
    final resolvedMobile = letter.mobile.trim().isNotEmpty
        ? PdfTranslationHelper.formatNumber(letter.mobile.trim(), activeLang)
        : '-';
    final resolvedType = PdfTranslationHelper.resolve(
      textCache,
      letter.letterType ?? letter.title,
      activeLang,
    );
    final resolvedArea = _resolveArea(
      textCache,
      letter.area,
      activeLang,
      fallback: AppTranslations.pick(activeLang, en: 'Prabhag 12', mr: 'प्रभाग १२', hi: 'प्रभाग १२'),
    );
    final resolvedSubject = PdfTranslationHelper.resolve(textCache, letter.subject, activeLang);
    final resolvedBody = PdfTranslationHelper.resolve(textCache, rawBody, activeLang);

    final dateLabel = AppTranslations.pick(activeLang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक');
    final contactLabel = AppTranslations.pick(activeLang, en: 'Contact', mr: 'संपर्क', hi: 'संपर्क');
    final flowLabel = AppTranslations.pick(activeLang, en: 'FLOW', mr: 'प्रवाह', hi: 'प्रवाह');
    final systemLabel = AppTranslations.pick(
      activeLang,
      en: 'Nagarsevak Office Management System',
      mr: 'नगरसेवक कार्यालय व्यवस्थापन प्रणाली',
      hi: 'नगरसेवक कार्यालय प्रबंधन प्रणाली',
    );
    final sealPlaceholder = AppTranslations.pick(
      activeLang,
      en: '[OFFICE\nSEAL]',
      mr: '[कार्यालय\nशिक्का]',
      hi: '[कार्यालय\nमुहर]',
    );
    final stampLabel = AppTranslations.pick(
      activeLang,
      en: 'Prabhag 12 Office Stamp',
      mr: 'प्रभाग १२ कार्यालय शिक्का',
      hi: 'प्रभाग १२ कार्यालय मुहर',
    );
    final signatoryLabel = AppTranslations.pick(
      activeLang,
      en: 'Authorized Signatory',
      mr: 'अधिकृत स्वाक्षरी',
      hi: 'अधिकृत हस्ताक्षरकर्ता',
    );
    final secretariatLabel = AppTranslations.pick(
      activeLang,
      en: 'Nagarsevak Secretariat • Pune',
      mr: 'नगरसेवक सचिवालय • पुणे',
      hi: 'नगरसेवक सचिवालय • पुणे',
    );
    final generatedByText = AppTranslations.formatDigits(
      AppTranslations.t('common.generated_by', lang: activeLang),
      activeLang,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '$resolvedOffice • $resolvedWard',
                          style: const pw.TextStyle(fontSize: 9, color: WebReportTheme.slate500),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          letter.isIncoming
                              ? AppTranslations.pick(activeLang, en: 'INWARD CORRESPONDENCE', mr: 'आवक पत्र', hi: 'आवक पत्र')
                              : AppTranslations.pick(activeLang, en: 'OUTWARD LETTER', mr: 'जावक पत्र', hi: 'जावक पत्र'),
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: WebReportTheme.brand700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          systemLabel,
                          style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate500),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: WebReportTheme.brand50,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
                          ),
                          child: pw.Text(
                            refNo,
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('$dateLabel: $dateStr', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Overview Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.slate50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: WebReportTheme.slate200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('$flowLabel: $flowText', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700)),
                    pw.Text('${AppTranslations.getReportColumn('status', activeLang)}: $statusText', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Parties Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(fromLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                          pw.SizedBox(height: 4),
                          pw.Text(resolvedPerson, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                          pw.Text('$contactLabel: $resolvedMobile', style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(typeLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                          pw.SizedBox(height: 4),
                          pw.Text(resolvedType, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                          pw.Text('${AppTranslations.getReportColumn('area', activeLang)}: $resolvedArea', style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Letter Body Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(subjectHeader, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                    pw.SizedBox(height: 6),
                    pw.Text('${AppTranslations.getReportColumn('subject', activeLang)}: $resolvedSubject', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                    pw.SizedBox(height: 6),
                    pw.Text(resolvedBody, style: const pw.TextStyle(fontSize: 9, lineSpacing: 2, color: WebReportTheme.slate800)),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer & Stamp
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: WebReportTheme.slate400),
                          borderRadius: pw.BorderRadius.circular(35),
                        ),
                        child: pw.Center(
                          child: pw.Text(sealPlaceholder, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(stampLabel, style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: WebReportTheme.slate700),
                      pw.SizedBox(height: 4),
                      pw.Text(signatoryLabel, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate800)),
                      pw.Text(secretariatLabel, style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: WebReportTheme.slate100, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(generatedByText, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: WebReportTheme.slate400)),
                    pw.Text('$dateLabel: $dateStr', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final fileName = 'Letter_${letter.id}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: letter.isIncoming
            ? AppTranslations.pick(activeLang, en: 'Incoming Letter', mr: 'आवक पत्र', hi: 'आवक पत्र')
            : AppTranslations.pick(activeLang, en: 'Outgoing Letter', mr: 'जावक पत्र', hi: 'जावक पत्र'),
        subtitle: '${AppTranslations.pick(activeLang, en: 'Ref:', mr: 'संदर्भ:', hi: 'संदर्भ:')} ${PdfTranslationHelper.formatNumber(rawShortId, activeLang)}',
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
