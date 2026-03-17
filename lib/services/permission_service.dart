import 'package:flutter/services.dart';

import '../models/installed_focus_app.dart';
import 'app_logger.dart';

typedef BlockedPackageQueuedListener = void Function(String packageName);

class PermissionService {
  static const String _tag = 'PermissionService';

  static const MethodChannel _channel = MethodChannel(
    'app_blocker/permissions',
  );

  static BlockedPackageQueuedListener? _blockedPackageQueuedListener;
  static bool _incomingHandlerBound = false;

  static void setBlockedPackageQueuedListener(
    BlockedPackageQueuedListener? listener,
  ) {
    _blockedPackageQueuedListener = listener;
    if (_incomingHandlerBound) {
      return;
    }

    _incomingHandlerBound = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'blockedPackageQueued') {
        AppLogger.warn(
          _tag,
          'Unhandled incoming method call: method=${call.method}',
        );
        return;
      }

      final packageName = call.arguments?.toString();
      AppLogger.debug(
        _tag,
        'Incoming blocked package queued event: package=$packageName',
      );

      if (packageName == null || packageName.isEmpty) {
        return;
      }

      _blockedPackageQueuedListener?.call(packageName);
    });
  }

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

  static Future<String?> peekBlockedPackage() async {
    try {
      final String? packageName = await _channel.invokeMethod<String>(
        'peekBlockedPackage',
      );
      AppLogger.debug(_tag, 'Peek blocked package event: package=$packageName');
      return packageName;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to peek blocked package event.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<bool> acknowledgeBlockedPackage(String packageName) async {
    try {
      final bool? acknowledged = await _channel.invokeMethod<bool>(
        'acknowledgeBlockedPackage',
        <String, dynamic>{'packageName': packageName},
      );
      AppLogger.debug(
        _tag,
        'Acknowledge blocked package: package=$packageName acknowledged=$acknowledged',
      );
      return acknowledged ?? false;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to acknowledge blocked package event.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
      return false;
    }
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

  static Future<bool> isNotificationListenerAccessGranted() async {
    try {
      final bool? isGranted = await _channel.invokeMethod<bool>(
        'isNotificationListenerAccessGranted',
      );
      return isGranted ?? false;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to check notification listener access.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to check notification listener access.',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to open notification listener settings.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to open notification listener settings.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<bool> isDoNotDisturbAccessGranted() async {
    try {
      final bool? isGranted = await _channel.invokeMethod<bool>(
        'isDoNotDisturbAccessGranted',
      );
      return isGranted ?? false;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to check Do Not Disturb access.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to check Do Not Disturb access.',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static Future<void> openDoNotDisturbSettings() async {
    try {
      await _channel.invokeMethod('openDoNotDisturbSettings');
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to open Do Not Disturb settings.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to open Do Not Disturb settings.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> syncNotificationInterruptionState() async {
    try {
      await _channel.invokeMethod('syncNotificationInterruptionState');
    } on MissingPluginException {
      AppLogger.debug(
        _tag,
        'Skipping notification interruption sync because native bridge is unavailable.',
      );
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to sync notification interruption state.',
        error: e.message ?? e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to sync notification interruption state.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
