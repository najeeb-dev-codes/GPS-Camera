import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_brand.dart';
import '../models/stamp_style_settings.dart';

/// Single source of truth for every setting shown across the Settings
/// screens (Camera, Stamp Defaults, Photo Quality,
/// File Naming, Storage & Backup, Theme,
/// Notifications, About & Help).
///
/// This is a plain [ChangeNotifier] singleton (`AppSettingsService.instance`)
/// so any screen can read the current value and any screen can change it —
/// Changes made on one screen are instantly reflected everywhere else that
/// reads the same field.
///
/// Wrap a screen's body in an `AnimatedBuilder(animation:
/// AppSettingsService.instance, builder: ...)` (or `ListenableBuilder`) to
/// rebuild automatically when any field changes.
class AppSettingsService extends ChangeNotifier {
  AppSettingsService._() {
    unawaited(_loadCameraSettings());
    unawaited(_loadFileNamingSettings());
    unawaited(ensureStampTemplateSettingsLoaded());
    unawaited(ensureThemeSettingsLoaded());
    unawaited(ensureNotificationSettingsLoaded());
  }

  static final AppSettingsService instance = AppSettingsService._();

  // ---------------------------------------------------------------------
  // CAMERA SETTINGS
  // ---------------------------------------------------------------------

  String defaultCamera = 'Back Camera';
  String captureMode = 'Photo';
  String aspectRatio = 'Full';
  bool gridLines = false;
  bool levelIndicator = false;
  bool tapToFocus = true;
  bool mirrorSelfies = false;
  bool shutterSound = true;
  String volumeKeyAction = 'Capture';
  String timer = 'Off';
  bool saveOriginalPhoto = false;
  bool showGpsAccuracyMeter = false;

  static const String _cameraPrefix = 'camera_setting_';
  bool _cameraSettingsLoaded = false;

  Future<void> ensureCameraSettingsLoaded() => _loadCameraSettings();

