import 'package:flutter/material.dart';

/// Centralized border radii values for consistent rounding across the app.
abstract final class AppRadius {
  // Raw Radius values
  static const double smValue = 6.0;
  static const double mdValue = 12.0;
  static const double lgValue = 16.0;
  static const double xlValue = 24.0;
  static const double fullValue = 999.0;

  // Radius objects
  static const Radius smRadius = Radius.circular(smValue);
  static const Radius mdRadius = Radius.circular(mdValue);
  static const Radius lgRadius = Radius.circular(lgValue);
  static const Radius xlRadius = Radius.circular(xlValue);
  static const Radius fullRadius = Radius.circular(fullValue);

  // BorderRadius objects
  static const BorderRadius small = BorderRadius.all(smRadius);
  static const BorderRadius medium = BorderRadius.all(mdRadius);
  static const BorderRadius large = BorderRadius.all(lgRadius);
  static const BorderRadius extraLarge = BorderRadius.all(xlRadius);
  static const BorderRadius circular = BorderRadius.all(fullRadius);

  // Top / Bottom specific
  static const BorderRadius topMedium = BorderRadius.vertical(top: mdRadius);
  static const BorderRadius bottomMedium = BorderRadius.vertical(
    bottom: mdRadius,
  );
  static const BorderRadius topLarge = BorderRadius.vertical(top: lgRadius);
  static const BorderRadius bottomLarge = BorderRadius.vertical(
    bottom: lgRadius,
  );
}
