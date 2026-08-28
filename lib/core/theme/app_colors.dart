






import 'package:flutter/material.dart';

/// Central color tokens for GeoStamp Camera, derived directly from the
/// mockups (Welcome, Permissions, Home, Live Camera, Capture Preview,
/// Stamp Templates, Settings, Ads).
///
/// Never hard-code a `Color(...)` in a widget — reference a token here so
/// theming stays consistent and can be re-skinned from one place.
abstract final class AppColors {
  // ---- Primary (violet/purple — Get Started, Allow & Continue, Save
  // Photo, Save Style, all primary CTAs, selected template outline) ----
  static const Color primary = Color(0xFF6D28D9);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primarySurface = Color(0xFFF3EEFD);

  // ---- Header / dark camera surfaces ----
  // Live Camera screen background + translucent toolbar/stamp chips.
  static const Color cameraBackground = Color(0xFF0B0B0F);
  static const Color cameraOverlay = Color(0xB3111827); // ~70% black, for GPS stamp / toolbar chips
  static const Color headerDark = Color(0xFF111827);

  // ---- Secondary / accents ----
  static const Color green = Color(0xFF16A34A);
  static const Color orange = Color(0xFFF59E0B);
  static const Color amber = Color(0xFFEAB308); // Ads "Sponsored" tag tint
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF2563EB); // used sparingly (e.g. maps / links)
  static const Color pink = Color(0xFFDB2777); // stamp accent-color swatch option

  // ---- Neutrals (dark -> light) ----
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color white = Color(0xFFFFFFFF);

  // ---- Semantic text / surface ----
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral500;
  static const Color textOnDark = white;
  static const Color textOnDarkSecondary = Color(0xCCFFFFFF); // ~80% white
  static const Color border = neutral200;
  static const Color surface = white;
  static const Color background = Color(0xFFFAFAFC);

  // ---- Status (GPS badges, permission chips, notification rows) ----
  static const Color success = green; // "Location verified", "Allowed"
  static const Color warning = orange; // "GPS accuracy warning", "Recommended"
  static const Color error = red; // "Denied", "Required", validation errors
  static const Color info = primary;

  // ---- Ads (Smart Ad Placements mockup) ----
  static const Color adTagBackground = Color(0xFFFFF7ED);
  static const Color adTagText = amber;
  static const Color adCardBorder = neutral200;

  // ---- Stamp accent-color picker options (Customize Stamp / Templates) ----
  static const List<Color> stampAccentOptions = [
    primary,
    green,
    orange,
    blue,
    red,
    neutral500,
  ];
}