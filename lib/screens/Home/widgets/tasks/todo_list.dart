import 'package:flutter/material.dart';
import '../../../../models/todo_model.dart';
import 'todo_card.dart';
import 'bulk_selection_manager.dart';

class TodoList extends StatelessWidget {
  final List<TodoModel> todos;
  final Function(String) onToggleComplete;
  final VoidCallback onDeleted;
  final BulkSelectionManager? selectionManager;
  final Function(TodoModel)? onDuplicate;

  const TodoList({
    super.key,
    required this.todos,
    required this.onToggleComplete,
    required this.onDeleted,
    this.selectionManager,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final todo = todos[index];
          return TodoCard(
            todo: todo,
            onToggleComplete: () => onToggleComplete(todo.id),
            onDeleted: onDeleted,
            selectionManager: selectionManager,
            onDuplicate: onDuplicate != null ? () => onDuplicate!(todo) : null,
          );
        }, childCount: todos.length),
      ),
    );
  }
}
