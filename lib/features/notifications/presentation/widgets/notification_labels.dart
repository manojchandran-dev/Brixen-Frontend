import '../../domain/entities/audience_target.dart';
import '../../domain/entities/push_notification.dart';

String priorityLabel(NotificationPriority p) => switch (p) {
  NotificationPriority.normal => 'Normal',
  NotificationPriority.important => 'Important',
  NotificationPriority.urgent => 'Urgent',
};

String openOnTapLabel(OpenOnTapTarget t) => switch (t) {
  OpenOnTapTarget.none => 'No Action',
  OpenOnTapTarget.dashboard => 'Dashboard',
  OpenOnTapTarget.subscription => 'Subscription',
  OpenOnTapTarget.billing => 'Billing',
  OpenOnTapTarget.attendance => 'Attendance',
  OpenOnTapTarget.payroll => 'Payroll',
  OpenOnTapTarget.inventory => 'Inventory',
  OpenOnTapTarget.production => 'Production',
  OpenOnTapTarget.support => 'Support',
  OpenOnTapTarget.announcement => 'Announcement',
  OpenOnTapTarget.specificPage => 'Specific Page',
};

/// Same target list, minus "Announcement" (an Announcement's own CTA
/// pointing at itself doesn't make sense) — used by the Announcement CTA
/// dropdown.
const kCtaTargets = [
  OpenOnTapTarget.none,
  OpenOnTapTarget.dashboard,
  OpenOnTapTarget.subscription,
  OpenOnTapTarget.billing,
  OpenOnTapTarget.payroll,
  OpenOnTapTarget.inventory,
  OpenOnTapTarget.production,
  OpenOnTapTarget.support,
  OpenOnTapTarget.specificPage,
];

String audienceLabel(AudienceTarget a) => switch (a.type) {
  AudienceType.allCompanies => 'All Companies',
  AudienceType.selectedCompanies => '${a.companyIds.length} Selected',
  AudienceType.byPlan => a.plan ?? 'By Plan',
  AudienceType.byStatus =>
    (a.activeOnly ?? true) ? 'Active Companies' : 'Inactive Companies',
};
