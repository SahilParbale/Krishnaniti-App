import 'dart:convert';
import 'dart:io' show File, Platform, Process;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as m;
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

  static String? _cachedDevRegB64;
  static String? _cachedDevBoldB64;

  static Future<({String regB64, String boldB64})> _getDevanagariFontBase64() async {
    if (_cachedDevRegB64 != null && _cachedDevBoldB64 != null) {
      return (regB64: _cachedDevRegB64!, boldB64: _cachedDevBoldB64!);
    }
    final regBytes = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
    final boldBytes = await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
    _cachedDevRegB64 = base64Encode(regBytes.buffer.asUint8List());
    _cachedDevBoldB64 = base64Encode(boldBytes.buffer.asUint8List());
    return (regB64: _cachedDevRegB64!, boldB64: _cachedDevBoldB64!);
  }

  static String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Generates a PDF using the platform's native Chromium/WebView2 HarfBuzz engine
  /// via [Printing.convertHtml], guaranteeing 100% accurate Devanagari (Marathi & Hindi)
  /// text shaping, matra positioning, conjuncts (जोडाक्षरे), and selectable/copyable text.
  static Future<Uint8List> generateHtmlPdfBytes({
    required String title,
    required String subtitle,
    String? dateFormatted,
    int? totalCount,
    String? foundLabel,
    List<String>? metaLines,
    required List<String> headers,
    required List<List<String>> rows,
    String? summaryText,
    String lang = 'en',
    PdfPageFormat? format,
  }) async {
    final fonts = await _getDevanagariFontBase64();
    final pageFmt = format ?? pageFormat;
    final datePrefix = AppTranslations.pick(lang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:');
    final effectiveFound = foundLabel ?? AppTranslations.pick(lang, en: 'Found', mr: 'एकूण', hi: 'कुल');

    final metaHtml = StringBuffer();
    if (metaLines != null && metaLines.isNotEmpty) {
      for (final line in metaLines) {
        metaHtml.write('<div class="meta-line">${_escapeHtml(AppTranslations.formatDigits(line, lang))}</div>');
      }
    } else {
      if (dateFormatted != null && dateFormatted.isNotEmpty) {
        metaHtml.write('<div class="meta-line">${_escapeHtml(datePrefix)} ${_escapeHtml(AppTranslations.formatDigits(dateFormatted, lang))}</div>');
      }
      if (totalCount != null) {
        metaHtml.write('<div class="meta-line">${_escapeHtml(effectiveFound)}: ${_escapeHtml(AppTranslations.formatDigits(totalCount, lang))}</div>');
      }
    }

    final thHtml = headers.map((h) => '<th>${_escapeHtml(h)}</th>').join();
    final trHtml = StringBuffer();
    for (int i = 0; i < rows.length; i++) {
      final rowClass = i.isOdd ? ' class="alt"' : '';
      final tds = rows[i].map((c) => '<td>${_escapeHtml(c)}</td>').join();
      trHtml.write('<tr$rowClass>$tds</tr>');
    }

    final summaryBlock = (summaryText != null && summaryText.trim().isNotEmpty)
        ? '<div class="summary">${_escapeHtml(summaryText)}</div>'
        : '';

    final html = '''
<!DOCTYPE html>
<html lang="${_escapeHtml(lang)}">
<head>
<meta charset="UTF-8">
<style>
  @font-face {
    font-family: 'NotoSansDevanagari';
    src: url('data:font/ttf;base64,${fonts.regB64}') format('truetype');
    font-weight: 400;
    font-style: normal;
  }
  @font-face {
    font-family: 'NotoSansDevanagari';
    src: url('data:font/ttf;base64,${fonts.boldB64}') format('truetype');
    font-weight: 700;
    font-style: normal;
  }
  * {
    box-sizing: border-box;
    font-family: 'NotoSansDevanagari', 'Noto Sans', sans-serif;
  }
  body {
    margin: 0;
    padding: 0;
    color: #1E293B;
    font-size: 10.5px;
    line-height: 1.45;
  }
  .report-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    border-bottom: 2px solid #0284C7;
    padding-bottom: 10px;
    margin-bottom: 14px;
  }
  .report-title {
    font-size: 18px;
    font-weight: 700;
    color: #0369A1;
    margin: 0 0 3px 0;
  }
  .report-subtitle {
    font-size: 11px;
    color: #64748B;
    margin: 0;
  }
  .meta-col {
    text-align: right;
  }
  .meta-line {
    font-size: 9.5px;
    color: #64748B;
    margin-bottom: 2px;
  }
  .summary {
    background: #F0F9FF;
    border: 1px solid #BAE6FD;
    border-radius: 6px;
    padding: 8px 12px;
    margin-bottom: 12px;
    font-size: 10px;
    color: #0C4A6E;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 4px;
  }
  th {
    background-color: #F8FAFC;
    color: #334155;
    font-weight: 700;
    font-size: 10px;
    text-align: left;
    padding: 7px 8px;
    border-bottom: 1.5px solid #CBD5E1;
    border-top: 1px solid #E2E8F0;
  }
  td {
    padding: 6px 8px;
    border-bottom: 1px solid #E2E8F0;
    font-size: 10px;
    color: #1E293B;
    vertical-align: top;
  }
  tr.alt td {
    background-color: #F8FAFC;
  }
</style>
</head>
<body>
  <div class="report-header">
    <div>
      <h1 class="report-title">${_escapeHtml(title)}</h1>
      <p class="report-subtitle">${_escapeHtml(subtitle)}</p>
    </div>
    <div class="meta-col">
      $metaHtml
    </div>
  </div>
  $summaryBlock
  <table>
    <thead><tr>$thHtml</tr></thead>
    <tbody>$trHtml</tbody>
  </table>
</body>
</html>
''';

    if (!kIsWeb && Platform.isWindows) {
      final tempDir = await File('${Platform.environment['TEMP'] ?? '.'}\\ns_pdf_${DateTime.now().microsecondsSinceEpoch}').parent.create(recursive: true);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final htmlFile = File('${tempDir.path}\\ns_report_$stamp.html');
      final pdfFile = File('${tempDir.path}\\ns_report_$stamp.pdf');
      try {
        await htmlFile.writeAsString(html, flush: true);
        final isLandscape = pageFmt.width > pageFmt.height;
        final htmlWithPage = html.replaceFirst(
          '</style>',
          '@page { size: A4 ${isLandscape ? 'landscape' : 'portrait'}; margin: 10mm; }\n</style>',
        );
        await htmlFile.writeAsString(htmlWithPage, flush: true);

        final edgePaths = [
          r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
          r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
          r'C:\Program Files\Google\Chrome\Application\chrome.exe',
          r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
        ];
        String? browserExe;
        for (final p in edgePaths) {
          if (await File(p).exists()) {
            browserExe = p;
            break;
          }
        }
        if (browserExe != null) {
          final res = await Process.run(browserExe, [
            '--headless=new',
            '--disable-gpu',
            '--no-sandbox',
            '--print-to-pdf=${pdfFile.path}',
            '--no-pdf-header-footer',
            Uri.file(htmlFile.path).toString(),
          ]);
          if (res.exitCode == 0 && await pdfFile.exists()) {
            return await pdfFile.readAsBytes();
          }
        }
      } finally {
        if (await htmlFile.exists()) await htmlFile.delete().catchError((_) => htmlFile);
        if (await pdfFile.exists()) await pdfFile.delete().catchError((_) => pdfFile);
      }
    }

    if (kIsWeb) {
      return _generateHarfBuzzRasterPdfBytes(
        title: title,
        subtitle: subtitle,
        dateFormatted: dateFormatted,
        totalCount: totalCount,
        foundLabel: effectiveFound,
        metaLines: metaLines,
        headers: headers,
        rows: rows,
        summaryText: summaryText,
        lang: lang,
        format: pageFmt,
      );
    }

    return Printing.convertHtml(
      html: html,
      format: pageFmt,
    );
  }

  /// Renders a single string using Flutter's native Skia/HarfBuzz [m.TextPainter]
  /// at 3x scale so Devanagari matras, conjuncts, and ligatures are 100% accurate.
  static Future<pw.MemoryImage> _renderShapedText(
    String text, {
    required double fontSize,
    required double maxWidth,
    m.FontWeight fontWeight = m.FontWeight.normal,
    m.Color color = const m.Color(0xFF1E293B),
    m.TextAlign textAlign = m.TextAlign.left,
  }) async {
    const double scale = 3.0;
    final painter = m.TextPainter(
      text: m.TextSpan(
        text: text.isEmpty ? ' ' : text,
        style: m.TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.35,
        ),
      ),
      textDirection: m.TextDirection.ltr,
      textAlign: textAlign,
    )..layout(maxWidth: maxWidth);

    final w = (painter.width * scale).ceil().clamp(1, 4096);
    final h = (painter.height * scale).ceil().clamp(1, 4096);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(scale, scale);
    painter.paint(canvas, ui.Offset.zero);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(byteData!.buffer.asUint8List());
  }

  static Future<Uint8List> _generateHarfBuzzRasterPdfBytes({
    required String title,
    required String subtitle,
    String? dateFormatted,
    int? totalCount,
    required String foundLabel,
    List<String>? metaLines,
    required List<String> headers,
    required List<List<String>> rows,
    String? summaryText,
    required String lang,
    required PdfPageFormat format,
  }) async {
    final doc = pw.Document();
    final usableWidth = format.availableWidth - (marginPt * 2);

    final titleImg = await _renderShapedText(
      title,
      fontSize: 16,
      maxWidth: usableWidth * 0.65,
      fontWeight: m.FontWeight.bold,
      color: const m.Color(0xFF0369A1),
    );
    final subtitleImg = await _renderShapedText(
      subtitle,
      fontSize: 10,
      maxWidth: usableWidth * 0.65,
      color: const m.Color(0xFF64748B),
    );

    final datePrefix = AppTranslations.pick(lang, en: 'Date:', mr: 'दिनांक:', hi: 'दिनांक:');
    final metaStrings = <String>[];
    if (metaLines != null && metaLines.isNotEmpty) {
      metaStrings.addAll(metaLines.map((l) => AppTranslations.formatDigits(l, lang)));
    } else {
      if (dateFormatted != null && dateFormatted.isNotEmpty) {
        metaStrings.add('$datePrefix ${AppTranslations.formatDigits(dateFormatted, lang)}');
      }
      if (totalCount != null) {
        metaStrings.add('$foundLabel: ${AppTranslations.formatDigits(totalCount, lang)}');
      }
    }
    final metaImg = metaStrings.isNotEmpty
        ? await _renderShapedText(
            metaStrings.join('\n'),
            fontSize: 9,
            maxWidth: usableWidth * 0.32,
            color: const m.Color(0xFF64748B),
            textAlign: m.TextAlign.right,
          )
        : null;

    final colCount = headers.isNotEmpty ? headers.length : 1;
    final colWidth = (usableWidth / colCount) - 12;

    final headerImgs = await Future.wait(
      headers.map((h) => _renderShapedText(
            h,
            fontSize: 9,
            maxWidth: colWidth,
            fontWeight: m.FontWeight.bold,
            color: const m.Color(0xFF334155),
          )),
    );

    final rowImgs = <List<pw.MemoryImage>>[];
    for (final row in rows) {
      final imgs = await Future.wait(
        row.map((cell) => _renderShapedText(
              cell,
              fontSize: 8.5,
              maxWidth: colWidth,
              color: const m.Color(0xFF1E293B),
            )),
      );
      rowImgs.add(imgs);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pageMargin,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(titleImg, width: titleImg.width! / 3.0),
                    pw.SizedBox(height: 2),
                    pw.Image(subtitleImg, width: subtitleImg.width! / 3.0),
                  ],
                ),
                if (metaImg != null) pw.Image(metaImg, width: metaImg.width! / 3.0),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 1.5, color: brand600),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (ctx) => [
          pw.Table(
            border: tableBorder,
            children: [
              pw.TableRow(
                decoration: tableHeaderDecoration,
                children: headerImgs
                    .map((img) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          child: pw.Image(img, width: img.width! / 3.0),
                        ))
                    .toList(),
              ),
              for (int i = 0; i < rowImgs.length; i++)
                pw.TableRow(
                  decoration: i.isOdd ? oddRowDecoration : null,
                  children: rowImgs[i]
                      .map((img) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            child: pw.Image(img, width: img.width! / 3.0),
                          ))
                      .toList(),
                ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
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
