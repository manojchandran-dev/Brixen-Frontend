import '../../domain/entities/announcement.dart';
import '../../domain/entities/audience_target.dart';
import '../../domain/entities/push_notification.dart' show CommunicationStatus, OpenOnTapTarget;

/// See `push_notification_model.dart` — same "shaped like the real payload
/// already" rationale for the eventual `POST /api/v1/announcements` swap.
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.shortDescription,
    required super.content,
    super.bannerUrl,
    required super.audience,
    super.ctaLabel,
    super.ctaTarget,
    super.specificPageRoute,
    super.status,
    super.publishedAt,
    super.scheduledAt,
    super.views,
    required super.createdAt,
    super.createdBy,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      shortDescription: (json['short_description'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      bannerUrl: json['banner_url'] as String?,
      audience: AudienceTarget.fromJson((json['audience'] as Map?)?.cast<String, dynamic>() ?? const {'type': 'allCompanies'}),
      ctaLabel: json['cta_label'] as String?,
      ctaTarget: OpenOnTapTarget.values.firstWhere(
        (o) => o.name == json['cta_target'],
        orElse: () => OpenOnTapTarget.none,
      ),
      specificPageRoute: json['specific_page_route'] as String?,
      status: CommunicationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CommunicationStatus.draft,
      ),
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString())?.toLocal() : null,
      scheduledAt: json['scheduled_at'] != null ? DateTime.tryParse(json['scheduled_at'].toString())?.toLocal() : null,
      views: (json['views'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      createdBy: (json['created_by'] ?? 'Super Admin').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'short_description': shortDescription,
        'content': content,
        'banner_url': bannerUrl,
        'audience': audience.toJson(),
        'cta_label': ctaLabel,
        'cta_target': ctaTarget.name,
        'specific_page_route': specificPageRoute,
        'status': status.name,
        'published_at': publishedAt?.toIso8601String(),
        'scheduled_at': scheduledAt?.toIso8601String(),
        'views': views,
        'created_at': createdAt.toIso8601String(),
        'created_by': createdBy,
      };

  factory AnnouncementModel.fromEntity(Announcement a) => AnnouncementModel(
        id: a.id,
        title: a.title,
        shortDescription: a.shortDescription,
        content: a.content,
        bannerUrl: a.bannerUrl,
        audience: a.audience,
        ctaLabel: a.ctaLabel,
        ctaTarget: a.ctaTarget,
        specificPageRoute: a.specificPageRoute,
        status: a.status,
        publishedAt: a.publishedAt,
        scheduledAt: a.scheduledAt,
        views: a.views,
        createdAt: a.createdAt,
        createdBy: a.createdBy,
      );
}
