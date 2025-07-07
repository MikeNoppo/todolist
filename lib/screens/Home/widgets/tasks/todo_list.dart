import 'package:flutter/material.dart';
import '../../../../models/todo_model.dart';
import 'todo_card.dart';

class TodoList extends StatelessWidget {
  final List<TodoModel> todos;
  final Function(String) onToggleComplete;
  final VoidCallback onDeleted;

  const TodoList({
    super.key,
    required this.todos,
    required this.onToggleComplete,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final todo = todos[index];
            return TodoCard(
              todo: todo,
              onToggleComplete: () => onToggleComplete(todo.id),
              onDeleted: onDeleted,
            );
          },
          childCount: todos.length,
        ),
      ),
    );
  }
}
