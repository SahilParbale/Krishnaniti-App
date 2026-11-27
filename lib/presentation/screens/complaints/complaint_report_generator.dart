import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/complaint_model.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Complaints Report Generator matching Nagarsevak-Managment (ComplaintReportGenerator.tsx)
class ComplaintReportGenerator {
  ComplaintReportGenerator._();

  /// Generates and prints multi-complaint ledger report matching web ComplaintReportGenerator.tsx
  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<ComplaintModel> complaints,
    String? categoryFilter,
    String? statusFilter,
    String? areaFilter,
    String title = 'Complaints Report',
    String subtitle = 'Detailed Ward Complaints Register',
    String lang = 'en',
  }) async {
    // Load Devanagari font to eliminate all crossmarks/tofu boxes in Marathi and Hindi
    pw.ThemeData? theme;
    try {
      final fontRegular = await PdfGoogleFonts.notoSansDevanagariRegular();
      final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();
      theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    } catch (_) {}

    final pdf = pw.Document(theme: theme);
    final now = DateTime.now();
    final rawDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final formattedDate = AppTranslations.formatDigits(rawDate, lang);
    final total = complaints.length;

    final resolvedTitle = (title == 'Complaints Report')
        ? (lang == 'mr'
            ? 'तक्रार व नागरी समस्या अहवाल'
            : (lang == 'hi' ? 'शिकायत एवं नागरिक समस्या रिपोर्ट' : title))
        : title;
    final resolvedSubtitle = (subtitle == 'Detailed Ward Complaints Register')
        ? (lang == 'mr'
            ? 'सविस्तर प्रभाग तक्रार नोंदवही'
            : (lang == 'hi' ? 'विस्तृत वार्ड शिकायत रजिस्टर' : subtitle))
        : subtitle;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: resolvedTitle,
              lang: lang,
            );
          }
          return WebReportTheme.buildHeader(
            title: resolvedTitle,
            subtitle: resolvedSubtitle,
            dateFormatted: formattedDate,
            totalCount: total,
            lang: lang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: lang),
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              border: WebReportTheme.tableBorder,
              headerStyle: WebReportTheme.tableHeaderStyle,
              headerDecoration: WebReportTheme.tableHeaderDecoration,
              headerHeight: 22,
              cellHeight: 20,
              cellStyle: WebReportTheme.tableCellStyle,
              headerCount: 1,
              oddRowDecoration: WebReportTheme.oddRowDecoration,
              columnWidths: const {
                0: pw.FlexColumnWidth(1.5), // Date & Time (15%)
                1: pw.FlexColumnWidth(1.8), // Citizen Info (18%)
                2: pw.FlexColumnWidth(2.2), // Title & Type (22%)
                3: pw.FlexColumnWidth(1.8), // Location / Area (18%)
                4: pw.FlexColumnWidth(1.6), // Staff (16%)
                5: pw.FlexColumnWidth(1.1), // Status (11%)
              },
              headers: [
                AppTranslations.getReportColumn('date_time', lang),
                AppTranslations.getReportColumn('citizen_info', lang),
                AppTranslations.getReportColumn('title_type', lang),
                AppTranslations.getReportColumn('location_area', lang),
                AppTranslations.getReportColumn('staff', lang),
                AppTranslations.getReportColumn('status', lang),
              ],
              data: complaints.map((c) {
                final dateRaw = DateFormat('dd/MM/yyyy').format(c.createdAt);
                final timeRaw = DateFormat('hh:mm a').format(c.createdAt);
                final dateStr = AppTranslations.formatDigits(dateRaw, lang);
                final timeStr = AppTranslations.formatDigits(timeRaw, lang);

                final anonymousText = lang == 'mr' ? 'निनावी' : (lang == 'hi' ? 'अनाम' : 'Anonymous');
                final rawName = c.citizenName?.trim();
                final citizenName = (rawName != null && rawName.isNotEmpty)
                    ? ((lang == 'mr' || lang == 'hi')
                        ? (DynamicTranslationService.getCachedTranslation(rawName, lang) ?? rawName)
                        : rawName)
                    : anonymousText;
                final citizenMobile = c.citizenMobile != null && c.citizenMobile!.trim().isNotEmpty
                    ? AppTranslations.formatDigits(c.citizenMobile!, lang)
                    : '';
                final citizenInfo = citizenMobile.isNotEmpty
                    ? '$citizenName\n$citizenMobile'
                    : citizenName;

                final typeStr = AppTranslations.getComplaintType(c.category, lang);
                final titleType = typeStr.isNotEmpty ? '${c.title}\n($typeStr)' : c.title;

                final area = c.area != null && c.area!.trim().isNotEmpty
                    ? AppTranslations.getAreaName(c.area!, lang)
                    : '';
                final location = c.location != null && c.location!.trim().isNotEmpty
                    ? AppTranslations.getAreaName(c.location!, lang)
                    : '';
                final locationArea = area.isNotEmpty && location.isNotEmpty
                    ? '$area\n$location'
                    : (area.isNotEmpty ? area : (location.isNotEmpty ? location : '-'));

                final unassignedText = lang == 'mr' ? 'अनियुक्त' : (lang == 'hi' ? 'अनियुक्त' : 'Unassigned');
                final staff = (c.assignedStaffName != null && c.assignedStaffName!.trim().isNotEmpty)
                    ? c.assignedStaffName!
                    : unassignedText;

                return [
                  '$dateStr\n$timeStr',
                  citizenInfo,
                  titleType,
                  locationArea,
                  staff,
                  AppTranslations.getStatus(c.status, lang),
                ];
              }).toList(),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    final fileName = 'Complaints_Report_${DateFormat('yyyy-MM-dd').format(now)}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: resolvedTitle,
        subtitle: resolvedSubtitle,
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

  /// Generates and prints a single grievance docket (Portrait A4) matching web docket generator
  static Future<void> generateAndPrintSingleComplaintDocket(
    ComplaintModel complaint, {
    BuildContext? context,
    String lang = 'en',
  }) async {
    // Load Devanagari font to eliminate all crossmarks/tofu boxes in Marathi and Hindi
    pw.ThemeData? theme;
    try {
      final fontRegular = await PdfGoogleFonts.notoSansDevanagariRegular();
      final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();
      theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    } catch (_) {}

    final pdf = pw.Document(theme: theme);
    final now = DateTime.now();
    final rawDate = DateFormat('dd/MM/yyyy, hh:mm a').format(now);
    final formattedDate = AppTranslations.formatDigits(rawDate, lang);

    final rawTicketId = complaint.id.length >= 8
        ? '#TKT-${complaint.id.substring(0, 8).toUpperCase()}'
        : '#${complaint.id}';
    final ticketId = AppTranslations.formatDigits(rawTicketId, lang);

    final rawCreatedDate = DateFormat('dd MMM yyyy').format(complaint.createdAt);
    final createdDateFormatted = AppTranslations.formatDigits(rawCreatedDate, lang);

    final systemTitle = lang == 'mr'
        ? 'नगरसेवक कार्यालय व्यवस्थापन प्रणाली'
        : (lang == 'hi' ? 'नगरसेवक कार्यालय प्रबंधन प्रणाली' : 'Nagarsevak Office Management System');
    final docketTitle = lang == 'mr'
        ? 'नागरिक तक्रार नोंदवही'
        : (lang == 'hi' ? 'नागरिक शिकायत डॉकेट' : 'CITIZEN GRIEVANCE DOCKET');
    final docketSubtitle = lang == 'mr'
        ? 'लोकसेवा निवारण अभिलेख'
        : (lang == 'hi' ? 'लोक सेवा निवारण रिकॉर्ड' : 'Public Services Redressal Record');

    final statusLabel = AppTranslations.getStatus(complaint.status, lang);
    final categoryLabel = AppTranslations.getComplaintType(complaint.category, lang);

    final citizenInfoHeading = lang == 'mr'
        ? 'नागरिक तपशील'
        : (lang == 'hi' ? 'नागरिक विवरण' : 'CITIZEN INFORMATION');
    final nameLabel = lang == 'mr' ? 'नाव:' : (lang == 'hi' ? 'नाम:' : 'Name:');
    final mobileLabel = lang == 'mr' ? 'मोबाईल:' : (lang == 'hi' ? 'मोबाइल:' : 'Mobile:');
    final locationLabel = lang == 'mr' ? 'पत्ता / परिसर:' : (lang == 'hi' ? 'स्थान / क्षेत्र:' : 'Location:');

    final anonymousText = lang == 'mr' ? 'निनावी' : (lang == 'hi' ? 'अनाम' : 'Anonymous');
    final rawCitizenName = complaint.citizenName?.trim();
    final citizenName = (rawCitizenName != null && rawCitizenName.isNotEmpty)
        ? ((lang == 'mr' || lang == 'hi')
            ? (DynamicTranslationService.getCachedTranslation(rawCitizenName, lang) ?? rawCitizenName)
            : rawCitizenName)
        : anonymousText;
    final citizenMobile = complaint.citizenMobile != null && complaint.citizenMobile!.trim().isNotEmpty
        ? AppTranslations.formatDigits(complaint.citizenMobile!, lang)
        : '-';

    final areaResolved = complaint.area != null && complaint.area!.trim().isNotEmpty
        ? AppTranslations.getAreaName(complaint.area!, lang)
        : '';
    final locResolved = complaint.location != null && complaint.location!.trim().isNotEmpty
        ? AppTranslations.getAreaName(complaint.location!, lang)
        : '';
    final locationText = areaResolved.isNotEmpty && locResolved.isNotEmpty
        ? '$areaResolved, $locResolved'
        : (areaResolved.isNotEmpty ? areaResolved : (locResolved.isNotEmpty ? locResolved : '-'));

    final subjectDescHeading = lang == 'mr'
        ? 'तक्रारीचा विषय आणि सविस्तर वर्णन'
        : (lang == 'hi' ? 'शिकायत का विषय एवं विस्तृत विवरण' : 'COMPLAINT SUBJECT & DESCRIPTION');

    final generatedByText = lang == 'mr'
        ? 'नगरसेवक व्यवस्थापन प्रणालीद्वारे तयार केलेले'
        : (lang == 'hi' ? 'नगरसेवक प्रबंधन प्रणाली द्वारा निर्मित' : 'Generated by Nagarsevak Management System');

    pdf.addPage(
      pw.Page(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: WebReportTheme.brand600, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          systemTitle,
                          style: const pw.TextStyle(fontSize: 9, color: WebReportTheme.slate500),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          docketTitle,
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          docketSubtitle,
                          style: const pw.TextStyle(fontSize: 9, color: WebReportTheme.slate500),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: WebReportTheme.brand50,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: WebReportTheme.brand600, width: 0.5),
                          ),
                          child: pw.Text(
                            ticketId,
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: WebReportTheme.brand700),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${lang == "mr" ? "दिनांक:" : (lang == "hi" ? "तारीख:" : "Date:")} $createdDateFormatted',
                          style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Status Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.slate50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: WebReportTheme.slate200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${lang == "mr" ? "स्थिती:" : (lang == "hi" ? "स्थिति:" : "STATUS:")} ${statusLabel.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                    pw.Text(
                      '${lang == "mr" ? "वर्गवारी:" : (lang == "hi" ? "श्रेणी:" : "CATEGORY:")} ${categoryLabel.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Citizen & Grievance Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      citizenInfoHeading,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('$nameLabel $citizenName', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Expanded(
                          child: pw.Text('$mobileLabel $citizenMobile', style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('$locationLabel $locationText', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Complaint description
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: WebReportTheme.slate200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      subjectDescHeading,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate700),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(complaint.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      complaint.description.isNotEmpty ? complaint.description : complaint.title,
                      style: const pw.TextStyle(fontSize: 9, lineSpacing: 2, color: WebReportTheme.slate800),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: WebReportTheme.slate100, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      generatedByText,
                      style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: WebReportTheme.slate400),
                    ),
                    pw.Text(
                      '${lang == "mr" ? "दिनांक:" : (lang == "hi" ? "तारीख:" : "Date:")} $formattedDate',
                      style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate400),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final docketLabel = lang == 'mr' ? 'तक्रार नोंद' : (lang == 'hi' ? 'शिकायत डॉकेट' : 'Grievance Docket');
    final fileName = 'Complaint_Docket_${complaint.id}';
    if (context != null) {
      await AppReportPreviewModal.show(
        context: context,
        title: docketLabel,
        subtitle: ticketId,
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
