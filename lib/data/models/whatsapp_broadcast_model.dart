import 'package:intl/intl.dart';

class WhatsAppBroadcastModel {
  final String id;
  final String title;
  final String message;
  final DateTime sentAt;
  final String channel; // 'whatsapp'
  final int recipients;
  final int sentCount;
  final int deliveredCount;
  final int failedCount;
  final String status; // 'COMPLETED', 'SENDING', 'FAILED'
  final String? targetCriteria;
  final String? category;

  const WhatsAppBroadcastModel({
    required this.id,
    required this.title,
    required this.message,
    required this.sentAt,
    this.channel = 'whatsapp',
    required this.recipients,
    required this.sentCount,
    required this.deliveredCount,
    required this.failedCount,
    this.status = 'COMPLETED',
    this.targetCriteria,
    this.category,
  });

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(sentAt);

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isSending => status.toUpperCase() == 'SENDING' || status.toUpperCase() == 'QUEUED';
  bool get isFailed => status.toUpperCase() == 'FAILED';

  factory WhatsAppBroadcastModel.fromJson(Map<String, dynamic> json) {
    final int rec = (json['recipients'] as num?)?.toInt() ?? 0;
    final int sent = (json['sent_count'] as num?)?.toInt() ?? rec;
    final int failed = (json['failed_count'] as num?)?.toInt() ?? 0;
    final int delivered = (json['delivered_count'] as num?)?.toInt() ?? (sent - failed).clamp(0, rec);

    return WhatsAppBroadcastModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'WhatsApp Broadcast',
      message: json['message']?.toString() ?? '',
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      channel: json['channel']?.toString() ?? 'whatsapp',
      recipients: rec,
      sentCount: sent,
      deliveredCount: delivered,
      failedCount: failed,
      status: json['status']?.toString() ?? 'COMPLETED',
      targetCriteria: json['target_criteria']?.toString(),
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson({String? tenantId}) => {
    'id': id,
    'title': title,
    'message': message,
    'sent_at': sentAt.toIso8601String(),
    'channel': channel,
    'recipients': recipients,
    'sent_count': sentCount,
    'delivered_count': deliveredCount,
    'failed_count': failedCount,
    'status': status,
    if (targetCriteria != null) 'target_criteria': targetCriteria,
    if (category != null) 'category': category,
    if (tenantId != null) 'tenant_id': tenantId,
  };
}

class WhatsAppTemplateModel {
  final String id;
  final String title;
  final String category;
  final String text;
  final String emoji;

  const WhatsAppTemplateModel({
    required this.id,
    required this.title,
    required this.category,
    required this.text,
    this.emoji = '📢',
  });
}

