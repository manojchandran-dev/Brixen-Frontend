import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/companies_repository.dart';
import '../datasources/companies_remote_datasource.dart';

final companiesRepositoryProvider = Provider<CompaniesRepository>((ref) {
  return CompaniesRepositoryImpl(ref.read(companiesRemoteDatasourceProvider));
});

class CompaniesRepositoryImpl implements CompaniesRepository {
  final CompaniesRemoteDatasource _ds;
  const CompaniesRepositoryImpl(this._ds);

  @override
  Future<List<Company>> getCompanies({int page = 1, int limit = 50, String? search, bool deleted = false}) =>
      _ds.getCompanies(page: page, limit: limit, search: search, deleted: deleted);

  @override
  Future<Company> getCompanyById(String id) => _ds.getCompanyById(id);

  @override
  Future<Company> createCompany(Company company) {
    // Step 1: identity fields only — server auto-generates company_code
    final body = <String, dynamic>{
      'company_name': company.name,
      if (company.entityType != null) 'entity_type': company.entityType,
      if (company.industryType != null) 'industry_type': company.industryType,
      if (company.gstNumber != null && company.gstNumber!.isNotEmpty)
        'gst_number': company.gstNumber,
      if (company.panNumber != null && company.panNumber!.isNotEmpty)
        'pan_card': company.panNumber,
    };
    return _ds.createCompany(body);
  }

  @override
  Future<Company> updateCompanyStep2(String id, Company company) {
    final body = <String, dynamic>{
      'owner_name': company.ownerName,
      if (company.email != null && company.email!.isNotEmpty) 'email': company.email,
      if (company.phone != null && company.phone!.isNotEmpty) 'phone': company.phone,
      if (company.secondaryEmail != null && company.secondaryEmail!.isNotEmpty)
        'secondary_email': company.secondaryEmail,
      if (company.website != null && company.website!.isNotEmpty) 'website': company.website,
    };
    return _ds.updateCompanyStep2(id, body);
  }

  @override
  Future<Company> updateCompanyStep3(String id, Company company) {
    final body = <String, dynamic>{
      if (company.address != null) 'address': company.address,
      if (company.city != null) 'city': company.city,
      if (company.state != null) 'state': company.state,
      if (company.pincode != null) 'pincode': company.pincode,
    };
    return _ds.updateCompanyStep3(id, body);
  }

  @override
  Future<Company> updateCompanyStatus(String id, bool isActive) =>
      _ds.updateCompanyStatus(id, isActive ? 'ACTIVE' : 'INACTIVE');

  @override
  Future<Company> updateCompany(String id, Company company) {
    final body = <String, dynamic>{
      'company_name': company.name,
      'owner_name': company.ownerName,
      if (company.email != null && company.email!.isNotEmpty) 'email': company.email,
      if (company.phone != null && company.phone!.isNotEmpty) 'phone': company.phone,
      if (company.secondaryEmail != null && company.secondaryEmail!.isNotEmpty)
        'secondary_email': company.secondaryEmail,
      if (company.website != null && company.website!.isNotEmpty) 'website': company.website,
      if (company.gstNumber != null && company.gstNumber!.isNotEmpty)
        'gst_number': company.gstNumber,
      if (company.panNumber != null && company.panNumber!.isNotEmpty)
        'pan_card': company.panNumber,
      if (company.address != null) 'address': company.address,
      if (company.city != null) 'city': company.city,
      if (company.state != null) 'state': company.state,
      if (company.country != null) 'country': company.country,
      if (company.pincode != null) 'pincode': company.pincode,
      if (company.industryType != null) 'industry_type': company.industryType,
      if (company.entityType != null) 'entity_type': company.entityType,
      if (company.subscriptionPlan != null) 'subscription_plan': company.subscriptionPlan,
    };
    return _ds.updateCompany(id, body);
  }

  @override
  Future<void> deleteCompany(String id) => _ds.deleteCompany(id);

  @override
  Future<Company> restoreCompany(String id) => _ds.restoreCompany(id);
}
