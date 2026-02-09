import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: responsive.availableHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Hero icon - Shield protection
              Container(
                width: responsive.iconSizePage2,
                height: responsive.iconSizePage2,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: responsive.iconSizePage2 * 0.5,
                  color: const Color(0xFF4A6FA5),
                ),
              ),

              // Title and subtitle section
              Column(
                children: [
                  Text(
                    'Lindungi Waktu\nProduktifmu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w300,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(0.02)),
                  Text(
                    'Sistem yang bisa mendeteksi dan mencegah akses ke aplikasi yang mengganggu produktivitas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: responsive.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),

              // Workflow steps
              Column(
                children: [
                  _buildWorkflowStep(
                    1,
                    Icons.assignment_outlined,
                    'Buat Daftar Tugas',
                    'Tambahkan tugas dengan prioritas dan deadline',
                    responsive,
                  ),
                  SizedBox(height: responsive.smallSpacing),
                  _buildWorkflowStep(
                    2,
                    Icons.block_outlined,
                    'Aktifkan Perlindungan',
                    'Sistem akan memblokir aplikasi pengganggu',
                    responsive,
                  ),
                  SizedBox(height: responsive.smallSpacing),
                  _buildWorkflowStep(
                    3,
                    Icons.trending_up_outlined,
                    'Tingkatkan Produktivitas',
                    'Fokus pada tugas tanpa gangguan',
                    responsive,
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
    ResponsiveHelper responsive,
  ) {
    final stepFontSize = responsive.stepCircleSize * 0.4;
    final iconSize = responsive.stepIconContainerSize * 0.45;

    return Row(
      children: [
        // Step number
        Container(
          width: responsive.stepCircleSize,
          height: responsive.stepCircleSize,
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
        SizedBox(width: responsive.smallSpacing),
        // Icon
        Container(
          width: responsive.stepIconContainerSize,
          height: responsive.stepIconContainerSize,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: iconSize, color: Colors.black54),
        ),
        SizedBox(width: responsive.smallSpacing),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.stepTitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: responsive.spacing(0.005)),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: responsive.stepSubtitleFontSize,
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
