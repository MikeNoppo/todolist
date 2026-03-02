import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mytask/models/todo_model.dart';
import 'package:mytask/repositories/todo_repository.dart';

void main() {
  late TodoRepository repository;

  final now = DateTime(2026, 3, 1, 12, 0, 0);
  final deadline = DateTime(2026, 3, 5, 18, 0, 0);

  TodoModel createTodo({
    String? id,
    String title = 'Test Todo',
    String description = 'Test description',
    DateTime? deadlineOverride,
    TodoPriority priority = TodoPriority.medium,
    bool isCompleted = false,
    DateTime? createdAtOverride,
  }) {
    return TodoModel(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      deadline: deadlineOverride ?? deadline,
      priority: priority,
      isCompleted: isCompleted,
      createdAt: createdAtOverride ?? now,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = TodoRepository();
  });

  group('getTodos', () {
    test('returns empty list when no todos stored', () async {
      final todos = await repository.getTodos();
      expect(todos, isEmpty);
    });

    test('returns empty list when stored value is null', () async {
      SharedPreferences.setMockInitialValues({});
      final todos = await repository.getTodos();
      expect(todos, isEmpty);
    });

    test('returns parsed todos from SharedPreferences', () async {
      final todo = createTodo(id: '100');
      SharedPreferences.setMockInitialValues({
        'todos': jsonEncode([todo.toJson()]),
      });

      final todos = await repository.getTodos();
      expect(todos.length, 1);
      expect(todos[0].id, '100');
      expect(todos[0].title, 'Test Todo');
    });

    test('returns multiple todos', () async {
      final todo1 = createTodo(id: '1', title: 'First');
      final todo2 = createTodo(id: '2', title: 'Second');
      SharedPreferences.setMockInitialValues({
        'todos': jsonEncode([todo1.toJson(), todo2.toJson()]),
      });

      final todos = await repository.getTodos();
      expect(todos.length, 2);
      expect(todos[0].title, 'First');
      expect(todos[1].title, 'Second');
    });

    test('returns empty list on invalid JSON', () async {
      SharedPreferences.setMockInitialValues({'todos': 'invalid-json'});

      final todos = await repository.getTodos();
      expect(todos, isEmpty);
    });
  });

  group('saveTodos', () {
    test('saves empty list', () async {
      await repository.saveTodos([]);

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('todos');
      expect(stored, '[]');
    });

    test('saves todo list as JSON string', () async {
      final todo = createTodo(id: '42', title: 'Saved');
      await repository.saveTodos([todo]);

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('todos');
      expect(stored, isNotNull);

      final decoded = jsonDecode(stored!) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['id'], '42');
      expect(decoded[0]['title'], 'Saved');
    });
  });

  group('addTodo', () {
    test('adds todo to empty list', () async {
      final todo = createTodo(id: '1', title: 'New');
      await repository.addTodo(todo);

      final todos = await repository.getTodos();
      expect(todos.length, 1);
      expect(todos[0].id, '1');
      expect(todos[0].title, 'New');
    });

    test('appends todo to existing list', () async {
      final todo1 = createTodo(id: '1', title: 'First');
      await repository.addTodo(todo1);

      final todo2 = createTodo(id: '2', title: 'Second');
      await repository.addTodo(todo2);

      final todos = await repository.getTodos();
      expect(todos.length, 2);
      expect(todos[0].id, '1');
      expect(todos[1].id, '2');
    });

    test('preserves all fields of the added todo', () async {
      final updated = DateTime(2026, 3, 2, 10, 0);
      final todo = TodoModel(
        id: '99',
        title: 'Full',
        description: 'Full description',
        deadline: deadline,
        priority: TodoPriority.high,
        isCompleted: true,
        createdAt: now,
        updatedAt: updated,
      );

      await repository.addTodo(todo);

      final todos = await repository.getTodos();
      expect(todos.length, 1);
      final stored = todos[0];
      expect(stored.id, '99');
      expect(stored.title, 'Full');
      expect(stored.description, 'Full description');
      expect(stored.deadline, deadline);
      expect(stored.priority, TodoPriority.high);
      expect(stored.isCompleted, true);
      expect(stored.createdAt, now);
      expect(stored.updatedAt, updated);
    });
  });

  group('updateTodo', () {
    test('updates existing todo by id', () async {
      final todo = createTodo(id: '1', title: 'Original');
      await repository.addTodo(todo);

      final updated = todo.copyWith(
        title: 'Updated',
        updatedAt: DateTime(2026, 3, 2),
      );
      await repository.updateTodo(updated);

      final todos = await repository.getTodos();
      expect(todos.length, 1);
      expect(todos[0].title, 'Updated');
      expect(todos[0].updatedAt, DateTime(2026, 3, 2));
    });

    test('does not modify list when id not found', () async {
      final todo = createTodo(id: '1', title: 'Original');
      await repository.addTodo(todo);

      final unknown = createTodo(id: 'nonexistent', title: 'Ghost');
      await repository.updateTodo(unknown);

      final todos = await repository.getTodos();
      expect(todos.length, 1);
      expect(todos[0].title, 'Original');
    });

    test('updates only the matching todo', () async {
      final todo1 = createTodo(id: '1', title: 'First');
      final todo2 = createTodo(id: '2', title: 'Second');
      await repository.addTodo(todo1);
      await repository.addTodo(todo2);

      final updated = todo2.copyWith(title: 'Updated Second');
      await repository.updateTodo(updated);

      final todos = await repository.getTodos();
      expect(todos[0].title, 'First');
      expect(todos[1].title, 'Updated Second');
    });

    test('can update priority', () async {
      final todo = createTodo(
        id: '1',
        title: 'Task',
        priority: TodoPriority.low,
      );
      await repository.addTodo(todo);

      final updated = todo.copyWith(priority: TodoPriority.high);
      await repository.updateTodo(updated);

      final todos = await repository.getTodos();
      expect(todos[0].priority, TodoPriority.high);
    });
  });

  group('deleteTodo', () {
    test('removes todo by id', () async {
      final todo = createTodo(id: '1', title: 'To Delete');
      await repository.addTodo(todo);
      expect((await repository.getTodos()).length, 1);

      await repository.deleteTodo('1');

      final todos = await repository.getTodos();
      expect(todos, isEmpty);
    });

    test('does nothing when id not found', () async {
      final todo = createTodo(id: '1', title: 'Keep');
      await repository.addTodo(todo);

      await repository.deleteTodo('nonexistent');

      final todos = await repository.getTodos();
      expect(todos.length, 1);
      expect(todos[0].id, '1');
    });

    test('removes only the matching todo', () async {
      final todo1 = createTodo(id: '1', title: 'Keep');
      final todo2 = createTodo(id: '2', title: 'Delete');
      final todo3 = createTodo(id: '3', title: 'Also Keep');
      await repository.addTodo(todo1);
      await repository.addTodo(todo2);
      await repository.addTodo(todo3);

      await repository.deleteTodo('2');

      final todos = await repository.getTodos();
      expect(todos.length, 2);
      expect(todos.map((t) => t.id), containsAll(['1', '3']));
      expect(todos.map((t) => t.id), isNot(contains('2')));
    });
  });

  group('toggleTodoComplete', () {
    test('marks incomplete todo as completed', () async {
      final todo = createTodo(id: '1', isCompleted: false);
      await repository.addTodo(todo);

      await repository.toggleTodoComplete('1');

      final todos = await repository.getTodos();
      expect(todos[0].isCompleted, true);
    });

    test('marks completed todo as incomplete', () async {
      final todo = createTodo(id: '1', isCompleted: true);
      await repository.addTodo(todo);

      await repository.toggleTodoComplete('1');

      final todos = await repository.getTodos();
      expect(todos[0].isCompleted, false);
    });

    test('sets updatedAt on toggle', () async {
      final todo = createTodo(id: '1', isCompleted: false);
      await repository.addTodo(todo);
      expect(todo.updatedAt, isNull);

      await repository.toggleTodoComplete('1');

      final todos = await repository.getTodos();
      expect(todos[0].updatedAt, isNotNull);
    });

    test('does nothing when id not found', () async {
      final todo = createTodo(id: '1', isCompleted: false);
      await repository.addTodo(todo);

      await repository.toggleTodoComplete('nonexistent');

      final todos = await repository.getTodos();
      expect(todos.length, 1);
      expect(todos[0].isCompleted, false);
    });

    test('only toggles the matching todo', () async {
      final todo1 = createTodo(id: '1', isCompleted: false);
      final todo2 = createTodo(id: '2', isCompleted: false);
      await repository.addTodo(todo1);
      await repository.addTodo(todo2);

      await repository.toggleTodoComplete('1');

      final todos = await repository.getTodos();
      expect(todos[0].isCompleted, true);
      expect(todos[1].isCompleted, false);
    });
  });

  group('User profile operations', () {
    test('getUserName returns null when not set', () async {
      final name = await repository.getUserName();
      expect(name, isNull);
    });

    test('saveUserName and getUserName round-trip', () async {
      await repository.saveUserName('Alice');
      final name = await repository.getUserName();
      expect(name, 'Alice');
    });

    test('getUserAvatar returns null when not set', () async {
      final avatar = await repository.getUserAvatar();
      expect(avatar, isNull);
    });

    test('saveUserAvatar and getUserAvatar round-trip', () async {
      await repository.saveUserAvatar('/path/to/avatar.png');
      final avatar = await repository.getUserAvatar();
      expect(avatar, '/path/to/avatar.png');
    });
  });

  group('Onboarding', () {
    test('hasCompletedOnboarding returns false when not set', () async {
      final completed = await repository.hasCompletedOnboarding();
      expect(completed, false);
    });

    test(
      'setOnboardingCompleted and hasCompletedOnboarding round-trip',
      () async {
        await repository.setOnboardingCompleted(true);
        expect(await repository.hasCompletedOnboarding(), true);

        await repository.setOnboardingCompleted(false);
        expect(await repository.hasCompletedOnboarding(), false);
      },
    );
  });

  group('getTodosByPriority', () {
    test('returns only incomplete todos of the given priority', () async {
      final low = createTodo(id: '1', priority: TodoPriority.low);
      final med = createTodo(id: '2', priority: TodoPriority.medium);
      final high = createTodo(id: '3', priority: TodoPriority.high);
      final completedHigh = createTodo(
        id: '4',
        priority: TodoPriority.high,
        isCompleted: true,
      );

      await repository.addTodo(low);
      await repository.addTodo(med);
      await repository.addTodo(high);
      await repository.addTodo(completedHigh);

      final highs = await repository.getTodosByPriority(TodoPriority.high);
      expect(highs.length, 1);
      expect(highs[0].id, '3');

      final lows = await repository.getTodosByPriority(TodoPriority.low);
      expect(lows.length, 1);
      expect(lows[0].id, '1');

      final meds = await repository.getTodosByPriority(TodoPriority.medium);
      expect(meds.length, 1);
      expect(meds[0].id, '2');
    });

    test('returns empty list when no match', () async {
      final low = createTodo(id: '1', priority: TodoPriority.low);
      await repository.addTodo(low);

      final highs = await repository.getTodosByPriority(TodoPriority.high);
      expect(highs, isEmpty);
    });
  });

  group('getOverdueTodos', () {
    test('returns incomplete todos past their deadline', () async {
      final overdue = createTodo(
        id: '1',
        title: 'Overdue',
        deadlineOverride: DateTime(2020, 1, 1),
      );
      final future = createTodo(
        id: '2',
        title: 'Future',
        deadlineOverride: DateTime(2030, 1, 1),
      );
      final completedOverdue = createTodo(
        id: '3',
        title: 'Done but overdue',
        deadlineOverride: DateTime(2020, 1, 1),
        isCompleted: true,
      );

      await repository.addTodo(overdue);
      await repository.addTodo(future);
      await repository.addTodo(completedOverdue);

      final overdues = await repository.getOverdueTodos();
      expect(overdues.length, 1);
      expect(overdues[0].id, '1');
    });

    test('returns empty when no overdue todos', () async {
      final future = createTodo(
        id: '1',
        deadlineOverride: DateTime(2030, 1, 1),
      );
      await repository.addTodo(future);

      final overdues = await repository.getOverdueTodos();
      expect(overdues, isEmpty);
    });
  });

  group('getHighestPriorityTodo', () {
    test('returns null when no incomplete todos', () async {
      final result = await repository.getHighestPriorityTodo();
      expect(result, isNull);
    });

    test('returns null when only completed todos', () async {
      final todo = createTodo(id: '1', isCompleted: true);
      await repository.addTodo(todo);

      final result = await repository.getHighestPriorityTodo();
      expect(result, isNull);
    });

    test('returns highest priority todo', () async {
      final low = createTodo(id: '1', priority: TodoPriority.low);
      final high = createTodo(id: '2', priority: TodoPriority.high);
      final med = createTodo(id: '3', priority: TodoPriority.medium);

      await repository.addTodo(low);
      await repository.addTodo(high);
      await repository.addTodo(med);

      final result = await repository.getHighestPriorityTodo();
      expect(result, isNotNull);
      expect(result!.id, '2');
    });

    test('returns earliest deadline when same priority', () async {
      final early = createTodo(
        id: '1',
        priority: TodoPriority.high,
        deadlineOverride: DateTime(2026, 3, 1),
      );
      final late = createTodo(
        id: '2',
        priority: TodoPriority.high,
        deadlineOverride: DateTime(2026, 3, 10),
      );

      await repository.addTodo(late);
      await repository.addTodo(early);

      final result = await repository.getHighestPriorityTodo();
      expect(result, isNotNull);
      expect(result!.id, '1');
    });
  });
}
