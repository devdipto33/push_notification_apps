import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../firebase_options.dart';
import '../../../devices/data/models/device_model.dart';
import '../../../devices/data/repositories/device_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../widgets/device_selector.dart';
import '../widgets/message_form.dart';

/// Primary screen for composing messages, selecting recipients, and dispatching push notifications.
class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});

  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  final DeviceRepository _deviceRepository = DeviceRepository();
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  final Set<String> _selectedDeviceIds = <String>{};
  String? _selectionError;
  bool _isSending = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _selectedDeviceIds.clear();
      _selectionError = null;
      _feedbackMessage = null;
    });
  }

  Future<void> _handleSend() async {
    // 1. Clear previous feedback
    setState(() {
      _feedbackMessage = null;
      _selectionError = null;
    });

    // 2. Validate form inputs
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final selectionError = Validators.validateDeviceSelection(
      _selectedDeviceIds.toList(),
    );

    if (!isFormValid || selectionError != null) {
      setState(() {
        _selectionError = selectionError;
      });
      return;
    }

    // 3. Confirm Firebase initialized
    if (!FirebaseService.instance.isFirebaseInitialized &&
        !DefaultFirebaseOptions.isConfigured) {
      setState(() {
        _feedbackIsError = true;
        _feedbackMessage = 'Firebase is not yet configured. Please run "flutterfire configure" or set your Firebase project credentials in firebase_options.dart.';
      });
      return;
    }

    // 4. Dispatch notification
    setState(() => _isSending = true);

    try {
      final result = await _notificationRepository.sendPushNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        targetDeviceIds: _selectedDeviceIds.toList(),
      );

      if (!mounted) return;

      setState(() {
        _feedbackIsError = !result.isSuccess;
        _feedbackMessage = result.message;
      });

      if (result.isSuccess) {
        // Clear message fields on successful delivery
        _titleController.clear();
        _bodyController.clear();
        _formKey.currentState?.reset();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                AppSpacing.hSpace12,
                Expanded(
                  child: Text(
                    'Notification sent to ${result.deliveredCount} device(s)!',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackIsError = true;
        _feedbackMessage = 'Failed to send notification: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: AppSpacing.p4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.small,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: AppDimensions.iconSm,
              ),
            ),
            AppSpacing.hSpace12,
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.devices_rounded),
            tooltip: 'View Registered Devices',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.devices),
          ),
        ],
      ),
      body: StreamBuilder<List<DeviceModel>>(
        stream: _deviceRepository.watchRegisteredDevices(),
        builder: (context, snapshot) {
          final isWaiting =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;

          final devices = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Configuration guidance notice if placeholder
                    if (!DefaultFirebaseOptions.isConfigured &&
                        !FirebaseService.instance.isFirebaseInitialized)
                      _buildSetupBanner(isDark),

                    // Delivery Feedback Banner
                    if (_feedbackMessage != null) ...[
                      _buildFeedbackBanner(isDark),
                      AppSpacing.vSpace16,
                    ],

                    // Message Composition Form
                    Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: MessageForm(
                        formKey: _formKey,
                        titleController: _titleController,
                        bodyController: _bodyController,
                        isSending: _isSending,
                        selectedDeviceCount: _selectedDeviceIds.length,
                        onSend: _handleSend,
                        onClear: _clearForm,
                      ),
                    ),
                    AppSpacing.vSpace24,

                    // Device Selection List
                    if (isWaiting)
                      const AppLoadingIndicator(message: 'Loading devices...')
                    else if (snapshot.hasError)
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: AppRadius.large,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: AppErrorView(
                          title: 'Restricted Access',
                          message:
                              snapshot.error.toString().contains(
                                'permission-denied',
                              )
                              ? 'Only authorized senders can view the device list and send notifications. Make sure your account UID is added to the "authorized_senders" collection in Firebase.'
                              : 'Could not load registered devices: ${snapshot.error}',
                          icon: Icons.lock_outline_rounded,
                        ),
                      )
                    else
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: AppRadius.large,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: DeviceSelector(
                          devices: devices,
                          selectedDeviceIds: _selectedDeviceIds,
                          errorMessage: _selectionError,
                          onSelectionChanged: (updated) {
                            setState(() {
                              _selectedDeviceIds
                                ..clear()
                                ..addAll(updated);
                              if (updated.isNotEmpty) {
                                _selectionError = null;
                              }
                            });
                          },
                        ),
                      ),
                    AppSpacing.vSpace32,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSetupBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s16),
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: AppColors.infoContainer.withAlpha(isDark ? 50 : 255),
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.info.withAlpha(100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: AppDimensions.iconSm,
          ),
          AppSpacing.hSpace12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firebase Setup Mode',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? const Color(0xFFBAE6FD)
                        : AppColors.onInfoContainer,
                  ),
                ),
                AppSpacing.vSpace4,
                Text(
                  'Connect your Firebase project using "flutterfire configure" and deploy Cloud Functions to send live notifications across devices. See README.md for step-by-step commands.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? const Color(0xFFBAE6FD)
                        : AppColors.onInfoContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner(bool isDark) {
    final isError = _feedbackIsError;
    final color = isError ? AppColors.error : AppColors.success;
    final containerColor = isError
        ? AppColors.errorContainer
        : AppColors.successContainer;
    final textColor = isError
        ? (isDark ? const Color(0xFFFCA5A5) : AppColors.onErrorContainer)
        : (isDark ? const Color(0xFF86EFAC) : AppColors.onSuccessContainer);

    return Container(
      padding: AppSpacing.p12,
      decoration: BoxDecoration(
        color: containerColor.withAlpha(isDark ? 50 : 255),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: AppDimensions.iconSm,
          ),
          AppSpacing.hSpace12,
          Expanded(
            child: Text(
              _feedbackMessage ?? '',
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: AppDimensions.iconSm),
            color: color,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _feedbackMessage = null),
          ),
        ],
      ),
    );
  }
}
