





import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Generates (once) and persists the unique `installation_id` the backend
/// uses to identify this app install, e.g. `INS-8F29A1B4`.
///
/// Generated the first time it's asked for, then read from
/// SharedPreferences forever after — surviving app updates, and only
/// resetting on a genuine uninstall/reinstall (which is the desired
/// behavior: a reinstall should register as a "new" device).
class InstallationIdService {
  InstallationIdService._();

  static const String _key = 'device_installation_id_v1';
  static const Uuid _uuid = Uuid();

  static String? _cached;

  static Future<String> getOrCreate() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);

    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }

    final generated = _generate();
    await prefs.setString(_key, generated);
    _cached = generated;
    return generated;
  }

  static String _generate() {
    final raw = _uuid.v4().replaceAll('-', '').toUpperCase();
    return 'INS-${raw.substring(0, 8)}';
  }
}