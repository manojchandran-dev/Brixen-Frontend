class ApiEndpoints {
  static const String baseUrl = 'http://localhost:3000';
  static const String health = '/health';
  static const String companies = '/api/v1/companies';
  static String companyById(String id) => '/api/v1/companies/$id';
}
