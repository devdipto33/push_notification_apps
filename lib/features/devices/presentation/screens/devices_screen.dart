import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../data/models/device_model.dart';
import '../../data/repositories/device_repository.dart';
import '../widgets/device_list_tile.dart';

/// Screen displaying all registered receiver devices and current local device status.
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final DeviceRepository _deviceRepository = DeviceRepository();
  bool _isReRegistering = false;

  Future<void> _refreshDeviceRegistration() async {
    setState(() => _isReRegistering = true);
    try {
      final fcmToken = await FcmService.instance.getFcmToken();
      final deviceId = FirebaseService.instance.installationId;
      final deviceName =
          FirebaseService.instance.deviceName ?? 'Android Device';

      if (deviceId != null && fcmToken != null) {
        await _deviceRepository.registerOrUpdateDevice(
          deviceId: deviceId,
          fcmToken: fcmToken,
          deviceName: deviceName,
          platform: 'Android',
          osVersion: 'Android',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Device registration and token refreshed successfully!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'FCM token not available yet. Please run "flutterfire configure" to link your Firebase project.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh registration: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDeviceId = FirebaseService.instance.installationId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Device by ID',
            onPressed: _showAddDeviceDialog,
          ),
          IconButton(
            icon: _isReRegistering
                ? const SizedBox(
                    width: AppDimensions.loaderSm,
                    height: AppDimensions.loaderSm,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Re-register / Refresh Token',
            onPressed: _isReRegistering ? null : _refreshDeviceRegistration,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDeviceDialog,
        icon: const Icon(Icons.phonelink_setup_rounded),
        label: const Text('Add Device by ID'),
        backgroundColor: isDark ? AppColors.primary : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DeviceModel>>(
        stream: _deviceRepository.watchRegisteredDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(
              message: 'Loading registered devices...',
            );
          }

          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Could not load devices',
              message: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          final devices = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.s16,
              right: AppSpacing.s16,
              top: AppSpacing.s16,
              bottom: 88.0, // Space for FAB
            ),
            children: [
              // Current Local Device Card
              _buildCurrentDeviceCard(isDark, currentDeviceId),
              AppSpacing.vSpace20,

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Registered Receivers (${devices.length})',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Device'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _showAddDeviceDialog,
                  ),
                ],
              ),
              AppSpacing.vSpace12,

              if (devices.isEmpty)
                Container(
                  padding: AppSpacing.p20,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.devices_other_rounded,
                        size: AppDimensions.iconXl,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      AppSpacing.vSpace12,
                      Text(
                        'No Registered Devices Yet',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      AppSpacing.vSpace8,
                      Text(
                        'Open the app on another phone or tap "+ Add Device" to register devices using their Device ID.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.vSpace16,
                      Wrap(
                        spacing: AppSpacing.s12,
                        runSpacing: AppSpacing.s8,
                        alignment: WrapAlignment.center,
                        children: [
                          AppButton(
                            text: 'Register This Device',
                            icon: Icons.app_registration_rounded,
                            variant: AppButtonVariant.primary,
                            isFullWidth: false,
                            isLoading: _isReRegistering,
                            onPressed: _refreshDeviceRegistration,
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add by Device ID'),
                            onPressed: _showAddDeviceDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                ...devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: DeviceListTile(
                      device: device,
                      isCurrentDevice: device.deviceId == currentDeviceId,
                      onDelete: device.deviceId == currentDeviceId
                          ? null
                          : () => _confirmDeleteDevice(device),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteDevice(DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device?'),
        content: Text(
          'Are you sure you want to remove "${device.deviceName}" from registered receivers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              await _deviceRepository.removeDevice(device.deviceId);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Device "${device.deviceName}" removed.'),
                    backgroundColor: AppColors.textPrimaryLight,
                  ),
                );
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final tokenController = TextEditingController();
    String selectedPlatform = 'Android';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 80 : 30),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: AppSpacing.s16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: AppSpacing.p12,
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary)
                                    .withAlpha(30),
                                borderRadius: AppRadius.medium,
                              ),
                              child: Icon(
                                Icons.phonelink_setup_rounded,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                size: 24,
                              ),
                            ),
                            AppSpacing.hSpace12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add Receiver Device',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Register another device using its Device ID',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vSpace16,

                        // Quick suggestion for detected Samsung A16
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.s12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1B4B)
                                : AppColors.primaryContainer.withAlpha(140),
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.primaryLight.withAlpha(40)
                                  : AppColors.primary.withAlpha(30),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              AppSpacing.hSpace8,
                              Expanded(
                                child: Text(
                                  'Detected ADB: Samsung A16 (SM-A166P)',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    final now = DateTime.now()
                                        .millisecondsSinceEpoch;
                                    idController.text =
                                        'dev_sma166p_${(now ^ 0x5DEECE66D).toRadixString(16)}';
                                    nameController.text =
                                        'Samsung Galaxy A16 (SM-A166P)';
                                    selectedPlatform = 'Android';
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Auto-fill'),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.vSpace16,

                        // Device ID Field (Required)
                        Text(
                          'Device ID *',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.vSpace8,
                        TextFormField(
                          controller: idController,
                          decoration: InputDecoration(
                            hintText: 'e.g. dev_1792179522492_1a49...',
                            prefixIcon: const Icon(
                              Icons.fingerprint_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.content_paste_rounded,
                                size: 20,
                              ),
                              tooltip: 'Paste from clipboard',
                              onPressed: () async {
                                final data = await Clipboard.getData(
                                  Clipboard.kTextPlain,
                                );
                                if (data?.text != null &&
                                    data!.text!.trim().isNotEmpty) {
                                  setModalState(() {
                                    idController.text = data.text!.trim();
                                  });
                                }
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a Device ID';
                            }
                            if (value.trim().length < 4) {
                              return 'Device ID must be at least 4 characters';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.vSpace16,

                        // Device Name Field
                        Text(
                          'Device Name / Model',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.vSpace8,
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Samsung Galaxy A16, Office Tablet',
                            prefixIcon: Icon(
                              Icons.phone_android_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        AppSpacing.vSpace16,

                        // Platform Choice
                        Text(
                          'Platform',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.vSpace8,
                        Row(
                          children: ['Android', 'iOS', 'Web'].map((platform) {
                            final isSelected = selectedPlatform == platform;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(platform),
                                selected: isSelected,
                                selectedColor: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setModalState(
                                      () => selectedPlatform = platform,
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        AppSpacing.vSpace16,

                        // Optional Token Field
                        Text(
                          'FCM Token (Optional)',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.vSpace8,
                        TextFormField(
                          controller: tokenController,
                          decoration: InputDecoration(
                            hintText: 'Optional push token or leave blank',
                            prefixIcon: const Icon(
                              Icons.vpn_key_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.content_paste_rounded,
                                size: 20,
                              ),
                              tooltip: 'Paste token',
                              onPressed: () async {
                                final data = await Clipboard.getData(
                                  Clipboard.kTextPlain,
                                );
                                if (data?.text != null &&
                                    data!.text!.trim().isNotEmpty) {
                                  setModalState(() {
                                    tokenController.text = data.text!.trim();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        AppSpacing.vSpace24,

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            AppSpacing.hSpace12,
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Device'),
                                onPressed: () async {
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    final deviceId = idController.text.trim();
                                    final deviceName = nameController.text
                                            .trim()
                                            .isNotEmpty
                                        ? nameController.text.trim()
                                        : 'Remote $selectedPlatform Device';
                                    final token = tokenController.text.trim();

                                    final messenger = ScaffoldMessenger.of(context);
                                    Navigator.of(context).pop();

                                    await _deviceRepository.addDeviceManually(
                                      deviceId: deviceId,
                                      deviceName: deviceName,
                                      fcmToken:
                                          token.isNotEmpty ? token : null,
                                      platform: selectedPlatform,
                                    );

                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Device "$deviceName" added successfully!',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentDeviceCard(bool isDark, String? currentDeviceId) {
    final deviceName = FirebaseService.instance.deviceName ?? 'Current Device';
    final hasToken = FcmService.instance.currentToken != null;

    return Container(
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1B4B)
            : AppColors.primaryContainer.withAlpha(160),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark
              ? AppColors.primaryLight.withAlpha(60)
              : AppColors.primary.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: AppSpacing.p8,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryLight.withAlpha(40)
                      : AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: AppDimensions.iconSm,
                ),
              ),
              AppSpacing.hSpace12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Physical Device',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      deviceName,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s4,
                ),
                decoration: BoxDecoration(
                  color: hasToken
                      ? AppColors.successContainer
                      : AppColors.warningContainer,
                  borderRadius: AppRadius.circular,
                ),
                child: Text(
                  hasToken ? 'FCM Active' : 'No Token',
                  style: AppTextStyles.badge.copyWith(
                    color: hasToken
                        ? AppColors.onSuccessContainer
                        : AppColors.onWarningContainer,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpace12,
          Text(
            'Device ID: ${currentDeviceId ?? 'Resolving...'}',
            style: AppTextStyles.caption.copyWith(
              fontFamily: 'monospace',
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
