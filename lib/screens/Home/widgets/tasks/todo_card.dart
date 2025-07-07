import 'package:flutter/material.dart';
import '../../../../models/todo_model.dart';
import '../../../add_edit_task_screen.dart';
import '../common/delete_confirmation_dialog.dart';
import 'todo_checkbox.dart';
import 'priority_indicator.dart';
import 'deadline_badge.dart';

class TodoCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggleComplete;
  final VoidCallback onDeleted;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggleComplete,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await DeleteConfirmationDialog.show(
            context: context,
            todo: todo,
            onDeleted: onDeleted,
          );
        } else if (direction == DismissDirection.startToEnd) {
          onToggleComplete();
          return false;
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF4A6FA5),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Complete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.delete,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditTaskScreen(todo: todo),
                ),
              );
              
              if (result == true) {
                onDeleted(); // refresh data
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  TodoCheckbox(
                    isCompleted: todo.isCompleted,
                    onToggle: onToggleComplete,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: todo.isCompleted 
                              ? Colors.grey[500]
                              : Colors.black87,
                            decoration: todo.isCompleted 
                              ? TextDecoration.lineThrough
                              : null,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            DeadlineBadge(deadline: todo.deadline),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PriorityIndicator(priority: todo.priority),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
