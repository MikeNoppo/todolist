import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/installed_focus_app.dart';
import '../../models/todo_model.dart';
import '../../services/app_blocker_service.dart';
import '../../services/app_logger.dart';
import '../../services/permission_service.dart';

class AppBlockerSettingsScreen extends StatefulWidget {
  const AppBlockerSettingsScreen({super.key});

  @override
  State<AppBlockerSettingsScreen> createState() =>
      _AppBlockerSettingsScreenState();
}

class _AppBlockerSettingsScreenState extends State<AppBlockerSettingsScreen> {
  static const String _tag = 'AppBlockerSettingsScreen';

  List<InstalledFocusApp> _installedApps = [];
  Map<String, bool> _blockedApps = {};
  int _lowWindowHours = AppBlockerService.defaultLowWindowHours;
  int _mediumWindowHours = AppBlockerService.defaultMediumWindowHours;
  int _highWindowHours = AppBlockerService.defaultHighWindowHours;
  bool _isLoading = true;
  bool _isDebugLoading = true;
  InterventionDebugInfo? _debugInfo;

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

      for (final app in installedApps) {
        final isBlocked =
            prefs.getBool(
              '${AppBlockerService.blockKeyPrefix}${app.packageName}',
            ) ??
            false;
        blockedApps[app.packageName] = isBlocked;
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

      final lowWindow =
          prefs.getInt(AppBlockerService.lowWindowHoursKey) ??
          AppBlockerService.defaultLowWindowHours;
      final mediumWindow =
          prefs.getInt(AppBlockerService.mediumWindowHoursKey) ??
          AppBlockerService.defaultMediumWindowHours;
      final highWindow =
          prefs.getInt(AppBlockerService.highWindowHoursKey) ??
          AppBlockerService.defaultHighWindowHours;
      final debugInfo = await AppBlockerService.getInterventionDebugInfo();

      if (!mounted) return;

      setState(() {
        _installedApps = installedApps;
        _blockedApps = blockedApps;
        _lowWindowHours = lowWindow;
        _mediumWindowHours = mediumWindow;
        _highWindowHours = highWindow;
        _debugInfo = debugInfo;
        _isLoading = false;
        _isDebugLoading = false;
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
        _isDebugLoading = false;
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

      if (!mounted) return;

      setState(() {
        _blockedApps[packageName] = value;
      });

      await _refreshDebugInfo();

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

  Future<void> _updatePriorityWindow(TodoPriority priority, int hours) async {
    try {
      await AppBlockerService.saveInterventionWindow(priority, hours);

      if (!mounted) return;

      setState(() {
        switch (priority) {
          case TodoPriority.low:
            _lowWindowHours = hours;
            break;
          case TodoPriority.medium:
            _mediumWindowHours = hours;
            break;
          case TodoPriority.high:
            _highWindowHours = hours;
            break;
        }
      });

      await _refreshDebugInfo();

      AppLogger.info(
        _tag,
        'Updated intervention window: priority=$priority hours=$hours',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to update intervention window for priority=$priority',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _refreshDebugInfo({bool showLoader = false}) async {
    if (!mounted) return;

    if (showLoader) {
      setState(() {
        _isDebugLoading = true;
      });
    }

    try {
      final debugInfo = await AppBlockerService.getInterventionDebugInfo();

      if (!mounted) return;
      setState(() {
        _debugInfo = debugInfo;
        _isDebugLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to refresh intervention debug info.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      setState(() {
        _isDebugLoading = false;
      });
    }
  }

  Future<void> _reloadInstalledApps() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isDebugLoading = true;
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
                _buildInterventionWindowCard(),
                SizedBox(height: 12.h),
                _buildDebugPanelCard(),
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
            'Aplikasi yang diaktifkan akan diblokir jika ada tugas yang mendekati deadline sesuai pengaturan urgensi',
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
            child: Row(
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
                            errorBuilder: (context, error, stackTrace) => Icon(
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
                              isBlocked ? 'Akan diblokir' : 'Tidak diblokir',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isBlocked
                                    ? const Color(0xFF4A6FA5)
                                    : Colors.grey[600],
                                fontWeight: isBlocked
                                    ? FontWeight.w500
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
                  onChanged: (value) => _toggleAppBlock(app.packageName, value),
                  activeThumbColor: const Color(0xFF4A6FA5),
                  activeTrackColor: const Color(
                    0xFF4A6FA5,
                  ).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfoCard() {
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
          Row(
            children: [
              Icon(Icons.info_outline, size: 16.sp, color: Colors.grey[600]),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Hard block selalu aktif untuk tugas yang masuk window urgensi',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '${_blockedApps.values.where((blocked) => blocked).length} dari ${_installedApps.length} aplikasi diblokir',
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

  Widget _buildInterventionWindowCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hard Block Aktif',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Hard block tidak dapat dimatikan. Atur window intervensi per urgensi di bawah ini.',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              height: 1.35,
            ),
          ),
          SizedBox(height: 12.h),
          _buildPriorityWindowSlider(
            label: 'Low',
            value: _lowWindowHours,
            color: Colors.grey[500]!,
            onChanged: (value) =>
                _updatePriorityWindow(TodoPriority.low, value),
          ),
          SizedBox(height: 8.h),
          _buildPriorityWindowSlider(
            label: 'Medium',
            value: _mediumWindowHours,
            color: Colors.grey[700]!,
            onChanged: (value) =>
                _updatePriorityWindow(TodoPriority.medium, value),
          ),
          SizedBox(height: 8.h),
          _buildPriorityWindowSlider(
            label: 'High',
            value: _highWindowHours,
            color: const Color(0xFF4A6FA5),
            onChanged: (value) =>
                _updatePriorityWindow(TodoPriority.high, value),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityWindowSlider({
    required String label,
    required int value,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '$value jam',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              min: 0,
              max: 48,
              divisions: 24,
              value: value.toDouble(),
              label: '$value jam',
              onChanged: (newValue) => onChanged(newValue.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugPanelCard() {
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
          Row(
            children: [
              Text(
                'Debug Intervensi',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _reloadInstalledApps,
                icon: Icon(
                  Icons.refresh,
                  size: 20.sp,
                  color: const Color(0xFF4A6FA5),
                ),
                tooltip: 'Refresh aplikasi',
              ),
            ],
          ),
          if (_isDebugLoading) ...[
            SizedBox(height: 12.h),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ] else if (_debugInfo == null) ...[
            SizedBox(height: 8.h),
            Text(
              'Belum ada data debug.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ] else ...[
            SizedBox(height: 8.h),
            _buildDebugInfoRow('Status hard block', 'Aktif (wajib)'),
            _buildDebugInfoRow(
              'Package terakhir',
              _debugInfo!.lastBlockedPackage ?? '-',
            ),
            _buildDebugInfoRow(
              'Task terakhir',
              _debugInfo!.lastBlockedTaskTitle ?? '-',
            ),
            _buildDebugInfoRow(
              'Prioritas terakhir',
              _formatPriorityFromString(_debugInfo!.lastBlockedPriority),
            ),
            _buildDebugInfoRow(
              'Sisa waktu terakhir',
              _formatRemainingMinutes(_debugInfo!.lastBlockedRemainingMinutes),
            ),
            _buildDebugInfoRow(
              'Window terakhir',
              _formatWindowHours(_debugInfo!.lastBlockedWindowHours),
            ),
            _buildDebugInfoRow(
              'Waktu blokir',
              _formatDebugTime(_debugInfo!.lastBlockedAt),
            ),
            SizedBox(height: 6.h),
            Divider(height: 1, color: Colors.grey[200]),
            SizedBox(height: 6.h),
            _buildDebugInfoRow(
              'Task kandidat',
              _debugInfo!.nextTaskTitle ?? '-',
            ),
            _buildDebugInfoRow(
              'Prioritas kandidat',
              _formatPriority(_debugInfo!.nextTaskPriority),
            ),
            _buildDebugInfoRow(
              'Sisa waktu kandidat',
              _formatRemainingMinutes(_debugInfo!.nextTaskRemainingMinutes),
            ),
            _buildDebugInfoRow(
              'Window kandidat',
              _formatWindowHours(_debugInfo!.nextTaskWindowHours),
            ),
            _buildDebugInfoRow(
              'Daftar package blokir',
              _formatBlockedPackages(_debugInfo!.blockedPackages),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPriority(TodoPriority? priority) {
    switch (priority) {
      case TodoPriority.low:
        return 'Low';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.high:
        return 'High';
      case null:
        return '-';
    }
  }

  String _formatPriorityFromString(String? priorityValue) {
    return _formatPriority(AppBlockerService.parsePriorityLabel(priorityValue));
  }

  String _formatRemainingMinutes(int? remainingMinutes) {
    if (remainingMinutes == null) {
      return '-';
    }

    final absMinutes = remainingMinutes.abs();
    final hours = absMinutes ~/ Duration.minutesPerHour;
    final minutes = absMinutes % Duration.minutesPerHour;

    final durationLabel = hours > 0 ? '${hours}j ${minutes}m' : '${minutes}m';

    if (remainingMinutes < 0) {
      return '$durationLabel terlambat';
    }

    return '$durationLabel menuju deadline';
  }

  String _formatWindowHours(int? hours) {
    if (hours == null) {
      return '-';
    }

    return '$hours jam';
  }

  String _formatDebugTime(DateTime? time) {
    if (time == null) {
      return '-';
    }

    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$day/$month/${time.year} $hour:$minute';
  }

  String _formatBlockedPackages(List<String> packages) {
    if (packages.isEmpty) {
      return '-';
    }

    final labels = packages.take(3).map(_resolvePackageName).toList();

    final extraCount = packages.length - labels.length;
    if (extraCount > 0) {
      return '${labels.join(', ')} +$extraCount';
    }

    return labels.join(', ');
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

  String _resolvePackageName(String packageName) {
    for (final app in _installedApps) {
      if (app.packageName == packageName) {
        return app.appName;
      }
    }

    return AppBlockerService.getAppDisplayName(packageName);
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
