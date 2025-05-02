import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gudmerchant/models/usermodel.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gudmerchant/utils/encryption_helper.dart';
import 'package:gudmerchant/screens/admin/user_edit_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  
  const UserDetailScreen({
    Key? key, 
    required this.userId,
  }) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _userOrders = [];
  bool _showDecrypted = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Fetch user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // Fetch user orders
        QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('OrderDate', descending: true)
            .get();
        
        List<Map<String, dynamic>> orders = orderSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        
        setState(() {
          _userData = userData;
          _userOrders = orders;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found'))
        );
        Get.back();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e'))
      );
    }
  }
  
  Map<String, dynamic> _processUserData(Map<String, dynamic> userData) {
    if (_showDecrypted) {
      return EncryptionHelper.decryptUserDetails(userData);
    }
    return userData;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          Switch(
            value: _showDecrypted,
            onChanged: (value) {
              setState(() {
                _showDecrypted = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _showDecrypted ? 'Decrypted' : 'Encrypted',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('User not found'))
              : _buildUserDetails(),
    );
  }
  
  Widget _buildUserDetails() {
    final processedUserData = _processUserData(_userData!);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Avatar and Name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                        child: processedUserData['userImg'] != null && 
                               processedUserData['userImg'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.network(
                                  processedUserData['userImg'],
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    size: 32,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 32,
                                color: AppConstants.primaryColor,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              processedUserData['username'] ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              processedUserData['email'] ?? 'No email',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: processedUserData['isAdmin'] ?? false,
                            onChanged: (value) async {
                              try {
                                await _firebaseService.makeUserAdmin(widget.userId);
                                setState(() {
                                  _userData!['isAdmin'] = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('User is now an admin'))
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'))
                                );
                              }
                            },
                          ),
                          const Text('Admin', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  // User Details
                  _buildDetailItem('User ID', widget.userId),
                  _buildDetailItem('Phone', processedUserData['phone'] ?? 'Not provided'),
                  _buildDetailItem('Address', processedUserData['userAdress'] ?? 'Not provided'),
                  _buildDetailItem('Country', processedUserData['country'] ?? 'Not provided'),
                  _buildDetailItem('Created On', processedUserData['CreatedOn'] ?? 'Unknown'),
                  _buildDetailItem('Status', 
                    (processedUserData['isActive'] ?? true) ? 'Active' : 'Inactive',
                    valueColor: (processedUserData['isActive'] ?? true) ? Colors.green : Colors.red,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _navigateToEditScreen(),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _toggleUserActiveStatus(),
                        icon: Icon(
                          (processedUserData['isActive'] ?? true) 
                              ? Icons.block 
                              : Icons.check_circle,
                        ),
                        label: Text(
                          (processedUserData['isActive'] ?? true) 
                              ? 'Deactivate Account' 
                              : 'Activate Account',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (processedUserData['isActive'] ?? true) 
                              ? Colors.red 
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _deleteUser(),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Order History
          const Text(
            'Order History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          _userOrders.isEmpty
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No orders found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userOrders.length,
                  itemBuilder: (context, index) {
                    final order = _userOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          'Order #${order['id'].toString().substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Date: ${_formatDate(order['OrderDate'])} • '
                          'Amount: PKR ${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                        ),
                        trailing: Chip(
                          label: Text(
                            order['isPaid'] ? 'Paid' : 'Unpaid',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: order['isPaid'] ? Colors.green : Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onTap: () {
                          // Navigate to order details
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    if (date is Timestamp) {
      DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return date.toString();
    }
  }
  
  Future<void> _toggleUserActiveStatus() async {
    try {
      final bool currentStatus = _userData!['isActive'] ?? true;
      final bool newStatus = !currentStatus;
      
      // Show confirmation dialog
      final bool confirm = await _showConfirmationDialog(
        title: newStatus ? 'Activate Account' : 'Deactivate Account',
        content: newStatus 
            ? 'Are you sure you want to activate this user account?'
            : 'Are you sure you want to deactivate this user account? The user will not be able to log in.',
        confirmText: newStatus ? 'Activate' : 'Deactivate',
        isDestructive: !newStatus,
      );
      
      if (!confirm) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'isActive': newStatus});
      
      setState(() {
        _userData!['isActive'] = newStatus;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus 
                ? 'User account has been activated'
                : 'User account has been deactivated'
          ),
          backgroundColor: newStatus ? Colors.green : Colors.red,
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user status: $e'))
      );
    }
  }
  
  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  Future<void> _navigateToEditScreen() async {
    final result = await Get.to(() => UserEditScreen(userId: widget.userId));
    
    if (result == true) {
      _loadUserData();
    }
  }
  
  Future<void> _deleteUser() async {
    // Show a confirmation dialog
    final bool confirm = await _showConfirmationDialog(
      title: 'Delete User',
      content: 'Are you sure you want to delete this user? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    
    if (!confirm) return;
    
    try {
      // Delete the user from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .delete();
      
      // Try to delete the user from Authentication as well
      try {
        // This requires admin SDK or callable functions for security
        // Here we'll add a note about this limitation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note: User account was deleted from the database, but may still exist in Authentication. Complete deletion requires Admin SDK.'),
            duration: Duration(seconds: 5),
          )
        );
      } catch (authError) {
        // Just log the error, as we've already notified the user
        debugPrint('Error deleting user from Authentication: $authError');
      }
      
      Get.back(result: true); // Return to previous screen
      
      Get.snackbar(
        'Success', 
        'User deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e'))
      );
    }
  }
} 