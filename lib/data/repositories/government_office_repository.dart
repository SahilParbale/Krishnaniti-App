import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/government_office_model.dart';

final governmentOfficeRepoProvider = Provider<GovernmentOfficeRepository>((ref) {
  return GovernmentOfficeRepository();
});

class GovernmentOfficeRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<GovernmentOfficeModel>> getOffices({
    String? category,
    String? area,
    bool? isEmergencyOnly,
    String? query,
  }) async {
    try {
      var dbQuery = _client.from('government_offices').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (category != null && category.isNotEmpty && category != 'All') {
        dbQuery = dbQuery.eq('category', category);
      }

      if (area != null && area.isNotEmpty && area != 'All') {
        dbQuery = dbQuery.eq('area', area);
      }

      if (isEmergencyOnly == true) {
        dbQuery = dbQuery.eq('is_emergency', true);
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim();
        dbQuery = dbQuery.or(
          'name.ilike.%$q%,officer_name.ilike.%$q%,contact_number.ilike.%$q%,address.ilike.%$q%,area.ilike.%$q%',
        );
      }

      final response = await dbQuery.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((item) => GovernmentOfficeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<GovernmentOfficeModel?> getOfficeById(String id) async {
    try {
      var query = _client.from('government_offices').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return GovernmentOfficeModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<GovernmentOfficeModel> addOffice(GovernmentOfficeModel office) async {
    final payload = office.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      payload['tenant_id'] = _tenantId;
    }
    payload.remove('id');

    final res = await _client
        .from('government_offices')
        .insert(payload)
        .select()
        .single();

    return GovernmentOfficeModel.fromJson(res);
  }

  Future<GovernmentOfficeModel> updateOffice(GovernmentOfficeModel office) async {
    final payload = office.toJson();
    payload.remove('id');
    var query = _client.from('government_offices').update(payload).eq('id', office.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return office;
  }

  Future<bool> deleteOffice(String id) async {
    try {
      var query = _client.from('government_offices').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
      return true;
    } catch (_) {
      return false;
    }
  }
}
