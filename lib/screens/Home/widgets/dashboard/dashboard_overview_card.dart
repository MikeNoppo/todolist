import 'package:flutter/material.dart';

import '../../../../core/ui/app_size_tokens.dart';
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
    final stats = [
      (
        label: 'Total',
        value: totalTasks.toString(),
        icon: Icons.assignment_outlined,
        color: Colors.grey[600]!,
      ),
      (
        label: 'Selesai',
        value: completedTasks.toString(),
        icon: Icons.check_circle_outline,
        color: const Color(0xFF4A6FA5),
      ),
      (
        label: 'Hari Ini',
        value: todayTasks.toString(),
        icon: Icons.today_outlined,
        color: Colors.grey[700]!,
      ),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSizeTokens.pagePadding,
        AppSizeTokens.space16,
        AppSizeTokens.pagePadding,
        0,
      ),
      padding: EdgeInsets.all(AppSizeTokens.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
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
          Text(
            'Ringkasan Tugas',
            style: TextStyle(
              fontSize: AppSizeTokens.text18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppSizeTokens.space16),
          Builder(
            builder: (context) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSizeTokens.space12,
                  mainAxisSpacing: AppSizeTokens.space12,
                  mainAxisExtent: textScale > 1.2 ? 148 : 132,
                ),
                itemBuilder: (context, index) {
                  final item = stats[index];

                  return StatCard(
                    label: item.label,
                    value: item.value,
                    icon: item.icon,
                    color: item.color,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
