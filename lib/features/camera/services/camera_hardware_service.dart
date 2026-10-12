import 'dart:async';

import 'package:flutter/services.dart';

class CameraHardwareService {
  CameraHardwareService._();

  static const MethodChannel _commands =
      MethodChannel('gps_camera/hardware_commands');
  static const EventChannel _buttons =
      EventChannel('gps_camera/volume_buttons');
  static const EventChannel _level =
      EventChannel('gps_camera/level_sensor');

  static Stream<String> get volumeButtons =>
      _buttons.receiveBroadcastStream().cast<String>();

  static Stream<double> get levelDegrees => _level
      .receiveBroadcastStream()
      .map((value) => (value as num).toDouble());

  static Future<void> setVolumeAction(String action) async {
    await _commands.invokeMethod<void>('setVolumeAction', action);
  }
}
