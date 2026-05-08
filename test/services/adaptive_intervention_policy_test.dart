import 'package:flutter_test/flutter_test.dart';
import 'package:mytask/models/adaptive_intervention_decision.dart';
import 'package:mytask/models/todo_model.dart';
import 'package:mytask/services/adaptive_intervention_policy.dart';

void main() {
  group('AdaptiveInterventionPolicy', () {
    late AdaptiveInterventionPolicy policy;

    setUp(() {
      policy = AdaptiveInterventionPolicy();
    });

    test('returns allow when app is whitelisted', () {
      final decision = policy.evaluateAdaptiveBlock(
        packageName: 'com.example.app',
        isWhitelisted: true,
        isBlockedByUser: true,
        hasActiveTask: true,
        activeTaskPriority: TodoPriority.high,
        currentSessionMs: 60 * 60 * 1000,
        todayUsageMs: 0,
      );

      expect(decision.level, InterventionLevel.allow);
      expect(decision.reason, 'App is whitelisted');
    });

    test('returns allow when app is not blocked by user', () {
      final decision = policy.evaluateAdaptiveBlock(
        packageName: 'com.example.app',
        isWhitelisted: false,
        isBlockedByUser: false,
        hasActiveTask: true,
        activeTaskPriority: TodoPriority.high,
        currentSessionMs: 60 * 60 * 1000,
        todayUsageMs: 0,
      );

      expect(decision.level, InterventionLevel.allow);
      expect(decision.reason, 'App is not in user block list');
    });

    test('returns allow when no active urgent task', () {
      final decision = policy.evaluateAdaptiveBlock(
        packageName: 'com.example.app',
        isWhitelisted: false,
        isBlockedByUser: true,
        hasActiveTask: false,
        currentSessionMs: 60 * 60 * 1000,
        todayUsageMs: 0,
      );

      expect(decision.level, InterventionLevel.allow);
      expect(decision.reason, 'No active urgent task');
    });

    group('High Priority Evaluator', () {
      test('returns allow if below soft warning threshold', () {
        final decision = policy.evaluateAdaptiveBlock(
          packageName: 'com.example.app',
          isWhitelisted: false,
          isBlockedByUser: true,
          hasActiveTask: true,
          activeTaskPriority: TodoPriority.high,
          currentSessionMs: 4 * 60 * 1000, // 4 mins (< 5m)
          todayUsageMs: 0,
        );

        expect(decision.level, InterventionLevel.allow);
      });

      test('returns softWarning if above soft but below strong threshold', () {
        final decision = policy.evaluateAdaptiveBlock(
          packageName: 'com.example.app',
          isWhitelisted: false,
          isBlockedByUser: true,
          hasActiveTask: true,
          activeTaskPriority: TodoPriority.high,
          currentSessionMs: 6 * 60 * 1000, // 6 mins (>= 5m)
          todayUsageMs: 0,
        );

        expect(decision.level, InterventionLevel.softWarning);
      });

      test('returns strongWarning if above strong but below temp block', () {
        final decision = policy.evaluateAdaptiveBlock(
          packageName: 'com.example.app',
          isWhitelisted: false,
          isBlockedByUser: true,
          hasActiveTask: true,
          activeTaskPriority: TodoPriority.high,
          currentSessionMs: 15 * 60 * 1000, // 15 mins (>= 10m)
          todayUsageMs: 0,
        );

        expect(decision.level, InterventionLevel.strongWarning);
      });

      test('returns temporaryBlock if above temp block but below hard block', () {
        final decision = policy.evaluateAdaptiveBlock(
          packageName: 'com.example.app',
          isWhitelisted: false,
          isBlockedByUser: true,
          hasActiveTask: true,
          activeTaskPriority: TodoPriority.high,
          currentSessionMs: 40 * 60 * 1000, // 40 mins (>= 30m)
          todayUsageMs: 0,
        );

        expect(decision.level, InterventionLevel.temporaryBlock);
      });

      test('returns hardBlock if above hard block threshold', () {
        final decision = policy.evaluateAdaptiveBlock(
          packageName: 'com.example.app',
          isWhitelisted: false,
          isBlockedByUser: true,
          hasActiveTask: true,
          activeTaskPriority: TodoPriority.high,
          currentSessionMs: 65 * 60 * 1000, // 65 mins (>= 60m)
          todayUsageMs: 0,
        );

        expect(decision.level, InterventionLevel.hardBlock);
      });
    });
  });
}
