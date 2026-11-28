import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/social_post_model.dart';
import '../../../data/repositories/social_analytics_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_dropdown.dart';
import 'social_analytics_report_generator.dart';
import 'social_post_detail_screen.dart';

class SocialAnalyticsScreen extends ConsumerStatefulWidget {
  const SocialAnalyticsScreen({super.key});

  @override
  ConsumerState<SocialAnalyticsScreen> createState() => _SocialAnalyticsScreenState();
}

class _SocialAnalyticsScreenState extends ConsumerState<SocialAnalyticsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedPlatform = 'All'; // 'All' | 'Facebook' | 'Instagram' | 'Twitter'
  String _sortBy = 'newest'; // 'newest' | 'likes' | 'reach' | 'engagement'
  String _viewMode = 'feed'; // 'feed' | 'table'

  bool _isLoading = true;
  List<SocialPostModel> _allPosts = [];
  List<VoterBirthdayModel> _birthdays = [];
  SocialAnalyticsSummary? _summary;

  final List<String> _platforms = ['All', 'Facebook', 'Instagram', 'Twitter'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(socialAnalyticsRepoProvider);
    final posts = await repo.getPosts();
    final birthdays = await repo.getBirthdays();
    final summary = await repo.getSummary();

    if (mounted) {
      setState(() {
        _allPosts = posts;
        _birthdays = birthdays;
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  List<SocialPostModel> get _filteredPosts {
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = _allPosts.where((p) {
      if (_selectedPlatform != 'All' && p.platform.toLowerCase() != _selectedPlatform.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        final contentMatch = p.content.toLowerCase().contains(query);
        final marathiMatch = p.contentMarathi.toLowerCase().contains(query);
        final tagMatch = p.tags.any((t) => t.toLowerCase().contains(query));
        final platformMatch = p.platform.toLowerCase().contains(query);
        if (!contentMatch && !marathiMatch && !tagMatch && !platformMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'likes':
        filtered.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case 'reach':
        filtered.sort((a, b) => b.reach.compareTo(a.reach));
        break;
      case 'engagement':
        filtered.sort((a, b) => b.engagementRate.compareTo(a.engagementRate));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    return filtered;
  }

  Future<void> _sendBirthdayGreeting(VoterBirthdayModel voter) async {
    final lang = ref.read(appLanguageProvider);
    final mobileClean = voter.mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    final voterName = await DynamicTranslationService.translateOrRaw(
      lang == 'mr' && voter.nameMarathi.isNotEmpty
          ? voter.nameMarathi
          : voter.displayName,
      lang,
      isName: true,
    );
    final msg = Uri.encodeComponent(
      AppTranslations.pick(
        lang,
        en: 'Wishing you a very Happy Birthday $voterName! Wishing you good health, long life, and happiness. - Your Nagarsevak, Ward 12, Pune.',
        mr: '$voterName, तुम्हाला वाढदिवसाच्या खूप खूप शुभेच्छा! तुम्हाला उत्तम आरोग्य, दीर्घायुष्य आणि आनंद लाभो ही सदिच्छा. - तुमचा नगरसेवक, प्रभाग १२, पुणे.',
        hi: '$voterName, आपको जन्मदिन की हार्दिक शुभकामनाएँ! आपके उत्तम स्वास्थ्य, दीर्घायु और खुशियों की कामना। - आपका नगरसेवक, वार्ड १२, पुणे।',
      ),
    );
    final uri = Uri.parse('https://wa.me/$mobileClean?text=$msg');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppTranslations.pick(lang, en: 'Opening WhatsApp for', mr: 'व्हॉट्सअॅप उघडत आहे:', hi: 'व्हाट्सएप खुल रहा है:')} $voterName...',
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
              '${AppTranslations.pick(lang, en: 'Opening WhatsApp for', mr: 'व्हॉट्सअॅप उघडत आहे:', hi: 'व्हाट्सएप खुल रहा है:')} $voterName...',
            ),
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final lang = ref.read(appLanguageProvider);
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppTranslations.pick(lang, en: 'Calling', mr: 'कॉल करत आहे', hi: 'कॉल कर रहे हैं')} ${AppTranslations.formatDigits(phoneNumber, lang)}...',
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
              '${AppTranslations.pick(lang, en: 'Calling', mr: 'कॉल करत आहे', hi: 'कॉल कर रहे हैं')} ${AppTranslations.formatDigits(phoneNumber, lang)}...',
            ),
          ),
        );
      }
    }
  }

  void _showHelpTutorialDialog() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Social Analytics Guide',
                    mr: 'सोशल मीडिया विश्लेषण मार्गदर्शक',
                    hi: 'सोशल एनालिटिक्स मार्गदर्शिका',
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Social Media Analytics & Constituent Engagement Guide',
                    mr: 'सोशल मीडिया विश्लेषण आणि नागरिक संवाद मार्गदर्शक',
                    hi: 'सोशल मीडिया एनालिटिक्स व नागरिक संवाद मार्गदर्शिका',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7)),
                ),
                const SizedBox(height: 10),
                _TutorialStep(
                  step: AppTranslations.formatDigits('1', lang),
                  title: AppTranslations.pick(
                    lang,
                    en: 'Performance Overview',
                    mr: 'कामगिरीचा आढावा',
                    hi: 'प्रदर्शन अवलोकन',
                  ),
                  desc: AppTranslations.pick(
                    lang,
                    en: 'Track total impressions, likes, citizen comments, and shares across Facebook, Instagram, and Twitter.',
                    mr: 'फेसबुक, इन्स्टाग्राम आणि ट्विटरवरील एकूण पोहोच, पसंती, नागरिकांच्या टिप्पण्या व शेअर्स ट्रॅक करा.',
                    hi: 'फेसबुक, इंस्टाग्राम व ट्विटर पर कुल पहुंच, पसंद, टिप्पणियां व शेयर ट्रैक करें।',
                  ),
                ),
                _TutorialStep(
                  step: AppTranslations.formatDigits('2', lang),
                  title: AppTranslations.pick(
                    lang,
                    en: 'Connect Accounts',
                    mr: 'खाती जोडा',
                    hi: 'खाते जोड़ें',
                  ),
                  desc: AppTranslations.pick(
                    lang,
                    en: 'Keep official Facebook page and Instagram accounts synchronized for live performance tracking.',
                    mr: 'थेट कामगिरी ट्रॅकिंगसाठी अधिकृत फेसबुक पेज व इन्स्टाग्राम खाती सिंक ठेवा.',
                    hi: 'लाइव प्रदर्शन ट्रैकिंग के लिए आधिकारिक फेसबुक पेज व इंस्टाग्राम खातों को सिंक रखें।',
                  ),
                ),
                _TutorialStep(
                  step: AppTranslations.formatDigits('3', lang),
                  title: AppTranslations.pick(
                    lang,
                    en: 'Constituent Birthdays',
                    mr: 'मतदारांचे वाढदिवस',
                    hi: 'मतदाता जन्मदिन',
                  ),
                  desc: AppTranslations.pick(
                    lang,
                    en: 'Build personal relations by sending customized greetings via WhatsApp to voters on their birthdays.',
                    mr: 'मतदारांना त्यांच्या वाढदिवसानिमित्त व्हॉट्सअॅपद्वारे वैयक्तिक शुभेच्छा पाठवून संवाद वाढवा.',
                    hi: 'मतदाताओं को उनके जन्मदिन पर व्हाट्सएप द्वारा व्यक्तिगत शुभकामनाएं भेजकर संबंध मजबूत करें।',
                  ),
                ),
                _TutorialStep(
                  step: AppTranslations.formatDigits('4', lang),
                  title: AppTranslations.pick(
                    lang,
                    en: 'PDF Audit Reports',
                    mr: 'पीडीएफ ऑडिट अहवाल',
                    hi: 'पीडीएफ ऑडिट रिपोर्ट',
                  ),
                  desc: AppTranslations.pick(
                    lang,
                    en: 'Export landscape A4 audit report with engagement metrics for corporator review meetings.',
                    mr: 'नगरसेवक आढावा बैठकांसाठी सहभाग आकडेवारीसह लँडस्केप A4 ऑडिट अहवाल डाउनलोड करा.',
                    hi: 'पार्षद समीक्षा बैठकों के लिए सहभागिता आंकड़ों सहित लैंडस्केप A4 ऑडिट रिपोर्ट डाउनलोड करें।',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppTranslations.pick(lang, en: 'Got it', mr: 'समजले', hi: 'समझ गया')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final filtered = _filteredPosts;
    final totalLikes = _allPosts.fold<int>(0, (acc, p) => acc + p.likes);
    final totalComments = _allPosts.fold<int>(0, (acc, p) => acc + p.comments);
    final totalShares = _allPosts.fold<int>(0, (acc, p) => acc + p.shares);
    final totalReach = _allPosts.fold<int>(0, (acc, p) => acc + p.reach);

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
          scrolledUnderElevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Open Menu Drawer',
                mr: 'मेनू उघडा',
                hi: 'मेनू खोलें',
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.getNavTitle('social_analytics', lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                lang == 'mr'
                    ? 'सोशल मीडिया पोहोच आणि परस्परसंवाद'
                    : (lang == 'hi'
                        ? 'सोशल मीडिया पहुंच और सहभागिता'
                        : 'Social reach & engagement'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: const [],
        ),
        drawer: const NagarsevakAppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  children: [
                    // 1) CONNECT SOCIAL CHANNELS BAR
                    _buildConnectChannelsBar(lang),
                    const SizedBox(height: 14),

                    // 2) 4 EXECUTIVE SUMMARY KPI CARDS
                    _buildKpiCardsRow(
                      reach: totalReach > 0 ? totalReach : 45200,
                      likes: totalLikes,
                      comments: totalComments,
                      shares: totalShares,
                      lang: lang,
                    ),
                    const SizedBox(height: 14),

                    // 3) GROWTH & ENGAGEMENT HIGHLIGHT BANNER
                    _buildGrowthBanner(lang),
                    const SizedBox(height: 14),

                    // 4) CONSTITUENCY ENGAGEMENT: TODAY'S BIRTHDAYS
                    _buildBirthdaysSection(lang),
                    const SizedBox(height: 16),

                    // 5) FILTER & SEARCH STRIP
                    _buildFilterSection(lang),
                    const SizedBox(height: 12),

                    // 6) POSTS COUNT & SORT BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lang == 'mr'
                                ? 'एकूण ${AppTranslations.formatDigits(_allPosts.length, lang)} पैकी ${AppTranslations.formatDigits(filtered.length, lang)} पोस्ट दाखवत आहे'
                                : (lang == 'hi'
                                    ? 'कुल ${AppTranslations.formatDigits(_allPosts.length, lang)} में से ${AppTranslations.formatDigits(filtered.length, lang)} पोस्ट दिखाए जा रहे हैं'
                                    : 'Showing ${filtered.length} of ${_allPosts.length} posts'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              lang == 'mr' ? 'क्रमवारी: ' : (lang == 'hi' ? 'क्रम: ' : 'Sort: '),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            AppDropdown<String>(
                              title: lang == 'mr' ? 'क्रमवारी' : (lang == 'hi' ? 'क्रम' : 'Sort By'),
                              value: _sortBy,
                              height: 36,
                              isExpanded: false,
                              items: [
                                DropdownMenuItem(value: 'newest', child: Text(lang == 'mr' ? 'नवीनतम प्रथम' : (lang == 'hi' ? 'नवीनतम पहले' : 'Newest First'))),
                                DropdownMenuItem(value: 'likes', child: Text(lang == 'mr' ? 'सर्वाधिक पसंती' : (lang == 'hi' ? 'सबसे ज्यादा पसंद' : 'Most Liked'))),
                                DropdownMenuItem(value: 'reach', child: Text(lang == 'mr' ? 'सर्वाधिक पोहोच' : (lang == 'hi' ? 'उच्चतम पहुंच' : 'Highest Reach'))),
                                DropdownMenuItem(value: 'engagement', child: Text(lang == 'mr' ? 'सर्वाधिक सहभाग' : (lang == 'hi' ? 'उच्चतम सहभागिता' : 'Highest Engagement'))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _sortBy = val);
                              },
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: Icon(
                                _viewMode == 'feed' ? Icons.table_chart_outlined : Icons.view_agenda_outlined,
                                color: const Color(0xFF0284C7),
                                size: 20,
                              ),
                              tooltip: _viewMode == 'feed'
                                  ? AppTranslations.pick(lang, en: 'Switch to Table', mr: 'तक्त्यात पहा', hi: 'तालिका में देखें')
                                  : AppTranslations.pick(lang, en: 'Switch to Feed', mr: 'फीड पहा', hi: 'फ़ीड में देखें'),
                              onPressed: () => setState(() => _viewMode = _viewMode == 'feed' ? 'table' : 'feed'),
                            ),
                            AppPdfButton.icon(
                              tooltip: AppTranslations.getDownloadReport(lang),
                              onPressed: () {
                                if (_summary != null) {
                                  SocialAnalyticsReportGenerator.generateAndPrintReport(
                                    posts: filtered,
                                    summary: _summary!,
                                    birthdays: _birthdays,
                                    platformFilter: _selectedPlatform,
                                    lang: lang,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 7) DUAL VIEW CONTENT (FEED CARDS vs REPORT TABLE)
                    if (filtered.isEmpty)
                      _buildEmptyState(lang)
                    else if (_viewMode == 'feed')
                      ...filtered.map((post) => _buildPostFeedCard(post, lang))
                    else
                      _buildPostsTableView(filtered, lang),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // 1) Connect Channels Bar
  Widget _buildConnectChannelsBar(String lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.share_rounded, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Text(
                    lang == 'mr' ? 'जोडलेले चॅनेल्स' : (lang == 'hi' ? 'जुड़े हुए चैनल' : 'Connected Channels'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(radius: 3, backgroundColor: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      lang == 'mr' ? 'थेट समक्रमित' : (lang == 'hi' ? 'लाइव सिंक' : 'Live Synced'),
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // FB Button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.facebook, size: 16),
                  label: Text(
                    lang == 'mr' ? 'फेसबुक जोडा' : (lang == 'hi' ? 'फेसबुक जोड़ें' : 'Connect FB'),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                        lang == 'mr'
                            ? 'अधिकृत फेसबुक पेज: "नगरसेवक प्रभाग १२" सक्रिय आहे.'
                            : (lang == 'hi'
                                ? 'आधिकारिक फेसबुक पेज: "नगरसेवक प्रभाग १२" सक्रिय है।'
                                : 'Official Facebook Page: "Nagarsevak Prabhag 12" is active.'),
                      )),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // IG Button
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF77737)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: Text(
                      lang == 'mr' ? 'इन्स्टाग्राम जोडा' : (lang == 'hi' ? 'इंस्टाग्राम जोड़ें' : 'Connect IG'),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(
                          lang == 'mr'
                              ? 'अधिकृत इंस्टाग्राम प्रोफाइल: "@nagarsevak_prabhag12" जोडले आहे.'
                              : (lang == 'hi'
                                  ? 'आधिकारिक इंस्टाग्राम प्रोफ़ाइल: "@nagarsevak_prabhag12" जुड़ी है।'
                                  : 'Official Instagram Profile: "@nagarsevak_prabhag12" connected.'),
                        )),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2) 4 Executive KPI Cards Row
  Widget _buildKpiCardsRow({
    required int reach,
    required int likes,
    required int comments,
    required int shares,
    required String lang,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: lang == 'mr' ? 'एकूण पोहोच' : (lang == 'hi' ? 'कुल पहुंच' : 'Total Reach'),
                marathi: lang == 'mr' ? 'नागरिक पोहोच' : (lang == 'hi' ? 'नागरिक पहुंच' : 'Total Reach'),
                value: AppTranslations.formatDigits(reach.toLocaleString(), lang),
                icon: Icons.remove_red_eye_outlined,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                subtitle: lang == 'mr' ? '+१२% मागील महिन्याच्या तुलनेत' : (lang == 'hi' ? '+१२% पिछले महीने की तुलना में' : '+12% vs last month'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: lang == 'mr' ? 'एकूण पसंती' : (lang == 'hi' ? 'कुल पसंद' : 'Total Likes'),
                marathi: lang == 'mr' ? 'पसंती' : (lang == 'hi' ? 'पसंद' : 'Likes'),
                value: AppTranslations.formatDigits(likes.toLocaleString(), lang),
                icon: Icons.thumb_up_alt_outlined,
                color: const Color(0xFFE11D48),
                bgColor: const Color(0xFFFFF1F2),
                subtitle: lang == 'mr' ? 'नागरिकांचा पाठिंबा' : (lang == 'hi' ? 'नागरिकों का समर्थन' : 'Constituent loves'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: lang == 'mr' ? 'टिप्पण्या' : (lang == 'hi' ? 'टिप्पणियाँ' : 'Comments'),
                marathi: lang == 'mr' ? 'टिप्पण्या' : (lang == 'hi' ? 'टिप्पणियाँ' : 'Comments'),
                value: AppTranslations.formatDigits(comments.toLocaleString(), lang),
                icon: Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF9333EA),
                bgColor: const Color(0xFFFAF5FF),
                subtitle: lang == 'mr' ? 'थेट अभिप्राय' : (lang == 'hi' ? 'सीधा फीडबैक' : 'Direct feedback'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: lang == 'mr' ? 'शेअर्स' : (lang == 'hi' ? 'शेयर' : 'Shares'),
                marathi: lang == 'mr' ? 'शेअर्स' : (lang == 'hi' ? 'शेयर' : 'Shares'),
                value: AppTranslations.formatDigits(shares.toLocaleString(), lang),
                icon: Icons.share_outlined,
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFF0FDF4),
                subtitle: lang == 'mr' ? 'माहिती प्रसार' : (lang == 'hi' ? 'सूचना प्रसार' : 'Word of mouth'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String marathi,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3) Growth Banner
  Widget _buildGrowthBanner(String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      lang == 'mr' ? 'मासिक पोहोच वाढ' : (lang == 'hi' ? 'मासिक पहुंच वृद्धि' : 'Monthly Reach Growth'),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lang == 'mr' ? '+१२%' : (lang == 'hi' ? '+१२%' : '+12%'),
                      style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  lang == 'mr'
                      ? 'प्रभाग १२ मधील नागरी कामांच्या नियमित अपडेट्समुळे नागरिकांचा सहभाग वाढला आहे.'
                      : (lang == 'hi'
                          ? 'वार्ड १२ में नागरिक कार्यों के नियमित अपडेट्स से नागरिकों की सहभागिता बढ़ी है।'
                          : 'Consistent updates on civic works in Ward 12 have boosted constituent engagement.'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4) Constituency Engagement: Today's Birthdays
  Widget _buildBirthdaysSection(String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.cake_rounded, size: 16, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lang == 'mr' ? 'आजचे वाढदिवस' : (lang == 'hi' ? 'आज के जन्मदिन' : "Today's Birthdays"),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  lang == 'mr'
                      ? 'शुभेच्छा पाठवा (${AppTranslations.formatDigits(_birthdays.length, lang)})'
                      : (lang == 'hi'
                          ? 'शुभकामनाएं भेजें (${AppTranslations.formatDigits(_birthdays.length, lang)})'
                          : 'Send Wishes (${_birthdays.length})'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_birthdays.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                lang == 'mr'
                    ? 'आज कोणाचाही वाढदिवस नोंदवलेला नाही.'
                    : (lang == 'hi'
                        ? 'आज किसी का जन्मदिन पंजीकृत नहीं है।'
                        : 'No constituent birthdays registered for today.'),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            ..._birthdays.map((voter) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.7),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      child: Text(
                        voter.name.isNotEmpty ? voter.name[0] : 'V',
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTranslatedText(
                            lang == 'mr' && voter.nameMarathi.isNotEmpty ? voter.nameMarathi : voter.name,
                            targetLanguage: lang,
                            isName: true,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${lang == 'mr' ? 'वय' : (lang == 'hi' ? 'आयु' : 'Age')}: ${AppTranslations.formatDigits(voter.age, lang)}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                          Text(
                            '${AppTranslations.getAreaName(voter.area, lang)} • ${lang == 'mr' ? 'बूथ क्र.' : (lang == 'hi' ? 'बूथ सं.' : 'Booth')}: ${AppTranslations.formatDigits(voter.boothNumber, lang)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons (WhatsApp Greeting & Phone Call)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF0284C7)),
                          tooltip: lang == 'mr' ? 'मतदाराला कॉल करा' : (lang == 'hi' ? 'मतदाता को कॉल करें' : 'Call Voter'),
                          onPressed: () => _makePhoneCall(voter.mobile),
                        ),
                        InkWell(
                          onTap: () => _sendBirthdayGreeting(voter),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  lang == 'mr' ? 'शुभेच्छा' : (lang == 'hi' ? 'शुभकामनाएं' : 'Wish'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 5) Filter & Search Section
  Widget _buildFilterSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: lang == 'mr'
                  ? 'विषय, मराठी मजकूर, #टॅग्ज शोधा...'
                  : (lang == 'hi'
                      ? 'विषय, मजमून, #टैग खोजें...'
                      : 'Search posts by topic, Marathi text, #tags...'),
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Platform Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _platforms.map((plat) {
              final isSel = _selectedPlatform == plat;
              final count = plat == 'All'
                  ? _allPosts.length
                  : _allPosts.where((p) => p.platform.toLowerCase() == plat.toLowerCase()).length;
              final platLabel = plat == 'All'
                  ? (lang == 'mr' ? 'सर्व' : (lang == 'hi' ? 'सभी' : 'All'))
                  : plat;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    '$platLabel (${AppTranslations.formatDigits(count, lang)})',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: const Color(0xFF0284C7),
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onSelected: (val) {
                    setState(() => _selectedPlatform = plat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 6) Feed Card View
  Widget _buildPostFeedCard(SocialPostModel post, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SocialPostDetailScreen(
                post: post,
                onPostUpdated: _loadData,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Top Banner (Platform Badge + Date)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: post.platformColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(post.platformIcon, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              post.platform,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.formatDigits(post.date, lang),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      lang == 'mr'
                          ? 'सहभाग: ${AppTranslations.formatDigits(post.engagementRate.toStringAsFixed(1), lang)}%'
                          : (lang == 'hi'
                              ? 'सहभागिता: ${AppTranslations.formatDigits(post.engagementRate.toStringAsFixed(1), lang)}%'
                              : 'Eng: ${post.engagementRate.toStringAsFixed(1)}%'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Post Image (if present)
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
              ),

            // Content text
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTranslatedText(
                    post.contentFor(lang),
                    targetLanguage: lang,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tags
                  if (post.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: post.tags.take(3).map((tag) {
                        return AppTranslatedText(
                          tag,
                          targetLanguage: lang,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            // Bottom Metrics Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildMetricChip(Icons.thumb_up_alt_outlined, AppTranslations.formatDigits(post.likes.toLocaleString(), lang), const Color(0xFFE11D48)),
                      const SizedBox(width: 14),
                      _buildMetricChip(Icons.chat_bubble_outline_rounded, AppTranslations.formatDigits(post.comments.toString(), lang), const Color(0xFF9333EA)),
                      const SizedBox(width: 14),
                      _buildMetricChip(Icons.share_outlined, AppTranslations.formatDigits(post.shares.toString(), lang), const Color(0xFF16A34A)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.formatDigits(post.reach.toLocaleString(), lang),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // 7) Report Table View
  Widget _buildPostsTableView(List<SocialPostModel> posts, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
          horizontalMargin: 12,
          columnSpacing: 16,
          headingTextStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          dataTextStyle: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
          columns: [
            DataColumn(label: Text(lang == 'mr' ? 'प्लॅटफॉर्म' : (lang == 'hi' ? 'प्लेटफ़ॉर्म' : 'Platform'))),
            DataColumn(label: Text(lang == 'mr' ? 'तारीख' : (lang == 'hi' ? 'दिनांक' : 'Date'))),
            DataColumn(label: Text(lang == 'mr' ? 'पोस्ट सारांश' : (lang == 'hi' ? 'पोस्ट सारांश' : 'Post Summary'))),
            DataColumn(label: Text(lang == 'mr' ? 'पोहोच' : (lang == 'hi' ? 'पहुंच' : 'Reach')), numeric: true),
            DataColumn(label: Text(lang == 'mr' ? 'पसंती' : (lang == 'hi' ? 'पसंद' : 'Likes')), numeric: true),
            DataColumn(label: Text(lang == 'mr' ? 'टिप्पण्या' : (lang == 'hi' ? 'टिप्पणियाँ' : 'Comments')), numeric: true),
            DataColumn(label: Text(lang == 'mr' ? 'शेअर्स' : (lang == 'hi' ? 'शेयर' : 'Shares')), numeric: true),
            DataColumn(label: Text(lang == 'mr' ? 'सहभाग %' : (lang == 'hi' ? 'सहभागिता %' : 'Eng. %')), numeric: true),
            DataColumn(label: Text(lang == 'mr' ? 'कृती' : (lang == 'hi' ? 'कार्रवाई' : 'Action'))),
          ],
          rows: posts.map((post) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: post.platformColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: post.platformColor, width: 0.5),
                    ),
                    child: Text(
                      post.platform,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: post.platformColor,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(AppTranslations.formatDigits(post.date, lang))),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: AppTranslatedText(
                      post.contentFor(lang),
                      targetLanguage: lang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(AppTranslations.formatDigits(post.reach.toLocaleString(), lang))),
                DataCell(Text(AppTranslations.formatDigits(post.likes.toLocaleString(), lang))),
                DataCell(Text(AppTranslations.formatDigits(post.comments.toString(), lang))),
                DataCell(Text(AppTranslations.formatDigits(post.shares.toString(), lang))),
                DataCell(
                  Text(
                    '${AppTranslations.formatDigits(post.engagementRate.toStringAsFixed(1), lang)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
                    tooltip: AppTranslations.getDetails(lang),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SocialPostDetailScreen(
                            post: post,
                            onPostUpdated: _loadData,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            lang == 'mr'
                ? 'फिल्टरशी जुळणारी कोणतीही पोस्ट आढळली नाही'
                : (lang == 'hi'
                    ? 'फ़िल्टर से मेल खाने वाली कोई पोस्ट नहीं मिली'
                    : 'No posts found matching filter'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            lang == 'mr'
                ? 'कृपया शोध क्वेरी हटवा किंवा वेगळा प्लॅटफॉर्म निवडा.'
                : (lang == 'hi'
                    ? 'कृपया अपनी खोज क्वेरी साफ़ करें या कोई भिन्न प्लेटफ़ॉर्म चुनें।'
                    : 'Try clearing your search query or selecting a different platform.'),
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _TutorialStep extends StatelessWidget {
  final String step;
  final String title;
  final String desc;

  const _TutorialStep({
    required this.step,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFF0284C7),
            child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

