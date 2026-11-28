import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/delta_sync_cache.dart';
import '../models/karyakarta_work_model.dart';

final karyakartaWorkRepoProvider = Provider<KaryakartaWorkRepository>((ref) {
  return KaryakartaWorkRepository();
});

class KaryakartaWorkRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<KaryakartaWorkStaff>> getStaff({
    String? category,
    String? query,
    String? area,
  }) async {
    try {
      var dbQuery = _client.from('staff').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }
      final cacheKey = 'karyakarta_work_${_tenantId ?? 'default'}';
      final response = await DeltaSyncCache.sync(cacheKey, (lastSyncedAt) async {
        var q = dbQuery;
        if (lastSyncedAt != null) {
          q = q.gt('updated_at', lastSyncedAt);
        }
        final res = await q.order('name', ascending: true);
        return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      final list = (response as List<dynamic>)
          .map((item) => KaryakartaWorkStaff.fromJson(item as Map<String, dynamic>))
          .toList();

      return _filterStaff(list, category: category, query: query, area: area);
    } catch (_) {
      return [];
    }
  }

  List<KaryakartaWorkStaff> _filterStaff(
    List<KaryakartaWorkStaff> staffList, {
    String? category,
    String? query,
    String? area,
  }) {
    return staffList.where((s) {
      if (category != null && category.isNotEmpty && category != 'All') {
        if (s.category.toLowerCase() != category.toLowerCase()) return false;
      }
      if (area != null && area.isNotEmpty && area != 'All') {
        if (s.area == null || !s.area!.toLowerCase().contains(area.toLowerCase())) {
          return false;
        }
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchName = s.name.toLowerCase().contains(q) ||
            (s.nameMarathi?.toLowerCase().contains(q) ?? false);
        final matchMobile = s.mobile.contains(q);
        final matchRole = s.role.toLowerCase().contains(q);
        final matchArea = s.area?.toLowerCase().contains(q) ?? false;
        if (!matchName && !matchMobile && !matchRole && !matchArea) return false;
      }
      return true;
    }).toList();
  }

  Future<List<KaryakartaWorkTask>> getTasks() async {
    try {
      var dbQuery = _client.from('tasks').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }
      final response = await dbQuery.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((item) => KaryakartaWorkTask.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<KaryakartaWorkComplaint>> getComplaints() async {
    try {
      var dbQuery = _client.from('complaints').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }
      final response = await dbQuery.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((item) => KaryakartaWorkComplaint.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<KaryakartaStaffWorkload>> getStaffWorkloads({
    String? category,
    String? query,
    String? area,
  }) async {
    final staff = await getStaff(category: category, query: query, area: area);
    final tasks = await getTasks();
    final complaints = await getComplaints();

    final workloads = staff.map((s) {
      final sTasks = tasks.where((t) => t.assignedStaffId == s.id).toList();
      final sComplaints = complaints.where((c) => c.assignedTo == s.id).toList();
      return KaryakartaStaffWorkload(
        staff: s,
        tasks: sTasks,
        complaints: sComplaints,
      );
    }).toList();

    workloads.sort((a, b) {
      if (b.totalAssigned != a.totalAssigned) {
        return b.totalAssigned.compareTo(a.totalAssigned);
      }
      return b.totalPending.compareTo(a.totalPending);
    });

    return workloads;
  }

  Future<KaryakartaWorkloadSummary> getSummaryStats({String? category}) async {
    final staff = await getStaff(category: category);
    final staffIds = staff.map((s) => s.id).toSet();

    final allTasks = await getTasks();
    final allComplaints = await getComplaints();

    final categoryTasks = (category == null || category.isEmpty || category == 'All')
        ? allTasks
        : allTasks.where((t) => t.assignedStaffId != null && staffIds.contains(t.assignedStaffId)).toList();

    final categoryComplaints = (category == null || category.isEmpty || category == 'All')
        ? allComplaints
        : allComplaints.where((c) => c.assignedTo != null && staffIds.contains(c.assignedTo)).toList();

    final totalTasks = categoryTasks.length;
    final completedTasks = categoryTasks.where((t) => t.isCompleted).length;
    final inProgressTasks = categoryTasks.where((t) => t.isInProgress).length;
    final pendingTasks = categoryTasks.where((t) => t.isPending).length;

    final totalComplaints = categoryComplaints.length;
    final resolvedComplaints = categoryComplaints.where((c) => c.isResolved).length;
    final inProgressComplaints = categoryComplaints.where((c) => c.isInProgress).length;
    final pendingComplaints = categoryComplaints.where((c) => c.isPending).length;

    return KaryakartaWorkloadSummary(
      totalLoad: totalTasks + totalComplaints,
      pendingLoad: pendingTasks + pendingComplaints,
      inProgressLoad: inProgressTasks + inProgressComplaints,
      completedLoad: completedTasks + resolvedComplaints,
      totalTasks: totalTasks,
      totalComplaints: totalComplaints,
    );
  }

  Future<List<KaryakartaWorkTask>> getUnassignedTasks() async {
    final allTasks = await getTasks();
    return allTasks.where((t) => t.assignedStaffId == null || t.assignedStaffId!.isEmpty).toList();
  }

  Future<List<KaryakartaWorkComplaint>> getUnassignedComplaints() async {
    final allComplaints = await getComplaints();
    return allComplaints.where((c) => c.assignedTo == null || c.assignedTo!.isEmpty).toList();
  }

  Future<void> assignTask({
    required String staffId,
    required String title,
    String? description,
    String priority = 'Medium',
    DateTime? dueDate,
    String? dueTime,
    String? address,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'priority': priority,
      'status': 'Pending',
      'due_date': (dueDate ?? DateTime.now().add(const Duration(days: 1))).toIso8601String(),
      'due_time': dueTime ?? '10:00',
      'address': address,
      'assigned_to': staffId,
      'assigned_staff_id': staffId,
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _client.from('tasks').insert(payload);
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    var query = _client.from('tasks').update({'status': newStatus}).eq('id', taskId);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> reassignTask(String taskId, String newStaffId) async {
    var query = _client.from('tasks').update({
      'assigned_to': newStaffId.isEmpty ? null : newStaffId,
      'assigned_staff_id': newStaffId.isEmpty ? null : newStaffId,
    }).eq('id', taskId);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> updateComplaintStatus(String complaintId, String newStatus) async {
    var query = _client.from('complaints').update({'status': newStatus}).eq('id', complaintId);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> reassignComplaint(String complaintId, String newStaffId) async {
    var query = _client.from('complaints').update({
      'assigned_to': newStaffId.isEmpty ? null : newStaffId,
      'status': newStaffId.isNotEmpty ? 'Assigned' : 'Pending',
    }).eq('id', complaintId);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<List<String>> getAvailableAreas() async {
    final staff = await getStaff();
    final areas = <String>{};
    for (final s in staff) {
      if (s.area != null && s.area!.isNotEmpty) areas.add(s.area!);
    }
    return areas.toList()..sort();
  }

  Future<List<KaryakartaWorkStaff>> getAllStaffList() => getStaff();
}
