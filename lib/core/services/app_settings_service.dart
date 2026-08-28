

import 'package:flutter/material.dart';

/// Single source of truth for every setting shown across the Settings
/// screens (Camera, Stamp Defaults, Location & GPS, Photo Quality,
/// File Naming, Storage & Backup, Offline Capture, Appearance,
/// Notifications, About & Help).
///
/// This is a plain [ChangeNotifier] singleton (`AppSettingsService.instance`)
/// so any screen can read the current value and any screen can change it —
/// changes made on one screen (e.g. toggling "Offline capture" from the
/// main Settings list) are instantly reflected everywhere else that reads
/// the same field (e.g. the Offline Capture detail screen), and vice versa.
///
/// Wrap a screen's body in an `AnimatedBuilder(animation:
/// AppSettingsService.instance, builder: ...)` (or `ListenableBuilder`) to
/// rebuild automatically when any field changes.
class AppSettingsService extends ChangeNotifier {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  // ---------------------------------------------------------------------
  // CAMERA SETTINGS
  // ---------------------------------------------------------------------

  String defaultCamera = 'Back Camera';
  String captureMode = 'Photo';
  String aspectRatio = '16:9';
  bool gridLines = false;
  bool levelIndicator = true;
  bool tapToFocus = true;
  bool mirrorSelfies = false;
  bool shutterSound = true;
  String volumeKeyAction = 'Capture';
  String timer = 'Off';
  bool saveOriginalPhoto = true;
  bool showGpsAccuracyMeter = true;

