import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/ui/app_size_tokens.dart';
import '../../services/app_logger.dart';
import '../../services/permission_service.dart';

class AppPermissionsScreen extends StatefulWidget {
  const AppPermissionsScreen({super.key});

  @override
  State<AppPermissionsScreen> createState() => _AppPermissionsScreenState();
}

class _AppPermissionsScreenState extends State<AppPermissionsScreen>
    with WidgetsBindingObserver {
  static const String _tag = 'AppPermissionsScreen';

  bool _isLoading = true;
  bool _accessibilityGranted = false;
  bool _usageStatsGranted = false;
  bool _notificationListenerGranted = false;
  bool _dndGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadPermissions();
    }
  }

  Future<void> _loadPermissions() async {
    try {
      final accessibilityGranted =
          await PermissionService.isAccessibilityServiceEnabled();
      final usageStatsGranted =
          await PermissionService.isUsageStatsPermissionGranted();
      final notificationListenerGranted =
          await PermissionService.isNotificationListenerAccessGranted();
      final dndGranted = await PermissionService.isDoNotDisturbAccessGranted();

      if (!mounted) return;

      setState(() {
        _accessibilityGranted = accessibilityGranted;
        _usageStatsGranted = usageStatsGranted;
        _notificationListenerGranted = notificationListenerGranted;
        _dndGranted = dndGranted;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to load permissions.',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          'Izin Aplikasi',
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
                _buildInfoCard(),
                SizedBox(height: AppSizeTokens.space24),
                _buildSectionHeader('Izin Wajib (Penting)'),
                SizedBox(height: AppSizeTokens.space12),
                _buildPermissionsCard([
                  _buildPermissionItem(
                    title: 'Akses Penggunaan',
                    description:
                        'Mendeteksi aplikasi yang sedang dibuka untuk memblokir distraksi',
                    isGranted: _usageStatsGranted,
                    importance: _PermissionImportance.high,
                    onTap: () async {
                      await PermissionService.openUsageStatsSettings();
                    },
                  ),
                  _buildDivider(),
                  _buildPermissionItem(
                    title: 'Aksesibilitas',
                    description: 'Menutup paksa aplikasi yang diblokir',
                    isGranted: _accessibilityGranted,
                    importance: _PermissionImportance.high,
                    onTap: () async {
                      await PermissionService.openAccessibilitySettings();
                    },
                  ),
                ]),
                SizedBox(height: AppSizeTokens.space24),
                _buildSectionHeader('Izin Opsional (Sedang)'),
                SizedBox(height: AppSizeTokens.space12),
                _buildPermissionsCard([
                  _buildPermissionItem(
                    title: 'Akses Notifikasi',
                    description: 'Memfilter notifikasi dari aplikasi distraksi',
                    isGranted: _notificationListenerGranted,
                    importance: _PermissionImportance.medium,
                    onTap: () async {
                      await PermissionService.openNotificationListenerSettings();
                    },
                  ),
                  _buildDivider(),
                  _buildPermissionItem(
                    title: 'Jangan Ganggu',
                    description: 'Membisukan semua notifikasi saat fokus',
                    isGranted: _dndGranted,
                    importance: _PermissionImportance.medium,
                    onTap: () async {
                      await PermissionService.openDoNotDisturbSettings();
                    },
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(AppSizeTokens.cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
        border: Border.all(
          color: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF4A6FA5),
            size: AppSizeTokens.icon24,
          ),
          SizedBox(width: AppSizeTokens.space12),
          Expanded(
            child: Text(
              'Aplikasi membutuhkan beberapa izin sistem untuk menjalankan fitur pemblokiran distraksi dengan baik. Data Anda tetap aman dan hanya diproses di perangkat ini.',
              style: TextStyle(
                fontSize: AppSizeTokens.text14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
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

  Widget _buildPermissionsCard(List<Widget> children) {
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

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required bool isGranted,
    required _PermissionImportance importance,
    required VoidCallback onTap,
  }) {
    final statusColor = isGranted ? Colors.green : Colors.red;
    final statusText = isGranted ? 'Diizinkan' : 'Belum Diizinkan';
    final statusIcon = isGranted ? Icons.check_circle : Icons.cancel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
        child: Padding(
          padding: EdgeInsets.all(AppSizeTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: AppSizeTokens.text16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(width: AppSizeTokens.space8),
                            _buildImportanceChip(importance),
                          ],
                        ),
                        SizedBox(height: AppSizeTokens.space4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: AppSizeTokens.text13,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizeTokens.space12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: AppSizeTokens.icon20,
                      ),
                      SizedBox(width: AppSizeTokens.space8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: AppSizeTokens.text14,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  if (!isGranted)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizeTokens.space12,
                        vertical: AppSizeTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A6FA5),
                        borderRadius: BorderRadius.circular(
                          AppSizeTokens.radius12,
                        ),
                      ),
                      child: Text(
                        'Izinkan',
                        style: TextStyle(
                          fontSize: AppSizeTokens.text12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: AppSizeTokens.icon20,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportanceChip(_PermissionImportance importance) {
    Color bgColor;
    Color textColor;
    String label;

    switch (importance) {
      case _PermissionImportance.high:
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        label = 'Penting';
        break;
      case _PermissionImportance.medium:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[800]!;
        label = 'Sedang';
        break;
      case _PermissionImportance.low:
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        label = 'Rendah';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizeTokens.space8,
        vertical: 2.sp,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[100]);
  }
}

enum _PermissionImportance { high, medium, low }
