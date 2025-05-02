import 'package:flutter/material.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:get/get.dart';

/// A utility class for admin-only commands and operations
class AdminCommandsUtil {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  /// Make a user an admin by their user ID
  /// Example usage:
  /// ```dart
  /// AdminCommandsUtil().makeUserAdmin('user123');
  /// ```
  Future<void> makeUserAdmin(String userId, {BuildContext? context}) async {
    try {
      final result = await _firebaseService.makeUserAdmin(userId);
      
      if (context != null) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User has been made an admin'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to make user an admin'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in AdminCommandsUtil.makeUserAdmin: $e');
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Makes the current logged-in user an admin (for testing purposes)
  Future<void> makeCurrentUserAdmin(BuildContext context) async {
    final currentUser = _firebaseService.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user is currently logged in'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    await makeUserAdmin(currentUser.uid, context: context);
  }
} 