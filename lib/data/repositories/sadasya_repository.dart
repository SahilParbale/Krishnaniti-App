import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/sadasya_model.dart';

class SadasyaRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // Local state with authentic Prabhag 12 Party Cadre Seed Data
  final List<SadasyaModel> _sadasyas = [
    SadasyaModel(
      id: 'sad-001',
      name: 'सचिन तुकाराम मोरे',
      nameMarathi: 'सचिन तुकाराम मोरे',
      nameEnglish: 'Sachin Tukaram More',
      mobile: '+91 98220 14589',
      age: 38,
      gender: 'M',
      ward: 'प्रभाग १२',
      area: 'शनिवार पेठ',
      address: 'घर क्र. १८२, शनिवार पेठ, पुणे',
      addressMarathi: 'घर क्र. १८२, शनिवार पेठ, पुणे',
      addressEnglish: 'House No. 182, Shaniwar Peth, Pune',
      isVoter: true,
      voterId: 'PMC8921456',
      status: 'Active',
      role: 'बूथ प्रमुख (बूथ १२/१)',
      registeredAt: DateTime(2025, 2, 10),
    ),
    SadasyaModel(
      id: 'sad-002',
      name: 'सुवर्णा नितीन कुलकर्णी',
      nameMarathi: 'सुवर्णा नितीन कुलकर्णी',
      nameEnglish: 'Suvarna Nitin Kulkarni',
      mobile: '+91 94235 67890',
      age: 42,
      gender: 'F',
      ward: 'प्रभाग १२',
      area: 'कसबा पेठ',
      address: 'फ्लॅट क्र. ४, कुबेर अपार्टमेंट, कसबा पेठ, पुणे',
      addressMarathi: 'फ्लॅट क्र. ४, कुबेर अपार्टमेंट, कसबा पेठ, पुणे',
      addressEnglish: 'Flat No. 4, Kuber Apt, Kasba Peth, Pune',
      isVoter: true,
      voterId: 'PMC7812903',
      status: 'Active',
      role: 'महिला आघाडी संयोजिका',
      registeredAt: DateTime(2025, 2, 12),
    ),
    SadasyaModel(
      id: 'sad-003',
      name: 'राहुल विलास शिंदे',
      nameMarathi: 'राहुल विलास शिंदे',
      nameEnglish: 'Rahul Vilas Shinde',
      mobile: '+91 99214 33211',
      age: 28,
      gender: 'M',
      ward: 'प्रभाग १२',
      area: 'नारायण पेठ',
      address: '५६/२, केळकर रोड, नारायण पेठ, पुणे',
      addressMarathi: '५६/२, केळकर रोड, नारायण पेठ, पुणे',
      addressEnglish: '56/2, Kelkar Road, Narayan Peth, Pune',
      isVoter: true,
      voterId: 'PMC6541289',
      status: 'Active',
      role: 'युवा मोर्चा अध्यक्ष',
      registeredAt: DateTime(2025, 2, 15),
    ),
    SadasyaModel(
      id: 'sad-004',
      name: 'गणेश महादेव पवार',
      nameMarathi: 'गणेश महादेव पवार',
      nameEnglish: 'Ganesh Mahadev Pawar',
      mobile: '+91 98812 99044',
      age: 55,
      gender: 'M',
      ward: 'प्रभाग १२',
      area: 'रास्ता पेठ',
      address: 'म.न.पा. शाळा क्र. १८ जवळ, रास्ता पेठ, पुणे',
      addressMarathi: 'म.न.पा. शाळा क्र. १८ जवळ, रास्ता पेठ, पुणे',
      addressEnglish: 'Near PMC School No. 18, Rasta Peth, Pune',
      isVoter: true,
      voterId: 'PMC9012431',
      status: 'Active',
      role: 'ज्येष्ठ मार्गदर्शक',
      registeredAt: DateTime(2025, 1, 20),
    ),
    SadasyaModel(
      id: 'sad-005',
      name: 'प्रियांका अमोल जोशी',
      nameMarathi: 'प्रियांका अमोल जोशी',
      nameEnglish: 'Priyanka Amol Joshi',
      mobile: '+91 98901 22345',
      age: 34,
      gender: 'F',
      ward: 'प्रभाग १२',
      area: 'सदाशिव पेठ',
      address: 'ज्ञानप्रबोधिनी चौक, सदाशिव पेठ, पुणे',
      addressMarathi: 'ज्ञानप्रबोधिनी चौक, सदाशिव पेठ, पुणे',
      addressEnglish: 'Dnyanaprabodhini Chowk, Sadashiv Peth, Pune',
      isVoter: true,
      voterId: 'PMC4451290',
      status: 'Active',
      role: 'जनसंपर्क प्रतिनिधी',
      registeredAt: DateTime(2025, 2, 18),
    ),
    SadasyaModel(
      id: 'sad-006',
      name: 'अमोल दत्तात्रय जाधव',
      nameMarathi: 'अमोल दत्तात्रय जाधव',
      nameEnglish: 'Amol Dattatray Jadhav',
      mobile: '+91 97654 88712',
      age: 31,
      gender: 'M',
      ward: 'प्रभाग १२',
      area: 'शनिवार पेठ',
      address: 'विश्रामबाग वाडा परिसर, शनिवार पेठ, पुणे',
      addressMarathi: 'विश्रामबाग वाडा परिसर, शनिवार पेठ, पुणे',
      addressEnglish: 'Vishrambaug Wada Area, Shaniwar Peth, Pune',
      isVoter: true,
      voterId: 'PMC3321901',
      status: 'Active',
      role: 'सोशल मीडिया प्रमुख',
      registeredAt: DateTime(2025, 2, 22),
    ),
    SadasyaModel(
      id: 'sad-007',
      name: 'दिगंबर रघुनाथ गायकवाड',
      nameMarathi: 'दिगंबर रघुनाथ गायकवाड',
      nameEnglish: 'Digambar Raghunath Gaikwad',
      mobile: '+91 94220 55432',
      age: 49,
      gender: 'M',
      ward: 'प्रभाग १२',
      area: 'कसबा पेठ',
      address: 'जिजामाता चौक, कसबा पेठ, पुणे',
      addressMarathi: 'जिजामाता चौक, कसबा पेठ, पुणे',
      addressEnglish: 'Jijamata Chowk, Kasba Peth, Pune',
      isVoter: true,
      voterId: 'PMC1198421',
      status: 'Active',
      role: 'प्रभाग संघटक',
      registeredAt: DateTime(2025, 1, 28),
    ),
    SadasyaModel(
      id: 'sad-008',
      name: 'वैशाली सतीश कदम',
      nameMarathi: 'वैशाली सतीश कदम',
      nameEnglish: 'Vaishali Satish Kadam',
      mobile: '+91 98231 66789',
      age: 39,
      gender: 'F',
      ward: 'प्रभाग १२',
      area: 'शनिवार पेठ',
      address: 'अप्पा बळवंत चौक, शनिवार पेठ, पुणे',
      addressMarathi: 'अप्पा बळवंत चौक, शनिवार पेठ, पुणे',
      addressEnglish: 'Appa Balwant Chowk, Shaniwar Peth, Pune',
      isVoter: false,
      status: 'Active',
      role: 'महिला बचतगट समन्वयक',
      registeredAt: DateTime(2025, 3, 1),
    ),
    SadasyaModel(
      id: 'sad-009',
      name: 'महेश चंद्रकांत आवळे',
      nameMarathi: 'महेश चंद्रकांत आवळे',
      nameEnglish: 'Mahesh Chandrakant Awale',
      mobile: '+91 97300 44123',
      age: 45,
      gender: 'M',
      ward: 'प्रभाग २७',
      area: 'नवी पेठ',
      address: 'दांडेकर पूल परिसर, नवी पेठ - पर्वती, पुणे',
      addressMarathi: 'दांडेकर पूल परिसर, नवी पेठ - पर्वती, पुणे',
      addressEnglish: 'Dandekar Bridge Area, Navi Peth, Pune',
      isVoter: true,
      voterId: 'PMC8877123',
      status: 'Active',
      role: 'बूथ प्रमुख (बूथ २७/१)',
      registeredAt: DateTime(2025, 2, 5),
    ),
    SadasyaModel(
      id: 'sad-010',
      name: 'नितीन शांताराम जगताप',
      nameMarathi: 'नितीन शांताराम जगताप',
      nameEnglish: 'Nitin Shantaram Jagtap',
      mobile: '+91 96041 33456',
      age: 26,
      gender: 'M',
      ward: 'प्रभाग १२',
      area: 'शनिवार पेठ',
      address: 'रमणबाग हायस्कूल परिसर, शनिवार पेठ, पुणे',
      addressMarathi: 'रमणबाग हायस्कूल परिसर, शनिवार पेठ, पुणे',
      addressEnglish: 'Ramanbaug School Area, Shaniwar Peth, Pune',
      isVoter: true,
      voterId: 'PMC9912045',
      status: 'Active',
      role: 'युवा कार्यकर्ता',
      registeredAt: DateTime(2025, 3, 5),
    ),
    SadasyaModel(
      id: 'sad-011',
      name: 'संगीता रवींद्र भोसले',
      nameMarathi: 'संगीता रवींद्र भोसले',
      nameEnglish: 'Sangita Ravindra Bhosale',
      mobile: '+91 98505 11987',
      age: 47,
      gender: 'F',
      ward: 'प्रभाग १२',
      area: 'नाना पेठ',
      address: 'म.न.पा. दवाखान्यामागे, नाना पेठ, पुणे',
      addressMarathi: 'म.न.पा. दवाखान्यामागे, नाना पेठ, पुणे',
      addressEnglish: 'Behind PMC Dispensary, Nana Peth, Pune',
      isVoter: false,
      status: 'Active',
      role: 'मतदार नोंदणी दूत',
      registeredAt: DateTime(2025, 3, 8),
    ),
    SadasyaModel(
      id: 'sad-012',
      name: 'ॲड. केदार प्रभाकर पटवर्धन',
      nameMarathi: 'ॲड. केदार प्रभाकर पटवर्धन',
      nameEnglish: 'Adv. Kedar Prabhakar Patwardhan',
      mobile: '+91 98224 88765',
      age: 51,
      gender: 'M',
      ward: 'प्रभाग १२',
      area: 'शनिवार पेठ',
      address: 'चितळे बंधू शेजारी, शनिवार पेठ, पुणे',
      addressMarathi: 'चितळे बंधू शेजारी, शनिवार पेठ, पुणे',
      addressEnglish: 'Near Chitale Bandhu, Shaniwar Peth, Pune',
      isVoter: true,
      voterId: 'PMC5521980',
      status: 'Active',
      role: 'कायदेशीर व निवडणूक सल्लागार',
      registeredAt: DateTime(2025, 1, 15),
    ),
  ];

  /// Get sadasyas with optional search query, area filter, and voter/non-voter filter
  Future<List<SadasyaModel>> getSadasyas({
    String? query,
    String? area,
    String? filterType, // 'all', 'voter', 'non-voter'
  }) async {
    // Try Supabase first if available
    try {
      var dbQuery = _client.from('sadasya').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }
      final response = await dbQuery.order('created_at', ascending: false);
      if (response.isNotEmpty) {
        final dbList = response.map((json) => SadasyaModel.fromJson(json)).toList();
        return _applyFilters(dbList, query: query, area: area, filterType: filterType);
      }
    } catch (_) {
      // Fallback gracefully to seed state
    }

    await Future.delayed(const Duration(milliseconds: 100));
    return _applyFilters(_sadasyas, query: query, area: area, filterType: filterType);
  }

  List<SadasyaModel> _applyFilters(
    List<SadasyaModel> list, {
    String? query,
    String? area,
    String? filterType,
  }) {
    var result = List<SadasyaModel>.from(list);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((s) {
        return s.name.toLowerCase().contains(q) ||
            (s.nameMarathi?.toLowerCase().contains(q) ?? false) ||
            (s.nameEnglish?.toLowerCase().contains(q) ?? false) ||
            s.mobile.replaceAll(' ', '').contains(q.replaceAll(' ', '')) ||
            (s.voterId?.toLowerCase().contains(q) ?? false) ||
            (s.address.toLowerCase().contains(q));
      }).toList();
    }

    if (area != null && area.trim().isNotEmpty && area.trim().toLowerCase() != 'all') {
      final a = area.trim().toLowerCase();
      result = result.where((s) => (s.area?.toLowerCase().contains(a) ?? false)).toList();
    }

    if (filterType == 'voter') {
      result = result.where((s) => s.isVoter).toList();
    } else if (filterType == 'non-voter') {
      result = result.where((s) => !s.isVoter).toList();
    }

    return result;
  }

  /// Get member by ID
  Future<SadasyaModel?> getSadasyaById(String id) async {
    try {
      final response = await _client.from('sadasya').select('*').eq('id', id).maybeSingle();
      if (response != null) {
        return SadasyaModel.fromJson(response);
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _sadasyas.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add member
  Future<SadasyaModel> addSadasya(SadasyaModel member) async {
    try {
      final payload = member.toJson();
      if (_tenantId != null) {
        payload['tenant_id'] = _tenantId;
      }
      final response = await _client.from('sadasya').insert(payload).select().single();
      final created = SadasyaModel.fromJson(response);
      _sadasyas.insert(0, created);
      return created;
    } catch (_) {
      // Offline fallback
      _sadasyas.insert(0, member);
      return member;
    }
  }

  /// Update member
  Future<SadasyaModel> updateSadasya(SadasyaModel member) async {
    try {
      final payload = member.toJson();
      final response = await _client.from('sadasya').update(payload).eq('id', member.id).select().single();
      final updated = SadasyaModel.fromJson(response);
      final idx = _sadasyas.indexWhere((s) => s.id == member.id);
      if (idx != -1) _sadasyas[idx] = updated;
      return updated;
    } catch (_) {
      final idx = _sadasyas.indexWhere((s) => s.id == member.id);
      if (idx != -1) {
        _sadasyas[idx] = member;
        return member;
      }
      throw Exception('Member not found');
    }
  }

  /// Delete member
  Future<void> deleteSadasya(String id) async {
    try {
      await _client.from('sadasya').delete().eq('id', id);
    } catch (_) {}
    _sadasyas.removeWhere((s) => s.id == id);
  }

  /// Get distinct areas with count
  Future<Map<String, int>> getAreasWithCount() async {
    final Map<String, int> counts = {};
    for (final s in _sadasyas) {
      if (s.area != null && s.area!.trim().isNotEmpty) {
        final a = s.area!.trim();
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Get quick summary stats
  Future<Map<String, int>> getStats() async {
    final total = _sadasyas.length;
    final voters = _sadasyas.where((s) => s.isVoter).length;
    final nonVoters = total - voters;
    final distinctAreas = _sadasyas.map((s) => s.area).where((a) => a != null && a.isNotEmpty).toSet().length;

    return {
      'total': total,
      'voters': voters,
      'nonVoters': nonVoters,
      'areas': distinctAreas,
    };
  }
}

final sadasyaRepoProvider = Provider<SadasyaRepository>((ref) {
  return SadasyaRepository();
});
