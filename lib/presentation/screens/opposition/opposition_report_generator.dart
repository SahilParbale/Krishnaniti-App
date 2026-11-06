import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/opposition_model.dart';

class OppositionReportGenerator {
  static Future<void> generateAndPrintReport({
    required List<OppositionMemberModel> members,
    required String Function(String) getCandidateName,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);

    final totalMembers = members.length;
    final totalCandidates = members.where((m) => m.isCandidate).length;
    final totalWorkers = members.where((m) => !m.isCandidate).length;
    int totalControversies = 0;
    for (final m in members) {
      totalControversies += m.negativeStories.length;
    }

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
                        'OPPOSITION INFORMATION & STRATEGIC DIRECTORY',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'विरोधी पक्षाची माहिती - उमेदवार, कार्यकर्ते, बालेकिल्ले आणि वादग्रस्त नोंदी',
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
                          color: PdfColors.red50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.red300),
                        ),
                        child: pw.Text(
                          'CONFIDENTIAL / अंतर्गत वापरासाठी',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red800,
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

            // Summary Metrics
            pw.Row(
              children: [
                _buildPdfKpiCard('Total Records', totalMembers.toString(), PdfColors.blue50, PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Candidates (उमेदवार)', totalCandidates.toString(), PdfColors.indigo50, PdfColors.indigo900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Workers (कार्यकर्ते)', totalWorkers.toString(), PdfColors.amber50, PdfColors.amber900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Controversies (वाद/किस्से)', totalControversies.toString(), PdfColors.red50, PdfColors.red900),
              ],
            ),

            pw.SizedBox(height: 14),

            // Directory Table
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'Name (नाव)',
                'Party',
                'Type',
                'Role / Designation',
                'Base Area',
                'Mobile',
                'Strongholds (बालेकिल्ले)',
                'Status / Linked Candidate',
                'Contr.',
              ],
              data: List.generate(members.length, (index) {
                final m = members[index];
                String statusOrCand = '-';
                if (m.isCandidate) {
                  statusOrCand = '${m.candidacyStatus ?? 'Declared'} (${m.constituency ?? 'Prabhag 12'})';
                } else if (m.candidateId != null && m.candidateId!.isNotEmpty) {
                  final candName = getCandidateName(m.candidateId!);
                  statusOrCand = candName.isNotEmpty ? 'Cand: $candName' : 'Linked';
                }

                return [
                  (index + 1).toString(),
                  m.name,
                  m.party,
                  m.isCandidate ? 'Candidate' : 'Worker',
                  m.role ?? '-',
                  m.area ?? '-',
                  m.mobile ?? '-',
                  m.strongholds.isNotEmpty ? m.strongholds.take(3).join(', ') : '-',
                  statusOrCand,
                  m.negativeStories.length.toString(),
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8.5,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0284C7)),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              columnWidths: {
                0: const pw.FixedColumnWidth(22),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FixedColumnWidth(48),
                3: const pw.FixedColumnWidth(55),
                4: const pw.FlexColumnWidth(1.8),
                5: const pw.FlexColumnWidth(1.6),
                6: const pw.FixedColumnWidth(68),
                7: const pw.FlexColumnWidth(2.0),
                8: const pw.FlexColumnWidth(1.8),
                9: const pw.FixedColumnWidth(30),
              },
            ),

            pw.SizedBox(height: 16),

            // Footer note
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'टीप: हा अहवाल केवळ पक्षांतर्गत निवडणूक विश्लेषण आणि रणनीती आखणीसाठी तयार केलेला आहे.',
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
      name: 'Opposition_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
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

