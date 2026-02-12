import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'shimmer_container.dart';
import 'shimmer_stat_card.dart';
import 'shimmer_task_card.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          pinned: true,
          expandedHeight: 160,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShimmerContainer(
                            width: 48,
                            height: 48,
                            isCircle: true,
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerContainer(width: 80, height: 14),
                              SizedBox(height: 4.h),
                              ShimmerContainer(width: 120, height: 20),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      ShimmerContainer(width: 150, height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0.h),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
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
                ShimmerContainer(width: 140, height: 18),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: ShimmerStatCard()),
                    SizedBox(width: 12.w),
                    Expanded(child: ShimmerStatCard()),
                    SizedBox(width: 12.w),
                    Expanded(child: ShimmerStatCard()),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 100.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const ShimmerTaskCard(),
              childCount: 5,
            ),
          ),
        ),
      ],
    );
  }
}
