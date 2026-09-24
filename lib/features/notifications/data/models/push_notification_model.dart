import '../../domain/entities/audience_target.dart';
import '../../domain/entities/push_notification.dart';

/// Confirmed key: `recipient_details`, on `GET /notifications/push/:id`
/// only (never the list). The other names are kept as fallbacks in case
/// that ever changes rather than pinning to just the one.
List<CompanyDeliveryStatus> _companyDeliveries(Map<String, dynamic> json) {
  final raw =
      json['recipient_details'] ??
      json['company_deliveries'] ??
      json['deliveries'] ??
      json['delivery_breakdown'] ??
      json['companies'];
  if (raw is! List) return const [];
  return raw.map((e) {
    final m = e as Map;
    return CompanyDeliveryStatus(
      companyId: (m['company_id'] ?? '').toString(),
      companyName: (m['company_name'] ?? m['name'] ?? 'Unknown company')
          .toString(),
      status: (m['status'] ?? '').toString(),
      error: m['error'] as String?,
      deliveredAt: m['delivered_at'] != null
          ? DateTime.tryParse(m['delivered_at'].toString())?.toLocal()
          : null,
      openedAt: m['opened_at'] != null
          ? DateTime.tryParse(m['opened_at'].toString())?.toLocal()
          : null,
    );
  }).toList();
}

/// `fromJson`/`toJson` are shaped exactly like the real
/// `POST /api/v1/notifications/push` payload would be, even though the mock
/// datasource never actually serializes over the wire yet — so swapping the
/// datasource for a real Dio-backed one later only touches that one file.
class PushNotificationModel extends PushNotification {
  const PushNotificationModel({
    required super.id,
    required super.title,
    required super.message,
    required super.audience,
    super.priority,
    super.openOnTap,
    super.specificPageRoute,
    super.status,
    super.scheduledAt,
    super.sentAt,
    super.recipients,
    super.delivered,
    super.failed,
    super.opened,
    super.companyDeliveries,
    required super.createdAt,
    super.createdBy,
  });

  factory PushNotificationModel.fromJson(Map<String, dynamic> json) {
    return PushNotificationModel(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      audience: AudienceTarget.fromJson(
        (json['audience'] as Map?)?.cast<String, dynamic>() ??
            const {'type': 'allCompanies'},
      ),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      openOnTap: OpenOnTapTarget.values.firstWhere(
        (o) => o.name == json['open_on_tap'],
        orElse: () => OpenOnTapTarget.none,
      ),
      specificPageRoute: json['specific_page_route'] as String?,
      status: CommunicationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CommunicationStatus.draft,
      ),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())?.toLocal()
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())?.toLocal()
          : null,
      recipients: (json['recipients'] as num?)?.toInt() ?? 0,
      delivered: (json['delivered'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      opened: (json['opened'] as num?)?.toInt() ?? 0,
      companyDeliveries: _companyDeliveries(json),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      createdBy: (json['created_by'] ?? 'Super Admin').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'audience': audience.toJson(),
    'priority': priority.name,
    'open_on_tap': openOnTap.name,
    'specific_page_route': specificPageRoute,
    'status': status.name,
    'scheduled_at': scheduledAt?.toIso8601String(),
    'sent_at': sentAt?.toIso8601String(),
    'recipients': recipients,
    'delivered': delivered,
    'failed': failed,
    'opened': opened,
    'created_at': createdAt.toIso8601String(),
    'created_by': createdBy,
  };

  factory PushNotificationModel.fromEntity(PushNotification p) =>
      PushNotificationModel(
        id: p.id,
        title: p.title,
        message: p.message,
        audience: p.audience,
        priority: p.priority,
        openOnTap: p.openOnTap,
        specificPageRoute: p.specificPageRoute,
        status: p.status,
        scheduledAt: p.scheduledAt,
        sentAt: p.sentAt,
        recipients: p.recipients,
        delivered: p.delivered,
        failed: p.failed,
        opened: p.opened,
        createdAt: p.createdAt,
        createdBy: p.createdBy,
      );
}
