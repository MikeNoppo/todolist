import 'package:flutter/material.dart';
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShimmerContainer(width: 48, height: 48, isCircle: true),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerContainer(width: 80, height: 14),
                              SizedBox(height: 4),
                              ShimmerContainer(width: 120, height: 20),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerContainer(width: 140, height: 18),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ShimmerStatCard()),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerStatCard()),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerStatCard()),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
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
