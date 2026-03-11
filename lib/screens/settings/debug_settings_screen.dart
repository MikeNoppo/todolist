import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/todo_model.dart';
import '../../services/app_blocker_service.dart';
import '../../services/app_logger.dart';
import '../../services/notification_service.dart';

class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> {
  static const String _tag = 'DebugSettingsScreen';

  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  bool _isTriggeringTaskNotification = false;
  bool _isTriggeringDailyReminder = false;
  InterventionDebugInfo? _debugInfo;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final debugInfo = await AppBlockerService.getInterventionDebugInfo();

      if (!mounted) return;
      setState(() {
        _debugInfo = debugInfo;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to load intervention debug info.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerTaskNotification(bool value) async {
    if (!value || _isTriggeringTaskNotification) return;

    setState(() {
      _isTriggeringTaskNotification = true;
    });
    HapticFeedback.lightImpact();

    try {
      var permissionStatus = await _notificationService
          .requestNotificationPermission();
      if (permissionStatus == NotificationPermissionStatus.granted) {
        permissionStatus = await _notificationService
            .showDebugTaskNotificationNow();
      }

      if (!mounted) return;
      _showNotificationSnackBar(
        permissionStatus == NotificationPermissionStatus.granted
            ? 'Preview notifikasi tugas dikirim'
            : permissionStatus == NotificationPermissionStatus.denied
            ? 'Izin notifikasi belum diberikan'
            : 'Gagal menampilkan preview notifikasi tugas',
        backgroundColor: _notificationStatusColor(permissionStatus),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to trigger debug task notification.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      _showNotificationSnackBar(
        'Gagal menampilkan preview notifikasi tugas',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTriggeringTaskNotification = false;
        });
      }
    }
  }

  Future<void> _triggerDailyReminder(bool value) async {
    if (!value || _isTriggeringDailyReminder) return;

    setState(() {
      _isTriggeringDailyReminder = true;
    });
    HapticFeedback.lightImpact();

    try {
      var permissionStatus = await _notificationService
          .requestNotificationPermission();
      if (permissionStatus == NotificationPermissionStatus.granted) {
        permissionStatus = await _notificationService
            .showDebugDailyReminderNow();
      }

      if (!mounted) return;
      _showNotificationSnackBar(
        permissionStatus == NotificationPermissionStatus.granted
            ? 'Preview reminder harian dikirim'
            : permissionStatus == NotificationPermissionStatus.denied
            ? 'Izin notifikasi belum diberikan'
            : 'Gagal menampilkan preview reminder harian',
        backgroundColor: _notificationStatusColor(permissionStatus),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to trigger debug daily reminder.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      _showNotificationSnackBar(
        'Gagal menampilkan preview reminder harian',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTriggeringDailyReminder = false;
        });
      }
    }
  }

  void _showNotificationSnackBar(
    String message, {
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _notificationStatusColor(NotificationPermissionStatus status) {
    return switch (status) {
      NotificationPermissionStatus.granted => const Color(0xFF4A6FA5),
      NotificationPermissionStatus.denied => const Color(0xFFE58F1E),
      NotificationPermissionStatus.failed => Colors.red,
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
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadDebugInfo();
            },
            icon: Icon(Icons.refresh, color: Colors.grey[700]),
            tooltip: 'Refresh debug',
          ),
        ],
        title: Text(
          'Debug',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
            )
          : _debugInfo == null
          ? Center(
              child: Text(
                'Data debug tidak tersedia',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            )
          : ListView(
              padding: EdgeInsets.all(20.r),
              children: [
                if (!kReleaseMode) ...[
                  _buildNotificationTestCard(),
                  SizedBox(height: 12.h),
                ],
                _buildDebugCard(
                  title: 'Intervensi Terakhir',
                  rows: [
                    _debugRow('Status hard block', 'Aktif (wajib)'),
                    _debugRow(
                      'Package terakhir',
                      _debugInfo!.lastBlockedPackage ?? '-',
                    ),
                    _debugRow(
                      'Task terakhir',
                      _debugInfo!.lastBlockedTaskTitle ?? '-',
                    ),
                    _debugRow(
                      'Prioritas terakhir',
                      _formatPriorityFromString(
                        _debugInfo!.lastBlockedPriority,
                      ),
                    ),
                    _debugRow(
                      'Sisa waktu terakhir',
                      _formatRemainingMinutes(
                        _debugInfo!.lastBlockedRemainingMinutes,
                      ),
                    ),
                    _debugRow(
                      'Window terakhir',
                      _formatWindowHours(_debugInfo!.lastBlockedWindowHours),
                    ),
                    _debugRow(
                      'Waktu blokir',
                      _formatDebugTime(_debugInfo!.lastBlockedAt),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildDebugCard(
                  title: 'Kandidat Saat Ini',
                  rows: [
                    _debugRow(
                      'Task kandidat',
                      _debugInfo!.nextTaskTitle ?? '-',
                    ),
                    _debugRow(
                      'Prioritas kandidat',
                      _formatPriority(_debugInfo!.nextTaskPriority),
                    ),
                    _debugRow(
                      'Sisa waktu kandidat',
                      _formatRemainingMinutes(
                        _debugInfo!.nextTaskRemainingMinutes,
                      ),
                    ),
                    _debugRow(
                      'Window kandidat',
                      _formatWindowHours(_debugInfo!.nextTaskWindowHours),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildDebugCard(
                  title: 'Daftar Aturan App',
                  rows: [
                    _debugRow(
                      'Daftar blokir',
                      _formatPackageList(_debugInfo!.blockedPackages),
                    ),
                    _debugRow(
                      'Whitelist always allow',
                      _formatPackageList(_debugInfo!.alwaysAllowedPackages),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildDebugCard({
    required String title,
    required List<(String, String)> rows,
  }) {
    return Container(
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
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10.h),
          ...rows.map((row) => _buildDebugInfoRow(row.$1, row.$2)),
        ],
      ),
    );
  }

  Widget _buildNotificationTestCard() {
    return Container(
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
            'Tes Notifikasi',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Hanya tampil di build debug/dev untuk preview cepat.',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          _buildNotificationTriggerRow(
            title: 'Trigger Notifikasi Tugas',
            subtitle: 'Kirim preview notifikasi deadline secara langsung',
            value: _isTriggeringTaskNotification,
            onChanged: _triggerTaskNotification,
          ),
          Divider(height: 20.h, color: Colors.grey[100]),
          _buildNotificationTriggerRow(
            title: 'Trigger Reminder Harian',
            subtitle: 'Kirim preview ringkasan harian secara langsung',
            value: _isTriggeringDailyReminder,
            onChanged: _triggerDailyReminder,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTriggerRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Switch.adaptive(
          value: value,
          onChanged: value ? null : onChanged,
          activeThumbColor: const Color(0xFF4A6FA5),
          activeTrackColor: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
        ),
      ],
    );
  }

  (String, String) _debugRow(String label, String value) => (label, value);

  Widget _buildDebugInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128.w,
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

  String _formatPackageList(List<String> packages) {
    if (packages.isEmpty) {
      return '-';
    }

    final labels = packages
        .take(4)
        .map(AppBlockerService.getAppDisplayName)
        .toList();
    final extra = packages.length - labels.length;
    if (extra > 0) {
      return '${labels.join(', ')} +$extra';
    }

    return labels.join(', ');
  }
}
