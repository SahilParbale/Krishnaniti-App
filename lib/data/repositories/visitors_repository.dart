import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/paginated_result.dart';
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

  Future<PaginatedResult<VisitorModel>> getPaginatedVisitors({
    int page = 1,
    int pageSize = 20,
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

      if (purpose != null && purpose.isNotEmpty && purpose != 'All') {
        query = query.eq('purpose', purpose);
      }

      if (area != null && area.isNotEmpty && area != 'All') {
        query = query.eq('area', area);
      }

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim();
        query = query.or('name.ilike.%$q%,mobile.ilike.%$q%,purpose.ilike.%$q%,area.ilike.%$q%');
      }

      final zeroBasedPage = page > 0 ? page - 1 : 0;
      final start = zeroBasedPage * pageSize;
      final end = start + pageSize - 1;

      final response = await query
          .order('visit_date', ascending: false)
          .range(start, end)
          .count(CountOption.exact);

      final items = (response.data as List<dynamic>)
          .map((item) => VisitorModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final total = response.count;

      return PaginatedResult<VisitorModel>(
        items: items,
        totalCount: total,
        currentPage: page,
        pageSize: pageSize,
      );
    } catch (_) {
      return PaginatedResult<VisitorModel>.empty(pageSize: pageSize);
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

