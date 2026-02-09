import 'package:flutter/services.dart';

import 'app_logger.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel('app_blocker/permissions');

  /// Check if accessibility service is enabled
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool isEnabled = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return isEnabled;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        'PermissionService',
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
        'PermissionService',
        'Failed to open accessibility settings.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if usage stats permission is granted using native method
  static Future<bool> isUsageStatsPermissionGranted() async {
    try {
      final bool isGranted = await _channel.invokeMethod('isUsageStatsPermissionGranted');
      return isGranted;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        'PermissionService',
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
        'PermissionService',
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
}
