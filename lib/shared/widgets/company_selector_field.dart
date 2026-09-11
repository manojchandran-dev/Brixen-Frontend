import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/companies/domain/entities/company.dart';
import '../../features/companies/presentation/providers/companies_provider.dart';
import 'brixen_dropdown.dart';

/// The "which company is this for" field shown only to a superAdmin on
/// every creation form — a companyAdmin/employee session already belongs
/// to one company (`Session.companyId`), so they never see this at all.
class CompanySelectorField extends ConsumerWidget {
  final Company? value;
  final ValueChanged<Company?> onChanged;
  const CompanySelectorField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(companiesProvider).valueOrNull ?? [];
    return BrixenDropdown<Company>(
      hint: companies.isEmpty ? 'No companies yet' : 'Company *',
      value: companies.contains(value) ? value : null,
      items: companies,
      labelOf: (c) => c.name,
      icon: Icons.business_rounded,
      onChanged: onChanged,
    );
  }
}
