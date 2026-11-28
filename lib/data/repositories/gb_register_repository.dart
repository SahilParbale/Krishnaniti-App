import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/gb_register_entry_model.dart';

final gbRegisterRepoProvider = Provider<GbRegisterRepository>((ref) {
  return GbRegisterRepository();
});

class GbRegisterRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<GbRegisterEntryModel>> getEntries() async {
    try {
      var query = _client.from('gb_diary').select('*');
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final cacheKey = 'gb_register_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = query;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('meeting_date', ascending: false);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      return (response as List<dynamic>)
          .map((item) => GbRegisterEntryModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<GbRegisterEntryModel?> getEntryById(String id) async {
    try {
      var query = _client.from('gb_diary').select('*').eq('id', id);
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return GbRegisterEntryModel.fromJson(Map<String, dynamic>.from(response));
    } catch (_) {
      return null;
    }
  }

  Future<GbRegisterEntryModel> addEntry(GbRegisterEntryModel entry) async {
    final payload = {
      'meeting_date': entry.meetingDate,
      'meeting_type': entry.meetingType,
      'subject': entry.subject,
      'description': entry.description,
      'department': entry.department,
      'area': entry.area,
      'status': entry.status,
      'beneficiaries': entry.beneficiaries,
      'response': entry.response,
      'tags': entry.tags,
      if (entry.resolutionNo != null) 'resolution_no': entry.resolutionNo,
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _client.from('gb_diary').insert(payload).select().single();
    return GbRegisterEntryModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<GbRegisterEntryModel> updateEntry(GbRegisterEntryModel updatedEntry) async {
    final payload = {
      'meeting_date': updatedEntry.meetingDate,
      'meeting_type': updatedEntry.meetingType,
      'subject': updatedEntry.subject,
      'description': updatedEntry.description,
      'department': updatedEntry.department,
      'area': updatedEntry.area,
      'status': updatedEntry.status,
      'beneficiaries': updatedEntry.beneficiaries,
      'response': updatedEntry.response,
      'tags': updatedEntry.tags,
      if (updatedEntry.resolutionNo != null) 'resolution_no': updatedEntry.resolutionNo,
      'updated_at': DateTime.now().toIso8601String(),
    };

    var query = _client.from('gb_diary').update(payload).eq('id', updatedEntry.id);
    if (_tenantId != null) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return updatedEntry;
  }

  Future<bool> deleteEntry(String id) async {
    try {
      var query = _client.from('gb_diary').delete().eq('id', id);
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
      return true;
    } catch (_) {
      return false;
    }
  }
}