  void resetCameraSettings() {
    defaultCamera = 'Back Camera';
    captureMode = 'Photo';
    aspectRatio = '16:9';
    gridLines = false;
    levelIndicator = true;
  showGpsAccuracyMeter = true;
    tapToFocus = true;
    mirrorSelfies = false;
    shutterSound = true;
    volumeKeyAction = 'Capture';
    timer = 'Off';
    saveOriginalPhoto = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // STAMP DEFAULTS
  // ---------------------------------------------------------------------

  String stampTemplate = 'Map Card';
  String mapType = 'Standard';

  bool showAddress = true;
  bool showCoordinates = true;
  bool showDateTime = true;
  bool showWeather = false;
  bool showCompass = true;
  bool showAltitude = true;
  bool showAccuracy = true;
  bool showNote = false;
  bool showLogo = false;

  String stampPosition = 'Bottom Right';
  double stampDefaultSize = 90;
  double stampOpacity = 80;

  // ---------------------------------------------------------------------
  // LOCATION & GPS
  // ---------------------------------------------------------------------

  String locationSource = 'Device GPS';
  bool preciseLocation = true;
  bool highAccuracyMode = true;
  String gpsAccuracyThreshold = '±10 m';
  bool waitForAccurateSignal = true;
  bool showAccuracyWarning = true;
  String coordinateFormat = 'Decimal Degrees';
  String addressLanguage = 'English';
  String refreshLocation = 'Every capture';

  void resetLocationSettings() {
    locationSource = 'Device GPS';
    preciseLocation = true;
    highAccuracyMode = true;
    gpsAccuracyThreshold = '±10 m';
    waitForAccurateSignal = true;
    showAccuracyWarning = true;
    coordinateFormat = 'Decimal Degrees';
    addressLanguage = 'English';
    refreshLocation = 'Every capture';
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // PHOTO QUALITY
  // ---------------------------------------------------------------------

  String photoResolution = 'Highest available';
  String imageFormat = 'JPEG';
  double jpegQuality = 95;
  bool hdrCapture = true;
  bool autoEnhance = false;
  String watermarkCompression = 'High Quality';
  bool preserveExifMetadata = true;
  bool embedGpsInExif = true;

  /// Rough estimated file size range shown at the bottom of Photo Quality,
  /// derived from the current resolution / format / quality choices.
  String get estimatedPhotoSize {
    final base = switch (photoResolution) {
      'Highest available' => 8.0,
      'High' => 5.0,
      'Medium' => 2.5,
      _ => 1.0,
    };
    final formatFactor = imageFormat == 'PNG' ? 1.6 : (imageFormat == 'HEIC' ? 0.55 : 1.0);
    final qualityFactor = jpegQuality / 100;
    final high = (base * formatFactor * qualityFactor).clamp(0.5, 20);
    final low = (high * 0.5).clamp(0.3, high);
    return '${low.toStringAsFixed(0)} – ${high.toStringAsFixed(0)} MB';
  }

  void resetPhotoQualitySettings() {
    photoResolution = 'Highest available';
    imageFormat = 'JPEG';
    jpegQuality = 95;
    hdrCapture = true;
    autoEnhance = false;
    watermarkCompression = 'High Quality';
    preserveExifMetadata = true;
    embedGpsInExif = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // FILE NAMING
  // ---------------------------------------------------------------------

  /// Ordered list of naming-pattern chips, e.g.
  /// `['Project', 'Date', 'Time']`.
  List<String> namingPatternChips = ['Project', 'Date', 'Time'];

  static const List<String> availableNamingChips = [
    'Project',
    'Date',
    'Time',
    'Sequence',
    'Latitude',
  ];

  String fileNamingPrefix = 'SITE-A';
  String dateFormat = 'YYYYMMDD';
  String timeFormat = 'HHmmss';
  bool sequenceNumberEnabled = true;
  int sequenceStartNumber = 1;
  bool avoidDuplicateNames = true;

  /// Builds a live filename preview from the current naming settings,
  /// e.g. "SITE-A_20260818_162530.jpg".
  String get fileNamePreview {
    final now = DateTime.now();
    final parts = <String>[];

    for (final chip in namingPatternChips) {
      switch (chip) {
        case 'Project':
          parts.add(fileNamingPrefix);
          break;
        case 'Date':
          parts.add(_formatDate(now, dateFormat));
          break;
        case 'Time':
          parts.add(_formatTime(now, timeFormat));
          break;
        case 'Sequence':
          if (sequenceNumberEnabled) {
            parts.add(sequenceStartNumber.toString().padLeft(3, '0'));
          }
          break;
        case 'Latitude':
          parts.add('7.7281');
          break;
      }
    }

    if (parts.isEmpty) parts.add(fileNamingPrefix);

    return '${parts.join('_')}.jpg';
  }

  String _formatDate(DateTime d, String format) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return switch (format) {
      'YYYYMMDD' => '$y$m$day',
      'DDMMYYYY' => '$day$m$y',
      'MM-DD-YYYY' => '$m-$day-$y',
      _ => '$y$m$day',
    };
  }

  String _formatTime(DateTime d, String format) {
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final s = d.second.toString().padLeft(2, '0');
    return switch (format) {
      'HHmmss' => '$h$min$s',
      'HH-mm-ss' => '$h-$min-$s',
      _ => '$h$min$s',
    };
  }

  void toggleNamingChip(String chip) {
    if (namingPatternChips.contains(chip)) {
      namingPatternChips = List.of(namingPatternChips)..remove(chip);
    } else {
      namingPatternChips = List.of(namingPatternChips)..add(chip);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // STORAGE & BACKUP
  // ---------------------------------------------------------------------

  double storageUsedGb = 2.4;
  double storageTotalGb = 10;
  String saveLocation = 'Pictures/GeoStamp';
  bool createProjectFolders = true;
  bool cloudBackup = true;
  bool backupOverWifiOnly = true;
  String autoBackup = 'Daily';
  bool backupOriginalPhotos = false;
  DateTime? lastBackupAt = DateTime.now().subtract(const Duration(hours: 2));

  double get storageUsedFraction =>
      storageTotalGb == 0 ? 0 : (storageUsedGb / storageTotalGb).clamp(0, 1);

  int get storageUsedPercent => (storageUsedFraction * 100).round();

  String get lastBackupLabel {
    final t = lastBackupAt;
    if (t == null) return 'Never';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final isToday = DateTime.now().difference(t).inHours < 24 &&
        DateTime.now().day == t.day;
    return '${isToday ? 'Today' : '${t.day}/${t.month}/${t.year}'}, $h:$m';
  }

  bool isBackingUp = false;

  Future<void> runBackupNow() async {
    if (isBackingUp) return;
    isBackingUp = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(seconds: 2));
    lastBackupAt = DateTime.now();
    isBackingUp = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // OFFLINE CAPTURE
  // ---------------------------------------------------------------------

  bool offlineCapture = true;
  bool storeGpsCoordinatesOffline = true;
  bool resolveAddressWhenOnline = true;
  String downloadedAreaName = 'Tirunelveli';
  double downloadedAreaMb = 84;
  int pendingAddressUpdates = 3;
  bool autoSync = true;
  bool syncOnWifiOnly = true;
  bool isSyncing = false;

  Future<void> syncNow() async {
    if (isSyncing) return;
    isSyncing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(seconds: 2));
    pendingAddressUpdates = 0;
    isSyncing = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // APPEARANCE (in-app "Theme" screen)
  // ---------------------------------------------------------------------

  ThemeMode themeMode = ThemeMode.system;

  static const List<Color> accentColors = [
    Color(0xFF6A3DE8), // purple (default)
    Color(0xFF2F80ED), // blue
    Color(0xFF17A2A2), // teal
    Color(0xFF2FB344), // green
    Color(0xFFF2994A), // orange
    Color(0xFFEB5757), // red
    Color(0xFF828282), // grey
  ];

  int accentColorIndex = 0;
  Color get accentColor => accentColors[accentColorIndex];

  String appFont = 'Default';
  String fontSize = 'Medium';
  bool compactLayout = false;
  bool highContrast = false;

  static const List<String> mapStyles = ['Standard', 'Muted', 'Terrain', 'Satellite', 'Night'];
  int mapStylePreviewIndex = 0;

  String get themeModeLabel => switch (themeMode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  // ---------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------

  bool masterNotifications = true;
  bool notifyCaptureSaved = true;
  bool notifyGpsAccuracyWarning = true;
  bool notifyBackupCompleted = true;
  bool notifyBackupFailed = true;
  bool notifyStorageAlmostFull = true;
  bool notifyLocationServicesDisabled = true;
  String reminderToSync = 'Weekly';
  bool notificationSound = true;
  bool notificationVibration = true;
  TimeOfDay quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get quietHoursLabel =>
      '${_formatTimeOfDay(quietHoursStart)} – ${_formatTimeOfDay(quietHoursEnd)}';

  // ---------------------------------------------------------------------
  // GENERIC SETTER — lets simple bool rows update + notify in one line
  // from any screen: `AppSettingsService.instance.set(() => x = value)`.
  // ---------------------------------------------------------------------

  void set(VoidCallback mutate) {
    mutate();
    notifyListeners();
  }
}