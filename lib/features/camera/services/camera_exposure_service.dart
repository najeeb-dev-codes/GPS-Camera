import 'package:camera/camera.dart';

/// Keeps all device-specific exposure logic outside the camera screen.
class CameraExposureService {
  double _minimum = 0;
  double _maximum = 0;
  double _current = 0;
  double _percentage = 50;

  double get minimum => _minimum;
  double get maximum => _maximum;
  double get current => _current;
  double get percentage => _percentage;
  bool get isSupported => _maximum > _minimum;

  Future<void> initialize(
    CameraController controller, {
    double percentage = 50,
  }) async {
    _minimum = await controller.getMinExposureOffset();
    _maximum = await controller.getMaxExposureOffset();
    await setPercentage(controller, percentage);
  }

  Future<double> setValue(
    CameraController controller,
    double value,
  ) async {
    final requested = value.clamp(_minimum, _maximum).toDouble();
    _current = await controller.setExposureOffset(requested);
    return _current;
  }

  Future<double> reset(CameraController controller) {
    return setValue(controller, 0);
  }

  /// Maps a friendly 1-100 value to the exact exposure range reported by the
  /// active camera. Level 50 always means the camera's neutral offset (0).
  Future<double> setPercentage(
    CameraController controller,
    double percentage,
  ) async {
    final safePercentage = percentage.clamp(1.0, 100.0).toDouble();
    final double requestedOffset;

    if (safePercentage <= 50) {
      final progress = (safePercentage - 1) / 49;
      requestedOffset = _minimum + ((0 - _minimum) * progress);
    } else {
      final progress = (safePercentage - 50) / 50;
      requestedOffset = _maximum * progress;
    }

    _current = await controller.setExposureOffset(
      requestedOffset.clamp(_minimum, _maximum).toDouble(),
    );
    // Keep the exact user-selected 1-100 level. The camera applies the nearest
    // exposure offset supported by its hardware.
    _percentage = safePercentage;
    return _percentage;
  }
}
