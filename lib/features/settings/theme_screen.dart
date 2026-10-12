import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Lets the user preview a color selection before applying it app-wide.
class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {

  static const Color _defaultAccentColor = Color(0xFF6D28D9);

  Future<void> _resetTheme(
    BuildContext context,
    AppSettingsService settings,
  ) async {
    await settings.setThemeMode(ThemeMode.system);
    await settings.setAccentColor(_defaultAccentColor);
    if (!context.mounted) return;
    setState(() => _pendingAccentColor = null);
    AppTopToast.show(
      context,
      message: 'Reset successfully',
      icon: Icons.refresh_rounded,
      backgroundColor: Colors.green,
    );
    Navigator.of(context).pop();
  }

  Color? _pendingAccentColor;


  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'App Colour',
        actions: [
          TextButton(
            onPressed: () => _resetTheme(context, settings),
            child: const Text(
              'Reset',
              style: TextStyle(
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
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 600
                  ? 48.0
                  : AppSpacing.screenPadding;
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AppSpacing.md,
                        horizontalPadding,
                        AppSpacing.md,
                      ),
                      children: [
                        Text(
                          'App Colour',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Choose the primary color used throughout the app.',
                          style: AppTypography.caption.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SettingsSectionCard(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          children: [
                            _ThemeColorPicker(
                              selectedColor:
                                  _pendingAccentColor ?? settings.accentColor,
                              onChanged: (color) => setState(
                                () => _pendingAccentColor = color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.sm,
                      horizontalPadding,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        const SizedBox(height: AppSpacing.sm),
                        AppPrimaryButton(
                          label: 'Save Changes',
                          icon: Icons.save_outlined,
                          onPressed: () async {
                            final selectedColor =
                                _pendingAccentColor ?? settings.accentColor;
                            await settings.setAccentColor(selectedColor);
                            if (!context.mounted) return;
                            setState(() => _pendingAccentColor = null);
                            AppTopToast.show(
                              context,
                              message: 'App colour settings saved successfully',
                              icon: Icons.check_circle_outline_rounded,
                              backgroundColor: Colors.green,
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThemeColorPreset {
  const _ThemeColorPreset(this.label, this.color);

  final String label;
  final Color color;
}

class _ThemeColorPicker extends StatelessWidget {
  const _ThemeColorPicker({
    required this.selectedColor,
    required this.onChanged,
  });

  static const presets = <_ThemeColorPreset>[
    _ThemeColorPreset('Purple', Color(0xFF6D28D9)),
    _ThemeColorPreset('Indigo', Color(0xFF4F46E5)),
    _ThemeColorPreset('Blue', Color(0xFF2563EB)),
    _ThemeColorPreset('Sky', Color(0xFF0284C7)),
    _ThemeColorPreset('Cyan', Color(0xFF0891B2)),
    _ThemeColorPreset('Teal', Color(0xFF0F766E)),
    _ThemeColorPreset('Emerald', Color(0xFF059669)),
    _ThemeColorPreset('Green', Color(0xFF16A34A)),
    _ThemeColorPreset('Lime', Color(0xFF65A30D)),
    _ThemeColorPreset('Yellow', Color(0xFFEAB308)),
    _ThemeColorPreset('Amber', Color(0xFFD97706)),
    _ThemeColorPreset('Orange', Color(0xFFEA580C)),
    _ThemeColorPreset('Red', Color(0xFFDC2626)),
    _ThemeColorPreset('Rose', Color(0xFFE11D48)),
    _ThemeColorPreset('Pink', Color(0xFFDB2777)),
    _ThemeColorPreset('Fuchsia', Color(0xFFC026D3)),
    _ThemeColorPreset('Violet', Color(0xFF7C3AED)),
    _ThemeColorPreset('Brown', Color(0xFF92400E)),
    _ThemeColorPreset('Slate', Color(0xFF475569)),
    _ThemeColorPreset('Charcoal', Color(0xFF334155)),
  ];

  final Color selectedColor;
  final ValueChanged<Color> onChanged;

  bool _same(Color a, Color b) => a.toARGB32() == b.toARGB32();

  Future<void> _openPicker(BuildContext context) async {
    final value = await showDialog<Color>(
      context: context,
      builder: (_) => _ThemeCustomColorDialog(initialColor: selectedColor),
    );
    if (value != null) onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom =
        !presets.any((preset) => _same(preset.color, selectedColor));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 840
            ? 8
            : width >= 600
                ? 6
                : width >= 360
                    ? 4
                    : 3;

        const spacing = AppSpacing.xs;
        final itemWidth =
            (width - (spacing * (columns - 1))) / columns;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final preset in presets)
                  SizedBox(
                    width: itemWidth,
                    height: 62,
                    child: _ThemeColorChoice(
                      label: preset.label,
                      color: preset.color,
                      selected: _same(preset.color, selectedColor),
                      onTap: () => onChanged(preset.color),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            SizedBox(
              width: itemWidth,
              height: 62,
              child: _ThemeColorChoice(
                label: 'Custom',
                color: isCustom
                    ? selectedColor
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                selected: isCustom,
                showPickerIcon: !isCustom,
                onTap: () => _openPicker(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeColorChoice extends StatelessWidget {
  const _ThemeColorChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.showPickerIcon = false,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool showPickerIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label app color',
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: AppSpacing.xxs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? colors.onSurface : colors.outline,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: showPickerIcon
                        ? Icon(
                            Icons.colorize_rounded,
                            size: AppSizes.iconXs,
                            color: colors.onSurfaceVariant,
                          )
                        : selected
                            ? Icon(
                                Icons.check_rounded,
                                color: color.computeLuminance() > 0.55
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppTypography.tiny.copyWith(
                        color: selected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeCustomColorDialog extends StatefulWidget {
  const _ThemeCustomColorDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_ThemeCustomColorDialog> createState() =>
      _ThemeCustomColorDialogState();
}

class _ThemeCustomColorDialogState extends State<_ThemeCustomColorDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor.withValues(alpha: 1));
  }

  void _updateColor(Offset position, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final brightness = (1 - position.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      _hsv = _hsv
          .withSaturation(saturation.toDouble())
          .withValue(brightness.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor().withValues(alpha: 1);
    final pickerSide = (MediaQuery.sizeOf(context).width - 96)
        .clamp(160.0, 300.0)
        .toDouble();
    final pickerSize = Size.square(pickerSide);

    return AlertDialog(
      title: const Text('Pick a color'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _updateColor(details.localPosition, pickerSize),
                  onPanStart: (details) =>
                      _updateColor(details.localPosition, pickerSize),
                  onPanUpdate: (details) =>
                      _updateColor(details.localPosition, pickerSize),
                  child: CustomPaint(
                    size: pickerSize,
                    painter: _ThemeColorAreaPainter(hsv: _hsv),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 0,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor:
                              HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                        ),
                        child: Slider(
                          value: _hsv.hue,
                          min: 0,
                          max: 360,
                          onChanged: (value) {
                            setState(() => _hsv = _hsv.withHue(value));
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _ThemeColorValues(color: color),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(color),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ThemeColorAreaPainter extends CustomPainter {
  const _ThemeColorAreaPainter({required this.hsv});

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hue = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hue],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final position = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
      position,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _ThemeColorAreaPainter oldDelegate) {
    return oldDelegate.hsv != hsv;
  }
}

class _ThemeColorValues extends StatelessWidget {
  const _ThemeColorValues({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final argb = color.toARGB32();
    final red = (argb >> 16) & 0xFF;
    final green = (argb >> 8) & 0xFF;
    final blue = argb & 0xFF;
    final hex = argb
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();

    return Row(
      children: [
        _ThemeColorValue(label: 'HEX', value: '#$hex'),
        _ThemeColorValue(label: 'R', value: '$red'),
        _ThemeColorValue(label: 'G', value: '$green'),
        _ThemeColorValue(label: 'B', value: '$blue'),
        const _ThemeColorValue(label: 'A', value: '100%'),
      ],
    );
  }
}

class _ThemeColorValue extends StatelessWidget {
  const _ThemeColorValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
