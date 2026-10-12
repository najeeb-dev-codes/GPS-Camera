import 'dart:io';

import 'package:flutter/services.dart';

/// Opens the Android internet connectivity panel without adding a plugin.
class InternetSettingsService {
  const InternetSettingsService._();

  static const MethodChannel _channel =
      MethodChannel('gps_camera/internet_settings');

  static Future<bool> open() async {
    if (!Platform.isAndroid) return false;

    try {
      return await _channel.invokeMethod<bool>('openInternetSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
