import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/gallery_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class GalleryReportGenerator {
  GalleryReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<GalleryItemModel> items,
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final totalItems = items.length;
    final eventCount = items.where((i) => i.category == GalleryCategory.event).length;
    final workCount = items.where((i) => i.category == GalleryCategory.work).length;
    final awardCount = items.where((i) => i.category == GalleryCategory.award).length;
    final campaignCount = items.where((i) => i.category == GalleryCategory.campaign).length;
    final totalViews = items.fold<int>(0, (sum, i) => sum + i.viewsCount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: 'Media Gallery & Photographic Archive',
            );
          }
          return WebReportTheme.buildHeader(
            title: 'Media Gallery & Archive',
            subtitle: 'Prabhag Ward 12 • High-Resolution Civic Photo & Event Media Register',
            dateFormatted: nowStr,
            totalCount: totalItems,
            foundLabel: 'Total Photos',
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
                  _statItem('Total Photos', '$totalItems'),
                  _statItem('Events', '$eventCount'),
                  _statItem('Development', '$workCount'),
                  _statItem('Awards', '$awardCount'),
                  _statItem('Campaigns', '$campaignCount'),
                  _statItem('Total Views', '$totalViews'),
                ],
              ),
            ),

            // Media Catalog Table
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
                1: pw.FixedColumnWidth(60),  // Date
                2: pw.FixedColumnWidth(65),  // Category
                3: pw.FlexColumnWidth(2.5),  // Title
                4: pw.FlexColumnWidth(1.8),  // Location
                5: pw.FlexColumnWidth(2.8),  // Description
                6: pw.FixedColumnWidth(40),  // Views
              },
              headers: [
                '#',
                'Date',
                'Category',
                'Photo Title & Event',
                'Location / Venue',
                'Description / Context',
                'Views',
              ],
              data: items.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                final dateFormatted = DateFormat('dd/MM/yyyy').format(item.date);
                return [
                  '$idx',
                  dateFormatted,
                  item.category.titleMr,
                  item.titleMr,
                  item.location,
                  item.descriptionMr,
                  '${item.viewsCount}',
                ];
              }).toList(),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
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

    final fileName = 'Prabhag_12_Media_Gallery_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Media Gallery Report',
        subtitle: 'Prabhag 12 Media Gallery & Public Campaign Assets',
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
