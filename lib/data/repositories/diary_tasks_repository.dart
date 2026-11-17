import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/diary_task_model.dart';

class DiaryTasksRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<DiaryTaskModel>> getTasks({
    String? status,
    String? search,
    String? area,
    DateTime? date,
  }) async {
    try {
      var query = _client.from('tasks').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      if (status != null && status != 'All') {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false).limit(200);
      final rawList = response as List<dynamic>;

      // Resolve assigned staff names if assigned_staff_id exists but assigned_to is empty
      final Map<String, String> staffMap = {};
      try {
        var sQuery = _client.from('staff').select('id, name');
        if (_tenantId != null && _tenantId!.isNotEmpty) {
          sQuery = sQuery.eq('tenant_id', _tenantId!);
        }
        final sRes = await sQuery;
        for (final s in (sRes as List<dynamic>)) {
          final m = s as Map<String, dynamic>;
          if (m['id'] != null && m['name'] != null) {
            staffMap[m['id'].toString()] = m['name'].toString();
          }
        }
      } catch (_) {}

      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if ((map['assigned_to'] == null || map['assigned_to'].toString().isEmpty) &&
            map['assigned_staff_id'] != null) {
          final sId = map['assigned_staff_id'].toString();
          if (staffMap.containsKey(sId)) {
            map['assigned_to'] = staffMap[sId];
          }
        }
        return DiaryTaskModel.fromJson(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<DiaryTaskModel?> addTask(DiaryTaskModel task) async {
    final payload = task.toJson(tenantId: _tenantId);
    final response = await _client.from('tasks').insert(payload).select().single();
    return DiaryTaskModel.fromJson(response);
  }

  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      var query = _client.from('tasks').update(updates).eq('id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      await query;
    } catch (_) {}
  }

  Future<void> toggleStatus(String id, bool isCurrentlyCompleted) async {
    final newStatus = isCurrentlyCompleted ? 'Pending' : 'Completed';
    await updateTask(id, {'status': newStatus});
  }

  Future<void> deleteTask(String id) async {
    try {
      var query = _client.from('tasks').delete().eq('id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      await query;
    } catch (_) {}
  }
}

final diaryTasksRepoProvider = Provider<DiaryTasksRepository>((ref) {
  return DiaryTasksRepository();
});
