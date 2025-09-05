import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _progressAnimation;

  bool _isInitialized = false;
  String _loadingText = "Initializing emergency services...";

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Progress animation controller
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _logoAnimationController.forward();
    _progressAnimationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Set system UI overlay style for emergency theme
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: AppTheme.primaryLight,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppTheme.primaryLight,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      // Simulate initialization tasks
      await _performInitializationTasks();

      // Navigate to appropriate screen after initialization
      if (mounted) {
        await _navigateToNextScreen();
      }
    } catch (e) {
      // Handle initialization errors gracefully
      if (mounted) {
        setState(() {
          _loadingText = "Preparing emergency services...";
        });
        await Future.delayed(const Duration(milliseconds: 1000));
        await _navigateToNextScreen();
      }
    }
  }

  Future<void> _performInitializationTasks() async {
    final tasks = [
      _checkAuthenticationStatus(),
      _loadCachedDisasterAlerts(),
      _prepareOfflineMaps(),
      _initializeEmergencyServices(),
      _checkLocationPermissions(),
    ];

    for (int i = 0; i < tasks.length; i++) {
      await tasks[i];
      if (mounted) {
        setState(() {
          _loadingText = _getLoadingTextForTask(i);
        });
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }

    setState(() {
      _isInitialized = true;
    });
  }

  String _getLoadingTextForTask(int taskIndex) {
    switch (taskIndex) {
      case 0:
        return "Checking authentication...";
      case 1:
        return "Loading disaster alerts...";
      case 2:
        return "Preparing offline maps...";
      case 3:
        return "Initializing emergency services...";
      case 4:
        return "Setting up location services...";
      default:
        return "Finalizing setup...";
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    // Simulate checking authentication status
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadCachedDisasterAlerts() async {
    // Simulate loading cached disaster alerts
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _prepareOfflineMaps() async {
    // Simulate preparing offline maps
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _initializeEmergencyServices() async {
    // Simulate initializing emergency services
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _checkLocationPermissions() async {
    // Simulate checking location permissions
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // For demo purposes, navigate to home dashboard
      // In real implementation, this would check authentication status
      Navigator.pushReplacementNamed(context, '/home-dashboard-screen');
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryLight,
              AppTheme.primaryVariantLight,
              AppTheme.primaryLight.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo section
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Opacity(
                          opacity: _logoOpacityAnimation.value,
                          child: _buildLogo(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Loading section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress indicator
                    Container(
                      width: 60.w,
                      height: 0.5.h,
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      decoration: BoxDecoration(
                        color: AppTheme.onPrimaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 60.w * _progressAnimation.value,
                              height: 0.5.h,
                              decoration: BoxDecoration(
                                color: AppTheme.onPrimaryLight,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Loading text
                    Text(
                      _loadingText,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onPrimaryLight,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 1.h),

                    // Version info
                    Text(
                      "HackNova Aid v1.0.0",
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.onPrimaryLight.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emergency shield icon with custom styling
        Container(
          width: 25.w,
          height: 25.w,
          decoration: BoxDecoration(
            color: AppTheme.onPrimaryLight,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'shield',
              color: AppTheme.primaryLight,
              size: 12.w,
            ),
          ),
        ),

        SizedBox(height: 4.h),

        // App name
        Text(
          "HackNova Aid",
          style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
            color: AppTheme.onPrimaryLight,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 1.h),

        // Tagline
        Text(
          "Emergency Response & Disaster Management",
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.onPrimaryLight.withValues(alpha: 0.9),
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 0.5.h),

        // Emergency indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: AppTheme.onPrimaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.onPrimaryLight.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'emergency',
                color: AppTheme.onPrimaryLight,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                "OFFLINE READY",
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.onPrimaryLight,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
