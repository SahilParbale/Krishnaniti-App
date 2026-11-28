import 'package:flutter/material.dart';
import '../../common/desktop_responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nagarsevak_mobile/core/localization/app_translations.dart';
import 'package:nagarsevak_mobile/core/services/translation_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/language_provider.dart';
import '../../../../data/models/social_post_model.dart';
import '../../../../data/repositories/social_analytics_repository.dart';
import '../../../screens/social/social_analytics_report_generator.dart';
import '../../../../presentation/widgets/app_load_more_footer.dart';

class DesktopSocialAnalyticsView extends ConsumerStatefulWidget {
  const DesktopSocialAnalyticsView({super.key});

  @override
  ConsumerState<DesktopSocialAnalyticsView> createState() => _DesktopSocialAnalyticsViewState();
}

class _DesktopSocialAnalyticsViewState extends ConsumerState<DesktopSocialAnalyticsView> {
  bool _loading = true;
  List<SocialPostModel> _posts = [];
  int _displayedLimit = 20;
  String _searchTerm = '';
  String _platformFilter = 'All'; // 'All' | 'Facebook' | 'Instagram'

  final List<Map<String, String>> _birthdays = [
    {'name': 'Sunil B. More', 'mobile': '9822012345', 'ward': 'Ward 12'},
    {'name': 'Anita R. Deshmukh', 'mobile': '9850123456', 'ward': 'Ward 12'},
    {'name': 'Prashant V. Kadam', 'mobile': '9422987654', 'ward': 'Ward 12'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(socialAnalyticsRepoProvider);
      final list = await repo.getPosts();
      if (mounted) {
        setState(() {
          _posts = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _posts = [];
          _loading = false;
        });
      }
    }
  }

  int get _totalLikes => _posts.fold(0, (acc, p) => acc + p.likes);
  int get _totalComments => _posts.fold(0, (acc, p) => acc + p.comments);
  int get _totalShares => _posts.fold(0, (acc, p) => acc + p.shares);

  List<SocialPostModel> get _filteredPosts {
    return _posts.where((p) {
      final matchesSearch = _searchTerm.isEmpty ||
          p.content.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.contentMarathi.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesPlatform = _platformFilter == 'All' ||
          p.platform.toLowerCase() == _platformFilter.toLowerCase();

      return matchesSearch && matchesPlatform;
    }).toList();
  }

