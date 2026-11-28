import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/survey_model.dart';
import '../../../data/repositories/surveys_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';

class CreateSurveyBottomSheet extends ConsumerStatefulWidget {
  final SurveyModel? surveyToEdit;

  const CreateSurveyBottomSheet({super.key, this.surveyToEdit});

  @override
  ConsumerState<CreateSurveyBottomSheet> createState() => _CreateSurveyBottomSheetState();
}

typedef CreateSurveyScreen = CreateSurveyBottomSheet;

class _CreateSurveyBottomSheetState extends ConsumerState<CreateSurveyBottomSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  String _selectedArea = 'Shaniwar Peth';

  final List<_TempQuestion> _questions = [];

  final List<String> _prabhagAreas = [
    'Shaniwar Peth',
    'Kasba Peth',
    'Narayan Peth',
    'Rasta Peth',
    'Sadashiv Peth',
    'Nana Peth',
    'Navi Peth',
    'Entire Ward 12',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.surveyToEdit != null) {
      final s = widget.surveyToEdit!;
      _titleCtrl.text = s.title;
      _descCtrl.text = s.description;
      _selectedArea = s.area ?? 'Shaniwar Peth';

      for (final q in s.questions) {
        _questions.add(_TempQuestion(
          id: q.id,
          textController: TextEditingController(text: q.text),
          type: q.type,
          options: List<String>.from(q.options),
        ));
      }
    } else {
      // Default initial question
      final lang = ref.read(appLanguageProvider);
      _questions.add(_TempQuestion(
        id: 'q1',
        textController: TextEditingController(
          text: AppTranslations.pick(
            lang,
            en: 'Did this scheme directly benefit your family?',
            mr: 'या योजनेचा तुमच्या कुटुंबाला थेट लाभ मिळाला का?',
            hi: 'क्या इस योजना का आपके परिवार को सीधा लाभ मिला?',
          ),
        ),
        type: SurveyQuestionType.yesNo,
        options: [],
      ));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final q in _questions) {
      q.textController.dispose();
    }
    super.dispose();
  }

  void _addNewQuestion() {
    setState(() {
      final nextId = 'q${_questions.length + 1}';
      _questions.add(_TempQuestion(
        id: nextId,
        textController: TextEditingController(),
        type: SurveyQuestionType.yesNo,
        options: [],
      ));
    });
  }

  void _removeQuestion(int index) {
    final lang = ref.read(appLanguageProvider);
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'At least one question is required',
              mr: 'किमान एक प्रश्न आवश्यक आहे',
              hi: 'कम से कम एक प्रश्न आवश्यक है',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _questions[index].textController.dispose();
      _questions.removeAt(index);
    });
  }

  Future<void> _saveSurvey() async {
    final lang = ref.read(appLanguageProvider);
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.pick(
              lang,
              en: 'Please enter survey title and details',
              mr: 'कृपया सर्व्हेक्षण शीर्षक आणि तपशील भरा',
              hi: 'कृपया सर्वेक्षण शीर्षक और विवरण दर्ज करें',
            ),
          ),
        ),
      );
      return;
    }

    final finalQuestions = <SurveyQuestionModel>[];
    for (int i = 0; i < _questions.length; i++) {
      final t = _questions[i].textController.text.trim();
      if (t.isEmpty) {
        final qNum = AppTranslations.formatDigits(i + 1, lang);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'Please enter text for Question $qNum',
                mr: 'कृपया प्रश्न $qNum चा मजकूर भरा',
                hi: 'कृपया प्रश्न $qNum का पाठ दर्ज करें',
              ),
            ),
          ),
        );
        return;
      }
      finalQuestions.add(SurveyQuestionModel(
        id: 'q${i + 1}',
        text: t,
        type: _questions[i].type,
        options: _questions[i].options,
      ));
    }

    // Default sample target to existing value or 500, and status to 'Active'
    final newSurvey = SurveyModel(
      id: widget.surveyToEdit?.id ?? 'surv-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: desc,
      area: _selectedArea,
      questions: finalQuestions,
      targetSampleSize: widget.surveyToEdit?.targetSampleSize ?? 500,
      status: widget.surveyToEdit?.status ?? 'Active',
      createdAt: widget.surveyToEdit?.createdAt ?? DateTime.now(),
    );

    final repo = ref.read(surveysRepoProvider);
    if (widget.surveyToEdit != null) {
      await repo.updateSurvey(newSurvey);
    } else {
      await repo.createSurvey(newSurvey);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _fieldLabel(String text, {bool isRequired = false}) {
    return AppFieldLabel(label: text, isRequired: isRequired);
  }

  InputDecoration _inputDec({String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isEdit = widget.surveyToEdit != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
            icon: Icons.poll_rounded,
            title: isEdit
                ? AppTranslations.pick(
                    lang,
                    en: 'Edit Survey',
                    mr: 'सर्व्हेक्षण संपादित करा',
                    hi: 'सर्वेक्षण संपादित करें',
                  )
                : AppTranslations.pick(
                    lang,
                    en: 'Create New Survey',
                    mr: 'नवीन सर्व्हेक्षण तयार करा',
                    hi: 'नया सर्वेक्षण बनाएं',
                  ),
            subtitle: AppTranslations.pick(
              lang,
              en: 'Design civic polls and opinion surveys for residents',
              mr: 'प्रभागातील नागरिकांचे मत जाणून घेण्यासाठी प्रश्न तयार करा',
              hi: 'नागरिकों की राय जानने के लिए सर्वेक्षण और प्रश्न तैयार करें',
            ),
            onClose: () => Navigator.pop(context),
          ),

          // 2. SCROLLABLE FORM BODY & BUTTONS
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(18, 14, 18, MediaQuery.of(context).viewInsets.bottom + 24),
              children: [
                // Survey Details Section
                _fieldLabel(
                  AppTranslations.pick(lang, en: 'Survey Title', mr: 'सर्व्हेक्षण शीर्षक', hi: 'सर्वेक्षण शीर्षक'),
                  isRequired: true,
                ),
                TextField(
                  controller: _titleCtrl,
                  decoration: _inputDec(
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'e.g. Shaniwar Peth Road & Water Survey',
                      mr: 'उदा. शनिवार पेठ पाणीपुरवठा व रस्ते पाहणी',
                      hi: 'उदा. शनिवार पेठ सड़क और जल सर्वेक्षण',
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _fieldLabel(
                  AppTranslations.pick(
                    lang,
                    en: 'Survey Description / Objective',
                    mr: 'सर्व्हेक्षण माहिती व उद्देश',
                    hi: 'सर्वेक्षण विवरण और उद्देश्य',
                  ),
                  isRequired: true,
                ),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: _inputDec(
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Objective and instructions for this survey...',
                      mr: 'या सर्व्हेक्षणाचा मुख्य उद्देश व माहिती...',
                      hi: 'इस सर्वेक्षण का मुख्य उद्देश्य और निर्देश...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Area Dropdown (Sample Target and Survey Status removed)
                AppDropdownFormField<String>(
                  label: AppTranslations.pick(lang, en: 'Ward / Area', mr: 'प्रभाग / परिसर', hi: 'वार्ड / क्षेत्र'),
                  value: _selectedArea,
                  items: _prabhagAreas.map((a) {
                    final areaLabel = a == 'Entire Ward 12'
                        ? AppTranslations.pick(
                            lang,
                            en: 'Entire Ward 12',
                            mr: 'संपूर्ण प्रभाग १२',
                            hi: 'पूरा वार्ड १२',
                          )
                        : AppTranslations.getAreaName(a, lang);
                    return DropdownMenuItem(
                      value: a,
                      child: AppTranslatedText(
                        areaLabel,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedArea = val);
                  },
                ),
                const SizedBox(height: 20),

                // Question Builder Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Survey Questions',
                            mr: 'सर्व्हेक्षण प्रश्न',
                            hi: 'सर्वेक्षण प्रश्न',
                          ),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _addNewQuestion,
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7), size: 18),
                      label: Text(
                        AppTranslations.pick(lang, en: 'Add Question', mr: 'प्रश्न जोडा', hi: 'प्रश्न जोड़ें'),
                        style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Questions List
                ..._questions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  final qNum = AppTranslations.formatDigits(idx + 1, lang);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Question $qNum',
                                mr: 'प्रश्न $qNum',
                                hi: 'प्रश्न $qNum',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 14),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                              onPressed: () => _removeQuestion(idx),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Question Text & Question Type side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Question Text',
                                      mr: 'प्रश्नाचा मजकूर',
                                      hi: 'प्रश्न का पाठ',
                                    ),
                                    isRequired: true,
                                  ),
                                  TextField(
                                    controller: q.textController,
                                    decoration: _inputDec(
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'e.g. Did you receive benefit?',
                                        mr: 'उदा. तुम्हाला योजनेचा लाभ मिळाला का?',
                                        hi: 'उदा. क्या आपको योजना का लाभ मिला?',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppDropdownFormField<SurveyQuestionType>(
                                    label: AppTranslations.pick(lang, en: 'Type', mr: 'प्रकार', hi: 'प्रकार'),
                                    value: q.type,
                                    isExpanded: true,
                                    items: [
                                      DropdownMenuItem(
                                        value: SurveyQuestionType.yesNo,
                                        child: Text(
                                          AppTranslations.pick(lang, en: 'Yes / No', mr: 'होय / नाही', hi: 'हाँ / नहीं'),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: SurveyQuestionType.mcq,
                                        child: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'MCQ Options',
                                            mr: 'बहुपर्यायी (MCQ)',
                                            hi: 'बहुविकल्पीय (MCQ)',
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: SurveyQuestionType.rating,
                                        child: Text(
                                          AppTranslations.pick(
                                            lang,
                                            en: 'Star Rating',
                                            mr: 'स्टार रेटिंग',
                                            hi: 'स्टार रेटिंग',
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          q.type = val;
                                          if (val == SurveyQuestionType.mcq && q.options.isEmpty) {
                                            q.options = [
                                              AppTranslations.pick(lang, en: 'Option 1', mr: 'पर्याय १', hi: 'विकल्प १'),
                                              AppTranslations.pick(lang, en: 'Option 2', mr: 'पर्याय २', hi: 'विकल्प २'),
                                              AppTranslations.pick(lang, en: 'Option 3', mr: 'पर्याय ३', hi: 'विकल्प ३'),
                                            ];
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (q.type == SurveyQuestionType.mcq) ...[
                          const SizedBox(height: 12),
                          Text(
                            AppTranslations.pick(lang, en: 'Options:', mr: 'पर्याय:', hi: 'विकल्प:'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: q.options.asMap().entries.map((optEntry) {
                              return Chip(
                                label: AppTranslatedText(
                                  optEntry.value,
                                  targetLanguage: lang,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                deleteIconColor: const Color(0xFFDC2626),
                                onDeleted: () {
                                  setState(() => q.options.removeAt(optEntry.key));
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: () => _addOptionToMcq(q),
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Add New Option',
                                mr: 'नवीन पर्याय जोडा',
                                hi: 'नया विकल्प जोड़ें',
                              ),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveSurvey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: Text(
                      isEdit
                          ? AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'बदलाव सहेजें')
                          : AppTranslations.pick(
                              lang,
                              en: 'Create & Publish Survey',
                              mr: 'सर्व्हेक्षण प्रकाशित करा',
                              hi: 'सर्वेक्षण बनाएं और प्रकाशित करें',
                            ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addOptionToMcq(_TempQuestion q) {
    final lang = ref.read(appLanguageProvider);
    final optCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppTranslations.pick(lang, en: 'Add New Option', mr: 'नवीन पर्याय जोडा', hi: 'नया विकल्प जोड़ें'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: optCtrl,
          decoration: InputDecoration(
            hintText: AppTranslations.pick(
              lang,
              en: 'Type option text...',
              mr: 'पर्यायाचा मजकूर लिहा...',
              hi: 'विकल्प का पाठ लिखें...',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () {
              final t = optCtrl.text.trim();
              if (t.isNotEmpty) {
                setState(() => q.options.add(t));
              }
              Navigator.pop(ctx);
            },
            child: Text(AppTranslations.pick(lang, en: 'Add', mr: 'जोडा', hi: 'जोड़ें')),
          ),
        ],
      ),
    );
  }
}

class _TempQuestion {
  final String id;
  final TextEditingController textController;
  SurveyQuestionType type;
  List<String> options;

  _TempQuestion({
    required this.id,
    required this.textController,
    required this.type,
    required this.options,
  });
}
