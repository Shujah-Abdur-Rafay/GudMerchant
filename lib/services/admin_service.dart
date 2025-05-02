import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Service for administrative operations
class AdminService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Status indicators
  final RxBool _isUploading = false.obs;
  
  bool get isUploading => _isUploading.value;
  
  /// Sample categories for our products
  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Home & Kitchen',
    'Beauty & Personal Care',
    'Sports & Outdoors',
    'Books & Media',
    'Toys & Games',
    'Jewelry & Watches',
    'Health & Wellness',
    'Automotive',
    'Pet Supplies',
    'Garden & Outdoor',
    'Office & Stationery',
    'Baby Products',
    'Food & Beverages'
  ];
  
  /// Get available product categories
  List<String> get availableCategories => _categories;
  
  /// Clears all products from the database - USE WITH CAUTION
  Future<void> clearAllProducts() async {
    // This feature is intentionally left unimplemented for safety
    // Add implementation if needed, but with proper safeguards
    debugPrint('⚠️ clearAllProducts not implemented for safety reasons');
  }

  Future<AdminService> init() async {
    debugPrint('Initializing Admin Service');
    // Any initialization logic can go here
    return this;
  }
} 