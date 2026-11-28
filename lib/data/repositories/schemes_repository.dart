import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/scheme_model.dart';

final schemesRepoProvider = Provider((ref) => SchemesRepository());

class SchemesRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // -------------------------------------------------------------
  // SCHEMES CRUD
  // -------------------------------------------------------------

  Future<List<SchemeModel>> getSchemes() async {
    try {
      var query = _client.from('schemes').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final cacheKey = 'schemes_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = query;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('created_at', ascending: false);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      final list = (response as List<dynamic>)
          .map((item) => SchemeModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<SchemeModel> createScheme(SchemeModel scheme) async {
    final payload = scheme.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      payload['tenant_id'] = _tenantId;
    }
    try {
      final response = await _client.from('schemes').insert(payload).select().single();
      return SchemeModel.fromJson(response);
    } catch (_) {
      return scheme;
    }
  }

  Future<void> updateScheme(SchemeModel scheme) async {
    try {
      final payload = scheme.toJson();
      var query = _client.from('schemes').update(payload).eq('id', scheme.id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }

  Future<void> deleteScheme(int id) async {
    try {
      var query = _client.from('schemes').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // SCHEME APPLICATIONS CRUD
  // -------------------------------------------------------------

  Future<List<SchemeApplicationModel>> getApplications() async {
    try {
      var query = _client.from('scheme_applications').select('*, schemes(name)');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.order('created_at', ascending: false);
      final list = (response as List<dynamic>)
          .map((item) => SchemeApplicationModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<SchemeApplicationModel> createApplication(SchemeApplicationModel app) async {
    final payload = app.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      payload['tenant_id'] = _tenantId;
    }
    try {
      final response = await _client.from('scheme_applications').insert(payload).select('*, schemes(name)').single();
      return SchemeApplicationModel.fromJson(response);
    } catch (_) {
      return app;
    }
  }

  Future<void> updateApplicationStatus(
    int id,
    String status, {
    String? benefit,
    String? rejectionReason,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{'status': status};
      if (benefit != null) payload['benefit'] = benefit;
      if (rejectionReason != null) payload['rejection_reason'] = rejectionReason;
      if (notes != null) payload['notes'] = notes;

      var query = _client.from('scheme_applications').update(payload).eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }

  Future<void> deleteApplication(int id) async {
    try {
      var query = _client.from('scheme_applications').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }
}
