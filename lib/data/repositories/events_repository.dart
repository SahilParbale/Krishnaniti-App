import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/event_model.dart';

class ConstituentInviteContact {
  final String id;
  final String name;
  final String nameMr;
  final String mobile;
  final String area;
  final String address;
  final int age;
  final String gender;

  const ConstituentInviteContact({
    required this.id,
    required this.name,
    required this.nameMr,
    required this.mobile,
    required this.area,
    required this.address,
    required this.age,
    required this.gender,
  });
}

class EventsRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _tenantId => SupabaseService.instance.activeTenantId;

  Future<List<EventModel>> getEvents() async {
    try {
      var query = _client.from('events').select('*, event_rsvps(*)');
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.order('event_date', ascending: false);
      final list = (response as List<dynamic>)
          .map((item) => EventModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      return list;
    } catch (_) {
      // Fallback if event_rsvps join fails
      try {
        var query2 = _client.from('events').select('*');
        if (_tenantId != null && _tenantId!.isNotEmpty) {
          query2 = query2.eq('tenant_id', _tenantId!);
        }
        final response2 = await query2.order('event_date', ascending: false);
        return (response2 as List<dynamic>)
            .map((item) => EventModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<EventModel?> getEventById(String id) async {
    try {
      var query = _client.from('events').select('*, event_rsvps(*)').eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.maybeSingle();
      if (response != null) {
        return EventModel.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<EventModel> createEvent(EventModel event) async {
    try {
      final payload = event.toJson(tenantId: _tenantId);
      final response = await _client.from('events').insert(payload).select('*, event_rsvps(*)').single();
      return EventModel.fromJson(Map<String, dynamic>.from(response));
    } catch (_) {
      return event;
    }
  }

  Future<EventModel> updateEvent(EventModel event) async {
    try {
      final payload = event.toJson(tenantId: _tenantId);
      var query = _client.from('events').update(payload).eq('id', event.id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      final response = await query.select('*, event_rsvps(*)').single();
      return EventModel.fromJson(Map<String, dynamic>.from(response));
    } catch (_) {
      return event;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      var query = _client.from('events').delete().eq('id', id);
      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }
      await query;
    } catch (_) {}
  }

  Future<void> addRsvp(String eventId, EventRsvpModel rsvp) async {
    try {
      final payload = rsvp.toJson(tenantId: _tenantId, eventId: eventId);
      await _client.from('event_rsvps').insert(payload);
    } catch (_) {}
  }

  Future<List<ConstituentInviteContact>> getVotersForInvites({
    String? nameSearch,
    String? addressSearch,
    int? ageMin,
    int? ageMax,
  }) async {
    try {
      var query = _client
          .from('voters')
          .select('id, name_english, name_marathi, mobile, address_english, address_marathi, age, gender')
          .not('mobile', 'is', null)
          .neq('mobile', '');

      if (_tenantId != null && _tenantId!.isNotEmpty) {
        query = query.eq('tenant_id', _tenantId!);
      }

      if (nameSearch != null && nameSearch.trim().length >= 2) {
        final term = nameSearch.trim();
        query = query.or('name_english.ilike.%$term%,name_marathi.ilike.%$term%');
      }

      if (addressSearch != null && addressSearch.trim().length >= 2) {
        final term = addressSearch.trim();
        query = query.or('address_english.ilike.%$term%,address_marathi.ilike.%$term%');
      }

      if (ageMin != null) {
        query = query.gte('age', ageMin);
      }

      if (ageMax != null) {
        query = query.lte('age', ageMax);
      }

      final response = await query.limit(80);
      return (response as List<dynamic>).map((r) {
        final map = Map<String, dynamic>.from(r as Map);
        return ConstituentInviteContact(
          id: map['id']?.toString() ?? '',
          name: map['name_english']?.toString() ?? map['name_marathi']?.toString() ?? '',
          nameMr: map['name_marathi']?.toString() ?? map['name_english']?.toString() ?? '',
          mobile: map['mobile']?.toString() ?? '',
          area: map['address_marathi']?.toString() ?? map['address_english']?.toString() ?? '',
          address: map['address_english']?.toString() ?? map['address_marathi']?.toString() ?? '',
          age: map['age'] is int ? map['age'] : int.tryParse(map['age']?.toString() ?? '0') ?? 0,
          gender: map['gender']?.toString() ?? 'M',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

final eventsRepoProvider = Provider<EventsRepository>((ref) {
  return EventsRepository();
});
