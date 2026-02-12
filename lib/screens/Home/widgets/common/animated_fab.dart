import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AnimatedFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
                  blurRadius: 15 * value,
                  offset: Offset(0, 4 * value),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: onPressed,
              backgroundColor: const Color(0xFF4A6FA5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 24.sp),
            ),
          ),
        );
      },
    );
  }
}
