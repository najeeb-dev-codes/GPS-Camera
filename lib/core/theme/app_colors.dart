import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';

/// Central color tokens for GPS Mark, derived directly from the
/// mockups (Welcome, Permissions, Home, Live Camera, Capture Preview,
/// Stamp Templates, Settings, Ads).
///
/// Never hard-code a `Color(...)` in a widget — reference a token here so
/// theming stays consistent and can be re-skinned from one place.
abstract final class AppColors {
  // ---- Primary (violet/purple — Get Started, Allow & Continue, Save
  // Photo, Save Style, all primary CTAs, selected template outline) ----
  static const Color defaultPrimary = Color(0xFF6D28D9);
  static Color get primary => AppSettingsService.instance.accentColor;
  static Color get primaryDark => Color.lerp(primary, Colors.black, 0.16)!;
  static Color get primaryLight => Color.lerp(primary, Colors.white, 0.24)!;
  static Color get lightPrimarySurface => Color.alphaBlend(
        primary.withValues(alpha: 0.09),
        lightSurface,
      );
  static Color get darkPrimarySurface => Color.alphaBlend(
        primary.withValues(alpha: 0.22),
        darkSurface,
      );
  static Color get primarySurface =>
      isDarkMode ? darkPrimarySurface : lightPrimarySurface;

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

  // ---- Semantic app text / surfaces ----
  // These values follow the selected app theme. Fixed colors such as [white]
  // and [neutral900] remain unchanged for photo stamps and camera overlays.
  // Fixed light/stamp text and softer app-UI text are kept separate so
  // changing the app theme never changes text burned into captured photos.
  static const Color lightTextPrimary = neutral900;
  static const Color lightUiTextPrimary = neutral700;
  static const Color lightTextSecondary = neutral500;
  static const Color lightBorder = neutral200;
  static const Color lightSurface = white;
  static const Color lightBackground = Color(0xFFFAFAFC);

  static const Color darkTextPrimary = Color(0xFFF5F7FA);
  static const Color darkTextSecondary = Color(0xFFB8BFCC);
  static const Color darkBorder = Color(0xFF343947);
  static const Color darkSurface = Color(0xFF171A21);
  static const Color darkBackground = Color(0xFF0F1115);

  static bool get isDarkMode {
    final mode = AppSettingsService.instance.themeMode;
    return switch (mode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
  }

  static Color get textPrimary =>
      isDarkMode ? darkTextPrimary : lightUiTextPrimary;
  static Color get textSecondary =>
      isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get border => isDarkMode ? darkBorder : lightBorder;
  static Color get surface => isDarkMode ? darkSurface : lightSurface;
  static Color get background =>
      isDarkMode ? darkBackground : lightBackground;
  static Color get mutedSurface =>
      isDarkMode ? const Color(0xFF242833) : neutral100;
  static Color get inactiveSurface =>
      isDarkMode ? darkBorder : neutral200;

  static const Color textOnDark = white;
  static const Color textOnDarkSecondary = Color(0xCCFFFFFF); // ~80% white

  // ---- Status (GPS badges, permission chips, notification rows) ----
  static const Color success = green; // "Location verified", "Allowed"
  static const Color warning = orange; // "GPS accuracy warning", "Recommended"
  static const Color error = red; // "Denied", "Required", validation errors
  static Color get info => primary;

  // ---- Ads (Smart Ad Placements mockup) ----
  static const Color adTagBackground = Color(0xFFFFF7ED);
  static const Color adTagText = amber;
  static const Color adCardBorder = neutral200;

  // ---- Stamp accent-color picker options (Customize Stamp / Templates) ----
  static List<Color> get stampAccentOptions => <Color>[
        primary,
        green,
        orange,
        blue,
        red,
        neutral500,
      ];
}
