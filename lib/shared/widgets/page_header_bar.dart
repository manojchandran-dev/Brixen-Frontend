import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A hamburger (opens the drawer) + the current page's name — the same
/// header shape every tab needs when its body has no header of its own.
/// Used by Report/More (their bodies are shared across roles and have
/// none), matching the header `WelcomeDashboardView` builds for Dashboard.
class PageHeaderBar extends StatelessWidget {
  final String title;
  const PageHeaderBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.shadows([
                    BoxShadow(
                      color: AppColors.shadowDark.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]),
                ),
                child: Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
