import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Centralized border definitions for text fields, cards, chips, and outlines.
abstract final class AppBorders {
  // Border Sides
  static const BorderSide none = BorderSide.none;

  static const BorderSide thinLight = BorderSide(
    color: AppColors.borderLight,
    width: 1.0,
  );

  static const BorderSide thinDark = BorderSide(
    color: AppColors.borderDark,
    width: 1.0,
  );

  static const BorderSide focusedLight = BorderSide(
    color: AppColors.borderFocusedLight,
    width: 1.5,
  );

  static const BorderSide focusedDark = BorderSide(
    color: AppColors.borderFocusedDark,
    width: 1.5,
  );

  static const BorderSide errorSide = BorderSide(
    color: AppColors.error,
    width: 1.0,
  );

  // Input Borders - Light
  static final OutlineInputBorder inputEnabledLight = OutlineInputBorder(
    borderRadius: AppRadius.medium,
    borderSide: thinLight,
  );

  static final OutlineInputBorder inputFocusedLight = OutlineInputBorder(
    borderRadius: AppRadius.medium,
    borderSide: focusedLight,
  );

  static final OutlineInputBorder inputErrorLight = OutlineInputBorder(
    borderRadius: AppRadius.medium,
    borderSide: errorSide,
  );

  // Input Borders - Dark
  static final OutlineInputBorder inputEnabledDark = OutlineInputBorder(
    borderRadius: AppRadius.medium,
    borderSide: thinDark,
  );

  static final OutlineInputBorder inputFocusedDark = OutlineInputBorder(
    borderRadius: AppRadius.medium,
    borderSide: focusedDark,
  );

  static final OutlineInputBorder inputErrorDark = OutlineInputBorder(
    borderRadius: AppRadius.medium,
    borderSide: errorSide,
  );

  // Card Borders
  static final Border cardBorderLight = Border.all(
    color: AppColors.borderLight,
    width: 1.0,
  );

  static final Border cardBorderDark = Border.all(
    color: AppColors.borderDark,
    width: 1.0,
  );

  static final Border cardActiveBorderLight = Border.all(
    color: AppColors.primary,
    width: 1.5,
  );

  static final Border cardActiveBorderDark = Border.all(
    color: AppColors.primaryLight,
    width: 1.5,
  );
}
