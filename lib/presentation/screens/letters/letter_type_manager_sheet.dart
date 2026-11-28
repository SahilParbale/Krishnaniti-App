import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/letter_type_model.dart';
import '../../../data/repositories/letters_repository.dart';
import '../../providers/language_provider.dart';

/// Letter Type Manager Sheet / Modal matching LetterTypeManager.tsx 100% on desktop,
/// while preserving the mobile bottom-sheet presentation for mobile screens.
class LetterTypeManagerSheet extends ConsumerStatefulWidget {
  final bool? isDesktop;

  const LetterTypeManagerSheet({super.key, this.isDesktop});

  static Future<void> show(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    if (isWide) {
      return showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: const LetterTypeManagerSheet(isDesktop: true),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const LetterTypeManagerSheet(isDesktop: false),
      );
    }
  }

  @override
  ConsumerState<LetterTypeManagerSheet> createState() => _LetterTypeManagerSheetState();
}

class _LetterTypeManagerSheetState extends ConsumerState<LetterTypeManagerSheet> {
  bool _isLoading = true;
  List<LetterTypeModel> _types = [];

  @override
  void initState() {
    super.initState();
    _fetchTypes();
  }

  Future<void> _fetchTypes() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(lettersRepoProvider);
      final list = await repo.getLetterTypes();
      if (mounted) {
        setState(() {
          _types = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _checkIsDesktop(BuildContext context) {
    return widget.isDesktop ?? (MediaQuery.of(context).size.width >= 768);
  }

  // --- Add / Edit Modal (matching LetterTypeManager.tsx lines 242-360) ---
  void _showEditModal({LetterTypeModel? existingType}) {
    final lang = ref.read(appLanguageProvider);
    final isDesktop = _checkIsDesktop(context);

    final nameCtrl = TextEditingController(text: existingType?.name ?? '');
    final nameMrCtrl = TextEditingController(text: existingType?.nameMarathi ?? '');
    final descCtrl = TextEditingController(text: existingType?.description ?? '');
    final templateCtrl = TextEditingController(
      text: existingType?.templateContent ??
          AppTranslations.pick(
            lang,
            en: 'This is to certify that Mr./Ms. {{name}}, residing at {{address}}, is a resident of Ward 12 to the best of my knowledge.\n\nThis letter is issued upon their request for the purpose of {{purpose}}.\n\nI wish them all the best for their future endeavors.',
            mr: 'प्रमाणित करण्यात येते की, श्री/श्रीमती {{name}}, रा. {{address}}, हे प्रभाग क्र. १२ मधील रहिवासी आहेत.\n\nसदर पत्र त्यांच्या विनंतीनुसार {{purpose}} या कारणास्तव देण्यात येत आहे.\n\nत्यांच्या भावी वाटचालीस मनःपूर्वक शुभेच्छा.',
            hi: 'प्रमाणित किया जाता है कि श्री/श्रीमती {{name}}, निवासी {{address}}, मेरी जानकारी के अनुसार वार्ड क्र. १२ के निवासी हैं।\n\nयह पत्र उनके अनुरोध पर {{purpose}} के उद्देश्य से जारी किया जा रहा है।\n\nउनके उज्ज्वल भविष्य के लिए हार्दिक शुभकामनाएँ।',
          ),
    );

    if (isDesktop) {
      // Desktop Dialog (Matching LetterTypeManager.tsx lines 242-360 verbatim)
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (dialogCtx) {
          bool isSubmitting = false;
          return StatefulBuilder(
            builder: (ctx, setDlgState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: Container(
                  width: 660,
                  constraints: const BoxConstraints(maxHeight: 720),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              existingType != null
                                  ? AppTranslations.pick(
                                      lang,
                                      en: 'Edit Letter Type',
                                      mr: 'पत्राचा प्रकार संपादित करा',
                                      hi: 'पत्र प्रकार संपादित करें',
                                    )
                                  : AppTranslations.pick(
                                      lang,
                                      en: 'Add New Letter Type',
                                      mr: 'नवीन पत्र प्रकार जोडा',
                                      hi: 'नया पत्र प्रकार जोड़ें',
                                    ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                              onPressed: () => Navigator.pop(dialogCtx),
                              tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                            ),
                          ],
                        ),
                      ),

                      // Form Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 2-Column Row for Name (English) and Name (Marathi)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Name (English) *',
                                            mr: 'नाव (इंग्रजी) *',
                                            hi: 'नाम (अंग्रेज़ी) *',
                                          ),
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: nameCtrl,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            hintText: AppTranslations.pick(
                                              lang,
                                              en: 'e.g. Character Certificate',
                                              mr: 'उदा. Character Certificate',
                                              hi: 'उदा. Character Certificate',
                                            ),
                                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Name (Marathi)',
                                            mr: 'नाव (मराठी)',
                                            hi: 'नाम (मराठी)',
                                          ),
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: nameMrCtrl,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            hintText: AppTranslations.pick(
                                              lang,
                                              en: 'e.g. चारित्र्य दाखला',
                                              mr: 'उदा. चारित्र्य दाखला',
                                              hi: 'उदा. चारित्र्य दाखला',
                                            ),
                                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
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
                                AppTranslations.pick(lang, en: 'Description', mr: 'वर्णन', hi: 'विवरण'),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: descCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'Brief description of the letter purpose...',
                                    mr: 'पत्राबद्दल थोडक्यात माहिती...',
                                    hi: 'पत्र के उद्देश्य का संक्षिप्त विवरण...',
                                  ),
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Template Content with Placeholders Guidance
                              Row(
                                children: [
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Template Content',
                                      mr: 'साचा मजकूर (Template Content)',
                                      hi: 'टेम्पलेट सामग्री',
                                    ),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'PDF Body Text',
                                        mr: 'PDF मुख्य मजकूर',
                                        hi: 'PDF मुख्य पाठ',
                                      ),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: templateCtrl,
                                maxLines: 6,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.5),
                                decoration: InputDecoration(
                                  hintText: AppTranslations.pick(
                                    lang,
                                    en: 'Enter the body of the letter here...',
                                    mr: 'पत्राचा मुख्य मजकूर येथे लिहा...',
                                    hi: 'पत्र की मुख्य सामग्री यहाँ दर्ज करें...',
                                  ),
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.all(14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Placeholder Guidance Box (matching LetterTypeManager.tsx lines 320-330)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBAE6FD)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Available Placeholders:',
                                        mr: 'वापरण्यायोग्य प्लेसहोल्डर्स (Placeholders):',
                                        hi: 'उपलब्ध प्लेसहोल्डर:',
                                      ),
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _buildPlaceholderPill('{{name}}', AppTranslations.pick(lang, en: 'Name', mr: 'नाव', hi: 'नाम')),
                                        _buildPlaceholderPill('{{address}}', AppTranslations.pick(lang, en: 'Address', mr: 'पत्ता', hi: 'पता')),
                                        _buildPlaceholderPill('{{purpose}}', AppTranslations.pick(lang, en: 'Purpose', mr: 'उद्देश', hi: 'उद्देश्य')),
                                        _buildPlaceholderPill('{{date}}', AppTranslations.pick(lang, en: 'Date', mr: 'तारीख', hi: 'तिथि')),
                                        _buildPlaceholderPill('{{age}}', AppTranslations.pick(lang, en: 'Age', mr: 'वय', hi: 'आयु')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer Actions
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              child: Text(
                                AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final name = nameCtrl.text.trim();
                                      if (name.isEmpty) {
                                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppTranslations.pick(
                                                lang,
                                                en: 'Name is required',
                                                mr: 'कृपया नाव प्रविष्ट करा',
                                                hi: 'कृपया नाम दर्ज करें',
                                              ),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setDlgState(() => isSubmitting = true);
                                      final repo = ref.read(lettersRepoProvider);

                                      if (existingType != null) {
                                        final updated = existingType.copyWith(
                                          name: name,
                                          nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : null,
                                          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                                          templateContent: templateCtrl.text.trim().isNotEmpty ? templateCtrl.text.trim() : null,
                                        );
                                        await repo.updateLetterType(updated);
                                      } else {
                                        await repo.createLetterType(
                                          name: name,
                                          nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : null,
                                          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                                          templateContent: templateCtrl.text.trim().isNotEmpty ? templateCtrl.text.trim() : null,
                                        );
                                      }

                                      if (dialogCtx.mounted) {
                                        Navigator.pop(dialogCtx);
                                      }
                                      if (mounted) {
                                        _fetchTypes();
                                      }
                                    },
                              icon: const Icon(Icons.save_outlined, size: 16),
                              label: isSubmitting
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Save Changes',
                                        mr: 'बदल जतन करा',
                                        hi: 'परिवर्तन सहेजें',
                                      ),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
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
      return;
    }

    // Mobile View Dialog (Preserved as present)
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                existingType != null
                    ? AppTranslations.pick(
                        lang,
                        en: 'Edit Letter Type',
                        mr: 'पत्राचा प्रकार संपादित करा',
                        hi: 'पत्र प्रकार संपादित करें',
                      )
                    : AppTranslations.pick(
                        lang,
                        en: 'Add New Letter Type',
                        mr: 'नवीन पत्र प्रकार जोडा',
                        hi: 'नया पत्र प्रकार जोड़ें',
                      ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Type Name (English) *',
                        mr: 'इंग्रजी नाव *',
                        hi: 'प्रकार नाम (अंग्रेज़ी) *',
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. Residential Certificate',
                          mr: 'उदा. Residential Certificate',
                          hi: 'उदा. Residential Certificate',
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Type Name (Marathi)',
                        mr: 'मराठी नाव',
                        hi: 'प्रकार नाम (मराठी)',
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameMrCtrl,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'e.g. रहिवासी दाखला',
                          mr: 'उदा. रहिवासी दाखला',
                          hi: 'उदा. रहिवासी दाखला',
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.pick(lang, en: 'Description', mr: 'वर्णन', hi: 'विवरण'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Brief description',
                          mr: 'थोडक्यात माहिती',
                          hi: 'संक्षिप्त विवरण',
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Template Content',
                        mr: 'पत्र मजकूर साचा (Template)',
                        hi: 'टेम्पलेट सामग्री',
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: templateCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.pick(
                                    lang,
                                    en: 'Name is required',
                                    mr: 'कृपया नाव प्रविष्ट करा',
                                    hi: 'कृपया नाम दर्ज करें',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          setDlgState(() => isSubmitting = true);
                          final repo = ref.read(lettersRepoProvider);

                          if (existingType != null) {
                            final updated = existingType.copyWith(
                              name: name,
                              nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : null,
                              description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                              templateContent: templateCtrl.text.trim().isNotEmpty ? templateCtrl.text.trim() : null,
                            );
                            await repo.updateLetterType(updated);
                          } else {
                            await repo.createLetterType(
                              name: name,
                              nameMarathi: nameMrCtrl.text.trim().isNotEmpty ? nameMrCtrl.text.trim() : null,
                              description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                              templateContent: templateCtrl.text.trim().isNotEmpty ? templateCtrl.text.trim() : null,
                            );
                          }

                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (mounted) {
                            _fetchTypes();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(AppTranslations.pick(lang, en: 'Save', mr: 'सेव्ह करा', hi: 'सहेजें')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholderPill(String code, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Text(
        '$code - $desc',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: Color(0xFF0369A1)),
      ),
    );
  }

  // --- Delete Modal (matching LetterTypeManager.tsx lines 363-395) ---
  Future<void> _deleteType(LetterTypeModel type) async {
    final lang = ref.read(appLanguageProvider);
    final isDesktop = _checkIsDesktop(context);

    bool? confirm;
    if (isDesktop) {
      confirm = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Delete Letter Type?',
                    mr: 'पत्राचा प्रकार हटवायचा का?',
                    hi: 'पत्र प्रकार हटाएँ?',
                  ),
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                AppTranslatedText(
                  AppTranslations.pick(
                    lang,
                    en: 'Are you sure you want to delete "${type.name}"? This action cannot be undone.',
                    mr: '"${type.name}" हा प्रकार कायमचा काढला जाईल. ही कृती पूर्ववत केली जाऊ शकत नाही.',
                    hi: 'क्या आप वाकई "${type.name}" को हटाना चाहते हैं? यह कार्रवाई पूर्ववत नहीं की जा सकती।',
                  ),
                  targetLanguage: lang,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: Text(
                          AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                          style: const TextStyle(color: Color(0xFF475569)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        child: Text(
                          AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Mobile alert dialog preserved as present
      confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            AppTranslations.pick(
              lang,
              en: 'Delete Letter Type?',
              mr: 'प्रकार हटवायचा का?',
              hi: 'पत्र प्रकार हटाएँ?',
            ),
          ),
          content: AppTranslatedText(
            AppTranslations.pick(
              lang,
              en: 'Are you sure you want to delete ${type.name}?',
              mr: '${type.name} हा प्रकार कायमचा काढला जाईल.',
              hi: 'क्या आप वाकई ${type.name} को हटाना चाहते हैं?',
            ),
            targetLanguage: lang,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द', hi: 'रद्द करें')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ')),
            ),
          ],
        ),
      );
    }

    if (confirm == true) {
      final repo = ref.read(lettersRepoProvider);
      await repo.deleteLetterType(type.id);
      _fetchTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isDesktop = _checkIsDesktop(context);

    // --- Desktop Layout (matching LetterTypeManager.tsx 100%) ---
    if (isDesktop) {
      return Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 740),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Letter Types Manager',
                              mr: 'पत्रांचे प्रकार व्यवस्थापन',
                              hi: 'पत्र प्रकार प्रबंधन',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Synchronized with Supabase DB',
                              mr: 'Supabase DB (letter_types) शी जोडलेले',
                              hi: 'Supabase DB से सिंक किया गया',
                            ),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showEditModal(),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Add New Type',
                            mr: 'नवीन प्रकार जोडा',
                            hi: 'नया प्रकार जोड़ें',
                          ),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                        onPressed: () => Navigator.pop(context),
                        tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Table (matching LetterTypeManager.tsx lines 180-238)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _types.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 10),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'No custom letter types found',
                                  mr: 'कोणतेही प्रकार आढळले नाहीत',
                                  hi: 'कोई कस्टम पत्र प्रकार नहीं मिला',
                                ),
                                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              horizontalMargin: 20,
                              columnSpacing: 24,
                              columns: [
                                DataColumn(
                                  label: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Type Name (English)',
                                      mr: 'प्रकार नाव (इंग्रजी)',
                                      hi: 'प्रकार नाम (अंग्रेज़ी)',
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF475569)),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Type Name (Marathi)',
                                      mr: 'प्रकार नाव (मराठी)',
                                      hi: 'प्रकार नाम (मराठी)',
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF475569)),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppTranslations.pick(lang, en: 'Template', mr: 'साचा', hi: 'टेम्पलेट'),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF475569)),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppTranslations.pick(lang, en: 'Actions', mr: 'कृती', hi: 'कार्रवाई'),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                              rows: _types.map((type) {
                                final hasTemplate = type.templateContent != null && type.templateContent!.trim().isNotEmpty;
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      AppTranslatedText(
                                        type.name,
                                        targetLanguage: lang,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    DataCell(
                                      AppTranslatedText(
                                        type.nameMarathi ?? '-',
                                        targetLanguage: lang,
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: hasTemplate ? const Color(0xFFF0FDF4) : const Color(0xFFFEFCE8),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: hasTemplate ? const Color(0xFFBBF7D0) : const Color(0xFFFEF08A)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(hasTemplate ? Icons.check_circle_rounded : Icons.info_outline_rounded, size: 12, color: hasTemplate ? const Color(0xFF16A34A) : const Color(0xFFCA8A04)),
                                            const SizedBox(width: 4),
                                            Text(
                                              hasTemplate
                                                  ? AppTranslations.pick(lang, en: 'Yes', mr: 'होय', hi: 'हाँ')
                                                  : AppTranslations.pick(lang, en: 'No', mr: 'नाही', hi: 'नहीं'),
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hasTemplate ? const Color(0xFF16A34A) : const Color(0xFFCA8A04)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                                            tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                                            onPressed: () => _showEditModal(existingType: type),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                                            tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ'),
                                            onPressed: () => _deleteType(type),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      );
    }

    // --- Mobile Bottom Sheet Layout (Preserved exactly as present) ---
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Letter Types Manager',
                          mr: 'पत्रांचे प्रकार व्यवस्थापन',
                          hi: 'पत्र प्रकार प्रबंधन',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Synchronized with Supabase DB',
                          mr: 'Supabase DB (letter_types) शी जोडलेले',
                          hi: 'Supabase DB से सिंक किया गया',
                        ),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  tooltip: AppTranslations.pick(lang, en: 'Close', mr: 'बंद करा', hi: 'बंद करें'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Action Bar (+ Add New)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => _showEditModal(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  AppTranslations.pick(
                    lang,
                    en: 'Add New Letter Type',
                    mr: 'नवीन पत्र प्रकार जोडा',
                    hi: 'नया पत्र प्रकार जोड़ें',
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),

          // Types List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _types.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'No custom letter types found',
                                mr: 'कोणतेही प्रकार आढळले नाहीत',
                                hi: 'कोई कस्टम पत्र प्रकार नहीं मिला',
                              ),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Standard defaults are currently active',
                                mr: 'सिस्टीमचे डीफॉल्ट प्रकार वापरले जात आहेत',
                                hi: 'मानक डिफ़ॉल्ट प्रकार वर्तमान में सक्रिय हैं',
                              ),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _types.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _types[index];
                          final primaryLabel = lang == 'mr' && item.nameMarathi?.isNotEmpty == true
                              ? item.nameMarathi!
                              : item.name;
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              dense: true,
                              title: AppTranslatedText(
                                primaryLabel,
                                targetLanguage: lang,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              subtitle: item.description != null && item.description!.isNotEmpty
                                  ? AppTranslatedText(
                                      item.description!,
                                      targetLanguage: lang,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    )
                                  : (item.nameMarathi != null
                                      ? AppTranslatedText(
                                          item.name,
                                          targetLanguage: lang,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        )
                                      : null),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                                    tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                                    onPressed: () => _showEditModal(existingType: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                    tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएँ'),
                                    onPressed: () => _deleteType(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
