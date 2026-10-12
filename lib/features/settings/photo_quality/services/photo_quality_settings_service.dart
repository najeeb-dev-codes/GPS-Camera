import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_quality_settings.dart';

class PhotoQualitySettingsService extends ChangeNotifier {
  PhotoQualitySettingsService._();

  static final PhotoQualitySettingsService instance =
      PhotoQualitySettingsService._();

  static const _resolutionKey = 'photo_quality_resolution_v1';
  static const _formatKey = 'photo_quality_format_v1';
  static const _jpegQualityKey = 'photo_quality_jpeg_quality_v1';
  static const _hdrKey = 'photo_quality_hdr_v1';
  static const _autoEnhanceKey = 'photo_quality_auto_enhance_v1';
  static const _watermarkKey = 'photo_quality_watermark_v1';
  static const _preserveExifKey = 'photo_quality_preserve_exif_v1';
  static const _embedGpsKey = 'photo_quality_embed_gps_v1';

  PhotoQualitySettings _settings = const PhotoQualitySettings();
  bool _loaded = false;
  Future<void>? _loading;

  PhotoQualitySettings get current => _settings;

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedResolution = prefs.getString(_resolutionKey);

    _settings = PhotoQualitySettings(
      // High is the default when no resolution has been saved yet.
      // An explicitly selected user's resolution is preserved.
      resolution: savedResolution == null
          ? PhotoQualitySettings.defaultResolution
          : PhotoResolutionOption.fromName(savedResolution),
      format: PhotoImageFormatOption.fromName(
        prefs.getString(_formatKey),
      ),
      jpegQuality: (prefs.getInt(_jpegQualityKey) ?? 95).clamp(1, 100).toInt(),
      hdrCapture: prefs.getBool(_hdrKey) ?? false,
      autoEnhance: prefs.getBool(_autoEnhanceKey) ?? false,
      watermarkCompression: WatermarkCompressionOption.fromName(
        prefs.getString(_watermarkKey),
      ),
      preserveExifMetadata: prefs.getBool(_preserveExifKey) ?? false,
      embedGpsInExif: prefs.getBool(_embedGpsKey) ?? true,
    );

    _loaded = true;
    _loading = null;

    // Store the default so future loads have an explicit High value while
    // keeping any existing user-selected resolution unchanged.
    if (savedResolution == null) {
      await prefs.setString(
        _resolutionKey,
        PhotoQualitySettings.defaultResolution.name,
      );
    }

    notifyListeners();
  }

  void setResolution(PhotoResolutionOption value) {
    _update(_settings.copyWith(resolution: value));
  }

  void setFormat(PhotoImageFormatOption value) {
    _update(_settings.copyWith(format: value));
  }

  void setJpegQuality(double value) {
    _update(
      _settings.copyWith(
        jpegQuality: value.round().clamp(1, 100).toInt(),
      ),
    );
  }

  void setHdrCapture(bool value) {
    _update(_settings.copyWith(hdrCapture: value));
  }

  void setAutoEnhance(bool value) {
    _update(_settings.copyWith(autoEnhance: value));
  }

  void setWatermarkCompression(WatermarkCompressionOption value) {
    _update(_settings.copyWith(watermarkCompression: value));
  }

  void setPreserveExifMetadata(bool value) {
    _update(_settings.copyWith(preserveExifMetadata: value));
  }

  void setEmbedGpsInExif(bool value) {
    _update(_settings.copyWith(embedGpsInExif: value));
  }

  void reset() {
    _update(const PhotoQualitySettings());
  }

  Future<void> save() async {
    await ensureLoaded();
    await _persist();
  }

  void _update(PhotoQualitySettings next) {
    _settings = next;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final value = _settings;

    await Future.wait([
      prefs.setString(_resolutionKey, value.resolution.name),
      prefs.setString(_formatKey, value.format.name),
      prefs.setInt(_jpegQualityKey, value.jpegQuality),
      prefs.setBool(_hdrKey, value.hdrCapture),
      prefs.setBool(_autoEnhanceKey, value.autoEnhance),
      prefs.setString(_watermarkKey, value.watermarkCompression.name),
      prefs.setBool(_preserveExifKey, value.preserveExifMetadata),
      prefs.setBool(_embedGpsKey, value.embedGpsInExif),
    ]);
  }
}
