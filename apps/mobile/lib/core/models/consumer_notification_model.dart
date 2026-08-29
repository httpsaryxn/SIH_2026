class ConsumerNotificationModel {
  final String id;
  final String consumerId;
  final String title;
  final String message;
  final String type; // 'complaint_update', 'scan_alert', 'system'
  final String? relatedComplaintId;
  final bool isRead;
  final DateTime createdAt;

  ConsumerNotificationModel({
    required this.id,
    required this.consumerId,
    required this.title,
    required this.message,
    this.type = 'complaint_update',
    this.relatedComplaintId,
    this.isRead = false,
    required this.createdAt,
  });

  factory ConsumerNotificationModel.fromJson(Map<String, dynamic> json) {
    return ConsumerNotificationModel(
      id: json['id'] as String? ?? '',
      consumerId: json['consumer_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'complaint_update',
      relatedComplaintId: json['related_complaint_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consumer_id': consumerId,
      'title': title,
      'message': message,
      'type': type,
      'related_complaint_id': relatedComplaintId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
