import 'package:flutter/material.dart';
import '../../../../models/todo_model.dart';

class TaskContextMenu {
  static void show({
    required BuildContext context,
    required TodoModel todo,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onToggleComplete,
    required VoidCallback onDuplicate,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ContextMenuBottomSheet(
        todo: todo,
        onEdit: onEdit,
        onDelete: onDelete,
        onToggleComplete: onToggleComplete,
        onDuplicate: onDuplicate,
      ),
    );
  }
}

class _ContextMenuBottomSheet extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;
  final VoidCallback onDuplicate;

  const _ContextMenuBottomSheet({
    required this.todo,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF4A6FA5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: todo.isCompleted ? Icons.refresh : Icons.check_circle_outline,
                  title: todo.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                  subtitle: todo.isCompleted 
                    ? 'Move task back to pending'
                    : 'Mark this task as done',
                  color: todo.isCompleted ? Colors.orange : const Color(0xFF4A6FA5),
                  onTap: () {
                    Navigator.pop(context);
                    onToggleComplete();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Task',
                  subtitle: 'Modify task details',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.content_copy_outlined,
                  title: 'Duplicate Task',
                  subtitle: 'Create a copy of this task',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    onDuplicate();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.delete_outline,
                  title: 'Delete Task',
                  subtitle: 'Remove this task permanently',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
          // Cancel button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
