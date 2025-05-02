import 'package:gudmerchant/models/usermodel.dart';
import 'package:gudmerchant/screens/auth-ui/SignInScreen.dart';
import 'package:gudmerchant/screens/auth-ui/WelcomeScreen.dart';
import 'package:gudmerchant/screens/home/home_screen.dart';
import 'package:gudmerchant/screens/auth-ui/splashscreen.dart';
import 'package:gudmerchant/services/admin_notification_service.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

/// AuthController handles all authentication-related operations and user state
/// It uses GetX for state management and Firebase for authentication
class AuthController extends GetxController {
  // Services
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminNotificationService _adminService = AdminNotificationService();
  
  // Observable state variables
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  
  // Getters
  User? get firebaseUser => _firebaseUser.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoggedIn => firebaseUser != null;
  bool get isLoading => _isLoading.value;
  
  @override
  void onInit() {
    super.onInit();
    // Bind to Firebase auth state changes
    _firebaseUser.bindStream(_auth.authStateChanges());
    // React to user changes
    ever(_firebaseUser, _handleAuthStateChanges);
  }
  
  /// Handles authentication state changes and redirects user accordingly
  Future<void> _handleAuthStateChanges(User? user) async {
    debugPrint('🔄 Auth state changed: ${user?.uid ?? 'logged out'}');
    
    // Skip navigation if splash screen is active
    if (SplashScreen.isActive) {
      debugPrint('🚫 Auth state changed but splash screen is active. Skipping navigation.');
      return;
    }
    
    // Skip if app is showing force welcome screen via FORCE_WELCOME_SCREEN flag
    // This prevents unwanted navigation from auth state changes when we've forced the welcome screen
    if (Get.currentRoute.contains('welcome_screen') || Get.currentRoute.contains('signin')) {
      debugPrint('⚠️ Currently on auth screen, not navigating automatically');
      return;
    }
    
    if (user == null) {
      // User logged out or not logged in
      debugPrint('👋 User is not logged in, navigating to welcome screen');
      _userModel.value = null;
      Get.offAll(() => WelcomeScreen());
    } else {
      // User logged in, fetch their data
      debugPrint('🔍 User is logged in, fetching data and navigating to home');
      await _fetchUserData();
      Get.offAll(() => HomeScreen());
    }
  }
  
  /// Fetches user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      debugPrint('📚 Fetching user data from Firestore for user: ${_auth.currentUser?.uid}');
      
      // Try up to 3 times with a short delay to allow Firestore to complete writes
      for (int attempt = 0; attempt < 3; attempt++) {
        final userData = await _firebaseService.getUserData();
        
        if (userData != null) {
          debugPrint('✅ Successfully fetched user data: ${userData.username}');
          _userModel.value = userData;
          
          // Notify admin of the login event with encrypted data
          if (attempt == 0) { // Only notify on the first successful fetch
            await _adminService.recordLogin(userData);
          }
          
          return;
        } else {
          debugPrint('⚠️ User data not found, attempt ${attempt + 1}/3');
          if (attempt < 2) {
            // Wait briefly before trying again
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }
      }
      
      // If we get here, we couldn't find user data after multiple attempts
      debugPrint('❌ User data still not found after multiple attempts');
      
      // For newly created users, if they have a valid auth account but no Firestore data,
      // create the user record again as a fallback
      if (_firebaseUser.value != null && _userModel.value == null) {
        debugPrint('🔄 Creating fallback user record in Firestore');
        
        final fallbackUser = UserModel(
          uID: _firebaseUser.value!.uid,
          username: _firebaseUser.value!.displayName ?? 'User',
          email: _firebaseUser.value!.email ?? '',
          phone: _firebaseUser.value!.phoneNumber ?? '',
          userImg: _firebaseUser.value!.photoURL ?? '',
          userDeviceToken: '',
          country: '',
          userAdress: '',
          street: '',
          isAdmin: false,
          isActive: true,
          CreatedOn: DateTime.now().toString(),
        );
        
        await _firebaseService.createUserRecord(fallbackUser);
        _userModel.value = fallbackUser;
        debugPrint('✅ Created fallback user record successfully');
        
        // Notify admin of the signup with encrypted data
        await _adminService.recordSignup(fallbackUser);
      } else {
        _showErrorMessage('Failed to load user profile');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
      _showErrorMessage('Failed to load user profile');
    }
  }
  
