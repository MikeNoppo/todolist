import 'package:flutter/material.dart';

class DeadlineBadge extends StatelessWidget {
  final DateTime deadline;

  const DeadlineBadge({
    super.key,
    required this.deadline,
  });

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    
    if (difference < 0) {
      return 'Terlambat ${difference.abs()} hari';
    } else if (difference == 0) {
      return 'Hari ini';
    } else if (difference == 1) {
      return 'Besok';
    } else {
      return '$difference hari lagi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = deadline.isBefore(now);
    final isToday = deadline.year == now.year && 
                   deadline.month == now.month && 
                   deadline.day == now.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue 
          ? Colors.red[50]
          : isToday 
            ? Colors.orange[50]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 16,
            color: isOverdue 
              ? Colors.red[600]
              : isToday 
                ? Colors.orange[600]
                : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            _formatDeadline(deadline),
            style: TextStyle(
              fontSize: 13,
              color: isOverdue 
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
