import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/work_history_model.dart';

final workHistoryRepoProvider = Provider<WorkHistoryRepository>((ref) {
  return WorkHistoryRepository();
});

class WorkHistoryRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<WorkHistoryModel>> getWorks() async {
    try {
      var query = _client.from('works').select('*');
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.order('created_at', ascending: false);
      final rawList = response as List<dynamic>;

      // Load feedback for these works
      final List<WorkHistoryModel> works = [];
      for (final item in rawList) {
        final map = Map<String, dynamic>.from(item as Map);
        final workId = map['id']?.toString() ?? '';

        List<WorkFeedbackModel> feedbacks = [];
        try {
          final fbRes = await _client
              .from('work_feedback')
              .select('*')
              .eq('work_id', workId)
              .order('created_at', ascending: false);
          feedbacks = (fbRes as List<dynamic>)
              .map((f) => WorkFeedbackModel.fromJson(Map<String, dynamic>.from(f as Map)))
              .toList();
        } catch (_) {}

        map['feedbacks'] = feedbacks.map((f) => f.toJson()).toList();
        if (feedbacks.isNotEmpty) {
          final sum = feedbacks.fold<double>(0, (acc, f) => acc + f.rating);
          map['feedback_rating'] = double.parse((sum / feedbacks.length).toStringAsFixed(1));
          map['feedback_count'] = feedbacks.length;
        }

        works.add(WorkHistoryModel.fromJson(map));
      }

      return works;
    } catch (_) {
      return [];
    }
  }

  Future<WorkHistoryModel?> getWorkById(String id) async {
    try {
      var query = _client.from('works').select('*').eq('id', id);
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response == null) return null;

      final map = Map<String, dynamic>.from(response);
      try {
        final fbRes = await _client
            .from('work_feedback')
            .select('id, work_id, citizen_name, rating, comment, created_at')
            .eq('work_id', id)
            .order('created_at', ascending: false)
            .limit(30);
        final feedbacks = (fbRes as List<dynamic>)
            .map((f) => WorkFeedbackModel.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList();
        map['feedbacks'] = feedbacks.map((f) => f.toJson()).toList();
        if (feedbacks.isNotEmpty) {
          final sum = feedbacks.fold<double>(0, (acc, f) => acc + f.rating);
          map['feedback_rating'] = double.parse((sum / feedbacks.length).toStringAsFixed(1));
          map['feedback_count'] = feedbacks.length;
        }
      } catch (_) {}

      return WorkHistoryModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<WorkHistoryModel> addWork(WorkHistoryModel work) async {
    final payload = {
      'title': work.title,
      'description': work.description,
      'location': work.location,
      'area': work.area,
      'status': work.status,
      'amount': work.amount ?? 0,
      'completion_date': work.date.isNotEmpty ? work.date : null,
      'metadata': {
        if (work.peopleBenefited != null) 'people_benefited': work.peopleBenefited,
      },
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _client.from('works').insert(payload).select().single();
    return WorkHistoryModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<WorkHistoryModel> updateWork(WorkHistoryModel updatedWork) async {
    final payload = {
      'title': updatedWork.title,
      'description': updatedWork.description,
      'location': updatedWork.location,
      'area': updatedWork.area,
      'status': updatedWork.status,
      'amount': updatedWork.amount ?? 0,
      'completion_date': updatedWork.date.isNotEmpty ? updatedWork.date : null,
      'metadata': {
        if (updatedWork.peopleBenefited != null) 'people_benefited': updatedWork.peopleBenefited,
      },
    };

    var query = _client.from('works').update(payload).eq('id', updatedWork.id);
    if (_tenantId != null) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
    return updatedWork;
  }

  Future<bool> deleteWork(String id) async {
    try {
      var query = _client.from('works').delete().eq('id', id);
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> addFeedback(String workId, WorkFeedbackModel feedback) async {
    await _client.from('work_feedback').insert({
      'work_id': workId,
      'rating': feedback.rating,
      'comment': feedback.comment,
      'citizen_name': feedback.citizenName,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
