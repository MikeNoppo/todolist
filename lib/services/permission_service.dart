import 'package:flutter/services.dart';

import '../models/adaptive_limit_summary.dart';
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

  static Future<Map<String, int>> getAppUsageStats({
    required List<String> packageNames,
    int? startMs,
    int? endMs,
  }) async {
    try {
      final arguments = <String, Object>{'packageNames': packageNames};
      if (startMs != null) {
        arguments['startMs'] = startMs;
      }
      if (endMs != null) {
        arguments['endMs'] = endMs;
      }

      final rawUsage = await _channel.invokeMethod<Object?>(
        'getAppUsageStats',
        arguments,
      );

      return _parseUsageMap(rawUsage);
    } on PlatformException catch (e, stackTrace) {
      _logUsageStatsError('Failed to fetch app usage stats.', e, stackTrace);
      return {};
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to parse app usage stats.',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  static Future<Map<String, Map<String, int>>> getAppUsageHistory({
    required List<String> packageNames,
    int days = 7,
  }) async {
    try {
      final rawHistory = await _channel.invokeMethod<Object?>(
        'getAppUsageHistory',
        {'packageNames': packageNames, 'days': days},
      );

      if (rawHistory is! Map) {
        return {};
      }

      return rawHistory.map((date, rawUsage) {
        return MapEntry(date.toString(), _parseUsageMap(rawUsage));
      });
    } on PlatformException catch (e, stackTrace) {
      _logUsageStatsError('Failed to fetch app usage history.', e, stackTrace);
      return {};
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to parse app usage history.',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  static Future<int> getAppCurrentSession({required String packageName}) async {
    try {
      final rawSession = await _channel.invokeMethod<Object?>(
        'getAppCurrentSession',
        {'packageName': packageName},
      );

      return rawSession is num ? rawSession.toInt() : 0;
    } on PlatformException catch (e, stackTrace) {
      _logUsageStatsError(
        'Failed to fetch current app session.',
        e,
        stackTrace,
      );
      return 0;
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to parse current app session.',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  static Future<Map<String, AdaptiveLimitSummary>> getAdaptiveLimitSummaries({
    required List<String> packageNames,
    required String priority,
  }) async {
    try {
      final rawSummaries = await _channel.invokeMethod<Object?>(
        'getAdaptiveLimitSummaries',
        {'packageNames': packageNames, 'priority': priority},
      );

      if (rawSummaries is! List) {
        return {};
      }

      final summaries = <String, AdaptiveLimitSummary>{};
      for (final rawSummary
          in rawSummaries.whereType<Map<dynamic, dynamic>>()) {
        final summary = AdaptiveLimitSummary.fromMap(rawSummary);
        if (summary.packageName.isNotEmpty) {
          summaries[summary.packageName] = summary;
        }
      }

      return summaries;
    } on PlatformException catch (e, stackTrace) {
      _logUsageStatsError(
        'Failed to fetch adaptive limit summaries.',
        e,
        stackTrace,
      );
      return {};
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to parse adaptive limit summaries.',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
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

  static Map<String, int> _parseUsageMap(Object? rawUsage) {
    if (rawUsage is! Map) {
      return {};
    }

    return rawUsage.map((packageName, usageMs) {
      final totalTimeMs = usageMs is num ? usageMs.toInt() : 0;
      return MapEntry(packageName.toString(), totalTimeMs);
    })..removeWhere((packageName, totalTimeMs) {
      return packageName.isEmpty || totalTimeMs <= 0;
    });
  }

  static void _logUsageStatsError(
    String message,
    PlatformException exception,
    StackTrace stackTrace,
  ) {
    if (exception.code == 'PERMISSION_DENIED') {
      AppLogger.warn(_tag, '$message Usage access has not been granted.');
      return;
    }

    AppLogger.error(
      _tag,
      message,
      error: exception.message ?? exception,
      stackTrace: stackTrace,
    );
  }
}
