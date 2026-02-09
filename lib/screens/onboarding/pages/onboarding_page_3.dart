import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class OnboardingPage3 extends StatefulWidget {
  final VoidCallback onReadComplete;

  const OnboardingPage3({super.key, required this.onReadComplete});

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3> {
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
    final responsive = ResponsiveHelper(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: responsive.availableHeightPage3,
          ),
          child: Column(
            children: [
              SizedBox(height: responsive.spacingPage3(0.02)),
              // Hero icon - Security/Permission
              Container(
                width: responsive.iconSizePage3,
                height: responsive.iconSizePage3,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_outlined,
                  size: responsive.iconSizePage3 * 0.5,
                  color: const Color(0xFF4A6FA5),
                ),
              ),
              SizedBox(height: responsive.spacingPage3(0.03)),
              // Title
              Text(
                'Izin Akses\nPenggunaan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.titleFontSizePage3,
                  fontWeight: FontWeight.w300,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              SizedBox(height: responsive.spacingPage3(0.015)),
              // Subtitle
              Text(
                'Untuk memblokir aplikasi pengganggu, kami memerlukan izin akses penggunaan aplikasi di perangkat Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.subtitleFontSizePage3,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              SizedBox(height: responsive.spacingPage3(0.03)),
              // Permission info
              Container(
                padding: EdgeInsets.all(responsive.spacingPage3(0.02)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildPermissionItem(
                      Icons.visibility_outlined,
                      'Memantau Aplikasi Aktif',
                      'Mendeteksi aplikasi yang sedang digunakan',
                      responsive,
                    ),
                    SizedBox(height: responsive.spacingPage3(0.015)),
                    _buildPermissionItem(
                      Icons.block_outlined,
                      'Mencegah Akses Aplikasi',
                      'Memblokir aplikasi yang mengganggu',
                      responsive,
                    ),
                    SizedBox(height: responsive.spacingPage3(0.015)),
                    _buildPermissionItem(
                      Icons.lock_outline,
                      'Privasi Terjamin',
                      'Data tidak dibagikan ke pihak ketiga',
                      responsive,
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacingPage3(0.02)),
              // Disclaimer
              Text(
                'Izin ini hanya digunakan untuk fitur pemblokiran aplikasi dan tidak akan mengakses data pribadi Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.disclaimerFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.black45,
                  height: 1.3,
                ),
              ),
              SizedBox(
                height: responsive.spacingPage3(0.04),
              ), // Extra space to ensure scroll
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
    ResponsiveHelper responsive,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: responsive.permissionIconSize,
          color: const Color(0xFF4A6FA5),
        ),
        SizedBox(width: responsive.spacingPage3(0.015)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.permissionTitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: responsive.spacingPage3(0.002)),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: responsive.permissionSubtitleFontSize,
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
