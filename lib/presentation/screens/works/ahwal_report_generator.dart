import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/work_history_model.dart';

class AhwalReportGenerator {
  AhwalReportGenerator._();

  static Future<void> generateAndPrintAhwal({
    required List<WorkHistoryModel> selectedWorks,
    String? nagarsevakName = 'Nagarsevak Office',
    String? wardName = 'Ward No. 12 (Prabhag 12)',
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

    final totalCount = selectedWorks.length;
    final totalAmount = selectedWorks.fold<double>(0, (sum, w) => sum + (w.amount ?? 0));
    final totalBenefited = selectedWorks.fold<int>(0, (sum, w) => sum + (w.peopleBenefited ?? 0));
    final avgRating = selectedWorks.isEmpty
        ? 0.0
        : selectedWorks.fold<double>(0, (sum, w) => sum + w.feedbackRating) / totalCount;

    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Top Emblem / Header Bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'PUNE MUNICIPAL CORPORATION - PRABHAG 12',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'TENURE DEVELOPMENT PERFORMANCE AHWAL (कार्य अहवाल)',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Public Accountability & Civil Development Progress Dossier',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              // Meta Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ward: $wardName', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date of Release: $nowStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 10),
              // Executive Summary Grid
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _metricItem('Selected Works', '$totalCount', PdfColors.blue900),
                    _metricItem('Total Expenditure', numFormat.format(totalAmount), PdfColors.green900),
                    _metricItem('Citizens Benefited', NumberFormat.decimalPattern().format(totalBenefited), PdfColors.blue800),
                    _metricItem('Public Rating', '${avgRating.toStringAsFixed(1)} / 5.0', PdfColors.orange900),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Nagarsevak Administration Portal • Verified Citizen Service Dossier',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Text(
              'DETAILED PROJECT PROFILES & ACCOMPLISHMENTS',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),

            ...List.generate(selectedWorks.length, (index) {
              final w = selectedWorks[index];
              final amt = w.amount != null ? numFormat.format(w.amount) : '--';
              final ben = w.peopleBenefited != null ? NumberFormat.decimalPattern().format(w.peopleBenefited) : '--';

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Card Top
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${index + 1}. ${w.title}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: w.status.toLowerCase() == 'completed' ? PdfColors.green100 : PdfColors.blue100,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            w.statusDisplayEn,
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: w.status.toLowerCase() == 'completed' ? PdfColors.green800 : PdfColors.blue800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    // Location & Source row
                    pw.Row(
                      children: [
                        pw.Text('Location: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text('${w.location} (${w.area})   •   ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                        pw.Text('Category: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text('${w.sourceDisplayEn}   •   ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                        pw.Text('Date: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text(w.date, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    // Scope description
                    pw.Text(
                      w.description,
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800, lineSpacing: 1.2),
                    ),
                    pw.SizedBox(height: 6),
                    // Bottom metrics row
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Beneficiaries: $ben Citizens', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                          pw.Text('Public Expenditure: $amt', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                          pw.Text('Rating: ${w.feedbackRating} / 5.0 (${w.feedbackCount} reviews)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800)),
                        ],
                      ),
                    ),
                    if (w.feedbacks.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Citizen Voice: "${w.feedbacks.first.comment}" - ${w.feedbacks.first.citizenName}',
                        style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                      ),
                    ],
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 20),
            // Verification and Seal Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Municipal Ward Engineer', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 25),
                    pw.Text('Seal & Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Nagarsevak / Local Representative', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 25),
                    pw.Text('Prabhag Ward No. 12', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
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
      name: 'Prabhag12_Ahwal_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _metricItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }
}
