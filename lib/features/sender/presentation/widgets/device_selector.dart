import 'package:flutter/material.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../devices/data/models/device_model.dart';
import '../../../devices/presentation/widgets/device_list_tile.dart';

/// Reusable device selection component supporting single and multi-device selection.
class DeviceSelector extends StatelessWidget {
  const DeviceSelector({
    super.key,
    required this.devices,
    required this.selectedDeviceIds,
    required this.onSelectionChanged,
    this.errorMessage,
  });

  final List<DeviceModel> devices;
  final Set<String> selectedDeviceIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final String? errorMessage;

  void _toggleDevice(String deviceId) {
    final updated = Set<String>.from(selectedDeviceIds);
    if (updated.contains(deviceId)) {
      updated.remove(deviceId);
    } else {
      updated.add(deviceId);
    }
    onSelectionChanged(updated);
  }

  void _selectAll() {
    final allIds = devices.map((d) => d.deviceId).toSet();
    onSelectionChanged(allIds);
  }

  void _clearSelection() {
    onSelectionChanged(<String>{});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDeviceId = FirebaseService.instance.installationId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count and Select All / Clear action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Target Devices',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                AppSpacing.hSpace8,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s2,
                  ),
                  decoration: BoxDecoration(
                    color: selectedDeviceIds.isEmpty
                        ? (isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariantLight)
                        : (isDark
                              ? AppColors.primaryContainer
                              : AppColors.primaryContainer),
                    borderRadius: AppRadius.circular,
                  ),
                  child: Text(
                    '${selectedDeviceIds.length} of ${devices.length} selected',
                    style: AppTextStyles.badge.copyWith(
                      color: selectedDeviceIds.isEmpty
                          ? (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondaryLight)
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (devices.isNotEmpty)
              Row(
                children: [
                  TextButton(
                    onPressed: selectedDeviceIds.length == devices.length
                        ? _clearSelection
                        : _selectAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      selectedDeviceIds.length == devices.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        AppSpacing.vSpace8,

        // Devices List
        if (devices.isEmpty)
          Container(
            width: double.infinity,
            padding: AppSpacing.p16,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: AppRadius.medium,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.phone_android_outlined,
                  size: AppDimensions.iconLg,
                  color: AppColors.textTertiaryLight,
                ),
                AppSpacing.vSpace8,
                Text(
                  'No Registered Devices Found',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                AppSpacing.vSpace4,
                Text(
                  'Receiver devices will show up here automatically when they open this app.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devices.length,
            separatorBuilder: (_, _) => AppSpacing.vSpace8,
            itemBuilder: (context, index) {
              final device = devices[index];
              final isSelected = selectedDeviceIds.contains(device.deviceId);

              return DeviceListTile(
                device: device,
                isSelected: isSelected,
                isCurrentDevice: device.deviceId == currentDeviceId,
                showSelector: true,
                onSelectChanged: (_) => _toggleDevice(device.deviceId),
              );
            },
          ),

        // Validation Error
        if (errorMessage != null) ...[
          AppSpacing.vSpace8,
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: AppDimensions.iconXs,
                color: AppColors.error,
              ),
              AppSpacing.hSpace4,
              Text(
                errorMessage!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
