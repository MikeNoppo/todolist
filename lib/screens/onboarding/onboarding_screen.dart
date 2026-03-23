import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../repositories/todo_repository.dart';
import '../../services/app_logger.dart';
import '../../services/permission_service.dart';
import '../Home/home_screen.dart';
import 'pages/onboarding_page_1.dart';
import 'pages/onboarding_page_2.dart';
import 'pages/onboarding_page_3.dart';
import 'pages/onboarding_page_4.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initialPage = 0});

  static const int accessibilityStepIndex = 2;
  static const int usageStatsStepIndex = 3;

  final int initialPage;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  static const String _tag = 'OnboardingScreen';
  static const int _introPageCount = 2;
  static const int _accessibilityPageIndex = 2;
  static const int _usageStatsPageIndex = 3;
  static const int _totalPages = 4;

  late final PageController _pageController;
  final TodoRepository _todoRepository = TodoRepository();
  int _currentPage = 0;
  bool _isAccessibilityGranted = false;
  bool _isUsageStatsGranted = false;
  bool _isReturningFromPermissionSettings = false;

  // Define accent color - muted blue
  static const Color accentColor = Color(0xFF4A6FA5);

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, _totalPages - 1);
    _pageController = PageController(initialPage: _currentPage);
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed &&
        _isReturningFromPermissionSettings) {
      _isReturningFromPermissionSettings = false;
      _checkPermissionsAfterResume();
    }
  }

  Future<({bool accessibilityEnabled, bool usageStatsGranted})>
  _refreshPermissionState() async {
    final accessibilityEnabled =
        await PermissionService.isAccessibilityServiceEnabled();
    final usageStatsGranted =
        await PermissionService.isUsageStatsPermissionGranted();

    if (mounted) {
      setState(() {
        _isAccessibilityGranted = accessibilityEnabled;
        _isUsageStatsGranted = usageStatsGranted;
      });
    }

    return (
      accessibilityEnabled: accessibilityEnabled,
      usageStatsGranted: usageStatsGranted,
    );
  }

  Future<void> _checkPermissionsAfterResume() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final permissionState = await _refreshPermissionState();

    if (!mounted) return;

    if (_currentPage == _accessibilityPageIndex) {
      if (permissionState.accessibilityEnabled) {
        AppLogger.info(
          _tag,
          'Accessibility permission granted after app resume. Moving to usage stats step.',
        );
        _showPermissionSnackBar(
          message: 'Izin aksesibilitas aktif. Lanjut ke izin berikutnya.',
          isSuccess: true,
        );
        _goToUsageStatsStep();
      } else {
        AppLogger.debug(
          _tag,
          'Accessibility permission still disabled after app resume.',
        );
        _showPermissionSnackBar(
          message:
              'Izin aksesibilitas belum aktif. Aktifkan dulu untuk lanjut.',
        );
      }
      return;
    }

    if (_currentPage != _usageStatsPageIndex) {
      return;
    }

    if (!permissionState.accessibilityEnabled) {
      AppLogger.warn(
        _tag,
        'Accessibility permission disabled while on usage stats step. Returning to accessibility step.',
      );
      _showPermissionSnackBar(
        message: 'Aksesibilitas harus aktif terlebih dahulu.',
      );
      _goToAccessibilityStep();
      return;
    }

    if (permissionState.usageStatsGranted) {
      AppLogger.info(
        _tag,
        'All required permissions granted after app resume.',
      );
      _showPermissionSnackBar(
        message: 'Semua izin berhasil diaktifkan!',
        isSuccess: true,
      );
      await _navigateToHome();
      return;
    }

    AppLogger.debug(
      _tag,
      'Usage stats permission still disabled after app resume.',
    );
    _showPermissionSnackBar(
      message: 'Izin statistik penggunaan belum aktif. Aktifkan untuk lanjut.',
    );
  }

  void _showPermissionSnackBar({
    required String message,
    bool isSuccess = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSkipButton(),
            _buildPageView(),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: EdgeInsets.all(20.0.r),
      child: Align(
        alignment: Alignment.centerRight,
        child: _currentPage < _introPageCount
            ? TextButton(
                onPressed: _skipToPermissionStep,
                child: Text(
                  'Lewati',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              )
            : SizedBox(height: 48.h),
      ),
    );
  }

  Widget _buildPageView() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          // Always update _currentPage first so indicators and buttons
          // reflect the actual page position during any animation.
          setState(() {
            _currentPage = index;
          });

          if (index == _usageStatsPageIndex && !_isAccessibilityGranted) {
            _showPermissionSnackBar(
              message: 'Aktifkan aksesibilitas terlebih dahulu.',
            );
            _goToAccessibilityStep();
            return;
          }
        },
        children: [
          const OnboardingPage1(),
          const OnboardingPage2(),
          const OnboardingPage3(),
          const OnboardingPage4(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: EdgeInsets.fromLTRB(32.w, 16.h, 32.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPageIndicator(),
          SizedBox(height: 20.h),
          _buildNavigationButton(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _totalPages,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? accentColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton() {
    final isCurrentPermissionStepReadable = _isCurrentPermissionStepReadable();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isCurrentPermissionStepReadable
            ? _handlePrimaryAction
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentPermissionStepReadable
              ? accentColor
              : Colors.grey[400],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          _navigationButtonLabel(),
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  bool _isCurrentPermissionStepReadable() {
    return true;
  }

  String _navigationButtonLabel() {
    if (_currentPage < _accessibilityPageIndex) {
      return 'Lanjutkan';
    }

    if (_currentPage == _accessibilityPageIndex) {
      return _isAccessibilityGranted
          ? 'Lanjut ke Izin Statistik'
          : 'Aktifkan Aksesibilitas';
    }

    return _isUsageStatsGranted
        ? 'Mulai Aplikasi'
        : 'Aktifkan Statistik Penggunaan';
  }

  void _handlePrimaryAction() {
    if (_currentPage < _accessibilityPageIndex) {
      _nextPage();
      return;
    }

    if (_currentPage == _accessibilityPageIndex) {
      _handleAccessibilityStep();
      return;
    }

    _handleUsageStatsStep();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipToPermissionStep() => _goToAccessibilityStep();

  void _goToAccessibilityStep() {
    _pageController.animateToPage(
      _accessibilityPageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToUsageStatsStep() {
    _pageController.animateToPage(
      _usageStatsPageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleAccessibilityStep() async {
    final permissionState = await _refreshPermissionState();

    if (!mounted) return;

    if (permissionState.accessibilityEnabled) {
      AppLogger.info(
        _tag,
        'Accessibility permission already granted. Moving to usage stats step.',
      );
      _goToUsageStatsStep();
      return;
    }

    await _showAccessibilityInstructions();
  }

  Future<void> _handleUsageStatsStep() async {
    final permissionState = await _refreshPermissionState();

    if (!mounted) return;

    if (!permissionState.accessibilityEnabled) {
      AppLogger.warn(
        _tag,
        'Usage stats step requested before accessibility permission is enabled.',
      );
      _showPermissionSnackBar(
        message: 'Aktifkan aksesibilitas terlebih dahulu.',
      );
      _goToAccessibilityStep();
      return;
    }

    if (permissionState.usageStatsGranted) {
      AppLogger.info(
        _tag,
        'Usage stats permission granted. Navigating to home.',
      );
      await _navigateToHome();
      return;
    }

    await _showUsageStatsInstructions();
  }

  Future<void> _showAccessibilityInstructions() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Aktifkan Layanan Aksesibilitas'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Langkah-langkah:'),
                SizedBox(height: 8.h),
                Text('1. Cari "myTask" dalam daftar layanan'),
                Text('2. Tap pada "myTask"'),
                Text('3. Aktifkan toggle "Gunakan myTask"'),
                Text('4. Tap "OK" pada dialog konfirmasi'),
                SizedBox(height: 12.h),
                Text('Setelah selesai, kembali ke aplikasi.'),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Buka Pengaturan'),
              onPressed: () async {
                Navigator.of(context).pop();
                AppLogger.info(_tag, 'Opening accessibility settings.');
                _isReturningFromPermissionSettings = true;
                // Open accessibility settings
                await PermissionService.openAccessibilitySettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUsageStatsInstructions() async {
    if (mounted) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Aktifkan Akses Statistik Penggunaan'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Langkah-langkah:'),
                  SizedBox(height: 8.h),
                  Text('1. Cari "myTask" dalam daftar aplikasi'),
                  Text('2. Tap pada "myTask"'),
                  Text(
                    '3. Aktifkan toggle "Izinkan akses statistik penggunaan"',
                  ),
                  SizedBox(height: 12.h),
                  Text('Setelah izin statistik aktif, kembali ke aplikasi.'),
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text('Buka Pengaturan'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  AppLogger.info(_tag, 'Opening usage stats settings.');
                  _isReturningFromPermissionSettings = true;
                  // Open usage stats settings
                  await PermissionService.openUsageStatsSettings();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _navigateToHome() async {
    try {
      await _todoRepository.setOnboardingCompleted(true);
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to persist onboarding completion state.',
        error: e,
        stackTrace: stackTrace,
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }
}
