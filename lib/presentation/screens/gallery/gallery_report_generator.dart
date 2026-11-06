import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/gallery_model.dart';

class GalleryReportGenerator {
  GalleryReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<GalleryItemModel> items,
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalItems = items.length;
    final eventCount = items.where((i) => i.category == GalleryCategory.event).length;
    final workCount = items.where((i) => i.category == GalleryCategory.work).length;
    final awardCount = items.where((i) => i.category == GalleryCategory.award).length;
    final campaignCount = items.where((i) => i.category == GalleryCategory.campaign).length;
    final totalViews = items.fold<int>(0, (sum, i) => sum + i.viewsCount);

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
                        'PUNE MUNICIPAL CORPORATION - PUBLIC RELATIONS & MEDIA ARCHIVE CELL',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Prabhag Ward 12 (Kasba-Vishrambaug Wada) • High-Resolution Civic Photo & Event Media Register',
                        style: const pw.TextStyle(
                          fontSize: 9,
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
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
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
                    'Office of Corporator Amit Chougale • Prabhag 12 • Official Civic Photographic Record',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Nagarsevak Mobile Media Suite',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
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
                _buildKpiCard('TOTAL PHOTOS', '$totalItems', 'Media Archive', PdfColors.blue900, PdfColors.blue50),
                pw.SizedBox(width: 8),
                _buildKpiCard('EVENTS', '$eventCount', 'Ceremonies & Gatherings', PdfColors.purple900, PdfColors.purple50),
                pw.SizedBox(width: 8),
                _buildKpiCard('DEVELOPMENT', '$workCount', 'Civic Projects', PdfColors.cyan900, PdfColors.cyan50),
                pw.SizedBox(width: 8),
                _buildKpiCard('AWARDS', '$awardCount', 'Honors & Citations', PdfColors.amber900, PdfColors.amber50),
                pw.SizedBox(width: 8),
                _buildKpiCard('CAMPAIGNS', '$campaignCount', 'Public Outreach', PdfColors.green900, PdfColors.green50),
                pw.SizedBox(width: 8),
                _buildKpiCard('TOTAL VIEWS', '$totalViews', 'Citizen Impressions', PdfColors.blueGrey900, PdfColors.blueGrey50),
              ],
            ),

            pw.SizedBox(height: 14),

            // Media Catalog Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(25),  // Sr
                1: pw.FlexColumnWidth(1.2), // Date
                2: pw.FlexColumnWidth(1.2), // Category
                3: pw.FlexColumnWidth(2.6), // Title
                4: pw.FlexColumnWidth(1.6), // Location
                5: pw.FlexColumnWidth(3.4), // Description
                6: pw.FixedColumnWidth(45), // Views
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeaderCell('#'),
                    _tableHeaderCell('Date'),
                    _tableHeaderCell('Category'),
                    _tableHeaderCell('Photo Title & Event'),
                    _tableHeaderCell('Location / Venue'),
                    _tableHeaderCell('Description / Context'),
                    _tableHeaderCell('Views'),
                  ],
                ),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final bg = entry.key % 2 == 0 ? PdfColors.white : PdfColors.grey100;
                  final dateFormatted = DateFormat('dd MMM yyyy').format(item.date);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _tableDataCell('$idx', align: pw.TextAlign.center),
                      _tableDataCell(dateFormatted, align: pw.TextAlign.center),
                      _tableCategoryCell(item.category),
                      _tableDataCell(item.titleMr, isBold: true),
                      _tableDataCell(item.location),
                      _tableDataCell(item.descriptionMr),
                      _tableDataCell('${item.viewsCount}', align: pw.TextAlign.center),
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
      name: 'Prabhag_12_Media_Gallery_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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

  static pw.Widget _tableCategoryCell(GalleryCategory category) {
    PdfColor color = PdfColors.blue800;
    PdfColor bg = PdfColors.blue50;

    switch (category) {
      case GalleryCategory.event:
        color = PdfColors.purple800;
        bg = PdfColors.purple50;
        break;
      case GalleryCategory.work:
        color = PdfColors.blue800;
        bg = PdfColors.blue50;
        break;
      case GalleryCategory.award:
        color = PdfColors.amber800;
        bg = PdfColors.amber50;
        break;
      case GalleryCategory.campaign:
        color = PdfColors.green800;
        bg = PdfColors.green50;
        break;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: bg,
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border.all(color: color, width: 0.5),
          ),
          child: pw.Text(
            category.titleMr,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }
}

