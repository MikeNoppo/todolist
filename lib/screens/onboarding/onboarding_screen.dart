import 'package:flutter/material.dart';
import '../Home/home_screen.dart';
import '../../services/app_logger.dart';
import '../../services/permission_service.dart';
import 'pages/onboarding_page_1.dart';
import 'pages/onboarding_page_2.dart';
import 'pages/onboarding_page_3.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasReadPage3 = false; // Track if user has read page 3 completely

  // Define accent color - muted blue
  static const Color accentColor = Color(0xFF4A6FA5);

  @override
  void initState() {
    super.initState();
    // Add observer to listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check permissions when app resumes from background
    if (state == AppLifecycleState.resumed && _currentPage == 2) {
      _checkPermissionsAfterResume();
    }
  }

  void _checkPermissionsAfterResume() async {
    // Wait a bit for the system to update permission status
    await Future.delayed(const Duration(milliseconds: 500));
    
    bool allPermissionsGranted = await PermissionService.areAllPermissionsGranted();

    if (!mounted) return;

    if (allPermissionsGranted) {
      AppLogger.info(
        'OnboardingScreen',
        'All permissions granted after app resume.',
      );

      // Show success message and navigate to home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua izin berhasil diaktifkan!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to home after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToHome();
        }
      });
    } else {
      AppLogger.debug(
        'OnboardingScreen',
        'Permissions still incomplete after app resume.',
      );
    }
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
      padding: const EdgeInsets.all(20.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: _currentPage < 2
            ? TextButton(
                onPressed: () => _skipToEnd(),
                child: const Text(
                  'Lewati',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              )
            : const SizedBox(height: 48),
      ),
    );
  }

  Widget _buildPageView() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          const OnboardingPage1(),
          const OnboardingPage2(),
          OnboardingPage3(
            onReadComplete: () {
              setState(() {
                _hasReadPage3 = true;
              });
            },
          ),
        ],  
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          _buildPageIndicator(),
          const SizedBox(height: 32),
          _buildNavigationButton(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? accentColor
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _currentPage < 2 
            ? _nextPage 
            : (_hasReadPage3 ? _requestPermission : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: (_currentPage == 2 && !_hasReadPage3) 
              ? Colors.grey[400] 
              : accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _currentPage < 2 
              ? 'Lanjutkan' 
              : (_hasReadPage3 
                  ? 'Berikan Izin Akses' 
                  : 'Baca Hingga Selesai'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _requestPermission() async {
    // Check if all permissions are already granted
    bool allPermissionsGranted = await PermissionService.areAllPermissionsGranted();

    if (!mounted) return;
    
    if (allPermissionsGranted) {
      AppLogger.info(
        'OnboardingScreen',
        'All required permissions already granted. Navigating to home.',
      );

      // If all permissions are granted, go to home screen
      _navigateToHome();
      return;
    }

    // Check individual permissions and show appropriate dialog
    bool accessibilityEnabled = await PermissionService.isAccessibilityServiceEnabled();
    bool usageStatsGranted = await PermissionService.isUsageStatsPermissionGranted();

    if (!mounted) return;

    if (!accessibilityEnabled) {
      AppLogger.warn('OnboardingScreen', 'Accessibility permission is not enabled.');

      // Show accessibility instructions if not enabled
      await _showAccessibilityInstructions();
    } else if (!usageStatsGranted) {
      AppLogger.warn('OnboardingScreen', 'Usage stats permission is not granted.');

      // Skip accessibility and go directly to usage stats if accessibility is already enabled
      await _showUsageStatsInstructions();
    } else {
      AppLogger.info(
        'OnboardingScreen',
        'Individual permission checks passed. Navigating to home.',
      );
      _navigateToHome();
    }
  }

  Future<void> _showAccessibilityInstructions() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aktifkan Layanan Aksesibilitas'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Langkah-langkah:'),
                SizedBox(height: 8),
                Text('1. Cari "TodoList" dalam daftar layanan'),
                Text('2. Tap pada "TodoList"'),
                Text('3. Aktifkan toggle "Gunakan TodoList"'),
                Text('4. Tap "OK" pada dialog konfirmasi'),
                SizedBox(height: 12),
                Text('Setelah selesai, kembali ke aplikasi.'),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Buka Pengaturan'),
              onPressed: () async {
                Navigator.of(context).pop();
                AppLogger.info('OnboardingScreen', 'Opening accessibility settings.');
                // Open accessibility settings
                await PermissionService.openAccessibilitySettings();
                _checkPermissionsAndNavigate();
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
            title: const Text('Aktifkan Akses Statistik Penggunaan'),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Langkah-langkah:'),
                  SizedBox(height: 8),
                  Text('1. Cari "TodoList" dalam daftar aplikasi'),
                  Text('2. Tap pada "TodoList"'),
                  Text('3. Aktifkan toggle "Izinkan akses statistik penggunaan"'),
                  SizedBox(height: 12),
                  Text('Setelah kedua izin aktif, kembali ke aplikasi.'),
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('Buka Pengaturan'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  AppLogger.info('OnboardingScreen', 'Opening usage stats settings.');
                  // Open usage stats settings
                  await PermissionService.openUsageStatsSettings();
                  _checkPermissionsAndNavigate();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _checkPermissionsAndNavigate() async {
    bool allPermissionsGranted = await PermissionService.areAllPermissionsGranted();

    if (!mounted) return;
    
    if (allPermissionsGranted) {
      AppLogger.info(
        'OnboardingScreen',
        'All required permissions granted after returning from settings.',
      );
      _navigateToHome();
    } else {
      AppLogger.warn(
        'OnboardingScreen',
        'Permissions still incomplete after returning from settings.',
      );

      // Show a dialog asking user to complete the permission setup
      await _showIncompletePermissionDialog();
    }
  }

  Future<void> _showIncompletePermissionDialog() async {
    AppLogger.warn('OnboardingScreen', 'Showing incomplete permission dialog.');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Belum Lengkap'),
          content: const Text(
            'Beberapa izin belum diaktifkan. Aplikasi mungkin tidak berfungsi dengan optimal.\n\n'
            'Anda dapat mengaktifkan izin nanti melalui pengaturan aplikasi.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Coba Lagi'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermission();
              },
            ),
            ElevatedButton(
              child: const Text('Lanjutkan'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToHome();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }
}
