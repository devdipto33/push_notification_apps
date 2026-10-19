import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Reusable error and empty state view with retry button.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.title = 'Something Went Wrong',
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = Icons.error_outline_rounded,
    this.isCompact = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCompact) {
      return Container(
        padding: AppSpacing.p12,
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withAlpha(isDark ? 50 : 255),
          borderRadius: AppRadius.medium,
          border: Border.all(color: AppColors.error.withAlpha(80)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: AppDimensions.iconSm,
            ),
            AppSpacing.hSpace12,
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? const Color(0xFFFCA5A5)
                      : AppColors.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null) ...[
              AppSpacing.hSpace8,
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: AppDimensions.iconSm,
                ),
                color: AppColors.error,
                onPressed: onRetry,
                tooltip: retryLabel,
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: AppSpacing.p16,
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withAlpha(isDark ? 60 : 255),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.error,
                size: AppDimensions.iconXl,
              ),
            ),
            AppSpacing.vSpace16,
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vSpace8,
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.vSpace24,
              AppButton(
                text: retryLabel,
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.outlined,
                isFullWidth: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
