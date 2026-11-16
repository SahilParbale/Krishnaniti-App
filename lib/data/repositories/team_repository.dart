import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/team_model.dart';

final teamRepoProvider = Provider((ref) => TeamRepository());

class TeamRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<TeamMemberModel>> getTeamMembers({
    String? category,
    String? area,
    String? searchQuery,
    String? query,
    String? partyWing,
  }) async {
    final effectiveQuery = query ?? searchQuery;
    try {
      var dbQuery = _client.from('staff').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (category != null && category.isNotEmpty && category != 'All') {
        dbQuery = dbQuery.eq('category', category);
      }

      if (area != null && area.isNotEmpty && area != 'All') {
        dbQuery = dbQuery.eq('area', area);
      }

      if (partyWing != null && partyWing.isNotEmpty && partyWing != 'All') {
        dbQuery = dbQuery.eq('party_wing', partyWing);
      }

      final response = await dbQuery.order('name');
      var list = (response as List<dynamic>)
          .map((json) => TeamMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (effectiveQuery != null && effectiveQuery.trim().isNotEmpty) {
        final q = effectiveQuery.trim().toLowerCase();
        list = list.where((m) {
          final matchName = m.name.toLowerCase().contains(q) ||
              (m.nameMarathi?.toLowerCase().contains(q) ?? false);
          final matchMobile = m.mobile.contains(q);
          final matchRole = m.role.toLowerCase().contains(q);
          final matchArea = (m.area?.toLowerCase().contains(q) ?? false);
          return matchName || matchMobile || matchRole || matchArea;
        }).toList();
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<TeamMemberModel?> getMemberById(String id) async {
    try {
      var query = _client.from('staff').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response != null) {
        return TeamMemberModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  Future<TeamMemberModel> addTeamMember(TeamMemberModel member) async {
    final payload = member.toJson();
    if (_tenantId != null && _tenantId!.isNotEmpty) payload['tenant_id'] = _tenantId;
    final response = await _client.from('staff').insert(payload).select().single();
    return TeamMemberModel.fromJson(response);
  }

  Future<TeamMemberModel> updateTeamMember(TeamMemberModel member) async {
    final payload = member.toJson();
    var query = _client.from('staff').update(payload).eq('id', member.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    final response = await query.select().single();
    return TeamMemberModel.fromJson(response);
  }

  Future<void> deleteTeamMember(String id) async {
    var query = _client.from('staff').delete().eq('id', id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<List<TeamTaskModel>> getMemberTasks(String staffId) async {
    try {
      var query = _client
          .from('tasks')
          .select('*')
          .eq('assigned_to', staffId);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((json) => TeamTaskModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> assignTask(String staffId, TeamTaskModel task) async {
    final payload = task.toJson();
    payload['assigned_to'] = staffId;
    if (_tenantId != null && _tenantId!.isNotEmpty) payload['tenant_id'] = _tenantId;
    await _client.from('tasks').insert(payload);
  }

  Future<void> updateTaskStatus(String staffId, String taskId, String status) async {
    var query = _client.from('tasks').update({'status': status}).eq('id', taskId);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<Map<String, int>> getTeamStats() async {
    try {
      var sQuery = _client.from('staff').select('category');
      var tQuery = _client.from('tasks').select('status');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        sQuery = sQuery.eq('tenant_id', _tenantId!);
        tQuery = tQuery.eq('tenant_id', _tenantId!);
      }
      final staffList = (await sQuery) as List<dynamic>;
      final taskList = (await tQuery) as List<dynamic>;

      int office = 0;
      int party = 0;
      int coop = 0;

      for (final m in staffList) {
        final cat = m['category']?.toString();
        if (cat == 'Office') {
          office++;
        } else if (cat == 'Party') {
          party++;
        } else if (cat == 'Cooperative') {
          coop++;
        }
      }

      int totalTasks = taskList.length;
      int completedTasks = taskList
          .where((t) => t['status'] == 'Completed' || t['status'] == 'Resolved')
          .length;

      return {
        'total': staffList.length,
        'office': office,
        'party': party,
        'cooperative': coop,
        'total_tasks': totalTasks,
        'completed_tasks': completedTasks,
      };
    } catch (_) {
      return {
        'total': 0,
        'office': 0,
        'party': 0,
        'cooperative': 0,
        'total_tasks': 0,
        'completed_tasks': 0,
      };
    }
  }

  List<String> getPartyWings() {
    return [
      'युवक आघाडी',
      'महिला आघाडी',
      'विद्यार्थी आघाडी',
      'शेतकरी आघाडी',
      'कामगार आघाडी',
      'व्यापारी आघाडी',
      'अल्पसंख्याक आघाडी',
      'ओबीसी आघाडी',
      'ज्येष्ठ नागरिक आघाडी',
      'क्रीडा आघाडी',
      'आयटी सेल',
      'सोशल मीडिया सेल',
      'जनसंपर्क विभाग',
      'स्वयंसेवक संघटना'
    ];
  }
}
