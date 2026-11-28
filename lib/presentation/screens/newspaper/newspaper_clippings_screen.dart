import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/newspaper_clipping_model.dart';
import '../../../data/repositories/newspaper_clippings_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_image_picker.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'newspaper_clipping_detail_screen.dart';
import 'newspaper_report_generator.dart';

class NewspaperClippingsScreen extends ConsumerStatefulWidget {
  const NewspaperClippingsScreen({super.key});

  @override
  ConsumerState<NewspaperClippingsScreen> createState() =>
      _NewspaperClippingsScreenState();
}

class _NewspaperClippingsScreenState
    extends ConsumerState<NewspaperClippingsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _activeSentiment = 'all'; // 'all' | 'positive' | 'negative'
  String _selectedNewspaper = 'All'; // 'All' | 'Sakal' | 'Lokmat' | ...
  String _filterDate = '';
  String _viewMode = 'grid'; // 'grid' | 'table'
  int _displayedLimit = 20;

  bool _isLoading = true;
  List<NewspaperClippingModel> _allClippings = [];

  List<NewspaperClippingModel> get _visibleClippings =>
      _filteredClippings.take(_displayedLimit).toList();

  final List<String> _newspapers = [
    'All',
    'Sakal',
    'Lokmat',
    'Maharashtra Times',
    'Pudhari',
    'Loksatta',
    'The Indian Express',
  ];

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
    final repo = ref.read(newspaperClippingsRepoProvider);
    final items = await repo.getClippings();
    if (mounted) {
      setState(() {
        _allClippings = items;
        _isLoading = false;
        _displayedLimit = 20;
      });
    }
  }

  List<NewspaperClippingModel> get _filteredClippings {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allClippings.where((c) {
      // Sentiment tab filter
      if (_activeSentiment == 'positive' && !c.isPositive) return false;
      if (_activeSentiment == 'negative' && c.isPositive) return false;

      // Newspaper publication filter
      if (_selectedNewspaper != 'All' &&
          c.newspaper.toLowerCase() != _selectedNewspaper.toLowerCase()) {
        return false;
      }

      // Date filter
      if (_filterDate.isNotEmpty && c.date != _filterDate) {
        return false;
      }

      // Search query
      if (query.isNotEmpty) {
        final titleEnMatch = c.title.toLowerCase().contains(query);
        final titleMrMatch = c.titleMarathi.toLowerCase().contains(query);
        final descEnMatch = c.description.toLowerCase().contains(query);
        final descMrMatch = c.descriptionMarathi.toLowerCase().contains(query);
        final paperMatch = c.newspaper.toLowerCase().contains(query);
        final actionMatch =
            c.actionTaken?.toLowerCase().contains(query) ?? false;
        final journalistMatch =
            c.journalistName?.toLowerCase().contains(query) ?? false;

        if (!titleEnMatch &&
            !titleMrMatch &&
            !descEnMatch &&
            !descMrMatch &&
            !paperMatch &&
            !actionMatch &&
            !journalistMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showHelpTutorial() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Newspaper Clipping Guide',
                    mr: 'वृत्तपत्र कात्रण मार्गदर्शक',
                    hi: 'समाचार पत्र कतरन मार्गदर्शिका',
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
                    en: 'Newspaper Clippings & Media Monitoring Guide',
                    mr: 'वृत्तपत्र कात्रणे व माध्यम निरीक्षण मार्गदर्शक',
                    hi: 'समाचार पत्र कतरन व मीडिया निगरानी मार्गदर्शिका',
                  ),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0284C7)),
                ),
                const SizedBox(height: 10),
                _GuideStep(
                  number: AppTranslations.formatDigits('1', lang),
                  title: AppTranslations.pick(
                    lang,
                    en: 'Coverage Categories',
                    mr: 'कव्हरेज प्रकार',
                    hi: 'कवरेज श्रेणियाँ',
                  ),
                  desc: AppTranslations.pick(
                    lang,
                    en: 'Switch between "Positive" and "Negative" to track public appreciation versus critical issues requiring municipal resolution.',
                    mr: 'लोकाभिमुख कौतुक आणि महापालिका कार्यवाही आवश्यक असलेल्या समस्यांचा मागोवा घेण्यासाठी सकारात्मक/नकारात्मक निवडा.',
                    hi: 'जन प्रशंसा व नगर निगम समाधान आवश्यक महत्वपूर्ण मुद्दों को ट्रैक करने के लिए सकारात्मक/नकारात्मक बदलें।',
                  ),
                ),
                _GuideStep(
                  number: AppTranslations.formatDigits('2', lang),
                  title: AppTranslations.pick(
                    lang,
                    en: 'Add New Clipping',
                    mr: 'नवीन कात्रण जोडा',
                    hi: 'नई कतरन जोड़ें',
                  ),
                  desc: AppTranslations.pick(
                    lang,
                    en: 'Upload news cutting images along with headline, page number, edition, and civic action taken report.',
                    mr: 'मथळा, पान क्रमांक, आवृत्ती आणि नागरी कार्यवाहीच्या माहितीसह बातमीचे कात्रण अपलोड करा.',
                    hi: 'शीर्षक, पृष्ठ संख्या, संस्करण व नागरिक कार्रवाई रिपोर्ट के साथ समाचार कटिंग अपलोड करें।',
                  ),
                ),
                _GuideStep(
                  number: AppTranslations.formatDigits('3', lang),
                  title: AppTranslations.pick(
                    lang,
                    en: 'Download Report',
                    mr: 'अहवाल डाउनलोड करा',
                    hi: 'रिपोर्ट डाउनलोड करें',
                  ),
                  desc: AppTranslations.pick(
                    lang,
                    en: 'Generate landscape A4 print-ready reports with clippings ledger for ward meetings and review.',
                    mr: 'प्रभाग बैठका व आढाव्यासाठी कात्रण नोंदवहीसह लँडस्केप A4 प्रिंट-रेडी अहवाल तयार करा.',
                    hi: 'वार्ड बैठकों व समीक्षा के लिए कतरन रजिस्टर सहित लैंडस्केप A4 प्रिंट रिपोर्ट बनाएं।',
                  ),
                ),
                _GuideStep(
                  number: AppTranslations.formatDigits('4', lang),
                  title: AppTranslations.pick(
                    lang,
                    en: 'Dual Views',
                    mr: 'दुहेरी दृश्ये',
                    hi: 'दोहरे दृश्य',
                  ),
                  desc: AppTranslations.pick(
                    lang,
                    en: 'Toggle between rich visual news card grid and tabular audit report view.',
                    mr: 'व्हिज्युअल न्यूज कार्ड आणि तक्ता अहवाल स्वरूपात सहज बदला.',
                    hi: 'विज़ुअल समाचार कार्ड ग्रिड और तालिका रिपोर्ट दृश्य के बीच बदलें।',
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.pick(lang, en: 'Got it', mr: 'समजले', hi: 'समझ गया'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddClippingModal() {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String sentiment = _activeSentiment == 'negative' ? 'negative' : 'positive';
    DateTime selectedDate = DateTime.now();
    XFile? pickedImage;

    InputDecoration inputDec({String? hint, String? prefixText, Widget? prefixIcon}) {
      return InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: prefixIcon,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
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
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final String dateStorage =
                "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
            final String dateDisplay =
                AppTranslations.formatDate(selectedDate, lang, pattern: 'dd MMM yyyy');

            return Container(
              constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                    icon: Icons.newspaper_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Add Newspaper Clipping',
                      mr: 'वृत्तपत्र कात्रण जोडा',
                      hi: 'समाचार पत्र कतरन जोड़ें',
                    ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Save print media clippings with sentiment and date',
                      mr: 'बातम्यांची कात्रणे, तारीख व स्वरूप नोंदवा',
                      hi: 'तारीख व भावना के साथ प्रिंट समाचार कतरन सहेजें',
                    ),
                    onClose: () => Navigator.pop(ctx),
                  ),

                  // 2. SCROLLABLE FORM BODY & BUTTONS
                  Flexible(
              child: ListView(
                shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(
                        18,
                        14,
                        18,
                        MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                      ),
                      children: [
                        // 1 & 2: TYPE & DATE (side-by-side)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Type (Sentiment: Positive / Issue)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Type / Sentiment',
                                      mr: 'बातमी स्वरूप (प्रकार)',
                                      hi: 'समाचार प्रकार / भावना',
                                    ),
                                    isRequired: true,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setModalState(() => sentiment = 'positive'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10.5),
                                            decoration: BoxDecoration(
                                              color: sentiment == 'positive' ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: sentiment == 'positive' ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              AppTranslations.pick(lang, en: 'Positive', mr: 'सकारात्मक', hi: 'सकारात्मक'),
                                              style: TextStyle(
                                                color: sentiment == 'positive' ? Colors.white : const Color(0xFF334155),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setModalState(() => sentiment = 'negative'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10.5),
                                            decoration: BoxDecoration(
                                              color: sentiment == 'negative' ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: sentiment == 'negative' ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              AppTranslations.pick(lang, en: 'Negative', mr: 'नकारात्मक', hi: 'नकारात्मक'),
                                              style: TextStyle(
                                                color: sentiment == 'negative' ? Colors.white : const Color(0xFF334155),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 2. Date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(lang, en: 'Date', mr: 'तारीख', hi: 'दिनांक'),
                                    isRequired: true,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final picked = await showThemedDatePicker(
                                        context: modalCtx,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              dateDisplay,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 3. TITLE
                        AppFieldLabel(
                          label: AppTranslations.pick(lang, en: 'Title / Headline', mr: 'बातमी शीर्षक', hi: 'समाचार शीर्षक'),
                          isRequired: true,
                        ),
                        TextField(
                          controller: titleCtrl,
                          decoration: inputDec(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'e.g. Major development fund sanctioned...',
                              mr: 'उदा. प्रभाग १२ मध्ये रस्त्याचे डांबरीकरण...',
                              hi: 'उदा. वार्ड १२ में सड़क डामरीकरण...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. STANDARDIZED IMAGE FIELD (Camera & Phone Storage)
                        AppImagePickerField(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Clipping Image (Camera & Phone Storage)',
                            mr: 'कात्रण फोटो (कॅमेरा व मोबाइल स्टोरेज)',
                            hi: 'कतरन छवि (कैमरा व स्टोरेज)',
                          ),
                          isRequired: false,
                          isMarathi: lang == 'mr',
                          initialFiles: pickedImage != null ? [pickedImage!] : [],
                          onFilesChanged: (files) {
                            setModalState(() {
                              pickedImage = files.isNotEmpty ? files.first : null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // 5. URL
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Article / Web Link URL',
                            mr: 'बातमी लिंक / वेब URL',
                            hi: 'लेख / वेब लिंक URL',
                          ),
                          isRequired: false,
                          optionalHint: AppTranslations.pick(lang, en: 'Optional', mr: 'ऐच्छिक', hi: 'वैकल्पिक'),
                        ),
                        TextField(
                          controller: urlCtrl,
                          keyboardType: TextInputType.url,
                          decoration: inputDec(
                            hint: 'https://example.com/news-article...',
                            prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 6. DESCRIPTION
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Description / Article Summary',
                            mr: 'बातमीचा तपशील / गोषवारा',
                            hi: 'विवरण / समाचार सारांश',
                          ),
                          isRequired: false,
                          optionalHint: AppTranslations.pick(lang, en: 'Optional', mr: 'ऐच्छिक', hi: 'वैकल्पिक'),
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: inputDec(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Enter article description / summary...',
                              mr: 'बातम्यांचे थोडक्यात विश्लेषण किंवा तपशील...',
                              hi: 'समाचार का संक्षिप्त विवरण या सारांश दर्ज करें...',
                            ),
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
                                  AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text(
                                  AppTranslations.pick(lang, en: 'Save Clipping', mr: 'कात्रण जतन करा', hi: 'कतरन सहेजें'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                onPressed: () async {
                                  final title = titleCtrl.text.trim();
                                  if (title.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Please enter headline for clipping.',
                                            mr: 'कृपया बातमीचे शीर्षक प्रविष्ट करा',
                                            hi: 'कृपया कतरन का शीर्षक दर्ज करें।',
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final finalImageUrl = pickedImage != null
                                      ? pickedImage!.path
                                      : (urlCtrl.text.trim().isNotEmpty
                                          ? urlCtrl.text.trim()
                                          : 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80&w=800');

                                  final descText = descCtrl.text.trim();
                                  final newClip = NewspaperClippingModel(
                                    id: 'clip_${DateTime.now().millisecondsSinceEpoch}',
                                    title: title,
                                    titleMarathi: title,
                                    newspaper: 'Newspaper',
                                    date: dateStorage,
                                    sentiment: sentiment,
                                    imageUrl: finalImageUrl,
                                    pageNumber: 'Page 1',
                                    description: descText,
                                    descriptionMarathi: descText,
                                  );

                                  final repo = ref.read(newspaperClippingsRepoProvider);
                                  await repo.addClipping(newClip);
                                  if (modalCtx.mounted) {
                                    Navigator.pop(modalCtx);
                                  }
                                  _loadData();

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Newspaper clipping added successfully!',
                                            mr: 'कात्रण यशस्वीरित्या जोडले!',
                                            hi: 'समाचार कतरन सफलतापूर्वक जोड़ी गई!',
                                          ),
                                        ),
                                        backgroundColor: const Color(0xFF16A34A),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
    final filtered = _filteredClippings;
    final totalCount = _allClippings.length;
    final positiveCount = _allClippings.where((c) => c.isPositive).length;
    final negativeCount = _allClippings.where((c) => !c.isPositive).length;

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
                AppTranslations.getNavTitle('newspaper_clippings', lang),
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
                    ? 'मुद्रित बातम्या कव्हरेज आणि प्रेस नोट संग्रहण'
                    : (lang == 'hi'
                        ? 'मुद्रित समाचार कवरेज और प्रेस नोट संग्रह'
                        : 'Print news media coverage archive and press releases'),
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
            ? const AppShimmerList(count: 6)
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF0284C7),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  children: [
                    // 1) SENTIMENT TABS (Positive vs Negative News)
                    _buildSentimentTabs(
                      positiveCount: positiveCount,
                      negativeCount: negativeCount,
                      totalCount: totalCount,
                      lang: lang,
                    ),
                    const SizedBox(height: 14),


                    // 3) SEARCH & FILTER BAR
                    _buildFiltersBar(lang),
                    const SizedBox(height: 12),

                    // 4) RESULTS BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lang == 'mr'
                                ? 'एकूण ${AppTranslations.formatDigits(totalCount, lang)} पैकी ${AppTranslations.formatDigits(filtered.length, lang)} बातम्या दाखवत आहे'
                                : (lang == 'hi'
                                    ? 'कुल ${AppTranslations.formatDigits(totalCount, lang)} में से ${AppTranslations.formatDigits(filtered.length, lang)} समाचार दिखाए जा रहे हैं'
                                    : 'Showing ${filtered.length} of $totalCount clippings'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (_filterDate.isNotEmpty)
                              InkWell(
                                onTap: () => setState(() {
                                  _filterDate = '';
                                  _displayedLimit = 20;
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Row(
                                    children: [
                                      Text('${lang == 'mr' ? 'दिनांक' : (lang == 'hi' ? 'दिनांक' : 'Date')}: ${AppTranslations.formatDigits(_filterDate, lang)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF0284C7),
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.close,
                                          size: 14, color: Color(0xFF0284C7)),
                                    ],
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                _viewMode == 'grid'
                                    ? Icons.table_chart_outlined
                                    : Icons.grid_view_rounded,
                                color: const Color(0xFF0284C7),
                                size: 20,
                              ),
                              tooltip: _viewMode == 'grid'
                                  ? AppTranslations.pick(
                                      lang,
                                      en: 'Switch to Table',
                                      mr: 'तक्त्यात पहा',
                                      hi: 'तालिका में देखें',
                                    )
                                  : AppTranslations.pick(
                                      lang,
                                      en: 'Switch to Grid',
                                      mr: 'कार्ड स्वरूपात पहा',
                                      hi: 'कार्ड रूप में देखें',
                                    ),
                              onPressed: () {
                                setState(() {
                                  _viewMode = _viewMode == 'grid' ? 'table' : 'grid';
                                });
                              },
                            ),
                            AppPdfButton.icon(
                              tooltip: AppTranslations.getDownloadReport(lang),
                              onPressed: () {
                                NewspaperReportGenerator.generateAndPrintReport(
                                  clippings: filtered,
                                  sentimentFilter: _activeSentiment == 'all'
                                      ? 'All News'
                                      : (_activeSentiment == 'positive'
                                          ? 'Positive News'
                                          : 'Negative Issues'),
                                  newspaperFilter: _selectedNewspaper,
                                  lang: lang,
                                );
                              },
                            ),

                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 5) DUAL VIEW (GRID CARDS vs REPORT TABLE)
                    if (filtered.isEmpty)
                      _buildEmptyState(lang)
                    else ...[
                      if (_viewMode == 'grid')
                        ..._visibleClippings.map((item) => _buildClippingCard(item, lang))
                      else
                        _buildTableView(_visibleClippings, lang),
                      AppLoadMoreFooter(
                        currentCount: _visibleClippings.length,
                        totalCount: filtered.length,
                        pageSize: 20,
                        onLoadMore: () => setState(() => _displayedLimit += 20),
                        label: AppTranslations.pick(lang, en: 'clippings', mr: 'बातम्या', hi: 'कतरनें'),
                        isMarathi: lang == 'mr',
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: Text(
            lang == 'mr' ? 'बातमी जोडा' : (lang == 'hi' ? 'समाचार जोड़ें' : 'Add Clipping'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _showAddClippingModal,
        ),
      ),
    );
  }

  // 1) Sentiment Tabs
  Widget _buildSentimentTabs({
    required int positiveCount,
    required int negativeCount,
    required int totalCount,
    required String lang,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              id: 'all',
              label: lang == 'mr' ? 'सर्व बातम्या' : (lang == 'hi' ? 'सभी समाचार' : 'All News'),
              count: totalCount,
              activeColor: const Color(0xFF0284C7),
              lang: lang,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              id: 'positive',
              label: lang == 'mr' ? 'सकारात्मक' : (lang == 'hi' ? 'सकारात्मक' : 'Positive'),
              count: positiveCount,
              activeColor: const Color(0xFF16A34A),
              lang: lang,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              id: 'negative',
              label: lang == 'mr' ? 'नकारात्मक' : (lang == 'hi' ? 'नकारात्मक' : 'Negative'),
              count: negativeCount,
              activeColor: const Color(0xFFDC2626),
              lang: lang,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String id,
    required String label,
    required String lang,
    required int count,
    required Color activeColor,
  }) {
    final isSelected = _activeSentiment == id;

    return GestureDetector(
      onTap: () => setState(() {
        _activeSentiment = id;
        _displayedLimit = 20;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppTranslations.formatDigits(count, lang),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3) Filters Bar
  Widget _buildFiltersBar(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() => _displayedLimit = 20),
            decoration: InputDecoration(
              hintText: lang == 'mr'
                  ? 'मथळा, विषय, सकाळ, लोकमत शोधा...'
                  : (lang == 'hi'
                      ? 'शीर्षक, विषय, सकल, लोकमत खोजें...'
                      : 'Search headline, topic, Sakal, Lokmat...'),
              hintStyle:
                  const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _displayedLimit = 20);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Newspaper horizontal filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _newspapers.map((paper) {
              final isSel = _selectedNewspaper == paper;
              final count = paper == 'All'
                  ? _allClippings.length
                  : _allClippings
                      .where((c) =>
                          c.newspaper.toLowerCase() == paper.toLowerCase())
                      .length;

              final paperName = paper == 'All'
                  ? (lang == 'mr' ? 'सर्व' : (lang == 'hi' ? 'सभी' : 'All'))
                  : paper;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (paper == 'All')
                        Text(
                          paperName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF475569),
                          ),
                        )
                      else
                        AppTranslatedText(
                          paperName,
                          targetLanguage: lang,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      Text(
                        ' (${AppTranslations.formatDigits(count, lang)})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  selected: isSel,
                  selectedColor: const Color(0xFF0284C7),
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSel
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onSelected: (val) {
                    setState(() {
                      _selectedNewspaper = paper;
                      _displayedLimit = 20;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 4) Clipping Card
  Widget _buildClippingCard(NewspaperClippingModel item, String lang) {
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
              builder: (_) => NewspaperClippingDetailScreen(
                clipping: item,
                onUpdated: _loadData,
                onDeleted: _loadData,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Thumbnail
            Stack(
              children: [
                _buildClippingThumbnail(item, lang),
                // Newspaper Tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.newspaperBrandColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AppTranslatedText(
                      item.newspaper,
                      targetLanguage: lang,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Sentiment Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.sentimentBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: item.sentimentColor, width: 0.8),
                    ),
                    child: Text(
                      item.sentimentLabel(lang),
                      style: TextStyle(
                        color: item.sentimentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Date Bar
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppTranslations.formatDigits(item.date, lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content text
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTranslatedText(
                    item.titleFor(lang),
                    targetLanguage: lang,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTranslatedText(
                    item.descriptionFor(lang),
                    targetLanguage: lang,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF475569),
                    ),
                  ),
                  if (item.actionTaken != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFCBD5E1), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.isPositive
                                ? Icons.check_circle_outline_rounded
                                : Icons.report_problem_outlined,
                            size: 13,
                            color: item.sentimentColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${AppTranslations.pick(lang, en: 'Action', mr: 'कारवाई', hi: 'कार्रवाई')}: ',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: AppTranslatedText(
                              item.actionTaken!,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom bar with action link
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.pageNumber != null
                        ? '${lang == 'mr' ? 'पान' : (lang == 'hi' ? 'पृष्ठ' : 'Page')} ${AppTranslations.formatDigits(item.pageNumber!, lang)}'
                        : '${lang == 'mr' ? 'पान' : (lang == 'hi' ? 'पृष्ठ' : 'Page')} ${AppTranslations.formatDigits('3', lang)}',
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                  Row(
                    children: [
                      Text(
                        AppTranslations.getDetails(lang),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: Color(0xFF0284C7)),
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

  Widget _buildClippingThumbnail(NewspaperClippingModel item, String lang) {
    Widget placeholder() => Container(
          width: double.infinity,
          height: 140,
          color: Colors.grey.shade100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.newspaper_rounded,
                  size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 6),
              AppTranslatedText(
                item.newspaper,
                targetLanguage: lang,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        );

    if (item.imageUrl.startsWith('http://') ||
        item.imageUrl.startsWith('https://')) {
      return Image.network(
        item.imageUrl,
        width: double.infinity,
        height: 170,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => placeholder(),
      );
    }
    try {
      final file = File(item.imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          height: 170,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => placeholder(),
        );
      }
    } catch (_) {}
    return placeholder();
  }

  // 5) Report Table View
  Widget _buildTableView(List<NewspaperClippingModel> clippings, String lang) {
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
          headingTextStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A)),
          dataTextStyle:
              const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
          columns: [
            DataColumn(label: Text(lang == 'mr' ? 'दिनांक' : (lang == 'hi' ? 'दिनांक' : 'Date'))),
            DataColumn(label: Text(lang == 'mr' ? 'वर्तमानपत्र' : (lang == 'hi' ? 'समाचार पत्र' : 'Newspaper'))),
            DataColumn(label: Text(lang == 'mr' ? 'मथळा' : (lang == 'hi' ? 'शीर्षक' : 'Headline'))),
            DataColumn(label: Text(lang == 'mr' ? 'प्रकार' : (lang == 'hi' ? 'प्रकार' : 'Type'))),
            DataColumn(label: Text(lang == 'mr' ? 'कारवाई' : (lang == 'hi' ? 'कार्रवाई' : 'Action Taken'))),
            DataColumn(label: Text(lang == 'mr' ? 'कृती' : (lang == 'hi' ? 'क्रिया' : 'Action'))),
          ],
          rows: clippings.map((c) {
            return DataRow(
              cells: [
                DataCell(Text(AppTranslations.formatDigits(c.date, lang))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.newspaperBrandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: c.newspaperBrandColor, width: 0.5),
                    ),
                    child: AppTranslatedText(
                      c.newspaper,
                      targetLanguage: lang,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: c.newspaperBrandColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: AppTranslatedText(
                      c.titleFor(lang),
                      targetLanguage: lang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.sentimentBgColor,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: c.sentimentColor, width: 0.5),
                    ),
                    child: Text(
                      c.sentimentLabel(lang),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: c.sentimentColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 160,
                    child: c.actionTaken != null
                        ? AppTranslatedText(
                            c.actionTaken!,
                            targetLanguage: lang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text('-'),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Color(0xFF0284C7)),
                    tooltip: AppTranslations.getDetails(lang),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewspaperClippingDetailScreen(
                            clipping: c,
                            onUpdated: _loadData,
                            onDeleted: _loadData,
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
          const Icon(Icons.newspaper_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            lang == 'mr'
                ? 'कोणतीही वृत्तपत्र कात्रणे सापडली नाहीत'
                : (lang == 'hi'
                    ? 'कोई समाचार पत्र कतरन नहीं मिली'
                    : 'No newspaper clippings found'),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            lang == 'mr'
                ? 'श्रेणी बदलून पहा किंवा फिल्टर साफ करा.'
                : (lang == 'hi'
                    ? 'श्रेणी बदलकर देखें या फ़िल्टर साफ़ करें.'
                    : 'Try switching categories or clearing search filters.'),
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _GuideStep({
    required this.number,
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
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
