import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/companies/domain/entities/company.dart';

/// The company a superAdmin is currently "browsing as" on the Employees/
/// Customers/Products/Sales/Expenses list screens — null means "All
/// Companies" (no `company_id` sent, matching the previous behaviour).
/// companyAdmin/employee sessions never touch this; their own single
/// company is already attached by [CompanyScopeInterceptor] directly from
/// `Session.companyId`.
final superAdminCompanyFilterProvider = StateProvider<Company?>((ref) => null);
