import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/housing_society_model.dart';

class HousingSocietyReportGenerator {
  static Future<void> generateAndPrintReport({
    required List<HousingSocietyModel> societies,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);

    final totalSocieties = societies.length;
    final totalVoters = societies.fold<int>(0, (sum, s) => sum + s.voterCount);
    final totalFavourable = societies.fold<int>(0, (sum, s) => sum + s.favourableVoterCount);
    final supportPercentage = totalVoters > 0 ? ((totalFavourable / totalVoters) * 100).round() : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Official Header
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
                        'सहकारी गृहनिर्माण संस्था, अध्यक्ष-सचिव व मतदार विश्लेषण अहवाल',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0F172A),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Housing Societies, Chairman & Secretary Contacts with Voter Support Breakdown',
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
                          'CONFIDENTIAL / राजकीय व प्रभाग दस्तऐवज',
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
                _buildPdfKpiCard('Total Societies (एकूण सोसायट्या)', totalSocieties.toString(), PdfColors.indigo50, PdfColors.indigo900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Total Voters (एकूण मतदार)', totalVoters.toString(), PdfColors.blue50, PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Favourable Support (फेवर मतदार)', totalFavourable.toString(), PdfColors.green50, PdfColors.green900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Support Rating (अंदाजे पाठिंबा)', '$supportPercentage%', PdfColors.amber50, PdfColors.amber900),
              ],
            ),

            pw.SizedBox(height: 14),

            // Directory Table
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'Society Name (सोसायटीचे नाव)',
                'Area (परिसर)',
                'Chairman (अध्यक्ष)',
                'Chairman Mobile',
                'Secretary (सचिव)',
                'Secretary Mobile',
                'Total Voters',
                'Fav Voters',
                'Support %',
                'Status',
                'Key Issues & Notes (समस्या व मागण्या)',
              ],
              data: List.generate(societies.length, (index) {
                final s = societies[index];
                return [
                  (index + 1).toString(),
                  s.displayName(true),
                  s.area.isNotEmpty ? s.area : '-',
                  s.chairmanName.isNotEmpty ? s.chairmanName : '-',
                  s.chairmanMobile.isNotEmpty ? s.chairmanMobile : '-',
                  s.secretaryName.isNotEmpty ? s.secretaryName : '-',
                  s.secretaryMobile.isNotEmpty ? s.secretaryMobile : '-',
                  s.voterCount.toString(),
                  s.favourableVoterCount.toString(),
                  '${s.supportPercentage}%',
                  s.status,
                  s.notes.isNotEmpty ? s.notes : '-',
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
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1.6),
                3: const pw.FlexColumnWidth(1.6),
                4: const pw.FixedColumnWidth(65),
                5: const pw.FlexColumnWidth(1.6),
                6: const pw.FixedColumnWidth(65),
                7: const pw.FixedColumnWidth(35),
                8: const pw.FixedColumnWidth(35),
                9: const pw.FixedColumnWidth(35),
                10: const pw.FixedColumnWidth(32),
                11: const pw.FlexColumnWidth(2.8),
              },
            ),

            pw.SizedBox(height: 16),

            // Footer note
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'टीप: हा अहवाल प्रभाग क्र. १२ मधील सहकारी गृहनिर्माण संस्थांचे संपर्क आणि मतदार समन्वय साध्य करण्यासाठी आहे.',
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
      name: 'Housing_Societies_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
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

