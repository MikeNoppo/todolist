import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';
import 'permission_service.dart';

enum NotificationInterruptionMode {
  off('off'),
  filterDistractingApps('filter_distracting_apps'),
  dnd('dnd');

  const NotificationInterruptionMode(this.storageValue);

  final String storageValue;

  static NotificationInterruptionMode fromStorageValue(String? value) {
    for (final mode in NotificationInterruptionMode.values) {
      if (mode.storageValue == value) {
        return mode;
      }
    }

    return NotificationInterruptionMode.off;
  }
}

class NotificationInterruptionService {
  NotificationInterruptionService._();

  static const String _tag = 'NotificationInterruptionService';
  static const String _modeKey = 'notification_interruption_mode';

  static final NotificationInterruptionService _instance =
      NotificationInterruptionService._();

  factory NotificationInterruptionService() => _instance;

  Future<NotificationInterruptionMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_modeKey);
    return NotificationInterruptionMode.fromStorageValue(rawValue);
  }

  Future<void> setMode(NotificationInterruptionMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.storageValue);
    AppLogger.info(
      _tag,
      'Notification interruption mode updated: ${mode.name}',
    );
    await syncNativeState();
  }

  Future<void> syncNativeState() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await PermissionService.syncNotificationInterruptionState();
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to sync native notification interruption state.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
