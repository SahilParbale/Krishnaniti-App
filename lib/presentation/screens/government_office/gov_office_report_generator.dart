import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/government_office_model.dart';
import '../../../data/models/work_tracker_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class GovOfficeReportGenerator {
  GovOfficeReportGenerator._();

  static Future<void> generateAndPrintOfficeReport({
    BuildContext? context,
    required List<GovernmentOfficeModel> offices,
    String? categoryFilter,
    String? areaFilter,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr =
        PdfTranslationHelper.formatDate(now, activeLang, pattern: 'dd/MM/yyyy');

    final hasCategoryFilter = categoryFilter != null &&
        categoryFilter.trim().isNotEmpty &&
        categoryFilter != 'All';
    final hasAreaFilter = areaFilter != null &&
        areaFilter.trim().isNotEmpty &&
        areaFilter != 'All' &&
        areaFilter != 'All Areas';

    final textCache = await PdfTranslationHelper.batchText(
      [
        if (hasCategoryFilter) categoryFilter,
        if (hasAreaFilter) areaFilter,
        for (final o in offices) ...[o.name, o.address, o.area, o.category],
      ],
      activeLang,
    );
    final nameCache = await PdfTranslationHelper.batchNames(
      [
        for (final o in offices)
          if (o.officerName.trim().isNotEmpty &&
              o.officerName.trim().toLowerCase() != 'officer in-charge')
            o.officerName,
      ],
      activeLang,
    );

    final totalCount = offices.length;
    final emergencyCount = offices.where((o) => o.isEmergency).length;
    final municipalCount =
        offices.where((o) => o.category.toLowerCase().contains('municipal')).length;
    final policeCount =
        offices.where((o) => o.category.toLowerCase().contains('police')).length;

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Government Offices',
      mr: 'शासकीय कार्यालये',
      hi: 'शासकीय कार्यालय',
    );
    final continuationTitle = AppTranslations.pick(
      activeLang,
      en: 'Government Offices Directory',
      mr: 'शासकीय कार्यालये निर्देशिका',
      hi: 'शासकीय कार्यालय निर्देशिका',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Directory of Key Government Departments & Administrative Officers',
      mr: 'प्रमुख शासकीय विभाग आणि प्रशासकीय अधिकाऱ्यांची निर्देशिका',
      hi: 'प्रमुख सरकारी विभागों और प्रशासनिक अधिकारियों की निर्देशिका',
    );
    final dateLabel = AppTranslations.pick(
      activeLang,
      en: 'Date',
      mr: 'दिनांक',
      hi: 'दिनांक',
    );
    final countLabel = AppTranslations.pick(
      activeLang,
      en: 'Count',
      mr: 'एकूण',
      hi: 'कुल',
    );
    final categoryLabel = AppTranslations.pick(
      activeLang,
      en: 'Category',
      mr: 'वर्गवारी',
      hi: 'श्रेणी',
    );
    final areaLabel = AppTranslations.pick(
      activeLang,
      en: 'Area',
      mr: 'परिसर',
      hi: 'क्षेत्र',
    );
    final emergencyBadgeLabel = AppTranslations.pick(
      activeLang,
      en: ' [Emergency]',
      mr: ' [आपत्कालीन]',
      hi: ' [आपातकालीन]',
    );
    final defaultOfficerLabel = AppTranslations.pick(
      activeLang,
      en: 'Officer In-Charge',
      mr: 'प्रभारी अधिकारी',
      hi: 'प्रभारी अधिकारी',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: continuationTitle,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) =>
            WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: reportTitle,
              subtitle: reportSubtitle,
              lang: activeLang,
              metaLines: [
                '$dateLabel: $nowStr',
                '$countLabel: ${PdfTranslationHelper.formatNumber(totalCount, activeLang)}',
                if (hasCategoryFilter)
                  '$categoryLabel: ${_resolveOfficeCategory(categoryFilter, textCache, activeLang)}',
                if (hasAreaFilter)
                  '$areaLabel: ${_resolveArea(areaFilter, textCache, activeLang)}',
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary strip
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Authorities',
                      mr: 'एकूण कार्यालये',
                      hi: 'कुल कार्यालय',
                    ),
                    PdfTranslationHelper.formatNumber(totalCount, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Emergency 24x7',
                      mr: 'आपत्कालीन २४x७',
                      hi: 'आपातकालीन २४x७',
                    ),
                    PdfTranslationHelper.formatNumber(emergencyCount, activeLang),
                    highlightColor: PdfColors.red700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Municipal Centers',
                      mr: 'मनपा केंद्रे',
                      hi: 'नगर निगम केंद्र',
                    ),
                    PdfTranslationHelper.formatNumber(municipalCount, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Police / Security',
                      mr: 'पोलीस / सुरक्षा',
                      hi: 'पुलिस / सुरक्षा',
                    ),
                    PdfTranslationHelper.formatNumber(policeCount, activeLang),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (offices.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No government office records found for the selected view.',
                    mr: 'निवडलेल्या पर्यायासाठी शासकीय कार्यालयांच्या नोंदी आढळल्या नाहीत.',
                    hi: 'चयनित दृश्य के लिए कोई सरकारी कार्यालय रिकॉर्ड नहीं मिला।',
                  ),
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: WebReportTheme.slate500,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(3.0),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(2.0),
                  4: pw.FlexColumnWidth(2.5),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Office / Department',
                    mr: 'कार्यालय / विभाग',
                    hi: 'कार्यालय / विभाग',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Officer Name',
                    mr: 'अधिकाऱ्याचे नाव',
                    hi: 'अधिकारी का नाम',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Contact Number',
                    mr: 'संपर्क क्रमांक',
                    hi: 'संपर्क नंबर',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Address & Area',
                    mr: 'पत्ता आणि परिसर',
                    hi: 'पता और क्षेत्र',
                  ),
                ],
                data: List.generate(offices.length, (index) {
                  final item = offices[index];
                  final officeName =
                      PdfTranslationHelper.resolve(textCache, item.name, activeLang);
                  final emergencyBadge =
                      item.isEmergency ? emergencyBadgeLabel : '';
                  final officerStr = item.officerName.trim().isEmpty
                      ? '-'
                      : (item.officerName.trim().toLowerCase() ==
                              'officer in-charge'
                          ? defaultOfficerLabel
                          : PdfTranslationHelper.resolveName(
                              nameCache,
                              item.officerName,
                              activeLang,
                            ));
                  final contacts = [item.contactNumber, item.secondaryContact]
                      .where((s) => s != null && s.trim().isNotEmpty)
                      .map((s) =>
                          PdfTranslationHelper.formatNumber(s!.trim(), activeLang))
                      .join('\n');
                  final addrStr = item.address.trim().isNotEmpty
                      ? PdfTranslationHelper.resolve(
                          textCache,
                          item.address,
                          activeLang,
                        )
                      : '';
                  final areaStr = item.area.trim().isNotEmpty
                      ? _resolveArea(item.area, textCache, activeLang)
                      : '';
                  final addressPart = [
                    if (addrStr.isNotEmpty) addrStr,
                    if (areaStr.isNotEmpty) '$areaLabel: $areaStr',
                  ].join('\n');

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$officeName$emergencyBadge',
                    officerStr,
                    contacts.isNotEmpty ? contacts : '-',
                    addressPart.isNotEmpty ? addressPart : '-',
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName =
        'Government_Offices_Directory_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: reportTitle,
        subtitle: reportSubtitle,
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

  /// Official File Tracker & Departmental Work Movement Report
  static Future<void> generateAndPrintFileTrackerReport({
    BuildContext? context,
    required List<WorkTrackerModel> trackers,
    String? statusFilter,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDateTime(now, activeLang);

    final hasStatusFilter = statusFilter != null &&
        statusFilter.trim().isNotEmpty &&
        statusFilter != 'All';

    final textCache = await PdfTranslationHelper.batchText(
      [
        if (hasStatusFilter) statusFilter,
        for (final t in trackers) ...[
          t.title,
          t.description,
          t.subject,
          t.department,
          t.currentStatus,
        ],
      ],
      activeLang,
    );

    final totalCount = trackers.length;
    final inProcessCount = trackers
        .where((t) =>
            t.currentStatus.toLowerCase().contains('process') ||
            t.currentStatus.toLowerCase().contains('pending'))
        .length;
    final completedCount = trackers
        .where((t) =>
            t.currentStatus.toLowerCase().contains('complete') ||
            t.currentStatus.toLowerCase().contains('dispatched') ||
            t.currentStatus.toLowerCase().contains('approved'))
        .length;
    final actionRequiredCount = trackers
        .where((t) =>
            t.currentStatus.toLowerCase().contains('action') ||
            t.currentStatus.toLowerCase().contains('review'))
        .length;

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Municipal File Tracker',
      mr: 'मनपा फाईल मागोवा',
      hi: 'नगरपालिका फाइल ट्रैकर',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Department Inward/Outward Document Progression & Approval Dossier',
      mr: 'विभागीय आवक/जावक दस्तऐवज प्रगती आणि मंजुरी अहवाल',
      hi: 'विभागीय आवक/जावक दस्तावेज़ प्रगति और स्वीकृति विवरण',
    );
    final modalTitle = AppTranslations.pick(
      activeLang,
      en: 'Municipal File Movement Tracker',
      mr: 'मनपा फाईल हालचाल मागोवा',
      hi: 'नगरपालिका फाइल मूवमेंट ट्रैकर',
    );
    final modalSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Follow-up Docket for Administrative Files, Approvals & Letters',
      mr: 'प्रशासकीय फाईल्स, मंजुरी आणि पत्रांसाठी पाठपुरावा नोंदवही',
      hi: 'प्रशासनिक फाइलों, स्वीकृतियों और पत्रों का फॉलो-अप रिकॉर्ड',
    );
    final dateLabel = AppTranslations.pick(
      activeLang,
      en: 'Date',
      mr: 'दिनांक',
      hi: 'दिनांक',
    );
    final foundLabel = AppTranslations.pick(
      activeLang,
      en: 'Found',
      mr: 'एकूण',
      hi: 'कुल',
    );
    final statusLabel = AppTranslations.pick(
      activeLang,
      en: 'Status',
      mr: 'स्थिती',
      hi: 'स्थिति',
    );
    final deptPrefix = AppTranslations.pick(
      activeLang,
      en: 'Dept',
      mr: 'विभाग',
      hi: 'विभाग',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return WebReportTheme.buildContinuationHeader(
            context,
            title: reportTitle,
            lang: activeLang,
          );
        },
        footer: (pw.Context context) =>
            WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: reportTitle,
              subtitle: reportSubtitle,
              lang: activeLang,
              metaLines: [
                '$dateLabel: $nowStr',
                '$foundLabel: ${PdfTranslationHelper.formatNumber(totalCount, activeLang)}',
                if (hasStatusFilter)
                  '$statusLabel: ${_resolveTrackerStatus(statusFilter, textCache, activeLang)}',
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Total Files',
                      mr: 'एकूण फाईल्स',
                      hi: 'कुल फाइलें',
                    ),
                    PdfTranslationHelper.formatNumber(totalCount, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'In Process',
                      mr: 'प्रक्रियेत',
                      hi: 'प्रक्रिया में',
                    ),
                    PdfTranslationHelper.formatNumber(inProcessCount, activeLang),
                    highlightColor: PdfColors.amber800,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Completed',
                      mr: 'पूर्ण',
                      hi: 'पूर्ण',
                    ),
                    PdfTranslationHelper.formatNumber(completedCount, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Action Required',
                      mr: 'कार्यवाही आवश्यक',
                      hi: 'कार्रवाई आवश्यक',
                    ),
                    PdfTranslationHelper.formatNumber(
                      actionRequiredCount,
                      activeLang,
                    ),
                    highlightColor: PdfColors.red700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (trackers.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No file tracking records found for the selected view.',
                    mr: 'निवडलेल्या पर्यायासाठी फाईल मागोवा नोंदी आढळल्या नाहीत.',
                    hi: 'चयनित दृश्य के लिए कोई फाइल ट्रैकिंग रिकॉर्ड नहीं मिला।',
                  ),
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: WebReportTheme.slate500,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(2.8),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(1.4),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.4),
                  6: pw.FlexColumnWidth(1.4),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'File Title & Scope',
                    mr: 'फाईल शीर्षक आणि तपशील',
                    hi: 'फाइल शीर्षक और विवरण',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Subject / Dept',
                    mr: 'विषय / विभाग',
                    hi: 'विषय / विभाग',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Inward No.',
                    mr: 'आवक क्र.',
                    hi: 'आवक सं.',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Outward No.',
                    mr: 'जावक क्र.',
                    hi: 'जावक सं.',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Status',
                    mr: 'स्थिती',
                    hi: 'स्थिति',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Updated',
                    mr: 'अद्ययावत',
                    hi: 'अद्यतन',
                  ),
                ],
                data: List.generate(trackers.length, (index) {
                  final t = trackers[index];
                  final titleStr =
                      PdfTranslationHelper.resolve(textCache, t.title, activeLang);
                  final descPart = t.description.trim().isNotEmpty
                      ? '\n${PdfTranslationHelper.resolve(textCache, t.description, activeLang)}'
                      : '';
                  final subjectStr =
                      PdfTranslationHelper.resolve(textCache, t.subject, activeLang);
                  final deptPart = t.department.trim().isNotEmpty
                      ? '\n$deptPrefix: ${PdfTranslationHelper.resolve(textCache, t.department, activeLang)}'
                      : '';
                  final updatedStr =
                      PdfTranslationHelper.formatDate(t.updatedAt, activeLang);

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    '$titleStr$descPart',
                    '$subjectStr$deptPart',
                    t.inwardNumber.trim().isNotEmpty
                        ? PdfTranslationHelper.formatNumber(
                            t.inwardNumber.trim(),
                            activeLang,
                          )
                        : '-',
                    t.outwardNumber.trim().isNotEmpty
                        ? PdfTranslationHelper.formatNumber(
                            t.outwardNumber.trim(),
                            activeLang,
                          )
                        : '-',
                    _resolveTrackerStatus(t.currentStatus, textCache, activeLang),
                    updatedStr,
                  ];
                }),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName =
        'Municipal_File_Tracker_Report_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: modalTitle,
        subtitle: modalSubtitle,
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

  static String _resolveOfficeCategory(
    String raw,
    Map<String, String> textCache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    switch (trimmed.toLowerCase()) {
      case 'police':
        return AppTranslations.pick(
          lang,
          en: 'Police',
          mr: 'पोलीस ठाणे',
          hi: 'पुलिस थाना',
        );
      case 'fire & disaster':
      case 'emergency':
        return AppTranslations.pick(
          lang,
          en: 'Fire & Disaster',
          mr: 'अग्निशमन व आपत्ती',
          hi: 'अग्निशमन एवं आपदा',
        );
      case 'msedcl electricity':
      case 'electricity':
        return AppTranslations.pick(
          lang,
          en: 'MSEDCL Electricity',
          mr: 'महावितरण विद्युत',
          hi: 'महावितरण विद्युत',
        );
      case 'water supply':
        return AppTranslations.pick(
          lang,
          en: 'Water Supply',
          mr: 'पाणी पुरवठा विभाग',
          hi: 'जल आपूर्ति विभाग',
        );
      case 'health & hospital':
      case 'health':
        return AppTranslations.pick(
          lang,
          en: 'Health & Hospital',
          mr: 'आरोग्य व रुग्णालय',
          hi: 'स्वास्थ्य एवं अस्पताल',
        );
      case 'revenue & post':
        return AppTranslations.pick(
          lang,
          en: 'Revenue & Post',
          mr: 'महसूल व पोस्ट',
          hi: 'राजस्व एवं डाक',
        );
      case 'municipal pmc':
        return AppTranslations.pick(
          lang,
          en: 'Municipal PMC',
          mr: 'मनपा क्षेत्रीय कार्यालय',
          hi: 'नगर निगम कार्यालय',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, trimmed, lang);
    }
  }

  static String _resolveTrackerStatus(
    String raw,
    Map<String, String> textCache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    switch (trimmed.toLowerCase()) {
      case 'pending':
        return AppTranslations.pick(
          lang,
          en: 'Pending',
          mr: 'प्रलंबित',
          hi: 'लंबित',
        );
      case 'in progress':
      case 'inprogress':
      case 'in process':
        return AppTranslations.pick(
          lang,
          en: 'In Process',
          mr: 'प्रक्रियेत',
          hi: 'प्रक्रिया में',
        );
      case 'approved':
        return AppTranslations.pick(
          lang,
          en: 'Approved',
          mr: 'मंजूर',
          hi: 'स्वीकृत',
        );
      case 'completed':
      case 'complete':
        return AppTranslations.pick(
          lang,
          en: 'Completed',
          mr: 'पूर्ण',
          hi: 'पूर्ण',
        );
      case 'dispatched':
        return AppTranslations.pick(
          lang,
          en: 'Dispatched',
          mr: 'रवाना झाले',
          hi: 'प्रेषित',
        );
      case 'action required':
        return AppTranslations.pick(
          lang,
          en: 'Action Required',
          mr: 'कार्यवाही आवश्यक',
          hi: 'कार्रवाई आवश्यक',
        );
      case 'review':
      case 'under review':
        return AppTranslations.pick(
          lang,
          en: 'Under Review',
          mr: 'पुनरावलोकनाधीन',
          hi: 'समीक्षाधीन',
        );
      case 'rejected':
        return AppTranslations.pick(
          lang,
          en: 'Rejected',
          mr: 'नाकारले',
          hi: 'अस्वीकृत',
        );
      default:
        final staticMatch = AppTranslations.getStatus(trimmed, lang);
        if (staticMatch != trimmed) {
          return PdfTranslationHelper.formatNumber(staticMatch, lang);
        }
        return PdfTranslationHelper.resolve(textCache, trimmed, lang);
    }
  }

  static String _resolveArea(
    String? raw,
    Map<String, String> textCache,
    String lang,
  ) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final trimmed = raw.trim();
    final staticArea = AppTranslations.getAreaName(trimmed, lang);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(staticArea);
    if (staticArea != AppTranslations.formatDigits(trimmed, lang)) {
      return staticArea;
    }
    if (lang == 'en' && !hasDevanagari) {
      return staticArea;
    }
    return PdfTranslationHelper.resolve(textCache, trimmed, lang);
  }

  static pw.Widget _buildSummaryItem(
    String label,
    String value, {
    PdfColor? highlightColor,
  }) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: WebReportTheme.slate500),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: highlightColor ?? WebReportTheme.slate800,
            ),
          ),
        ],
      ),
    );
  }
}
