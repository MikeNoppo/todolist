import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mytask/services/notification_interruption_service.dart';

void main() {
  group('NotificationInterruptionService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to off on fresh install', () async {
      final service = NotificationInterruptionService();

      final mode = await service.getMode();

      expect(mode, NotificationInterruptionMode.off);
    });

    test('reads stored filter mode', () async {
      SharedPreferences.setMockInitialValues({
        'notification_interruption_mode': 'filter_distracting_apps',
      });
      final service = NotificationInterruptionService();

      final mode = await service.getMode();

      expect(mode, NotificationInterruptionMode.filterDistractingApps);
    });

    test('reads stored dnd mode', () async {
      SharedPreferences.setMockInitialValues({
        'notification_interruption_mode': 'dnd',
      });
      final service = NotificationInterruptionService();

      final mode = await service.getMode();

      expect(mode, NotificationInterruptionMode.dnd);
    });

    test('falls back to off for unknown stored value', () async {
      SharedPreferences.setMockInitialValues({
        'notification_interruption_mode': 'unexpected_mode',
      });
      final service = NotificationInterruptionService();

      final mode = await service.getMode();

      expect(mode, NotificationInterruptionMode.off);
    });

    test('setMode persists selected mode', () async {
      final service = NotificationInterruptionService();

      await service.setMode(NotificationInterruptionMode.filterDistractingApps);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('notification_interruption_mode'),
        'filter_distracting_apps',
      );
    });
  });
}
