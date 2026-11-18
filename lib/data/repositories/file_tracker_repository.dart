import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/work_tracker_model.dart';

final fileTrackerRepoProvider = Provider<FileTrackerRepository>((ref) {
  return FileTrackerRepository();
});

class FileTrackerRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // ─────────────────────────────────────────────────────────────
  // Fetch All File Trackers (Table: work_trackers)
  // ─────────────────────────────────────────────────────────────
  Future<List<WorkTrackerModel>> getFileTrackers({
    String? status,
    String? search,
  }) async {
    try {
      var query = _client.from('work_trackers').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      if (status != null && status != 'All' && status.isNotEmpty) {
        query = query.eq('current_status', status);
      }

      final response = await query.order('updated_at', ascending: false);

      final list = (response as List<dynamic>)
          .map((item) => WorkTrackerModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim().toLowerCase();
        return list.where((item) {
          return item.title.toLowerCase().contains(term) ||
              item.subject.toLowerCase().contains(term) ||
              item.inwardNumber.toLowerCase().contains(term) ||
              item.outwardNumber.toLowerCase().contains(term) ||
              item.department.toLowerCase().contains(term);
        }).toList();
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Fetch Single File Tracker & Movement Stages
  // (Tables: work_trackers, work_tracker_history)
  // ─────────────────────────────────────────────────────────────
  Future<WorkTrackerModel?> getFileTrackerById(String id) async {
    try {
      var query = _client.from('work_trackers').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      final doc = await query.maybeSingle();
      if (doc == null) return null;

      // Fetch movement stages
      var stagesQuery = _client
          .from('work_tracker_history')
          .select('*')
          .eq('work_tracker_id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        stagesQuery = stagesQuery.eq('tenant_id', _tenantId!);
      }

      final stagesRes = await stagesQuery.order('created_at', ascending: false);
      final stages = (stagesRes as List<dynamic>)
          .map((s) => WorkTrackerMovementStage.fromJson(s as Map<String, dynamic>))
          .toList();

      return WorkTrackerModel.fromJson(doc, stages: stages);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Create File Tracker
  // ─────────────────────────────────────────────────────────────
  Future<WorkTrackerModel?> createFileTracker({
    required String title,
    required String subject,
    required String department,
    required String inwardNumber,
    required String outwardNumber,
    String currentStatus = 'Pending',
    required String description,
    String? initialStageName,
    String? initialLocation,
    String? updatedBy,
  }) async {
    final now = DateTime.now().toIso8601String();
    final payload = {
      'title': title,
      'subject': subject,
      'department': department,
      'inward_number': inwardNumber,
      'outward_number': outwardNumber,
      'current_status': currentStatus,
      'description': description,
      'created_at': now,
      'updated_at': now,
      if (_tenantId != null) 'tenant_id': _tenantId,
    };

    try {
      final res = await _client.from('work_trackers').insert(payload).select().single();
      final newTracker = WorkTrackerModel.fromJson(res);

      // Add initial stage history if provided
      if (initialStageName != null && initialStageName.isNotEmpty) {
        await addMovementStage(
          workTrackerId: newTracker.id,
          stageName: initialStageName,
          location: initialLocation ?? department,
          statusDescription: 'Initial registration: $currentStatus',
          updatedBy: updatedBy,
        );
      }

      return newTracker;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Update File Tracker
  // ─────────────────────────────────────────────────────────────
  Future<bool> updateFileTracker({
    required String id,
    String? title,
    String? subject,
    String? department,
    String? inwardNumber,
    String? outwardNumber,
    String? currentStatus,
    String? description,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (title != null) updates['title'] = title;
      if (subject != null) updates['subject'] = subject;
      if (department != null) updates['department'] = department;
      if (inwardNumber != null) updates['inward_number'] = inwardNumber;
      if (outwardNumber != null) updates['outward_number'] = outwardNumber;
      if (currentStatus != null) updates['current_status'] = currentStatus;
      if (description != null) updates['description'] = description;

      var query = _client.from('work_trackers').update(updates).eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Add Movement Stage (Table: work_tracker_history)
  // ─────────────────────────────────────────────────────────────
  Future<WorkTrackerMovementStage?> addMovementStage({
    required String workTrackerId,
    required String stageName,
    required String location,
    required String statusDescription,
    String? updatedBy,
    String? newTrackerStatus,
  }) async {
    final now = DateTime.now().toIso8601String();
    final payload = {
      'work_tracker_id': workTrackerId,
      'stage_name': stageName,
      'location': location,
      'status_description': statusDescription,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (_tenantId != null) 'tenant_id': _tenantId,
      'created_at': now,
    };

    try {
      final res = await _client.from('work_tracker_history').insert(payload).select().single();

      // Update work_trackers updated_at & current_status
      final trackerUpdates = <String, dynamic>{'updated_at': now};
      if (newTrackerStatus != null && newTrackerStatus.isNotEmpty) {
        trackerUpdates['current_status'] = newTrackerStatus;
      }
      var query = _client.from('work_trackers').update(trackerUpdates).eq('id', workTrackerId);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;

      return WorkTrackerMovementStage.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Delete File Tracker
  // ─────────────────────────────────────────────────────────────
  Future<bool> deleteFileTracker(String id) async {
    try {
      // 1. Delete associated history
      var histQuery = _client.from('work_tracker_history').delete().eq('work_tracker_id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        histQuery = histQuery.eq('tenant_id', _tenantId!);
      }
      await histQuery;

      // 2. Delete tracker
      var trackQuery = _client.from('work_trackers').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        trackQuery = trackQuery.eq('tenant_id', _tenantId!);
      }
      await trackQuery;
      return true;
    } catch (_) {
      return false;
    }
  }
}
