import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_translations.dart';
import '../../../data/models/ward_map_point_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_report_theme.dart';
import '../../widgets/app_report_preview_modal.dart';

class WardMapReportGenerator {
  WardMapReportGenerator._();

  static Future<void> generateAndPrintWardMapReport({
    BuildContext? context,
    required List<WardMapPointModel> points,
    String? categoryFilter,
    String? lang,
  }) async {
    final activeLang = (lang != null && lang.isNotEmpty)
        ? lang
        : appLanguageValueNotifier.value;
    final pdf = await WebReportTheme.createDocument(lang: activeLang);
    final now = DateTime.now();
    final nowStr = PdfTranslationHelper.formatDateTime(now, activeLang);

    final hasCategoryFilter = categoryFilter != null &&
        categoryFilter.trim().isNotEmpty &&
        categoryFilter != 'All';

    final textCache = await PdfTranslationHelper.batchText(
      [
        if (hasCategoryFilter) categoryFilter,
        for (final pt in points) ...[
          pt.title,
          pt.description,
          pt.address,
          pt.category,
          pt.status,
        ],
      ],
      activeLang,
    );

    final total = points.length;
    final booths = points.where((p) => p.category.toLowerCase() == 'booth').length;
    final works =
        points.where((p) => p.category.toLowerCase() == 'civilworks').length;
    final amenities =
        points.where((p) => p.category.toLowerCase() == 'amenity').length;
    final problems =
        points.where((p) => p.category.toLowerCase() == 'problemspot').length;

    final headerTitle = AppTranslations.pick(
      activeLang,
      en: 'Ward Geographic & GIS Directory',
      mr: 'प्रभाग भौगोलिक आणि जीआयएस निर्देशिका',
      hi: 'वार्ड भौगोलिक और जीआईएस निर्देशिका',
    );
    final continuationTitle = AppTranslations.pick(
      activeLang,
      en: 'Ward GIS Directory',
      mr: 'प्रभाग जीआयएस निर्देशिका',
      hi: 'वार्ड जीआईएस निर्देशिका',
    );
    final headerSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Prabhag Ward 12 • GIS Mapped Polling Booths, Civil Works & Civic Hotspots',
      mr: 'प्रभाग १२ • जीआयएस नकाशावरील मतदान केंद्रे, विकासकामे आणि नागरी ठिकाणे',
      hi: 'वार्ड १२ • जीआईएस मैप्ड मतदान केंद्र, विकास कार्य और नागरिक स्थल',
    );
    final totalPointsLabel = AppTranslations.pick(
      activeLang,
      en: 'Total Points',
      mr: 'एकूण ठिकाणे',
      hi: 'कुल स्थल',
    );
    final dateLabel = AppTranslations.pick(
      activeLang,
      en: 'Date',
      mr: 'दिनांक',
      hi: 'दिनांक',
    );
    final layerLabel = AppTranslations.pick(
      activeLang,
      en: 'Layer',
      mr: 'स्तर',
      hi: 'परत',
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
        footer: (pw.Context context) {
          return WebReportTheme.buildFooter(context, lang: activeLang);
        },
        build: (pw.Context context) {
          return [
            WebReportTheme.buildHeader(
              title: headerTitle,
              subtitle: headerSubtitle,
              dateFormatted: nowStr,
              totalCount: total,
              foundLabel: totalPointsLabel,
              lang: activeLang,
              metaLines: hasCategoryFilter
                  ? [
                      '$dateLabel: $nowStr',
                      '$layerLabel: ${_resolveCategory(categoryFilter, textCache, activeLang)}',
                      '$totalPointsLabel: ${PdfTranslationHelper.formatNumber(total, activeLang)}',
                    ]
                  : null,
            ),

            // Summary Strip
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 14),
              decoration: pw.BoxDecoration(
                color: WebReportTheme.slate50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: WebReportTheme.slate200, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                    totalPointsLabel,
                    PdfTranslationHelper.formatNumber(total, activeLang),
                  ),
                  _statItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Electoral Booths',
                      mr: 'मतदान केंद्रे',
                      hi: 'मतदान केंद्र',
                    ),
                    PdfTranslationHelper.formatNumber(booths, activeLang),
                  ),
                  _statItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Civil Works Sites',
                      mr: 'विकासकामे ठिकाणे',
                      hi: 'विकास कार्य स्थल',
                    ),
                    PdfTranslationHelper.formatNumber(works, activeLang),
                  ),
                  _statItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Civic Amenities',
                      mr: 'नागरी सुविधा',
                      hi: 'नागरिक सुविधाएं',
                    ),
                    PdfTranslationHelper.formatNumber(amenities, activeLang),
                  ),
                  _statItem(
                    AppTranslations.pick(
                      activeLang,
                      en: 'Civic Hotspots',
                      mr: 'समस्या ठिकाणे',
                      hi: 'समस्या स्थल',
                    ),
                    PdfTranslationHelper.formatNumber(problems, activeLang),
                  ),
                ],
              ),
            ),

            if (points.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  AppTranslations.pick(
                    activeLang,
                    en: 'No ward map points found for the selected view.',
                    mr: 'निवडलेल्या पर्यायासाठी प्रभाग नकाशावरील ठिकाणे आढळली नाहीत.',
                    hi: 'चयनित दृश्य के लिए कोई वार्ड मानचित्र बिंदु नहीं मिला।',
                  ),
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: WebReportTheme.slate500,
                  ),
                ),
              )
            else
              // Table of Points
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
                  0: pw.FixedColumnWidth(30), // Sr
                  1: pw.FlexColumnWidth(2.4), // Location Title
                  2: pw.FixedColumnWidth(75), // Category
                  3: pw.FlexColumnWidth(2.6), // Address & Details
                  4: pw.FixedColumnWidth(85), // GPS Coordinates
                  5: pw.FixedColumnWidth(55), // Status
                },
                headers: [
                  AppTranslations.pick(activeLang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Landmark / Location Title',
                    mr: 'ठिकाण / खूण शीर्षक',
                    hi: 'स्थल / स्थान शीर्षक',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Category Layer',
                    mr: 'वर्गवारी स्तर',
                    hi: 'श्रेणी स्तर',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Address & Scope',
                    mr: 'पत्ता आणि तपशील',
                    hi: 'पता और विवरण',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'GPS Coordinates',
                    mr: 'जीपीएस निर्देशांक',
                    hi: 'जीपीएस निर्देशांक',
                  ),
                  AppTranslations.pick(
                    activeLang,
                    en: 'Current Status',
                    mr: 'सद्यस्थिती',
                    hi: 'वर्तमान स्थिति',
                  ),
                ],
                data: points.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final pt = entry.value;
                  final titleStr =
                      PdfTranslationHelper.resolve(textCache, pt.title, activeLang);
                  final titleDesc = pt.description.trim().isNotEmpty
                      ? '$titleStr\n${PdfTranslationHelper.resolve(textCache, pt.description, activeLang)}'
                      : titleStr;
                  final coordsStr = PdfTranslationHelper.formatNumber(
                    '${pt.latitude.toStringAsFixed(4)}, ${pt.longitude.toStringAsFixed(4)}',
                    activeLang,
                  );

                  return [
                    PdfTranslationHelper.formatNumber(idx, activeLang),
                    titleDesc,
                    _resolveCategory(pt.category, textCache, activeLang),
                    PdfTranslationHelper.resolve(textCache, pt.address, activeLang),
                    coordsStr,
                    _resolvePointStatus(pt.status, textCache, activeLang),
                  ];
                }).toList(),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                },
              ),
          ];
        },
      ),
    );

    final modalTitle = AppTranslations.pick(
      activeLang,
      en: 'Ward Map & Geo Registry',
      mr: 'प्रभाग नकाशा आणि भू-नोंदवही',
      hi: 'वार्ड मानचित्र और भू-पंजीकरण',
    );
    final modalSubtitle = AppTranslations.pick(
      activeLang,
      en: 'Key Landmarks, Polling Stations & Public Amenity Points',
      mr: 'प्रमुख खुणा, मतदान केंद्रे आणि सार्वजनिक सुविधा ठिकाणे',
      hi: 'प्रमुख स्थल, मतदान केंद्र और सार्वजनिक सुविधा बिंदु',
    );

    final fileName = 'Ward_Map_Directory_${DateFormat('yyyyMMdd').format(now)}';
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

  static String _resolveCategory(
    String raw,
    Map<String, String> textCache,
    String lang,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    switch (trimmed.toLowerCase()) {
      case 'booth':
        return AppTranslations.pick(
          lang,
          en: 'Polling Booth',
          mr: 'मतदान केंद्र',
          hi: 'मतदान केंद्र',
        );
      case 'civilworks':
      case 'civil works':
        return AppTranslations.pick(
          lang,
          en: 'Civil Works',
          mr: 'विकासकामे',
          hi: 'विकास कार्य',
        );
      case 'amenity':
        return AppTranslations.pick(
          lang,
          en: 'Civic Amenity',
          mr: 'नागरी सुविधा',
          hi: 'नागरिक सुविधा',
        );
      case 'problemspot':
      case 'problem spot':
        return AppTranslations.pick(
          lang,
          en: 'Problem Spot',
          mr: 'समस्या ठिकाण',
          hi: 'समस्या स्थल',
        );
      case 'office':
        return AppTranslations.pick(
          lang,
          en: 'Ward Office',
          mr: 'प्रभाग कार्यालय',
          hi: 'वार्ड कार्यालय',
        );
      default:
        return PdfTranslationHelper.resolve(textCache, trimmed, lang);
    }
  }

  static String _resolvePointStatus(
    String? raw,
    Map<String, String> textCache,
    String lang,
  ) {
    final trimmed = (raw == null || raw.trim().isEmpty) ? 'Active' : raw.trim();
    switch (trimmed.toLowerCase()) {
      case 'active':
        return AppTranslations.pick(
          lang,
          en: 'ACTIVE',
          mr: 'सक्रिय',
          hi: 'सक्रिय',
        );
      case 'inactive':
        return AppTranslations.pick(
          lang,
          en: 'INACTIVE',
          mr: 'निष्क्रिय',
          hi: 'निष्क्रिय',
        );
      default:
        final staticMatch = AppTranslations.getStatus(trimmed, lang);
        if (staticMatch != trimmed) {
          final formatted = PdfTranslationHelper.formatNumber(staticMatch, lang);
          return lang == 'en' ? formatted.toUpperCase() : formatted;
        }
        final resolved = PdfTranslationHelper.resolve(textCache, trimmed, lang);
        return lang == 'en' ? resolved.toUpperCase() : resolved;
    }
  }

  static pw.Widget _statItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: WebReportTheme.brand700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 7.5,
            color: WebReportTheme.slate600,
          ),
        ),
      ],
    );
  }
}
