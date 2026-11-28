import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/gb_register_entry_model.dart';
import '../../../data/repositories/gb_register_repository.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../navigation/app_drawer.dart';
import '../../widgets/app_modal_sheet.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_pdf_button.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'gb_register_detail_screen.dart';
import 'gb_register_report_generator.dart';

class GbRegisterScreen extends ConsumerStatefulWidget {
  const GbRegisterScreen({super.key});

  @override
  ConsumerState<GbRegisterScreen> createState() => _GbRegisterScreenState();
}

class _GbRegisterScreenState extends ConsumerState<GbRegisterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _viewMode = 'grid'; // 'grid' | 'report'
  String _selectedMeetingType = 'All'; // 'All', 'GB', 'Standing Committee', 'Ward Committee', 'Special GB'
  String _selectedStatus = 'All'; // 'All', 'Raised', 'In Discussion', 'Action Taken', 'Rejected'
  String _selectedArea = 'All';

  bool _isLoading = true;
  List<GbRegisterEntryModel> _allEntries = [];

  int _displayedLimit = 20;

  List<GbRegisterEntryModel> get _visibleEntries =>
      _filteredEntries.take(_displayedLimit).toList();

  final List<String> _meetingTypes = ['All', 'GB', 'Standing Committee', 'Ward Committee', 'Special GB', 'Other'];
  final List<String> _statusList = ['All', 'Raised', 'In Discussion', 'Resolved', 'Action Taken'];

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
    final repo = ref.read(gbRegisterRepoProvider);
    final items = await repo.getEntries();
    if (mounted) {
      setState(() {
        _allEntries = items;
        _isLoading = false;
      });
    }
  }

  List<String> get _areas {
    final list = _allEntries.map((e) => e.area.trim()).where((a) => a.isNotEmpty).toSet().toList();
    list.sort();
    return ['All', ...list];
  }

  List<GbRegisterEntryModel> get _filteredEntries {
    final query = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim()).toLowerCase();

    return _allEntries.where((e) {
      if (_selectedMeetingType != 'All' && e.meetingType.toLowerCase() != _selectedMeetingType.toLowerCase()) {
        return false;
      }
      if (_selectedStatus != 'All' && e.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_selectedArea != 'All' && !e.area.toLowerCase().contains(_selectedArea.toLowerCase())) {
        return false;
      }
      if (query.isNotEmpty) {
        final subMatch = e.subject.toLowerCase().contains(query);
        final descMatch = e.description.toLowerCase().contains(query);
        final deptMatch = e.department.toLowerCase().contains(query);
        final areaMatch = e.area.toLowerCase().contains(query);
        final resMatch = e.resolutionNo?.toLowerCase().contains(query) ?? false;
        final tagMatch = e.tags.any((t) => t.toLowerCase().contains(query));
        if (!subMatch && !descMatch && !deptMatch && !areaMatch && !resMatch && !tagMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showAddModal() {
    final lang = ref.read(appLanguageProvider);
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final dateCtrl = TextEditingController(
      text: AppTranslations.formatDate(selectedDate, lang, pattern: 'dd MMM yyyy'),
    );
    final benCtrl = TextEditingController();
    final respCtrl = TextEditingController();

    String meetingType = (_selectedMeetingType != 'All' && _meetingTypes.contains(_selectedMeetingType))
        ? _selectedMeetingType
        : 'GB';
    String status = 'Raised';
    bool isGeneratingAi = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            void autoDraftDescription() {
              if (subjectCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Please enter a subject title first to auto-draft description',
                        mr: 'वर्णन तयार करण्यासाठी आधी विषय प्रविष्ट करा',
                        hi: 'विवरण तैयार करने के लिए पहले विषय दर्ज करें',
                      ),
                    ),
                    backgroundColor: const Color(0xFFCA8A04),
                  ),
                );
                return;
              }

              setModalState(() => isGeneratingAi = true);
              Future.delayed(const Duration(milliseconds: 350), () {
                if (!stCtx.mounted) return;
                final subject = subjectCtrl.text.trim();
                final dept = deptCtrl.text.trim().isNotEmpty
                    ? deptCtrl.text.trim()
                    : AppTranslations.pick(
                        lang,
                        en: 'Department',
                        mr: 'संबंधित विभाग',
                        hi: 'संबंधित विभाग',
                      );
                final area = areaCtrl.text.trim().isNotEmpty
                    ? areaCtrl.text.trim()
                    : AppTranslations.pick(
                        lang,
                        en: 'Ward',
                        mr: 'प्रभाग',
                        hi: 'वार्ड',
                      );

                final String generated = AppTranslations.pick(
                  lang,
                  en:
                      'Formal legislative submission placed before the Assembly regarding "$subject" across $area. Citizens have lodged recurring representations with the $dept. It is respectfully moved that administrative sanction, technical feasibility review, and budgetary allocation be granted on priority.',
                  mr:
                      'पुणे महानगरपालिका कार्यक्षेत्रातील $area परिसरामध्ये "$subject" संदर्भात तातडीने धोरणात्मक निर्णय घेणे अत्यावश्यक आहे. $dept कडे स्थानिक नागरिकांनी वारंवार पाठपुरावा करूनही अडचण प्रलंबित राहिली आहे. सबब, सदर विषयावर महासभेत / संबंधित समितीत तात्काळ प्रशासकीय मंजुरी, अंदाजपत्रकीय तरतूद व कामाचे आदेश काढण्यात यावेत ही विनंती.',
                  hi:
                      'पुणे नगर निगम क्षेत्र के $area में "$subject" के संबंध में तत्काल नीतिगत निर्णय लेना अत्यंत आवश्यक है। स्थानीय नागरिकों द्वारा $dept से बार-बार अनुरोध करने के बावजूद समस्या लंबित है। अतः महासभा / संबंधित समिति में तत्काल प्रशासनिक स्वीकृति, बजट प्रावधान और कार्य आदेश जारी करने का अनुरोध है।',
                );

                setModalState(() {
                  descCtrl.text = generated;
                  isGeneratingAi = false;
                });
              });
            }

            Future<void> pickDate() async {
              final picked = await showThemedDatePicker(
                context: sheetCtx,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setModalState(() {
                  selectedDate = picked;
                  dateCtrl.text = AppTranslations.formatDate(picked, lang, pattern: 'dd MMM yyyy');
                });
              }
            }

            InputDecoration inputDec({required String hintText, IconData? prefixIcon}) {
              return InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
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

            Widget fieldLabel(String label, {bool isRequired = false}) {
              return AppFieldLabel(label: label, isRequired: isRequired);
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. FIXED HEADER
                  AppModalHeader(
                    icon: Icons.gavel_rounded,
                    title: AppTranslations.pick(
                      lang,
                      en: 'Record Assembly Motion (GB Register)',
                      mr: 'नवीन GB नोंद (महासभा नोंदवही)',
                      hi: 'नया जीबी प्रस्ताव दर्ज करें (जीबी रजिस्टर)',
                    ),
                    subtitle: AppTranslations.pick(
                      lang,
                      en: 'Record motions, questions and resolutions in General Body',
                      mr: 'महासभा किंवा समितीमध्ये उपस्थित केलेले प्रश्न व ठराव नोंदवा',
                      hi: 'महासभा या समिति में उठाए गए प्रश्न और संकल्प दर्ज करें',
                    ),
                    onClose: () => Navigator.pop(sheetCtx),
                  ),

                  // 2. SCROLLABLE FORM BODY & BUTTONS
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        14,
                        18,
                        16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Meeting Date & Meeting Type (Side-by-Side)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Meeting Date',
                                        mr: 'बैठक तारीख',
                                        hi: 'बैठक तिथि',
                                      ),
                                      isRequired: true,
                                    ),
                                    TextField(
                                      controller: dateCtrl,
                                      readOnly: true,
                                      onTap: pickDate,
                                      decoration: inputDec(
                                        hintText: AppTranslations.pick(
                                          lang,
                                          en: 'Select Date',
                                          mr: 'तारीख निवडा',
                                          hi: 'तिथि चुनें',
                                        ),
                                        prefixIcon: Icons.calendar_today_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppDropdownFormField<String>(
                                      label: AppTranslations.pick(
                                        lang,
                                        en: 'Meeting Type',
                                        mr: 'बैठक प्रकार',
                                        hi: 'बैठक प्रकार',
                                      ),
                                      isRequired: true,
                                      value: meetingType,
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'Select Type',
                                        mr: 'प्रकार निवडा',
                                        hi: 'प्रकार चुनें',
                                      ),
                                      items: _meetingTypes
                                          .where((t) => t != 'All')
                                          .map((t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(
                                                  _getMeetingTypeLabel(t, lang),
                                                  style: const TextStyle(fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => meetingType = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 2. Subject / Issue (Full Width)
                          fieldLabel(
                            AppTranslations.pick(
                              lang,
                              en: 'Subject / Issue',
                              mr: 'विषय / मुद्दा',
                              hi: 'विषय / मुद्दा',
                            ),
                            isRequired: true,
                          ),
                          TextField(
                            controller: subjectCtrl,
                            decoration: inputDec(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'e.g. Water shortage in Ward 12',
                                mr: 'उदा. प्रभाग १२ मध्ये पाणी पुरवठ्याची समस्या',
                                hi: 'उदा. वार्ड १२ में पानी की समस्या',
                              ),
                              prefixIcon: Icons.title_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Description with AI Auto-Draft (Full Width)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              fieldLabel(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Description',
                                  mr: 'वर्णन',
                                  hi: 'विवरण',
                                ),
                              ),
                              InkWell(
                                onTap: isGeneratingAi ? null : autoDraftDescription,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isGeneratingAi)
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                                        )
                                      else
                                        const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'AI Auto-Draft',
                                          mr: 'AI स्वयं-मसुदा',
                                          hi: 'AI ऑटो-ड्राफ्ट',
                                        ),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: descCtrl,
                            maxLines: 3,
                            decoration: inputDec(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'Detailed description of the issue raised...',
                                mr: 'मांडलेल्या मुद्द्याचे सविस्तर वर्णन...',
                                hi: 'उठाए गए मुद्दे का विस्तृत विवरण...',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 4. Area & Beneficiaries (Side-by-Side)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Area',
                                        mr: 'क्षेत्र / भाग',
                                        hi: 'क्षेत्र / वार्ड',
                                      ),
                                    ),
                                    TextField(
                                      controller: areaCtrl,
                                      decoration: inputDec(
                                        hintText: AppTranslations.pick(
                                          lang,
                                          en: 'e.g. Ward 12',
                                          mr: 'उदा. प्रभाग १२',
                                          hi: 'उदा. वार्ड १२',
                                        ),
                                        prefixIcon: Icons.map_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'People Benefited',
                                        mr: 'लाभार्थी',
                                        hi: 'लाभार्थी',
                                      ),
                                    ),
                                    TextField(
                                      controller: benCtrl,
                                      decoration: inputDec(
                                        hintText: AppTranslations.pick(
                                          lang,
                                          en: 'e.g. 500+ residents',
                                          mr: 'उदा. ५००+ नागरिक',
                                          hi: 'उदा. ५००+ निवासी',
                                        ),
                                        prefixIcon: Icons.people_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 5. Department & Outcome / Status (Side-by-Side)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    fieldLabel(
                                      AppTranslations.pick(
                                        lang,
                                        en: 'Department',
                                        mr: 'विभाग',
                                        hi: 'विभाग',
                                      ),
                                    ),
                                    TextField(
                                      controller: deptCtrl,
                                      decoration: inputDec(
                                        hintText: AppTranslations.pick(
                                          lang,
                                          en: 'e.g. Water Supply',
                                          mr: 'उदा. पाणी पुरवठा',
                                          hi: 'उदा. जल आपूर्ति',
                                        ),
                                        prefixIcon: Icons.business_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppDropdownFormField<String>(
                                      label: AppTranslations.pick(
                                        lang,
                                        en: 'Outcome / Status',
                                        mr: 'निकाल / स्थिती',
                                        hi: 'परिणाम / स्थिति',
                                      ),
                                      isRequired: true,
                                      value: status,
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'Select Status',
                                        mr: 'स्थिती निवडा',
                                        hi: 'स्थिति चुनें',
                                      ),
                                      items: _statusList
                                          .where((s) => s != 'All')
                                          .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(
                                                  _getStatusLabel(s, lang),
                                                  style: const TextStyle(fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => status = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 6. Administrative Response (Full Width)
                          fieldLabel(
                            AppTranslations.pick(
                              lang,
                              en: 'Administrative Response',
                              mr: 'प्रशासकीय उत्तर',
                              hi: 'प्रशासनिक उत्तर',
                            ),
                          ),
                          TextField(
                            controller: respCtrl,
                            maxLines: 2,
                            decoration: inputDec(
                              hintText: AppTranslations.pick(
                                lang,
                                en: 'Response received from administration...',
                                mr: 'प्रशासनाकडून मिळालेले उत्तर...',
                                hi: 'प्रशासन से प्राप्त उत्तर...',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const SizedBox(height: 20),

                          // Submit Button (Scrolls together with form)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                              onPressed: () async {
                                if (subjectCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Please enter a subject',
                                          mr: 'कृपया विषय प्रविष्ट करा',
                                          hi: 'कृपया विषय दर्ज करें',
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                final newEntry = GbRegisterEntryModel(
                                  id: 'gb-${DateTime.now().millisecondsSinceEpoch}',
                                  meetingType: meetingType,
                                  meetingDate: DateFormat('yyyy-MM-dd').format(selectedDate),
                                  subject: subjectCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  department: deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : 'General Administration',
                                  area: areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Ward 12',
                                  status: status,
                                  beneficiaries: benCtrl.text.trim().isNotEmpty ? benCtrl.text.trim() : null,
                                  response: respCtrl.text.trim().isNotEmpty ? respCtrl.text.trim() : null,
                                  resolutionNo: null,
                                  tags: const [],
                                  createdAt: DateTime.now().toIso8601String(),
                                );

                                final repo = ref.read(gbRegisterRepoProvider);
                                await repo.addEntry(newEntry);
                                await _loadData();

                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.pick(
                                          lang,
                                          en: 'Entry registered successfully!',
                                          mr: 'नोंद यशस्वीरित्या जतन केली!',
                                          hi: 'प्रविष्टि सफलतापूर्वक सहेजी गई!',
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              label: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Save Entry',
                                  mr: 'नोंद जतन करा',
                                  hi: 'प्रविष्टि सहेजें',
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(GbRegisterEntryModel item) {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Delete Assembly Record',
                  mr: 'सभेची नोंद हटवा',
                  hi: 'सभा रिकॉर्ड हटाएं',
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.pick(
                lang,
                en: 'Are you sure you want to delete this motion? This cannot be undone.',
                mr: 'तुम्हाला खात्री आहे का की तुम्हाला हा ठराव हटवायचा आहे? ही कृती पूर्ववत करता येणार नाही.',
                hi: 'क्या आप वाकई इस प्रस्ताव को हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।',
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            AppTranslatedText(
              '"${item.subject}"',
              targetLanguage: lang,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(gbRegisterRepoProvider);
              await repo.deleteEntry(item.id);
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Motion record deleted',
                        mr: 'ठरावाची नोंद हटवली',
                        hi: 'प्रस्ताव रिकॉर्ड हटाया गया',
                      ),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final displayed = _filteredEntries;

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
                AppTranslations.getNavTitle('gb_register', lang),
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
                    ? 'जीबी प्रस्ताव, प्रश्न आणि ठराव'
                    : (lang == 'hi'
                        ? 'जीबी प्रस्ताव, प्रश्न और संकल्प'
                        : 'GB motions, questions & resolutions'),
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            lang == 'mr' ? 'नवीन ठराव / प्रश्न' : (lang == 'hi' ? 'नया प्रस्ताव / प्रश्न' : 'Record Motion'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _showAddModal,
        ),
        body: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: AppShimmerList(count: 6),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar & Filters
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            // Search row with View Mode & Download
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (_) => setState(() => _displayedLimit = 20),
                                    decoration: InputDecoration(
                                      hintText: AppTranslations.pick(
                                        lang,
                                        en: 'Search motion subject, dept, area, resolution...',
                                        mr: 'ठराव, विषय, खाते किंवा संदर्भ क्रमांक शोधा...',
                                        hi: 'प्रस्ताव, विषय, विभाग, क्षेत्र या संदर्भ संख्या खोजें...',
                                      ),
                                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                                      suffixIcon: _searchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 18),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                setState(() => _displayedLimit = 20);
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _viewMode = _viewMode == 'grid' ? 'report' : 'grid';
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Icon(
                                      _viewMode == 'grid' ? Icons.table_chart_rounded : Icons.grid_view_rounded,
                                      size: 20,
                                      color: const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AppPdfButton.icon(
                                  tooltip: AppTranslations.getDownloadReport(lang),
                                  onPressed: () {
                                    GbRegisterReportGenerator.generateAndPrintGbReport(
                                      context: context,
                                      entries: displayed,
                                      meetingTypeFilter: _selectedMeetingType != 'All' ? _selectedMeetingType : null,
                                      statusFilter: _selectedStatus != 'All' ? _selectedStatus : null,
                                      lang: lang,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Meeting Type filter chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _meetingTypes.map((type) {
                                  final isSelected = _selectedMeetingType == type;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      selected: isSelected,
                                      showCheckmark: false,
                                      label: Text(
                                        type == 'All'
                                            ? AppTranslations.pick(
                                                lang,
                                                en: 'All Meetings',
                                                mr: 'सर्व सभा',
                                                hi: 'सभी बैठकें',
                                              )
                                            : _getMeetingTypeLabel(type, lang),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : const Color(0xFF475569),
                                        ),
                                      ),
                                      selectedColor: const Color(0xFF0284C7),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                      ),
                                      onSelected: (val) {
                                        if (val) {
                                          setState(() {
                                            _selectedMeetingType = type;
                                            _displayedLimit = 20;
                                          });
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status & Area Filters
                            Row(
                              children: [
                                Expanded(
                                  child: AppDropdown<String>(
                                    title: AppTranslations.pick(
                                      lang,
                                      en: 'Filter by Status',
                                      mr: 'स्थिती निवडा',
                                      hi: 'स्थिति चुनें',
                                    ),
                                    value: _selectedStatus,
                                    items: _statusList.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s == 'All'
                                              ? AppTranslations.pick(
                                                  lang,
                                                  en: 'All Status',
                                                  mr: 'सर्व स्थिती',
                                                  hi: 'सभी स्थिति',
                                                )
                                              : _getStatusLabel(s, lang),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedStatus = val;
                                          _displayedLimit = 20;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: AppDropdown<String>(
                                    title: AppTranslations.pick(
                                      lang,
                                      en: 'Filter by Area',
                                      mr: 'प्रभाग / परिसर निवडा',
                                      hi: 'क्षेत्र / वार्ड चुनें',
                                    ),
                                    value: _areas.contains(_selectedArea) ? _selectedArea : 'All',
                                    items: _areas.map((a) {
                                      return DropdownMenuItem(
                                        value: a,
                                        child: Text(
                                          a == 'All'
                                              ? AppTranslations.getAllAreas(lang)
                                              : AppTranslations.getAreaName(a, lang),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedArea = val;
                                          _displayedLimit = 20;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // List / Table
                      if (displayed.isEmpty)
                        Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'No GB Register Records Found',
                                  mr: 'कोणतेही ठराव किंवा प्रश्न सापडले नाहीत',
                                  hi: 'कोई जीबी रजिस्टर रिकॉर्ड नहीं मिला',
                                ),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Try adjusting your filters or record a new motion.',
                                  mr: 'कृपया शोध निकष बदला किंवा नवीन ठराव जोडा.',
                                  hi: 'कृपया फ़िल्टर बदलें या नया प्रस्ताव दर्ज करें।',
                                ),
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else ...[
                        if (_viewMode == 'grid')
                          _buildGridCardView(_visibleEntries, lang)
                        else
                          _buildTableView(_visibleEntries, lang),
                        AppLoadMoreFooter(
                          currentCount: _visibleEntries.length,
                          totalCount: displayed.length,
                          pageSize: 20,
                          onLoadMore: () => setState(() => _displayedLimit += 20),
                          label: 'entries',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildGridCardView(List<GbRegisterEntryModel> entries, String lang) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = entries[index];
        return InkWell(
          onTap: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GbRegisterDetailScreen(entry: item)),
            );
            if (res == true) _loadData();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                // Meeting type & date & status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.meetingTypeBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: item.meetingTypeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _getMeetingTypeDisplay(item.meetingType, lang),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.meetingTypeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(item.meetingDate, lang),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: item.statusBorderColor),
                      ),
                      child: Text(
                        _getStatusLabel(item.status, lang),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subject Title
                AppTranslatedText(
                  item.subject,
                  targetLanguage: lang,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                AppTranslatedText(
                  item.description,
                  targetLanguage: lang,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Department & Area
                Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AppTranslatedText(
                        item.department,
                        targetLanguage: lang,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    AppTranslatedText(
                      item.area,
                      targetLanguage: lang,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                // Administration response snippet if available
                if (item.response != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Administration Floor Reply:',
                                mr: 'प्रशासकीय कार्यवाही उत्तर:',
                                hi: 'प्रशासनिक कार्रवाई उत्तर:',
                              ),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                            if (item.resolutionNo != null) ...[
                              const Spacer(),
                              Text(
                                AppTranslations.formatDigits(item.resolutionNo!, lang),
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        AppTranslatedText(
                          item.response!,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.35),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],

                // Tags
                if (item.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: item.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AppTranslatedText(
                          tag,
                          prefix: '#',
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const Divider(height: 20),

                // Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GbRegisterDetailScreen(entry: item)),
                        );
                        if (res == true) _loadData();
                      },
                      child: Row(
                        children: [
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'View Details',
                              mr: 'सविस्तर पहा',
                              hi: 'विवरण देखें',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0284C7)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                          tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showDeleteConfirmation(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView(List<GbRegisterEntryModel> entries, String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: [
              DataColumn(label: Text(AppTranslations.pick(lang, en: '#', mr: 'अ.क्र.', hi: 'क्र.'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Date', mr: 'दिनांक', hi: 'दिनांक'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Meeting Type', mr: 'सभेचा प्रकार', hi: 'बैठक प्रकार'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Subject & Motion', mr: 'विषय / ठराव', hi: 'विषय / प्रस्ताव'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Department', mr: 'खाते', hi: 'विभाग'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Area', mr: 'परिसर', hi: 'क्षेत्र'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(AppTranslations.pick(lang, en: 'Action', mr: 'कृती', hi: 'कार्रवाई'), style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: entries.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;

              return DataRow(
                cells: [
                  DataCell(Text(AppTranslations.formatDigits(idx, lang))),
                  DataCell(Text(_formatDate(item.meetingDate, lang))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.meetingTypeBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getMeetingTypeDisplay(item.meetingType, lang),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.meetingTypeColor),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppTranslatedText(
                            item.subject,
                            targetLanguage: lang,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.resolutionNo != null)
                            Text(
                              AppTranslations.formatDigits(item.resolutionNo!, lang),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(AppTranslatedText(item.department, targetLanguage: lang, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.statusBgColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: item.statusBorderColor),
                      ),
                      child: Text(
                        _getStatusLabel(item.status, lang),
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: item.statusColor),
                      ),
                    ),
                  ),
                  DataCell(AppTranslatedText(item.area, targetLanguage: lang, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0284C7)),
                      tooltip: AppTranslations.pick(lang, en: 'View Details', mr: 'सविस्तर पहा', hi: 'विवरण देखें'),
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GbRegisterDetailScreen(entry: item)),
                        );
                        if (res == true) _loadData();
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static String _formatDate(String dateStr, String lang) {
    try {
      final dt = DateTime.parse(dateStr);
      return AppTranslations.formatDate(dt, lang, pattern: 'dd MMM yyyy');
    } catch (_) {
      return AppTranslations.formatDigits(dateStr, lang);
    }
  }

  static String _getMeetingTypeLabel(String type, String lang) {
    switch (type.toLowerCase()) {
      case 'gb':
        return AppTranslations.pick(lang, en: 'GB', mr: 'महासभा (GB)', hi: 'महासभा (GB)');
      case 'standing committee':
      case 'standing':
        return AppTranslations.pick(lang, en: 'Standing Committee', mr: 'स्थायी समिती', hi: 'स्थायी समिति');
      case 'ward committee':
      case 'ward':
        return AppTranslations.pick(lang, en: 'Ward Committee', mr: 'प्रभाग समिती', hi: 'वार्ड समिति');
      case 'special gb':
        return AppTranslations.pick(lang, en: 'Special GB', mr: 'विशेष महासभा', hi: 'विशेष महासभा');
      case 'other':
        return AppTranslations.pick(lang, en: 'Other', mr: 'इतर', hi: 'अन्य');
      default:
        return type;
    }
  }

  static String _getMeetingTypeDisplay(String type, String lang) {
    switch (type.toLowerCase()) {
      case 'gb':
        return AppTranslations.pick(lang, en: 'General Body (GB)', mr: 'महासभा (GB)', hi: 'महासभा (GB)');
      case 'standing committee':
      case 'standing':
        return AppTranslations.pick(lang, en: 'Standing Committee', mr: 'स्थायी समिती', hi: 'स्थायी समिति');
      case 'ward committee':
      case 'ward':
        return AppTranslations.pick(lang, en: 'Ward Committee', mr: 'प्रभाग समिती', hi: 'वार्ड समिति');
      case 'special gb':
        return AppTranslations.pick(lang, en: 'Special GB', mr: 'विशेष महासभा', hi: 'विशेष महासभा');
      case 'other':
        return AppTranslations.pick(lang, en: 'Other', mr: 'इतर', hi: 'अन्य');
      default:
        return type;
    }
  }

  static String _getStatusLabel(String status, String lang) {
    switch (status.toLowerCase()) {
      case 'action taken':
      case 'action_taken':
      case 'sanctioned':
        return AppTranslations.pick(lang, en: 'Action Taken', mr: 'कार्यवाही झाली', hi: 'कार्रवाई हुई');
      case 'resolved':
        return AppTranslations.pick(lang, en: 'Resolved', mr: 'सोडवला', hi: 'समाधान हुआ');
      case 'in discussion':
      case 'in_discussion':
        return AppTranslations.pick(lang, en: 'In Discussion', mr: 'चर्चेत', hi: 'चर्चा में');
      case 'rejected':
        return AppTranslations.pick(lang, en: 'Rejected', mr: 'नाकारले', hi: 'अस्वीकृत');
      case 'raised':
      default:
        return AppTranslations.pick(lang, en: 'Raised', mr: 'मांडलेला', hi: 'उठाया गया');
    }
  }
}
