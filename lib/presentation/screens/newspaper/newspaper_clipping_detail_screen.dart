import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/newspaper_clipping_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_image_picker.dart';
import '../../widgets/app_date_picker.dart';

class NewspaperClippingDetailScreen extends ConsumerStatefulWidget {
  final NewspaperClippingModel clipping;
  final VoidCallback? onUpdated;
  final VoidCallback? onDeleted;

  const NewspaperClippingDetailScreen({
    super.key,
    required this.clipping,
    this.onUpdated,
    this.onDeleted,
  });

  @override
  ConsumerState<NewspaperClippingDetailScreen> createState() =>
      _NewspaperClippingDetailScreenState();
}

class _NewspaperClippingDetailScreenState
    extends ConsumerState<NewspaperClippingDetailScreen> {
  late NewspaperClippingModel _clipping;
  bool _showOriginalEnglish = false;

  @override
  void initState() {
    super.initState();
    _clipping = widget.clipping;
  }

  Future<void> _copySummary() async {
    final lang = ref.read(appLanguageProvider);
    final rawTitle =
        _showOriginalEnglish ? _clipping.title : _clipping.titleFor(lang);
    final rawDesc = _showOriginalEnglish
        ? _clipping.description
        : _clipping.descriptionFor(lang);
    final trTitle = _showOriginalEnglish
        ? rawTitle
        : await DynamicTranslationService.translateOrRaw(rawTitle, lang);
    final trDesc = _showOriginalEnglish
        ? rawDesc
        : await DynamicTranslationService.translateOrRaw(rawDesc, lang);
    final text =
        '${_clipping.newspaper} (${AppTranslations.formatDigits(_clipping.date, lang)})\n$trTitle\n\n$trDesc';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.pick(
            lang,
            en: 'News clipping summary copied to clipboard!',
            mr: 'वृत्तपत्र कात्रण सारांश क्लिपबोर्डवर कॉपी केला!',
            hi: 'समाचार पत्र कतरन सारांश क्लिपबोर्ड पर कॉपी किया गया!',
          ),
        ),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  void _showDeleteDialog() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Delete Clipping',
                    mr: 'कात्रण हटवा',
                    hi: 'कतरन हटाएं',
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Are you sure you want to delete this clipping from ${_clipping.newspaper}?',
              mr: 'तुम्हाला ${_clipping.newspaper} मधील हे कात्रण कायमचे हटवायचे आहे का?',
              hi: 'क्या आप वाकई ${_clipping.newspaper} की यह कतरन हटाना चाहते हैं?',
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                widget.onDeleted?.call();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Newspaper clipping deleted successfully.',
                        mr: 'वृत्तपत्र कात्रण यशस्वीरित्या हटवले.',
                        hi: 'समाचार पत्र कतरन सफलतापूर्वक हटाई गई।',
                      ),
                    ),
                  ),
                );
              },
              child: Text(
                AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditModal() {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController(
        text: _clipping.titleMarathi.isNotEmpty
            ? _clipping.titleMarathi
            : _clipping.title);
    final descCtrl = TextEditingController(
        text: _clipping.descriptionMarathi.isNotEmpty
            ? _clipping.descriptionMarathi
            : _clipping.description);
    final urlCtrl = TextEditingController(
        text: _clipping.imageUrl.startsWith('http') ? _clipping.imageUrl : '');
    String sentiment = _clipping.sentiment;
    DateTime selectedDate = DateTime.tryParse(_clipping.date) ?? DateTime.now();
    XFile? pickedImage = (!_clipping.imageUrl.startsWith('http') &&
            _clipping.imageUrl.isNotEmpty)
        ? XFile(_clipping.imageUrl)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final dateStorage =
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
            final dateDisplay =
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
                  AppModalHeader(
                    icon: Icons.newspaper_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Edit Clipping',
                      mr: 'वृत्तपत्र कात्रण संपादन',
                      hi: 'समाचार कतरन संपादित करें',
                    ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Update clipping information & details',
                      mr: 'कात्रण माहिती व तपशील अद्यतनित करा',
                      hi: 'कतरन की जानकारी व विवरण अपडेट करें',
                    ),
                    onClose: () => Navigator.pop(ctx),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 16,
                        bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                      ),
                      children: [
                        // 1 & 2: Type & Date side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'News Type',
                                      mr: 'बातमी स्वरूप (प्रकार)',
                                      hi: 'समाचार प्रकार',
                                    ),
                                    isRequired: true,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setModalState(
                                              () => sentiment = 'positive'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10.5),
                                            decoration: BoxDecoration(
                                              color: sentiment == 'positive'
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: sentiment == 'positive'
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              AppTranslations.pick(
                                                lang,
                                                en: 'Positive',
                                                mr: 'सकारात्मक',
                                                hi: 'सकारात्मक',
                                              ),
                                              style: TextStyle(
                                                color: sentiment == 'positive'
                                                    ? Colors.white
                                                    : const Color(0xFF334155),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setModalState(
                                              () => sentiment = 'negative'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10.5),
                                            decoration: BoxDecoration(
                                              color: sentiment == 'negative'
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: sentiment == 'negative'
                                                    ? const Color(0xFFDC2626)
                                                    : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              AppTranslations.pick(
                                                lang,
                                                en: 'Negative',
                                                mr: 'नकारात्मक',
                                                hi: 'नकारात्मक',
                                              ),
                                              style: TextStyle(
                                                color: sentiment == 'negative'
                                                    ? Colors.white
                                                    : const Color(0xFF334155),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel(
                                    label: AppTranslations.pick(
                                      lang,
                                      en: 'Date',
                                      mr: 'तारीख',
                                      hi: 'दिनांक',
                                    ),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFCBD5E1),
                                            width: 1.0),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 16,
                                              color: Color(0xFF0284C7)),
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

                        // 3. Title
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'News Headline',
                            mr: 'बातमी शीर्षक',
                            hi: 'समाचार शीर्षक',
                          ),
                          isRequired: true,
                        ),
                        TextField(
                          controller: titleCtrl,
                          decoration: appInputDecoration(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'e.g. Road asphalting in Prabhag 12...',
                              mr: 'उदा. प्रभाग १२ मध्ये रस्त्याचे डांबरीकरण...',
                              hi: 'उदा. वार्ड १२ में सड़क डामरीकरण...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Image Picker (Camera & Storage)
                        AppImagePickerField(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Clipping Photo (Camera & Storage)',
                            mr: 'कात्रण फोटो (कॅमेरा व मोबाइल स्टोरेज)',
                            hi: 'कतरन फ़ोटो (कैमरा व स्टोरेज)',
                          ),
                          isRequired: false,
                          isMarathi: lang == 'mr',
                          initialFiles:
                              pickedImage != null ? [pickedImage!] : [],
                          onFilesChanged: (files) {
                            setModalState(() {
                              pickedImage =
                                  files.isNotEmpty ? files.first : null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // 5. URL
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'News Web URL',
                            mr: 'बातमी लिंक / वेब URL',
                            hi: 'समाचार वेब URL',
                          ),
                          isRequired: false,
                          optionalHint: AppTranslations.pick(
                            lang,
                            en: 'Optional',
                            mr: 'ऐच्छिक',
                            hi: 'वैकल्पिक',
                          ),
                        ),
                        TextField(
                          controller: urlCtrl,
                          keyboardType: TextInputType.url,
                          decoration: appInputDecoration(
                            hint: 'https://example.com/news-article...',
                            prefixIcon: const Icon(Icons.link_rounded,
                                size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 6. Description
                        AppFieldLabel(
                          label: AppTranslations.pick(
                            lang,
                            en: 'Article Description / Summary',
                            mr: 'बातमीचा तपशील / गोषवारा',
                            hi: 'समाचार विवरण / सारांश',
                          ),
                          isRequired: false,
                          optionalHint: AppTranslations.pick(
                            lang,
                            en: 'Optional',
                            mr: 'ऐच्छिक',
                            hi: 'वैकल्पिक',
                          ),
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: appInputDecoration(
                            hint: AppTranslations.pick(
                              lang,
                              en: 'Brief summary of the news...',
                              mr: 'बातमीचा संक्षिप्त गोषवारा...',
                              hi: 'समाचार का संक्षिप्त सारांश...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final text = titleCtrl.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Please enter news headline',
                                        mr: 'कृपया बातमी शीर्षक प्रविष्ट करा',
                                        hi: 'कृपया समाचार शीर्षक दर्ज करें',
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }
                              final updated = _clipping.copyWith(
                                titleMarathi: text,
                                title: text,
                                descriptionMarathi: descCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                date: dateStorage,
                                sentiment: sentiment,
                                imageUrl: pickedImage != null
                                    ? pickedImage!.path
                                    : (urlCtrl.text.trim().isNotEmpty
                                        ? urlCtrl.text.trim()
                                        : _clipping.imageUrl),
                              );
                              setState(() => _clipping = updated);
                              widget.onUpdated?.call();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Clipping updated successfully!',
                                      mr: 'कात्रण यशस्वीरित्या अद्यतनित केले!',
                                      hi: 'कतरन सफलतापूर्वक अपडेट की गई!',
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                            },
                            child: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Save Changes',
                                mr: 'बदल जतन करा',
                                hi: 'बदलाव सहेजें',
                              ),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
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
    final headlineText =
        _showOriginalEnglish ? _clipping.title : _clipping.titleFor(lang);
    final descText = _showOriginalEnglish
        ? _clipping.description
        : _clipping.descriptionFor(lang);
    final dateDisplay = AppTranslations.formatDigits(_clipping.date, lang);

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: AppTranslations.pick(lang, en: 'Back', mr: 'मागे', hi: 'वापस'),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Newspaper Clipping Details',
                  mr: 'वृत्तपत्र कात्रण तपशील',
                  hi: 'समाचार पत्र कतरन विवरण',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${_clipping.newspaper} • $dateDisplay',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: Colors.white, size: 20),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Copy Summary',
                mr: 'सारांश कॉपी करा',
                hi: 'सारांश कॉपी करें',
              ),
              onPressed: _copySummary,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 20),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Edit Clipping',
                mr: 'कात्रण संपादित करा',
                hi: 'कतरन संपादित करें',
              ),
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 20),
              tooltip: AppTranslations.pick(
                lang,
                en: 'Delete Clipping',
                mr: 'कात्रण हटवा',
                hi: 'कतरन हटाएं',
              ),
              onPressed: _showDeleteDialog,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Media Clipping Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // High-Res Image Preview
                    Stack(
                      children: [
                        _buildClippingImage(lang),
                        // Sentiment Badge Top Left
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _clipping.sentimentBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _clipping.sentimentColor, width: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                    radius: 4,
                                    backgroundColor: _clipping.sentimentColor),
                                const SizedBox(width: 5),
                                Text(
                                  _clipping.sentimentLabel(lang),
                                  style: TextStyle(
                                    color: _clipping.sentimentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Date Badge Top Right
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dateDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Publication Metadata Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFE2E8F0), width: 0.8)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _clipping.newspaperBrandColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: AppTranslatedText(
                              _clipping.newspaper,
                              targetLanguage: lang,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTranslatedText(
                              '${_clipping.edition} • ${_clipping.pageNumber}',
                              targetLanguage: lang,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_clipping.journalistName != null)
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline_rounded,
                                      size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: AppTranslatedText(
                                      _clipping.journalistName!,
                                      targetLanguage: lang,
                                      isName: true,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Content Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Language Switcher Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Headline & Article',
                                  mr: 'शीर्षक आणि बातमी',
                                  hi: 'शीर्षक और समाचार',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _showOriginalEnglish = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: !_showOriginalEnglish
                                              ? const Color(0xFF0284C7)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Translated',
                                            mr: 'मराठी',
                                            hi: 'हिंदी',
                                          ),
                                          style: TextStyle(
                                            color: !_showOriginalEnglish
                                                ? Colors.white
                                                : const Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _showOriginalEnglish = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _showOriginalEnglish
                                              ? const Color(0xFF0284C7)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Original',
                                            mr: 'इंग्रजी / मूळ',
                                            hi: 'अंग्रेज़ी / मूल',
                                          ),
                                          style: TextStyle(
                                            color: _showOriginalEnglish
                                                ? Colors.white
                                                : const Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Headline
                          _showOriginalEnglish
                              ? Text(
                                  headlineText,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1.45,
                                    color: Color(0xFF0F172A),
                                  ),
                                )
                              : AppTranslatedText(
                                  headlineText,
                                  targetLanguage: lang,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1.45,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                          const SizedBox(height: 12),

                          // Description
                          _showOriginalEnglish
                              ? Text(
                                  descText,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.6,
                                    color: Color(0xFF334155),
                                  ),
                                )
                              : AppTranslatedText(
                                  descText,
                                  targetLanguage: lang,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.6,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Civic Action Taken Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _clipping.isPositive
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFECACA),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
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
                            color: _clipping.isPositive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _clipping.isPositive
                                ? Icons.task_alt_rounded
                                : Icons.published_with_changes_rounded,
                            size: 16,
                            color: _clipping.sentimentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _clipping.isPositive
                              ? AppTranslations.pick(
                                  lang,
                                  en: 'Development Milestone',
                                  mr: 'विकास टप्पा',
                                  hi: 'विकास उपलब्धि',
                                )
                              : AppTranslations.pick(
                                  lang,
                                  en: 'Civic Action Taken',
                                  mr: 'केलेली नागरी कार्यवाही',
                                  hi: 'की गई नागरिक कार्रवाई',
                                ),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _clipping.sentimentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _clipping.actionTaken != null
                        ? AppTranslatedText(
                            _clipping.actionTaken!,
                            targetLanguage: lang,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: Color(0xFF1E293B),
                            ),
                          )
                        : Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Conducted inspection with municipal engineers and resolved the civic issue.',
                              mr: 'महापालिका अभियंत्यांसमवेत पाहणी करून नागरी समस्या सोडविली.',
                              hi: 'नगर निगम अभियंताओं के साथ निरीक्षण कर नागरिक समस्या का समाधान किया।',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Share / Export Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Share Summary',
                          mr: 'सारांश शेअर करा',
                          hi: 'सारांश साझा करें',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _copySummary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClippingImage(String lang) {
    Widget placeholder() => Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.newspaper_rounded,
                  size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              AppTranslatedText(
                '${_clipping.newspaper} ${AppTranslations.pick(lang, en: 'Press Clipping', mr: 'वृत्तपत्र कात्रण', hi: 'समाचार कतरन')}',
                targetLanguage: lang,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        );

    if (_clipping.imageUrl.startsWith('http://') ||
        _clipping.imageUrl.startsWith('https://')) {
      return Image.network(
        _clipping.imageUrl,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => placeholder(),
      );
    }
    try {
      final file = File(_clipping.imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => placeholder(),
        );
      }
    } catch (_) {}
    return placeholder();
  }
}

