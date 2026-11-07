import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/survey_model.dart';
import '../../../data/repositories/surveys_repository.dart';

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

  @override
  Widget build(BuildContext context) {
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
          isEdit ? 'Edit Survey' : 'Create New Survey',
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
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Survey Basic Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Survey Main Subject / Title *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Survey Details & Objective *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedArea,
                          decoration: const InputDecoration(
                            labelText: 'Ward / Area',
                            border: OutlineInputBorder(),
                          ),
                          items: _prabhagAreas.map((a) {
                            return DropdownMenuItem(value: a, child: Text(a));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedArea = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _targetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sample Target (1% = 426)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Survey Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Active', label: Text('Active')),
                          ButtonSegment(value: 'Draft', label: Text('Draft')),
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
                const Text(
                  'Survey Questions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                TextButton.icon(
                  onPressed: _addNewQuestion,
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7)),
                  label: const Text('Add Question', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
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
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Question ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                          onPressed: () => _removeQuestion(idx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    TextField(
                      controller: q.textController,
                      decoration: const InputDecoration(
                        labelText: 'Question Text *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<SurveyQuestionType>(
                      value: q.type,
                      decoration: const InputDecoration(
                        labelText: 'Question Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: SurveyQuestionType.yesNo, child: Text('Yes / No')),
                        DropdownMenuItem(value: SurveyQuestionType.mcq, child: Text('Multiple Choice (MCQ)')),
                        DropdownMenuItem(value: SurveyQuestionType.rating, child: Text('Star Rating (1 to 5)')),
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

                    if (q.type == SurveyQuestionType.mcq) ...[
                      const SizedBox(height: 10),
                      const Text('Options:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: q.options.asMap().entries.map((optEntry) {
                          return Chip(
                            label: Text(optEntry.value),
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
                        label: const Text('Add New Option', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _saveSurvey,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isEdit ? 'Save Changes' : 'Create & Publish Survey',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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

