import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/visitor_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Visitor Log Report Generator matching Nagarsevak-Managment
/// (VisitorReportGenerator.tsx).
class VisitorReportGenerator {
  VisitorReportGenerator._();

  static Future<void> generateAndPrintListReport({
    BuildContext? context,
    required List<VisitorModel> visitors,
    String? filterTitle,
    String title = 'Visitor Log Report',
    String subtitle = 'Visitor Records Report',
    String lang = 'en',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final total = visitors.length;

    final resolvedTitle = (title == 'Visitor Log Report')
        ? (lang == 'mr'
            ? 'कार्यालय भेट नोंदवही अहवाल'
            : (lang == 'hi' ? 'कार्यालय आगंतुक लॉग रिपोर्ट' : title))
        : title;
    final resolvedSubtitle = (subtitle == 'Visitor Records Report')
        ? (lang == 'mr'
            ? 'प्रभाग कार्यालय नागरिक व शिष्टमंडळ भेट नोंद'
            : (lang == 'hi' ? 'वार्ड कार्यालय नागरिक एवं शिष्टमंडल भेंट रिकॉर्ड' : subtitle))
        : subtitle;

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
              columnWidths: const {
                0: pw.FlexColumnWidth(1.5), // Date & Time (15%)
                1: pw.FlexColumnWidth(2.0), // Full Name (20%)
                2: pw.FlexColumnWidth(1.5), // Mobile (15%)
                3: pw.FlexColumnWidth(2.0), // Area (20%)
                4: pw.FlexColumnWidth(1.5), // Purpose (15%)
                5: pw.FlexColumnWidth(1.5), // Reference (15%)
              },
              headers: [
                AppTranslations.getReportColumn('date_time', lang),
                AppTranslations.getReportColumn('name', lang),
                AppTranslations.getReportColumn('mobile', lang),
                AppTranslations.getReportColumn('area', lang),
                lang == 'mr' ? 'उद्दिष्ट' : (lang == 'hi' ? 'उद्देश्य' : 'Purpose'),
                lang == 'mr' ? 'संदर्भ' : (lang == 'hi' ? 'संदर्भ' : 'Reference'),
              ],
              data: visitors.map((v) {
                final dateStr = DateFormat('dd/MM/yyyy').format(v.visitDate);
                final timeStr = DateFormat('hh:mm a').format(v.visitDate);

                return [
                  '$dateStr\n$timeStr',
                  v.name,
                  v.mobile.isNotEmpty ? v.mobile : '-',
                  v.area ?? '-',
                  v.purpose,
                  v.reference ?? '-',
                ];
              }).toList(),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerLeft,
              },
            ),
          ];
        },
      ),
    );

    final fileName = 'Visitor_Log_Report_${DateFormat('yyyy-MM-dd').format(now)}';
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

  /// Generates and prints single visitor pass / gate slip
  static Future<void> generateAndPrintVisitorSlip(
    VisitorModel visitor, {
    BuildContext? context,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Nagarsevak Office Management System',
                          style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate500),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'VISITOR ENTRY PASS',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: WebReportTheme.brand50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
                      ),
                      child: pw.Text(
                        'PASS #${visitor.id.length >= 6 ? visitor.id.substring(0, 6).toUpperCase() : visitor.id}',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('VISITOR NAME', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                            pw.SizedBox(height: 2),
                            pw.Text(visitor.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('CONTACT NUMBER', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                            pw.SizedBox(height: 2),
                            pw.Text(visitor.mobile, style: const pw.TextStyle(fontSize: 10, color: WebReportTheme.slate800)),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: WebReportTheme.slate200, thickness: 0.5),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('PURPOSE OF VISIT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                              pw.SizedBox(height: 2),
                              pw.Text(visitor.purpose, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('AREA / LOCALITY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700)),
                              pw.SizedBox(height: 2),
                              pw.Text(visitor.area ?? 'Prabhag 12', style: const pw.TextStyle(fontSize: 9.5, color: WebReportTheme.slate800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (visitor.reference != null && visitor.reference!.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Text('REFERENCE: ${visitor.reference}', style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600)),
                    ],
                  ],
                ),
              ),

              pw.Spacer(),

              // Signature strip
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Security / Desk In-Charge', style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate500)),
                      pw.SizedBox(height: 20),
                      pw.Container(width: 100, height: 1, color: WebReportTheme.slate400),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Officer / PA Signature', style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate500)),
                      pw.SizedBox(height: 20),
                      pw.Container(width: 100, height: 1, color: WebReportTheme.slate400),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: WebReportTheme.slate100, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Generated by Nagarsevak Management System', style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: WebReportTheme.slate400)),
                    pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 7, color: WebReportTheme.slate400)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final fileName = 'Visitor_Pass_${visitor.id}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Visitor Entry Pass',
        subtitle: 'Pass #${visitor.id.length >= 6 ? visitor.id.substring(0, 6).toUpperCase() : visitor.id}',
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
