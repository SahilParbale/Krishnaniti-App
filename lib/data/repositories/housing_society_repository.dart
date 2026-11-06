import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/housing_society_model.dart';

final housingSocietyRepoProvider = Provider<HousingSocietyRepository>((ref) {
  return HousingSocietyRepository();
});

class HousingSocietyRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // Realistic seed data for Prabhag 12 (matching web app + authentic Prabhag areas)
  final List<HousingSocietyModel> _seedSocieties = [
    HousingSocietyModel(
      id: 'soc-1',
      name: 'गोकुळधाम सहकारी गृहनिर्माण संस्था',
      nameMarathi: 'गोकुळधाम सहकारी गृहनिर्माण संस्था',
      nameEnglish: 'Gokuldham Co-operative Housing Society',
      chairmanName: 'अशोक भिडे',
      chairmanMobile: '9867543210',
      secretaryName: 'आत्माराम भिडे',
      secretaryMobile: '9820123456',
      voterCount: 120,
      favourableVoterCount: 85,
      area: 'शांती नगर (Shanti Nagar)',
      address: 'प्लॉट क्र. १२, शांती नगर, प्रभाग क्र. १२',
      notes: 'सोसायटीमधील अंतर्गत रस्ते डांबरीकरण करणे आवश्यक आहे. पाणीपुरवठ्याचा दाब कमी आहे.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    HousingSocietyModel(
      id: 'soc-2',
      name: 'पंचशील हाईट्स',
      nameMarathi: 'पंचशील हाईट्स',
      nameEnglish: 'Panchsheel Heights',
      chairmanName: 'आनंद देशपांडे',
      chairmanMobile: '9988776655',
      secretaryName: 'विक्रम साळुंखे',
      secretaryMobile: '9850123987',
      voterCount: 210,
      favourableVoterCount: 140,
      area: 'शास्त्री नगर चौक (Shastri Nagar Chowk)',
      address: 'पंचशील नगर, शास्त्री नगर, प्रभाग क्र. १२',
      notes: 'सोसायटी गेटजवळ कचरा कुंडी हटवून सुशोभीकरण हवे आहे. स्ट्रीट लाईट बंद आहेत.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 85)),
    ),
    HousingSocietyModel(
      id: 'soc-3',
      name: 'सिद्धांचल रेसिडेन्सी',
      nameMarathi: 'सिद्धांचल रेसिडेन्सी',
      nameEnglish: 'Siddhachal Residency',
      chairmanName: 'चंद्रकांत पाटील',
      chairmanMobile: '9765432109',
      secretaryName: 'राजेश शहा',
      secretaryMobile: '9922334455',
      voterCount: 95,
      favourableVoterCount: 50,
      area: 'नेहरू चौक (Nehru Chowk)',
      address: 'गल्ली क्र. ३, नेहरू चौक प्रभाग',
      notes: 'पावसाळी गटारांचे चेंबर साफ करणे आवश्यक आहे.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
    ),
    HousingSocietyModel(
      id: 'soc-4',
      name: 'गंगा आशियाना सोसायटी',
      nameMarathi: 'गंगा आशियाना सोसायटी',
      nameEnglish: 'Ganga Asiana Society',
      chairmanName: 'सुरेश जाधव',
      chairmanMobile: '9123456789',
      secretaryName: 'नितीन सरनाईक',
      secretaryMobile: '9654321987',
      voterCount: 320,
      favourableVoterCount: 245,
      area: 'संजय नगर (Sanjay Nagar)',
      address: 'सर्व्हे क्र. ८८, संजय नगर रस्ता',
      notes: 'सोसायटी आवारात नवीन ज्येष्ठ नागरिक कोपरा आणि ओपन जिम बसवून दिल्याबद्दल आभार.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 75)),
    ),
    HousingSocietyModel(
      id: 'soc-5',
      name: 'साई श्रद्धा रेसिडेन्सी',
      nameMarathi: 'साई श्रद्धा रेसिडेन्सी',
      nameEnglish: 'Sai Shraddha Residency',
      chairmanName: 'रमेश कुंटे',
      chairmanMobile: '9012345678',
      secretaryName: 'अमोल शिंदे',
      secretaryMobile: '9890123456',
      voterCount: 65,
      favourableVoterCount: 45,
      area: 'हनुमान आळी (Hanuman Ali)',
      address: 'हनुमान मंदिराच्या मागे, प्रभाग क्र. १२',
      notes: 'पाणी सोडण्याची वेळ नियमित हवी आहे.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 70)),
    ),
    HousingSocietyModel(
      id: 'soc-6',
      name: 'ग्रीन फिल्ड रेसिडेन्सी',
      nameMarathi: 'ग्रीन फिल्ड रेसिडेन्सी',
      nameEnglish: 'Green Field Residency',
      chairmanName: 'दिनेश कामत',
      chairmanMobile: '9422334455',
      secretaryName: 'सुहास जोशी',
      secretaryMobile: '9860123450',
      voterCount: 150,
      favourableVoterCount: 75,
      area: 'गांधी मैदान परिसर (Gandhi Maidan Area)',
      address: 'गांधी मैदान जवळ, प्रभाग क्र. १२',
      notes: 'सीसीटीव्ही कॅमेरे लावण्यासाठी महापालिका निधी हवा आहे.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 65)),
    ),
    HousingSocietyModel(
      id: 'soc-7',
      name: 'शिवनेरी को-ऑपरेटिव्ह हाउसिंग सोसायटी',
      nameMarathi: 'शिवनेरी को-ऑपरेटिव्ह हाउसिंग सोसायटी',
      nameEnglish: 'Shivneri Co-operative Housing Society',
      chairmanName: 'महेंद्र भोसले',
      chairmanMobile: '9822998811',
      secretaryName: 'संतोष गायकवाड',
      secretaryMobile: '9822001122',
      voterCount: 180,
      favourableVoterCount: 125,
      area: 'सेक्टर १० (Sector 10)',
      address: 'प्लॉट क्र. ४५, सेक्टर १०, मुख्य रस्ता',
      notes: 'सोसायटी बाहेरील रस्त्यावर गतिरोधक (Speed Breaker) बसवण्याची मागणी.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    HousingSocietyModel(
      id: 'soc-8',
      name: 'ओंकार अपार्टमेंट्स',
      nameMarathi: 'ओंकार अपार्टमेंट्स',
      nameEnglish: 'Omkar Apartments',
      chairmanName: 'प्रमोद कुलकर्णी',
      chairmanMobile: '9766554433',
      secretaryName: 'सचिन मोरे',
      secretaryMobile: '9855443322',
      voterCount: 110,
      favourableVoterCount: 72,
      area: 'सेक्टर ५ (Sector 5)',
      address: 'बाजारपेठ जवळ, सेक्टर ५, प्रभाग क्र. १२',
      notes: 'कचरा वर्गीकरण मोहीम राबवली असून घंटागाडी वेळेवर येण्याची विनंती.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
    ),
    HousingSocietyModel(
      id: 'soc-9',
      name: 'नीळकंठ हाईट्स',
      nameMarathi: 'नीळकंठ हाईट्स',
      nameEnglish: 'Nilkanth Heights',
      chairmanName: 'प्रवीण बागल',
      chairmanMobile: '9821223344',
      secretaryName: 'योगेश सावंत',
      secretaryMobile: '9823445566',
      voterCount: 250,
      favourableVoterCount: 175,
      area: 'सेक्टर ६ (Sector 6)',
      address: 'कॉलेज रोड, सेक्टर ६, प्रभाग क्र. १२',
      notes: 'सोसायटीसमोरील फुटपाथ दुरुस्ती व नवीन पथदिवे मंजूर झाले आहेत.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    ),
    HousingSocietyModel(
      id: 'soc-10',
      name: 'स्वप्नपूर्ती रेसिडेन्सी',
      nameMarathi: 'स्वप्नपूर्ती रेसिडेन्सी',
      nameEnglish: 'Swapnapurti Residency',
      chairmanName: 'संजय माने',
      chairmanMobile: '9890112233',
      secretaryName: 'दीपक तांबडे',
      secretaryMobile: '9822338877',
      voterCount: 140,
      favourableVoterCount: 98,
      area: 'सेक्टर ७ (Sector 7)',
      address: 'गार्डन समोर, सेक्टर ७, प्रभाग क्र. १२',
      notes: 'उद्यानाच्या संरक्षक भिंतीचे काम पूर्ण झाले असून नगरसेवकांना विशेष धन्यवाद.',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  late final List<HousingSocietyModel> _inMemoryList = List.from(_seedSocieties);

  /// Fetch housing societies with optional search, area and status filter
  Future<List<HousingSocietyModel>> getSocieties({
    String? searchQuery,
    String? area,
    String? status,
  }) async {
    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        var query = _client
            .from('housing_societies')
            .select()
            .eq('tenant_id', tenantId);

        if (status != null && status != 'all') {
          query = query.eq('status', status);
        }

        final response = await query.order('created_at', ascending: false);
        if (response.isNotEmpty) {
          final dbList = response
              .map((row) => HousingSocietyModel.fromJson(row))
              .toList();

          return _applyLocalFilter(dbList, searchQuery, area, status);
        }
      }
    } catch (_) {
      // Fallback to in-memory state
    }

    return _applyLocalFilter(_inMemoryList, searchQuery, area, status);
  }

  List<HousingSocietyModel> _applyLocalFilter(
    List<HousingSocietyModel> list,
    String? query,
    String? area,
    String? status,
  ) {
    return list.where((soc) {
      if (status != null && status != 'all' && soc.status != status) {
        return false;
      }
      if (area != null && area != 'all') {
        if (!soc.area.toLowerCase().contains(area.toLowerCase())) {
          return false;
        }
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchName = soc.name.toLowerCase().contains(q) ||
            (soc.nameMarathi?.toLowerCase().contains(q) ?? false) ||
            (soc.nameEnglish?.toLowerCase().contains(q) ?? false);
        final matchChairman = soc.chairmanName.toLowerCase().contains(q) ||
            soc.chairmanMobile.contains(q);
        final matchSecretary = soc.secretaryName.toLowerCase().contains(q) ||
            soc.secretaryMobile.contains(q);
        final matchArea = soc.area.toLowerCase().contains(q);
        final matchNotes = soc.notes.toLowerCase().contains(q);
        if (!matchName && !matchChairman && !matchSecretary && !matchArea && !matchNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Get distinct area list
  Future<List<String>> getUniqueAreas() async {
    final list = await getSocieties();
    final areas = list.map((s) => s.area.trim()).where((a) => a.isNotEmpty).toSet().toList();
    areas.sort();
    return areas;
  }

  /// Get specific society by ID
  Future<HousingSocietyModel?> getSocietyById(String id) async {
    final list = await getSocieties();
    try {
      return list.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add new society
  Future<HousingSocietyModel> addSociety(HousingSocietyModel society) async {
    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        final data = society.toJson();
        data['tenant_id'] = tenantId;
        data.remove('id'); // let supabase generate or use provided

        final res = await _client
            .from('housing_societies')
            .insert(data)
            .select()
            .single();

        final created = HousingSocietyModel.fromJson(res);
        _inMemoryList.insert(0, created);
        return created;
      }
    } catch (_) {
      // Local fallback
    }

    _inMemoryList.insert(0, society);
    return society;
  }

  /// Update existing society
  Future<void> updateSociety(HousingSocietyModel society) async {
    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        final data = society.toJson();
        data.remove('id');
        await _client
            .from('housing_societies')
            .update(data)
            .eq('id', society.id)
            .eq('tenant_id', tenantId);
      }
    } catch (_) {
      // Local fallback
    }

    final idx = _inMemoryList.indexWhere((s) => s.id == society.id);
    if (idx != -1) {
      _inMemoryList[idx] = society;
    }
  }

  /// Delete society
  Future<void> deleteSociety(String id) async {
    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        await _client
            .from('housing_societies')
            .delete()
            .eq('id', id)
            .eq('tenant_id', tenantId);
      }
    } catch (_) {
      // Local fallback
    }

    _inMemoryList.removeWhere((s) => s.id == id);
  }

  /// Get KPI summary statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final list = await getSocieties();
    final totalSocieties = list.length;
    final totalVoters = list.fold<int>(0, (sum, s) => sum + s.voterCount);
    final totalFavourable = list.fold<int>(0, (sum, s) => sum + s.favourableVoterCount);
    final avgSupport = totalVoters > 0 ? ((totalFavourable / totalVoters) * 100).round() : 0;
    final activeCount = list.where((s) => s.status == 'Active').length;

    return {
      'total': totalSocieties,
      'voters': totalVoters,
      'favourable': totalFavourable,
      'supportPercentage': avgSupport,
      'active': activeCount,
    };
  }
}

