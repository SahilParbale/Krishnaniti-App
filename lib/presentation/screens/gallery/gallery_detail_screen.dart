import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/gallery_model.dart';
import '../../../data/repositories/gallery_repository.dart';
import '../../providers/language_provider.dart';
import 'gallery_report_generator.dart';
import '../../widgets/app_pdf_button.dart';

class GalleryDetailScreen extends ConsumerStatefulWidget {
  final GalleryItemModel item;

  const GalleryDetailScreen({super.key, required this.item});

  @override
  ConsumerState<GalleryDetailScreen> createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends ConsumerState<GalleryDetailScreen> {
  late GalleryItemModel _item;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    // Increment view count
    ref.read(galleryRepoProvider).incrementViews(_item.id);
  }

  Future<void> _handleToggleFavorite() async {
    final repo = ref.read(galleryRepoProvider);
    final fav = await repo.toggleFavorite(_item.id);
    if (mounted) {
      setState(() => _item = _item.copyWith(isFavorite: fav));
    }
  }

  String _localizedRawTitle(String lang) =>
      lang == 'mr' && _item.titleMr.isNotEmpty ? _item.titleMr : _item.title;

  String _localizedRawDesc(String lang) =>
      lang == 'mr' && _item.descriptionMr.isNotEmpty
          ? _item.descriptionMr
          : _item.description;

  Future<void> _handleShare() async {
    final lang = ref.read(appLanguageProvider);
    final rawTitle = _localizedRawTitle(lang);
    final rawDesc = _localizedRawDesc(lang);
    final titleText =
        DynamicTranslationService.getCachedTranslation(rawTitle, lang) ??
            rawTitle;
    final descText =
        DynamicTranslationService.getCachedTranslation(rawDesc, lang) ?? rawDesc;
    final locText = AppTranslations.getAreaName(_item.location, lang);
    final catLabel =
        AppTranslations.pick(lang, en: 'Category', mr: 'श्रेणी', hi: 'श्रेणी');
    final locLabel =
        AppTranslations.pick(lang, en: 'Location', mr: 'ठिकाण', hi: 'स्थान');
    final dateLabel =
        AppTranslations.pick(lang, en: 'Date', mr: 'तारीख', hi: 'दिनांक');
    final imgLabel =
        AppTranslations.pick(lang, en: 'Image', mr: 'फोटो', hi: 'फ़ोटो');
    final footer = AppTranslations.pick(
      lang,
      en: '— Nagarsevak Amit Chougale (Ward 12, PMC)',
      mr: '— नगरसेवक अमित चौगुले (प्रभाग १२, मनपा)',
      hi: '— नगरसेवक अमित चौगुले (वार्ड १२, मनपा)',
    );
    final text =
        '*$titleText*\n\n'
        '$catLabel: ${_item.category.title(lang)}\n'
        '$locLabel: $locText\n'
        '$dateLabel: ${_item.formattedDateFullFor(lang)}\n\n'
        '$descText\n\n'
        '$imgLabel: ${_item.imageUrl}\n\n'
        '$footer';

    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Details copied to clipboard!',
                  mr: 'तपशील क्लिपबोर्डवर कॉपी केला!',
                  hi: 'विवरण क्लिपबोर्ड पर कॉपी किया गया!',
                ),
              ),
            ),
          );
        }
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: text));
    }
  }

  void _handleCopy() {
    final lang = ref.read(appLanguageProvider);
    final rawTitle = _localizedRawTitle(lang);
    final rawDesc = _localizedRawDesc(lang);
    final titleText =
        DynamicTranslationService.getCachedTranslation(rawTitle, lang) ??
            rawTitle;
    final descText =
        DynamicTranslationService.getCachedTranslation(rawDesc, lang) ?? rawDesc;
    Clipboard.setData(ClipboardData(text: '$titleText\n\n$descText'));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Description copied to clipboard!',
            mr: 'वर्णन क्लिपबोर्डवर कॉपी केले!',
            hi: 'विवरण क्लिपबोर्ड पर कॉपी किया गया!',
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
          title: Text(
            _item.category.title(lang),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _item.isFavorite ? const Color(0xFFEF4444) : Colors.white,
              ),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Favorite',
                mr: 'आवडते',
                hi: 'पसंदीदा',
              ),
              onPressed: _handleToggleFavorite,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AppPdfButton.icon(
                  tooltip: AppTranslations.getDownloadReport(lang),
                  onPressed: () => GalleryReportGenerator.generateAndPrintReport(
                    items: [_item],
                    lang: lang,
                  ),
                ),
              ),
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
              // Zoomable Image Card
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 3.5,
                  child: (_item.imageUrl.startsWith('http://') || _item.imageUrl.startsWith('https://'))
                      ? Image.network(
                          _item.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (ctx, error, stackTrace) => _buildDetailImageError(lang),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: const Color(0xFF0F172A),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            );
                          },
                        )
                      : (File(_item.imageUrl).existsSync()
                          ? Image.file(
                              File(_item.imageUrl),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (ctx, error, stackTrace) => _buildDetailImageError(lang),
                            )
                          : _buildDetailImageError(lang)),
                ),
              ),

              const SizedBox(height: 16),

              // Metadata Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category, Date & Views
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _item.category.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _item.category.color.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_item.category.icon, size: 12, color: _item.category.color),
                              const SizedBox(width: 4),
                              Text(
                                _item.category.title(lang),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _item.category.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${_item.relativeTimeFor(lang)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const Spacer(),
                        const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: '${AppTranslations.formatDigits(_item.viewsCount, lang)} views',
                            mr: '${AppTranslations.formatDigits(_item.viewsCount, lang)} पाहिले',
                            hi: '${AppTranslations.formatDigits(_item.viewsCount, lang)} बार देखा गया',
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title
                    AppTranslatedText(
                      _localizedRawTitle(lang),
                      targetLanguage: lang,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),

                    // Date & Location Info
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        Text(
                          _item.formattedDateFullFor(lang),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppTranslatedText(
                            AppTranslations.getAreaName(_item.location, lang),
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Description Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Image Description',
                            mr: 'फोटोचे वर्णन',
                            hi: 'फ़ोटो का विवरण',
                          ),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        InkWell(
                          onTap: _handleCopy,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Row(
                              children: [
                                Icon(
                                  _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                  size: 13,
                                  color: _copied ? const Color(0xFF059669) : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _copied
                                      ? AppTranslations.pick(
                                          lang,
                                          en: 'Copied!',
                                          mr: 'कॉपी झाले!',
                                          hi: 'कॉपी हो गया!',
                                        )
                                      : AppTranslations.pick(
                                          lang,
                                          en: 'Copy',
                                          mr: 'कॉपी करा',
                                          hi: 'कॉपी करें',
                                        ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _copied ? const Color(0xFF059669) : const Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppTranslatedText(
                      _localizedRawDesc(lang),
                      targetLanguage: lang,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: Color(0xFF334155),
                      ),
                    ),
                    if (_item.tags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _item.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '#',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                AppTranslatedText(
                                  tag,
                                  targetLanguage: lang,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleShare,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Share Photo (WhatsApp)',
                          mr: 'फोटो शेअर करा (WhatsApp)',
                          hi: 'फ़ोटो साझा करें (WhatsApp)',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailImageError(String lang) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
            const SizedBox(height: 8),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No image available',
                mr: 'फोटो उपलब्ध नाही',
                hi: 'कोई फ़ोटो उपलब्ध नहीं',
              ),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
