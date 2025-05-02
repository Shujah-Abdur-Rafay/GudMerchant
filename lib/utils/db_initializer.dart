import 'package:gudmerchant/data/mock_categories.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class DbInitializer {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  // Initialize the database with sample categories and products
  Future<void> initializeDatabase() async {
    try {
      debugPrint('Starting database initialization...');
      
      // For each category, add products if they don't already exist
      for (final category in categories) {
        debugPrint('Processing category: ${category.name}');
        
        // Get existing products for this category
        List<ProductModel> existingProducts = 
            await _firebaseService.getProductsByCategory(category.name);
        
        // If there are already products in this category, skip
        if (existingProducts.isNotEmpty) {
          debugPrint('Category ${category.name} already has ${existingProducts.length} products, skipping...');
          continue;
        }
        
        // Get products for this category from mock data
        final categoryProductsList = categoryProducts[category.name];
        if (categoryProductsList == null || categoryProductsList.isEmpty) {
          debugPrint('No mock products found for category ${category.name}');
          continue;
        }
        
        // Add each product to the database
        for (final productData in categoryProductsList) {
          final productId = const Uuid().v4();
          
          final product = ProductModel(
            id: productId,
            name: productData['name'],
            description: productData['description'],
            price: productData['price'],
            images: List<String>.from(productData['images']),
            category: category.name,
            stock: productData['stockQuantity'],
            isFeatured: productData['isFeatured'] ?? false,
            rating: 0.0,
            reviewCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await _firebaseService.addProduct(product);
          debugPrint('Added product: ${product.name} to category ${category.name}');
        }
      }
      
      debugPrint('Database initialization completed successfully!');
      Get.snackbar(
        'Database Initialized',
        'New product categories and items have been added successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize database: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 