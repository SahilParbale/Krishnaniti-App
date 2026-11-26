import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/letter_model.dart';
import '../../../core/localization/app_translations.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Letter Registry & Documentation Report Generator matching Nagarsevak-Managment
/// (LetterReportGenerator.tsx).
class LetterReportGenerator {
  LetterReportGenerator._();

  static Future<void> generateAndPrintLetterReport({
    BuildContext? context,
    required List<LetterModel> letters,
    String? statusFilter,
    String? typeFilter,
    String? areaFilter,
    String? title,
    String? subtitle,
    String lang = 'en',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final total = letters.length;

    final resolvedTitle = title ??
        (lang == 'mr'
            ? 'पत्र नोंदवही अहवाल'
            : (lang == 'hi' ? 'पत्र रजिस्टर रिपोर्ट' : 'Letters Register Report'));
    final resolvedSubtitle = subtitle ??
        (lang == 'mr'
            ? 'आवक आणि जावक अधिकृत पत्र नोंदवही'
            : (lang == 'hi' ? 'आवक और जावक आधिकारिक पत्र रजिस्टर' : 'Inward & Outward Letters Official Register'));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: resolvedTitle,
              lang: lang,
            );
          }
          return WebReportTheme.buildHeader(
            title: resolvedTitle,
            subtitle: resolvedSubtitle,
            dateFormatted: formattedDate,
            totalCount: total,
            foundLabel: lang == 'mr' ? 'एकूण आढळले' : (lang == 'hi' ? 'कुल मिले' : 'Found'),
            lang: lang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: lang),
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              border: WebReportTheme.tableBorder,
              headerStyle: WebReportTheme.tableHeaderStyle,
              headerDecoration: WebReportTheme.tableHeaderDecoration,
              headerHeight: 22,
              cellHeight: 20,
              cellStyle: WebReportTheme.tableCellStyle,
              headerCount: 1,
              oddRowDecoration: WebReportTheme.oddRowDecoration,
              headers: [
                '#',
                lang == 'mr' ? 'संदर्भ / दिनांक' : (lang == 'hi' ? 'संदर्भ / दिनांक' : 'Ref / Date'),
                lang == 'mr' ? 'प्रवाह' : (lang == 'hi' ? 'प्रवाह' : 'Flow'),
                AppTranslations.getReportColumn('citizen', lang),
                AppTranslations.getReportColumn('subject', lang),
                AppTranslations.getReportColumn('area', lang),
                AppTranslations.getReportColumn('status', lang),
              ],
              columnWidths: const {
                0: pw.FixedColumnWidth(22),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(1.0),
                3: pw.FlexColumnWidth(1.8),
                4: pw.FlexColumnWidth(2.2),
                5: pw.FlexColumnWidth(1.4),
                6: pw.FlexColumnWidth(1.0),
              },
              data: List.generate(letters.length, (index) {
                final l = letters[index];
                final dateStr = DateFormat('dd/MM/yyyy').format(l.receivedDate ?? l.createdAt);
                final refNo = l.details['letter_ref']?.toString() ?? (l.id.length >= 8 ? l.id.substring(0, 8).toUpperCase() : l.id);
                final flow = l.isIncoming
                    ? (lang == 'mr' ? 'आवक' : (lang == 'hi' ? 'आवक' : 'INWARD'))
                    : (lang == 'mr' ? 'जावक' : (lang == 'hi' ? 'जावक' : 'OUTWARD'));
                final recipient = l.isIncoming ? (l.sender ?? l.citizenName) : l.citizenName;
                final typeSubject = '${l.letterType ?? l.title}\n${l.subject}';
                final area = l.area ?? 'Prabhag 12';
                return [
                  '${index + 1}',
                  '$refNo\n$dateStr',
                  flow,
                  recipient,
                  typeSubject,
                  area,
                  AppTranslations.getStatus(l.status, lang),
                ];
              }),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerLeft,
                6: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    final fileName = 'Letters_Register_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: resolvedTitle,
        subtitle: resolvedSubtitle,
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

