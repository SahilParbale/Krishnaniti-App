import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/team_model.dart';

final teamRepoProvider = Provider((ref) => TeamRepository());

class TeamRepository {
  final SupabaseClient _client = SupabaseService.instance.client;
  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // Authentic Prabhag 12 seed team database
  final List<TeamMemberModel> _seedMembers = [
    // 1. Office Team (कार्यालयीन कर्मचारी)
    TeamMemberModel(
      id: 'stf-001',
      name: 'Adv. Sachin Deshmukh',
      nameMarathi: 'अ‍ॅड. सचिन सुधाकर देशमुख',
      mobile: '9822011223',
      email: 'sachin.deshmukh@nagarsevak.office',
      role: 'Office Admin',
      area: 'शनिवार पेठ',
      category: 'Office',
      keywords: ['प्रशासन', 'परवानगी', 'अर्ज', 'शासकीय पत्रव्यवहार'],
      permissions: ['all', 'admin', 'letters', 'staff'],
      joinedDate: DateTime(2023, 1, 15),
      canAssignWork: true,
    ),
    TeamMemberModel(
      id: 'stf-002',
      name: 'Ramesh Balasaheb Kadam',
      nameMarathi: 'रमेश बाळासाहेब कदम',
      mobile: '9850334455',
      email: 'ramesh.kadam@nagarsevak.office',
      role: 'Supervisor',
      area: 'कसबा पेठ',
      category: 'Office',
      keywords: ['पाणी', 'ड्रेनेज', 'रस्ता', 'गटार', 'खड्डे', 'पाइपलाईन'],
      permissions: ['complaints', 'works', 'field'],
      joinedDate: DateTime(2023, 3, 10),
      canAssignWork: true,
    ),
    TeamMemberModel(
      id: 'stf-003',
      name: 'Pooja Anand Shinde',
      nameMarathi: 'पूजा आनंद शिंदे',
      mobile: '9890556677',
      email: 'pooja.shinde@nagarsevak.office',
      role: 'Executive',
      area: 'रविवार पेठ',
      category: 'Office',
      keywords: ['शासकीय योजना', 'दाखले', 'रेशनकार्ड', 'आरोग्य', 'पेन्शन'],
      permissions: ['schemes', 'visitors', 'diary'],
      joinedDate: DateTime(2023, 6, 1),
      canAssignWork: true,
    ),
    TeamMemberModel(
      id: 'stf-004',
      name: 'Sunil Tukaram Gaikwad',
      nameMarathi: 'सुनील तुकाराम गायकवाड',
      mobile: '9764112233',
      email: 'sunil.gaikwad@nagarsevak.office',
      role: 'Driver',
      area: 'प्रभाग १२',
      category: 'Office',
      keywords: ['वाहन', 'दौरा', 'साहित्य वाहतूक'],
      joinedDate: DateTime(2023, 4, 15),
      canAssignWork: false,
    ),
    TeamMemberModel(
      id: 'stf-005',
      name: 'Omkar Rajendra Jagtap',
      nameMarathi: 'ओंकार राजेंद्र जगताप',
      mobile: '9823998877',
      email: 'omkar.jagtap@nagarsevak.office',
      role: 'IT Cell Head',
      area: 'शनिवार पेठ',
      category: 'Office',
      keywords: ['सोशल मीडिया', 'व्हायरल', 'ग्राफिक्स', 'व्हॉट्सॲप', 'वेबसाईट'],
      permissions: ['social', 'media', 'ai_studio'],
      joinedDate: DateTime(2023, 8, 20),
      canAssignWork: true,
    ),

    // 2. Party Workers (पक्ष व संघटना कार्यकर्ते)
    TeamMemberModel(
      id: 'stf-006',
      name: 'Swapnil Vilasrao More',
      nameMarathi: 'स्वप्नील विलासराव मोरे',
      mobile: '9422019988',
      role: 'Karyakarta',
      area: 'शनिवार पेठ',
      category: 'Party',
      partyWing: 'युवक आघाडी',
      paksh: 'प्रभाग १२ जनविकास मंच',
      pad: 'प्रभाग युवक अध्यक्ष',
      keywords: ['युवक', 'क्रीडा स्पर्धा', 'शिबीर', 'आंदोलन', 'मेळावा'],
      joinedDate: DateTime(2022, 11, 1),
      canAssignWork: true,
    ),
    TeamMemberModel(
      id: 'stf-007',
      name: 'Manisha Chandrakant Bapat',
      nameMarathi: 'मनीषा चंद्रकांत बापट',
      mobile: '9890123987',
      role: 'Karyakarta',
      area: 'कसबा पेठ',
      category: 'Party',
      partyWing: 'महिला आघाडी',
      paksh: 'प्रभाग १२ जनविकास मंच',
      pad: 'महिला आघाडी संयोजिका',
      keywords: ['महिला बचतगट', 'हळदीकुंकू', 'आरोग्य तपासणी', 'सुरक्षा'],
      joinedDate: DateTime(2023, 2, 10),
      canAssignWork: true,
    ),
    TeamMemberModel(
      id: 'stf-008',
      name: 'Vikram Dnyaneshwar Joshi',
      nameMarathi: 'विक्रम ज्ञानेश्वर जोशी',
      mobile: '9850445566',
      role: 'Karyakarta',
      area: 'शनिवार पेठ',
      category: 'Party',
      partyWing: 'आयटी सेल',
      paksh: 'प्रभाग १२ जनविकास मंच',
      pad: 'सोशल मीडिया समन्वयक',
      keywords: ['फेसबुक', 'इन्स्टाग्राम', 'डिजिटल मोहीम', 'व्हिडिओ'],
      joinedDate: DateTime(2023, 5, 12),
      canAssignWork: true,
    ),
    TeamMemberModel(
      id: 'stf-009',
      name: 'Prabhakar Narayan Phadke',
      nameMarathi: 'प्रभाकर नारायण फडके',
      mobile: '9764778899',
      role: 'Karyakarta',
      area: 'सोमवार पेठ',
      category: 'Party',
      partyWing: 'ज्येष्ठ नागरिक आघाडी',
      paksh: 'प्रभाग १२ जनविकास मंच',
      pad: 'ज्येष्ठ नागरिक कक्ष प्रमुख',
      keywords: ['ज्येष्ठ नागरिक', 'विश्रांती गृह', 'आरोग्य', 'तीर्थक्षेत्र भेट'],
      joinedDate: DateTime(2023, 4, 1),
      canAssignWork: true,
    ),

    // 3. Cooperative & Municipal Liaisons (शासकीय व सहकार कर्मचारी)
    TeamMemberModel(
      id: 'stf-010',
      name: 'Santosh Mahadev Kamble',
      nameMarathi: 'संतोष महादेव कांबळे',
      mobile: '9822441100',
      role: 'Sanitation Worker',
      area: 'शनिवार पेठ व कसबा पेठ',
      category: 'Cooperative',
      societyName: 'मनपा परिमंडळ १ स्वच्छता विभाग',
      keywords: ['कचरा', 'घंटागाडी', 'सफाई', 'कंटेनर', 'झाडलोट'],
      joinedDate: DateTime(2023, 3, 1),
      canAssignWork: true,
    ),
    TeamMemberModel(
      id: 'stf-011',
      name: 'Dattatraya Baban Kulkarni',
      nameMarathi: 'दत्तात्रय बबन कुलकर्णी',
      mobile: '9850119922',
      role: 'Helper',
      area: 'सोमवार पेठ व रविवार पेठ',
      category: 'Cooperative',
      societyName: 'महावितरण विद्युत शाखा कार्यालय',
      keywords: ['लाईट', 'पोल', 'विद्युत पुरवठा', 'पथदिवे', 'डीपी बॉक्स'],
      joinedDate: DateTime(2023, 6, 15),
      canAssignWork: true,
    ),
    TeamMemberModel(
      id: 'stf-012',
      name: 'Milind Yashwant Sathe',
      nameMarathi: 'मिलिंद यशवंत साठे',
      mobile: '9823554433',
      role: 'Supervisor',
      area: 'शनिवार पेठ',
      category: 'Cooperative',
      societyName: 'शनिवार पेठ गृहनिर्माण संस्था फेडरेशन',
      keywords: ['सोसायटी', 'पाणी समस्या', 'ऑडिट', 'ड्रेनेज चेंबर'],
      joinedDate: DateTime(2023, 7, 10),
      canAssignWork: true,
    ),
  ];

