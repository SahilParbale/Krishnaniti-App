import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/opposition_model.dart';

final oppositionRepoProvider = Provider<OppositionRepository>((ref) => OppositionRepository());

class OppositionRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;
  List<OppositionMemberModel> _cachedMembers = [];

  OppositionRepository();

  Future<List<OppositionMemberModel>> getMembers({
    String? party,
    String? area,
    String? type,
    String? searchQuery,
    String? query,
  }) async {
    final effectiveQuery = query ?? searchQuery;
    try {
      var dbQuery = _client.from('opposition_karyakartas').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (party != null && party.isNotEmpty && party != 'all' && party != 'All') {
        dbQuery = dbQuery.eq('party', party);
      }

      if (area != null && area.isNotEmpty && area != 'all' && area != 'All') {
        dbQuery = dbQuery.eq('area', area);
      }

      if (type == 'candidates') {
        dbQuery = dbQuery.eq('is_candidate', true);
      } else if (type == 'workers') {
        dbQuery = dbQuery.eq('is_candidate', false);
      }

      final cacheKey = 'opposition_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = dbQuery;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('created_at', ascending: false);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      var list = (response as List<dynamic>)
          .map((item) => OppositionMemberModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (effectiveQuery != null && effectiveQuery.trim().isNotEmpty) {
        final q = effectiveQuery.trim().toLowerCase();
        list = list.where((m) {
          final matchName = m.name.toLowerCase().contains(q);
          final matchMobile = m.mobile?.contains(q) ?? false;
          final matchParty = m.party.toLowerCase().contains(q);
          final matchArea = m.area?.toLowerCase().contains(q) ?? false;
          final matchRole = m.role?.toLowerCase().contains(q) ?? false;
          final matchStrongholds = m.strongholds.any((s) => s.toLowerCase().contains(q));
          return matchName || matchMobile || matchParty || matchArea || matchRole || matchStrongholds;
        }).toList();
      }

      _cachedMembers = list;
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<OppositionMemberModel?> getMemberById(String id) async {
    try {
      var query = _client.from('opposition_karyakartas').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return OppositionMemberModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<OppositionMemberModel> addMember(OppositionMemberModel member) async {
    final payload = member.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      payload['tenant_id'] = _tenantId;
    }
    payload.remove('id');

    final res = await _client.from('opposition_karyakartas').insert(payload).select().single();
    return OppositionMemberModel.fromJson(res);
  }

  Future<OppositionMemberModel> updateMember(OppositionMemberModel member) async {
    final payload = member.toJson();
    payload.remove('id');

    var query = _client.from('opposition_karyakartas').update(payload).eq('id', member.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return member;
  }

  Future<void> deleteMember(String id) async {
    var query = _client.from('opposition_karyakartas').delete().eq('id', id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> addActivity(String memberId, OppositionActivityModel activity) async {
    final member = await getMemberById(memberId);
    if (member != null) {
      final updatedActivities = [activity, ...member.activities];
      await _client.from('opposition_karyakartas').update({
        'activities': updatedActivities.map((a) => a.toJson()).toList(),
      }).eq('id', memberId);
    }
  }

  Future<void> deleteActivity(String memberId, String activityId) async {
    final member = await getMemberById(memberId);
    if (member != null) {
      final updatedActivities = member.activities.where((a) => a.id != activityId).toList();
      await _client.from('opposition_karyakartas').update({
        'activities': updatedActivities.map((a) => a.toJson()).toList(),
      }).eq('id', memberId);
    }
  }

  Future<void> addNegativeStory(String memberId, OppositionNegativeStoryModel story) async {
    final member = await getMemberById(memberId);
    if (member != null) {
      final updatedStories = [story, ...member.negativeStories];
      await _client.from('opposition_karyakartas').update({
        'negative_stories': updatedStories.map((s) => s.toJson()).toList(),
      }).eq('id', memberId);
    }
  }

  Future<void> updateNegativeStory(String memberId, OppositionNegativeStoryModel story) async {
    final member = await getMemberById(memberId);
    if (member != null) {
      final updatedStories = member.negativeStories.map((s) => s.id == story.id ? story : s).toList();
      await _client.from('opposition_karyakartas').update({
        'negative_stories': updatedStories.map((s) => s.toJson()).toList(),
      }).eq('id', memberId);
    }
  }

  Future<void> deleteNegativeStory(String memberId, String storyId) async {
    final member = await getMemberById(memberId);
    if (member != null) {
      final updatedStories = member.negativeStories.where((s) => s.id != storyId).toList();
      await _client.from('opposition_karyakartas').update({
        'negative_stories': updatedStories.map((s) => s.toJson()).toList(),
      }).eq('id', memberId);
    }
  }

  Future<void> linkWorkerToCandidate(String workerId, String candidateId) async {
    var query = _client.from('opposition_karyakartas').update({
      'candidate_id': candidateId,
    }).eq('id', workerId);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> unlinkWorker(String workerId) async {
    var query = _client.from('opposition_karyakartas').update({
      'candidate_id': null,
    }).eq('id', workerId);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  List<OppositionMemberModel> getCandidateTeam(String candidateId) {
    return _cachedMembers.where((m) => !m.isCandidate && m.candidateId == candidateId).toList();
  }

  List<OppositionMemberModel> getUnassignedWorkers() {
    return _cachedMembers.where((m) => !m.isCandidate && (m.candidateId == null || m.candidateId!.isEmpty)).toList();
  }

  String getCandidateName(String candidateId) {
    final cand = _cachedMembers.where((m) => m.id == candidateId);
    if (cand.isNotEmpty) return cand.first.name;
    return candidateId;
  }

  Future<Map<String, int>> getOppositionStats() async {
    final members = await getMembers();
    int total = members.length;
    int candidates = 0;
    int workers = 0;
    int totalControversies = 0;
    int totalActivities = 0;

    for (final m in members) {
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
