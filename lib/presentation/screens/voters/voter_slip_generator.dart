
import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/voter_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class VoterSlipGenerator {
  VoterSlipGenerator._();

  static String _pickNameSource(VoterModel voter, String lang) {
    if (lang == 'en') {
      return voter.nameEnglish.trim().isNotEmpty
          ? voter.nameEnglish.trim()
          : voter.displayName.trim();
    }
    return voter.nameMarathi.trim().isNotEmpty
        ? voter.nameMarathi.trim()
        : voter.nameEnglish.trim();
  }

  static String _resolvePollingStation(
    VoterModel voter,
    String lang,
    Map<String, String> textCache,
  ) {
    if (voter.pollingStation != null && voter.pollingStation!.trim().isNotEmpty) {
      return PdfTranslationHelper.resolve(
        textCache,
        voter.pollingStation!.trim(),
        lang,
      );
    }
    final boothNorm = AppTranslations.normalizeAsciiDigits(voter.booth);
    if (boothNorm.contains('28')) {
      return AppTranslations.pick(
        lang,
        en: 'New English School, Shaniwar Peth, Pune - 411030',
        mr: 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३०',
        hi: 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३०',
      );
    } else if (boothNorm.contains('29')) {
      return AppTranslations.pick(
        lang,
        en: 'Pune Municipal School No. 15 (Boys), Kasba Peth, Pune',
        mr: 'पुणे मनपा शाळा क्र. १५ (मुलांची), कसबा पेठ, पुणे',
        hi: 'पुणे मनपा स्कूल क्र. १५ (लड़के), कसबा पेठ, पुणे',
      );
    } else if (boothNorm.contains('30')) {
      return AppTranslations.pick(
        lang,
        en: 'Ahilyadevi High School, Shaniwar Peth, Pune - 411030',
        mr: 'अहिल्यादेवी हायस्कूल, शनिवार पेठ, पुणे - ४११०३०',
        hi: 'अहिल्यादेवी हाई स्कूल, शनिवार पेठ, पुणे - ४११०३०',
      );
    } else if (boothNorm.contains('31')) {
      return AppTranslations.pick(
        lang,
        en: 'K.P.B. Hindu High School, Raviwar Peth, Pune',
        mr: 'के.पी.बी. हिंदू हायस्कूल, रविवार पेठ, पुणे',
        hi: 'के.पी.बी. हिंदू हाई स्कूल, रविवार पेठ, पुणे',
      );
    }
    final boothFormatted = PdfTranslationHelper.resolve(textCache, voter.booth, lang);
    return AppTranslations.pick(
      lang,
      en: 'Polling Station No. $boothFormatted, Ward 12, Pune',
      mr: 'मतदान केंद्र क्र. $boothFormatted, प्रभाग १२, पुणे',
      hi: 'मतदान केंद्र क्र. $boothFormatted, वार्ड १२, पुणे',
    );
  }

  static String _localizeFavour(
    String? favour,
    String lang,
    Map<String, String> textCache,
  ) {
    if (favour == null || favour.trim().isEmpty) return '-';
    final clean = favour.trim();
    switch (clean.toLowerCase()) {
      case 'favourable':
      case 'favorable':
      case 'supporter':
      case 'अनुकूल':
        return AppTranslations.pick(
          lang,
          en: 'Favourable',
          mr: 'अनुकूल',
          hi: 'अनुकूल',
        );
      case 'against':
      case 'opponent':
      case 'प्रतिकूल':
        return AppTranslations.pick(
          lang,
          en: 'Against',
          mr: 'प्रतिकूल',
          hi: 'प्रतिकूल',
        );
      case 'neutral':
      case 'तटस्थ':
        return AppTranslations.pick(
          lang,
          en: 'Neutral',
          mr: 'तटस्थ',
          hi: 'तटस्थ',
        );
      case 'swing':
      case 'अनिश्चित':
      case 'अस्पष्ट':
        return AppTranslations.pick(
          lang,
          en: 'Swing',
          mr: 'अनिश्चित',
          hi: 'अनिश्चित',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, clean, lang);
    }
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

  static String _localizeFilterSummary(
    String summary,
    String lang,
    Map<String, String> textCache,
  ) {
    final trimmed = summary.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.toLowerCase().startsWith('booth:')) {
      final rawBooth = trimmed.substring(6).trim();
      final resolvedBooth = PdfTranslationHelper.resolve(textCache, rawBooth, lang);
      final boothLabel = AppTranslations.pick(
        lang,
        en: 'Booth',
        mr: 'बूथ',
        hi: 'बूथ',
      );
      return '$boothLabel: $resolvedBooth';
    }
    return PdfTranslationHelper.resolve(textCache, trimmed, lang);
  }

  /// Generate and print single official voter information slip
  static Future<void> printVoterSlip(
    VoterModel voter, {
    BuildContext? context,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDateTime(DateTime.now(), activeLang);

    final primaryNameSrc = _pickNameSource(voter, activeLang);
    final nameCache = await PdfTranslationHelper.batchNames(
      [primaryNameSrc],
      activeLang,
    );
    final textCache = await PdfTranslationHelper.batchText(
      [
        voter.address,
        voter.booth,
        if (voter.pollingStation != null && voter.pollingStation!.trim().isNotEmpty)
          voter.pollingStation!,
        if (voter.houseNo != null && voter.houseNo!.trim().isNotEmpty)
          voter.houseNo!,
      ],
      activeLang,
    );

    final resolvedVoterName =
        PdfTranslationHelper.resolveName(nameCache, primaryNameSrc, activeLang);
    final resolvedEnglishName = voter.nameEnglish.trim();
    final resolvedBooth = voter.booth.trim().isNotEmpty
        ? PdfTranslationHelper.resolve(textCache, voter.booth, activeLang)
        : '-';
    final resolvedAddress =
        PdfTranslationHelper.resolve(textCache, voter.address, activeLang);
    final resolvedPollingStation =
        _resolvePollingStation(voter, activeLang, textCache);
    final resolvedSerial = voter.serialNo != null
        ? '#${PdfTranslationHelper.formatNumber(voter.serialNo, activeLang)}'
        : '-';
    final resolvedAge = PdfTranslationHelper.formatNumber(voter.age, activeLang);
    final yrsLabel = AppTranslations.pick(
      activeLang,
      en: 'Yrs',
      mr: 'वर्षे',
      hi: 'वर्ष',
    );
    final resolvedGender = _resolveGender(voter.gender, activeLang, textCache);
    final resolvedHouseNo =
        (voter.houseNo != null && voter.houseNo!.trim().isNotEmpty)
            ? '#${PdfTranslationHelper.formatNumber(voter.houseNo!.trim(), activeLang)}'
            : '-';
    final mobileStr = (voter.mobile != null && voter.mobile!.trim().isNotEmpty)
        ? (voter.mobile!.trim().startsWith('+')
            ? voter.mobile!.trim()
            : '+91 ${voter.mobile!.trim()}')
        : AppTranslations.pick(
            activeLang,
            en: 'Not Registered',
            mr: 'नोंदणीकृत नाही',
            hi: 'पंजीकृत नहीं',
          );
    final epicDisplay = voter.epicNo.trim().isNotEmpty ? voter.epicNo.trim() : '-';

    final slipModalTitle = AppTranslations.pick(
      activeLang,
      en: 'Voter Information Slip',
      mr: 'मतदार माहिती स्लिप',
      hi: 'मतदाता सूचना पर्ची',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        AppTranslations.pick(
                          activeLang,
                          en: 'PUNE MUNICIPAL CORPORATION - GENERAL ELECTION',
                          mr: 'पुणे महानगरपालिका - सार्वत्रिक निवडणूक',
                          hi: 'पुणे नगर निगम - आम चुनाव',
                        ),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        AppTranslations.pick(
                          activeLang,
                          en: 'OFFICIAL VOTER INFORMATION SLIP',
                          mr: 'अधिकृत मतदार माहिती स्लिप',
                          hi: 'आधिकारिक मतदाता सूचना पर्ची',
                        ),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          color: PdfColors.amber200,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      pw.Text(
                        AppTranslations.pick(
                          activeLang,
                          en: '214 - Kasba Peth Assembly Constituency | Ward No. 12',
                          mr: '२१४ - कसबा पेठ विधानसभा मतदारसंघ | प्रभाग क्र. १२',
                          hi: '२१४ - कसबा पेठ विधानसभा क्षेत्र | वार्ड क्र. १२',
                        ),
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // Serial & Part Number Highlight Box
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              AppTranslations.pick(
                                activeLang,
                                en: 'Serial No. in Electoral Roll',
                                mr: 'मतदार यादीतील अनुक्रमांक',
                                hi: 'मतदाता सूची में क्रम संख्या',
                              ),
                              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                            ),
                            pw.Text(
                              resolvedSerial,
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              AppTranslations.pick(
                                activeLang,
                                en: 'Booth / Part No.',
                                mr: 'मतदान केंद्र / भाग क्र.',
                                hi: 'मतदान केंद्र / भाग सं.',
                              ),
                              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                            ),
                            pw.Text(
                              resolvedBooth,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),

                // Voter Data Grid
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(5),
                    },
                    children: [
                      _buildTableRow(
                        AppTranslations.pick(
                          activeLang,
                          en: 'Voter Full Name',
                          mr: 'मतदाराचे पूर्ण नाव',
                          hi: 'मतदाता का पूरा नाम',
                        ),
                        resolvedVoterName,
                      ),
                      if (activeLang != 'en' && resolvedEnglishName.isNotEmpty)
                        _buildTableRow(
                          AppTranslations.pick(
                            activeLang,
                            en: 'English Name',
                            mr: 'नाव (इंग्रजी)',
                            hi: 'नाम (अंग्रेज़ी)',
                          ),
                          resolvedEnglishName,
                        ),
                      _buildTableRow(
                        AppTranslations.pick(
                          activeLang,
                          en: 'EPIC No.',
                          mr: 'मतदार ओळखपत्र क्र. (EPIC)',
                          hi: 'मतदाता पहचान पत्र सं. (EPIC)',
                        ),
                        epicDisplay,
                      ),
                      _buildTableRow(
                        AppTranslations.pick(
                          activeLang,
                          en: 'Age / Gender',
                          mr: 'वय / लिंग',
                          hi: 'आयु / लिंग',
                        ),
                        '$resolvedAge $yrsLabel / $resolvedGender',
                      ),
                      _buildTableRow(
                        AppTranslations.pick(
                          activeLang,
                          en: 'House No.',
                          mr: 'घर क्र.',
                          hi: 'मकान नं.',
                        ),
                        resolvedHouseNo,
                      ),
                      _buildTableRow(
                        AppTranslations.pick(
                          activeLang,
                          en: 'Residential Address',
                          mr: 'निवासी पत्ता',
                          hi: 'निवासी पता',
                        ),
                        resolvedAddress,
                      ),
                      _buildTableRow(
                        AppTranslations.pick(
                          activeLang,
                          en: 'Mobile Number',
                          mr: 'मोबाईल क्रमांक',
                          hi: 'मोबाइल नंबर',
                        ),
                        mobileStr,
                      ),
                      _buildTableRow(
                        AppTranslations.pick(
                          activeLang,
                          en: 'Polling Station',
                          mr: 'मतदान केंद्र',
                          hi: 'मतदान केंद्र',
                        ),
                        resolvedPollingStation,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // Important Note Box
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    border: pw.Border.all(color: PdfColors.amber300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppTranslations.pick(
                          activeLang,
                          en: 'Important Guidelines:',
                          mr: 'महत्त्वाच्या सूचना:',
                          hi: 'महत्वपूर्ण निर्देश:',
                        ),
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        AppTranslations.pick(
                          activeLang,
                          en: '1. This slip is for finding polling station and serial number. Carrying voter ID (EPIC) or Aadhaar is required for voting.\n'
                              '2. Voting Hours: 7:00 AM to 6:00 PM.',
                          mr: '१. ही स्लिप मतदान केंद्र आणि अनुक्रमांक शोधण्यासाठी आहे. मतदानासाठी मतदार ओळखपत्र (EPIC) किंवा आधार कार्ड सोबत बाळगणे आवश्यक आहे.\n'
                              '२. मतदानाची वेळ: सकाळी ७:०० ते सायंकाळी ६:०० वाजेपर्यंत.',
                          hi: '१. यह पर्ची मतदान केंद्र और क्रम संख्या खोजने के लिए है। मतदान के लिए मतदाता पहचान पत्र (EPIC) या आधार कार्ड साथ लाना अनिवार्य है।\n'
                              '२. मतदान का समय: सुबह ७:०० बजे से शाम ६:०० बजे तक।',
                        ),
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      AppTranslations.pick(
                        activeLang,
                        en: 'Nagarsevak Election Assistance Portal • Ward 12',
                        mr: 'नगरसेवक निवडणूक सहाय्य पोर्टल • प्रभाग १२',
                        hi: 'नगरसेवक चुनाव सहायता पोर्टल • वार्ड १२',
                      ),
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      AppTranslations.pick(
                        activeLang,
                        en: 'Generated: $nowStr',
                        mr: 'तयार केले: $nowStr',
                        hi: 'निर्मित: $nowStr',
                      ),
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final fileName = 'Voter_Slip_${voter.epicNo.replaceAll('/', '_')}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: slipModalTitle,
        subtitle: resolvedVoterName,
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

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
          ),
        ),
      ],
    );
  }

  /// Generate and download complete filtered voter list matching web VoterReportGenerator.tsx
  static Future<void> downloadVotersListReport({
    BuildContext? context,
    required List<VoterModel> voters,
    String? currentFilterSummary,
    int totalCount = 42560,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final nowStr = PdfTranslationHelper.formatDateTime(DateTime.now(), activeLang);

    final nameSources = voters.map((v) => _pickNameSource(v, activeLang)).toList();
    final nameCache = await PdfTranslationHelper.batchNames(nameSources, activeLang);

    final textItems = <String?>[
      for (final v in voters) ...[
        v.address,
        v.booth,
        v.favour,
        v.gender,
      ],
      if (currentFilterSummary != null && currentFilterSummary.trim().isNotEmpty)
        if (currentFilterSummary.trim().toLowerCase().startsWith('booth:'))
          currentFilterSummary.trim().substring(6).trim()
        else
          currentFilterSummary.trim(),
    ];
    final textCache = await PdfTranslationHelper.batchText(textItems, activeLang);

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Voters List',
      mr: 'मतदार यादी',
      hi: 'मतदाता सूची',
    );
    final hasFilter =
        currentFilterSummary != null && currentFilterSummary.trim().isNotEmpty;
    final reportSubtitle = hasFilter
        ? '${AppTranslations.pick(activeLang, en: 'Filtered:', mr: 'फिल्टर केलेले:', hi: 'फ़िल्टर:')} ${_localizeFilterSummary(currentFilterSummary, activeLang, textCache)}'
        : AppTranslations.pick(
            activeLang,
            en: 'Detailed Electoral Roll Report',
            mr: 'सविस्तर मतदार यादी अहवाल',
            hi: 'विस्तृत मतदाता सूची रिपोर्ट',
          );
    final foundLabel = AppTranslations.pick(
      activeLang,
      en: 'Found',
      mr: 'सापडले',
      hi: 'मिले',
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
            dateFormatted: nowStr,
            totalCount: voters.length,
            foundLabel: foundLabel,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) =>
            WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          if (voters.isEmpty) {
            return [
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No voter records found.',
                    mr: 'कोणत्याही मतदार नोंदी आढळल्या नाहीत.',
                    hi: 'कोई मतदाता रिकॉर्ड नहीं मिला।',
                  ),
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: WebReportTheme.slate500,
                  ),
                ),
              ),
            ];
          }

          return [
            // Table of Voters matching web VoterReportGenerator.tsx
            pw.TableHelper.fromTextArray(
              border: WebReportTheme.tableBorder,
              headerCount: 1,
              headerStyle: WebReportTheme.tableHeaderStyle,
              headerDecoration: WebReportTheme.tableHeaderDecoration,
              oddRowDecoration: WebReportTheme.oddRowDecoration,
              cellStyle: WebReportTheme.tableCellStyle,
              columnWidths: const {
                0: pw.FlexColumnWidth(0.6), // # (5%)
                1: pw.FlexColumnWidth(2.2), // Name (20%)
                2: pw.FlexColumnWidth(1.4), // EPIC No (12%)
                3: pw.FlexColumnWidth(0.8), // Age/Sex (6%)
                4: pw.FlexColumnWidth(2.6), // Address (25%)
                5: pw.FlexColumnWidth(1.2), // Ward / Booth (10%)
                6: pw.FlexColumnWidth(1.1), // Caste / Favour (10%)
              },
              headers: [
                AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                AppTranslations.pick(activeLang, en: 'Name', mr: 'नाव', hi: 'नाम'),
                AppTranslations.pick(
                  activeLang,
                  en: 'EPIC No.',
                  mr: 'ओळखपत्र क्र.',
                  hi: 'ईपीआईसी सं.',
                ),
                AppTranslations.pick(
                  activeLang,
                  en: 'Age/Sex',
                  mr: 'वय/लिंग',
                  hi: 'आयु/लिंग',
                ),
                AppTranslations.pick(activeLang, en: 'Address', mr: 'पत्ता', hi: 'पता'),
                AppTranslations.pick(activeLang, en: 'Booth', mr: 'बूथ', hi: 'बूथ'),
                AppTranslations.pick(
                  activeLang,
                  en: 'Favour',
                  mr: 'कल / बाजू',
                  hi: 'रुझान',
                ),
              ],
              data: voters.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                final resolvedName = PdfTranslationHelper.resolveName(
                  nameCache,
                  nameSources[idx],
                  activeLang,
                );
                final resolvedAddr = PdfTranslationHelper.resolve(
                  textCache,
                  v.address,
                  activeLang,
                );
                final addressStr = (v.houseNo != null && v.houseNo!.trim().isNotEmpty)
                    ? '#${PdfTranslationHelper.formatNumber(v.houseNo!.trim(), activeLang)}, $resolvedAddr'
                    : resolvedAddr;
                final ageStr = PdfTranslationHelper.formatNumber(v.age, activeLang);
                final genderStr = _resolveGender(v.gender, activeLang, textCache);
                final boothStr = v.booth.trim().isNotEmpty
                    ? PdfTranslationHelper.resolve(textCache, v.booth, activeLang)
                    : '-';

                return [
                  PdfTranslationHelper.formatNumber(
                    v.serialNo ?? (idx + 1),
                    activeLang,
                  ),
                  resolvedName,
                  v.epicNo.trim().isNotEmpty ? v.epicNo.trim() : '-',
                  '$ageStr / $genderStr',
                  addressStr,
                  boothStr,
                  _localizeFavour(v.favour, activeLang, textCache),
                ];
              }).toList(),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    final fileName = 'Voter_List_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
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


