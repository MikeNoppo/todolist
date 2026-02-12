import 'package:flutter/material.dart';
import '../../services/app_blocker_service.dart';

class InterventionDemoScreen extends StatelessWidget {
  const InterventionDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final blockedApps = AppBlockerService.getDefaultBlockedApps();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Demo Intervention Screen',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final horizontalPadding = constraints.maxWidth < 380 ? 16.0 : 20.0;
          const crossAxisSpacing = 16.0;
          const maxTileWidth = 170.0;

          final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
          var crossAxisCount =
              ((availableWidth + crossAxisSpacing) /
                      (maxTileWidth + crossAxisSpacing))
                  .floor();

          crossAxisCount = crossAxisCount.clamp(1, 3);

          if (textScale >= 1.35 && crossAxisCount > 1) {
            crossAxisCount -= 1;
          }

          final extraHeight = ((textScale - 1.0).clamp(0.0, 1.0)) * 40;
          final cardHeight = 148.0 + extraHeight;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Intervention Screen',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Klik salah satu aplikasi di bawah untuk melihat layar intervensi',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  20,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: 16,
                    mainAxisExtent: cardHeight,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final packageName = blockedApps[index];
                    final appName = AppBlockerService.getAppDisplayName(
                      packageName,
                    );

                    return _buildAppCard(context, packageName, appName);
                  }, childCount: blockedApps.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    String packageName,
    String appName,
  ) {
    // Map package names to appropriate icons
    final Map<String, IconData> appIcons = {
      'com.facebook.katana': Icons.facebook,
      'com.instagram.android': Icons.camera_alt,
      'com.twitter.android': Icons.alternate_email,
      'com.snapchat.android': Icons.camera,
      'com.zhiliaoapp.musically': Icons.music_note,
      'com.google.android.youtube': Icons.play_arrow,
      'com.spotify.music': Icons.music_note_outlined,
      'com.netflix.mediaclient': Icons.movie,
    };

    final iconData = appIcons[packageName] ?? Icons.apps;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInterventionScreen(context, packageName),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: const Color(0xFF4A6FA5),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: Text(
                    appName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Diblokir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInterventionScreen(BuildContext context, String packageName) {
    AppBlockerService.showInterventionScreen(context, packageName);
  }
}
