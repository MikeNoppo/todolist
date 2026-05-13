import 'package:flutter_test/flutter_test.dart';

import 'package:mytask/models/adaptive_limit_summary.dart';

void main() {
  group('AdaptiveLimitSummary', () {
    test('parses all native fields', () {
      final summary = AdaptiveLimitSummary.fromMap({
        'packageName': 'com.example.app',
        'priority': 'high',
        'usageRisk': 'heavy',
        'currentSessionMs': 1000,
        'todayUsageMs': 2000,
        'averageDailyUsageMs': 3000,
        'activeDays': 4,
        'maxDailyUsageMs': 5000,
        'sessionHardMs': 6000,
        'dailyHardMs': 7000,
        'remainingSessionMs': 8000,
        'remainingDailyMs': 9000,
      });

      expect(summary.packageName, 'com.example.app');
      expect(summary.priority, 'high');
      expect(summary.usageRisk, 'heavy');
      expect(summary.currentSessionMs, 1000);
      expect(summary.todayUsageMs, 2000);
      expect(summary.averageDailyUsageMs, 3000);
      expect(summary.activeDays, 4);
      expect(summary.maxDailyUsageMs, 5000);
      expect(summary.sessionHardMs, 6000);
      expect(summary.dailyHardMs, 7000);
      expect(summary.remainingSessionMs, 8000);
      expect(summary.remainingDailyMs, 9000);
    });

    test('uses safe defaults for missing or non-numeric values', () {
      final summary = AdaptiveLimitSummary.fromMap({
        'packageName': null,
        'priority': null,
        'usageRisk': null,
        'sessionHardMs': 'not-a-number',
      });

      expect(summary.packageName, '');
      expect(summary.priority, '');
      expect(summary.usageRisk, 'light');
      expect(summary.sessionHardMs, 0);
      expect(summary.dailyHardMs, 0);
    });
  });
}
