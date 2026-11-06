import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/voter_model.dart';
import '../models/duplicate_voter_group_model.dart';

final duplicateVotersRepoProvider = Provider<DuplicateVotersRepository>((ref) {
  return DuplicateVotersRepository();
});

class DuplicateVotersRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // Realistic seed voters for Prabhag 12 including authentic duplicate groups
  final List<VoterModel> _seedVoters = [
    // Duplicate Group 1: राजेश दत्तात्रय जोशी (Registered in 2 different booths)
    VoterModel(
      id: 'vtr-dup-01a',
      serialNo: 142,
      nameMarathi: 'राजेश दत्तात्रय जोशी',
      nameEnglish: 'Rajesh Dattatraya Joshi',
      epicNo: 'MH/12/042/102941',
      booth: '२८/शनिवार पेठ',
      address: 'सदाशिव सदन, शनिवार पेठ, पुणे - ४११०३०',
      houseNo: '४२',
      age: 48,
      gender: 'M',
      mobile: '9822014589',
      caste: 'ब्राह्मण',
      favour: 'Favourable',
      isFriendRelative: true,
      relationType: 'Head',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ (खोली क्र. २)',
    ),
    VoterModel(
      id: 'vtr-dup-01b',
      serialNo: 389,
      nameMarathi: 'राजेश दत्तात्रय जोशी',
      nameEnglish: 'Rajesh Dattatraya Joshi',
      epicNo: 'MH/12/045/889211',
      booth: '३१/सोमवार पेठ',
      address: 'प्लॉट क्र. १०४/ब, सोमवार पेठ, पुणे',
      houseNo: '१०४/ब',
      age: 48,
      gender: 'M',
      mobile: '9822014589',
      caste: 'ब्राह्मण',
      favour: 'Neutral',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'महानगरपालिका प्राथमिक शाळा, सोमवार पेठ',
    ),

    // Duplicate Group 2: सचिन विठ्ठलराव देशपांडे (Old house vs. New society)
    VoterModel(
      id: 'vtr-dup-02a',
      serialNo: 151,
      nameMarathi: 'सचिन विठ्ठलराव देशपांडे',
      nameEnglish: 'Sachin Vitthalrao Deshpande',
      epicNo: 'MH/12/042/102950',
      booth: '२८/शनिवार पेठ',
      address: 'देशपांडे वाडा, गल्ली क्र. २, शनिवार पेठ',
      houseNo: '४५',
      age: 52,
      gender: 'M',
      mobile: '9822345678',
      caste: 'मराठा',
      favour: 'Favourable',
      isFriendRelative: true,
      relationType: 'Head',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ (खोली क्र. २)',
    ),
    VoterModel(
      id: 'vtr-dup-02b',
      serialNo: 204,
      nameMarathi: 'सचिन विठ्ठलराव देशपांडे',
      nameEnglish: 'Sachin Vitthalrao Deshpande',
      epicNo: 'MH/12/044/552109',
      booth: '३०/रविवार पेठ',
      address: 'फ्लॅट क्र. ४०२, सिद्धिविनायक हाईट्स, रविवार पेठ',
      houseNo: '१२',
      age: 52,
      gender: 'M',
      mobile: '9822345678',
      caste: 'मराठा',
      favour: 'Neutral',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'अहिल्यादेवी हायस्कूल, रविवार पेठ',
    ),

    // Duplicate Group 3: अनिता चंद्रशेखर बापट (Duplicate registration across polling parts)
    VoterModel(
      id: 'vtr-dup-03a',
      serialNo: 78,
      nameMarathi: 'अनिता चंद्रशेखर बापट',
      nameEnglish: 'Anita Chandrashekhar Bapat',
      epicNo: 'MH/12/043/339102',
      booth: '२९/कसबा पेठ',
      address: 'बापट निवास, कसबा पेठ, पुणे - ४११०११',
      houseNo: '१८',
      age: 46,
      gender: 'F',
      mobile: '9823456789',
      caste: 'ब्राह्मण',
      favour: 'Favourable',
      isFriendRelative: false,
      relationType: 'Spouse',
      pollingStation: 'कसबा विश्रामगृह सभागृह, कसबा पेठ',
    ),
    VoterModel(
      id: 'vtr-dup-03b',
      serialNo: 312,
      nameMarathi: 'अनिता चंद्रशेखर बापट',
      nameEnglish: 'Anita Chandrashekhar Bapat',
      epicNo: 'MH/12/044/991204',
      booth: '३०/रविवार पेठ',
      address: 'गंगोत्री अपार्टमेंट, रविवार पेठ, पुणे',
      houseNo: '८८',
      age: 46,
      gender: 'F',
      mobile: '9823456789',
      caste: 'ब्राह्मण',
      favour: 'Neutral',
      isFriendRelative: false,
      relationType: 'Spouse',
      pollingStation: 'अहिल्यादेवी हायस्कूल, रविवार पेठ',
    ),

    // Duplicate Group 4: महेश प्रभाकर फडके (Dual EPIC issuance on same house)
    VoterModel(
      id: 'vtr-dup-04a',
      serialNo: 161,
      nameMarathi: 'महेश प्रभाकर फडके',
      nameEnglish: 'Mahesh Prabhakar Phadke',
      epicNo: 'MH/12/042/102960',
      booth: '२८/शनिवार पेठ',
      address: '५० शनिवार पेठ, विठ्ठल मंदिर जवळ, पुणे',
      houseNo: '५०',
      age: 39,
      gender: 'M',
      mobile: '9822678901',
      caste: 'मराठा',
      favour: 'Favourable',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ (खोली क्र. ३)',
    ),
    VoterModel(
      id: 'vtr-dup-04b',
      serialNo: 198,
      nameMarathi: 'महेश प्रभाकर फडके',
      nameEnglish: 'Mahesh Prabhakar Phadke',
      epicNo: 'MH/12/042/901234',
      booth: '२८/शनिवार पेठ',
      address: '५० शनिवार पेठ, विठ्ठल मंदिर मागे, पुणे',
      houseNo: '५०',
      age: 39,
      gender: 'M',
      mobile: '9822678901',
      caste: 'मराठा',
      favour: 'Neutral',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ (खोली क्र. ३)',
    ),

    // Duplicate Group 5: सुनिता राजेश जोशी (Triple / Dual entry)
    VoterModel(
      id: 'vtr-dup-05a',
      serialNo: 143,
      nameMarathi: 'सुनिता राजेश जोशी',
      nameEnglish: 'Sunita Rajesh Joshi',
      epicNo: 'MH/12/042/102942',
      booth: '२८/शनिवार पेठ',
      address: 'सदाशिव सदन, शनिवार पेठ, पुणे - ४११०३०',
      houseNo: '४२',
      age: 45,
      gender: 'F',
      mobile: '9822014590',
      caste: 'ब्राह्मण',
      favour: 'Favourable',
      isFriendRelative: true,
      relationType: 'Spouse',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ (खोली क्र. २)',
    ),
    VoterModel(
      id: 'vtr-dup-05b',
      serialNo: 390,
      nameMarathi: 'सुनिता राजेश जोशी',
      nameEnglish: 'Sunita Rajesh Joshi',
      epicNo: 'MH/12/045/889212',
      booth: '३१/सोमवार पेठ',
      address: 'प्लॉट क्र. १०४/ब, सोमवार पेठ, पुणे',
      houseNo: '१०४/ब',
      age: 45,
      gender: 'F',
      mobile: '9822014590',
      caste: 'ब्राह्मण',
      favour: 'Neutral',
      isFriendRelative: false,
      relationType: 'Spouse',
      pollingStation: 'महानगरपालिका प्राथमिक शाळा, सोमवार पेठ',
    ),

    // Unique control voters (will not be in duplicate groups)
    VoterModel(
      id: 'vtr-unique-01',
      serialNo: 144,
      nameMarathi: 'अथर्व राजेश जोशी',
      nameEnglish: 'Atharva Rajesh Joshi',
      epicNo: 'MH/12/042/102943',
      booth: '२८/शनिवार पेठ',
      address: 'सदाशिव सदन, शनिवार पेठ, पुणे',
      houseNo: '४२',
      age: 21,
      gender: 'M',
      mobile: '9822014591',
      favour: 'Favourable',
    ),
    VoterModel(
      id: 'vtr-unique-02',
      serialNo: 225,
      nameMarathi: 'मंगेश विनायक कुलकर्णी',
      nameEnglish: 'Mangesh Vinayak Kulkarni',
      epicNo: 'MH/12/042/204511',
      booth: '२८/शनिवार पेठ',
      address: 'कुलकर्णी निवास, शनिवार पेठ',
      houseNo: '५५',
      age: 55,
      gender: 'M',
      mobile: '9822156789',
      favour: 'Favourable',
    ),
  ];

  late final List<VoterModel> _activeVoters = List.from(_seedVoters);

  /// Fetch all duplicate groups based on matchType ('name' | 'epic' | 'mobile')
  Future<List<DuplicateVoterGroupModel>> getDuplicateGroups({
    String? query,
    String matchType = 'name',
  }) async {
    List<VoterModel> sourceVoters = [];

    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        final res = await _client
            .from('voters')
            .select('*')
            .eq('tenant_id', tenantId)
            .order('name_english', ascending: true);

        if (res.isNotEmpty) {
          sourceVoters = res
              .map((row) => VoterModel.fromJson(row))
              .toList();
        }
      }
    } catch (_) {
      // Fallback to active in-memory voters
    }

    if (sourceVoters.isEmpty) {
      sourceVoters = _activeVoters;
    }

    // Grouping map
    final Map<String, List<VoterModel>> groupMap = {};
    final Map<String, String> displayNames = {};

    for (final voter in sourceVoters) {
      String key = '';
      String display = voter.displayName;

      if (matchType == 'name') {
        final raw = voter.nameEnglish.isNotEmpty ? voter.nameEnglish : voter.nameMarathi;
        key = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        if (voter.nameMarathi.isNotEmpty) display = voter.nameMarathi;
      } else if (matchType == 'epic') {
        key = voter.epicNo.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
        display = voter.epicNo.isNotEmpty ? voter.epicNo : voter.displayName;
      } else if (matchType == 'mobile') {
        key = (voter.mobile ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        display = voter.mobile ?? voter.displayName;
      }

      if (key.isEmpty) continue;

      if (!groupMap.containsKey(key)) {
        groupMap[key] = [];
        displayNames[key] = display;
      }
      groupMap[key]!.add(voter);
    }

    // Keep only duplicates (voters.length > 1)
    final List<DuplicateVoterGroupModel> duplicateGroups = [];
    groupMap.forEach((key, voters) {
      if (voters.length > 1) {
        duplicateGroups.add(
          DuplicateVoterGroupModel(
            normalizedKey: key,
            displayName: displayNames[key] ?? key,
            matchType: matchType,
            voters: voters,
          ),
        );
      }
    });

    // Sort by count descending
    duplicateGroups.sort((a, b) => b.recordsCount.compareTo(a.recordsCount));

    // Apply search filter if provided
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      return duplicateGroups.where((group) {
        final matchesKey = group.normalizedKey.toLowerCase().contains(q);
        final matchesDisplay = group.displayName.toLowerCase().contains(q);
        final matchesAnyVoter = group.voters.any((v) =>
            v.nameEnglish.toLowerCase().contains(q) ||
            v.nameMarathi.toLowerCase().contains(q) ||
            v.epicNo.toLowerCase().contains(q) ||
            v.booth.toLowerCase().contains(q) ||
            (v.mobile?.contains(q) ?? false));
        return matchesKey || matchesDisplay || matchesAnyVoter;
      }).toList();
    }

    return duplicateGroups;
  }

  /// Delete a duplicate voter record
  Future<bool> deleteVoter(String voterId) async {
    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        await _client
            .from('voters')
            .delete()
            .eq('id', voterId)
            .eq('tenant_id', tenantId);
      }
    } catch (_) {
      // Local fallback
    }

    _activeVoters.removeWhere((v) => v.id == voterId);
    return true;
  }

  /// KPI Summary Statistics for Duplicate Voters
  Future<Map<String, dynamic>> getStatistics() async {
    final groups = await getDuplicateGroups();
    final totalGroups = groups.length;
    final totalAffected = groups.fold<int>(0, (sum, g) => sum + g.recordsCount);
    final estExtra = groups.fold<int>(0, (sum, g) => sum + g.extraRecordsCount);

    return {
      'duplicateGroups': totalGroups,
      'totalAffectedVoters': totalAffected,
      'estimatedExtraRecords': estExtra,
      'cleanRecordsCount': _activeVoters.length - totalAffected,
    };
  }
}

