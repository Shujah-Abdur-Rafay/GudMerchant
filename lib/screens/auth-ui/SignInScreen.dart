import 'package:gudmerchant/controllers/auth_controller.dart';
import 'package:gudmerchant/screens/auth-ui/SignUpScreen.dart';
import 'package:gudmerchant/screens/admin/admin_panel_screen.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:gudmerchant/widgets/lottie_compat.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class Signinscreen extends StatefulWidget {
  const Signinscreen({super.key});

  @override
  State<Signinscreen> createState() => _SigninscreenState();
}

class _SigninscreenState extends State<Signinscreen> with SingleTickerProviderStateMixin {
  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Password visibility
  final RxBool _passwordVisible = false.obs;
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Auth controller
  final AuthController _authController = Get.find<AuthController>();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.mediumAnimationDuration,
    );
    
    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.easeIn,
      ),
    );
    
    // Slide animation
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Start animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
      return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: AppTheme.primaryColor),
            title: const Text(
              "Sign In",
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
          centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing_xl),
                child: Form(
                  key: _formKey,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                          // Logo/Animation
                          if (!isKeyboardVisible) ...[
                            Column(
                              children: [
                                SizedBox(
                                  height: 120,
                                  child: LottieCompat(
                                    assetName: 'Assets/json/cart_animation.json',
                                    height: 120,
                                    fallbackWidget: Image.asset(
                                      'Assets/images/cart.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FadeInSlide(
                                  duration: const Duration(milliseconds: 600),
                                  offsetStart: const Offset(0, 30),
                                  child: Text(
                                    'GudMerchant',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Your trusted shopping partner',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacing_lg),
                          ],
                          
                          // Welcome message
                          Text(
                            "Welcome Back!",
                            style: TextStyle(
                              fontSize: isKeyboardVisible ? 20 : 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_sm),
                          
                          Text(
                            "Sign in to continue shopping",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_xl),
                          
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            cursorColor: AppTheme.primaryColor,
                            decoration: InputDecoration(
                              labelText: "Email",
                              hintText: "Enter your email",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              
                              // Basic format validation
                              if (!GetUtils.isEmail(value)) {
                                return 'Please enter a valid email address';
                              }
                              
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_lg),
                          
                          // Password field
                          Obx(() => TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible.value,
                            cursorColor: AppTheme.primaryColor,
                decoration: InputDecoration(
                              labelText: "Password",
                              hintText: "Enter your password",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible.value 
                                      ? Icons.visibility_outlined 
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  _passwordVisible.value = !_passwordVisible.value;
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          )),
                          
                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showForgotPasswordDialog(),
                              child: const Text("Forgot Password?"),
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_md),
                          
                          // Sign up link
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: "Sign Up",
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Get.to(
                                        () => const SignUpScreen(),
                                        transition: Transition.rightToLeft,
                                        duration: AppTheme.mediumAnimationDuration,
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_lg),
                          
                          // Sign In button
                          SizedBox(
                            width: double.infinity,
                            height: AppTheme.buttonHeight,
                            child: Obx(() => ElevatedButton(
                              onPressed: _authController.isLoading 
                                  ? null 
                                  : () => _signIn(),
                              child: _authController.isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : const Text(
                                      "SIGN IN",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            )),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_md),
                          
                          // Admin Login button
                          TextButton.icon(
                            onPressed: () => _showAdminLoginDialog(),
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text("Admin Login"),
                          ),
                        ],
                      ),
      ),
    ),
 ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Handle sign in
  void _signIn() {
    // Validate form
    if (_formKey.currentState!.validate()) {
      // Hide keyboard
      FocusScope.of(context).unfocus();
      
      debugPrint('📱 Sign-in button pressed');
      
      // Sign in
      _authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ).then((_) {
        debugPrint('✅ Sign-in function complete');
        // No need to navigate here as auth controller will handle it
      }).catchError((error) {
        debugPrint('❌ Sign-in error caught in UI: $error');
      });
    }
  }
  
  // Show forgot password dialog
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: resetFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we will send you a link to reset your password.',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: AppTheme.spacing_md),
              TextFormField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
       ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (resetFormKey.currentState!.validate()) {
                Get.back();
                _authController.resetPassword(resetEmailController.text.trim());
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
      );
  }
  
  // Show admin login dialog
  void _showAdminLoginDialog() {
    final TextEditingController adminPasswordController = TextEditingController();
    final GlobalKey<FormState> adminFormKey = GlobalKey<FormState>();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Admin Login'),
        content: Form(
          key: adminFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter admin password to access admin panel',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: AppTheme.spacing_md),
              TextFormField(
                controller: adminPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Admin Password",
                  prefixIcon: Icon(Icons.security),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter admin password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (adminFormKey.currentState!.validate()) {
                Get.back();
                // Check if password matches
                if (adminPasswordController.text == '123123') {
                  // Navigate to admin panel
                  Get.to(
                    () => const AdminPanelScreen(),
                    transition: Transition.zoom,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Invalid admin password',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

/// A widget that animates its child with a fade and slide effect
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset offsetStart;
  final Curve curve;

  const FadeInSlide({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.offsetStart = const Offset(0, 20),
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(begin: widget.offsetStart, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}