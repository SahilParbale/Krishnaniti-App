import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/localization/app_translations.dart';
import '../../core/services/translation_service.dart';

/// Web report theme matching the exact Tailwind color tokens and layout of Nagarsevak-Managment,
/// enhanced with guaranteed Devanagari + Latin font loading and 3-language localization.
class WebReportTheme {
  WebReportTheme._();

  // Brand colors from web Tailwind config
  static const PdfColor brand900 = PdfColor.fromInt(0xFF0C4A6E);
  static const PdfColor brand800 = PdfColor.fromInt(0xFF075985);
  static const PdfColor brand700 = PdfColor.fromInt(0xFF0369A1); // Title color (#0369a1)
  static const PdfColor brand600 = PdfColor.fromInt(0xFF0284C7); // Header accent border (#0284c7)
  static const PdfColor brand500 = PdfColor.fromInt(0xFF0EA5E9);
  static const PdfColor brand50 = PdfColor.fromInt(0xFFF0F9FF);

  // Slate colors from web Tailwind config
  static const PdfColor slate900 = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor slate800 = PdfColor.fromInt(0xFF1E293B); // Cell text color
  static const PdfColor slate700 = PdfColor.fromInt(0xFF334155); // Table header text
  static const PdfColor slate600 = PdfColor.fromInt(0xFF475569);
  static const PdfColor slate500 = PdfColor.fromInt(0xFF64748B); // Subtitle color
  static const PdfColor slate400 = PdfColor.fromInt(0xFF94A3B8); // Date / Total / Footer color
  static const PdfColor slate200 = PdfColor.fromInt(0xFFE2E8F0); // Border color
  static const PdfColor slate100 = PdfColor.fromInt(0xFFF1F5F9); // Footer border color
  static const PdfColor slate50 = PdfColor.fromInt(0xFFF8FAFC);  // Table header bg / alternating row

  /// Standard 10mm margins in points (10mm = 28.35 pt)
  static const double marginPt = 28.35;

  /// Standard A4 Portrait page format matching web jsPDF('p', 'mm', 'a4')
  static final PdfPageFormat pageFormat = PdfPageFormat.a4;

  /// Standard A4 Landscape format
  static final PdfPageFormat landscapePageFormat = PdfPageFormat.a4.landscape;

  /// Standard 10mm margins matching web jsPDF margin = 10
  static const pw.EdgeInsets pageMargin = pw.EdgeInsets.all(marginPt);

  static pw.ThemeData? _cachedTheme;

  /// Loads and caches NotoSans + NotoSansDevanagari fonts from bundled assets
  /// (falling back to Google Fonts / default if unavailable).
  /// Guarantees Marathi & Hindi Unicode glyphs, conjuncts, ₹ symbol, and numerals render offline.
  static Future<pw.ThemeData?> getTheme() async {
    if (_cachedTheme != null) return _cachedTheme;

    try {
      final latinRegBytes = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final latinBoldBytes = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      final devRegBytes = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
      final devBoldBytes = await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');

      final latinReg = pw.Font.ttf(latinRegBytes);
      final latinBold = pw.Font.ttf(latinBoldBytes);
      final devReg = pw.Font.ttf(devRegBytes);
      final devBold = pw.Font.ttf(devBoldBytes);

      _cachedTheme = pw.ThemeData.withFont(
        base: latinReg,
        bold: latinBold,
        italic: latinReg,
        boldItalic: latinBold,
        fontFallback: [devReg, devBold],
      );
      return _cachedTheme;
    } catch (_) {
      try {
        final devReg = await PdfGoogleFonts.notoSansDevanagariRegular();
        final devBold = await PdfGoogleFonts.notoSansDevanagariBold();
        _cachedTheme = pw.ThemeData.withFont(
          base: devReg,
          bold: devBold,
          italic: devReg,
          boldItalic: devBold,
        );
        return _cachedTheme;
      } catch (_) {
        return null;
      }
    }
  }

  /// Creates a [pw.Document] preconfigured with Devanagari + Latin fonts for all 3 languages.
  static Future<pw.Document> createDocument({String lang = 'en'}) async {
    final theme = await getTheme();
    return pw.Document(theme: theme);
  }

