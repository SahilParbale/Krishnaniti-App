import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/localization/app_translations.dart';

/// Web report theme matching the exact Tailwind color tokens and layout of Nagarsevak-Managment
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

  /// Standard 10mm margins matching web jsPDF margin = 10
  static const pw.EdgeInsets pageMargin = pw.EdgeInsets.all(marginPt);

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

    final String datePrefix = (lang == 'mr' || lang == 'hi') ? 'दिनांक:' : 'Date:';
    final String effectiveFound = foundLabel ?? (lang == 'mr' ? 'एकूण' : (lang == 'hi' ? 'कुल' : 'Found'));

    if (metaLines != null && metaLines.isNotEmpty) {
      for (final line in metaLines) {
        rightColumnWidgets.add(
          pw.Text(
            line,
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
            '$datePrefix $dateFormatted',
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
            '$effectiveFound: $totalCount',
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
                  title,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: brand700,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: slate500,
                  ),
                ),
              ],
            ),
          ),
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
    final String continuedSuffix = (lang == 'mr' || lang == 'hi') ? '(पुढे चालू)' : '(Continued)';
    final String pageLabel = (lang == 'mr' || lang == 'hi')
        ? 'पृष्ठ ${context.pageNumber} / ${context.pagesCount}'
        : 'Page ${context.pageNumber} of ${context.pagesCount}';

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
            '$title $continuedSuffix',
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
    final String pageLabel = (lang == 'mr' || lang == 'hi')
        ? 'पृष्ठ ${context.pageNumber} / ${context.pagesCount}'
        : 'Page ${context.pageNumber} of ${context.pagesCount}';

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
            generatedBy,
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
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
