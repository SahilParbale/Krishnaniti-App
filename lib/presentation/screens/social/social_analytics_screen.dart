import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/social_post_model.dart';
import '../../../data/repositories/social_analytics_repository.dart';
import '../../navigation/app_drawer.dart';
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
    final mobileClean = voter.mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = Uri.encodeComponent(
      '🎂 Wishing you a very Happy Birthday ${voter.displayName}! Wishing you good health, long life, and happiness. - Your Nagarsevak, Ward 12, Pune.',
    );
    final uri = Uri.parse('https://wa.me/$mobileClean?text=$msg');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening WhatsApp for ${voter.name}...')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening WhatsApp for ${voter.name}...')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calling $phoneNumber...')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling $phoneNumber...')),
        );
      }
    }
  }

  void _showHelpTutorialDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Social Analytics Guide',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Social Media Analytics & Constituent Engagement Guide',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7)),
                ),
                SizedBox(height: 10),
                _TutorialStep(
                  step: '1',
                  title: 'Performance Overview',
                  desc: 'Track total impressions, likes, citizen comments, and shares across Facebook, Instagram, and Twitter.',
                ),
                _TutorialStep(
                  step: '2',
                  title: 'Connect Accounts',
                  desc: 'Keep official Facebook page and Instagram accounts synchronized for live performance tracking.',
                ),
                _TutorialStep(
                  step: '3',
                  title: 'Constituent Birthdays',
                  desc: 'Build personal relations by sending customized Marathi greetings via WhatsApp to voters on their birthdays.',
                ),
                _TutorialStep(
                  step: '4',
                  title: 'PDF Audit Reports',
                  desc: 'Export landscape A4 audit report with engagement metrics for corporator review meetings.',
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
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPostModal() {
    final contentEnCtrl = TextEditingController();
    final contentMrCtrl = TextEditingController();
    final tagsCtrl = TextEditingController(text: '#Development #Ward12 #Pune');
    final imageCtrl = TextEditingController();
    final postUrlCtrl = TextEditingController();
    final reachCtrl = TextEditingController(text: '5000');
    final likesCtrl = TextEditingController(text: '450');
    final commentsCtrl = TextEditingController(text: '28');
    final sharesCtrl = TextEditingController(text: '15');
    String platform = 'Facebook';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Modal Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Track New Post',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Modal Form Fields
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Platform Select
                        const Text('Platform', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          children: ['Facebook', 'Instagram', 'Twitter'].map((p) {
                            final isSel = platform == p;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => platform = p),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    p,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : const Color(0xFF334155),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Post Content Marathi
                        const Text('Post Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: contentMrCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Inspected development works in Ward 12...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Post Content English
                        const Text('Post Content (English Description)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: contentEnCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Inspected civic development works in Prabhag 12...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Hashtags & Link
                        TextField(
                          controller: tagsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Hashtags (space separated)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: postUrlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Live Post URL (Optional)',
                            hintText: 'https://facebook.com/... or https://instagram.com/...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: imageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Image URL (Optional)',
                            hintText: 'https://images.unsplash.com/...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Initial Metrics
                        const Text('Initial Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: reachCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Reach',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: likesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Likes',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: commentsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Comments',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: sharesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Shares',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text(
                            'Save & Track Post',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () async {
                            final mrText = contentMrCtrl.text.trim();
                            final enText = contentEnCtrl.text.trim();
                            if (mrText.isEmpty && enText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter post content.')),
                              );
                              return;
                            }

                            final newPost = SocialPostModel(
                              id: 'soc_${DateTime.now().millisecondsSinceEpoch}',
                              platform: platform,
                              content: enText.isNotEmpty ? enText : mrText,
                              contentMarathi: mrText.isNotEmpty ? mrText : enText,
                              likes: int.tryParse(likesCtrl.text) ?? 0,
                              comments: int.tryParse(commentsCtrl.text) ?? 0,
                              shares: int.tryParse(sharesCtrl.text) ?? 0,
                              reach: int.tryParse(reachCtrl.text) ?? 1000,
                              date: DateTime.now().toString().substring(0, 10),
                              imageUrl: imageCtrl.text.trim().isNotEmpty
                                  ? imageCtrl.text.trim()
                                  : 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80&w=800',
                              postUrl: postUrlCtrl.text.trim().isNotEmpty ? postUrlCtrl.text.trim() : null,
                              tags: tagsCtrl.text.split(' ').where((s) => s.isNotEmpty).toList(),
                            );

                            final repo = ref.read(socialAnalyticsRepoProvider);
                            await repo.addPost(newPost);
                            if (modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                            }
                            _loadData();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('New post added to analytics tracker!'),
                                  backgroundColor: Color(0xFF0284C7),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              tooltip: 'Open Menu Drawer',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Social Analytics',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Social reach & engagement',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
                    _buildConnectChannelsBar(),
                    const SizedBox(height: 14),

                    // 2) 4 EXECUTIVE SUMMARY KPI CARDS
                    _buildKpiCardsRow(
                      reach: totalReach > 0 ? totalReach : 45200,
                      likes: totalLikes,
                      comments: totalComments,
                      shares: totalShares,
                    ),
                    const SizedBox(height: 14),

                    // 3) GROWTH & ENGAGEMENT HIGHLIGHT BANNER
                    _buildGrowthBanner(),
                    const SizedBox(height: 14),

                    // 4) CONSTITUENCY ENGAGEMENT: TODAY'S BIRTHDAYS
                    _buildBirthdaysSection(),
                    const SizedBox(height: 16),

                    // 5) FILTER & SEARCH STRIP
                    _buildFilterSection(),
                    const SizedBox(height: 12),

                    // 6) POSTS COUNT & SORT BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${filtered.length} of ${_allPosts.length} posts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          children: [
                            const Text('Sort: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            DropdownButton<String>(
                              value: _sortBy,
                              isDense: true,
                              underline: const SizedBox(),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              items: const [
                                DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                                DropdownMenuItem(value: 'likes', child: Text('Most Liked')),
                                DropdownMenuItem(value: 'reach', child: Text('Highest Reach')),
                                DropdownMenuItem(value: 'engagement', child: Text('Highest Engagement')),
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
                              tooltip: _viewMode == 'feed' ? 'Switch to Table' : 'Switch to Feed',
                              onPressed: () => setState(() => _viewMode = _viewMode == 'feed' ? 'table' : 'feed'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF0284C7), size: 20),
                              tooltip: 'Download PDF Report',
                              onPressed: () {
                                if (_summary != null) {
                                  SocialAnalyticsReportGenerator.generateAndPrintReport(
                                    posts: filtered,
                                    summary: _summary!,
                                    birthdays: _birthdays,
                                    platformFilter: _selectedPlatform,
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 20),
                              tooltip: 'Help Guide',
                              onPressed: _showHelpTutorialDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 7) DUAL VIEW CONTENT (FEED CARDS vs REPORT TABLE)
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else if (_viewMode == 'feed')
                      ...filtered.map((post) => _buildPostFeedCard(post))
                    else
                      _buildPostsTableView(filtered),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Track Post', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _showAddPostModal,
        ),
      ),
    );
  }

  // 1) Connect Channels Bar
  Widget _buildConnectChannelsBar() {
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
                children: const [
                  Icon(Icons.share_rounded, size: 16, color: Color(0xFF0284C7)),
                  SizedBox(width: 6),
                  Text(
                    'Connected Channels',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                  children: const [
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'Live Synced',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
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
                  label: const Text('Connect FB', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Official Facebook Page: "Nagarsevak Prabhag 12" is active.')),
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
                    label: const Text('Connect IG', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Official Instagram Profile: "@nagarsevak_prabhag12" connected.')),
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
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Reach',
                marathi: 'Total Reach',
                value: reach.toLocaleString(),
                icon: Icons.remove_red_eye_outlined,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                subtitle: '+12% vs last month',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Likes',
                marathi: 'Likes',
                value: likes.toLocaleString(),
                icon: Icons.thumb_up_alt_outlined,
                color: const Color(0xFFE11D48),
                bgColor: const Color(0xFFFFF1F2),
                subtitle: 'Constituent loves',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Comments',
                marathi: 'Comments',
                value: comments.toLocaleString(),
                icon: Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF9333EA),
                bgColor: const Color(0xFFFAF5FF),
                subtitle: 'Direct feedback',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Shares',
                marathi: 'Shares',
                value: shares.toLocaleString(),
                icon: Icons.share_outlined,
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFF0FDF4),
                subtitle: 'Word of mouth',
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                marathi,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3) Growth Banner
  Widget _buildGrowthBanner() {
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
                  children: const [
                    Text(
                      'Monthly Reach Growth',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '+12%',
                      style: TextStyle(color: Color(0xFF86EFAC), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Consistent updates on civic works in Ward 12 have boosted constituent engagement.',
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
  Widget _buildBirthdaysSection() {
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
                  const Text(
                    "Today's Birthdays",
                    style: TextStyle(
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
                  'Send Wishes (${_birthdays.length})',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_birthdays.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No constituent birthdays registered for today.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                          Text(
                            voter.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${voter.displayName} • Age: ${voter.age}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                          Text(
                            '${voter.area} • ${voter.boothNumber}',
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
                          tooltip: 'Call Voter',
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
                              children: const [
                                Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Wish',
                                  style: TextStyle(
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
  Widget _buildFilterSection() {
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
              hintText: 'Search posts by topic, Marathi text, #tags...',
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

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    '$plat ($count)',
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
  Widget _buildPostFeedCard(SocialPostModel post) {
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
                        post.date,
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
                      'Eng: ${post.engagementRate.toStringAsFixed(1)}%',
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
                  Text(
                    post.contentMarathi,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tags
                  if (post.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: post.tags.take(3).map((tag) {
                        return Text(
                          tag,
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
                      _buildMetricChip(Icons.thumb_up_alt_outlined, post.likes.toLocaleString(), const Color(0xFFE11D48)),
                      const SizedBox(width: 14),
                      _buildMetricChip(Icons.chat_bubble_outline_rounded, post.comments.toString(), const Color(0xFF9333EA)),
                      const SizedBox(width: 14),
                      _buildMetricChip(Icons.share_outlined, post.shares.toString(), const Color(0xFF16A34A)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        post.reach.toLocaleString(),
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
  Widget _buildPostsTableView(List<SocialPostModel> posts) {
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
          columns: const [
            DataColumn(label: Text('Platform')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Post Summary')),
            DataColumn(label: Text('Reach'), numeric: true),
            DataColumn(label: Text('Likes'), numeric: true),
            DataColumn(label: Text('Comments'), numeric: true),
            DataColumn(label: Text('Shares'), numeric: true),
            DataColumn(label: Text('Eng. %'), numeric: true),
            DataColumn(label: Text('Action')),
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
                DataCell(Text(post.date)),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      post.contentMarathi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(post.reach.toLocaleString())),
                DataCell(Text(post.likes.toLocaleString())),
                DataCell(Text(post.comments.toString())),
                DataCell(Text(post.shares.toString())),
                DataCell(
                  Text(
                    '${post.engagementRate.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0284C7)),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No posts found matching filter',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
          ),
          SizedBox(height: 4),
          Text(
            'Try clearing your search query or selecting a different platform.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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

