import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'device_type_helper.dart';

class ResponsiveHelper {
  final BuildContext context;
  
  ResponsiveHelper(this.context);
  
  double get screenHeight => MediaQuery.of(context).size.height;
  double get screenWidth => MediaQuery.of(context).size.width;
  double get devicePixelRatio => MediaQuery.of(context).devicePixelRatio;
  
  // Calculate text scale factor based on screen size and pixel density
  double get textScaleFactor {
    // Base calculation on screen diagonal (in dp)
    double diagonal = math.sqrt(math.pow(screenWidth, 2) + math.pow(screenHeight, 2));
    
    // Normalize diagonal to a scale factor
    // Assuming 600dp diagonal as baseline (typical phone)
    double scaleFactor = diagonal / 600.0;
    
    // Clamp the scale factor to prevent extreme sizes
    return math.max(0.8, math.min(1.4, scaleFactor));
  }
  
  // Helper method to calculate responsive font size with minimum constraints
  double _responsiveFontSize(double baseSize, {double? minSize, double? maxSize}) {
    // Apply emulator scaling if needed
    double emulatorScale = DeviceTypeHelper.getEmulatorFontScale(context);
    double calculated = baseSize * textScaleFactor * emulatorScale;
    
    if (minSize != null) calculated = math.max(minSize, calculated);
    if (maxSize != null) calculated = math.min(maxSize, calculated);
    
    return calculated;
  }
  
  // Available height for content (65% of screen for page 1 & 2, 75% for page 3)
  double get availableHeight => screenHeight * 0.65;
  double get availableHeightPage3 => screenHeight * 0.75;
  
  // Horizontal padding
  double get horizontalPadding => screenWidth * 0.08;
  
  // Page 1 & 2 sizing with minimum font sizes
  double get iconSize => (availableHeight * 0.15).clamp(60.0, 120.0);
  double get iconSizePage2 => (availableHeight * 0.12).clamp(50.0, 100.0);
  double get titleFontSize => _responsiveFontSize(28.0, minSize: 24.0, maxSize: 36.0);
  double get subtitleFontSize => _responsiveFontSize(16.0, minSize: 14.0, maxSize: 20.0);
  double get featureTitleFontSize => _responsiveFontSize(16.0, minSize: 14.0, maxSize: 20.0);
  double get featureSubtitleFontSize => _responsiveFontSize(14.0, minSize: 12.0, maxSize: 18.0);
  double get stepTitleFontSize => _responsiveFontSize(18.0, minSize: 16.0, maxSize: 22.0);
  double get stepSubtitleFontSize => _responsiveFontSize(14.0, minSize: 12.0, maxSize: 18.0);
  
  // Page 3 sizing with minimum font sizes
  double get iconSizePage3 => (screenHeight * 0.1).clamp(50.0, 100.0);
  double get titleFontSizePage3 => _responsiveFontSize(24.0, minSize: 20.0, maxSize: 30.0);
  double get subtitleFontSizePage3 => _responsiveFontSize(14.0, minSize: 12.0, maxSize: 18.0);
  double get permissionTitleFontSize => _responsiveFontSize(14.0, minSize: 12.0, maxSize: 18.0);
  double get permissionSubtitleFontSize => _responsiveFontSize(12.0, minSize: 11.0, maxSize: 16.0);
  double get disclaimerFontSize => _responsiveFontSize(12.0, minSize: 11.0, maxSize: 16.0);
  double get infoTitleFontSize => _responsiveFontSize(13.0, minSize: 12.0, maxSize: 17.0);
  double get infoContentFontSize => _responsiveFontSize(11.0, minSize: 10.0, maxSize: 15.0);
  
  // Spacing with minimum constraints
  double get smallSpacing => (availableHeight * 0.02).clamp(8.0, 20.0);
  double get mediumSpacing => (availableHeight * 0.03).clamp(12.0, 30.0);
  double get largeSpacing => (availableHeight * 0.04).clamp(16.0, 40.0);
  double get extraLargeSpacing => (availableHeight * 0.05).clamp(20.0, 50.0);
  double get hugeSpacing => (availableHeight * 0.06).clamp(24.0, 60.0);
  
  // Icon container sizes with minimum constraints
  double get featureIconContainerSize => (availableHeight * 0.08).clamp(40.0, 80.0);
  double get stepCircleSize => (availableHeight * 0.05).clamp(24.0, 50.0);
  double get stepIconContainerSize => (availableHeight * 0.07).clamp(32.0, 70.0);
  double get permissionIconSize => (screenHeight * 0.025).clamp(16.0, 32.0);
  
  // Helper methods for consistent sizing
  double spacing(double ratio) => (availableHeight * ratio).clamp(4.0, 100.0);
  double spacingPage3(double ratio) => (screenHeight * ratio).clamp(4.0, 100.0);
  
  // Debug method to check current values
  void debugPrintSizes() {
    print('Screen: ${screenWidth}x$screenHeight, DPR: $devicePixelRatio');
    print('Text Scale Factor: $textScaleFactor');
    print('Title Font Size: $titleFontSize');
    print('Subtitle Font Size: $subtitleFontSize');
  }
}
