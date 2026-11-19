import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gallery_model.dart';
import '../../../data/repositories/gallery_repository.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_image_picker.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'gallery_detail_screen.dart';
import 'gallery_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'all'; // 'all' or GalleryCategory.id
  String _viewMode = 'grid'; // 'grid' | 'list'
  int _displayedLimit = 20;

  bool _isLoading = true;
  List<GalleryItemModel> _allGalleryItems = [];

  List<GalleryItemModel> get _visibleItems =>
      _filteredItems.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGallery() async {
    setState(() => _isLoading = true);
    final repo = ref.read(galleryRepoProvider);
    final items = await repo.getGalleryItems();
    if (mounted) {
      setState(() {
        _allGalleryItems = items;
        _isLoading = false;
        _displayedLimit = 20;
      });
    }
  }

  List<GalleryItemModel> get _filteredItems {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allGalleryItems.where((item) {
      final matchesSearch = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.titleMr.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          item.descriptionMr.toLowerCase().contains(q) ||
          item.location.toLowerCase().contains(q);

      final matchesCategory = _selectedCategory == 'all' ||
          item.category.id.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showAddPhotoDialog() {
    final isMr = ref.read(isMarathiProvider);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    GalleryCategory selectedCat = GalleryCategory.event;
    XFile? pickedImage;

    InputDecoration inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. FIXED HEADER
                AppModalHeader(
                  icon: Icons.add_photo_alternate_rounded,
                  title: isMr ? 'नवीन फोटो जोडा' : 'Add New Photo',
                  subtitle: isMr
                      ? 'गॅलरीमध्ये फोटो, श्रेणी व माहिती जोडा'
                      : 'Add media files, category and event details',
                  onClose: () => Navigator.pop(ctx),
                ),

                // 2. SCROLLABLE FORM BODY & BUTTONS
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(ctx).viewInsets.bottom + 24,
                    ),
                    children: [
                      // Title & Category side-by-side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFieldLabel(
                                  label: isMr ? 'फोटोचे नाव / शीर्षक' : 'Photo Title',
                                  isRequired: true,
                                ),
                                TextField(
                                  controller: titleCtrl,
                                  decoration: inputDec(
                                    hintText: isMr ? 'उदा. प्रभाग विकास पाहणी २०२४' : 'e.g. Ward Development 2024',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppDropdownFormField<GalleryCategory>(
                                label: isMr ? 'श्रेणी' : 'Category',
                                value: selectedCat,
                                  isExpanded: true,
                                  items: GalleryCategory.values.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          Icon(c.icon, size: 14, color: c.color),
                                          const SizedBox(width: 6),
                                          Text(isMr ? c.titleMr : c.titleEn, style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedCat = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // STANDARDIZED IMAGE UPLOAD (Camera & Phone Storage)
                      AppImagePickerField(
                        label: isMr ? 'फोटो निवडा (कॅमेरा व मोबाइल स्टोरेज)' : 'Select Photo (Camera & Phone Storage)',
                        isRequired: true,
                        isMarathi: isMr,
                        initialFiles: pickedImage != null ? [pickedImage!] : [],
                        onFilesChanged: (files) {
                          setModalState(() {
                            pickedImage = files.isNotEmpty ? files.first : null;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // Optional Image URL
                      AppFieldLabel(
                        label: isMr ? 'किंवा फोटो वेब लिंक / URL' : 'Or Image Web URL',
                        isRequired: false,
                        optionalHint: isMr ? 'ऐच्छिक' : 'Optional',
                      ),
                      TextField(
                        controller: urlCtrl,
                        decoration: inputDec(
                          hintText: 'https://images.unsplash.com/...',
                          prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Date Picker
                      AppFieldLabel(
                        label: isMr ? 'तारीख' : 'Date',
                        isRequired: false,
                      ),
                      InkWell(
                        onTap: () async {
                          final picked = await showThemedDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      AppFieldLabel(
                        label: isMr ? 'तपशील / वर्णन' : 'Description',
                        isRequired: false,
                        optionalHint: isMr ? 'ऐच्छिक' : 'Optional',
                      ),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: inputDec(
                          hintText: isMr ? 'फोटो किंवा कार्यक्रमाविषयी थोडक्यात माहिती...' : 'Brief details about this photo or event...',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SCROLLABLE ACTION BUTTONS (Cancel & Submit)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                isMr ? 'रद्द करा' : 'Cancel',
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isMr ? 'कृपया फोटोचे शीर्षक प्रविष्ट करा' : 'Please enter photo title.')),
                                  );
                                  return;
                                }

                                final finalImageUrl = pickedImage != null
                                    ? pickedImage!.path
                                    : (urlCtrl.text.trim().isNotEmpty
                                        ? urlCtrl.text.trim()
                                        : 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?auto=format&fit=crop&w=800&q=80');

                                final desc = descCtrl.text.trim().isNotEmpty
                                    ? descCtrl.text.trim()
                                    : 'Ward 12 public development program.';

                                final newItem = GalleryItemModel(
                                  id: 'gal-${DateTime.now().millisecondsSinceEpoch}',
                                  title: title,
                                  titleMr: title,
                                  category: selectedCat,
                                  imageUrl: finalImageUrl,
                                  description: desc,
                                  descriptionMr: desc,
                                  date: selectedDate,
                                  location: 'Ward 12, Pune',
                                  tags: ['Ward Development', selectedCat.titleEn],
                                  isFavorite: false,
                                  viewsCount: 1,
                                  createdAt: DateTime.now(),
                                );

                                final repo = ref.read(galleryRepoProvider);
                                await repo.addGalleryItem(newItem);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  _loadGallery();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isMr ? 'फोटो गॅलरीमध्ये यशस्वीरित्या जोडला गेला!' : 'Photo added to gallery successfully!'),
                                      backgroundColor: const Color(0xFF16A34A),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: Text(
                                isMr ? 'गॅलरीत जोडा' : 'Add to Gallery',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isMarathi = ref.watch(isMarathiProvider);
    final filtered = _filteredItems;
    final totalCount = _allGalleryItems.length;
    final eventsCount = _allGalleryItems.where((i) => i.category == GalleryCategory.event).length;
    final worksCount = _allGalleryItems.where((i) => i.category == GalleryCategory.work).length;
    final awardsCount = _allGalleryItems.where((i) => i.category == GalleryCategory.award).length;
    final campaignsCount = _allGalleryItems.where((i) => i.category == GalleryCategory.campaign).length;

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
            children: const [
              Text(
                'Gallery & Media',
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
                'Official photo archive, development work images and press albums',
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
        body: _isLoading
            ? const AppShimmerList(count: 6)
            : RefreshIndicator(
                onRefresh: _loadGallery,
                color: const Color(0xFF0284C7),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4 Executive KPI Stat Cards
                      _buildKpiSummaryRow(totalCount, eventsCount, worksCount, awardsCount, campaignsCount),

                      const SizedBox(height: 16),

                      // Search & Filter Card
                      _buildSearchAndFiltersCard(filtered),

                      const SizedBox(height: 16),

                      // Gallery Grid or List Content
                      if (_viewMode == 'grid')
                        _buildGridView(_visibleItems)
                      else
                        _buildListView(_visibleItems),
                      if (!_isLoading && filtered.isNotEmpty)
                        AppLoadMoreFooter(
                          currentCount: _visibleItems.length,
                          totalCount: filtered.length,
                          pageSize: 20,
                          onLoadMore: () => setState(() => _displayedLimit += 20),
                          label: isMarathi ? 'छायाचित्रे' : 'photos',
                          isMarathi: isMarathi,
                        ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddPhotoDialog,
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text(
            'Add Photo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSummaryRow(int total, int events, int works, int awards, int campaigns) {
    return Row(
      children: [
        _buildKpiCard('Total Photos', '$total', const Color(0xFF0284C7), Icons.photo_library_rounded),
        const SizedBox(width: 8),
        _buildKpiCard('Events', '$events', const Color(0xFF8B5CF6), Icons.celebration_rounded),
        const SizedBox(width: 8),
        _buildKpiCard('Development Works', '$works', const Color(0xFF0284C7), Icons.engineering_rounded),
        const SizedBox(width: 8),
        _buildKpiCard('Awards', '$awards', const Color(0xFFD97706), Icons.emoji_events_rounded),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFiltersCard(List<GalleryItemModel> filtered) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Search Input & Action Controls
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search gallery or photos...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _displayedLimit = 20;
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  onChanged: (_) => setState(() => _displayedLimit = 20),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _viewMode == 'grid' ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        color: const Color(0xFF0284C7),
                        size: 20,
                      ),
                      tooltip: _viewMode == 'grid' ? 'List View' : 'Grid View',
                      onPressed: () {
                        setState(() {
                          _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
                        });
                      },
                    ),
                    AppPdfButton.icon(
                      tooltip: 'Official PDF Catalog',
                      onPressed: () => GalleryReportGenerator.generateAndPrintReport(items: filtered),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Categories Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryFilterChip('All (${_allGalleryItems.length})', 'all'),
                const SizedBox(width: 6),
                _buildCategoryFilterChip('Events & Functions', 'Event'),
                const SizedBox(width: 6),
                _buildCategoryFilterChip('Development Works', 'Work'),
                const SizedBox(width: 6),
                _buildCategoryFilterChip('Awards', 'Award'),
                const SizedBox(width: 6),
                _buildCategoryFilterChip('Campaigns', 'Campaign'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFF334155),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      onSelected: (_) => setState(() {
        _selectedCategory = value;
        _displayedLimit = 20;
      }),
    );
  }

  // ==========================================
  // VIEW MODE 1: GRID VIEW (2 COLUMNS)
  // ==========================================
  Widget _buildGridView(List<GalleryItemModel> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No photos found.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        return _buildGridCard(item);
      },
    );
  }

  Widget _buildGridCard(GalleryItemModel item) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GalleryDetailScreen(item: item)),
        );
        _loadGallery();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack with Badges
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildGalleryImage(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF1F5F9),
                        child: Center(
                          child: Icon(item.category.icon, size: 32, color: Colors.grey.shade400),
                        ),
                      );
                    },
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFF8FAFC),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                          ),
                        ),
                      );
                    },
                  ),
                  // Category Tag Overlay
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category.titleMr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Favorite Heart
                  if (item.isFavorite)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 12,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Card Body (Title, Date, Views)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titleMr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF64748B)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.location,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.formattedDate,
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                        ),
                        Text(
                          '${item.viewsCount} views',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW MODE 2: LIST VIEW
  // ==========================================
  Widget _buildListView(List<GalleryItemModel> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No photos available.'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        return InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GalleryDetailScreen(item: item)),
            );
            _loadGallery();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
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
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildGalleryImage(
                    item.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFFF1F5F9),
                        child: Center(
                          child: Icon(item.category.icon, size: 28, color: Colors.grey.shade400),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.category.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.category.titleMr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.category.color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.formattedDate,
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.titleMr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.descriptionMr,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              item.location,
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${item.viewsCount} views',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
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
  }

  Widget _buildGalleryImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
  }) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
      );
    }
    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      }
    } catch (_) {}
    return errorBuilder != null
        ? errorBuilder(context, Exception('File not found'), null)
        : const SizedBox();
  }
}
