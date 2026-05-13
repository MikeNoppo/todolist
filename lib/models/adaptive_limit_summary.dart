class AdaptiveLimitSummary {
  const AdaptiveLimitSummary({
    required this.packageName,
    required this.priority,
    required this.usageRisk,
    required this.currentSessionMs,
    required this.todayUsageMs,
    required this.averageDailyUsageMs,
    required this.activeDays,
    required this.maxDailyUsageMs,
    required this.sessionHardMs,
    required this.dailyHardMs,
    required this.remainingSessionMs,
    required this.remainingDailyMs,
  });

  final String packageName;
  final String priority;
  final String usageRisk;
  final int currentSessionMs;
  final int todayUsageMs;
  final int averageDailyUsageMs;
  final int activeDays;
  final int maxDailyUsageMs;
  final int sessionHardMs;
  final int dailyHardMs;
  final int remainingSessionMs;
  final int remainingDailyMs;

  factory AdaptiveLimitSummary.fromMap(Map<dynamic, dynamic> map) {
    return AdaptiveLimitSummary(
      packageName: map['packageName']?.toString() ?? '',
      priority: map['priority']?.toString() ?? '',
      usageRisk: map['usageRisk']?.toString() ?? 'light',
      currentSessionMs: _readInt(map['currentSessionMs']),
      todayUsageMs: _readInt(map['todayUsageMs']),
      averageDailyUsageMs: _readInt(map['averageDailyUsageMs']),
      activeDays: _readInt(map['activeDays']),
      maxDailyUsageMs: _readInt(map['maxDailyUsageMs']),
      sessionHardMs: _readInt(map['sessionHardMs']),
      dailyHardMs: _readInt(map['dailyHardMs']),
      remainingSessionMs: _readInt(map['remainingSessionMs']),
      remainingDailyMs: _readInt(map['remainingDailyMs']),
    );
  }

  static int _readInt(Object? value) {
    return value is num ? value.toInt() : 0;
  }
}
