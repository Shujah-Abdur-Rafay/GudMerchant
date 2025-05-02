import 'package:gudmerchant/controllers/auth_controller.dart';
import 'package:gudmerchant/screens/auth-ui/SignInScreen.dart';
import 'package:gudmerchant/screens/admin/admin_panel_screen.dart';
import 'package:gudmerchant/screens/order/order_history_screen.dart';
import 'package:gudmerchant/screens/profile/addresses_screen.dart';
import 'package:gudmerchant/screens/profile/help_support_screen.dart';
import 'package:gudmerchant/screens/profile/settings_screen.dart';
import 'package:gudmerchant/screens/profile/wishlist_screen.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
              ),
              child: Obx(() {
                final user = authController.userModel;
                final isLoggedIn = user != null;
                
                return Column(
                  children: [
                    // Profile image
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Username
                    Text(
                      isLoggedIn ? user.username : 'Guest User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    // Email
                    if (isLoggedIn && user.email.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Login/Logout button
                    if (!isLoggedIn)
                      ElevatedButton(
                        onPressed: () {
                          Get.to(() => const Signinscreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Login'),
                      )
                    else
                      OutlinedButton(
                        onPressed: () {
                          Get.defaultDialog(
                            title: 'Logout',
                            middleText: 'Are you sure you want to logout?',
                            textConfirm: 'Logout',
                            textCancel: 'Cancel',
                            confirmTextColor: Colors.white,
                            onConfirm: () {
                              authController.signOut();
                              Get.back();
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                  ],
                );
              }),
            ),
            
            // Menu items
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'My Orders',
              onTap: () {
                Get.to(() => const OrderHistoryScreen());
              },
            ),
            _buildMenuItem(
              icon: Icons.location_on_outlined,
              title: 'My Addresses',
              onTap: () {
                Get.to(() => const AddressesScreen());
              },
            ),
            _buildMenuItem(
              icon: Icons.favorite_border_outlined,
              title: 'My Wishlist',
              onTap: () {
                Get.to(() => const WishlistScreen());
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Get.to(() => const SettingsScreen());
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline_outlined,
              title: 'Help & Support',
              onTap: () {
                Get.to(() => const HelpSupportScreen());
              },
            ),
            if (authController.userModel?.isAdmin == true)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Panel'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.to(() => const AdminPanelScreen());
                },
              ),
            
            // App version
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'App Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.black87,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 