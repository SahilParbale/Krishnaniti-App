import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/survey_model.dart';

class SurveysRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // Local state with authentic Prabhag 12 seed surveys
  final List<SurveyModel> _surveys = [
    SurveyModel(
      id: 'surv-001',
      title: 'प्रभाग १२ मध्ये २४ तास समान पाणीपुरवठा व दाबाबाबत नागरिकांचे समाधान सर्वेक्षण',
      description: 'समान पाणीपुरवठा योजनेअंतर्गत प्रभागातील विविध पेठांमध्ये पाणीपुरवठ्याचा दाब, वेळ आणि गुणवत्ता याविषयी नागरिकांचे प्रत्यक्ष मत जाणून घेणे.',
      area: 'शनिवार पेठ',
      status: 'Active',
      targetSampleSize: 426, // 1% of 42,560 voters
      createdAt: DateTime(2025, 2, 10),
      questions: const [
        SurveyQuestionModel(
          id: 'q1',
          text: 'आपल्या घरात दररोज पुरेशा दाबाने पाणीपुरवठा होतो का?',
          type: SurveyQuestionType.yesNo,
        ),
        SurveyQuestionModel(
          id: 'q2',
          text: 'सध्याची पाणी सोडण्याची वेळ आपल्यासाठी सोयीस्कर आहे का?',
          type: SurveyQuestionType.yesNo,
        ),
        SurveyQuestionModel(
          id: 'q3',
          text: 'पाणीपुरवठ्याबाबत सर्वात मोठी अडचण कोणती आहे?',
          type: SurveyQuestionType.mcq,
          options: ['कमी दाब', 'अवेळी पाणी', 'गढूळ पाणी', 'कोणतीही समस्या नाही'],
        ),
        SurveyQuestionModel(
          id: 'q4',
          text: 'प्रभागातील पाणीपुरवठा सुधारणा कामांचे एकूण समाधान रेटिंग द्या',
          type: SurveyQuestionType.rating,
        ),
      ],
    ),
    SurveyModel(
      id: 'surv-002',
      title: 'शनिवार पेठ व कसबा पेठ अंतर्गत भूमिगत ड्रेनेज व रस्ता काँक्रीटीकरण प्राधान्यक्रम',
      description: 'पुढील आर्थिक वर्षात प्रभागातील रस्ते व जुन्या ड्रेनेज वाहिन्या बदलण्यासाठी नागरिकांकडून प्राधान्यक्रम मागविणे.',
      area: 'कसबा पेठ',
      status: 'Active',
      targetSampleSize: 426,
      createdAt: DateTime(2025, 2, 18),
      questions: const [
        SurveyQuestionModel(
          id: 'q1',
          text: 'आपल्या गल्लीतील जुनी ड्रेनेज लाईन पावसाळ्यात तुंबते का?',
          type: SurveyQuestionType.yesNo,
        ),
        SurveyQuestionModel(
          id: 'q2',
          text: 'आपल्या परिसरात कोणत्या विकासकामाला सर्वोच्च प्राधान्य द्यावे?',
          type: SurveyQuestionType.mcq,
          options: ['सिमेंट काँक्रीट रस्ता', 'नवी ड्रेनेज लाईन', 'सीसीटीव्ही व पथदिवे', 'कचरा व्यवस्थापन'],
        ),
        SurveyQuestionModel(
          id: 'q3',
          text: 'प्रभागात नुकत्याच पूर्ण झालेल्या रस्ता कामांच्या दर्जाचे रेटिंग',
          type: SurveyQuestionType.rating,
        ),
      ],
    ),
    SurveyModel(
      id: 'surv-003',
      title: 'ज्येष्ठ नागरिक विरंगुळा केंद्र व विनामूल्य आरोग्य तपासणी शिबिर उपयुक्तता',
      description: 'नारायण पेठ व सदाशिव पेठ भागातील ज्येष्ठ नागरिकांसाठी सुरू केलेल्या विरंगुळा केंद्राच्या सेवा व पुढील आरोग्य उपक्रमांचे नियोजन.',
      area: 'नारायण पेठ',
      status: 'Active',
      targetSampleSize: 200,
      createdAt: DateTime(2025, 2, 25),
      questions: const [
        SurveyQuestionModel(
          id: 'q1',
          text: 'आपण किंवा आपल्या घरातील ज्येष्ठ नागरिक विरंगुळा केंद्राच्या उपक्रमात सहभागी होतात का?',
          type: SurveyQuestionType.yesNo,
        ),
        SurveyQuestionModel(
          id: 'q2',
          text: 'पुढील महिन्यात आयोजित मोफत आरोग्य शिबिरात कोणती तपासणी असावी?',
          type: SurveyQuestionType.mcq,
          options: ['नेत्र व मोतीबिंदू तपासणी', 'मधुमेह व रक्तदाब', 'ईसीजी व हृदय तपासणी', 'हाडांची घनता (BMD)'],
        ),
        SurveyQuestionModel(
          id: 'q3',
          text: 'आरोग्य शिबिरांच्या एकूण व्यवस्थापनाचे रेटिंग',
          type: SurveyQuestionType.rating,
        ),
      ],
    ),
    SurveyModel(
      id: 'surv-004',
      title: 'प्रभागातील घनकचरा व्यवस्थापन व घंटागाडी वेळेबाबत नागरिक जनमत',
      description: 'रास्ता पेठ व नाना पेठ परिसरात दररोज घंटागाडी येण्याची वेळ, सुका व ओला कचरा संकलन आणि स्वच्छता मोहिमेचा आढावा.',
      area: 'रास्ता पेठ',
      status: 'Closed',
      targetSampleSize: 300,
      createdAt: DateTime(2025, 1, 15),
      questions: const [
        SurveyQuestionModel(
          id: 'q1',
          text: 'आपल्या भागात दररोज ठरलेल्या वेळेवर घंटागाडी कचरा उचलण्यास येते का?',
          type: SurveyQuestionType.yesNo,
        ),
        SurveyQuestionModel(
          id: 'q2',
          text: 'परिसरातील सार्वजनिक स्वच्छता कर्मचाऱ्यांच्या नियमिततेचे रेटिंग',
          type: SurveyQuestionType.rating,
        ),
      ],
    ),
  ];

  // Seed simulated responses
  final Map<String, List<SurveyResponseModel>> _responses = {};

  SurveysRepository() {
    _initSeedResponses();
  }

  void _initSeedResponses() {
    // Generate 142 responses for Survey 1
    final s1Responses = <SurveyResponseModel>[];
    for (int i = 1; i <= 142; i++) {
      s1Responses.add(
        SurveyResponseModel(
          id: 'resp-1-$i',
          surveyId: 'surv-001',
          voterName: i <= 10 ? 'नागरिक $i (शनिवार पेठ)' : null,
          voterMobile: i <= 10 ? '+91 98220 ${10000 + i}' : null,
          answers: {
            'q1': (i % 5 == 0) ? 'No' : 'Yes', // ~80% Yes
            'q2': (i % 4 == 0) ? 'No' : 'Yes', // ~75% Yes
            'q3': (i % 6 == 0)
                ? 'कमी दाब'
                : (i % 7 == 0 ? 'अवेळी पाणी' : (i % 8 == 0 ? 'गढूळ पाणी' : 'कोणतीही समस्या नाही')),
            'q4': ((i % 5) + 1).clamp(3, 5), // Mostly 4-5 stars
          },
          submittedAt: DateTime(2025, 2, 11).add(Duration(hours: i * 2)),
        ),
      );
    }
    _responses['surv-001'] = s1Responses;

    // Generate 98 responses for Survey 2
    final s2Responses = <SurveyResponseModel>[];
    for (int i = 1; i <= 98; i++) {
      s2Responses.add(
        SurveyResponseModel(
          id: 'resp-2-$i',
          surveyId: 'surv-002',
          answers: {
            'q1': (i % 3 == 0) ? 'No' : 'Yes',
            'q2': (i % 4 == 0)
                ? 'सिमेंट काँक्रीट रस्ता'
                : (i % 4 == 1 ? 'नवी ड्रेनेज लाईन' : (i % 4 == 2 ? 'सीसीटीव्ही व पथदिवे' : 'कचरा व्यवस्थापन')),
            'q3': ((i % 5) + 1).clamp(2, 5),
          },
          submittedAt: DateTime(2025, 2, 19).add(Duration(hours: i * 3)),
        ),
      );
    }
    _responses['surv-002'] = s2Responses;

    // Generate 65 responses for Survey 3
    final s3Responses = <SurveyResponseModel>[];
    for (int i = 1; i <= 65; i++) {
      s3Responses.add(
        SurveyResponseModel(
          id: 'resp-3-$i',
          surveyId: 'surv-003',
          answers: {
            'q1': (i % 6 == 0) ? 'No' : 'Yes',
            'q2': (i % 4 == 0)
                ? 'नेत्र व मोतीबिंदू तपासणी'
                : (i % 4 == 1 ? 'मधुमेह व रक्तदाब' : (i % 4 == 2 ? 'ईसीजी व हृदय तपासणी' : 'हाडांची घनता (BMD)')),
            'q3': 5,
          },
          submittedAt: DateTime(2025, 2, 26).add(Duration(hours: i * 2)),
        ),
      );
    }
    _responses['surv-003'] = s3Responses;

    // Generate 120 responses for Survey 4
    final s4Responses = <SurveyResponseModel>[];
    for (int i = 1; i <= 120; i++) {
      s4Responses.add(
        SurveyResponseModel(
          id: 'resp-4-$i',
          surveyId: 'surv-004',
          answers: {
            'q1': (i % 4 == 0) ? 'No' : 'Yes',
            'q2': ((i % 5) + 1).clamp(3, 5),
          },
          submittedAt: DateTime(2025, 1, 16).add(Duration(hours: i * 2)),
        ),
      );
    }
    _responses['surv-004'] = s4Responses;
  }

  /// Get surveys with filters
  Future<List<SurveyModel>> getSurveys({
    String? query,
    String? area,
    String? status,
  }) async {
    // Try Supabase first
    try {
      var dbQuery = _client.from('surveys').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }
      final response = await dbQuery.order('created_at', ascending: false);
      if (response.isNotEmpty) {
        final dbList = response.map((json) => SurveyModel.fromJson(json)).toList();
        return _applyFilters(dbList, query: query, area: area, status: status);
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 100));
    return _applyFilters(_surveys, query: query, area: area, status: status);
  }

  List<SurveyModel> _applyFilters(
    List<SurveyModel> list, {
    String? query,
    String? area,
    String? status,
  }) {
    var result = List<SurveyModel>.from(list);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((s) {
        return s.title.toLowerCase().contains(q) || s.description.toLowerCase().contains(q);
      }).toList();
    }

    if (area != null && area.trim().isNotEmpty && area.trim().toLowerCase() != 'all') {
      final a = area.trim().toLowerCase();
      result = result.where((s) => (s.area?.toLowerCase().contains(a) ?? false)).toList();
    }

    if (status != null && status.trim().isNotEmpty && status.trim().toLowerCase() != 'all') {
      result = result.where((s) => s.status.toLowerCase() == status.toLowerCase()).toList();
    }

    return result;
  }

  /// Get survey by ID
  Future<SurveyModel?> getSurveyById(String id) async {
    try {
      final response = await _client.from('surveys').select('*').eq('id', id).maybeSingle();
      if (response != null) {
        return SurveyModel.fromJson(response);
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _surveys.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all responses for a survey
  Future<List<SurveyResponseModel>> getResponses(String surveyId) async {
    try {
      final response = await _client
          .from('survey_responses')
          .select('*, voters(id, name, name_marathi, mobile)')
          .eq('survey_id', surveyId)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        return response.map((json) => SurveyResponseModel.fromJson(json)).toList();
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 100));
    return _responses[surveyId] ?? [];
  }

  /// Create new survey
  Future<SurveyModel> createSurvey(SurveyModel survey) async {
    try {
      final payload = survey.toJson();
      if (_tenantId != null) payload['tenant_id'] = _tenantId;
      final response = await _client.from('surveys').insert(payload).select().single();
      final created = SurveyModel.fromJson(response);
      _surveys.insert(0, created);
      return created;
    } catch (_) {
      _surveys.insert(0, survey);
      return survey;
    }
  }

  /// Update survey
  Future<SurveyModel> updateSurvey(SurveyModel survey) async {
    try {
      final payload = survey.toJson();
      final response = await _client.from('surveys').update(payload).eq('id', survey.id).select().single();
      final updated = SurveyModel.fromJson(response);
      final idx = _surveys.indexWhere((s) => s.id == survey.id);
      if (idx != -1) _surveys[idx] = updated;
      return updated;
    } catch (_) {
      final idx = _surveys.indexWhere((s) => s.id == survey.id);
      if (idx != -1) {
        _surveys[idx] = survey;
        return survey;
      }
      throw Exception('Survey not found');
    }
  }

  /// Delete survey
  Future<void> deleteSurvey(String id) async {
    try {
      await _client.from('surveys').delete().eq('id', id);
    } catch (_) {}
    _surveys.removeWhere((s) => s.id == id);
    _responses.remove(id);
  }

  /// Submit answer response
  Future<void> submitResponse(SurveyResponseModel response) async {
    try {
      await _client.from('survey_responses').insert(response.toJson());
    } catch (_) {}

    final list = _responses[response.surveyId] ?? [];
    list.insert(0, response);
    _responses[response.surveyId] = list;
  }

  /// Get distinct areas with survey counts
  Future<Map<String, int>> getAreasWithCount() async {
    final Map<String, int> counts = {};
    for (final s in _surveys) {
      if (s.area != null && s.area!.trim().isNotEmpty) {
        final a = s.area!.trim();
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Get summary stats
  Future<Map<String, int>> getStats() async {
    final total = _surveys.length;
    final active = _surveys.where((s) => s.status == 'Active').length;
    final closed = _surveys.where((s) => s.status == 'Closed').length;
    final totalResponses = _responses.values.fold<int>(0, (sum, list) => sum + list.length);

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