  Future<void> _sendBirthdayWish(String mobile, String name, String lang) async {
    final locName = await DynamicTranslationService.translateOrRaw(
      name,
      lang,
      isName: true,
    );
    final messageText = AppTranslations.pick(
      lang,
      en: '🎂 Happy Birthday, $locName! Wishing you joy, health, and success in life. - Nagar Sevak Office • Ward 12',
      mr: '🎂 वाढदिवसाच्या हार्दिक शुभेच्छा, $locName! आपणास उत्तम आरोग्य, आनंद आणि यश लाभो ही सदिच्छा. - नगरसेवक कार्यालय • प्रभाग १२',
      hi: '🎂 जन्मदिन की हार्दिक शुभकामनाएं, $locName! आपके सुख, उत्तम स्वास्थ्य और सफलता की कामना करते हैं। - नगरसेवक कार्यालय • वार्ड १२',
    );
    final message = Uri.encodeComponent(messageText);
    final cleanMobile = AppTranslations.normalizeAsciiDigits(mobile);
    final uri = Uri.parse('https://wa.me/91$cleanMobile?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredPosts;
    final visible = filtered.take(_displayedLimit).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesktopResponsive.of(context).contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(lang),
          const SizedBox(height: 24),

          // 4 Stat Overview Cards
          _buildStatCards(lang),
          const SizedBox(height: 24),

          // Birthday Wishes Banner Card
          _buildBirthdayBanner(lang),
          const SizedBox(height: 24),

          // Filters Row
          _buildFilterRow(lang),
          const SizedBox(height: 24),

          // Posts Feed Grid
          if (_loading)
            _buildLoadingGrid()
          else ...[
            _buildPostGrid(visible, lang),
            if (filtered.isNotEmpty)
              AppLoadMoreFooter(
                currentCount: visible.length,
                totalCount: filtered.length,
                pageSize: 20,
                onLoadMore: () {
                  setState(() => _displayedLimit += 20);
                },
                label: AppTranslations.pick(lang, en: 'posts', mr: 'पोस्ट', hi: 'पोस्ट'),
                isMarathi: lang == 'mr',
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Social Analytics',
                  mr: 'सोशल मीडिया विश्लेषण',
                  hi: 'सोशल मीडिया विश्लेषण',
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Track Facebook and Instagram social performance, engagement and citizen reach',
                  mr: 'फेसबुक आणि इंस्टाग्राम कामगिरी, प्रतिसाद आणि नागरिकांपर्यंत पोहोच ट्रॅक करा',
                  hi: 'फेसबुक और इंस्टाग्राम प्रदर्शन, जुड़ाव और नागरिकों तक पहुंच ट्रैक करें',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions Row matching SocialAnalytics.tsx
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                final summary = SocialAnalyticsSummary(
                  totalPosts: _posts.length,
                  totalReach: (_totalLikes + _totalComments) * 12,
                  totalLikes: _totalLikes,
                  totalComments: _totalComments,
                  totalShares: _totalShares,
                  averageEngagementRate: _posts.isNotEmpty ? ((_totalLikes + _totalComments) / _posts.length) : 0.0,
                  monthlyGrowth: '+12.4%',
                );
                SocialAnalyticsReportGenerator.generateAndPrintReport(
                  context: context,
                  posts: _filteredPosts,
                  summary: summary,
                  birthdays: const [],
                  platformFilter: _platformFilter,
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.getDownloadReport(lang),
                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),

            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.facebook, size: 18, color: Colors.white),
              label: Text(
                AppTranslations.pick(lang, en: 'Facebook Connect', mr: 'फेसबुक कनेक्ट', hi: 'फेसबुक कनेक्ट'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
              label: Text(
                AppTranslations.pick(lang, en: 'Instagram Connect', mr: 'इंस्टाग्राम कनेक्ट', hi: 'इंस्टाग्राम कनेक्ट'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE1306C),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards(String lang) {
    final sharesStr = AppTranslations.formatDigits(_totalShares, lang);
    final commentsStr = AppTranslations.formatDigits(_totalComments, lang);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _statCard(
              title: AppTranslations.pick(lang, en: 'Total Reach', mr: 'एकूण पोहोच (Reach)', hi: 'कुल पहुंच (Reach)'),
              value: AppTranslations.formatDigits('45.2K', lang),
              subtitle: AppTranslations.formatDigits(
                AppTranslations.pick(lang, en: '+12% vs last month', mr: 'मागील महिन्यापेक्षा +१२% अधिक', hi: 'पिछले महीने से +१२% अधिक'),
                lang,
              ),
              icon: Icons.remove_red_eye_outlined,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFF0F9FF),
            ),
            _statCard(
              title: AppTranslations.pick(lang, en: 'Engagement', mr: 'नागरिक प्रतिसाद', hi: 'नागरिक जुड़ाव'),
              value: AppTranslations.formatDigits('8.4%', lang),
              subtitle: AppTranslations.pick(lang, en: 'High citizen interaction', mr: 'उत्कृष्ट नागरिक संवाद', hi: 'उच्च नागरिक संवाद'),
              icon: Icons.trending_up,
              iconColor: const Color(0xFF16A34A),
              iconBgColor: const Color(0xFFF0FDF4),
            ),
            _statCard(
              title: AppTranslations.pick(lang, en: 'Followers', mr: 'फॉलोअर्स', hi: 'फॉलोअर्स'),
              value: AppTranslations.formatDigits('+1,250', lang),
              subtitle: AppTranslations.pick(lang, en: 'Growing this month', mr: 'या महिन्यात सातत्याने वाढ', hi: 'इस महीने लगातार वृद्धि'),
              icon: Icons.group_outlined,
              iconColor: const Color(0xFF7E22CE),
              iconBgColor: const Color(0xFFFAF5FF),
            ),
            _statCard(
              title: AppTranslations.pick(lang, en: 'Total Likes & Shares', mr: 'एकूण लाईक्स व शेअर्स', hi: 'कुल लाइक्स और शेयर'),
              value: AppTranslations.formatDigits(_totalLikes, lang),
              subtitle: AppTranslations.pick(
                lang,
                en: '$sharesStr shares • $commentsStr comments',
                mr: '$sharesStr शेअर्स • $commentsStr कमेंट्स',
                hi: '$sharesStr शेयर • $commentsStr कमेंट्स',
              ),
              icon: Icons.thumb_up_alt_outlined,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFFFBEB),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildBirthdayBanner(String lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cake_outlined, size: 20, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text(
                AppTranslations.pick(
                  lang,
                  en: "Today's Voter Birthdays",
                  mr: 'आजचे मतदार वाढदिवस',
                  hi: 'आज के मतदाता जन्मदिन',
                ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Send direct birthday wishes to ward voters via WhatsApp',
                    mr: 'प्रभागातील मतदारांना थेट WhatsApp वरून वाढदिवसाच्या शुभेच्छा पाठवा',
                    hi: 'वार्ड के मतदाताओं को सीधे WhatsApp पर जन्मदिन की शुभकामनाएं भेजें',
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: _birthdays.map((v) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTranslatedText(
                      v['name']!,
                      isName: true,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _sendBirthdayWish(v['mobile']!, v['name']!, lang),
                      icon: const Icon(Icons.chat_bubble_outline, size: 12, color: Colors.white),
                      label: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Send Wishes',
                          mr: 'शुभेच्छा पाठवा',
                          hi: 'शुभकामना भेजें',
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(String lang) {
    return Row(
      children: [
        // Search Input (Col 8)
        Expanded(
          flex: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _displayedLimit = 20;
                _searchTerm = val;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search social media post content...',
                  mr: 'सोशल मीडिया पोस्ट मजकूर शोधा...',
                  hi: 'सोशल मीडिया पोस्ट सामग्री खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Platform Filter Tabs (Col 4)
        Row(
          children: ['All', 'Facebook', 'Instagram'].map((platform) {
            final isSelected = _platformFilter == platform;
            final label = platform == 'All'
                ? AppTranslations.pick(lang, en: 'All Platforms', mr: 'सर्व प्लॅटफॉर्म', hi: 'सभी प्लेटफॉर्म')
                : platform == 'Facebook'
                    ? AppTranslations.pick(lang, en: 'Facebook', mr: 'फेसबुक', hi: 'फेसबुक')
                    : AppTranslations.pick(lang, en: 'Instagram', mr: 'इंस्टाग्राम', hi: 'इंस्टाग्राम');

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() {
                  _displayedLimit = 20;
                  _platformFilter = platform;
                }),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPostGrid(List<SocialPostModel> items, String lang) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.feed_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No posts found',
                mr: 'कोणत्याही पोस्ट सापडल्या नाहीत',
                hi: 'कोई पोस्ट नहीं मिली',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 380,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final isFb = item.platform.toLowerCase() == 'facebook';
            final parsedDate = DateTime.tryParse(item.date);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Platform badge & Date
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFb ? const Color(0xFFF0F9FF) : const Color(0xFFFDF2F8),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: isFb ? const Color(0xFFBAE6FD) : const Color(0xFFFBCFE8)),
                            ),
                            child: Row(
                              children: [
                                Icon(isFb ? Icons.facebook : Icons.camera_alt_outlined, size: 14, color: isFb ? const Color(0xFF1877F2) : const Color(0xFFE1306C)),
                                const SizedBox(width: 6),
                                AppTranslatedText(
                                  item.platform,
                                  targetLanguage: lang,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isFb ? const Color(0xFF1877F2) : const Color(0xFFE1306C)),
                                ),
                              ],
                            ),
                          ),
                          parsedDate != null
                              ? Text(
                                  AppTranslations.formatDate(parsedDate, lang),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                )
                              : AppTranslatedText(
                                  item.date,
                                  targetLanguage: lang,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                        ],
                      ),
                    ),

                    // Image Thumbnail
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      Image.network(
                        item.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          color: const Color(0xFFF1F5F9),
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                        ),
                      ),

                    // Text Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: AppTranslatedText(
                          item.contentFor(lang),
                          targetLanguage: lang,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                        ),
                      ),
                    ),

                    // Bottom Stats (Likes, Comments, Shares)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(AppTranslations.formatDigits(item.likes, lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(AppTranslations.formatDigits(item.comments, lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.share_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(AppTranslations.formatDigits(item.shares, lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 320,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
