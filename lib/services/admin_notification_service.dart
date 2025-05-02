import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gudmerchant/models/usermodel.dart';
import 'package:gudmerchant/utils/encryption_helper.dart';
import 'package:flutter/foundation.dart';

class AdminNotificationService {
  late final FirebaseFirestore _firestore;
  bool _isInitialized = false;

  AdminNotificationService() {
    _initializeFirestore();
  }

  void _initializeFirestore() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      debugPrint('✅ AdminNotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing AdminNotificationService: $e');
      _isInitialized = false;
    }
  }

  /// Send encrypted user details to admin when user signs up or logs in
  Future<void> notifyAdminOfUserActivity(
      UserModel user, String activityType) async {
    if (!_isInitialized) {
      debugPrint(
          '⚠️ AdminNotificationService not initialized, skipping notification');
      return;
    }

    try {
      // Create a record of the user activity with encrypted details
      Map<String, dynamic> encryptedUserDetails;
      try {
        encryptedUserDetails =
            EncryptionHelper.encryptUserDetails(user.toMap());
      } catch (encryptionError) {
        debugPrint('❌ Error encrypting user details: $encryptionError');
        // Use minimal encryption to avoid crashing
        encryptedUserDetails = {
          'userId': user.uID,
          'error': 'Encryption failed'
        };
      }

      final activityData = {
        'userId': user.uID,
        'encryptedDetails': encryptedUserDetails,
        'activityType': activityType, // "signup" or "login"
        'timestamp': FieldValue.serverTimestamp(),
        'isProcessed': false
      };

      // Store the activity in a separate collection for admin review
      await _firestore.collection('admin_notifications').add(activityData);

      debugPrint('✅ Sent encrypted user activity notification to admin');
    } catch (e) {
      debugPrint('❌ Error sending user activity to admin: $e');
      // Don't rethrow - this should fail silently and not affect the user experience
    }
  }

  /// Record a login event for a user
  Future<void> recordLogin(UserModel user) async {
    try {
      await notifyAdminOfUserActivity(user, 'login');
    } catch (e) {
      debugPrint('❌ Error recording login: $e');
    }
  }

  /// Record a signup event for a user
  Future<void> recordSignup(UserModel user) async {
    try {
      await notifyAdminOfUserActivity(user, 'signup');
    } catch (e) {
      debugPrint('❌ Error recording signup: $e');
    }
  }

  /// Get all admin notifications
  Future<List<Map<String, dynamic>>> getNotifications(
      {String? filterByType}) async {
    if (!_isInitialized) {
      debugPrint(
          '⚠️ AdminNotificationService not initialized, returning empty notifications');
      return [];
    }

    try {
      Query query = _firestore
          .collection('admin_notifications')
          .orderBy('timestamp', descending: true);

      if (filterByType != null) {
        query = query.where('activityType', isEqualTo: filterByType);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting admin notifications: $e');
      return [];
    }
  }

  /// Mark a notification as processed
  Future<bool> markAsProcessed(String notificationId) async {
    if (!_isInitialized) {
      debugPrint(
          '⚠️ AdminNotificationService not initialized, skipping mark as processed');
      return false;
    }

    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'isProcessed': true});
      return true;
    } catch (e) {
      debugPrint('❌ Error marking notification as processed: $e');
      return false;
    }
  }
}
