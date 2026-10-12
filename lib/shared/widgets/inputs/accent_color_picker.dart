import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

class AccentColorPreset {
  const AccentColorPreset(this.label, this.color);

  final String label;
  final Color color;
}

/// Five quick app colors plus a responsive, dependency-free custom picker.
class AccentColorPicker extends StatelessWidget {
  const AccentColorPicker({
    super.key,
    required this.selectedColor,
    required this.onChanged,
  });

  static const List<AccentColorPreset> presets = <AccentColorPreset>[
    AccentColorPreset('Purple', Color(0xFF6D28D9)),
    AccentColorPreset('Blue', Color(0xFF2563EB)),
    AccentColorPreset('Teal', Color(0xFF0F766E)),
    AccentColorPreset('Green', Color(0xFF16A34A)),
    AccentColorPreset('Orange', Color(0xFFEA580C)),
  ];

  final Color selectedColor;
  final ValueChanged<Color> onChanged;

  bool _sameColor(Color first, Color second) =>
      first.toARGB32() == second.toARGB32();

  Future<void> _pickCustomColor(BuildContext context) async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (_) => _CustomAccentColorDialog(
        initialColor: selectedColor,
      ),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final customSelected =
        !presets.any((preset) => _sameColor(preset.color, selectedColor));

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Wrap(
          spacing: compact ? AppSpacing.sm : AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final preset in presets)
              _AccentColorChoice(
                label: preset.label,
                color: preset.color,
                selected: _sameColor(preset.color, selectedColor),
                onTap: () => onChanged(preset.color),
              ),
            _AccentColorChoice(
              label: 'Custom',
              color: customSelected
                  ? selectedColor
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              selected: customSelected,
              custom: true,
              onTap: () => _pickCustomColor(context),
            ),
          ],
        );
      },
    );
  }
}

class _AccentColorChoice extends StatelessWidget {
  const _AccentColorChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.custom = false,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool custom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label app color',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: SizedBox(
            width: 52,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? scheme.onSurface : scheme.outline,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: custom && !selected
                      ? Icon(
                          Icons.colorize_rounded,
                          size: AppSizes.iconSm,
                          color: scheme.onSurfaceVariant,
                        )
                      : selected
                          ? Icon(
                              Icons.check_rounded,
                              size: AppSizes.iconMd,
                              color: color.computeLuminance() > 0.55
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.tiny.copyWith(
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomAccentColorDialog extends StatefulWidget {
  const _CustomAccentColorDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_CustomAccentColorDialog> createState() =>
      _CustomAccentColorDialogState();
}

class _CustomAccentColorDialogState
    extends State<_CustomAccentColorDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor.withValues(alpha: 1));
  }

  void _updateSaturationAndValue(Offset position, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - (position.dy / size.height)).clamp(0.0, 1.0);

    setState(() {
      _hsv = _hsv
          .withSaturation(saturation.toDouble())
          .withValue(value.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _hsv.toColor().withValues(alpha: 1);
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Pick a color'),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.sm,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final side = math.min(constraints.maxWidth, 300.0);
                  final size = Size.square(side);

                  return Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => _updateSaturationAndValue(
                        details.localPosition,
                        size,
                      ),
                      onPanStart: (details) => _updateSaturationAndValue(
                        details.localPosition,
                        size,
                      ),
                      onPanUpdate: (details) => _updateSaturationAndValue(
                        details.localPosition,
                        size,
                      ),
                      child: CustomPaint(
                        size: size,
                        painter: _SaturationValuePainter(hsv: _hsv),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.outline),
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
                          thumbColor: HSVColor.fromAHSV(
                            1,
                            _hsv.hue,
                            1,
                            1,
                          ).toColor(),
                          overlayColor:
                              selectedColor.withValues(alpha: 0.14),
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
              _ColorValues(color: selectedColor),
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
          onPressed: () => Navigator.of(context).pop(selectedColor),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({required this.hsv});

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
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

    final center = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(
      center,
      10.5,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.hsv != hsv;
  }
}

class _ColorValues extends StatelessWidget {
  const _ColorValues({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = color.toARGB32();
    final red = (value >> 16) & 0xFF;
    final green = (value >> 8) & 0xFF;
    final blue = value & 0xFF;
    final hex = value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ColorValue(label: 'HEX', value: '#$hex'),
        _ColorValue(label: 'R', value: '$red'),
        _ColorValue(label: 'G', value: '$green'),
        _ColorValue(label: 'B', value: '$blue'),
        const _ColorValue(label: 'A', value: '100%'),
      ],
    );
  }
}

class _ColorValue extends StatelessWidget {
  const _ColorValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
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
      ),
    );
  }
}
