import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/duplicate_voter_group_model.dart';

class DuplicateVotersReportGenerator {
  static Future<void> generateAndPrintReport({
    required List<DuplicateVoterGroupModel> duplicateGroups,
    required int totalAffectedVoters,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);
    final estExtraRecords = duplicateGroups.fold<int>(0, (sum, g) => sum + g.extraRecordsCount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Official PMC & Nagarsevak Office Header
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
                        'ड्युप्लिकेट मतदार शोध व तपासणी अहवाल',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0F172A),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Duplicate Voter Detection Report - Electoral Roll Cleanliness Audit',
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
                          color: const PdfColor.fromInt(0xFFFEF2F2),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFFECACA), width: 0.5),
                        ),
                        child: pw.Text(
                          'ELECTORAL AUDIT / मतदार यादी तपासणी',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFFDC2626),
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

            // Summary KPI Cards Row
            pw.Row(
              children: [
                _buildPdfKpiCard('Duplicate Groups (ड्युप्लिकेट गट)', duplicateGroups.length.toString(), PdfColors.blue50, PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Total Affected Voters (एकूण बाधित मतदार)', totalAffectedVoters.toString(), const PdfColor.fromInt(0xFFFEF2F2), const PdfColor.fromInt(0xFFB91C1C)),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Est. Extra Records (अंदाजे अतिरिक्त रेकॉर्ड)', estExtraRecords.toString(), PdfColors.amber50, PdfColors.amber900),
              ],
            ),

            pw.SizedBox(height: 14),

            if (duplicateGroups.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'कोणतेही ड्युप्लिकेट मतदार आढळले नाहीत. सर्व मतदार रेकॉर्ड अद्वितीय आहेत.',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                ),
              )
            else
              ...duplicateGroups.map((group) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Group Header Banner
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFF1F5F9),
                          borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(5)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${group.displayName} (${group.recordsCount} नोंदी आढळल्या)',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A)),
                            ),
                            pw.Text(
                              '${group.extraRecordsCount} संभाव्य अतिरिक्त नोंद (Form 7 Deletion)',
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),

                      // Side-by-side Table of Voters in Group
                      pw.TableHelper.fromTextArray(
                        headers: [
                          '#',
                          'Status',
                          'Voter Name',
                          'EPIC No.',
                          'Booth / Part',
                          'Sr No',
                          'Age/Sex',
                          'House #',
                          'Mobile',
                          'Address',
                        ],
                        data: List.generate(group.voters.length, (idx) {
                          final v = group.voters[idx];
                          return [
                            (idx + 1).toString(),
                            idx == 0 ? 'First Record' : 'Duplicate',
                            v.displayName,
                            v.epicNo.isNotEmpty ? v.epicNo : '-',
                            v.booth,
                            v.serialNo != null ? v.serialNo.toString() : '-',
                            '${v.age} / ${v.gender}',
                            v.houseNo ?? '-',
                            v.mobile ?? '-',
                            v.address,
                          ];
                        }),
                        headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0284C7)),
                        rowDecoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
                        ),
                        cellStyle: const pw.TextStyle(fontSize: 7, color: PdfColors.grey900),
                        cellAlignment: pw.Alignment.centerLeft,
                        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                        columnWidths: {
                          0: const pw.FixedColumnWidth(16),
                          1: const pw.FixedColumnWidth(50),
                          2: const pw.FlexColumnWidth(2.2),
                          3: const pw.FlexColumnWidth(1.8),
                          4: const pw.FlexColumnWidth(1.6),
                          5: const pw.FixedColumnWidth(28),
                          6: const pw.FixedColumnWidth(35),
                          7: const pw.FixedColumnWidth(30),
                          8: const pw.FixedColumnWidth(55),
                          9: const pw.FlexColumnWidth(2.6),
                        },
                      ),
                    ],
                  ),
                );
              }),

            pw.SizedBox(height: 12),

            // Footer note
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'टीप: मतदार यादीतील ड्युप्लिकेट नावे वगळण्यासाठी निवडणूक आयोगाचा नमुना क्र. ७ (Form 7) दाखल करावा.',
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
      name: 'Duplicate_Voters_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
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

