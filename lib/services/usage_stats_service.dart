import 'dart:async';

import '../models/app_usage_stat.dart';
import 'app_logger.dart';
import 'permission_service.dart';

class UsageStatsService {
  const UsageStatsService();

  static const String _tag = 'UsageStatsService';
  static const Duration defaultPollingInterval = Duration(seconds: 10);

  Future<List<AppUsageStat>> getTodayUsageForApps(
    List<String> packageNames,
  ) async {
    final normalizedPackages = _normalizePackageNames(packageNames);
    if (normalizedPackages.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final usageByPackage = await PermissionService.getAppUsageStats(
      packageNames: normalizedPackages,
      startMs: today.millisecondsSinceEpoch,
      endMs: now.millisecondsSinceEpoch,
    );

    return _toSortedStats(usageByPackage, today);
  }

  Future<Map<String, List<AppUsageStat>>> getUsageHistory({
    required List<String> packageNames,
    int days = 7,
  }) async {
    final normalizedPackages = _normalizePackageNames(packageNames);
    if (normalizedPackages.isEmpty) {
      return {};
    }

    final rawHistory = await PermissionService.getAppUsageHistory(
      packageNames: normalizedPackages,
      days: days,
    );
    final orderedDates = rawHistory.keys.toList()..sort();
    final history = <String, List<AppUsageStat>>{};

    for (final dateKey in orderedDates) {
      final date = DateTime.tryParse(dateKey) ?? DateTime.now();
      history[dateKey] = _toSortedStats(rawHistory[dateKey] ?? {}, date);
    }

    return history;
  }

  Future<int> getCurrentSessionForApp(String packageName) async {
    if (packageName.isEmpty) {
      return 0;
    }

    return PermissionService.getAppCurrentSession(packageName: packageName);
  }

  Stream<Map<String, int>> watchCurrentSessions(
    List<String> packageNames, {
    Duration interval = defaultPollingInterval,
  }) {
    final normalizedPackages = _normalizePackageNames(packageNames);
    Timer? timer;
    var isPolling = false;

    final controller = StreamController<Map<String, int>>();

    Future<void> emitSnapshot() async {
      if (controller.isClosed) {
        return;
      }

      if (normalizedPackages.isEmpty) {
        controller.add({});
        return;
      }

      if (isPolling) {
        return;
      }

      isPolling = true;
      try {
        final sessions = await PermissionService.getAppCurrentSessions(
          packageNames: normalizedPackages,
        );

        if (!controller.isClosed) {
          controller.add(sessions);
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          _tag,
          'Failed to poll current app sessions.',
          error: e,
          stackTrace: stackTrace,
        );
        if (!controller.isClosed) {
          controller.add({});
        }
      } finally {
        isPolling = false;
      }
    }

    controller.onListen = () {
      unawaited(emitSnapshot());
      timer = Timer.periodic(interval, (_) => unawaited(emitSnapshot()));
    };
    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }

  List<String> _normalizePackageNames(List<String> packageNames) {
    return packageNames
        .where((packageName) => packageName.isNotEmpty)
        .toSet()
        .toList();
  }

  List<AppUsageStat> _toSortedStats(
    Map<String, int> usageByPackage,
    DateTime date,
  ) {
    final stats =
        usageByPackage.entries
            .map(
              (entry) => AppUsageStat(
                packageName: entry.key,
                totalTimeMs: entry.value,
                date: date,
              ),
            )
            .where((stat) => stat.hasUsage)
            .toList()
          ..sort(
            (left, right) => right.totalTimeMs.compareTo(left.totalTimeMs),
          );

    return stats;
  }
}
