import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../../models/todo_model.dart';
import '../../repositories/todo_repository.dart';
import '../../services/app_logger.dart';
import 'intervention_icons.dart';

class InterventionScreen extends StatefulWidget {
  final String blockedAppName;
  final String? currentHighPriorityTask;

  const InterventionScreen({
    super.key,
    required this.blockedAppName,
    this.currentHighPriorityTask,
  });

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen>
    with SingleTickerProviderStateMixin {
  static const String _tag = 'InterventionScreen';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final TodoRepository _todoRepository = TodoRepository();
  String? _urgentTask;

  // List of motivational quotes
  final List<Map<String, String>> _quotes = [
    {
      'text': 'Penundaan adalah pembunuh alami kesempatan.',
      'author': 'Victor Kiam',
    },
    {
      'text': 'Fokus adalah kekuatan super rahasia untuk mencapai kesuksesan.',
      'author': 'Unknown',
    },
    {
      'text':
          'Produktivitas bukan tentang waktu yang Anda habiskan, tetapi tentang perhatian yang Anda berikan.',
      'author': 'Unknown',
    },
    {
      'text': 'Distraksi adalah musuh terbesar dari pencapaian.',
      'author': 'Unknown',
    },
    {
      'text':
          'Setiap detik yang Anda fokus adalah investasi untuk masa depan yang lebih baik.',
      'author': 'Unknown',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _urgentTask = widget.currentHighPriorityTask;
    if (_urgentTask == null || _urgentTask!.isEmpty) {
      _loadUrgentTask();
    }
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  Future<void> _loadUrgentTask() async {
    try {
      final todos = await _todoRepository.getTodos();
      final urgentTodos = todos
          .where(
            (todo) => !todo.isCompleted && todo.priority == TodoPriority.high,
          )
          .toList();

      if (urgentTodos.isNotEmpty) {
        // Sort by deadline to get the most urgent
        urgentTodos.sort((a, b) => a.deadline.compareTo(b.deadline));

        AppLogger.debug(
          _tag,
          'Loaded ${urgentTodos.length} high-priority incomplete task(s).',
        );

        if (!mounted) return;
        setState(() {
          _urgentTask = urgentTodos.first.title;
        });
      } else {
        AppLogger.info(_tag, 'No high-priority incomplete tasks found.');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to load urgent task.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, String> _getRandomQuote() {
    final random = DateTime.now().millisecondsSinceEpoch % _quotes.length;
    return _quotes[random];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quote = _getRandomQuote();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark grey background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Main Icon with Animation
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          InterventionIcons.getIconForApp(
                            widget.blockedAppName.toLowerCase(),
                          ),
                          size: 60.sp,
                          color: Colors.white70,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 48.h),

                // Motivational Quote with Fade Animation
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          // Quote Text
                          Text(
                            '"${quote['text']}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia', // Serif font for elegance
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 1.5,
                              letterSpacing: 0.5.sp,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Quote Author
                          Text(
                            '— ${quote['author']}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 40.h),

                // Task Reminder
                if (_urgentTask != null) ...[
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4A6FA5,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: const Color(
                                0xFF4A6FA5,
                              ).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Tugas mendesak saat ini:',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                _urgentTask!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A6FA5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 32.h),
                ],

                const Spacer(flex: 3),

                // Back to Work Button
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: GestureDetector(
                        onTap: _handleBackToWork,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.w,
                            vertical: 16.h,
                          ),
                          child: Text(
                            'Kembali Bekerja',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.5.sp,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 20.h),

                // Blocked App Info
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.6,
                      child: Text(
                        'Akses ke ${widget.blockedAppName} diblokir',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBackToWork() {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    // Close the intervention screen
    Navigator.of(context).pop();

    // Optional: Navigate to home screen or task list
    // You can customize this behavior based on your app's navigation structure
  }
}
