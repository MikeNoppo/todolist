import 'package:flutter/material.dart';
import '../../../../models/todo_model.dart';
import 'stat_card.dart';

class DashboardOverviewCard extends StatelessWidget {
  final List<TodoModel> todos;

  const DashboardOverviewCard({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    final completedTasks = todos.where((todo) => todo.isCompleted).length;
    final totalTasks = todos.length;
    final todayTasks = todos.where((todo) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadline = DateTime(
        todo.deadline.year,
        todo.deadline.month,
        todo.deadline.day,
      );
      return deadline.isAtSameMomentAs(today);
    }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Tugas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total',
                  value: totalTasks.toString(),
                  icon: Icons.assignment_outlined,
                  color: Colors.grey[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Selesai',
                  value: completedTasks.toString(),
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF4A6FA5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Hari Ini',
                  value: todayTasks.toString(),
                  icon: Icons.today_outlined,
                  color: Colors.grey[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
