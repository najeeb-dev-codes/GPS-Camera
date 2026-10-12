import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_input_limits.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/file_naming_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > File Name Format.
///
/// Live filename preview, a toggleable "naming pattern" chip set
/// (Project / Date / Time / Sequence / Latitude / +), prefix field, date
/// & time format, sequence numbering, and duplicate-name avoidance.
class FileNamingScreen extends StatefulWidget {
  const FileNamingScreen({super.key});

  @override
  State<FileNamingScreen> createState() => _FileNamingScreenState();
}

class _FileNamingScreenState extends State<FileNamingScreen> {
  static const _dateFormats = ['YYYYMMDD', 'DDMMYYYY', 'MM-DD-YYYY'];
  static const _timeFormats = ['HHmmss', 'HH-mm-ss'];

  late final TextEditingController _prefixController;
  late final TextEditingController _startNumberController;

  @override
  void initState() {
    super.initState();
    final settings = AppSettingsService.instance;
    _prefixController = TextEditingController(text: settings.fileNamingPrefix);
    _startNumberController =
        TextEditingController(text: settings.sequenceStartNumber.toString());
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = AppSettingsService.instance;
    await settings.ensureFileNamingSettingsLoaded();
    if (!mounted) return;
    _prefixController.text = settings.fileNamingPrefix;
    _startNumberController.text = settings.sequenceStartNumber.toString();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _startNumberController.dispose();
    super.dispose();
  }

  Future<void> _addCustomChip(AppSettingsService settings) async {
    final remaining = AppSettingsService.availableNamingChips
        .where((c) => !settings.namingPatternChips.contains(c))
        .toList();

    if (remaining.isEmpty) {
      AppTopToast.show(
        context,
        message: 'All naming fields are already added',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Add to naming pattern', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              for (final chip in remaining)
                ListTile(
                  title: Text(chip),
                  onTap: () => Navigator.of(context).pop(chip),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      settings.toggleNamingChip(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'File Name Format',
        actions: [
          TextButton(
            onPressed: () {
              settings.resetFileNamingSettings();
              _prefixController.text = settings.fileNamingPrefix;
              _startNumberController.text =
                  settings.sequenceStartNumber.toString();
              AppTopToast.show(
                context,
                message: 'Reset successfully',
                icon: Icons.refresh_rounded,
                backgroundColor: Colors.green,
              );
              Navigator.of(context).pop();
            },
            child: Text(
              'Reset',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth >= 600 ? 48.0 : AppSpacing.screenPadding;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.md,
                          horizontalPadding,
                          24,
                        ),
                        children: [
                          Text(
                            'Preview',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.isDarkMode
                                    ? AppColors.primaryLight
                                    : AppColors.primaryLight.withValues(
                                        alpha: 0.55,
                                      ),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                FileNamingService.preview(),
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          SettingsSectionCard(children: [
                          Text(
                            'Naming Pattern',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final chip in AppSettingsService.availableNamingChips)
                                _NamingChip(
                                  label: chip,
                                  selected: settings.namingPatternChips.contains(chip),
                                  onTap: () => settings.toggleNamingChip(chip),
                                ),
                              _NamingChip(
                                label: '+',
                                selected: false,
                                onTap: () => _addCustomChip(settings),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          AppTextField(
                            label: 'Project Name',
                            controller: _prefixController,
                            hint: 'e.g. SITE-A or WORK',
                            maxLength: AppInputLimits.fileNamePrefix,
                            onChanged: (v) =>
                                settings.set(() => settings.fileNamingPrefix = v),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          DropdownSettingRow<String>(
                            title: 'Date Format',
                            value: settings.dateFormat,
                            items: _dateFormats,
                            onChanged: (v) => settings.set(() => settings.dateFormat = v!),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Time Format',
                            value: settings.timeFormat,
                            items: _timeFormats,
                            onChanged: (v) => settings.set(() => settings.timeFormat = v!),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          ToggleSettingRow(
                            title: 'Sequence Number',
                            value: settings.sequenceNumberEnabled,
                            onChanged: (v) =>
                                settings.set(() => settings.sequenceNumberEnabled = v),
                          ),

                          if (settings.sequenceNumberEnabled) ...[
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                              label: 'Start number',
                              controller: _startNumberController,
                              keyboardType: TextInputType.number,
                              maxLength: AppInputLimits.sequenceNumber,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (v) {
                                final n = int.tryParse(v);
                                if (n != null) {
                                  settings.set(() => settings.sequenceStartNumber = n);
                                }
                              },
                            ),
                          ],

                          const SizedBox(height: AppSpacing.sm),
                          ToggleSettingRow(
                            title: 'Avoid duplicate names',
                            value: settings.avoidDuplicateNames,
                            onChanged: (v) =>
                                settings.set(() => settings.avoidDuplicateNames = v),
                          ),
                          ]),
                        ],
                      ),
                    ),
                    const AdBannerWidget(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        16,
                      ),
                      child: AppPrimaryButton(
                        label: 'Save Changes',
                        icon: Icons.save_outlined,
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          await settings.saveFileNamingSettings();
                          await FileNamingService.resetSequence(
                            settings.sequenceStartNumber,
                          );
                          if (!context.mounted) return;
                          AppTopToast.show(
                            context,
                            message: 'Changes saved successfully',
                            icon: Icons.drive_file_rename_outline,
                            backgroundColor: Colors.green,
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NamingChip extends StatelessWidget {
  const _NamingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.mutedSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
