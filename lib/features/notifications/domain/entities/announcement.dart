import 'audience_target.dart';
import 'push_notification.dart' show CommunicationStatus, OpenOnTapTarget;

class Announcement {
  final String id;
  final String title;
  final String shortDescription;

  /// Quill Delta JSON string (flutter_quill's `Document.toDelta().toJson()`
  /// round-tripped through `jsonEncode`) — not plain text.
  final String content;
  final String? bannerUrl;
  final AudienceTarget audience;
  final String? ctaLabel;
  final OpenOnTapTarget ctaTarget;
  final String? specificPageRoute;
  final CommunicationStatus status;
  final DateTime? publishedAt;
  final DateTime? scheduledAt;
  final int views;
  final DateTime createdAt;
  final String createdBy;

  const Announcement({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.content,
    this.bannerUrl,
    required this.audience,
    this.ctaLabel,
    this.ctaTarget = OpenOnTapTarget.none,
    this.specificPageRoute,
    this.status = CommunicationStatus.draft,
    this.publishedAt,
    this.scheduledAt,
    this.views = 0,
    required this.createdAt,
    this.createdBy = 'Super Admin',
  });

  Announcement copyWith({
    String? title,
    String? shortDescription,
    String? content,
    String? bannerUrl,
    AudienceTarget? audience,
    String? ctaLabel,
    OpenOnTapTarget? ctaTarget,
    String? specificPageRoute,
    CommunicationStatus? status,
    DateTime? publishedAt,
    DateTime? scheduledAt,
    int? views,
  }) {
    return Announcement(
      id: id,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      content: content ?? this.content,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      audience: audience ?? this.audience,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      ctaTarget: ctaTarget ?? this.ctaTarget,
      specificPageRoute: specificPageRoute ?? this.specificPageRoute,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      views: views ?? this.views,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
