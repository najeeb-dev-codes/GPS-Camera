


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Poppins-based type scale, matched against the mockup text sizes:
///
/// | Token       | Size | Weight    | Used for                              |
/// |-------------|------|-----------|----------------------------------------|
/// | display     | 26   | Bold      | "Capture proof with place & time"      |
/// | h1          | 20   | Bold      | Screen titles ("Photo Saved", totals)  |
/// | h2          | 18   | SemiBold  | Top bar titles, section headers        |
/// | h3          | 16   | SemiBold  | Card titles, list section labels       |
/// | bodyMedium  | 14   | Medium    | Buttons, emphasized list text          |
/// | body        | 14   | Regular   | Standard body / description text       |
/// | caption     | 12   | Regular   | Subtitles, timestamps, helper text     |
/// | tiny        | 10   | Regular   | GPS stamp meta text, nav bar labels    |
/// | stampLabel  | 11   | Medium    | GPS stamp address/coords on photo      |
abstract final class AppTypography {
  static TextStyle _poppins(
    double size,
    FontWeight weight,
    double lineHeight, {
    Color color = AppColors.textPrimary,
    double? letterSpacing,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        height: lineHeight / size,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// "Capture proof with place & time" — Welcome screen hero text.
  static TextStyle get display => _poppins(26, FontWeight.w700, 32);

  static TextStyle get h1 => _poppins(20, FontWeight.w700, 26);
  static TextStyle get h2 => _poppins(18, FontWeight.w600, 24);
  static TextStyle get h3 => _poppins(16, FontWeight.w600, 22);

  static TextStyle get bodyMedium => _poppins(14, FontWeight.w500, 20);
  static TextStyle get body => _poppins(14, FontWeight.w400, 20);

  static TextStyle get caption =>
      _poppins(12, FontWeight.w400, 16, color: AppColors.textSecondary);

  /// Smallest label — bottom nav labels, dense meta rows.
  static TextStyle get tiny =>
      _poppins(10, FontWeight.w400, 13, color: AppColors.textSecondary);

  /// GPS stamp text overlaid on photos (address, coordinates, date/time).
  /// Slightly tighter line-height since it's stacked densely on an image.
  static TextStyle get stampLabel =>
      _poppins(11, FontWeight.w500, 15, color: AppColors.textOnDark);

  /// Small uppercase-style tag text, e.g. "Sponsored", "Advertisement".
  static TextStyle get overline => _poppins(
        10,
        FontWeight.w600,
        13,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      );

  /// Builds a Material [TextTheme] so framework widgets inherit Poppins too.
  static TextTheme get textTheme => TextTheme(
        displayLarge: display,
        titleLarge: h1,
        titleMedium: h2,
        titleSmall: h3,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: bodyMedium,
        labelSmall: tiny,
      );
}