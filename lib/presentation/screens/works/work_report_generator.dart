import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/work_history_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Work History Report Generator matching Nagarsevak-Managment
/// (WorkReportGenerator.tsx).
class WorkReportGenerator {
  WorkReportGenerator._();

  static String _resolveArea(Map<String, String> cache, String? raw, String lang) {
    if (raw == null || raw.trim().isEmpty) return '';
    final clean = raw.trim();
    final domain = AppTranslations.getAreaName(clean, lang);
    final plainDigits = AppTranslations.formatDigits(clean, lang);
    if (domain != clean && domain != plainDigits) return domain;
    return PdfTranslationHelper.resolve(cache, clean, lang, fallback: clean);
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

  static Future<void> generateAndPrintWorkReport({
    BuildContext? context,
    required List<WorkHistoryModel> works,
    String? statusFilter,
    String? areaFilter,
    String title = 'Work History Report',
    String subtitle = 'Historical Register of Development Works & Municipal Projects',
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);
    final total = works.length;

    final textCache = await PdfTranslationHelper.batchText([
      if (title != 'Work History Report') title,
      if (subtitle != 'Historical Register of Development Works & Municipal Projects') subtitle,
      statusFilter,
      areaFilter,
      for (final w in works) ...[
        w.title,
        w.description,
        w.location,
        w.area,
        w.status,
      ],
    ], activeLang);

    final effectiveTitle = title != 'Work History Report'
        ? PdfTranslationHelper.resolve(textCache, title, activeLang, fallback: title)
        : AppTranslations.pick(
            activeLang,
            en: 'Work History Report',
            mr: 'विकास कामांचा अहवाल',
            hi: 'विकास कार्य रिपोर्ट',
          );
    final effectiveSubtitle = subtitle != 'Historical Register of Development Works & Municipal Projects'
        ? PdfTranslationHelper.resolve(textCache, subtitle, activeLang, fallback: subtitle)
        : AppTranslations.pick(
            activeLang,
            en: 'Historical Register of Development Works & Municipal Projects',
            mr: 'विकास कामे आणि विकास प्रकल्पांची ऐतिहासिक नोंद',
            hi: 'विकास कार्यों और नगर निगम परियोजनाओं का ऐतिहासिक रजिस्टर',
          );

    final activeFilters = <String>[];
    if (statusFilter != null && statusFilter.trim().isNotEmpty && statusFilter.trim().toLowerCase() != 'all') {
      final label = AppTranslations.pick(activeLang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति');
      activeFilters.add('$label: ${_resolveStatus(textCache, statusFilter, activeLang)}');
    }
    if (areaFilter != null && areaFilter.trim().isNotEmpty && areaFilter.trim().toLowerCase() != 'all' && areaFilter.trim().toLowerCase() != 'all areas') {
      final label = AppTranslations.pick(activeLang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र');
      activeFilters.add('$label: ${_resolveArea(textCache, areaFilter, activeLang)}');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: effectiveTitle,
              lang: activeLang,
            );
          }
          return WebReportTheme.buildHeader(
            title: effectiveTitle,
            subtitle: effectiveSubtitle,
            dateFormatted: formattedDate,
            totalCount: total,
            foundLabel: AppTranslations.pick(
              activeLang,
              en: 'Found',
              mr: 'एकूण कामे',
              hi: 'कुल कार्य',
            ),
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          if (works.isEmpty) {
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
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No development work records found.',
                    mr: 'विकास कामांच्या कोणत्याही नोंदी आढळल्या नाहीत.',
                    hi: 'कोई विकास कार्य रिकॉर्ड नहीं मिला।',
                  ),
                  style: const pw.TextStyle(fontSize: 12, color: WebReportTheme.slate400),
                ),
              ),
            ];
          }

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
                0: pw.FlexColumnWidth(0.6), // # (5%)
                1: pw.FlexColumnWidth(3.5), // Complaint / Subject (35%)
                2: pw.FlexColumnWidth(2.5), // Location / Area (25%)
                3: pw.FlexColumnWidth(1.5), // Status (15%)
                4: pw.FlexColumnWidth(1.9), // Amount (20%)
              },
              headers: [
                AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                AppTranslations.pick(activeLang, en: 'Complaint / Subject', mr: 'तक्रार / विषय', hi: 'शिकायत / विषय'),
                AppTranslations.pick(activeLang, en: 'Location / Area', mr: 'स्थान / क्षेत्र', hi: 'स्थान / क्षेत्र'),
                AppTranslations.getReportColumn('status', activeLang),
                AppTranslations.pick(activeLang, en: 'Amount', mr: 'रक्कम', hi: 'राशि'),
              ],
              data: List.generate(works.length, (index) {
                final w = works[index];
                final dateStr = w.date.trim().isNotEmpty
                    ? PdfTranslationHelper.parseAndFormatDateString(w.date, activeLang)
                    : '';
                final locResolved = _resolveArea(textCache, w.location, activeLang);
                final areaResolved = _resolveArea(textCache, w.area, activeLang);
                final locationStr = areaResolved.isNotEmpty && locResolved.isNotEmpty && areaResolved != locResolved
                    ? '$locResolved ($areaResolved)'
                    : (locResolved.isNotEmpty ? locResolved : (areaResolved.isNotEmpty ? areaResolved : '-'));

                final amountStr = w.amount != null && w.amount! > 0
                    ? PdfTranslationHelper.formatCurrency(
                        NumberFormat.decimalPattern('en_IN').format(w.amount!.toInt()),
                        activeLang,
                      )
                    : '--';

                final titleResolved = PdfTranslationHelper.resolve(textCache, w.title, activeLang);
                final descResolved = w.description.trim().isNotEmpty
                    ? PdfTranslationHelper.resolve(textCache, w.description, activeLang)
                    : '';
                final subjectDesc = descResolved.isNotEmpty
                    ? '$titleResolved\n$descResolved'
                    : titleResolved;

                final localizedStatus = _resolveStatus(textCache, w.status, activeLang);
                final statusWithDate = dateStr.isNotEmpty && dateStr != '-'
                    ? '$localizedStatus\n$dateStr'
                    : localizedStatus;

                return [
                  PdfTranslationHelper.formatNumber(index + 1, activeLang),
                  subjectDesc,
                  locationStr,
                  statusWithDate,
                  amountStr,
                ];
              }),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    final fileName = 'Work_History_Report_${DateFormat('yyyy-MM-dd').format(now)}';
    final bool useHarfBuzz = activeLang == 'mr' || activeLang == 'hi';

    Future<List<int>> buildPdfBytes() async {
      if (!useHarfBuzz) return pdf.save();
      final htmlHeaders = [
        AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
        AppTranslations.pick(activeLang, en: 'Complaint / Subject', mr: 'तक्रार / विषय', hi: 'शिकायत / विषय'),
        AppTranslations.pick(activeLang, en: 'Location / Area', mr: 'स्थान / क्षेत्र', hi: 'स्थान / क्षेत्र'),
        AppTranslations.getReportColumn('status', activeLang),
        AppTranslations.pick(activeLang, en: 'Amount', mr: 'रक्कम', hi: 'राशि'),
      ];
      final htmlRows = List.generate(works.length, (index) {
        final w = works[index];
        final dateStr = w.date.trim().isNotEmpty ? PdfTranslationHelper.parseAndFormatDateString(w.date, activeLang) : '';
        final locResolved = _resolveArea(textCache, w.location, activeLang);
        final areaResolved = _resolveArea(textCache, w.area, activeLang);
        final locationStr = areaResolved.isNotEmpty && locResolved.isNotEmpty && areaResolved != locResolved
            ? '$locResolved ($areaResolved)'
            : (locResolved.isNotEmpty ? locResolved : (areaResolved.isNotEmpty ? areaResolved : '-'));
        final amountStr = w.amount != null && w.amount! > 0
            ? PdfTranslationHelper.formatCurrency(NumberFormat.decimalPattern('en_IN').format(w.amount!.toInt()), activeLang)
            : '--';
        final titleResolved = PdfTranslationHelper.resolve(textCache, w.title, activeLang);
        final descResolved = w.description.trim().isNotEmpty ? PdfTranslationHelper.resolve(textCache, w.description, activeLang) : '';
        final subjectDesc = descResolved.isNotEmpty ? '$titleResolved\n$descResolved' : titleResolved;
        final localizedStatus = _resolveStatus(textCache, w.status, activeLang);
        final statusWithDate = dateStr.isNotEmpty && dateStr != '-' ? '$localizedStatus\n$dateStr' : localizedStatus;
        return [
          PdfTranslationHelper.formatNumber(index + 1, activeLang),
          subjectDesc,
          locationStr,
          statusWithDate,
          amountStr,
        ];
      });
      try {
        return await WebReportTheme.generateHtmlPdfBytes(
          title: effectiveTitle,
          subtitle: effectiveSubtitle,
          dateFormatted: formattedDate,
          totalCount: total,
          headers: htmlHeaders,
          rows: htmlRows,
          lang: activeLang,
        );
      } catch (_) {
        return pdf.save();
      }
    }

    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: effectiveTitle,
        subtitle: effectiveSubtitle,
        fileName: fileName,
        onBuildPdf: () async => (await buildPdfBytes()) as dynamic,
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => (await buildPdfBytes()) as dynamic,
        name: '$fileName.pdf',
      );
    }
  }
}
