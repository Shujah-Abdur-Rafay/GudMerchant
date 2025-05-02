import 'package:gudmerchant/controllers/auth_controller.dart';
import 'package:gudmerchant/screens/auth-ui/SignInScreen.dart';
import 'package:gudmerchant/screens/auth-ui/email_input_screen.dart';
import 'package:gudmerchant/screens/auth-ui/phone_verification_screen.dart';
import 'package:gudmerchant/services/email_verification_service.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:gudmerchant/widgets/lottie_compat.dart';
import 'package:gudmerchant/widgets/otp_input_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class SignUpScreen extends StatefulWidget {
  final String? verifiedEmail;
  final String? initialUsername;
  final String? initialPhone;
  final String? initialPassword;
  
  const SignUpScreen({
    Key? key, 
    this.verifiedEmail,
    this.initialUsername,
    this.initialPhone,
    this.initialPassword,
  }) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  // Form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  // Password visibility
  final RxBool _passwordVisible = false.obs;
  
  // OTP verification states
  final RxBool _isVerifying = false.obs;
  final RxBool _showOtpInput = false.obs;
  final RxBool _isEmailVerified = false.obs;
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Controllers
  final AuthController _authController = Get.find<AuthController>();
  final EmailVerificationService _verificationService = Get.find<EmailVerificationService>();
  
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
    
    // Set verified email
    if (widget.verifiedEmail != null) {
      _emailController.text = widget.verifiedEmail!;
      _isEmailVerified.value = true;
    }
    
    // Set preserved form data if available
    if (widget.initialUsername != null) {
      _usernameController.text = widget.initialUsername!;
    }
    
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
    
    if (widget.initialPassword != null) {
      _passwordController.text = widget.initialPassword!;
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Send OTP method
  Future<void> _sendOTP() async {
    if (!_validateEmail()) {
      return;
    }
    
    final email = _emailController.text.trim();
    
    _isVerifying.value = true;
    
    try {
      final success = await _verificationService.sendVerificationCode(email);
      
      _showOtpInput.value = true;
      
      if (success) {
        Get.snackbar(
          'OTP Sent',
          'Please check your email for verification code',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryColor,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Email Sending Failed',
          'Check console for OTP code. Using test mode.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 7),
        );
      }
      
      // Add debug information
      debugPrint('📧 OTP sent for email: $email. Check console for code.');
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 7),
      );
    } finally {
      _isVerifying.value = false;
    }
  }
  
  // Verify OTP method
  Future<void> _verifyOTP(String otp) async {
    if (otp.length != 6) {
      return;
    }
    
    _isVerifying.value = true;
    
    try {
      final email = _emailController.text.trim();
      final isVerified = await _verificationService.verifyOTP(email, otp);
      
      if (isVerified) {
        _isEmailVerified.value = true;
        _showOtpInput.value = false;
        
        Get.snackbar(
          'Verification Successful',
          'Your email has been verified',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Verification Failed',
          'Invalid or expired code. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isVerifying.value = false;
    }
  }
  
  // Validate email
  bool _validateEmail() {
    if (_emailController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    
    if (!GetUtils.isEmail(_emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    
    return true;
  }

  // Sign up method
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    
    // Check if email is verified
    if (!_isEmailVerified.value) {
      Get.snackbar(
        'Email Verification Required',
        'Please verify your email by entering the OTP code sent to your inbox',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
        duration: Duration(seconds: 5),
        margin: EdgeInsets.all(10),
        borderRadius: 10,
        isDismissible: true,
        forwardAnimationCurve: Curves.easeOutBack,
      );
      
      // Show OTP input if not already showing
      if (!_showOtpInput.value) {
        _sendOTP();
      }
      return;
    }
    
    // Directly sign up with email/password - skip phone verification
    await _authController.signUpWithEmailAndPassword(
      email: email,
      password: password,
      username: username,
      phone: phone,
    );
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
              "Create Account",
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
                            SizedBox(
                              height: 120,
                              child: Icon(
                                Icons.shopping_cart,
                                size: 80,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing_md),
                          ],
                          
                          // Welcome message
                          Text(
                            "Join GudMerchant",
                            style: TextStyle(
                              fontSize: isKeyboardVisible ? 20 : 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_sm),
                          
                          Text(
                            "Create an account to start shopping",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_xl),
                          
                          // Username field
                          TextFormField(
                            controller: _usernameController,
                            cursorColor: AppTheme.primaryColor,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                              labelText: "Full Name",
                              hintText: "Enter your full name",
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              
                              // Name validation - check for minimum length
                              if (value.trim().length < 3) {
                                return 'Name must be at least 3 characters';
                              }
                              
                              // Check for valid name format (letters and spaces only)
                              if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                                return 'Name should contain only letters and spaces';
                              }
                              
                              return null;
                            },
                            onChanged: (value) {
                              // Force validation on each change
                              _formKey.currentState?.validate();
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_md),
                          
                          // Email field with verify button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  cursorColor: AppTheme.primaryColor,
                                  readOnly: _isEmailVerified.value, // Make readonly if verified
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    hintText: "Enter your email",
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                    ),
                                    suffixIcon: Obx(() => _isEmailVerified.value
                                        ? const Icon(Icons.verified, color: Colors.green)
                                        : const SizedBox.shrink()),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    
                                    // Email format validation
                                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                    if (!emailRegex.hasMatch(value)) {
                                      return 'Please enter a valid email address';
                                    }
                                    
                                    return null;
                                  },
                                ),
                              ),
                              if (!_isEmailVerified.value && !_showOtpInput.value) ...[
                                const SizedBox(width: 8),
                                Obx(() => ElevatedButton(
                                  onPressed: _isVerifying.value ? null : _sendOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                    ),
                                  ),
                                  child: _isVerifying.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.0,
                                          ),
                                        )
                                      : const Text(
                                          "Verify",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                )),
                              ],
                            ],
                          ),
                          
                          // OTP Input Section
                          Obx(() => _showOtpInput.value
                            ? Container(
                                margin: EdgeInsets.symmetric(vertical: 15),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Enter Verification Code',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'We sent a 6-digit code to your email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red[200]!),
                                      ),
                                      child: Text(
                                        'Check console/logs for testing code',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    OtpInputField(
                                      onOtpEntered: _verifyOTP,
                                    ),
                                    const SizedBox(height: 5),
                                    TextButton.icon(
                                      onPressed: _isVerifying.value ? null : _sendOTP,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Resend Code"),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink()
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_md),
                          
                          // Phone field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            cursorColor: AppTheme.primaryColor,
                            decoration: InputDecoration(
                              labelText: "Phone (Optional)",
                              hintText: "Enter your phone number (optional)",
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null; // Phone is now optional
                              }
                              
                              // Phone number validation - check for valid format
                              if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
                                return 'Please enter a valid phone number';
                              }
                              
                              return null;
                            },
                            onChanged: (value) {
                              // Force validation on each change
                              _formKey.currentState?.validate();
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_md),
                          
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
                                return 'Please enter a password';
                              }
                              
                              // Password validation
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              
                              // Check for a mix of characters
                              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]+$').hasMatch(value)) {
                                return 'Password must include letters and numbers';
                              }
                              
                              return null;
                            },
                            onChanged: (value) {
                              // Force validation on each change
                              _formKey.currentState?.validate();
                            },
                          )),
                          
                          const SizedBox(height: AppTheme.spacing_xl),
                          
                          // Sign up button
                          SizedBox(
                            width: double.infinity,
                            child: Obx(() => ElevatedButton(
                              onPressed: _authController.isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: _isEmailVerified.value ? AppTheme.primaryColor : Colors.grey[400],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                ),
                              ),
                              child: _authController.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Sign Up",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (!_isEmailVerified.value) ...[
                                          SizedBox(width: 8),
                                          Icon(Icons.error_outline, size: 18)
                                        ]
                                      ],
                                    ),
                            )),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_md),
                          
                          // Sign in link
                          RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                              children: [
                                TextSpan(
                                  text: "Sign In",
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Get.to(() => const Signinscreen());
                                    },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing_xl),
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
}