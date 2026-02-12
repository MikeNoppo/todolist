import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    final availableHeight = 0.55.sh;
    final horizontalPadding = 0.08.sw;
    final iconSize = (availableHeight * 0.15).clamp(60.w, 120.w).toDouble();
    final featureIconSize = (availableHeight * 0.08)
        .clamp(40.w, 80.w)
        .toDouble();
    final titleSize = 28.sp.clamp(24.sp, 36.sp).toDouble();
    final subtitleSize = 16.sp.clamp(14.sp, 20.sp).toDouble();
    final featureTitleSize = 16.sp.clamp(14.sp, 20.sp).toDouble();
    final featureSubtitleSize = 14.sp.clamp(12.sp, 18.sp).toDouble();
    final smallSpacing = (availableHeight * 0.02).clamp(8.h, 20.h).toDouble();
    final mediumSpacing = (availableHeight * 0.03).clamp(12.h, 30.h).toDouble();

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
                  Icons.center_focus_strong_outlined,
                  size: iconSize * 0.5,
                  color: const Color(0xFF4A6FA5),
                ),
              ),
              Column(
                children: [
                  Text(
                    'Tetap Fokus,\nRaih Tujuan',
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
                    'Bantu kamu fokus dengan memblokir distraksi dan mengingatkan tugas penting.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  _buildFeatureItem(
                    Icons.block_outlined,
                    'Blokir Aplikasi Pengganggu',
                    'Hindari distraksi dari media sosial',
                    featureIconSize,
                    featureTitleSize,
                    featureSubtitleSize,
                    smallSpacing,
                  ),
                  SizedBox(height: mediumSpacing),
                  _buildFeatureItem(
                    Icons.schedule_outlined,
                    'Kelola Waktu Dengan Baik',
                    'Atur prioritas dan deadline tugas',
                    featureIconSize,
                    featureTitleSize,
                    featureSubtitleSize,
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

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String subtitle,
    double featureIconSize,
    double featureTitleSize,
    double featureSubtitleSize,
    double smallSpacing,
  ) {
    final iconSize = featureIconSize * 0.5;

    return Row(
      children: [
        Container(
          width: featureIconSize,
          height: featureIconSize,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10.r),
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
                  fontSize: featureTitleSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: featureSubtitleSize,
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
