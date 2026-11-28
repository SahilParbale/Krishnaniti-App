import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/duplicate_voter_group_model.dart';
import '../../../data/models/voter_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class DuplicateVotersReportGenerator {
  DuplicateVotersReportGenerator._();

  static String _pickVoterNameSource(VoterModel v, String lang) {
    if (lang == 'en') {
      return v.nameEnglish.trim().isNotEmpty
          ? v.nameEnglish.trim()
          : v.nameMarathi.trim();
    }
    return v.nameMarathi.trim().isNotEmpty
        ? v.nameMarathi.trim()
        : v.nameEnglish.trim();
  }

  static String _pickGroupNameSource(DuplicateVoterGroupModel g, String lang) {
    if (lang == 'en' && g.voters.isNotEmpty) {
      final firstEng = g.voters.first.nameEnglish.trim();
      if (firstEng.isNotEmpty) return firstEng;
    }
    if (lang != 'en' && g.voters.isNotEmpty) {
      final firstMar = g.voters.first.nameMarathi.trim();
      if (firstMar.isNotEmpty) return firstMar;
    }
    return g.displayName.trim();
  }

  static String _resolveGender(
    String gender,
    String lang,
    Map<String, String> textCache,
  ) {
    if (gender.trim().isEmpty) return '-';
    final g = AppTranslations.getGender(gender, lang);
    if (g != gender) return g;
    return PdfTranslationHelper.resolve(textCache, gender, lang);
  }

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<DuplicateVoterGroupModel> duplicateGroups,
    required int totalAffectedVoters,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);
    final estExtraRecords =
        duplicateGroups.fold<int>(0, (sum, g) => sum + g.extraRecordsCount);

    final nameItems = <String?>[];
    final textItems = <String?>[];
    for (final g in duplicateGroups) {
      if (g.matchType != 'epic' && g.matchType != 'mobile') {
        nameItems.add(_pickGroupNameSource(g, activeLang));
      }
      for (final v in g.voters) {
        nameItems.add(_pickVoterNameSource(v, activeLang));
        textItems.add(v.address);
        textItems.add(v.booth);
        textItems.add(v.gender);
      }
    }

    final nameCache = await PdfTranslationHelper.batchNames(nameItems, activeLang);
    final textCache = await PdfTranslationHelper.batchText(textItems, activeLang);

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Duplicate Voters Report',
      mr: 'दुबार मतदार अहवाल',
      hi: 'डुप्लिकेट मतदाता रिपोर्ट',
    );
    final continuationTitle = AppTranslations.pick(
      activeLang,
      en: 'Duplicate Voters Audit',
      mr: 'दुबार मतदार पडताळणी',
      hi: 'डुप्लिकेट मतदाता ऑडिट',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Identification of duplicated voter registrations across electoral rolls',
      mr: 'मतदार याद्यांमधील दुबार मतदार नोंदींची ओळख व पडताळणी',
      hi: 'मतदाता सूचियों में दोहरी मतदाता प्रविष्टियों की पहचान',
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
                '${AppTranslations.pick(activeLang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक')}: $formattedDate',
                '${AppTranslations.pick(activeLang, en: 'Affected Voters', mr: 'प्रभावित मतदार', hi: 'प्रभावित मतदाता')}: ${PdfTranslationHelper.formatNumber(totalAffectedVoters, activeLang)}',
                '${AppTranslations.pick(activeLang, en: 'Extra Records', mr: 'अतिरिक्त नोंदी', hi: 'अतिरिक्त रिकॉर्ड')}: ${PdfTranslationHelper.formatNumber(estExtraRecords, activeLang)}',
              ],
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary KPI boxes matching web layout
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
                      en: 'Duplicate Groups',
                      mr: 'दुबार गट',
                      hi: 'डुप्लिकेट समूह',
                    ),
                    PdfTranslationHelper.formatNumber(
                      duplicateGroups.length,
                      activeLang,
                    ),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Affected',
                      mr: 'एकूण प्रभावित',
                      hi: 'कुल प्रभावित',
                    ),
                    PdfTranslationHelper.formatNumber(
                      totalAffectedVoters,
                      activeLang,
                    ),
                    highlightColor: PdfColors.red700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Est. Extra Records',
                      mr: 'अंदाजे अतिरिक्त नोंदी',
                      hi: 'अनुमानित अतिरिक्त रिकॉर्ड',
                    ),
                    PdfTranslationHelper.formatNumber(estExtraRecords, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            if (duplicateGroups.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(32),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No duplicate voters found. All voter records are unique.',
                    mr: 'कोणतेही दुबार मतदार आढळले नाहीत. सर्व मतदार नोंदी अद्वितीय आहेत.',
                    hi: 'कोई डुप्लिकेट मतदाता नहीं मिला। सभी मतदाता रिकॉर्ड अद्वितीय हैं।',
                  ),
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: WebReportTheme.slate500,
                  ),
                ),
              )
            else
              ...duplicateGroups.map((group) {
                final groupTitle =
                    (group.matchType == 'epic' || group.matchType == 'mobile')
                        ? group.displayName
                        : PdfTranslationHelper.resolveName(
                            nameCache,
                            _pickGroupNameSource(group, activeLang),
                            activeLang,
                          );
                final recordsLabel = AppTranslations.pick(
                  activeLang,
                  en: 'records',
                  mr: 'नोंदी',
                  hi: 'रिकॉर्ड',
                );
                final extraForm7Label = AppTranslations.pick(
                  activeLang,
                  en: 'extra records (Form 7)',
                  mr: 'अतिरिक्त नोंदी (फॉर्म ७)',
                  hi: 'अतिरिक्त रिकॉर्ड (फॉर्म ७)',
                );

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Group Header Banner
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: WebReportTheme.brand50,
                          borderRadius: pw.BorderRadius.vertical(
                            top: pw.Radius.circular(5),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                '$groupTitle (${PdfTranslationHelper.formatNumber(group.recordsCount, activeLang)} $recordsLabel)',
                                style: pw.TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: WebReportTheme.brand900,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              '${PdfTranslationHelper.formatNumber(group.extraRecordsCount, activeLang)} $extraForm7Label',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.red700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table of Voters in Group
                      pw.TableHelper.fromTextArray(
                        headerCount: 1,
                        border: WebReportTheme.tableBorder,
                        headerStyle: WebReportTheme.tableHeaderStyle,
                        headerDecoration: WebReportTheme.tableHeaderDecoration,
                        headerHeight: 20,
                        cellHeight: 18,
                        cellAlignment: pw.Alignment.centerLeft,
                        cellStyle: WebReportTheme.tableCellStyle,
                        columnWidths: const {
                          0: pw.FixedColumnWidth(22),
                          1: pw.FlexColumnWidth(2.6),
                          2: pw.FlexColumnWidth(1.8),
                          3: pw.FlexColumnWidth(1.0),
                          4: pw.FlexColumnWidth(1.0),
                          5: pw.FlexColumnWidth(1.2),
                          6: pw.FlexColumnWidth(1.2),
                          7: pw.FlexColumnWidth(2.4),
                        },
                        headers: [
                          AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                          AppTranslations.pick(
                            activeLang,
                            en: 'Voter Name',
                            mr: 'मतदाराचे नाव',
                            hi: 'मतदाता का नाम',
                          ),
                          AppTranslations.pick(
                            activeLang,
                            en: 'EPIC No.',
                            mr: 'ओळखपत्र क्र.',
                            hi: 'ईपीआईसी सं.',
                          ),
                          AppTranslations.pick(
                            activeLang,
                            en: 'Serial',
                            mr: 'अनुक्रमांक',
                            hi: 'क्रम सं.',
                          ),
                          AppTranslations.pick(
                            activeLang,
                            en: 'Age',
                            mr: 'वय',
                            hi: 'आयु',
                          ),
                          AppTranslations.pick(
                            activeLang,
                            en: 'Gender',
                            mr: 'लिंग',
                            hi: 'लिंग',
                          ),
                          AppTranslations.pick(
                            activeLang,
                            en: 'Booth',
                            mr: 'बूथ',
                            hi: 'बूथ',
                          ),
                          AppTranslations.pick(
                            activeLang,
                            en: 'Address / Area',
                            mr: 'पत्ता / परिसर',
                            hi: 'पता / क्षेत्र',
                          ),
                        ],
                        data: List.generate(group.voters.length, (idx) {
                          final v = group.voters[idx];
                          final nameSrc = _pickVoterNameSource(v, activeLang);
                          final resolvedName = PdfTranslationHelper.resolveName(
                            nameCache,
                            nameSrc,
                            activeLang,
                          );

                          return [
                            PdfTranslationHelper.formatNumber(idx + 1, activeLang),
                            resolvedName,
                            v.epicNo.trim().isNotEmpty ? v.epicNo.trim() : '-',
                            v.serialNo != null
                                ? PdfTranslationHelper.formatNumber(
                                    v.serialNo,
                                    activeLang,
                                  )
                                : '-',
                            PdfTranslationHelper.formatNumber(v.age, activeLang),
                            _resolveGender(v.gender, activeLang, textCache),
                            v.booth.trim().isNotEmpty
                                ? PdfTranslationHelper.resolve(
                                    textCache,
                                    v.booth,
                                    activeLang,
                                  )
                                : '-',
                            v.address.trim().isNotEmpty
                                ? PdfTranslationHelper.resolve(
                                    textCache,
                                    v.address,
                                    activeLang,
                                  )
                                : '-',
                          ];
                        }),
                        oddRowDecoration: WebReportTheme.oddRowDecoration,
                      ),
                    ],
                  ),
                );
              }),
          ];
        },
      ),
    );

    final fileName =
        'Duplicate_Voters_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
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
