import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/installed_focus_app.dart';
import '../../services/app_blocker_service.dart';
import '../../services/app_logger.dart';
import '../../services/notification_interruption_service.dart';
import '../../services/permission_service.dart';

class AppBlockerSettingsScreen extends StatefulWidget {
  const AppBlockerSettingsScreen({super.key});

  @override
  State<AppBlockerSettingsScreen> createState() =>
      _AppBlockerSettingsScreenState();
}

class _AppBlockerSettingsScreenState extends State<AppBlockerSettingsScreen> {
  static const String _tag = 'AppBlockerSettingsScreen';

  final NotificationInterruptionService _notificationInterruptionService =
      NotificationInterruptionService();
  List<InstalledFocusApp> _installedApps = [];
  Map<String, bool> _blockedApps = {};
  Map<String, bool> _alwaysAllowedApps = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final installedApps = await PermissionService.getInstalledFocusApps();
      final Map<String, bool> blockedApps = {};
      final Map<String, bool> alwaysAllowedApps = {};
      final hasAnyUserBlockConfig = prefs.getKeys().any(
        (key) => key.startsWith(AppBlockerService.blockKeyPrefix),
      );
      for (final app in installedApps) {
        final isAlwaysAllowed =
            prefs.getBool(
              '${AppBlockerService.allowKeyPrefix}${app.packageName}',
            ) ??
            false;
        final isBlocked = hasAnyUserBlockConfig
            ? prefs.getBool(
                    '${AppBlockerService.blockKeyPrefix}${app.packageName}',
                  ) ??
                  false
            : false;
        blockedApps[app.packageName] = isAlwaysAllowed ? false : isBlocked;
        alwaysAllowedApps[app.packageName] = isAlwaysAllowed;
      }

      final appNamesMap = {
        for (final app in installedApps) app.packageName: app.appName,
      };
      await AppBlockerService.cacheAppDisplayNames(appNamesMap);

      final blockedCount = blockedApps.values
          .where((isBlocked) => isBlocked)
          .length;
      AppLogger.info(
        _tag,
        'Loaded blocked apps: $blockedCount/${blockedApps.length}',
      );

      if (!mounted) return;

