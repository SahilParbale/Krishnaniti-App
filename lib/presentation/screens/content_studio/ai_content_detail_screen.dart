import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/ai_content_model.dart';
import '../../../data/repositories/ai_content_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_pdf_button.dart';
import 'ai_content_report_generator.dart';

class AiContentDetailScreen extends ConsumerStatefulWidget {
  final AiContentHistoryItem item;
  final VoidCallback? onReloadIntoEditor;

  const AiContentDetailScreen({
    super.key,
    required this.item,
    this.onReloadIntoEditor,
  });

  @override
  ConsumerState<AiContentDetailScreen> createState() =>
      _AiContentDetailScreenState();
}

class _AiContentDetailScreenState extends ConsumerState<AiContentDetailScreen> {
  late AiContentHistoryItem _item;
  bool _copied = false;
  double _fontSize = 15.0;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  void _handleCopy() {
    final lang = ref.read(appLanguageProvider);
    final translatedContent =
        DynamicTranslationService.getCachedTranslation(_item.generatedContent, lang) ??
            _item.generatedContent;
    Clipboard.setData(ClipboardData(text: translatedContent));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Content copied to clipboard!',
            mr: 'मजकूर क्लिपबोर्डवर कॉपी केला!',
            hi: 'सामग्री क्लिपबोर्ड पर कॉपी की गई!',
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _handleShare() async {
    final lang = ref.read(appLanguageProvider);
    final title =
        DynamicTranslationService.getCachedTranslation(_item.title, lang) ??
            _item.title;
    final content =
        DynamicTranslationService.getCachedTranslation(_item.generatedContent, lang) ??
            _item.generatedContent;
    final footer = AppTranslations.pick(
      lang,
      en: '— Nagarsevak Amit Chougale (Ward 12)',
      mr: '— नगरसेवक अमित चौगुले (प्रभाग १२)',
      hi: '— नगरसेवक अमित चौगुले (वार्ड १२)',
    );
    final text = '$title\n\n$content\n\n$footer';
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    final copiedMsg = AppTranslations.pick(
      lang,
      en: 'Content copied to clipboard!',
      mr: 'मजकूर क्लिपबोर्डवर कॉपी केला!',
      hi: 'सामग्री क्लिपबोर्ड पर कॉपी की गई!',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(copiedMsg)),
          );
        }
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(copiedMsg)),
        );
      }
    }
  }

  Future<void> _handleToggleFavorite() async {
    final repo = ref.read(aiContentRepoProvider);
    final fav = await repo.toggleFavorite(_item.id);
    if (mounted) {
      setState(() {
        _item = _item.copyWith(isFavorite: fav);
      });
    }
  }

  Future<void> _handlePrintPdf() async {
    final lang = ref.read(appLanguageProvider);
    await AiContentReportGenerator.printDocument(_item, lang: lang);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'वापस'),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _item.contentType.title(lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_item.tone.title(lang)} • ${_item.language.labelFor(lang)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _item.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: _item.isFavorite ? Colors.amberAccent : Colors.white,
              ),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Favorite',
                mr: 'आवडते',
                hi: 'पसंदीदा',
              ),
              onPressed: _handleToggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.print_rounded, color: Colors.white),
              tooltip: AppTranslations.getDownloadReport(lang),
              onPressed: _handlePrintPdf,
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Share',
                mr: 'शेअर करा',
                hi: 'साझा करें',
              ),
              onPressed: _handleShare,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic / Context Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _item.contentType.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _item.contentType.color.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _item.contentType.icon,
                                size: 14,
                                color: _item.contentType.color,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _item.contentType.title(lang),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _item.contentType.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _item.tone.icon,
                                size: 14,
                                color: const Color(0xFF475569),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _item.tone.title(lang),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _item.relativeTimeFor(lang),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppTranslatedText(
                      _item.title,
                      targetLanguage: lang,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: '${AppTranslations.formatDigits(_item.wordCount, lang)} words',
                            mr: '${AppTranslations.formatDigits(_item.wordCount, lang)} शब्द',
                            hi: '${AppTranslations.formatDigits(_item.wordCount, lang)} शब्द',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${AppTranslations.pick(lang, en: "Reading Time", mr: "वाचन वेळ", hi: "पढ़ने का समय")}: ${_item.readingTimeFormattedFor(lang)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        // Font Size Controls for reading on stage
                        InkWell(
                          onTap: () {
                            if (_fontSize > 13) {
                              setState(() => _fontSize -= 1.5);
                            }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'A-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            if (_fontSize < 24) {
                              setState(() => _fontSize += 1.5);
                            }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'A+',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Generated Text Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FutureBuilder<String>(
                  key: ValueKey('ai_content_${_item.id}_$lang'),
                  future: DynamicTranslationService.translateOrRaw(
                    _item.generatedContent,
                    lang,
                  ),
                  initialData: DynamicTranslationService.getCachedTranslation(
                        _item.generatedContent,
                        lang,
                      ) ??
                      _item.generatedContent,
                  builder: (ctx, snap) {
                    return SelectableText(
                      snap.data ?? _item.generatedContent,
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: 1.6,
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.normal,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleCopy,
                      icon: Icon(
                        _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _copied
                            ? AppTranslations.pick(
                                lang,
                                en: 'Copied!',
                                mr: 'कॉपी झाले!',
                                hi: 'कॉपी हो गया!',
                              )
                            : AppTranslations.pick(
                                lang,
                                en: 'Copy Content',
                                mr: 'मजकूर कॉपी करा',
                                hi: 'सामग्री कॉपी करें',
                              ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _copied
                            ? const Color(0xFF059669)
                            : const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _handleShare,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Share',
                        mr: 'शेअर करा',
                        hi: 'साझा करें',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppPdfButton.outlined(
                label: AppTranslations.pick(
                  lang,
                  en: 'Reports',
                  mr: 'अहवाल',
                  hi: 'रिपोर्ट',
                ),
                tooltip: AppTranslations.pick(
                  lang,
                  en: 'Reports',
                  mr: 'अहवाल',
                  hi: 'रिपोर्ट',
                ),
                isCompact: false,
                onPressed: _handlePrintPdf,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

