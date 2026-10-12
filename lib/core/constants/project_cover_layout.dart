abstract final class ProjectCoverLayout {
  ProjectCoverLayout._();

  /// Shared ratio used by cover selection, cropping, and Project Details.
  static const double aspectRatio = 8 / 7;

  /// Saved crop size. This keeps covers clear without creating oversized files.
  static const int outputWidth = 1600;
  static const int outputHeight = 1400;
}
