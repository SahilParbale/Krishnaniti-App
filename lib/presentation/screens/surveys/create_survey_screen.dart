import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/survey_model.dart';
import '../../../data/repositories/surveys_repository.dart';
import '../../providers/auth_provider.dart';

class CreateSurveyScreen extends ConsumerStatefulWidget {
  final SurveyModel? surveyToEdit;

  const CreateSurveyScreen({super.key, this.surveyToEdit});

  @override
  ConsumerState<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends ConsumerState<CreateSurveyScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController(text: '426');
  String _selectedArea = 'Shaniwar Peth';
  String _status = 'Active';

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
      _targetCtrl.text = s.targetSampleSize.toString();
      _selectedArea = s.area ?? 'Shaniwar Peth';
      _status = s.status;

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
    _targetCtrl.dispose();
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
    final target = int.tryParse(_targetCtrl.text.trim()) ?? 426;

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

    final newSurvey = SurveyModel(
      id: widget.surveyToEdit?.id ?? 'surv-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: desc,
      area: _selectedArea,
      questions: finalQuestions,
      targetSampleSize: target,
      status: _status,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit
              ? (isMr ? 'सर्व्हेक्षण संपादित करा' : 'Edit Survey')
              : (isMr ? 'नवीन सर्व्हेक्षण तयार करा' : 'Create New Survey'),
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Survey Details Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isMr ? 'सर्व्हेक्षणाची मूलभूत माहिती' : 'Survey Basic Information',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _fieldLabel(isMr ? 'सर्व्हेक्षणाचा विषय / शीर्षक' : 'Survey Main Subject / Title', isRequired: true),
                  TextField(
                    controller: _titleCtrl,
                    decoration: _inputDec(
                      hintText: isMr ? 'उदा. प्रभाग १२ विकास कामे जनमत' : 'e.g. Ward 12 Development Survey',
                    ),
                  ),
                  const SizedBox(height: 14),

                  _fieldLabel(isMr ? 'सर्व्हेक्षण तपशील व उद्दिष्ट' : 'Survey Details & Objective', isRequired: true),
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

                  // Area & Target Sample Size side-by-side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel(isMr ? 'प्रभाग / परिसर' : 'Ward / Area'),
                            DropdownButtonFormField<String>(
                              value: _selectedArea,
                              decoration: _inputDec(),
                              items: _prabhagAreas.map((a) {
                                return DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedArea = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel(isMr ? 'नमुना उद्दिष्ट (1% = 426)' : 'Sample Target (1% = 426)'),
                            TextField(
                              controller: _targetCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDec(hintText: '426'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr ? 'सर्व्हेक्षण स्थिती:' : 'Survey Status:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                      ),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'Active', label: Text(isMr ? 'सक्रिय' : 'Active')),
                          ButtonSegment(value: 'Draft', label: Text(isMr ? 'मसुदा' : 'Draft')),
                        ],
                        selected: {_status},
                        onSelectionChanged: (set) => setState(() => _status = set.first),
                      ),
                    ],
                  ),
                ],
              ),
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
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7)),
                  label: Text(
                    isMr ? 'प्रश्न जोडा' : 'Add Question',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
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
                  color: Colors.white,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

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
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel(isMr ? 'प्रकार' : 'Question Type'),
                              DropdownButtonFormField<SurveyQuestionType>(
                                value: q.type,
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
                            label: Text(optEntry.value),
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

            const SizedBox(height: 40),
          ],
        ),
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

