import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/media_tracking_model.dart';
import '../../../data/models/social_post_model.dart'; // for IntFormatting
import '../../../data/repositories/media_tracking_repository.dart';
import '../../providers/language_provider.dart';

class MediaTrackingDetailScreen extends ConsumerStatefulWidget {
  final MediaTrackingArticleModel article;
  final VoidCallback? onArticleUpdated;

  const MediaTrackingDetailScreen({
    super.key,
    required this.article,
    this.onArticleUpdated,
  });

  @override
  ConsumerState<MediaTrackingDetailScreen> createState() =>
      _MediaTrackingDetailScreenState();
}

class _MediaTrackingDetailScreenState
    extends ConsumerState<MediaTrackingDetailScreen> {
  late MediaTrackingArticleModel _article;
  bool _showOriginalEnglish = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
  }

  Future<void> _openArticleUrl() async {
    final lang = ref.read(appLanguageProvider);
    final uri = Uri.parse(_article.url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppTranslations.pick(lang, en: 'Opening portal', mr: 'पोर्टल उघडत आहे', hi: 'पोर्टल खुल रहा है')}: ${_article.url}',
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppTranslations.pick(lang, en: 'Opening portal', mr: 'पोर्टल उघडत आहे', hi: 'पोर्टल खुल रहा है')}: ${_article.url}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveToNewspaperClippings() async {
    final lang = ref.read(appLanguageProvider);
    setState(() => _isSaving = true);
    final repo = ref.read(mediaTrackingRepoProvider);
    final success = await repo.saveToClipping(_article.id);
    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) {
          _article = _article.copyWith(isSavedToClipping: true);
        }
      });
      widget.onArticleUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Successfully exported to Newspaper Clippings!',
              mr: 'वृत्तपत्र कात्रणामध्ये यशस्वीरित्या जतन केले!',
              hi: 'समाचार पत्र कतरन में सफलतापूर्वक सहेजा गया!',
            ),
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> _copySummary() async {
    final lang = ref.read(appLanguageProvider);
    final rawTitle = _showOriginalEnglish ? _article.title : _article.titleFor(lang);
    final rawSummary = _showOriginalEnglish ? _article.summary : _article.summaryFor(lang);
    final trTitle = _showOriginalEnglish
        ? rawTitle
        : await DynamicTranslationService.translateOrRaw(rawTitle, lang);
    final trSummary = _showOriginalEnglish
        ? rawSummary
        : await DynamicTranslationService.translateOrRaw(rawSummary, lang);
    final readMore = AppTranslations.pick(
      lang,
      en: 'Read more',
      mr: 'अधिक वाचा',
      hi: 'अधिक पढ़ें',
    );
    final text =
        '${_article.source} (${AppTranslations.formatDigits(_article.date, lang)} ${AppTranslations.formatDigits(_article.time, lang)})\n$trTitle\n\n$trSummary\n\n$readMore: ${_article.url}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Media mention summary copied to clipboard!',
            mr: 'बातमीचा सारांश क्लिपबोर्डवर कॉपी केला!',
            hi: 'मीडिया उल्लेख सारांश क्लिपबोर्ड पर कॉपी किया गया!',
          ),
        ),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final headlineText =
        _showOriginalEnglish ? _article.title : _article.titleFor(lang);
    final summaryText =
        _showOriginalEnglish ? _article.summary : _article.summaryFor(lang);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(
              lang,
              en: 'Back',
              mr: 'मागे',
              hi: 'वापस',
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Media Mention Details',
                  mr: 'माध्यम बातमी तपशील',
                  hi: 'मीडिया उल्लेख विवरण',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${_article.source} • ${AppTranslations.formatDigits(_article.date, lang)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded,
                  color: Colors.white, size: 20),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Open in Browser',
                mr: 'ब्राउझरमध्ये उघडा',
                hi: 'ब्राउज़र में खोलें',
              ),
              onPressed: _openArticleUrl,
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: Colors.white, size: 20),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Copy Summary',
                mr: 'सारांश कॉपी करा',
                hi: 'सारांश कॉपी करें',
              ),
              onPressed: _copySummary,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Article Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar with Source and Reach
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _article.sourceBrandColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_article.sourceIcon,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                AppTranslatedText(
                                  _article.source,
                                  targetLanguage: lang,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.remove_red_eye_outlined,
                                  size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                '${AppTranslations.formatDigits(_article.reachEstimate.toLocaleString(), lang)} ${AppTranslations.pick(lang, en: 'reach', mr: 'पोहोच', hi: 'पहुंच')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Metadata details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sentiment and Subject Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _article.sentimentBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _article.sentimentColor, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                        radius: 3.5,
                                        backgroundColor:
                                            _article.sentimentColor),
                                    const SizedBox(width: 5),
                                    Text(
                                      _article.sentimentLabel(lang),
                                      style: TextStyle(
                                        color: _article.sentimentColor,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person_pin_rounded,
                                        size: 14, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: AppTranslatedText(
                                        _article.personTracked,
                                        targetLanguage: lang,
                                        isName: true,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Language Toggle Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${AppTranslations.formatDigits(_article.date, lang)} • ${AppTranslations.formatDigits(_article.time, lang)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _showOriginalEnglish = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: !_showOriginalEnglish
                                              ? const Color(0xFF0284C7)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Translated',
                                            mr: 'मराठी',
                                            hi: 'हिंदी',
                                          ),
                                          style: TextStyle(
                                            color: !_showOriginalEnglish
                                                ? Colors.white
                                                : const Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _showOriginalEnglish = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _showOriginalEnglish
                                              ? const Color(0xFF0284C7)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Original',
                                            mr: 'इंग्रजी / मूळ',
                                            hi: 'अंग्रेज़ी / मूल',
                                          ),
                                          style: TextStyle(
                                            color: _showOriginalEnglish
                                                ? Colors.white
                                                : const Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Headline
                          _showOriginalEnglish
                              ? Text(
                                  headlineText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    height: 1.45,
                                    color: Color(0xFF0F172A),
                                  ),
                                )
                              : AppTranslatedText(
                                  headlineText,
                                  targetLanguage: lang,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    height: 1.45,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                          const SizedBox(height: 12),

                          // Summary
                          _showOriginalEnglish
                              ? Text(
                                  summaryText,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.6,
                                    color: Color(0xFF334155),
                                  ),
                                )
                              : AppTranslatedText(
                                  summaryText,
                                  targetLanguage: lang,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.6,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                          const SizedBox(height: 16),

                          // Keywords
                          if (_article.keywords.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _article.keywords.map((k) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                        width: 0.5),
                                  ),
                                  child: AppTranslatedText(
                                    k,
                                    targetLanguage: lang,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Source Link Preview Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded,
                        size: 20, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Online News Source URL',
                              mr: 'ऑनलाइन बातमी स्रोत लिंक',
                              hi: 'ऑनलाइन समाचार स्रोत लिंक',
                            ),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _article.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0284C7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_browser_rounded,
                          size: 20, color: Color(0xFF0284C7)),
                      tooltip: AppTranslations.pick(
                        lang,
                        en: 'Open Link',
                        mr: 'लिंक उघडा',
                        hi: 'लिंक खोलें',
                      ),
                      onPressed: _openArticleUrl,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.language_rounded, size: 18),
                      label: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'View Full News',
                          mr: 'संपूर्ण बातमी पहा',
                          hi: 'पूरी खबर देखें',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _openArticleUrl,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _article.isSavedToClipping
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 13, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            _article.isSavedToClipping
                                ? Icons.bookmark_added_rounded
                                : Icons.bookmark_add_outlined,
                            size: 18),
                    label: Text(
                      _article.isSavedToClipping
                          ? AppTranslations.pick(
                              lang,
                              en: 'Saved',
                              mr: 'जतन केले',
                              hi: 'सहेजा गया',
                            )
                          : AppTranslations.pick(
                              lang,
                              en: 'Save to Clipping',
                              mr: 'कात्रणात जतन करा',
                              hi: 'कतरन में सहेजें',
                            ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _article.isSavedToClipping
                        ? null
                        : _saveToNewspaperClippings,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

