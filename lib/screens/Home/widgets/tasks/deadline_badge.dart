import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeadlineBadge extends StatelessWidget {
  final DateTime deadline;
  final bool isCompleted;

  const DeadlineBadge({
    super.key,
    required this.deadline,
    this.isCompleted = false,
  });

  String _formatDeadline(DateTime deadline) {
    if (isCompleted) return 'Selesai';

    final now = DateTime.now();
    final isOverdue = deadline.isBefore(now);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    final dayDifference = deadlineDate.difference(todayDate).inDays;

    if (isOverdue) {
      final overdueDuration = now.difference(deadline);
      if (overdueDuration.inHours < 1) {
        final minutes = overdueDuration.inMinutes.clamp(1, 59).toInt();
        return 'Terlambat $minutes menit';
      }

      if (overdueDuration.inHours < 24) {
        return 'Terlambat ${overdueDuration.inHours} jam';
      }

      final days = overdueDuration.inDays;
      return 'Terlambat $days hari';
    }

    if (dayDifference == 0) {
      return 'Hari ini';
    } else if (dayDifference == 1) {
      return 'Besok';
    } else {
      return '$dayDifference hari lagi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = deadline.isBefore(now) && !isCompleted;
    final isToday =
        deadline.year == now.year &&
        deadline.month == now.month &&
        deadline.day == now.day &&
        !isCompleted;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green[50]
            : isOverdue
            ? Colors.red[50]
            : isToday
            ? Colors.orange[50]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_outline : Icons.schedule_outlined,
            size: 16.sp,
            color: isCompleted
                ? Colors.green[600]
                : isOverdue
                ? Colors.red[600]
                : isToday
                ? Colors.orange[600]
                : Colors.grey[600],
          ),
          SizedBox(width: 4.w),
          Text(
            _formatDeadline(deadline),
            style: TextStyle(
              fontSize: 13.sp,
              color: isCompleted
                  ? Colors.green[600]
                  : isOverdue
                  ? Colors.red[600]
                  : isToday
                  ? Colors.orange[600]
                  : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
