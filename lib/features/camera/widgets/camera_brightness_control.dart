import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraBrightnessControl extends StatelessWidget {
  const CameraBrightnessControl({
    super.key,
    required this.percentage,
    required this.onChanged,
    required this.onInteractionStart,
    required this.onInteractionEnd,
    required this.deviceOrientation,
    this.safeInsets = EdgeInsets.zero,
    this.topRightExtraInset = 0,
  });

  final double percentage;
  final ValueChanged<double> onChanged;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;
  final DeviceOrientation deviceOrientation;

  /// Space kept free at the screen edges. In Full ratio the camera layer runs
  /// behind the toolbar (top) and the shutter + banner ad (bottom), so the
  /// caller passes those heights here and the control is never hidden.
  final EdgeInsets safeInsets;

  /// Extra space below the screen's top-right corner (for example the GPS
  /// accuracy chip). Used only when the control sits in that corner.
  final double topRightExtraInset;

  @override
  Widget build(BuildContext context) {
    final safeValue = percentage.clamp(1.0, 100.0).toDouble();

    // The control always appears in the top-right corner AS THE USER SEES IT.
    // The app layout stays portrait, so that visual corner is a different
    // screen corner for each phone orientation, and the slider is rotated so
    // it stays upright:
    //
    //  - portrait up          -> screen top-right
    //  - landscape (top left) -> screen bottom-right
    //  - landscape (top right)-> screen top-left
    //  - portrait down        -> screen bottom-left
    final int quarterTurns;
    final Alignment alignment;
    final EdgeInsets margin;

    switch (deviceOrientation) {
      // Phone top points toward the physical left.
      case DeviceOrientation.landscapeLeft:
        quarterTurns = 1;
        alignment = Alignment.bottomRight;
        margin = EdgeInsets.only(
          right: 12,
          bottom: 12 + safeInsets.bottom,
        );
        break;

      // Phone top points toward the physical right.
      case DeviceOrientation.landscapeRight:
        quarterTurns = 3;
        alignment = Alignment.topLeft;
        margin = EdgeInsets.only(
          left: 12,
          top: 12 + safeInsets.top,
        );
        break;

      case DeviceOrientation.portraitDown:
        quarterTurns = 2;
        alignment = Alignment.bottomLeft;
        margin = EdgeInsets.only(
          left: 12,
          bottom: 12 + safeInsets.bottom,
        );
        break;

      case DeviceOrientation.portraitUp:
        quarterTurns = 0;
        alignment = Alignment.topRight;
        margin = EdgeInsets.only(
          right: 12,
          top: 12 + safeInsets.top + topRightExtraInset,
        );
        break;
    }

    return Padding(
      padding: margin,
      child: Align(
        alignment: alignment,
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: Container(
            width: 42,
            height: 280,
            padding: const EdgeInsets.symmetric(
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.58,
              ),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: Colors.white24,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.light_mode_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white30,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white12,
                        trackHeight: 2.5,
                      ),
                      child: Slider(
                        min: 1,
                        max: 100,
                        divisions: 99,
                        value: safeValue,
                        onChanged: onChanged,
                        onChangeStart: (_) {
                          onInteractionStart();
                        },
                        onChangeEnd: (_) {
                          onInteractionEnd();
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    safeValue.round().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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