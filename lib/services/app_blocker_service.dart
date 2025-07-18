import 'package:flutter/material.dart';
import '../screens/intervention/intervention_screen.dart';

class AppBlockerService {
  static const List<String> _defaultBlockedApps = [
    'com.facebook.katana',
    'com.instagram.android',
    'com.twitter.android',
    'com.snapchat.android',
    'com.zhiliaoapp.musically',
    'com.google.android.youtube',
    'com.spotify.music',
    'com.netflix.mediaclient',
  ];

  static const Map<String, String> _appNames = {
    'com.facebook.katana': 'Facebook',
    'com.instagram.android': 'Instagram',
    'com.twitter.android': 'Twitter',
    'com.snapchat.android': 'Snapchat',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.google.android.youtube': 'YouTube',
    'com.spotify.music': 'Spotify',
    'com.netflix.mediaclient': 'Netflix',
  };

  /// Check if an app should be blocked
  // TODO: Implement logic to determine if an app should be blocked
  static bool shouldBlockApp(String packageName) {
    // In a real implementation, this would check:
    // 1. If the app is in the user's blocked list
    // 2. If there are any urgent tasks pending
    // 3. If the blocking feature is enabled
    return _defaultBlockedApps.contains(packageName);
  }

  /// Show intervention screen for a blocked app
  static void showInterventionScreen(
    BuildContext context,
    String packageName,
  ) {
    final appName = _appNames[packageName] ?? 'Unknown App';
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            InterventionScreen(
          blockedAppName: appName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        fullscreenDialog: true,
      ),
    );
  }

  /// Get the display name for an app package
  static String getAppDisplayName(String packageName) {
    return _appNames[packageName] ?? packageName;
  }

  /// Get all default blocked apps
  static List<String> getDefaultBlockedApps() {
    return List.from(_defaultBlockedApps);
  }

  /// Get app names mapping
  static Map<String, String> getAppNamesMapping() {
    return Map.from(_appNames);
  }
}
