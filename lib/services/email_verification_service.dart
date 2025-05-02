import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

/// Service for handling email verification processes
class EmailVerificationService extends GetxService {
  final RxBool _isVerifying = false.obs;
  final storage = GetStorage();
  
  // Debug options
  final bool _debugMode = true; // Set to true to show OTPs in console
  final bool _forceTestMode = true; // Set to true to proceed even if email fails

  // SMTP Configuration
  final String _smtpUsername = 'GudMerchant@cuitd.pk'; // Elastic Email username
  final String _smtpPassword = '9F0CDEF433D5D4EBA26DC177225B5F877A1B'; // Elastic Email password
  final String _smtpServer = 'smtp.elasticemail.com'; // Elastic Email server
  final int _smtpPort = 2525; // Elastic Email port
  final String _accountId = '376d6ee3-5bac-4be4-9af6-5f55b546f8a5'; // Account identifier

  bool get isVerifying => _isVerifying.value;
  bool get forceTestMode => _forceTestMode;

  Future<EmailVerificationService> init() async {
    debugPrint('✉️ EmailVerificationService initialized');
    
    // Ensure storage is initialized
    await GetStorage.init();
    
    return this;
  }

  // Generate a 6-digit OTP
  String _generateOTP() {
    final random = Random();
    final otp = List.generate(6, (_) => random.nextInt(10)).join();
    
    if (_debugMode) {
      final now = DateFormat('HH:mm:ss').format(DateTime.now());
      debugPrint('\n\n=================================================');
      debugPrint('🔑 [TEST MODE - $now] GENERATED OTP: $otp');
      debugPrint('=================================================\n\n');
    }
    
    return otp;
  }

  // Send verification code
  Future<bool> sendVerificationCode(String email) async {
    _isVerifying.value = true;
    
    try {
      final otp = _generateOTP();
      
      // Save OTP with email for verification
      _saveOTP(email, otp);
      
      // Send OTP via email
      final sent = await _sendOTPEmail(email, otp);
      
      // In test mode, we return true even if email sending fails
      return sent || _forceTestMode;
    } catch (e) {
      debugPrint('❌ Error sending verification code: $e');
      return _forceTestMode; // Return true in test mode even if there's an error
    } finally {
      _isVerifying.value = false;
    }
  }

  // Send OTP email using SMTP
  Future<bool> _sendOTPEmail(String email, String otp) async {
    try {
      // Configure SMTP server for Elastic Email
      final smtpServer = SmtpServer(
        _smtpServer,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: true,
        ignoreBadCertificate: true,
      );
      
      // Create email message
      final message = Message()
        ..from = Address(_smtpUsername, 'GudMerchant Support')
        ..recipients.add(email)
        ..subject = 'Your GudMerchant Verification Code'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
            <h2 style="color: #4a86e8;">GudMerchant Verification</h2>
            <p>Hello,</p>
            <p>Your verification code is:</p>
            <div style="background-color: #f5f5f5; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
              $otp
            </div>
            <p>This code will expire in 10 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
            <p>Thanks,<br>The GudMerchant Team</p>
            <p style="font-size: 12px; color: #999; margin-top: 20px;">Sent via Elastic Email</p>
          </div>
        ''';
      
      // Send the message
      debugPrint('📧 Sending verification email to: $email');
      
      final sendReport = await send(message, smtpServer);
      
      debugPrint('✅ Message sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending verification email: $e');
      
      // Always display OTP in console for testing
      debugPrint('📱 OTP for testing: $otp');
      
      // Show more detailed error
      print('Email Error Details: ${e.toString()}');
      
      // Return false to indicate failure in production
      return false;
    }
  }

  // Save OTP in storage for verification
  void _saveOTP(String email, String otp) {
    // Generate a key based on the email
    final key = 'otp_${email.toLowerCase()}';
    
    // Save OTP and expiration time (10 minutes)
    final expiry = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch;
    storage.write(key, {
      'otp': otp,
      'expiry': expiry,
    });
    
    debugPrint('💾 OTP saved for email: $email');
  }

  // Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final key = 'otp_${email.toLowerCase()}';
      final data = storage.read(key);
      
      if (data == null) {
        debugPrint('❌ No OTP found for email: $email');
        return false;
      }
      
      final savedOTP = data['otp'];
      final expiry = data['expiry'];
      
      // Check if OTP matches and is not expired
      final isValid = savedOTP == otp && 
          DateTime.now().millisecondsSinceEpoch < expiry;
      
      if (isValid) {
        // Mark email as verified
        await _markEmailAsVerified(email);
        debugPrint('✅ OTP verified for email: $email');
      } else {
        debugPrint('❌ Invalid or expired OTP for email: $email');
      }
      
      return isValid;
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      return false;
    }
  }

  // Mark email as verified
  Future<void> _markEmailAsVerified(String email) async {
    final key = 'verified_${email.toLowerCase()}';
    storage.write(key, true);
  }

  // Check if email is verified
  Future<bool> isEmailVerified(String email) async {
    final key = 'verified_${email.toLowerCase()}';
    return storage.read(key) == true;
  }

  // Clear verification data for email
  Future<void> clearVerificationData(String email) async {
    final otpKey = 'otp_${email.toLowerCase()}';
    final verifiedKey = 'verified_${email.toLowerCase()}';
    
    storage.remove(otpKey);
    storage.remove(verifiedKey);
    
    debugPrint('🧹 Verification data cleared for email: $email');
  }
} 