import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/complaint_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Complaints Report Generator matching Nagarsevak-Managment (ComplaintReportGenerator.tsx)
class ComplaintReportGenerator {
  ComplaintReportGenerator._();

  static String _resolveArea(Map<String, String> cache, String? raw, String lang) {
    if (raw == null || raw.trim().isEmpty) return '';
    final clean = raw.trim();
    final domain = AppTranslations.getAreaName(clean, lang);
    final plainDigits = AppTranslations.formatDigits(clean, lang);
    if (domain != clean && domain != plainDigits) return domain;
    return PdfTranslationHelper.resolve(cache, clean, lang, fallback: clean);
  }

  static String _resolveStatus(Map<String, String> cache, String? raw, String lang) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final clean = raw.trim();
    final domain = AppTranslations.getStatus(clean, lang);
    final plainDigits = AppTranslations.formatDigits(clean, lang);
    if (domain.toLowerCase() != clean.toLowerCase() && domain != plainDigits) {
      return AppTranslations.formatDigits(domain, lang);
    }
    if (lang == 'en' && !RegExp(r'[\u0900-\u097F]').hasMatch(clean)) {
      return AppTranslations.formatDigits(domain, lang);
    }
    return PdfTranslationHelper.resolve(cache, clean, lang);
  }

  static String _resolveComplaintType(Map<String, String> cache, String? raw, String lang) {
    if (raw == null || raw.trim().isEmpty) return '';
    final clean = raw.trim();
    final domain = AppTranslations.getComplaintType(clean, lang);
    final plainDigits = AppTranslations.formatDigits(clean, lang);
    if (domain.toLowerCase() != clean.toLowerCase() && domain != plainDigits) {
      return AppTranslations.formatDigits(domain, lang);
    }
    if (lang == 'en' && !RegExp(r'[\u0900-\u097F]').hasMatch(clean)) {
      return AppTranslations.formatDigits(domain, lang);
    }
    return PdfTranslationHelper.resolve(cache, clean, lang, fallback: clean);
  }

  /// Generates and prints multi-complaint ledger report matching web ComplaintReportGenerator.tsx
  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<ComplaintModel> complaints,
    String? categoryFilter,
    String? statusFilter,
    String? areaFilter,
    String title = 'Complaints Report',
    String subtitle = 'Detailed Ward Complaints Register',
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);
    final total = complaints.length;

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        if (title != 'Complaints Report') title,
        if (subtitle != 'Detailed Ward Complaints Register') subtitle,
        categoryFilter,
        statusFilter,
        areaFilter,
        for (final c in complaints) ...[
          c.title,
          c.description,
          c.category,
          c.area,
          c.location,
          c.status,
          c.ward,
        ],
      ], activeLang),
      PdfTranslationHelper.batchNames([
        for (final c in complaints) ...[
          c.citizenName,
          c.assignedStaffName,
          c.addedByStaffName,
        ],
      ], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final resolvedTitle = (title == 'Complaints Report')
        ? AppTranslations.pick(
            activeLang,
            en: 'Complaints Report',
            mr: 'तक्रार व नागरी समस्या अहवाल',
            hi: 'शिकायत एवं नागरिक समस्या रिपोर्ट',
          )
        : PdfTranslationHelper.resolve(textCache, title, activeLang, fallback: title);

    final resolvedSubtitle = (subtitle == 'Detailed Ward Complaints Register')
        ? AppTranslations.pick(
            activeLang,
            en: 'Detailed Ward Complaints Register',
            mr: 'सविस्तर प्रभाग तक्रार नोंदवही',
            hi: 'विस्तृत वार्ड शिकायत रजिस्टर',
          )
        : PdfTranslationHelper.resolve(textCache, subtitle, activeLang, fallback: subtitle);

    final activeFilters = <String>[];
    if (categoryFilter != null && categoryFilter.trim().isNotEmpty && categoryFilter.trim().toLowerCase() != 'all') {
      final label = AppTranslations.pick(activeLang, en: 'Category', mr: 'वर्गवारी', hi: 'श्रेणी');
      activeFilters.add('$label: ${_resolveComplaintType(textCache, categoryFilter, activeLang)}');
    }
    if (statusFilter != null && statusFilter.trim().isNotEmpty && statusFilter.trim().toLowerCase() != 'all') {
      final label = AppTranslations.pick(activeLang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति');
      activeFilters.add('$label: ${_resolveStatus(textCache, statusFilter, activeLang)}');
    }
    if (areaFilter != null && areaFilter.trim().isNotEmpty && areaFilter.trim().toLowerCase() != 'all' && areaFilter.trim().toLowerCase() != 'all areas') {
      final label = AppTranslations.pick(activeLang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र');
      activeFilters.add('$label: ${_resolveArea(textCache, areaFilter, activeLang)}');
    }

    final anonymousText = AppTranslations.pick(activeLang, en: 'Anonymous', mr: 'निनावी', hi: 'अनाम');
    final unassignedText = AppTranslations.pick(activeLang, en: 'Unassigned', mr: 'अनियुक्त', hi: 'अनियुक्त');
    final emptyMsg = AppTranslations.pick(
      activeLang,
      en: 'No complaint records found for the selected filters.',
      mr: 'निवडलेल्या निकषांनुसार कोणत्याही तक्रारी आढळल्या नाहीत.',
      hi: 'चयनित फ़िल्टर के लिए कोई शिकायत रिकॉर्ड नहीं मिला।',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: resolvedTitle,
              lang: activeLang,
            );
          }
          return WebReportTheme.buildHeader(
            title: resolvedTitle,
            subtitle: resolvedSubtitle,
            dateFormatted: formattedDate,
            totalCount: total,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            if (activeFilters.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.slate50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
                ),
                child: pw.Text(
                  activeFilters.join('  |  '),
                  style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600),
                ),
              ),
            if (complaints.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  emptyMsg,
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
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
                  AppTranslations.getReportColumn('date_time', activeLang),
                  AppTranslations.getReportColumn('citizen_info', activeLang),
                  AppTranslations.getReportColumn('title_type', activeLang),
                  AppTranslations.getReportColumn('location_area', activeLang),
                  AppTranslations.getReportColumn('staff', activeLang),
                  AppTranslations.getReportColumn('status', activeLang),
                ],
                data: complaints.map((c) {
                  final dateStr = PdfTranslationHelper.formatDate(c.createdAt, activeLang, pattern: 'dd/MM/yyyy');
                  final timeStr = AppTranslations.formatTime(c.createdAt, activeLang);

                  final citizenName = PdfTranslationHelper.resolveName(
                    nameCache,
                    c.citizenName,
                    activeLang,
                    fallback: anonymousText,
                  );
                  final citizenMobile = c.citizenMobile != null && c.citizenMobile!.trim().isNotEmpty
                      ? PdfTranslationHelper.formatNumber(c.citizenMobile!.trim(), activeLang)
                      : '';
                  final citizenInfo = citizenMobile.isNotEmpty
                      ? '$citizenName\n$citizenMobile'
                      : citizenName;

                  final resolvedTitleText = PdfTranslationHelper.resolve(textCache, c.title, activeLang);
                  final typeStr = _resolveComplaintType(textCache, c.category, activeLang);
                  final titleType = typeStr.isNotEmpty ? '$resolvedTitleText\n($typeStr)' : resolvedTitleText;

                  final area = _resolveArea(textCache, c.area, activeLang);
                  final location = _resolveArea(textCache, c.location, activeLang);
                  final locationArea = area.isNotEmpty && location.isNotEmpty && area != location
                      ? '$area\n$location'
                      : (area.isNotEmpty ? area : (location.isNotEmpty ? location : '-'));

                  final staff = PdfTranslationHelper.resolveName(
                    nameCache,
                    c.assignedStaffName,
                    activeLang,
                    fallback: unassignedText,
                  );

                  return [
                    '$dateStr\n$timeStr',
                    citizenInfo,
                    titleType,
                    locationArea,
                    staff,
                    _resolveStatus(textCache, c.status, activeLang),
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
    final bool useHarfBuzzHtml = activeLang == 'mr' || activeLang == 'hi';

    Future<List<int>> buildPdfBytes() async {
      if (!useHarfBuzzHtml) return pdf.save();
      final htmlHeaders = [
        AppTranslations.getReportColumn('date_time', activeLang),
        AppTranslations.getReportColumn('citizen_info', activeLang),
        AppTranslations.getReportColumn('title_type', activeLang),
        AppTranslations.getReportColumn('location_area', activeLang),
        AppTranslations.getReportColumn('staff', activeLang),
        AppTranslations.getReportColumn('status', activeLang),
      ];
      final htmlRows = complaints.map((c) {
        final dateStr = PdfTranslationHelper.formatDate(c.createdAt, activeLang, pattern: 'dd/MM/yyyy');
        final timeStr = AppTranslations.formatTime(c.createdAt, activeLang);
        final citizenName = PdfTranslationHelper.resolveName(
          nameCache,
          c.citizenName,
          activeLang,
          fallback: AppTranslations.pick(activeLang, en: 'Anonymous', mr: 'निनावी', hi: 'अनाम'),
        );
        final citizenMobile = AppTranslations.formatDigits(c.citizenMobile ?? '', activeLang);
        final citizenInfo = citizenMobile.isNotEmpty ? '$citizenName\n$citizenMobile' : citizenName;
        final cTitle = PdfTranslationHelper.resolve(textCache, c.title, activeLang);
        final cType = _resolveComplaintType(textCache, c.category, activeLang);
        final titleInfo = cType.isNotEmpty ? '$cTitle\n($cType)' : cTitle;
        final area = _resolveArea(textCache, c.area ?? c.location, activeLang);
        final staff = PdfTranslationHelper.resolveName(
          nameCache,
          c.assignedStaffName,
          activeLang,
          fallback: AppTranslations.pick(activeLang, en: 'Unassigned', mr: 'अनियुक्त', hi: 'अनियुक्त'),
        );
        final status = _resolveStatus(textCache, c.status, activeLang);
        return ['$dateStr\n$timeStr', citizenInfo, titleInfo, area, staff, status];
      }).toList();

      try {
        return await WebReportTheme.generateHtmlPdfBytes(
          title: resolvedTitle,
          subtitle: resolvedSubtitle,
          dateFormatted: formattedDate,
          totalCount: total,
          headers: htmlHeaders,
          rows: htmlRows,
          summaryText: activeFilters.isNotEmpty ? activeFilters.join('  |  ') : null,
          lang: activeLang,
        );
      } catch (_) {
        return pdf.save();
      }
    }

    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: resolvedTitle,
        subtitle: resolvedSubtitle,
        fileName: fileName,
        onBuildPdf: () async => (await buildPdfBytes()) as dynamic,
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => (await buildPdfBytes()) as dynamic,
        name: '$fileName.pdf',
      );
    }
  }

  /// Generates and prints a single grievance docket (Portrait A4) matching web docket generator
  static Future<void> generateAndPrintSingleComplaintDocket(
    ComplaintModel complaint, {
    BuildContext? context,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        complaint.title,
        complaint.description,
        complaint.category,
        complaint.status,
        complaint.area,
        complaint.location,
        complaint.ward,
        complaint.workInProgress?.note,
        complaint.resolutionDetails?.note,
        for (final u in complaint.progressUpdates) u.note,
      ], activeLang),
      PdfTranslationHelper.batchNames([
        complaint.citizenName,
        complaint.assignedStaffName,
        complaint.addedByStaffName,
      ], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final rawTicketId = complaint.id.length >= 8
        ? '#TKT-${complaint.id.substring(0, 8).toUpperCase()}'
        : '#${complaint.id}';
    final ticketId = PdfTranslationHelper.formatNumber(rawTicketId, activeLang);
    final createdDateFormatted = PdfTranslationHelper.formatDate(
      complaint.createdAt,
      activeLang,
      pattern: 'dd MMM yyyy',
    );

    final systemTitle = AppTranslations.pick(
      activeLang,
      en: 'Nagarsevak Office Management System',
      mr: 'नगरसेवक कार्यालय व्यवस्थापन प्रणाली',
      hi: 'नगरसेवक कार्यालय प्रबंधन प्रणाली',
    );
    final docketTitle = AppTranslations.pick(
      activeLang,
      en: 'CITIZEN GRIEVANCE DOCKET',
      mr: 'नागरिक तक्रार नोंदवही',
      hi: 'नागरिक शिकायत डॉकेट',
    );
    final docketSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Public Services Redressal Record',
      mr: 'लोकसेवा निवारण अभिलेख',
      hi: 'लोक सेवा निवारण रिकॉर्ड',
    );

    final datePrefix = AppTranslations.pick(activeLang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:');
    final statusPrefix = AppTranslations.pick(activeLang, en: 'STATUS:', mr: 'स्थिती:', hi: 'स्थिति:');
    final categoryPrefix = AppTranslations.pick(activeLang, en: 'CATEGORY:', mr: 'वर्गवारी:', hi: 'श्रेणी:');

    final statusLabel = _resolveStatus(textCache, complaint.status, activeLang);
    final categoryLabel = _resolveComplaintType(textCache, complaint.category, activeLang);

    final citizenInfoHeading = AppTranslations.pick(
      activeLang,
      en: 'CITIZEN INFORMATION',
      mr: 'नागरिक तपशील',
      hi: 'नागरिक विवरण',
    );
    final nameLabel = AppTranslations.pick(activeLang, en: 'Name:', mr: 'नाव:', hi: 'नाम:');
    final mobileLabel = AppTranslations.pick(activeLang, en: 'Mobile:', mr: 'मोबाईल:', hi: 'मोबाइल:');
    final locationLabel = AppTranslations.pick(activeLang, en: 'Location:', mr: 'पत्ता / परिसर:', hi: 'स्थान / क्षेत्र:');
    final assignedLabel = AppTranslations.pick(activeLang, en: 'Assigned Staff:', mr: 'नियुक्त कर्मचारी:', hi: 'नियुक्त कर्मचारी:');

    final anonymousText = AppTranslations.pick(activeLang, en: 'Anonymous', mr: 'निनावी', hi: 'अनाम');
    final unassignedText = AppTranslations.pick(activeLang, en: 'Unassigned', mr: 'अनियुक्त', hi: 'अनियुक्त');

    final citizenName = PdfTranslationHelper.resolveName(
      nameCache,
      complaint.citizenName,
      activeLang,
      fallback: anonymousText,
    );
    final citizenMobile = complaint.citizenMobile != null && complaint.citizenMobile!.trim().isNotEmpty
        ? PdfTranslationHelper.formatNumber(complaint.citizenMobile!.trim(), activeLang)
        : '-';
    final staffName = PdfTranslationHelper.resolveName(
      nameCache,
      complaint.assignedStaffName,
      activeLang,
      fallback: unassignedText,
    );

    final areaResolved = _resolveArea(textCache, complaint.area, activeLang);
    final locResolved = _resolveArea(textCache, complaint.location, activeLang);
    final locationText = areaResolved.isNotEmpty && locResolved.isNotEmpty && areaResolved != locResolved
        ? '$areaResolved, $locResolved'
        : (areaResolved.isNotEmpty ? areaResolved : (locResolved.isNotEmpty ? locResolved : '-'));

    final subjectDescHeading = AppTranslations.pick(
      activeLang,
      en: 'COMPLAINT SUBJECT & DESCRIPTION',
      mr: 'तक्रारीचा विषय आणि सविस्तर वर्णन',
      hi: 'शिकायत का विषय एवं विस्तृत विवरण',
    );

    final titleText = PdfTranslationHelper.resolve(textCache, complaint.title, activeLang);
    final descText = complaint.description.trim().isNotEmpty
        ? PdfTranslationHelper.resolve(textCache, complaint.description, activeLang)
        : titleText;

    final generatedByText = AppTranslations.formatDigits(
      AppTranslations.t('common.generated_by', lang: activeLang),
      activeLang,
    );

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
                          '$datePrefix $createdDateFormatted',
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
                      '$statusPrefix ${activeLang == 'en' ? statusLabel.toUpperCase() : statusLabel}',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.brand700,
                      ),
                    ),
                    pw.Text(
                      '$categoryPrefix ${activeLang == 'en' ? categoryLabel.toUpperCase() : categoryLabel}',
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
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('$locationLabel $locationText', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Expanded(
                          child: pw.Text('$assignedLabel $staffName', style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ],
                    ),
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
                    pw.Text(titleText, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: WebReportTheme.slate900)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      descText,
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
                      '$datePrefix $formattedDate',
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

    final docketLabel = AppTranslations.pick(
      activeLang,
      en: 'Grievance Docket',
      mr: 'तक्रार नोंद',
      hi: 'शिकायत डॉकेट',
    );
    final fileName = 'Complaint_Docket_${complaint.id}';
    if (context != null) {
      if (!context.mounted) return;
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
