import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/voter_application_model.dart';
import '../models/voter_model.dart';
import 'voters_repository.dart';

final voterApplicationsRepoProvider = Provider<VoterApplicationsRepository>((ref) {
  final votersRepo = ref.read(votersRepoProvider);
  return VoterApplicationsRepository(votersRepo);
});

class VoterApplicationsRepository {
  final VotersRepository _votersRepo;
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  VoterApplicationsRepository(this._votersRepo);

  // Realistic seed data for Prabhag 12 voter applications
  final List<VoterApplicationModel> _seedApplications = [
    VoterApplicationModel(
      id: 'app-01',
      applicantName: 'प्रथमेश संदीप शिंदे',
      applicantMobile: '9822104523',
      formType: 'Form 6',
      status: 'Approved',
      notes: '१८ वर्षे पूर्ण, पहिल्यांदाच मतदार नोंदणी. आधार व जन्मतारीख दाखला जोडला.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    VoterApplicationModel(
      id: 'app-02',
      applicantName: 'वैशाली अरविंद चव्हाण',
      applicantMobile: '9850123987',
      formType: 'Form 8',
      status: 'Submitted',
      notes: 'विवाहानंतर आडनाव व पत्ता दुरुस्ती. विवाह नोंदणी प्रमाणपत्र जोडले.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    VoterApplicationModel(
      id: 'app-03',
      applicantName: 'सुरेश विठ्ठल तांबडे',
      applicantMobile: '9765432109',
      formType: 'Form 7',
      status: 'Approved',
      notes: 'मतदार कायमस्वरूपी ठाणे येथे स्थलांतरित झाल्याने प्रभाग १२ यादीतून नाव वगळणे.',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    VoterApplicationModel(
      id: 'app-04',
      applicantName: 'प्रणाली दीपक माने',
      applicantMobile: '9890112233',
      formType: 'Form 6',
      status: 'Pending',
      notes: 'नवीन मतदार नोंदणी अर्ज. निवासाचा पुरावा (लाईट बिल) पडताळणी प्रलंबित.',
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
    ),
    VoterApplicationModel(
      id: 'app-05',
      applicantName: 'गजानन बाळकृष्ण मोरे',
      applicantMobile: '9822338877',
      formType: 'Form 8',
      status: 'Approved',
      notes: 'मतदार ओळखपत्रावरील जन्मदिनांक दुरुस्ती. पॅन कार्ड प्रत जोडली.',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    VoterApplicationModel(
      id: 'app-06',
      applicantName: 'निखील अशोक भिडे',
      applicantMobile: '9867543210',
      formType: 'Form 6',
      status: 'Submitted',
      notes: 'दुसऱ्या मतदारसंघातून स्थलांतर, प्रभाग १२ शनिवार पेठ येथे नाव समाविष्ट करणे.',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    VoterApplicationModel(
      id: 'app-07',
      applicantName: 'मंदाकिनी अनंत देशपांडे',
      applicantMobile: '9988776655',
      formType: 'Form 7',
      status: 'Pending',
      notes: 'मतदार मयत झाल्यामुळे यादीतून नाव कमी करणे. महानगरपालिका मृत्यू दाखला संलग्न.',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
    VoterApplicationModel(
      id: 'app-08',
      applicantName: 'रोहन मंगेश कुलकर्णी',
      applicantMobile: '9822156789',
      formType: 'Form 8',
      status: 'Approved',
      notes: 'जुने ओळखपत्र खराब झाल्यामुळे नवीन डिजिटल पीव्हीसी स्मार्ट मतदार ओळखपत्र मागणी.',
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
    ),
    VoterApplicationModel(
      id: 'app-09',
      applicantName: 'स्नेहल सचिन कदम',
      applicantMobile: '9823445566',
      formType: 'Form 6',
      status: 'Submitted',
      notes: 'नवीन मतदार नोंदणी. कॉलेज ओळखपत्र व पासपोर्ट फोटो जोडला.',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    VoterApplicationModel(
      id: 'app-10',
      applicantName: 'चंद्रकांत नारायण बापट',
      applicantMobile: '9823456789',
      formType: 'Search',
      status: 'Approved',
      notes: 'मतदार यादीतील भाग क्रमांक व खोली क्रमांक शोधून स्लिप वाटप केले.',
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
  ];

  late final List<VoterApplicationModel> _inMemoryList = List.from(_seedApplications);

  /// Fetch applications with optional search, status and formType filter
  Future<List<VoterApplicationModel>> getApplications({
    String? searchQuery,
    String? statusFilter,
    String? formTypeFilter,
  }) async {
    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        var query = _client
            .from('voter_applications')
            .select()
            .eq('tenant_id', tenantId);

        if (statusFilter != null && statusFilter != 'All') {
          query = query.eq('status', statusFilter);
        }
        if (formTypeFilter != null && formTypeFilter != 'All') {
          query = query.eq('form_type', formTypeFilter);
        }

        final response = await query.order('created_at', ascending: false);
        if (response.isNotEmpty) {
          final dbList = response
              .map((row) => VoterApplicationModel.fromJson(row))
              .toList();

          return _applyLocalFilter(dbList, searchQuery, statusFilter, formTypeFilter);
        }
      }
    } catch (_) {
      // Fallback to in-memory state
    }

    return _applyLocalFilter(_inMemoryList, searchQuery, statusFilter, formTypeFilter);
  }

  List<VoterApplicationModel> _applyLocalFilter(
    List<VoterApplicationModel> list,
    String? query,
    String? statusFilter,
    String? formTypeFilter,
  ) {
    return list.where((app) {
      if (statusFilter != null && statusFilter != 'All' && app.status != statusFilter) {
        return false;
      }
      if (formTypeFilter != null && formTypeFilter != 'All' && app.formType != formTypeFilter) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesName = app.applicantName.toLowerCase().contains(q);
        final matchesMobile = (app.applicantMobile ?? '').contains(q);
        final matchesNotes = (app.notes ?? '').toLowerCase().contains(q);
        final matchesFormType = app.formType.toLowerCase().contains(q) ||
            app.formTypeMarathi.toLowerCase().contains(q);
        if (!matchesName && !matchesMobile && !matchesNotes && !matchesFormType) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Get specific application by ID
  Future<VoterApplicationModel?> getApplicationById(String id) async {
    final list = await getApplications();
    try {
      return list.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add new application
  Future<VoterApplicationModel> addApplication(VoterApplicationModel application) async {
    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        final data = application.toJson();
        data['tenant_id'] = tenantId;
        data.remove('id');

        final res = await _client
            .from('voter_applications')
            .insert(data)
            .select()
            .single();

        final created = VoterApplicationModel.fromJson(res);
        _inMemoryList.insert(0, created);
        return created;
      }
    } catch (_) {
      // Local fallback
    }

    _inMemoryList.insert(0, application);
    return application;
  }

  /// Update existing application
  Future<void> updateApplication(VoterApplicationModel application) async {
    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        final data = application.toJson();
        data.remove('id');
        await _client
            .from('voter_applications')
            .update(data)
            .eq('id', application.id)
            .eq('tenant_id', tenantId);
      }
    } catch (_) {
      // Local fallback
    }

    final idx = _inMemoryList.indexWhere((a) => a.id == application.id);
    if (idx != -1) {
      _inMemoryList[idx] = application;
    }
  }

  /// Delete application
  Future<void> deleteApplication(String id) async {
    try {
      final tenantId = _tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        await _client
            .from('voter_applications')
            .delete()
            .eq('id', id)
            .eq('tenant_id', tenantId);
      }
    } catch (_) {
      // Local fallback
    }

    _inMemoryList.removeWhere((a) => a.id == id);
  }

  /// Search voters from constituency to auto-fill applicant
  Future<List<VoterModel>> searchVoters(String query) async {
    if (query.trim().length < 2) return [];
    return _votersRepo.searchVoters(query: query);
  }

  /// Get KPI summary statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final list = await getApplications();
    final total = list.length;
    final submitted = list.where((a) => a.status.toLowerCase() == 'submitted').length;
    final pending = list.where((a) => a.status.toLowerCase() == 'pending').length;
    final approved = list.where((a) => a.status.toLowerCase() == 'approved').length;
    final rejected = list.where((a) => a.status.toLowerCase() == 'rejected').length;

    return {
      'total': total,
      'submitted': submitted,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }
}
