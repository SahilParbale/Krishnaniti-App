import 'package:intl/intl.dart';

class SmsCampaignStats {
  final int queued;
  final int sending;
  final int sent;
  final int delivered;
  final int failed;

  const SmsCampaignStats({
    this.queued = 0,
    this.sending = 0,
    this.sent = 0,
    this.delivered = 0,
    this.failed = 0,
  });

  factory SmsCampaignStats.fromJson(Map<String, dynamic> json) {
    return SmsCampaignStats(
      queued: (json['QUEUED'] as num?)?.toInt() ?? (json['queued'] as num?)?.toInt() ?? 0,
      sending: (json['SENDING'] as num?)?.toInt() ?? (json['sending'] as num?)?.toInt() ?? 0,
      sent: (json['SENT'] as num?)?.toInt() ?? (json['sent'] as num?)?.toInt() ?? 0,
      delivered: (json['DELIVERED'] as num?)?.toInt() ?? (json['delivered'] as num?)?.toInt() ?? 0,
      failed: (json['FAILED'] as num?)?.toInt() ?? (json['failed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'QUEUED': queued,
    'SENDING': sending,
    'SENT': sent,
    'DELIVERED': delivered,
    'FAILED': failed,
  };
}

class SmsCampaignModel {
  final String id;
  final String name;
  final String message;
  final String status; // 'COMPLETED', 'SENDING', 'QUEUED', 'FAILED', 'CANCELLED'
  final int totalRecipients;
  final DateTime createdAt;
  final SmsCampaignStats stats;
  final String? targetCriteria;
  final String? dltTemplateId;
  final String? createdBy;

  const SmsCampaignModel({
    required this.id,
    required this.name,
    required this.message,
    this.status = 'COMPLETED',
    required this.totalRecipients,
    required this.createdAt,
    this.stats = const SmsCampaignStats(),
    this.targetCriteria,
    this.dltTemplateId,
    this.createdBy,
  });

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isSending => status.toUpperCase() == 'SENDING' || status.toUpperCase() == 'QUEUED';
  bool get isFailed => status.toUpperCase() == 'FAILED';

  factory SmsCampaignModel.fromJson(Map<String, dynamic> json) {
    return SmsCampaignModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'SMS Campaign',
      message: json['message']?.toString() ?? json['message_body']?.toString() ?? '',
      status: json['status']?.toString() ?? 'COMPLETED',
      totalRecipients: (json['total_recipients'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      stats: json['stats'] != null && json['stats'] is Map
          ? SmsCampaignStats.fromJson(Map<String, dynamic>.from(json['stats']))
          : const SmsCampaignStats(),
      targetCriteria: json['target_criteria']?.toString(),
      dltTemplateId: json['dlt_template_id']?.toString(),
      createdBy: json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) => {
    'id': id,
    'name': name,
    'message': message,
    'status': status,
    'total_recipients': totalRecipients,
    'created_at': createdAt.toIso8601String(),
    'stats': stats.toJson(),
    if (targetCriteria != null) 'target_criteria': targetCriteria,
    if (dltTemplateId != null) 'dlt_template_id': dltTemplateId,
    if (tenantId != null) 'tenant_id': tenantId,
  };
}

class SmsTemplateModel {
  final String id;
  final String title;
  final String category;
  final String text;
  final String dltTeId;

  const SmsTemplateModel({
    required this.id,
    required this.title,
    required this.category,
    required this.text,
    required this.dltTeId,
  });
}

