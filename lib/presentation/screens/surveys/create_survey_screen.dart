import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/survey_model.dart';
import '../../../data/repositories/surveys_repository.dart';
import '../../providers/auth_provider.dart';

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
      _questions.add(_TempQuestion(
        id: 'q1',
        textController: TextEditingController(text: 'Did this scheme directly benefit your family?'),
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
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one question is required')),
      );
      return;
    }
    setState(() {
      _questions[index].textController.dispose();
      _questions.removeAt(index);
    });
  }

  Future<void> _saveSurvey() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter survey title and details')),
      );
      return;
    }

    final finalQuestions = <SurveyQuestionModel>[];
    for (int i = 0; i < _questions.length; i++) {
      final t = _questions[i].textController.text.trim();
      if (t.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter text for Question ${i + 1}')),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
          children: isRequired
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
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
    final isMr = ref.read(isMarathiProvider);
    final isEdit = widget.surveyToEdit != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
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
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.poll_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEdit
                        ? (isMr ? 'सर्व्हेक्षण संपादित करा' : 'Edit Survey')
                        : (isMr ? 'नवीन सर्व्हेक्षण तयार करा' : 'Create New Survey'),
                    style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Survey Details Section
                  _fieldLabel(isMr ? 'सर्व्हेक्षण शीर्षक' : 'Survey Title', isRequired: true),
                  TextField(
                    controller: _titleCtrl,
                    decoration: _inputDec(
                      hintText: isMr
                          ? 'उदा. शनिवार पेठ पाणीपुरवठा व रस्ते पाहणी'
                          : 'e.g. Shaniwar Peth Road & Water Survey',
                    ),
                  ),
                  const SizedBox(height: 14),

                  _fieldLabel(isMr ? 'सर्व्हेक्षण माहिती व उद्देश' : 'Survey Description / Objective', isRequired: true),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _inputDec(
                      hintText: isMr
                          ? 'या सर्व्हेक्षणाचा मुख्य उद्देश व माहिती...'
                          : 'Objective and instructions for this survey...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Area Dropdown (Sample Target and Survey Status removed)
                  _fieldLabel(isMr ? 'प्रभाग / परिसर' : 'Ward / Area'),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedArea,
                    decoration: _inputDec(),
                    items: _prabhagAreas.map((a) {
                      return DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)));
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
                            isMr ? 'सर्व्हेक्षण प्रश्न' : 'Survey Questions',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _addNewQuestion,
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7), size: 18),
                        label: Text(
                          isMr ? 'प्रश्न जोडा' : 'Add Question',
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
                                isMr ? 'प्रश्न ${idx + 1}' : 'Question ${idx + 1}',
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
                                    _fieldLabel(isMr ? 'प्रश्नाचा मजकूर' : 'Question Text', isRequired: true),
                                    TextField(
                                      controller: q.textController,
                                      decoration: _inputDec(
                                        hintText: isMr ? 'उदा. तुम्हाला योजनेचा लाभ मिळाला का?' : 'e.g. Did you receive benefit?',
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
                                    _fieldLabel(isMr ? 'प्रकार' : 'Type'),
                                    DropdownButtonFormField<SurveyQuestionType>(
                                      initialValue: q.type,
                                      decoration: _inputDec(),
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: SurveyQuestionType.yesNo, child: Text('Yes / No', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: SurveyQuestionType.mcq, child: Text('MCQ Options', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: SurveyQuestionType.rating, child: Text('Star Rating', style: TextStyle(fontSize: 12))),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            q.type = val;
                                            if (val == SurveyQuestionType.mcq && q.options.isEmpty) {
                                              q.options = ['Option 1', 'Option 2', 'Option 3'];
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
                            Text(isMr ? 'पर्याय:' : 'Options:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: q.options.asMap().entries.map((optEntry) {
                                return Chip(
                                  label: Text(optEntry.value, style: const TextStyle(fontSize: 12)),
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
                              label: Text(isMr ? 'नवीन पर्याय जोडा' : 'Add New Option', style: const TextStyle(fontSize: 11)),
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
                            ? (isMr ? 'बदल जतन करा' : 'Save Changes')
                            : (isMr ? 'सर्व्हेक्षण प्रकाशित करा' : 'Create & Publish Survey'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addOptionToMcq(_TempQuestion q) {
    final optCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Option', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: optCtrl,
          decoration: const InputDecoration(hintText: 'Type option text...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final t = optCtrl.text.trim();
              if (t.isNotEmpty) {
                setState(() => q.options.add(t));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
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
