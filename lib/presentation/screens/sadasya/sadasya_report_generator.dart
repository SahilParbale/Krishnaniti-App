import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/sadasya_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class SadasyaReportGenerator {
  SadasyaReportGenerator._();

  static String _pickNameSource(SadasyaModel item, String lang) {
    if (lang == 'en') {
      if (item.nameEnglish != null && item.nameEnglish!.trim().isNotEmpty) {
        return item.nameEnglish!.trim();
      }
      if (item.name.trim().isNotEmpty) return item.name.trim();
      return item.nameMarathi?.trim() ?? '';
    }
    if (item.nameMarathi != null && item.nameMarathi!.trim().isNotEmpty) {
      return item.nameMarathi!.trim();
    }
    if (item.name.trim().isNotEmpty) return item.name.trim();
    return item.nameEnglish?.trim() ?? '';
  }

  static String _pickAddressSource(SadasyaModel item, String lang) {
    if (lang == 'en') {
      if (item.addressEnglish != null && item.addressEnglish!.trim().isNotEmpty) {
        return item.addressEnglish!.trim();
      }
      if (item.address.trim().isNotEmpty) return item.address.trim();
      return item.addressMarathi?.trim() ?? '';
    }
    if (item.addressMarathi != null && item.addressMarathi!.trim().isNotEmpty) {
      return item.addressMarathi!.trim();
    }
    if (item.address.trim().isNotEmpty) return item.address.trim();
    return item.addressEnglish?.trim() ?? '';
  }

  static String _resolveArea(
    String? area,
    String lang,
    Map<String, String> textCache,
  ) {
    if (area == null || area.trim().isEmpty) return '-';
    final clean = area.trim();
    final staticArea = AppTranslations.getAreaName(clean, lang);
    final hasDev = RegExp(r'[\u0900-\u097F]').hasMatch(staticArea);
    final hasLat = RegExp(r'[A-Za-z]').hasMatch(staticArea);
    if (lang == 'en' && !hasDev) return staticArea;
    if ((lang == 'mr' || lang == 'hi') && hasDev && !hasLat) return staticArea;
    return PdfTranslationHelper.resolve(textCache, clean, lang);
  }

  static String _localizeTypeFilter(String filter, String lang) {
    switch (filter.trim().toLowerCase()) {
      case 'voter':
      case 'voters':
        return AppTranslations.pick(
          lang,
          en: 'Voter Members',
          mr: 'मतदार सदस्य',
          hi: 'मतदाता सदस्य',
        );
      case 'non-voter':
      case 'non_voter':
      case 'non-voters':
        return AppTranslations.pick(
          lang,
          en: 'Party Cadre',
          mr: 'पक्ष कार्यकर्ते',
          hi: 'पार्टी कार्यकर्ता',
        );
      default:
        return filter;
    }
  }

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<SadasyaModel> members,
    String? areaFilter,
    String? typeFilter,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDate(DateTime.now(), activeLang);

    final totalCount = members.length;
    final voterCount = members.where((m) => m.isVoter).length;
    final nonVoterCount = totalCount - voterCount;

    final nameSources =
        members.map((item) => _pickNameSource(item, activeLang)).toList();
    final addressSources =
        members.map((item) => _pickAddressSource(item, activeLang)).toList();

    final nameCache = await PdfTranslationHelper.batchNames(nameSources, activeLang);
    final textCache = await PdfTranslationHelper.batchText(
      [
        for (int i = 0; i < members.length; i++) ...[
          addressSources[i],
          members[i].area,
          members[i].ward,
        ],
        if (areaFilter != null &&
            areaFilter.trim().isNotEmpty &&
            areaFilter.trim().toLowerCase() != 'all')
          areaFilter.trim(),
      ],
      activeLang,
    );

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Party Members Directory',
      mr: 'पक्ष सदस्य नोंदवही',
      hi: 'पार्टी सदस्य निर्देशिका',
    );
    final baseSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Registered party members, volunteers and booth level workers',
      mr: 'नोंदणीकृत पक्ष सदस्य, स्वयंसेवक आणि बूथ स्तर कार्यकर्ते',
      hi: 'पंजीकृत पार्टी सदस्य, स्वयंसेवक और बूथ स्तर के कार्यकर्ता',
    );

    final filterParts = <String>[];
    if (areaFilter != null &&
        areaFilter.trim().isNotEmpty &&
        areaFilter.trim().toLowerCase() != 'all') {
      filterParts.add(_resolveArea(areaFilter, activeLang, textCache));
    }
    if (typeFilter != null &&
        typeFilter.trim().isNotEmpty &&
        typeFilter.trim().toLowerCase() != 'all') {
      filterParts.add(_localizeTypeFilter(typeFilter, activeLang));
    }
    final reportSubtitle = filterParts.isNotEmpty
        ? '$baseSubtitle • ${filterParts.join(' | ')}'
        : baseSubtitle;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: reportTitle,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) =>
            WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: reportTitle,
              subtitle: reportSubtitle,
              dateFormatted: nowStr,
              totalCount: totalCount,
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary row
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
                      en: 'Total Members',
                      mr: 'एकूण सदस्य',
                      hi: 'कुल सदस्य',
                    ),
                    PdfTranslationHelper.formatNumber(totalCount, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Voter Members',
                      mr: 'मतदार सदस्य',
                      hi: 'मतदाता सदस्य',
                    ),
                    PdfTranslationHelper.formatNumber(voterCount, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Party Cadre',
                      mr: 'पक्ष कार्यकर्ते',
                      hi: 'पार्टी कार्यकर्ता',
                    ),
                    PdfTranslationHelper.formatNumber(nonVoterCount, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (members.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No party members found for the selected view.',
                    mr: 'निवडलेल्या निकषांनुसार कोणतेही पक्ष सदस्य आढळले नाहीत.',
                    hi: 'चयनित दृश्य के लिए कोई पार्टी सदस्य नहीं मिला।',
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
                headerCount: 1,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(26),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(1.6),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(2.4),
                  5: pw.FlexColumnWidth(1.4),
                  6: pw.FlexColumnWidth(1.2),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Member Name',
                    mr: 'सदस्याचे नाव',
                    hi: 'सदस्य का नाम',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Mobile No.',
                    mr: 'मोबाईल क्र.',
                    hi: 'मोबाइल नं.',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Area / Ward',
                    mr: 'परिसर / प्रभाग',
                    hi: 'क्षेत्र / वार्ड',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Address',
                    mr: 'पत्ता',
                    hi: 'पता',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Type',
                    mr: 'प्रकार',
                    hi: 'प्रकार',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Joined Date',
                    mr: 'नोंदणी दिनांक',
                    hi: 'शामिल होने की तिथि',
                  ),
                ],
                data: members.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final dateFormatted = PdfTranslationHelper.formatDate(
                    item.registeredAt,
                    activeLang,
                    pattern: 'MMM d, yyyy',
                  );
                  final rawArea = (item.area != null && item.area!.trim().isNotEmpty)
                      ? item.area
                      : item.ward;

                  return [
                    PdfTranslationHelper.formatNumber(idx + 1, activeLang),
                    PdfTranslationHelper.resolveName(
                      nameCache,
                      nameSources[idx],
                      activeLang,
                    ),
                    item.mobile.trim().isNotEmpty ? item.mobile.trim() : '-',
                    _resolveArea(rawArea, activeLang, textCache),
                    addressSources[idx].isNotEmpty
                        ? PdfTranslationHelper.resolve(
                            textCache,
                            addressSources[idx],
                            activeLang,
                          )
                        : '-',
                    item.isVoter
                        ? AppTranslations.pick(
                            activeLang,
                            en: 'Voter Member',
                            mr: 'मतदार सदस्य',
                            hi: 'मतदाता सदस्य',
                          )
                        : AppTranslations.pick(
                            activeLang,
                            en: 'Party Member',
                            mr: 'पक्ष सदस्य',
                            hi: 'पार्टी सदस्य',
                          ),
                    dateFormatted,
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName =
        'Party_Members_Report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
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
