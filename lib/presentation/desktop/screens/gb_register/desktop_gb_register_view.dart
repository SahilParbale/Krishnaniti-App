import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../providers/language_provider.dart';
import '../../../../data/models/diary_entry_model.dart';
import '../../../../data/models/gb_register_entry_model.dart';
import '../../../../data/repositories/diary_repository.dart';
import '../../common/desktop_modal_dialog.dart';
import '../../../screens/gb_register/gb_register_report_generator.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_load_more_footer.dart';

class DesktopGbRegisterView extends ConsumerStatefulWidget {
  const DesktopGbRegisterView({super.key});

  @override
  ConsumerState<DesktopGbRegisterView> createState() => _DesktopGbRegisterViewState();
}

class _DesktopGbRegisterViewState extends ConsumerState<DesktopGbRegisterView> {
  bool _loading = true;
  List<DiaryEntryModel> _entries = [];
  String _searchTerm = '';
  String _areaSearch = '';
  String _meetingType = 'All'; // 'All' | 'GB' | 'Standing Committee' | 'Ward Committee' | 'Special GB' | 'Other'
  String _statusFilter = 'All'; // 'All' | 'Raised' | 'In Discussion' | 'Resolved' | 'Action Taken'
  String _viewMode = 'grid'; // 'grid' | 'table'
  int _displayedLimit = 20;

