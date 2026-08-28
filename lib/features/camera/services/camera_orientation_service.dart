import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

/// Reads physical phone orientation even when the Flutter activity is locked
/// to portrait. This keeps sensor handling out of the camera screen.
class CameraOrientationService {
  final NativeDeviceOrientationCommunicator _communicator =
      NativeDeviceOrientationCommunicator();

  Stream<DeviceOrientation> get orientationStream => _communicator
      .onOrientationChanged(useSensor: true)
      .map(_toFlutterOrientation)
      .distinct();

  DeviceOrientation _toFlutterOrientation(
    NativeDeviceOrientation orientation,
  ) {
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft:
        return DeviceOrientation.landscapeLeft;
      case NativeDeviceOrientation.landscapeRight:
        return DeviceOrientation.landscapeRight;
      case NativeDeviceOrientation.portraitDown:
        return DeviceOrientation.portraitDown;
      case NativeDeviceOrientation.portraitUp:
      case NativeDeviceOrientation.unknown:
        return DeviceOrientation.portraitUp;
    }
  }
}
