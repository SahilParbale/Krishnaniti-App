import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/voter_model.dart';
import '../models/duplicate_voter_group_model.dart';

final duplicateVotersRepoProvider = Provider<DuplicateVotersRepository>((ref) {
  return DuplicateVotersRepository();
});

class DuplicateVotersRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<VoterModel>> _fetchLiveVoters() async {
    try {
      var query = _client.from('voters').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final cacheKey = 'duplicate_voters_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = query;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('serial_no', ascending: true);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      return (response as List<dynamic>)
          .map((item) => VoterModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Groups live voters into duplicate clusters based on match criteria
  Future<List<DuplicateVoterGroupModel>> getDuplicateGroups({
    String matchType = 'name',
    String? query,
  }) async {
    final liveVoters = await _fetchLiveVoters();
    if (liveVoters.isEmpty) return [];

    final Map<String, List<VoterModel>> groupMap = {};
    final Map<String, String> displayNames = {};

    for (final voter in liveVoters) {
      String key = '';
      String displayName = '';

      switch (matchType) {
        case 'epic':
          key = voter.epicNo.trim().toUpperCase().replaceAll(' ', '');
          displayName = voter.epicNo;
          break;

        case 'mobile':
          if (voter.mobile != null && voter.mobile!.trim().isNotEmpty) {
            key = voter.mobile!.trim().replaceAll(RegExp(r'[^0-9]'), '');
            displayName = voter.mobile!;
          }
          break;

        case 'name':
        default:
          final cleanEng = voter.nameEnglish.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
          final cleanMar = voter.nameMarathi.trim().replaceAll(RegExp(r'\s+'), ' ');
          key = cleanEng.isNotEmpty ? cleanEng : cleanMar;
          displayName = voter.nameMarathi.isNotEmpty ? voter.nameMarathi : voter.nameEnglish;
          break;
      }

      if (key.isNotEmpty) {
        groupMap.putIfAbsent(key, () => []).add(voter);
        displayNames.putIfAbsent(key, () => displayName);
      }
    }

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

    duplicateGroups.sort((a, b) => b.recordsCount.compareTo(a.recordsCount));

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
      var query = _client.from('voters').delete().eq('id', voterId);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// KPI Summary Statistics for Duplicate Voters
  Future<Map<String, dynamic>> getStatistics() async {
    final liveVoters = await _fetchLiveVoters();
    final groups = await getDuplicateGroups();
    final totalGroups = groups.length;
    final totalAffected = groups.fold<int>(0, (sum, g) => sum + g.recordsCount);
    final estExtra = groups.fold<int>(0, (sum, g) => sum + g.extraRecordsCount);

    return {
      'duplicateGroups': totalGroups,
      'totalAffectedVoters': totalAffected,
      'estimatedExtraRecords': estExtra,
      'cleanRecordsCount': (liveVoters.length - totalAffected).clamp(0, liveVoters.length),
    };
  }
}
