import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger }

/// Reusable application button with loading state, icons, and theme adherence.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = AppDimensions.buttonHeightMd,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final childWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              width: AppDimensions.loaderSm,
              height: AppDimensions.loaderSm,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  variant == AppButtonVariant.outlined ||
                          variant == AppButtonVariant.text
                      ? theme.colorScheme.primary
                      : Colors.white,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppDimensions.iconSm),
                  AppSpacing.hSpace8,
                ],
                Text(text, style: AppTextStyles.button),
              ],
            ),
    );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.primary.withAlpha(128),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
            elevation: 0,
            minimumSize: Size(isFullWidth ? double.infinity : 88.0, height),
          ),
          child: childWidget,
        );
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
            foregroundColor: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
            elevation: 0,
            minimumSize: Size(isFullWidth ? double.infinity : 88.0, height),
          ),
          child: childWidget,
        );
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.0,
            ),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
            minimumSize: Size(isFullWidth ? double.infinity : 88.0, height),
          ),
          child: childWidget,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
            minimumSize: Size(isFullWidth ? double.infinity : 88.0, height),
          ),
          child: childWidget,
        );
      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
            elevation: 0,
            minimumSize: Size(isFullWidth ? double.infinity : 88.0, height),
          ),
          child: childWidget,
        );
    }

    if (!isFullWidth) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}
