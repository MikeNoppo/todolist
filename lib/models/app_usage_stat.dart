class AppUsageStat {
  const AppUsageStat({
    required this.packageName,
    required this.totalTimeMs,
    required this.date,
  });

  final String packageName;
  final int totalTimeMs;
  final DateTime date;

  Duration get duration => Duration(milliseconds: totalTimeMs);

  bool get hasUsage => totalTimeMs > 0;

  String get formattedTime => formatDuration(duration);

  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes.remainder(60);
      return minutes > 0
          ? '${duration.inHours}j ${minutes}m'
          : '${duration.inHours}j';
    }

    if (duration.inMinutes > 0) {
      final seconds = duration.inSeconds.remainder(60);
      return seconds > 0
          ? '${duration.inMinutes}m ${seconds}d'
          : '${duration.inMinutes}m';
    }

    return '${duration.inSeconds}d';
  }
}
