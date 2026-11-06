import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/scheme_model.dart';
import '../../../data/models/voter_model.dart';
import '../../../data/repositories/schemes_repository.dart';
import '../../../data/repositories/voters_repository.dart';
import '../../providers/auth_provider.dart';
import 'scheme_report_generator.dart';

class SchemeDetailScreen extends ConsumerStatefulWidget {
  final SchemeModel scheme;
  final VoidCallback? onSchemeUpdated;

  const SchemeDetailScreen({
    super.key,
    required this.scheme,
    this.onSchemeUpdated,
  });

  @override
  ConsumerState<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends ConsumerState<SchemeDetailScreen> {
  late SchemeModel _scheme;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scheme = widget.scheme;
  }

  void _showApplyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _SchemeApplicationSheet(
        scheme: _scheme,
        onApplied: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application registered successfully!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          if (widget.onSchemeUpdated != null) widget.onSchemeUpdated!();
        },
      ),
    );
  }

  void _showEditSchemeSheet() {
    final nameCtrl = TextEditingController(text: _scheme.name);
    final descCtrl = TextEditingController(text: _scheme.description);
    final eligCtrl = TextEditingController(text: _scheme.eligibility);
    final benCtrl = TextEditingController(text: _scheme.benefits);
    final docCtrl = TextEditingController(text: _scheme.documents);
    String selectedCat = _scheme.category;

    final categories = ['All', 'Women', 'Student', 'Senior Citizen', 'Farmer', 'Health', 'Youth', 'Housing'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Scheme Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    // Name
                    const Text('Scheme Name (English / Marathi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Enter scheme name...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Category
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: categories.contains(selectedCat) ? selectedCat : 'All',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCat = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    // Description
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Describe purpose and background...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Benefits
                    const Text('Benefits & Entitlements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: benCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Financial grant, subsidy, scholarship amount...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Eligibility
                    const Text('Eligibility Criteria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: eligCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Age, income limits, residence criteria...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Documents
                    const Text('Required Documents Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: docCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Aadhaar, Ration card, Income cert, Bank book...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final updated = _scheme.copyWith(
                                  name: nameCtrl.text.trim(),
                                  category: selectedCat,
                                  description: descCtrl.text.trim(),
                                  benefits: benCtrl.text.trim(),
                                  eligibility: eligCtrl.text.trim(),
                                  documents: docCtrl.text.trim(),
                                );
                                Navigator.pop(sheetCtx);
                                setState(() {
                                  _scheme = updated;
                                  _isSaving = true;
                                });
                                await ref.read(schemesRepoProvider).updateScheme(updated);
                                if (mounted) {
                                  setState(() => _isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Scheme updated successfully!')),
                                  );
                                  if (widget.onSchemeUpdated != null) widget.onSchemeUpdated!();
                                }
                              },
                        child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Delete Scheme?'),
        content: Text('Are you sure you want to delete "${_scheme.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await ref.read(schemesRepoProvider).deleteScheme(_scheme.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scheme deleted.')),
                );
                if (widget.onSchemeUpdated != null) widget.onSchemeUpdated!();
                Navigator.pop(context);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);

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
        appBar: AppBar(
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Text(
            isMr ? 'योजनेचा तपशील' : 'Scheme Details',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 22),
              tooltip: 'Download PDF Flyer',
              onPressed: () {
                SchemeReportGenerator.generateAndPrintSingleSchemeFlyer(
                  scheme: _scheme,
                  isMarathi: isMr,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
              tooltip: 'Edit Scheme',
              onPressed: _showEditSchemeSheet,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
              tooltip: 'Delete Scheme',
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scheme Main Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _scheme.bgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _scheme.color.withValues(alpha: 0.3)),
                          ),
                          child: Icon(_scheme.icon, color: _scheme.color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _scheme.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _scheme.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _scheme.color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _scheme.localizedName(isMr),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _scheme.localizedDescription(isMr),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Benefits & Entitlements Box
              _DetailSectionCard(
                icon: Icons.stars_rounded,
                iconColor: const Color(0xFF16A34A),
                borderColor: const Color(0xFFBBF7D0),
                bgColor: const Color(0xFFF0FDF4),
                title: isMr ? 'योजनेचे लाभ व अनुदान' : 'Financial Benefits & Entitlements',
                content: _scheme.localizedBenefits(isMr),
              ),

              const SizedBox(height: 14),

              // Eligibility Criteria Box
              _DetailSectionCard(
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF0284C7),
                borderColor: const Color(0xFFBAE6FD),
                bgColor: const Color(0xFFF0F9FF),
                title: isMr ? 'पात्रता निकष' : 'Eligibility Criteria',
                content: _scheme.localizedEligibility(isMr),
              ),

              const SizedBox(height: 14),

              // Documents Required Box
              _DetailSectionCard(
                icon: Icons.checklist_rounded,
                iconColor: const Color(0xFFD97706),
                borderColor: const Color(0xFFFDE68A),
                bgColor: const Color(0xFFFFFBEB),
                title: isMr ? 'आवश्यक कागदपत्रे' : 'Required Documents Checklist',
                content: _scheme.localizedDocuments(isMr),
              ),

              const SizedBox(height: 16),

              // Helpdesk & Ward Office Contact
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Color(0xFF0284C7), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMr ? 'नगरसेवक कार्यालय सहाय्यता कक्ष' : 'Ward Office Citizen Helpdesk',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMr ? 'प्रभाग १२ कार्यालय | सोमवार - शनिवार, स. १० ते सायं. ६' : 'Ward 12 Office | Mon - Sat, 10:00 AM - 6:00 PM',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    SchemeReportGenerator.generateAndPrintSingleSchemeFlyer(
                      scheme: _scheme,
                      isMarathi: isMr,
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    isMr ? 'माहिती पत्रक' : 'PDF Flyer',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showApplyModal,
                  icon: const Icon(Icons.assignment_ind_rounded, size: 20),
                  label: Text(
                    isMr ? 'नागरिकाचा अर्ज भरा' : 'Apply for Citizen',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final Color bgColor;
  final String title;
  final String content;

  const _DetailSectionCard({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.bgColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // Split bullet points if text contains commas or bullet markers
    final lines = content.split(RegExp(r'[,;]|\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (lines.length > 1)
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _SchemeApplicationSheet extends ConsumerStatefulWidget {
  final SchemeModel scheme;
  final VoidCallback onApplied;

  const _SchemeApplicationSheet({
    required this.scheme,
    required this.onApplied,
  });

  @override
  ConsumerState<_SchemeApplicationSheet> createState() => _SchemeApplicationSheetState();
}

class _SchemeApplicationSheetState extends ConsumerState<_SchemeApplicationSheet> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _benefitCtrl = TextEditingController();
  int? _selectedVoterId;
  bool _isSubmitting = false;

  void _openVoterPicker() {
    final voterSearchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Citizen / Voter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bCtx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: voterSearchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search voter by name or EPIC ID...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<VoterModel>>(
                      future: ref.read(votersRepoProvider).searchVoters(
                            query: voterSearchCtrl.text.trim().isNotEmpty ? voterSearchCtrl.text.trim() : null,
                            pageSize: 40,
                          ),
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final voters = snapshot.data ?? [];
                        if (voters.isEmpty) {
                          return const Center(child: Text('No voters found in database'));
                        }
                        return ListView.separated(
                          itemCount: voters.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final v = voters[idx];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF0F9FF),
                                child: Text(
                                  v.displayName.isNotEmpty ? v.displayName[0] : 'V',
                                  style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(v.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('${v.epicNo.isNotEmpty ? "EPIC: ${v.epicNo} | " : ""}${v.address}', style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0284C7)),
                              onTap: () {
                                Navigator.pop(bCtx);
                                setState(() {
                                  _nameCtrl.text = v.displayName;
                                  if (v.mobile != null && v.mobile!.isNotEmpty) {
                                    _mobileCtrl.text = v.mobile!;
                                  }
                                  if (v.address.isNotEmpty) {
                                    _addressCtrl.text = v.address;
                                  }
                                  _selectedVoterId = int.tryParse(v.id);
                                });
                              },
                            );
                          },
                        );
                      },
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Citizen Scheme Application',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        widget.scheme.name,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Applicant Name & Link Voter button
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Applicant Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter full name...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _openVoterPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.person_search_rounded, size: 18, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Text('Voters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Mobile Number
            const Text('Mobile Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '10-digit mobile number...',
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 14),

            // Residential Address / Ward Area
            const Text('Address / Prabhag Area *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'House no, lane, prabhag area...',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 14),

            // Expected Benefit / Note
            const Text('Expected Benefit / Sanction Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _benefitCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. ₹1,500/month or ₹2.5 Lakhs grant...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 14),

            // Officer Remarks / Follow-up notes
            const Text('Officer / Office Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Documents verified, verification token...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter applicant name')),
                          );
                          return;
                        }
                        if (_mobileCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter applicant mobile number')),
                          );
                          return;
                        }

                        setState(() => _isSubmitting = true);
                        final app = SchemeApplicationModel(
                          id: 0,
                          schemeId: widget.scheme.id,
                          schemeName: widget.scheme.name,
                          voterId: _selectedVoterId,
                          applicantName: _nameCtrl.text.trim(),
                          mobile: _mobileCtrl.text.trim(),
                          address: _addressCtrl.text.trim(),
                          status: 'Pending',
                          benefit: _benefitCtrl.text.trim().isNotEmpty ? _benefitCtrl.text.trim() : null,
                          notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                          createdAt: DateTime.now(),
                        );

                        await ref.read(schemesRepoProvider).createApplication(app);
                        if (mounted) {
                          setState(() => _isSubmitting = false);
                          Navigator.pop(context);
                          widget.onApplied();
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

