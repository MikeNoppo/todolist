import 'package:flutter/services.dart';

import '../models/adaptive_intervention_runtime_event.dart';

class AdaptiveInterventionEventService {
  const AdaptiveInterventionEventService();

  static const EventChannel _channel = EventChannel(
    'app_blocker/adaptive_intervention_events',
  );

  Stream<AdaptiveInterventionRuntimeEvent> watchRuntimeEvents() {
    return _channel
        .receiveBroadcastStream()
        .where((event) {
          return event is Map<dynamic, dynamic>;
        })
        .map((event) {
          return AdaptiveInterventionRuntimeEvent.fromMap(
            event as Map<dynamic, dynamic>,
          );
        })
        .where((event) {
          return event.packageName.isNotEmpty;
        });
  }
}
