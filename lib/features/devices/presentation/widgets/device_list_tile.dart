import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/device_model.dart';

/// Reusable device list item representing a registered receiver device.
class DeviceListTile extends StatelessWidget {
  const DeviceListTile({
    super.key,
    required this.device,
    this.isSelected = false,
    this.isCurrentDevice = false,
    this.onTap,
    this.showSelector = false,
    this.onSelectChanged,
    this.onDelete,
  });

  final DeviceModel device;
  final bool isSelected;
  final bool isCurrentDevice;
  final VoidCallback? onTap;
  final bool showSelector;
  final ValueChanged<bool?>? onSelectChanged;
  final VoidCallback? onDelete;

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _maskToken(String token) {
    if (token.isEmpty) return 'No token';
    if (token.length <= 10) return '••••••••';
    return '...${token.substring(token.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isSelected
        ? (isDark ? AppColors.primaryLight : AppColors.primary)
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    final bgColor = isSelected
        ? (isDark
              ? const Color(0xFF1E1B4B)
              : AppColors.primaryContainer.withAlpha(120))
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    return InkWell(
      onTap:
          onTap ??
          (showSelector ? () => onSelectChanged?.call(!isSelected) : null),
      borderRadius: AppRadius.medium,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: AppSpacing.p12,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.medium,
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            if (showSelector) ...[
              Checkbox(
                value: isSelected,
                onChanged: onSelectChanged,
                activeColor: isDark
                    ? AppColors.primaryLight
                    : AppColors.primary,
              ),
              AppSpacing.hSpace8,
            ],
            // Platform Device Icon
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                borderRadius: AppRadius.medium,
              ),
              child: Icon(
                device.platform.toLowerCase().contains('ios')
                    ? Icons.phone_iphone_rounded
                    : Icons.phone_android_rounded,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
                size: AppDimensions.iconMd,
              ),
            ),
            AppSpacing.hSpace12,
            // Device Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          device.deviceName,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentDevice) ...[
                        AppSpacing.hSpace8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(
                              isDark ? 60 : 30,
                            ),
                            borderRadius: AppRadius.circular,
                          ),
                          child: Text(
                            'This Device',
                            style: AppTextStyles.badge.copyWith(
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.vSpace4,
                  // Device ID Display
                  Text(
                    'ID: ${device.deviceId}',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vSpace4,
                  Row(
                    children: [
                      // Active indicator dot
                      Container(
                        width: AppDimensions.statusDotSize,
                        height: AppDimensions.statusDotSize,
                        decoration: BoxDecoration(
                          color: device.isActive
                              ? AppColors.success
                              : AppColors.disabled,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.hSpace4,
                      Text(
                        device.isActive ? 'Registered' : 'Inactive',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      AppSpacing.hSpace8,
                      Text(
                        '•',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                      AppSpacing.hSpace8,
                      Text(
                        _formatTime(device.lastSeenAt),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vSpace4,
                  // Masked Token Preview
                  Text(
                    'Token: ${_maskToken(device.fcmToken)}',
                    style: AppTextStyles.caption.copyWith(
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null && !isCurrentDevice) ...[
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 20.0,
                ),
                tooltip: 'Remove Device',
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
