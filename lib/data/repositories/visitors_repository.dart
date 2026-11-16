import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/visitor_model.dart';

class VisitorsRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<VisitorModel>> getVisitors({
    String? search,
    String? purpose,
    String? area,
    DateTime? date,
  }) async {
    try {
      var query = _client.from('visitors').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      final response = await query.order('visit_date', ascending: false).limit(200);

      final list = (response as List<dynamic>)
          .map((item) => VisitorModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<VisitorModel?> addVisitor(VisitorModel visitor) async {
    try {
      final payload = visitor.toJson(tenantId: _tenantId);
      final response = await _client.from('visitors').insert(payload).select().single();
      return VisitorModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateVisitor(String id, Map<String, dynamic> updates) async {
    try {
      var query = _client.from('visitors').update(updates).eq('id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      await query;
    } catch (_) {}
  }

  Future<void> deleteVisitor(String id) async {
    try {
      var query = _client.from('visitors').delete().eq('id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      await query;
    } catch (_) {}
  }
}

final visitorsRepoProvider = Provider<VisitorsRepository>((ref) {
  return VisitorsRepository();
});

