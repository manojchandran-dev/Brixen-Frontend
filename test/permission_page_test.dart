import 'package:brixen/features/companies/data/repositories/companies_repository_impl.dart';
import 'package:brixen/features/companies/domain/entities/company.dart';
import 'package:brixen/features/companies/domain/entities/company_page.dart';
import 'package:brixen/features/companies/domain/repositories/companies_repository.dart';
import 'package:brixen/features/navigation/presentation/providers/nav_modules_provider.dart';
import 'package:brixen/features/permissions/data/models/permission_model.dart';
import 'package:brixen/features/permissions/data/repositories/permissions_repository_impl.dart';
import 'package:brixen/features/permissions/domain/repositories/permissions_repository.dart';
import 'package:brixen/features/permissions/presentation/pages/permission_management_page.dart';
import 'package:brixen/shared/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake GET /permissions/companies.
class _Companies implements CompaniesRepository {
  final withAccessCalls = <bool>[];

  @override
  Future<CompanyPage> getCompanyPage({String? search, String? status, String? plan, String? industry, int page = 1, int limit = 50, bool withAccess = false}) async {
    withAccessCalls.add(withAccess);
    return CompanyPage(
      items: [
        Company(
          id: '41',
          name: 'Kaveri Textiles',
          ownerName: 'Senthil',
          access: const AccessCounts(full: 2, custom: 0, none: 9),
          createdAt: DateTime(2026),
        ),
      ],
      total: 1,
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Fails the test if the page falls back to one request per company.
class _Perms implements PermissionsRepository {
  var calls = 0;
  @override
  Future<List<PermissionModel>> getPermissions({required String companyId, String? moduleId}) async {
    calls++;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  // Also a regression: AppBottomNav without extendBody left the body 0px tall.
  testWidgets('permissions page lists companies with their access counts from one call', (tester) async {
    final companies = _Companies();
    final perms = _Perms();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        companiesRepositoryProvider.overrideWithValue(companies),
        permissionsRepositoryProvider.overrideWithValue(perms),
        grantableModulesProvider.overrideWith((ref) async => []),
      ],
      child: const MaterialApp(home: PermissionManagementPage()),
    ));
    // While loading: search box already shown, skeleton only below it.
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(SkeletonListView), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(SkeletonListView), findsNothing);
    expect(find.text('Kaveri Textiles'), findsOneWidget);
    expect(find.text('2 Full'), findsOneWidget);
    expect(find.text('9 None'), findsOneWidget);
    expect(companies.withAccessCalls, [true], reason: 'one GET /permissions/companies');
    expect(perms.calls, 0, reason: 'no per-company GET /permissions');
  });
}
