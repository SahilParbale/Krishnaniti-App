import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/sms_campaign_model.dart';

class SmsHistoryReportGenerator {
  SmsHistoryReportGenerator._();

  static Future<void> generateAndPrintReport({
    required List<SmsCampaignModel> campaigns,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final nowStr = DateFormat('dd/MM/yyyy, hh:mm a').format(now);

    final totalCampaigns = campaigns.length;
    final totalRecipients = campaigns.fold<int>(0, (sum, c) => sum + c.totalRecipients);
    final totalDelivered = campaigns.fold<int>(0, (sum, c) => sum + c.stats.delivered);
    final totalFailed = campaigns.fold<int>(0, (sum, c) => sum + c.stats.failed);
    final deliveryRate = totalRecipients > 0 ? ((totalDelivered / totalRecipients) * 100).round() : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - NAGARSEVAK OFFICE PRABHAG 12',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Public Communication & Bulk SMS Report',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0F172A),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Official Bulk SMS Broadcast History with DLT Delivery Verification · Prabhag No. 12',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFEFF6FF),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                        ),
                        child: pw.Text(
                          'Page ${context.pageNumber} of ${context.pagesCount}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: $nowStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'Central Command System',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.blue900, thickness: 1.5),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Cards Row
            pw.Row(
              children: [
                _buildKpiCard('Total Campaigns', '$totalCampaigns', 'Broadcast Dispatches', PdfColors.blue50, PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildKpiCard('Total Recipients', '$totalRecipients', 'Registered Voters', const PdfColor.fromInt(0xFFF1F5F9), const PdfColor.fromInt(0xFF1E293B)),
                pw.SizedBox(width: 8),
                _buildKpiCard('Delivered', '$totalDelivered', '$deliveryRate% Success Rate', const PdfColor.fromInt(0xFFECFDF5), const PdfColor.fromInt(0xFF047857)),
                pw.SizedBox(width: 8),
                _buildKpiCard('Failed', '$totalFailed', 'Invalid / Network Issues', const PdfColor.fromInt(0xFFFEF2F2), const PdfColor.fromInt(0xFFDC2626)),
              ],
            ),

            pw.SizedBox(height: 12),

            // Campaigns Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26), // Sr No
                1: const pw.FlexColumnWidth(1.6), // Date & Time
                2: const pw.FlexColumnWidth(3.4), // Campaign Name & Message
                3: const pw.FlexColumnWidth(1.0), // Channel
                4: const pw.FlexColumnWidth(1.2), // Recipients
                5: const pw.FlexColumnWidth(1.2), // Delivered
                6: const pw.FlexColumnWidth(1.0), // Failed
                7: const pw.FlexColumnWidth(1.2), // Status
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildCell('Sr.', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Date & Time', isHeader: true),
                    _buildCell('Campaign & Message', isHeader: true),
                    _buildCell('Channel', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Recipients', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Delivered', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Failed', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Status', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                // Data Rows
                ...campaigns.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final campaign = entry.value;

                  final isEven = entry.key % 2 == 0;
                  final rowBg = isEven ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFC);

                  PdfColor statusColor = const PdfColor.fromInt(0xFF047857);
                  if (campaign.isFailed) {
                    statusColor = const PdfColor.fromInt(0xFFDC2626);
                  } else if (campaign.isSending) {
                    statusColor = const PdfColor.fromInt(0xFFD97706);
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _buildCell('$index', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Text(
                          campaign.formattedDate,
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              campaign.name,
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              campaign.message,
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                              maxLines: 2,
                            ),
                            if (campaign.dltTemplateId != null) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'DLT ID: ${campaign.dltTemplateId}',
                                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildCell('SMS', align: pw.TextAlign.center, bold: true),
                      _buildCell('${campaign.totalRecipients}', align: pw.TextAlign.center, bold: true),
                      _buildCell(
                        '${campaign.stats.delivered}',
                        align: pw.TextAlign.center,
                        bold: true,
                        textColor: const PdfColor.fromInt(0xFF047857),
                      ),
                      _buildCell(
                        '${campaign.stats.failed}',
                        align: pw.TextAlign.center,
                        textColor: campaign.stats.failed > 0 ? const PdfColor.fromInt(0xFFDC2626) : PdfColors.grey600,
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: statusColor == const PdfColor.fromInt(0xFF047857)
                                ? const PdfColor.fromInt(0xFFECFDF5)
                                : const PdfColor.fromInt(0xFFFFFBEB),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Text(
                            campaign.status,
                            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 16),

            // Summary notes & Signature block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  width: 320,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF8FAFC),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Important Compliance:',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '1. All SMS broadcasts are sent via TRAI DLT approved headers and registered templates.\n'
                        '2. Citizen data privacy and cybersecurity standards are strictly maintained.\n'
                        '3. Official emergency alerts are broadcast with approvals from PMC disaster management.',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Corporator / Ward Committee Head',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(
                      'Ward 12, Pune Municipal Corporation',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'SMS_Campaigns_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildKpiCard(String title, String value, String sub, PdfColor bg, PdfColor textColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: textColor),
            ),
            pw.SizedBox(height: 1),
            pw.Text(sub, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7.5,
          fontWeight: (isHeader || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColors.grey800 : PdfColors.grey800),
        ),
      ),
    );
  }
}

