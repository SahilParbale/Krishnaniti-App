import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/gb_register_entry_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official General Body (GB) Register Report Generator matching Nagarsevak-Managment
/// (pages/diary/DiaryReportGenerator.tsx).
class GbRegisterReportGenerator {
  GbRegisterReportGenerator._();

  static Future<void> generateAndPrintGbReport({
    BuildContext? context,
    required List<GbRegisterEntryModel> entries,
    String? meetingTypeFilter,
    String? statusFilter,
    String title = 'GB Register Report',
    String subtitle = 'Meeting Records, Resolutions & Outcomes',
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);
    final total = entries.length;

    final hasCustomTitle = title != 'GB Register Report';
    final hasCustomSubtitle =
        subtitle != 'Meeting Records, Resolutions & Outcomes';
    final hasMeetingTypeFilter = meetingTypeFilter != null &&
        meetingTypeFilter.trim().isNotEmpty &&
        meetingTypeFilter != 'All';
    final hasStatusFilter = statusFilter != null &&
        statusFilter.trim().isNotEmpty &&
        statusFilter != 'All';

    final textCache = await PdfTranslationHelper.batchText(
      [
        if (hasCustomTitle) title,
        if (hasCustomSubtitle) subtitle,
        if (hasMeetingTypeFilter) meetingTypeFilter,
        if (hasStatusFilter) statusFilter,
        for (final e in entries) ...[
          e.subject,
          e.description,
          e.department,
          e.area,
          e.response,
          e.meetingType,
          e.status,
        ],
      ],
      activeLang,
    );

    final effectiveTitle = hasCustomTitle
        ? PdfTranslationHelper.resolve(textCache, title, activeLang)
        : AppTranslations.pick(
            activeLang,
            en: 'GB Register Report',
            mr: 'जीबी रजिस्टर अहवाल',
            hi: 'जीबी रजिस्टर रिपोर्ट',
          );
    final effectiveSubtitle = hasCustomSubtitle
        ? PdfTranslationHelper.resolve(textCache, subtitle, activeLang)
        : AppTranslations.pick(
            activeLang,
            en: 'Meeting Records, Resolutions & Outcomes',
            mr: 'सभेच्या नोंदी, ठराव आणि कार्यवाही तपशील',
            hi: 'बैठक रिकॉर्ड, प्रस्ताव और निष्कर्ष विवरण',
          );
    final totalRecordsLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Records',
      mr: 'एकूण नोंदी',
      hi: 'कुल रिकॉर्ड',
    );
    final dateLabel = AppTranslations.pick(
      activeLang,
      en: 'Date',
      mr: 'दिनांक',
      hi: 'दिनांक',
    );
    final meetingTypeLabel = AppTranslations.pick(
      activeLang,
      en: 'Meeting Type',
      mr: 'सभेचा प्रकार',
      hi: 'बैठक प्रकार',
    );
    final statusLabel = AppTranslations.pick(
      activeLang,
      en: 'Status',
      mr: 'स्थिती',
      hi: 'स्थिति',
    );
    final defaultAreaLabel = AppTranslations.pick(
      activeLang,
      en: 'Prabhag 12',
      mr: 'प्रभाग १२',
      hi: 'वार्ड १२',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: effectiveTitle,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) =>
            WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: effectiveTitle,
              subtitle: effectiveSubtitle,
              dateFormatted: formattedDate,
              totalCount: total,
              foundLabel: totalRecordsLabel,
              lang: activeLang,
              metaLines: (hasMeetingTypeFilter || hasStatusFilter)
                  ? [
                      '$dateLabel: $formattedDate',
                      '$totalRecordsLabel: ${PdfTranslationHelper.formatNumber(total, activeLang)}',
                      if (hasMeetingTypeFilter)
                        '$meetingTypeLabel: ${_resolveMeetingType(meetingTypeFilter, textCache, activeLang)}',
                      if (hasStatusFilter)
                        '$statusLabel: ${_resolveStatus(statusFilter, textCache, activeLang)}',
                    ]
                  : null,
            ),
            if (entries.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No GB register records found for the selected view.',
                    mr: 'निवडलेल्या पर्यायासाठी जीबी रजिस्टरच्या नोंदी आढळल्या नाहीत.',
                    hi: 'चयनित दृश्य के लिए कोई जीबी रजिस्टर रिकॉर्ड नहीं मिला।',
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
                cellStyle: WebReportTheme.tableCellStyle,
                headerCount: 1,
                oddRowDecoration: WebReportTheme.oddRowDecoration,
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.7), // #
                  1: pw.FlexColumnWidth(1.2), // Date
                  2: pw.FlexColumnWidth(1.2), // Meeting Type
                  3: pw.FlexColumnWidth(2.6), // Subject
                  4: pw.FlexColumnWidth(1.5), // Department
                  5: pw.FlexColumnWidth(1.4), // Outcome
                  6: pw.FlexColumnWidth(1.4), // Area
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Date',
                    mr: 'दिनांक',
                    hi: 'दिनांक',
                  ),
                  meetingTypeLabel,
                  AppTranslations.pick(
                    activeLang,
                    en: 'Subject / Resolution',
                    mr: 'विषय / ठराव',
                    hi: 'विषय / प्रस्ताव',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Department',
                    mr: 'विभाग',
                    hi: 'विभाग',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Outcome / Status',
                    mr: 'निष्कर्ष / स्थिती',
                    hi: 'निष्कर्ष / स्थिति',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Area',
                    mr: 'परिसर',
                    hi: 'क्षेत्र',
                  ),
                ],
                data: List.generate(entries.length, (index) {
                  final e = entries[index];
                  final statusStr = _resolveStatus(e.status, textCache, activeLang);
                  final outcomeStr =
                      (e.response != null && e.response!.trim().isNotEmpty)
                          ? '$statusStr\n${PdfTranslationHelper.resolve(textCache, e.response, activeLang)}'
                          : statusStr;

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    _resolveMeetingDate(e.meetingDate, activeLang),
                    _resolveMeetingType(e.meetingType, textCache, activeLang),
                    PdfTranslationHelper.resolve(textCache, e.subject, activeLang),
                    PdfTranslationHelper.resolve(textCache, e.department, activeLang),
                    outcomeStr,
                    e.area.trim().isNotEmpty
                        ? _resolveArea(e.area, textCache, activeLang)
                        : defaultAreaLabel,
                  ];
                }),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerLeft,
                  6: pw.Alignment.centerLeft,
                },
              ),
          ];
        },
      ),
    );

    final fileName = 'GB_Register_Report_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: effectiveTitle,
        subtitle: effectiveSubtitle,
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

  static String _resolveMeetingDate(String raw, String lang) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) {
      return PdfTranslationHelper.formatDate(iso, lang, pattern: 'dd/MM/yyyy');
    }
    for (final fmt in const ['dd/MM/yyyy', 'dd MMM yyyy', 'MMM d, yyyy', 'yyyy-MM-dd']) {
      try {
        final dt = DateFormat(fmt, 'en_US').parseStrict(trimmed);
        return PdfTranslationHelper.formatDate(dt, lang, pattern: 'dd MMM yyyy');
      } catch (_) {}
    }
    return PdfTranslationHelper.parseAndFormatDateString(trimmed, lang);
  }

  static String _resolveMeetingType(
    String raw,
    Map<String, String> textCache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    switch (trimmed.toLowerCase()) {
      case 'gb':
        return AppTranslations.pick(
          lang,
          en: 'General Body (GB)',
          mr: 'महासभा (GB)',
          hi: 'महासभा (GB)',
        );
      case 'standing committee':
      case 'standing':
        return AppTranslations.pick(
          lang,
          en: 'Standing Committee',
          mr: 'स्थायी समिती',
          hi: 'स्थायी समिति',
        );
      case 'ward committee':
      case 'ward':
        return AppTranslations.pick(
          lang,
          en: 'Ward Committee',
          mr: 'प्रभाग समिती',
          hi: 'वार्ड समिति',
        );
      case 'special gb':
        return AppTranslations.pick(
          lang,
          en: 'Special GB',
          mr: 'विशेष महासभा',
          hi: 'विशेष महासभा',
        );
      case 'other':
        return AppTranslations.pick(
          lang,
          en: 'Other',
          mr: 'इतर',
          hi: 'अन्य',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, trimmed, lang);
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
      case 'action taken':
      case 'action_taken':
      case 'sanctioned':
        return AppTranslations.pick(
          lang,
          en: 'Action Taken',
          mr: 'कार्यवाही झाली',
          hi: 'कार्रवाई की गई',
        );
      case 'resolved':
        return AppTranslations.pick(
          lang,
          en: 'Resolved',
          mr: 'सोडवला',
          hi: 'समाधान हुआ',
        );
      case 'in discussion':
      case 'in_discussion':
        return AppTranslations.pick(
          lang,
          en: 'In Discussion',
          mr: 'चर्चेत',
          hi: 'चर्चा में',
        );
      case 'rejected':
        return AppTranslations.pick(
          lang,
          en: 'Rejected',
          mr: 'नाकारले',
          hi: 'अस्वीकृत',
        );
      case 'raised':
        return AppTranslations.pick(
          lang,
          en: 'Raised',
          mr: 'मांडलेला',
          hi: 'उठाया गया',
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
}
