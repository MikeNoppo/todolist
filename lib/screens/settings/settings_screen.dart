import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../repositories/todo_repository.dart';
import 'app_blocker_settings_screen.dart';
import 'profile_screen.dart';
import '../intervention/intervention_demo_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    } catch (e) {
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifikasi diaktifkan' : 'Notifikasi dinonaktifkan',
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
          'Pengaturan',
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
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile Section
              _buildSectionHeader('Profil'),
              const SizedBox(height: 12),
              _buildProfileCard(),
              
              const SizedBox(height: 32),
              
              // App Settings Section
              _buildSectionHeader('Pengaturan Aplikasi'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildSettingItem(
                  icon: Icons.block_outlined,
                  title: 'Atur Aplikasi Distraksi',
                  subtitle: 'Kelola aplikasi yang akan diblokir',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppBlockerSettingsScreen(),
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
                  icon: Icons.notifications_outlined,
                  title: 'Notifikasi',
                  subtitle: 'Pengingat tugas dan deadline',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: _updateNotificationSetting,
                    activeThumbColor: const Color(0xFF4A6FA5),
                    activeTrackColor: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
                  ),
                ),
              ]),
              
              const SizedBox(height: 32),
              
              // About Section
              _buildSectionHeader('Tentang'),
              const SizedBox(height: 12),
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProfileCard() {
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
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
            if (!mounted) return;
            if (result == true) {
              _loadSettings(); // Reload settings to get updated name
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF4A6FA5),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola profil dan avatar Anda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
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
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.grey[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 80),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[100],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kebijakan Privasi'),
        content: const SingleChildScrollView(
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
            child: const Text(
              'Tutup',
              style: TextStyle(color: Color(0xFF4A6FA5)),
            ),
          ),
        ],
      ),
    );
  }
}
