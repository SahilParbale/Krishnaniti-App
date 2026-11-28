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

/// Official Political Work Report (Ahwal) Generator matching Nagarsevak-Managment
/// (AhwalReportGenerator.tsx).
class AhwalReportGenerator {
  AhwalReportGenerator._();

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

  static Future<void> generateAndPrintAhwal({
    BuildContext? context,
    required List<WorkHistoryModel> selectedWorks,
    String? nagarsevakName,
    String? wardName,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDate(now, activeLang, pattern: 'dd MMMM yyyy');
    final totalCount = selectedWorks.length;
    final totalAmount = selectedWorks.fold<double>(0, (sum, w) => sum + (w.amount ?? 0));

    final effectiveOfficeInput = (nagarsevakName != null && nagarsevakName.trim().isNotEmpty && nagarsevakName != 'Nagarsevak Office')
        ? nagarsevakName
        : null;
    final effectiveWardInput = (wardName != null && wardName.trim().isNotEmpty && wardName != 'Ward No. 12 (Prabhag 12)')
        ? wardName
        : null;

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        effectiveWardInput,
        for (final w in selectedWorks) ...[
          w.title,
          w.description,
          w.location,
          w.area,
          w.status,
        ],
      ], activeLang),
      PdfTranslationHelper.batchNames([
        effectiveOfficeInput,
      ], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final resolvedOffice = effectiveOfficeInput != null
        ? PdfTranslationHelper.resolveName(nameCache, effectiveOfficeInput, activeLang)
        : AppTranslations.pick(
            activeLang,
            en: 'Nagarsevak Office',
            mr: 'नगरसेवक कार्यालय',
            hi: 'नगरसेवक कार्यालय',
          );
    final resolvedWard = effectiveWardInput != null
        ? _resolveArea(textCache, effectiveWardInput, activeLang)
        : AppTranslations.pick(
            activeLang,
            en: 'Ward No. 12 (Prabhag 12)',
            mr: 'प्रभाग क्र. १२',
            hi: 'वार्ड नं. १२ (प्रभाग १२)',
          );

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Political Work Report (Ahwal)',
      mr: 'विकास कामे अहवाल (अहवाल)',
      hi: 'विकास कार्य रिपोर्ट (अहवाल)',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Development Works & Achievements Summary',
      mr: 'विकासाची कामे आणि कामगिरीचा सारांश',
      hi: 'विकास कार्य और उपलब्धियों का सारांश',
    );
    final datePrefix = AppTranslations.pick(activeLang, en: 'Date', mr: 'तारीख', hi: 'दिनांक');
    final totalWorksLabel = AppTranslations.pick(activeLang, en: 'Total Works', mr: 'एकूण कामे', hi: 'कुल कार्य');
    final totalSpentLabel = AppTranslations.pick(
      activeLang,
      en: 'TOTAL ESTIMATED AMOUNT',
      mr: 'एकूण अंदाजित रक्कम',
      hi: 'कुल अनुमानित राशि',
    );
    final locationLabel = AppTranslations.pick(activeLang, en: 'Location', mr: 'स्थान', hi: 'स्थान');
    final statusLabel = AppTranslations.pick(activeLang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति');
    final sealSigLabel = AppTranslations.pick(
      activeLang,
      en: 'Office Seal & Signature',
      mr: 'कार्यालय शिक्का आणि स्वाक्षरी',
      hi: 'कार्यालय मुहर एवं हस्ताक्षर',
    );
    final emptyMsg = AppTranslations.pick(
      activeLang,
      en: 'No development works selected for Ahwal report.',
      mr: 'अहवाल रिपोर्टसाठी कोणतीही विकास कामे निवडलेली नाहीत.',
      hi: 'अहवाल रिपोर्ट के लिए कोई विकास कार्य चयनित नहीं है।',
    );

    final totalCountStr = PdfTranslationHelper.formatNumber(totalCount, activeLang);
    final totalAmountStr = PdfTranslationHelper.formatCurrency(
      NumberFormat.decimalPattern('en_IN').format(totalAmount.toInt()),
      activeLang,
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
            metaLines: [
              '$datePrefix: $nowStr',
              '$totalWorksLabel: $totalCountStr',
            ],
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            // Report Summary Box (matching web AhwalReportGenerator.tsx)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              margin: const pw.EdgeInsets.only(bottom: 16),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.brand50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        activeLang == 'en' ? totalWorksLabel.toUpperCase() : totalWorksLabel,
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        totalCountStr,
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand900),
                      ),
                    ],
                  ),
                  if (totalAmount > 0)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          totalSpentLabel,
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          totalAmountStr,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF15803D)),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            if (selectedWorks.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  emptyMsg,
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              // Works List Cards (matching web AhwalReportGenerator.tsx)
              ...selectedWorks.asMap().entries.map((entry) {
                final idxStr = PdfTranslationHelper.formatNumber(entry.key + 1, activeLang);
                final work = entry.value;
                final workTitle = PdfTranslationHelper.resolve(textCache, work.title, activeLang);
                final workDate = work.date.trim().isNotEmpty
                    ? PdfTranslationHelper.parseAndFormatDateString(work.date, activeLang)
                    : '-';
                final locResolved = _resolveArea(textCache, work.location, activeLang);
                final areaResolved = _resolveArea(textCache, work.area, activeLang);
                final locLine = areaResolved.isNotEmpty && locResolved.isNotEmpty && areaResolved != locResolved
                    ? '$locResolved ($areaResolved)'
                    : (locResolved.isNotEmpty ? locResolved : (areaResolved.isNotEmpty ? areaResolved : '-'));
                final descResolved = work.description.trim().isNotEmpty
                    ? PdfTranslationHelper.resolve(textCache, work.description, activeLang)
                    : '';
                final statusResolved = _resolveStatus(textCache, work.status, activeLang);
                final amountStr = work.amount != null && work.amount! > 0
                    ? PdfTranslationHelper.formatCurrency(
                        NumberFormat.decimalPattern('en_IN').format(work.amount!.toInt()),
                        activeLang,
                      )
                    : null;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '$idxStr. $workTitle',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: WebReportTheme.slate900,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: WebReportTheme.slate50,
                              borderRadius: pw.BorderRadius.circular(12),
                              border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
                            ),
                            child: pw.Text(
                              workDate,
                              style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate600),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '$locationLabel: $locLine',
                        style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate700),
                      ),
                      if (descResolved.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          descResolved,
                          style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate800, lineSpacing: 1.5),
                        ),
                      ],
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '$statusLabel: $statusResolved',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                          ),
                          if (amountStr != null)
                            pw.Text(
                              amountStr,
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF15803D)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            // Signature Block
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 180,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 40,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: WebReportTheme.slate400, width: 0.8),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        sealSigLabel,
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700),
                      ),
                      pw.Text(
                        '$resolvedOffice • $resolvedWard',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final fileName = 'Ahwal_Report_${DateFormat('yyyyMMdd').format(now)}';
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
}
