import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/ward_map_point_model.dart';
import '../../widgets/app_pdf_report_theme.dart';

class WardMapReportGenerator {
  WardMapReportGenerator._();

  static Future<void> generateAndPrintWardMapReport({
    required List<WardMapPointModel> points,
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final total = points.length;
    final booths = points.where((p) => p.category.toLowerCase() == 'booth').length;
    final works = points.where((p) => p.category.toLowerCase() == 'civilworks').length;
    final amenities = points.where((p) => p.category.toLowerCase() == 'amenity').length;
    final problems = points.where((p) => p.category.toLowerCase() == 'problemspot').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: 'Ward GIS Directory',
            );
          }
          return WebReportTheme.buildHeader(
            title: 'Ward Geographic & GIS Directory',
            subtitle: 'Prabhag Ward 12 • GIS Mapped Polling Booths, Civil Works & Civic Hotspots',
            dateFormatted: nowStr,
            totalCount: total,
            foundLabel: 'Total Points',
            metaLines: (categoryFilter != null && categoryFilter != 'All')
                ? [
                    'Date: $nowStr',
                    'Layer: $categoryFilter',
                    'Total Points: $total',
                  ]
                : null,
          );
        },
        footer: (pw.Context context) {
          return WebReportTheme.buildFooter(context);
        },
        build: (pw.Context context) {
          return [
            // Summary Strip
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
                  _statItem('Total Points', '$total'),
                  _statItem('Electoral Booths', '$booths'),
                  _statItem('Civil Works Sites', '$works'),
                  _statItem('Civic Amenities', '$amenities'),
                  _statItem('Civic Hotspots', '$problems'),
                ],
              ),
            ),

            // Table of Points
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
                1: pw.FlexColumnWidth(2.5),  // Location Title
                2: pw.FixedColumnWidth(75),  // Category
                3: pw.FlexColumnWidth(2.6),  // Address & Details
                4: pw.FixedColumnWidth(85),  // GPS Coordinates
                5: pw.FixedColumnWidth(55),  // Status
              },
              headers: [
                '#',
                'Landmark / Location Title',
                'Category Layer',
                'Address & Scope',
                'GPS Coordinates',
                'Current Status',
              ],
              data: points.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final pt = entry.value;
                final titleDesc = pt.description.isNotEmpty
                    ? '${pt.title}\n${pt.description}'
                    : pt.title;
                return [
                  '$idx',
                  titleDesc,
                  pt.categoryDisplay,
                  pt.address,
                  '${pt.latitude.toStringAsFixed(4)}, ${pt.longitude.toStringAsFixed(4)}',
                  (pt.status ?? 'Active').toUpperCase(),
                ];
              }).toList(),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
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
