import 'package:flutter_test/flutter_test.dart';

import 'package:mytask/models/adaptive_intervention_runtime_event.dart';

void main() {
  group('AdaptiveInterventionRuntimeEvent', () {
    test('parses native event payload', () {
      final event = AdaptiveInterventionRuntimeEvent.fromMap({
        'packageName': 'com.brave.browser',
        'interventionLevel': 'temporary_block',
        'isBlockingNow': true,
        'recordedAtMillis': 1716000000000,
        'currentSessionMs': 600000,
        'todayUsageMs': 2820000,
        'averageDailyUsageMs': 5400000,
        'warningCount': 2,
        'message': 'Blocked',
        'reason': 'level=temporary_block',
      });

      expect(event.packageName, 'com.brave.browser');
      expect(event.interventionLevel, 'temporary_block');
      expect(event.isBlockingNow, isTrue);
      expect(event.recordedAt.millisecondsSinceEpoch, 1716000000000);
      expect(event.currentSessionMs, 600000);
      expect(event.todayUsageMs, 2820000);
      expect(event.averageDailyUsageMs, 5400000);
      expect(event.warningCount, 2);
      expect(event.message, 'Blocked');
      expect(event.reason, 'level=temporary_block');
    });

    test('uses safe defaults for malformed payloads', () {
      final event = AdaptiveInterventionRuntimeEvent.fromMap({
        'packageName': null,
        'interventionLevel': null,
        'isBlockingNow': 'yes',
        'recordedAtMillis': 'now',
      });

      expect(event.packageName, '');
      expect(event.interventionLevel, 'allow');
      expect(event.isBlockingNow, isFalse);
      expect(event.recordedAt.millisecondsSinceEpoch, 0);
      expect(event.currentSessionMs, 0);
      expect(event.todayUsageMs, 0);
    });
  });
}
