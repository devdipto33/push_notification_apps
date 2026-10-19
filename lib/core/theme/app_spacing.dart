import 'package:flutter/material.dart';

/// Centralized spacing system adhering to an 4-point/8-point grid scale.
abstract final class AppSpacing {
  // Numeric spacing tokens
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // Semantic aliases
  static const double xs = s4;
  static const double sm = s8;
  static const double md = s16;
  static const double lg = s24;
  static const double xl = s32;

  // EdgeInsets presets
  static const EdgeInsets zero = EdgeInsets.zero;

  // All sides
  static const EdgeInsets p4 = EdgeInsets.all(s4);
  static const EdgeInsets p8 = EdgeInsets.all(s8);
  static const EdgeInsets p12 = EdgeInsets.all(s12);
  static const EdgeInsets p16 = EdgeInsets.all(s16);
  static const EdgeInsets p20 = EdgeInsets.all(s20);
  static const EdgeInsets p24 = EdgeInsets.all(s24);
  static const EdgeInsets p32 = EdgeInsets.all(s32);

  // Symmetric Horizontal
  static const EdgeInsets px8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets px12 = EdgeInsets.symmetric(horizontal: s12);
  static const EdgeInsets px16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets px20 = EdgeInsets.symmetric(horizontal: s20);
  static const EdgeInsets px24 = EdgeInsets.symmetric(horizontal: s24);

  // Symmetric Vertical
  static const EdgeInsets py4 = EdgeInsets.symmetric(vertical: s4);
  static const EdgeInsets py8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets py12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets py16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets py20 = EdgeInsets.symmetric(vertical: s20);

  // Common UI Patterns
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s16,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(s16);
  static const EdgeInsets dialogPadding = EdgeInsets.all(s24);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: s20,
    vertical: s12,
  );

  // Vertical SizedBox Spacers
  static const SizedBox vSpace4 = SizedBox(height: s4);
  static const SizedBox vSpace8 = SizedBox(height: s8);
  static const SizedBox vSpace12 = SizedBox(height: s12);
  static const SizedBox vSpace16 = SizedBox(height: s16);
  static const SizedBox vSpace20 = SizedBox(height: s20);
  static const SizedBox vSpace24 = SizedBox(height: s24);
  static const SizedBox vSpace32 = SizedBox(height: s32);
  static const SizedBox vSpace48 = SizedBox(height: s48);

  // Horizontal SizedBox Spacers
  static const SizedBox hSpace4 = SizedBox(width: s4);
  static const SizedBox hSpace8 = SizedBox(width: s8);
  static const SizedBox hSpace12 = SizedBox(width: s12);
  static const SizedBox hSpace16 = SizedBox(width: s16);
  static const SizedBox hSpace20 = SizedBox(width: s20);
  static const SizedBox hSpace24 = SizedBox(width: s24);
}
