import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Custom theme extension for application-specific semantic styles.
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  const AppCustomColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.deviceCardBg,
    required this.deviceCardBorder,
    required this.deviceCardActiveBg,
    required this.deviceCardActiveBorder,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color deviceCardBg;
  final Color deviceCardBorder;
  final Color deviceCardActiveBg;
  final Color deviceCardActiveBorder;

  static const AppCustomColors light = AppCustomColors(
    success: AppColors.success,
    successContainer: AppColors.successContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    onWarningContainer: AppColors.onWarningContainer,
    info: AppColors.info,
    infoContainer: AppColors.infoContainer,
    onInfoContainer: AppColors.onInfoContainer,
    deviceCardBg: AppColors.surfaceLight,
    deviceCardBorder: AppColors.borderLight,
    deviceCardActiveBg: AppColors.primaryContainer,
    deviceCardActiveBorder: AppColors.primary,
  );

  static const AppCustomColors dark = AppCustomColors(
    success: AppColors.success,
    successContainer: Color(0xFF064E3B),
    onSuccessContainer: Color(0xFFA7F3D0),
    warning: AppColors.warning,
    warningContainer: Color(0xFF78350F),
    onWarningContainer: Color(0xFFFDE68A),
    info: AppColors.info,
    infoContainer: Color(0xFF0C4A6E),
    onInfoContainer: Color(0xFFBAE6FD),
    deviceCardBg: AppColors.surfaceDark,
    deviceCardBorder: AppColors.borderDark,
    deviceCardActiveBg: Color(0xFF312E81),
    deviceCardActiveBorder: AppColors.primaryLight,
  );

  @override
  ThemeExtension<AppCustomColors> copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? deviceCardBg,
    Color? deviceCardBorder,
    Color? deviceCardActiveBg,
    Color? deviceCardActiveBorder,
  }) {
    return AppCustomColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      deviceCardBg: deviceCardBg ?? this.deviceCardBg,
      deviceCardBorder: deviceCardBorder ?? this.deviceCardBorder,
      deviceCardActiveBg: deviceCardActiveBg ?? this.deviceCardActiveBg,
      deviceCardActiveBorder:
          deviceCardActiveBorder ?? this.deviceCardActiveBorder,
    );
  }

  @override
  ThemeExtension<AppCustomColors> lerp(
    covariant ThemeExtension<AppCustomColors>? other,
    double t,
  ) {
    if (other is! AppCustomColors) {
      return this;
    }
    return AppCustomColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      deviceCardBg: Color.lerp(deviceCardBg, other.deviceCardBg, t)!,
      deviceCardBorder: Color.lerp(
        deviceCardBorder,
        other.deviceCardBorder,
        t,
      )!,
      deviceCardActiveBg: Color.lerp(
        deviceCardActiveBg,
        other.deviceCardActiveBg,
        t,
      )!,
      deviceCardActiveBorder: Color.lerp(
        deviceCardActiveBorder,
        other.deviceCardActiveBorder,
        t,
      )!,
    );
  }
}
