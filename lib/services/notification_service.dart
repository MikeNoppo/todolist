import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/todo_model.dart';
import '../repositories/todo_repository.dart';
import 'app_logger.dart';

enum DailyReminderSyncResult { scheduled, noPendingTasks, disabled, failed }

enum TaskNotificationSyncResult {
  scheduled,
  nothingToSchedule,
  disabled,
  failed,
}

enum NotificationPermissionStatus { granted, denied, failed }

/// Callback yang dipanggil saat notifikasi ditekan (harus top-level function).
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  AppLogger.debug(
    'NotificationService',
    'Notification tapped: payload=${response.payload}',
  );
}

class NotificationService {
  static const String _tag = 'NotificationService';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void> Function(int pendingCount, int hour, int minute)?
  _dailyReminderSchedulerOverrideForTesting;

  bool _isInitialized = false;

  /// Whether initialization has been attempted and failed permanently.
  /// After [_maxInitRetries] failures, we stop retrying.
  int _initAttempts = 0;
  static const int _maxInitRetries = 3;

  // Notification channel IDs
  static const String _taskReminderChannelId = 'task_reminders';
  static const String _taskReminderChannelName = 'Pengingat Tugas';
  static const String _taskReminderChannelDesc =
      'Notifikasi pengingat sebelum dan saat deadline tugas';

  static const String _dailySummaryChannelId = 'daily_summary';
  static const String _dailySummaryChannelName = 'Ringkasan Harian';
  static const String _dailySummaryChannelDesc =
      'Notifikasi ringkasan tugas harian setiap pagi';

  // SharedPreferences keys
  static const String legacyNotificationsEnabledKey = 'notifications_enabled';
  static const String taskNotificationsEnabledKey =
      'task_notifications_enabled';
  static const String dailyReminderEnabledKey = 'daily_reminder_enabled';
  static const String dailyReminderHourKey = 'daily_reminder_hour';
  static const String dailyReminderMinuteKey = 'daily_reminder_minute';
  static const String _settingsMigrationCompletedKey =
      'notification_settings_migrated_v2';

  // Notification ID scheme:
  // Todo IDs are millisecondsSinceEpoch strings (e.g. "1735689600000").
  // We parse the numeric ID, take a stable range, and multiply by 10
  // to reserve slots 0-4 for per-todo reminder offsets.
  // Daily summary uses a fixed ID.
  static const int _debugTaskNotificationId = 999997;
  static const int _debugDailyReminderNotificationId = 999998;
  static const int _dailySummaryNotificationId = 999999;

  // Max offset slots per todo (high priority has 4 reminders).
  static const int _maxOffsetsPerTodo = 5;

  // Default daily reminder time: 07:00
  static const int defaultDailyReminderHour = 7;
  static const int defaultDailyReminderMinute = 0;

  // ─── Initialization ───

