import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/social_organization_model.dart';

final socialOrgRepoProvider = Provider<SocialOrganizationRepository>((ref) {
  return SocialOrganizationRepository();
});

class SocialOrganizationRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<SocialOrganizationModel>> getOrganizations({
    String? type,
    String? area,
    String? searchQuery,
    String? query,
    String? status,
  }) async {
    final effectiveQuery = query ?? searchQuery;
    try {
      var dbQuery = _client.from('social_organizations').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (type != null && type.isNotEmpty && type != 'All') {
        dbQuery = dbQuery.eq('type', type);
      }

      if (area != null && area.isNotEmpty && area != 'All') {
        dbQuery = dbQuery.eq('area', area);
      }

      if (effectiveQuery != null && effectiveQuery.trim().isNotEmpty) {
        final q = effectiveQuery.trim();
        dbQuery = dbQuery.or(
          'name.ilike.%$q%,president_name.ilike.%$q%,president_mobile.ilike.%$q%,area.ilike.%$q%',
        );
      }

      final cacheKey = 'social_organization_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = dbQuery;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('created_at', ascending: false);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      return (response as List<dynamic>)
          .map((item) => SocialOrganizationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<SocialOrganizationModel?> getOrganizationById(String id) async {
    try {
      var query = _client.from('social_organizations').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return SocialOrganizationModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<SocialOrganizationModel> addOrganization(SocialOrganizationModel org) async {
    final payload = org.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      payload['tenant_id'] = _tenantId;
    }
    payload.remove('id');

    final res = await _client
        .from('social_organizations')
        .insert(payload)
        .select()
        .single();

    return SocialOrganizationModel.fromJson(res);
  }

  Future<void> updateOrganization(SocialOrganizationModel org) async {
    final payload = org.toJson();
    payload.remove('id');
    var query = _client.from('social_organizations').update(payload).eq('id', org.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> deleteOrganization(String id) async {
    var query = _client.from('social_organizations').delete().eq('id', id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> addEvent(String orgId, SocialOrgEventModel event) async {
    final org = await getOrganizationById(orgId);
    if (org != null) {
      final updatedEvents = [event, ...org.eventsConducted];
      await _client.from('social_organizations').update({
        'events_conducted': updatedEvents.map((e) => e.toJson()).toList(),
      }).eq('id', orgId);
    }
  }

  Future<void> deleteEvent(String orgId, String eventId) async {
    final org = await getOrganizationById(orgId);
    if (org != null) {
      final updatedEvents = org.eventsConducted.where((e) => e.id != eventId).toList();
      await _client.from('social_organizations').update({
        'events_conducted': updatedEvents.map((e) => e.toJson()).toList(),
      }).eq('id', orgId);
    }
  }

  Future<Map<String, int>> getOrganizationStats() async {
    final list = await getOrganizations();
    int total = list.length;
    int ngos = 0;
    int sports = 0;
    int mandals = 0;

    for (final o in list) {
      if (o.type == 'ngo') {
        ngos++;
      } else if (o.type == 'sports_cricket') {
        sports++;
      } else if (o.type == 'ganpati_mandal' || o.type == 'navratri_mandal') {
        mandals++;
      }
    }

    return {
      'total': total,
      'ngos': ngos,
      'sports': sports,
      'mandals': mandals,
    };
  }
}
