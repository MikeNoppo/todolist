import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBlockerSettingsScreen extends StatefulWidget {
  const AppBlockerSettingsScreen({super.key});

  @override
  State<AppBlockerSettingsScreen> createState() => _AppBlockerSettingsScreenState();
}

class _AppBlockerSettingsScreenState extends State<AppBlockerSettingsScreen> {
  Map<String, bool> _blockedApps = {};
  bool _isLoading = true;

  // Mock list of installed apps (in a real app, you'd get this from the system)
  final List<AppInfo> _installedApps = [
    AppInfo(
      packageName: 'com.facebook.katana',
      appName: 'Facebook',
      iconData: Icons.facebook,
    ),
    AppInfo(
      packageName: 'com.instagram.android',
      appName: 'Instagram',
      iconData: Icons.camera_alt,
    ),
    AppInfo(
      packageName: 'com.twitter.android',
      appName: 'Twitter',
      iconData: Icons.alternate_email,
    ),
    AppInfo(
      packageName: 'com.snapchat.android',
      appName: 'Snapchat',
      iconData: Icons.camera,
    ),
    AppInfo(
      packageName: 'com.zhiliaoapp.musically',
      appName: 'TikTok',
      iconData: Icons.music_note,
    ),
    AppInfo(
      packageName: 'com.whatsapp',
      appName: 'WhatsApp',
      iconData: Icons.chat,
    ),
    AppInfo(
      packageName: 'com.google.android.youtube',
      appName: 'YouTube',
      iconData: Icons.play_arrow,
    ),
    AppInfo(
      packageName: 'com.spotify.music',
      appName: 'Spotify',
      iconData: Icons.music_note_outlined,
    ),
    AppInfo(
      packageName: 'com.netflix.mediaclient',
      appName: 'Netflix',
      iconData: Icons.movie,
    ),
    AppInfo(
      packageName: 'com.google.android.apps.photos',
      appName: 'Google Photos',
      iconData: Icons.photo_library,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBlockedApps();
  }

  Future<void> _loadBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, bool> blockedApps = {};
      
      for (final app in _installedApps) {
        final isBlocked = prefs.getBool('block_${app.packageName}') ?? false;
        blockedApps[app.packageName] = isBlocked;
      }

      if (!mounted) return;
      
      setState(() {
        _blockedApps = blockedApps;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAppBlock(String packageName, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('block_$packageName', value);

      if (!mounted) return;
      
      setState(() {
        _blockedApps[packageName] = value;
      });
      
      HapticFeedback.lightImpact();
      
      final appName = _installedApps.firstWhere((app) => app.packageName == packageName).appName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? '$appName diblokir' : '$appName tidak diblokir',
          ),
          backgroundColor: const Color(0xFF4A6FA5),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
        ),
        title: const Text(
          'Atur Aplikasi Distraksi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A6FA5)))
        : Column(
            children: [
              // Header Information
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6FA5).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF4A6FA5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pilih Aplikasi untuk Diblokir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aplikasi yang diaktifkan akan diblokir saat Anda memiliki tugas dengan prioritas tinggi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Apps List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _installedApps.length,
                  itemBuilder: (context, index) {
                    final app = _installedApps[index];
                    final isBlocked = _blockedApps[app.packageName] ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleAppBlock(app.packageName, !isBlocked),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // App Icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getAppIconColor(app.packageName).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    app.iconData,
                                    color: _getAppIconColor(app.packageName),
                                    size: 24,
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // App Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.appName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isBlocked ? 'Akan diblokir' : 'Tidak diblokir',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isBlocked 
                                            ? const Color(0xFF4A6FA5) 
                                            : Colors.grey[600],
                                          fontWeight: isBlocked 
                                            ? FontWeight.w500 
                                            : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Toggle Switch
                                Switch.adaptive(
                                  value: isBlocked,
                                  onChanged: (value) => _toggleAppBlock(app.packageName, value),
                                  activeThumbColor: const Color(0xFF4A6FA5),
                                  activeTrackColor: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pemblokiran aktif hanya ketika ada tugas prioritas tinggi',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_blockedApps.values.where((blocked) => blocked).length} dari ${_installedApps.length} aplikasi diblokir',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6FA5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Color _getAppIconColor(String packageName) {
    // Return different colors for different apps to make them visually distinct
    switch (packageName) {
      case 'com.facebook.katana':
        return const Color(0xFF1877F2);
      case 'com.instagram.android':
        return const Color(0xFFE4405F);
      case 'com.twitter.android':
        return const Color(0xFF1DA1F2);
      case 'com.snapchat.android':
        return const Color(0xFFFFFC00);
      case 'com.zhiliaoapp.musically':
        return const Color(0xFF000000);
      case 'com.whatsapp':
        return const Color(0xFF25D366);
      case 'com.google.android.youtube':
        return const Color(0xFFFF0000);
      case 'com.spotify.music':
        return const Color(0xFF1DB954);
      case 'com.netflix.mediaclient':
        return const Color(0xFFE50914);
      case 'com.google.android.apps.photos':
        return const Color(0xFF4285F4);
      default:
        return Colors.grey[600]!;
    }
  }
}

class AppInfo {
  final String packageName;
  final String appName;
  final IconData iconData;

  AppInfo({
    required this.packageName,
    required this.appName,
    required this.iconData,
  });
}
