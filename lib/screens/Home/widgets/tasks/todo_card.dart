import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/todo_model.dart';
import '../../../add_edit_task_screen.dart';
import '../common/delete_confirmation_dialog.dart';
import 'todo_checkbox.dart';
import 'priority_indicator.dart';
import 'deadline_badge.dart';
import 'task_context_menu.dart';
import 'bulk_selection_manager.dart';

class TodoCard extends StatefulWidget {
  final TodoModel todo;
  final VoidCallback onToggleComplete;
  final VoidCallback onDeleted;
  final BulkSelectionManager? selectionManager;
  final VoidCallback? onDuplicate;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggleComplete,
    required this.onDeleted,
    this.selectionManager,
    this.onDuplicate,
  });

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  @override
  void initState() {
    super.initState();
  }

  void _handleLongPress() {
    if (widget.selectionManager?.isSelectionMode == true) {
      widget.selectionManager!.toggleSelection(widget.todo.id);
    } else {
      TaskContextMenu.show(
        context: context,
        todo: widget.todo,
        onEdit: _editTask,
        onDelete: _deleteTask,
        onToggleComplete: widget.onToggleComplete,
        onDuplicate: widget.onDuplicate ?? () {},
      );
    }
  }

  void _handleDoubleTap() {
    if (widget.selectionManager != null &&
        !widget.selectionManager!.isSelectionMode) {
      widget.selectionManager!.enterSelectionMode(widget.todo.id);
    }
  }

  void _handleTap() {
    if (widget.selectionManager?.isSelectionMode == true) {
      widget.selectionManager!.toggleSelection(widget.todo.id);
    } else {
      _editTask();
    }
  }

  void _editTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(todo: widget.todo),
      ),
    );

    if (result == true) {
      widget.onDeleted(); // refresh data
    }
  }

  void _deleteTask() async {
    await DeleteConfirmationDialog.show(
      context: context,
      todo: widget.todo,
      onDeleted: widget.onDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = widget.selectionManager?.isSelectionMode ?? false;
    final isSelected =
        widget.selectionManager?.isSelected(widget.todo.id) ?? false;

    return Dismissible(
      key: Key(widget.todo.id),
      direction: isSelectionMode
          ? DismissDirection.none
          : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await DeleteConfirmationDialog.show(
            context: context,
            todo: widget.todo,
            onDeleted: widget.onDeleted,
          );
        } else if (direction == DismissDirection.startToEnd) {
          widget.onToggleComplete();
          return false;
        }
        return false;
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 16.r),
        decoration: BoxDecoration(
          color: const Color(0xFF4A6FA5),
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.r),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 24.sp),
            SizedBox(width: 8.w),
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
        margin: EdgeInsets.only(bottom: 16.r),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.delete, color: Colors.white, size: 24.sp),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 16.r),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A6FA5).withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: isSelected
              ? Border.all(color: const Color(0xFF4A6FA5), width: 2)
              : null,
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
          child: GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: InkWell(
              onTap: _handleTap,
              onLongPress: _handleLongPress,
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (isSelectionMode) ...[
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4A6FA5)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4A6FA5)
                                    : Colors.grey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16.sp,
                                  )
                                : null,
                          ),
                          SizedBox(width: 16.w),
                        ] else ...[
                          TodoCheckbox(
                            isCompleted: widget.todo.isCompleted,
                            onToggle: widget.onToggleComplete,
                          ),
                          SizedBox(width: 16.w),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.todo.title,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: widget.todo.isCompleted
                                      ? Colors.grey[500]
                                      : Colors.black87,
                                  decoration: widget.todo.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  DeadlineBadge(deadline: widget.todo.deadline),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isSelectionMode) ...[
                          PriorityIndicator(priority: widget.todo.priority),
                        ] else ...[
                          PriorityIndicator(priority: widget.todo.priority),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
