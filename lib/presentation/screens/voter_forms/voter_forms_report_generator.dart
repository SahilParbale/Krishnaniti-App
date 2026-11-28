import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/voter_application_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class VoterFormsReportGenerator {
  VoterFormsReportGenerator._();

  static String _localizeFormType(
    String formType,
    String lang,
    Map<String, String> textCache,
  ) {
    final norm = formType.toLowerCase().replaceAll(' ', '');
    switch (norm) {
      case 'form6':
        return AppTranslations.pick(
          lang,
          en: 'Form 6 (New Registration)',
          mr: 'फॉर्म ६ (नवीन नोंदणी)',
          hi: 'फॉर्म ६ (नया पंजीकरण)',
        );
      case 'form7':
        return AppTranslations.pick(
          lang,
          en: 'Form 7 (Name Deletion)',
          mr: 'फॉर्म ७ (नाव वगळणे)',
          hi: 'फॉर्म ७ (नाम विलोपन)',
        );
      case 'form8':
        return AppTranslations.pick(
          lang,
          en: 'Form 8 (Correction / Shift)',
          mr: 'फॉर्म ८ (तपशील दुरुस्ती)',
          hi: 'फॉर्म ८ (विवरण सुधार)',
        );
      case 'search':
        return AppTranslations.pick(
          lang,
          en: 'Search in Roll',
          mr: 'मतदार यादीत शोध',
          hi: 'मतदाता सूची में खोज',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, formType, lang);
    }
  }

  static String _localizeStatus(
    String status,
    String lang,
    Map<String, String> textCache,
  ) {
    final lower = status.trim().toLowerCase();
    switch (lower) {
      case 'submitted':
        return AppTranslations.pick(
          lang,
          en: 'Submitted',
          mr: 'दाखल केला',
          hi: 'प्रस्तुत',
        );
      case 'pending':
        return AppTranslations.getStatus('Pending', lang);
      case 'approved':
        return AppTranslations.getStatus('Approved', lang);
      case 'rejected':
        return AppTranslations.getStatus('Rejected', lang);
      default:
        final mapped = AppTranslations.getStatus(status, lang);
        if (mapped.toLowerCase() != lower) return mapped;
        return PdfTranslationHelper.resolve(textCache, status, lang);
    }
  }

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<VoterApplicationModel> applications,
    String? lang,
  }) async {
    final activeLang =
        (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);

    final total = applications.length;
    final approved =
        applications.where((a) => a.status.toLowerCase() == 'approved').length;
    final pending =
        applications.where((a) => a.status.toLowerCase() == 'pending').length;
    final submitted =
        applications.where((a) => a.status.toLowerCase() == 'submitted').length;

    final nameCache = await PdfTranslationHelper.batchNames(
      applications.map((a) => a.applicantName),
      activeLang,
    );
    final textCache = await PdfTranslationHelper.batchText(
      [
        for (final a in applications) ...[
          a.notes,
          a.formType,
          a.status,
        ],
      ],
      activeLang,
    );

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Voter Applications History',
      mr: 'मतदार अर्ज इतिहास',
      hi: 'मतदाता आवेदन इतिहास',
    );
    final continuationTitle = AppTranslations.pick(
      activeLang,
      en: 'Voter Applications',
      mr: 'मतदार अर्ज',
      hi: 'मतदाता आवेदन',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'List of all logged voter form applications (Form 6, 7, 8)',
      mr: 'नोंदवलेल्या सर्व मतदार अर्ज फॉर्मची यादी (फॉर्म ६, ७, ८)',
      hi: 'दर्ज सभी मतदाता फॉर्म आवेदनों की सूची (फॉर्म ६, ७, ८)',
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
              totalCount: total,
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary KPI Row matching web
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
                      en: 'Total Applications',
                      mr: 'एकूण अर्ज',
                      hi: 'कुल आवेदन',
                    ),
                    PdfTranslationHelper.formatNumber(total, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Approved',
                      mr: 'मंजूर',
                      hi: 'स्वीकृत',
                    ),
                    PdfTranslationHelper.formatNumber(approved, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Pending',
                      mr: 'प्रलंबित',
                      hi: 'लंबित',
                    ),
                    PdfTranslationHelper.formatNumber(pending, activeLang),
                    highlightColor: PdfColors.amber800,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Submitted',
                      mr: 'दाखल केलेले',
                      hi: 'प्रस्तुत',
                    ),
                    PdfTranslationHelper.formatNumber(submitted, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (applications.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No voter form applications found.',
                    mr: 'कोणतेही मतदार अर्ज आढळले नाहीत.',
                    hi: 'कोई मतदाता फॉर्म आवेदन नहीं मिला।',
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
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(1.8),
                  3: pw.FlexColumnWidth(2.0),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.4),
                  6: pw.FlexColumnWidth(2.8),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Applicant Name',
                    mr: 'अर्जदाराचे नाव',
                    hi: 'आवेदक का नाम',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Mobile',
                    mr: 'मोबाईल',
                    hi: 'मोबाइल',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Form Type',
                    mr: 'फॉर्म प्रकार',
                    hi: 'फॉर्म प्रकार',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Status',
                    mr: 'स्थिती',
                    hi: 'स्थिति',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Date',
                    mr: 'दिनांक',
                    hi: 'दिनांक',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Notes / Purpose',
                    mr: 'नोंदी / उद्देश',
                    hi: 'टिप्पणी / उद्देश्य',
                  ),
                ],
                data: List.generate(applications.length, (index) {
                  final app = applications[index];
                  final dateStr =
                      PdfTranslationHelper.formatDate(app.createdAt, activeLang);

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    PdfTranslationHelper.resolveName(
                      nameCache,
                      app.applicantName,
                      activeLang,
                    ),
                    (app.applicantMobile != null &&
                            app.applicantMobile!.trim().isNotEmpty)
                        ? app.applicantMobile!.trim()
                        : '-',
                    _localizeFormType(app.formType, activeLang, textCache),
                    _localizeStatus(app.status, activeLang, textCache),
                    dateStr,
                    (app.notes != null && app.notes!.trim().isNotEmpty)
                        ? PdfTranslationHelper.resolve(
                            textCache,
                            app.notes,
                            activeLang,
                          )
                        : '-',
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Voter_Forms_Report_${DateFormat('yyyyMMdd').format(now)}';
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
