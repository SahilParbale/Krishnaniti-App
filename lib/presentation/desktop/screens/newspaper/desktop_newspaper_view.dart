import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/newspaper_clipping_model.dart';
import '../../../../data/repositories/newspaper_clippings_repository.dart';
import '../../../providers/language_provider.dart';
import '../../../screens/newspaper/newspaper_report_generator.dart';
import '../../../widgets/app_date_picker.dart';
import '../../../widgets/app_load_more_footer.dart';
import '../../common/desktop_modal_dialog.dart';

class DesktopNewspaperView extends ConsumerStatefulWidget {
  const DesktopNewspaperView({super.key});

  @override
  ConsumerState<DesktopNewspaperView> createState() => _DesktopNewspaperViewState();
}

class _DesktopNewspaperViewState extends ConsumerState<DesktopNewspaperView> {
  String _activeSection = 'positive'; // 'positive' | 'negative'
  String _viewMode = 'grid'; // 'grid' | 'table'
  bool _loading = true;
  List<NewspaperClippingModel> _clippings = [];
  String _searchTerm = '';
  String _filterDate = '';
  int _displayedLimit = 20;

  List<NewspaperClippingModel> get _visibleClippings =>
      _filteredClippings.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchClippings();
  }

  Future<void> _fetchClippings() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(newspaperClippingsRepoProvider);
      final list = await repo.getClippings();
      if (mounted) {
        setState(() {
          _clippings = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _clippings = [];
          _loading = false;
        });
      }
    }
  }

  List<NewspaperClippingModel> get _filteredClippings {
    final normalizedSearch = AppTranslations.normalizeAsciiDigits(_searchTerm).trim().toLowerCase();
    final normalizedDateFilter = AppTranslations.normalizeAsciiDigits(_filterDate).trim().toLowerCase();

    return _clippings.where((c) {
      final matchesSection = c.sentiment.toLowerCase() == _activeSection.toLowerCase();

      final matchesSearch = normalizedSearch.isEmpty ||
          c.title.toLowerCase().contains(normalizedSearch) ||
          c.titleMarathi.toLowerCase().contains(normalizedSearch) ||
          c.description.toLowerCase().contains(normalizedSearch) ||
          c.descriptionMarathi.toLowerCase().contains(normalizedSearch) ||
          c.newspaper.toLowerCase().contains(normalizedSearch);

      final matchesDate = normalizedDateFilter.isEmpty ||
          AppTranslations.normalizeAsciiDigits(c.date).toLowerCase().contains(normalizedDateFilter);

      return matchesSection && matchesSearch && matchesDate;
    }).toList();
  }

  int get _positiveCount => _clippings.where((c) => c.sentiment.toLowerCase() == 'positive').length;
  int get _negativeCount => _clippings.where((c) => c.sentiment.toLowerCase() == 'negative').length;

  String _formatClippingDate(String rawDate, String lang) {
    final normalized = AppTranslations.normalizeAsciiDigits(rawDate.trim());
    final dt = DateTime.tryParse(normalized);
    if (dt != null) {
      return AppTranslations.formatDate(dt, lang, pattern: 'dd MMM yyyy');
    }
    return AppTranslations.formatDigits(rawDate, lang);
  }

  void _showAddModal({NewspaperClippingModel? item}) {
    final initialLang = ref.read(desktopLanguageProvider);
    final initialTitle = item != null ? item.titleFor(initialLang) : '';
    final initialDesc = item != null ? item.descriptionFor(initialLang) : '';
    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController(text: initialDesc);
    final paperController = TextEditingController(
      text: item?.newspaper ??
          AppTranslations.pick(
            initialLang,
            en: 'Daily Herald',
            mr: 'सकाळ',
            hi: 'दैनिक जागरण',
          ),
    );
    final imageController = TextEditingController(
      text: item?.imageUrl ??
          'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&q=80&w=800',
    );
    String selectedSentiment = item?.sentiment ?? _activeSection;
    String dateStr = item?.date ?? DateTime.now().toIso8601String().split('T')[0];

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => StatefulBuilder(
          builder: (ctx, setModalState) {
            final parsedDate = DateTime.tryParse(
                  AppTranslations.normalizeAsciiDigits(dateStr.trim()),
                ) ??
                DateTime.now();

            return DesktopModalDialog(
              title: item == null
                  ? AppTranslations.pick(
                      lang,
                      en: 'Add News Clipping',
                      mr: 'बातमीचे कात्रण जोडा',
                      hi: 'समाचार कतरन जोड़ें',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Edit News Clipping',
                      mr: 'बातमीचे कात्रण संपादित करा',
                      hi: 'समाचार कतरन संपादित करें',
                    ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Press coverage and newspaper clipping archive',
                mr: 'वृत्तपत्र कात्रणे व प्रसिद्धी संग्रह',
                hi: 'प्रेस कवरेज और समाचार कतरन संग्रह',
              ),
              icon: Icons.newspaper_rounded,
              width: 600,
              onClose: () => Navigator.pop(ctx),
              actions: [
                DesktopModalDialog.cancelButton(ctx),
                const SizedBox(width: 12),
                DesktopModalDialog.primaryButton(
                  text: item == null
                      ? AppTranslations.pick(
                          lang,
                          en: 'Add Clipping',
                          mr: 'कात्रण जोडा',
                          hi: 'कतरन जोड़ें',
                        )
                      : AppTranslations.pick(
                          lang,
                          en: 'Save Changes',
                          mr: 'बदल जतन करा',
                          hi: 'बदलाव सहेजें',
                        ),
                  onPressed: () async {
                    final rawTitle = titleController.text.trim();
                    if (rawTitle.isEmpty) return;
                    final rawDesc = descController.text.trim();

                    final savedTitle = item != null && rawTitle == initialTitle
                        ? item.title
                        : rawTitle;
                    final savedTitleMr = item != null && rawTitle == initialTitle
                        ? item.titleMarathi
                        : rawTitle;
                    final savedDesc = item != null && rawDesc == initialDesc
                        ? item.description
                        : rawDesc;
                    final savedDescMr = item != null && rawDesc == initialDesc
                        ? item.descriptionMarathi
                        : rawDesc;

                    final newClip = NewspaperClippingModel(
                      id: item?.id ?? 'clip-${DateTime.now().millisecondsSinceEpoch}',
                      title: savedTitle,
                      titleMarathi: savedTitleMr,
                      newspaper: paperController.text.trim(),
                      date: dateStr,
                      sentiment: selectedSentiment,
                      imageUrl: imageController.text.trim(),
                      pageNumber: item?.pageNumber ?? 'Page 3',
                      edition: item?.edition ?? 'Pune City Edition',
                      description: savedDesc,
                      descriptionMarathi: savedDescMr,
                      actionTaken: item?.actionTaken,
                      journalistName: item?.journalistName,
                    );

                    final repo = ref.read(newspaperClippingsRepoProvider);
                    if (item == null) {
                      await repo.addClipping(newClip);
                    } else {
                      await repo.updateClipping(newClip);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchClippings();
                  },
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Headline *',
                      mr: 'बातमीचे शीर्षक *',
                      hi: 'समाचार शीर्षक *',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Residents satisfied with completion of road works in Ward 12...',
                        mr: 'उदा. प्रभाग १२ मधील रस्ते कामांमुळे नागरिक समाधानी...',
                        hi: 'उदा. वार्ड १२ में सड़क कार्य पूरा होने से नागरिक संतुष्ट...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Newspaper & Date
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Newspaper *',
                                mr: 'वृत्तपत्र *',
                                hi: 'समाचार पत्र *',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: paperController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Publication Date',
                                mr: 'प्रकाशन तारीख',
                                hi: 'प्रकाशन तिथि',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showThemedDatePicker(
                                  context: ctx,
                                  initialDate: parsedDate,
                                  firstDate: DateTime(2015),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    dateStr = picked.toIso8601String().split('T')[0];
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: AppColors.slate200),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatClippingDate(dateStr, lang),
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sentiment Selection
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Category / Sentiment *',
                      mr: 'श्रेणी / बातमीचा प्रकार *',
                      hi: 'श्रेणी / समाचार प्रकार *',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedSentiment = 'positive'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedSentiment == 'positive' ? const Color(0xFFF0FDF4) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedSentiment == 'positive' ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                width: selectedSentiment == 'positive' ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 6),
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Positive',
                                    mr: 'सकारात्मक',
                                    hi: 'सकारात्मक',
                                  ),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedSentiment = 'negative'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedSentiment == 'negative' ? const Color(0xFFFEF2F2) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedSentiment == 'negative' ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                width: selectedSentiment == 'negative' ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                                const SizedBox(width: 6),
                                Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Issue / Critical',
                                    mr: 'समस्या / टीका',
                                    hi: 'समस्या / आलोचनात्मक',
                                  ),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Description / Summary *',
                      mr: 'वर्णन / सारांश *',
                      hi: 'विवरण / सारांश *',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Key highlights from the article...',
                        mr: 'बातमीतील मुख्य मुद्दे...',
                        hi: 'लेख के मुख्य बिंदु...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image URL
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Clipping Image URL',
                      mr: 'कात्रणाची इमेज लिंक (URL)',
                      hi: 'कतरन छवि URL',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirm(NewspaperClippingModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppTranslations.pick(
              lang,
              en: 'Delete Clipping',
              mr: 'कात्रण हटवायचे का?',
              hi: 'कतरन हटाएं?',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Are you sure you want to delete this clipping?',
                  mr: 'तुम्हाला खात्री आहे की तुम्ही हे कात्रण हटवू इच्छिता?',
                  hi: 'क्या आप वाकई इस कतरन को हटाना चाहते हैं?',
                ),
              ),
              const SizedBox(height: 8),
              AppTranslatedText(
                item.titleFor(lang),
                targetLanguage: lang,
                prefix: '"',
                suffix: '"',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(newspaperClippingsRepoProvider);
                await repo.deleteClipping(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchClippings();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: Text(
                AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageZoomDialog(NewspaperClippingModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppTranslatedText(
                            item.titleFor(lang),
                            targetLanguage: lang,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 64)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredClippings;
    final visible = _visibleClippings;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(lang),
          const SizedBox(height: 20),

          // Positive vs Negative Tabs
          _buildSectionTabs(lang),
          const SizedBox(height: 20),

          // Filter Row
          _buildFilterRow(lang),
          const SizedBox(height: 24),

          // Content
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildReportTable(visible, lang)
          else
            _buildCardGrid(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: AppTranslations.pick(lang, en: 'clippings', mr: 'कात्रणे', hi: 'कतरनें'),
              isMarathi: lang == 'mr',
            ),
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
              Row(
                children: [
                  const Icon(Icons.feed_outlined, size: 26, color: Color(0xFF0369A1)),
                  const SizedBox(width: 10),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Newspaper Clipping',
                      mr: 'वृत्तपत्र कात्रणे',
                      hi: 'समाचार पत्र कतरनें',
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Digital documentation of media coverage, news clippings and ward publicity',
                  mr: 'प्रसिद्धी माध्यमे, बातम्यांची कात्रणे आणि प्रभाग प्रसिद्धीचे डिजिटल दस्तऐवजीकरण',
                  hi: 'मीडिया कवरेज, समाचार कतरन और वार्ड प्रचार का डिजिटल दस्तावेज़ीकरण',
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Actions: Download Report + Upload Clipping
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                NewspaperReportGenerator.generateAndPrintReport(
                  context: context,
                  clippings: _filteredClippings,
                  sentimentFilter: _activeSection,
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

            // Add Clipping
            ElevatedButton(
              onPressed: () => _showAddModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Upload Clipping',
                      mr: 'कात्रण अपलोड करा',
                      hi: 'कतरन अपलोड करें',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTabs(String lang) {
    return Row(
      children: [
        _sectionTab(
          label: AppTranslations.pick(
            lang,
            en: 'Positive News',
            mr: 'सकारात्मक बातम्या',
            hi: 'सकारात्मक समाचार',
          ),
          count: _positiveCount,
          key: 'positive',
          color: const Color(0xFF16A34A),
          activeBg: const Color(0xFFF0FDF4),
          activeBorder: const Color(0xFFBBF7D0),
          lang: lang,
        ),
        const SizedBox(width: 14),
        _sectionTab(
          label: AppTranslations.pick(
            lang,
            en: 'Issues Raised',
            mr: 'समस्या / टीका',
            hi: 'उठाए गए मुद्दे',
          ),
          count: _negativeCount,
          key: 'negative',
          color: const Color(0xFFDC2626),
          activeBg: const Color(0xFFFEF2F2),
          activeBorder: const Color(0xFFFECACA),
          lang: lang,
        ),
      ],
    );
  }

  Widget _sectionTab({
    required String label,
    required int count,
    required String key,
    required Color color,
    required Color activeBg,
    required Color activeBorder,
    required String lang,
  }) {
    final isSelected = _activeSection == key;

    return InkWell(
      onTap: () => setState(() {
        _activeSection = key;
        _displayedLimit = 20;
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBorder : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                AppTranslations.formatDigits(count, lang),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String lang) {
    return Row(
      children: [
        // Headline Search (Col 8)
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
                _searchTerm = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search headline, newspaper, description...',
                  mr: 'शीर्षक, वृत्तपत्र, वर्णन शोधा...',
                  hi: 'शीर्षक, समाचार पत्र, विवरण खोजें...',
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

        // Date Search (Col 4)
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _filterDate = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search date (e.g. 2026-01)',
                  mr: 'तारीख शोधा (उदा. २०२६-०१)',
                  hi: 'तिथि खोजें (उदा. २०२६-०१)',
                ),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: _filterDate.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        tooltip: AppTranslations.pick(lang, en: 'Clear', mr: 'पुसून टाका', hi: 'साफ़ करें'),
                        onPressed: () => setState(() => _filterDate = ''),
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildViewToggleButton(
                icon: Icons.grid_view_rounded,
                label: AppTranslations.pick(lang, en: 'Grid', mr: 'ग्रिड', hi: 'ग्रिड'),
                isActive: _viewMode == 'grid',
                onTap: () => setState(() => _viewMode = 'grid'),
              ),
              const SizedBox(width: 4),
              _buildViewToggleButton(
                icon: Icons.table_rows_rounded,
                label: AppTranslations.pick(lang, en: 'Table', mr: 'तक्ता', hi: 'तालिका'),
                isActive: _viewMode == 'table',
                onTap: () => setState(() => _viewMode = 'table'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String lang) {
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
          const Icon(Icons.newspaper_outlined, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            AppTranslations.pick(
              lang,
              en: 'No news clippings found',
              mr: 'कोणतीही बातमी कात्रणे आढळली नाहीत',
              hi: 'कोई समाचार कतरन नहीं मिली',
            ),
            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(List<NewspaperClippingModel> items, String lang) {
    if (items.isEmpty) {
      return _buildEmptyState(lang);
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
                    // Image with click to zoom
                    InkWell(
                      onTap: () => _showImageZoomDialog(item),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Image.network(
                            item.imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 160,
                              color: const Color(0xFFF1F5F9),
                              alignment: Alignment.center,
                              child: const Icon(Icons.newspaper_outlined, size: 48, color: Color(0xFF94A3B8)),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.zoom_in, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  AppTranslations.pick(lang, en: 'View', mr: 'पहा', hi: 'देखें'),
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Newspaper tag & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFBAE6FD)),
                                  ),
                                  child: AppTranslatedText(
                                    item.newspaper,
                                    targetLanguage: lang,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatClippingDate(item.date, lang),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Title
                          AppTranslatedText(
                            item.titleFor(lang),
                            targetLanguage: lang,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                          ),
                          const SizedBox(height: 6),

                          // Description
                          AppTranslatedText(
                            item.descriptionFor(lang),
                            targetLanguage: lang,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Bottom Edit/Delete Actions
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.isPositive
                                ? AppTranslations.pick(lang, en: 'Positive', mr: 'सकारात्मक', hi: 'सकारात्मक')
                                : AppTranslations.pick(lang, en: 'Issue', mr: 'समस्या', hi: 'मुद्दा'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                                onPressed: () => _showAddModal(item: item),
                                tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                                onPressed: () => _showDeleteConfirm(item),
                                tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                              ),
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

  Widget _buildReportTable(List<NewspaperClippingModel> items, String lang) {
    if (items.isEmpty) {
      return _buildEmptyState(lang);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: [
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Date', mr: 'तारीख', hi: 'तिथि'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Newspaper', mr: 'वृत्तपत्र', hi: 'समाचार पत्र'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Headline & Summary', mr: 'शीर्षक आणि सारांश', hi: 'शीर्षक और सारांश'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Category', mr: 'प्रकार', hi: 'श्रेणी'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Actions', mr: 'कार्यवाही', hi: 'कार्रवाई'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
          ],
          rows: items.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    _formatClippingDate(item.date, lang),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                DataCell(
                  AppTranslatedText(
                    item.newspaper,
                    targetLanguage: lang,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppTranslatedText(
                          item.titleFor(lang),
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        AppTranslatedText(
                          item.descriptionFor(lang),
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      item.isPositive
                          ? AppTranslations.pick(lang, en: 'Positive', mr: 'सकारात्मक', hi: 'सकारात्मक')
                          : AppTranslations.pick(lang, en: 'Issue', mr: 'समस्या', hi: 'मुद्दा'),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
                    ),
                  ),
                ),
                DataCell(
                  (item.actionTaken != null && item.actionTaken!.trim().isNotEmpty)
                      ? AppTranslatedText(
                          item.actionTaken!,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        )
                      : const Text('-', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ),
              ],
            );
          }).toList(),
        ),
      ),
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
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
