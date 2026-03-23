import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo_model.dart';
import '../repositories/todo_repository.dart';
import 'app_logger.dart';

class InterventionDebugInfo {
  const InterventionDebugInfo({
    required this.interventionEnabled,
    required this.blockedPackages,
    required this.alwaysAllowedPackages,
    required this.lastBlockedPackage,
    required this.lastBlockedPriority,
    required this.lastBlockedTaskTitle,
    required this.lastBlockedRemainingMinutes,
    required this.lastBlockedWindowHours,
    required this.lastBlockedAt,
    required this.nextTaskTitle,
    required this.nextTaskPriority,
    required this.nextTaskRemainingMinutes,
    required this.nextTaskWindowHours,
  });

  final bool interventionEnabled;
  final List<String> blockedPackages;
  final List<String> alwaysAllowedPackages;

  final String? lastBlockedPackage;
  final String? lastBlockedPriority;
  final String? lastBlockedTaskTitle;
  final int? lastBlockedRemainingMinutes;
  final int? lastBlockedWindowHours;
  final DateTime? lastBlockedAt;

  final String? nextTaskTitle;
  final TodoPriority? nextTaskPriority;
  final int? nextTaskRemainingMinutes;
  final int? nextTaskWindowHours;
}

class _InterventionCandidate {
  const _InterventionCandidate({
    required this.todo,
    required this.remainingMinutes,
    required this.windowHours,
  });

  final TodoModel todo;
  final int remainingMinutes;
  final int windowHours;
}

class AppBlockerService {
  static const String _tag = 'AppBlockerService';

  static const String blockKeyPrefix = 'block_';
  static const String allowKeyPrefix = 'allow_';
  static const String interventionEnabledKey = 'intervention_enabled';
  static const String customQuoteKey = 'intervention_custom_quote';
  static const String lowWindowHoursKey = 'intervention_window_low_hours';
  static const String mediumWindowHoursKey = 'intervention_window_medium_hours';
  static const String highWindowHoursKey = 'intervention_window_high_hours';
  static const String appNameKeyPrefix = 'app_name_';

  static const String debugLastBlockedPackageKey = 'debug_last_blocked_package';
  static const String debugLastBlockedPriorityKey =
      'debug_last_blocked_priority';
  static const String debugLastBlockedTaskTitleKey =
      'debug_last_blocked_task_title';
  static const String debugLastBlockedRemainingMinutesKey =
      'debug_last_blocked_remaining_minutes';
  static const String debugLastBlockedWindowHoursKey =
      'debug_last_blocked_window_hours';
  static const String debugLastBlockedAtMillisKey =
      'debug_last_blocked_at_millis';

  static const int defaultLowWindowHours = 2;
  static const int defaultMediumWindowHours = 8;
  static const int defaultHighWindowHours = 24;

  static const Map<String, String> _appNames = {
    'com.facebook.katana': 'Facebook',
    'com.instagram.android': 'Instagram',
    'com.twitter.android': 'Twitter',
    'com.snapchat.android': 'Snapchat',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.google.android.youtube': 'YouTube',
    'com.spotify.music': 'Spotify',
    'com.netflix.mediaclient': 'Netflix',
  };

  /// Check if an app should be blocked
  static Future<bool> shouldBlockApp(String packageName) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final shouldBlockThisApp = _isAppBlockedByUserSettings(
        prefs: prefs,
        packageName: packageName,
      );

      if (!shouldBlockThisApp) {
        return false;
      }

      final hasUrgentTask = await _hasUrgentTaskWithinWindow(prefs);
      return hasUrgentTask;
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to evaluate block policy for package=$packageName.',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static Future<String?> getCurrentBlockingTaskTitle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todos = await TodoRepository().getTodos();
      final candidate = _findCurrentCandidate(
        prefs: prefs,
        todos: todos,
        now: DateTime.now(),
      );

      return candidate?.todo.title;
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to get current blocking task.',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<InterventionDebugInfo> getInterventionDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final todos = await TodoRepository().getTodos();
    final now = DateTime.now();

    var blockedPackages = prefs
        .getKeys()
        .where((key) => key.startsWith(blockKeyPrefix))
        .where((key) => prefs.getBool(key) ?? false)
        .map((key) => key.replaceFirst(blockKeyPrefix, ''))
        .toList();

    blockedPackages.sort();

    final alwaysAllowedPackages =
        prefs
            .getKeys()
            .where((key) => key.startsWith(allowKeyPrefix))
            .where((key) => prefs.getBool(key) ?? false)
            .map((key) => key.replaceFirst(allowKeyPrefix, ''))
            .toList()
          ..sort();

    blockedPackages = blockedPackages
        .where((packageName) => !alwaysAllowedPackages.contains(packageName))
        .toList();

