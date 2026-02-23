import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/ui/app_size_tokens.dart';
import '../../repositories/todo_repository.dart';
import '../../services/app_logger.dart';
import 'app_blocker_settings_screen.dart';
import 'debug_settings_screen.dart';
import 'intervention_rules_settings_screen.dart';
import 'profile_screen.dart';
import '../intervention/intervention_demo_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _tag = 'SettingsScreen';

  final TodoRepository _todoRepository = TodoRepository();
  String _userName = 'Pengguna';
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userName = await _todoRepository.getUserName();
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getBool('notifications_enabled') ?? true;

      if (!mounted) return;

      setState(() {
        _userName = userName ?? 'Pengguna';
        _notificationsEnabled = notifications;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to load settings.',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationSetting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);

      if (!mounted) return;

      setState(() {
        _notificationsEnabled = value;
      });

      HapticFeedback.lightImpact();

      AppLogger.info(_tag, 'Notification setting updated: enabled=$value');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifikasi diaktifkan' : 'Notifikasi dinonaktifkan',
          ),
          backgroundColor: const Color(0xFF4A6FA5),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to update notification setting.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui pengaturan notifikasi'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
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
          icon: Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: AppSizeTokens.text20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
            )
          : ListView(
              padding: EdgeInsets.all(AppSizeTokens.cardPadding),
              children: [
                _buildSectionHeader('Profil'),
                SizedBox(height: AppSizeTokens.space12),
                _buildProfileCard(),

                SizedBox(height: AppSizeTokens.space32),

                _buildSectionHeader('Pengaturan Aplikasi'),
                SizedBox(height: AppSizeTokens.space12),
                _buildSettingsCard([
                  _buildSettingItem(
                    icon: Icons.block_outlined,
                    title: 'Atur Aplikasi Distraksi',
                    subtitle: 'Kelola aplikasi yang akan diblokir',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AppBlockerSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.tune,
                    title: 'Aturan Intervensi',
                    subtitle: 'Atur urgensi deadline untuk pemblokiran',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const InterventionRulesSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.security_outlined,
                    title: 'Test Layar Intervensi',
                    subtitle: 'Lihat preview layar blocking',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InterventionDemoScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.bug_report_outlined,
                    title: 'Debug',
                    subtitle: 'Data policy hard block dan alasan blokir',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebugSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi',
                    subtitle: 'Pengingat tugas dan deadline',
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      onChanged: _updateNotificationSetting,
                      activeThumbColor: const Color(0xFF4A6FA5),
                      activeTrackColor: const Color(
                        0xFF4A6FA5,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                ]),

                SizedBox(height: AppSizeTokens.space32),

                _buildSectionHeader('Tentang'),
                SizedBox(height: AppSizeTokens.space12),
                _buildSettingsCard([
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: 'Versi Aplikasi',
                    subtitle: '1.0.0',
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Kebijakan Privasi',
                    subtitle: 'Pelajari tentang privasi data Anda',
                    onTap: () {
                      _showPrivacyPolicy();
                    },
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppSizeTokens.text14,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.5.sp,
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
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
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            if (!mounted) return;
            if (result == true) {
              _loadSettings(); // Reload settings to get updated name
            }
          },
          borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
          child: Padding(
            padding: EdgeInsets.all(AppSizeTokens.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: Color(0xFF4A6FA5),
                    size: AppSizeTokens.icon28,
                  ),
                ),
                SizedBox(width: AppSizeTokens.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppSizeTokens.text18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: AppSizeTokens.space4),
                      Text(
                        'Kelola profil dan avatar Anda',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppSizeTokens.text14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: AppSizeTokens.icon20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
        child: Padding(
          padding: EdgeInsets.all(AppSizeTokens.cardPadding),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppSizeTokens.radius12),
                ),
                child: Icon(
                  icon,
                  color: Colors.grey[700],
                  size: AppSizeTokens.icon20,
                ),
              ),
              SizedBox(width: AppSizeTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSizeTokens.text16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: AppSizeTokens.space2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSizeTokens.text13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: AppSizeTokens.icon20,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 80.w),
      child: Divider(height: 1, thickness: 1, color: Colors.grey[100]),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kebijakan Privasi'),
        content: SingleChildScrollView(
          child: Text(
            'Aplikasi myTask berkomitmen untuk melindungi privasi Anda:\n\n'
            '• Data tugas disimpan secara lokal di perangkat Anda\n'
            '• Izin akses penggunaan hanya digunakan untuk fitur pemblokiran\n'
            '• Tidak ada data yang dikirim ke server eksternal\n'
            '• Anda memiliki kontrol penuh atas data Anda\n\n'
            'Untuk pertanyaan lebih lanjut, hubungi pengembang.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: Color(0xFF4A6FA5))),
          ),
        ],
      ),
    );
  }
}
