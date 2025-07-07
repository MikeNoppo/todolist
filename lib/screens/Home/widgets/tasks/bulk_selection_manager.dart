import 'package:flutter/material.dart';
import '../../../../models/todo_model.dart';

class BulkSelectionManager extends ChangeNotifier {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  int get selectedCount => _selectedIds.length;

  bool isSelected(String id) => _selectedIds.contains(id);

  void enterSelectionMode(String firstItemId) {
    _isSelectionMode = true;
    _selectedIds.clear();
    _selectedIds.add(firstItemId);
    notifyListeners();
  }

  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedIds.isEmpty) {
        exitSelectionMode();
      }
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll(List<TodoModel> todos) {
    _selectedIds.clear();
    _selectedIds.addAll(todos.map((todo) => todo.id));
    notifyListeners();
  }

  void deselectAll() {
    _selectedIds.clear();
    if (_isSelectionMode) {
      exitSelectionMode();
    }
    notifyListeners();
  }

  List<TodoModel> getSelectedTodos(List<TodoModel> allTodos) {
    return allTodos.where((todo) => _selectedIds.contains(todo.id)).toList();
  }
}
