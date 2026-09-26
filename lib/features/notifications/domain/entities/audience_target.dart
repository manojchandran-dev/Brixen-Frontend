import '../../../companies/domain/entities/company.dart';

/// How a Push Notification or Announcement's recipients are selected.
/// Shared by both features — built once here rather than duplicated.
enum AudienceType { allCompanies, selectedCompanies, byPlan, byStatus }

/// A resolved audience choice. Only the field(s) relevant to [type] are
/// populated; the rest stay at their default (empty/null).
class AudienceTarget {
  final AudienceType type;
  final List<String> companyIds;
  final String? plan;
  final bool? activeOnly;

  const AudienceTarget({
    required this.type,
    this.companyIds = const [],
    this.plan,
    this.activeOnly,
  });

  const AudienceTarget.allCompanies() : this(type: AudienceType.allCompanies);

  factory AudienceTarget.selectedCompanies(List<String> ids) =>
      AudienceTarget(type: AudienceType.selectedCompanies, companyIds: ids);

  factory AudienceTarget.byPlan(String plan) =>
      AudienceTarget(type: AudienceType.byPlan, plan: plan);

  factory AudienceTarget.byStatus({required bool activeOnly}) =>
      AudienceTarget(type: AudienceType.byStatus, activeOnly: activeOnly);

  /// Which of [allCompanies] this target actually resolves to right now —
  /// the single source of truth for both "N companies selected" and the
  /// eventual recipient list, so the estimate is never allowed to drift
  /// out of sync with what would actually get sent.
  List<Company> resolve(List<Company> allCompanies) {
    switch (type) {
      case AudienceType.allCompanies:
        return allCompanies.where((c) => c.isActive).toList();
      case AudienceType.selectedCompanies:
        final ids = companyIds.toSet();
        return allCompanies.where((c) => ids.contains(c.id)).toList();
      case AudienceType.byPlan:
        return allCompanies.where((c) => c.subscriptionPlan == plan).toList();
      case AudienceType.byStatus:
        return allCompanies.where((c) => c.isActive == activeOnly).toList();
    }
  }

  int estimatedRecipients(List<Company> allCompanies) =>
      resolve(allCompanies).length;

  /// Only the field relevant to [type] is sent, as the API expects. Company
  /// ids go out as numbers when they are numeric (the backend's ids are).
  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (type == AudienceType.selectedCompanies)
      'company_ids': companyIds.map((id) => int.tryParse(id) ?? id).toList(),
    if (type == AudienceType.byPlan) 'plan': plan,
    if (type == AudienceType.byStatus) 'active_only': activeOnly ?? true,
  };

  factory AudienceTarget.fromJson(Map<String, dynamic> json) => AudienceTarget(
    type: AudienceType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => AudienceType.allCompanies,
    ),
    companyIds:
        (json['company_ids'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    plan: json['plan'] as String?,
    activeOnly: json['active_only'] as bool?,
  );
}
