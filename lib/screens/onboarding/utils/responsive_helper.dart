import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;
  
  ResponsiveHelper(this.context);
  
  double get screenHeight => MediaQuery.of(context).size.height;
  double get screenWidth => MediaQuery.of(context).size.width;
  
  // Available height for content (65% of screen for page 1 & 2, 75% for page 3)
  double get availableHeight => screenHeight * 0.65;
  double get availableHeightPage3 => screenHeight * 0.75;
  
  // Horizontal padding
  double get horizontalPadding => screenWidth * 0.08;
  
  // Page 1 & 2 sizing (based on availableHeight)
  double get iconSize => availableHeight * 0.15;
  double get iconSizePage2 => availableHeight * 0.12;
  double get titleFontSize => availableHeight * 0.045;
  double get subtitleFontSize => availableHeight * 0.025;
  double get featureTitleFontSize => availableHeight * 0.025;
  double get featureSubtitleFontSize => availableHeight * 0.022;
  double get stepTitleFontSize => availableHeight * 0.028;
  double get stepSubtitleFontSize => availableHeight * 0.022;
  
  // Page 3 sizing (based on screenHeight)
  double get iconSizePage3 => screenHeight * 0.1;
  double get titleFontSizePage3 => screenHeight * 0.03;
  double get subtitleFontSizePage3 => screenHeight * 0.018;
  double get permissionTitleFontSize => screenHeight * 0.017;
  double get permissionSubtitleFontSize => screenHeight * 0.014;
  double get disclaimerFontSize => screenHeight * 0.015;
  double get infoTitleFontSize => screenHeight * 0.016;
  double get infoContentFontSize => screenHeight * 0.013;
  
  // Spacing
  double get smallSpacing => availableHeight * 0.02;
  double get mediumSpacing => availableHeight * 0.03;
  double get largeSpacing => availableHeight * 0.04;
  double get extraLargeSpacing => availableHeight * 0.05;
  double get hugeSpacing => availableHeight * 0.06;
  
  // Icon container sizes
  double get featureIconContainerSize => availableHeight * 0.08;
  double get stepCircleSize => availableHeight * 0.05;
  double get stepIconContainerSize => availableHeight * 0.07;
  double get permissionIconSize => screenHeight * 0.025;
  
  // Helper methods for consistent sizing
  double spacing(double ratio) => availableHeight * ratio;
  double spacingPage3(double ratio) => screenHeight * ratio;
}
