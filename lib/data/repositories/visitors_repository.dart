import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/visitor_model.dart';

class VisitorsRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  // Realistic mock visitors matching web VisitorLog.tsx
  final List<VisitorModel> _defaultVisitors = [
    VisitorModel(
      id: 'VIS-901',
      name: 'Ramesh Patil',
      mobile: '9876543210',
      purpose: 'Complaint',
      area: 'Lane 4, Sector 2',
      reference: 'Sunil Shinde (JE)',
      remarks: 'Low water pressure issue in society for last 3 days. Demanded pipeline flushing.',
      visitDate: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    VisitorModel(
      id: 'VIS-902',
      name: 'Sunita Anil Kadam',
      mobile: '9822011223',
      purpose: 'Help',
      area: 'Sector B, Prabhag 12',
      reference: 'Self',
      remarks: 'Requested financial assistance documentation for hospital surgery under CM Relief fund.',
      amount: '15000',
      visitDate: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
    ),
    VisitorModel(
      id: 'VIS-903',
      name: 'Vijay Deshmukh',
      mobile: '9822044556',
      purpose: 'Greeting',
      area: 'Shivaji Chowk Hall',
      reference: 'Ganesh Mandal Committee',
      remarks: 'Invited Nagarsevak for annual Ganesh Utsav aarti ceremony and felicitation program.',
      eventDate: '2026-11-10',
      eventTime: '18:30',
      visitDate: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    VisitorModel(
      id: 'VIS-904',
      name: 'Mahesh Jadhav',
      mobile: '9822088990',
      purpose: 'Meeting',
      area: 'Sector 3 Market Road',
      reference: 'Vyapari Mandal President',
      remarks: 'Discussed road widening and hawker demarcation lines on the main sector road.',
      visitDate: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    VisitorModel(
      id: 'VIS-905',
      name: 'Rekha Suresh More',
      mobile: '9890123456',
      purpose: 'Complaint',
      area: 'Sector 5, Colony 2',
      reference: 'Ward Karyakarta',
      remarks: 'Frequent garbage vehicle skipping Lane 2 collection spot. Requested daily monitoring.',
      visitDate: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    VisitorModel(
      id: 'VIS-906',
      name: 'Ganesh Mandale',
      mobile: '9823456789',
      purpose: 'Donation',
      area: 'Prabhag 12 Sports Club',
      reference: 'Youth Mandal',
      remarks: 'Contribution request for ward inter-school cricket tournament trophies and kit bags.',
      amount: '5000',
      visitDate: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
    ),
  ];

  Future<List<VisitorModel>> getVisitors({
    String? search,
    String? purpose,
    String? area,
    DateTime? date,
  }) async {
    try {
      var query = _client.from('visitors').select('*');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      final response = await query.order('visit_date', ascending: false).limit(200);

      final list = (response as List<dynamic>)
          .map((item) => VisitorModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        return List.from(_defaultVisitors);
      }
      return list;
    } catch (_) {
      return List.from(_defaultVisitors);
    }
  }

  Future<VisitorModel?> addVisitor(VisitorModel visitor) async {
    try {
      final payload = visitor.toJson(tenantId: _tenantId);
      final response = await _client.from('visitors').insert(payload).select().single();
      return VisitorModel.fromJson(response);
    } catch (_) {
      return visitor.copyWith(id: 'VIS-${DateTime.now().millisecondsSinceEpoch % 10000}');
    }
  }

  Future<void> updateVisitor(String id, Map<String, dynamic> updates) async {
    try {
      var query = _client.from('visitors').update(updates).eq('id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      await query;
    } catch (_) {}
  }

  Future<void> deleteVisitor(String id) async {
    try {
      var query = _client.from('visitors').delete().eq('id', id);

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      await query;
    } catch (_) {}
  }
}

final visitorsRepoProvider = Provider<VisitorsRepository>((ref) {
  return VisitorsRepository();
});

