import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding/onboarding_screen.dart';
import 'Home/home_screen.dart';
import '../repositories/todo_repository.dart';
import '../services/app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'SplashScreen';

  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _iconScaleAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _progressAnimation;

  final TodoRepository _todoRepository = TodoRepository();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Icon animation controller
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Icon animations
    _iconScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    // Text animations
    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Progress animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSplashSequence() async {
    // Vibrate device for feedback
    HapticFeedback.lightImpact();

    // Start icon animation
    _iconController.forward();

    // Wait a bit, then start text animation
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // Start progress animation
    await Future.delayed(const Duration(milliseconds: 200));
    _progressController.forward();

    // Check if user has completed onboarding
    await Future.delayed(const Duration(milliseconds: 1500));
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    try {
      // Check if user has saved their name (indicator of completed onboarding)
      final userName = await _todoRepository.getUserName();
      final hasCompletedOnboarding = userName != null && userName.isNotEmpty;

      AppLogger.info(
        _tag,
        hasCompletedOnboarding
            ? 'Onboarding complete, navigating to home.'
            : 'Onboarding incomplete, navigating to onboarding.',
      );

      if (mounted) {
        if (hasCompletedOnboarding) {
          _navigateToHome();
        } else {
          _navigateToOnboarding();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to check first launch state; falling back to onboarding.',
        error: e,
        stackTrace: stackTrace,
      );

      // On error, go to onboarding to be safe
      if (mounted) {
        _navigateToOnboarding();
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToOnboarding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon with animations
                  AnimatedBuilder(
                    animation: _iconController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _iconScaleAnimation.value,
                        child: Container(
                          width: screenWidth * 0.25,
                          height: screenWidth * 0.25,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4A6FA5,
                                ).withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/icon/appIcon.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback icon if image not found
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A6FA5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.assignment_outlined,
                                    size: screenWidth * 0.12,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.06),

                  // App title with animations
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Opacity(
                          opacity: _textFadeAnimation.value,
                          child: Column(
                            children: [
                              // App name
                              Text(
                                'myTask',
                                style: TextStyle(
                                  fontSize: screenHeight * 0.045,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.black87,
                                  letterSpacing: 1.2,
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.015),

                              // Tagline
                              Text(
                                'Fokus. Produktif. Terlindungi.',
                                style: TextStyle(
                                  fontSize: screenHeight * 0.018,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF4A6FA5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.08),

                  // Loading progress indicator
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _progressAnimation.value,
                        child: SizedBox(
                          width: screenWidth * 0.3,
                          child: Column(
                            children: [
                              // Progress bar
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progressAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A6FA5),
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              // Loading text
                              Text(
                                'Menyiapkan aplikasi...',
                                style: TextStyle(
                                  fontSize: screenHeight * 0.016,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Version info at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFadeAnimation.value * 0.7,
                    child: Center(
                      child: Text(
                        'Versi 1.0.0',
                        style: TextStyle(
                          fontSize: screenHeight * 0.014,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
