import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/scheme_model.dart';
import '../../../core/localization/app_translations.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class SchemeReportGenerator {
  SchemeReportGenerator._();

  /// Multi-page PDF directory of all government schemes
  static Future<void> generateAndPrintListReport({
    BuildContext? context,
    required List<SchemeModel> schemes,
    bool isMarathi = true,
    String lang = 'en',
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final total = schemes.length;
    final activeLang = lang != 'en' ? lang : (isMarathi ? 'mr' : 'en');

    final title = activeLang == 'mr'
        ? 'शासकीय योजना'
        : (activeLang == 'hi' ? 'सरकारी योजनाएं' : 'Government Schemes');
    final subtitle = activeLang == 'mr'
        ? 'राज्य व केंद्र शासकीय कल्याणकारी योजनांची अधिकृत सूची'
        : (activeLang == 'hi'
            ? 'राज्य व केंद्र सरकारी कल्याणकारी योजनाओं की आधिकारिक सूची'
            : 'Official Directory of State & Central Welfare Schemes');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: title,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: title,
              subtitle: subtitle,
              dateFormatted: nowStr,
              totalCount: total,
              foundLabel: activeLang == 'mr' ? 'एकूण आढळले' : (activeLang == 'hi' ? 'कुल मिले' : 'Found'),
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            if (schemes.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  activeLang == 'mr'
                      ? 'कोणत्याही शासकीय योजना सापडल्या नाहीत.'
                      : (activeLang == 'hi'
                          ? 'कोई सरकारी योजना नहीं मिली।'
                          : 'No government schemes found for the selected view.'),
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
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
                  1: pw.FlexColumnWidth(2.5),
                  2: pw.FlexColumnWidth(3.5),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(3.0),
                },
                headers: [
                  '#',
                  activeLang == 'mr' ? 'योजनेचे नाव' : (activeLang == 'hi' ? 'योजना का नाम' : 'Scheme Name'),
                  AppTranslations.getReportColumn('desc', activeLang),
                  AppTranslations.getReportColumn('category', activeLang),
                  activeLang == 'mr' ? 'लाभ' : (activeLang == 'hi' ? 'लाभ' : 'Benefits'),
                ],
                data: List.generate(schemes.length, (index) {
                  final item = schemes[index];
                  final isMrOrHi = activeLang == 'mr' || activeLang == 'hi';
                  final nameStr = item.localizedName(isMrOrHi);
                  final descStr = item.localizedDescription(isMrOrHi);
                  final benStr = item.localizedBenefits(isMrOrHi);

                  return [
                    '${index + 1}',
                    nameStr,
                    descStr,
                    item.category.isNotEmpty ? item.category : '-',
                    benStr,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Government_Schemes_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: title,
        subtitle: subtitle,
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

  /// Single Scheme Official Guideline Slip / Public Flyer
  static Future<void> generateAndPrintSingleSchemeFlyer({
    BuildContext? context,
    required SchemeModel scheme,
    required bool isMarathi,
  }) async {
    final pdf = pw.Document();
    final nameEn = SchemeModel.extractLocalized(scheme.name, false);
    final nameMr = SchemeModel.extractLocalized(scheme.name, true);

    final descEn = SchemeModel.extractLocalized(scheme.description, false);
    final descMr = SchemeModel.extractLocalized(scheme.description, true);

    final eligEn = SchemeModel.extractLocalized(scheme.eligibility, false);
    final eligMr = SchemeModel.extractLocalized(scheme.eligibility, true);

    final benEn = SchemeModel.extractLocalized(scheme.benefits, false);
    final benMr = SchemeModel.extractLocalized(scheme.benefits, true);

    final docEn = SchemeModel.extractLocalized(scheme.documents, false);
    final docMr = SchemeModel.extractLocalized(scheme.documents, true);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    nameEn,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.brand700,
                    ),
                  ),
                  if (nameMr.isNotEmpty && nameMr != nameEn) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      nameMr,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand600,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: WebReportTheme.brand50,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      scheme.category.isNotEmpty ? scheme.category : 'Government Scheme',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Description Box
            _buildFlyerSection(
              title: 'Description / माहिती',
              accentColor: WebReportTheme.brand600,
              contentEn: descEn,
              contentMr: descMr,
            ),
            pw.SizedBox(height: 12),

            // Eligibility Box
            _buildFlyerSection(
              title: 'Eligibility / पात्रता',
              accentColor: PdfColors.green700,
              contentEn: eligEn,
              contentMr: eligMr,
            ),
            pw.SizedBox(height: 12),

            // Benefits Box
            _buildFlyerSection(
              title: 'Benefits / फायदे',
              accentColor: PdfColors.amber700,
              contentEn: benEn,
              contentMr: benMr,
            ),
            pw.SizedBox(height: 12),

            // Required Documents Box
            _buildFlyerSection(
              title: 'Required Documents / आवश्यक कागदपत्रे',
              accentColor: PdfColors.purple700,
              contentEn: docEn,
              contentMr: docMr,
            ),
          ];
        },
      ),
    );

    final fileName = 'Scheme_${scheme.id}_Flyer';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: isMarathi ? (nameMr.isNotEmpty ? nameMr : nameEn) : nameEn,
        subtitle: 'Scheme Guide & Eligibility Slip',
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

  /// Beneficiary / Applications List PDF Report
  static Future<void> generateAndPrintBeneficiaryReport({
    BuildContext? context,
    required List<SchemeApplicationModel> applications,
    bool isMarathi = false,
    String? lang,
  }) async {
    final effectiveLang = lang ?? (isMarathi ? 'mr' : 'en');
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final total = applications.length;
    final approved = applications.where((a) => a.isApproved).length;
    final pending = applications.where((a) => a.isPending).length;
    final rejected = applications.where((a) => a.isRejected).length;

    final title = effectiveLang == 'mr'
        ? 'शासकीय योजना'
        : (effectiveLang == 'hi' ? 'सरकारी योजनाएं' : 'Government Schemes');
    final subtitle = effectiveLang == 'mr'
        ? 'अर्ज व लाभार्थी अहवाल'
        : (effectiveLang == 'hi' ? 'आवेदन व लाभार्थी रिपोर्ट' : 'Application & Beneficiary Dossier');
    final contTitle = effectiveLang == 'mr'
        ? 'योजना लाभार्थी (पुढे चालू)'
        : (effectiveLang == 'hi' ? 'योजना लाभार्थी (आगे जारी)' : 'Scheme Beneficiaries (Continued)');
    final totalAppsLabel = effectiveLang == 'mr'
        ? 'एकूण अर्ज'
        : (effectiveLang == 'hi' ? 'कुल आवेदन' : 'Total Applications');
    final approvedLabel = AppTranslations.getStatus('Approved', effectiveLang);
    final pendingLabel = AppTranslations.getStatus('Pending', effectiveLang);
    final rejectedLabel = AppTranslations.getStatus('Rejected', effectiveLang);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: contTitle,
            lang: effectiveLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: effectiveLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: title,
              subtitle: subtitle,
              metaLines: [
                '${effectiveLang == 'mr' ? 'तारीख' : (effectiveLang == 'hi' ? 'दिनांक' : 'Date')}: $nowStr',
                '$totalAppsLabel: $total',
              ],
              lang: effectiveLang,
            ),
            pw.SizedBox(height: 12),

            // Overview summary bar
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem(totalAppsLabel, '$total'),
                  _buildSummaryItem(approvedLabel, '$approved', highlightColor: PdfColors.green700),
                  _buildSummaryItem(pendingLabel, '$pending', highlightColor: PdfColors.amber800),
                  _buildSummaryItem(rejectedLabel, '$rejected', highlightColor: PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (applications.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  effectiveLang == 'mr'
                      ? 'निवडलेल्या दृश्यासाठी कोणतीही योजना अर्ज नोंद आढळली नाही.'
                      : (effectiveLang == 'hi' ? 'चयनित दृश्य के लिए कोई योजना आवेदन रिकॉर्ड नहीं मिला।' : 'No scheme application records found for the selected view.'),
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
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
                  1: pw.FlexColumnWidth(2.0),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(2.6),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.2),
                  6: pw.FlexColumnWidth(2.2),
                },
                headers: [
                  '#',
                  effectiveLang == 'mr' ? 'अर्जदाराचे नाव' : (effectiveLang == 'hi' ? 'आवेदक का नाम' : 'Applicant Name'),
                  effectiveLang == 'mr' ? 'मोबाईल / पत्ता' : (effectiveLang == 'hi' ? 'मोबाइल / पता' : 'Mobile / Address'),
                  AppTranslations.getReportColumn('scheme_name', effectiveLang),
                  AppTranslations.getReportColumn('date', effectiveLang),
                  AppTranslations.getReportColumn('status', effectiveLang),
                  effectiveLang == 'mr' ? 'लाभ / कारण' : (effectiveLang == 'hi' ? 'लाभ / कारण' : 'Benefit / Reason'),
                ],
                data: List.generate(applications.length, (index) {
                  final app = applications[index];
                  final contactPart = [app.mobile, app.address].where((s) => s.isNotEmpty).join('\n');
                  final dateStr = DateFormat('dd/MM/yyyy').format(app.createdAt);
                  final notePart = app.isRejected
                      ? (app.rejectionReason ?? '-')
                      : (app.benefit ?? '-');

                  return [
                    '${index + 1}',
                    app.applicantName,
                    contactPart,
                    app.schemeName ?? '-',
                    dateStr,
                    AppTranslations.getStatus(app.status, effectiveLang),
                    notePart,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Scheme_Applications_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: isMarathi ? 'योजना अर्ज व लाभार्थी अहवाल' : 'Scheme Applications Report',
        subtitle: 'Beneficiary & Application Audit',
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

  static pw.Widget _buildFlyerSection({
    required String title,
    required PdfColor accentColor,
    required String contentEn,
    required String contentMr,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: WebReportTheme.slate50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border(
          left: pw.BorderSide(color: accentColor, width: 3),
          top: const pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
          right: const pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
          bottom: const pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: WebReportTheme.slate800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('English', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500)),
                    pw.SizedBox(height: 2),
                    pw.Text(contentEn.isNotEmpty ? contentEn : '-', style: const pw.TextStyle(fontSize: 9, color: WebReportTheme.slate700)),
                  ],
                ),
              ),
              if (contentMr.isNotEmpty && contentMr != contentEn) ...[
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('मराठी', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500)),
                      pw.SizedBox(height: 2),
                      pw.Text(contentMr, style: const pw.TextStyle(fontSize: 9, color: WebReportTheme.slate700)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
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
