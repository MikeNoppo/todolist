import 'package:flutter/material.dart';
import 'dart:io';

class DeviceTypeHelper {
  static bool isEmulator(BuildContext context) {
    // Check if running on emulator by examining device properties
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double pixelRatio = mediaQuery.devicePixelRatio;
    final Size size = mediaQuery.size;
    
    // Common emulator characteristics
    bool hasEmulatorSize = (size.width == 393.0 && size.height == 851.0) || // Pixel 5
                          (size.width == 411.0 && size.height == 731.0) || // Common tablet
                          (size.width == 360.0 && size.height == 640.0);   // Common phone
    
    bool hasEmulatorDensity = pixelRatio == 3.0 || pixelRatio == 2.75;
    
    return Platform.isAndroid && (hasEmulatorSize || hasEmulatorDensity);
  }
  
  static double getEmulatorFontScale(BuildContext context) {
    if (isEmulator(context)) {
      // Increase font size by 20% for emulators
      return 1.2;
    }
    return 1.0;
  }
  
  static double getAdaptiveFontSize(BuildContext context, double baseSize) {
    return baseSize * getEmulatorFontScale(context);
  }
}
