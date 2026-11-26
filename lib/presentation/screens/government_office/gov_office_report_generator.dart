import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/government_office_model.dart';
import '../../../data/models/work_tracker_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class GovOfficeReportGenerator {
  GovOfficeReportGenerator._();

  static Future<void> generateAndPrintOfficeReport({
    BuildContext? context,
    required List<GovernmentOfficeModel> offices,
    String? categoryFilter,
    String? areaFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final totalCount = offices.length;
    final emergencyCount = offices.where((o) => o.isEmergency).length;
    final municipalCount = offices.where((o) => o.category.toLowerCase().contains('municipal')).length;
    final policeCount = offices.where((o) => o.category.toLowerCase().contains('police')).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Government Offices Directory (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Government Offices',
              subtitle: 'Directory of Key Government Departments & Administrative Officers',
              metaLines: [
                'Date: $nowStr',
                'Count: $totalCount',
                if (categoryFilter != null && categoryFilter != 'All') 'Category: $categoryFilter',
                if (areaFilter != null && areaFilter != 'All') 'Area: $areaFilter',
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary strip
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Authorities', '$totalCount'),
                  _buildSummaryItem('Emergency 24x7', '$emergencyCount', highlightColor: PdfColors.red700),
                  _buildSummaryItem('Municipal Centers', '$municipalCount', highlightColor: WebReportTheme.brand700),
                  _buildSummaryItem('Police / Security', '$policeCount'),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (offices.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No government office records found for the selected view.',
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
                  1: pw.FlexColumnWidth(3.0),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(2.0),
                  4: pw.FlexColumnWidth(2.5),
                },
                headers: const [
                  '#',
                  'Office / Department',
                  'Officer Name',
                  'Contact Number',
                  'Address & Area',
                ],
                data: List.generate(offices.length, (index) {
                  final item = offices[index];
                  final emergencyBadge = item.isEmergency ? ' [Emergency]' : '';
                  final contacts = [item.contactNumber, item.secondaryContact]
                      .where((s) => s != null && s.isNotEmpty)
                      .join('\n');
                  final addressPart = [item.address, item.area].where((s) => s.isNotEmpty).join('\nArea: ');

                  return [
                    '${index + 1}',
                    '${item.name}$emergencyBadge',
                    item.officerName.isNotEmpty ? item.officerName : '-',
                    contacts.isNotEmpty ? contacts : '-',
                    addressPart.isNotEmpty ? addressPart : '-',
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Government_Offices_Directory_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Government Offices',
        subtitle: 'Directory of Key Government Departments & Administrative Officers',
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

  /// Official File Tracker & Departmental Work Movement Report
  static Future<void> generateAndPrintFileTrackerReport({
    BuildContext? context,
    required List<WorkTrackerModel> trackers,
    String? statusFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final totalCount = trackers.length;
    final inProcessCount = trackers
        .where((t) => t.currentStatus.toLowerCase().contains('process') || t.currentStatus.toLowerCase().contains('pending'))
        .length;
    final completedCount = trackers
        .where((t) =>
            t.currentStatus.toLowerCase().contains('complete') ||
            t.currentStatus.toLowerCase().contains('dispatched') ||
            t.currentStatus.toLowerCase().contains('approved'))
        .length;
    final actionRequiredCount = trackers
        .where((t) => t.currentStatus.toLowerCase().contains('action') || t.currentStatus.toLowerCase().contains('review'))
        .length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(WebReportTheme.marginPt),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: 'Municipal File Tracker (Continued)',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: 'Municipal File Tracker',
              subtitle: 'Department Inward/Outward Document Progression & Approval Dossier',
              metaLines: [
                'Date: $nowStr',
                'Found: $totalCount',
                if (statusFilter != null && statusFilter != 'All') 'Status: $statusFilter',
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem('Total Files', '$totalCount'),
                  _buildSummaryItem('In Process', '$inProcessCount', highlightColor: PdfColors.amber800),
                  _buildSummaryItem('Completed', '$completedCount', highlightColor: PdfColors.green700),
                  _buildSummaryItem('Action Required', '$actionRequiredCount', highlightColor: PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (trackers.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No file tracking records found for the selected view.',
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
                  1: pw.FlexColumnWidth(2.8),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(1.4),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.4),
                  6: pw.FlexColumnWidth(1.4),
                },
                headers: const [
                  '#',
                  'File Title & Scope',
                  'Subject / Dept',
                  'Inward No.',
                  'Outward No.',
                  'Status',
                  'Updated',
                ],
                data: List.generate(trackers.length, (index) {
                  final t = trackers[index];
                  final descPart = t.description.isNotEmpty ? '\n${t.description}' : '';
                  final deptPart = t.department.isNotEmpty ? '\nDept: ${t.department}' : '';
                  final updatedStr = DateFormat('dd/MM/yyyy').format(t.updatedAt);

                  return [
                    '${index + 1}',
                    '${t.title}$descPart',
                    '${t.subject}$deptPart',
                    t.inwardNumber.isNotEmpty ? t.inwardNumber : '-',
                    t.outwardNumber.isNotEmpty ? t.outwardNumber : '-',
                    t.currentStatus,
                    updatedStr,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Municipal_File_Tracker_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Municipal File Movement Tracker',
        subtitle: 'Follow-up Docket for Administrative Files, Approvals & Letters',
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
