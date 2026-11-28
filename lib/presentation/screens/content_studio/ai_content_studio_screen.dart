import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/ai_content_model.dart';
import '../../../data/repositories/ai_content_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_load_more_footer.dart';
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
  int _historyLimit = 10;

  List<AiContentHistoryItem> get _visibleHistory {
    return _filteredHistory.take(_historyLimit).toList();
  }

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
        _historyLimit = 10;
      });
    }
  }

  void _applyTemplate(AiPromptTemplate tmpl) {
    final lang = ref.read(appLanguageProvider);
    setState(() {
      _topicCtrl.text = tmpl.prompt;
      _selectedType = tmpl.defaultType;
      _selectedTone = tmpl.defaultTone;
    });
    final tmplTitle = lang == 'mr'
        ? tmpl.titleMr
        : (DynamicTranslationService.getCachedTranslation(tmpl.title, lang) ??
            tmpl.title);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: '\'$tmplTitle\' template applied',
            mr: '\'$tmplTitle\' नमुना लागू केला',
            hi: '\'$tmplTitle\' टेम्पलेट लागू किया गया',
          ),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    final lang = ref.read(appLanguageProvider);
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please enter a topic or context first',
              mr: 'कृपया प्रथम विषय किंवा संदर्भ प्रविष्ट करा',
              hi: 'कृपया पहले विषय या संदर्भ दर्ज करें',
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
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
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Content generated successfully!',
                mr: 'मजकूर यशस्वीरित्या तयार झाला!',
                hi: 'सामग्री सफलतापूर्वक तैयार हुई!',
              ),
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppTranslations.pick(lang, en: "Error", mr: "त्रुटी", hi: "त्रुटि")}: ${e.toString()}',
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _handleCopy() {
    if (_lastGeneratedItem == null) return;
    final lang = ref.read(appLanguageProvider);
    final content = DynamicTranslationService.getCachedTranslation(
          _lastGeneratedItem!.generatedContent,
          lang,
        ) ??
        _lastGeneratedItem!.generatedContent;
    Clipboard.setData(ClipboardData(text: content));
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

  Future<void> _handleShare(AiContentHistoryItem item) async {
    final lang = ref.read(appLanguageProvider);
    final title =
        DynamicTranslationService.getCachedTranslation(item.title, lang) ??
            item.title;
    final content = DynamicTranslationService.getCachedTranslation(
          item.generatedContent,
          lang,
        ) ??
        item.generatedContent;
    final footer = AppTranslations.pick(
      lang,
      en: '— Nagarsevak Amit Chougale (Ward 12)',
      mr: '— नगरसेवक अमित चौगुले (प्रभाग १२)',
      hi: '— नगरसेवक अमित चौगुले (वार्ड १२)',
    );
    final copiedMsg = AppTranslations.pick(
      lang,
      en: 'Content copied to clipboard!',
      mr: 'मजकूर क्लिपबोर्डवर कॉपी केला!',
      hi: 'सामग्री क्लिपबोर्ड पर कॉपी की गई!',
    );
    final text = '$title\n\n$content\n\n$footer';
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
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

  void _loadFromHistory(AiContentHistoryItem item) {
    final lang = ref.read(appLanguageProvider);
    setState(() {
      _topicCtrl.text = item.title;
      _selectedType = item.contentType;
      _selectedTone = item.tone;
      _selectedLanguage = item.language;
      _lastGeneratedItem = item;
      _tabController.animateTo(0);
    });
    final title =
        DynamicTranslationService.getCachedTranslation(item.title, lang) ??
            item.title;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: '\'$title\' loaded in editor',
            mr: '\'$title\' संपादकात लोड केले',
            hi: '\'$title\' संपादक में लोड किया गया',
          ),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  Future<void> _handleDelete(String id) async {
    final lang = ref.read(appLanguageProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppTranslations.pick(
            lang,
            en: 'Delete Draft?',
            mr: 'मसुदा हटवायचा का?',
            hi: 'ड्राफ्ट हटाएं?',
          ),
        ),
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'This draft will be permanently removed from your history.',
            mr: 'हा मसुदा तुमच्या इतिहासातून कायमचा हटवला जाईल.',
            hi: 'यह ड्राफ्ट आपके इतिहास से स्थायी रूप से हटा दिया जाएगा।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: Text(
              AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
              style: const TextStyle(color: Colors.white),
            ),
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
    final lang = ref.read(appLanguageProvider);
    await AiContentReportGenerator.generateDossier(
      items: _filteredHistory,
      categoryFilter: _historyFilter,
      lang: lang,
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
    final lang = ref.watch(appLanguageProvider);

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
                AppTranslations.getNavTitle('ai_content', lang),
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
                    ? 'भाषणे, प्रसिद्धी पत्रके आणि शुभेच्छा'
                    : (lang == 'hi'
                        ? 'भाषण, प्रेस विज्ञप्ति और शुभकामनाएं'
                        : 'AI releases, greetings & speeches'),
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
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0284C7)),
              )
            : Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
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
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.edit_note_rounded, size: 16),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          lang == 'mr' ? 'कंटेंट तयार करा' : (lang == 'hi' ? 'कंटेंट बनाएं' : 'Create Content'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.history_rounded, size: 16),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${AppTranslations.pick(lang, en: "History", mr: "इतिहास", hi: "इतिहास")} (${AppTranslations.formatDigits(_allHistory.length, lang)})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppPdfButton.icon(
                          tooltip: AppTranslations.getDownloadReport(lang),
                          onPressed: _exportDossierPdf,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStudioTab(lang),
                        _buildHistoryTab(lang),
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
  Widget _buildStudioTab(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Prompt Templates Carousel
          _buildTemplatesCarousel(lang),

          const SizedBox(height: 16),

          // Generator Form Card
          _buildGeneratorFormCard(lang),

          // If content is generated, show Result Card
          if (_lastGeneratedItem != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_lastGeneratedItem!, lang),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTemplatesCarousel(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Quick Political Drafting Templates (Prompts)',
                  mr: 'त्वरित राजकीय मसुदा नमुने (Prompts)',
                  hi: 'त्वरित राजनीतिक ड्राफ्टिंग टेम्पलेट्स (Prompts)',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
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
                            child: AppTranslatedText(
                              lang == 'mr' ? tmpl.titleMr : tmpl.title,
                              targetLanguage: lang,
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
                      AppTranslatedText(
                        tmpl.subtitle,
                        targetLanguage: lang,
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

  Widget _buildGeneratorFormCard(String lang) {
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
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Enter Draft Details',
                  mr: 'मसुद्याचा तपशील प्रविष्ट करा',
                  hi: 'ड्राफ्ट का विवरण दर्ज करें',
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Topic / Context TextArea
          Text(
            AppTranslations.pick(
              lang,
              en: 'Topic / Context',
              mr: 'विषय / संदर्भ',
              hi: 'विषय / संदर्भ',
            ),
            style: const TextStyle(
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
              hintText: AppTranslations.pick(
                lang,
                en: 'e.g., Inauguration of new community center in Ward 12 on Sunday...',
                mr: 'उदा. रविवारी प्रभाग १२ मध्ये नवीन सभागृहाचे उद्घाटन...',
                hi: 'उदा. रविवार को वार्ड १२ में नए सामुदायिक केंद्र का उद्घाटन...',
              ),
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
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Content Type',
                        mr: 'सामग्री प्रकार',
                        hi: 'सामग्री प्रकार',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppDropdown<AiContentType>(
                      title: AppTranslations.pick(
                        lang,
                        en: 'Content Type',
                        mr: 'सामग्री प्रकार निवडा',
                        hi: 'सामग्री प्रकार चुनें',
                      ),
                      value: _selectedType,
                      items: AiContentType.values.map((type) {
                        return DropdownMenuItem<AiContentType>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon, size: 15, color: type.color),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  type.title(lang),
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Tone / Sentiment',
                        mr: 'संभाषण सूर / भाव',
                        hi: 'संवाद शैली / भाव',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppDropdown<AiToneType>(
                      title: AppTranslations.pick(
                        lang,
                        en: 'Tone / Sentiment',
                        mr: 'संभाषण सूर निवडा',
                        hi: 'संवाद शैली चुनें',
                      ),
                      value: _selectedTone,
                      items: AiToneType.values.map((tone) {
                        return DropdownMenuItem<AiToneType>(
                          value: tone,
                          child: Row(
                            children: [
                              Icon(tone.icon, size: 15, color: const Color(0xFF475569)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  tone.title(lang),
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
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Language',
                  mr: 'भाषा',
                  hi: 'भाषा',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: AiLanguageType.values.map((aiLang) {
                  final isSelected = _selectedLanguage == aiLang;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _selectedLanguage = aiLang),
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
                            aiLang.labelFor(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Generating Content...',
                            mr: 'मजकूर तयार होत आहे...',
                            hi: 'सामग्री तैयार हो रही है...',
                          ),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Generate Content',
                            mr: 'मजकूर तयार करा',
                            hi: 'सामग्री तैयार करें',
                          ),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(AiContentHistoryItem item, String lang) {
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
                      item.contentType.title(lang),
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
                  item.tone.title(lang),
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
                        _copied
                            ? AppTranslations.pick(lang, en: 'Copied!', mr: 'कॉपी!', hi: 'कॉपी!')
                            : AppTranslations.pick(lang, en: 'Copy', mr: 'कॉपी', hi: 'कॉपी'),
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
              Tooltip(
                message: AppTranslations.pick(lang, en: 'Share', mr: 'शेअर करा', hi: 'साझा करें'),
                child: InkWell(
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
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title
          AppTranslatedText(
            item.title,
            targetLanguage: lang,
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
                AppTranslations.pick(
                  lang,
                  en: '${AppTranslations.formatDigits(item.wordCount, lang)} words',
                  mr: '${AppTranslations.formatDigits(item.wordCount, lang)} शब्द',
                  hi: '${AppTranslations.formatDigits(item.wordCount, lang)} शब्द',
                ),
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${AppTranslations.pick(lang, en: "Reading Time", mr: "वाचन वेळ", hi: "पढ़ने का समय")}: ${item.readingTimeFormattedFor(lang)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
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
            child: FutureBuilder<String>(
              key: ValueKey('studio_res_${item.id}_$lang'),
              future: DynamicTranslationService.translateOrRaw(
                item.generatedContent,
                lang,
              ),
              initialData: DynamicTranslationService.getCachedTranslation(
                    item.generatedContent,
                    lang,
                  ) ??
                  item.generatedContent,
              builder: (ctx, snap) {
                return SelectableText(
                  snap.data ?? item.generatedContent,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: Color(0xFF1E293B),
                  ),
                );
              },
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
                  label: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'View Full Screen',
                      mr: 'पूर्ण स्क्रीन पहा',
                      hi: 'पूर्ण स्क्रीन देखें',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
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
                  onPressed: () => AiContentReportGenerator.printDocument(item, lang: lang),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Print Letterhead',
                      mr: 'लेटरहेड प्रिंट',
                      hi: 'लेटरहेड प्रिंट',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
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
  Widget _buildHistoryTab(String lang) {
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
                  hintText: AppTranslations.pick(
                    lang,
                    en: 'Search drafts or topics...',
                    mr: 'मसुदे किंवा विषय शोधा...',
                    hi: 'ड्राफ्ट या विषय खोजें...',
                  ),
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: _historySearchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() {
                              _historySearchCtrl.clear();
                              _historyLimit = 10;
                            });
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
                onChanged: (val) => setState(() => _historyLimit = 10),
              ),

              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      '${AppTranslations.getAll(lang)} (${AppTranslations.formatDigits(_allHistory.length, lang)})',
                      'all',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(AiContentType.speech.title(lang), 'Speech'),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      AiContentType.socialMediaCaption.title(lang),
                      'Social Media Caption',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(AiContentType.letterNotice.title(lang), 'Letter/Notice'),
                    const SizedBox(width: 6),
                    _buildFilterChip(AiContentType.pressRelease.title(lang), 'Press Release'),
                    const SizedBox(width: 6),
                    _buildFilterChip(AiContentType.workReport.title(lang), 'Work Report'),
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
                            ? AppTranslations.pick(
                                lang,
                                en: 'No drafts found matching search',
                                mr: 'शोधाशी जुळणारे मसुदे आढळले नाहीत',
                                hi: 'खोज से मेल खाने वाला कोई ड्राफ्ट नहीं मिला',
                              )
                            : AppTranslations.pick(
                                lang,
                                en: 'No draft history found',
                                mr: 'कोणताही मसुदा इतिहास सापडला नाही',
                                hi: 'कोई ड्राफ्ट इतिहास नहीं मिला',
                              ),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visibleHistory.length + (filtered.isNotEmpty ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    if (idx == _visibleHistory.length) {
                      return AppLoadMoreFooter(
                        currentCount: _visibleHistory.length,
                        totalCount: filtered.length,
                        pageSize: 10,
                        label: AppTranslations.pick(
                          lang,
                          en: 'drafts',
                          mr: 'मसुदे',
                          hi: 'ड्राफ्ट',
                        ),
                        isMarathi: lang == 'mr',
                        onLoadMore: () {
                          setState(() {
                            _historyLimit += 10;
                          });
                        },
                      );
                    }
                    final item = _visibleHistory[idx];
                    return _buildHistoryCard(item, lang);
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
        setState(() {
          _historyFilter = value;
          _historyLimit = 10;
        });
      },
    );
  }

  Widget _buildHistoryCard(AiContentHistoryItem item, String lang) {
    final wordsLabel = AppTranslations.pick(lang, en: 'words', mr: 'शब्द', hi: 'शब्द');
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
                        item.contentType.title(lang),
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
                  '• ${item.tone.title(lang)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                Text(
                  item.relativeTimeFor(lang),
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Subject / Title
            AppTranslatedText(
              item.title,
              targetLanguage: lang,
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
            AppTranslatedText(
              item.generatedContent.replaceAll('\n', ' '),
              targetLanguage: lang,
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
                  '${AppTranslations.formatDigits(item.wordCount, lang)} $wordsLabel • ${item.language.labelFor(lang)}',
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
                      children: [
                        const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Use',
                            mr: 'वापरा',
                            hi: 'उपयोग करें',
                          ),
                          style: const TextStyle(
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
                Tooltip(
                  message: AppTranslations.pick(lang, en: 'Share', mr: 'शेअर करा', hi: 'साझा करें'),
                  child: InkWell(
                    onTap: () => _handleShare(item),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.share_rounded, size: 15, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Quick Delete
                Tooltip(
                  message: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                  child: InkWell(
                    onTap: () => _handleDelete(item.id),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    ),
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

