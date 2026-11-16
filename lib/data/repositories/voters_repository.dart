import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/voter_model.dart';

final votersRepoProvider = Provider((ref) => VotersRepository());

class VotersRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<VoterModel>> getVoters({
    int page = 0,
    int pageSize = 30,
    String? query,
    String? boothFilter,
    String? favourFilter,
    String? genderFilter,
    String? ageRangeFilter,
    bool isFriendOnly = false,
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

      if (ageRangeFilter != null && ageRangeFilter.isNotEmpty && ageRangeFilter != 'All') {
        if (ageRangeFilter == '18-25') {
          dbQuery = dbQuery.gte('age', 18).lte('age', 25);
        } else if (ageRangeFilter == '26-40') {
          dbQuery = dbQuery.gte('age', 26).lte('age', 40);
        } else if (ageRangeFilter == '41-60') {
          dbQuery = dbQuery.gte('age', 41).lte('age', 60);
        } else if (ageRangeFilter == '60+') {
          dbQuery = dbQuery.gt('age', 60);
        }
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim();
        dbQuery = dbQuery.or(
          'name_marathi.ilike.%$q%,name_english.ilike.%$q%,epic_no.ilike.%$q%,mobile.ilike.%$q%',
        );
      }

      final start = page * pageSize;
      final end = start + pageSize - 1;

      final List<dynamic> response = await dbQuery
          .order('serial_no', ascending: true)
          .range(start, end);

      return response
          .map((item) => VoterModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VoterModel>> searchVoters({
    int page = 0,
    int pageSize = 30,
    String? query,
    String? boothFilter,
    String? favourFilter,
    String? genderFilter,
    String? ageRangeFilter,
    bool isFriendOnly = false,
  }) {
    return getVoters(
      page: page,
      pageSize: pageSize,
      query: query,
      boothFilter: boothFilter,
      favourFilter: favourFilter,
      genderFilter: genderFilter,
      ageRangeFilter: ageRangeFilter,
      isFriendOnly: isFriendOnly,
    );
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
      return response
          .map((item) => VoterModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateFavour(String voterId, String favour) async {
    try {
      var query = _client.from('voters').update({'favour': favour}).eq('id', voterId);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }

  Future<void> toggleFriendRelative(String voterId, [bool? currentVal]) async {
    try {
      final newVal = currentVal != null ? !currentVal : true;
      var query = _client.from('voters').update({
        'is_friend_relative': newVal,
      }).eq('id', voterId);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }

  Future<Map<String, int>> getVotersStats() async {
    try {
      var baseQuery = _client.from('voters').select('favour, is_friend_relative, booth');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        baseQuery = baseQuery.eq('tenant_id', _tenantId!);
      }
      final response = await baseQuery;
      final list = response as List<dynamic>;

      int fav = 0;
      int against = 0;
      int neutral = 0;
      int swing = 0;
      int friends = 0;
      final Set<String> booths = {};

      for (final item in list) {
        final f = item['favour']?.toString().toLowerCase();
        if (f == 'favourable') fav++;
        if (f == 'against') against++;
        if (f == 'neutral') neutral++;
        if (f == 'swing') swing++;
        if (item['is_friend_relative'] == true) friends++;
        final b = item['booth']?.toString();
        if (b != null && b.isNotEmpty) booths.add(b);
      }

      return {
        'total': list.length,
        'favourable': fav,
        'against': against,
        'neutral': neutral,
        'swing': swing,
        'friends': friends,
        'booths': booths.length,
      };
    } catch (_) {
      return {
        'total': 0,
        'favourable': 0,
        'against': 0,
        'neutral': 0,
        'swing': 0,
        'friends': 0,
        'booths': 0,
      };
    }
  }

  Future<int> getVotersCount() async {
    final stats = await getVotersStats();
    return stats['total'] ?? 0;
  }

  Future<void> addVoter(VoterModel voter) async {
    final payload = voter.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      payload['tenant_id'] = _tenantId;
    }
    await _client.from('voters').insert(payload);
  }

  Future<List<String>> getBoothsList() async {
    try {
      var query = _client.from('voters').select('booth');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query;
      final Set<String> booths = {};
      for (final item in (response as List<dynamic>)) {
        final b = item['booth']?.toString();
        if (b != null && b.isNotEmpty) booths.add(b);
      }
      return booths.toList()..sort();
    } catch (_) {
      return [];
    }
  }
}
