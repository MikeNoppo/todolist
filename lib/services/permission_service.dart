import 'package:flutter/services.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel('app_blocker/permissions');

  /// Check if accessibility service is enabled
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool isEnabled = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return isEnabled;
    } on PlatformException catch (e) {
      print("Failed to check accessibility service: '${e.message}'.");
      return false;
    }
  }

  /// Open accessibility settings
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print("Failed to open accessibility settings: '${e.message}'.");
    }
  }

  /// Check if usage stats permission is granted using native method
  static Future<bool> isUsageStatsPermissionGranted() async {
    try {
      final bool isGranted = await _channel.invokeMethod('isUsageStatsPermissionGranted');
      return isGranted;
    } on PlatformException catch (e) {
      print("Failed to check usage stats permission: '${e.message}'.");
      return false;
    }
  }

  /// Open usage stats settings
  static Future<void> openUsageStatsSettings() async {
    try {
      await _channel.invokeMethod('openUsageStatsSettings');
    } on PlatformException catch (e) {
      print("Failed to open usage stats settings: '${e.message}'.");
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final bool accessibilityEnabled = await isAccessibilityServiceEnabled();
    final bool usageStatsGranted = await isUsageStatsPermissionGranted();
    return accessibilityEnabled && usageStatsGranted;
  }
}
