import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Form component for composing and submitting push notification messages.
class MessageForm extends StatelessWidget {
  const MessageForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.bodyController,
    required this.isSending,
    required this.selectedDeviceCount,
    required this.onSend,
    required this.onClear,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final bool isSending;
  final int selectedDeviceCount;
  final VoidCallback onSend;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Clear Form
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notification Content',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              TextButton.icon(
                onPressed: isSending ? null : onClear,
                icon: const Icon(
                  Icons.clear_all_rounded,
                  size: AppDimensions.iconSm,
                ),
                label: const Text('Clear Form'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondaryLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpace8,

          // Message Title Field
          AppTextField(
            label: 'Message Title',
            controller: titleController,
            hint: 'e.g. Server Alert, Meeting Reminder',
            maxLength: AppConstants.maxTitleLength,
            prefixIcon: const Icon(
              Icons.title_rounded,
              size: AppDimensions.iconSm,
            ),
            validator: Validators.validateTitle,
            textInputAction: TextInputAction.next,
            enabled: !isSending,
          ),
          AppSpacing.vSpace16,

          // Message Body Field
          AppTextField(
            label: 'Message Body',
            controller: bodyController,
            hint: 'Enter your push notification message content here...',
            minLines: 3,
            maxLines: 5,
            maxLength: AppConstants.maxBodyLength,
            prefixIcon: const Icon(
              Icons.message_outlined,
              size: AppDimensions.iconSm,
            ),
            validator: Validators.validateBody,
            textInputAction: TextInputAction.done,
            enabled: !isSending,
          ),
          AppSpacing.vSpace20,

          // Send Action Button
          AppButton(
            text: selectedDeviceCount > 0
                ? 'Send Push to $selectedDeviceCount Device${selectedDeviceCount > 1 ? "s" : ""}'
                : 'Send Notification',
            icon: Icons.send_rounded,
            isLoading: isSending,
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
