import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// PhoneVerificationService handles phone number verification using Firebase Auth.
class PhoneVerificationService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Observable to track verification state
  final RxBool _isVerifying = false.obs;
  bool get isVerifying => _isVerifying.value;
  
  // Initialize service
  Future<PhoneVerificationService> init() async {
    debugPrint('📱 PhoneVerificationService initialized');
    return this;
  }
  
  // Verify phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      _isVerifying.value = true;
      
      // Format phone number if needed
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      debugPrint('📱 Verifying phone number: $formattedPhone');
      
      // Start verification process
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('✅ Phone verification completed automatically');
          _isVerifying.value = false;
          onVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.message}');
          _isVerifying.value = false;
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📤 Verification code sent, ID: $verificationId');
          _isVerifying.value = false;
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏱️ Code auto retrieval timeout');
          _isVerifying.value = false;
          onCodeAutoRetrievalTimeout(verificationId);
        },
        timeout: timeout,
      );
    } catch (e) {
      _isVerifying.value = false;
      debugPrint('❌ Error during phone verification: $e');
      rethrow;
    }
  }
  
  // Link phone credential to existing user
  Future<UserCredential> linkPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      
      // Link the credential to the current user
      return await user.linkWithCredential(credential);
    } catch (e) {
      debugPrint('❌ Error linking phone credential: $e');
      rethrow;
    }
  }
  
  // Format phone number to E.164 format
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If doesn't start with +, assume it's a US number (+1)
    if (!cleaned.startsWith('+')) {
      cleaned = '+1$cleaned'; // Default to US country code, adjust as needed
    }
    
    return cleaned;
  }
  
  // Verify OTP
  Future<PhoneAuthCredential> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      return credential;
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      rethrow;
    }
  }
} 