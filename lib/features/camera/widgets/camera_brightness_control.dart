



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
  });

  final double percentage;
  final ValueChanged<double> onChanged;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;
  final DeviceOrientation deviceOrientation;

  @override
  Widget build(BuildContext context) {
    final safeValue = percentage.clamp(1.0, 100.0).toDouble();

    final int quarterTurns;
    final Alignment alignment;
    final EdgeInsets margin;

    switch (deviceOrientation) {
      // Phone top points toward the physical left.
      // The portrait screen's bottom becomes the landscape right side.
      case DeviceOrientation.landscapeLeft:
        quarterTurns = 1;
        alignment = Alignment.bottomCenter;
        margin = const EdgeInsets.only(
          left: 10,
          right: 10,
          bottom: 10,
        );
        break;

      // Phone top points toward the physical right.
      // The portrait screen's top becomes the landscape right side.
      case DeviceOrientation.landscapeRight:
        quarterTurns = 3;
        alignment = Alignment.topCenter;
        margin = const EdgeInsets.only(
          left: 10,
          right: 10,
          top: 10,
        );
        break;

      case DeviceOrientation.portraitDown:
        quarterTurns = 2;
        alignment = Alignment.bottomLeft;
        margin = const EdgeInsets.only(
          left: 10,
          bottom: 120,
        );
        break;

      case DeviceOrientation.portraitUp:
        quarterTurns = 0;
        alignment = Alignment.topRight;
        margin = const EdgeInsets.only(
          top: 120,
          right: 10,
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