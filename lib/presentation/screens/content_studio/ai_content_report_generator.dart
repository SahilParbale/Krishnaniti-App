import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/ai_content_model.dart';

class AiContentReportGenerator {
  AiContentReportGenerator._();

  /// Generates a single official letterhead document (Speech, Press Release, Letter, etc.)
  static Future<void> printDocument(AiContentHistoryItem item) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy').format(item.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Letterhead
              _buildLetterhead(item),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1.5, color: PdfColors.blue800),
              pw.SizedBox(height: 12),

              // Document Metadata Strip
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Ref: PMC/W12/CS/${item.id.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Type: ${item.contentType.titleEn} (${item.contentType.titleMr}) • Tone: ${item.tone.titleEn}',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey600,
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
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Language: ${item.language.label}',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Title / Subject Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue300, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SUBJECT / TOPIC:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      item.title,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Content Body
              pw.Expanded(
                child: pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                  ),
                  child: pw.Text(
                    item.generatedContent,
                    style: const pw.TextStyle(
                      fontSize: 10.5,
                      lineSpacing: 4.5,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

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
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Generated via PMC Nagar Sevak AI Content Studio',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 140,
                        padding: const pw.EdgeInsets.only(top: 24),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500, width: 0.8)),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'AMIT CHOUGALE',
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Corporator (Nagarsevak) • Ward 12',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                            pw.Text(
                              'Pune Municipal Corporation',
                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Content_${item.contentType.id}_${item.id}.pdf',
    );
  }

  /// Generates a comprehensive summary dossier of all generated AI content
  static Future<void> generateDossier({
    required List<AiContentHistoryItem> items,
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final speechCount = items.where((i) => i.contentType == AiContentType.speech).length;
    final captionCount = items.where((i) => i.contentType == AiContentType.socialMediaCaption).length;
    final noticeCount = items.where((i) => i.contentType == AiContentType.letterNotice).length;
    final pressCount = items.where((i) => i.contentType == AiContentType.pressRelease).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - CORPORATOR MEDIA & PUBLICITY CELL',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 • AI Content Studio Official Dossier (Speeches, Notices & Media Releases)',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated: $nowStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.blue800),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Office of Corporator Amit Chougale • Ward 12 (Kasba-Vishrambaug Wada) • Confidential Civic Archive',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Nagarsevak Mobile AI Suite',
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Row(
              children: [
                _buildKpiCard('TOTAL DRAFTS', '${items.length}', 'Speeches, Notices & Posts', PdfColors.blue900, PdfColors.blue50),
                pw.SizedBox(width: 8),
                _buildKpiCard('SPEECHES', '$speechCount', 'Public & Council Addresses', PdfColors.purple900, PdfColors.purple50),
                pw.SizedBox(width: 8),
                _buildKpiCard('SOCIAL CAPTIONS', '$captionCount', 'Citizen Outreach Posts', PdfColors.cyan900, PdfColors.cyan50),
                pw.SizedBox(width: 8),
                _buildKpiCard('NOTICES & LETTERS', '$noticeCount', 'Official Civic Alerts', PdfColors.amber900, PdfColors.amber50),
                pw.SizedBox(width: 8),
                _buildKpiCard('PRESS RELEASES', '$pressCount', 'Journalist Briefings', PdfColors.teal900, PdfColors.teal50),
              ],
            ),

            pw.SizedBox(height: 14),

            // Content Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(30),  // Sr
                1: pw.FlexColumnWidth(1.2), // Date
                2: pw.FlexColumnWidth(1.0), // Type
                3: pw.FlexColumnWidth(0.9), // Tone & Lang
                4: pw.FlexColumnWidth(2.5), // Subject / Topic
                5: pw.FlexColumnWidth(3.8), // Content Excerpt
                6: pw.FixedColumnWidth(40), // Words
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeaderCell('#'),
                    _tableHeaderCell('Date'),
                    _tableHeaderCell('Type'),
                    _tableHeaderCell('Tone / Lang'),
                    _tableHeaderCell('Topic / Context'),
                    _tableHeaderCell('Generated Content Excerpt'),
                    _tableHeaderCell('Words'),
                  ],
                ),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final bg = entry.key % 2 == 0 ? PdfColors.white : PdfColors.grey100;
                  final dateFormatted = DateFormat('dd/MM/yy').format(item.createdAt);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _tableDataCell('$idx', align: pw.TextAlign.center),
                      _tableDataCell(dateFormatted, align: pw.TextAlign.center),
                      _tableTypeCell(item.contentType),
                      _tableDataCell('${item.tone.titleEn}\n${item.language.id}', align: pw.TextAlign.center),
                      _tableDataCell(item.title, isBold: true),
                      _tableDataCell(
                        item.generatedContent.replaceAll('\n', ' ').length > 180
                            ? '${item.generatedContent.replaceAll('\n', ' ').substring(0, 180)}...'
                            : item.generatedContent.replaceAll('\n', ' '),
                      ),
                      _tableDataCell('${item.wordCount}', align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'AI_Content_Dossier_Ward12_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildLetterhead(AiContentHistoryItem item) {
    return pw.Row(
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
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Ward No. 12 (Kasba-Vishrambaug Wada) • Pune Municipal Corporation',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Public Relations Office: 1002, Shaniwar Peth, Pune - 411 030 | Phone: 020-25501234',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue900,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'OFFICIAL DRAFT',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                item.contentType.id.toUpperCase(),
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.amber300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildKpiCard(String title, String value, String subtitle, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 7.5, color: textColor, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textColor)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableDataCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _tableTypeCell(AiContentType type) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border.all(color: PdfColors.blue800, width: 0.5),
          ),
          child: pw.Text(
            type.titleEn,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
        ),
      ),
    );
  }
}

