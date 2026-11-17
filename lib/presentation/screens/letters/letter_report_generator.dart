import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/letter_model.dart';

/// Official Letter Registry & Documentation Report Generator matching Nagarsevak-Managment
/// (LetterReportGenerator.tsx).
class LetterReportGenerator {
  LetterReportGenerator._();

  static Future<void> generateAndPrintLetterReport({
    required List<LetterModel> letters,
    String? statusFilter,
    String? typeFilter,
    String? areaFilter,
    String title = 'Inward & Outward Letters Official Register',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);

    final total = letters.length;
    final incoming = letters.where((l) => l.isIncoming).length;
    final outgoing = letters.where((l) => !l.isIncoming).length;
    final approved = letters.where((l) => l.status.toLowerCase() == 'approved').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Official PMC & Nagarsevak Letterhead Header
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
                        title,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0F172A),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Nagarsevak Office Official Secretariat • Despatch & Inward Register',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
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
                          border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                        ),
                        child: pw.Text(
                          'OFFICIAL DESPATCH RECORD',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Generated: $formattedDate', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      if (areaFilter != null && areaFilter != 'All')
                        pw.Text('Area: $areaFilter', style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // KPI Summary Statistics
            pw.Row(
              children: [
                _buildPdfKpiCard('Total Entries', '$total', PdfColors.blue50, PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Outgoing Letters', '$outgoing', PdfColors.green50, PdfColors.green900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Inward / Received', '$incoming', PdfColors.purple50, PdfColors.purple900),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Sanctioned / Approved', '$approved', PdfColors.amber50, PdfColors.amber900),
              ],
            ),
            pw.SizedBox(height: 14),

            // Letters Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0284C7)),
              headerHeight: 24,
              cellHeight: 22,
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey900),
              headers: [
                '#',
                'Ref / Date',
                'Flow',
                'Citizen / Recipient / Dept',
                'Letter Type & Subject',
                'Area / Ward',
                'Status',
              ],
              columnWidths: const {
                0: pw.FixedColumnWidth(22),
                1: pw.FixedColumnWidth(65),
                2: pw.FixedColumnWidth(48),
                3: pw.FlexColumnWidth(1.8),
                4: pw.FlexColumnWidth(2.4),
                5: pw.FixedColumnWidth(75),
                6: pw.FixedColumnWidth(55),
              },
              data: List.generate(letters.length, (index) {
                final l = letters[index];
                final dateStr = DateFormat('dd/MM/yyyy').format(l.receivedDate ?? l.createdAt);
                final refNo = l.details['letter_ref']?.toString() ?? (l.id.length >= 8 ? l.id.substring(0, 8).toUpperCase() : l.id);
                final flow = l.isIncoming ? 'INWARD' : 'OUTWARD';
                final recipient = l.isIncoming ? (l.sender ?? l.citizenName) : l.citizenName;
                final typeSubject = '${l.letterType ?? l.title}\n${l.subject}';
                final area = l.area ?? 'Prabhag 12';
                return [
                  '${index + 1}',
                  '$refNo\n$dateStr',
                  flow,
                  recipient,
                  typeSubject,
                  area,
                  l.status,
                ];
              }),
            ),
            pw.SizedBox(height: 18),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Note: Official computerized register of Pune Municipal Corporation Prabhag 12 secretariat.',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Secretariat Officer / Authorized Signatory',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
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
      name: 'Letters_Register_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  /// Generates and prints a single official letter / request docket (Portrait A4)
  static Future<void> generateAndPrintSingleLetter({
    required LetterModel letter,
    String? letterBody,
    String? nagarsevakName = 'Nagarsevak Office',
    String? wardName = 'Ward No. 12 (Prabhag 12)',
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy').format(letter.createdAt);
    final refNo = letter.id.length >= 8
        ? (letter.isIncoming ? 'INW-${letter.id.substring(0, 8).toUpperCase()}' : 'OUT-${letter.id.substring(0, 8).toUpperCase()}')
        : (letter.isIncoming ? 'INW-${letter.id}' : 'OUT-${letter.id}');

    final bodyText = letterBody ?? letter.description ?? letter.details['text']?.toString() ?? letter.details['details']?.toString() ?? 'Official letter representation recorded for civic administration and department follow-up.';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Letterhead Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.blue900, width: 2),
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
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          letter.isIncoming ? 'OFFICE OF NAGARSEVAK - INWARD LETTER' : 'OFFICE OF NAGARSEVAK - OUTWARD LETTER',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF0F172A),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Ward Secretariat & Citizen Correspondence Cell',
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
                            color: PdfColors.blue50,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: PdfColors.blue300),
                          ),
                          child: pw.Text(
                            refNo,
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Status Bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: letter.status.toLowerCase() == 'approved' ? PdfColors.green50 : PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color: letter.status.toLowerCase() == 'approved' ? PdfColors.green300 : PdfColors.blue300,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'STATUS: ${letter.status.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: letter.status.toLowerCase() == 'approved' ? PdfColors.green900 : PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Type: ${letter.letterType ?? "General Letter"}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                    ),
                    pw.Text(
                      'Area: ${letter.area?.isNotEmpty == true ? letter.area! : "Prabhag 12"}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Recipient / Sender Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            letter.isIncoming ? 'From (Citizen / Applicant):' : 'To (Recipient / Department):',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            letter.citizenName,
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A)),
                          ),
                          if (letter.mobile.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Contact: ${letter.mobile}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          ],
                          if (letter.address.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Address: ${letter.address}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          ],
                        ],
                      ),
                    ),
                    if (letter.department?.isNotEmpty == true) ...[
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Target Department:',
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              letter.department!,
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Subject
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF1F5F9),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Subject: ',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A)),
                      ),
                      pw.TextSpan(
                        text: letter.subject,
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // Body Content
              pw.Expanded(
                child: pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Representation / Official Communication:',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        bodyText,
                        style: const pw.TextStyle(
                          fontSize: 10.5,
                          lineSpacing: 2.5,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Signatures & Official Seal
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Pune Municipal Corporation', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                      pw.Text('Prabhag No. 12 Office Record', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                      pw.Text('Computer Generated Document', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Signatory',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                      ),
                      pw.Text(
                        'Nagarsevak Office, Prabhag 12',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Letter_${refNo.replaceAll('-', '_')}.pdf',
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
            pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: text)),
          ],
        ),
      ),
    );
  }
}
