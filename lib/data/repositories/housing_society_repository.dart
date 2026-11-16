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

  Future<List<HousingSocietyModel>> getSocieties({
    String? searchQuery,
    String? area,
    String? areaFilter,
    String? status,
  }) async {
    final effectiveArea = area ?? areaFilter;
    try {
      var dbQuery = _client.from('housing_societies').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (effectiveArea != null && effectiveArea.isNotEmpty && effectiveArea != 'All') {
        dbQuery = dbQuery.eq('area', effectiveArea);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        dbQuery = dbQuery.or(
          'name.ilike.%$q%,chairman_name.ilike.%$q%,secretary_name.ilike.%$q%,area.ilike.%$q%,chairman_mobile.ilike.%$q%',
        );
      }

      final response = await dbQuery.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((item) => HousingSocietyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> getUniqueAreas() async {
    try {
      final societies = await getSocieties();
      final areas = societies.map((s) => s.area.trim()).where((a) => a.isNotEmpty).toSet().toList();
      areas.sort();
      return ['All', ...areas];
    } catch (_) {
      return ['All'];
    }
  }

  Future<HousingSocietyModel?> getSocietyById(String id) async {
    try {
      var query = _client.from('housing_societies').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return HousingSocietyModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<HousingSocietyModel> addSociety(HousingSocietyModel society) async {
    final data = society.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      data['tenant_id'] = _tenantId;
    }
    data.remove('id');

    final res = await _client
        .from('housing_societies')
        .insert(data)
        .select()
        .single();

    return HousingSocietyModel.fromJson(res);
  }

  Future<void> updateSociety(HousingSocietyModel society) async {
    final data = society.toJson();
    data.remove('id');
    var query = _client.from('housing_societies').update(data).eq('id', society.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> deleteSociety(String id) async {
    var query = _client.from('housing_societies').delete().eq('id', id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

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
