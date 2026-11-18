import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/letter_type_model.dart';
import '../../../data/repositories/letters_repository.dart';
import '../../providers/auth_provider.dart';

class LetterTypeManagerSheet extends ConsumerStatefulWidget {
  const LetterTypeManagerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LetterTypeManagerSheet(),
    );
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

  void _showEditModal({LetterTypeModel? existingType}) {
    final isMr = ref.read(isMarathiProvider);
    final nameCtrl = TextEditingController(text: existingType?.name ?? '');
    final nameMrCtrl = TextEditingController(text: existingType?.nameMarathi ?? '');
    final descCtrl = TextEditingController(text: existingType?.description ?? '');
    final templateCtrl = TextEditingController(
      text: existingType?.templateContent ??
          'This is to certify that Mr./Ms. {{name}}, residing at {{address}}, is a resident of Ward 12 to the best of my knowledge.\n\nThis letter is issued upon their request for the purpose of {{purpose}}.\n\nI wish them all the best for their future endeavors.',
    );

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
                    ? (isMr ? 'पत्राचा प्रकार संपादित करा' : 'Edit Letter Type')
                    : (isMr ? 'नवीन पत्र प्रकार जोडा' : 'Add New Letter Type'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMr ? 'इंग्रजी नाव *' : 'Type Name (English) *',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Residential Certificate',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isMr ? 'मराठी नाव' : 'Type Name (Marathi)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameMrCtrl,
                      decoration: InputDecoration(
                        hintText: 'उदा. रहिवासी दाखला',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isMr ? 'वर्णन' : 'Description',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        hintText: isMr ? 'थोडक्यात माहिती' : 'Brief description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isMr ? 'पत्र मजकूर साचा (Template)' : 'Template Content (Placeholders: {{name}}, {{address}}, {{purpose}})',
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
                  child: Text(isMr ? 'रद्द करा' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(content: Text(isMr ? 'कृपया नाव प्रविष्ट करा' : 'Name is required')),
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

                          if (mounted) {
                            Navigator.pop(dialogCtx);
                            _fetchTypes();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isMr ? 'सेव्ह करा' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteType(LetterTypeModel type) async {
    final isMr = ref.read(isMarathiProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMr ? 'प्रकार हटवायचा का?' : 'Delete Letter Type?'),
        content: Text(isMr ? '${type.name} हा प्रकार कायमचा काढला जाईल.' : 'Are you sure you want to delete ${type.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isMr ? 'रद्द' : 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isMr ? 'हटवा' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(lettersRepoProvider);
      await repo.deleteLetterType(type.id);
      _fetchTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMr ? 'पत्रांचे प्रकार व्यवस्थापन' : 'Letter Types Manager',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          isMr ? 'Supabase DB (letter_types)' : 'Synchronized with Supabase DB',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
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
                  isMr ? 'नवीन पत्र प्रकार जोडा' : 'Add New Letter Type',
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
                              isMr ? 'कोणतेही प्रकार आढळले नाहीत' : 'No custom letter types found',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMr ? 'सिस्टीमचे डीफॉल्ट प्रकार वापरले जात आहेत' : 'Standard defaults are currently active',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _types.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _types[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                isMr && item.nameMarathi?.isNotEmpty == true ? item.nameMarathi! : item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              subtitle: item.description != null && item.description!.isNotEmpty
                                  ? Text(item.description!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))
                                  : (item.nameMarathi != null ? Text(item.name, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))) : null),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                                    onPressed: () => _showEditModal(existingType: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
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
