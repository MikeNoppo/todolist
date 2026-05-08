import '../models/adaptive_intervention_decision.dart';
import '../models/todo_model.dart';

class AdaptiveInterventionPolicy {
  // Hardcoded thresholds in milliseconds (for the static policy phase)
  
  // High Priority
  static const int _highSoftWarningMs = 5 * 60 * 1000;      // 5 min
  static const int _highStrongWarningMs = 10 * 60 * 1000;   // 10 min
  static const int _highTempBlockMs = 30 * 60 * 1000;       // 30 min
  static const int _highHardBlockMs = 60 * 60 * 1000;       // 60 min

  // Medium Priority
  static const int _mediumSoftWarningMs = 10 * 60 * 1000;   // 10 min
  static const int _mediumStrongWarningMs = 20 * 60 * 1000; // 20 min
  static const int _mediumTempBlockMs = 45 * 60 * 1000;     // 45 min
  static const int _mediumHardBlockMs = 90 * 60 * 1000;     // 90 min

  // Low Priority
  static const int _lowSoftWarningMs = 15 * 60 * 1000;      // 15 min
  static const int _lowStrongWarningMs = 30 * 60 * 1000;    // 30 min
  static const int _lowTempBlockMs = 60 * 60 * 1000;        // 60 min
  static const int _lowHardBlockMs = 120 * 60 * 1000;       // 120 min

  AdaptiveInterventionDecision evaluateAdaptiveBlock({
    required String packageName,
    required bool isWhitelisted,
    required bool isBlockedByUser,
    required bool hasActiveTask,
    TodoPriority? activeTaskPriority,
    required int currentSessionMs,
    required int todayUsageMs,
  }) {
    if (isWhitelisted) {
      return const AdaptiveInterventionDecision(
        level: InterventionLevel.allow,
        reason: 'App is whitelisted',
        message: '',
      );
    }

    if (!isBlockedByUser) {
      return const AdaptiveInterventionDecision(
        level: InterventionLevel.allow,
        reason: 'App is not in user block list',
        message: '',
      );
    }

    if (!hasActiveTask || activeTaskPriority == null) {
      return const AdaptiveInterventionDecision(
        level: InterventionLevel.allow,
        reason: 'No active urgent task',
        message: '',
      );
    }

    return _evaluateByDuration(currentSessionMs, activeTaskPriority);
  }

  AdaptiveInterventionDecision _evaluateByDuration(int currentSessionMs, TodoPriority priority) {
    int softWarningMs;
    int strongWarningMs;
    int tempBlockMs;
    int hardBlockMs;

    switch (priority) {
      case TodoPriority.high:
        softWarningMs = _highSoftWarningMs;
        strongWarningMs = _highStrongWarningMs;
        tempBlockMs = _highTempBlockMs;
        hardBlockMs = _highHardBlockMs;
        break;
      case TodoPriority.medium:
        softWarningMs = _mediumSoftWarningMs;
        strongWarningMs = _mediumStrongWarningMs;
        tempBlockMs = _mediumTempBlockMs;
        hardBlockMs = _mediumHardBlockMs;
        break;
      case TodoPriority.low:
        softWarningMs = _lowSoftWarningMs;
        strongWarningMs = _lowStrongWarningMs;
        tempBlockMs = _lowTempBlockMs;
        hardBlockMs = _lowHardBlockMs;
        break;
    }

    if (currentSessionMs >= hardBlockMs) {
      return const AdaptiveInterventionDecision(
        level: InterventionLevel.hardBlock,
        reason: 'Exceeded hard block threshold',
        message: 'Aplikasi diblokir karena kamu sudah terlalu lama membuka aplikasi ini, sedangkan ada tugas penting.',
      );
    } else if (currentSessionMs >= tempBlockMs) {
      return AdaptiveInterventionDecision(
        level: InterventionLevel.temporaryBlock,
        reason: 'Exceeded temporary block threshold',
        message: 'Kamu harus kembali mengerjakan tugasmu sekarang.',
        remainingGraceMs: hardBlockMs - currentSessionMs,
      );
    } else if (currentSessionMs >= strongWarningMs) {
      return AdaptiveInterventionDecision(
        level: InterventionLevel.strongWarning,
        reason: 'Exceeded strong warning threshold',
        message: 'Peringatan: Kamu sudah cukup lama membuka aplikasi ini. Segera selesaikan tugasmu.',
        remainingGraceMs: tempBlockMs - currentSessionMs,
      );
    } else if (currentSessionMs >= softWarningMs) {
      return AdaptiveInterventionDecision(
        level: InterventionLevel.softWarning,
        reason: 'Exceeded soft warning threshold',
        message: 'Kamu punya tugas penting. Ambil jeda sebentar boleh, tapi jangan terlalu lama.',
        remainingGraceMs: strongWarningMs - currentSessionMs,
      );
    }

    return const AdaptiveInterventionDecision(
      level: InterventionLevel.allow,
      reason: 'Session duration below warning threshold',
      message: '',
    );
  }
}
