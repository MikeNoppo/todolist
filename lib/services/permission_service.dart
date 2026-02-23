import 'package:flutter/services.dart';

import '../models/installed_focus_app.dart';
import 'app_logger.dart';

class PermissionService {
  static const String _tag = 'PermissionService';

  static const MethodChannel _channel = MethodChannel(
    'app_blocker/permissions',
  );

  /// Check if accessibility service is enabled
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool isEnabled = await _channel.invokeMethod(
        'isAccessibilityServiceEnabled',
      );
      return isEnabled;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to check accessibility service.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Open accessibility settings
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to open accessibility settings.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if usage stats permission is granted using native method
  static Future<bool> isUsageStatsPermissionGranted() async {
    try {
      final bool isGranted = await _channel.invokeMethod(
        'isUsageStatsPermissionGranted',
      );
      return isGranted;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to check usage stats permission.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Open usage stats settings
  static Future<void> openUsageStatsSettings() async {
    try {
      await _channel.invokeMethod('openUsageStatsSettings');
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to open usage stats settings.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final bool accessibilityEnabled = await isAccessibilityServiceEnabled();
    final bool usageStatsGranted = await isUsageStatsPermissionGranted();
    return accessibilityEnabled && usageStatsGranted;
  }

  static Future<String?> consumeBlockedPackage() async {
    try {
      final String? packageName = await _channel.invokeMethod<String>(
        'consumeBlockedPackage',
      );
      return packageName;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to consume blocked package event.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<List<InstalledFocusApp>> getInstalledFocusApps() async {
    try {
      final List<dynamic>? rawApps = await _channel.invokeMethod<List<dynamic>>(
        'getInstalledFocusApps',
      );

      if (rawApps == null) {
        return [];
      }

      final apps = rawApps
          .whereType<Map<dynamic, dynamic>>()
          .map(InstalledFocusApp.fromMap)
          .where((app) => app.packageName.isNotEmpty && app.appName.isNotEmpty)
          .toList();

      return apps;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to fetch installed focus apps.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
      return [];
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to parse installed focus apps.',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}
