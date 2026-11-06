import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/ward_map_point_model.dart';

class WardMapReportGenerator {
  WardMapReportGenerator._();

  static Future<void> generateAndPrintWardMapReport({
    required List<WardMapPointModel> points,
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final total = points.length;
    final booths = points.where((p) => p.category.toLowerCase() == 'booth').length;
    final works = points.where((p) => p.category.toLowerCase() == 'civilworks').length;
    final amenities = points.where((p) => p.category.toLowerCase() == 'amenity').length;
    final problems = points.where((p) => p.category.toLowerCase() == 'problemspot').length;

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
                        'WARD GEOGRAPHIC & INFRASTRUCTURE DIRECTORY',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 - GIS Mapped Polling Booths, Civil Works, Amenities & Civic Hotspots',
                        style: const pw.TextStyle(
                          fontSize: 10,
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
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                      if (categoryFilter != null && categoryFilter != 'All')
                        pw.Text('Layer: $categoryFilter', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Summary Strip
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _statPill('Total Points', '$total', PdfColors.blue900),
                    _statPill('Electoral Booths', '$booths', PdfColors.blue800),
                    _statPill('Civil Works Sites', '$works', PdfColors.orange800),
                    _statPill('Civic Amenities', '$amenities', PdfColors.green800),
                    _statPill('Flagged Problem Spots', '$problems', PdfColors.red800),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Nagarsevak Ward GIS Geographic Management System',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26), // Sr
                1: const pw.FlexColumnWidth(2.8), // Location Title
                2: const pw.FlexColumnWidth(1.6), // Category
                3: const pw.FlexColumnWidth(3.0), // Address & Details
                4: const pw.FlexColumnWidth(1.6), // GPS Coordinates
                5: const pw.FlexColumnWidth(1.4), // Status
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _cellHeader('Sr', align: pw.TextAlign.center),
                    _cellHeader('Landmark / Location Title'),
                    _cellHeader('Category Layer'),
                    _cellHeader('Address & Infrastructure Scope'),
                    _cellHeader('GPS Coordinates'),
                    _cellHeader('Current Status'),
                  ],
                ),
                // Rows
                ...points.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final pt = entry.value;
                  final isEven = idx % 2 == 0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _cellText('$idx', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(pt.title, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            if (pt.description.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(pt.description, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700), maxLines: 2),
                            ],
                          ],
                        ),
                      ),
                      _cellText(pt.categoryDisplay),
                      _cellText(pt.address, maxLines: 3),
                      _cellText('${pt.latitude.toStringAsFixed(4)}, ${pt.longitude.toStringAsFixed(4)}'),
                      _cellText(pt.status ?? 'Active', isBold: true),
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
      name: 'Ward_Map_Directory_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _statPill(String label, String val, PdfColor col) {
    return pw.Row(
      children: [
        pw.Text('$label: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.Text(val, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: col)),
      ],
    );
  }

  static pw.Widget _cellHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.blue900),
      ),
    );
  }

  static pw.Widget _cellText(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false, int? maxLines}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }
}

