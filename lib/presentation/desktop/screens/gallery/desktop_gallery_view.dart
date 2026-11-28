import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../common/desktop_modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/gallery_model.dart';
import '../../../../data/repositories/gallery_repository.dart';
import '../../../screens/gallery/gallery_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopGalleryView extends ConsumerStatefulWidget {
  const DesktopGalleryView({super.key});

  @override
  ConsumerState<DesktopGalleryView> createState() => _DesktopGalleryViewState();
}

class _DesktopGalleryViewState extends ConsumerState<DesktopGalleryView> {
  bool _loading = true;
  List<GalleryItemModel> _items = [];
  String _searchTerm = '';
  GalleryCategory? _selectedCategory;
  int _displayedLimit = 20;

  List<GalleryItemModel> get _visibleItems =>
      _filteredItems.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchGallery();
  }

  Future<void> _fetchGallery() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(galleryRepoProvider);
      final list = await repo.getGalleryItems(category: _selectedCategory);
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = [];
          _loading = false;
        });
      }
    }
  }

  List<GalleryItemModel> get _filteredItems {
    final q = AppTranslations.normalizeAsciiDigits(_searchTerm.trim()).toLowerCase();
    return _items.where((i) {
      final matchesSearch = q.isEmpty ||
          i.title.toLowerCase().contains(q) ||
          i.titleMr.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          i.descriptionMr.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q);

      return matchesSearch;
    }).toList();
  }

  void _showAddModal({GalleryItemModel? item}) {
    final currentLang = ref.read(desktopLanguageProvider);
    final initialTitle = item == null
        ? ''
        : ((currentLang == 'mr' && item.titleMr.trim().isNotEmpty) ? item.titleMr : item.title);
    final initialDesc = item == null
        ? ''
        : ((currentLang == 'mr' && item.descriptionMr.trim().isNotEmpty)
            ? item.descriptionMr
            : item.description);
    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController(text: initialDesc);
    final imageController = TextEditingController(
      text: item?.imageUrl ??
          'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80&w=800',
    );
    GalleryCategory selectedCat = item?.category ?? GalleryCategory.event;
    String dateStr = item != null
        ? DateFormat('yyyy-MM-dd').format(item.date)
        : DateTime.now().toIso8601String().split('T')[0];

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => StatefulBuilder(
          builder: (ctx, setModalState) {
            final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
            return DesktopModalDialog(
              title: item == null
                  ? AppTranslations.pick(lang, en: 'Add Photo', mr: 'फोटो जोडा', hi: 'फ़ोटो जोड़ें')
                  : AppTranslations.pick(
                      lang,
                      en: 'Edit Photo Details',
                      mr: 'फोटो तपशील संपादित करा',
                      hi: 'फ़ोटो विवरण संपादित करें',
                    ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Upload work photos and public event imagery',
                mr: 'विकासकामे आणि सार्वजनिक कार्यक्रमांचे फोटो अपलोड करा',
                hi: 'विकास कार्यों और सार्वजनिक कार्यक्रमों की तस्वीरें अपलोड करें',
              ),
              icon: Icons.photo_library_rounded,
              width: 600,
              onClose: () => Navigator.pop(ctx),
              actions: [
                DesktopModalDialog.cancelButton(ctx),
                const SizedBox(width: 12),
                DesktopModalDialog.primaryButton(
                  text: item == null
                      ? AppTranslations.pick(lang, en: 'Add Photo', mr: 'फोटो जोडा', hi: 'फ़ोटो जोड़ें')
                      : AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'परिवर्तन सहेजें'),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final newPhoto = GalleryItemModel(
                      id: item?.id ?? 'gal-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      titleMr: titleController.text.trim(),
                      description: descController.text.trim(),
                      descriptionMr: descController.text.trim(),
                      category: selectedCat,
                      imageUrl: imageController.text.trim(),
                      date: DateTime.tryParse(dateStr) ?? DateTime.now(),
                      location: item?.location ?? 'Ward 12',
                      createdAt: item?.createdAt ?? DateTime.now(),
                    );

                    final repo = ref.read(galleryRepoProvider);
                    if (item == null) {
                      await repo.addGalleryItem(newPhoto);
                    } else {
                      await repo.updateGalleryItem(newPhoto);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchGallery();
                  },
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    AppTranslations.pick(lang, en: 'Title *', mr: 'शीर्षक *', hi: 'शीर्षक *'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Ward 12 Community Center Inauguration...',
                        mr: 'उदा. प्रभाग १२ समाज मंदिर उद्घाटन...',
                        hi: 'जैसे वार्ड १२ सामुदायिक भवन उद्घाटन...',
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

                  // Category & Date
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(lang, en: 'Category *', mr: 'प्रकार *', hi: 'श्रेणी *'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<GalleryCategory>(
                              value: selectedCat,
                              height: 44,
                              backgroundColor: const Color(0xFFF8FAFC),
                              borderColor: const Color(0xFFE2E8F0),
                              items: GalleryCategory.values.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c.title(lang)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedCat = val);
                              },
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
                              AppTranslations.pick(lang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: parsedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => dateStr = DateFormat('yyyy-MM-dd').format(picked));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppTranslations.formatDate(parsedDate, lang, pattern: 'dd/MM/yyyy'),
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

                  // Description
                  Text(
                    AppTranslations.pick(lang, en: 'Description', mr: 'तपशील', hi: 'विवरण'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Brief description of the photo...',
                        mr: 'फोटोबद्दल थोडक्यात माहिती...',
                        hi: 'फ़ोटो का संक्षिप्त विवरण...',
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
                    AppTranslations.pick(lang, en: 'Image URL *', mr: 'फोटो URL *', hi: 'छवि URL *'),
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

  void _showDeleteConfirm(GalleryItemModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppTranslations.pick(lang, en: 'Delete Photo', mr: 'फोटो हटवा', hi: 'फ़ोटो हटाएं')),
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Are you sure you want to delete this photo?',
              mr: 'तुम्हाला खात्री आहे की तुम्ही हा फोटो हटवू इच्छिता?',
              hi: 'क्या आप वाकई इस फ़ोटो को हटाना चाहते हैं?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(galleryRepoProvider);
                await repo.deleteGalleryItem(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchGallery();
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

  void _showZoomDialog(GalleryItemModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) {
          final displayTitle = (lang == 'mr' && item.titleMr.trim().isNotEmpty)
              ? item.titleMr
              : item.title;
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
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
                          displayTitle,
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
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 64)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredItems;
    final visible = _visibleItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length, lang),
          const SizedBox(height: 20),

          // Category Chips & Search Row
          _buildFilterRow(lang),
          const SizedBox(height: 24),

          // Photos Grid
          if (_loading)
            _buildLoadingGrid()
          else
            _buildGalleryGrid(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: 'photos',
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Gallery & Media',
                    mr: 'गॅलरी आणि मीडिया',
                    hi: 'गैलरी और मीडिया',
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text(
                    '${AppTranslations.pick(lang, en: 'Total Photos:', mr: 'एकूण फोटो:', hi: 'कुल फ़ोटो:')} ${AppTranslations.formatDigits(count, lang)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.pick(
                lang,
                en: 'Visual archives of civil works, events and community initiatives',
                mr: 'विकासकामे, कार्यक्रम आणि उपक्रमांचे छायाचित्र संग्रह',
                hi: 'विकास कार्यों, कार्यक्रमों और सामुदायिक पहलों का दृश्य संग्रह',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                GalleryReportGenerator.generateAndPrintReport(
                  context: context,
                  items: _filteredItems,
                  categoryFilter: _selectedCategory?.id,
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

            // Add Photo
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
                    AppTranslations.pick(lang, en: 'Add Photo', mr: 'फोटो जोडा', hi: 'फ़ोटो जोड़ें'),
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

  Widget _buildFilterRow(String lang) {
    return Row(
      children: [
        // Category Pills
        Wrap(
          spacing: 8,
          children: [
            _categoryPill(null, AppTranslations.getAll(lang)),
            _categoryPill(GalleryCategory.event, GalleryCategory.event.title(lang)),
            _categoryPill(GalleryCategory.work, GalleryCategory.work.title(lang)),
            _categoryPill(GalleryCategory.award, GalleryCategory.award.title(lang)),
            _categoryPill(GalleryCategory.campaign, GalleryCategory.campaign.title(lang)),
          ],
        ),
        const Spacer(),

        // Search Input
        Container(
          width: 280,
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
                en: 'Search photo or event...',
                mr: 'फोटो किंवा कार्यक्रम शोधा...',
                hi: 'फ़ोटो या कार्यक्रम खोजें...',
              ),
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: AppTranslations.pick(lang, en: 'Clear', mr: 'साफ करा', hi: 'साफ़ करें'),
                      onPressed: () => setState(() => _searchTerm = ''),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryPill(GalleryCategory? category, String label) {
    final isSelected = _selectedCategory == category;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _displayedLimit = 20;
        });
        _fetchGallery();
      },
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(List<GalleryItemModel> items, String lang) {
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
            const Icon(Icons.photo_library_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No photos found',
                mr: 'कोणतेही फोटो आढळले नाहीत',
                hi: 'कोई फ़ोटो नहीं मिली',
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
            mainAxisExtent: 330,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final displayTitle = (lang == 'mr' && item.titleMr.trim().isNotEmpty)
                ? item.titleMr
                : item.title;
            final displayDesc = (lang == 'mr' && item.descriptionMr.trim().isNotEmpty)
                ? item.descriptionMr
                : item.description;

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
                    // Photo Thumbnail with zoom click
                    InkWell(
                      onTap: () => _showZoomDialog(item),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Image.network(
                            item.imageUrl,
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 170,
                              color: const Color(0xFFF1F5F9),
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Color(0xFF94A3B8)),
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

                    // Details
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFBAE6FD)),
                                ),
                                child: Text(
                                  item.category.title(lang),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                ),
                              ),
                              Text(
                                AppTranslations.formatDate(item.date, lang),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Title
                          AppTranslatedText(
                            displayTitle,
                            targetLanguage: lang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),

                          // Description
                          AppTranslatedText(
                            displayDesc,
                            targetLanguage: lang,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Bottom Edit/Delete Actions
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.remove_red_eye_outlined, size: 13, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                '${AppTranslations.formatDigits(item.viewsCount, lang)} ${AppTranslations.pick(lang, en: 'views', mr: 'वेळा पाहिले', hi: 'बार देखा गया')}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
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
            mainAxisExtent: 300,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
