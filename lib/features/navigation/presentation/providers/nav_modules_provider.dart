import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../data/datasources/nav_modules_remote_datasource.dart';
import '../../data/repositories/nav_modules_repository_impl.dart';
import '../../domain/entities/nav_module.dart';

/// Exposes [authCubit]'s state to Riverpod purely so [navModulesProvider]
/// can depend on it below — `GET /modules` is scoped by `Session.role`/
/// `companyId`/`employeeId` at call time, but a plain [FutureProvider]
/// caches its result for the app's whole lifetime otherwise. Without this,
/// signing out and into a *different* account (different company, or a
/// more/less restricted one) would keep showing the previous session's
/// cached drawer menu instead of re-fetching it. `signIn()`/`signOut()`
/// always pass through a distinct state (e.g. AuthLoading) before landing
/// on the next one, so every real sign-in/out transition is a fresh value
/// here — driving `navModulesProvider` to refetch right along with it.
final authStateProvider = StreamProvider<AuthState>((ref) => authCubit.stream);

/// Read-only fetch of the app's menu tree — no create/update/delete exists
/// server-side, so a plain [FutureProvider] is enough.
final navModulesProvider = FutureProvider<List<NavModule>>((ref) {
  ref.watch(authStateProvider);
  return ref.read(navModulesRepositoryProvider).getModules();
});

/// Modules a superadmin can grant a company (Permissions screen) — not the
/// superadmin's own menu, which [navModulesProvider] returns.
final grantableModulesProvider = FutureProvider<List<NavModule>>((ref) {
  ref.watch(authStateProvider);
  return ref.read(navModulesRemoteDatasourceProvider).getGrantableModules();
});
