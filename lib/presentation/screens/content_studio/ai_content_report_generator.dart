import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/ai_content_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class AiContentReportGenerator {
  AiContentReportGenerator._();

  /// Generates a single official letterhead document (Speech, Press Release, Letter, etc.)
  static Future<void> printDocument(
    AiContentHistoryItem item, {
    BuildContext? context,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy').format(item.createdAt);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: item.contentType.titleEn.toUpperCase(),
            );
          }
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildLetterhead(item),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return WebReportTheme.buildFooter(context);
        },
        build: (pw.Context context) {
          return [
            // Document Metadata Strip
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const pw.BoxDecoration(
                color: WebReportTheme.slate50,
                border: pw.Border(
                  left: pw.BorderSide(color: WebReportTheme.brand600, width: 3),
                  top: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                  right: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                  bottom: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Ref: PMC/W12/CS/${item.id.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Type: ${item.contentType.titleEn} (${item.contentType.titleMr}) • Tone: ${item.tone.titleEn}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: WebReportTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: $dateStr',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Language: ${item.language.label}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: WebReportTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Title / Subject Banner
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.brand50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SUBJECT / TOPIC:',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.brand700,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    item.title,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.slate900,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Content Body
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
              ),
              child: pw.Text(
                item.generatedContent,
                style: const pw.TextStyle(
                  fontSize: 10,
                  lineSpacing: 4,
                  color: WebReportTheme.slate800,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            // Footer & Official Sign Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Words: ${item.wordCount} | Est. Reading Time: ${item.readingTimeFormatted}',
                      style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Generated via PMC Nagar Sevak AI Content Studio',
                      style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate400),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 140,
                      padding: const pw.EdgeInsets.only(top: 20),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: WebReportTheme.slate400, width: 0.8)),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'AMIT CHOUGALE',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Corporator (Nagarsevak) • Ward 12',
                            style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate600),
                          ),
                          pw.Text(
                            'Pune Municipal Corporation',
                            style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final fileName = 'Content_${item.contentType.id}_${item.id}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: item.contentType.titleEn,
        subtitle: item.title,
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

  /// Generates a comprehensive summary dossier of all generated AI content
  static Future<void> generateDossier({
    BuildContext? context,
    required List<AiContentHistoryItem> items,
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final speechCount = items.where((i) => i.contentType == AiContentType.speech).length;
    final captionCount = items.where((i) => i.contentType == AiContentType.socialMediaCaption).length;
    final noticeCount = items.where((i) => i.contentType == AiContentType.letterNotice).length;
    final pressCount = items.where((i) => i.contentType == AiContentType.pressRelease).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: 'AI Content Studio Dossier',
            );
          }
          return WebReportTheme.buildHeader(
            title: 'AI Content Studio Dossier',
            subtitle: 'Speeches, Notices, Press Releases & Citizen Outreach',
            dateFormatted: nowStr,
            totalCount: items.length,
            foundLabel: 'Total Drafts',
          );
        },
        footer: (pw.Context context) {
          return WebReportTheme.buildFooter(context);
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 14),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Total', '${items.length}'),
                  _statItem('Speeches', '$speechCount'),
                  _statItem('Social Captions', '$captionCount'),
                  _statItem('Notices', '$noticeCount'),
                  _statItem('Press Releases', '$pressCount'),
                ],
              ),
            ),

            // Content Table
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
                0: pw.FixedColumnWidth(24),  // Sr
                1: pw.FixedColumnWidth(55),  // Date
                2: pw.FixedColumnWidth(70),  // Type
                3: pw.FixedColumnWidth(60),  // Tone / Lang
                4: pw.FlexColumnWidth(2.5),  // Topic
                5: pw.FlexColumnWidth(3.5),  // Content Excerpt
                6: pw.FixedColumnWidth(36),  // Words
              },
              headers: ['#', 'Date', 'Type', 'Tone / Lang', 'Topic / Context', 'Generated Content Excerpt', 'Words'],
              data: items.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                final dateFormatted = DateFormat('dd/MM/yy').format(item.createdAt);
                final excerpt = item.generatedContent.replaceAll('\n', ' ').trim();
                return [
                  '$idx',
                  dateFormatted,
                  item.contentType.titleEn,
                  '${item.tone.titleEn}\n${item.language.id.toUpperCase()}',
                  item.title,
                  excerpt.length > 130 ? '${excerpt.substring(0, 130)}...' : excerpt,
                  '${item.wordCount}',
                ];
              }).toList(),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
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

    final fileName = 'AI_Content_Dossier_Ward12_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'AI Content Dossier',
        subtitle: 'Official Archive of Speeches, Press Releases & Social Media Content',
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

  static pw.Widget _buildLetterhead(AiContentHistoryItem item) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Office: Nagarsevak Amit Chougale',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: WebReportTheme.brand700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Ward No. 12 (Kasba-Vishrambaug Wada) • Pune Municipal Corporation',
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: WebReportTheme.slate600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Public Relations Office: 1002, Shaniwar Peth, Pune - 411 030 | Phone: 020-25501234',
                style: const pw.TextStyle(fontSize: 7.5, color: WebReportTheme.slate400),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              color: WebReportTheme.brand50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'OFFICIAL DRAFT',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: WebReportTheme.brand700,
                  ),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  item.contentType.id.toUpperCase(),
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: WebReportTheme.slate600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _statItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: WebReportTheme.brand700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 7.5,
            color: WebReportTheme.slate600,
          ),
        ),
      ],
    );
  }
}
