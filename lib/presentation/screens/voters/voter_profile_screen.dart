import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/voter_model.dart';
import '../../../data/repositories/voters_repository.dart';
import 'voter_slip_generator.dart';

class VoterProfileScreen extends ConsumerStatefulWidget {
  final VoterModel voter;

  const VoterProfileScreen({super.key, required this.voter});

  @override
  ConsumerState<VoterProfileScreen> createState() => _VoterProfileScreenState();
}

class _VoterProfileScreenState extends ConsumerState<VoterProfileScreen> {
  late VoterModel _voter;
  List<VoterModel> _familyMembers = [];
  bool _isLoadingFamily = true;

  @override
  void initState() {
    super.initState();
    _voter = widget.voter;
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    if (_voter.houseNo == null || _voter.houseNo!.isEmpty) {
      if (mounted) setState(() => _isLoadingFamily = false);
      return;
    }

    final repo = ref.read(votersRepoProvider);
    final family = await repo.getFamilyMembers(_voter.houseNo!, _voter.booth);

    if (mounted) {
      setState(() {
        _familyMembers = family.where((m) => m.id != _voter.id).toList();
        _isLoadingFamily = false;
      });
    }
  }

  Future<void> _updateFavour(String newFavour) async {
    final repo = ref.read(votersRepoProvider);
    await repo.updateFavour(_voter.id, newFavour);
    setState(() {
      _voter = _voter.copyWith(favour: newFavour);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('राजकीय कल "${_voter.favourLabelMarathi}" म्हणून नोंदवला गेला'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    }
  }

  Future<void> _toggleFriendRelative() async {
    final repo = ref.read(votersRepoProvider);
    await repo.toggleFriendRelative(_voter.id);
    setState(() {
      _voter = _voter.copyWith(isFriendRelative: !_voter.isFriendRelative);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_voter.isFriendRelative
              ? 'आप्तस्वकीय व मित्र यादीत जोडले गेले!'
              : 'आप्तस्वकीय यादीतून काढले गेले'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _callVoter() async {
    if (_voter.mobile == null || _voter.mobile!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('या मतदाराचा मोबाईल नंबर उपलब्ध नाही')),
      );
      return;
    }
    final url = Uri.parse('tel:+91${_voter.mobile}');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  Future<void> _shareSlipOnWhatsApp() async {
    final mobile = _voter.mobile != null ? _voter.mobile!.replaceAll(RegExp(r'\D'), '') : '';
    final msg = Uri.encodeComponent(
      'सस्नेह नमस्कार ${_voter.displayName},\n\n'
      'आपली प्रभाग क्र. १२ ची अधिकृत मतदार स्लिप खालीलप्रमाणे आहे:\n\n'
      '*मतदार नाव:* ${_voter.displayName}\n'
      '*EPIC क्र.:* ${_voter.epicNo}\n'
      '*यादी भाग क्र. / बूथ:* ${_voter.booth}\n'
      '*मतदार यादीतील अ. क्र.:* #${_voter.serialNo ?? "-"}\n'
      '*मतदान केंद्र:* ${_voter.displayPollingStation}\n'
      '*पत्ता:* ${_voter.address}\n\n'
      'कृपया मतदानाच्या दिवशी सोबत ओळखपत्र (EPIC किंवा आधार कार्ड) बाळगावे.\n\n'
      '- कार्यालय, प्रभाग १२ नगरसेवक',
    );

    Uri url;
    if (mobile.isNotEmpty) {
      url = Uri.parse('https://wa.me/91$mobile?text=$msg');
    } else {
      url = Uri.parse('https://wa.me/?text=$msg');
    }

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Color favourColor = const Color(0xFF64748B);
    Color favourBg = const Color(0xFFF1F5F9);

    switch (_voter.favour?.toLowerCase()) {
      case 'favourable':
        favourColor = const Color(0xFF16A34A);
        favourBg = const Color(0xFFDCFCE7);
        break;
      case 'against':
        favourColor = const Color(0xFFDC2626);
        favourBg = const Color(0xFFFEE2E2);
        break;
      case 'neutral':
        favourColor = const Color(0xFF0284C7);
        favourBg = const Color(0xFFE0F2FE);
        break;
      case 'swing':
        favourColor = const Color(0xFFD97706);
        favourBg = const Color(0xFFFEF3C7);
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _voter.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'मतदार तपशील व अधिकृत स्लिप',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _voter.isFriendRelative ? Icons.star_rounded : Icons.star_border_rounded,
              color: _voter.isFriendRelative ? Colors.amberAccent : Colors.white,
            ),
            tooltip: _voter.isFriendRelative ? 'आप्तस्वकीय यादीतून काढा' : 'आप्तस्वकीय म्हणून चिन्हांकित करा',
            onPressed: _toggleFriendRelative,
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            tooltip: 'मतदार स्लिप प्रिंट करा',
            onPressed: () => VoterSlipGenerator.printVoterSlip(_voter),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'व्हॉट्सॲपवर स्लिप पाठवा',
            onPressed: _shareSlipOnWhatsApp,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Top Identity Header Card
          _buildIdentityHeaderCard(favourColor, favourBg),
          const SizedBox(height: 14),

          // Official Voter Slip Card
          _buildOfficialVoterSlipCard(),
          const SizedBox(height: 14),

          // Political Favour / Stance Card
          _buildPoliticalStanceCard(),
          const SizedBox(height: 14),

          // Family Members in Same House Card
          _buildFamilyMembersCard(),
          const SizedBox(height: 14),

          // Polling Station Location Card
          _buildPollingStationCard(),
          const SizedBox(height: 40),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_voter.mobile != null && _voter.mobile!.isNotEmpty) ...[
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone, size: 16, color: Color(0xFF0284C7)),
                  label: const Text('थेट कॉल करा', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _callVoter,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                label: const Text('व्हॉट्सॲप स्लिप', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _shareSlipOnWhatsApp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityHeaderCard(Color favourColor, Color favourBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _voter.displayName.isNotEmpty ? _voter.displayName.substring(0, 1) : 'V',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _voter.displayName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    if (_voter.nameEnglish.isNotEmpty && _voter.nameEnglish != _voter.displayName)
                      Text(
                        _voter.nameEnglish,
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'वय: ${_voter.age} वर्षे • ${_voter.genderLabelMarathi}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        if (_voter.caste != null && _voter.caste!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _voter.caste!,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Serial No Badge
              Row(
                children: [
                  const Icon(Icons.format_list_numbered, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Text(
                    'यादी अ. क्र.: #${_voter.serialNo ?? "-"}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
              // Stance Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: favourBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: favourColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: favourColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _voter.favourLabelMarathi,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: favourColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialVoterSlipCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slip Top Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFF0284C7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.badge_outlined, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'अधिकृत मतदार माहिती स्लिप (Voter Slip)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => VoterSlipGenerator.printVoterSlip(_voter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.print, size: 12, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Text(
                          'प्रिंट स्लिप',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildSlipRow(
                  icon: Icons.credit_card_rounded,
                  label: 'EPIC ओळखपत्र क्र.',
                  value: _voter.epicNo,
                  isCopyable: true,
                ),
                const Divider(height: 14),
                _buildSlipRow(
                  icon: Icons.how_to_vote_outlined,
                  label: 'यादी भाग क्र. / बूथ',
                  value: _voter.booth,
                ),
                const Divider(height: 14),
                _buildSlipRow(
                  icon: Icons.home_outlined,
                  label: 'घर क्रमांक',
                  value: _voter.houseNo != null ? '#${_voter.houseNo}' : 'उपलब्ध नाही',
                ),
                const Divider(height: 14),
                _buildSlipRow(
                  icon: Icons.location_on_outlined,
                  label: 'रहिवासी पत्ता',
                  value: _voter.address,
                ),
                if (_voter.mobile != null && _voter.mobile!.isNotEmpty) ...[
                  const Divider(height: 14),
                  _buildSlipRow(
                    icon: Icons.phone_iphone_rounded,
                    label: 'मोबाईल नंबर',
                    value: '+91 ${_voter.mobile}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlipRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCopyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              if (isCopyable)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.grey),
                  tooltip: 'कॉपी करा',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$value कॉपी केले!'), duration: const Duration(seconds: 1)),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPoliticalStanceCard() {
    final stances = [
      {'key': 'Favourable', 'label': 'अनुकूल', 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)},
      {'key': 'Neutral', 'label': 'तटस्थ', 'color': const Color(0xFF0284C7), 'bg': const Color(0xFFE0F2FE)},
      {'key': 'Against', 'label': 'प्रतिकूल', 'color': const Color(0xFFDC2626), 'bg': const Color(0xFFFEE2E2)},
      {'key': 'Swing', 'label': 'अनिश्चित', 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7)},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.how_to_reg_rounded, size: 18, color: Color(0xFF0284C7)),
                  SizedBox(width: 6),
                  Text(
                    'राजकीय कल व अनुकूलता (Political Stance)',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'मतदाराचा पक्षाकडे असलेला कल नोंदवा:',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: stances.map((st) {
              final isSel = _voter.favour?.toLowerCase() == st['key']!.toString().toLowerCase();
              final c = st['color'] as Color;
              final bg = st['bg'] as Color;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => _updateFavour(st['key']!.toString()),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? bg : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? c : Colors.grey.shade300,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            st['label']!.toString(),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? c : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.family_restroom_rounded, size: 18, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Text(
                    'एकाच घरातील कुटुंबीय (${_voter.houseNo != null ? "घर #${_voter.houseNo}" : ""})',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_familyMembers.length + 1} मतदार',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isLoadingFamily
              ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
              : _familyMembers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'या घर क्रमांकावर इतर कोणताही मतदार नोंदणीकृत नाही.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _familyMembers.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (ctx, idx) {
                        final m = _familyMembers[idx];
                        String inferredRel = 'कुटुंब सदस्य';
                        if (m.relationType != null && m.relationType!.isNotEmpty) {
                          if (m.relationType == 'Spouse') {
                            inferredRel = 'पत्नी/पती';
                          } else if (m.relationType == 'Son') {
                            inferredRel = 'मुलगा';
                          } else if (m.relationType == 'Daughter') {
                            inferredRel = 'मुलगी';
                          } else if (m.relationType == 'Head') {
                            inferredRel = 'कुटुंब प्रमुख';
                          }
                        } else {
                          if (m.age > _voter.age + 18) {
                            inferredRel = 'वडील / आई';
                          } else if (m.age < _voter.age - 18) {
                            inferredRel = 'मुलगा / मुलगी';
                          } else if ((m.age - _voter.age).abs() < 8 && m.gender != _voter.gender) {
                            inferredRel = 'पत्नी / पती';
                          }
                        }

                        return InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => VoterProfileScreen(voter: m)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  child: Text(
                                    m.displayName.isNotEmpty ? m.displayName.substring(0, 1) : 'V',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.displayName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '$inferredRel • वय: ${m.age} वर्षे • ${m.genderLabelMarathi}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                          if (m.serialNo != null) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '• #${m.serialNo}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (m.favour != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: m.favour == 'Favourable'
                                          ? const Color(0xFFDCFCE7)
                                          : (m.favour == 'Against' ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.favourLabelMarathi,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: m.favour == 'Favourable'
                                            ? const Color(0xFF16A34A)
                                            : (m.favour == 'Against' ? const Color(0xFFDC2626) : const Color(0xFF0284C7)),
                                      ),
                                    ),
                                  ),
                                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildPollingStationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_city_rounded, size: 18, color: Color(0xFF0284C7)),
              SizedBox(width: 6),
              Text(
                'मतदान केंद्र तपशील (Polling Station Details)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _voter.displayPollingStation,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            'विधानसभा: २१४ - कसबा पेठ • प्रभाग: १२ • यादी भाग: ${_voter.booth}',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: const [
                Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'मतदानाची वेळ: सकाळी ७:०० ते सायंकाळी ६:०० वाजेपर्यंत',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
