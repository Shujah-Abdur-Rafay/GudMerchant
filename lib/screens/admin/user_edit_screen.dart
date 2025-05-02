import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:gudmerchant/models/usermodel.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:gudmerchant/utils/app_theme.dart';

class UserEditScreen extends StatefulWidget {
  final String userId;
  
  const UserEditScreen({
    Key? key, 
    required this.userId,
  }) : super(key: key);

  @override
  _UserEditScreenState createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  UserModel? _user;
  
  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  
  bool _isAdmin = false;
  bool _isActive = true;
  
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _streetController.dispose();
    _countryController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'User not found';
          _isLoading = false;
        });
        return;
      }
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      _user = UserModel.fromMap(userData);
      
      // Set form values
      _usernameController.text = _user!.username;
      _emailController.text = _user!.email;
      _phoneController.text = _user!.phone;
      _addressController.text = _user!.userAdress;
      _streetController.text = _user!.street;
      _countryController.text = _user!.country;
      
      setState(() {
        _isAdmin = _user!.isAdmin;
        _isActive = _user!.isActive;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });
    
    try {
      // Update user data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'userAdress': _addressController.text.trim(),
        'street': _streetController.text.trim(),
        'country': _countryController.text.trim(),
        'isAdmin': _isAdmin,
        'isActive': _isActive,
      });
      
      // Make admin using the service function if needed
      if (_isAdmin && (_user?.isAdmin != true)) {
        await _firebaseService.makeUserAdmin(widget.userId);
      }
      
      setState(() {
        _isSaving = false;
      });
      
      Get.back(result: true);
      Get.snackbar(
        'Success', 
        'User updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating user: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveUserData,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _buildForm(),
    );
  }
  
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User ID (read-only)
            TextFormField(
              initialValue: widget.userId,
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 16),
            
            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!GetUtils.isEmail(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Street
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Country
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Admin switch
            SwitchListTile(
              title: const Text('Admin User'),
              subtitle: const Text('Grant administrative privileges'),
              value: _isAdmin,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _isAdmin = value;
                });
              },
            ),
            
            // Active switch
            SwitchListTile(
              title: const Text('Active Account'),
              subtitle: const Text('Allow user to log in'),
              value: _isActive,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveUserData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAVE CHANGES', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 