import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/voter_application_model.dart';
import '../models/voter_model.dart';
import 'voters_repository.dart';

final voterApplicationsRepoProvider = Provider<VoterApplicationsRepository>((ref) {
  final votersRepo = ref.read(votersRepoProvider);
  return VoterApplicationsRepository(votersRepo);
});

class VoterApplicationsRepository {
  final VotersRepository _votersRepo;
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  VoterApplicationsRepository(this._votersRepo);

  Future<List<VoterApplicationModel>> getApplications({
    String? searchQuery,
    String? statusFilter,
    String? formTypeFilter,
  }) async {
    try {
      var dbQuery = _client.from('voter_applications').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (statusFilter != null && statusFilter != 'All') {
        dbQuery = dbQuery.eq('status', statusFilter);
      }

      if (formTypeFilter != null && formTypeFilter != 'All') {
        dbQuery = dbQuery.eq('form_type', formTypeFilter);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        dbQuery = dbQuery.or('applicant_name.ilike.%$q%,applicant_mobile.ilike.%$q%,notes.ilike.%$q%');
      }

      final response = await dbQuery.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((item) => VoterApplicationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<VoterApplicationModel?> getApplicationById(String id) async {
    try {
      var query = _client.from('voter_applications').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return VoterApplicationModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<VoterApplicationModel> addApplication(VoterApplicationModel application) async {
    final data = application.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      data['tenant_id'] = _tenantId;
    }
    data.remove('id');

    final res = await _client
        .from('voter_applications')
        .insert(data)
        .select()
        .single();

    return VoterApplicationModel.fromJson(res);
  }

  Future<void> updateApplication(VoterApplicationModel application) async {
    final data = application.toJson();
    data.remove('id');
    var query = _client.from('voter_applications').update(data).eq('id', application.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> deleteApplication(String id) async {
    var query = _client.from('voter_applications').delete().eq('id', id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<List<VoterModel>> searchVoters(String query) async {
    if (query.trim().length < 2) return [];
    return _votersRepo.getVoters(query: query, pageSize: 20);
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final list = await getApplications();
    final total = list.length;
    final submitted = list.where((a) => a.status.toLowerCase() == 'submitted').length;
    final pending = list.where((a) => a.status.toLowerCase() == 'pending').length;
    final approved = list.where((a) => a.status.toLowerCase() == 'approved').length;
    final rejected = list.where((a) => a.status.toLowerCase() == 'rejected').length;

    return {
      'total': total,
      'submitted': submitted,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }
}
