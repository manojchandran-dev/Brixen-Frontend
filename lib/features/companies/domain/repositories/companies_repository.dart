import '../entities/company.dart';

abstract class CompaniesRepository {
  /// [deleted] lists soft-deleted companies instead (for restore).
  Future<List<Company>> getCompanies({int page = 1, int limit = 50, String? search, bool deleted = false});
  Future<Company> getCompanyById(String id);

  // Multi-step creation
  Future<Company> createCompany(Company company);          // POST — step 1 (identity)
  Future<Company> updateCompanyStep2(String id, Company company); // PUT /step2 (contact)
  Future<Company> updateCompanyStep3(String id, Company company); // PUT /step3 (location)

  // Status toggle — dedicated endpoint, rejects if onboarding not completed
  Future<Company> updateCompanyStatus(String id, bool isActive);

  // Generic full update & delete
  Future<Company> updateCompany(String id, Company company);
  Future<void> deleteCompany(String id); // soft delete
  Future<Company> restoreCompany(String id);
}
