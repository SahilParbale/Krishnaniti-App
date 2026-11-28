import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';
import 'analysis_strategy_screen.dart';

class AnalysisStrategyReportGenerator {
  AnalysisStrategyReportGenerator._();

  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
    unicode: true,
  );

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required AreaMetrics reportData,
    required String generatedBrief,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);

    final sanitizedBrief = _sanitizeBriefForPdf(generatedBrief);
    final toTranslate = <String>[
      if (reportData.areaName.trim().isNotEmpty) reportData.areaName,
      for (final key in reportData.casteDistribution.keys)
        if (_knownCasteLabel(key, activeLang) == null && key.trim().isNotEmpty) key,
      if (sanitizedBrief.isNotEmpty) sanitizedBrief,
    ];
    final namesToTransliterate = <String>[];
    if (reportData.winnerName.trim().isNotEmpty) {
      if (_isPartyOrRoleLabel(reportData.winnerName)) {
        toTranslate.add(reportData.winnerName);
      } else {
        namesToTransliterate.add(reportData.winnerName);
      }
    }

    final results = await Future.wait([
      PdfTranslationHelper.batchText(toTranslate, activeLang),
      PdfTranslationHelper.batchNames(namesToTransliterate, activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final resolvedArea = _resolveArea(reportData.areaName, textCache, activeLang);
    final resolvedWinner = _isPartyOrRoleLabel(reportData.winnerName)
        ? PdfTranslationHelper.resolve(textCache, reportData.winnerName, activeLang)
        : PdfTranslationHelper.resolveName(nameCache, reportData.winnerName, activeLang);
    final resolvedBrief = sanitizedBrief.isNotEmpty
        ? PdfTranslationHelper.resolve(textCache, sanitizedBrief, activeLang)
        : '';

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Area Intelligence & Strategy Docket',
      mr: 'परिसर विश्लेषण व निवडणूक रणनीती अहवाल',
      hi: 'क्षेत्र विश्लेषण एवं रणनीति डॉकेट',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Area: $resolvedArea - Field Strategy & Analytics',
      mr: 'परिसर: $resolvedArea - क्षेत्रीय रणनीती व विश्लेषण',
      hi: 'क्षेत्र: $resolvedArea - क्षेत्रीय रणनीति एवं विश्लेषण',
    );
    final contTitle = AppTranslations.pick(
      activeLang,
      en: 'Area Intelligence - $resolvedArea',
      mr: 'परिसर विश्लेषण - $resolvedArea',
      hi: 'क्षेत्र विश्लेषण - $resolvedArea',
    );
    final totalVotersLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Voters',
      mr: 'एकूण मतदार',
      hi: 'कुल मतदाता',
    );

    final totalVotersFormatted = PdfTranslationHelper.formatNumber(
      NumberFormat('#,##,###').format(reportData.totalVoters),
      activeLang,
    );
    final electionVotesFormatted = PdfTranslationHelper.formatNumber(
      NumberFormat('#,##,###').format(reportData.totalElectionVotes),
      activeLang,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: contTitle,
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
              totalCount: reportData.totalVoters,
              foundLabel: totalVotersLabel,
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Key KPI Stats Row matching web
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
                    totalVotersLabel,
                    totalVotersFormatted,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Karyakartas', mr: 'कार्यकर्ते', hi: 'कार्यकर्ता'),
                    PdfTranslationHelper.formatNumber(reportData.staffCount, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Supporters', mr: 'समर्थक', hi: 'समर्थक'),
                    PdfTranslationHelper.formatNumber(reportData.supportersCount, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(activeLang, en: 'Mobile Reach', mr: 'मोबाईल पोहोच', hi: 'मोबाइल पहुंच'),
                    '${PdfTranslationHelper.formatNumber(reportData.mobileReach, activeLang)}%',
                    highlightColor: WebReportTheme.brand600,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Demographics & Population Analysis
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    AppTranslations.pick(
                      activeLang,
                      en: 'VOTER DEMOGRAPHICS & POPULATION ANALYSIS',
                      mr: 'मतदार लोकसंख्या व वर्गीकरण विश्लेषण',
                      hi: 'मतदाता जनसांख्यिकी एवं जनसंख्या विश्लेषण',
                    ),
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.brand700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              AppTranslations.pick(
                                activeLang,
                                en: 'Age Group Distribution:',
                                mr: 'वयोगट निहाय वितरण:',
                                hi: 'आयु वर्ग वितरण:',
                              ),
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: WebReportTheme.slate700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            _buildDataRow(
                              AppTranslations.pick(activeLang, en: 'Youth (18-35 yrs)', mr: 'युवा (१८-३५ वर्षे)', hi: 'युवा (१८-३५ वर्ष)'),
                              PdfTranslationHelper.formatNumber(reportData.age18_35, activeLang),
                            ),
                            _buildDataRow(
                              AppTranslations.pick(activeLang, en: 'Middle-aged (36-60 yrs)', mr: 'मध्यम वयीन (३६-६० वर्षे)', hi: 'मध्यम आयु (३६-६० वर्ष)'),
                              PdfTranslationHelper.formatNumber(reportData.age36_60, activeLang),
                            ),
                            _buildDataRow(
                              AppTranslations.pick(activeLang, en: 'Senior Citizens (60+ yrs)', mr: 'ज्येष्ठ नागरिक (६०+ वर्षे)', hi: 'वरिष्ठ नागरिक (६०+ वर्ष)'),
                              PdfTranslationHelper.formatNumber(reportData.age61Plus, activeLang),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              AppTranslations.pick(
                                activeLang,
                                en: 'Gender Ratio:',
                                mr: 'लिंग गुणोत्तर:',
                                hi: 'लिंग अनुपात:',
                              ),
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: WebReportTheme.slate700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            _buildDataRow(
                              AppTranslations.pick(activeLang, en: 'Male Voters', mr: 'पुरुष मतदार', hi: 'पुरुष मतदाता'),
                              PdfTranslationHelper.formatNumber(reportData.genderMale, activeLang),
                            ),
                            _buildDataRow(
                              AppTranslations.pick(activeLang, en: 'Female Voters', mr: 'महिला मतदार', hi: 'महिला मतदाता'),
                              PdfTranslationHelper.formatNumber(reportData.genderFemale, activeLang),
                            ),
                            _buildDataRow(
                              AppTranslations.pick(activeLang, en: 'Other / Unspecified', mr: 'इतर / अनिर्दिष्ट', hi: 'अन्य / अनिर्दिष्ट'),
                              PdfTranslationHelper.formatNumber(reportData.genderOther, activeLang),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // Caste Distribution Table
            if (reportData.casteDistribution.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AppTranslations.pick(
                        activeLang,
                        en: 'ESTIMATED COMMUNITY / CASTE BREAKDOWN',
                        mr: 'अंदाजित समाज / प्रवर्गनिहाय विभाजन',
                        hi: 'अनुमानित समुदाय / वर्गवार विवरण',
                      ),
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.TableHelper.fromTextArray(
                      border: WebReportTheme.tableBorder,
                      headerCount: 1,
                      headers: [
                        AppTranslations.pick(activeLang, en: 'Community / Caste Segment', mr: 'समाज / प्रवर्ग गट', hi: 'समुदाय / वर्ग श्रेणी'),
                        AppTranslations.pick(activeLang, en: 'Estimated Voter Count', mr: 'अंदाजित मतदार संख्या', hi: 'अनुमानित मतदाता संख्या'),
                      ],
                      data: reportData.casteDistribution.entries
                          .map((e) => [
                                _knownCasteLabel(e.key, activeLang) ??
                                    PdfTranslationHelper.resolve(textCache, e.key, activeLang),
                                PdfTranslationHelper.formatNumber(e.value, activeLang),
                              ])
                          .toList(),
                      headerStyle: WebReportTheme.tableHeaderStyle,
                      headerDecoration: WebReportTheme.tableHeaderDecoration,
                      oddRowDecoration: WebReportTheme.oddRowDecoration,
                      cellStyle: WebReportTheme.tableCellStyle,
                      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // Civic Problems & Personal Requests Row
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          AppTranslations.pick(
                            activeLang,
                            en: 'CIVIC GRIEVANCES & WORKS',
                            mr: 'नागरी तक्रारी व विकासकामे',
                            hi: 'नागरिक शिकायतें एवं विकास कार्य',
                          ),
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate800),
                        ),
                        pw.SizedBox(height: 6),
                        _buildDataRow(
                          AppTranslations.pick(activeLang, en: 'Solved Complaints', mr: 'सोडवलेल्या तक्रारी', hi: 'सुलझाई गई शिकायतें'),
                          PdfTranslationHelper.formatNumber(reportData.solvedComplaints, activeLang),
                        ),
                        _buildDataRow(
                          AppTranslations.pick(activeLang, en: 'Ongoing Complaints', mr: 'सुरू असलेल्या तक्रारी', hi: 'चालू शिकायतें'),
                          PdfTranslationHelper.formatNumber(reportData.ongoingComplaints, activeLang),
                        ),
                        _buildDataRow(
                          AppTranslations.pick(activeLang, en: 'Total Registered', mr: 'एकूण नोंदणीकृत', hi: 'कुल पंजीकृत'),
                          PdfTranslationHelper.formatNumber(reportData.totalComplaints, activeLang),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          AppTranslations.pick(
                            activeLang,
                            en: 'OFFICE ASSISTANCE REQUESTS',
                            mr: 'कार्यालयीन मदत विनंत्या',
                            hi: 'कार्यालय सहायता अनुरोध',
                          ),
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate800),
                        ),
                        pw.SizedBox(height: 6),
                        _buildDataRow(
                          AppTranslations.pick(activeLang, en: 'Completed Requests', mr: 'पूर्ण विनंत्या', hi: 'पूर्ण अनुरोध'),
                          PdfTranslationHelper.formatNumber(reportData.solvedRequests, activeLang),
                        ),
                        _buildDataRow(
                          AppTranslations.pick(activeLang, en: 'Pending Requests', mr: 'प्रलंबित विनंत्या', hi: 'लंबित अनुरोध'),
                          PdfTranslationHelper.formatNumber(reportData.pendingRequests, activeLang),
                        ),
                        _buildDataRow(
                          AppTranslations.pick(activeLang, en: 'Total Requests', mr: 'एकूण विनंत्या', hi: 'कुल अनुरोध'),
                          PdfTranslationHelper.formatNumber(reportData.totalRequests, activeLang),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // Past Election Performance
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    AppTranslations.pick(
                      activeLang,
                      en: 'PAST ELECTION PERFORMANCE & MARGIN',
                      mr: 'मागील निवडणूक कामगिरी व मताधिक्य',
                      hi: 'पिछला चुनाव प्रदर्शन एवं जीत का अंतर',
                    ),
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate800),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildDataRow(
                          AppTranslations.pick(activeLang, en: 'Winner Candidate', mr: 'विजयी उमेदवार', hi: 'विजेता उम्मीदवार'),
                          resolvedWinner,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: _buildDataRow(
                          AppTranslations.pick(activeLang, en: 'Winning Margin', mr: 'विजयी मताधिक्य', hi: 'जीत का अंतर'),
                          '+${PdfTranslationHelper.formatNumber(reportData.winningMargin, activeLang)}',
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: _buildDataRow(
                          AppTranslations.pick(activeLang, en: 'Total Votes Cast', mr: 'एकूण झालेले मतदान', hi: 'कुल डाले गए मत'),
                          electionVotesFormatted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (resolvedBrief.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.brand50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: WebReportTheme.brand600, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AppTranslations.pick(
                        activeLang,
                        en: 'AI FIELD VISIT BRIEFING & STRATEGIC ADVISORY',
                        mr: 'AI क्षेत्रीय भेट माहिती व धोरणात्मक सल्ला',
                        hi: 'AI क्षेत्रीय दौरा ब्रीफिंग एवं रणनीतिक सलाह',
                      ),
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      resolvedBrief,
                      style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate800, lineSpacing: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    final fileName = 'Area_Intelligence_${reportData.areaName.replaceAll(' ', '_')}';
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

  static String _sanitizeBriefForPdf(String raw) {
    return raw
        .replaceAll(_emojiRegex, '')
        .replaceAll('**', '')
        .replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  static bool _isPartyOrRoleLabel(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('sitting') ||
        lower.contains('corporator') ||
        lower.contains('bjp') ||
        lower.contains('ncp') ||
        lower.contains('inc') ||
        lower.contains('mahayuti') ||
        lower.contains('shiv sena') ||
        lower.contains('party') ||
        lower.contains('candidate') ||
        lower.contains('(') ||
        lower.contains('नगरसेवक') ||
        lower.contains('भाजप') ||
        lower.contains('महायुती');
  }

  static String _resolveArea(
    String raw,
    Map<String, String> cache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final dictArea = AppTranslations.getAreaName(trimmed, lang);
    if (AppTranslations.normalizeAsciiDigits(dictArea) !=
        AppTranslations.normalizeAsciiDigits(trimmed)) {
      return dictArea;
    }
    return PdfTranslationHelper.resolve(cache, trimmed, lang);
  }

  static String? _knownCasteLabel(String raw, String lang) {
    switch (raw.trim().toLowerCase()) {
      case 'general':
        return AppTranslations.pick(lang, en: 'General', mr: 'खुला प्रवर्ग (General)', hi: 'सामान्य (General)');
      case 'obc':
        return AppTranslations.pick(lang, en: 'OBC', mr: 'इतर मागासवर्ग (OBC)', hi: 'अन्य पिछड़ा वर्ग (OBC)');
      case 'sc/st':
        return AppTranslations.pick(lang, en: 'SC/ST', mr: 'अनुसूचित जाती / जमाती (SC/ST)', hi: 'अनुसूचित जाति / जनजाति (SC/ST)');
      case 'sc':
        return AppTranslations.pick(lang, en: 'SC', mr: 'अनुसूचित जाती (SC)', hi: 'अनुसूचित जाति (SC)');
      case 'st':
        return AppTranslations.pick(lang, en: 'ST', mr: 'अनुसूचित जमाती (ST)', hi: 'अनुसूचित जनजाति (ST)');
      case 'maratha':
        return AppTranslations.pick(lang, en: 'Maratha', mr: 'मराठा', hi: 'मराठा');
      case 'brahmin':
        return AppTranslations.pick(lang, en: 'Brahmin', mr: 'ब्राह्मण', hi: 'ब्राह्मण');
      case 'minority':
        return AppTranslations.pick(lang, en: 'Minority', mr: 'अल्पसंख्याक', hi: 'अल्पसंख्यक');
      case 'other':
      case 'others':
        return AppTranslations.pick(lang, en: 'Others', mr: 'इतर', hi: 'अन्य');
      default:
        return null;
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

  static pw.Widget _buildDataRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
        ],
      ),
    );
  }
}
