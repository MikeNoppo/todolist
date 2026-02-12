import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TodoCheckbox extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onToggle;

  const TodoCheckbox({
    super.key,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isCompleted ? const Color(0xFF4A6FA5) : Colors.grey[300]!,
            width: 2,
          ),
          color: isCompleted ? const Color(0xFF4A6FA5) : Colors.transparent,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isCompleted
              ? Icon(
                  Icons.check,
                  size: 18.sp,
                  color: Colors.white,
                  key: ValueKey('checked'),
                )
              : const SizedBox.shrink(key: ValueKey('unchecked')),
        ),
      ),
    );
  }
}
