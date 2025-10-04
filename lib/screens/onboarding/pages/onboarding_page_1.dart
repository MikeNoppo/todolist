import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: responsive.availableHeight,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Hero icon - Focus target
              Container(
                width: responsive.iconSize,
                height: responsive.iconSize,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.center_focus_strong_outlined,
                  size: responsive.iconSize * 0.5,
                  color: const Color(0xFF4A6FA5),
                ),
              ),
              // Title and subtitle section
              Column(
                children: [
                  Text(
                    'Tetap Fokus,\nRaih Tujuan',
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
                    'Bantu kamu fokus dengan memblokir distraksi dan mengingatkan tugas penting.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: responsive.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              // Feature highlights with icons
              Column(
                children: [
                  _buildFeatureItem(
                    Icons.block_outlined,
                    'Blokir Aplikasi Pengganggu',
                    'Hindari distraksi dari media sosial',
                    responsive,
                  ),
                  SizedBox(height: responsive.mediumSpacing),
                  _buildFeatureItem(
                    Icons.schedule_outlined,
                    'Kelola Waktu Dengan Baik',
                    'Atur prioritas dan deadline tugas',
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

  Widget _buildFeatureItem(
    IconData icon, 
    String title, 
    String subtitle, 
    ResponsiveHelper responsive,
  ) {
    final iconSize = responsive.featureIconContainerSize * 0.5;
    
    return Row(
      children: [
        Container(
          width: responsive.featureIconContainerSize,
          height: responsive.featureIconContainerSize,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: Colors.black54,
          ),
        ),
        SizedBox(width: responsive.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.featureTitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: responsive.spacing(0.005)),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: responsive.featureSubtitleFontSize,
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
