import 'audience_target.dart';

enum NotificationPriority { normal, important, urgent }

/// Where the app navigates to when the user taps the push notification.
enum OpenOnTapTarget {
  none,
  dashboard,
  subscription,
  billing,
  attendance,
  payroll,
  inventory,
  production,
  support,
  announcement,
  specificPage,
}

enum CommunicationStatus {
  draft,
  scheduled,
  sending,
  sent,
  published,
  failed,
  cancelled,
}

/// One company's delivery outcome for a sent push — only ever populated by
/// the single-record `GET .../push/:id` endpoint, never the list.
class CompanyDeliveryStatus {
  final String companyId;
  final String companyName;
  final String status;
  final String? error;
  final DateTime? deliveredAt;
  final DateTime? openedAt;

  const CompanyDeliveryStatus({
    required this.companyId,
    required this.companyName,
    required this.status,
    this.error,
    this.deliveredAt,
    this.openedAt,
  });
}

class PushNotification {
  final String id;
  final String title;
  final String message;
  final AudienceTarget audience;
  final NotificationPriority priority;
  final OpenOnTapTarget openOnTap;
  final String? specificPageRoute;
  final CommunicationStatus status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int recipients;
  final int delivered;
  final int failed;
  final int opened;
  final List<CompanyDeliveryStatus> companyDeliveries;
  final DateTime createdAt;
  final String createdBy;

  const PushNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    this.priority = NotificationPriority.normal,
    this.openOnTap = OpenOnTapTarget.none,
    this.specificPageRoute,
    this.status = CommunicationStatus.draft,
    this.scheduledAt,
    this.sentAt,
    this.recipients = 0,
    this.delivered = 0,
    this.failed = 0,
    this.opened = 0,
    this.companyDeliveries = const [],
    required this.createdAt,
    this.createdBy = 'Super Admin',
  });

  PushNotification copyWith({
    String? title,
    String? message,
    AudienceTarget? audience,
    NotificationPriority? priority,
    OpenOnTapTarget? openOnTap,
    String? specificPageRoute,
    CommunicationStatus? status,
    DateTime? scheduledAt,
    DateTime? sentAt,
    int? recipients,
    int? delivered,
    int? failed,
    int? opened,
  }) {
    return PushNotification(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      audience: audience ?? this.audience,
      priority: priority ?? this.priority,
      openOnTap: openOnTap ?? this.openOnTap,
      specificPageRoute: specificPageRoute ?? this.specificPageRoute,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      recipients: recipients ?? this.recipients,
      delivered: delivered ?? this.delivered,
      failed: failed ?? this.failed,
      opened: opened ?? this.opened,
      companyDeliveries: companyDeliveries,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
