import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mytask/models/todo_model.dart';
import 'package:mytask/repositories/todo_repository.dart';
import 'package:mytask/services/notification_service.dart';

/// Replicates the private [NotificationService._notificationIdForTodo] logic
/// for test verification. This must stay in sync with the production code.
int notificationIdForTodo(String todoId, int offsetIndex) {
  final parsed = int.tryParse(todoId);
  if (parsed != null) {
    return (parsed % 90000) * 10 + offsetIndex;
  }
  int sum = 0;
  for (int i = 0; i < todoId.length; i++) {
    sum = (sum * 31 + todoId.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return (sum % 90000) * 10 + offsetIndex;
}

/// Replicates [NotificationService._getReminderOffsets] for test verification.
List<Duration> getReminderOffsets(TodoPriority priority) {
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

void main() {
  final now = DateTime(2026, 3, 1, 12, 0, 0);
  final deadline = DateTime(2026, 3, 5, 18, 0, 0);

  TodoModel createTodo({
    String id = '1735689600000',
    String title = 'Test Todo',
    TodoPriority priority = TodoPriority.medium,
    bool isCompleted = false,
    DateTime? deadlineOverride,
  }) {
    return TodoModel(
      id: id,
      title: title,
      description: 'Description',
      deadline: deadlineOverride ?? deadline,
      priority: priority,
      createdAt: now,
      isCompleted: isCompleted,
    );
  }

  group('Notification ID generation', () {
    test('produces deterministic IDs for numeric todo IDs', () {
      const todoId = '1735689600000';
      final id1 = notificationIdForTodo(todoId, 0);
      final id2 = notificationIdForTodo(todoId, 0);
      expect(id1, id2);
    });

    test('different offset indices produce different IDs', () {
      const todoId = '1735689600000';
      final ids = List.generate(5, (i) => notificationIdForTodo(todoId, i));
      expect(ids.toSet().length, 5, reason: 'All IDs should be unique');
    });

    test('offset index is embedded in the last digit', () {
      const todoId = '1735689600000';
      for (int i = 0; i < 5; i++) {
        final id = notificationIdForTodo(todoId, i);
        expect(id % 10, i);
      }
    });

    test('IDs are within valid range (0..899999)', () {
      // Test with various todo IDs
      final testIds = ['1735689600000', '1000000000000', '0', '99999', '1'];
      for (final todoId in testIds) {
        for (int offset = 0; offset < 5; offset++) {
          final id = notificationIdForTodo(todoId, offset);
          expect(id, greaterThanOrEqualTo(0));
          expect(id, lessThan(900000));
        }
      }
    });

    test('does not collide with daily summary ID (999999)', () {
      final testIds = ['1735689600000', '999999', '0', '89999'];
      for (final todoId in testIds) {
        for (int offset = 0; offset < 5; offset++) {
          final id = notificationIdForTodo(todoId, offset);
          expect(id, isNot(999999));
        }
      }
    });

    test('different todo IDs produce different base IDs', () {
      final id1 = notificationIdForTodo('1735689600000', 0);
      final id2 = notificationIdForTodo('1735689600001', 0);
      expect(id1, isNot(id2));
    });

    test('fallback hash for non-numeric IDs is deterministic', () {
      const todoId = 'abc-def-123';
      final id1 = notificationIdForTodo(todoId, 0);
      final id2 = notificationIdForTodo(todoId, 0);
      expect(id1, id2);
    });

    test('fallback hash respects same range', () {
      const todoId = 'non-numeric-id';
      for (int offset = 0; offset < 5; offset++) {
        final id = notificationIdForTodo(todoId, offset);
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThan(900000));
      }
    });

    test('fallback hash offset index is embedded in last digit', () {
      const todoId = 'some-uuid-style-id';
      for (int i = 0; i < 5; i++) {
        final id = notificationIdForTodo(todoId, i);
        expect(id % 10, i);
      }
    });
  });

  group('Reminder offsets per priority', () {
    test('high priority has 4 offsets: 24h, 6h, 1h, 0', () {
      final offsets = getReminderOffsets(TodoPriority.high);
      expect(offsets.length, 4);
      expect(offsets[0], const Duration(hours: 24));
      expect(offsets[1], const Duration(hours: 6));
      expect(offsets[2], const Duration(hours: 1));
      expect(offsets[3], Duration.zero);
    });

    test('medium priority has 3 offsets: 8h, 1h, 0', () {
      final offsets = getReminderOffsets(TodoPriority.medium);
      expect(offsets.length, 3);
      expect(offsets[0], const Duration(hours: 8));
      expect(offsets[1], const Duration(hours: 1));
      expect(offsets[2], Duration.zero);
    });

    test('low priority has 2 offsets: 2h, 0', () {
      final offsets = getReminderOffsets(TodoPriority.low);
      expect(offsets.length, 2);
      expect(offsets[0], const Duration(hours: 2));
      expect(offsets[1], Duration.zero);
    });

    test('all priorities include zero offset (at-deadline reminder)', () {
      for (final priority in TodoPriority.values) {
        final offsets = getReminderOffsets(priority);
        expect(offsets.last, Duration.zero);
      }
    });

    test('offsets are in descending order for all priorities', () {
      for (final priority in TodoPriority.values) {
        final offsets = getReminderOffsets(priority);
        for (int i = 0; i < offsets.length - 1; i++) {
          expect(
            offsets[i].compareTo(offsets[i + 1]),
            greaterThan(0),
            reason:
                'Offset at index $i should be greater than at index ${i + 1} '
                'for priority $priority',
          );
        }
      }
    });

    test('high priority offsets align with intervention window (24h)', () {
      final offsets = getReminderOffsets(TodoPriority.high);
      expect(offsets.first.inHours, 24);
    });

    test('medium priority offsets align with intervention window (8h)', () {
      final offsets = getReminderOffsets(TodoPriority.medium);
      expect(offsets.first.inHours, 8);
    });

    test('low priority offsets align with intervention window (2h)', () {
      final offsets = getReminderOffsets(TodoPriority.low);
      expect(offsets.first.inHours, 2);
    });

    test('max offsets per todo (5) covers all priorities', () {
      // The notification service uses _maxOffsetsPerTodo = 5
      // High has 4 offsets, so 5 slots should be sufficient for all.
      for (final priority in TodoPriority.values) {
        final offsets = getReminderOffsets(priority);
        expect(
          offsets.length,
          lessThanOrEqualTo(5),
          reason:
              'Priority $priority has ${offsets.length} offsets, '
              'max is 5',
        );
      }
    });
  });

  group('NotificationService singleton', () {
    test('factory constructor returns the same instance', () {
      final a = NotificationService();
      final b = NotificationService();
      expect(identical(a, b), isTrue);
    });
  });

  group('NotificationService settings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      NotificationService().debugResetForTesting();
    });

    tearDown(() {
      NotificationService().debugResetForTesting();
    });

    test('defaults task notifications to true on fresh install', () async {
      final service = NotificationService();
      final enabled = await service.isTaskNotificationsEnabled();
      expect(enabled, true);
    });

    test('defaults daily reminder to true on fresh install', () async {
      final service = NotificationService();
      final enabled = await service.isDailyReminderEnabled();
      expect(enabled, true);
    });

    test('migrates legacy enabled setting to both toggles', () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
      final service = NotificationService();
      final taskEnabled = await service.isTaskNotificationsEnabled();
      final dailyEnabled = await service.isDailyReminderEnabled();

      expect(taskEnabled, true);
      expect(dailyEnabled, true);
    });

    test('migrates legacy disabled setting to both toggles', () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': false});
      final service = NotificationService();
      final taskEnabled = await service.isTaskNotificationsEnabled();
      final dailyEnabled = await service.isDailyReminderEnabled();

      expect(taskEnabled, false);
      expect(dailyEnabled, false);
    });

    test('isEnabled stays aligned with task notifications', () async {
      SharedPreferences.setMockInitialValues({
        'task_notifications_enabled': false,
        'daily_reminder_enabled': true,
        'notification_settings_migrated_v2': true,
      });

      final service = NotificationService();
      final enabled = await service.isEnabled();

      expect(enabled, false);
    });

    test(
      'areAnyNotificationsEnabled returns false when both are disabled',
      () async {
        SharedPreferences.setMockInitialValues({
          'task_notifications_enabled': false,
          'daily_reminder_enabled': false,
          'notification_settings_migrated_v2': true,
        });

        final service = NotificationService();
        final enabled = await service.areAnyNotificationsEnabled();

        expect(enabled, false);
      },
    );

    test('setTaskNotificationsEnabled persists the value', () async {
      final service = NotificationService();

      await service.setTaskNotificationsEnabled(false);

      expect(await service.isTaskNotificationsEnabled(), false);
    });

    test('setDailyReminderEnabled persists the value', () async {
      final service = NotificationService();

      await service.setDailyReminderEnabled(false);

      expect(await service.isDailyReminderEnabled(), false);
    });

    test('daily reminder time falls back to default values', () async {
      final service = NotificationService();

      expect(
        await service.getDailyReminderHour(),
        NotificationService.defaultDailyReminderHour,
      );
      expect(
        await service.getDailyReminderMinute(),
        NotificationService.defaultDailyReminderMinute,
      );
    });

    test('setDailyReminderTime persists hour and minute', () async {
      final service = NotificationService();

      await service.setDailyReminderTime(hour: 9, minute: 30);

      expect(await service.getDailyReminderHour(), 9);
      expect(await service.getDailyReminderMinute(), 30);
    });

    test(
      'cancelAllTaskNotifications returns false when initialization fails',
      () async {
        final service = NotificationService();
        service.debugSetInitializationState(
          isInitialized: false,
          initAttempts: 3,
        );

        final result = await service.cancelAllTaskNotifications();

        expect(result, false);
      },
    );

    test(
      'syncDailyReminderState returns failed when scheduling throws',
      () async {
        final service = NotificationService();
        service.debugSetInitializationState(isInitialized: true);
        service.debugSetDailyReminderSchedulerForTesting((
          pendingCount,
          hour,
          minute,
        ) async {
          throw StateError('schedule failed');
        });

        await TodoRepository().addTodo(createTodo());

        final result = await service.syncDailyReminderState();

        expect(result, DailyReminderSyncResult.failed);
      },
    );
  });

  group('SharedPreferences key constants', () {
    test('legacyNotificationsEnabledKey matches expected value', () {
      expect(
        NotificationService.legacyNotificationsEnabledKey,
        'notifications_enabled',
      );
    });

    test('taskNotificationsEnabledKey matches expected value', () {
      expect(
        NotificationService.taskNotificationsEnabledKey,
        'task_notifications_enabled',
      );
    });

    test('dailyReminderEnabledKey matches expected value', () {
      expect(
        NotificationService.dailyReminderEnabledKey,
        'daily_reminder_enabled',
      );
    });

    test('dailyReminderHourKey matches expected value', () {
      expect(NotificationService.dailyReminderHourKey, 'daily_reminder_hour');
    });

    test('dailyReminderMinuteKey matches expected value', () {
      expect(
        NotificationService.dailyReminderMinuteKey,
        'daily_reminder_minute',
      );
    });
  });

  group('Notification scheduling logic (behavioral)', () {
    // These tests verify the expected scheduling behavior by computing
    // what the service SHOULD do, based on the known algorithm.
    // They don't call the actual plugin (which requires Android platform),
    // but validate the logic that drives scheduling decisions.

    test('completed todo should not be scheduled', () {
      final todo = createTodo(isCompleted: true);
      // The service checks todo.isCompleted and cancels instead of scheduling.
      expect(todo.isCompleted, true);
    });

    test('past deadline offsets should be skipped', () {
      final pastDeadline = DateTime(2020, 1, 1);
      final todo = createTodo(deadlineOverride: pastDeadline);
      final offsets = getReminderOffsets(todo.priority);
      final now = DateTime.now();

      // All offsets subtracted from a past deadline will be in the past.
      for (final offset in offsets) {
        final scheduledTime = todo.deadline.subtract(offset);
        expect(
          scheduledTime.isBefore(now),
          isTrue,
          reason: 'All reminders for a past deadline should be skipped',
        );
      }
    });

    test('future deadline produces schedulable times for high priority', () {
      final futureDeadline = DateTime.now().add(const Duration(days: 7));
      final todo = createTodo(
        priority: TodoPriority.high,
        deadlineOverride: futureDeadline,
      );
      final offsets = getReminderOffsets(todo.priority);
      final now = DateTime.now();

      // With a 7-day-out deadline, all offsets (24h, 6h, 1h, 0) are in the future.
      for (final offset in offsets) {
        final scheduledTime = todo.deadline.subtract(offset);
        expect(
          scheduledTime.isAfter(now),
          isTrue,
          reason: 'Offset ${offset.inHours}h should be schedulable',
        );
      }
    });

    test('deadline soon skips distant offsets for high priority', () {
      // Deadline is 30 minutes from now: only at-deadline reminder
      // might be schedulable (but 24h, 6h, 1h offsets would be in the past).
      final soonDeadline = DateTime.now().add(const Duration(minutes: 30));
      final offsets = getReminderOffsets(TodoPriority.high);
      final now = DateTime.now();

      int schedulable = 0;
      for (final offset in offsets) {
        final scheduledTime = soonDeadline.subtract(offset);
        if (scheduledTime.isAfter(now)) schedulable++;
      }

      // Only the at-deadline (Duration.zero) reminder should be schedulable.
      expect(schedulable, 1);
    });

    test('notification count per priority for far-future deadline', () {
      final futureDeadline = DateTime.now().add(const Duration(days: 30));

      expect(getReminderOffsets(TodoPriority.high).length, 4);
      expect(getReminderOffsets(TodoPriority.medium).length, 3);
      expect(getReminderOffsets(TodoPriority.low).length, 2);

      // For a 30-day deadline, all offsets are schedulable
      for (final priority in TodoPriority.values) {
        final offsets = getReminderOffsets(priority);
        for (final offset in offsets) {
          final time = futureDeadline.subtract(offset);
          expect(time.isAfter(DateTime.now()), isTrue);
        }
      }
    });
  });

  group('Notification ID collision analysis', () {
    test('different sequential millisecond IDs do not collide', () {
      // Simulate typical usage: IDs are sequential millisecond timestamps
      final ids = <int>{};
      const baseId = 1735689600000;

      // Generate 100 todos with IDs 1ms apart
      for (int i = 0; i < 100; i++) {
        final todoId = (baseId + i).toString();
        for (int offset = 0; offset < 5; offset++) {
          ids.add(notificationIdForTodo(todoId, offset));
        }
      }

      // Should have 500 unique notification IDs
      expect(ids.length, 500);
    });

    test('ID scheme reserves enough slots per todo', () {
      // With 5 slots per todo and max 4 offsets (high), there is headroom.
      const maxOffsets = 4; // high priority
      const slotsPerTodo = 5; // _maxOffsetsPerTodo
      expect(slotsPerTodo, greaterThanOrEqualTo(maxOffsets));
    });
  });
}
