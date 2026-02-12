import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF4A6FA5),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 13.sp,
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
            padding: EdgeInsets.all(8.r),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: todo.isCompleted
                      ? Icons.refresh
                      : Icons.check_circle_outline,
                  title: todo.isCompleted
                      ? 'Mark as Incomplete'
                      : 'Mark as Complete',
                  subtitle: todo.isCompleted
                      ? 'Move task back to pending'
                      : 'Mark this task as done',
                  color: todo.isCompleted
                      ? Colors.orange
                      : const Color(0xFF4A6FA5),
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
            margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16.sp,
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
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}
