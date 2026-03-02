import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPage4 extends StatefulWidget {
  final VoidCallback onReadComplete;

  const OnboardingPage4({super.key, required this.onReadComplete});

  @override
  State<OnboardingPage4> createState() => _OnboardingPage4State();
}

class _OnboardingPage4State extends State<OnboardingPage4> {
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
      final threshold = maxScroll * 0.95;

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

    double spacingPage4(double ratio) {
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
              SizedBox(height: spacingPage4(0.02)),
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.query_stats_outlined,
                  size: iconSize * 0.5,
                  color: const Color(0xFF4A6FA5),
                ),
              ),
              SizedBox(height: spacingPage4(0.03)),
              Text(
                'Izin Statistik\nPenggunaan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w300,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              SizedBox(height: spacingPage4(0.015)),
              Text(
                'Agar myTask bisa menilai penggunaan aplikasi dan menjalankan aturan blokir, aktifkan akses statistik penggunaan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              SizedBox(height: spacingPage4(0.03)),
              Container(
                padding: EdgeInsets.all(spacingPage4(0.02)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildPermissionItem(
                      Icons.timeline_outlined,
                      'Memantau Pola Penggunaan',
                      'Melihat aplikasi aktif dan durasi penggunaan',
                      permissionIconSize,
                      permissionTitleSize,
                      permissionSubtitleSize,
                      spacingPage4,
                    ),
                    SizedBox(height: spacingPage4(0.015)),
                    _buildPermissionItem(
                      Icons.rule_outlined,
                      'Menjalankan Aturan Blokir',
                      'Menentukan kapan intervensi harus muncul',
                      permissionIconSize,
                      permissionTitleSize,
                      permissionSubtitleSize,
                      spacingPage4,
                    ),
                    SizedBox(height: spacingPage4(0.015)),
                    _buildPermissionItem(
                      Icons.lock_outline,
                      'Privasi Tetap Terkontrol',
                      'Data penggunaan tetap berada di perangkat',
                      permissionIconSize,
                      permissionTitleSize,
                      permissionSubtitleSize,
                      spacingPage4,
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacingPage4(0.02)),
              Text(
                'Data statistik penggunaan tidak dikirim ke server eksternal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: disclaimerSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.black45,
                  height: 1.3,
                ),
              ),
              SizedBox(height: spacingPage4(0.04)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    IconData icon,
    String title,
    String subtitle,
    double permissionIconSize,
    double permissionTitleSize,
    double permissionSubtitleSize,
    double Function(double ratio) spacingPage4,
  ) {
    return Row(
      children: [
        Icon(icon, size: permissionIconSize, color: const Color(0xFF4A6FA5)),
        SizedBox(width: spacingPage4(0.015)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: permissionTitleSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: spacingPage4(0.002)),
              Text(
                subtitle,
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
