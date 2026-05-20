import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytask/services/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app_blocker/permissions');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PermissionService adaptive limit summaries', () {
    test('parses native summaries keyed by package name', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'getAdaptiveLimitSummaries');
            expect(call.arguments, {
              'packageNames': ['com.zhiliaoapp.musically'],
              'priority': 'high',
            });

            return [
              {
                'packageName': 'com.zhiliaoapp.musically',
                'priority': 'high',
                'usageRisk': 'abusive',
                'currentSessionMs': 3 * 60 * 1000,
                'todayUsageMs': 25 * 60 * 1000,
                'averageDailyUsageMs': 3 * 60 * 60 * 1000,
                'activeDays': 6,
                'maxDailyUsageMs': 4 * 60 * 60 * 1000,
                'interventionLevel': 'temporary_block',
                'isBlockingNow': true,
                'temporaryBlockMs': 12 * 60 * 1000,
                'sessionHardMs': 24 * 60 * 1000,
                'dailyHardMs': 81 * 60 * 1000,
                'remainingBeforeBlockMs': 0,
                'remainingSessionMs': 21 * 60 * 1000,
                'remainingDailyMs': 56 * 60 * 1000,
              },
            ];
          });

      final summaries = await PermissionService.getAdaptiveLimitSummaries(
        packageNames: ['com.zhiliaoapp.musically'],
        priority: 'high',
      );

      final summary = summaries['com.zhiliaoapp.musically'];
      expect(summary, isNotNull);
      expect(summary!.usageRisk, 'abusive');
      expect(summary.interventionLevel, 'temporary_block');
      expect(summary.isBlockingNow, isTrue);
      expect(summary.temporaryBlockMs, 12 * 60 * 1000);
      expect(summary.sessionHardMs, 24 * 60 * 1000);
      expect(summary.dailyHardMs, 81 * 60 * 1000);
      expect(summary.remainingBeforeBlockMs, 0);
      expect(summary.activeDays, 6);
    });

    test('ignores malformed summaries', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return [
              {'packageName': '', 'sessionHardMs': 1},
              'invalid-entry',
            ];
          });

      final summaries = await PermissionService.getAdaptiveLimitSummaries(
        packageNames: [''],
        priority: 'medium',
      );

      expect(summaries, isEmpty);
    });
  });
}
