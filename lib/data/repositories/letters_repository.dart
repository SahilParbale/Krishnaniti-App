import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/letter_model.dart';

final lettersRepoProvider = Provider<LettersRepository>((ref) => LettersRepository());

class LettersRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<LetterModel>> getLetters({required bool isIncoming, int limit = 50}) async {
    try {
      final tableName = isIncoming ? 'incoming_letters' : 'letter_requests';
      var query = _client.from(tableName).select('*');

      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }

      final response = await query.order('created_at', ascending: false).limit(limit);

      return (response as List<dynamic>)
          .map((item) => LetterModel.fromJson(item as Map<String, dynamic>, isIncoming: isIncoming))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<LetterModel?> getLetterById(String id, {required bool isIncoming}) async {
    try {
      final tableName = isIncoming ? 'incoming_letters' : 'letter_requests';
      var query = _client.from(tableName).select('*').eq('id', id);

      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }

      final response = await query.maybeSingle();
      if (response != null) {
        return LetterModel.fromJson(response, isIncoming: isIncoming);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateLetterStatus(String id, String newStatus) async {
    var query = _client.from('letter_requests').update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    if (_tenantId != null) {
      query = query.eq('tenant_id', _tenantId!);
    }

    await query;
  }

  Future<void> deleteLetter(String id, {required bool isIncoming}) async {
    final tableName = isIncoming ? 'incoming_letters' : 'letter_requests';
    var query = _client.from(tableName).delete().eq('id', id);

    if (_tenantId != null) {
      query = query.eq('tenant_id', _tenantId!);
    }

    await query;
  }

  Future<LetterModel> createLetterRequest({
    required String type,
    required String name,
    required String subject,
    required String address,
    required String purpose,
    String? area,
    String? mobile,
    String? gender,
    String? voterId,
    String? addedByStaffId,
    List<String> attachments = const [],
  }) async {
    final payload = {
      'type': type,
      'user_id': mobile?.isNotEmpty == true ? mobile! : name,
      'area': area,
      'details': {
        'name': name,
        'subject': subject,
        'text': address,
        'address': address,
        'purpose': purpose,
        'mobile': mobile,
        if (gender != null) 'gender': gender,
        if (voterId != null) 'voter_id': voterId,
        if (addedByStaffId != null) 'added_by_staff_id': addedByStaffId,
        if (attachments.isNotEmpty) 'attachments': attachments,
      },
      if (addedByStaffId != null) 'added_by_staff_id': addedByStaffId,
      'status': 'Pending',
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _client.from('letter_requests').insert(payload).select().single();
      return LetterModel.fromJson(res, isIncoming: false);
    } catch (_) {
      // Fallback offline model
      return LetterModel(
        id: 'REQ-LTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        title: subject.isNotEmpty ? subject : '$type - $name',
        letterType: type,
        recipient: name,
        sender: 'Nagarsevak Office',
        userId: name,
        area: area,
        details: payload['details'] as Map<String, dynamic>,
        status: 'Pending',
        isIncoming: false,
        createdAt: DateTime.now(),
        tenantId: _tenantId,
      );
    }
  }

  Future<LetterModel> uploadIncomingLetter({
    required String title,
    required String description,
    String? area,
    required DateTime receivedDate,
    required String fileUrl,
    required String fileType,
    String? bearerName,
    String? bearerMobile,
    String? addedByStaffId,
    String? voterId,
  }) async {
    String finalDesc = description;
    if (bearerName != null && bearerName.isNotEmpty) {
      finalDesc += '\n\n--- Bearer Details ---\nName: $bearerName';
      if (bearerMobile != null && bearerMobile.isNotEmpty) {
        finalDesc += '\nMobile: $bearerMobile';
      }
    }

    final payload = {
      'title': title,
      'description': finalDesc,
      'area': area,
      'scanned_file_url': fileUrl,
      'file_type': fileType,
      'received_date': receivedDate.toIso8601String(),
      if (addedByStaffId != null) 'added_by_staff_id': addedByStaffId,
      if (voterId != null) 'voter_id': voterId,
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _client.from('incoming_letters').insert(payload).select().single();
      return LetterModel.fromJson(res, isIncoming: true);
    } catch (_) {
      // Fallback offline model
      return LetterModel(
        id: 'INC-LTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        title: title,
        letterType: 'Incoming Letter',
        sender: bearerName ?? 'Citizen / Dept',
        recipient: 'Nagarsevak Office',
        area: area,
        details: {
          'title': title,
          'bearer_name': bearerName,
          'bearer_mobile': bearerMobile,
          'file_url': fileUrl,
        },
        status: 'Received',
        isIncoming: true,
        letterUrl: fileUrl,
        fileType: fileType,
        description: finalDesc,
        receivedDate: receivedDate,
        createdAt: DateTime.now(),
        tenantId: _tenantId,
      );
    }
  }

  Future<String?> uploadLetterFile(String localPath, String fileName) async {
    try {
      final file = File(localPath);
      final bytes = await file.readAsBytes();
      final path = '${_tenantId ?? 'default'}/letters/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _client.storage.from('documents').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _client.storage.from('documents').getPublicUrl(path);
      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  Future<int> getLettersCount() async {
    try {
      var query = _client.from('letter_requests').select('id');
      if (_tenantId != null) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query;
      return (response as List<dynamic>).length;
    } catch (_) {
      return 0;
    }
  }
}