  /// Initialize the notification service. Must be called once at app startup.
  /// Automatically retries up to [_maxInitRetries] times on failure.
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initAttempts >= _maxInitRetries) {
      AppLogger.warn(
        _tag,
        'Skipping initialization: max retries ($_maxInitRetries) exhausted.',
      );
      return;
    }

    _initAttempts++;

    try {
      await _migrateSettingsIfNeeded();

      // Initialize timezone data
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );

      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      );

      // Create notification channels
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _taskReminderChannelId,
            _taskReminderChannelName,
            description: _taskReminderChannelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _dailySummaryChannelId,
            _dailySummaryChannelName,
            description: _dailySummaryChannelDesc,
            importance: Importance.defaultImportance,
            playSound: true,
          ),
        );
      }

      _isInitialized = true;
      AppLogger.info(_tag, 'Notification service initialized successfully.');
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to initialize notification service '
        '(attempt $_initAttempts/$_maxInitRetries).',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Ensures the service is initialized, retrying if a previous attempt failed.
  /// Call this before any operation that requires an initialized plugin.
  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;
    await initialize();
    return _isInitialized;
  }

  /// Ensure notification settings are migrated from the legacy single-toggle
  /// format to the split task/daily reminder format.
  Future<void> ensureSettingsMigrated() async {
    await _migrateSettingsIfNeeded();
  }

  Future<void> _migrateSettingsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_settingsMigrationCompletedKey) ?? false;
    if (migrated) {
      return;
    }

    final legacyValue = prefs.getBool(legacyNotificationsEnabledKey);
    final defaultValue = legacyValue ?? true;

    if (!prefs.containsKey(taskNotificationsEnabledKey)) {
      await prefs.setBool(taskNotificationsEnabledKey, defaultValue);
    }

    if (!prefs.containsKey(dailyReminderEnabledKey)) {
      await prefs.setBool(dailyReminderEnabledKey, defaultValue);
    }

    await prefs.setBool(_settingsMigrationCompletedKey, true);
  }

  /// Backward-compatible alias for task reminder notifications.
  Future<bool> isEnabled() async {
    return isTaskNotificationsEnabled();
  }

  /// Check if per-task reminder notifications are enabled.
  Future<bool> isTaskNotificationsEnabled() async {
    await _migrateSettingsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(taskNotificationsEnabledKey) ?? true;
  }

  /// Check if the daily reminder notification is enabled.
  Future<bool> isDailyReminderEnabled() async {
    await _migrateSettingsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dailyReminderEnabledKey) ?? true;
  }

  /// Whether any notification type is enabled.
  Future<bool> areAnyNotificationsEnabled() async {
    final taskNotificationsEnabled = await isTaskNotificationsEnabled();
    if (taskNotificationsEnabled) {
      return true;
    }

    return isDailyReminderEnabled();
  }

  Future<int> getDailyReminderHour() async {
    await _migrateSettingsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dailyReminderHourKey) ?? defaultDailyReminderHour;
  }

  Future<int> getDailyReminderMinute() async {
    await _migrateSettingsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dailyReminderMinuteKey) ?? defaultDailyReminderMinute;
  }

  Future<void> setTaskNotificationsEnabled(bool value) async {
    await _migrateSettingsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(taskNotificationsEnabledKey, value);
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    await _migrateSettingsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dailyReminderEnabledKey, value);
  }

  Future<void> setDailyReminderTime({
    required int hour,
    required int minute,
  }) async {
    await _migrateSettingsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(dailyReminderHourKey, hour);
    await prefs.setInt(dailyReminderMinuteKey, minute);
  }

  @visibleForTesting
  void debugSetInitializationState({
    required bool isInitialized,
    int initAttempts = 0,
  }) {
    _isInitialized = isInitialized;
    _initAttempts = initAttempts;
  }

  @visibleForTesting
  void debugSetDailyReminderSchedulerForTesting(
    Future<void> Function(int pendingCount, int hour, int minute)? scheduler,
  ) {
    _dailyReminderSchedulerOverrideForTesting = scheduler;
  }

  @visibleForTesting
  void debugResetForTesting() {
    _isInitialized = false;
    _initAttempts = 0;
    _dailyReminderSchedulerOverrideForTesting = null;
  }

  Future<NotificationPermissionStatus> getNotificationPermissionStatus() async {
    if (!await _ensureInitialized()) return NotificationPermissionStatus.failed;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      AppLogger.info(
        _tag,
        'Notification permission request result: granted=$granted',
      );
      return granted ?? false;
    }

    return true;
  }

  // ─── Notification Schedule Points Based on Priority ───

  /// Returns the list of Duration offsets before deadline at which
  /// notifications should fire, based on the todo's priority.
  ///
  /// High:   24h, 6h, 1h, 0 (at deadline)
  /// Medium: 8h, 1h, 0
  /// Low:    2h, 0
  List<Duration> _getReminderOffsets(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return const [
          Duration(hours: 24),
          Duration(hours: 6),
          Duration(hours: 1),
          Duration.zero,
        ];
      case TodoPriority.medium:
        return const [Duration(hours: 8), Duration(hours: 1), Duration.zero];
      case TodoPriority.low:
        return const [Duration(hours: 2), Duration.zero];
    }
  }

  /// Generate a human-readable label for a reminder offset.
  String _offsetLabel(Duration offset) {
    if (offset == Duration.zero) return 'Deadline tercapai!';
    if (offset.inHours >= 1) return '${offset.inHours} jam lagi';
    return '${offset.inMinutes} menit lagi';
  }

  /// Get a priority label in Indonesian.
  String _priorityLabel(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return 'Tinggi';
      case TodoPriority.medium:
        return 'Sedang';
      case TodoPriority.low:
        return 'Rendah';
    }
  }

  // ─── Schedule Notifications for a Single Todo ───

  /// Schedule all reminder notifications for a single todo.
  /// This cancels any existing notifications for this todo first.
  ///
  /// When called from [rescheduleAllNotifications], set [skipEnabledCheck]
  /// to `true` to avoid redundant SharedPreferences lookups.
  Future<void> scheduleNotificationsForTodo(
    TodoModel todo, {
    bool skipEnabledCheck = false,
  }) async {
    if (!await _ensureInitialized()) return;

    if (!skipEnabledCheck) {
      final enabled = await isEnabled();
      if (!enabled) return;
    }

    // Don't schedule for completed todos
    if (todo.isCompleted) {
      await cancelNotificationsForTodo(todo.id);
      return;
    }

    // Cancel existing notifications for this todo first
    await cancelNotificationsForTodo(todo.id);

    final offsets = _getReminderOffsets(todo.priority);
    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final scheduledTime = tz.TZDateTime.from(
        todo.deadline.subtract(offset),
        tz.local,
      );

      // Skip notifications in the past
      if (scheduledTime.isBefore(now) || scheduledTime.isAtSameMomentAs(now)) {
        continue;
      }

      final notificationId = _notificationIdForTodo(todo.id, i);
      final isDeadline = offset == Duration.zero;

      final title = isDeadline
          ? 'Deadline: ${todo.title}'
          : 'Pengingat: ${todo.title}';

      final body = isDeadline
          ? 'Deadline tugas "${todo.title}" sudah tercapai! '
                'Prioritas: ${_priorityLabel(todo.priority)}'
          : 'Tugas "${todo.title}" deadline ${_offsetLabel(offset)}. '
                'Prioritas: ${_priorityLabel(todo.priority)}';

      try {
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          scheduledTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _taskReminderChannelId,
              _taskReminderChannelName,
              channelDescription: _taskReminderChannelDesc,
              importance: isDeadline ? Importance.max : Importance.high,
              priority: isDeadline ? Priority.max : Priority.high,
              styleInformation: BigTextStyleInformation(body),
              category: AndroidNotificationCategory.reminder,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: todo.id,
          matchDateTimeComponents: null,
        );

        AppLogger.debug(
          _tag,
          'Scheduled notification: todoId=${todo.id} '
          'offset=${offset.inMinutes}min '
          'at=$scheduledTime '
          'notifId=$notificationId',
        );
      } catch (e, stackTrace) {
        AppLogger.error(
          _tag,
          'Failed to schedule notification for todoId=${todo.id} '
          'offset=${offset.inMinutes}min.',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Cancel all notifications for a specific todo.
  Future<void> cancelNotificationsForTodo(String todoId) async {
    if (!await _ensureInitialized()) return;

    for (int i = 0; i < _maxOffsetsPerTodo; i++) {
      final notificationId = _notificationIdForTodo(todoId, i);
      await _plugin.cancel(notificationId);
    }

    AppLogger.debug(_tag, 'Cancelled notifications for todoId=$todoId');
  }

  /// Cancel ALL notifications (task reminders + daily summary).
  Future<void> cancelAllNotifications() async {
    if (!await _ensureInitialized()) return;

    await _plugin.cancelAll();
    AppLogger.info(_tag, 'All notifications cancelled.');
  }

  // ─── Reschedule All Notifications ───

  /// Reschedule notifications for all incomplete todos.
  /// Call this when the app starts, after settings change, or after boot.
  Future<void> rescheduleAllNotifications() async {
    if (!await _ensureInitialized()) return;

    final enabled = await isEnabled();
    if (!enabled) {
      await cancelAllNotifications();
      return;
    }

    try {
      // Cancel everything first
      await cancelAllNotifications();

      // Reschedule task reminders (skip per-todo isEnabled check)
      final todos = await TodoRepository().getTodos();
      int scheduledCount = 0;
      for (final todo in todos) {
        if (!todo.isCompleted) {
          await scheduleNotificationsForTodo(todo, skipEnabledCheck: true);
          scheduledCount++;
        }
      }

      // Reschedule daily summary (skip isEnabled check internally)
      await _scheduleDailyReminderInternal();

      AppLogger.info(
        _tag,
        'Rescheduled notifications for $scheduledCount incomplete todos.',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to reschedule all notifications.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ─── Daily Summary Reminder ───

  /// Schedule a daily reminder notification that shows a summary of pending tasks.
  Future<void> scheduleDailyReminder() async {
    if (!await _ensureInitialized()) return;

    final enabled = await isEnabled();
    if (!enabled) return;

    await _scheduleDailyReminderInternal();
  }

  /// Internal daily reminder scheduling that skips the isEnabled() check.
  /// Used by [rescheduleAllNotifications] which already checked once.
  Future<void> _scheduleDailyReminderInternal() async {
    try {
      // Cancel previous daily reminder
      await _plugin.cancel(_dailySummaryNotificationId);

      final prefs = await SharedPreferences.getInstance();
      final hour =
          prefs.getInt(dailyReminderHourKey) ?? _defaultDailyReminderHour;
      final minute =
          prefs.getInt(dailyReminderMinuteKey) ?? _defaultDailyReminderMinute;

      // Schedule daily repeating notification
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _dailySummaryNotificationId,
        'Ringkasan Tugas Hari Ini',
        'Kamu punya tugas yang belum selesai. Buka myTask untuk cek!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailySummaryChannelId,
            _dailySummaryChannelName,
            channelDescription: _dailySummaryChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'daily_summary',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      AppLogger.info(
        _tag,
        'Daily reminder scheduled at '
        '$hour:${minute.toString().padLeft(2, '0')}.',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to schedule daily reminder.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Cancel the daily reminder.
  Future<void> cancelDailyReminder() async {
    if (!await _ensureInitialized()) return;
    await _plugin.cancel(_dailySummaryNotificationId);
    AppLogger.info(_tag, 'Daily reminder cancelled.');
  }

  // ─── Helpers ───

  /// Generate a stable notification ID from a todo ID and offset index.
  ///
  /// Todo IDs in this app are [DateTime.now().millisecondsSinceEpoch.toString()]
  /// (e.g. "1735689600000"). We parse the numeric value and derive a
  /// deterministic int that is stable across app restarts.
  ///
  /// Scheme: (parsedId % 90_000) * 10 + offsetIndex
  /// Range: 0 .. 899_999  (well below the 2^31 int limit, avoids collision
  /// with [_dailySummaryNotificationId] = 999_999).
  int _notificationIdForTodo(String todoId, int offsetIndex) {
    final parsed = int.tryParse(todoId);
    if (parsed != null) {
      // Stable: same numeric ID always yields the same notification ID.
      return (parsed % 90000) * 10 + offsetIndex;
    }
    // Fallback for non-numeric IDs (shouldn't happen in this app).
    // Use a simple character-sum hash for determinism across restarts.
    int sum = 0;
    for (int i = 0; i < todoId.length; i++) {
      sum = (sum * 31 + todoId.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return (sum % 90000) * 10 + offsetIndex;
  }
}
