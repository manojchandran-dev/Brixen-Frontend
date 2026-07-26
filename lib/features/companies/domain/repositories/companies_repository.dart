import '../entities/company.dart';

abstract class CompaniesRepository {
  Future<List<Company>> getCompanies({int page = 1, int limit = 50, String? search});
  Future<Company> getCompanyById(String id);
  Future<Company> createCompany(Company company);
  Future<Company> updateCompany(String id, Company company);
  Future<void> deleteCompany(String id);
}
