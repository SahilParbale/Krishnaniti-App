import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Supported Event Types
enum EventType {
  publicMeeting,
  inauguration,
  rally,
  healthCamp,
  doorToDoor,
  cultural,
  other,
}

extension EventTypeX on EventType {
  String get id {
    switch (this) {
      case EventType.publicMeeting:
        return 'Public Meeting';
      case EventType.inauguration:
        return 'Inauguration';
      case EventType.rally:
        return 'Rally';
      case EventType.healthCamp:
        return 'Health Camp';
      case EventType.doorToDoor:
        return 'Door-to-Door';
      case EventType.cultural:
        return 'Cultural';
      case EventType.other:
        return 'Other';
    }
  }

  String get titleMr {
    switch (this) {
      case EventType.publicMeeting:
        return 'सार्वजनिक सभा';
      case EventType.inauguration:
        return 'उद्घाटन';
      case EventType.rally:
        return 'रॅली / मोर्चा';
      case EventType.healthCamp:
        return 'आरोग्य शिबिर';
      case EventType.doorToDoor:
        return 'गाठीभेटी (Door-to-Door)';
      case EventType.cultural:
        return 'सांस्कृतिक महोत्सव';
      case EventType.other:
        return 'इतर';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.publicMeeting:
        return Icons.groups_rounded;
      case EventType.inauguration:
        return Icons.celebration_rounded;
      case EventType.rally:
        return Icons.campaign_rounded;
      case EventType.healthCamp:
        return Icons.medical_services_rounded;
      case EventType.doorToDoor:
        return Icons.transfer_within_a_station_rounded;
      case EventType.cultural:
        return Icons.festival_rounded;
      case EventType.other:
        return Icons.event_note_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EventType.publicMeeting:
        return const Color(0xFF0284C7); // Sky Blue
      case EventType.inauguration:
        return const Color(0xFF8B5CF6); // Purple
      case EventType.rally:
        return const Color(0xFFD97706); // Amber
      case EventType.healthCamp:
        return const Color(0xFF059669); // Emerald Green
      case EventType.doorToDoor:
        return const Color(0xFF2563EB); // Royal Blue
      case EventType.cultural:
        return const Color(0xFFE11D48); // Rose
      case EventType.other:
        return const Color(0xFF64748B); // Slate
    }
  }
}

/// RSVP Status for an attendee
enum RsvpStatus {
  going,
  notGoing,
  maybe,
}

extension RsvpStatusX on RsvpStatus {
  String get id {
    switch (this) {
      case RsvpStatus.going:
        return 'Going';
      case RsvpStatus.notGoing:
        return 'Not Going';
      case RsvpStatus.maybe:
        return 'Maybe';
    }
  }

  String get titleMr {
    switch (this) {
      case RsvpStatus.going:
        return 'येणार';
      case RsvpStatus.notGoing:
        return 'येणार नाही';
      case RsvpStatus.maybe:
        return 'कदाचित';
    }
  }

  Color get color {
    switch (this) {
      case RsvpStatus.going:
        return const Color(0xFF16A34A);
      case RsvpStatus.notGoing:
        return const Color(0xFFDC2626);
      case RsvpStatus.maybe:
        return const Color(0xFFD97706);
    }
  }

  IconData get icon {
    switch (this) {
      case RsvpStatus.going:
        return Icons.check_circle_rounded;
      case RsvpStatus.notGoing:
        return Icons.cancel_rounded;
      case RsvpStatus.maybe:
        return Icons.help_rounded;
    }
  }
}

/// RSVP Record
class EventRsvpModel {
  final String id;
  final String voterName;
  final String voterNameMr;
  final String mobile;
  final String address;
  final RsvpStatus status;
  final String responseSource; // 'WhatsApp Bot', 'Direct', 'SMS', 'Call'
  final DateTime respondedAt;

  const EventRsvpModel({
    required this.id,
    required this.voterName,
    required this.voterNameMr,
    required this.mobile,
    required this.address,
    required this.status,
    required this.responseSource,
    required this.respondedAt,
  });

  EventRsvpModel copyWith({
    String? id,
    String? voterName,
    String? voterNameMr,
    String? mobile,
    String? address,
    RsvpStatus? status,
    String? responseSource,
    DateTime? respondedAt,
  }) {
    return EventRsvpModel(
      id: id ?? this.id,
      voterName: voterName ?? this.voterName,
      voterNameMr: voterNameMr ?? this.voterNameMr,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      status: status ?? this.status,
      responseSource: responseSource ?? this.responseSource,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

/// Main Event Model
class EventModel {
  final String id;
  final String title;
  final String titleMr;
  final String description;
  final DateTime eventDate;
  final String eventTime; // e.g. "सकाळी १०:०० वा."
  final String location;
  final String locationMr;
  final EventType type;
  final String status; // 'Planned', 'Completed', 'Cancelled'
  final String area;
  final String targetAudience; // 'All', 'Senior Citizens', 'Women', 'Youth', etc.
  final DateTime createdAt;
  final List<EventRsvpModel> rsvps;

  const EventModel({
    required this.id,
    required this.title,
    required this.titleMr,
    required this.description,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    required this.locationMr,
    required this.type,
    this.status = 'Planned',
    required this.area,
    this.targetAudience = 'All',
    required this.createdAt,
    this.rsvps = const [],
  });

  int get goingCount =>
      rsvps.where((r) => r.status == RsvpStatus.going).length;

  int get notGoingCount =>
      rsvps.where((r) => r.status == RsvpStatus.notGoing).length;

  int get maybeCount =>
      rsvps.where((r) => r.status == RsvpStatus.maybe).length;

  int get totalRsvps => rsvps.length;

  double get goingPercentage {
    if (totalRsvps == 0) return 0.0;
    return (goingCount / totalRsvps) * 100;
  }

  bool get isCompleted =>
      status.toLowerCase() == 'completed' ||
      eventDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  bool get isUpcoming => !isCompleted && status.toLowerCase() != 'cancelled';

  String get formattedDate => DateFormat('d MMMM yyyy').format(eventDate);

  String get formattedDateShort => DateFormat('dd/MM/yyyy').format(eventDate);

  String get monthShortMr {
    final months = [
      'जाने', 'फेब्रु', 'मार्च', 'एप्रिल', 'मे', 'जून',
      'जुलै', 'ऑगस्ट', 'सप्टें', 'ऑक्टो', 'नोव्हें', 'डिसें'
    ];
    return months[eventDate.month - 1];
  }

  String get monthShortEn => DateFormat('MMM').format(eventDate).toUpperCase();

  String get dayNum => DateFormat('d').format(eventDate);

  EventModel copyWith({
    String? id,
    String? title,
    String? titleMr,
    String? description,
    DateTime? eventDate,
    String? eventTime,
    String? location,
    String? locationMr,
    EventType? type,
    String? status,
    String? area,
    String? targetAudience,
    DateTime? createdAt,
    List<EventRsvpModel>? rsvps,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleMr: titleMr ?? this.titleMr,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      location: location ?? this.location,
      locationMr: locationMr ?? this.locationMr,
      type: type ?? this.type,
      status: status ?? this.status,
      area: area ?? this.area,
      targetAudience: targetAudience ?? this.targetAudience,
      createdAt: createdAt ?? this.createdAt,
      rsvps: rsvps ?? this.rsvps,
    );
  }
}

