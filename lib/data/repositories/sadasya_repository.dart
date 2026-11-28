import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/sadasya_model.dart';

class SadasyaRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<SadasyaModel>> getSadasyas({
    String? searchQuery,
    String? areaFilter,
    String? addressFilter,
    String? voterFilter,
  }) async {
    try {
      var dbQuery = _client.from('sadasya').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (areaFilter != null && areaFilter.isNotEmpty && areaFilter != 'All') {
        dbQuery = dbQuery.eq('area', areaFilter);
      }

      if (voterFilter == 'voter') {
        dbQuery = dbQuery.eq('is_voter', true);
      } else if (voterFilter == 'non-voter') {
        dbQuery = dbQuery.eq('is_voter', false);
      }

      final cacheKey = 'sadasya_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = dbQuery;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('created_at', ascending: false);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      var list = (response as List<dynamic>)
          .map((item) => SadasyaModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (addressFilter != null && addressFilter.isNotEmpty && addressFilter != 'All') {
        list = list.where((s) => s.address.toLowerCase().contains(addressFilter.toLowerCase())).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list = list.where((s) {
          final matchName = s.name.toLowerCase().contains(q) ||
              (s.nameMarathi?.toLowerCase().contains(q) ?? false) ||
              (s.nameEnglish?.toLowerCase().contains(q) ?? false);
          final matchMobile = s.mobile.contains(q);
          final matchArea = (s.area?.toLowerCase().contains(q) ?? false);
          final matchAddress = s.address.toLowerCase().contains(q);
          final matchRole = (s.role?.toLowerCase().contains(q) ?? false);
          return matchName || matchMobile || matchArea || matchAddress || matchRole;
        }).toList();
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<SadasyaModel?> getSadasyaById(String id) async {
    try {
      var query = _client.from('sadasya').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response != null) {
        return SadasyaModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  Future<SadasyaModel> addSadasya(SadasyaModel member) async {
    final payload = member.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      payload['tenant_id'] = _tenantId;
    }
    payload.remove('id');

    final response = await _client.from('sadasya').insert(payload).select().single();
    return SadasyaModel.fromJson(response);
  }

  Future<SadasyaModel> updateSadasya(SadasyaModel member) async {
    final payload = member.toJson();
    payload.remove('id');

    var query = _client.from('sadasya').update(payload).eq('id', member.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    final response = await query.select().single();
    return SadasyaModel.fromJson(response);
  }

  Future<void> deleteSadasya(String id) async {
    var query = _client.from('sadasya').delete().eq('id', id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<Map<String, int>> getAreasWithCount() async {
    final list = await getSadasyas();
    final Map<String, int> counts = {};
    for (final s in list) {
      if (s.area != null && s.area!.trim().isNotEmpty) {
        final a = s.area!.trim();
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<Map<String, int>> getStats() async {
    final list = await getSadasyas();
    final total = list.length;
    final voters = list.where((s) => s.isVoter).length;
    final nonVoters = total - voters;
    final distinctAreas = list.map((s) => s.area).where((a) => a != null && a.isNotEmpty).toSet().length;

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
