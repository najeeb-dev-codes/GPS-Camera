/// Canonical stamp-template catalogue shared by camera, preview and projects.
///
/// Keeping the labels and index mapping here prevents one screen from showing
/// a template that another screen cannot render.
enum StampTemplate {
  map('Map'),
  defaultStamp('Address'),
  timeAndPlace('Time & Place'),
  minimal('Minimal');

  const StampTemplate(this.label);

  final String label;

  static StampTemplate fromIndex(int index) {
    final safeIndex = index.clamp(0, StampTemplate.values.length - 1).toInt();
    return StampTemplate.values[safeIndex];
  }

  /// Converts saved project values from older releases. Removed presets safely
  /// fall back to Map instead of selecting a different template.
  static StampTemplate fromStoredName(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'address' || 'default' || 'location card' => StampTemplate.defaultStamp,
      'time & place' => StampTemplate.timeAndPlace,
      'minimal' || 'minimal proof' => StampTemplate.minimal,
      'map' || 'map (default)' => StampTemplate.map,
      _ => StampTemplate.map,
    };
  }
}

final List<String> kStampTemplateLabels = List<String>.unmodifiable(
  StampTemplate.values.map((template) => template.label),
);
