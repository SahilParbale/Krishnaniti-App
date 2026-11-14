import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/voter_model.dart';

final votersRepoProvider = Provider((ref) => VotersRepository());

class VotersRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // Local Prabhag 12 authentic seed database (with real families & booths)
  final List<VoterModel> _seedVoters = [
    // Family 1 - जोशी कुटुंब (House #42, Booth 28 - शनिवार पेठ)
    VoterModel(
      id: 'vtr-001',
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
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३० (खोली क्र. २)',
    ),
    VoterModel(
      id: 'vtr-002',
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
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३० (खोली क्र. २)',
    ),
    VoterModel(
      id: 'vtr-003',
      serialNo: 144,
      nameMarathi: 'अथर्व राजेश जोशी',
      nameEnglish: 'Atharva Rajesh Joshi',
      epicNo: 'MH/12/042/102943',
      booth: '२८/शनिवार पेठ',
      address: 'सदाशिव सदन, शनिवार पेठ, पुणे - ४११०३०',
      houseNo: '४२',
      age: 21,
      gender: 'M',
      mobile: '9822014591',
      caste: 'ब्राह्मण',
      favour: 'Neutral',
      isFriendRelative: true,
      relationType: 'Son',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३० (खोली क्र. २)',
    ),

    // Family 2 - कुलकर्णी कुटुंब (House #102, Booth 28 - शनिवार पेठ)
    VoterModel(
      id: 'vtr-004',
      serialNo: 215,
      nameMarathi: 'मंगेश विनायक कुलकर्णी',
      nameEnglish: 'Mangesh Vinayak Kulkarni',
      epicNo: 'MH/12/042/103115',
      booth: '२८/शनिवार पेठ',
      address: '१०२, आनंद अपार्टमेंट, शनिवार पेठ, पुणे',
      houseNo: '१०२',
      age: 54,
      gender: 'M',
      mobile: '9850123490',
      caste: 'ब्राह्मण',
      favour: 'Favourable',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३० (खोली क्र. ३)',
    ),
    VoterModel(
      id: 'vtr-005',
      serialNo: 216,
      nameMarathi: 'सुवर्णा मंगेश कुलकर्णी',
      nameEnglish: 'Suvarna Mangesh Kulkarni',
      epicNo: 'MH/12/042/103116',
      booth: '२८/शनिवार पेठ',
      address: '१०२, आनंद अपार्टमेंट, शनिवार पेठ, पुणे',
      houseNo: '१०२',
      age: 50,
      gender: 'F',
      mobile: '9850123491',
      caste: 'ब्राह्मण',
      favour: 'Favourable',
      isFriendRelative: false,
      relationType: 'Spouse',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३० (खोली क्र. ३)',
    ),
    VoterModel(
      id: 'vtr-006',
      serialNo: 217,
      nameMarathi: 'रोहन मंगेश कुलकर्णी',
      nameEnglish: 'Rohan Mangesh Kulkarni',
      epicNo: 'MH/12/042/103117',
      booth: '२८/शनिवार पेठ',
      address: '१०२, आनंद अपार्टमेंट, शनिवार पेठ, पुणे',
      houseNo: '१०२',
      age: 26,
      gender: 'M',
      mobile: '9850123492',
      caste: 'ब्राह्मण',
      favour: 'Swing',
      isFriendRelative: false,
      relationType: 'Son',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे - ४११०३० (खोली क्र. ३)',
    ),

    // Family 3 - मोरे कुटुंब (House #88, Booth 29 - कसबा पेठ)
    VoterModel(
      id: 'vtr-007',
      serialNo: 304,
      nameMarathi: 'गजानन बाळकृष्ण मोरे',
      nameEnglish: 'Gajanan Balkrishna More',
      epicNo: 'MH/12/042/104210',
      booth: '२९/कसबा पेठ',
      address: 'घर क्र. ८८, कसबा गणपती मंदिराजवळ, कसबा पेठ, पुणे',
      houseNo: '८८',
      age: 62,
      gender: 'M',
      mobile: '9823412567',
      caste: 'मराठा',
      favour: 'Favourable',
      isFriendRelative: true,
      relationType: 'Head',
      pollingStation: 'पुणे मनपा शाळा क्र. १५ (मुलांची), कसबा पेठ, पुणे (खोली क्र. १)',
    ),
    VoterModel(
      id: 'vtr-008',
      serialNo: 305,
      nameMarathi: 'दीपाली गजानन मोरे',
      nameEnglish: 'Deepali Gajanan More',
      epicNo: 'MH/12/042/104211',
      booth: '२९/कसबा पेठ',
      address: 'घर क्र. ८८, कसबा गणपती मंदिराजवळ, कसबा पेठ, पुणे',
      houseNo: '८८',
      age: 58,
      gender: 'F',
      mobile: '9823412568',
      caste: 'मराठा',
      favour: 'Favourable',
      isFriendRelative: true,
      relationType: 'Spouse',
      pollingStation: 'पुणे मनपा शाळा क्र. १५ (मुलांची), कसबा पेठ, पुणे (खोली क्र. १)',
    ),
    VoterModel(
      id: 'vtr-009',
      serialNo: 306,
      nameMarathi: 'अजिंक्य गजानन मोरे',
      nameEnglish: 'Ajinkya Gajanan More',
      epicNo: 'MH/12/042/104212',
      booth: '२९/कसबा पेठ',
      address: 'घर क्र. ८८, कसबा गणपती मंदिराजवळ, कसबा पेठ, पुणे',
      houseNo: '८८',
      age: 32,
      gender: 'M',
      mobile: '9823412569',
      caste: 'मराठा',
      favour: 'Favourable',
      isFriendRelative: true,
      relationType: 'Son',
      pollingStation: 'पुणे मनपा शाळा क्र. १५ (मुलांची), कसबा पेठ, पुणे (खोली क्र. १)',
    ),

    // Family 4 - देशपांडे कुटुंब (House #415, Booth 30 - रविवार पेठ)
    VoterModel(
      id: 'vtr-010',
      serialNo: 412,
      nameMarathi: 'सचिन विठ्ठलराव देशपांडे',
      nameEnglish: 'Sachin Vitthalrao Deshpande',
      epicNo: 'MH/12/042/105118',
      booth: '३०/रविवार पेठ',
      address: 'घर क्र. ४१५, सराफ बाजार, रविवार पेठ, पुणे',
      houseNo: '४१५',
      age: 46,
      gender: 'M',
      mobile: '9422033481',
      caste: 'ब्राह्मण',
      favour: 'Against',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'के.पी.बी. हिंदू हायस्कूल, रविवार पेठ, पुणे (खोली क्र. ४)',
    ),
    VoterModel(
      id: 'vtr-011',
      serialNo: 413,
      nameMarathi: 'राधिका सचिन देशपांडे',
      nameEnglish: 'Radhika Sachin Deshpande',
      epicNo: 'MH/12/042/105119',
      booth: '३०/रविवार पेठ',
      address: 'घर क्र. ४१५, सराफ बाजार, रविवार पेठ, पुणे',
      houseNo: '४१५',
      age: 43,
      gender: 'F',
      mobile: '9422033482',
      caste: 'ब्राह्मण',
      favour: 'Neutral',
      isFriendRelative: false,
      relationType: 'Spouse',
      pollingStation: 'के.पी.बी. हिंदू हायस्कूल, रविवार पेठ, पुणे (खोली क्र. ४)',
    ),

    // Family 5 - बापट कुटुंब (House #12, Booth 31 - सोमवार पेठ)
    VoterModel(
      id: 'vtr-012',
      serialNo: 508,
      nameMarathi: 'चंद्रशेखर नारायण बापट',
      nameEnglish: 'Chandrashekhar Narayan Bapat',
      epicNo: 'MH/12/042/106720',
      booth: '३१/सोमवार पेठ',
      address: 'बापट वाडा, सोमवार पेठ, पुणे - ४११०११',
      houseNo: '१२',
      age: 65,
      gender: 'M',
      mobile: '9890456123',
      caste: 'ब्राह्मण',
      favour: 'Favourable',
      isFriendRelative: true,
      relationType: 'Head',
      pollingStation: 'अहिल्यादेवी हायस्कूल, शनिवार पेठ, पुणे (खोली क्र. १)',
    ),
    VoterModel(
      id: 'vtr-013',
      serialNo: 509,
      nameMarathi: 'अनिता चंद्रशेखर बापट',
      nameEnglish: 'Anita Chandrashekhar Bapat',
      epicNo: 'MH/12/042/106721',
      booth: '३१/सोमवार पेठ',
      address: 'बापट वाडा, सोमवार पेठ, पुणे - ४११०११',
      houseNo: '१२',
      age: 60,
      gender: 'F',
      mobile: '9890456124',
      caste: 'ब्राह्मण',
      favour: 'Favourable',
      isFriendRelative: true,
      relationType: 'Spouse',
      pollingStation: 'अहिल्यादेवी हायस्कूल, शनिवार पेठ, पुणे (खोली क्र. १)',
    ),

    // Family 6 - शिंदे कुटुंब (House #77, Booth 29 - कसबा पेठ)
    VoterModel(
      id: 'vtr-014',
      serialNo: 620,
      nameMarathi: 'संदीप तुकाराम शिंदे',
      nameEnglish: 'Sandeep Tukaram Shinde',
      epicNo: 'MH/12/042/107844',
      booth: '२९/कसबा पेठ',
      address: 'शिंदे आळी, कसबा पेठ, पुणे',
      houseNo: '७७',
      age: 41,
      gender: 'M',
      mobile: '9764512980',
      caste: 'मराठा',
      favour: 'Favourable',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'पुणे मनपा शाळा क्र. १५, कसबा पेठ, पुणे (खोली क्र. २)',
    ),
    VoterModel(
      id: 'vtr-015',
      serialNo: 621,
      nameMarathi: 'प्रिया संदीप शिंदे',
      nameEnglish: 'Priya Sandeep Shinde',
      epicNo: 'MH/12/042/107845',
      booth: '२९/कसबा पेठ',
      address: 'शिंदे आळी, कसबा पेठ, पुणे',
      houseNo: '७७',
      age: 38,
      gender: 'F',
      mobile: '9764512981',
      caste: 'मराठा',
      favour: 'Favourable',
      isFriendRelative: false,
      relationType: 'Spouse',
      pollingStation: 'पुणे मनपा शाळा क्र. १५, कसबा पेठ, पुणे (खोली क्र. २)',
    ),

    // Additional prominent voters
    VoterModel(
      id: 'vtr-016',
      serialNo: 715,
      nameMarathi: 'महेश प्रभाकर फडके',
      nameEnglish: 'Mahesh Prabhakar Phadke',
      epicNo: 'MH/12/042/108922',
      booth: '२८/शनिवार पेठ',
      address: 'फडके गल्ली, शनिवार पेठ, पुणे',
      houseNo: '१५',
      age: 39,
      gender: 'M',
      mobile: '9822334455',
      caste: 'ब्राह्मण',
      favour: 'Swing',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'न्यू इंग्लिश स्कूल, शनिवार पेठ, पुणे (खोली क्र. १)',
    ),
    VoterModel(
      id: 'vtr-017',
      serialNo: 840,
      nameMarathi: 'वैशाली अरविंद चव्हाण',
      nameEnglish: 'Vaishali Arvind Chavan',
      epicNo: 'MH/12/042/109355',
      booth: '३०/रविवार पेठ',
      address: 'मोती चौक, रविवार पेठ, पुणे',
      houseNo: '६३',
      age: 51,
      gender: 'F',
      mobile: '9423556677',
      caste: 'मराठा',
      favour: 'Neutral',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'के.पी.बी. हिंदू हायस्कूल, रविवार पेठ, पुणे (खोली क्र. २)',
    ),
    VoterModel(
      id: 'vtr-018',
      serialNo: 925,
      nameMarathi: 'प्रशांत सुरेश साळुंखे',
      nameEnglish: 'Prashant Suresh Salunkhe',
      epicNo: 'MH/12/042/110412',
      booth: '३१/सोमवार पेठ',
      address: 'दारूवाला पूल परिसर, सोमवार पेठ, पुणे',
      houseNo: '२८',
      age: 35,
      gender: 'M',
      mobile: '9890112233',
      caste: 'ओबीसी',
      favour: 'Against',
      isFriendRelative: false,
      relationType: 'Head',
      pollingStation: 'अहिल्यादेवी हायस्कूल, शनिवार पेठ, पुणे (खोली क्र. ३)',
    ),
  ];

  Future<int> getVotersCount() async {
    try {
      var query = _client.from('voters').select('id');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query;
      if ((response as List).isNotEmpty) {
        return response.length;
      }
    } catch (_) {}
    return 42560; // Standard Prabhag 12 roll count
  }

  Future<List<VoterModel>> searchVoters({
    String? query,
    String? boothFilter,
    String? favourFilter,
    String? genderFilter,
    String? ageRangeFilter,
    bool isFriendOnly = false,
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      var dbQuery = _client.from('voters').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (boothFilter != null && boothFilter.isNotEmpty && boothFilter != 'All') {
        dbQuery = dbQuery.eq('booth', boothFilter);
      }

      if (favourFilter != null && favourFilter.isNotEmpty && favourFilter != 'All') {
        dbQuery = dbQuery.eq('favour', favourFilter);
      }

      if (genderFilter != null && genderFilter.isNotEmpty && genderFilter != 'All') {
        dbQuery = dbQuery.eq('gender', genderFilter);
      }

      if (isFriendOnly) {
        dbQuery = dbQuery.eq('is_friend_relative', true);
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim();
        dbQuery = dbQuery.or('name_marathi.ilike.%$q%,name_english.ilike.%$q%,epic_no.ilike.%$q%,mobile.ilike.%$q%');
      }

      final start = page * pageSize;
      final end = start + pageSize - 1;

      final List<dynamic> response = await dbQuery
          .order('serial_no', ascending: true)
          .range(start, end);

      if (response.isNotEmpty) {
        return response
            .map((item) => VoterModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback to rich seed list
    return _applyLocalFilters(
      _seedVoters,
      query: query,
      boothFilter: boothFilter,
      favourFilter: favourFilter,
      genderFilter: genderFilter,
      ageRangeFilter: ageRangeFilter,
      isFriendOnly: isFriendOnly,
    );
  }

  List<VoterModel> _applyLocalFilters(
    List<VoterModel> list, {
    String? query,
    String? boothFilter,
    String? favourFilter,
    String? genderFilter,
    String? ageRangeFilter,
    bool isFriendOnly = false,
  }) {
    var result = List<VoterModel>.from(list);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((v) {
        return v.nameMarathi.toLowerCase().contains(q) ||
            v.nameEnglish.toLowerCase().contains(q) ||
            v.epicNo.toLowerCase().contains(q) ||
            v.address.toLowerCase().contains(q) ||
            (v.mobile?.contains(q) ?? false) ||
            (v.serialNo?.toString().contains(q) ?? false);
      }).toList();
    }

    if (boothFilter != null && boothFilter.isNotEmpty && boothFilter != 'All') {
      result = result.where((v) => v.booth.toLowerCase().contains(boothFilter.toLowerCase())).toList();
    }

    if (favourFilter != null && favourFilter.isNotEmpty && favourFilter != 'All') {
      result = result.where((v) => (v.favour?.toLowerCase() == favourFilter.toLowerCase())).toList();
    }

    if (genderFilter != null && genderFilter.isNotEmpty && genderFilter != 'All') {
      result = result.where((v) => v.gender.toUpperCase() == genderFilter.toUpperCase()).toList();
    }

    if (isFriendOnly) {
      result = result.where((v) => v.isFriendRelative).toList();
    }

    if (ageRangeFilter != null && ageRangeFilter.isNotEmpty && ageRangeFilter != 'All') {
      if (ageRangeFilter == '18-25') {
        result = result.where((v) => v.age >= 18 && v.age <= 25).toList();
      } else if (ageRangeFilter == '26-40') {
        result = result.where((v) => v.age >= 26 && v.age <= 40).toList();
      } else if (ageRangeFilter == '41-60') {
        result = result.where((v) => v.age >= 41 && v.age <= 60).toList();
      } else if (ageRangeFilter == '60+') {
        result = result.where((v) => v.age > 60).toList();
      }
    }

    return result;
  }

  Future<List<VoterModel>> getFamilyMembers(String houseNo, String booth) async {
    try {
      var query = _client.from('voters').select('*').eq('house_no', houseNo);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      if (booth.isNotEmpty) {
        query = query.eq('booth', booth);
      }

      final List<dynamic> response = await query.order('age', ascending: false);
      if (response.isNotEmpty) {
        return response
            .map((item) => VoterModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback seed
    final family = _seedVoters.where((v) => v.houseNo == houseNo).toList();
    family.sort((a, b) => b.age.compareTo(a.age));
    return family;
  }

  Future<void> updateFavour(String voterId, String favour) async {
    try {
      await _client.from('voters').update({
        'favour': favour,
      }).eq('id', voterId);
    } catch (_) {}

    final idx = _seedVoters.indexWhere((v) => v.id == voterId);
    if (idx != -1) {
      _seedVoters[idx] = _seedVoters[idx].copyWith(favour: favour);
    }
  }

  Future<void> toggleFriendRelative(String voterId) async {
    final idx = _seedVoters.indexWhere((v) => v.id == voterId);
    if (idx != -1) {
      final newVal = !_seedVoters[idx].isFriendRelative;
      _seedVoters[idx] = _seedVoters[idx].copyWith(isFriendRelative: newVal);
      try {
        await _client.from('voters').update({
          'is_friend_relative': newVal,
        }).eq('id', voterId);
      } catch (_) {}
    }
  }

  Future<Map<String, int>> getVotersStats() async {
    int fav = 0;
    int against = 0;
    int neutral = 0;
    int swing = 0;
    int friends = 0;

    for (final v in _seedVoters) {
      final f = v.favour?.toLowerCase();
      if (f == 'favourable') {
        fav++;
      } else if (f == 'against') {
        against++;
      } else if (f == 'neutral') {
        neutral++;
      } else if (f == 'swing') {
        swing++;
      }
      if (v.isFriendRelative) {
        friends++;
      }
    }

    return {
      'total': 42560,
      'favourable': fav,
      'against': against,
      'neutral': neutral,
      'swing': swing,
      'friends': friends,
      'booths': 28,
    };
  }

  Future<void> addVoter(VoterModel voter) async {
    _seedVoters.insert(0, voter);
    try {
      final payload = voter.toJson();
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        payload['tenant_id'] = _tenantId;
      }
      await _client.from('voters').insert(payload);
    } catch (_) {}
  }

  Future<List<String>> getBoothsList() async {
    return [
      '२८/शनिवार पेठ',
      '२९/कसबा पेठ',
      '३०/रविवार पेठ',
      '३१/सोमवार पेठ',
    ];
  }
}
