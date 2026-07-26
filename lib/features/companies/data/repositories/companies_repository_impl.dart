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
  Future<List<Company>> getCompanies({int page = 1, int limit = 50, String? search}) =>
      _ds.getCompanies(page: page, limit: limit, search: search);

  @override
  Future<Company> getCompanyById(String id) => _ds.getCompanyById(id);

  @override
  Future<Company> createCompany(Company company) {
    final body = {
      'name': company.name,
      'owner_name': company.ownerName,
      'email': company.email,
      if (company.code != null) 'code': company.code,
      if (company.phone != null) 'phone': company.phone,
      if (company.address != null) 'address': company.address,
      if (company.city != null) 'city': company.city,
      if (company.state != null) 'state': company.state,
      if (company.country != null) 'country': company.country,
      if (company.pincode != null) 'pincode': company.pincode,
      if (company.industryType != null) 'industry_type': company.industryType,
      if (company.entityType != null) 'entity_type': company.entityType,
      if (company.panNumber != null) 'pan_number': company.panNumber,
      if (company.subscriptionPlan != null) 'subscription_plan': company.subscriptionPlan,
      'is_active': company.isActive,
    };
    return _ds.createCompany(body);
  }

  @override
  Future<Company> updateCompany(String id, Company company) {
    final body = {
      'name': company.name,
      'owner_name': company.ownerName,
      'email': company.email,
      if (company.code != null) 'code': company.code,
      if (company.phone != null) 'phone': company.phone,
      if (company.address != null) 'address': company.address,
      if (company.city != null) 'city': company.city,
      if (company.state != null) 'state': company.state,
      if (company.country != null) 'country': company.country,
      if (company.pincode != null) 'pincode': company.pincode,
      if (company.industryType != null) 'industry_type': company.industryType,
      if (company.entityType != null) 'entity_type': company.entityType,
      if (company.panNumber != null) 'pan_number': company.panNumber,
      if (company.subscriptionPlan != null) 'subscription_plan': company.subscriptionPlan,
      'is_active': company.isActive,
    };
    return _ds.updateCompany(id, body);
  }

  @override
  Future<void> deleteCompany(String id) => _ds.deleteCompany(id);
}
