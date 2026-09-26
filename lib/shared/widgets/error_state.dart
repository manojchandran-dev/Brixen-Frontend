import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';

/// The clean, user-facing message for an error — strips the
/// `ApiException(400): ` wrapper so screens never show a raw exception
/// string.
String errorMessage(Object error) =>
    error is ApiException ? error.message : error.toString();

/// A styled "something went wrong" card — drop in wherever a screen's data
/// failed to load, in place of a raw `Text(error.toString())`.
class ErrorCard extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  const ErrorCard({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.brandBlack.withValues(alpha: 0.15)),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandBlack.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.ink,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Something went wrong',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage(error),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textHint, fontSize: 12.5, height: 1.4),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    'Retry',
                    style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A modal alert dialog for one-off failures (e.g. a failed create/update
/// action) — styled like every other dialog in the app (rounded card,
/// single "OK" dismiss).
Future<void> showErrorDialog(BuildContext context, Object error) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.ink, size: 20),
          const SizedBox(width: 8),
          Text(
            'Something went wrong',
            style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Text(
        errorMessage(error),
        style: TextStyle(color: AppColors.textHint, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('OK', style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
