import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/ward_provision_model.dart';

final wardProvisionsRepoProvider = Provider<WardProvisionsRepository>((ref) {
  return WardProvisionsRepository();
});

class WardProvisionsRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<WardProvisionModel>> getProvisions({
    String? year,
    String? category,
    String? status,
    String? query,
  }) async {
    try {
      var dbQuery = _client.from('ward_provisions').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (year != null && year.isNotEmpty && year != 'All') {
        dbQuery = dbQuery.eq('financial_year', year);
      }

      if (category != null && category.isNotEmpty && category != 'All') {
        dbQuery = dbQuery.eq('category', category);
      }

      if (status != null && status.isNotEmpty && status != 'All') {
        dbQuery = dbQuery.eq('status', status);
      }

      final response = await dbQuery.order('created_at', ascending: false);
      var list = (response as List<dynamic>)
          .map((item) => WardProvisionModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        list = list.where((p) {
          return p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.letterReference.toLowerCase().contains(q) ||
              p.area.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q);
        }).toList();
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<WardProvisionModel?> getProvisionById(String id) async {
    try {
      var query = _client.from('ward_provisions').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return WardProvisionModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<WardProvisionModel> addProvision(WardProvisionModel provision) async {
    final payload = {
      'title': provision.title,
      'description': provision.description,
      'requested_amount': provision.requestedAmount,
      'sanctioned_amount': provision.sanctionedAmount,
      'requested_date': provision.requestedDate.isNotEmpty ? provision.requestedDate : null,
      'sanctioned_date': provision.sanctionedDate,
      'status': provision.status,
      'financial_year': provision.financialYear,
      'category': provision.category,
      'area': provision.area,
      'letter_reference': provision.letterReference,
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _client.from('ward_provisions').insert(payload).select().single();
    return WardProvisionModel.fromJson(res);
  }

  Future<WardProvisionModel> updateProvision(WardProvisionModel updatedProvision) async {
    final payload = {
      'title': updatedProvision.title,
      'description': updatedProvision.description,
      'requested_amount': updatedProvision.requestedAmount,
      'sanctioned_amount': updatedProvision.sanctionedAmount,
      'requested_date': updatedProvision.requestedDate.isNotEmpty ? updatedProvision.requestedDate : null,
      'sanctioned_date': updatedProvision.sanctionedDate,
      'status': updatedProvision.status,
      'financial_year': updatedProvision.financialYear,
      'category': updatedProvision.category,
      'area': updatedProvision.area,
      'letter_reference': updatedProvision.letterReference,
      'updated_at': DateTime.now().toIso8601String(),
    };

    var query = _client.from('ward_provisions').update(payload).eq('id', updatedProvision.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return updatedProvision;
  }

  Future<bool> deleteProvision(String id) async {
    try {
      var query = _client.from('ward_provisions').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getStatistics({String? year}) async {
    final list = await getProvisions(year: year);
    final totalCount = list.length;
    final totalRequested = list.fold<double>(0.0, (acc, p) => acc + p.requestedAmount);
    final totalSanctioned = list.fold<double>(0.0, (acc, p) => acc + (p.sanctionedAmount ?? 0.0));
    final approvedCount = list.where((p) => p.status == 'Approved').length;
    final pendingCount = list.where((p) => p.status == 'Pending').length;

    return {
      'totalCount': totalCount,
      'totalRequested': totalRequested,
      'totalSanctioned': totalSanctioned,
      'approvedCount': approvedCount,
      'pendingCount': pendingCount,
    };
  }
}
