import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Labeled text input / search field.
///
/// Used for search bars (Gallery, Templates, Projects) and form fields
/// (Create Project name, code, client, description, custom naming prefix).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.maxLines = 1,
    this.isSearch = false,
    this.keyboardType,
    this.maxLength,
    this.showCharacterCounter = false,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  /// Renders as a compact pill search field (rounded, filled neutral bg).
  final bool isSearch;

  final TextInputType? keyboardType;
  final int? maxLength;
  final bool showCharacterCounter;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: AppTypography.body,
      decoration: InputDecoration(
        hintText: hint,
        counterText: maxLength != null && !showCharacterCounter ? '' : null,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.neutral400, size: AppSizes.iconSm)
            : (isSearch ? const Icon(Icons.search, color: AppColors.neutral400) : null),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isSearch
            ? (AppColors.isDarkMode
                ? AppColors.darkSurface
                : AppColors.neutral100)
            : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSearch ? AppRadius.pill : AppRadius.md),
          borderSide: isSearch
              ? BorderSide.none
              : BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSearch ? AppRadius.pill : AppRadius.md),
          borderSide: isSearch
              ? BorderSide.none
              : BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSearch ? AppRadius.pill : AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        field,
      ],
    );
  }
}
