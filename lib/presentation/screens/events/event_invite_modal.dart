import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/events_repository.dart';

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

  late List<ConstituentInviteContact> _allVoters;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(eventsRepoProvider);
    _allVoters = repo.getVotersForInvites();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ConstituentInviteContact> get _filteredVoters {
    final q = _searchCtrl.text.trim().toLowerCase();
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

    setState(() => _isSending = true);

    final event = widget.event;
    final message =
        '🎉 *Invitation: ${event.title}*\n\nDear Resident,\nYou are cordially invited to attend the community program:\n\n📌 *Event:* ${event.title}\n📅 *Date:* ${event.formattedDate}\n⏰ *Time:* ${event.eventTime}\n📍 *Venue:* ${event.location}\n\nPlease join us with your family.\n\n— *Nagarsevak Amit Chougale*\n(Ward No. 12, Pune Municipal Corporation)';

    final encoded = Uri.encodeComponent(message);
    // If 1 voter selected, send directly to their number. If multiple, open generic WhatsApp share
    final uri = _selectedMobiles.length == 1
        ? Uri.parse('https://wa.me/91${_selectedMobiles.first}?text=$encoded')
        : Uri.parse('https://wa.me/?text=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: message));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation text copied to clipboard!')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'WhatsApp invitations sent to ${_selectedMobiles.length} residents!',
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
    final filtered = _filteredVoters;
    final allSelected = filtered.isNotEmpty && _selectedMobiles.length == filtered.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF16A34A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Send Event Invitations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        widget.event.titleMr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

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
                    hintText: 'Search voters by name or mobile...',
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
                      _buildAreaChip('All Areas (${_allVoters.length})', 'all'),
                      const SizedBox(width: 6),
                      _buildAreaChip('Shaniwar Peth', 'Shaniwar Peth'),
                      const SizedBox(width: 6),
                      _buildAreaChip('Kasba Peth', 'Kasba Peth'),
                      const SizedBox(width: 6),
                      _buildAreaChip('Narayan Peth', 'Narayan Peth'),
                      const SizedBox(width: 6),
                      _buildAreaChip('Rasta Peth', 'Rasta Peth'),
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
                        allSelected ? 'Deselect All' : 'Select All',
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
                    '${_selectedMobiles.length} Selected',
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
                        const Text(
                          'No citizens found.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
                                    Text(
                                      voter.nameMr,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${voter.address} • Age: ${voter.age} yrs',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+91 ${voter.mobile}',
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
                    child: const Text('Cancel'),
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
                          ? 'Sending...'
                          : 'Send WhatsApp Invites (${_selectedMobiles.length})',
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