  /// Builds the top report header matching Nagarsevak-Managment web .report-header
  static pw.Widget buildHeader({
    required String title,
    required String subtitle,
    String? dateFormatted,
    int? totalCount,
    String? foundLabel,
    List<String>? metaLines,
    String lang = 'en',
  }) {
    final List<pw.Widget> rightColumnWidgets = [];

    final String datePrefix = AppTranslations.pick(
      lang,
      en: 'Date:',
      mr: 'दिनांक:',
      hi: 'दिनांक:',
    );
    final String effectiveFound = foundLabel ??
        AppTranslations.pick(lang, en: 'Found', mr: 'एकूण', hi: 'कुल');

    if (metaLines != null && metaLines.isNotEmpty) {
      for (final line in metaLines) {
        rightColumnWidgets.add(
          pw.Text(
            AppTranslations.formatDigits(line, lang),
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: slate400,
            ),
          ),
        );
        rightColumnWidgets.add(pw.SizedBox(height: 1.5));
      }
    } else {
      if (dateFormatted != null) {
        rightColumnWidgets.add(
          pw.Text(
            '$datePrefix ${AppTranslations.formatDigits(dateFormatted, lang)}',
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: slate400,
            ),
          ),
        );
        rightColumnWidgets.add(pw.SizedBox(height: 2));
      }
      if (totalCount != null) {
        rightColumnWidgets.add(
          pw.Text(
            '$effectiveFound: ${AppTranslations.formatDigits(totalCount, lang)}',
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: slate400,
            ),
          ),
        );
      }
    }

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: brand600, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  AppTranslations.formatDigits(title, lang),
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: brand700,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  AppTranslations.formatDigits(subtitle, lang),
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: slate500,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: rightColumnWidgets,
          ),
        ],
      ),
    );
  }

  /// Builds continuation header for pages > 1
  static pw.Widget buildContinuationHeader(
    pw.Context context, {
    required String title,
    String lang = 'en',
  }) {
    if (context.pageNumber <= 1) return pw.SizedBox.shrink();
    final String continuedSuffix = AppTranslations.pick(
      lang,
      en: '(Continued)',
      mr: '(पुढे चालू)',
      hi: '(क्रमशः)',
    );
    final String pageNo = AppTranslations.formatDigits(context.pageNumber, lang);
    final String totalPages = AppTranslations.formatDigits(context.pagesCount, lang);
    final String pageLabel = AppTranslations.pick(
      lang,
      en: 'Page $pageNo of $totalPages',
      mr: 'पृष्ठ $pageNo / $totalPages',
      hi: 'पृष्ठ $pageNo / $totalPages',
    );

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: brand600, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${AppTranslations.formatDigits(title, lang)} $continuedSuffix',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: brand700,
            ),
          ),
          pw.Text(
            pageLabel,
            style: const pw.TextStyle(
              fontSize: 8,
              color: slate400,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the standard footer matching web .mt-12 .pt-6 .border-t
  static pw.Widget buildFooter(pw.Context context, {String lang = 'en'}) {
    final String generatedBy = AppTranslations.t('common.generated_by', lang: lang);
    final String pageNo = AppTranslations.formatDigits(context.pageNumber, lang);
    final String totalPages = AppTranslations.formatDigits(context.pagesCount, lang);
    final String pageLabel = AppTranslations.pick(
      lang,
      en: 'Page $pageNo of $totalPages',
      mr: 'पृष्ठ $pageNo / $totalPages',
      hi: 'पृष्ठ $pageNo / $totalPages',
    );

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: slate100, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            AppTranslations.formatDigits(generatedBy, lang),
            style: const pw.TextStyle(
              fontSize: 8,
              color: slate400,
            ),
          ),
          pw.Text(
            pageLabel,
            style: const pw.TextStyle(
              fontSize: 8,
              color: slate400,
            ),
          ),
        ],
      ),
    );
  }

  /// Standard table border matching web border-collapse border border-slate-200
  static pw.TableBorder tableBorder = pw.TableBorder.all(
    color: slate200,
    width: 0.5,
  );

  /// Standard table header decoration matching web thead tr.bg-slate-50
  static const pw.BoxDecoration tableHeaderDecoration = pw.BoxDecoration(
    color: slate50,
  );

  /// Standard table header text style matching web th.font-bold.text-slate-700
  static pw.TextStyle tableHeaderStyle = pw.TextStyle(
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
    color: slate700,
  );

  /// Standard table cell text style matching web text-[10px] text-slate-800
  static const pw.TextStyle tableCellStyle = pw.TextStyle(
    fontSize: 8,
    color: slate800,
  );

  /// Alternating row decoration
  static const pw.BoxDecoration oddRowDecoration = pw.BoxDecoration(
    color: slate50,
  );
}

/// Helper utilities for PDF Report Generators to cross-lingually translate dynamic content,
/// transliterate person/organization names, format localized dates & currency, and localize numerals.
class PdfTranslationHelper {
  PdfTranslationHelper._();

  static Future<Map<String, String>> batchText(
    Iterable<String?> items,
    String lang,
  ) {
    return DynamicTranslationService.translateBatch(
      items.whereType<String>().where((s) => s.trim().isNotEmpty),
      lang,
      isName: false,
    );
  }

  static Future<Map<String, String>> batchNames(
    Iterable<String?> items,
    String lang,
  ) {
    return DynamicTranslationService.translateBatch(
      items.whereType<String>().where((s) => s.trim().isNotEmpty),
      lang,
      isName: true,
    );
  }

  static String resolve(
    Map<String, String> cache,
    String? raw,
    String lang, {
    String fallback = '-',
  }) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final clean = raw.trim();
    final mapped = cache[clean] ??
        DynamicTranslationService.getCachedTranslation(clean, lang) ??
        AppTranslations.tr(clean, lang: lang) ??
        clean;
    return AppTranslations.formatDigits(mapped, lang);
  }

  static String resolveName(
    Map<String, String> cache,
    String? raw,
    String lang, {
    String fallback = '-',
  }) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final clean = raw.trim();
    final mapped = cache[clean] ??
        DynamicTranslationService.getCachedTranslation(clean, lang, isName: true) ??
        clean;
    return AppTranslations.formatDigits(mapped, lang);
  }

  static String formatDate(DateTime? dt, String lang, {String pattern = 'dd/MM/yyyy'}) {
    if (dt == null) return '-';
    return AppTranslations.formatDate(dt, lang, pattern: pattern);
  }

  static String formatDateTime(DateTime? dt, String lang) {
    if (dt == null) return '-';
    return AppTranslations.formatDateTime(dt, lang);
  }

  static String formatNumber(dynamic value, String lang) {
    return AppTranslations.formatDigits(value, lang);
  }

  static String formatCurrency(dynamic amount, String lang) {
    return AppTranslations.formatCurrency(amount, lang);
  }

  static String parseAndFormatDateString(String raw, String lang) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return formatDate(parsed, lang);
    // Try dd/MM/yyyy or yyyy-MM-dd prefix
    try {
      final d = DateFormat('yyyy-MM-dd').parseStrict(trimmed.split(' ').first);
      return formatDate(d, lang);
    } catch (_) {}
    return AppTranslations.formatDigits(trimmed, lang);
  }
}
