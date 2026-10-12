import 'package:flutter/material.dart';

import '../../core/models/stamp_template.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'customize_stamp_screen.dart';

/// Describes one selectable built-in stamp look.
class StampTemplateInfo {
  const StampTemplateInfo({
    required this.label,
  });

  final String label;
}

final List<StampTemplateInfo> kBuiltInStampTemplates =
    List<StampTemplateInfo>.unmodifiable(
  StampTemplate.values.map(
    (template) => StampTemplateInfo(label: template.label),
  ),
);

/// Screen 6 — Stamp Templates.
///
/// Vertical list of stamp looks, each rendered with the real
/// [GpsStampOverlay] so a
/// template looks identical here as it does on a live photo. Every template
/// has its own "Customize Stamp" action; customization edits that template
/// and never adds another stamp.
///
/// When [selectionMode] is true (opened from Live Camera to pick a
/// template for the next shot) "Apply Template" pops with the chosen
/// index. When opened from Home ("Templates" quick action) it just manages
/// the list in place.
class StampTemplatesScreen extends StatefulWidget {
  const StampTemplatesScreen({
    super.key,
    this.selectionMode = false,
    this.initialSelectedIndex,
    this.stampData,
  });

  final bool selectionMode;
  final int? initialSelectedIndex;

  /// Current live stamp from Camera, or frozen stamp from Capture Preview.
  final GpsStampData? stampData;

  @override
  State<StampTemplatesScreen> createState() => _StampTemplatesScreenState();
}

class _StampTemplatesScreenState extends State<StampTemplatesScreen> {
  late int _selectedIndex;
  final List<StampTemplateInfo> _templates = [...kBuiltInStampTemplates];

  @override
  void initState() {
    super.initState();
    final savedIndex = AppSettingsService.instance.selectedStampTemplateIndex;
    _selectedIndex = StampTemplate.fromIndex(
      widget.initialSelectedIndex ?? savedIndex,
    ).index;
    _restoreAppliedTemplate();
  }

  Future<void> _restoreAppliedTemplate() async {
    if (widget.initialSelectedIndex != null) return;

    final settings = AppSettingsService.instance;
    await settings.ensureStampTemplateSettingsLoaded();
    if (!mounted) return;

    setState(() {
      _selectedIndex = StampTemplate.fromIndex(
        settings.selectedStampTemplateIndex,
      ).index;
    });
  }

  Future<void> _openCustomize(int index) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomizeStampScreen(
          templateIndex: index,
          templateName: _templates[index].label,
          stampData: widget.stampData,
        ),
      ),
    );

    if (changed != true || !mounted) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _resetTemplates() async {
    await AppSettingsService.instance.setSelectedStampTemplateIndex(0);
    if (!mounted) return;

    setState(() => _selectedIndex = 0);
    AppTopToast.show(
      context,
      message: 'Reset successfully',
      icon: Icons.refresh_rounded,
      backgroundColor: Colors.green,
    );
    Navigator.of(context).pop();
  }

  Future<void> _applyTemplate() async {
    await AppSettingsService.instance.setSelectedStampTemplateIndex(
      _selectedIndex,
    );
    if (!mounted) return;

    AppTopToast.show(
      context,
      message: 'Stamp template applied successfully',
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: Colors.green,
    );

    if (widget.selectionMode) {
      Navigator.of(context).pop(_selectedIndex);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.stampData ??
        const GpsStampData(
          address: 'Tirunelveli, Tamil Nadu, India',
          title: 'Tirunelveli, Tamil Nadu, India',
          streetAddress: 'Tirunelveli, Tamil Nadu 627001, India',
          latitude: 8.7139,
          longitude: 77.7567,
          coordinates: 'Lat 8.713900° Long 77.756700°',
          dateTime: 'Saturday, 29/08/2026 02:30 PM',
          altitude: 'Altitude 47 m',
          compassDirection: 'NE 45°',
        );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'Stamp Templates',
        actions: [
          TextButton(
            onPressed: _resetTemplates,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final horizontalPadding =
                isWide ? 32.0 : AppSpacing.screenPadding;
            final availableWidth =
                constraints.maxWidth - (horizontalPadding * 2);
            final stampRowHeight =
                (availableWidth * 0.16).clamp(64.0, 88.0).toDouble();
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.md,
                      horizontalPadding,
                      AppSpacing.md,
                    ),
                    itemCount: _templates.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      // Place a standard banner directly after Address and
                      // before Time & Place, using the same row height as a
                      // stamp preview.
                      if (index == 2) {
                        return _StampSizedAd(height: stampRowHeight);
                      }

                      final templateIndex = index > 2 ? index - 1 : index;
                      final template = _templates[templateIndex];
                      final selected = templateIndex == _selectedIndex;

                      return _TemplateTile(
                        templateIndex: templateIndex,
                        template: template,
                        data: data,
                        height: stampRowHeight,
                        selected: selected,
                        onTap: () =>
                            setState(() => _selectedIndex = templateIndex),
                        onCustomize: () => _openCustomize(templateIndex),
                      );
                    },
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const AdBannerWidget(
                      format: AdDisplayFormat.adaptiveBanner,
                      reserveSpaceWhileLoading: true,
                      slotHeight: 50,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    16,
                  ),
                  child: AppPrimaryButton(
                    label: 'Apply Template',
                    onPressed: _applyTemplate,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StampSizedAd extends StatelessWidget {
  const _StampSizedAd({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AdBannerWidget(
      reserveSpaceWhileLoading: true,
      slotHeight: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm / 2),
      ),
    );
  }
}

// =============================================================================
// TEMPLATE TILE
// =============================================================================

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.templateIndex,
    required this.template,
    required this.data,
    required this.height,
    required this.selected,
    required this.onTap,
    required this.onCustomize,
  });

  final int templateIndex;
  final StampTemplateInfo template;
  final GpsStampData data;
  final double height;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${template.label}${selected ? ' (Default)' : ''}',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCustomize,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: height,
            child: ListenableBuilder(
              listenable: AppSettingsService.instance,
              builder: (context, _) {
                final style = AppSettingsService.instance
                    .stampStyleFor(templateIndex);
                final scale = (style.size / 90)
                    .clamp(0.40, 1.0)
                    .toDouble();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.mutedSurface,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Align(
                        alignment: Alignment.center,
                        child: FractionallySizedBox(
                          widthFactor: scale,
                          heightFactor: scale,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                            child: templateIndex == StampTemplate.minimal.index
                                ? GpsStampTemplateOverlay(
                                    data: data,
                                    templateIndex: templateIndex,
                                    compact: true,
                                    mapSize: 60,
                                  )
                                : FittedBox(
                                    fit: BoxFit.fill,
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: 520,
                                      child: GpsStampTemplateOverlay(
                                        data: data,
                                        templateIndex: templateIndex,
                                        compact: true,
                                        mapSize: 60,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.primary,
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

