import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

/// Persistent source of truth for real in-app notifications.
class NotificationRepository extends ChangeNotifier {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();
  static const String _storageKey = 'gps_camera_in_app_notifications_v1';

  /// Removed after migrating users who installed the temporary test-data
  /// build. This key must remain only for that one-time cleanup.
  static const String _legacyTestDataSeededKey =
      'gps_camera_notification_test_data_seeded_v1';

  final List<AppNotification> _items = <AppNotification>[];
  bool _loaded = false;
  Future<void>? _loading;

  List<AppNotification> get notifications => List.unmodifiable(
        List<AppNotification>.of(_items)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  int get unreadCount => _items.where((item) => !item.isRead).length;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final pending = _loading;
    if (pending != null) return pending;

    final load = _load();
    _loading = load;
    try {
      await load;
    } finally {
      _loading = null;
    }
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    _items.clear();

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final value in decoded) {
          try {
            _items.add(
              AppNotification.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            );
          } catch (_) {
            // Keep valid notifications if one saved record is damaged.
          }
        }
      } catch (_) {
        // Invalid storage starts with a safe empty notification list.
      }
    }

    // Remove test notifications already saved by the temporary seeded build.
    // Real notifications use timestamp IDs, so this does not affect them.
    final countBeforeCleanup = _items.length;
    _items.removeWhere((item) => item.id.startsWith('test_'));
    if (_items.length != countBeforeCleanup) {
      await preferences.setString(
        _storageKey,
        jsonEncode(_items.map((item) => item.toJson()).toList()),
      );
    }
    await preferences.remove(_legacyTestDataSeededKey);

    _loaded = true;
    notifyListeners();
  }

  Future<void> add({
    required String title,
    required String message,
    required AppNotificationType type,
    DateTime? createdAt,
    String? relatedPhotoId,
  }) async {
    await ensureLoaded();
    final timestamp = createdAt ?? DateTime.now();
    _items.insert(
      0,
      AppNotification(
        id: timestamp.microsecondsSinceEpoch.toString(),
        title: title,
        message: message,
        createdAt: timestamp,
        type: type,
        relatedPhotoId: relatedPhotoId,
      ),
    );
    await _persist();
  }

  Future<void> markRead(String id) async {
    await ensureLoaded();
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _items[index].isRead) return;
    _items[index] = _items[index].copyWith(isRead: true);
    await _persist();
  }

  Future<void> markAllRead() async {
    await ensureLoaded();
    var changed = false;
    for (var index = 0; index < _items.length; index++) {
      if (_items[index].isRead) continue;
      _items[index] = _items[index].copyWith(isRead: true);
      changed = true;
    }
    if (changed) await _persist();
  }

  Future<void> delete(String id) async {
    if (!_loaded) await ensureLoaded();
    final countBeforeDelete = _items.length;
    _items.removeWhere((item) => item.id == id);
    if (_items.length == countBeforeDelete) return;

    // Update the screen immediately while storage finishes in the background.
    notifyListeners();
    await _persist(notify: false);
  }

  Future<void> _persist({bool notify = true}) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(_items.map((item) => item.toJson()).toList()),
    );
    if (!saved) throw Exception('Unable to save notifications.');
    if (notify) notifyListeners();
  }
}
