import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/work_tracker_model.dart';
import '../../../data/repositories/file_tracker_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_load_more_footer.dart';
import '../../widgets/app_shimmer_card.dart';
import 'gov_office_report_generator.dart';

class FileTrackerTabView extends ConsumerStatefulWidget {
  const FileTrackerTabView({super.key});

  @override
  ConsumerState<FileTrackerTabView> createState() => _FileTrackerTabViewState();
}

class _FileTrackerTabViewState extends ConsumerState<FileTrackerTabView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatus = 'All';
  bool _isLoading = true;
  List<WorkTrackerModel> _trackers = [];

  int _displayedLimit = 20;

  List<WorkTrackerModel> get _visibleTrackers =>
      _trackers.take(_displayedLimit).toList();

  final List<String> _statuses = [
    'All',
    'Pending',
    'In Progress',
    'Approved',
    'Rejected',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTrackers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTrackers() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(fileTrackerRepoProvider);
      final list = await repo.getFileTrackers(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim()),
      );
      if (mounted) {
        setState(() {
          _trackers = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'in progress':
      case 'inprogress':
        return const Color(0xFF0284C7);
      case 'approved':
        return const Color(0xFF16A34A);
      case 'completed':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'in progress':
      case 'inprogress':
        return const Color(0xFFE0F2FE);
      case 'approved':
        return const Color(0xFFDCFCE7);
      case 'completed':
        return const Color(0xFFD1FAE5);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  void _showAddEditModal({WorkTrackerModel? existing}) {
    final lang = ref.read(appLanguageProvider);
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final deptCtrl = TextEditingController(text: existing?.department ?? '');
    final inwardCtrl = TextEditingController(
      text: existing != null
          ? AppTranslations.formatDigits(existing.inwardNumber, lang)
          : '',
    );
    final outwardCtrl = TextEditingController(
      text: existing != null
          ? AppTranslations.formatDigits(existing.outwardNumber, lang)
          : '',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String status = existing?.currentStatus ?? 'Pending';
    final initialStageCtrl = TextEditingController();
    final initialLocationCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF0284C7), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                existing != null
                                    ? AppTranslations.pick(
                                        lang,
                                        en: 'Edit File Tracker',
                                        mr: 'फाईल माहिती संपादित करा',
                                        hi: 'फ़ाइल जानकारी संपादित करें',
                                      )
                                    : AppTranslations.pick(
                                        lang,
                                        en: 'Register New File Tracker',
                                        mr: 'नवीन फाईल नोंदवा',
                                        hi: 'नई फ़ाइल दर्ज करें',
                                      ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(bottomCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildInputLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'File Title *',
                            mr: 'फाईल शीर्षक *',
                            hi: 'फ़ाइल शीर्षक *',
                          ),
                        ),
                        TextField(
                          controller: titleCtrl,
                          decoration: _inputDecoration(
                            AppTranslations.pick(
                              lang,
                              en: 'e.g. Ward Road Concreting Proposal',
                              mr: 'उदा. प्रभाग रस्ते काँक्रिटीकरण प्रस्ताव',
                              hi: 'उदा. वार्ड सड़क कंक्रीटीकरण प्रस्ताव',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Subject *',
                            mr: 'विषय *',
                            hi: 'विषय *',
                          ),
                        ),
                        TextField(
                          controller: subjectCtrl,
                          decoration: _inputDecoration(
                            AppTranslations.pick(
                              lang,
                              en: 'e.g. Road concretization sanction file',
                              mr: 'उदा. रस्ते काँक्रिटीकरण मंजुरी फाईल',
                              hi: 'उदा. सड़क कंक्रीटीकरण स्वीकृति फ़ाइल',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Department *',
                            mr: 'संबंधित विभाग *',
                            hi: 'संबंधित विभाग *',
                          ),
                        ),
                        TextField(
                          controller: deptCtrl,
                          decoration: _inputDecoration(
                            AppTranslations.pick(
                              lang,
                              en: 'e.g. PWD / Water Supply / Town Planning',
                              mr: 'उदा. बांधकाम / पाणी पुरवठा / नगर रचना',
                              hi: 'उदा. लोक निर्माण / जल आपूर्ति / नगर नियोजन',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Inward Number',
                                      mr: 'आवक क्रमांक',
                                      hi: 'आवक क्रमांक',
                                    ),
                                  ),
                                  TextField(
                                    controller: inwardCtrl,
                                    decoration: _inputDecoration(
                                      AppTranslations.formatDigits('IN-2026-401', lang),
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
                                  _buildInputLabel(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Outward Number',
                                      mr: 'जावक क्रमांक',
                                      hi: 'जावक क्रमांक',
                                    ),
                                  ),
                                  TextField(
                                    controller: outwardCtrl,
                                    decoration: _inputDecoration(
                                      AppTranslations.formatDigits('OUT-2026-88', lang),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Current Status',
                            mr: 'सद्यस्थिती',
                            hi: 'वर्तमान स्थिति',
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: status,
                          items: _statuses
                              .where((s) => s != 'All')
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(AppTranslations.getStatus(s, lang)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => status = val);
                          },
                          decoration: _inputDecoration(
                            AppTranslations.pick(
                              lang,
                              en: 'Status',
                              mr: 'स्थिती',
                              hi: 'स्थिति',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel(
                          AppTranslations.pick(
                            lang,
                            en: 'Description / Remarks',
                            mr: 'तपशील / शेरा',
                            hi: 'विवरण / टिप्पणी',
                          ),
                        ),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            AppTranslations.pick(
                              lang,
                              en: 'Notes regarding file submission, approvals...',
                              mr: 'फाईल सादर करणे, मंजुरीबाबत नोंदी...',
                              hi: 'फ़ाइल प्रस्तुति, स्वीकृतियों से संबंधित नोट्स...',
                            ),
                          ),
                        ),
                        if (existing == null) ...[
                          const SizedBox(height: 12),
                          _buildInputLabel(
                            AppTranslations.pick(
                              lang,
                              en: 'Initial Movement Stage (Optional)',
                              mr: 'सुरुवातीचा टप्पा (ऐच्छिक)',
                              hi: 'प्रारंभिक चरण (वैकल्पिक)',
                            ),
                          ),
                          TextField(
                            controller: initialStageCtrl,
                            decoration: _inputDecoration(
                              AppTranslations.pick(
                                lang,
                                en: 'e.g. Submitted to Chief Engineer Office',
                                mr: 'उदा. मुख्य अभियंता कार्यालयात सादर',
                                hi: 'उदा. मुख्य अभियंता कार्यालय में प्रस्तुत',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInputLabel(
                            AppTranslations.pick(
                              lang,
                              en: 'Current Location / Table',
                              mr: 'सध्याचे ठिकाण / टेबल',
                              hi: 'वर्तमान स्थान / टेबल',
                            ),
                          ),
                          TextField(
                            controller: initialLocationCtrl,
                            decoration: _inputDecoration(
                              AppTranslations.pick(
                                lang,
                                en: 'e.g. Desk 4, PMC Main Building',
                                mr: 'उदा. टेबल क्र. ४, मनपा मुख्य इमारत',
                                hi: 'उदा. डेस्क ४, मनपा मुख्य भवन',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        final subject = subjectCtrl.text.trim();
                        final dept = deptCtrl.text.trim();

                        if (title.isEmpty || dept.isEmpty) {
                          ScaffoldMessenger.of(bottomCtx).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Title and Department are required',
                                  mr: 'शीर्षक व विभाग आवश्यक आहेत',
                                  hi: 'शीर्षक और विभाग आवश्यक हैं',
                                ),
                              ),
                            ),
                          );
                          return;
                        }

                        final repo = ref.read(fileTrackerRepoProvider);
                        final user = ref.read(currentUserProvider);
                        final cleanInward = AppTranslations.normalizeAsciiDigits(inwardCtrl.text.trim());
                        final cleanOutward = AppTranslations.normalizeAsciiDigits(outwardCtrl.text.trim());

                        if (existing != null) {
                          await repo.updateFileTracker(
                            id: existing.id,
                            title: title,
                            subject: subject,
                            department: dept,
                            inwardNumber: cleanInward,
                            outwardNumber: cleanOutward,
                            currentStatus: status,
                            description: descCtrl.text.trim(),
                          );
                        } else {
                          await repo.createFileTracker(
                            title: title,
                            subject: subject,
                            department: dept,
                            inwardNumber: cleanInward,
                            outwardNumber: cleanOutward,
                            currentStatus: status,
                            description: descCtrl.text.trim(),
                            initialStageName: initialStageCtrl.text.trim().isNotEmpty ? initialStageCtrl.text.trim() : null,
                            initialLocation: initialLocationCtrl.text.trim().isNotEmpty ? initialLocationCtrl.text.trim() : null,
                            updatedBy: user?.name,
                          );
                        }

                        if (mounted) {
                          Navigator.pop(bottomCtx);
                          _fetchTrackers();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        AppTranslations.pick(
                          lang,
                          en: 'Save File Record',
                          mr: 'फाईल नोंद जतन करा',
                          hi: 'फ़ाइल रिकॉर्ड सहेजें',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  void _showDetailModal(WorkTrackerModel file) async {
    final lang = ref.read(appLanguageProvider);
    final repo = ref.read(fileTrackerRepoProvider);

    final fullItem = await repo.getFileTrackerById(file.id) ?? file;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTranslatedText(
                              fullItem.title,
                              targetLanguage: lang,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            AppTranslatedText(
                              fullItem.department,
                              targetLanguage: lang,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(fullItem.currentStatus),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(fullItem.currentStatus).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          AppTranslations.getStatus(fullItem.currentStatus, lang),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(fullItem.currentStatus)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      // Numbers card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Inward No.',
                                      mr: 'आवक क्र.',
                                      hi: 'आवक क्र.',
                                    ),
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                  Text(
                                    fullItem.inwardNumber.isNotEmpty
                                        ? AppTranslations.formatDigits(fullItem.inwardNumber, lang)
                                        : '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 30, color: const Color(0xFFCBD5E1)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Outward No.',
                                      mr: 'जावक क्र.',
                                      hi: 'जावक क्र.',
                                    ),
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                  Text(
                                    fullItem.outwardNumber.isNotEmpty
                                        ? AppTranslations.formatDigits(fullItem.outwardNumber, lang)
                                        : '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (fullItem.description.isNotEmpty) ...[
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'Description',
                            mr: 'तपशील',
                            hi: 'विवरण',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        AppTranslatedText(
                          fullItem.description,
                          targetLanguage: lang,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Movement History Header + Add Stage button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.history_rounded, size: 18, color: Color(0xFF0284C7)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    AppTranslations.pick(
                                      lang,
                                      en: 'Movement Stages History',
                                      mr: 'हालचाल इतिहास',
                                      hi: 'फ़ाइल गतिविधि इतिहास',
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _showAddStageDialog(fullItem.id, () async {
                                final updated = await repo.getFileTrackerById(fullItem.id);
                                if (updated != null && mounted) {
                                  Navigator.pop(sheetCtx);
                                  _showDetailModal(updated);
                                }
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(
                              AppTranslations.pick(
                                lang,
                                en: 'Add Stage',
                                mr: 'टप्पा जोडा',
                                hi: 'चरण जोड़ें',
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (fullItem.stages.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'No movement stages recorded yet',
                              mr: 'कोणतेही टप्पे नोंदवलेले नाहीत',
                              hi: 'अभी तक कोई चरण दर्ज नहीं किया गया है',
                            ),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: fullItem.stages.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final stage = fullItem.stages[idx];
                            final dateStr = AppTranslations.formatDateTime(stage.createdAt, lang);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.place_outlined, size: 16, color: Color(0xFF0284C7)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppTranslatedText(
                                          stage.stageName,
                                          targetLanguage: lang,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        if (stage.location.isNotEmpty)
                                          AppTranslatedText(
                                            stage.location,
                                            targetLanguage: lang,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                                          ),
                                        if (stage.statusDescription.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: AppTranslatedText(
                                              stage.statusDescription,
                                              targetLanguage: lang,
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(dateStr, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _showAddEditModal(existing: fullItem);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(
                            AppTranslations.pick(
                              lang,
                              en: 'Edit',
                              mr: 'संपादित करा',
                              hi: 'संपादित करें',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'Delete File Tracker?',
                                  mr: 'हटवायचे का?',
                                  hi: 'फ़ाइल ट्रैकर हटाएं?',
                                ),
                              ),
                              content: Text(
                                AppTranslations.pick(
                                  lang,
                                  en: 'This file record and its stages will be permanently deleted.',
                                  mr: 'ही फाईल व इतिहास कायमचा हटवला जाईल.',
                                  hi: 'यह फ़ाइल रिकॉर्ड और इसके चरण स्थायी रूप से हटा दिए जाएंगे।',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: Text(
                                    AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: Text(
                                    AppTranslations.pick(lang, en: 'Delete', mr: 'हटवा', hi: 'हटाएं'),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await repo.deleteFileTracker(fullItem.id);
                            if (mounted) {
                              Navigator.pop(sheetCtx);
                              _fetchTrackers();
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddStageDialog(String trackerId, VoidCallback onAdded) {
    final lang = ref.read(appLanguageProvider);
    final stageCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String newStatus = 'In Progress';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppTranslations.pick(
            lang,
            en: 'Add Movement Stage',
            mr: 'नवीन हालचाल टप्पा जोडा',
            hi: 'नया गतिविधि चरण जोड़ें',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel(
                AppTranslations.pick(
                  lang,
                  en: 'Stage Name *',
                  mr: 'टप्प्याचे नाव *',
                  hi: 'चरण का नाम *',
                ),
              ),
              TextField(
                controller: stageCtrl,
                decoration: _inputDecoration(
                  AppTranslations.pick(
                    lang,
                    en: 'e.g. Sent for Audit Verification',
                    mr: 'उदा. लेखापरीक्षण पडताळणीसाठी पाठवले',
                    hi: 'उदा. ऑडिट सत्यापन हेतु भेजा गया',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildInputLabel(
                AppTranslations.pick(
                  lang,
                  en: 'Location / Office',
                  mr: 'स्थान / कार्यालय',
                  hi: 'स्थान / कार्यालय',
                ),
              ),
              TextField(
                controller: locCtrl,
                decoration: _inputDecoration(
                  AppTranslations.pick(
                    lang,
                    en: 'e.g. Accounts Department, 2nd Floor',
                    mr: 'उदा. लेखा विभाग, २ रा मजला',
                    hi: 'उदा. लेखा विभाग, दूसरी मंजिल',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildInputLabel(
                AppTranslations.pick(
                  lang,
                  en: 'Status Description / Remarks',
                  mr: 'शेरा / सद्यस्थिती तपशील',
                  hi: 'स्थिति विवरण / टिप्पणी',
                ),
              ),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: _inputDecoration(
                  AppTranslations.pick(
                    lang,
                    en: 'e.g. Verified and signed by superintendent',
                    mr: 'उदा. अधीक्षकांनी तपासून स्वाक्षरी केली',
                    hi: 'उदा. अधीक्षक द्वारा सत्यापित और हस्ताक्षरित',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildInputLabel(
                AppTranslations.pick(
                  lang,
                  en: 'Update Status',
                  mr: 'नवीन स्थिती',
                  hi: 'स्थिति अपडेट करें',
                ),
              ),
              DropdownButtonFormField<String>(
                value: newStatus,
                items: _statuses
                    .where((s) => s != 'All')
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(AppTranslations.getStatus(s, lang)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) newStatus = val;
                },
                decoration: _inputDecoration(
                  AppTranslations.pick(lang, en: 'Status', mr: 'स्थिती', hi: 'स्थिति'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppTranslations.pick(lang, en: 'Cancel', mr: 'रद्द करा', hi: 'रद्द करें'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final stageName = stageCtrl.text.trim();
              if (stageName.isEmpty) return;

              final repo = ref.read(fileTrackerRepoProvider);
              final user = ref.read(currentUserProvider);

              await repo.addMovementStage(
                workTrackerId: trackerId,
                stageName: stageName,
                location: locCtrl.text.trim(),
                statusDescription: descCtrl.text.trim(),
                updatedBy: user?.name,
                newTrackerStatus: newStatus,
              );

              if (mounted) {
                Navigator.pop(ctx);
                onAdded();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
            child: Text(
              AppTranslations.pick(lang, en: 'Add Stage', mr: 'जोडा', hi: 'जोड़ें'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
    );
  }

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Column(
      children: [
        // Filter & Search Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) {
                        setState(() => _displayedLimit = 20);
                        _fetchTrackers();
                      },
                      decoration: InputDecoration(
                        hintText: AppTranslations.pick(
                          lang,
                          en: 'Search title, inward/outward no...',
                          mr: 'शीर्षक, आवक/जावक क्र. शोधा...',
                          hi: 'शीर्षक, आवक/जावक क्र. खोजें...',
                        ),
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: AppTranslations.getDownloadReport(lang),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0284C7)),
                    onPressed: _trackers.isEmpty
                        ? null
                        : () => GovOfficeReportGenerator.generateAndPrintFileTrackerReport(
                              trackers: _trackers,
                              statusFilter: _selectedStatus,
                              lang: lang,
                            ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditModal(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Add File',
                        mr: 'नोंदवा',
                        hi: 'फ़ाइल जोड़ें',
                      ),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status Filter Pills
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statuses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final s = _statuses[i];
                    final isSel = _selectedStatus == s;
                    final labelText = s == 'All'
                        ? AppTranslations.getAll(lang)
                        : AppTranslations.getStatus(s, lang);
                    return ChoiceChip(
                      label: Text(
                        labelText,
                        style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF64748B)),
                      ),
                      selected: isSel,
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: Colors.white,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedStatus = s;
                            _displayedLimit = 20;
                          });
                          _fetchTrackers();
                        }
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Files List
        Expanded(
          child: _isLoading
              ? const AppShimmerList(count: 6)
              : _trackers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 8),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'No file trackers found',
                              mr: 'कोणतीही फाईल सापडली नाही',
                              hi: 'कोई फ़ाइल ट्रैकर नहीं मिला',
                            ),
                            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTranslations.pick(
                              lang,
                              en: 'No work tracker records available',
                              mr: 'सध्या कोणतीही फाईल नोंद उपलब्ध नाही',
                              hi: 'फ़िलहाल कोई फ़ाइल रिकॉर्ड उपलब्ध नहीं है',
                            ),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchTrackers,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _visibleTrackers.length + (_trackers.isNotEmpty ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == _visibleTrackers.length) {
                            return AppLoadMoreFooter(
                              currentCount: _visibleTrackers.length,
                              totalCount: _trackers.length,
                              pageSize: 20,
                              onLoadMore: () => setState(() => _displayedLimit += 20),
                              label: AppTranslations.pick(
                                lang,
                                en: 'files',
                                mr: 'फाईली',
                                hi: 'फ़ाइलें',
                              ),
                              isMarathi: lang == 'mr',
                            );
                          }
                          final item = _visibleTrackers[index];
                          final dateStr = AppTranslations.formatDate(item.updatedAt, lang);
                          final inLabel = AppTranslations.pick(
                            lang,
                            en: 'In',
                            mr: 'आवक',
                            hi: 'आवक',
                          );
                          final outLabel = AppTranslations.pick(
                            lang,
                            en: 'Out',
                            mr: 'जावक',
                            hi: 'जावक',
                          );

                          return InkWell(
                            onTap: () => _showDetailModal(item),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: AppTranslatedText(
                                            item.department,
                                            targetLanguage: lang,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusBgColor(item.currentStatus),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          AppTranslations.getStatus(item.currentStatus, lang),
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _getStatusColor(item.currentStatus)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  AppTranslatedText(
                                    item.title,
                                    targetLanguage: lang,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  if (item.subject.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: AppTranslatedText(
                                        item.subject,
                                        targetLanguage: lang,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          if (item.inwardNumber.isNotEmpty) ...[
                                            const Icon(Icons.arrow_downward_rounded, size: 12, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '$inLabel: ${AppTranslations.formatDigits(item.inwardNumber, lang)}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (item.outwardNumber.isNotEmpty) ...[
                                            const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF16A34A)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '$outLabel: ${AppTranslations.formatDigits(item.outwardNumber, lang)}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(dateStr, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
