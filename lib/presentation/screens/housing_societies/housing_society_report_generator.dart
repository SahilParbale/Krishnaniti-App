import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/housing_society_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class HousingSocietyReportGenerator {
  HousingSocietyReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<HousingSocietyModel> societies,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDate(now, activeLang);

    final totalSocieties = societies.length;
    final totalVoters = societies.fold<int>(0, (sum, s) => sum + s.voterCount);
    final totalFavourable = societies.fold<int>(0, (sum, s) => sum + s.favourableVoterCount);
    final supportPercentage = totalVoters > 0 ? ((totalFavourable / totalVoters) * 100).round() : 0;

    final textItems = <String?>[];
    final nameItems = <String?>[];
    for (final s in societies) {
      textItems.add(_pickSocietyName(s, activeLang));
      textItems.add(s.area);
      textItems.add(s.address);
      textItems.add(s.status);
      nameItems.add(s.chairmanName);
      nameItems.add(s.secretaryName);
    }

    final caches = await Future.wait([
      PdfTranslationHelper.batchText(textItems, activeLang),
      PdfTranslationHelper.batchNames(nameItems, activeLang),
    ]);
    final textCache = caches[0];
    final nameCache = caches[1];

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Housing Societies Registry',
      mr: 'सहकारी गृहनिर्माण संस्था नोंदवही',
      hi: 'हाउसिंग सोसायटी रजिस्ट्री',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'List of Co-operative Housing Societies & Executive Contacts',
      mr: 'सहकारी गृहनिर्माण संस्था व कार्यकारिणी संपर्क यादी',
      hi: 'सहकारी आवास समितियों और कार्यकारिणी संपर्क सूची',
    );
    final areaPrefix = AppTranslations.pick(
      activeLang,
      en: 'Area:',
      mr: 'परिसर:',
      hi: 'क्षेत्र:',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: reportTitle,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(
          context,
          lang: activeLang,
        ),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: reportTitle,
              subtitle: reportSubtitle,
              dateFormatted: formattedDate,
              totalCount: totalSocieties,
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary row matching web layout
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
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Societies',
                      mr: 'एकूण संस्था',
                      hi: 'कुल सोसायटियां',
                    ),
                    PdfTranslationHelper.formatNumber(totalSocieties, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Voters',
                      mr: 'एकूण मतदार',
                      hi: 'कुल मतदाता',
                    ),
                    PdfTranslationHelper.formatNumber(totalVoters, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Favourable',
                      mr: 'अनुकूल मतदार',
                      hi: 'अनुकूल मतदाता',
                    ),
                    PdfTranslationHelper.formatNumber(totalFavourable, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Support Rating',
                      mr: 'समर्थन टक्केवारी',
                      hi: 'समर्थन प्रतिशत',
                    ),
                    '${PdfTranslationHelper.formatNumber(supportPercentage, activeLang)}%',
                    highlightColor: WebReportTheme.brand600,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (societies.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No housing societies found.',
                    mr: 'कोणत्याही गृहनिर्माण संस्था आढळल्या नाहीत.',
                    hi: 'कोई हाउसिंग सोसायटी नहीं मिली।',
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
                  1: pw.FlexColumnWidth(2.8),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(2.2),
                  4: pw.FlexColumnWidth(1.6),
                  5: pw.FlexColumnWidth(1.2),
                  6: pw.FlexColumnWidth(1.2),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Society & Area',
                    mr: 'सोसायटी व परिसर',
                    hi: 'सोसायटी और क्षेत्र',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Chairman',
                    mr: 'चेअरमन',
                    hi: 'चेयरमैन',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Secretary',
                    mr: 'सेक्रेटरी',
                    hi: 'सचिव',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Voters (Tot/Fav)',
                    mr: 'मतदार (एकूण/अनुकूल)',
                    hi: 'मतदाता (कुल/अनुकूल)',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Support',
                    mr: 'समर्थन',
                    hi: 'समर्थन',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Status',
                    mr: 'स्थिती',
                    hi: 'स्थिति',
                  ),
                ],
                data: List.generate(societies.length, (index) {
                  final s = societies[index];
                  final societyName = PdfTranslationHelper.resolve(
                    textCache,
                    _pickSocietyName(s, activeLang),
                    activeLang,
                  );
                  final areaStr = s.area.trim().isNotEmpty
                      ? '\n$areaPrefix ${_resolveArea(s.area, activeLang, textCache)}'
                      : '';
                  final addressStr = (s.address.trim().isNotEmpty &&
                          s.address.trim().toLowerCase() != s.area.trim().toLowerCase())
                      ? '\n${PdfTranslationHelper.resolve(textCache, s.address, activeLang)}'
                      : '';

                  final chairmanResolved = PdfTranslationHelper.resolveName(
                    nameCache,
                    s.chairmanName,
                    activeLang,
                  );
                  final chairmanMob = PdfTranslationHelper.formatNumber(
                    s.chairmanMobile.trim(),
                    activeLang,
                  );
                  final chairmanStr = s.chairmanName.trim().isNotEmpty
                      ? (chairmanMob.isNotEmpty ? '$chairmanResolved\n($chairmanMob)' : chairmanResolved)
                      : '-';

                  final secResolved = PdfTranslationHelper.resolveName(
                    nameCache,
                    s.secretaryName,
                    activeLang,
                  );
                  final secMob = PdfTranslationHelper.formatNumber(
                    s.secretaryMobile.trim(),
                    activeLang,
                  );
                  final secStr = s.secretaryName.trim().isNotEmpty
                      ? (secMob.isNotEmpty ? '$secResolved\n($secMob)' : secResolved)
                      : '-';

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$societyName$areaStr$addressStr',
                    chairmanStr,
                    secStr,
                    '${PdfTranslationHelper.formatNumber(s.voterCount, activeLang)} / ${PdfTranslationHelper.formatNumber(s.favourableVoterCount, activeLang)}',
                    '${PdfTranslationHelper.formatNumber(s.supportPercentage, activeLang)}%',
                    _resolveStatus(s.status, activeLang, textCache),
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Housing_Societies_Report_${DateFormat('yyyyMMdd').format(now)}';
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

  static String _pickSocietyName(HousingSocietyModel s, String lang) {
    if (lang == 'mr') {
      if (s.nameMarathi != null && s.nameMarathi!.trim().isNotEmpty) {
        return s.nameMarathi!.trim();
      }
      return s.name.trim();
    }
    if (lang == 'en') {
      if (s.nameEnglish != null && s.nameEnglish!.trim().isNotEmpty) {
        return s.nameEnglish!.trim();
      }
      return s.name.trim();
    }
    if (s.nameEnglish != null && s.nameEnglish!.trim().isNotEmpty) {
      return s.nameEnglish!.trim();
    }
    if (s.name.trim().isNotEmpty) return s.name.trim();
    return s.displayName(true);
  }

  static String _resolveArea(String area, String lang, Map<String, String> textCache) {
    final trimmed = area.trim();
    if (trimmed.isEmpty) return '-';
    final mapped = AppTranslations.getAreaName(trimmed, lang);
    if (AppTranslations.normalizeAsciiDigits(mapped) ==
        AppTranslations.normalizeAsciiDigits(trimmed)) {
      return PdfTranslationHelper.resolve(textCache, trimmed, lang);
    }
    return mapped;
  }

  static String _resolveStatus(String status, String lang, Map<String, String> textCache) {
    final trimmed = status.trim();
    if (trimmed.isEmpty) return '-';
    final lower = trimmed.toLowerCase();
    if (lower == 'active') {
      return AppTranslations.pick(lang, en: 'Active', mr: 'सक्रिय', hi: 'सक्रिय');
    }
    if (lower == 'inactive') {
      return AppTranslations.pick(lang, en: 'Inactive', mr: 'निष्क्रिय', hi: 'निष्क्रिय');
    }
    final translated = AppTranslations.getStatus(trimmed, lang);
    if (AppTranslations.normalizeAsciiDigits(translated) ==
        AppTranslations.normalizeAsciiDigits(trimmed)) {
      return PdfTranslationHelper.resolve(textCache, trimmed, lang);
    }
    return AppTranslations.formatDigits(translated, lang);
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
