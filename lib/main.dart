import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'services/app_blocker_service.dart';
import 'services/app_logger.dart';
import 'services/permission_service.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'FlutterError',
      'Unhandled Flutter framework error.',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    AppLogger.error(
      'PlatformDispatcher',
      'Unhandled asynchronous error.',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  static const String _tag = 'MainApp';

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isInterventionVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeBlockedPackageAndPresent();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _consumeBlockedPackageAndPresent();
    }
  }

  Future<void> _consumeBlockedPackageAndPresent() async {
    if (_isInterventionVisible) {
      return;
    }

    final blockedPackage = await PermissionService.consumeBlockedPackage();
    if (blockedPackage == null || blockedPackage.isEmpty) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null || !mounted) {
      return;
    }

    AppLogger.info(
      _tag,
      'Presenting intervention for blocked package=$blockedPackage',
    );

    _isInterventionVisible = true;
    try {
      await AppBlockerService.showInterventionScreenWithNavigator(
        navigator,
        blockedPackage,
      );
    } finally {
      _isInterventionVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 851),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Todo List',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.grey,
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Inter',
            textTheme: TextTheme(
              displayLarge: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
              ),
              displayMedium: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
              ),
              headlineMedium: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
              titleLarge: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              bodyLarge: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
              bodyMedium: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ),
          home: child,
        );
      },
      child: const SplashScreen(),
    );
  }
}
