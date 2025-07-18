import 'package:flutter/material.dart';
import '../../services/app_blocker_service.dart';

class InterventionDemoScreen extends StatelessWidget {
  const InterventionDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(20),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Grid of blocked apps for demo
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: AppBlockerService.getDefaultBlockedApps().length,
                itemBuilder: (context, index) {
                  final packageName = AppBlockerService.getDefaultBlockedApps()[index];
                  final appName = AppBlockerService.getAppDisplayName(packageName);
                  
                  return _buildAppCard(context, packageName, appName);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, String packageName, String appName) {
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
            color: Colors.black.withOpacity(0.04),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: const Color(0xFF4A6FA5),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
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
