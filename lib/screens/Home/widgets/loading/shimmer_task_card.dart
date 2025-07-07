import 'package:flutter/material.dart';
import 'shimmer_container.dart';

class ShimmerTaskCard extends StatelessWidget {
  const ShimmerTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          ShimmerContainer(width: 28, height: 28, isCircle: true),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerContainer(width: 200, height: 16),
                SizedBox(height: 12),
                ShimmerContainer(width: 120, height: 32),
              ],
            ),
          ),
          ShimmerContainer(width: 6, height: 50),
        ],
      ),
    );
  }
}
