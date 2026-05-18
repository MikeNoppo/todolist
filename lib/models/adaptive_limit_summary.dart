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
    required this.interventionLevel,
    required this.isBlockingNow,
    required this.temporaryBlockMs,
    required this.sessionHardMs,
    required this.dailyHardMs,
    required this.remainingBeforeBlockMs,
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
  final String interventionLevel;
  final bool isBlockingNow;
  final int temporaryBlockMs;
  final int sessionHardMs;
  final int dailyHardMs;
  final int remainingBeforeBlockMs;
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
      interventionLevel: map['interventionLevel']?.toString() ?? 'allow',
      isBlockingNow: _readBool(map['isBlockingNow']),
      temporaryBlockMs: _readInt(map['temporaryBlockMs']),
      sessionHardMs: _readInt(map['sessionHardMs']),
      dailyHardMs: _readInt(map['dailyHardMs']),
      remainingBeforeBlockMs: _readInt(map['remainingBeforeBlockMs']),
      remainingSessionMs: _readInt(map['remainingSessionMs']),
      remainingDailyMs: _readInt(map['remainingDailyMs']),
    );
  }

  static int _readInt(Object? value) {
    return value is num ? value.toInt() : 0;
  }

  static bool _readBool(Object? value) {
    return value is bool ? value : false;
  }
}
