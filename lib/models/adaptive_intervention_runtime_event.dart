class AdaptiveInterventionRuntimeEvent {
  const AdaptiveInterventionRuntimeEvent({
    required this.packageName,
    required this.interventionLevel,
    required this.isBlockingNow,
    required this.recordedAt,
    required this.currentSessionMs,
    required this.todayUsageMs,
    required this.averageDailyUsageMs,
    required this.warningCount,
    required this.message,
    required this.reason,
  });

  final String packageName;
  final String interventionLevel;
  final bool isBlockingNow;
  final DateTime recordedAt;
  final int currentSessionMs;
  final int todayUsageMs;
  final int averageDailyUsageMs;
  final int warningCount;
  final String message;
  final String reason;

  factory AdaptiveInterventionRuntimeEvent.fromMap(Map<dynamic, dynamic> map) {
    final recordedAtMillis = _readInt(map['recordedAtMillis']);
    return AdaptiveInterventionRuntimeEvent(
      packageName: map['packageName']?.toString() ?? '',
      interventionLevel: map['interventionLevel']?.toString() ?? 'allow',
      isBlockingNow: _readBool(map['isBlockingNow']),
      recordedAt: DateTime.fromMillisecondsSinceEpoch(recordedAtMillis),
      currentSessionMs: _readInt(map['currentSessionMs']),
      todayUsageMs: _readInt(map['todayUsageMs']),
      averageDailyUsageMs: _readInt(map['averageDailyUsageMs']),
      warningCount: _readInt(map['warningCount']),
      message: map['message']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
    );
  }

  static int _readInt(Object? value) {
    return value is num ? value.toInt() : 0;
  }

  static bool _readBool(Object? value) {
    return value is bool ? value : false;
  }
}
