import 'dart:typed_data';

enum InstalledAppCategory { social, game }

class InstalledFocusApp {
  const InstalledFocusApp({
    required this.packageName,
    required this.appName,
    required this.category,
    required this.iconBytes,
  });

  final String packageName;
  final String appName;
  final InstalledAppCategory category;
  final Uint8List iconBytes;

  factory InstalledFocusApp.fromMap(Map<dynamic, dynamic> map) {
    final rawCategory = map['category']?.toString().toLowerCase();
    final category = rawCategory == 'game'
        ? InstalledAppCategory.game
        : InstalledAppCategory.social;

    final rawIcon = map['iconBytes'];
    final iconBytes = rawIcon is Uint8List
        ? rawIcon
        : rawIcon is List<int>
        ? Uint8List.fromList(rawIcon)
        : Uint8List(0);

    return InstalledFocusApp(
      packageName: map['packageName']?.toString() ?? '',
      appName: map['appName']?.toString() ?? '',
      category: category,
      iconBytes: iconBytes,
    );
  }
}
