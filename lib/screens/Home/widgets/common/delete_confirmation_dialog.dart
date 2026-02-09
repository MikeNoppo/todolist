import 'package:flutter/material.dart';
import '../../../../models/todo_model.dart';
import '../../../../repositories/todo_repository.dart';
import '../../../../services/app_logger.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onDeleted;

  const DeleteConfirmationDialog({
    super.key,
    required this.todo,
    required this.onDeleted,
  });

  static Future<bool> show({
    required BuildContext context,
    required TodoModel todo,
    required VoidCallback onDeleted,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(
          todo: todo,
          onDeleted: onDeleted,
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Hapus Tugas',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        'Apakah Anda yakin ingin menghapus "${todo.title}"?',
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Batal',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final repository = TodoRepository();

            try {
              await repository.deleteTodo(todo.id);

              if (!context.mounted) return;

              AppLogger.info('DeleteConfirmationDialog', 'Task deleted successfully.');

              Navigator.of(context).pop(true);
              onDeleted();

              messenger.showSnackBar(
                SnackBar(
                  content: Text('${todo.title} dihapus'),
                  duration: const Duration(seconds: 3),
                ),
              );
            } catch (e, stackTrace) {
              AppLogger.error(
                'DeleteConfirmationDialog',
                'Failed to delete task.',
                error: e,
                stackTrace: stackTrace,
              );

              if (!context.mounted) return;

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Gagal menghapus tugas'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
