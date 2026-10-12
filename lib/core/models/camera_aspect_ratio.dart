/// Shared camera aspect-ratio definition used by Settings, Live Camera,
/// and Capture Preview so every screen uses the same supported values.
enum CameraAspectRatioOption {
  ratio4x3(label: '4:3', value: 4 / 3),
  ratio16x9(label: '16:9', value: 16 / 9),
  ratio1x1(label: '1:1', value: 1),
  full(label: 'Full', value: null);

  const CameraAspectRatioOption({
    required this.label,
    required this.value,
  });

  final String label;

  /// Landscape ratio. `null` means use the camera's native ratio.
  final double? value;

  static List<String> get labels =>
      values.map((option) => option.label).toList(growable: false);

  static CameraAspectRatioOption fromLabel(String label) {
    for (final option in values) {
      if (option.label == label) return option;
    }
    return full;
  }

  CameraAspectRatioOption get next {
    final index = values.indexOf(this);
    return values[(index + 1) % values.length];
  }

  /// Resolves the visible frame ratio for the current device orientation.
  double resolve({
    required bool isLandscape,
    required double nativeCameraRatio,
  }) {
    final landscapeRatio = value ?? nativeCameraRatio;
    if (landscapeRatio <= 0) return isLandscape ? 4 / 3 : 3 / 4;
    return isLandscape ? landscapeRatio : 1 / landscapeRatio;
  }
}
