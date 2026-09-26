import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'confirm_dialog.dart';

/// Wraps a screen that can be the bottom of the navigation stack
/// (Dashboard, Sign-in, Lock, PIN setup). When it IS the bottom, back/swipe
/// asks "Exit Brixen?" instead of closing the app; when it was pushed on
/// top of something (e.g. Sign-in from "Add account"), back works normally.
///
/// A PopScope (not a back-button hook) so it also works with Android's
/// predictive back, where the OS closes the app itself if no route claims
/// the gesture.
class ExitGuard extends StatelessWidget {
  final Widget child;
  const ExitGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isRoot = ModalRoute.of(context)?.isFirst ?? true;
    return PopScope(
      canPop: !isRoot,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await showConfirmDialog(
          context,
          title: 'Exit Brixen?',
          message: 'Are you sure you want to exit the app?',
          confirmLabel: 'Exit',
          isDestructive: true,
        );
        if (exit) await SystemNavigator.pop();
      },
      child: child,
    );
  }
}
