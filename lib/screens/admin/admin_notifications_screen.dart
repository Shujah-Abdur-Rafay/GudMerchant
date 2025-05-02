import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gudmerchant/utils/encryption_helper.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'login', 'signup'
  bool _showDecrypted = false;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get notifications from Firestore
      Query query = _firestore.collection('admin_notifications')
          .orderBy('timestamp', descending: true);
      
      // Apply filter if needed
      if (_filter != 'all') {
        query = query.where('activityType', isEqualTo: _filter);
      }
      
      final snapshot = await query.get();
      
      setState(() {
        _notifications = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
      
      Get.snackbar(
        'Error',
        'Failed to load notifications',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> _markAsProcessed(String notificationId) async {
    try {
      await _firestore.collection('admin_notifications')
          .doc(notificationId)
          .update({'isProcessed': true});
      
      // Refresh the list
      _loadNotifications();
      
      Get.snackbar(
        'Success',
        'Notification marked as processed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error marking notification as processed: $e');
      Get.snackbar(
        'Error',
        'Failed to update notification',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notifications'),
        actions: [
          IconButton(
            icon: Icon(_showDecrypted ? Icons.lock_open : Icons.lock),
            onPressed: () {
              setState(() {
                _showDecrypted = !_showDecrypted;
              });
            },
            tooltip: _showDecrypted ? 'Show Encrypted' : 'Show Decrypted',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
              _loadNotifications();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Notifications'),
              ),
              const PopupMenuItem(
                value: 'login',
                child: Text('Login Events'),
              ),
              const PopupMenuItem(
                value: 'signup',
                child: Text('Signup Events'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications found'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final data = notification.data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'] as Timestamp?;
                      final formattedDate = timestamp != null
                          ? DateFormat('MMM dd, yyyy hh:mm a').format(timestamp.toDate())
                          : 'Unknown date';
                      final isProcessed = data['isProcessed'] ?? false;
                      final activityType = data['activityType'] ?? 'unknown';
                      final userId = data['userId'] ?? 'unknown';
                      
                      // Get encrypted user details
                      final encryptedDetails = data['encryptedDetails'];
                      
                      // Decrypt if needed
                      Map<String, dynamic> userDetails = {};
                      if (_showDecrypted && encryptedDetails != null) {
                        userDetails = EncryptionHelper.decryptUserDetails(Map<String, dynamic>.from(encryptedDetails));
                      } else if (encryptedDetails != null) {
                        userDetails = Map<String, dynamic>.from(encryptedDetails);
                      }
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: isProcessed ? Colors.grey.shade100 : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(
                                      activityType.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: activityType == 'login'
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'User ID: $userId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'User Details:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (userDetails.isNotEmpty) ..._buildUserDetailsWidgets(userDetails),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isProcessed)
                                    ElevatedButton.icon(
                                      onPressed: () => _markAsProcessed(notification.id),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Mark as Processed'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  if (isProcessed)
                                    Chip(
                                      label: const Text(
                                        'PROCESSED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: Colors.grey,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNotifications,
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  List<Widget> _buildUserDetailsWidgets(Map<String, dynamic> userDetails) {
    // Filter out some fields we don't need to show
    final filteredDetails = Map<String, dynamic>.from(userDetails);
    filteredDetails.remove('uID'); // Already showing userId elsewhere
    
    return filteredDetails.entries.map((entry) {
      final key = entry.key;
      final value = entry.value;
      
      // Format key for display (camelCase to Title Case)
      final formattedKey = key.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => ' ${match.group(0)}',
      ).capitalize!;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$formattedKey:',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value?.toString() ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
} 