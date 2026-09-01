/// Editable appearance and field visibility for one built-in stamp template.
class StampStyleSettings {
  const StampStyleSettings({
    this.showMap = true,
    this.showAddress = true,
    this.showCoordinates = true,
    this.showDateTime = true,
    this.showCompass = false,
    this.showAltitude = true,
    this.size = 90,
    this.opacity = 80,
  });

  final bool showMap;
  final bool showAddress;
  final bool showCoordinates;
  final bool showDateTime;
  final bool showCompass;
  final bool showAltitude;
  final double size;
  final double opacity;

  StampStyleSettings copyWith({
    bool? showMap,
    bool? showAddress,
    bool? showCoordinates,
    bool? showDateTime,
    bool? showCompass,
    bool? showAltitude,
    double? size,
    double? opacity,
  }) {
    return StampStyleSettings(
      showMap: showMap ?? this.showMap,
      showAddress: showAddress ?? this.showAddress,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showDateTime: showDateTime ?? this.showDateTime,
      showCompass: showCompass ?? this.showCompass,
      showAltitude: showAltitude ?? this.showAltitude,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
    );
  }
}

const List<StampStyleSettings> kDefaultStampStyles = [
  StampStyleSettings(),
  StampStyleSettings(showMap: false),
  StampStyleSettings(showMap: false),
  StampStyleSettings(
    showMap: false,
    showCoordinates: false,
    showCompass: true,
    showAltitude: false,
  ),
  StampStyleSettings(
    showMap: false,
    showCoordinates: false,
    showAltitude: false,
  ),
];
