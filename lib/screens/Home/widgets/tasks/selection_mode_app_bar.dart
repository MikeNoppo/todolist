import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectionModeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback onBulkActions;

  const SelectionModeAppBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.onSelectAll,
    required this.onBulkActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF4A6FA5),
      elevation: 0,
      leading: IconButton(
        onPressed: onCancel,
        icon: Icon(Icons.close, color: Colors.white),
      ),
      title: Text(
        '$selectedCount selected',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onSelectAll,
          icon: Icon(Icons.select_all, color: Colors.white),
          tooltip: 'Select All',
        ),
        IconButton(
          onPressed: selectedCount > 0 ? onBulkActions : null,
          icon: Icon(Icons.more_vert, color: Colors.white),
          tooltip: 'Bulk Actions',
        ),
        SizedBox(width: 8.w),
      ],
    );
  }
}
