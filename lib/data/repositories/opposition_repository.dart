import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/opposition_model.dart';

final oppositionRepoProvider = Provider<OppositionRepository>((ref) => OppositionRepository());

class OppositionRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  OppositionRepository();

  // Realistic seed data matching Nagarsevak-Managment in Pune Prabhag 12
  final List<OppositionMemberModel> _seedMembers = [
    // 1. INC Candidate
    OppositionMemberModel(
      id: 'opp-cand-1',
      name: 'Adv. रमेश सुरेश शिंदे',
      mobile: '+91 98220 11223',
      party: 'INC',
      role: 'माजी नगरसेवक व गटनेते',
      area: 'टिळक चौक, सेक्टर ३',
      strongholds: ['टिळक चौक', 'शांती नगर', 'बूथ क्र. ४-६', 'आझाद गल्ली'],
      notes: 'वकील वर्ग व जुन्या व्यापारी पेठांमध्ये चांगला जनसंपर्क. आगामी महापालिका निवडणुकीसाठी सक्रिय प्रचार मोहीम सुरू केली आहे.',
      isCandidate: true,
      constituency: 'प्रभाग क्र. १२ (पुणे मनपा)',
      opposingCandidate: 'विद्यमान नगरसेवक (आपण)',
      candidacyStatus: 'Declared',
      activities: [
        OppositionActivityModel(
          id: 'act-101',
          date: '2026-10-24',
          title: 'नागरी हक्क मोर्चा व जनसंवाद बैठक',
          description: 'पाणीटंचाई आणि ड्रेनेज लाईनच्या कामातील विलंबावर महापालिका क्षेत्रीय कार्यालयावर मोर्चा काढला.',
          location: 'सेक्टर ३ चौक',
        ),
        OppositionActivityModel(
          id: 'act-102',
          date: '2026-10-10',
          title: 'जेष्ठ नागरिक आरोग्य तपासणी शिबिर',
          description: 'शांती नगर सांस्कृतिक भवनात मोफत आरोग्य तपासणी शिबिराचे आयोजन केले.',
          location: 'शांती नगर हॉल',
        ),
      ],
      negativeStories: [
        OppositionNegativeStoryModel(
          id: 'story-101',
          date: '2026-09-18',
          title: 'अनधिकृत गाळे बांधकामात महापालिका नोटीस',
          severity: 'High',
          source: 'https://punenews.example.com/illegal-shops-notice',
          description: 'मार्केट यार्ड परिसरातील आरक्षित जागेवर बेकायदेशीर व्यावसायिक गाळे बांधल्याप्रकरणी अतिक्रमण विभागाने नोटीस बजावली होती.',
        ),
        OppositionNegativeStoryModel(
          id: 'story-102',
          date: '2026-06-12',
          title: 'सार्वजनिक रस्ता रुंदीकरणास विरोध',
          severity: 'Medium',
          source: 'सकाळ वृत्तपत्र कात्रण',
          description: 'स्वतःच्या व्यापारी भागीदारांचे नुकसान टाळण्यासाठी मुख्य डीपी रोड रुंदीकरणाच्या विकास आराखड्यात हरकती नोंदवून अडथळा आणला.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),

    // 2. NCP Candidate
    OppositionMemberModel(
      id: 'opp-cand-2',
      name: 'सुनील दत्तात्रय गायकवाड',
      mobile: '+91 94220 33445',
      party: 'NCP',
      role: 'शहर सरचिटणीस व प्रभाग संघटक',
      area: 'विठ्ठल मंदिर परिसर, प्रभात कॉलनी',
      strongholds: ['विठ्ठल चौक', 'गल्ली क्र. ३ व ४', 'प्रभात कॉलनी', 'बूथ क्र. ९-११'],
      notes: 'स्थानिक गणेश मंडळे व तरुण कार्यकर्त्यांचे मजबूत जाळे. दहीहंडी व क्रीडा स्पर्धांच्या माध्यमातून मतदारांशी थेट संपर्क ठेवतात.',
      isCandidate: true,
      constituency: 'प्रभाग क्र. १२ (पुणे मनपा)',
      opposingCandidate: 'विद्यमान नगरसेवक (आपण)',
      candidacyStatus: 'Contesting',
      activities: [
        OppositionActivityModel(
          id: 'act-201',
          date: '2026-10-20',
          title: 'भव्य रक्तदान शिबिर व युवा संवाद',
          description: 'प्रभात कॉलनी मैदानात १०० हून अधिक दात्यांचे रक्तदान आणि युवकांसाठी स्पर्धा परीक्षा मार्गदर्शन.',
          location: 'प्रभात कॉलनी मैदान',
        ),
      ],
      negativeStories: [
        OppositionNegativeStoryModel(
          id: 'story-201',
          date: '2026-08-05',
          title: 'कचरा व्यवस्थापन निविदा वाटपात वाद',
          severity: 'Medium',
          source: 'महानगरपालिका स्थायी समिती टिप्पणी',
          description: 'माजी कार्यकाळात स्वतःच्या नातेवाईकाच्या कंपनीला घनकचरा वाहतुकीचे कंत्राट देण्याचा प्रयत्न उघडकीस आला होता.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 75)),
    ),

    // 3. MNS Candidate
    OppositionMemberModel(
      id: 'opp-cand-3',
      name: 'प्रवीण विठ्ठल भोसले',
      mobile: '+91 98901 55667',
      party: 'MNS',
      role: 'विभाग अध्यक्ष',
      area: 'मार्केट यार्ड परिसर, गणेश नगर',
      strongholds: ['मार्केट यार्ड', 'रिक्षा स्टँड', 'गणेश नगर', 'बूथ क्र. १४-१६'],
      notes: 'स्थानिक रिक्षा चालक, छोटे व्यावसायिक व फेरीवाला युनियनवर प्रभाव. आक्रमक आंदोलने व सोशल मीडिया रील द्वारे प्रसिद्धी मिळवण्याचा प्रयत्न.',
      isCandidate: true,
      constituency: 'प्रभाग क्र. १२ (पुणे मनपा)',
      opposingCandidate: 'विद्यमान नगरसेवक (आपण)',
      candidacyStatus: 'Declared',
      activities: [
        OppositionActivityModel(
          id: 'act-301',
          date: '2026-10-15',
          title: 'रस्त्यावरील खड्ड्यांवर ताशे वाजवून आंदोलन',
          description: 'मुख्य रस्त्यावरील खड्डे न बुजवल्याबद्दल महापालिका अभियंत्यांच्या कार्यालयात ताशे वाजवून घोषणाबाजी केली.',
          location: 'PMC प्रभाग कार्यालय',
        ),
      ],
      negativeStories: [
        OppositionNegativeStoryModel(
          id: 'story-301',
          date: '2026-07-22',
          title: 'अधिकृत महापालिका कर्मचाऱ्यांशी अरेरावी',
          severity: 'Low',
          source: 'विभागीय पोलीस स्टेशन अदखलपात्र गुन्हा (NC)',
          description: 'पाण्याच्या मीटर तपासणीसाठी आलेल्या महापालिका कर्मचाऱ्यांना अरेरावी करून कामात अडथळा आणल्याची तक्रार.',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),

    // 4. Worker linked to Ramesh Shinde (INC)
    OppositionMemberModel(
      id: 'opp-wrk-1',
      name: 'सचिन दिलीप मोरे',
      mobile: '+91 97631 88990',
      party: 'INC',
      role: 'युवक काँग्रेस प्रभाग अध्यक्ष',
      area: 'टिळक नगर',
      strongholds: ['टिळक नगर चौक', 'चाळ क्र. २'],
      notes: 'Adv. रमेश शिंदे यांचे मुख्य प्रचार व्यवस्थापक. घरोघरी पत्रके वाटणे व बूथ कमिटी बैठका घेण्याचे काम पाहतात.',
      isCandidate: false,
      candidateId: 'opp-cand-1',
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
    ),

    // 5. Worker linked to Ramesh Shinde (INC)
    OppositionMemberModel(
      id: 'opp-wrk-2',
      name: 'अमोल दशरथ कदम',
      mobile: '+91 98812 77441',
      party: 'INC',
      role: 'शाखा सचिव',
      area: 'शांती नगर',
      strongholds: ['शांती नगर हाउसिंग सोसायटी'],
      notes: 'सोसायटी पदाधिकाऱ्यांशी संपर्क आणि मतदार यादी पडताळणीचे काम सांभाळतात.',
      isCandidate: false,
      candidateId: 'opp-cand-1',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),

    // 6. Worker linked to Sunil Gaikwad (NCP)
    OppositionMemberModel(
      id: 'opp-wrk-3',
      name: 'महेश बबनराव पाटील',
      mobile: '+91 99224 33112',
      party: 'NCP',
      role: 'बूथ क्र. १० प्रमुख',
      area: 'विठ्ठल चौक',
      strongholds: ['विठ्ठल मंदिर परिसर'],
      notes: 'सुनील गायकवाड यांच्या टीममधील सक्रिय बूथ समन्वयक.',
      isCandidate: false,
      candidateId: 'opp-cand-2',
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    ),

    // 7. Worker linked to Sunil Gaikwad (NCP)
    OppositionMemberModel(
      id: 'opp-wrk-4',
      name: 'विकास रामचंद्र पवार',
      mobile: '+91 95521 66443',
      party: 'NCP',
      role: 'सोशल मीडिया समन्वयक',
      area: 'प्रभात कॉलनी',
      strongholds: ['प्रभात कॉलनी ब्लॉक ए'],
      notes: 'फेसबुक व व्हॉट्सॲप ग्रुप्सवर विरोधकांची बाजू मांडणे आणि स्थानिक समस्यांचे व्हिडिओ प्रसारित करणे.',
      isCandidate: false,
      candidateId: 'opp-cand-2',
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    ),

    // 8. Worker linked to Pravin Bhosale (MNS)
    OppositionMemberModel(
      id: 'opp-wrk-5',
      name: 'संतोष नारायण जगताप',
      mobile: '+91 98239 44556',
      party: 'MNS',
      role: 'शाखा अध्यक्ष',
      area: 'गणेश नगर',
      strongholds: ['गणेश नगर मेन रोड'],
      notes: 'मनसेच्या आंदोलनांचे आयोजन आणि स्थानिक फेरीवाल्यांचे संघटन.',
      isCandidate: false,
      candidateId: 'opp-cand-3',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),

    // 9. Independent Candidate (Rebel)
    OppositionMemberModel(
      id: 'opp-cand-4',
      name: 'दीपक शंकर जगदाळे',
      mobile: '+91 94235 66778',
      party: 'Independent',
      role: 'माजी नगरसेवक (अपक्ष)',
      area: 'जुनी चाळ, हनुमान नगर',
      strongholds: ['हनुमान नगर', 'जुनी चाळ', 'बूथ क्र. १ व २'],
      notes: 'बंडखोर अपक्ष उमेदवार म्हणून उमेदवारी जाहीर केली आहे. झोपडपट्टी भागातील मतदारांवर व्यक्तिगत प्रभाव.',
      isCandidate: true,
      constituency: 'प्रभाग क्र. १२ (पुणे मनपा)',
      opposingCandidate: 'विद्यमान नगरसेवक (आपण)',
      candidacyStatus: 'Declared',
      activities: [
        OppositionActivityModel(
          id: 'act-401',
          date: '2026-10-18',
          title: 'हनुमान नगर पदयात्रा',
          description: 'स्थानिक रहिवाशांच्या भेटीगाठी व घरपट्टी सवलत मिळवून देण्याचे आश्वासन.',
          location: 'हनुमान नगर',
        ),
      ],
      negativeStories: [],
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),

    // 10. Shivsena UBT Worker (Unlinked)
    OppositionMemberModel(
      id: 'opp-wrk-6',
      name: 'संजय काशिनाथ माने',
      mobile: '+91 98902 33881',
      party: 'UBT',
      role: 'उपविभाग प्रमुख',
      area: 'समर्थ नगर',
      strongholds: ['समर्थ नगर', 'शाखा क्र. ४'],
      notes: 'शिवसेना उबाठा पक्षाचे स्थानिक संघटन सांभाळतात. आगामी महापालिका निवडणुकीसाठी पक्षादेशाची वाट पाहत आहेत.',
      isCandidate: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  /// Fetch opposition members with filtering
  Future<List<OppositionMemberModel>> getMembers({
    String? party,
    String? type,
    String? area,
    String? query,
  }) async {
    try {
      var dbQuery = _client.from('opposition_karyakartas').select('*');
      final tId = _tenantId;
      if (tId != null && tId.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', tId);
      }
      final response = await dbQuery.order('created_at', ascending: false);
      if ((response as List).isNotEmpty) {
        final dbList = response.map((json) => OppositionMemberModel.fromJson(json)).toList();
        return _applyFilters(dbList, party: party, type: type, area: area, query: query);
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 100));
    return _applyFilters(_seedMembers, party: party, type: type, area: area, query: query);
  }

  /// Get candidate name by ID
  String getCandidateName(String candidateId) {
    final cand = _seedMembers.where((m) => m.id == candidateId).firstOrNull;
    return cand?.name ?? '';
  }

  /// Filter helper
  List<OppositionMemberModel> _applyFilters(
    List<OppositionMemberModel> list, {
    String? party,
    String? type,
    String? area,
    String? query,
  }) {
    return list.where((m) {
      if (party != null && party.isNotEmpty && party != 'all') {
        if (m.party.toUpperCase() != party.toUpperCase()) return false;
      }

      if (type != null && type.isNotEmpty && type != 'all') {
        if (type == 'candidate' && !m.isCandidate) return false;
        if (type == 'worker' && m.isCandidate) return false;
      }

      if (area != null && area.isNotEmpty) {
        final mArea = (m.area ?? '').toLowerCase();
        if (!mArea.contains(area.toLowerCase())) return false;
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final nameMatch = m.name.toLowerCase().contains(q);
        final roleMatch = (m.role ?? '').toLowerCase().contains(q);
        final areaMatch = (m.area ?? '').toLowerCase().contains(q);
        final notesMatch = (m.notes ?? '').toLowerCase().contains(q);
        final constMatch = (m.constituency ?? '').toLowerCase().contains(q);
        final oppMatch = (m.opposingCandidate ?? '').toLowerCase().contains(q);
        final strongMatch = m.strongholds.any((s) => s.toLowerCase().contains(q));
        if (!nameMatch && !roleMatch && !areaMatch && !notesMatch && !constMatch && !oppMatch && !strongMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Add new opposition member
  Future<void> addMember(OppositionMemberModel member) async {
    try {
      final payload = member.toJson();
      final tId = _tenantId;
      if (tId != null && tId.isNotEmpty) payload['tenant_id'] = tId;
      await _client.from('opposition_karyakartas').insert(payload);
    } catch (_) {}

    _seedMembers.insert(0, member);
  }

  /// Update existing opposition member
  Future<void> updateMember(OppositionMemberModel member) async {
    try {
      final payload = member.toJson();
      await _client.from('opposition_karyakartas').update(payload).eq('id', member.id);
    } catch (_) {}

    final idx = _seedMembers.indexWhere((m) => m.id == member.id);
    if (idx != -1) {
      _seedMembers[idx] = member;
    }
  }

  /// Delete opposition member
  Future<void> deleteMember(String id) async {
    try {
      await _client.from('opposition_karyakartas').delete().eq('id', id);
    } catch (_) {}

    _seedMembers.removeWhere((m) => m.id == id);
    // Also unlink workers linked to this candidate
    for (int i = 0; i < _seedMembers.length; i++) {
      if (_seedMembers[i].candidateId == id) {
        _seedMembers[i] = _seedMembers[i].copyWith(candidateId: null);
      }
    }
  }

  /// Add campaign activity
  Future<void> addActivity(String memberId, OppositionActivityModel activity) async {
    final idx = _seedMembers.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      final current = _seedMembers[idx];
      final updatedActivities = [activity, ...current.activities];
      _seedMembers[idx] = current.copyWith(activities: updatedActivities);

      try {
        await _client.from('opposition_karyakartas').update({
          'activities': updatedActivities.map((a) => a.toJson()).toList(),
        }).eq('id', memberId);
      } catch (_) {}
    }
  }

  /// Delete campaign activity
  Future<void> deleteActivity(String memberId, String activityId) async {
    final idx = _seedMembers.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      final current = _seedMembers[idx];
      final updatedActivities = current.activities.where((a) => a.id != activityId).toList();
      _seedMembers[idx] = current.copyWith(activities: updatedActivities);

      try {
        await _client.from('opposition_karyakartas').update({
          'activities': updatedActivities.map((a) => a.toJson()).toList(),
        }).eq('id', memberId);
      } catch (_) {}
    }
  }

  /// Add negative story / controversy
  Future<void> addNegativeStory(String memberId, OppositionNegativeStoryModel story) async {
    final idx = _seedMembers.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      final current = _seedMembers[idx];
      final updatedStories = [story, ...current.negativeStories];
      _seedMembers[idx] = current.copyWith(negativeStories: updatedStories);

      try {
        await _client.from('opposition_karyakartas').update({
          'negative_stories': updatedStories.map((s) => s.toJson()).toList(),
        }).eq('id', memberId);
      } catch (_) {}
    }
  }

  /// Update negative story / controversy
  Future<void> updateNegativeStory(String memberId, OppositionNegativeStoryModel story) async {
    final idx = _seedMembers.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      final current = _seedMembers[idx];
      final updatedStories = current.negativeStories.map((s) => s.id == story.id ? story : s).toList();
      _seedMembers[idx] = current.copyWith(negativeStories: updatedStories);

      try {
        await _client.from('opposition_karyakartas').update({
          'negative_stories': updatedStories.map((s) => s.toJson()).toList(),
        }).eq('id', memberId);
      } catch (_) {}
    }
  }

  /// Delete negative story
  Future<void> deleteNegativeStory(String memberId, String storyId) async {
    final idx = _seedMembers.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      final current = _seedMembers[idx];
      final updatedStories = current.negativeStories.where((s) => s.id != storyId).toList();
      _seedMembers[idx] = current.copyWith(negativeStories: updatedStories);

      try {
        await _client.from('opposition_karyakartas').update({
          'negative_stories': updatedStories.map((s) => s.toJson()).toList(),
        }).eq('id', memberId);
      } catch (_) {}
    }
  }

  /// Link a worker to a candidate
  Future<void> linkWorkerToCandidate(String workerId, String candidateId) async {
    final idx = _seedMembers.indexWhere((m) => m.id == workerId);
    if (idx != -1) {
      _seedMembers[idx] = _seedMembers[idx].copyWith(candidateId: candidateId);

      try {
        await _client.from('opposition_karyakartas').update({
          'candidate_id': candidateId,
        }).eq('id', workerId);
      } catch (_) {}
    }
  }

  /// Unlink worker from candidate
  Future<void> unlinkWorker(String workerId) async {
    final idx = _seedMembers.indexWhere((m) => m.id == workerId);
    if (idx != -1) {
      _seedMembers[idx] = _seedMembers[idx].copyWith(candidateId: null);

      try {
        await _client.from('opposition_karyakartas').update({
          'candidate_id': null,
        }).eq('id', workerId);
      } catch (_) {}
    }
  }

  /// Get candidate's team members
  List<OppositionMemberModel> getCandidateTeam(String candidateId) {
    return _seedMembers.where((m) => !m.isCandidate && m.candidateId == candidateId).toList();
  }

  /// Get unassigned workers (not linked to any candidate)
  List<OppositionMemberModel> getUnassignedWorkers() {
    return _seedMembers.where((m) => !m.isCandidate && (m.candidateId == null || m.candidateId!.isEmpty)).toList();
  }

  /// Get statistics summary
  Future<Map<String, int>> getOppositionStats() async {
    int total = _seedMembers.length;
    int candidates = 0;
    int workers = 0;
    int totalControversies = 0;
    int totalActivities = 0;

    for (final m in _seedMembers) {
      if (m.isCandidate) {
        candidates++;
      } else {
        workers++;
      }
      totalControversies += m.negativeStories.length;
      totalActivities += m.activities.length;
    }

    return {
      'total': total,
      'candidates': candidates,
      'workers': workers,
      'controversies': totalControversies,
      'activities': totalActivities,
    };
  }
}

