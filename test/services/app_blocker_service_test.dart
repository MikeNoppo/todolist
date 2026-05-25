import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mytask/models/todo_model.dart';
import 'package:mytask/services/app_blocker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TodoModel createTodo({
    required DateTime deadline,
    TodoPriority priority = TodoPriority.high,
  }) {
    final createdAt = deadline.subtract(const Duration(hours: 2));
    return TodoModel(
      id: 'todo-1',
      title: 'Finish report',
      description: 'Important task',
      deadline: deadline,
      priority: priority,
      createdAt: createdAt,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppBlockerService', () {
    test('returns no blocked packages on fresh install', () async {
      final debugInfo = await AppBlockerService.getInterventionDebugInfo();

      expect(debugInfo.blockedPackages, isEmpty);
      expect(debugInfo.alwaysAllowedPackages, isEmpty);
    });

    test('does not block apps when there is no urgent task', () async {
      final laterTodo = createTodo(
        deadline: DateTime.now().add(const Duration(days: 2)),
      );
      SharedPreferences.setMockInitialValues({
        'todos': jsonEncode([laterTodo.toJson()]),
      });

      final shouldBlock = await AppBlockerService.shouldBlockApp(
        'com.instagram.android',
      );

      expect(shouldBlock, isFalse);
    });

    test('monitors apps automatically when urgent task exists', () async {
      final urgentTodo = createTodo(
        deadline: DateTime.now().add(const Duration(minutes: 30)),
      );
      SharedPreferences.setMockInitialValues({
        'todos': jsonEncode([urgentTodo.toJson()]),
      });

      final shouldBlock = await AppBlockerService.shouldBlockApp(
        'com.instagram.android',
      );

      expect(shouldBlock, isTrue);
    });

    test('continues to support legacy explicit block prefs', () async {
      final urgentTodo = createTodo(
        deadline: DateTime.now().add(const Duration(minutes: 30)),
      );
      SharedPreferences.setMockInitialValues({
        'todos': jsonEncode([urgentTodo.toJson()]),
        'block_com.instagram.android': true,
      });

      final shouldBlock = await AppBlockerService.shouldBlockApp(
        'com.instagram.android',
      );

      expect(shouldBlock, isTrue);
    });

    test('whitelist overrides automatic monitoring', () async {
      final urgentTodo = createTodo(
        deadline: DateTime.now().add(const Duration(minutes: 30)),
      );
      SharedPreferences.setMockInitialValues({
        'todos': jsonEncode([urgentTodo.toJson()]),
        'allow_com.instagram.android': true,
      });

      final shouldBlock = await AppBlockerService.shouldBlockApp(
        'com.instagram.android',
      );

      expect(shouldBlock, isFalse);
    });
  });
}
