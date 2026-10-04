import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Body of the Push Notifications / Announcements pages for anyone who
/// isn't superadmin: those pages send to companies, so a company admin gets
/// this instead of the tools (the page keeps its header, menu and nav).
class AdminOnlyNotice extends StatelessWidget {
  final String what;
  const AdminOnlyNotice({super.key, required this.what});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brand.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.brand,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$what are sent by Brixen',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Only the Brixen super admin can create and manage these.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
