import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/voter_application_model.dart';

class VoterFormsReportGenerator {
  static Future<void> generateAndPrintReport({
    required List<VoterApplicationModel> applications,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);

    final total = applications.length;
    final approved = applications.where((a) => a.status.toLowerCase() == 'approved').length;
    final pending = applications.where((a) => a.status.toLowerCase() == 'pending').length;
    final submitted = applications.where((a) => a.status.toLowerCase() == 'submitted').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Official PMC & Office Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PUNE MUNICIPAL CORPORATION - PRABHAG 12',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'मतदार नोंदणी व दुरुस्ती अर्ज अहवाल (ECI Voter Forms Register)',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0F172A),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Form 6 (New Voter), Form 7 (Deletion), Form 8 (Correction) Application Tracker',
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
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                        ),
                        child: pw.Text(
                          'ECI HELPDESK / मतदार साहाय्यता कक्ष',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'दिनांक: $formattedDate',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Nagarsevak Office - Prabhag 12',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // Summary KPI Row
            pw.Row(
              children: [
                _buildPdfKpiCard('Total Applications (एकूण अर्ज)', total.toString(), PdfColors.indigo50, PdfColors.indigo900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Approved (मंजूर अर्ज)', approved.toString(), PdfColors.green50, PdfColors.green900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Pending (प्रलंबित अर्ज)', pending.toString(), PdfColors.amber50, PdfColors.amber900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Submitted (दाखल अर्ज)', submitted.toString(), PdfColors.blue50, PdfColors.blue900),
              ],
            ),

            pw.SizedBox(height: 14),

            // Applications Table
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'Applicant Name (अर्जदाराचे नाव)',
                'Mobile',
                'Form Type (अर्जाचा प्रकार)',
                'Status (स्थिती)',
                'Date (तारीख)',
                'Notes & Purpose (नोंद व तपशील)',
              ],
              data: List.generate(applications.length, (index) {
                final app = applications[index];
                return [
                  (index + 1).toString(),
                  app.applicantName,
                  app.applicantMobile ?? '-',
                  app.formTypeMarathi,
                  app.statusMarathi,
                  DateFormat('dd/MM/yyyy').format(app.createdAt),
                  app.notes ?? '-',
                ];
              }),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0284C7)),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey900),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),
                1: const pw.FlexColumnWidth(2.4),
                2: const pw.FixedColumnWidth(65),
                3: const pw.FlexColumnWidth(2.0),
                4: const pw.FixedColumnWidth(45),
                5: const pw.FixedColumnWidth(55),
                6: const pw.FlexColumnWidth(3.2),
              },
            ),

            pw.SizedBox(height: 16),

            // Footer note
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'टीप: हा अहवाल नागरिकांच्या मतदार ओळखपत्र अर्ज व ईसीआय सेवा ट्रॅकिंगसाठी तयार केलेला आहे.',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Nagarsevak Central Command System',
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Voter_Forms_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildPdfKpiCard(String label, String value, PdfColor bg, PdfColor text) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: text),
            ),
          ],
        ),
      ),
    );
  }
}

