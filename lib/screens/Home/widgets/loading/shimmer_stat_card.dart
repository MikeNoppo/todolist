import 'package:flutter/material.dart';
import 'shimmer_container.dart';

class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          ShimmerContainer(width: 24, height: 24, isCircle: true),
          SizedBox(height: 8),
          ShimmerContainer(width: 30, height: 18),
          SizedBox(height: 4),
          ShimmerContainer(width: 50, height: 12),
        ],
      ),
    );
  }
}
