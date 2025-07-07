import 'package:flutter/material.dart';

class ShimmerContainer extends StatelessWidget {
  final double width;
  final double height;
  final bool isCircle;

  const ShimmerContainer({
    super.key,
    required this.width,
    required this.height,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return AnimatedOpacity(
          opacity: value,
          duration: const Duration(milliseconds: 500),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: isCircle ? null : BorderRadius.circular(8),
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            ),
          ),
        );
      },
    );
  }
}