  /// Generates and prints a single official letter / request docket (Portrait A4)
  static Future<void> generateAndPrintSingleLetter({
    BuildContext? context,
    required LetterModel letter,
    String? letterBody,
    String? nagarsevakName = 'Nagarsevak Office',
    String? wardName = 'Ward No. 12 (Prabhag 12)',
    String lang = 'en',
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy').format(letter.createdAt);
    final refNo = letter.id.length >= 8
        ? (letter.isIncoming ? 'INW-${letter.id.substring(0, 8).toUpperCase()}' : 'OUT-${letter.id.substring(0, 8).toUpperCase()}')
        : (letter.isIncoming ? 'INW-${letter.id}' : 'OUT-${letter.id}');

    final bodyText = letterBody ?? letter.description ?? letter.details['text']?.toString() ?? letter.details['details']?.toString() ?? 'Official letter representation recorded for civic administration and department follow-up.';

    final flowText = letter.isIncoming
        ? (lang == 'mr' ? 'आवक / प्राप्त' : (lang == 'hi' ? 'आवक / प्राप्त' : 'INWARD / RECEIVED'))
        : (lang == 'mr' ? 'जावक / पाठवले' : (lang == 'hi' ? 'जावक / भेजा गया' : 'OUTWARD / DISPATCHED'));
    final statusText = AppTranslations.getStatus(letter.status, lang);
    final fromLabel = letter.isIncoming
        ? (lang == 'mr' ? 'प्रेषक (पाठवणारा)' : (lang == 'hi' ? 'प्रेषक (भेजने वाला)' : 'FROM (SENDER)'))
        : (lang == 'mr' ? 'नागरिक / अर्जदार' : (lang == 'hi' ? 'नागरिक / आवेदक' : 'CITIZEN / APPLICANT'));
    final typeLabel = lang == 'mr' ? 'प्रकार आणि अधिकारक्षेत्र' : (lang == 'hi' ? 'प्रकार और अधिकार क्षेत्र' : 'TYPE & JURISDICTION');
    final subjectHeader = lang == 'mr' ? 'पत्राचा विषय आणि तपशील' : (lang == 'hi' ? 'पत्र विषय और विवरण' : 'LETTER SUBJECT & SUBMISSION DETAILS');

    pdf.addPage(
      pw.Page(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Office of Nagarsevak • $wardName',
                          style: const pw.TextStyle(fontSize: 9, color: WebReportTheme.slate500),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          letter.isIncoming
                              ? (lang == 'mr' ? 'आवक पत्र' : (lang == 'hi' ? 'आवक पत्र' : 'INWARD CORRESPONDENCE'))
                              : (lang == 'mr' ? 'जावक पत्र' : (lang == 'hi' ? 'जावक पत्र' : 'OUTWARD LETTER')),
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: WebReportTheme.brand700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Nagarsevak Office Management System',
                          style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate500),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: WebReportTheme.brand50,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
                          ),
                          child: pw.Text(
                            refNo,
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('${lang == 'mr' ? 'दिनांक' : (lang == 'hi' ? 'दिनांक' : 'Date')}: $dateStr', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Overview Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.slate50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: WebReportTheme.slate200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${lang == 'mr' ? 'प्रवाह' : (lang == 'hi' ? 'प्रवाह' : 'FLOW')}: $flowText', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700)),
                    pw.Text('${AppTranslations.getReportColumn('status', lang)}: $statusText', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Parties Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(fromLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                          pw.SizedBox(height: 4),
                          pw.Text(letter.isIncoming ? (letter.sender ?? letter.citizenName) : letter.citizenName, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                          pw.Text('${lang == 'mr' ? 'संपर्क' : (lang == 'hi' ? 'संपर्क' : 'Contact')}: ${letter.mobile.isNotEmpty ? letter.mobile : "-"}', style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(typeLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                          pw.SizedBox(height: 4),
                          pw.Text(letter.letterType ?? letter.title, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                          pw.Text('${AppTranslations.getReportColumn('area', lang)}: ${letter.area ?? "Prabhag 12"}', style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Letter Body Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(subjectHeader, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                    pw.SizedBox(height: 6),
                    pw.Text('${AppTranslations.getReportColumn('subject', lang)}: ${letter.subject}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                    pw.SizedBox(height: 6),
                    pw.Text(bodyText, style: const pw.TextStyle(fontSize: 9, lineSpacing: 2, color: WebReportTheme.slate800)),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer & Stamp
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: WebReportTheme.slate400),
                          borderRadius: pw.BorderRadius.circular(35),
                        ),
                        child: pw.Center(
                          child: pw.Text('[OFFICE\nSEAL]', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Prabhag 12 Office Stamp', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: WebReportTheme.slate700),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate800)),
                      pw.Text('Nagarsevak Secretariat • Pune', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: WebReportTheme.slate100, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Generated by Nagarsevak Management System', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: WebReportTheme.slate400)),
                    pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final fileName = 'Letter_${letter.id}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: letter.isIncoming ? 'Incoming Letter' : 'Outgoing Letter',
        subtitle: 'Ref: ${letter.id.length >= 8 ? letter.id.substring(0, 8).toUpperCase() : letter.id}',
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
