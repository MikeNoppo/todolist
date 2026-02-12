import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/todo_model.dart';

class PriorityIndicator extends StatelessWidget {
  final TodoPriority priority;

  const PriorityIndicator({super.key, required this.priority});

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return const Color(0xFF4A6FA5);
      case TodoPriority.medium:
        return Colors.grey[600]!;
      case TodoPriority.low:
        return Colors.grey[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 50,
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        borderRadius: BorderRadius.circular(3.r),
      ),
    );
  }
}
