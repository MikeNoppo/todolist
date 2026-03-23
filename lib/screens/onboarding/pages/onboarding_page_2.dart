import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final availableHeight = 0.65.sh;
    final horizontalPadding = 0.08.sw;
    final iconSize = (availableHeight * 0.12).clamp(50.w, 100.w).toDouble();
    final titleSize = 28.sp.clamp(24.sp, 36.sp).toDouble();
    final subtitleSize = 16.sp.clamp(14.sp, 20.sp).toDouble();
    final stepCircleSize = (availableHeight * 0.05)
        .clamp(24.w, 50.w)
        .toDouble();
    final stepIconContainer = (availableHeight * 0.07)
        .clamp(32.w, 70.w)
        .toDouble();
    final stepTitleSize = 18.sp.clamp(16.sp, 22.sp).toDouble();
    final stepSubtitleSize = 14.sp.clamp(12.sp, 18.sp).toDouble();
    final smallSpacing = (availableHeight * 0.02).clamp(8.h, 20.h).toDouble();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: availableHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: iconSize * 0.5,
                  color: const Color(0xFF4A6FA5),
                ),
              ),
              Column(
                children: [
                  Text(
                    'Lindungi Waktu\nProduktifmu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w300,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: smallSpacing),
                  Text(
                    'Sistem yang bisa mendeteksi dan mencegah akses ke aplikasi yang mengganggu produktivitas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  _buildWorkflowStep(
                    1,
                    Icons.assignment_outlined,
                    'Buat Daftar Tugas',
                    'Tambahkan tugas dengan prioritas dan deadline',
                    stepCircleSize,
                    stepIconContainer,
                    stepTitleSize,
                    stepSubtitleSize,
                    smallSpacing,
                  ),
                  SizedBox(height: smallSpacing),
                  _buildWorkflowStep(
                    2,
                    Icons.block_outlined,
                    'Aktifkan Perlindungan',
                    'Sistem akan memblokir aplikasi pengganggu',
                    stepCircleSize,
                    stepIconContainer,
                    stepTitleSize,
                    stepSubtitleSize,
                    smallSpacing,
                  ),
                  SizedBox(height: smallSpacing),
                  _buildWorkflowStep(
                    3,
                    Icons.trending_up_outlined,
                    'Tingkatkan Produktivitas',
                    'Fokus pada tugas tanpa gangguan',
                    stepCircleSize,
                    stepIconContainer,
                    stepTitleSize,
                    stepSubtitleSize,
                    smallSpacing,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowStep(
    int step,
    IconData icon,
    String title,
    String subtitle,
    double stepCircleSize,
    double stepIconContainer,
    double stepTitleSize,
    double stepSubtitleSize,
    double smallSpacing,
  ) {
    final stepFontSize = stepCircleSize * 0.4;
    final iconSize = stepIconContainer * 0.45;

    return Row(
      children: [
        Container(
          width: stepCircleSize,
          height: stepCircleSize,
          decoration: const BoxDecoration(
            color: Color(0xFF4A6FA5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: Colors.white,
                fontSize: stepFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: smallSpacing),
        Container(
          width: stepIconContainer,
          height: stepIconContainer,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: iconSize, color: Colors.black54),
        ),
        SizedBox(width: smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: stepTitleSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: stepSubtitleSize,
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
