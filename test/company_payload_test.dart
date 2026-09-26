import 'package:brixen/features/companies/data/datasources/companies_remote_datasource.dart';
import 'package:brixen/features/companies/data/models/company_model.dart';
import 'package:brixen/features/companies/data/repositories/companies_repository_impl.dart';
import 'package:brixen/features/companies/domain/entities/company.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the create body instead of calling the API.
class _CapturingDs extends CompaniesRemoteDatasource {
  Map<String, dynamic>? body;
  _CapturingDs() : super(Dio());

  @override
  Future<CompanyModel> createCompany(Map<String, dynamic> body) async {
    this.body = body;
    return CompanyModel(id: '1', name: 'x', ownerName: '', createdAt: DateTime(2026));
  }
}

void main() {
  test('create sends the company category id and name, no entity_type', () async {
    final ds = _CapturingDs();
    await CompaniesRepositoryImpl(ds).createCompany(Company(
      id: '',
      name: 'Kaveri Textiles',
      ownerName: '',
      industryType: 'Textiles',
      companyCategoryId: 'COCAT65618502479',
      logoUrl: 'https://cdn.example/logo.png',
      galleryUrls: const ['https://cdn.example/a.png', 'https://cdn.example/b.png'],
      createdAt: DateTime(2026),
    ));

    expect(ds.body, containsPair('company_category_id', 'COCAT65618502479'));
    expect(ds.body, containsPair('company_category_name', 'Textiles'));
    expect(ds.body, containsPair('industry_type', 'Textiles'));
    expect(ds.body!.containsKey('entity_type'), isFalse);
    expect(ds.body, containsPair('logo_url', 'https://cdn.example/logo.png'));
    expect(ds.body, containsPair('gallery_urls', ['https://cdn.example/a.png', 'https://cdn.example/b.png']));
  });

  test('a removed logo (empty string) is sent as null so it clears', () async {
    final ds = _CapturingDs();
    await CompaniesRepositoryImpl(ds).createCompany(Company(id: '', name: 'x', ownerName: '', logoUrl: '', createdAt: DateTime(2026)));
    expect(ds.body, containsPair('logo_url', null));
    expect(ds.body, containsPair('gallery_urls', <String>[]));
  });
}
