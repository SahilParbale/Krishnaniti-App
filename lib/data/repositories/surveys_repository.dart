import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/survey_model.dart';

class SurveysRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<SurveyModel>> getSurveys({
    String? searchQuery,
    String? areaFilter,
    String? statusFilter,
  }) async {
    try {
      var dbQuery = _client.from('surveys').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }

      if (areaFilter != null && areaFilter.isNotEmpty && areaFilter != 'All') {
        dbQuery = dbQuery.eq('area', areaFilter);
      }

      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'All') {
        dbQuery = dbQuery.eq('status', statusFilter);
      }

      final response = await dbQuery.order('created_at', ascending: false);
      var list = (response as List<dynamic>)
          .map((item) => SurveyModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list = list.where((s) {
          final matchTitle = s.title.toLowerCase().contains(q);
          final matchDesc = s.description.toLowerCase().contains(q);
          final matchArea = (s.area?.toLowerCase().contains(q) ?? false);
          return matchTitle || matchDesc || matchArea;
        }).toList();
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<SurveyModel?> getSurveyById(String id) async {
    try {
      var query = _client.from('surveys').select('*').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response != null) {
        return SurveyModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  Future<List<SurveyResponseModel>> getSurveyResponses(String surveyId) async {
    try {
      var query = _client
          .from('survey_responses')
          .select('*')
          .eq('survey_id', surveyId)
          .order('created_at', ascending: false);
      final response = await query;
      return (response as List<dynamic>)
          .map((item) => SurveyResponseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<SurveyModel> addSurvey(SurveyModel survey) async {
    final payload = survey.toJson();
    if (_tenantId != null) payload['tenant_id'] = _tenantId;
    payload.remove('id');

    final response = await _client.from('surveys').insert(payload).select().single();
    return SurveyModel.fromJson(response);
  }

  Future<SurveyModel> createSurvey(SurveyModel survey) => addSurvey(survey);

  Future<List<SurveyResponseModel>> getResponses(String surveyId) => getSurveyResponses(surveyId);

  Future<SurveyModel> updateSurvey(SurveyModel survey) async {
    final payload = survey.toJson();
    payload.remove('id');

    var query = _client.from('surveys').update(payload).eq('id', survey.id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    final response = await query.select().single();
    return SurveyModel.fromJson(response);
  }

  Future<void> deleteSurvey(String id) async {
    var query = _client.from('surveys').delete().eq('id', id);
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      query = query.eq('tenant_id', _tenantId!);
    }
    await query;
  }

  Future<void> submitResponse(SurveyResponseModel response) async {
    await _client.from('survey_responses').insert(response.toJson());
  }

  Future<Map<String, int>> getAreasWithCount() async {
    final list = await getSurveys();
    final Map<String, int> counts = {};
    for (final s in list) {
      if (s.area != null && s.area!.trim().isNotEmpty) {
        final a = s.area!.trim();
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<Map<String, int>> getStats() async {
    final list = await getSurveys();
    final total = list.length;
    final active = list.where((s) => s.status == 'Active').length;
    final closed = list.where((s) => s.status == 'Closed').length;

    int totalResponses = 0;
    try {
      final res = await _client.from('survey_responses').select('id');
      totalResponses = (res as List).length;
    } catch (_) {}

    return {
      'total': total,
      'active': active,
      'closed': closed,
      'totalResponses': totalResponses,
    };
  }
}

final surveysRepoProvider = Provider<SurveysRepository>((ref) {
  return SurveysRepository();
});