  // Seed tasks mapped by staff ID
  final Map<String, List<TeamTaskModel>> _memberTasks = {
    'stf-001': [
      TeamTaskModel(
        id: 'tsk-001',
        staffId: 'stf-001',
        title: 'पुणे मनपा प्रभाग समिती बैठकीचा अजेंडा व ठराव मसुदा तयार करणे',
        description: 'आगामी शुक्रवारी होणाऱ्या प्रभाग समिती सभेत मांडायच्या विकासकामांचे ठराव तयार करणे.',
        priority: 'High',
        status: 'In Progress',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        location: 'प्रभाग १२ मुख्य कार्यालय, शनिवार पेठ',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TeamTaskModel(
        id: 'tsk-002',
        staffId: 'stf-001',
        title: 'मासिक कार्यालयीन खर्चाचा ताळेबंद व अहवाल सादर करणे',
        description: 'कार्यालयीन व्यवस्थापन खर्चाची तपासणी व अंतिम मंजुरी.',
        priority: 'Medium',
        status: 'Completed',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ],
    'stf-002': [
      TeamTaskModel(
        id: 'tsk-003',
        staffId: 'stf-002',
        title: 'शनिवार पेठ गल्ली क्र. ४ मधील ड्रेनेज चेंबर दुरुस्ती काम प्रत्यक्ष पाहणी',
        description: 'नागरिकांच्या तक्रारीनुसार तुंबलेल्या चेंबरची स्वच्छता व नवीन झाकण बसविणे.',
        priority: 'High',
        status: 'Pending',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        location: 'शनिवार पेठ, गल्ली क्र. ४',
        createdAt: DateTime.now(),
      ),
      TeamTaskModel(
        id: 'tsk-004',
        staffId: 'stf-002',
        title: 'कसबा पेठ मुख्य रस्त्यावरील खड्डे बुजविण्याचे काम पूर्ण करणे',
        description: 'डांबरीकरण पथकाकडून रस्ता दुरुस्ती करवून घेणे.',
        priority: 'Medium',
        status: 'Completed',
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
        location: 'कसबा पेठ, गणपती चौक',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ],
    'stf-003': [
      TeamTaskModel(
        id: 'tsk-005',
        staffId: 'stf-003',
        title: 'संजय गांधी निराधार योजना लाभार्थी अर्जांची पडताळणी',
        description: 'नवीन दाखल झालेल्या १५ अर्जांची तहसील कार्यालयासाठी कागदपत्रे तपासणे.',
        priority: 'Medium',
        status: 'In Progress',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        location: 'कार्यालय योजना कक्ष',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
    'stf-006': [
      TeamTaskModel(
        id: 'tsk-006',
        staffId: 'stf-006',
        title: 'प्रभाग १२ भव्य आंतर-गल्ली क्रिकेट स्पर्धा नियोजन बैठक',
        description: 'सर्व संघांचे कर्णधार व स्थानिक मंडळांच्या पदाधिकाऱ्यांची बैठक घेणे.',
        priority: 'High',
        status: 'Pending',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        location: 'सदाशिव सदन हॉल, शनिवार पेठ',
        createdAt: DateTime.now(),
      ),
    ],
    'stf-010': [
      TeamTaskModel(
        id: 'tsk-007',
        staffId: 'stf-010',
        title: 'शनिवार वाडा परिसरातील दैनंदिन घंटागाडी वेळ नियत करणे',
        description: 'सकाळी ७:३० ते ८:३० या वेळेत घंटागाडी नियमित येण्याबाबत मुकादमाशी चर्चा करणे.',
        priority: 'Medium',
        status: 'In Progress',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        location: 'शनिवार वाडा परिसर',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ],
  };

  /// Get team members with filters
  Future<List<TeamMemberModel>> getTeamMembers({
    String? category, // 'Office', 'Party', 'Cooperative', or 'All'
    String? query,
    String? wing,
    String? area,
  }) async {
    try {
      var dbQuery = _client.from('staff').select('*');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        dbQuery = dbQuery.eq('tenant_id', _tenantId!);
      }
      final response = await dbQuery.order('created_at', ascending: false);
      if ((response as List).isNotEmpty) {
        final dbList = response.map((json) => TeamMemberModel.fromJson(json)).toList();
        return _applyFilters(dbList, category: category, query: query, wing: wing, area: area);
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 100));
    return _applyFilters(_seedMembers, category: category, query: query, wing: wing, area: area);
  }

  List<TeamMemberModel> _applyFilters(
    List<TeamMemberModel> list, {
    String? category,
    String? query,
    String? wing,
    String? area,
  }) {
    var result = List<TeamMemberModel>.from(list);

    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      result = result.where((m) => m.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((m) {
        final inKeywords = m.keywords.any((k) => k.toLowerCase().contains(q));
        return m.name.toLowerCase().contains(q) ||
            (m.nameMarathi?.toLowerCase().contains(q) ?? false) ||
            m.role.toLowerCase().contains(q) ||
            m.mobile.contains(q) ||
            (m.area?.toLowerCase().contains(q) ?? false) ||
            (m.partyWing?.toLowerCase().contains(q) ?? false) ||
            (m.societyName?.toLowerCase().contains(q) ?? false) ||
            inKeywords;
      }).toList();
    }

    if (wing != null && wing.isNotEmpty && wing != 'All') {
      result = result.where((m) => m.partyWing == wing).toList();
    }

    if (area != null && area.isNotEmpty && area != 'All') {
      result = result.where((m) => (m.area?.toLowerCase().contains(area.toLowerCase()) ?? false)).toList();
    }

    return result;
  }

  /// Get team member by ID
  Future<TeamMemberModel?> getTeamMemberById(String id) async {
    try {
      final response = await _client.from('staff').select('*').eq('id', id).maybeSingle();
      if (response != null) {
        return TeamMemberModel.fromJson(response);
      }
    } catch (_) {}

    try {
      return _seedMembers.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add new team member
  Future<TeamMemberModel> addTeamMember(TeamMemberModel member) async {
    try {
      final payload = member.toJson();
      if (_tenantId != null && _tenantId!.isNotEmpty) payload['tenant_id'] = _tenantId;
      final response = await _client.from('staff').insert(payload).select().single();
      final created = TeamMemberModel.fromJson(response);
      _seedMembers.insert(0, created);
      return created;
    } catch (_) {
      _seedMembers.insert(0, member);
      return member;
    }
  }

  /// Update team member
  Future<TeamMemberModel> updateTeamMember(TeamMemberModel member) async {
    try {
      final payload = member.toJson();
      final response = await _client.from('staff').update(payload).eq('id', member.id).select().single();
      final updated = TeamMemberModel.fromJson(response);
      final idx = _seedMembers.indexWhere((m) => m.id == member.id);
      if (idx != -1) _seedMembers[idx] = updated;
      return updated;
    } catch (_) {
      final idx = _seedMembers.indexWhere((m) => m.id == member.id);
      if (idx != -1) _seedMembers[idx] = member;
      return member;
    }
  }

  /// Delete team member
  Future<void> deleteTeamMember(String id) async {
    try {
      await _client.from('staff').delete().eq('id', id);
    } catch (_) {}
    _seedMembers.removeWhere((m) => m.id == id);
    _memberTasks.remove(id);
  }

  /// Get tasks assigned to a member
  Future<List<TeamTaskModel>> getMemberTasks(String staffId) async {
    try {
      final response = await _client.from('tasks').select('*').eq('assigned_to', staffId).order('created_at', ascending: false);
      if ((response as List).isNotEmpty) {
        return response.map((json) => TeamTaskModel.fromJson(json)).toList();
      }
    } catch (_) {}

    return _memberTasks[staffId] ?? [];
  }

  /// Assign task to a member
  Future<void> assignTask(String staffId, TeamTaskModel task) async {
    try {
      final payload = task.toJson();
      if (_tenantId != null && _tenantId!.isNotEmpty) payload['tenant_id'] = _tenantId;
      await _client.from('tasks').insert(payload);
    } catch (_) {}

    final list = _memberTasks[staffId] ?? [];
    list.insert(0, task);
    _memberTasks[staffId] = list;
  }

  /// Update task status
  Future<void> updateTaskStatus(String staffId, String taskId, String status) async {
    try {
      await _client.from('tasks').update({'status': status}).eq('id', taskId);
    } catch (_) {}

    final list = _memberTasks[staffId] ?? [];
    final idx = list.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(status: status);
      _memberTasks[staffId] = list;
    }
  }

  /// Get statistics summary
  Future<Map<String, int>> getTeamStats() async {
    int office = 0;
    int party = 0;
    int coop = 0;

    for (final m in _seedMembers) {
      if (m.category == 'Office') {
        office++;
      } else if (m.category == 'Party') {
        party++;
      } else if (m.category == 'Cooperative') {
        coop++;
      }
    }

    int totalTasks = 0;
    int completedTasks = 0;
    for (final tasks in _memberTasks.values) {
      totalTasks += tasks.length;
      completedTasks += tasks.where((t) => t.status == 'Completed' || t.status == 'Resolved').length;
    }

    return {
      'total': _seedMembers.length,
      'office': office,
      'party': party,
      'cooperative': coop,
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
    };
  }

  /// Available party wings
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