  Future<void> _loadCameraSettings() async {
    if (_cameraSettingsLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    defaultCamera = prefs.getString('${_cameraPrefix}defaultCamera') ?? 'Back Camera';
    captureMode = prefs.getString('${_cameraPrefix}captureMode') ?? 'Photo';
    aspectRatio = prefs.getString('${_cameraPrefix}aspectRatio') ?? 'Full';
    gridLines = prefs.getBool('${_cameraPrefix}gridLines') ?? false;
    levelIndicator = prefs.getBool('${_cameraPrefix}levelIndicator') ?? false;
    showGpsAccuracyMeter =
        prefs.getBool('${_cameraPrefix}showGpsAccuracyMeter') ?? false;
    tapToFocus = prefs.getBool('${_cameraPrefix}tapToFocus') ?? true;
    mirrorSelfies = prefs.getBool('${_cameraPrefix}mirrorSelfies') ?? false;
    shutterSound = prefs.getBool('${_cameraPrefix}shutterSound') ?? true;
    volumeKeyAction =
        prefs.getString('${_cameraPrefix}volumeKeyAction') ?? 'Capture';
    timer = prefs.getString('${_cameraPrefix}timer') ?? 'Off';
    saveOriginalPhoto =
        prefs.getBool('${_cameraPrefix}saveOriginalPhoto') ?? false;
    _cameraSettingsLoaded = true;
    notifyListeners();
  }

  Future<void> _saveCameraSettings() async {
    if (!_cameraSettingsLoaded) await _loadCameraSettings();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      prefs.setString('${_cameraPrefix}defaultCamera', defaultCamera),
      prefs.setString('${_cameraPrefix}captureMode', captureMode),
      prefs.setString('${_cameraPrefix}aspectRatio', aspectRatio),
      prefs.setBool('${_cameraPrefix}gridLines', gridLines),
      prefs.setBool('${_cameraPrefix}levelIndicator', levelIndicator),
      prefs.setBool('${_cameraPrefix}showGpsAccuracyMeter', showGpsAccuracyMeter),
      prefs.setBool('${_cameraPrefix}tapToFocus', tapToFocus),
      prefs.setBool('${_cameraPrefix}mirrorSelfies', mirrorSelfies),
      prefs.setBool('${_cameraPrefix}shutterSound', shutterSound),
      prefs.setString('${_cameraPrefix}volumeKeyAction', volumeKeyAction),
      prefs.setString('${_cameraPrefix}timer', timer),
      prefs.setBool('${_cameraPrefix}saveOriginalPhoto', saveOriginalPhoto),
    ]);
  }

  Future<void> saveCameraSettings() async {
    await _saveCameraSettings();
  }

  void resetCameraSettings() {
    defaultCamera = 'Back Camera';
    captureMode = 'Photo';
    aspectRatio = 'Full';
    gridLines = false;
    levelIndicator = false;
    showGpsAccuracyMeter = false;
    tapToFocus = true;
    mirrorSelfies = false;
    shutterSound = true;
    volumeKeyAction = 'Capture';
    timer = 'Off';
    saveOriginalPhoto = false;
    notifyListeners();
    unawaited(_saveCameraSettings());
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
  // Optional stamp fields. Both are hidden in the default stamp because the
  // full location/address/coordinates remain the primary proof information.
  bool showAltitude = false;
  bool showAccuracy = false;
  bool showNote = false;
  bool showLogo = false;

  String stampPosition = 'Bottom Right';
  double stampDefaultSize = 90;
  double stampOpacity = 80;

  /// The template applied by the user and restored when the app reopens.
  int selectedStampTemplateIndex = 0;

  static const String _selectedStampTemplateKey =
      'selected_stamp_template_index_v1';
  bool _stampTemplateSettingsLoaded = false;
  Future<void>? _stampTemplateSettingsLoading;

  Future<void> ensureStampTemplateSettingsLoaded() {
    if (_stampTemplateSettingsLoaded) return Future<void>.value();

    final activeLoad = _stampTemplateSettingsLoading;
    if (activeLoad != null) return activeLoad;

    final load = _loadStampTemplateSettings();
    _stampTemplateSettingsLoading = load;
    return load;
  }

  Future<void> _loadStampTemplateSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_selectedStampTemplateKey) ?? 0;
      selectedStampTemplateIndex =
          savedIndex.clamp(0, _stampStyles.length - 1).toInt();
      _stampTemplateSettingsLoaded = true;
      notifyListeners();
    } finally {
      _stampTemplateSettingsLoading = null;
    }
  }

  Future<void> setSelectedStampTemplateIndex(int templateIndex) async {
    await ensureStampTemplateSettingsLoaded();

    final safeIndex =
        templateIndex.clamp(0, _stampStyles.length - 1).toInt();
    selectedStampTemplateIndex = safeIndex;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedStampTemplateKey, safeIndex);
    _stampTemplateSettingsLoaded = true;
  }

  /// Each built-in stamp keeps its own editable style.
  final List<StampStyleSettings> _stampStyles =
      List<StampStyleSettings>.of(kDefaultStampStyles);

  StampStyleSettings stampStyleFor(int templateIndex) {
    final index = templateIndex.clamp(0, _stampStyles.length - 1).toInt();
    return _stampStyles[index];
  }

  void saveStampStyle(int templateIndex, StampStyleSettings style) {
    final index = templateIndex.clamp(0, _stampStyles.length - 1).toInt();
    _stampStyles[index] = style;
    notifyListeners();
  }

  StampStyleSettings resetStampStyle(int templateIndex) {
    final index = templateIndex.clamp(0, kDefaultStampStyles.length - 1).toInt();
    final defaults = kDefaultStampStyles[index];
    _stampStyles[index] = defaults;
    notifyListeners();
    return defaults;
  }

  // ---------------------------------------------------------------------
  // PHOTO QUALITY
  // ---------------------------------------------------------------------

  String photoResolution = 'High';
  String imageFormat = 'PNG';
  double jpegQuality = 95;
  bool hdrCapture = true;
  bool autoEnhance = false;
  String watermarkCompression = 'Balanced';
  bool preserveExifMetadata = false;
  bool embedGpsInExif = true;

  /// Rough estimated file size range shown at the bottom of Photo Quality,
  /// derived from the current resolution / format / quality choices.
  String get estimatedPhotoSize {
    final base = switch (photoResolution) {
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
    photoResolution = 'High';
    imageFormat = 'PNG';
    jpegQuality = 95;
    hdrCapture = true;
    autoEnhance = false;
    watermarkCompression = 'Balanced';
    preserveExifMetadata = false;
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

  String fileNamingPrefix = 'GPSMark';
  String dateFormat = 'YYYYMMDD';
  String timeFormat = 'HHmmss';
  bool sequenceNumberEnabled = false;
  int sequenceStartNumber = 1;
  bool avoidDuplicateNames = true;

  static const String _namingPrefix = 'file_naming_setting_';
  bool _fileNamingSettingsLoaded = false;

  Future<void> ensureFileNamingSettingsLoaded() => _loadFileNamingSettings();

  Future<void> _loadFileNamingSettings() async {
    if (_fileNamingSettingsLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final storedPattern = prefs.getStringList('${_namingPrefix}pattern');
    final storedPrefix = prefs.getString('${_namingPrefix}prefix');
    final storedSequenceEnabled =
        prefs.getBool('${_namingPrefix}sequenceEnabled');

    final isLegacyDefault = storedPattern != null &&
        storedPattern.length == 1 &&
        storedPattern.first == 'Sequence' &&
        (storedPrefix == null || storedPrefix == 'GPS') &&
        (storedSequenceEnabled == null || storedSequenceEnabled);

    namingPatternChips = isLegacyDefault
        ? <String>['Project', 'Date', 'Time']
        : (storedPattern ?? <String>['Project', 'Date', 'Time']);
    fileNamingPrefix = isLegacyDefault
        ? 'GPSMark'
        : (storedPrefix ?? 'GPSMark');
    dateFormat = prefs.getString('${_namingPrefix}dateFormat') ?? 'YYYYMMDD';
    timeFormat = prefs.getString('${_namingPrefix}timeFormat') ?? 'HHmmss';
    sequenceNumberEnabled =
        isLegacyDefault ? false : (storedSequenceEnabled ?? false);
    sequenceStartNumber = prefs.getInt('${_namingPrefix}sequenceStart') ?? 1;
    avoidDuplicateNames =
        prefs.getBool('${_namingPrefix}avoidDuplicates') ?? true;
    _fileNamingSettingsLoaded = true;
    notifyListeners();
  }

  void resetFileNamingSettings() {
    namingPatternChips = <String>['Project', 'Date', 'Time'];
    fileNamingPrefix = 'GPSMark';
    dateFormat = 'YYYYMMDD';
    timeFormat = 'HHmmss';
    sequenceNumberEnabled = false;
    sequenceStartNumber = 1;
    avoidDuplicateNames = true;
    notifyListeners();
    unawaited(saveFileNamingSettings());
  }

  Future<void> saveFileNamingSettings() async {
    if (!_fileNamingSettingsLoaded) await _loadFileNamingSettings();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      prefs.setStringList('${_namingPrefix}pattern', namingPatternChips),
      prefs.setString('${_namingPrefix}prefix', fileNamingPrefix),
      prefs.setString('${_namingPrefix}dateFormat', dateFormat),
      prefs.setString('${_namingPrefix}timeFormat', timeFormat),
      prefs.setBool('${_namingPrefix}sequenceEnabled', sequenceNumberEnabled),
      prefs.setInt('${_namingPrefix}sequenceStart', sequenceStartNumber),
      prefs.setBool('${_namingPrefix}avoidDuplicates', avoidDuplicateNames),
    ]);
  }

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
    unawaited(saveFileNamingSettings());
  }

  // ---------------------------------------------------------------------
  // STORAGE & BACKUP
  // ---------------------------------------------------------------------

  double storageUsedGb = 2.4;
  double storageTotalGb = 10;
  String saveLocation = AppBrand.galleryPath;
  bool createProjectFolders = true;

  double get storageUsedFraction =>
      storageTotalGb == 0 ? 0 : (storageUsedGb / storageTotalGb).clamp(0, 1);

  int get storageUsedPercent => (storageUsedFraction * 100).round();

  // ---------------------------------------------------------------------
  // THEME
  // ---------------------------------------------------------------------

  ThemeMode themeMode = ThemeMode.light;
  static const int defaultAccentColorValue = 0xFF6D28D9;
  Color accentColor = const Color(defaultAccentColorValue);
  static const String _themeModeKey = 'theme_mode_v2';
  static const String _accentColorKey = 'app_accent_color_v1';
  bool _themeSettingsLoaded = false;
  Future<void>? _themeSettingsLoading;

  Future<void> ensureThemeSettingsLoaded() {
    if (_themeSettingsLoaded) return Future<void>.value();
    return _themeSettingsLoading ??= _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      themeMode = switch (savedMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
      accentColor = Color(
        prefs.getInt(_accentColorKey) ?? defaultAccentColorValue,
      ).withValues(alpha: 1);
      _themeSettingsLoaded = true;
      notifyListeners();
    } finally {
      _themeSettingsLoading = null;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ensureThemeSettingsLoaded();
    themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeModeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
    _themeSettingsLoaded = true;
  }

  Future<void> setAccentColor(Color color) async {
    await ensureThemeSettingsLoaded();
    final nextColor = color.withValues(alpha: 1);
    if (accentColor.toARGB32() == nextColor.toARGB32()) return;

    accentColor = nextColor;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, nextColor.toARGB32());
    _themeSettingsLoaded = true;
  }

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
  bool notifyProjectCreated = true;
  bool notifyGpsAccuracyWarning = false;
  bool notifyStorageAlmostFull = true;
  bool notifyLocationServicesDisabled = true;
  bool notificationSound = true;
  bool notificationVibration = false;

  static const String _notificationPrefix = 'notification_setting_';
  bool _notificationSettingsLoaded = false;
  Future<void>? _notificationSettingsLoading;

  Future<void> ensureNotificationSettingsLoaded() {
    if (_notificationSettingsLoaded) return Future<void>.value();
    final activeLoad = _notificationSettingsLoading;
    if (activeLoad != null) return activeLoad;
    final load = _loadNotificationSettings();
    _notificationSettingsLoading = load;
    return load;
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      masterNotifications =
          prefs.getBool('${_notificationPrefix}master') ?? true;
      notifyCaptureSaved =
          prefs.getBool('${_notificationPrefix}captureSaved') ?? true;
      notifyProjectCreated =
          prefs.getBool('${_notificationPrefix}projectCreated') ?? true;
      notifyGpsAccuracyWarning =
          prefs.getBool('${_notificationPrefix}gpsAccuracyWarning') ?? false;
      notifyStorageAlmostFull =
          prefs.getBool('${_notificationPrefix}storageAlmostFull') ?? true;
      notifyLocationServicesDisabled = prefs.getBool(
            '${_notificationPrefix}locationServicesDisabled',
          ) ??
          true;
      final savedSound =
          prefs.getBool('${_notificationPrefix}sound') ?? true;
      final savedVibration =
          prefs.getBool('${_notificationPrefix}vibration') ?? false;
      if (savedVibration && !savedSound) {
        notificationSound = false;
        notificationVibration = true;
      } else {
        notificationSound = true;
        notificationVibration = false;
      }
      _notificationSettingsLoaded = true;
      notifyListeners();
    } finally {
      _notificationSettingsLoading = null;
    }
  }

  void resetNotificationSettings() {
    masterNotifications = true;
    notifyCaptureSaved = true;
    notifyProjectCreated = true;
    notifyGpsAccuracyWarning = false;
    notifyStorageAlmostFull = true;
    notifyLocationServicesDisabled = true;
    notificationSound = true;
    notificationVibration = false;
    notifyListeners();
    unawaited(saveNotificationSettings());
  }

  Future<void> saveNotificationSettings() async {
    await ensureNotificationSettingsLoaded();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      prefs.setBool('${_notificationPrefix}master', masterNotifications),
      prefs.setBool('${_notificationPrefix}captureSaved', notifyCaptureSaved),
      prefs.setBool(
        '${_notificationPrefix}projectCreated',
        notifyProjectCreated,
      ),
      prefs.setBool(
        '${_notificationPrefix}gpsAccuracyWarning',
        notifyGpsAccuracyWarning,
      ),
      prefs.setBool(
        '${_notificationPrefix}storageAlmostFull',
        notifyStorageAlmostFull,
      ),
      prefs.setBool(
        '${_notificationPrefix}locationServicesDisabled',
        notifyLocationServicesDisabled,
      ),
      prefs.setBool('${_notificationPrefix}sound', notificationSound),
      prefs.setBool('${_notificationPrefix}vibration', notificationVibration),
    ]);
  }

  void setNotification(VoidCallback mutate) {
    mutate();
    notifyListeners();
    unawaited(saveNotificationSettings());
  }

  void setNotificationSound(bool enabled) {
    if (!enabled && !notificationVibration) return;
    notificationSound = enabled;
    if (enabled) notificationVibration = false;
    notifyListeners();
    unawaited(saveNotificationSettings());
  }

  void setNotificationVibration(bool enabled) {
    if (!enabled && !notificationSound) return;
    notificationVibration = enabled;
    if (enabled) notificationSound = false;
    notifyListeners();
    unawaited(saveNotificationSettings());
  }

  // ---------------------------------------------------------------------
  // GENERIC SETTER — lets simple bool rows update + notify in one line
  // from any screen: `AppSettingsService.instance.set(() => x = value)`.
  // ---------------------------------------------------------------------

  void set(VoidCallback mutate) {
    mutate();
    notifyListeners();
    unawaited(saveFileNamingSettings());
    unawaited(_saveCameraSettings());
  }
}


