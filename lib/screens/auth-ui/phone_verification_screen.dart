import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:gudmerchant/controllers/auth_controller.dart';
import 'package:gudmerchant/services/phone_verification_service.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:gudmerchant/widgets/lottie_compat.dart';
import 'package:gudmerchant/widgets/otp_input_field.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phone;
  final String email;
  final String password;
  final String username;

  const PhoneVerificationScreen({
    Key? key,
    required this.phone,
    required this.email,
    required this.password,
    required this.username,
  }) : super(key: key);

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // OTP verification
  final RxString _otp = ''.obs;
  final RxString _verificationId = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isResending = false.obs;
  final RxInt _resendTimer = 60.obs;
  final RxBool _isCodeSent = false.obs;

  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PhoneVerificationService _phoneService = Get.find<PhoneVerificationService>();
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

    // Send OTP immediately
    _sendOTP();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Send OTP to user's phone
  Future<void> _sendOTP() async {
    if (_isLoading.value || _isResending.value) return;
    
    try {
      _isResending.value = true;
      
      final formattedPhone = _formatPhoneNumber(widget.phone);
      debugPrint('📱 Sending OTP to: $formattedPhone');
      
      await _phoneService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        onVerificationCompleted: _onVerificationCompleted,
        onVerificationFailed: _onVerificationFailed,
        onCodeSent: _onCodeSent,
        onCodeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      Get.snackbar(
        'Error',
        'Failed to send verification code. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isResending.value = false;
    }
  }

  // Format phone number to E.164 format
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If doesn't start with +, assume it's local and prepend country code
    if (!cleaned.startsWith('+')) {
      cleaned = '+${cleaned}'; // Add your default country code here
    }
    
    return cleaned;
  }

  // Verification completed automatically (usually on Android)
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    debugPrint('✅ Verification completed automatically!');
    _isLoading.value = true;
    
    try {
      await _completeSignUp(credential);
    } catch (e) {
      debugPrint('❌ Error completing auto verification: $e');
      _isLoading.value = false;
      
      Get.snackbar(
        'Error',
        'Automatic verification failed. Please enter the code manually.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Verification failed
  void _onVerificationFailed(FirebaseAuthException error) {
    debugPrint('❌ Verification failed: ${error.message}');
    _isResending.value = false;
    
    Get.snackbar(
      'Verification Failed',
      error.message ?? 'Failed to verify phone number',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Code sent to the user's phone
  void _onCodeSent(String verificationId, int? resendToken) {
    debugPrint('📱 Verification code sent! ID: $verificationId');
    _verificationId.value = verificationId;
    _isCodeSent.value = true;
    _isResending.value = false;
    
    // Start countdown timer for resend button
    _startResendTimer();
    
    Get.snackbar(
      'Code Sent',
      'Verification code has been sent to your phone',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Code auto retrieval timeout
  void _onCodeAutoRetrievalTimeout(String verificationId) {
    debugPrint('⏱️ Auto retrieval timeout');
    _verificationId.value = verificationId;
  }

  // Start resend timer countdown
  void _startResendTimer() {
    _resendTimer.value = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      _resendTimer.value--;
      return _resendTimer.value > 0;
    });
  }

  // Verify entered OTP
  Future<void> _verifyOTP() async {
    if (_isLoading.value || _otp.value.length != 6) return;
    
    _isLoading.value = true;
    
    try {
      debugPrint('🔐 Verifying OTP: ${_otp.value}, verification ID: ${_verificationId.value}');
      
      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId.value,
        smsCode: _otp.value,
      );
      
      await _completeSignUp(credential);
    } catch (e) {
      debugPrint('❌ OTP verification error: $e');
      _isLoading.value = false;
      
      Get.snackbar(
        'Verification Failed',
        'Invalid verification code. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Complete sign up after phone verification
  Future<void> _completeSignUp(PhoneAuthCredential phoneCredential) async {
    try {
      // Now complete the signup with email/password
      await _authController.signUpWithPhoneVerification(
        email: widget.email,
        password: widget.password,
        username: widget.username,
        phone: widget.phone,
        phoneCredential: phoneCredential,
      );
      
      _isLoading.value = false;
    } catch (e) {
      debugPrint('❌ Error completing signup: $e');
      _isLoading.value = false;
      
      Get.snackbar(
        'Signup Failed',
        'Unable to complete signup. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
              "Verify Your Phone",
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing_xl),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animation
                        if (!isKeyboardVisible) ...[
                          SizedBox(
                            height: 120,
                            child: Icon(
                              Icons.phone_android,
                              size: 80,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing_md),
                        ],
                        
                        // Title
                        Text(
                          "Verify Your Phone",
                          style: TextStyle(
                            fontSize: isKeyboardVisible ? 20 : 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacing_sm),
                        
                        // Description
                        Text(
                          "We've sent a 6-digit code to ${widget.phone}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacing_xl),
                        
                        // OTP Input Fields
                        OtpInputField(
                          onOtpEntered: (otp) {
                            _otp.value = otp;
                            if (otp.length == 6) {
                              _verifyOTP();
                            }
                          },
                        ),
                        
                        const SizedBox(height: AppTheme.spacing_xl),
                        
                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          height: AppTheme.buttonHeight,
                          child: Obx(() => ElevatedButton(
                            onPressed: _isLoading.value ? null : _verifyOTP,
                            child: _isLoading.value
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : const Text(
                                    "VERIFY",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          )),
                        ),
                        
                        const SizedBox(height: AppTheme.spacing_xl),
                        
                        // Resend code
                        Obx(() => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't receive the code? ",
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            if (_resendTimer.value > 0) ...[
                              Text(
                                "Resend in ${_resendTimer.value}s",
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else ...[
                              GestureDetector(
                                onTap: _isResending.value ? null : _sendOTP,
                                child: Text(
                                  _isResending.value ? "Sending..." : "Resend",
                                  style: TextStyle(
                                    color: _isResending.value
                                        ? AppTheme.primaryColor.withOpacity(0.5)
                                        : AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )),
                      ],
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