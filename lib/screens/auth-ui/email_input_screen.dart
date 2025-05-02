import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gudmerchant/screens/auth-ui/signupScreen.dart';
import 'package:gudmerchant/services/email_verification_service.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:gudmerchant/widgets/lottie_compat.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:gudmerchant/widgets/otp_input_field.dart';

class EmailInputScreen extends StatefulWidget {
  final String? initialUsername;
  final String? initialPhone;
  final String? initialPassword;
  
  const EmailInputScreen({
    Key? key, 
    this.initialUsername,
    this.initialPhone,
    this.initialPassword,
  }) : super(key: key);

  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final EmailVerificationService _verificationService = Get.find<EmailVerificationService>();
  
  final RxBool _isLoading = false.obs;
  final RxBool _otpSent = false.obs;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.mediumAnimationDuration,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
    
    // Check if we already have an email from previous screen
    if (widget.initialUsername != null) {
      // If we have preserved data, automatically show OTP input
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_emailController.text.isNotEmpty) {
          _sendOTP();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final email = _emailController.text.trim();
    
    _isLoading.value = true;
    
    try {
      final success = await _verificationService.sendVerificationCode(email);
      
      // Set otpSent to true regardless of email sending success
      // This ensures we show the OTP input boxes
      _otpSent.value = true;
      
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
      
      // Add some debug information about UI state
      debugPrint('✅ OTP sent, showing input boxes. _otpSent = ${_otpSent.value}');
      
    } catch (e) {
      // Even on error, we'll show OTP input for testing
      _otpSent.value = true;
      
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 7),
      );
      
      debugPrint('❌ Error sending OTP, but still showing input boxes: $e');
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate() || _otpController.text.length != 6) {
      return;
    }
    
    _isLoading.value = true;
    
    try {
      final email = _emailController.text.trim();
      final otp = _otpController.text;
      
      final isVerified = await _verificationService.verifyOTP(email, otp);
      
      if (isVerified) {
        Get.snackbar(
          'Success',
          'Email verified successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        // Navigate to signup screen with verified email
        Get.off(() => SignUpScreen(
          verifiedEmail: email,
          initialUsername: widget.initialUsername,
          initialPhone: widget.initialPhone,
          initialPassword: widget.initialPassword,
        ));
      } else {
        Get.snackbar(
          'Verification Failed',
          'Invalid or expired verification code',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        title: const Text(
          "Email Verification",
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animation (using alternative fallback since asset is missing)
                  SizedBox(
                    height: 120,
                    child: Icon(
                      Icons.email_outlined,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacing_md),
                  
                  // Title
                  Obx(() => Text(
                    _otpSent.value ? "Enter Verification Code" : "Verify Your Email",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  )),
                  
                  const SizedBox(height: AppTheme.spacing_sm),
                  
                  // Subtitle
                  Obx(() => Text(
                    _otpSent.value 
                        ? "Please enter the code we sent to your email"
                        : "We need to verify your email before you can create an account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  )),
                  
                  const SizedBox(height: AppTheme.spacing_xl),
                  
                  // Email field (only shown if OTP not sent)
                  Obx(() => !_otpSent.value 
                    ? TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_otpSent.value,
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
                          if (!GetUtils.isEmail(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      )
                    : const SizedBox.shrink()
                  ),
                  
                  const SizedBox(height: AppTheme.spacing_md),
                  
                  // Replace the OTP field with OtpInputField when _otpSent is true
                  Obx(() => _otpSent.value 
                    ? Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              'Enter Verification Code',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'We sent a 6-digit code to your email.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.all(8),
                              margin: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'TESTING MODE',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Check console/debug output for OTP code',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            OtpInputField(
                              onOtpEntered: (otp) {
                                _otpController.text = otp;
                                if (otp.length == 6) {
                                  _verifyOTP();
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()
                  ),
                  
                  // Send OTP or Verify OTP button
                  SizedBox(
                    width: double.infinity,
                    height: AppTheme.buttonHeight,
                    child: Obx(() => ElevatedButton(
                      onPressed: _isLoading.value 
                          ? null 
                          : (_otpSent.value ? _verifyOTP : _sendOTP),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                        ),
                      ),
                      child: _isLoading.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : Text(
                              _otpSent.value ? "VERIFY CODE" : "SEND VERIFICATION CODE",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    )),
                  ),
                  
                  const SizedBox(height: AppTheme.spacing_md),
                  
                  // Resend OTP button (conditional rendering)
                  Obx(() => _otpSent.value
                    ? TextButton.icon(
                        onPressed: _isLoading.value ? null : _sendOTP,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Resend Code"),
                      )
                    : const SizedBox.shrink()
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 