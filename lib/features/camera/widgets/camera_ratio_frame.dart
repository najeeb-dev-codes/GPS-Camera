import 'package:flutter/material.dart';

/// Keeps the camera preview inside the selected ratio.
class CameraRatioFrame extends StatelessWidget {
  const CameraRatioFrame({
    super.key,
    required this.aspectRatio,
    required this.child,
  });

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRect(
          child: child,
        ),
      ),
    );
  }
}