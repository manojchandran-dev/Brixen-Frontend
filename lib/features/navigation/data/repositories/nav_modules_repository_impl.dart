import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/nav_module.dart';
import '../../domain/repositories/nav_modules_repository.dart';
import '../datasources/nav_modules_remote_datasource.dart';

final navModulesRepositoryProvider = Provider<NavModulesRepository>((ref) {
  return NavModulesRepositoryImpl(ref.read(navModulesRemoteDatasourceProvider));
});

class NavModulesRepositoryImpl implements NavModulesRepository {
  final NavModulesRemoteDatasource _ds;
  const NavModulesRepositoryImpl(this._ds);

  @override
  Future<List<NavModule>> getModules() => _ds.getModules();
}
