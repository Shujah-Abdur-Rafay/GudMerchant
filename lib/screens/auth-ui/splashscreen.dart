import 'dart:async';

import 'package:gudmerchant/controllers/auth_controller.dart';
import 'package:gudmerchant/screens/auth-ui/WelcomeScreen.dart';
import 'package:gudmerchant/screens/home/home_screen.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:gudmerchant/main.dart';

class SplashScreen extends StatefulWidget {
  // Static flag to prevent multiple navigation attempts during splash screen
  static bool isActive = false;

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Set the flag to true to prevent navigation from auth controller
    SplashScreen.isActive = true;

    // Initialize animations
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.longAnimationDuration,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Text animations
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animations
    _controller.forward();

    // Navigate to next screen after a fixed delay of 3 seconds
    Timer(const Duration(seconds: 3), () {
      navigateToNextScreen();
    });
  }

  void navigateToNextScreen() {
    try {
      // Set the flag to false as we're now handling navigation
      SplashScreen.isActive = false;

      // Get the auth controller to check if user is logged in
      final AuthController authController;
      try {
        authController = Get.find<AuthController>();
        debugPrint('✅ Found AuthController instance');
      } catch (e) {
        debugPrint('❌ Error finding AuthController: $e');
        // If we can't find the auth controller, navigate to welcome screen
        Get.offAll(
          () => WelcomeScreen(),
          transition: Transition.fadeIn,
          duration: AppTheme.mediumAnimationDuration,
        );
        return;
      }

      // Debug: Print auth state
      debugPrint('🔍 Auth Check: isLoggedIn = ${authController.isLoggedIn}');
      if (authController.firebaseUser != null) {
        debugPrint('👤 User ID: ${authController.firebaseUser?.uid}');
        debugPrint('📧 User Email: ${authController.firebaseUser?.email}');
      }

      // Check if we should force the welcome screen
      if (FORCE_WELCOME_SCREEN) {
        debugPrint('🔑 Forcing welcome screen (login bypass disabled)');
        Get.offAll(
          () => WelcomeScreen(),
          transition: Transition.fadeIn,
          duration: AppTheme.mediumAnimationDuration,
        );
        return;
      }

      if (authController.isLoggedIn) {
        Get.offAll(
          () => HomeScreen(),
          transition: Transition.fadeIn,
          duration: AppTheme.mediumAnimationDuration,
        );
      } else {
        Get.offAll(
          () => WelcomeScreen(),
          transition: Transition.fadeIn,
          duration: AppTheme.mediumAnimationDuration,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error during navigation: $e');
      debugPrint('Stack trace: $stackTrace');

      // Show error dialog and fallback to WelcomeScreen
      try {
        Get.dialog(
          AlertDialog(
            title: Text('Navigation Error'),
            content: Text('An error occurred: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.offAll(
                    () => WelcomeScreen(),
                    transition: Transition.fadeIn,
                  );
                },
                child: Text('Go to Welcome Screen'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      } catch (_) {
        // If dialog fails, try to navigate directly
        Get.offAll(
          () => WelcomeScreen(),
          transition: Transition.fadeIn,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final logoSize = screenSize.width * 0.4; // Adjusted from 0.6 to 0.4

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryDarkColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenSize.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacing_md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Debug message for black screen issues
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: Text(
                        'App is starting...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.15),

                    // Logo animation
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacityAnimation.value,
                          child: Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        padding: const EdgeInsets.all(AppTheme.spacing_md),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          size: logoSize * 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacing_xl),

                    // App name animation
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: child,
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            'GudMerchant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing_sm),
                          Text(
                            'Your one-stop shopping destination',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.2),

                    // Bottom text
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: child,
                        );
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTheme.spacing_lg),
                        child: Text(
                          'Powered by GudMerchant',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
