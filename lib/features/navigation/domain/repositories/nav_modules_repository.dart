import '../entities/nav_module.dart';

abstract class NavModulesRepository {
  Future<List<NavModule>> getModules();
}
