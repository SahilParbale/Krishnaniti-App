import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/social_post_model.dart';
import '../../../../data/repositories/social_analytics_repository.dart';
import '../../../screens/social/social_analytics_report_generator.dart';

class DesktopSocialAnalyticsView extends ConsumerStatefulWidget {
  const DesktopSocialAnalyticsView({super.key});

  @override
  ConsumerState<DesktopSocialAnalyticsView> createState() => _DesktopSocialAnalyticsViewState();
}

class _DesktopSocialAnalyticsViewState extends ConsumerState<DesktopSocialAnalyticsView> {
  bool _loading = true;
  List<SocialPostModel> _posts = [];
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

  void _sendBirthdayWish(String mobile, String name) async {
    final message = Uri.encodeComponent(
      '🎂 Happy Birthday, $name! Wishing you joy, health, and success in life. - Nagar Sevak Office • Ward 12',
    );
    final uri = Uri.parse('https://wa.me/91$mobile?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPosts;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // 4 Stat Overview Cards
          _buildStatCards(),
          const SizedBox(height: 24),

          // Birthday Wishes Banner Card
          _buildBirthdayBanner(),
          const SizedBox(height: 24),

          // Filters Row
          _buildFilterRow(),
          const SizedBox(height: 24),

          // Posts Feed Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildPostGrid(filtered),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Social Analytics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            SizedBox(height: 4),
            Text(
              'Track Facebook and Instagram social performance, engagement and citizen reach',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Connect Buttons
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.facebook, size: 18, color: Colors.white),
              label: const Text('Facebook Connect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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
              label: const Text('Instagram Connect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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

  Widget _buildStatCards() {
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
              title: 'Total Reach',
              value: '45.2K',
              subtitle: '+12% vs last month',
              icon: Icons.remove_red_eye_outlined,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFF0F9FF),
            ),
            _statCard(
              title: 'Engagement',
              value: '8.4%',
              subtitle: 'High citizen interaction',
              icon: Icons.trending_up,
              iconColor: const Color(0xFF16A34A),
              iconBgColor: const Color(0xFFF0FDF4),
            ),
            _statCard(
              title: 'Followers',
              value: '+1,250',
              subtitle: 'Growing this month',
              icon: Icons.group_outlined,
              iconColor: const Color(0xFF7E22CE),
              iconBgColor: const Color(0xFFFAF5FF),
            ),
            _statCard(
              title: 'Total Likes & Shares',
              value: '$_totalLikes',
              subtitle: '$_totalShares shares • $_totalComments comments',
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
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildBirthdayBanner() {
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
            children: const [
              Icon(Icons.cake_outlined, size: 20, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text(
                'Today\'s Voter Birthdays',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
              Spacer(),
              const Text('Send direct birthday wishes to ward voters via WhatsApp', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
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
                    Text(v['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _sendBirthdayWish(v['mobile']!, v['name']!),
                      icon: const Icon(Icons.chat_bubble_outline, size: 12, color: Colors.white),
                      label: const Text('Send Wishes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildFilterRow() {
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
              onChanged: (val) => setState(() => _searchTerm = val),
              decoration: const InputDecoration(
                hintText: 'Search social media post content...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Platform Filter Tabs (Col 4)
        Row(
          children: ['All', 'Facebook', 'Instagram'].map((platform) {
            final isSelected = _platformFilter == platform;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _platformFilter = platform),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    platform == 'All' ? 'All Platforms' : platform,
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

  Widget _buildPostGrid(List<SocialPostModel> items) {
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
          children: const [
            Icon(Icons.feed_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            const Text('No posts found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;

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
                                Text(
                                  item.platform,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isFb ? const Color(0xFF1877F2) : const Color(0xFFE1306C)),
                                ),
                              ],
                            ),
                          ),
                          Text(item.date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
                        child: Text(
                          item.contentMarathi,
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
                              Text('${item.likes}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text('${item.comments}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.share_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text('${item.shares}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
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
        final crossAxisCount = constraints.maxWidth > 1050 ? 3 : 2;
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
