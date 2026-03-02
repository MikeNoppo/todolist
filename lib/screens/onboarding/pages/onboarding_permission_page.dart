import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PermissionItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingPermissionPage extends StatefulWidget {
  final VoidCallback onReadComplete;
  final IconData headerIcon;
  final String title;
  final String subtitle;
  final List<PermissionItem> items;
  final String disclaimer;

  const OnboardingPermissionPage({
    super.key,
    required this.onReadComplete,
    required this.headerIcon,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.disclaimer,
  });

  @override
  State<OnboardingPermissionPage> createState() =>
      _OnboardingPermissionPageState();
}

class _OnboardingPermissionPageState extends State<OnboardingPermissionPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasReachedBottom && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll * 0.95; // 95% of the way down

      if (currentScroll >= threshold) {
        setState(() {
          _hasReachedBottom = true;
        });
        widget.onReadComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = 0.08.sw;
    final availableHeight = 0.75.sh;
    final iconSize = (0.1.sh).clamp(50.w, 100.w).toDouble();
    final titleSize = 24.sp.clamp(20.sp, 30.sp).toDouble();
    final subtitleSize = 14.sp.clamp(12.sp, 18.sp).toDouble();
    final permissionTitleSize = 14.sp.clamp(12.sp, 18.sp).toDouble();
    final permissionSubtitleSize = 12.sp.clamp(11.sp, 16.sp).toDouble();
    final disclaimerSize = 12.sp.clamp(11.sp, 16.sp).toDouble();
    final permissionIconSize = (0.025.sh).clamp(16.sp, 32.sp).toDouble();

    double spacing(double ratio) {
      return (ScreenUtil().screenHeight * ratio).clamp(4.h, 100.h).toDouble();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: availableHeight),
          child: Column(
            children: [
              SizedBox(height: spacing(0.02)),
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.headerIcon,
                  size: iconSize * 0.5,
                  color: const Color(0xFF4A6FA5),
                ),
              ),
              SizedBox(height: spacing(0.03)),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w300,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              SizedBox(height: spacing(0.015)),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              SizedBox(height: spacing(0.03)),
              Container(
                padding: EdgeInsets.all(spacing(0.02)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < widget.items.length; i++) ...[
                      if (i > 0) SizedBox(height: spacing(0.015)),
                      _buildPermissionItem(
                        widget.items[i],
                        permissionIconSize,
                        permissionTitleSize,
                        permissionSubtitleSize,
                        spacing,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: spacing(0.02)),
              Text(
                widget.disclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: disclaimerSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.black45,
                  height: 1.3,
                ),
              ),
              SizedBox(height: spacing(0.04)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    PermissionItem item,
    double permissionIconSize,
    double permissionTitleSize,
    double permissionSubtitleSize,
    double Function(double ratio) spacing,
  ) {
    return Row(
      children: [
        Icon(
          item.icon,
          size: permissionIconSize,
          color: const Color(0xFF4A6FA5),
        ),
        SizedBox(width: spacing(0.015)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: permissionTitleSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: spacing(0.002)),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: permissionSubtitleSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
