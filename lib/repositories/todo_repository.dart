import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';

class TodoRepository {
  static const String _todosKey = 'todos';
  static const String _userNameKey = 'user_name';
  static const String _userAvatarKey = 'user_avatar';

  // Todo Operations
  Future<List<TodoModel>> getTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = prefs.getString(_todosKey);
    
    if (todosJson == null) return [];
    
    final List<dynamic> todosList = jsonDecode(todosJson);
    return todosList.map((json) => TodoModel.fromJson(json)).toList();
  }

  Future<void> saveTodos(List<TodoModel> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = jsonEncode(todos.map((todo) => todo.toJson()).toList());
    await prefs.setString(_todosKey, todosJson);
  }

  Future<void> addTodo(TodoModel todo) async {
    final todos = await getTodos();
    todos.add(todo);
    await saveTodos(todos);
  }

  Future<void> updateTodo(TodoModel updatedTodo) async {
    final todos = await getTodos();
    final index = todos.indexWhere((todo) => todo.id == updatedTodo.id);
    
    if (index != -1) {
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }

  Future<void> deleteTodo(String todoId) async {
    final todos = await getTodos();
    todos.removeWhere((todo) => todo.id == todoId);
    await saveTodos(todos);
  }

  Future<void> toggleTodoComplete(String todoId) async {
    final todos = await getTodos();
    final index = todos.indexWhere((todo) => todo.id == todoId);
    
    if (index != -1) {
      final todo = todos[index];
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now(),
      );
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }

  // User Profile Operations
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  Future<String?> getUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userAvatarKey);
  }

  Future<void> saveUserAvatar(String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userAvatarKey, avatarPath);
  }

  // Utility Methods
  Future<List<TodoModel>> getTodosByPriority(TodoPriority priority) async {
    final todos = await getTodos();
    return todos.where((todo) => todo.priority == priority && !todo.isCompleted).toList();
  }

  Future<List<TodoModel>> getOverdueTodos() async {
    final todos = await getTodos();
    final now = DateTime.now();
    return todos.where((todo) => 
      !todo.isCompleted && 
      todo.deadline.isBefore(now)
    ).toList();
  }

  Future<TodoModel?> getHighestPriorityTodo() async {
    final todos = await getTodos();
    final incompleteTodos = todos.where((todo) => !todo.isCompleted).toList();
    
    if (incompleteTodos.isEmpty) return null;
    
    // Sort by priority (high first) then by deadline
    incompleteTodos.sort((a, b) {
      if (a.priority != b.priority) {
        return _priorityValue(b.priority).compareTo(_priorityValue(a.priority));
      }
      return a.deadline.compareTo(b.deadline);
    });
    
    return incompleteTodos.first;
  }

  int _priorityValue(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return 3;
      case TodoPriority.medium:
        return 2;
      case TodoPriority.low:
        return 1;
    }
  }
}
