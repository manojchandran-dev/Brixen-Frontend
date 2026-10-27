import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/permissions/presentation/providers/module_access_provider.dart';

/// Shows [child] only to a user who may view [module] — for every route that
/// opens a module, so a typed or saved URL can't open a screen the menu
/// hides. The server refuses the data too (permission.middleware); this
/// keeps the app from showing an empty screen of errors instead.
class ModuleGuard extends ConsumerWidget {
  /// The module's name as the modules API spells it, e.g. 'Sales'.
  final String module;
  final Widget child;
  const ModuleGuard({super.key, required this.module, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(moduleAccessReadyProvider)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (ref.watch(moduleAccessProvider(module)).view) return child;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 52,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 14),
              Text(
                'No access to $module',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ask your company admin if you need it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.go(AppRouter.dashboard),
                child: const Text('Go to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
