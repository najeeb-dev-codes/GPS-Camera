import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/camera_hardware_service.dart';

class CameraLevelIndicator extends StatefulWidget {
  const CameraLevelIndicator({super.key});

  @override
  State<CameraLevelIndicator> createState() => _CameraLevelIndicatorState();
}

class _CameraLevelIndicatorState extends State<CameraLevelIndicator> {
  StreamSubscription<double>? _subscription;
  double _degrees = 0;

  bool get _isLevel => _degrees.abs() <= 1.5;

  @override
  void initState() {
    super.initState();
    _subscription = CameraHardwareService.levelDegrees.listen((value) {
      if (mounted) {
        setState(() => _degrees = value.clamp(-45, 45).toDouble());
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _isLevel ? const Color(0xFF32D74B) : Colors.white;
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 130,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 130, height: 1, color: Colors.white38),
              Transform.rotate(
                angle: _degrees * math.pi / 180,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 78,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 3),
                    ],
                  ),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
