import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/election_result_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class ResultAnalysisReportGenerator {
  ResultAnalysisReportGenerator._();

  static String _resolveWardDisplay(
    String ward,
    String lang,
    Map<String, String> textCache,
  ) {
    final clean = ward.trim();
    if (clean.isEmpty) return '-';
    final staticArea = AppTranslations.getAreaName(clean, lang);
    final hasDev = RegExp(r'[\u0900-\u097F]').hasMatch(staticArea);
    final hasLat = RegExp(r'[A-Za-z]').hasMatch(staticArea);
    if (lang == 'en' && !hasDev) return staticArea;
    if ((lang == 'mr' || lang == 'hi') && hasDev && !hasLat) return staticArea;
    return PdfTranslationHelper.resolve(textCache, clean, lang);
  }

  static String _formatWardBadge(String resolvedWard, String lang) {
    final lower = resolvedWard.toLowerCase();
    if (lower.startsWith('ward') ||
        resolvedWard.startsWith('प्रभाग') ||
        resolvedWard.startsWith('वार्ड')) {
      return resolvedWard;
    }
    final prefix = AppTranslations.pick(lang, en: 'Ward', mr: 'प्रभाग', hi: 'वार्ड');
    return '$prefix $resolvedWard';
  }

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required String ward,
    required String selectedCandidate,
    required List<ElectionResultModel> results,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDate(DateTime.now(), activeLang);

    // Calculate aggregated statistics
    final totalVotesRow = results.where((r) => r.boothNumber == 'एकूण मत').firstOrNull;
    final totalVotes = totalVotesRow != null
        ? totalVotesRow.totalVotesCasted
        : results.fold<int>(0, (sum, r) => sum + r.totalVotesCasted);

    final ourVotes = totalVotesRow != null
        ? totalVotesRow.votesFor(selectedCandidate)
        : results.fold<int>(0, (sum, r) => sum + r.votesFor(selectedCandidate));

    final voteShare = totalVotes > 0 ? (ourVotes / totalVotes) * 100 : 0.0;
    final winningBooths = results.where((r) => r.isWinner(selectedCandidate)).length;
    final losingBooths = results.length - winningBooths;

    // Filter out summary/postal rows for booth table
    final boothList = results
        .where((r) =>
            r.boothNumber != 'एकूण मत' &&
            r.boothNumber != 'टपाल मतदान' &&
            r.boothNumber != 'सर्व मतदान केंद्र नोंदवण्यात आलेली मते')
        .toList();

    // Sort booths numerically
    boothList.sort((a, b) {
      final aMatch = RegExp(r'\d+').firstMatch(a.boothNumber);
      final bMatch = RegExp(r'\d+').firstMatch(b.boothNumber);
      if (aMatch != null && bMatch != null) {
        return int.parse(aMatch.group(0)!).compareTo(int.parse(bMatch.group(0)!));
      }
      return a.boothNumber.compareTo(b.boothNumber);
    });

    final nameCache = await PdfTranslationHelper.batchNames(
      [
        selectedCandidate,
        ...boothList.map((r) => r.winner),
      ],
      activeLang,
    );
    final textCache = await PdfTranslationHelper.batchText(
      [
        ward,
        ...boothList.map((r) => r.boothNumber),
        ...boothList.map((r) => r.boothName),
      ],
      activeLang,
    );

    final resolvedCandidate = PdfTranslationHelper.resolveName(
      nameCache,
      selectedCandidate,
      activeLang,
    );
    final resolvedWard = _resolveWardDisplay(ward, activeLang, textCache);
    final wardBadge = _formatWardBadge(resolvedWard, activeLang);

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Election Results & Booth Analysis',
      mr: 'निवडणूक निकाल व बूथ विश्लेषण',
      hi: 'चुनाव परिणाम एवं बूथ विश्लेषण',
    );
    final continuationTitle = AppTranslations.pick(
      activeLang,
      en: 'Election Results Analysis',
      mr: 'निवडणूक निकाल विश्लेषण',
      hi: 'चुनाव परिणाम विश्लेषण',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Performance report for $resolvedCandidate',
      mr: '$resolvedCandidate यांचा कामगिरी अहवाल',
      hi: '$resolvedCandidate की प्रदर्शन रिपोर्ट',
    );
    final modalTitle = continuationTitle;
    final modalSubtitle = AppTranslations.pick(
      activeLang,
      en: '$wardBadge • Candidate Performance & Booth Analysis',
      mr: '$wardBadge • उमेदवार कामगिरी आणि बूथ विश्लेषण',
      hi: '$wardBadge • उम्मीदवार प्रदर्शन एवं बूथ विश्लेषण',
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
              metaLines: [
                '${AppTranslations.pick(activeLang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक')}: $nowStr',
                '${AppTranslations.pick(activeLang, en: 'Ward', mr: 'प्रभाग', hi: 'वार्ड')}: $resolvedWard',
                '${AppTranslations.pick(activeLang, en: 'Total Booths', mr: 'एकूण बूथ', hi: 'कुल बूथ')}: ${PdfTranslationHelper.formatNumber(boothList.length, activeLang)}',
              ],
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary metrics matching web style
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
                      en: 'Total Votes',
                      mr: 'एकूण मते',
                      hi: 'कुल मत',
                    ),
                    '${PdfTranslationHelper.formatNumber(ourVotes, activeLang)} / ${PdfTranslationHelper.formatNumber(totalVotes, activeLang)}',
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Vote Share',
                      mr: 'मत टक्केवारी',
                      hi: 'मत प्रतिशत',
                    ),
                    '${PdfTranslationHelper.formatNumber(voteShare.toStringAsFixed(1), activeLang)}%',
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Winning Booths',
                      mr: 'आघाडी असलेले बूथ',
                      hi: 'बढ़त वाले बूथ',
                    ),
                    PdfTranslationHelper.formatNumber(winningBooths, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Losing Booths',
                      mr: 'पिछाडी असलेले बूथ',
                      hi: 'पिछड़े बूथ',
                    ),
                    PdfTranslationHelper.formatNumber(losingBooths, activeLang),
                    highlightColor: PdfColors.red700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (boothList.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No election booth results available.',
                    mr: 'निवडणूक बूथ निकाल उपलब्ध नाहीत.',
                    hi: 'चुनाव बूथ परिणाम उपलब्ध नहीं हैं।',
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
                  0: pw.FixedColumnWidth(28),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(2.0),
                  4: pw.FlexColumnWidth(2.4),
                  5: pw.FlexColumnWidth(1.6),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Booth / Centre',
                    mr: 'बूथ / मतदान केंद्र',
                    hi: 'बूथ / मतदान केंद्र',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Candidate Votes',
                    mr: 'उमेदवाराची मते',
                    hi: 'उम्मीदवार के मत',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Total Cast',
                    mr: 'एकूण मतदान',
                    hi: 'कुल मतदान',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Winner',
                    mr: 'विजेता',
                    hi: 'विजेता',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Margin',
                    mr: 'मताधिक्य',
                    hi: 'अंतर',
                  ),
                ],
                data: List.generate(boothList.length, (index) {
                  final r = boothList[index];
                  final candVotes = r.votesFor(selectedCandidate);
                  final isWinner = r.isWinner(selectedCandidate);
                  final margin = r.margin;

                  final boothNum = PdfTranslationHelper.resolve(
                    textCache,
                    r.boothNumber,
                    activeLang,
                  );
                  final boothNameTrim = r.boothName.trim();
                  final boothDisplay = (boothNameTrim.isNotEmpty &&
                          boothNameTrim != r.boothNumber.trim())
                      ? '$boothNum - ${PdfTranslationHelper.resolve(textCache, boothNameTrim, activeLang)}'
                      : boothNum;

                  final votesWord = AppTranslations.pick(
                    activeLang,
                    en: 'votes',
                    mr: 'मते',
                    hi: 'मत',
                  );
                  final wonWord = AppTranslations.pick(
                    activeLang,
                    en: 'Won',
                    mr: 'विजयी',
                    hi: 'विजयी',
                  );
                  final resolvedWinner = PdfTranslationHelper.resolveName(
                    nameCache,
                    r.winner,
                    activeLang,
                  );

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    boothDisplay,
                    '${PdfTranslationHelper.formatNumber(candVotes, activeLang)} $votesWord',
                    PdfTranslationHelper.formatNumber(
                      r.totalVotesCasted,
                      activeLang,
                    ),
                    isWinner ? '$resolvedCandidate ($wonWord)' : resolvedWinner,
                    '+${PdfTranslationHelper.formatNumber(margin, activeLang)}',
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Election_Results_${DateFormat('yyyyMMdd').format(DateTime.now())}';
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
