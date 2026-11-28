import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/improvement_model.dart';

final improvementsRepoProvider = Provider<ImprovementsRepository>((ref) {
  return ImprovementsRepository();
});

class ImprovementsRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<ImprovementModel>> getImprovements({
    String? status,
    String? area,
    String? query,
  }) async {
    try {
      var dbQuery = _client.from('improvements').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (status != null && status.isNotEmpty && status != 'All') {
        dbQuery = dbQuery.eq('status', status);
      }

      if (area != null && area.isNotEmpty && area != 'All') {
        dbQuery = dbQuery.eq('area', area);
      }

      final cacheKey = 'improvements_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = dbQuery;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('votes', ascending: false);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      var list = (response as List<dynamic>)
          .map((item) => ImprovementModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        list = list.where((i) {
          return i.title.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q) ||
              i.location.toLowerCase().contains(q);
        }).toList();
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<ImprovementModel?> getImprovementById(String id) async {
    try {
      var query = _client.from('improvements').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return ImprovementModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<ImprovementModel> addImprovement(ImprovementModel improvement) async {
    final payload = {
      'title': improvement.title,
      'description': improvement.description,
      'location': improvement.location,
      'area': improvement.area,
      'status': improvement.status,
      'completion_date': improvement.completionDate,
      'votes': improvement.votes,
      'metadata': {
        if (improvement.peopleBenefited != null) 'people_benefited': improvement.peopleBenefited,
        if (improvement.estimatedBudget != null) 'estimated_budget': improvement.estimatedBudget,
      },
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _client.from('improvements').insert(payload).select().single();
    return ImprovementModel.fromJson(res);
  }

  Future<ImprovementModel> updateImprovement(ImprovementModel updated) async {
    final payload = {
      'title': updated.title,
      'description': updated.description,
      'location': updated.location,
      'area': updated.area,
      'status': updated.status,
      'completion_date': updated.completionDate,
      'votes': updated.votes,
      'metadata': {
        if (updated.peopleBenefited != null) 'people_benefited': updated.peopleBenefited,
        if (updated.estimatedBudget != null) 'estimated_budget': updated.estimatedBudget,
      },
    };

    var query = _client.from('improvements').update(payload).eq('id', updated.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return updated;
  }

  Future<bool> deleteImprovement(String id) async {
    try {
      var query = _client.from('improvements').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> voteImprovement(String id) async {
    try {
      final item = await getImprovementById(id);
      if (item != null) {
        final newVotes = item.votes + 1;
        var query = _client.from('improvements').update({'votes': newVotes}).eq('id', id);
        if (_tenantId != null && _tenantId!.isNotEmpty) {
          query = query.eq('tenant_id', _tenantId!);
        }
        await query;
        return newVotes;
      }
    } catch (_) {}
    return 0;
  }
}
