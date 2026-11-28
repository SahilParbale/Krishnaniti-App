import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/karyakarta_work_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class KaryakartaWorkReportGenerator {
  KaryakartaWorkReportGenerator._();

  static Future<void> generateAndPrintReport({
    BuildContext? context,
    required List<KaryakartaWorkStaff> staffList,
    required List<KaryakartaWorkTask> tasks,
    required List<KaryakartaWorkComplaint> complaints,
    required String activeTabLabel,
    String? categoryFilter,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDateTime(now, activeLang);

    final staffIds = staffList.map((s) => s.id).toSet();
    final tabTasks = tasks.where((t) => t.assignedStaffId != null && staffIds.contains(t.assignedStaffId)).toList();
    final tabComplaints = complaints.where((c) => c.assignedTo != null && staffIds.contains(c.assignedTo)).toList();

    final totalTasks = tabTasks.length;
    final completedTasks = tabTasks.where((t) => t.isCompleted).length;
    final inProgressTasks = tabTasks.where((t) => t.isInProgress).length;
    final pendingTasks = tabTasks.where((t) => t.isPending).length;

    final totalComplaints = tabComplaints.length;
    final resolvedComplaints = tabComplaints.where((c) => c.isResolved).length;
    final inProgressComplaints = tabComplaints.where((c) => c.isInProgress).length;
    final pendingComplaints = tabComplaints.where((c) => c.isPending).length;

    final totalLoad = totalTasks + totalComplaints;
    final pendingLoad = pendingTasks + pendingComplaints;
    final inProgressLoad = inProgressTasks + inProgressComplaints;
    final completedLoad = completedTasks + resolvedComplaints;

    final textItems = <String?>[
      activeTabLabel,
      categoryFilter,
    ];
    final nameItems = <String?>[];
    for (final member in staffList) {
      nameItems.add(_pickStaffName(member, activeLang));
      textItems.add(member.role);
      textItems.add(member.area);
    }

    final caches = await Future.wait([
      PdfTranslationHelper.batchText(textItems, activeLang),
      PdfTranslationHelper.batchNames(nameItems, activeLang),
    ]);
    final textCache = caches[0];
    final nameCache = caches[1];

    final resolvedTabLabel = _resolveTabLabel(
      activeTabLabel,
      categoryFilter,
      activeLang,
      textCache,
    );

    final reportTitle = AppTranslations.pick(
      activeLang,
      en: 'Team Workload Monitor',
      mr: 'टीम कार्यभार निरीक्षण',
      hi: 'टीम कार्यभार निगरानी',
    );
    final reportSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Department: $resolvedTabLabel',
      mr: 'विभाग: $resolvedTabLabel',
      hi: 'विभाग: $resolvedTabLabel',
    );
    final previewTitle = AppTranslations.pick(
      activeLang,
      en: 'Karyakarta Workload Report',
      mr: 'कार्यकर्ता कार्यभार अहवाल',
      hi: 'कार्यकर्ता कार्यभार रिपोर्ट',
    );
    final previewSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Staff Task & Civic Grievance Allocation Dossier',
      mr: 'कर्मचारी कार्य व नागरी तक्रार वाटप नोंदवही',
      hi: 'स्टाफ कार्य और नागरिक शिकायत आवंटन डोजियर',
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
        footer: (pw.Context context) => WebReportTheme.buildFooter(
          context,
          lang: activeLang,
        ),
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: reportTitle,
              subtitle: reportSubtitle,
              dateFormatted: nowStr,
              totalCount: staffList.length,
              foundLabel: AppTranslations.pick(
                activeLang,
                en: 'Members',
                mr: 'सदस्य',
                hi: 'सदस्य',
              ),
              lang: activeLang,
            ),
            pw.SizedBox(height: 12),

            // Summary KPI strip matching web style
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
                      en: 'Total Workload',
                      mr: 'एकूण कार्यभार',
                      hi: 'कुल कार्यभार',
                    ),
                    PdfTranslationHelper.formatNumber(totalLoad, activeLang),
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Pending',
                      mr: 'प्रलंबित',
                      hi: 'लंबित',
                    ),
                    PdfTranslationHelper.formatNumber(pendingLoad, activeLang),
                    highlightColor: PdfColors.amber800,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'In Progress',
                      mr: 'काम चालू',
                      hi: 'प्रगति पर',
                    ),
                    PdfTranslationHelper.formatNumber(inProgressLoad, activeLang),
                    highlightColor: WebReportTheme.brand700,
                  ),
                  _buildSummaryItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Completed',
                      mr: 'पूर्ण',
                      hi: 'पूर्ण',
                    ),
                    PdfTranslationHelper.formatNumber(completedLoad, activeLang),
                    highlightColor: PdfColors.green700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            if (staffList.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No team members found for the selected category.',
                    mr: 'निवडलेल्या श्रेणीसाठी कोणतेही सदस्य आढळले नाहीत.',
                    hi: 'चयनित श्रेणी के लिए कोई टीम सदस्य नहीं मिला।',
                  ),
                  style: const pw.TextStyle(fontSize: 11, color: WebReportTheme.slate500),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: WebReportTheme.tableBorder,
                headerCount: 1,
                headerStyle: WebReportTheme.tableHeaderStyle,
                headerDecoration: WebReportTheme.tableHeaderDecoration,
                headerHeight: 22,
                cellHeight: 20,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: WebReportTheme.tableCellStyle,
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(1.4),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.1),
                  6: pw.FlexColumnWidth(1.1),
                  7: pw.FlexColumnWidth(1.2),
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Member & Mobile',
                    mr: 'सदस्य व मोबाईल',
                    hi: 'सदस्य और मोबाइल',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Role & Area',
                    mr: 'पद व परिसर',
                    hi: 'पद और क्षेत्र',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Tasks',
                    mr: 'कामे',
                    hi: 'कार्य',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Complaints',
                    mr: 'तक्रारी',
                    hi: 'शिकायतें',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Pending',
                    mr: 'प्रलंबित',
                    hi: 'लंबित',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Done',
                    mr: 'पूर्ण',
                    hi: 'पूर्ण',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Progress',
                    mr: 'प्रगती',
                    hi: 'प्रगति',
                  ),
                ],
                data: staffList.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final member = entry.value;

                  final mTasks = tasks.where((t) => t.assignedStaffId == member.id).toList();
                  final mComplaints = complaints.where((c) => c.assignedTo == member.id).toList();

                  final mTPending = mTasks.where((t) => t.isPending || t.isInProgress).length;
                  final mCPending = mComplaints.where((c) => c.isPending || c.isInProgress).length;

                  final totalAssigned = mTasks.length + mComplaints.length;
                  final totalCompleted =
                      mTasks.where((t) => t.isCompleted).length +
                      mComplaints.where((c) => c.isResolved).length;

                  final totalPending = mTPending + mCPending;
                  final progressPct = totalAssigned > 0 ? ((totalCompleted / totalAssigned) * 100).round() : 0;

                  final resolvedName = PdfTranslationHelper.resolveName(
                    nameCache,
                    _pickStaffName(member, activeLang),
                    activeLang,
                  );
                  final formattedPhone = PdfTranslationHelper.formatNumber(
                    member.mobile.trim(),
                    activeLang,
                  );
                  final phoneStr = formattedPhone.isNotEmpty ? '\n$formattedPhone' : '';

                  final resolvedRole = _resolveRole(member.role, activeLang, textCache);
                  final areaStr = (member.area != null && member.area!.trim().isNotEmpty)
                      ? '\n${_resolveArea(member.area!, activeLang, textCache)}'
                      : '';

                  return [
                    PdfTranslationHelper.formatNumber(index, activeLang),
                    '$resolvedName$phoneStr',
                    '$resolvedRole$areaStr',
                    '${PdfTranslationHelper.formatNumber(mTPending, activeLang)} / ${PdfTranslationHelper.formatNumber(mTasks.length, activeLang)}',
                    '${PdfTranslationHelper.formatNumber(mCPending, activeLang)} / ${PdfTranslationHelper.formatNumber(mComplaints.length, activeLang)}',
                    PdfTranslationHelper.formatNumber(totalPending, activeLang),
                    PdfTranslationHelper.formatNumber(totalCompleted, activeLang),
                    '${PdfTranslationHelper.formatNumber(progressPct, activeLang)}%',
                  ];
                }).toList(),
                oddRowDecoration: WebReportTheme.oddRowDecoration,
              ),
          ];
        },
      ),
    );

    final fileName = 'Karyakarta_Workload_Report_${DateFormat('yyyyMMdd').format(now)}';
    if (context != null) {
      if (!context.mounted) return;
      await AppReportPreviewModal.show(
        context: context,
        title: previewTitle,
        subtitle: previewSubtitle,
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

  static String _pickStaffName(KaryakartaWorkStaff member, String lang) {
    if (lang == 'mr') {
      if (member.nameMarathi != null && member.nameMarathi!.trim().isNotEmpty) {
        return member.nameMarathi!.trim();
      }
      return member.name.trim();
    }
    if (member.name.trim().isNotEmpty) return member.name.trim();
    return member.displayName.trim();
  }

  static String _resolveTabLabel(
    String activeTabLabel,
    String? categoryFilter,
    String lang,
    Map<String, String> textCache,
  ) {
    final raw = activeTabLabel.trim().isNotEmpty
        ? activeTabLabel.trim()
        : (categoryFilter?.trim() ?? '');
    final lower = raw.toLowerCase();
    if (lower == 'office team' || lower == 'office') {
      return AppTranslations.pick(
        lang,
        en: 'Office Team',
        mr: 'कार्यालयीन टीम',
        hi: 'कार्यालय टीम',
      );
    }
    if (lower == 'government work' || lower == 'govt work' || lower == 'cooperative') {
      return AppTranslations.pick(
        lang,
        en: 'Government Work',
        mr: 'शासकीय कामकाज',
        hi: 'शासकीय कार्य',
      );
    }
    if (lower == 'party cadre' || lower == 'party') {
      return AppTranslations.pick(
        lang,
        en: 'Party Cadre',
        mr: 'पक्ष कार्यकर्ते',
        hi: 'पार्टी कार्यकर्ता',
      );
    }
    return PdfTranslationHelper.resolve(textCache, raw, lang);
  }

  static String _resolveRole(
    String role,
    String lang,
    Map<String, String> textCache,
  ) {
    final trimmed = role.trim();
    if (trimmed.isEmpty) return '-';
    final mapped = AppTranslations.getRoleName(trimmed, lang);
    if (AppTranslations.normalizeAsciiDigits(mapped) ==
        AppTranslations.normalizeAsciiDigits(trimmed)) {
      return PdfTranslationHelper.resolve(textCache, trimmed, lang);
    }
    return AppTranslations.formatDigits(mapped, lang);
  }

  static String _resolveArea(
    String area,
    String lang,
    Map<String, String> textCache,
  ) {
    final trimmed = area.trim();
    if (trimmed.isEmpty) return '-';
    final mapped = AppTranslations.getAreaName(trimmed, lang);
    if (AppTranslations.normalizeAsciiDigits(mapped) ==
        AppTranslations.normalizeAsciiDigits(trimmed)) {
      return PdfTranslationHelper.resolve(textCache, trimmed, lang);
    }
    return mapped;
  }

  static pw.Widget _buildSummaryItem(String label, String value, {PdfColor? highlightColor}) {
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