      setState(() {
        _installedApps = installedApps;
        _blockedApps = blockedApps;
        _alwaysAllowedApps = alwaysAllowedApps;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to load blocked apps.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAppBlock(String packageName, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        '${AppBlockerService.blockKeyPrefix}$packageName',
        value,
      );

      if (value) {
        await prefs.setBool(
          '${AppBlockerService.allowKeyPrefix}$packageName',
          false,
        );
      }

      await _notificationInterruptionService.syncNativeState();

      if (!mounted) return;

      setState(() {
        _blockedApps[packageName] = value;
        if (value) {
          _alwaysAllowedApps[packageName] = false;
        }
      });

      if (!mounted) return;

      AppLogger.info(
        _tag,
        'Updated app block status: package=$packageName blocked=$value',
      );

      HapticFeedback.lightImpact();

      var appName = packageName;
      for (final app in _installedApps) {
        if (app.packageName == packageName) {
          appName = app.appName;
          break;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? '$appName diblokir' : '$appName tidak diblokir',
          ),
          backgroundColor: const Color(0xFF4A6FA5),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to update app block status: package=$packageName',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status blokir aplikasi'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleAlwaysAllow(String packageName, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        '${AppBlockerService.allowKeyPrefix}$packageName',
        value,
      );

      if (value) {
        await prefs.setBool(
          '${AppBlockerService.blockKeyPrefix}$packageName',
          false,
        );
      }

      await _notificationInterruptionService.syncNativeState();

      if (!mounted) return;

      setState(() {
        _alwaysAllowedApps[packageName] = value;
        if (value) {
          _blockedApps[packageName] = false;
        }
      });

      HapticFeedback.lightImpact();

      var appName = packageName;
      for (final app in _installedApps) {
        if (app.packageName == packageName) {
          appName = app.appName;
          break;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '$appName masuk whitelist (selalu diizinkan)'
                : '$appName dikeluarkan dari whitelist',
          ),
          backgroundColor: const Color(0xFF4A6FA5),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to update always-allow setting: package=$packageName',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _reloadInstalledApps() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    await _loadSettings();
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
        actions: [
          IconButton(
            onPressed: _reloadInstalledApps,
            icon: Icon(Icons.refresh, color: Colors.grey[700]),
            tooltip: 'Refresh aplikasi',
          ),
        ],
        title: Text(
          'Atur Aplikasi Distraksi',
          style: TextStyle(
            fontSize: 20.sp,
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
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
              children: [
                _buildHeaderCard(),
                SizedBox(height: 12.h),
                if (_installedApps.isEmpty)
                  _buildNoAppsCard()
                else
                  ..._installedApps.map((app) {
                    final isBlocked = _blockedApps[app.packageName] ?? false;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: _buildAppTile(app: app, isBlocked: isBlocked),
                    );
                  }),
                SizedBox(height: 12.h),
                _buildBottomInfoCard(),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6FA5).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
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
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: const Color(0xFF4A6FA5),
              size: 24.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Pilih Aplikasi Sosial & Game',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Aktifkan aplikasi yang ingin diblokir. Atur urgensi deadline dari menu Aturan Intervensi di halaman Pengaturan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTile({
    required InstalledFocusApp app,
    required bool isBlocked,
  }) {
    final accentColor = _getCategoryAccentColor(app.category);
    final isAlwaysAllowed = _alwaysAllowedApps[app.packageName] ?? false;
    final statusLabel = isAlwaysAllowed
        ? 'Selalu diizinkan'
        : isBlocked
        ? 'Akan diblokir'
        : 'Tidak diblokir';
    final statusColor = isAlwaysAllowed
        ? const Color(0xFF2E8B57)
        : isBlocked
        ? const Color(0xFF4A6FA5)
        : Colors.grey[600]!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: app.iconBytes.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.memory(
                                app.iconBytes,
                                width: 24.sp,
                                height: 24.sp,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      _getCategoryFallbackIcon(app.category),
                                      color: accentColor,
                                      size: 24.sp,
                                    ),
                              ),
                            )
                          : Icon(
                              _getCategoryFallbackIcon(app.category),
                              color: accentColor,
                              size: 24.sp,
                            ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.appName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Text(
                                _formatCategoryLabel(app.category),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: statusColor,
                                    fontWeight: isAlwaysAllowed || isBlocked
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: isBlocked,
                      onChanged: (value) =>
                          _toggleAppBlock(app.packageName, value),
                      activeColor: const Color(0xFF4A6FA5),
                      activeTrackColor: const Color(
                        0xFF4A6FA5,
                      ).withValues(alpha: 0.3),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                InkWell(
                  onTap: () =>
                      _toggleAlwaysAllow(app.packageName, !isAlwaysAllowed),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAlwaysAllowed
                              ? Icons.verified_user_outlined
                              : Icons.shield_outlined,
                          size: 16.sp,
                          color: isAlwaysAllowed
                              ? const Color(0xFF2E8B57)
                              : Colors.grey[600],
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          isAlwaysAllowed
                              ? 'Whitelist aktif'
                              : 'Masukkan whitelist',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isAlwaysAllowed
                                ? const Color(0xFF2E8B57)
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildBottomInfoCard() {
    final blockedCount = _blockedApps.values.where((blocked) => blocked).length;
    final allowCount = _alwaysAllowedApps.values
        .where((isAllowed) => isAllowed)
        .length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 8.h),
          Text(
            '$blockedCount diblokir • $allowCount whitelist • ${_installedApps.length} terdeteksi',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A6FA5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAppsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.apps_outlined, size: 24.sp, color: Colors.grey[600]),
          SizedBox(height: 8.h),
          Text(
            'Belum ada aplikasi sosial/game terdeteksi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Pastikan izin aplikasi sudah diberikan, lalu tap tombol refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getCategoryAccentColor(InstalledAppCategory category) {
    switch (category) {
      case InstalledAppCategory.social:
        return const Color(0xFF4A6FA5);
      case InstalledAppCategory.game:
        return const Color(0xFF2E8B57);
    }
  }

  IconData _getCategoryFallbackIcon(InstalledAppCategory category) {
    switch (category) {
      case InstalledAppCategory.social:
        return Icons.forum_outlined;
      case InstalledAppCategory.game:
        return Icons.sports_esports_outlined;
    }
  }

  String _formatCategoryLabel(InstalledAppCategory category) {
    switch (category) {
      case InstalledAppCategory.social:
        return 'Sosial';
      case InstalledAppCategory.game:
        return 'Game';
    }
  }
}
