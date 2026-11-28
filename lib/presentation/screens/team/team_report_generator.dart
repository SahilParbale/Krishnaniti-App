import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/team_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class TeamReportGenerator {
  TeamReportGenerator._();

  static String _pickNameSource(TeamMemberModel member, String lang) {
    if (lang == 'en') {
      return member.name.trim().isNotEmpty
          ? member.name.trim()
          : (member.nameMarathi?.trim() ?? '');
    }
    return (member.nameMarathi != null && member.nameMarathi!.trim().isNotEmpty)
        ? member.nameMarathi!.trim()
        : member.name.trim();
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

  static String _localizeRole(
    String role,
    String lang,
    Map<String, String> textCache,
  ) {
    final clean = role.trim();
    if (clean.isEmpty) return '';
    switch (clean.toLowerCase()) {
      case 'office admin':
        return AppTranslations.pick(
          lang,
          en: 'Office Admin',
          mr: 'कार्यालय प्रशासक',
          hi: 'कार्यालय प्रशासक',
        );
      case 'supervisor':
        return AppTranslations.pick(
          lang,
          en: 'Supervisor',
          mr: 'क्षेत्रीय पर्यवेक्षक',
          hi: 'क्षेत्रीय पर्यवेक्षक',
        );
      case 'staff':
      case 'executive':
        return AppTranslations.pick(
          lang,
          en: 'Office Executive',
          mr: 'कार्यालयीन सहाय्यक',
          hi: 'कार्यालय सहायक',
        );
      case 'driver':
        return AppTranslations.pick(
          lang,
          en: 'Authorized Driver',
          mr: 'अधिकृत चालक',
          hi: 'अधिकृत चालक',
        );
      case 'peon':
        return AppTranslations.pick(
          lang,
          en: 'Peon / Attendant',
          mr: 'शिपाई व सेवक',
          hi: 'चपरासी / सेवक',
        );
      case 'helper':
        return AppTranslations.pick(
          lang,
          en: 'Helper',
          mr: 'मदतनीस',
          hi: 'सहायक',
        );
      case 'sanitation worker':
        return AppTranslations.pick(
          lang,
          en: 'Sanitation Coordinator',
          mr: 'स्वच्छता समन्वयक',
          hi: 'स्वच्छता समन्वयक',
        );
      case 'karyakarta':
        return AppTranslations.pick(
          lang,
          en: 'Active Karyakarta',
          mr: 'सक्रिय कार्यकर्ता',
          hi: 'सक्रिय कार्यकर्ता',
        );
      case 'it cell head':
        return AppTranslations.pick(
          lang,
          en: 'IT & Social Media Head',
          mr: 'आयटी व सोशल मीडिया प्रमुख',
          hi: 'आईटी एवं सोशल मीडिया प्रमुख',
        );
      case 'pro':
        return AppTranslations.pick(
          lang,
          en: 'Public Relations Officer',
          mr: 'जनसंपर्क अधिकारी',
          hi: 'जनसंपर्क अधिकारी',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, clean, lang);
    }
  }

  static String _localizeCategory(
    String category,
    String lang,
    Map<String, String> textCache,
  ) {
    final clean = category.trim();
    switch (clean.toLowerCase()) {
      case 'all':
      case 'all team':
        return AppTranslations.pick(
          lang,
          en: 'All Team',
          mr: 'सर्व टीम',
          hi: 'पूरी टीम',
        );
      case 'office':
        return AppTranslations.pick(
          lang,
          en: 'Office Staff',
          mr: 'कार्यालयीन टीम',
          hi: 'कार्यालय टीम',
        );
      case 'party':
        return AppTranslations.pick(
          lang,
          en: 'Party Cadre',
          mr: 'पक्ष कार्यकर्ते',
          hi: 'पार्टी कार्यकर्ता',
        );
      case 'cooperative':
        return AppTranslations.pick(
          lang,
          en: 'Cooperative',
          mr: 'शासकीय व सहकार',
          hi: 'सहकारी / शासकीय',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, clean, lang);
    }
  }

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<TeamMemberModel> staffList,
    String activeCategory = 'All',
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDate(DateTime.now(), activeLang);

    final officeCount =
        staffList.where((s) => s.category.toLowerCase() == 'office').length;
    final partyCount =
        staffList.where((s) => s.category.toLowerCase() == 'party').length;
    final coopCount =
        staffList.where((s) => s.category.toLowerCase() == 'cooperative').length;

    final nameSources =
        staffList.map((m) => _pickNameSource(m, activeLang)).toList();
    final nameCache = await PdfTranslationHelper.batchNames(nameSources, activeLang);
    final textCache = await PdfTranslationHelper.batchText(
      [
        for (final m in staffList) ...[
          m.role,
          m.area,
          ...m.keywords,
        ],
        activeCategory,
      ],
      activeLang,
    );

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Staff & Team Directory',
      mr: 'कर्मचारी व टीम नोंदवही',
      hi: 'स्टाफ एवं टीम निर्देशिका',
    );
    final baseSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Prabhag Ward 12 Staff, Executives & Cadre Directory',
      mr: 'प्रभाग १२ कर्मचारी, पदाधिकारी आणि कार्यकर्ते नोंदवही',
      hi: 'वार्ड १२ स्टाफ, अधिकारी एवं कार्यकर्ता निर्देशिका',
    );
    final catNorm = activeCategory.trim().toLowerCase();
    final reportSubtitle = (catNorm.isNotEmpty &&
            catNorm != 'all' &&
            catNorm != 'all team')
        ? '$baseSubtitle • ${_localizeCategory(activeCategory, activeLang, textCache)}'
        : baseSubtitle;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
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
              totalCount: staffList.length,
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary strip
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
                      en: 'Total Team',
                      mr: 'एकूण टीम',
                      hi: 'कुल टीम',
                    ),
                    PdfTranslationHelper.formatNumber(staffList.length, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Office Staff',
                      mr: 'कार्यालयीन कर्मचारी',
                      hi: 'कार्यालय स्टाफ',
                    ),
                    PdfTranslationHelper.formatNumber(officeCount, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Party Cadre',
                      mr: 'पक्ष कार्यकर्ते',
                      hi: 'पार्टी कार्यकर्ता',
                    ),
                    PdfTranslationHelper.formatNumber(partyCount, activeLang),
                    highlightColor: PdfColors.indigo700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Cooperative',
                      mr: 'सहकार / शासकीय',
                      hi: 'सहकारी / शासकीय',
                    ),
                    PdfTranslationHelper.formatNumber(coopCount, activeLang),
                    highlightColor: PdfColors.teal700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (staffList.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No team members found for the selected view.',
                    mr: 'निवडलेल्या निकषांनुसार कोणतेही टीम सदस्य आढळले नाहीत.',
                    hi: 'चयनित दृश्य के लिए कोई टीम सदस्य नहीं मिला।',
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
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(3.0),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(3.0),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Name & Role',
                    mr: 'नाव आणि पद',
                    hi: 'नाम एवं पद',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Contact',
                    mr: 'संपर्क',
                    hi: 'संपर्क',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Area',
                    mr: 'परिसर',
                    hi: 'क्षेत्र',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Keywords / Scope',
                    mr: 'कीवर्ड्स / कार्यक्षेत्र',
                    hi: 'कीवर्ड / कार्यक्षेत्र',
                  ),
                ],
                data: staffList.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final member = entry.value;
                  final resolvedName = PdfTranslationHelper.resolveName(
                    nameCache,
                    nameSources[idx],
                    activeLang,
                  );
                  final resolvedRole = _localizeRole(
                    member.role,
                    activeLang,
                    textCache,
                  );
                  final roleStr = resolvedRole.isNotEmpty ? '\n$resolvedRole' : '';
                  final keywordsStr = member.keywords.isNotEmpty
                      ? member.keywords
                          .map((k) => PdfTranslationHelper.resolve(
                                textCache,
                                k,
                                activeLang,
                              ))
                          .join(', ')
                      : '-';

                  return [
                    PdfTranslationHelper.formatNumber(idx + 1, activeLang),
                    '$resolvedName$roleStr',
                    member.mobile.trim().isNotEmpty ? member.mobile.trim() : '-',
                    _resolveArea(member.area, activeLang, textCache),
                    keywordsStr,
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName =
        'Team_Staff_Directory_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    final bool useHarfBuzz = activeLang == 'mr' || activeLang == 'hi';

    Future<List<int>> buildPdfBytes() async {
      if (!useHarfBuzz) return pdf.save();
      final htmlHeaders = [
        AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
        AppTranslations.pick(activeLang, en: 'Name & Role', mr: 'नाव आणि पद', hi: 'नाम एवं पद'),
        AppTranslations.pick(activeLang, en: 'Contact', mr: 'संपर्क', hi: 'संपर्क'),
        AppTranslations.pick(activeLang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र'),
        AppTranslations.pick(activeLang, en: 'Keywords / Scope', mr: 'कीवर्ड्स / कार्यक्षेत्र', hi: 'कीवर्ड / कार्यक्षेत्र'),
      ];
      final htmlRows = staffList.asMap().entries.map((entry) {
        final idx = entry.key;
        final member = entry.value;
        final resolvedName = PdfTranslationHelper.resolveName(nameCache, nameSources[idx], activeLang);
        final resolvedRole = _localizeRole(member.role, activeLang, textCache);
        final roleStr = resolvedRole.isNotEmpty ? '\n$resolvedRole' : '';
        final keywordsStr = member.keywords.isNotEmpty
            ? member.keywords.map((k) => PdfTranslationHelper.resolve(textCache, k, activeLang)).join(', ')
            : '-';
        return [
          PdfTranslationHelper.formatNumber(idx + 1, activeLang),
          '$resolvedName$roleStr',
          member.mobile.trim().isNotEmpty ? member.mobile.trim() : '-',
          _resolveArea(member.area, activeLang, textCache),
          keywordsStr,
        ];
      }).toList();
      try {
        return await WebReportTheme.generateHtmlPdfBytes(
          title: reportTitle,
          subtitle: reportSubtitle,
          dateFormatted: PdfTranslationHelper.formatDateTime(DateTime.now(), activeLang),
          totalCount: staffList.length,
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
        title: reportTitle,
        subtitle: reportSubtitle,
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
