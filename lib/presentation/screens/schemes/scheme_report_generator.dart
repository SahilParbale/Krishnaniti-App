import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/scheme_model.dart';

class SchemeReportGenerator {
  SchemeReportGenerator._();

  /// Multi-page PDF directory of all government schemes
  static Future<void> generateAndPrintListReport({
    required List<SchemeModel> schemes,
    required bool isMarathi,
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final total = schemes.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GOVERNMENT WELFARE SCHEMES DIRECTORY',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prabhag Ward 12 - Public Welfare & Citizen Assistance Desk',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Generated: $nowStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      if (categoryFilter != null && categoryFilter != 'All')
                        pw.Text('Category: $categoryFilter', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Summary Strip
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Schemes Listed: $total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
                    pw.Text('Official Ward Citizen Information Notice', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Confidential & Public Notice - Nagarsevak Ward Management System',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28), // Sr
                1: const pw.FlexColumnWidth(2.8), // Name
                2: const pw.FlexColumnWidth(1.2), // Category
                3: const pw.FlexColumnWidth(2.6), // Eligibility
                4: const pw.FlexColumnWidth(2.8), // Benefits
                5: const pw.FlexColumnWidth(2.4), // Documents
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _cellHeader('Sr', align: pw.TextAlign.center),
                    _cellHeader('Scheme Name'),
                    _cellHeader('Category'),
                    _cellHeader('Eligibility Criteria'),
                    _cellHeader('Entitlements / Benefits'),
                    _cellHeader('Documents Required'),
                  ],
                ),
                // Rows
                ...schemes.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final s = entry.value;
                  final isEven = idx % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey50 : PdfColors.white),
                    children: [
                      _cellText('$idx', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(s.name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.SizedBox(height: 2),
                            pw.Text(s.description, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700), maxLines: 3),
                          ],
                        ),
                      ),
                      _cellText(s.category),
                      _cellText(s.eligibility, maxLines: 4),
                      _cellText(s.benefits, maxLines: 4),
                      _cellText(s.documents, maxLines: 4),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Government_Schemes_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  /// Single Scheme Official Guideline Slip / Public Flyer
  static Future<void> generateAndPrintSingleSchemeFlyer({
    required SchemeModel scheme,
    required bool isMarathi,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Header
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NAGARSEVAK PUBLIC WELFARE DESK',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Prabhag Ward 12 | Government Scheme Public Information Slip',
                          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.blue100),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        scheme.category.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Title
              pw.Text(
                scheme.name,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                scheme.description,
                style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey800, lineSpacing: 2),
              ),

              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Benefit Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.green300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FINANCIAL BENEFITS & ENTITLEMENTS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    pw.SizedBox(height: 5),
                    pw.Text(scheme.benefits, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900, lineSpacing: 1.5)),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Eligibility Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ELIGIBILITY CRITERIA', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.SizedBox(height: 5),
                    pw.Text(scheme.eligibility, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900, lineSpacing: 1.5)),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Documents Required Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.amber300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('REQUIRED DOCUMENTS CHECKLIST', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                    pw.SizedBox(height: 5),
                    pw.Text(scheme.documents, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900, lineSpacing: 1.5)),
                  ],
                ),
              ),

              pw.Spacer(),

              // How to Apply / Office Contact
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Where to Apply / Assistance Desk:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                        pw.SizedBox(height: 2),
                        pw.Text('Nagarsevak Office, Prabhag 12 | Mon - Sat, 10:00 AM to 6:00 PM', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Issued: $nowStr', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                        pw.Text('Helpline: 1800-11-6163 / Ward Desk', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Scheme_${scheme.id}_Flyer.pdf',
    );
  }

  /// Beneficiary / Applications List PDF Report
  static Future<void> generateAndPrintBeneficiaryReport({
    required List<SchemeApplicationModel> applications,
    required bool isMarathi,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final total = applications.length;
    final approved = applications.where((a) => a.isApproved).length;
    final pending = applications.where((a) => a.isPending).length;
    final rejected = applications.where((a) => a.isRejected).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GOVERNMENT SCHEME BENEFICIARIES & APPLICATIONS REGISTER',
                        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text('Prabhag 12 - Nagarsevak Citizen Welfare & Entitlement Tracking', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text('Generated: $nowStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
              pw.SizedBox(height: 10),
              // Metrics bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _statPill('Total Applications', '$total', PdfColors.blue900),
                    _statPill('Approved', '$approved', PdfColors.green800),
                    _statPill('In Verification / Pending', '$pending', PdfColors.amber800),
                    _statPill('Rejected', '$rejected', PdfColors.red800),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28), // Sr
                1: const pw.FlexColumnWidth(2.2), // Applicant Name
                2: const pw.FlexColumnWidth(1.5), // Mobile
                3: const pw.FlexColumnWidth(2.2), // Address
                4: const pw.FlexColumnWidth(2.5), // Scheme
                5: const pw.FlexColumnWidth(1.2), // Status
                6: const pw.FlexColumnWidth(2.4), // Benefit / Notes
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _cellHeader('Sr', align: pw.TextAlign.center),
                    _cellHeader('Applicant Citizen'),
                    _cellHeader('Mobile'),
                    _cellHeader('Residential Address'),
                    _cellHeader('Applied Scheme'),
                    _cellHeader('Status'),
                    _cellHeader('Benefit Sanctioned / Notes'),
                  ],
                ),
                ...applications.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final a = entry.value;
                  final isEven = idx % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey50 : PdfColors.white),
                    children: [
                      _cellText('$idx', align: pw.TextAlign.center),
                      _cellText(a.applicantName, isBold: true),
                      _cellText(a.mobile),
                      _cellText(a.address),
                      _cellText(a.schemeName ?? 'Scheme #${a.schemeId}'),
                      _cellText(a.status, isBold: true),
                      _cellText(a.benefit ?? a.notes ?? a.rejectionReason ?? '-'),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Scheme_Beneficiaries_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _statPill(String label, String val, PdfColor col) {
    return pw.Row(
      children: [
        pw.Text('$label: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.Text(val, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: col)),
      ],
    );
  }

  static pw.Widget _cellHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.blue900),
      ),
    );
  }

  static pw.Widget _cellText(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false, int? maxLines}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }
}

