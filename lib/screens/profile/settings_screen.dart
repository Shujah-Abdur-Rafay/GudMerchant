import 'package:gudmerchant/utils/app_constants.dart';
import 'package:gudmerchant/utils/admin_commands.dart';
import 'package:gudmerchant/controllers/auth_controller.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gudmerchant/screens/profile/privacy_policy_screen.dart';
import 'package:gudmerchant/screens/profile/terms_of_service_screen.dart';
import 'package:gudmerchant/screens/profile/help_center_screen.dart';
import 'package:gudmerchant/screens/profile/contact_us_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthController _authController = Get.find<AuthController>();
  
  // User preferences
  bool _notificationsEnabled = true;
  RxBool _darkModeEnabled = false.obs;
  String _selectedLanguage = 'English';
  
  // Add developer options section before About section or at the end
  
  // Developer Options (hidden setting, requires multiple taps)
  // This is for testing purposes only and should be removed in production
  int _devOptionsTapCounter = 0;
  bool _showDevOptions = false;

  @override
  void initState() {
    super.initState();
    // Get current theme mode
    _darkModeEnabled.value = Get.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Account Settings
          _buildSettingSection(
            title: 'Account Settings',
            children: [
              ListTile(
                title: const Text('Change Name'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showChangeNameDialog();
                },
              ),
              ListTile(
                title: const Text('Change Password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showChangePasswordDialog();
                },
              ),
            ],
          ),
          
          // Notifications
          _buildSettingSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive promotional offers and updates'),
                value: _notificationsEnabled,
                activeColor: AppConstants.primaryColor,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ],
          ),
          
          // Appearance
          _buildSettingSection(
            title: 'Appearance',
            children: [
              Obx(() => SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark themes'),
                value: _darkModeEnabled.value,
                activeColor: AppConstants.primaryColor,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled.value = value;
                  });
                  // Apply theme change
                  Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  Get.snackbar(
                    'Theme Changed',
                    value ? 'Dark mode enabled' : 'Light mode enabled',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              )),
            ],
          ),
          
          // Language
          _buildSettingSection(
            title: 'Language',
            children: [
              ListTile(
                title: const Text('App Language'),
                subtitle: Text(_selectedLanguage),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showLanguageSelector();
                },
              ),
            ],
          ),
          
          // Privacy & Security
          _buildSettingSection(
            title: 'Privacy & Security',
            children: [
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.to(() => const PrivacyPolicyScreen());
                },
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.to(() => const TermsOfServiceScreen());
                },
              ),
            ],
          ),
          
          // Help & Support
          _buildSettingSection(
            title: 'Help & Support',
            children: [
              ListTile(
                title: const Text('Help Center'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.to(() => const HelpCenterScreen());
                },
              ),
              ListTile(
                title: const Text('Contact Us'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.to(() => const ContactUsScreen());
                },
              ),
            ],
          ),
          
          // About
          _buildSettingSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
                onTap: () {
                  // Secret tap counter to enable developer options
                  _devOptionsTapCounter++;
                  if (_devOptionsTapCounter >= 7) {
                    setState(() {
                      _showDevOptions = true;
                    });
                    Get.snackbar(
                      'Developer Options Enabled',
                      'Developer options are now visible',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.amber,
                    );
                    _devOptionsTapCounter = 0;
                  }
                },
              ),
            ],
          ),
          
          // Developer Options (Hidden)
          if (_showDevOptions)
            _buildSettingSection(
              title: 'Developer Options',
              children: [
                ListTile(
                  title: const Text('Make Current User Admin'),
                  subtitle: const Text('For testing purposes only'),
                  tileColor: Colors.amber.withOpacity(0.2),
                  trailing: const Icon(Icons.warning, color: Colors.orange),
                  onTap: () {
                    AdminCommandsUtil().makeCurrentUserAdmin(context);
                  },
                ),
              ],
            ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  void _showLanguageSelector() {
    final List<String> languages = ['English', 'Urdu', 'Punjabi', 'Sindhi', 'Pashto', 'Balochi'];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];
                return RadioListTile<String>(
                  title: Text(language),
                  value: language,
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    Navigator.of(context).pop();
                    
                    // Show a message
                    Get.snackbar(
                      'Language Changed',
                      'Language set to $_selectedLanguage',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showChangeNameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _authController.userModel?.username ?? ''
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your new name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Name cannot be empty',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }
                
                // Update name using the AuthController
                await _authController.updateProfile(username: newName);
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate passwords
                if (newPasswordController.text != confirmPasswordController.text) {
                  Get.snackbar(
                    'Error',
                    'New passwords do not match',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }
                
                // Change password
                _authController.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                
                Navigator.of(context).pop();
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }
} 