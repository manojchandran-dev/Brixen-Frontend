import 'package:flutter/material.dart';
import '../../../../shared/widgets/chip_filter_sheet.dart';
import '../../domain/entities/company.dart';
import '../providers/companies_provider.dart';

export '../../../../shared/widgets/chip_filter_sheet.dart'
    show HeaderIconButton;

/// Company filter panel (Companies and Permissions pages): Status,
/// Onboarding, Plan, Industry. Options come from [companies] — or, for the
/// sections the API reports, from [serverOptions] (the list response's
/// `filters` block) — so there's no hard-coded list to keep in sync.
/// [onApply] gets the chosen filters on "Apply filters"; [onClear] runs on
/// "Clear all".
void showCompanyFilterSheet(
  BuildContext context, {
  required CompanyFilters initial,
  required List<Company> companies,
  Map<String, Map<String, int>> serverOptions = const {},
  required ValueChanged<CompanyFilters> onApply,
  required VoidCallback onClear,
}) {
  // (field key, title, API filters key, value getter, label for a value)
  final fields =
      <
        (
          String,
          String,
          String?,
          Object? Function(Company),
          String Function(Object),
        )
      >[
        (
          'active',
          'Status',
          'status',
          (c) => c.isActive,
          (v) => v == true ? 'Active' : 'Inactive',
        ),
        (
          'onboarding',
          'Onboarding',
          null,
          (c) => c.onboardingStatus,
          (v) => v == 'completed'
              ? 'Completed'
              : v == 'pending'
              ? 'Pending'
              : '$v',
        ),
        (
          'plan',
          'Subscription plan',
          'subscription_plan',
          (c) => c.subscriptionPlan,
          (v) => '$v',
        ),
        (
          'industry',
          'Industry',
          'industry_type',
          (c) => c.industryType,
          (v) => '$v',
        ),
      ];

  final sections = [
    for (final (key, title, apiKey, valueOf, labelOf) in fields)
      FilterSection(
        key: key,
        title: title,
        options: () {
          // Values from the API's `filters` block when it reports this
          // section, else the distinct values in the loaded companies.
          final server = serverOptions[apiKey];
          final values = <Object>{
            if (server != null)
              for (final k in server.keys)
                key == 'active' ? k.toUpperCase() == 'ACTIVE' : k
            else
              for (final c in companies)
                if (valueOf(c) case final v?
                    when v is! String || v.trim().isNotEmpty)
                  v,
          }.toList()..sort((a, b) => labelOf(a).compareTo(labelOf(b)));
          return [for (final v in values) (v, labelOf(v))];
        }(),
      ),
  ];

  showChipFilterSheet(
    context,
    title: 'Filter companies',
    sections: sections,
    selected: {
      'active': initial.active,
      'onboarding': initial.onboarding,
      'plan': initial.plan,
      'industry': initial.industry,
    },
    onApply: (chosen) => onApply(
      chosen.entries.fold(
        const CompanyFilters(),
        (f, e) => f.withField(e.key, e.value),
      ),
    ),
    onClear: onClear,
  );
}
