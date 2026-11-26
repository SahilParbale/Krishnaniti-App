
import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/voter_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class VoterSlipGenerator {
  VoterSlipGenerator._();

  /// Generate and print single official voter information slip
  static Future<void> printVoterSlip(
    VoterModel voter, {
    BuildContext? context,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - GENERAL ELECTION',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'OFFICIAL VOTER INFORMATION SLIP',
                        style: pw.TextStyle(
                          color: PdfColors.amber200,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        '214 - Kasba Peth Assembly Constituency | Ward No. 12',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // Serial & Part Number Highlight Box
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Serial No. in Electoral Roll',
                                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            pw.Text('#${voter.serialNo ?? "-"}',
                                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Booth / Part No.',
                                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            pw.Text(voter.booth,
                                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),

                // Voter Data Grid
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(5),
                    },
                    children: [
                      _buildTableRow('Voter Full Name', voter.displayName),
                      _buildTableRow('English Name', voter.nameEnglish),
                      _buildTableRow('EPIC No.', voter.epicNo),
                      _buildTableRow('Age / Gender', '${voter.age} Yrs / ${voter.gender}'),
                      _buildTableRow('House No.', voter.houseNo != null ? '#${voter.houseNo}' : '-'),
                      _buildTableRow('Residential Address', voter.address),
                      _buildTableRow('Mobile Number', voter.mobile != null ? '+91 ${voter.mobile}' : 'Not Registered'),
                      _buildTableRow('Polling Station', voter.displayPollingStation),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // Important Note Box
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    border: pw.Border.all(color: PdfColors.amber300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Important Guidelines:',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '1. This slip is for finding polling station and serial number. Carrying voter ID (EPIC) or Aadhaar is required for voting.\n'
                        '2. Voting Hours: 7:00 AM to 6:00 PM.',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Nagarsevak Election Assistance Portal â€¢ Ward 12',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                    pw.Text('Generated: $nowStr',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final fileName = 'Voter_Slip_${voter.epicNo.replaceAll('/', '_')}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Voter Information Slip',
        subtitle: voter.displayName,
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

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black)),
        ),
      ],
    );
  }

  /// Generate and download complete filtered voter list matching web VoterReportGenerator.tsx
  static Future<void> downloadVotersListReport({
    BuildContext? context,
    required List<VoterModel> voters,
    String? currentFilterSummary,
    int totalCount = 42560,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: 'Voters List',
            );
          }
          return WebReportTheme.buildHeader(
            title: 'Voters List',
            subtitle: currentFilterSummary?.isNotEmpty == true
                ? 'Filtered: $currentFilterSummary'
                : 'Detailed Electoral Roll Report',
            dateFormatted: nowStr,
            totalCount: voters.length,
            foundLabel: 'Found',
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context),
        build: (pw.Context context) {
          return [
            // Table of Voters matching web VoterReportGenerator.tsx
            pw.TableHelper.fromTextArray(
              border: WebReportTheme.tableBorder,
              headerCount: 1,
              headerStyle: WebReportTheme.tableHeaderStyle,
              headerDecoration: WebReportTheme.tableHeaderDecoration,
              oddRowDecoration: WebReportTheme.oddRowDecoration,
              cellStyle: WebReportTheme.tableCellStyle,
              columnWidths: const {
                0: pw.FlexColumnWidth(0.6), // # (5%)
                1: pw.FlexColumnWidth(2.2), // Name (20%)
                2: pw.FlexColumnWidth(1.4), // EPIC No (12%)
                3: pw.FlexColumnWidth(0.8), // Age/Sex (6%)
                4: pw.FlexColumnWidth(2.6), // Address (25%)
                5: pw.FlexColumnWidth(1.2), // Ward / Booth (10%)
                6: pw.FlexColumnWidth(1.1), // Caste / Favour (10%)
              },
              headers: [
                '#',
                'Name',
                'EPIC No',
                'Age/Sex',
                'Address',
                'Booth',
                'Favour',
              ],
              data: voters.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                final addressStr = v.houseNo != null && v.houseNo!.isNotEmpty
                    ? '#${v.houseNo}, ${v.address}'
                    : v.address;
                return [
                  '${v.serialNo ?? (idx + 1)}',
                  v.displayName,
                  v.epicNo,
                  '${v.age} / ${v.gender}',
                  addressStr,
                  v.booth,
                  v.favour ?? '-',
                ];
              }).toList(),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    final fileName = 'Voter_List_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: 'Voters List',
        subtitle: currentFilterSummary?.isNotEmpty == true
            ? 'Filtered: $currentFilterSummary'
            : 'Detailed Electoral Roll Report',
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