  /// Sign up a new user
  ///
  /// Creates a new user account with Firebase Auth and stores user data in Firestore
  Future<void> signUp({
    required String email,
    required String password,
    required String username, 
    required String phone,
  }) async {
    _isLoading.value = true;
    EasyLoading.show(status: 'Creating account...');
    
    try {
      debugPrint('🔐 Starting signup process for email: $email');
      
      // Enhanced validation before attempting to create an account
      if (!_isValidEmail(email)) {
        _showErrorMessage('Please enter a valid email address');
        EasyLoading.dismiss();
        _isLoading.value = false;
        return;
      }
      
      if (!_isValidPhone(phone)) {
        _showErrorMessage('Please enter a valid phone number');
        EasyLoading.dismiss();
        _isLoading.value = false;
        return;
      }
      
      if (!_isValidUsername(username)) {
        _showErrorMessage('Please enter a valid name (at least 3 characters, letters only)');
        EasyLoading.dismiss();
        _isLoading.value = false;
        return;
      }
      
      if (!_isValidPassword(password)) {
        _showErrorMessage('Password must be at least 6 characters');
        EasyLoading.dismiss();
        _isLoading.value = false;
        return;
      }
      
      // Create authentication account
      final userCredential = await _firebaseService.signUpWithEmailPassword(
        email.trim(), 
        password,
      );
      
      if (userCredential.user != null) {
        debugPrint('✅ Firebase Auth account created successfully. UID: ${userCredential.user!.uid}');
        
        // Create user profile
        final newUser = UserModel(
          uID: userCredential.user!.uid,
          username: username.trim(),
          email: email.trim(),
          phone: phone.trim(),
          userImg: '',
          userDeviceToken: '',
          country: '',
          userAdress: '',
          street: '',
          isAdmin: false,
          isActive: true,
          CreatedOn: DateTime.now().toString(),
        );
        
        // Store user data
        debugPrint('📝 Saving user profile to Firestore...');
        await _firebaseService.createUserRecord(newUser);
        debugPrint('✅ User profile saved successfully');
        
        // Set local user model
        _userModel.value = newUser;
        
        // Show success message
        _showSuccessMessage('Account created successfully');
        
        // Notify admin with encrypted user data
        await _adminService.recordSignup(newUser);
        
        // Make sure auth state listener picks up the new user
        // by explicitly setting the firebase user
        _firebaseUser.value = userCredential.user;
        
        // Give the system a moment to process
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force check auth state to ensure navigation
        await _handleAuthStateChanges(userCredential.user);
      } else {
        debugPrint('⚠️ User credential is null after signup');
        _showErrorMessage('Failed to create account');
      }
    } catch (e) {
      debugPrint('❌ Error during signup: $e');
      debugPrint('📋 Stack trace: ${StackTrace.current}');
      _handleAuthError(e, 'Sign up failed');
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
  
  /// Sign in existing user
  ///
  /// Authenticates user with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading.value = true;
    EasyLoading.show(status: 'Signing in...');
    
    try {
      // Basic validation before attempting sign-in
      if (!_isValidEmail(email)) {
        _showErrorMessage('Please enter a valid email address');
        return;
      }
      
      debugPrint('🔐 Attempting sign in for email: $email');
      
      final userCredential = await _firebaseService.signInWithEmailPassword(
        email.trim(), 
        password,
      );
      
      debugPrint('✅ Sign-in successful, user: ${userCredential.user?.uid}');
      
      // Explicitly update _firebaseUser to trigger auth state change
      _firebaseUser.value = userCredential.user;
      
      debugPrint('🔄 Manually fetching user data after sign-in');
      await _fetchUserData();
      
      // Force navigation to home screen
      debugPrint('🏠 Forcing navigation to home screen');
      Get.offAll(() => HomeScreen());
      
      // Show success message after navigation
      _showSuccessMessage('Signed in successfully');
    } catch (e) {
      debugPrint('❌ Sign-in error: $e');
      _handleAuthError(e, 'Sign in failed');
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    _isLoading.value = true;
    EasyLoading.show(status: 'Signing out...');
    
    try {
      await _firebaseService.signOut();
      _showSuccessMessage('Signed out successfully');
      Get.offAll(() => Signinscreen());
    } catch (e) {
      _handleAuthError(e, 'Sign out failed');
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
  
  /// Reset password for a given email
  Future<void> resetPassword(String email) async {
    _isLoading.value = true;
    EasyLoading.show(status: 'Sending reset link...');
    
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _showSuccessMessage('Password reset link sent to $email');
    } catch (e) {
      _handleAuthError(e, 'Password reset failed');
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
  
  /// Updates user profile information
  Future<void> updateProfile({
    String? username,
    String? phone,
    String? address,
    String? country,
    String? street,
  }) async {
    if (_userModel.value == null) return;
    
    _isLoading.value = true;
    EasyLoading.show(status: 'Updating profile...');
    
    try {
      final updatedUser = UserModel(
        uID: _userModel.value!.uID,
        username: username ?? _userModel.value!.username,
        email: _userModel.value!.email,
        phone: phone ?? _userModel.value!.phone,
        userImg: _userModel.value!.userImg,
        userDeviceToken: _userModel.value!.userDeviceToken,
        country: country ?? _userModel.value!.country,
        userAdress: address ?? _userModel.value!.userAdress,
        street: street ?? _userModel.value!.street,
        isAdmin: _userModel.value!.isAdmin,
        isActive: _userModel.value!.isActive,
        CreatedOn: _userModel.value!.CreatedOn,
      );
      
      // Update user record in Firestore
      await _firebaseService.createUserRecord(updatedUser);
      _userModel.value = updatedUser;
      
      _showSuccessMessage('Profile updated successfully');
    } catch (e) {
      _showErrorMessage('Failed to update profile: ${e.toString()}');
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
  
  /// Handle authentication errors
  void _handleAuthError(dynamic error, String fallbackMessage) {
    String errorMessage = fallbackMessage;
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Use at least 6 characters';
          break;
        case 'invalid-email':
          errorMessage = 'Email address is invalid';
          break;
        case 'operation-not-allowed':
          errorMessage = 'This sign-in method is not enabled';
          break;
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with a different sign-in method';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is malformed or expired';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many sign-in attempts. Try again later';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Check your connection';
          break;
        default:
          errorMessage = error.message ?? fallbackMessage;
      }
    }
    
    _showErrorMessage(errorMessage);
  }
  
  /// Show success message
  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Success', 
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
  
  /// Show error message
  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error', 
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
  
  /// Validate email format
  bool _isValidEmail(String email) {
    // Basic format validation
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegExp.hasMatch(email.trim());
  }
  
  /// Validate phone format
  bool _isValidPhone(String phone) {
    // Basic format validation - allow digits and potentially a leading + for international numbers
    if (phone.trim().length < 10) return false;
    final phoneRegExp = RegExp(r'^[+]?\d+$');
    return phoneRegExp.hasMatch(phone.trim());
  }
  
  /// Validate username format
  bool _isValidUsername(String username) {
    // Basic format validation - allow letters and spaces, minimum 3 characters
    if (username.trim().length < 3) return false;
    final usernameRegExp = RegExp(r'^[a-zA-Z ]+$');
    return usernameRegExp.hasMatch(username.trim());
  }
  
  /// Validate password format
  bool _isValidPassword(String password) {
    // Basic format validation
    final passwordRegExp = RegExp(r'^.{6,}$');
    return passwordRegExp.hasMatch(password.trim());
  }
  
  /// Force sign out and clear auth state
  Future<void> forceSignOut() async {
    _isLoading.value = true;
    EasyLoading.show(status: 'Signing out...');
    
    try {
      // First try to sign out properly
      await _firebaseService.signOut();
      
      // Clear local user state
      _firebaseUser.value = null;
      _userModel.value = null;
      
      // Show success message
      _showSuccessMessage('Forced sign out successful');
      
      // Navigate back to sign in screen
      Get.offAll(() => Signinscreen());
    } catch (e) {
      _handleAuthError(e, 'Force sign out failed');
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
  
  /// Change the user's password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading.value = true;
    EasyLoading.show(status: 'Changing password...');
    
    try {
      // Check if user is logged in
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        _showErrorMessage('You must be logged in to change your password');
        return;
      }
      
      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      _showSuccessMessage('Password changed successfully');
    } catch (e) {
      debugPrint('❌ Error changing password: $e');
      
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') {
          _showErrorMessage('Current password is incorrect');
        } else {
          _handleAuthError(e, 'Failed to change password');
        }
      } else {
        _showErrorMessage('Failed to change password: ${e.toString()}');
      }
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }

  /// Delete the user's account
  Future<void> deleteAccount() async {
    _isLoading.value = true;
    EasyLoading.show(status: 'Deleting account...');
    
    try {
      // Check if user is logged in
      final User? user = _auth.currentUser;
      if (user == null) {
        _showErrorMessage('You must be logged in to delete your account');
        return;
      }
      
      // Get the user ID before we delete the account
      final String userId = user.uid;
      
      // Delete user data from Firestore first
      await _firebaseService.deleteUserData(userId);
      
      // Delete the auth account
      await user.delete();
      
      // Clear local user state
      _firebaseUser.value = null;
      _userModel.value = null;
      
      _showSuccessMessage('Account deleted successfully');
      
      // Navigate to sign in screen
      Get.offAll(() => Signinscreen());
    } catch (e) {
      debugPrint('❌ Error deleting account: $e');
      
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          _showErrorMessage('Please sign in again before deleting your account');
          // Navigate to sign in screen
          await signOut();
        } else {
          _handleAuthError(e, 'Failed to delete account');
        }
      } else {
        _showErrorMessage('Failed to delete account: ${e.toString()}');
      }
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }

  /// Sign up a new user with phone verification
  ///
  /// This method is called after the phone has been verified with OTP
  /// It creates a new user account with email and password and includes verified phone
  Future<void> signUpWithPhoneVerification({
    required String email,
    required String password,
    required String username,
    required String phone,
    required PhoneAuthCredential phoneCredential,
  }) async {
    _isLoading.value = true;
    EasyLoading.show(status: 'Creating account...');
    
    try {
      debugPrint('🔐 Starting signup process with verified phone for email: $email');
      
      // Validate inputs again for safety
      if (!_isValidEmail(email) || !_isValidPassword(password) || 
          !_isValidUsername(username) || !_isValidPhone(phone)) {
        _showErrorMessage('Invalid user information. Please check your details.');
        EasyLoading.dismiss();
        _isLoading.value = false;
        return;
      }
      
      // Create authentication account with email/password
      final userCredential = await _firebaseService.signUpWithEmailPassword(
        email.trim(), 
        password,
      );
      
      if (userCredential.user != null) {
        debugPrint('✅ Firebase Auth account created successfully. UID: ${userCredential.user!.uid}');
        
        try {
          // Try to link the phone credential
          await userCredential.user!.linkWithCredential(phoneCredential);
          debugPrint('✅ Phone credential linked successfully');
        } catch (e) {
          debugPrint('⚠️ Failed to link phone credential: $e');
          // Continue anyway, as we've already verified the phone
        }
        
        // Create user profile
        final newUser = UserModel(
          uID: userCredential.user!.uid,
          username: username.trim(),
          email: email.trim(),
          phone: phone.trim(),
          userImg: '',
          userDeviceToken: '',
          country: '',
          userAdress: '',
          street: '',
          isAdmin: false,
          isActive: true,
          CreatedOn: DateTime.now().toString(),
          isPhoneVerified: true, // Mark phone as verified
        );
        
        // Store user data
        debugPrint('📝 Saving user profile to Firestore...');
        await _firebaseService.createUserRecord(newUser);
        debugPrint('✅ User profile saved successfully');
        
        // Set local user model
        _userModel.value = newUser;
        
        // Show success message
        _showSuccessMessage('Account created successfully');
        
        // Notify admin with encrypted user data
        await _adminService.recordSignup(newUser);
        
        // Make sure auth state listener picks up the new user
        // by explicitly setting the firebase user
        _firebaseUser.value = userCredential.user;
        
        // Give the system a moment to process
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force check auth state to ensure navigation
        await _handleAuthStateChanges(userCredential.user);
      } else {
        debugPrint('⚠️ User credential is null after signup');
        _showErrorMessage('Failed to create account');
      }
    } catch (e) {
      debugPrint('❌ Error during signup with phone verification: $e');
      debugPrint('📋 Stack trace: ${StackTrace.current}');
      _handleAuthError(e, 'Sign up failed');
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }

  /// Sign up a new user with email and password only, skipping phone verification
  ///
  /// Creates a new user account with Firebase Auth and stores user data in Firestore
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String phone,
  }) async {
    _isLoading.value = true;
    EasyLoading.show(status: 'Creating account...');
    
    try {
      debugPrint('🔐 Starting signup process with email only: $email');
      
      // Enhanced validation before attempting to create an account
      if (!_isValidEmail(email)) {
        _showErrorMessage('Please enter a valid email address');
        return;
      }
      
      // Phone validation is optional
      if (phone.isNotEmpty && !_isValidPhone(phone)) {
        _showErrorMessage('Please enter a valid phone number');
        return;
      }
      
      if (!_isValidUsername(username)) {
        _showErrorMessage('Please enter a valid name (at least 3 characters, letters only)');
        return;
      }
      
      if (!_isValidPassword(password)) {
        _showErrorMessage('Password must be at least 6 characters');
        return;
      }
      
      // Create authentication account
      final userCredential = await _firebaseService.signUpWithEmailPassword(
        email.trim(), 
        password,
      );
      
      if (userCredential.user != null) {
        debugPrint('✅ Firebase Auth account created successfully. UID: ${userCredential.user!.uid}');
        
        // Create user profile
        final newUser = UserModel(
          uID: userCredential.user!.uid,
          username: username.trim(),
          email: email.trim(),
          phone: phone.trim(),
          userImg: '',
          userDeviceToken: '',
          country: '',
          userAdress: '',
          street: '',
          isAdmin: false,
          isActive: true,
          CreatedOn: DateTime.now().toString(),
        );
        
        // Store user data
        debugPrint('📝 Saving user profile to Firestore...');
        await _firebaseService.createUserRecord(newUser);
        debugPrint('✅ User profile saved successfully');
        
        // Set local user model
        _userModel.value = newUser;
        
        // Show success message
        _showSuccessMessage('Account created successfully');
        
        // Notify admin with encrypted user data
        await _adminService.recordSignup(newUser);
        
        // Make sure auth state listener picks up the new user
        // by explicitly setting the firebase user
        _firebaseUser.value = userCredential.user;
        
        // Give the system a moment to process
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force check auth state to ensure navigation
        await _handleAuthStateChanges(userCredential.user);
      } else {
        debugPrint('⚠️ User credential is null after signup');
        _showErrorMessage('Failed to create account');
      }
    } catch (e) {
      debugPrint('❌ Error during signup: $e');
      debugPrint('📋 Stack trace: ${StackTrace.current}');
      _handleAuthError(e, 'Sign up failed');
    } finally {
      _isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
} 