  List<DiaryEntryModel> get _visibleEntries =>
      _filteredEntries.take(_displayedLimit).toList();

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(diaryRepositoryProvider);
      final data = await repo.getEntries();
      if (mounted) {
        setState(() {
          _entries = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _entries = [];
          _loading = false;
        });
      }
    }
  }

  List<DiaryEntryModel> get _filteredEntries {
    final q = AppTranslations.normalizeAsciiDigits(_searchTerm.trim()).toLowerCase();
    final aq = AppTranslations.normalizeAsciiDigits(_areaSearch.trim()).toLowerCase();
    return _entries.where((e) {
      final matchesSearch = q.isEmpty ||
          e.subject.toLowerCase().contains(q) ||
          (e.description != null && e.description!.toLowerCase().contains(q)) ||
          (e.department != null && e.department!.toLowerCase().contains(q)) ||
          (e.response != null && e.response!.toLowerCase().contains(q));

      final matchesArea = aq.isEmpty ||
          (e.area != null && e.area!.toLowerCase().contains(aq));

      final matchesType = _meetingType == 'All' || e.meetingType == _meetingType;

      final matchesStatus = _statusFilter == 'All' ||
          e.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesArea && matchesType && matchesStatus;
    }).toList();
  }

  String _localizeMeetingType(String type, String lang) {
    switch (type.trim()) {
      case 'All':
        return AppTranslations.pick(lang, en: 'All Meetings', mr: 'सर्व सभा', hi: 'सभी बैठकें');
      case 'GB':
        return AppTranslations.pick(lang, en: 'General Body (GB)', mr: 'सर्वसाधारण सभा (GB)', hi: 'सामान्य सभा (GB)');
      case 'Standing Committee':
        return AppTranslations.pick(lang, en: 'Standing Committee', mr: 'स्थायी समिती', hi: 'स्थायी समिति');
      case 'Ward Committee':
        return AppTranslations.pick(lang, en: 'Ward Committee', mr: 'प्रभाग समिती', hi: 'वार्ड समिति');
      case 'Special GB':
        return AppTranslations.pick(lang, en: 'Special GB', mr: 'विशेष सर्वसाधारण सभा', hi: 'विशेष सामान्य सभा');
      case 'Other':
        return AppTranslations.pick(lang, en: 'Other', mr: 'इतर', hi: 'अन्य');
      default:
        return type;
    }
  }

  String _localizeGbStatus(String status, String lang) {
    switch (status.trim().toLowerCase()) {
      case 'all':
        return AppTranslations.getAll(lang);
      case 'raised':
        return AppTranslations.pick(lang, en: 'Raised', mr: 'उपस्थित केले', hi: 'उठाया गया');
      case 'in discussion':
        return AppTranslations.pick(lang, en: 'In Discussion', mr: 'चर्चेत', hi: 'चर्चा में');
      case 'resolved':
        return AppTranslations.pick(lang, en: 'Resolved', mr: 'निकाली काढलेले', hi: 'समाधान किया गया');
      case 'action taken':
        return AppTranslations.pick(lang, en: 'Action Taken', mr: 'कारवाई केली', hi: 'कार्रवाई की गई');
      default:
        return AppTranslations.getStatus(status, lang);
    }
  }

  void _showEntryModal({DiaryEntryModel? entry}) {
    final subjectController = TextEditingController(text: entry?.subject ?? '');
    final descController = TextEditingController(text: entry?.description ?? '');
    final deptController = TextEditingController(text: entry?.department ?? '');
    final areaController = TextEditingController(text: entry?.area ?? 'Ward 12');
    final beneficiariesController = TextEditingController(text: entry?.beneficiaries ?? '');
    final responseController = TextEditingController(text: entry?.response ?? '');
    String selectedType = entry?.meetingType ?? 'GB';
    String selectedStatus = entry?.status ?? 'Raised';
    DateTime selectedDate = entry?.meetingDate ?? DateTime.now();
    bool isGeneratingAI = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => StatefulBuilder(
          builder: (ctx, setModalState) {
            return DesktopModalDialog(
              title: entry == null
                  ? AppTranslations.pick(
                      lang,
                      en: 'Add GB Register Entry',
                      mr: 'नवीन जीबी नोंद जोडा',
                      hi: 'नई जीबी रजिस्टर प्रविष्टि जोड़ें',
                    )
                  : AppTranslations.pick(
                      lang,
                      en: 'Edit GB Register Entry',
                      mr: 'जीबी नोंद संपादित करा',
                      hi: 'जीबी रजिस्टर प्रविष्टि संपादित करें',
                    ),
              subtitle: AppTranslations.pick(
                lang,
                en: 'Log and track resolutions, questions, and discussions from official meetings',
                mr: 'अधिकृत सभांमधील ठराव, प्रश्न आणि चर्चा नोंदवा व पाठपुरावा करा',
                hi: 'आधिकारिक बैठकों के प्रस्तावों, प्रश्नों और चर्चाओं को दर्ज और ट्रैक करें',
              ),
              icon: Icons.menu_book_rounded,
              width: 620,
              onClose: () => Navigator.pop(ctx),
              actions: [
                DesktopModalDialog.cancelButton(ctx),
                const SizedBox(width: 12),
                DesktopModalDialog.primaryButton(
                  text: entry == null
                      ? AppTranslations.pick(lang, en: 'Add Entry', mr: 'नोंद जोडा', hi: 'प्रविष्टि जोड़ें')
                      : AppTranslations.pick(lang, en: 'Save Changes', mr: 'बदल जतन करा', hi: 'परिवर्तन सहेजें'),
                  onPressed: () async {
                    if (subjectController.text.trim().isEmpty) return;
                    final newEntry = DiaryEntryModel(
                      id: entry?.id ?? 'diary-',
                      meetingDate: selectedDate,
                      meetingType: selectedType,
                      subject: subjectController.text.trim(),
                      description: descController.text.trim(),
                      department: deptController.text.trim(),
                      area: areaController.text.trim(),
                      status: selectedStatus,
                      beneficiaries: beneficiariesController.text.trim(),
                      response: responseController.text.trim(),
                    );

                    final repo = ref.read(diaryRepositoryProvider);
                    if (entry == null) {
                      await repo.addEntry(newEntry);
                    } else {
                      await repo.updateEntry(entry.id, newEntry.toJson());
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchEntries();
                  },
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meeting Type & Date
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Meeting Type *',
                                mr: 'सभेचा प्रकार *',
                                hi: 'बैठक का प्रकार *',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<String>(
                              value: selectedType,
                              height: 44,
                              backgroundColor: const Color(0xFFF8FAFC),
                              borderColor: const Color(0xFFE2E8F0),
                              items: [
                                DropdownMenuItem(value: 'GB', child: Text(_localizeMeetingType('GB', lang))),
                                DropdownMenuItem(value: 'Standing Committee', child: Text(_localizeMeetingType('Standing Committee', lang))),
                                DropdownMenuItem(value: 'Ward Committee', child: Text(_localizeMeetingType('Ward Committee', lang))),
                                DropdownMenuItem(value: 'Special GB', child: Text(_localizeMeetingType('Special GB', lang))),
                                DropdownMenuItem(value: 'Other', child: Text(_localizeMeetingType('Other', lang))),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedType = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Meeting Date *',
                                mr: 'सभेचा दिनांक *',
                                hi: 'बैठक की तिथि *',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setModalState(() => selectedDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppTranslations.formatDate(selectedDate, lang, pattern: 'dd/MM/yyyy'),
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Subject
                  Text(
                    AppTranslations.pick(
                      lang,
                      en: 'Subject / Question *',
                      mr: 'विषय / प्रश्न *',
                      hi: 'विषय / प्रश्न *',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'e.g. Sanction increased water supply quota for the ward...',
                        mr: 'उदा. प्रभागासाठी वाढीव पाणी पुरवठा कोटा मंजूर करणे...',
                        hi: 'जैसे वार्ड के लिए बढ़ा हुआ जल आपूर्ति कोटा स्वीकृत करना...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description + AI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.pick(lang, en: 'Description', mr: 'तपशील', hi: 'विवरण'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      TextButton.icon(
                        onPressed: isGeneratingAI || subjectController.text.trim().isEmpty
                            ? null
                            : () async {
                                setModalState(() => isGeneratingAI = true);
                                await Future.delayed(const Duration(milliseconds: 600));
                                final subj = subjectController.text.trim();
                                descController.text = AppTranslations.pick(
                                  lang,
                                  en: 'Resolution submitted in the General Body regarding $subj demanding urgent administrative implementation.',
                                  mr: '$subj या संदर्भात सर्वसाधारण सभेत ठराव सादर करून तातडीने प्रशासकीय अंमलबजावणीची मागणी करण्यात आली.',
                                  hi: '$subj के संबंध में सामान्य सभा में प्रस्ताव प्रस्तुत कर तत्काल प्रशासनिक कार्यान्वयन की मांग की गई।',
                                );
                                setModalState(() => isGeneratingAI = false);
                              },
                        icon: isGeneratingAI
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF0284C7)),
                        label: Text(
                          isGeneratingAI
                              ? AppTranslations.pick(lang, en: 'Generating...', mr: 'तयार होत आहे...', hi: 'तैयार हो रहा है...')
                              : AppTranslations.pick(lang, en: 'Auto-Generate (AI)', mr: 'AI द्वारे तयार करा', hi: 'AI से स्वतः बनाएं'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppTranslations.pick(
                        lang,
                        en: 'Enter details of the motion raised in the meeting...',
                        mr: 'सभेत मांडलेल्या प्रस्तावाचा तपशील लिहा...',
                        hi: 'बैठक में उठाए गए प्रस्ताव का विवरण दर्ज करें...',
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Department & Area
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(lang, en: 'Department', mr: 'विभाग', hi: 'विभाग'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: deptController,
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Water Supply Department',
                                  mr: 'उदा. पाणी पुरवठा विभाग',
                                  hi: 'जैसे जल आपूर्ति विभाग',
                                ),
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(lang, en: 'Ward / Area', mr: 'प्रभाग / परिसर', hi: 'वार्ड / क्षेत्र'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: areaController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status & Response
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(lang, en: 'Status *', mr: 'स्थिती *', hi: 'स्थिति *'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<String>(
                              value: selectedStatus,
                              height: 44,
                              backgroundColor: const Color(0xFFF8FAFC),
                              borderColor: const Color(0xFFE2E8F0),
                              items: [
                                DropdownMenuItem(value: 'Raised', child: Text(_localizeGbStatus('Raised', lang))),
                                DropdownMenuItem(value: 'In Discussion', child: Text(_localizeGbStatus('In Discussion', lang))),
                                DropdownMenuItem(value: 'Resolved', child: Text(_localizeGbStatus('Resolved', lang))),
                                DropdownMenuItem(value: 'Action Taken', child: Text(_localizeGbStatus('Action Taken', lang))),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedStatus = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Administrative Response',
                                mr: 'प्रशासकीय प्रतिसाद / निर्णय',
                                hi: 'प्रशासनिक प्रतिक्रिया / निर्णय',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: responseController,
                              decoration: InputDecoration(
                                hintText: AppTranslations.pick(
                                  lang,
                                  en: 'e.g. Ordered immediate survey',
                                  mr: 'उदा. तात्काळ सर्वेक्षणाचे आदेश दिले',
                                  hi: 'जैसे तत्काल सर्वेक्षण का आदेश दिया गया',
                                ),
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.brand600, width: 1.5)),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(DiaryEntryModel entry) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: appLanguageValueNotifier,
        builder: (ctx, lang, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppTranslations.pick(lang, en: 'Delete Entry', mr: 'नोंद हटवा', hi: 'प्रविष्टि हटाएं')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.pick(
                  lang,
                  en: 'Are you sure you want to delete this entry?',
                  mr: 'तुम्हाला खात्री आहे की तुम्ही ही नोंद हटवू इच्छिता?',
                  hi: 'क्या आप वाकई इस प्रविष्टि को हटाना चाहते हैं?',
                ),
              ),
              const SizedBox(height: 6),
              AppTranslatedText(
                entry.subject,
                targetLanguage: lang,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें')),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(diaryRepositoryProvider);
                await repo.deleteEntry(entry.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchEntries();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: Text(
                AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(desktopLanguageProvider);
    final filtered = _filteredEntries;
    final visible = _visibleEntries;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(filtered.length, lang),
          const SizedBox(height: 16),

          // Filters Row
          _buildFilterRow(lang),
          const SizedBox(height: 16),

          // Status Pills
          _buildStatusTabs(lang),
          const SizedBox(height: 24),

          // Content
          if (_loading)
            _buildLoadingGrid()
          else if (_viewMode == 'table')
            _buildReportTable(visible, lang)
          else
            _buildCardGrid(visible, lang),

          if (!_loading && filtered.isNotEmpty)
            AppLoadMoreFooter(
              currentCount: visible.length,
              totalCount: filtered.length,
              pageSize: 20,
              onLoadMore: () {
                setState(() => _displayedLimit += 20);
              },
              label: 'entries',
              isMarathi: lang == 'mr',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppTranslations.getNavTitle('gb_register', lang),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text(
                    '${AppTranslations.pick(lang, en: 'Entries:', mr: 'एकूण नोंदी:', hi: 'कुल प्रविष्टियां:')} ${AppTranslations.formatDigits(count, lang)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.pick(
                lang,
                en: 'General Body motions, resolutions and committee decisions',
                mr: 'सर्वसाधारण सभा ठराव, प्रस्ताव आणि समिती निर्णय',
                hi: 'सामान्य सभा प्रस्ताव, संकल्प और समिति निर्णय',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        // Actions: Download Report + Add Entry
        Row(
          children: [
            // Download Report
            OutlinedButton.icon(
              onPressed: () {
                GbRegisterReportGenerator.generateAndPrintGbReport(
                  context: context,
                  entries: _filteredEntries.map((e) => GbRegisterEntryModel(
                    id: e.id,
                    meetingType: e.meetingType,
                    meetingDate: e.formattedDate,
                    subject: e.subject,
                    description: e.description ?? '',
                    department: e.department ?? '',
                    area: e.area ?? 'Ward 12',
                    status: e.status,
                    response: e.response,
                    beneficiaries: e.beneficiaries,
                    createdAt: e.createdAt?.toIso8601String() ?? '',
                  )).toList(),
                  meetingTypeFilter: _meetingType,
                  statusFilter: _statusFilter,
                  lang: lang,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                AppTranslations.getDownloadReport(lang),
                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),

            // Add Entry (ns-btn-primary matching GBRegister.tsx)
            ElevatedButton(
              onPressed: () => _showEntryModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7), // bg-brand-600
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // rounded-xl
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white), // Plus w-4 h-4
                  const SizedBox(width: 8), // gap-2
                  Text(
                    AppTranslations.pick(lang, en: 'Add Entry', mr: 'नवीन नोंद', hi: 'नई प्रविष्टि'),
                    style: const TextStyle(
                      fontSize: 14, // text-sm
                      fontWeight: FontWeight.w600, // font-semibold
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF0369A1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String lang) {
    return Row(
      children: [
        // Main Search (Col 6)
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _searchTerm = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search subject, department or decision...',
                  mr: 'विषय, विभाग किंवा निर्णय शोधा...',
                  hi: 'विषय, विभाग या निर्णय खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        tooltip: AppTranslations.pick(lang, en: 'Clear', mr: 'साफ करा', hi: 'साफ़ करें'),
                        onPressed: () => setState(() => _searchTerm = ''),
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Area Search (Col 3)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() {
                _areaSearch = val;
                _displayedLimit = 20;
              }),
              decoration: InputDecoration(
                hintText: AppTranslations.pick(
                  lang,
                  en: 'Search Area...',
                  mr: 'परिसर शोधा...',
                  hi: 'क्षेत्र खोजें...',
                ),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: _areaSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        tooltip: AppTranslations.pick(lang, en: 'Clear', mr: 'साफ करा', hi: 'साफ़ करें'),
                        onPressed: () => setState(() => _areaSearch = ''),
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Meeting Type Dropdown (Col 3)
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: _meetingType,
            height: 42,
            prefixIcon: const Icon(Icons.groups_outlined, size: 18, color: Color(0xFF94A3B8)),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            items: [
              DropdownMenuItem(value: 'All', child: Text(_localizeMeetingType('All', lang))),
              DropdownMenuItem(value: 'GB', child: Text(_localizeMeetingType('GB', lang))),
              DropdownMenuItem(value: 'Standing Committee', child: Text(_localizeMeetingType('Standing Committee', lang))),
              DropdownMenuItem(value: 'Ward Committee', child: Text(_localizeMeetingType('Ward Committee', lang))),
              DropdownMenuItem(value: 'Special GB', child: Text(_localizeMeetingType('Special GB', lang))),
              DropdownMenuItem(value: 'Other', child: Text(_localizeMeetingType('Other', lang))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _meetingType = val;
                  _displayedLimit = 20;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs(String lang) {
    final statuses = [
      {'key': 'All', 'label': _localizeGbStatus('All', lang)},
      {'key': 'Raised', 'label': _localizeGbStatus('Raised', lang)},
      {'key': 'In Discussion', 'label': _localizeGbStatus('In Discussion', lang)},
      {'key': 'Resolved', 'label': _localizeGbStatus('Resolved', lang)},
      {'key': 'Action Taken', 'label': _localizeGbStatus('Action Taken', lang)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statuses.map((s) {
            final key = s['key']!;
            final label = s['label']!;
            final isSelected = _statusFilter == key;

            return InkWell(
              onTap: () => setState(() {
                _statusFilter = key;
                _displayedLimit = 20;
              }),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildViewToggleButton(
                icon: Icons.grid_view_rounded,
                label: AppTranslations.pick(lang, en: 'Grid', mr: 'ग्रिड', hi: 'ग्रिड'),
                isActive: _viewMode == 'grid',
                onTap: () => setState(() => _viewMode = 'grid'),
              ),
              const SizedBox(width: 4),
              _buildViewToggleButton(
                icon: Icons.table_rows_rounded,
                label: AppTranslations.pick(lang, en: 'Table', mr: 'तक्ता', hi: 'तालिका'),
                isActive: _viewMode == 'table',
                onTap: () => setState(() => _viewMode = 'table'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<DiaryEntryModel> items, String lang) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.book_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              AppTranslations.pick(
                lang,
                en: 'No entries found',
                mr: 'कोणतीही नोंद आढळली नाही',
                hi: 'कोई प्रविष्टि नहीं मिली',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 300,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Type badge + Status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Text(
                            _localizeMeetingType(item.meetingType, lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(item.status, lang),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Subject
                  AppTranslatedText(
                    item.subject,
                    targetLanguage: lang,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Expanded(
                    child: AppTranslatedText(
                      item.description ?? '',
                      targetLanguage: lang,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ),

                  // Admin response if present
                  if (item.response != null && item.response!.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.reply, size: 12, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Text(
                            '${AppTranslations.pick(lang, en: 'Decision:', mr: 'निर्णय:', hi: 'निर्णय:')} ',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          Expanded(
                            child: AppTranslatedText(
                              item.response!,
                              targetLanguage: lang,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Bottom info & actions
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              AppTranslations.formatDate(item.meetingDate, lang),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                              onPressed: () => _showEntryModal(entry: item),
                              tooltip: AppTranslations.pick(lang, en: 'Edit', mr: 'संपादित करा', hi: 'संपादित करें'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                              onPressed: () => _showDeleteDialog(item),
                              tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                            ),
                          ],
                        ),
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

  Widget _buildStatusBadge(String status, String lang) {
    Color bg;
    Color text;

    final s = status.toLowerCase();
    if (s == 'resolved') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF15803D);
    } else if (s == 'action taken') {
      bg = const Color(0xFFF3E8FF);
      text = const Color(0xFF7E22CE);
    } else if (s == 'in discussion') {
      bg = const Color(0xFFE0F2FE);
      text = const Color(0xFF0369A1);
    } else {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(_localizeGbStatus(status, lang), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
    );
  }

  Widget _buildReportTable(List<DiaryEntryModel> items, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: [
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Meeting Date', mr: 'सभेचा दिनांक', hi: 'बैठक की तिथि'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Meeting Type', mr: 'सभेचा प्रकार', hi: 'बैठक का प्रकार'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Subject & Details', mr: 'विषय व तपशील', hi: 'विषय और विवरण'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Department', mr: 'विभाग', hi: 'विभाग'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
            DataColumn(
              label: Text(
                AppTranslations.pick(lang, en: 'Decision / Outcome', mr: 'निर्णय / फलनिष्पत्ती', hi: 'निर्णय / परिणाम'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ),
          ],
          rows: items.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    AppTranslations.formatDate(item.meetingDate, lang),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                DataCell(
                  Text(
                    _localizeMeetingType(item.meetingType, lang),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppTranslatedText(
                        item.subject,
                        targetLanguage: lang,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      if (item.description != null && item.description!.trim().isNotEmpty)
                        AppTranslatedText(
                          item.description!,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
                DataCell(
                  (item.department == null || item.department!.trim().isEmpty)
                      ? const Text('-', style: TextStyle(fontSize: 12, color: Color(0xFF334155)))
                      : AppTranslatedText(
                          item.department!,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                        ),
                ),
                DataCell(_buildStatusBadge(item.status, lang)),
                DataCell(
                  (item.response == null || item.response!.trim().isEmpty)
                      ? const Text('-', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
                      : AppTranslatedText(
                          item.response!,
                          targetLanguage: lang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 260,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }
}
