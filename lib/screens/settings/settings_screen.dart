import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/ui/app_size_tokens.dart';
import '../../repositories/todo_repository.dart';
import '../../services/app_logger.dart';
import '../../services/notification_service.dart';
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
  final NotificationService _notificationService = NotificationService();
  String _userName = 'Pengguna';
  bool _taskNotificationsEnabled = true;
  bool _dailyReminderEnabled = true;
  int _dailyReminderHour = NotificationService.defaultDailyReminderHour;
  int _dailyReminderMinute = NotificationService.defaultDailyReminderMinute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userName = await _todoRepository.getUserName();
      await _notificationService.ensureSettingsMigrated();
      final taskNotificationsEnabled = await _notificationService
          .isTaskNotificationsEnabled();
      final dailyReminderEnabled = await _notificationService
          .isDailyReminderEnabled();
      final dailyReminderHour = await _notificationService
          .getDailyReminderHour();
      final dailyReminderMinute = await _notificationService
          .getDailyReminderMinute();

      if (!mounted) return;

      setState(() {
        _userName = userName ?? 'Pengguna';
        _taskNotificationsEnabled = taskNotificationsEnabled;
        _dailyReminderEnabled = dailyReminderEnabled;
        _dailyReminderHour = dailyReminderHour;
        _dailyReminderMinute = dailyReminderMinute;
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

  Future<void> _updateTaskNotificationSetting(bool value) async {
    try {
      await _notificationService.setTaskNotificationsEnabled(value);

      if (!mounted) return;

      setState(() {
        _taskNotificationsEnabled = value;
      });

      HapticFeedback.lightImpact();

      NotificationPermissionStatus permissionStatus =
          NotificationPermissionStatus.granted;
      TaskNotificationSyncResult syncResult =
          TaskNotificationSyncResult.disabled;
      bool cancelSucceeded = true;
      if (value) {
        permissionStatus = await _notificationService
            .requestNotificationPermission();
        syncResult = await _notificationService.rescheduleTaskNotifications();
      } else {
        cancelSucceeded = await _notificationService
            .cancelAllTaskNotifications();
      }

      AppLogger.info(_tag, 'Task notification setting updated: enabled=$value');

      if (!mounted) return;

      _showSettingsSnackBar(
        value
            ? _taskNotificationEnabledMessage(syncResult, permissionStatus)
            : _taskNotificationDisabledMessage(cancelSucceeded),
        backgroundColor: value
            ? _taskNotificationMessageColor(syncResult, permissionStatus)
            : _taskNotificationDisabledColor(cancelSucceeded),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to update task notification setting.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showSettingsSnackBar(
        'Gagal memperbarui notifikasi tugas',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _updateDailyReminderSetting(bool value) async {
    try {
      await _notificationService.setDailyReminderEnabled(value);

      if (!mounted) return;

      setState(() {
        _dailyReminderEnabled = value;
      });

      HapticFeedback.lightImpact();

      NotificationPermissionStatus permissionStatus =
          NotificationPermissionStatus.granted;
      DailyReminderSyncResult syncResult = DailyReminderSyncResult.disabled;
      if (value) {
        permissionStatus = await _notificationService
            .requestNotificationPermission();
        syncResult = await _notificationService.syncDailyReminderState();
      } else {
        await _notificationService.cancelDailyReminder();
      }

      AppLogger.info(_tag, 'Daily reminder setting updated: enabled=$value');

      if (!mounted) return;

      _showSettingsSnackBar(
        value
            ? _dailyReminderEnabledMessage(syncResult, permissionStatus)
            : 'Reminder harian dinonaktifkan',
        backgroundColor: value
            ? _dailyReminderMessageColor(syncResult, permissionStatus)
            : const Color(0xFF4A6FA5),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to update daily reminder setting.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showSettingsSnackBar(
        'Gagal memperbarui reminder harian',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _pickDailyReminderTime() async {
    if (!_dailyReminderEnabled) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _dailyReminderHour,
        minute: _dailyReminderMinute,
      ),
    );

    if (selectedTime == null) return;

    try {
      await _notificationService.setDailyReminderTime(
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );

      if (!mounted) return;

      setState(() {
        _dailyReminderHour = selectedTime.hour;
        _dailyReminderMinute = selectedTime.minute;
      });

      HapticFeedback.lightImpact();

      final permissionStatus = await _notificationService
          .getNotificationPermissionStatus();
      final syncResult = await _notificationService.syncDailyReminderState();

      AppLogger.info(
        _tag,
        'Daily reminder time updated: '
        'hour=${selectedTime.hour} minute=${selectedTime.minute}',
      );

      if (!mounted) return;

      _showSettingsSnackBar(
        _dailyReminderTimeUpdatedMessage(syncResult, permissionStatus),
        backgroundColor: _dailyReminderMessageColor(
          syncResult,
          permissionStatus,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to update daily reminder time.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showSettingsSnackBar(
        'Gagal memperbarui jam reminder harian',
        backgroundColor: Colors.red,
      );
    }
  }

  void _showSettingsSnackBar(
    String message, {
    Color backgroundColor = const Color(0xFF4A6FA5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDailyReminderTime(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      TimeOfDay(hour: _dailyReminderHour, minute: _dailyReminderMinute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  String _taskNotificationEnabledMessage(
    TaskNotificationSyncResult syncResult,
    NotificationPermissionStatus permissionStatus,
  ) {
    if (permissionStatus == NotificationPermissionStatus.failed) {
      return 'Notifikasi tugas belum berhasil disiapkan';
    }

    if (permissionStatus == NotificationPermissionStatus.denied) {
      return 'Notifikasi tugas aktif, tapi izin notifikasi belum diberikan';
    }

    return switch (syncResult) {
      TaskNotificationSyncResult.scheduled => 'Notifikasi tugas diaktifkan',
      TaskNotificationSyncResult.nothingToSchedule =>
        'Notifikasi tugas aktif saat ada deadline yang masih akan datang',
      TaskNotificationSyncResult.disabled => 'Notifikasi tugas dinonaktifkan',
      TaskNotificationSyncResult.failed =>
        'Notifikasi tugas belum berhasil dijadwalkan',
    };
  }

  Color _taskNotificationMessageColor(
    TaskNotificationSyncResult syncResult,
    NotificationPermissionStatus permissionStatus,
  ) {
    if (permissionStatus == NotificationPermissionStatus.failed ||
        syncResult == TaskNotificationSyncResult.failed) {
      return Colors.red;
    }

    if (permissionStatus == NotificationPermissionStatus.denied) {
      return const Color(0xFFE58F1E);
    }

    return const Color(0xFF4A6FA5);
  }

  String _taskNotificationDisabledMessage(bool cancelSucceeded) {
    return cancelSucceeded
        ? 'Notifikasi tugas dinonaktifkan'
        : 'Pengaturan disimpan, tapi pembatalan notifikasi tugas gagal';
  }

  Color _taskNotificationDisabledColor(bool cancelSucceeded) {
    return cancelSucceeded ? const Color(0xFF4A6FA5) : Colors.red;
  }

  String _dailyReminderEnabledMessage(
    DailyReminderSyncResult result,
    NotificationPermissionStatus permissionStatus,
  ) {
    if (permissionStatus == NotificationPermissionStatus.failed) {
      return 'Reminder harian belum berhasil disiapkan';
    }

    if (permissionStatus == NotificationPermissionStatus.denied) {
      return 'Reminder harian aktif, tapi izin notifikasi belum diberikan';
    }

    return switch (result) {
      DailyReminderSyncResult.scheduled => 'Reminder harian diaktifkan',
      DailyReminderSyncResult.noPendingTasks =>
        'Reminder harian aktif saat ada tugas yang belum selesai',
      DailyReminderSyncResult.disabled => 'Reminder harian dinonaktifkan',
      DailyReminderSyncResult.failed =>
        'Reminder harian belum berhasil dijadwalkan',
    };
  }

  String _dailyReminderTimeUpdatedMessage(
    DailyReminderSyncResult result,
    NotificationPermissionStatus permissionStatus,
  ) {
    if (permissionStatus == NotificationPermissionStatus.failed) {
      return 'Jam disimpan, tapi reminder harian belum berhasil disiapkan';
    }

    if (permissionStatus == NotificationPermissionStatus.denied) {
      return 'Jam disimpan, tapi izin notifikasi belum diberikan';
    }

    return switch (result) {
      DailyReminderSyncResult.scheduled => 'Jam reminder harian diperbarui',
      DailyReminderSyncResult.noPendingTasks =>
        'Jam disimpan. Reminder aktif saat ada tugas yang belum selesai',
      DailyReminderSyncResult.disabled =>
        'Aktifkan reminder harian untuk menjadwalkan notifikasi',
      DailyReminderSyncResult.failed =>
        'Jam disimpan, tapi reminder harian belum berhasil dijadwalkan',
    };
  }

  Color _dailyReminderMessageColor(
    DailyReminderSyncResult result,
    NotificationPermissionStatus permissionStatus,
  ) {
    if (permissionStatus == NotificationPermissionStatus.failed) {
      return Colors.red;
    }

    if (permissionStatus == NotificationPermissionStatus.denied) {
      return const Color(0xFFE58F1E);
    }

    return switch (result) {
      DailyReminderSyncResult.failed => Colors.red,
      DailyReminderSyncResult.scheduled ||
      DailyReminderSyncResult.noPendingTasks ||
      DailyReminderSyncResult.disabled => const Color(0xFF4A6FA5),
    };
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
                  if (!kReleaseMode) ...[
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
                  ],
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi Tugas',
                    subtitle: 'Pengingat deadline berdasarkan prioritas tugas',
                    trailing: Switch.adaptive(
                      value: _taskNotificationsEnabled,
                      onChanged: _updateTaskNotificationSetting,
                      activeThumbColor: const Color(0xFF4A6FA5),
                      activeTrackColor: const Color(
                        0xFF4A6FA5,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.today_outlined,
                    title: 'Reminder Harian',
                    subtitle: 'Ringkasan tugas aktif setiap hari',
                    trailing: Switch.adaptive(
                      value: _dailyReminderEnabled,
                      onChanged: _updateDailyReminderSetting,
                      activeThumbColor: const Color(0xFF4A6FA5),
                      activeTrackColor: const Color(
                        0xFF4A6FA5,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.schedule_outlined,
                    title: 'Jam Reminder Harian',
                    subtitle: _dailyReminderEnabled
                        ? 'Setiap hari pukul ${_formatDailyReminderTime(context)}'
                        : 'Aktifkan reminder harian untuk mengubah jam',
                    trailing: _buildDailyReminderTimeTrailing(context),
                    onTap: _dailyReminderEnabled
                        ? _pickDailyReminderTime
                        : null,
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

  Widget _buildDailyReminderTimeTrailing(BuildContext context) {
    final textColor = _dailyReminderEnabled ? Colors.black87 : Colors.grey[500];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatDailyReminderTime(context),
          style: TextStyle(
            fontSize: AppSizeTokens.text13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (_dailyReminderEnabled) SizedBox(width: AppSizeTokens.space8),
        if (_dailyReminderEnabled)
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: AppSizeTokens.icon20,
          ),
      ],
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
