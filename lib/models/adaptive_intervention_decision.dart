enum InterventionLevel {
  allow,
  softWarning,
  strongWarning,
  temporaryBlock,
  hardBlock,
}

class AdaptiveInterventionDecision {
  final InterventionLevel level;
  final String reason;
  final String message;
  final int? nextAllowedDelayMs;
  final int? remainingGraceMs;

  const AdaptiveInterventionDecision({
    required this.level,
    required this.reason,
    required this.message,
    this.nextAllowedDelayMs,
    this.remainingGraceMs,
  });

  @override
  String toString() {
    return 'AdaptiveInterventionDecision(level: $level, reason: $reason, message: $message)';
  }
}
