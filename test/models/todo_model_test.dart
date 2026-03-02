import 'package:flutter_test/flutter_test.dart';

import 'package:mytask/models/todo_model.dart';

void main() {
  // Shared test fixtures
  final now = DateTime(2026, 3, 1, 12, 0, 0);
  final deadline = DateTime(2026, 3, 5, 18, 0, 0);

  TodoModel createSampleTodo({
    String id = '1735689600000',
    String title = 'Test Todo',
    String description = 'A test description',
    DateTime? deadlineOverride,
    TodoPriority priority = TodoPriority.medium,
    bool isCompleted = false,
    DateTime? createdAtOverride,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id,
      title: title,
      description: description,
      deadline: deadlineOverride ?? deadline,
      priority: priority,
      isCompleted: isCompleted,
      createdAt: createdAtOverride ?? now,
      updatedAt: updatedAt,
    );
  }

  group('TodoPriority enum', () {
    test('has exactly three values', () {
      expect(TodoPriority.values.length, 3);
    });

    test('values are low, medium, high in order', () {
      expect(TodoPriority.values, [
        TodoPriority.low,
        TodoPriority.medium,
        TodoPriority.high,
      ]);
    });
  });

  group('TodoModel constructor', () {
    test('creates instance with all required fields', () {
      final todo = createSampleTodo();

      expect(todo.id, '1735689600000');
      expect(todo.title, 'Test Todo');
      expect(todo.description, 'A test description');
      expect(todo.deadline, deadline);
      expect(todo.priority, TodoPriority.medium);
      expect(todo.isCompleted, false);
      expect(todo.createdAt, now);
      expect(todo.updatedAt, isNull);
    });

    test('isCompleted defaults to false', () {
      final todo = TodoModel(
        id: '1',
        title: 'T',
        description: 'D',
        deadline: deadline,
        priority: TodoPriority.low,
        createdAt: now,
      );

      expect(todo.isCompleted, false);
    });

    test('updatedAt defaults to null', () {
      final todo = createSampleTodo();
      expect(todo.updatedAt, isNull);
    });

    test('accepts explicit isCompleted=true', () {
      final todo = createSampleTodo(isCompleted: true);
      expect(todo.isCompleted, true);
    });

    test('accepts explicit updatedAt', () {
      final updated = DateTime(2026, 3, 2);
      final todo = createSampleTodo(updatedAt: updated);
      expect(todo.updatedAt, updated);
    });
  });

  group('TodoModel.toJson', () {
    test('serializes all fields correctly', () {
      final todo = createSampleTodo();
      final json = todo.toJson();

      expect(json['id'], '1735689600000');
      expect(json['title'], 'Test Todo');
      expect(json['description'], 'A test description');
      expect(json['deadline'], deadline.toIso8601String());
      expect(json['priority'], 'medium');
      expect(json['isCompleted'], false);
      expect(json['createdAt'], now.toIso8601String());
      expect(json['updatedAt'], isNull);
    });

    test('serializes priority values correctly', () {
      for (final entry in {
        TodoPriority.low: 'low',
        TodoPriority.medium: 'medium',
        TodoPriority.high: 'high',
      }.entries) {
        final todo = createSampleTodo(priority: entry.key);
        expect(todo.toJson()['priority'], entry.value);
      }
    });

    test('serializes updatedAt when present', () {
      final updated = DateTime(2026, 3, 2, 10, 30);
      final todo = createSampleTodo(updatedAt: updated);
      final json = todo.toJson();

      expect(json['updatedAt'], updated.toIso8601String());
    });

    test('serializes isCompleted=true', () {
      final todo = createSampleTodo(isCompleted: true);
      expect(todo.toJson()['isCompleted'], true);
    });
  });

  group('TodoModel.fromJson', () {
    test('deserializes all fields correctly', () {
      final json = {
        'id': '1735689600000',
        'title': 'Test Todo',
        'description': 'A test description',
        'deadline': deadline.toIso8601String(),
        'priority': 'medium',
        'isCompleted': false,
        'createdAt': now.toIso8601String(),
        'updatedAt': null,
      };

      final todo = TodoModel.fromJson(json);

      expect(todo.id, '1735689600000');
      expect(todo.title, 'Test Todo');
      expect(todo.description, 'A test description');
      expect(todo.deadline, deadline);
      expect(todo.priority, TodoPriority.medium);
      expect(todo.isCompleted, false);
      expect(todo.createdAt, now);
      expect(todo.updatedAt, isNull);
    });

    test('deserializes each priority value', () {
      final baseJson = {
        'id': '1',
        'title': 'T',
        'description': 'D',
        'deadline': deadline.toIso8601String(),
        'isCompleted': false,
        'createdAt': now.toIso8601String(),
      };

      for (final entry in {
        'low': TodoPriority.low,
        'medium': TodoPriority.medium,
        'high': TodoPriority.high,
      }.entries) {
        final json = {...baseJson, 'priority': entry.key};
        final todo = TodoModel.fromJson(json);
        expect(todo.priority, entry.value);
      }
    });

    test('defaults isCompleted to false when missing', () {
      final json = {
        'id': '1',
        'title': 'T',
        'description': 'D',
        'deadline': deadline.toIso8601String(),
        'priority': 'low',
        'createdAt': now.toIso8601String(),
      };

      final todo = TodoModel.fromJson(json);
      expect(todo.isCompleted, false);
    });

    test('parses updatedAt when present', () {
      final updated = DateTime(2026, 3, 2, 10, 30);
      final json = {
        'id': '1',
        'title': 'T',
        'description': 'D',
        'deadline': deadline.toIso8601String(),
        'priority': 'high',
        'isCompleted': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': updated.toIso8601String(),
      };

      final todo = TodoModel.fromJson(json);
      expect(todo.updatedAt, updated);
    });
  });

  group('TodoModel JSON round-trip', () {
    test('toJson -> fromJson preserves all fields', () {
      final original = createSampleTodo(updatedAt: DateTime(2026, 3, 2, 8, 0));

      final restored = TodoModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.deadline, original.deadline);
      expect(restored.priority, original.priority);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trip works for all priorities', () {
      for (final priority in TodoPriority.values) {
        final original = createSampleTodo(priority: priority);
        final restored = TodoModel.fromJson(original.toJson());
        expect(restored.priority, original.priority);
      }
    });

    test('round-trip preserves completed todo', () {
      final original = createSampleTodo(
        isCompleted: true,
        updatedAt: DateTime(2026, 3, 2),
      );
      final restored = TodoModel.fromJson(original.toJson());
      expect(restored.isCompleted, true);
    });
  });

  group('TodoModel.copyWith', () {
    test('returns identical copy when no arguments provided', () {
      final original = createSampleTodo(updatedAt: DateTime(2026, 3, 2));
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.description, original.description);
      expect(copy.deadline, original.deadline);
      expect(copy.priority, original.priority);
      expect(copy.isCompleted, original.isCompleted);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
    });

    test('updates only id', () {
      final original = createSampleTodo();
      final copy = original.copyWith(id: 'new-id');

      expect(copy.id, 'new-id');
      expect(copy.title, original.title);
    });

    test('updates only title', () {
      final original = createSampleTodo();
      final copy = original.copyWith(title: 'New Title');

      expect(copy.title, 'New Title');
      expect(copy.id, original.id);
    });

    test('updates only description', () {
      final original = createSampleTodo();
      final copy = original.copyWith(description: 'New desc');

      expect(copy.description, 'New desc');
    });

    test('updates only deadline', () {
      final newDeadline = DateTime(2026, 4, 1);
      final original = createSampleTodo();
      final copy = original.copyWith(deadline: newDeadline);

      expect(copy.deadline, newDeadline);
      expect(copy.title, original.title);
    });

    test('updates only priority', () {
      final original = createSampleTodo(priority: TodoPriority.low);
      final copy = original.copyWith(priority: TodoPriority.high);

      expect(copy.priority, TodoPriority.high);
    });

    test('updates only isCompleted', () {
      final original = createSampleTodo(isCompleted: false);
      final copy = original.copyWith(isCompleted: true);

      expect(copy.isCompleted, true);
      expect(copy.id, original.id);
    });

    test('updates only createdAt', () {
      final newCreated = DateTime(2025, 1, 1);
      final original = createSampleTodo();
      final copy = original.copyWith(createdAt: newCreated);

      expect(copy.createdAt, newCreated);
    });

    test('updates only updatedAt', () {
      final newUpdated = DateTime(2026, 3, 3);
      final original = createSampleTodo();
      final copy = original.copyWith(updatedAt: newUpdated);

      expect(copy.updatedAt, newUpdated);
    });

    test('updates multiple fields simultaneously', () {
      final original = createSampleTodo();
      final copy = original.copyWith(
        title: 'Updated',
        priority: TodoPriority.high,
        isCompleted: true,
        updatedAt: DateTime(2026, 3, 3),
      );

      expect(copy.title, 'Updated');
      expect(copy.priority, TodoPriority.high);
      expect(copy.isCompleted, true);
      expect(copy.updatedAt, DateTime(2026, 3, 3));
      // Unchanged fields
      expect(copy.id, original.id);
      expect(copy.description, original.description);
      expect(copy.deadline, original.deadline);
      expect(copy.createdAt, original.createdAt);
    });

    test('does not mutate the original', () {
      final original = createSampleTodo();
      original.copyWith(title: 'Changed');

      expect(original.title, 'Test Todo');
    });
  });
}
