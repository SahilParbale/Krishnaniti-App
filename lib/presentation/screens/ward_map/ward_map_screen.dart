import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/ward_map_point_model.dart';
import '../../../data/repositories/ward_map_repository.dart';
import '../../navigation/app_drawer.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_pdf_button.dart';
import 'ward_map_report_generator.dart';
import '../../widgets/app_dropdown.dart';

class WardMapScreen extends ConsumerStatefulWidget {
  const WardMapScreen({super.key});

  @override
  ConsumerState<WardMapScreen> createState() => _WardMapScreenState();
}

class _WardMapScreenState extends ConsumerState<WardMapScreen> {
  final TransformationController _transformCtrl = TransformationController();
  final TextEditingController _searchCtrl = TextEditingController();

  String _viewMode = 'map'; // 'map' or 'list'
  String _activeCategory = 'All'; // 'All', 'Booth', 'CivilWorks', 'Amenity', 'ProblemSpot', 'Office'
  bool _isSatelliteMode = false;

  bool _isLoading = true;
  List<WardMapPointModel> _allPoints = [];
  WardMapPointModel? _selectedPoint;

  final List<Map<String, String>> _categories = [
    {'id': 'All', 'labelEn': 'All Places', 'labelMr': 'सर्व ठिकाणे', 'labelHi': 'सभी स्थान'},
    {'id': 'Booth', 'labelEn': 'Polling Booths', 'labelMr': 'मतदान केंद्र', 'labelHi': 'मतदान केंद्र'},
    {'id': 'CivilWorks', 'labelEn': 'Civil Works', 'labelMr': 'विकासकामे', 'labelHi': 'विकास कार्य'},
    {'id': 'Amenity', 'labelEn': 'Civic Amenities', 'labelMr': 'नागरी सुविधा', 'labelHi': 'नागरिक सुविधाएं'},
    {'id': 'ProblemSpot', 'labelEn': 'Problem Spots', 'labelMr': 'समस्या ठिकाणे', 'labelHi': 'समस्या स्थल'},
    {'id': 'Office', 'labelEn': 'Ward Office', 'labelMr': 'कार्यालय', 'labelHi': 'वार्ड कार्यालय'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(wardMapRepoProvider);
    final points = await repo.getWardPoints();
    if (mounted) {
      setState(() {
        _allPoints = points;
        _isLoading = false;
        if (_selectedPoint == null && points.isNotEmpty) {
          _selectedPoint = points.first;
        }
      });
    }
  }

  List<WardMapPointModel> get _filteredPoints {
    final query = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim())
        .toLowerCase();

    return _allPoints.where((p) {
      if (_activeCategory != 'All' && p.category.toLowerCase() != _activeCategory.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        final titleMatch = p.title.toLowerCase().contains(query);
        final addrMatch = p.address.toLowerCase().contains(query);
        final descMatch = p.description.toLowerCase().contains(query);
        final catMatch = p.category.toLowerCase().contains(query);
        if (!titleMatch && !addrMatch && !descMatch && !catMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _resetMapZoom() {
    final lang = ref.read(appLanguageProvider);
    _transformCtrl.value = Matrix4.identity();
    final wardNo = AppTranslations.formatDigits('12', lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Map centered to Ward No. $wardNo',
            mr: 'नकाशा प्रभाग क्र. $wardNo वर केंद्रित केला',
            hi: 'मानचित्र वार्ड क्र. $wardNo पर केंद्रित किया गया',
          ),
        ),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _zoomIn() {
    final matrix = _transformCtrl.value.clone();
    matrix.scale(1.25);
    _transformCtrl.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformCtrl.value.clone();
    matrix.scale(0.80);
    _transformCtrl.value = matrix;
  }

  Future<void> _openDirections(WardMapPointModel point) async {
    final uri = Uri.parse(point.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyAddress(WardMapPointModel point) {
    final lang = ref.read(appLanguageProvider);
    Clipboard.setData(ClipboardData(text: '${point.title}\n${point.address}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'Address copied to clipboard!',
            mr: 'पत्ता क्लिपबोर्डवर कॉपी केला!',
            hi: 'पता क्लिपबोर्ड पर कॉपी किया गया!',
          ),
        ),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  Widget _fieldLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          if (isRequired)
            const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  InputDecoration _inputDec({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  // Add custom geo-tag point modal
  void _showAddPointModal() {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String cat = 'Amenity';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
                    icon: Icons.pin_drop_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Tag New Ward Location',
                      mr: 'नवीन ठिकाण नोंदवा',
                      hi: 'नया वार्ड स्थान जोड़ें',
                    ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Tag location, booth or civic spot',
                      mr: 'प्रभागातील ठिकाण, केंद्र किंवा काम टॅग करा',
                      hi: 'वार्ड में स्थान, मतदान केंद्र या कार्य टैग करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),

                  // Content
                  Flexible(
              child: ListView(
                shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Location Title & Category Side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Location Title',
                                      mr: 'ठिकाणाचे नाव',
                                      hi: 'स्थान का नाम',
                                    ),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: titleCtrl,
                                    decoration: _inputDec(
                                      hint: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. Community Hall, Booth...',
                                        mr: 'उदा. समाज मंदिर, ईव्हीएम केंद्र...',
                                        hi: 'उदा. समाज मंदिर, मतदान केंद्र...',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppDropdownFormField<String>(
                                label: AppTranslations.pick(
                                  lang,
                                  en: 'Category',
                                  mr: 'वर्गवारी',
                                  hi: 'श्रेणी',
                                ),
                                isRequired: true,
                                value: cat,
                                    items: [
                                      DropdownMenuItem(value: 'Booth', child: Text(AppTranslations.pick(lang, en: 'Booth', mr: 'मतदान केंद्र', hi: 'मतदान केंद्र'))),
                                      DropdownMenuItem(value: 'CivilWorks', child: Text(AppTranslations.pick(lang, en: 'Civil Works', mr: 'विकासकाम', hi: 'नागरिक कार्य'))),
                                      DropdownMenuItem(value: 'Amenity', child: Text(AppTranslations.pick(lang, en: 'Amenity', mr: 'सुविधा', hi: 'सुविधा'))),
                                      DropdownMenuItem(value: 'ProblemSpot', child: Text(AppTranslations.pick(lang, en: 'Problem Spot', mr: 'समस्या ठिकाण', hi: 'समस्या स्थल'))),
                                      DropdownMenuItem(value: 'Office', child: Text(AppTranslations.pick(lang, en: 'Office', mr: 'कार्यालय', hi: 'कार्यालय'))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => cat = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Address / Landmark
                        _fieldLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Address / Landmark',
                            mr: 'पत्ता / लँडमार्क',
                            hi: 'पता / लैंडमार्क',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: addrCtrl,
                          decoration: _inputDec(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'e.g. Near Ganpati Mandir, Lane 4, Prabhag 12...',
                              mr: 'उदा. गणपती मंदिराशेजारी, गल्ली क्र. ४...',
                              hi: 'उदा. गणपति मंदिर के पास, गली क्र. ४...',
                            ),
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description / Scope
                        _fieldLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Description / Scope',
                            mr: 'तपशील / व्याप्ती',
                            hi: 'विवरण / दायरा',
                          ),
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: _inputDec(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Infrastructure scope, voter capacity, or details...',
                              mr: 'कामाचे स्वरूप, मतदार क्षमता किंवा इतर तपशील...',
                              hi: 'कार्य का स्वरूप, मतदाता क्षमता या अन्य विवरण...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                            label: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Save Geo-Tag',
                                mr: 'ठिकाण सेव्ह करा',
                                hi: 'स्थान सहेजें',
                              ),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Please enter location title',
                                        mr: 'कृपया ठिकाणाचे नाव प्रविष्ट करा',
                                        hi: 'कृपया स्थान का नाम दर्ज करें',
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }
                              final newPoint = WardMapPointModel(
                                id: 'pt-${DateTime.now().millisecondsSinceEpoch}',
                                title: titleCtrl.text.trim(),
                                category: cat,
                                address: addrCtrl.text.trim(),
                                latitude: 18.5020 + (_allPoints.length * 0.0008),
                                longitude: 73.8430 + (_allPoints.length * 0.0008),
                                description: descCtrl.text.trim(),
                                relativeX: 0.45 + ((_allPoints.length % 5) * 0.06),
                                relativeY: 0.40 + ((_allPoints.length % 4) * 0.08),
                                status: 'Verified Spot',
                              );

                              Navigator.pop(sheetCtx);
                              final added = await ref.read(wardMapRepoProvider).addWardPoint(newPoint);
                              setState(() {
                                _allPoints.insert(0, added);
                                _selectedPoint = added;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Location geo-tagged on Ward Map!',
                                        mr: 'प्रभाग नकाशावर ठिकाण यशस्वीरित्या जोडले गेले!',
                                        hi: 'वार्ड मानचित्र पर स्थान सफलतापूर्वक जोड़ा गया!',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                          ),
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
    final lang = ref.watch(appLanguageProvider);
    final displayed = _filteredPoints;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0284C7),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const NagarsevakAppDrawer(currentTabIndex: 0),
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
                AppTranslations.pick(
                  lang,
                  en: 'Ward Map',
                  mr: 'प्रभाग नकाशा',
                  hi: 'वार्ड मानचित्र',
                ),
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
                AppTranslations.pick(
                  lang,
                  en: 'Boundaries, booths & civil works',
                  mr: 'प्रभाग सीमा, मतदान केंद्रे व विकासकामे',
                  hi: 'वार्ड सीमाएं, मतदान केंद्र व नागरिक कार्य',
                ),
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : Column(
                children: [
                  // 1) HEADER TOOLBAR: View Mode Toggle & Search
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Search Box
                            Expanded(
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchCtrl,
                                        onChanged: (_) => setState(() {}),
                                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                                        decoration: InputDecoration(
                                          hintText: AppTranslations.pick(
                                            lang,
                                            en: 'Search booth, project, landmark...',
                                            mr: 'केंद्र, विकासकाम किंवा पत्ता शोधा...',
                                            hi: 'केंद्र, कार्य या पता खोजें...',
                                          ),
                                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    if (_searchCtrl.text.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          _searchCtrl.clear();
                                          setState(() {});
                                        },
                                        child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // View Mode Toggle (Map vs List)
                            Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                children: [
                                  _buildViewModeBtn('map', Icons.map_rounded, AppTranslations.pick(lang, en: 'Map', mr: 'नकाशा', hi: 'मानचित्र')),
                                  _buildViewModeBtn('list', Icons.format_list_bulleted_rounded, AppTranslations.pick(lang, en: 'List', mr: 'यादी', hi: 'सूची')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _resetMapZoom,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBAE6FD)),
                                ),
                                child: const Icon(Icons.my_location_rounded, size: 20, color: Color(0xFF0284C7)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            AppPdfButton.icon(
                              tooltip: AppTranslations.getDownloadReport(lang),
                              onPressed: () {
                                WardMapReportGenerator.generateAndPrintWardMapReport(
                                  points: displayed,
                                  categoryFilter: _activeCategory,
                                  lang: lang,
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Category Layer Filter Pills
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, idx) {
                              final cat = _categories[idx];
                              final id = cat['id']!;
                              final isSel = _activeCategory == id;
                              final label = lang == 'mr' ? cat['labelMr']! : (lang == 'hi' ? (cat['labelHi'] ?? cat['labelEn']!) : cat['labelEn']!);

                              return GestureDetector(
                                onTap: () => setState(() => _activeCategory = id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF0284C7) : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        color: isSel ? Colors.white : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                  // 2) MAIN VIEW (Interactive Map or Structured List)
                  Expanded(
                    child: _viewMode == 'map'
                        ? _buildInteractiveMapView(displayed, lang)
                        : _buildListView(displayed, lang),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 3,
          onPressed: _showAddPointModal,
          icon: const Icon(Icons.add_location_alt_rounded, size: 20),
          label: Text(
            AppTranslations.pick(
              lang,
              en: 'Tag Spot',
              mr: 'ठिकाण जोडा',
              hi: 'स्थान जोड़ें',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeBtn(String mode, IconData icon, String label) {
    final isSel = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSel ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                color: isSel ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // INTERACTIVE GIS MAP VIEW
  // -------------------------------------------------------------
  Widget _buildInteractiveMapView(List<WardMapPointModel> displayed, String lang) {
    const mapW = 600.0;
    const mapH = 920.0;

    return Stack(
      children: [
        // Pan & Zoom Interactive Vector GIS Canvas
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _transformCtrl,
            minScale: 0.6,
            maxScale: 3.5,
            boundaryMargin: const EdgeInsets.all(200),
            child: SizedBox(
              width: mapW,
              height: mapH,
              child: Stack(
                children: [
                  // Vector GIS Base Canvas
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WardVectorGisPainter(
                        isSatellite: _isSatelliteMode,
                      ),
                    ),
                  ),

                  // Center Ward Demographic Badge
                  Positioned(
                    left: mapW * 0.40,
                    top: mapH * 0.48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Ward No. 12',
                              mr: 'प्रभाग क्र. १२',
                              hi: 'वार्ड क्र. १२',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            AppTranslations.formatDigits(
                              AppTranslations.pick(
                                lang,
                                en: 'Navi Peth - Parvati | 42,560 Voters',
                                mr: 'नवी पेठ - पर्वती | ४२,५६० मतदार',
                                hi: 'नवी पेठ - पर्वती | ४२,५६० मतदाता',
                              ),
                              lang,
                            ),
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Interactive Markers / Pins
                  ...displayed.map((pt) {
                    final isSel = _selectedPoint?.id == pt.id;
                    final pinX = (pt.relativeX * mapW) - 18;
                    final pinY = (pt.relativeY * mapH) - 36;

                    return Positioned(
                      left: pinX,
                      top: pinY,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedPoint = pt);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isSel ? 38 : 30,
                              height: isSel ? 38 : 30,
                              decoration: BoxDecoration(
                                color: pt.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: pt.color.withValues(alpha: isSel ? 0.6 : 0.3),
                                    blurRadius: isSel ? 10 : 5,
                                    spreadRadius: isSel ? 3 : 1,
                                  ),
                                ],
                              ),
                              child: Icon(pt.icon, size: isSel ? 20 : 16, color: Colors.white),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: pt.color.withValues(alpha: 0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: AppTranslatedText(
                                pt.title.split('(').first.trim(),
                                targetLanguage: lang,
                                style: TextStyle(
                                  fontSize: isSel ? 9.5 : 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        // Floating Map Controls (Top Right)
        Positioned(
          top: 14,
          right: 14,
          child: Column(
            children: [
              _buildFloatingIconBtn(
                icon: _isSatelliteMode ? Icons.map_rounded : Icons.satellite_alt_rounded,
                tooltip: AppTranslations.pick(
                  lang,
                  en: 'Toggle Hybrid / Satellite',
                  mr: 'उपग्रह / नकाशा बदला',
                  hi: 'सैटेलाइट / मानचित्र बदलें',
                ),
                onTap: () => setState(() => _isSatelliteMode = !_isSatelliteMode),
              ),
              const SizedBox(height: 8),
              _buildFloatingIconBtn(
                icon: Icons.add_rounded,
                tooltip: AppTranslations.pick(
                  lang,
                  en: 'Zoom In',
                  mr: 'मोठे करा',
                  hi: 'ज़ूम इन',
                ),
                onTap: _zoomIn,
              ),
              const SizedBox(height: 8),
              _buildFloatingIconBtn(
                icon: Icons.remove_rounded,
                tooltip: AppTranslations.pick(
                  lang,
                  en: 'Zoom Out',
                  mr: 'लहान करा',
                  hi: 'ज़ूम आउट',
                ),
                onTap: _zoomOut,
              ),
              const SizedBox(height: 8),
              _buildFloatingIconBtn(
                icon: Icons.center_focus_strong_rounded,
                tooltip: AppTranslations.pick(
                  lang,
                  en: 'Reset Centering',
                  mr: 'मध्यवर्ती करा',
                  hi: 'केंद्र रीसेट करें',
                ),
                onTap: _resetMapZoom,
              ),
            ],
          ),
        ),

        // Selected Place Bottom Card UI (Google Maps Style matching WardMap.tsx)
        if (_selectedPoint != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: _buildGoogleMapsPlaceCard(_selectedPoint!, lang),
          ),
      ],
    );
  }

  Widget _buildFloatingIconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF334155)),
        ),
      ),
    );
  }

  // Bottom Place Card UI matching lines 330-405 of WardMap.tsx
  Widget _buildGoogleMapsPlaceCard(WardMapPointModel point, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Title + Category + Close
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: point.bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: point.color.withValues(alpha: 0.3)),
                ),
                child: Icon(point.icon, color: point.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: point.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        point.categoryDisplayFor(lang).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: point.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppTranslatedText(
                      point.title,
                      targetLanguage: lang,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                onPressed: () => setState(() => _selectedPoint = null),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Expanded(
                child: AppTranslatedText(
                  point.address,
                  targetLanguage: lang,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Description snippet
          AppTranslatedText(
            point.description,
            targetLanguage: lang,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Action Buttons: Directions & Share (Matching WardMap.tsx lines 380-400)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _openDirections(point),
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Directions',
                      mr: 'दिशा / मार्ग',
                      hi: 'दिशा / मार्ग',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _copyAddress(point),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Copy Address',
                      mr: 'पत्ता शेअर करा',
                      hi: 'पता कॉपी करें',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STRUCTURED LIST VIEW
  // -------------------------------------------------------------
  Widget _buildListView(List<WardMapPointModel> displayed, String lang) {
    if (displayed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 54, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No ward locations match your filter',
                mr: 'कोणतेही ठिकाण आढळले नाही',
                hi: 'आपके फ़िल्टर से कोई स्थान मेल नहीं खाता',
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: displayed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final pt = displayed[idx];
        return Container(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: pt.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: pt.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(pt.icon, color: pt.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pt.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pt.categoryDisplayFor(lang),
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: pt.color),
                          ),
                        ),
                        const SizedBox(height: 5),
                        AppTranslatedText(
                          pt.title,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AppTranslatedText(
                      pt.address,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AppTranslatedText(
                pt.description,
                targetLanguage: lang,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.35),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GPS: ${AppTranslations.formatDigits('${pt.latitude.toStringAsFixed(4)}, ${pt.longitude.toStringAsFixed(4)}', lang)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _copyAddress(pt),
                        icon: const Icon(Icons.share_outlined, size: 14),
                        label: Text(
                          AppTranslations.pick(lang, en: 'Copy', mr: 'कॉपी', hi: 'कॉपी'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          elevation: 0,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _openDirections(pt),
                        icon: const Icon(Icons.navigation_rounded, size: 14),
                        label: Text(
                          AppTranslations.pick(lang, en: 'Navigate', mr: 'मार्ग', hi: 'मार्ग'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for the realistic GIS street map and Ward No. 12 boundary polygon matching WardMap.tsx
class _WardVectorGisPainter extends CustomPainter {
  final bool isSatellite;

  _WardVectorGisPainter({required this.isSatellite});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Land Background
    final baseBg = Paint()..color = isSatellite ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), baseBg);

    // 2. Green Municipal Parks
    final parkPaint = Paint()
      ..color = isSatellite ? const Color(0xFF14532D).withValues(alpha: 0.6) : const Color(0xFFE2F4DF)
      ..style = PaintingStyle.fill;

    // Top-left park
    final park1 = Path()
      ..moveTo(0, h * 0.12)
      ..lineTo(w * 0.32, h * 0.08)
      ..lineTo(w * 0.28, h * 0.22)
      ..lineTo(w * 0.10, h * 0.26)
      ..lineTo(0, h * 0.20)
      ..close();
    canvas.drawPath(park1, parkPaint);

    // Bottom-center large municipal park (Sambhaji Park)
    final park4 = Path()
      ..moveTo(w * 0.20, h * 0.72)
      ..lineTo(w * 0.55, h * 0.74)
      ..lineTo(w * 0.52, h * 0.92)
      ..lineTo(w * 0.18, h * 0.90)
      ..close();
    canvas.drawPath(park4, parkPaint);

    // 3. Water Canal Lines
    final waterPaint = Paint()
      ..color = isSatellite ? const Color(0xFF0369A1).withValues(alpha: 0.7) : const Color(0xFFD4EBF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final waterPath = Path()
      ..moveTo(w * 0.02, h * 0.38)
      ..cubicTo(w * 0.24, h * 0.42, w * 0.50, h * 0.56, w * 0.72, h * 0.52)
      ..lineTo(w * 0.98, h * 0.58);
    canvas.drawPath(waterPath, waterPaint);

    // 4. Street Grid
    final streetPaint = Paint()
      ..color = isSatellite ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 9; i++) {
      final yOffset = h * 0.10 + i * (h * 0.09);
      canvas.drawLine(Offset(0, yOffset), Offset(w, yOffset + h * 0.08), streetPaint);
      canvas.drawLine(Offset(w * 0.10 + i * (w * 0.10), 0), Offset(w * 0.05 + i * (w * 0.10), h), streetPaint);
    }

    // 5. Main Arterial Roads & Highways
    final highwayBorder = Paint()
      ..color = isSatellite ? const Color(0xFF475569) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final highwayFill = Paint()
      ..color = isSatellite ? const Color(0xFF64748B) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2;

    final road1 = Path()
      ..moveTo(0, h * 0.28)
      ..cubicTo(w * 0.35, h * 0.32, w * 0.65, h * 0.45, w, h * 0.48);
    canvas.drawPath(road1, highwayBorder);
    canvas.drawPath(road1, highwayFill);

    final road2 = Path()
      ..moveTo(w * 0.15, h)
      ..cubicTo(w * 0.25, h * 0.65, w * 0.55, h * 0.35, w * 0.85, 0);
    canvas.drawPath(road2, highwayBorder);
    canvas.drawPath(road2, highwayFill);

    // 6. --- WARD BOUNDARY POLYGON (Matching WardMap.tsx) ---
    final wardPolygon = Path();
    final cx = w * 0.50;
    final cy = h * 0.48;

    wardPolygon.moveTo(cx - w * 0.22, cy - h * 0.18);
    wardPolygon.lineTo(cx - w * 0.08, cy - h * 0.15);
    wardPolygon.lineTo(cx + w * 0.02, cy - h * 0.22);
    wardPolygon.lineTo(cx + w * 0.13, cy - h * 0.24);
    wardPolygon.lineTo(cx + w * 0.18, cy - h * 0.32);
    wardPolygon.lineTo(cx + w * 0.24, cy - h * 0.30);
    wardPolygon.lineTo(cx + w * 0.21, cy - h * 0.21);
    wardPolygon.lineTo(cx + w * 0.28, cy - h * 0.17);
    wardPolygon.lineTo(cx + w * 0.25, cy - h * 0.10);
    wardPolygon.lineTo(cx + w * 0.34, cy - h * 0.08);
    wardPolygon.lineTo(cx + w * 0.27, cy + h * 0.08);
    wardPolygon.lineTo(cx + w * 0.32, cy + h * 0.18);
    wardPolygon.lineTo(cx + w * 0.16, cy + h * 0.26);
    wardPolygon.lineTo(cx + w * 0.06, cy + h * 0.32);
    wardPolygon.lineTo(cx - w * 0.08, cy + h * 0.38);
    wardPolygon.lineTo(cx - w * 0.20, cy + h * 0.38);
    wardPolygon.lineTo(cx - w * 0.20, cy + h * 0.22);
    wardPolygon.lineTo(cx - w * 0.42, cy + h * 0.22);
    wardPolygon.lineTo(cx - w * 0.42, cy + h * 0.06);
    wardPolygon.lineTo(cx - w * 0.46, cy + h * 0.05);
    wardPolygon.lineTo(cx - w * 0.38, cy - h * 0.10);
    wardPolygon.close();

    // Fill polygon
    final polygonFill = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: isSatellite ? 0.25 : 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawPath(wardPolygon, polygonFill);

    // Stroke boundary line (Red / Brand Blue matching WardMap.tsx)
    final polygonStroke = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(wardPolygon, polygonStroke);
  }

  @override
  bool shouldRepaint(covariant _WardVectorGisPainter oldDelegate) {
    return oldDelegate.isSatellite != isSatellite;
  }
}
