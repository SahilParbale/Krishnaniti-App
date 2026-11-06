import 'dart:convert';

class LetterModel {
  final String id;
  final String title;
  final String? letterType;
  final String? department;
  final String? recipient;
  final String? sender;
  final String? userId;
  final String? area;
  final Map<String, dynamic> details;
  final String status; // 'Pending', 'Approved', 'Rejected', 'Received'
  final bool isIncoming;
  final String? letterUrl;
  final String? fileType; // 'application/pdf', 'image/jpeg', etc.
  final String? description;
  final DateTime? receivedDate;
  final DateTime createdAt;
  final String? tenantId;

  LetterModel({
    required this.id,
    required this.title,
    this.letterType,
    this.department,
    this.recipient,
    this.sender,
    this.userId,
    this.area,
    this.details = const {},
    required this.status,
    required this.isIncoming,
    this.letterUrl,
    this.fileType,
    this.description,
    this.receivedDate,
    required this.createdAt,
    this.tenantId,
  });

  // Convenience getters matching web version
  String get citizenName =>
      details['name']?.toString() ??
      recipient ??
      userId ??
      sender ??
      'Citizen';

  String get subject => details['subject']?.toString() ?? title;

  String get address =>
      details['address']?.toString() ?? details['text']?.toString() ?? '';

  String get purpose =>
      details['purpose']?.toString() ?? details['reason']?.toString() ?? '';

  String get mobile => details['mobile']?.toString() ?? '';

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory LetterModel.fromJson(Map<String, dynamic> json, {bool isIncoming = false}) {
    final incoming = isIncoming || json['is_incoming'] == true || json.containsKey('scanned_file_url');

    Map<String, dynamic> detailsMap = {};
    if (json['details'] != null) {
      if (json['details'] is Map) {
        detailsMap = Map<String, dynamic>.from(json['details'] as Map);
      } else if (json['details'] is String && (json['details'] as String).isNotEmpty) {
        try {
          detailsMap = Map<String, dynamic>.from(jsonDecode(json['details'] as String) as Map);
        } catch (_) {}
      }
    }

    final title = json['title'] ?? json['subject'] ?? json['type'] ?? 'Official Letter';
    final letterType = json['type'] ?? json['letter_type'] ?? 'General';
    final letterUrl = json['scanned_file_url'] ?? json['pdf_url'] ?? json['file_url'] ?? json['attachment_url'];
    final rawFileType = json['file_type']?.toString();
    final fileType = rawFileType ?? (letterUrl != null && letterUrl.toString().toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'image/jpeg');

    return LetterModel(
      id: json['id']?.toString() ?? '',
      title: title.toString(),
      letterType: letterType.toString(),
      department: json['department']?.toString(),
      recipient: json['recipient'] ?? json['to_whom'] ?? detailsMap['name'],
      sender: json['sender'] ?? json['from_whom'] ?? json['user_id'],
      userId: json['user_id']?.toString(),
      area: json['area']?.toString(),
      details: detailsMap,
      status: json['status']?.toString() ?? (incoming ? 'Received' : 'Pending'),
      isIncoming: incoming,
      letterUrl: letterUrl?.toString(),
      fileType: fileType,
      description: json['description']?.toString(),
      receivedDate: json['received_date'] != null
          ? DateTime.tryParse(json['received_date'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tenantId: json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    if (isIncoming) {
      return {
        'title': title,
        'description': description,
        'scanned_file_url': letterUrl,
        'file_type': fileType,
        'area': area,
        'received_date': receivedDate?.toIso8601String(),
        'tenant_id': tenantId,
      };
    } else {
      return {
        'type': letterType,
        'user_id': userId,
        'area': area,
        'details': details,
        'status': status,
        'tenant_id': tenantId,
      };
    }
  }

  LetterModel copyWith({
    String? id,
    String? title,
    String? letterType,
    String? department,
    String? recipient,
    String? sender,
    String? userId,
    String? area,
    Map<String, dynamic>? details,
    String? status,
    bool? isIncoming,
    String? letterUrl,
    String? fileType,
    String? description,
    DateTime? receivedDate,
    DateTime? createdAt,
    String? tenantId,
  }) {
    return LetterModel(
      id: id ?? this.id,
      title: title ?? this.title,
      letterType: letterType ?? this.letterType,
      department: department ?? this.department,
      recipient: recipient ?? this.recipient,
      sender: sender ?? this.sender,
      userId: userId ?? this.userId,
      area: area ?? this.area,
      details: details ?? this.details,
      status: status ?? this.status,
      isIncoming: isIncoming ?? this.isIncoming,
      letterUrl: letterUrl ?? this.letterUrl,
      fileType: fileType ?? this.fileType,
      description: description ?? this.description,
      receivedDate: receivedDate ?? this.receivedDate,
      createdAt: createdAt ?? this.createdAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}
