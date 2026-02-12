import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'shimmer_container.dart';

class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          ShimmerContainer(width: 24, height: 24, isCircle: true),
          SizedBox(height: 8.h),
          ShimmerContainer(width: 30, height: 18),
          SizedBox(height: 4.h),
          ShimmerContainer(width: 50, height: 12),
        ],
      ),
    );
  }
}
