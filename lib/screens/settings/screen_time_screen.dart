import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/app_usage_stat.dart';
import '../../models/installed_focus_app.dart';
import '../../models/todo_model.dart';
import '../../core/ui/app_size_tokens.dart';
import '../../services/app_blocker_service.dart';
import '../../services/app_logger.dart';
import '../../services/permission_service.dart';
import '../../services/usage_stats_service.dart';

enum _ScreenTimeView { today, history }

enum _UsageRiskLevel { light, moderate, heavy, abusive }

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen>
    with WidgetsBindingObserver {
  static const String _tag = 'ScreenTimeScreen';

  final UsageStatsService _usageStatsService = const UsageStatsService();
  StreamSubscription<Map<String, int>>? _sessionSubscription;

  List<InstalledFocusApp> _trackedApps = [];
  List<AppUsageStat> _todayStats = [];
  Map<String, List<AppUsageStat>> _usageHistory = {};
  Map<String, int> _currentSessions = {};
  Set<String> _blockedPackages = {};
  InterventionDebugInfo? _debugInfo;
  _ScreenTimeView _selectedView = _ScreenTimeView.today;
  bool _isLoading = true;
  bool _usagePermissionGranted = false;

  static const int _minActiveDayMs = 5 * Duration.millisecondsPerMinute;

  static const Map<TodoPriority, int> _baseHardBlockMinutes = {
    TodoPriority.high: 60,
    TodoPriority.medium: 90,
    TodoPriority.low: 120,
  };

  static const Map<TodoPriority, int> _minimumHardBlockMinutes = {
    TodoPriority.high: 15,
    TodoPriority.medium: 25,
    TodoPriority.low: 40,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadData(showLoading: false);
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final usagePermissionGranted =
          await PermissionService.isUsageStatsPermissionGranted();

      if (!usagePermissionGranted) {
        await _sessionSubscription?.cancel();
        if (!mounted) return;
        setState(() {
          _usagePermissionGranted = false;
          _trackedApps = [];
          _todayStats = [];
          _usageHistory = {};
          _currentSessions = {};
          _blockedPackages = {};
          _debugInfo = null;
          _isLoading = false;
        });
        return;
      }

      final installedApps = await PermissionService.getInstalledFocusApps();
      final trackedApps = await _resolveTrackedApps(installedApps);
      final packageNames = trackedApps.map((app) => app.packageName).toList();
      final todayStats = await _usageStatsService.getTodayUsageForApps(
        packageNames,
      );
      final usageHistory = await _usageStatsService.getUsageHistory(
        packageNames: packageNames,
      );
      final debugInfo = await AppBlockerService.getInterventionDebugInfo();
      final blockedPackages = debugInfo.blockedPackages
          .where(packageNames.contains)
          .toSet();

      if (!mounted) return;

      setState(() {
        _usagePermissionGranted = true;
        _trackedApps = trackedApps;
        _todayStats = todayStats;
        _usageHistory = usageHistory;
        _blockedPackages = blockedPackages;
        _debugInfo = debugInfo;
        _isLoading = false;
      });

      _watchCurrentSessions(packageNames);
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to load screen time data.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<InstalledFocusApp>> _resolveTrackedApps(
    List<InstalledFocusApp> installedApps,
  ) async {
    return installedApps;
  }

  void _watchCurrentSessions(List<String> packageNames) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _usageStatsService
        .watchCurrentSessions(packageNames)
        .listen(
          (sessions) {
            if (!mounted) return;
            setState(() {
              _currentSessions = sessions;
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.error(
              _tag,
              'Failed to receive current session update.',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  Future<void> _openUsageSettings() async {
    await PermissionService.openUsageStatsSettings();
  }

  int _hardBlockMsForPriority(
    TodoPriority priority,
    _UsageRiskLevel riskLevel,
  ) {
    final baseMs =
        (_baseHardBlockMinutes[priority] ??
            _baseHardBlockMinutes[TodoPriority.medium]!) *
        Duration.millisecondsPerMinute;
    final minimumMs =
        (_minimumHardBlockMinutes[priority] ??
            _minimumHardBlockMinutes[TodoPriority.medium]!) *
        Duration.millisecondsPerMinute;
    return max(minimumMs, (baseMs * _thresholdScaleForRisk(riskLevel)).round());
  }

  _UsageHistoryProfile _usageHistoryProfileForPackage(String packageName) {
    final dateKeys = _usageHistory.keys.toList()..sort();
    if (dateKeys.length <= 1) {
      return const _UsageHistoryProfile(
        averageDailyUsageMs: 0,
        activeDays: 0,
        maxDailyUsageMs: 0,
        riskLevel: _UsageRiskLevel.light,
      );
    }

    final dailyUsageMs = <int>[];
    for (final dateKey in dateKeys.take(dateKeys.length - 1)) {
      final stats = _usageHistory[dateKey] ?? const <AppUsageStat>[];
      var usageMs = 0;
      for (final stat in stats) {
        if (stat.packageName == packageName) {
          usageMs = stat.totalTimeMs;
          break;
        }
      }
      dailyUsageMs.add(usageMs);
    }

    final totalUsageMs = dailyUsageMs.fold<int>(0, (total, ms) => total + ms);
    final averageDailyUsageMs = totalUsageMs ~/ dailyUsageMs.length;
    final activeDays = dailyUsageMs.where((usageMs) {
      return usageMs >= _minActiveDayMs;
    }).length;
    final maxDailyUsageMs = dailyUsageMs.fold<int>(0, max);

    return _UsageHistoryProfile(
      averageDailyUsageMs: averageDailyUsageMs,
      activeDays: activeDays,
      maxDailyUsageMs: maxDailyUsageMs,
      riskLevel: _classifyUsageRisk(
        averageDailyUsageMs: averageDailyUsageMs,
        activeDays: activeDays,
        maxDailyUsageMs: maxDailyUsageMs,
      ),
    );
  }

  _UsageRiskLevel _classifyUsageRisk({
    required int averageDailyUsageMs,
    required int activeDays,
    required int maxDailyUsageMs,
  }) {
    const minuteMs = Duration.millisecondsPerMinute;
    if (averageDailyUsageMs >= 120 * minuteMs ||
        maxDailyUsageMs >= 240 * minuteMs ||
        activeDays >= 5 && averageDailyUsageMs >= 90 * minuteMs) {
      return _UsageRiskLevel.abusive;
    }

    if (averageDailyUsageMs >= 75 * minuteMs ||
        maxDailyUsageMs >= 150 * minuteMs ||
        activeDays >= 5 && averageDailyUsageMs >= 45 * minuteMs) {
      return _UsageRiskLevel.heavy;
    }

    if (averageDailyUsageMs >= 30 * minuteMs ||
        maxDailyUsageMs >= 60 * minuteMs ||
        activeDays >= 4 && averageDailyUsageMs >= 15 * minuteMs) {
      return _UsageRiskLevel.moderate;
    }

    return _UsageRiskLevel.light;
  }

  double _thresholdScaleForRisk(_UsageRiskLevel riskLevel) {
    switch (riskLevel) {
      case _UsageRiskLevel.light:
        return 1.0;
      case _UsageRiskLevel.moderate:
        return 0.8;
      case _UsageRiskLevel.heavy:
        return 0.6;
      case _UsageRiskLevel.abusive:
        return 0.4;
    }
  }

  double _dailyHardMultiplierForRisk(_UsageRiskLevel riskLevel) {
    switch (riskLevel) {
      case _UsageRiskLevel.light:
        return 1.0;
      case _UsageRiskLevel.moderate:
        return 0.85;
      case _UsageRiskLevel.heavy:
        return 0.65;
      case _UsageRiskLevel.abusive:
        return 0.45;
    }
  }

  _UsageLimitInfo? _usageLimitInfoForRow(_AppUsageRow row) {
    if (!_blockedPackages.contains(row.app.packageName)) {
      return null;
    }

    final priority = _debugInfo?.nextTaskPriority;
    if (priority == null) {
      return null;
    }

    final usageProfile = _usageHistoryProfileForPackage(row.app.packageName);
    final sessionLimitMs = _hardBlockMsForPriority(
      priority,
      usageProfile.riskLevel,
    );
    final dailyLimitMs = max(
      sessionLimitMs,
      (usageProfile.averageDailyUsageMs *
              _dailyHardMultiplierForRisk(usageProfile.riskLevel))
          .round(),
    );

    return _UsageLimitInfo(
      priority: priority,
      riskLevel: usageProfile.riskLevel,
      averageDailyUsageMs: usageProfile.averageDailyUsageMs,
      activeDays: usageProfile.activeDays,
      maxDailyUsageMs: usageProfile.maxDailyUsageMs,
      dailyLimitMs: dailyLimitMs,
      sessionLimitMs: sessionLimitMs,
      remainingDailyMs: max(0, dailyLimitMs - row.usageMs),
      remainingSessionMs: max(0, sessionLimitMs - row.currentSessionMs),
    );
  }

  String _priorityLabel(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return 'Rendah';
      case TodoPriority.medium:
        return 'Sedang';
      case TodoPriority.high:
        return 'Tinggi';
    }
  }

  String _riskLabel(_UsageRiskLevel riskLevel) {
    switch (riskLevel) {
      case _UsageRiskLevel.light:
        return 'Ringan';
      case _UsageRiskLevel.moderate:
        return 'Sedang';
      case _UsageRiskLevel.heavy:
        return 'Berat';
      case _UsageRiskLevel.abusive:
        return 'Abusive';
    }
  }

  Color _riskColor(_UsageRiskLevel riskLevel) {
    switch (riskLevel) {
      case _UsageRiskLevel.light:
        return const Color(0xFF2E8B57);
      case _UsageRiskLevel.moderate:
        return const Color(0xFF4A6FA5);
      case _UsageRiskLevel.heavy:
        return Colors.orange[700]!;
      case _UsageRiskLevel.abusive:
        return const Color(0xFFE53935);
    }
  }

  String _formatDeadlineLabel(int remainingMinutes) {
    if (remainingMinutes <= 0) {
      return 'Deadline sudah lewat';
    }

    if (remainingMinutes < Duration.minutesPerHour) {
      return 'Deadline dalam $remainingMinutes menit';
    }

    final hours = remainingMinutes ~/ Duration.minutesPerHour;
    final minutes = remainingMinutes.remainder(Duration.minutesPerHour);
    if (minutes == 0) {
      return 'Deadline dalam ${hours}j';
    }

    return 'Deadline dalam ${hours}j ${minutes}m';
  }

  Color _remainingColor(_UsageLimitInfo info) {
    final warningThresholdMs = info.dailyLimitMs ~/ 4;
    return info.remainingDailyMs <= warningThresholdMs
        ? const Color(0xFFE53935)
        : Colors.orange[700]!;
  }

  void _showAppDetailSheet(BuildContext context, _AppUsageRow row) {
    final limitInfo = _usageLimitInfoForRow(row);
    final remainingColor = limitInfo == null
        ? Colors.grey[600]!
        : _remainingColor(limitInfo);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizeTokens.radius16),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSizeTokens.pagePadding,
                AppSizeTokens.space16,
                AppSizeTokens.pagePadding,
                AppSizeTokens.space24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSizeTokens.space16),
                  Row(
                    children: [
                      _buildAppIcon(
                        row.app,
                        _getCategoryAccentColor(row.app.category),
                      ),
                      SizedBox(width: AppSizeTokens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.app.appName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppSizeTokens.text18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: AppSizeTokens.space6),
                            _buildBlockedChip(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizeTokens.space20),
                  _buildDetailStat(
                    icon: Icons.bar_chart_outlined,
                    label: 'Penggunaan hari ini',
                    value: AppUsageStat.formatDuration(
                      Duration(milliseconds: row.usageMs),
                    ),
                    color: const Color(0xFF4A6FA5),
                  ),
                  SizedBox(height: AppSizeTokens.space12),
                  if (limitInfo != null) ...[
                    _buildDetailStat(
                      icon: Icons.speed_outlined,
                      label: 'Batas total harian adaptif',
                      value: AppUsageStat.formatDuration(
                        Duration(milliseconds: limitInfo.dailyLimitMs),
                      ),
                      color: const Color(0xFFE53935),
                    ),
                    SizedBox(height: AppSizeTokens.space12),
                    _buildDetailStat(
                      icon: Icons.history_outlined,
                      label: 'Pola 7 hari',
                      value: _riskLabel(limitInfo.riskLevel),
                      color: _riskColor(limitInfo.riskLevel),
                    ),
                    SizedBox(height: AppSizeTokens.space12),
                    _buildDetailStat(
                      icon: Icons.query_stats_outlined,
                      label: 'Rata-rata harian',
                      value: AppUsageStat.formatDuration(
                        Duration(milliseconds: limitInfo.averageDailyUsageMs),
                      ),
                      color: Colors.grey[700]!,
                    ),
                    SizedBox(height: AppSizeTokens.space12),
                    _buildDetailStat(
                      icon: Icons.event_available_outlined,
                      label: 'Hari aktif historis',
                      value: '${limitInfo.activeDays}/6 hari',
                      color: Colors.grey[700]!,
                    ),
                    SizedBox(height: AppSizeTokens.space12),
                    _buildDetailStat(
                      icon: Icons.trending_up_outlined,
                      label: 'Hari terberat',
                      value: AppUsageStat.formatDuration(
                        Duration(milliseconds: limitInfo.maxDailyUsageMs),
                      ),
                      color: Colors.grey[700]!,
                    ),
                    SizedBox(height: AppSizeTokens.space12),
                    _buildDetailStat(
                      icon: Icons.hourglass_bottom_outlined,
                      label: 'Sisa jatah hari ini',
                      value: AppUsageStat.formatDuration(
                        Duration(milliseconds: limitInfo.remainingDailyMs),
                      ),
                      color: remainingColor,
                    ),
                    SizedBox(height: AppSizeTokens.space12),
                  ],
                  _buildDetailStat(
                    icon: Icons.timer_outlined,
                    label: 'Sesi saat ini',
                    value: row.currentSessionMs > 0
                        ? AppUsageStat.formatDuration(
                            Duration(milliseconds: row.currentSessionMs),
                          )
                        : 'Tidak aktif',
                    color: row.currentSessionMs > 0
                        ? const Color(0xFF2E8B57)
                        : Colors.grey[600]!,
                  ),
                  if (limitInfo != null) ...[
                    SizedBox(height: AppSizeTokens.space12),
                    _buildDetailStat(
                      icon: Icons.block_outlined,
                      label: 'Batas sesi adaptif',
                      value: AppUsageStat.formatDuration(
                        Duration(milliseconds: limitInfo.sessionLimitMs),
                      ),
                      color: const Color(0xFFE53935),
                    ),
                    SizedBox(height: AppSizeTokens.space12),
                    _buildDetailStat(
                      icon: Icons.timelapse_outlined,
                      label: 'Sisa sesi sebelum diblokir',
                      value: AppUsageStat.formatDuration(
                        Duration(milliseconds: limitInfo.remainingSessionMs),
                      ),
                      color: remainingColor,
                    ),
                    SizedBox(height: AppSizeTokens.space16),
                    Divider(color: Colors.grey[200]),
                    SizedBox(height: AppSizeTokens.space12),
                    _buildTriggerTaskCard(limitInfo),
                  ] else ...[
                    SizedBox(height: AppSizeTokens.space16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSizeTokens.space12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(
                          AppSizeTokens.radius12,
                        ),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        'Belum ada tugas mendesak aktif. Hard block tidak akan terpicu sekarang.',
                        style: TextStyle(
                          fontSize: AppSizeTokens.text13,
                          color: Colors.grey[600],
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSizeTokens.radius8),
          ),
          child: Icon(icon, size: AppSizeTokens.icon18, color: color),
        ),
        SizedBox(width: AppSizeTokens.space12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppSizeTokens.text13,
              color: Colors.grey[600],
            ),
          ),
        ),
        SizedBox(width: AppSizeTokens.space8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: AppSizeTokens.text14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerTaskCard(_UsageLimitInfo limitInfo) {
    final remainingMinutes = _debugInfo?.nextTaskRemainingMinutes;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizeTokens.space12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppSizeTokens.radius12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.task_alt_outlined,
                size: AppSizeTokens.icon16,
                color: Colors.grey[600],
              ),
              SizedBox(width: AppSizeTokens.space8),
              Text(
                'Tugas pemicu',
                style: TextStyle(
                  fontSize: AppSizeTokens.text13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizeTokens.space8),
          Text(
            _debugInfo?.nextTaskTitle ?? 'Tugas mendesak',
            style: TextStyle(
              fontSize: AppSizeTokens.text14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppSizeTokens.space4),
          Text(
            [
              'Prioritas ${_priorityLabel(limitInfo.priority)}',
              if (remainingMinutes != null)
                _formatDeadlineLabel(remainingMinutes),
            ].join(' • '),
            style: TextStyle(
              fontSize: AppSizeTokens.text12,
              color: remainingMinutes != null && remainingMinutes <= 60
                  ? const Color(0xFFE53935)
                  : Colors.grey[600],
              height: 1.35,
            ),
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            onPressed: () => _loadData(showLoading: false),
            icon: Icon(Icons.refresh, color: Colors.grey[700]),
            tooltip: 'Refresh data',
          ),
        ],
        title: Text(
          'Penggunaan Aplikasi',
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
          : RefreshIndicator(
              color: const Color(0xFF4A6FA5),
              onRefresh: () => _loadData(showLoading: false),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSizeTokens.pagePadding,
                  AppSizeTokens.space20,
                  AppSizeTokens.pagePadding,
                  AppSizeTokens.space24,
                ),
                children: [
                  if (!_usagePermissionGranted)
                    _buildPermissionCard()
                  else if (_trackedApps.isEmpty)
                    _buildEmptyCard()
                  else ...[
                    _buildSummaryCard(),
                    SizedBox(height: AppSizeTokens.space16),
                    _buildViewSwitch(),
                    SizedBox(height: AppSizeTokens.space16),
                    if (_selectedView == _ScreenTimeView.today)
                      _buildTodayView()
                    else
                      _buildHistoryView(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final todayTotalMs = _todayStats.fold<int>(
      0,
      (total, stat) => total + stat.totalTimeMs,
    );
    final activeTotalMs = _currentSessions.values.fold<int>(
      0,
      (total, sessionMs) => total + sessionMs,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizeTokens.cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6FA5).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
        border: Border.all(
          color: const Color(0xFF4A6FA5).withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6FA5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizeTokens.radius12),
                ),
                child: Icon(
                  Icons.insights_outlined,
                  color: const Color(0xFF4A6FA5),
                  size: AppSizeTokens.icon22,
                ),
              ),
              SizedBox(width: AppSizeTokens.space12),
              Expanded(
                child: Text(
                  'Total distraksi hari ini',
                  style: TextStyle(
                    fontSize: AppSizeTokens.text14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizeTokens.space16),
          Text(
            AppUsageStat.formatDuration(Duration(milliseconds: todayTotalMs)),
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppSizeTokens.space12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Dipantau',
                  value: '${_trackedApps.length} app',
                ),
              ),
              SizedBox(width: AppSizeTokens.space12),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Sesi aktif',
                  value: AppUsageStat.formatDuration(
                    Duration(milliseconds: activeTotalMs),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({required String label, required String value}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizeTokens.space12,
        vertical: AppSizeTokens.space10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppSizeTokens.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppSizeTokens.text12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppSizeTokens.space4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppSizeTokens.text15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitch() {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizeTokens.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildViewSwitchButton(
            label: 'Hari ini',
            icon: Icons.today_outlined,
            view: _ScreenTimeView.today,
          ),
          _buildViewSwitchButton(
            label: '7 hari',
            icon: Icons.bar_chart_outlined,
            view: _ScreenTimeView.history,
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitchButton({
    required String label,
    required IconData icon,
    required _ScreenTimeView view,
  }) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedView = view;
          });
        },
        borderRadius: BorderRadius.circular(AppSizeTokens.radius8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: AppSizeTokens.space10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A6FA5) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizeTokens.radius8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppSizeTokens.icon18,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              SizedBox(width: AppSizeTokens.space8),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizeTokens.text14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayView() {
    final rows = _buildTodayRows();
    final maxUsageMs = rows.fold<int>(
      0,
      (value, row) => max(value, row.usageMs),
    );

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSizeTokens.space10),
          child: _buildAppUsageTile(row: row, maxUsageMs: maxUsageMs),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDailyHistoryList(),
        SizedBox(height: AppSizeTokens.space16),
        _buildSevenDayAppList(),
      ],
    );
  }

  Widget _buildDailyHistoryList() {
    final dateKeys = _usageHistory.keys.toList()..sort();
    final totalsByDate = {
      for (final dateKey in dateKeys)
        dateKey:
            _usageHistory[dateKey]?.fold<int>(
              0,
              (total, stat) => total + stat.totalTimeMs,
            ) ??
            0,
    };
    final maxDailyMs = totalsByDate.values.fold<int>(0, max);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizeTokens.itemPadding),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat harian',
            style: TextStyle(
              fontSize: AppSizeTokens.text16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppSizeTokens.space12),
          ...dateKeys.map((dateKey) {
            final usageMs = totalsByDate[dateKey] ?? 0;
            return Padding(
              padding: EdgeInsets.only(bottom: AppSizeTokens.space10),
              child: _buildDailyBar(
                dateKey: dateKey,
                usageMs: usageMs,
                maxUsageMs: maxDailyMs,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDailyBar({
    required String dateKey,
    required int usageMs,
    required int maxUsageMs,
  }) {
    final progress = maxUsageMs == 0 ? 0.0 : usageMs / maxUsageMs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _formatDateLabel(dateKey),
                style: TextStyle(
                  fontSize: AppSizeTokens.text13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              AppUsageStat.formatDuration(Duration(milliseconds: usageMs)),
              style: TextStyle(
                fontSize: AppSizeTokens.text12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizeTokens.space6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizeTokens.radius8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8.h,
            backgroundColor: Colors.grey[100],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A6FA5)),
          ),
        ),
      ],
    );
  }

  Widget _buildSevenDayAppList() {
    final totals = <String, int>{};
    for (final stats in _usageHistory.values) {
      for (final stat in stats) {
        totals[stat.packageName] =
            (totals[stat.packageName] ?? 0) + stat.totalTimeMs;
      }
    }

    final rows = _trackedApps.map((app) {
      return _AppUsageRow(
        app: app,
        usageMs: totals[app.packageName] ?? 0,
        currentSessionMs: _currentSessions[app.packageName] ?? 0,
      );
    }).toList()..sort((left, right) => right.usageMs.compareTo(left.usageMs));

    final maxUsageMs = rows.fold<int>(
      0,
      (value, row) => max(value, row.usageMs),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSizeTokens.space10),
          child: _buildAppUsageTile(row: row, maxUsageMs: maxUsageMs),
        );
      }).toList(),
    );
  }

  Widget _buildAppUsageTile({
    required _AppUsageRow row,
    required int maxUsageMs,
  }) {
    final accentColor = _getCategoryAccentColor(row.app.category);
    final progress = maxUsageMs == 0 ? 0.0 : row.usageMs / maxUsageMs;
    final isActive = row.currentSessionMs > 0;
    final isBlocked = _blockedPackages.contains(row.app.packageName);
    final showDailyAllowance = _selectedView == _ScreenTimeView.today;
    final limitInfo = showDailyAllowance ? _usageLimitInfoForRow(row) : null;
    final remainingColor = limitInfo == null
        ? Colors.grey[600]!
        : _remainingColor(limitInfo);

    final tile = Container(
      padding: EdgeInsets.all(AppSizeTokens.itemPadding),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _buildAppIcon(row.app, accentColor),
          SizedBox(width: AppSizeTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              row.app.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppSizeTokens.text15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (isBlocked) ...[
                            SizedBox(width: AppSizeTokens.space6),
                            _buildBlockedChip(),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      AppUsageStat.formatDuration(
                        Duration(milliseconds: row.usageMs),
                      ),
                      style: TextStyle(
                        fontSize: AppSizeTokens.text13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A6FA5),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizeTokens.space6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizeTokens.radius8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 7.h,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                if (limitInfo != null) ...[
                  SizedBox(height: AppSizeTokens.space6),
                  Row(
                    children: [
                      Icon(
                        Icons.hourglass_bottom_outlined,
                        size: 14.sp,
                        color: remainingColor,
                      ),
                      SizedBox(width: AppSizeTokens.space6),
                      Expanded(
                        child: Text(
                          'Sisa jatah ${AppUsageStat.formatDuration(Duration(milliseconds: limitInfo.remainingDailyMs))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppSizeTokens.text12,
                            color: remainingColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (isActive) ...[
                  SizedBox(height: AppSizeTokens.space6),
                  Row(
                    children: [
                      Container(
                        width: 7.w,
                        height: 7.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E8B57),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: AppSizeTokens.space6),
                      Expanded(
                        child: Text(
                          'Sedang aktif ${AppUsageStat.formatDuration(Duration(milliseconds: row.currentSessionMs))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppSizeTokens.text12,
                            color: const Color(0xFF2E8B57),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!isBlocked || !showDailyAllowance) {
      return tile;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAppDetailSheet(context, row),
        borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
        child: tile,
      ),
    );
  }

  Widget _buildBlockedChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: const Color(0xFFE53935).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_outlined,
            size: 10.sp,
            color: const Color(0xFFE53935),
          ),
          SizedBox(width: 3.w),
          Text(
            'Diblokir',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizeTokens.cardPadding),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: AppSizeTokens.icon28,
            color: const Color(0xFF4A6FA5),
          ),
          SizedBox(height: AppSizeTokens.space12),
          Text(
            'Izin Usage Access dibutuhkan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizeTokens.text16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppSizeTokens.space8),
          Text(
            'Aktifkan izin penggunaan aplikasi agar screen time dapat dibaca dari Android.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizeTokens.text13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          SizedBox(height: AppSizeTokens.space16),
          FilledButton.icon(
            onPressed: _openUsageSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Buka Pengaturan'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4A6FA5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizeTokens.cardPadding),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.apps_outlined,
            size: AppSizeTokens.icon28,
            color: Colors.grey[600],
          ),
          SizedBox(height: AppSizeTokens.space12),
          Text(
            'Belum ada aplikasi sosial atau game terdeteksi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizeTokens.text14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(InstalledFocusApp app, Color accentColor) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizeTokens.radius12),
      ),
      child: app.iconBytes.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSizeTokens.radius12),
              child: Image.memory(
                app.iconBytes,
                width: 32.w,
                height: 32.w,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  _getCategoryFallbackIcon(app.category),
                  color: accentColor,
                  size: AppSizeTokens.icon22,
                ),
              ),
            )
          : Icon(
              _getCategoryFallbackIcon(app.category),
              color: accentColor,
              size: AppSizeTokens.icon22,
            ),
    );
  }

  List<_AppUsageRow> _buildTodayRows() {
    final statsByPackage = {
      for (final stat in _todayStats) stat.packageName: stat.totalTimeMs,
    };

    return _trackedApps.map((app) {
      return _AppUsageRow(
        app: app,
        usageMs: statsByPackage[app.packageName] ?? 0,
        currentSessionMs: _currentSessions[app.packageName] ?? 0,
      );
    }).toList()..sort((left, right) => right.usageMs.compareTo(left.usageMs));
  }

  String _formatDateLabel(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    if (date == null) {
      return dateKey;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (normalizedDate == today) {
      return 'Hari ini';
    }

    if (normalizedDate == today.subtract(const Duration(days: 1))) {
      return 'Kemarin';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
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
}

class _AppUsageRow {
  const _AppUsageRow({
    required this.app,
    required this.usageMs,
    required this.currentSessionMs,
  });

  final InstalledFocusApp app;
  final int usageMs;
  final int currentSessionMs;
}

class _UsageLimitInfo {
  const _UsageLimitInfo({
    required this.priority,
    required this.riskLevel,
    required this.averageDailyUsageMs,
    required this.activeDays,
    required this.maxDailyUsageMs,
    required this.dailyLimitMs,
    required this.sessionLimitMs,
    required this.remainingDailyMs,
    required this.remainingSessionMs,
  });

  final TodoPriority priority;
  final _UsageRiskLevel riskLevel;
  final int averageDailyUsageMs;
  final int activeDays;
  final int maxDailyUsageMs;
  final int dailyLimitMs;
  final int sessionLimitMs;
  final int remainingDailyMs;
  final int remainingSessionMs;
}

class _UsageHistoryProfile {
  const _UsageHistoryProfile({
    required this.averageDailyUsageMs,
    required this.activeDays,
    required this.maxDailyUsageMs,
    required this.riskLevel,
  });

  final int averageDailyUsageMs;
  final int activeDays;
  final int maxDailyUsageMs;
  final _UsageRiskLevel riskLevel;
}
