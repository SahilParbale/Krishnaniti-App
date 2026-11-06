import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/letter_model.dart';

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
        return LetterModel.fromJson(response as Map<String, dynamic>, isIncoming: isIncoming);
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
  }) async {
    final payload = {
      'type': type,
      'user_id': name,
      'area': area,
      'details': {
        'name': name,
        'subject': subject,
        'text': address,
        'address': address,
        'purpose': purpose,
        'mobile': mobile,
      },
      'status': 'Pending',
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _client.from('letter_requests').insert(payload).select().single();
    return LetterModel.fromJson(res, isIncoming: false);
  }

  Future<LetterModel> uploadIncomingLetter({
    required String title,
    required String description,
    String? area,
    required DateTime receivedDate,
    required String fileUrl,
    required String fileType,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'area': area,
      'scanned_file_url': fileUrl,
      'file_type': fileType,
      'received_date': receivedDate.toIso8601String(),
      'tenant_id': _tenantId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _client.from('incoming_letters').insert(payload).select().single();
    return LetterModel.fromJson(res, isIncoming: true);
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
