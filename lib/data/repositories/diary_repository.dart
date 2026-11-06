import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/diary_entry_model.dart';

class DiaryRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<DiaryEntryModel>> getEntries({
    String? meetingType,
    String? status,
    String? search,
    String? area,
    int limit = 100,
  }) async {
    try {
      var query = _client.from('gb_diary').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      if (meetingType != null && meetingType != 'All' && meetingType.isNotEmpty) {
        query = query.eq('meeting_type', meetingType);
      }

      if (status != null && status != 'All' && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      if (area != null && area.isNotEmpty) {
        query = query.ilike('area', '%$area%');
      }

      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim();
        query = query.or('subject.ilike.%$term%,description.ilike.%$term%');
      }

      final response = await query.order('meeting_date', ascending: false).limit(limit);

      return (response as List<dynamic>)
          .map((item) => DiaryEntryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<DiaryEntryModel?> getEntryById(String id) async {
    try {
      var query = _client.from('gb_diary').select('*').eq('id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      final response = await query.maybeSingle();
      if (response != null) {
        return DiaryEntryModel.fromJson(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DiaryEntryModel?> addEntry(DiaryEntryModel entry) async {
    try {
      final payload = entry.toJson(tenantId: _tenantId);
      final response = await _client.from('gb_diary').insert(payload).select().single();
      return DiaryEntryModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEntry(String id, Map<String, dynamic> updates) async {
    try {
      var query = _client.from('gb_diary').update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      await query;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      var query = _client.from('gb_diary').delete().eq('id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      await query;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, int>> getStats() async {
    try {
      final entries = await getEntries(limit: 500);
      int raised = 0;
      int inDiscussion = 0;
      int resolved = 0;
      int actionTaken = 0;

      for (final e in entries) {
        final st = e.status.toLowerCase();
        if (st == 'raised') {
          raised++;
        } else if (st == 'in discussion' || st == 'indiscussion') {
          inDiscussion++;
        } else if (st == 'resolved') {
          resolved++;
        } else if (st == 'action taken' || st == 'actiontaken') {
          actionTaken++;
        }
      }

      return {
        'total': entries.length,
        'raised': raised,
        'inDiscussion': inDiscussion,
        'resolved': resolved,
        'actionTaken': actionTaken,
      };
    } catch (_) {
      return {
        'total': 0,
        'raised': 0,
        'inDiscussion': 0,
        'resolved': 0,
        'actionTaken': 0,
      };
    }
  }
}

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository();
});

final diaryEntriesProvider = FutureProvider.autoDispose<List<DiaryEntryModel>>((ref) async {
  final repo = ref.watch(diaryRepositoryProvider);
  return repo.getEntries();
});