    final int? lastBlockedAtMillis = prefs.getInt(debugLastBlockedAtMillisKey);
    final DateTime? lastBlockedAt = lastBlockedAtMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastBlockedAtMillis);

    final candidate = _findCurrentCandidate(
      prefs: prefs,
      todos: todos,
      now: now,
    );

    return InterventionDebugInfo(
      interventionEnabled: true,
      blockedPackages: blockedPackages,
      alwaysAllowedPackages: alwaysAllowedPackages,
      lastBlockedPackage: prefs.getString(debugLastBlockedPackageKey),
      lastBlockedPriority: prefs.getString(debugLastBlockedPriorityKey),
      lastBlockedTaskTitle: prefs.getString(debugLastBlockedTaskTitleKey),
      lastBlockedRemainingMinutes: prefs.getInt(
        debugLastBlockedRemainingMinutesKey,
      ),
      lastBlockedWindowHours: prefs.getInt(debugLastBlockedWindowHoursKey),
      lastBlockedAt: lastBlockedAt,
      nextTaskTitle: candidate?.todo.title,
      nextTaskPriority: candidate?.todo.priority,
      nextTaskRemainingMinutes: candidate?.remainingMinutes,
      nextTaskWindowHours: candidate?.windowHours,
    );
  }

  static Future<Map<TodoPriority, int>> getInterventionWindows() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      TodoPriority.low:
          prefs.getInt(lowWindowHoursKey) ?? defaultLowWindowHours,
      TodoPriority.medium:
          prefs.getInt(mediumWindowHoursKey) ?? defaultMediumWindowHours,
      TodoPriority.high:
          prefs.getInt(highWindowHoursKey) ?? defaultHighWindowHours,
    };
  }

  static Future<void> saveInterventionWindow(
    TodoPriority priority,
    int hours,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    switch (priority) {
      case TodoPriority.low:
        await prefs.setInt(lowWindowHoursKey, hours);
        break;
      case TodoPriority.medium:
        await prefs.setInt(mediumWindowHoursKey, hours);
        break;
      case TodoPriority.high:
        await prefs.setInt(highWindowHoursKey, hours);
        break;
    }
  }

  static Future<String?> getCustomQuote() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(customQuoteKey);
  }

  static Future<void> saveCustomQuote(String quote) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedQuote = quote.trim();
    if (trimmedQuote.isEmpty) {
      await prefs.remove(customQuoteKey);
    } else {
      await prefs.setString(customQuoteKey, trimmedQuote);
    }
  }

  static Future<void> setInterventionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(interventionEnabledKey, enabled);
  }

  static Future<void> cacheAppDisplayNames(Map<String, String> appNames) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in appNames.entries) {
      await prefs.setString('$appNameKeyPrefix${entry.key}', entry.value);
    }
  }

  static bool _isAppBlockedByUserSettings({
    required SharedPreferences prefs,
    required String packageName,
  }) {
    final isAlwaysAllowed =
        prefs.getBool('$allowKeyPrefix$packageName') ?? false;
    if (isAlwaysAllowed) {
      return false;
    }

    final hasAnyUserConfig = prefs.getKeys().any(
      (key) => key.startsWith(blockKeyPrefix),
    );

    if (hasAnyUserConfig) {
      return prefs.getBool('$blockKeyPrefix$packageName') ?? false;
    }

    return false;
  }

  static Future<bool> _hasUrgentTaskWithinWindow(
    SharedPreferences prefs,
  ) async {
    final todos = await TodoRepository().getTodos();
    return _findCurrentCandidate(
          prefs: prefs,
          todos: todos,
          now: DateTime.now(),
        ) !=
        null;
  }

  static _InterventionCandidate? _findCurrentCandidate({
    required SharedPreferences prefs,
    required List<TodoModel> todos,
    required DateTime now,
  }) {
    _InterventionCandidate? candidate;

    for (final todo in todos) {
      if (todo.isCompleted) {
        continue;
      }

      final windowHours = _windowHoursForPriority(prefs, todo.priority);
      if (windowHours <= 0) {
        continue;
      }

      final remainingMinutes = todo.deadline.difference(now).inMinutes;
      final maxAllowedMinutes = windowHours * Duration.minutesPerHour;
      if (remainingMinutes > maxAllowedMinutes) {
        continue;
      }

      final nextCandidate = _InterventionCandidate(
        todo: todo,
        remainingMinutes: remainingMinutes,
        windowHours: windowHours,
      );

      if (candidate == null ||
          nextCandidate.remainingMinutes < candidate.remainingMinutes) {
        candidate = nextCandidate;
      }
    }

    return candidate;
  }

  static TodoPriority? parsePriorityLabel(String? priorityValue) {
    switch (priorityValue?.toLowerCase()) {
      case 'low':
        return TodoPriority.low;
      case 'medium':
        return TodoPriority.medium;
      case 'high':
        return TodoPriority.high;
      default:
        return null;
    }
  }

  static int _windowHoursForPriority(
    SharedPreferences prefs,
    TodoPriority priority,
  ) {
    switch (priority) {
      case TodoPriority.low:
        return prefs.getInt(lowWindowHoursKey) ?? defaultLowWindowHours;
      case TodoPriority.medium:
        return prefs.getInt(mediumWindowHoursKey) ?? defaultMediumWindowHours;
      case TodoPriority.high:
        return prefs.getInt(highWindowHoursKey) ?? defaultHighWindowHours;
    }
  }

  static String getAppDisplayName(String packageName) {
    return _appNames[packageName] ?? packageName;
  }
}
