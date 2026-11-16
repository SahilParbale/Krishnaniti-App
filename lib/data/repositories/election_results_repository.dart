import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/election_result_model.dart';

class ElectionResultsRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<String>> getWards() async {
    final results = await getResults();
    return results.map((r) => r.wardName).toSet().toList();
  }

  Future<List<String>> getCandidates(String ward) async {
    final results = await getResults(ward: ward);
    if (results.isEmpty) return [];
    return results.first.candidateVotes.keys.toList();
  }

  Future<List<ElectionResultModel>> getResults({String? ward}) async {
    try {
      var query = _client.from('election_results').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      if (ward != null && ward.isNotEmpty) {
        query = query.eq('ward_name', ward);
      }

      final response = await query.order('booth_number', ascending: true);
      return (response as List<dynamic>)
          .map((item) => ElectionResultModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ElectionResultModel> addResult(ElectionResultModel result) async {
    final payload = result.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      payload['tenant_id'] = _tenantId;
    }
    payload.remove('id');

    final res = await _client.from('election_results').insert(payload).select().single();
    return ElectionResultModel.fromJson(res);
  }

  Future<ElectionResultModel> updateResult(ElectionResultModel result) async {
    final payload = result.toJson();
    payload.remove('id');

    var query = _client.from('election_results').update(payload).eq('id', result.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return result;
  }

  Future<void> deleteResult(String id) async {
    var query = _client.from('election_results').delete().eq('id', id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }
}

final electionResultsRepoProvider = Provider<ElectionResultsRepository>((ref) {
  return ElectionResultsRepository();
});
