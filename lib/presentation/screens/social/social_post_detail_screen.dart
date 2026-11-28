import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/social_post_model.dart';
import '../../providers/language_provider.dart';

class SocialPostDetailScreen extends ConsumerStatefulWidget {
  final SocialPostModel post;
  final VoidCallback? onPostUpdated;

  const SocialPostDetailScreen({
    super.key,
    required this.post,
    this.onPostUpdated,
  });

  @override
  ConsumerState<SocialPostDetailScreen> createState() =>
      _SocialPostDetailScreenState();
}

class _SocialPostDetailScreenState
    extends ConsumerState<SocialPostDetailScreen> {
  late SocialPostModel _currentPost;
  bool _showOriginalEnglish = false;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  Future<void> _openPostUrl() async {
    final lang = ref.read(appLanguageProvider);
    final urlStr = _currentPost.postUrl;
    if (urlStr == null || urlStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'No external post URL attached to this entry.',
              mr: 'या नोंदीसोबत बाह्य पोस्ट URL जोडलेले नाही.',
              hi: 'इस प्रविष्टि के साथ कोई बाहरी पोस्ट URL संलग्न नहीं है।',
            ),
          ),
        ),
      );
      return;
    }
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppTranslations.pick(lang, en: 'Opening post', mr: 'पोस्ट उघडत आहे', hi: 'पोस्ट खुल रहा है')} (${widget.post.platform}): $urlStr',
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
              '${AppTranslations.pick(lang, en: 'Opening post', mr: 'पोस्ट उघडत आहे', hi: 'पोस्ट खुल रहा है')} (${widget.post.platform}): $urlStr',
            ),
          ),
        );
      }
    }
  }

  Future<void> _copyPostContent() async {
    final lang = ref.read(appLanguageProvider);
    final rawText =
        _showOriginalEnglish ? _currentPost.content : _currentPost.contentFor(lang);
    final text = _showOriginalEnglish
        ? rawText
        : await DynamicTranslationService.translateOrRaw(rawText, lang);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Post content copied to clipboard!',
            mr: 'पोस्ट मजकूर क्लिपबोर्डवर कॉपी केला!',
            hi: 'पोस्ट सामग्री क्लिपबोर्ड पर कॉपी की गई!',
          ),
        ),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  void _showEditMetricsDialog() {
    final lang = ref.read(appLanguageProvider);
    final likesCtrl = TextEditingController(text: _currentPost.likes.toString());
    final commentsCtrl = TextEditingController(text: _currentPost.comments.toString());
    final sharesCtrl = TextEditingController(text: _currentPost.shares.toString());
    final reachCtrl = TextEditingController(text: _currentPost.reach.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Update Metrics',
                    mr: 'आकडेवारी अद्यतनित करा',
                    hi: 'आंकड़े अपडेट करें',
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reachCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppTranslations.pick(lang, en: 'Total Reach', mr: 'एकूण पोहोच', hi: 'कुल पहुंच'),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: likesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppTranslations.pick(lang, en: 'Likes', mr: 'पसंती', hi: 'पसंद'),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppTranslations.pick(lang, en: 'Comments', mr: 'टिप्पण्या', hi: 'टिप्पणियाँ'),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sharesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppTranslations.pick(lang, en: 'Shares', mr: 'शेअर्स', hi: 'शेयर'),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final newLikes = int.tryParse(AppTranslations.normalizeAsciiDigits(likesCtrl.text)) ?? _currentPost.likes;
                final newComments = int.tryParse(AppTranslations.normalizeAsciiDigits(commentsCtrl.text)) ?? _currentPost.comments;
                final newShares = int.tryParse(AppTranslations.normalizeAsciiDigits(sharesCtrl.text)) ?? _currentPost.shares;
                final newReach = int.tryParse(AppTranslations.normalizeAsciiDigits(reachCtrl.text)) ?? _currentPost.reach;

                final updated = _currentPost.copyWith(
                  likes: newLikes,
                  comments: newComments,
                  shares: newShares,
                  reach: newReach,
                );

                setState(() => _currentPost = updated);
                widget.onPostUpdated?.call();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Post metrics updated successfully!',
                        mr: 'पोस्ट आकडेवारी यशस्वीरित्या अद्यतनित केली!',
                        hi: 'पोस्ट आंकड़े सफलतापूर्वक अपडेट किए गए!',
                      ),
                    ),
                  ),
                );
              },
              child: Text(AppTranslations.pick(lang, en: 'Save', mr: 'जतन करा', hi: 'सहेजें')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final postText = _showOriginalEnglish ? _currentPost.content : _currentPost.contentFor(lang);
    final dateDisplay = AppTranslations.formatDigits(_currentPost.date, lang);

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
            tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'वापस'),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Post Details & Analytics',
                  mr: 'पोस्ट तपशील व विश्लेषण',
                  hi: 'पोस्ट विवरण व विश्लेषण',
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
                '${_currentPost.platform} • $dateDisplay',
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
              icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
              tooltip: AppTranslations.pick(lang, en: 'Copy Content', mr: 'मजकूर कॉपी करा', hi: 'सामग्री कॉपी करें'),
              onPressed: _copyPostContent,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              tooltip: AppTranslations.pick(lang, en: 'Edit Metrics', mr: 'आकडेवारी संपादित करा', hi: 'आंकड़े संपादित करें'),
              onPressed: _showEditMetricsDialog,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Preview Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentPost.imageUrl != null && _currentPost.imageUrl!.isNotEmpty)
                      Stack(
                        children: [
                          Image.network(
                            _currentPost.imageUrl!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) {
                              return Container(
                                width: double.infinity,
                                height: 180,
                                color: Colors.grey.shade200,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_currentPost.platformIcon, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_currentPost.platform} ${AppTranslations.pick(lang, en: 'Media Preview', mr: 'मीडिया पूर्वावलोकन', hi: 'मीडिया पूर्वावलोकन')}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _currentPost.platformColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_currentPost.platformIcon, color: Colors.white, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    _currentPost.platform,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dateDisplay,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Post Meta & Author
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                child: const Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF0284C7)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppTranslatedText(
                                      _currentPost.author,
                                      targetLanguage: lang,
                                      isName: true,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Official Public Update • Prabhag 12',
                                        mr: 'अधिकृत सार्वजनिक अद्यतन • प्रभाग १२',
                                        hi: 'आधिकारिक सार्वजनिक अपडेट • वार्ड १२',
                                      ),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              // Language Toggle
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => _showOriginalEnglish = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: !_showOriginalEnglish ? const Color(0xFF0284C7) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Translated',
                                            mr: 'मराठी',
                                            hi: 'हिंदी',
                                          ),
                                          style: TextStyle(
                                            color: !_showOriginalEnglish ? Colors.white : const Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _showOriginalEnglish = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _showOriginalEnglish ? const Color(0xFF0284C7) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Original',
                                            mr: 'इंग्रजी / मूळ',
                                            hi: 'अंग्रेज़ी / मूल',
                                          ),
                                          style: TextStyle(
                                            color: _showOriginalEnglish ? Colors.white : const Color(0xFF64748B),
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

                          // Text Content
                          _showOriginalEnglish
                              ? Text(
                                  postText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Color(0xFF1E293B),
                                  ),
                                )
                              : AppTranslatedText(
                                  postText,
                                  targetLanguage: lang,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                          const SizedBox(height: 12),

                          // Tags
                          if (_currentPost.tags.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _currentPost.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
                                  ),
                                  child: AppTranslatedText(
                                    tag,
                                    targetLanguage: lang,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF15803D),
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

              // KPI Stats Grid
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Performance Metrics',
                  mr: 'कामगिरी आकडेवारी',
                  hi: 'प्रदर्शन आंकड़े',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: AppTranslations.pick(lang, en: 'Total Reach', mr: 'एकूण पोहोच', hi: 'कुल पहुंच'),
                      value: AppTranslations.formatDigits(_currentPost.reach.toLocaleString(), lang),
                      icon: Icons.remove_red_eye_outlined,
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFF0F9FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      label: AppTranslations.pick(lang, en: 'Likes', mr: 'पसंती', hi: 'पसंद'),
                      value: AppTranslations.formatDigits(_currentPost.likes.toLocaleString(), lang),
                      icon: Icons.thumb_up_alt_outlined,
                      color: const Color(0xFFE11D48),
                      bgColor: const Color(0xFFFFF1F2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: AppTranslations.pick(lang, en: 'Comments', mr: 'टिप्पण्या', hi: 'टिप्पणियाँ'),
                      value: AppTranslations.formatDigits(_currentPost.comments.toString(), lang),
                      icon: Icons.chat_bubble_outline_rounded,
                      color: const Color(0xFF9333EA),
                      bgColor: const Color(0xFFFAF5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      label: AppTranslations.pick(lang, en: 'Shares', mr: 'शेअर्स', hi: 'शेयर'),
                      value: AppTranslations.formatDigits(_currentPost.shares.toString(), lang),
                      icon: Icons.share_outlined,
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFF0FDF4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Engagement Rate Meter
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                            en: 'Engagement Rate',
                            mr: 'सहभाग प्रमाण',
                            hi: 'सहभागिता दर',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${AppTranslations.formatDigits(_currentPost.engagementRate.toStringAsFixed(1), lang)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_currentPost.engagementRate / 25).clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Formula: ((Likes + Comments + Shares) / Reach) * 100 • Benchmark: > 5% is excellent',
                        mr: 'सूत्र: ((पसंती + टिप्पण्या + शेअर्स) / पोहोच) * १०० • निकष: > ५% उत्तम आहे',
                        hi: 'सूत्र: ((पसंद + टिप्पणियाँ + शेयर) / पहुंच) * १०० • मानक: > ५% उत्कृष्ट है',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Primary Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPost.platformColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: Icon(_currentPost.platformIcon, size: 18),
                      label: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Open on ${_currentPost.platform}',
                          mr: '${_currentPost.platform} वर उघडा',
                          hi: '${_currentPost.platform} पर खोलें',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _openPostUrl,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text(
                      AppTranslations.pick(lang, en: 'Share Link', mr: 'शेअर करा', hi: 'लिंक साझा करें'),
                    ),
                    onPressed: _copyPostContent,
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

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

