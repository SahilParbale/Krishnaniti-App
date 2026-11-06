import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/social_organization_model.dart';

class SocialOrgReportGenerator {
  static Future<void> generateAndPrintReport({
    required List<SocialOrganizationModel> organizations,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);

    final total = organizations.length;
    final ngos = organizations.where((o) => o.type == 'ngo').length;
    final sports = organizations.where((o) => o.type == 'sports_cricket').length;
    final mandals = organizations.where((o) => o.type == 'ganpati_mandal' || o.type == 'navratri_mandal').length;

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
                        'NGOS, SPORTS CLUBS & FESTIVAL MANDALS REGISTRY',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'एन.जी.ओ., क्रीडा क्लब व सार्वजनिक उत्सव मंडळ माहिती व संपर्क यादी',
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
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.blue200),
                        ),
                        child: pw.Text(
                          'OFFICIAL DIRECTORY / प्रभाग नोंदवही',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: $formattedDate',
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
                _buildPdfKpiCard('Total Registered', total.toString(), PdfColors.blue50, PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('NGOs / सामाजिक संस्था', ngos.toString(), PdfColors.indigo50, PdfColors.indigo900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Sports & Cricket Clubs', sports.toString(), PdfColors.green50, PdfColors.green900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Festival Mandals (उत्सव मंडळे)', mandals.toString(), PdfColors.amber50, PdfColors.amber900),
              ],
            ),

            pw.SizedBox(height: 14),

            // Directory Table
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'Organization Name (संस्थेचे नाव)',
                'Type',
                'President (अध्यक्ष)',
                'Mobile',
                'Area (परिसर)',
                'Members',
                'Est.',
                'Support Received (नगरसेवक मदत)',
                'Events',
                'Status',
              ],
              data: List.generate(organizations.length, (index) {
                final o = organizations[index];
                return [
                  (index + 1).toString(),
                  o.displayName,
                  o.typeLabelEnglish,
                  o.presidentName.isNotEmpty ? o.presidentName : '-',
                  o.presidentMobile.isNotEmpty ? o.presidentMobile : '-',
                  o.area.isNotEmpty ? o.area : '-',
                  o.membersCount > 0 ? o.membersCount.toString() : '-',
                  o.establishedYear.isNotEmpty ? o.establishedYear : '-',
                  o.supportReceived.isNotEmpty ? o.supportReceived : '-',
                  o.eventsConducted.length.toString(),
                  o.status,
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
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
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1.6),
                3: const pw.FlexColumnWidth(1.8),
                4: const pw.FixedColumnWidth(65),
                5: const pw.FlexColumnWidth(1.6),
                6: const pw.FixedColumnWidth(35),
                7: const pw.FixedColumnWidth(30),
                8: const pw.FlexColumnWidth(2.4),
                9: const pw.FixedColumnWidth(28),
                10: const pw.FixedColumnWidth(35),
              },
            ),

            pw.SizedBox(height: 16),

            // Footer note
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'टीप: हा अहवाल प्रभाग क्र. १२ मधील सामाजिक, क्रीडा आणि धार्मिक संस्थांच्या समन्वयासाठी तयार केलेला आहे.',
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
      name: 'Mandal_NGO_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
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
