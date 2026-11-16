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

      return (response as List<dynamic>)
          .map((item) => DiaryTaskModel.fromJson(item as Map<String, dynamic>))
          .toList();
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
