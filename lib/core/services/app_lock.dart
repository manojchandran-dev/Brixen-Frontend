import 'package:flutter/widgets.dart';
import '../../features/security/presentation/cubit/security_cubit.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import 'token_service.dart';

/// Locks the app again (PIN / fingerprint) when it comes back to the
/// foreground after being away for [awayLimit] or longer. Until now the lock
/// screen only showed on a cold start, so returning from the background
/// never asked for the fingerprint.
///
/// The lock screen is pushed over the current page, and unlocking pops it,
/// so the user lands back where they were. Short trips away — picking a
/// photo, the fingerprint dialog itself — stay under the limit.
class AppLock with WidgetsBindingObserver {
  AppLock._();
  static final instance = AppLock._();

  static const awayLimit = Duration(seconds: 30);

  /// Pages that are themselves part of signing in / unlocking.
  static const _unlockedPages = {
    RouteNames.splash,
    RouteNames.signIn,
    RouteNames.signUp,
    RouteNames.forgotPassword,
    RouteNames.lockScreen,
    RouteNames.pinSetup,
  };

  DateTime? _leftAt;
  bool _showing = false;

  bool _started = false;

  /// Once: the app root can be rebuilt (a new one per signed-in account).
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _leftAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final leftAt = _leftAt;
        _leftAt = null;
        if (leftAt != null && DateTime.now().difference(leftAt) >= awayLimit) {
          _lock();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _lock() async {
    if (_showing || !TokenService.isLoggedIn) return;
    if (!await securityCubit.isLockActive()) return;
    final path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    if (_unlockedPages.contains(path)) return;
    _showing = true;
    try {
      await AppRouter.router.push<void>(RouteNames.lockScreen, extra: true);
    } finally {
      _showing = false;
    }
  }
}
