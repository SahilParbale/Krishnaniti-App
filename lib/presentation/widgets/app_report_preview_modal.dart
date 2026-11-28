import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/localization/app_translations.dart';
import '../providers/language_provider.dart';

/// Modal dialog that presents the exact PDF report format preview matching
/// Nagarsevak-Managment (*ReportGenerator.tsx / *PdfGenerator.tsx)
/// with a one-click Download PDF function and Print option.
class AppReportPreviewModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final String fileName;
  final Future<Uint8List> Function() onBuildPdf;

  const AppReportPreviewModal({
    super.key,
    required this.title,
    this.subtitle = 'Report Preview',
    required this.fileName,
    required this.onBuildPdf,
  });

  /// Opens the PDF report preview modal
  static Future<void> show({
    required BuildContext context,
    required String title,
    String subtitle = 'Report Preview',
    required String fileName,
    required Future<Uint8List> Function() onBuildPdf,
  }) async {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AppReportPreviewModal(
        title: title,
        subtitle: subtitle,
        fileName: fileName.replaceAll('.pdf', ''),
        onBuildPdf: onBuildPdf,
      ),
    );
  }

  /// Convenience helper to show directly from a pw.Document
  static Future<void> showDocument({
    required BuildContext context,
    required String title,
    String subtitle = 'Report Preview',
    required String fileName,
    required pw.Document document,
  }) async {
    return show(
      context: context,
      title: title,
      subtitle: subtitle,
      fileName: fileName,
      onBuildPdf: () => document.save(),
    );
  }

  @override
  State<AppReportPreviewModal> createState() => _AppReportPreviewModalState();
}

class _AppReportPreviewModalState extends State<AppReportPreviewModal> {
  bool _downloading = false;
  Uint8List? _cachedPdfBytes;

  Future<Uint8List> _getPdfBytes() async {
    if (_cachedPdfBytes != null) return _cachedPdfBytes!;
    _cachedPdfBytes = await widget.onBuildPdf();
    return _cachedPdfBytes!;
  }

  Future<void> _handleDownload() async {
    setState(() => _downloading = true);
    try {
      final bytes = await _getPdfBytes();
      final fullFileName = '${widget.fileName}.pdf';
      bool savedLocally = false;

      // On Windows / Desktop, attempt to write directly to Downloads folder
      if (!kIsWeb && Platform.isWindows) {
        try {
          final userProfile = Platform.environment['USERPROFILE'];
          if (userProfile != null) {
            final downloadsDir = Directory('$userProfile\\Downloads');
            if (downloadsDir.existsSync()) {
              final targetFile = File('${downloadsDir.path}\\$fullFileName');
              await targetFile.writeAsBytes(bytes);
              savedLocally = true;
            }
          }
        } catch (_) {}
      }

      // Also invoke platform share / download dialog
      try {
        await Printing.sharePdf(bytes: bytes, filename: fullFileName);
      } catch (_) {}

      if (!mounted) return;
      final lang = appLanguageValueNotifier.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  savedLocally
                      ? AppTranslations.pick(
                          lang,
                          en: 'Downloaded to Downloads folder: $fullFileName',
                          mr: 'डाउनलोड्स फोल्डरमध्ये जतन केले: $fullFileName',
                          hi: 'डाउनलोड फ़ोल्डर में सहेजा गया: $fullFileName',
                        )
                      : AppTranslations.pick(
                          lang,
                          en: 'PDF ready: $fullFileName',
                          mr: 'पीडीएफ तयार आहे: $fullFileName',
                          hi: 'पीडीएफ तैयार है: $fullFileName',
                        ),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final lang = appLanguageValueNotifier.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Failed to download PDF: $e',
              mr: 'पीडीएफ डाउनलोड अयशस्वी: $e',
              hi: 'पीडीएफ डाउनलोड विफल: $e',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _handlePrint() async {
    final bytes = await _getPdfBytes();
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: '${widget.fileName}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        final effectiveSubtitle = widget.subtitle == 'Report Preview'
            ? AppTranslations.pick(lang, en: 'Report Preview', mr: 'अहवाल पूर्वावलोकन', hi: 'रिपोर्ट पूर्वावलोकन')
            : AppTranslations.formatDigits(
                AppTranslations.tr(widget.subtitle, lang: lang) ?? widget.subtitle,
                lang,
              );
        final effectiveTitle = AppTranslations.formatDigits(
          AppTranslations.tr(widget.title, lang: lang) ?? widget.title,
          lang,
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Center(
            child: Container(
              width: 960,
              constraints: const BoxConstraints(maxHeight: 840),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBAE6FD)),
                                ),
                                child: const Icon(Icons.description_rounded, size: 20, color: Color(0xFF0284C7)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      effectiveTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      effectiveSubtitle,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _handlePrint,
                              icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFF334155)),
                              label: Text(
                                AppTranslations.pick(lang, en: 'Print', mr: 'प्रिंट करा', hi: 'प्रिंट करें'),
                                style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _downloading ? null : _handleDownload,
                              icon: _downloading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                              label: Text(
                                _downloading
                                    ? AppTranslations.pick(lang, en: 'Downloading...', mr: 'डाउनलोड होत आहे...', hi: 'डाउनलोड हो रहा है...')
                                    : AppTranslations.pick(lang, en: 'Download PDF', mr: 'पीडीएफ डाउनलोड करा', hi: 'पीडीएफ डाउनलोड करें'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                              icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              splashRadius: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: PdfPreview(
                      build: (format) => _getPdfBytes(),
                      useActions: false,
                      allowPrinting: false,
                      allowSharing: false,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      initialPageFormat: PdfPageFormat.a4,
                      scrollViewDecoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                      pdfFileName: '${widget.fileName}.pdf',
                      loadingWidget: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                            const SizedBox(height: 12),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Preparing report preview...',
                                mr: 'अहवाल पूर्वावलोकन तयार होत आहे...',
                                hi: 'रिपोर्ट पूर्वावलोकन तैयार हो रहा है...',
                              ),
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
