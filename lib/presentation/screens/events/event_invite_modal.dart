import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/events_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_modal_sheet.dart';

class EventInviteModal extends ConsumerStatefulWidget {
  final EventModel event;

  const EventInviteModal({super.key, required this.event});

  static Future<void> show(BuildContext context, EventModel event) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventInviteModal(event: event),
    );
  }

  @override
  ConsumerState<EventInviteModal> createState() => _EventInviteModalState();
}

class _EventInviteModalState extends ConsumerState<EventInviteModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedMobiles = {};
  String _selectedArea = 'all';
  int? _minAge;
  int? _maxAge;
  bool _isSending = false;

  List<ConstituentInviteContact> _allVoters = [];

  @override
  void initState() {
    super.initState();
    _loadVoters();
  }

  Future<void> _loadVoters() async {
    final repo = ref.read(eventsRepoProvider);
    final list = await repo.getVotersForInvites();
    if (mounted) {
      setState(() => _allVoters = list);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ConstituentInviteContact> get _filteredVoters {
    final q = AppTranslations.normalizeAsciiDigits(_searchCtrl.text.trim())
        .toLowerCase();
    return _allVoters.where((v) {
      final matchesSearch = q.isEmpty ||
          v.name.toLowerCase().contains(q) ||
          v.nameMr.toLowerCase().contains(q) ||
          v.mobile.contains(q) ||
          v.address.toLowerCase().contains(q);

      final matchesArea =
          _selectedArea == 'all' || v.area.toLowerCase() == _selectedArea.toLowerCase();

      final matchesMinAge = _minAge == null || v.age >= _minAge!;
      final matchesMaxAge = _maxAge == null || v.age <= _maxAge!;

      return matchesSearch && matchesArea && matchesMinAge && matchesMaxAge;
    }).toList();
  }

  void _toggleSelectAll() {
    final filtered = _filteredVoters;
    setState(() {
      if (_selectedMobiles.length == filtered.length && filtered.isNotEmpty) {
        _selectedMobiles.clear();
      } else {
        _selectedMobiles.clear();
        for (final v in filtered) {
          _selectedMobiles.add(v.mobile);
        }
      }
    });
  }

  Future<void> _handleSendWhatsAppInvites() async {
    if (_selectedMobiles.isEmpty) return;

    final lang = ref.read(appLanguageProvider);
    setState(() => _isSending = true);

    final event = widget.event;
    final rawTitle =
        lang == 'mr' && event.titleMr.isNotEmpty ? event.titleMr : event.title;
    final rawLoc =
        lang == 'mr' && event.locationMr.isNotEmpty ? event.locationMr : event.location;
    final eventTitle =
        DynamicTranslationService.getCachedTranslation(rawTitle, lang) ?? rawTitle;
    final eventLoc =
        DynamicTranslationService.getCachedTranslation(rawLoc, lang) ?? rawLoc;
    final eventDate = event.formattedDateFor(lang);
    final eventTime = AppTranslations.formatDigits(event.eventTime, lang);

    final message = lang == 'mr'
        ? '*निमंत्रण: $eventTitle*\n\nप्रिय नागरिक,\nआपणास या सामुदायिक कार्यक्रमासाठी सस्नेह निमंत्रित करण्यात येत आहे:\n\n*कार्यक्रम:* $eventTitle\n*तारीख:* $eventDate\n*वेळ:* $eventTime\n*ठिकाण:* $eventLoc\n\nकृपया सहकुटुंब उपस्थित राहावे ही विनंती.\n\n— *नगरसेवक अमित चौगुले*\n(प्रभाग क्र. १२, पुणे महानगरपालिका)'
        : (lang == 'hi'
            ? '*निमंत्रण: $eventTitle*\n\nप्रिय नागरिक,\nआपको इस सामुदायिक कार्यक्रम में सादर आमंत्रित किया जाता है:\n\n*कार्यक्रम:* $eventTitle\n*दिनांक:* $eventDate\n*समय:* $eventTime\n*स्थान:* $eventLoc\n\nकृपया सपरिवार पधारें।\n\n— *नगरसेवक अमित चौगुले*\n(वार्ड क्र. १२, पुणे महानगरपालिका)'
            : '*Invitation: $eventTitle*\n\nDear Resident,\nYou are cordially invited to attend the community program:\n\n*Event:* $eventTitle\n*Date:* $eventDate\n*Time:* $eventTime\n*Venue:* $eventLoc\n\nPlease join us with your family.\n\n— *Nagarsevak Amit Chougale*\n(Ward No. 12, Pune Municipal Corporation)');

    final encoded = Uri.encodeComponent(message);
    // If 1 voter selected, send directly to their number. If multiple, open generic WhatsApp share
    final uri = _selectedMobiles.length == 1
        ? Uri.parse('https://wa.me/91${AppTranslations.normalizeAsciiDigits(_selectedMobiles.first)}?text=$encoded')
        : Uri.parse('https://wa.me/?text=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: message));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppTranslations.pick(
                  lang,
                  en: 'Invitation text copied to clipboard!',
                  mr: 'निमंत्रण मजकूर क्लिपबोर्डवर कॉपी केला!',
                  hi: 'निमंत्रण संदेश क्लिपबोर्ड पर कॉपी किया गया!',
                ),
              ),
            ),
          );
        }
      }

      // Add RSVP automatically
      final repo = ref.read(eventsRepoProvider);
      for (final mob in _selectedMobiles) {
        final voter = _allVoters.firstWhere((v) => v.mobile == mob);
        await repo.addRsvp(
          event.id,
          EventRsvpModel(
            id: 'rsvp-${DateTime.now().millisecondsSinceEpoch}-${voter.id}',
            voterName: voter.name,
            voterNameMr: voter.nameMr,
            mobile: voter.mobile,
            address: voter.address,
            status: RsvpStatus.going,
            responseSource: 'WhatsApp Broadcast',
            respondedAt: DateTime.now(),
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        final cntStr = AppTranslations.formatDigits(_selectedMobiles.length, lang);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.pick(
                lang,
                en: 'WhatsApp invitations sent to $cntStr residents!',
                mr: '$cntStr नागरिकांना WhatsApp निमंत्रण पाठवले!',
                hi: '$cntStr नागरिकों को WhatsApp निमंत्रण भेजा गया!',
              ),
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final filtered = _filteredVoters;
    final allSelected = filtered.isNotEmpty && _selectedMobiles.length == filtered.length;
    final rawEventTitle = lang == 'mr' && widget.event.titleMr.isNotEmpty
        ? widget.event.titleMr
        : widget.event.title;
    final headerSub =
        DynamicTranslationService.getCachedTranslation(rawEventTitle, lang) ??
            rawEventTitle;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          AppModalHeader(
            icon: Icons.send_rounded,
            title: AppTranslations.pick(
              lang,
              en: 'Send Event Invitations',
              mr: 'कार्यक्रमाचे निमंत्रण पाठवा',
              hi: 'कार्यक्रम निमंत्रण भेजें',
            ),
            subtitle: headerSub,
            onClose: () => Navigator.pop(context),
          ),

          // Search & Filters Strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: AppTranslations.pick(
                      lang,
                      en: 'Search voters by name or mobile...',
                      mr: 'मतदाराचे नाव किंवा मोबाइल शोधा...',
                      hi: 'मतदाता का नाम या मोबाइल खोजें...',
                    ),
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _searchCtrl.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 8),

                // Area Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAreaChip(
                        '${AppTranslations.getAllAreas(lang)} (${AppTranslations.formatDigits(_allVoters.length, lang)})',
                        'all',
                      ),
                      const SizedBox(width: 6),
                      _buildAreaChip(
                        AppTranslations.getAreaName('Shaniwar Peth', lang),
                        'Shaniwar Peth',
                      ),
                      const SizedBox(width: 6),
                      _buildAreaChip(
                        AppTranslations.getAreaName('Kasba Peth', lang),
                        'Kasba Peth',
                      ),
                      const SizedBox(width: 6),
                      _buildAreaChip(
                        AppTranslations.getAreaName('Narayan Peth', lang),
                        'Narayan Peth',
                      ),
                      const SizedBox(width: 6),
                      _buildAreaChip(
                        AppTranslations.getAreaName('Rasta Peth', lang),
                        'Rasta Peth',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Select All Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: _toggleSelectAll,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: allSelected,
                        activeColor: const Color(0xFF16A34A),
                        onChanged: (_) => _toggleSelectAll(),
                      ),
                      Text(
                        allSelected
                            ? AppTranslations.pick(
                                lang,
                                en: 'Deselect All',
                                mr: 'सर्व रद्द करा',
                                hi: 'सभी अचयनित करें',
                              )
                            : AppTranslations.pick(
                                lang,
                                en: 'Select All',
                                mr: 'सर्व निवडा',
                                hi: 'सभी चुनें',
                              ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppTranslations.pick(
                      lang,
                      en: '${AppTranslations.formatDigits(_selectedMobiles.length, lang)} Selected',
                      mr: '${AppTranslations.formatDigits(_selectedMobiles.length, lang)} निवडले',
                      hi: '${AppTranslations.formatDigits(_selectedMobiles.length, lang)} चयनित',
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Voters List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          AppTranslations.pick(
                            lang,
                            en: 'No citizens found.',
                            mr: 'कोणतेही नागरिक आढळले नाहीत.',
                            hi: 'कोई नागरिक नहीं मिला।',
                          ),
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, idx) {
                      final voter = filtered[idx];
                      final isChecked = _selectedMobiles.contains(voter.mobile);
                      final voterDisplayName =
                          lang == 'mr' && voter.nameMr.isNotEmpty
                              ? voter.nameMr
                              : voter.name;
                      final ageSuffix = AppTranslations.pick(
                        lang,
                        en: '• Age: ${AppTranslations.formatDigits(voter.age, lang)} yrs',
                        mr: '• वय: ${AppTranslations.formatDigits(voter.age, lang)} वर्षे',
                        hi: '• आयु: ${AppTranslations.formatDigits(voter.age, lang)} वर्ष',
                      );

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              _selectedMobiles.remove(voter.mobile);
                            } else {
                              _selectedMobiles.add(voter.mobile);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                activeColor: const Color(0xFF16A34A),
                                onChanged: (_) {
                                  setState(() {
                                    if (isChecked) {
                                      _selectedMobiles.remove(voter.mobile);
                                    } else {
                                      _selectedMobiles.add(voter.mobile);
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppTranslatedText(
                                      voterDisplayName,
                                      isName: true,
                                      targetLanguage: lang,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: AppTranslatedText(
                                            voter.address,
                                            targetLanguage: lang,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          ageSuffix,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${AppTranslations.formatDigits("91 ${voter.mobile}", lang)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      AppTranslations.pick(
                        lang,
                        en: 'Cancel',
                        mr: 'रद्द करा',
                        hi: 'रद्द करें',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selectedMobiles.isEmpty || _isSending
                        ? null
                        : _handleSendWhatsAppInvites,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSending
                          ? AppTranslations.pick(
                              lang,
                              en: 'Sending...',
                              mr: 'पाठवत आहे...',
                              hi: 'भेज रहे हैं...',
                            )
                          : AppTranslations.pick(
                              lang,
                              en: 'Send WhatsApp Invites (${AppTranslations.formatDigits(_selectedMobiles.length, lang)})',
                              mr: 'WhatsApp निमंत्रण (${AppTranslations.formatDigits(_selectedMobiles.length, lang)})',
                              hi: 'WhatsApp निमंत्रण (${AppTranslations.formatDigits(_selectedMobiles.length, lang)})',
                            ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChip(String label, String value) {
    final isSelected = _selectedArea == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFF334155),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF16A34A),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
      ),
      onSelected: (_) => setState(() => _selectedArea = value),
    );
  }
}

