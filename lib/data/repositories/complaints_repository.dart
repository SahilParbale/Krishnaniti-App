import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/complaint_model.dart';
import '../models/staff_model.dart';

final complaintsRepoProvider = Provider((ref) => ComplaintsRepository());

class ComplaintsRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  String _getTableForId(String id) {
    if (id.startsWith('pr-')) return 'personal_requests';
    if (id.startsWith('ap-')) return 'area_problems';
    return 'complaints';
  }

  String _getActualId(String id) {
    if (id.startsWith('pr-')) return id.substring(3);
    if (id.startsWith('ap-')) return id.substring(3);
    return id;
  }

  Future<List<ComplaintModel>> getComplaints({
    String? statusFilter,
    String? searchQuery,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('complaints').select('''
        *,
        voter:voters (
          name_marathi,
          name_english,
          mobile
        ),
        staff:staff (
          name,
          mobile
        )
      ''');

      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }

      if (statusFilter != null && statusFilter != 'All') {
        query = query.eq('status', statusFilter);
      }

      final response = await query.order('created_at', ascending: false).limit(limit);

      return (response as List<dynamic>)
          .map((item) => ComplaintModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list on network or query failure
      return [];
    }
  }

  Future<ComplaintModel?> getComplaintById(String id) async {
    try {
      final table = _getTableForId(id);
      final actualId = _getActualId(id);

      if (table == 'complaints') {
        var query = _client.from('complaints').select('''
          *,
          voter:voters (
            name_marathi,
            name_english,
            mobile
          ),
          staff:staff (
            name,
            mobile
          )
        ''').eq('id', actualId);

        if (_tenantId != null) {
          query = query.eq('tenant_id', _tenantId!);
        }

        final res = await query.maybeSingle();
        if (res != null) {
          return ComplaintModel.fromJson(res);
        }
      } else {
        var query = _client.from(table).select('*').eq('id', actualId);
        if (_tenantId != null) {
          query = query.eq('tenant_id', _tenantId!);
        }
        final res = await query.maybeSingle();
        if (res != null) {
          final data = Map<String, dynamic>.from(res);
          // Preserve prefix id
          data['id'] = id;
          return ComplaintModel.fromJson(data);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<StaffModel>> getStaffList() async {
    try {
      var query = _client.from('staff').select('*');
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query;
      return (response as List<dynamic>)
          .map((item) => StaffModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> assignStaff(String complaintId, String staffId) async {
    final table = _getTableForId(complaintId);
    final actualId = _getActualId(complaintId);

    var query = _client.from(table).update({
      'assigned_to': staffId,
      'status': 'Assigned',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', actualId);

    if (_tenantId != null) {
      query = query.eq('tenant_id', _tenantId!);
    }

    await query;
  }

  Future<void> addProgressLog({
    required String complaintId,
    required String note,
    required String status,
    required String updatedBy,
    List<ComplaintAttachment> images = const [],
  }) async {
    final table = _getTableForId(complaintId);
    final actualId = _getActualId(complaintId);

    // Fetch existing description_meta
    var query = _client.from(table).select('description_meta').eq('id', actualId);
    if (_tenantId != null) query = query.eq('tenant_id', _tenantId!);
    final current = await query.maybeSingle();

    Map<String, dynamic> meta = {};
    if (current != null && current['description_meta'] != null) {
      if (current['description_meta'] is Map) {
        meta = Map<String, dynamic>.from(current['description_meta'] as Map);
      } else if (current['description_meta'] is String && (current['description_meta'] as String).isNotEmpty) {
        try {
          meta = Map<String, dynamic>.from(jsonDecode(current['description_meta'] as String) as Map);
        } catch (_) {}
      }
    }

    final timestamp = DateTime.now().toIso8601String();
    final newRecord = {
      'note': note,
      'images': images.map((i) => i.toJson()).toList(),
      'status': status,
      'timestamp': timestamp,
      'updated_by': updatedBy,
    };

    final existingUpdates = meta['progress_updates'] is List
        ? List<dynamic>.from(meta['progress_updates'] as List)
        : <dynamic>[];
    existingUpdates.add(newRecord);
    meta['progress_updates'] = existingUpdates;

    if (status == 'InProgress') {
      meta['work_in_progress'] = {
        'note': note,
        'images': images.map((i) => i.toJson()).toList(),
        'updated_at': timestamp,
        'updated_by': updatedBy,
      };
    } else if (status == 'Resolved') {
      meta['resolution_details'] = {
        'note': note,
        'images': images.map((i) => i.toJson()).toList(),
        'resolved_at': timestamp,
        'resolved_by': updatedBy,
      };
    }

    var updateQuery = _client.from(table).update({
      'status': status,
      'description_meta': meta,
      'updated_at': timestamp,
    }).eq('id', actualId);

    if (_tenantId != null) updateQuery = updateQuery.eq('tenant_id', _tenantId!);
    await updateQuery;
  }

  Future<void> editProgressLog({
    required String complaintId,
    required int logIndex,
    required String note,
    required String status,
    required String updatedBy,
    required List<ComplaintAttachment> images,
  }) async {
    final table = _getTableForId(complaintId);
    final actualId = _getActualId(complaintId);

    var query = _client.from(table).select('description_meta').eq('id', actualId);
    if (_tenantId != null) query = query.eq('tenant_id', _tenantId!);
    final current = await query.maybeSingle();

    Map<String, dynamic> meta = {};
    if (current != null && current['description_meta'] != null) {
      if (current['description_meta'] is Map) {
        meta = Map<String, dynamic>.from(current['description_meta'] as Map);
      } else if (current['description_meta'] is String && (current['description_meta'] as String).isNotEmpty) {
        try {
          meta = Map<String, dynamic>.from(jsonDecode(current['description_meta'] as String) as Map);
        } catch (_) {}
      }
    }

    final existingUpdates = meta['progress_updates'] is List
        ? List<dynamic>.from(meta['progress_updates'] as List)
        : <dynamic>[];

    final original = (logIndex >= 0 && logIndex < existingUpdates.length)
        ? Map<String, dynamic>.from(existingUpdates[logIndex] as Map)
        : <String, dynamic>{};

    final updatedRecord = {
      ...original,
      'note': note,
      'status': status,
      'images': images.map((i) => i.toJson()).toList(),
      'updated_by': updatedBy,
    };

    if (logIndex >= 0 && logIndex < existingUpdates.length) {
      existingUpdates[logIndex] = updatedRecord;
    } else {
      existingUpdates.add(updatedRecord);
    }
    meta['progress_updates'] = existingUpdates;

    // If updating latest log, sync work_in_progress or resolution_details
    if (logIndex == existingUpdates.length - 1) {
      if (status == 'InProgress') {
        meta['work_in_progress'] = {
          'note': note,
          'images': images.map((i) => i.toJson()).toList(),
          'updated_at': original['timestamp'] ?? DateTime.now().toIso8601String(),
          'updated_by': updatedBy,
        };
      } else if (status == 'Resolved') {
        meta['resolution_details'] = {
          'note': note,
          'images': images.map((i) => i.toJson()).toList(),
          'resolved_at': original['timestamp'] ?? DateTime.now().toIso8601String(),
          'resolved_by': updatedBy,
        };
      }
    }

    var updateQuery = _client.from(table).update({
      'description_meta': meta,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', actualId);

    if (_tenantId != null) updateQuery = updateQuery.eq('tenant_id', _tenantId!);
    await updateQuery;
  }

  Future<void> deleteProgressLog({
    required String complaintId,
    required int logIndex,
  }) async {
    final table = _getTableForId(complaintId);
    final actualId = _getActualId(complaintId);

    var query = _client.from(table).select('description_meta').eq('id', actualId);
    if (_tenantId != null) query = query.eq('tenant_id', _tenantId!);
    final current = await query.maybeSingle();

    Map<String, dynamic> meta = {};
    if (current != null && current['description_meta'] != null) {
      if (current['description_meta'] is Map) {
        meta = Map<String, dynamic>.from(current['description_meta'] as Map);
      } else if (current['description_meta'] is String && (current['description_meta'] as String).isNotEmpty) {
        try {
          meta = Map<String, dynamic>.from(jsonDecode(current['description_meta'] as String) as Map);
        } catch (_) {}
      }
    }

    final existingUpdates = meta['progress_updates'] is List
        ? List<dynamic>.from(meta['progress_updates'] as List)
        : <dynamic>[];

    if (logIndex >= 0 && logIndex < existingUpdates.length) {
      existingUpdates.removeAt(logIndex);
    }
    meta['progress_updates'] = existingUpdates;

    var updateQuery = _client.from(table).update({
      'description_meta': meta,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', actualId);

    if (_tenantId != null) updateQuery = updateQuery.eq('tenant_id', _tenantId!);
    await updateQuery;
  }

  Future<void> updateComplaint({
    required String complaintId,
    required String problem,
    required String category,
  }) async {
    final table = _getTableForId(complaintId);
    final actualId = _getActualId(complaintId);

    Map<String, dynamic> updateData = {};
    if (table == 'personal_requests' || table == 'area_problems') {
      updateData = {
        'description': problem,
        'updated_at': DateTime.now().toIso8601String(),
      };
    } else {
      updateData = {
        'problem': problem,
        'description': problem,
        'category': category,
        'updated_at': DateTime.now().toIso8601String(),
      };
    }

    var updateQuery = _client.from(table).update(updateData).eq('id', actualId);
    if (_tenantId != null) updateQuery = updateQuery.eq('tenant_id', _tenantId!);
    await updateQuery;
  }

  Future<void> deleteComplaint(String complaintId) async {
    final table = _getTableForId(complaintId);
    final actualId = _getActualId(complaintId);

    var deleteQuery = _client.from(table).delete().eq('id', actualId);
    if (_tenantId != null) deleteQuery = deleteQuery.eq('tenant_id', _tenantId!);
    await deleteQuery;
  }

  Future<String?> uploadMedia(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final path = '${_tenantId ?? 'default'}/complaints/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _client.storage.from('documents').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Return public URL or path
      final publicUrl = _client.storage.from('documents').getPublicUrl(path);
      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, int>> getComplaintStats() async {
    try {
      var query = _client.from('complaints').select('status');
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }

      final response = await query;
      final list = response as List<dynamic>;

      int pending = 0;
      int inProgress = 0;
      int resolved = 0;

      for (final item in list) {
        final status = item['status']?.toString();
        if (status == 'Pending') {
          pending++;
        } else if (status == 'InProgress' || status == 'Assigned') {
          inProgress++;
        } else if (status == 'Resolved' || status == 'Closed') {
          resolved++;
        }
      }

      return {
        'total': list.length,
        'pending': pending,
        'inProgress': inProgress,
        'resolved': resolved,
      };
    } catch (_) {
      return {'total': 0, 'pending': 0, 'inProgress': 0, 'resolved': 0};
    }
  }

  Future<ComplaintModel> createComplaint({
    required String title,
    required String description,
    required String category,
    String? ward,
    String? area,
    String? society,
    String? citizenName,
    String? citizenMobile,
    String? voterId,
    String? addedByStaffId,
    String? priority,
    String? peopleAffected,
    List<String> photos = const [],
    List<ComplaintAttachment> attachments = const [],
  }) async {
    final effectiveArea = (society != null && society.isNotEmpty)
        ? (area != null && area.isNotEmpty ? '$society, $area' : society)
        : area;

    final payload = {
      'title': title,
      'problem': title,
      'description': description,
      'category': category,
      'status': 'Pending',
      'priority': priority ?? 'Medium',
      'ward': ward,
      'area': effectiveArea,
      'location': ward != null ? (ward.startsWith('Sector') ? ward : 'Ward $ward') : null,
      'source': 'Mobile App',
      if (citizenName != null) 'citizen_name': citizenName,
      if (citizenMobile != null) 'citizen_mobile': citizenMobile,
      if (voterId != null) 'voter_id': voterId,
      if (addedByStaffId != null && addedByStaffId.isNotEmpty) 'added_by_staff_id': addedByStaffId,
      'photos': photos,
      if (attachments.isNotEmpty) 'attachments': attachments.map((a) => a.toJson()).toList(),
      'description_meta': {
        if (citizenName != null) 'submitter_name': citizenName,
        if (citizenMobile != null) 'submitter_mobile': citizenMobile,
        if (peopleAffected != null) 'people_affected': peopleAffected,
        'original_title': title,
        'original_description': description,
        if (society != null) 'society': society,
      },
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _client.from('complaints').insert(payload).select().single();
      return ComplaintModel.fromJson(res);
    } catch (_) {
      // In offline / demo mode, return an in-memory ComplaintModel
      return ComplaintModel(
        id: 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        title: title,
        description: description,
        category: category,
        status: 'Pending',
        ward: ward,
        area: effectiveArea,
        location: ward != null ? 'Ward $ward' : effectiveArea,
        citizenName: citizenName,
        citizenMobile: citizenMobile,
        voterId: voterId,
        addedByStaffId: addedByStaffId,
        photos: photos,
        attachments: attachments,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<ComplaintModel> createPersonalRequest({
    required String reporterName,
    required String reporterMobile,
    required String requestType,
    required String description,
    String? voterId,
    String? addedByStaffId,
    List<String> photos = const [],
    List<ComplaintAttachment> attachments = const [],
  }) async {
    final payload = {
      'tenant_id': _tenantId,
      'user_id': 'Manual',
      'reporter_name': reporterName,
      'reporter_mobile': reporterMobile.trim(),
      'request_type': requestType,
      'category': requestType,
      'description': description,
      'problem': description,
      'status': 'Pending',
      'priority': 'Medium',
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'photos': photos,
      if (voterId != null) 'voter_id': voterId,
      if (addedByStaffId != null && addedByStaffId.isNotEmpty) 'added_by_staff_id': addedByStaffId,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _client.from('personal_requests').insert(payload).select().single();
      final map = Map<String, dynamic>.from(res);
      map['id'] = 'pr-${map['id']}';
      return ComplaintModel.fromJson(map);
    } catch (_) {
      // Fallback insert to complaints or generate offline ComplaintModel
      try {
        final fallbackPayload = {
          'title': '$requestType - $reporterName',
          'problem': description,
          'description': description,
          'category': requestType,
          'status': 'Pending',
          'citizen_name': reporterName,
          'citizen_mobile': reporterMobile,
          if (voterId != null) 'voter_id': voterId,
          if (addedByStaffId != null && addedByStaffId.isNotEmpty) 'added_by_staff_id': addedByStaffId,
          'tenant_id': _tenantId,
          'created_at': DateTime.now().toIso8601String(),
        };
        final res = await _client.from('complaints').insert(fallbackPayload).select().single();
        return ComplaintModel.fromJson(res);
      } catch (_) {
        return ComplaintModel(
          id: 'PR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          title: '$requestType Request',
          description: description,
          category: requestType,
          status: 'Pending',
          citizenName: reporterName,
          citizenMobile: reporterMobile,
          voterId: voterId,
          addedByStaffId: addedByStaffId,
          photos: photos,
          attachments: attachments,
          createdAt: DateTime.now(),
        );
      }
    }
  }

  Future<void> updateStatus(String complaintId, String newStatus) async {
    final table = _getTableForId(complaintId);
    final actualId = _getActualId(complaintId);

    var updateQuery = _client.from(table).update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', actualId);

    if (_tenantId != null) updateQuery = updateQuery.eq('tenant_id', _tenantId!);
    await updateQuery;
  }

  Future<List<ComplaintModel>> getWardProblems() async {
    try {
      final List<ComplaintModel> allProblems = [];

      // 1. Fetch complaints where category is SelfIdentified or general civic issues
      try {
        var cQuery = _client.from('complaints').select('''
          *,
          voter:voters (
            name_marathi,
            name_english,
            mobile
          ),
          staff:staff (
            name,
            mobile
          )
        ''');
        if (_tenantId != null) {
          cQuery = cQuery.eq('tenant_id', _tenantId!);
        }
        final cRes = await cQuery.order('created_at', ascending: false).limit(80);
        final cList = (cRes as List<dynamic>)
            .map((item) => ComplaintModel.fromJson(item as Map<String, dynamic>))
            .toList();

        final selfIdentified = cList.where((c) => c.category.toLowerCase() == 'selfidentified').toList();
        if (selfIdentified.isNotEmpty) {
          allProblems.addAll(selfIdentified);
        } else {
          allProblems.addAll(cList);
        }
      } catch (_) {}

      // 2. Fetch area_problems
      try {
        var aQuery = _client.from('area_problems').select('*');
        if (_tenantId != null) {
          aQuery = aQuery.eq('tenant_id', _tenantId!);
        }
        final aRes = await aQuery.order('created_at', ascending: false);
        for (final item in (aRes as List<dynamic>)) {
          final map = Map<String, dynamic>.from(item as Map);
          map['id'] = 'ap-${map['id']}';
          map['category'] = 'SelfIdentified';
          allProblems.add(ComplaintModel.fromJson(map));
        }
      } catch (_) {}

      if (allProblems.isNotEmpty) {
        allProblems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return allProblems;
      }
    } catch (_) {}

    return _getFallbackWardProblems();
  }

  Future<ComplaintModel> createWardProblem({
    required String title,
    required String description,
    required String category,
    String? area,
    String? location,
    String? citizenName,
    String? citizenMobile,
    String? voterId,
    String? assignedTo,
    List<String> photos = const [],
  }) async {
    try {
      final payload = {
        'title': title,
        'problem': title,
        'description': description,
        'category': category.isEmpty ? 'SelfIdentified' : category,
        'status': 'Pending',
        'ward': 'Ward 12',
        'area': area,
        'location': location,
        if (citizenName != null) 'citizen_name': citizenName,
        if (citizenMobile != null) 'citizen_mobile': citizenMobile,
        if (voterId != null) 'voter_id': voterId,
        if (assignedTo != null) 'assigned_to': assignedTo,
        'photos': photos,
        'tenant_id': _tenantId,
        'created_at': DateTime.now().toIso8601String(),
      };
      final res = await _client.from('complaints').insert(payload).select().single();
      return ComplaintModel.fromJson(res);
    } catch (_) {
      return ComplaintModel(
        id: 'wp-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        category: category.isEmpty ? 'SelfIdentified' : category,
        status: 'Pending',
        ward: 'Ward 12',
        area: area,
        location: location,
        citizenName: citizenName,
        citizenMobile: citizenMobile,
        createdAt: DateTime.now(),
      );
    }
  }

  List<ComplaintModel> _getFallbackWardProblems() {
    return [
      ComplaintModel(
        id: 'wp-101',
        title: 'Water pressure severely low in Sector 3 residential lanes',
        description:
            'Main supply pipeline valve malfunctioning near Sambhaji Park booster pump. Water not reaching 2nd and 3rd floors during morning supply hours.',
        category: 'SelfIdentified',
        status: 'Pending',
        ward: 'Ward 12',
        area: 'Shivajinagar, Sector 3',
        location: 'Near Sambhaji Park Booster Station',
        citizenName: 'Suresh Baban Patil',
        citizenMobile: '9822014589',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ComplaintModel(
        id: 'wp-102',
        title: 'Overflowing storm drainage chamber causing foul smell and puddle',
        description:
            'Chamber choked due to plastic waste and silt. Drainage water overflowing onto main market road during evening peak rush.',
        category: 'SelfIdentified',
        status: 'InProgress',
        ward: 'Ward 12',
        area: 'Shivaji Chowk Market',
        location: 'Opposite Old Vegetable Mandi Gate',
        citizenName: 'Kishor Dnyaneshwar Shinde',
        citizenMobile: '9890123456',
        assignedStaffName: 'Mahesh Jadhav (Civil Engg)',
        assignedStaffMobile: '9823055112',
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      ComplaintModel(
        id: 'wp-103',
        title: 'Three consecutive high-mast streetlights dark on Lane 4',
        description:
            'Underground cable shorted during recent tree trimming. The entire internal crossroad is pitch dark, creating safety hazard for women and senior citizens.',
        category: 'SelfIdentified',
        status: 'Pending',
        ward: 'Ward 12',
        area: 'Lane 4, Prabhag 12',
        location: 'Near Ganpati Mandir Crossroads',
        citizenName: 'Sunita Anand Deshmukh',
        citizenMobile: '9764501234',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      ComplaintModel(
        id: 'wp-104',
        title: 'Chronic illegal garbage dumping spot on Canal Ring Road',
        description:
            'Uncontrolled waste dumping by commercial shops at night. Requires immediate JCB clearance, daily garbage bin placement, and CCTV warning board.',
        category: 'SelfIdentified',
        status: 'Assigned',
        ward: 'Ward 12',
        area: 'Canal Ring Road',
        location: 'Behind Municipal Water Tank No. 2',
        citizenName: 'Ganesh Ramchandra Kadam',
        citizenMobile: '9850123987',
        assignedStaffName: 'Sachin Thorat (Sanitation Inspector)',
        assignedStaffMobile: '9822188443',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 18)),
      ),
      ComplaintModel(
        id: 'wp-105',
        title: 'Damaged speed breaker with exposed reinforcement rebars',
        description:
            'Concrete broken by heavy construction transit trucks. Two wheelers skidding frequently during school dispersal hours.',
        category: 'SelfIdentified',
        status: 'Resolved',
        ward: 'Ward 12',
        area: 'Gaothan Main Road',
        location: 'In front of Municipal School No. 14',
        citizenName: 'Anil Eknath Gaikwad',
        citizenMobile: '9822890123',
        assignedStaffName: 'Mahesh Jadhav (Civil Engg)',
        assignedStaffMobile: '9823055112',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ComplaintModel(
        id: 'wp-106',
        title: 'Haphazard low-hanging internet cables tangled across electrical pole',
        description:
            'Multiple private telecom optical fiber cables hanging within 7 feet of road level. Fire hazard risk during summer.',
        category: 'SelfIdentified',
        status: 'InProgress',
        ward: 'Ward 12',
        area: 'Siddheshwar Nagar',
        location: 'Pole No. 42, Cross Lane 2',
        citizenName: 'Rahul Vinayak Joshi',
        citizenMobile: '9923456789',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      ComplaintModel(
        id: 'wp-107',
        title: 'Open unattended manhole without cover near playground',
        description:
            'Cement cover broken last week during drainage desilting. Currently covered only with loose tree branches. Extreme hazard for children.',
        category: 'SelfIdentified',
        status: 'Resolved',
        ward: 'Ward 12',
        area: 'Sambhaji Park Layout',
        location: 'Adjacent to Children Play Area',
        citizenName: 'Pravin Narayan More',
        citizenMobile: '9822334455',
        assignedStaffName: 'Sachin Thorat (Sanitation Inspector)',
        assignedStaffMobile: '9822188443',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ];
  }
}
