import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/ai_content_model.dart';
import '../../../data/repositories/ai_content_repository.dart';
import '../../navigation/app_drawer.dart';
import 'ai_content_detail_screen.dart';
import 'ai_content_report_generator.dart';

class AiContentStudioScreen extends ConsumerStatefulWidget {
  const AiContentStudioScreen({super.key});

  @override
  ConsumerState<AiContentStudioScreen> createState() =>
      _AiContentStudioScreenState();
}

class _AiContentStudioScreenState extends ConsumerState<AiContentStudioScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _topicCtrl = TextEditingController();
  final TextEditingController _historySearchCtrl = TextEditingController();

  AiContentType _selectedType = AiContentType.speech;
  AiToneType _selectedTone = AiToneType.enthusiastic;
  AiLanguageType _selectedLanguage = AiLanguageType.marathi;

  bool _isGenerating = false;
  bool _isLoading = true;
  AiContentHistoryItem? _lastGeneratedItem;
  bool _copied = false;

  List<AiContentHistoryItem> _allHistory = [];
  List<AiPromptTemplate> _templates = [];
  String _historyFilter = 'all'; // 'all' or contentType.id

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _historySearchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(aiContentRepoProvider);
    final history = await repo.getHistory();
    final templates = repo.getTemplates();

    if (mounted) {
      setState(() {
        _allHistory = history;
        _templates = templates;
        _isLoading = false;
      });
    }
  }

  void _applyTemplate(AiPromptTemplate tmpl) {
    setState(() {
      _topicCtrl.text = tmpl.prompt;
      _selectedType = tmpl.defaultType;
      _selectedTone = tmpl.defaultTone;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'${tmpl.titleMr}\' template applied'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a topic or context first'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isGenerating = true;
      _copied = false;
    });

    try {
      final repo = ref.read(aiContentRepoProvider);
      final result = await repo.generateContent(
        topic: topic,
        type: _selectedType,
        tone: _selectedTone,
        language: _selectedLanguage,
      );

      final updatedHistory = await repo.getHistory();

      if (mounted) {
        setState(() {
          _lastGeneratedItem = result;
          _allHistory = updatedHistory;
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content generated successfully!'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _handleCopy() {
    if (_lastGeneratedItem == null) return;
    Clipboard.setData(ClipboardData(text: _lastGeneratedItem!.generatedContent));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content copied to clipboard!'),
        backgroundColor: Color(0xFF059669),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _handleShare(AiContentHistoryItem item) async {
    final text = '${item.title}\n\n${item.generatedContent}\n\n— Nagarsevak Amit Chougale (Ward 12)';
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content copied to clipboard!')),
          );
        }
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content copied to clipboard!')),
        );
      }
    }
  }

  void _loadFromHistory(AiContentHistoryItem item) {
    setState(() {
      _topicCtrl.text = item.title;
      _selectedType = item.contentType;
      _selectedTone = item.tone;
      _selectedLanguage = item.language;
      _lastGeneratedItem = item;
      _tabController.animateTo(0);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'${item.title}\' loaded in editor'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: const Text('This draft will be permanently removed from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(aiContentRepoProvider);
      await repo.deleteHistoryItem(id);
      final updated = await repo.getHistory();
      if (mounted) {
        setState(() {
          _allHistory = updated;
          if (_lastGeneratedItem?.id == id) {
            _lastGeneratedItem = null;
          }
        });
      }
    }
  }

  Future<void> _exportDossierPdf() async {
    await AiContentReportGenerator.generateDossier(
      items: _filteredHistory,
      categoryFilter: _historyFilter,
    );
  }

  List<AiContentHistoryItem> get _filteredHistory {
    final query = _historySearchCtrl.text.trim().toLowerCase();
    return _allHistory.where((item) {
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.generatedContent.toLowerCase().contains(query);

      final matchesType = _historyFilter == 'all' ||
          item.contentType.id.toLowerCase() == _historyFilter.toLowerCase();

      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const NagarsevakAppDrawer(),
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
                'AI Content Studio',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Generate press releases, festival greetings and speeches',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              tooltip: 'Download Official PDF Report',
              onPressed: _exportDossierPdf,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: _loadData,
            ),
          ],
          ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0284C7)),
              )
            : Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        dividerColor: Colors.transparent,
                        tabs: [
                          const Tab(
                            icon: Icon(Icons.edit_note_rounded, size: 18),
                            text: 'Create Content (Studio)',
                          ),
                          Tab(
                            icon: const Icon(Icons.history_rounded, size: 18),
                            text: 'History & Drafts (${_allHistory.length})',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStudioTab(),
                        _buildHistoryTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ==========================================
  // TAB 1: STUDIO (INPUT + GENERATED PREVIEW)
  // ==========================================
  Widget _buildStudioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Row
          _buildQuickStatsStrip(),

          const SizedBox(height: 16),

          // Quick Prompt Templates Carousel
          _buildTemplatesCarousel(),

          const SizedBox(height: 16),

          // Generator Form Card
          _buildGeneratorFormCard(),

          // If content is generated, show Result Card
          if (_lastGeneratedItem != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_lastGeneratedItem!),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickStatsStrip() {
    final speeches = _allHistory.where((i) => i.contentType == AiContentType.speech).length;
    final posts = _allHistory.where((i) => i.contentType == AiContentType.socialMediaCaption).length;
    final notices = _allHistory.where((i) => i.contentType == AiContentType.letterNotice).length;
    final press = _allHistory.where((i) => i.contentType == AiContentType.pressRelease).length;

    return Row(
      children: [
        _buildStatPill('Speeches', '$speeches', const Color(0xFF8B5CF6), Icons.record_voice_over_rounded),
        const SizedBox(width: 8),
        _buildStatPill('Social Posts', '$posts', const Color(0xFF0284C7), Icons.tag_rounded),
        const SizedBox(width: 8),
        _buildStatPill('Notices/Letters', '$notices', const Color(0xFFD97706), Icons.description_rounded),
        const SizedBox(width: 8),
        _buildStatPill('Press Releases', '$press', const Color(0xFF059669), Icons.newspaper_rounded),
      ],
    );
  }

  Widget _buildStatPill(String label, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            const Text(
              'Quick Political Drafting Templates (Prompts)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              final tmpl = _templates[idx];
              return InkWell(
                onTap: () => _applyTemplate(tmpl),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 175,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(tmpl.icon, size: 14, color: const Color(0xFF0284C7)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              tmpl.titleMr,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tmpl.subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratorFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Enter Draft Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Topic / Context TextArea
          const Text(
            'Topic / Context',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _topicCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g., Inauguration of new community center in Ward 12 on Sunday...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
              ),
              suffixIcon: _topicCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        setState(() => _topicCtrl.clear());
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // Content Type & Tone Grid
          Row(
            children: [
              // Content Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Content Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AiContentType>(
                          value: _selectedType,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          items: AiContentType.values.map((type) {
                            return DropdownMenuItem<AiContentType>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(type.icon, size: 15, color: type.color),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      type.titleMr,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedType = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tone / Sentiment',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AiToneType>(
                          value: _selectedTone,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          items: AiToneType.values.map((tone) {
                            return DropdownMenuItem<AiToneType>(
                              value: tone,
                              child: Row(
                                children: [
                                  Icon(tone.icon, size: 15, color: const Color(0xFF475569)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      tone.titleMr,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedTone = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Language Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Language',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: AiLanguageType.values.map((lang) {
                  final isSelected = _selectedLanguage == lang;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _selectedLanguage = lang),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            lang.id == 'Marathi'
                                ? 'Marathi'
                                : (lang.id == 'Hindi' ? 'Hindi' : 'English'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _handleGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isGenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Generating Content...',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.auto_awesome_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Generate Content',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(AiContentHistoryItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Type badge and Action buttons
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.contentType.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.contentType.icon, size: 12, color: item.contentType.color),
                    const SizedBox(width: 4),
                    Text(
                      item.contentType.titleMr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.contentType.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.tone.titleMr,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                ),
              ),
              const Spacer(),
              // Copy Button
              InkWell(
                onTap: _handleCopy,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _copied ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _copied ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 13,
                        color: _copied ? const Color(0xFF15803D) : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied!' : 'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _copied ? const Color(0xFF15803D) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Share Button
              InkWell(
                onTap: () => _handleShare(item),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.share_rounded, size: 14, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 8),

          // Metadata row (word count, reading time)
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                '${item.wordCount} words',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Reading Time: ${item.readingTimeFormatted}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Content Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SelectableText(
              item.generatedContent,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Bottom Quick Bar: View Full Screen & Print PDF
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiContentDetailScreen(
                          item: item,
                          onReloadIntoEditor: () => _loadFromHistory(item),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fullscreen_rounded, size: 16),
                  label: const Text('View Full Screen', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => AiContentReportGenerator.printDocument(item),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Print Letterhead', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: HISTORY & ARCHIVE
  // ==========================================
  Widget _buildHistoryTab() {
    final filtered = _filteredHistory;

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _historySearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search drafts or topics...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: _historySearchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() => _historySearchCtrl.clear());
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),

              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All (${_allHistory.length})', 'all'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Speeches', 'Speech'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Social Captions', 'Social Media Caption'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Letters & Notices', 'Letter/Notice'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Press Releases', 'Press Release'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Work Reports', 'Work Report'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // History Items List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        _historySearchCtrl.text.isNotEmpty
                            ? 'No drafts found matching search'
                            : 'No draft history found',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final item = filtered[idx];
                    return _buildHistoryCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _historyFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFF334155),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      onSelected: (_) {
        setState(() => _historyFilter = value);
      },
    );
  }

  Widget _buildHistoryCard(AiContentHistoryItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AiContentDetailScreen(
              item: item,
              onReloadIntoEditor: () => _loadFromHistory(item),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Type badge, Tone, relative time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.contentType.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.contentType.icon, size: 11, color: item.contentType.color),
                      const SizedBox(width: 4),
                      Text(
                        item.contentType.titleMr,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: item.contentType.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• ${item.tone.titleMr}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                Text(
                  item.relativeTime,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Subject / Title
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Excerpt
            Text(
              item.generatedContent.replaceAll('\n', ' '),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            // Card Action Bar
            Row(
              children: [
                Text(
                  '${item.wordCount} words • ${item.language.id}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const Spacer(),
                // Quick Load to Editor
                InkWell(
                  onTap: () => _loadFromHistory(item),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Text(
                          'Use',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Quick Share
                InkWell(
                  onTap: () => _handleShare(item),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.share_rounded, size: 15, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 6),
                // Quick Delete
                InkWell(
                  onTap: () => _handleDelete(item.id),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

