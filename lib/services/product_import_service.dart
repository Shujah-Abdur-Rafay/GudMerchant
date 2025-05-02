import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ProductImportService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxBool _isImporting = false.obs;

  bool get isImporting => _isImporting.value;

  /// Check if we already have products in the database
  Future<bool> hasProducts() async {
    try {
      final snapshot = await _firestore.collection('products').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking for products: $e');
      return false;
    }
  }
  
  /// Delete all products from Firestore
  Future<void> clearAllProducts() async {
    try {
      _isImporting.value = true;
      
      // Get all products
      final snapshot = await _firestore.collection('products').get();
      
      // Delete in batches of 500 (Firestore limit)
      const batchSize = 500;
      int count = 0;
      WriteBatch batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        
        if (count >= batchSize) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      
      // Commit any remaining deletes
      if (count > 0) {
        await batch.commit();
      }
      
      debugPrint('All products cleared successfully!');
    } catch (e) {
      debugPrint('Error clearing products: $e');
    } finally {
      _isImporting.value = false;
    }
  }
} 