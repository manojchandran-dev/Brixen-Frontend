import 'package:brixen/features/employees/presentation/pages/staff_permissions_pages.dart';
import 'package:brixen/features/permissions/domain/entities/module_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The company may view and add sales, but not edit or delete them.
  final sales = StaffModuleGrant.fromJson({
    'id': 'M1',
    'name': 'Sales',
    'group': null,
    'company': {'view': true, 'create': true, 'edit': false, 'delete': false},
    'employee': {'view': true, 'create': false},
  });

  test('Full Access is everything the company has — nothing more', () {
    expect(sales.fullFlags, {
      'view': true,
      'create': true,
      'edit': false,
      'delete': false,
    });
    expect(sales.levelOf(sales.fullFlags), AccessLevel.full);
  });

  test('levels from the switches', () {
    expect(sales.levelOf(sales.employee), AccessLevel.custom); // view only
    expect(
      sales.levelOf({
        'view': false,
        'create': false,
        'edit': false,
        'delete': false,
      }),
      AccessLevel.none,
    );
  });

  test('group from the modules API (Masters children)', () {
    final unit = StaffModuleGrant.fromJson({
      'id': 'M2',
      'name': 'Units',
      'group': 'Masters',
      'company': {'view': true},
      'employee': {},
    });
    expect(unit.group, 'Masters');
    expect(unit.levelOf(unit.employee), AccessLevel.none);
  });
}
