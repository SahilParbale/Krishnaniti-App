import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/diary_task_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

/// Official Tasks & Daily Work Diary Report Generator matching Nagarsevak-Managment
/// (TaskReportGenerator.tsx).
class DiaryReportGenerator {
  DiaryReportGenerator._();

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

  static String _resolvePriority(Map<String, String> cache, String? raw, String lang) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final clean = raw.trim();
    final domain = AppTranslations.getPriority(clean, lang);
    final plainDigits = AppTranslations.formatDigits(clean, lang);
    if (domain.toLowerCase() != clean.toLowerCase() && domain != plainDigits) {
      return AppTranslations.formatDigits(domain, lang);
    }
    if (lang == 'en' && !RegExp(r'[\u0900-\u097F]').hasMatch(clean)) {
      return AppTranslations.formatDigits(domain, lang);
    }
    return PdfTranslationHelper.resolve(cache, clean, lang);
  }

  static String _formatTaskTime(String? rawTime, String lang) {
    if (rawTime == null || rawTime.trim().isEmpty) return '';
    final clean = AppTranslations.normalizeAsciiDigits(rawTime.trim());
    final amPmMatch = RegExp(r'^(\d{1,2}):(\d{2})\s*(am|pm)$', caseSensitive: false).firstMatch(clean);
    if (amPmMatch != null) {
      var hour = int.parse(amPmMatch.group(1)!);
      final min = int.parse(amPmMatch.group(2)!);
      final isPm = amPmMatch.group(3)!.toLowerCase() == 'pm';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      if (hour >= 0 && hour <= 23 && min >= 0 && min <= 59) {
        return AppTranslations.formatTime(DateTime(2026, 1, 1, hour, min), lang);
      }
    }
    final parts = clean.split(':');
    if (parts.length >= 2 && !clean.toLowerCase().contains('am') && !clean.toLowerCase().contains('pm')) {
      final hour = int.tryParse(parts[0].trim());
      final min = int.tryParse(parts[1].replaceAll(RegExp(r'\D.*'), ''));
      if (hour != null && min != null && hour >= 0 && hour <= 23 && min >= 0 && min <= 59) {
        return AppTranslations.formatTime(DateTime(2026, 1, 1, hour, min), lang);
      }
    }
    return AppTranslations.formatDigits(rawTime.trim(), lang);
  }

  static Future<void> generateAndPrintTasksReport({
    BuildContext? context,
    required List<DiaryTaskModel> tasks,
    String? filterTitle,
    String title = 'Daily Work Diary & Tasks Report',
    String subtitle = 'Executive Itinerary & Scheduled Field Tasks',
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);
    final total = tasks.length;

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        if (title != 'Daily Work Diary & Tasks Report') title,
        if (subtitle != 'Executive Itinerary & Scheduled Field Tasks') subtitle,
        filterTitle,
        for (final t in tasks) ...[
          t.title,
          t.description,
          t.address,
          t.officeName,
          t.priority,
          t.status,
        ],
      ], activeLang),
      PdfTranslationHelper.batchNames([
        for (final t in tasks) ...[
          t.meetPersonName,
          t.assignedStaffName,
        ],
      ], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final effectiveTitle = title != 'Daily Work Diary & Tasks Report'
        ? PdfTranslationHelper.resolve(textCache, title, activeLang, fallback: title)
        : AppTranslations.pick(
            activeLang,
            en: 'Daily Work Diary & Tasks Report',
            mr: 'दैनंदिनी आणि कार्ये अहवाल',
            hi: 'दैनिक डायरी और कार्य रिपोर्ट',
          );
    final effectiveSubtitle = subtitle != 'Executive Itinerary & Scheduled Field Tasks'
        ? PdfTranslationHelper.resolve(textCache, subtitle, activeLang, fallback: subtitle)
        : AppTranslations.pick(
            activeLang,
            en: 'Executive Itinerary & Scheduled Field Tasks',
            mr: 'नियोजित कार्ये आणि फील्ड भेटी',
            hi: 'अनुसूचित कार्य और फील्ड बैठकें',
          );

    final resolvedFilter = (filterTitle != null && filterTitle.trim().isNotEmpty)
        ? PdfTranslationHelper.resolve(textCache, filterTitle, activeLang)
        : '';

    final meetPrefix = AppTranslations.pick(activeLang, en: 'Meet', mr: 'भेट', hi: 'मुलाकात');
    final emptyMsg = AppTranslations.pick(
      activeLang,
      en: 'No tasks or diary entries found.',
      mr: 'कोणत्याही कार्याच्या नोंदी आढळल्या नाहीत.',
      hi: 'कोई कार्य या डायरी प्रविष्टि नहीं मिली।',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: effectiveTitle,
              lang: activeLang,
            );
          }
          return WebReportTheme.buildHeader(
            title: effectiveTitle,
            subtitle: effectiveSubtitle,
            dateFormatted: formattedDate,
            totalCount: total,
            foundLabel: AppTranslations.pick(
              activeLang,
              en: 'Total Tasks',
              mr: 'एकूण कार्ये',
              hi: 'कुल कार्य',
            ),
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            if (resolvedFilter.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: WebReportTheme.slate50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
                ),
                child: pw.Text(
                  resolvedFilter,
                  style: const pw.TextStyle(fontSize: 8.5, color: WebReportTheme.slate600),
                ),
              ),
            if (tasks.isEmpty)
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
                  0: pw.FlexColumnWidth(0.6), // #
                  1: pw.FlexColumnWidth(2.8), // Task Title & Description
                  2: pw.FlexColumnWidth(1.2), // Priority
                  3: pw.FlexColumnWidth(1.6), // Due Date & Time
                  4: pw.FlexColumnWidth(2.2), // Location & Contact
                  5: pw.FlexColumnWidth(1.2), // Status
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(activeLang, en: 'Task Title & Details', mr: 'कार्याचे शीर्षक आणि तपशील', hi: 'कार्य शीर्षक और विवरण'),
                  AppTranslations.getReportColumn('priority', activeLang),
                  AppTranslations.pick(activeLang, en: 'Due Date / Time', mr: 'देय तारीख / वेळ', hi: 'नियत तारीख / समय'),
                  AppTranslations.pick(activeLang, en: 'Location / Contact', mr: 'स्थान / संपर्क', hi: 'स्थान / संपर्क'),
                  AppTranslations.getReportColumn('status', activeLang),
                ],
                data: List.generate(tasks.length, (index) {
                  final t = tasks[index];
                  final dateStr = t.dueDate != null
                      ? PdfTranslationHelper.formatDate(t.dueDate, activeLang, pattern: 'dd/MM/yyyy')
                      : '-';
                  final timeStr = _formatTaskTime(t.dueTime, activeLang);
                  final due = timeStr.isNotEmpty ? '$dateStr\n$timeStr' : dateStr;

                  final resolvedTitleText = PdfTranslationHelper.resolve(textCache, t.title, activeLang);
                  final resolvedDesc = (t.description != null && t.description!.trim().isNotEmpty)
                      ? PdfTranslationHelper.resolve(textCache, t.description, activeLang)
                      : '';
                  final desc = resolvedDesc.isNotEmpty
                      ? '$resolvedTitleText\n$resolvedDesc'
                      : resolvedTitleText;

                  final loc = (t.address != null && t.address!.trim().isNotEmpty)
                      ? PdfTranslationHelper.resolve(textCache, t.address, activeLang)
                      : PdfTranslationHelper.resolve(textCache, t.officeName, activeLang);
                  final meet = (t.meetPersonName != null && t.meetPersonName!.trim().isNotEmpty)
                      ? '\n$meetPrefix: ${PdfTranslationHelper.resolveName(nameCache, t.meetPersonName, activeLang)}'
                      : '';

                  final priorityStr = _resolvePriority(textCache, t.priority, activeLang);
                  final statusStr = _resolveStatus(textCache, t.status, activeLang);

                  return [
                    PdfTranslationHelper.formatNumber(index + 1, activeLang),
                    desc,
                    activeLang == 'en' ? priorityStr.toUpperCase() : priorityStr,
                    due,
                    '$loc$meet',
                    activeLang == 'en' ? statusStr.toUpperCase() : statusStr,
                  ];
                }),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.center,
                },
              ),
          ];
        },
      ),
    );

    final fileName = 'Task_Report_${DateFormat('yyyy-MM-dd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: effectiveTitle,
        subtitle: effectiveSubtitle,
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

  /// Generates a single Task / Diary docket
  static Future<void> generateAndPrintSingleTask(
    DiaryTaskModel task, {
    BuildContext? context,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty) ? lang : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final formattedDate = PdfTranslationHelper.formatDateTime(now, activeLang);

    final results = await Future.wait([
      PdfTranslationHelper.batchText([
        task.title,
        task.description,
        task.address,
        task.officeName,
        task.status,
        task.priority,
      ], activeLang),
      PdfTranslationHelper.batchNames([
        task.meetPersonName,
        task.assignedStaffName,
      ], activeLang),
    ]);
    final textCache = results[0];
    final nameCache = results[1];

    final taskDueDateStr = task.dueDate != null
        ? PdfTranslationHelper.formatDate(task.dueDate, activeLang, pattern: 'dd/MM/yyyy')
        : AppTranslations.pick(activeLang, en: 'Not scheduled', mr: 'नियोजित नाही', hi: 'निर्धारित नहीं');
    final taskDueTimeStr = _formatTaskTime(task.dueTime, activeLang);
    final taskIdDisplay = PdfTranslationHelper.formatNumber(task.id, activeLang);

    final docketTitle = AppTranslations.pick(
      activeLang,
      en: 'Task / Diary Docket',
      mr: 'कार्य / दैनंदिनी डॉकेट',
      hi: 'कार्य / डायरी डॉकेट',
    );
    final docketSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Office of Nagarsevak • Executive Schedule & Action Item',
      mr: 'नगरसेवक कार्यालय • दैनिक वेळापत्रक व कृती नोंद',
      hi: 'नगरसेवक कार्यालय • दैनिक अनुसूची और कार्य विवरण',
    );
    final taskIdLabel = AppTranslations.pick(activeLang, en: 'Task ID', mr: 'कार्य क्र.', hi: 'कार्य आईडी');

    final statusLabel = AppTranslations.pick(activeLang, en: 'STATUS:', mr: 'स्थिती:', hi: 'स्थिति:');
    final priorityLabel = AppTranslations.pick(activeLang, en: 'PRIORITY:', mr: 'प्राधान्य:', hi: 'प्राथमिकता:');
    final assignedToLabel = AppTranslations.pick(activeLang, en: 'ASSIGNED TO:', mr: 'नियुक्त:', hi: 'नियुक्त:');

    final statusValue = _resolveStatus(textCache, task.status, activeLang);
    final priorityValue = _resolvePriority(textCache, task.priority, activeLang);
    final unassignedText = AppTranslations.pick(activeLang, en: 'Unassigned', mr: 'अनियुक्त', hi: 'अनियुक्त');
    final assignedValue = PdfTranslationHelper.resolveName(
      nameCache,
      task.assignedStaffName,
      activeLang,
      fallback: unassignedText,
    );

    final taskTitleHeading = AppTranslations.pick(activeLang, en: 'TASK TITLE', mr: 'कार्याचे शीर्षक', hi: 'कार्य शीर्षक');
    final descHeading = AppTranslations.pick(activeLang, en: 'DESCRIPTION / NOTES', mr: 'तपशील / नोंदी', hi: 'विवरण / टिप्पणी');

    final resolvedTitle = PdfTranslationHelper.resolve(textCache, task.title, activeLang);
    final resolvedDesc = (task.description != null && task.description!.trim().isNotEmpty)
        ? PdfTranslationHelper.resolve(textCache, task.description, activeLang)
        : '';
    final resolvedAddress = PdfTranslationHelper.resolve(textCache, task.address, activeLang);
    final resolvedOffice = PdfTranslationHelper.resolve(textCache, task.officeName, activeLang);
    final resolvedMeetPerson = PdfTranslationHelper.resolveName(nameCache, task.meetPersonName, activeLang);
    final resolvedStaff = PdfTranslationHelper.resolveName(nameCache, task.assignedStaffName, activeLang);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: WebReportTheme.pageFormat,
        margin: WebReportTheme.pageMargin,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return WebReportTheme.buildContinuationHeader(
              context,
              title: '$docketTitle • $taskIdDisplay',
              lang: activeLang,
            );
          }
          return WebReportTheme.buildHeader(
            title: docketTitle,
            subtitle: docketSubtitle,
            dateFormatted: formattedDate,
            totalCount: 1,
            foundLabel: '$taskIdLabel: $taskIdDisplay',
            lang: activeLang,
          );
        },
        footer: (pw.Context context) => WebReportTheme.buildFooter(context, lang: activeLang),
        build: (pw.Context context) {
          return [
            // Status and priority strip
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const pw.BoxDecoration(
                color: WebReportTheme.slate50,
                border: pw.Border(
                  left: pw.BorderSide(color: WebReportTheme.brand600, width: 3),
                  top: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                  right: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                  bottom: pw.BorderSide(color: WebReportTheme.slate200, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '$statusLabel ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate700,
                        ),
                      ),
                      pw.Text(
                        activeLang == 'en' ? statusValue.toUpperCase() : statusValue,
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.brand700,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        '$priorityLabel ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate700,
                        ),
                      ),
                      pw.Text(
                        activeLang == 'en' ? priorityValue.toUpperCase() : priorityValue,
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: task.priority.toLowerCase() == 'urgent' || task.priority.toLowerCase() == 'high'
                              ? PdfColors.red800
                              : WebReportTheme.slate800,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        '$assignedToLabel ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: WebReportTheme.slate700,
                        ),
                      ),
                      pw.Text(
                        activeLang == 'en' ? assignedValue.toUpperCase() : assignedValue,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: WebReportTheme.slate800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Task Title & Description Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    taskTitleHeading,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.slate500,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    resolvedTitle,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: WebReportTheme.slate900,
                    ),
                  ),
                  if (resolvedDesc.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      descHeading,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: WebReportTheme.slate500,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      resolvedDesc,
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        color: WebReportTheme.slate800,
                        lineSpacing: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Details Grid
            pw.Table(
              border: WebReportTheme.tableBorder,
              children: [
                _buildTableRow(
                  AppTranslations.getReportColumn('due_date', activeLang),
                  taskDueDateStr,
                  AppTranslations.pick(activeLang, en: 'Due Time', mr: 'नियोजित वेळ', hi: 'नियत समय'),
                  taskDueTimeStr.isNotEmpty ? taskDueTimeStr : '-',
                ),
                _buildTableRow(
                  AppTranslations.pick(activeLang, en: 'Location / Address', mr: 'ठिकाण / पत्ता', hi: 'स्थान / पता'),
                  resolvedAddress,
                  AppTranslations.pick(activeLang, en: 'Office', mr: 'कार्यालय', hi: 'कार्यालय'),
                  resolvedOffice,
                ),
                _buildTableRow(
                  AppTranslations.pick(activeLang, en: 'Person to Meet', mr: 'भेटण्याची व्यक्ती', hi: 'मिलने वाले व्यक्ति'),
                  resolvedMeetPerson,
                  AppTranslations.pick(activeLang, en: 'Assigned Staff', mr: 'नियुक्त कर्मचारी', hi: 'नियुक्त कर्मचारी'),
                  resolvedStaff,
                ),
              ],
            ),
          ];
        },
      ),
    );

    final fileName = 'Task_Docket_${task.id}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: docketTitle,
        subtitle: '${AppTranslations.pick(activeLang, en: 'ID:', mr: 'क्र.:', hi: 'आईडी:')} $taskIdDisplay',
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

  static pw.TableRow _buildTableRow(String l1, String v1, String l2, String v2) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: WebReportTheme.slate50,
          child: pw.Text(
            l1,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: WebReportTheme.slate700,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            v1,
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: WebReportTheme.slate800,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: WebReportTheme.slate50,
          child: pw.Text(
            l2,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: WebReportTheme.slate700,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            v2,
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: WebReportTheme.slate800,
            ),
          ),
        ),
      ],
    );
  }
}
