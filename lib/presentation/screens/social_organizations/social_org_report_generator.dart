import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/social_organization_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class SocialOrgReportGenerator {
  SocialOrgReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<SocialOrganizationModel> organizations,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDate(now, activeLang);

    final total = organizations.length;
    final ngos = organizations.where((o) => o.type == 'ngo').length;
    final sports = organizations.where((o) => o.type == 'sports_cricket').length;
    final mandals = organizations.where((o) => o.type == 'ganpati_mandal' || o.type == 'navratri_mandal').length;

    final textItems = <String?>[];
    final nameItems = <String?>[];
    for (final o in organizations) {
      textItems.add(_pickOrgName(o, activeLang));
      textItems.add(o.type);
      textItems.add(o.area);
      textItems.add(o.status);
      nameItems.add(o.presidentName);
    }

    final caches = await Future.wait([
      PdfTranslationHelper.batchText(textItems, activeLang),
      PdfTranslationHelper.batchNames(nameItems, activeLang),
    ]);
    final textCache = caches[0];
    final nameCache = caches[1];

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'NGO & Mandal Registry',
      mr: 'NGO व मंडळ नोंदवही',
      hi: 'एनजीओ एवं मंडल रजिस्ट्री',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'List of NGOs, Clubs and Mandals in the ward',
      mr: 'प्रभागातील सामाजिक संस्था, क्रीडा क्लब व मंडळांची यादी',
      hi: 'वार्ड के एनजीओ, क्लब और मंडलों की सूची',
    );
    final typePrefix = AppTranslations.pick(
      activeLang,
      en: 'Type:',
      mr: 'प्रकार:',
      hi: 'प्रकार:',
    );
    final estPrefix = AppTranslations.pick(
      activeLang,
      en: 'Est:',
      mr: 'स्थापना:',
      hi: 'स्थापना:',
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
              totalCount: total,
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
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total NGOs',
                      mr: 'एकूण NGO',
                      hi: 'कुल एनजीओ',
                    ),
                    PdfTranslationHelper.formatNumber(ngos, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Sports Clubs',
                      mr: 'क्रीडा क्लब',
                      hi: 'स्पोर्ट्स क्लब',
                    ),
                    PdfTranslationHelper.formatNumber(sports, activeLang),
                    highlightColor: PdfColors.teal700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Mandals',
                      mr: 'मंडळे',
                      hi: 'मंडल',
                    ),
                    PdfTranslationHelper.formatNumber(mandals, activeLang),
                    highlightColor: PdfColors.amber800,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Registered',
                      mr: 'एकूण नोंदणी',
                      hi: 'कुल पंजीकृत',
                    ),
                    PdfTranslationHelper.formatNumber(total, activeLang),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (organizations.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No social organizations or mandals found.',
                    mr: 'कोणत्याही सामाजिक संस्था किंवा मंडळे आढळली नाहीत.',
                    hi: 'कोई सामाजिक संगठन या मंडल नहीं मिला।',
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
                  1: pw.FlexColumnWidth(3.0),
                  2: pw.FlexColumnWidth(2.4),
                  3: pw.FlexColumnWidth(1.8),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.2),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Organization Name & Type',
                    mr: 'संस्थेचे नाव व प्रकार',
                    hi: 'संगठन का नाम और प्रकार',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'President & Mobile',
                    mr: 'अध्यक्ष व मोबाईल',
                    hi: 'अध्यक्ष और मोबाइल',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Area',
                    mr: 'परिसर',
                    hi: 'क्षेत्र',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Members & Est.',
                    mr: 'सदस्य व स्थापना',
                    hi: 'सदस्य और स्थापना',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Status',
                    mr: 'स्थिती',
                    hi: 'स्थिति',
                  ),
                ],
                data: List.generate(organizations.length, (index) {
                  final o = organizations[index];
                  final orgName = PdfTranslationHelper.resolve(
                    textCache,
                    _pickOrgName(o, activeLang),
                    activeLang,
                  );
                  final typeStr = '\n$typePrefix ${_resolveOrgType(o.type, activeLang, textCache)}';

                  final presResolved = PdfTranslationHelper.resolveName(
                    nameCache,
                    o.presidentName,
                    activeLang,
                  );
                  final presMobile = PdfTranslationHelper.formatNumber(
                    o.presidentMobile.trim(),
                    activeLang,
                  );
                  final presStr = o.presidentName.trim().isNotEmpty
                      ? (presMobile.isNotEmpty ? '$presResolved\n$presMobile' : presResolved)
                      : '-';

                  final memCount = PdfTranslationHelper.formatNumber(o.membersCount, activeLang);
                  final memStr = o.membersCount > 0
                      ? AppTranslations.pick(
                          activeLang,
                          en: '$memCount members',
                          mr: '$memCount सदस्य',
                          hi: '$memCount सदस्य',
                        )
                      : '-';
                  final estStr = o.establishedYear.trim().isNotEmpty
                      ? '\n$estPrefix ${PdfTranslationHelper.formatNumber(o.establishedYear.trim(), activeLang)}'
                      : '';

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$orgName$typeStr',
                    presStr,
                    _resolveArea(o.area, activeLang, textCache),
                    '$memStr$estStr',
                    _resolveStatus(o.status, activeLang, textCache),
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Mandal_NGO_Report_${DateFormat('yyyyMMdd').format(now)}';
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

  static String _pickOrgName(SocialOrganizationModel o, String lang) {
    if (lang == 'mr') {
      if (o.nameMarathi != null && o.nameMarathi!.trim().isNotEmpty) {
        return o.nameMarathi!.trim();
      }
      return o.name.trim();
    }
    if (lang == 'en') {
      if (o.nameEnglish != null && o.nameEnglish!.trim().isNotEmpty) {
        return o.nameEnglish!.trim();
      }
      return o.name.trim();
    }
    if (o.nameEnglish != null && o.nameEnglish!.trim().isNotEmpty) {
      return o.nameEnglish!.trim();
    }
    if (o.name.trim().isNotEmpty) return o.name.trim();
    return o.displayName;
  }

  static String _resolveOrgType(
    String type,
    String lang,
    Map<String, String> textCache,
  ) {
    switch (type.trim().toLowerCase()) {
      case 'ngo':
        return AppTranslations.pick(
          lang,
          en: 'NGO / Foundation',
          mr: 'एन.जी.ओ / सामाजिक संस्था',
          hi: 'एनजीओ / सामाजिक संस्था',
        );
      case 'sports_cricket':
        return AppTranslations.pick(
          lang,
          en: 'Cricket & Sports Club',
          mr: 'क्रीडा व क्रिकेट क्लब',
          hi: 'क्रिकेट एवं स्पोर्ट्स क्लब',
        );
      case 'ganpati_mandal':
        return AppTranslations.pick(
          lang,
          en: 'Ganpati Mandal',
          mr: 'गणपती मंडळ',
          hi: 'गणपति मंडल',
        );
      case 'navratri_mandal':
        return AppTranslations.pick(
          lang,
          en: 'Navratri Mandal',
          mr: 'नवरात्रौत्सव मंडळ',
          hi: 'नवरात्रोत्सव मंडल',
        );
      case 'other':
        return AppTranslations.pick(
          lang,
          en: 'Other Organization',
          mr: 'इतर संस्था व मंडळ',
          hi: 'अन्य संगठन एवं मंडल',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, type, lang);
    }
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
