import 'package:flutter/material.dart';

/// Collection of elegant icons for intervention screen
class InterventionIcons {
  // Brain/Focus related icons
  static const IconData brain = Icons.psychology_outlined;
  static const IconData focusMode = Icons.center_focus_strong_outlined;
  static const IconData mindfulness = Icons.self_improvement_outlined;

  // Shield/Protection icons
  static const IconData shield = Icons.shield_outlined;
  static const IconData security = Icons.security_outlined;
  static const IconData lock = Icons.lock_outline;

  // Nature/Zen icons
  static const IconData lotus = Icons.local_florist_outlined;
  static const IconData spa = Icons.spa_outlined;
  static const IconData nature = Icons.nature_outlined;

  // Work/Productivity icons
  static const IconData work = Icons.work_outline;
  static const IconData assignment = Icons.assignment_outlined;
  static const IconData target = Icons.track_changes_outlined;

  // Time/Focus icons
  static const IconData timer = Icons.timer_outlined;
  static const IconData hourglass = Icons.hourglass_empty_outlined;
  static const IconData schedule = Icons.schedule_outlined;

  /// Get a random icon from the collection
  static IconData getRandomIcon() {
    final icons = [
      brain,
      focusMode,
      mindfulness,
      shield,
      security,
      lotus,
      spa,
      work,
      assignment,
      target,
    ];

    final random = DateTime.now().millisecondsSinceEpoch % icons.length;
    return icons[random];
  }

  /// Get icon based on app category
  static IconData getIconForApp(String packageName) {
    if (packageName.contains('facebook') ||
        packageName.contains('instagram') ||
        packageName.contains('twitter')) {
      return shield; // Social media apps get shield
    } else if (packageName.contains('youtube') ||
        packageName.contains('netflix') ||
        packageName.contains('spotify')) {
      return timer; // Entertainment apps get timer
    } else if (packageName.contains('game')) {
      return target; // Games get target
    } else {
      return brain; // Default to brain icon
    }
  }
}
