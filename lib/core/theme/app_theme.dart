import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Assembles the global [ThemeData] from the design tokens.
///
/// Light theme only for now — the mockups don't show a dark app theme
/// (the Live Camera screen's dark UI is a screen-specific overlay, not a
/// global dark mode, so it's handled by widgets like `GpsStampOverlay`
/// rather than `ThemeData.dark()`). Settings > Appearance shows a
/// Light/Dark/System selector for future support.
abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    // Apply Poppins to EVERY text style, then layer our tokens on top so
    // all sections (app bars, dialogs, default Text, etc.) inherit Poppins.
    final appTextTheme = GoogleFonts.poppinsTextTheme(base.textTheme)
        .merge(AppTypography.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      textTheme: appTextTheme,
      primaryTextTheme: appTextTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.green,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        // Material 3 adds a ColorScheme tint when content scrolls under an
        // app bar. Keep every standard app bar white in all scroll states.
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h2,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.neutral400,
          elevation: 0,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
          minimumSize: const Size(0, AppSizes.buttonHeight),
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.white : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.primary : AppColors.neutral200,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.neutral100,
        labelStyle: AppTypography.caption,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.neutral400),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary, width: 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, width: 1.5),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.neutral400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.h2,
        contentTextStyle: AppTypography.body,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral900,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
}
