import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/opposition_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class OppositionReportGenerator {
  OppositionReportGenerator._();

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

  static String _localizeParty(
    String party,
    String lang,
    Map<String, String> textCache,
  ) {
    final clean = party.trim();
    if (clean.isEmpty) return '';
    switch (clean.toUpperCase()) {
      case 'INC':
        return AppTranslations.pick(
          lang,
          en: 'Congress (INC)',
          mr: 'काँग्रेस (INC)',
          hi: 'कांग्रेस (INC)',
        );
      case 'NCP':
        return AppTranslations.pick(
          lang,
          en: 'NCP',
          mr: 'राष्ट्रवादी (NCP)',
          hi: 'एनसीपी (NCP)',
        );
      case 'UBT':
        return AppTranslations.pick(
          lang,
          en: 'Shiv Sena (UBT)',
          mr: 'शिवसेना (UBT)',
          hi: 'शिवसेना (UBT)',
        );
      case 'SHIVSENA':
      case 'SHIV SENA':
        return AppTranslations.pick(
          lang,
          en: 'Shiv Sena',
          mr: 'शिवसेना',
          hi: 'शिवसेना',
        );
      case 'MNS':
        return AppTranslations.pick(
          lang,
          en: 'MNS',
          mr: 'मनसे (MNS)',
          hi: 'मनसे (MNS)',
        );
      case 'BJP':
        return AppTranslations.pick(
          lang,
          en: 'BJP',
          mr: 'भाजप (BJP)',
          hi: 'भाजपा (BJP)',
        );
      case 'AAP':
        return AppTranslations.pick(
          lang,
          en: 'AAP',
          mr: 'आप (AAP)',
          hi: 'आप (AAP)',
        );
      case 'INDEPENDENT':
        return AppTranslations.pick(
          lang,
          en: 'Independent',
          mr: 'अपक्ष',
          hi: 'निर्दलीय',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, clean, lang);
    }
  }

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<OppositionMemberModel> members,
    required String Function(String) getCandidateName,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDate(now, activeLang);

    final totalMembers = members.length;
    final totalCandidates = members.where((m) => m.isCandidate).length;
    final totalWorkers = members.where((m) => !m.isCandidate).length;

    final linkedCandidates = <String, String>{};
    for (final m in members) {
      if (!m.isCandidate && m.candidateId != null && m.candidateId!.isNotEmpty) {
        final cand = getCandidateName(m.candidateId!);
        if (cand.trim().isNotEmpty && cand.trim() != m.candidateId!.trim()) {
          linkedCandidates[m.id] = cand.trim();
        }
      }
    }

    final nameCache = await PdfTranslationHelper.batchNames(
      [
        ...members.map((m) => m.name),
        ...members.map((m) => m.opposingCandidate),
        ...linkedCandidates.values,
      ],
      activeLang,
    );
    final textCache = await PdfTranslationHelper.batchText(
      [
        for (final m in members) ...[
          m.party,
          m.role,
          m.area,
          ...m.strongholds,
          m.constituency,
          m.notes,
        ],
      ],
      activeLang,
    );

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Opposition Information',
      mr: 'विरोधी पक्षाची माहिती',
      hi: 'विपक्ष की जानकारी',
    );
    final continuationTitle = AppTranslations.pick(
      activeLang,
      en: 'Opposition Intelligence',
      mr: 'विरोधी पक्ष विश्लेषण',
      hi: 'विपक्ष विश्लेषण',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Track and monitor opposition workers, strongholds, and key public campaigns',
      mr: 'विरोधी कार्यकर्ते, बालेकिल्ले आणि प्रमुख सार्वजनिक मोहिमांचा मागोवा व निरीक्षण',
      hi: 'विपक्षी कार्यकर्ताओं, गढ़ों और प्रमुख जन अभियानों की निगरानी एवं विश्लेषण',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: continuationTitle,
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
              dateFormatted: formattedDate,
              totalCount: totalMembers,
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
                      en: 'Total Members',
                      mr: 'एकूण सदस्य',
                      hi: 'कुल सदस्य',
                    ),
                    PdfTranslationHelper.formatNumber(totalMembers, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Candidates',
                      mr: 'उमेदवार',
                      hi: 'उम्मीदवार',
                    ),
                    PdfTranslationHelper.formatNumber(totalCandidates, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Workers',
                      mr: 'कार्यकर्ते',
                      hi: 'कार्यकर्ता',
                    ),
                    PdfTranslationHelper.formatNumber(totalWorkers, activeLang),
                    highlightColor: WebReportTheme.slate700,
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
                    en: 'No opposition members found.',
                    mr: 'कोणतेही विरोधी पक्ष सदस्य आढळले नाहीत.',
                    hi: 'कोई विपक्षी सदस्य नहीं मिला।',
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
                  1: pw.FlexColumnWidth(2.8),
                  2: pw.FlexColumnWidth(1.6),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(1.8),
                  5: pw.FlexColumnWidth(2.6),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Name & Party',
                    mr: 'नाव व पक्ष',
                    hi: 'नाम एवं पार्टी',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Role / Designation',
                    mr: 'पद / जबाबदारी',
                    hi: 'पद / भूमिका',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Type',
                    mr: 'प्रकार',
                    hi: 'प्रकार',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Mobile',
                    mr: 'मोबाईल',
                    hi: 'मोबाइल',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Area & Strongholds',
                    mr: 'परिसर व बालेकिल्ले',
                    hi: 'क्षेत्र एवं गढ़',
                  ),
                ],
                data: List.generate(members.length, (index) {
                  final m = members[index];
                  final resolvedName = PdfTranslationHelper.resolveName(
                    nameCache,
                    m.name,
                    activeLang,
                  );
                  final partyLabel = AppTranslations.pick(
                    activeLang,
                    en: 'Party',
                    mr: 'पक्ष',
                    hi: 'पार्टी',
                  );
                  final resolvedParty = _localizeParty(m.party, activeLang, textCache);
                  final partyStr =
                      resolvedParty.isNotEmpty ? '\n$partyLabel: $resolvedParty' : '';

                  final strongholdsLabel = AppTranslations.pick(
                    activeLang,
                    en: 'Strongholds',
                    mr: 'बालेकिल्ले',
                    hi: 'प्रभाव क्षेत्र',
                  );
                  final strongholdsStr = m.strongholds.isNotEmpty
                      ? '\n$strongholdsLabel: ${m.strongholds.take(2).map((s) => PdfTranslationHelper.resolve(textCache, s, activeLang)).join(', ')}'
                      : '';
                  final areaStr = _resolveArea(m.area, activeLang, textCache);

                  final baseType = m.isCandidate
                      ? AppTranslations.pick(
                          activeLang,
                          en: 'Candidate',
                          mr: 'उमेदवार',
                          hi: 'उम्मीदवार',
                        )
                      : AppTranslations.pick(
                          activeLang,
                          en: 'Worker',
                          mr: 'कार्यकर्ता',
                          hi: 'कार्यकर्ता',
                        );
                  final linkedCand = linkedCandidates[m.id];
                  final typeStr = linkedCand != null
                      ? '$baseType\n(${PdfTranslationHelper.resolveName(nameCache, linkedCand, activeLang)})'
                      : baseType;

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$resolvedName$partyStr',
                    (m.role != null && m.role!.trim().isNotEmpty)
                        ? PdfTranslationHelper.resolve(
                            textCache,
                            m.role,
                            activeLang,
                          )
                        : '-',
                    typeStr,
                    (m.mobile != null && m.mobile!.trim().isNotEmpty)
                        ? m.mobile!.trim()
                        : '-',
                    '$areaStr$strongholdsStr',
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Opposition_Report_${DateFormat('yyyyMMdd').format(now)}';
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
