import 'package:gudmerchant/models/product_model.dart';
import 'package:gudmerchant/models/wishlist_model.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class WishlistController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final RxList<WishlistModel> _wishlistItems = <WishlistModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxMap<String, bool> _productWishlistStatus = <String, bool>{}.obs;
  
  List<WishlistModel> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading.value;
  
  StreamSubscription? _authSubscription;
  
  @override
  void onInit() {
    super.onInit();
    // Fetch wishlist when controller initializes
    fetchWishlist();
    
    // Set up listener for auth changes to reload wishlist when user logs in/out
    _authSubscription = _firebaseService.userChanges.listen((_) {
      fetchWishlist();
      _productWishlistStatus.clear();
    });
  }
  
  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
  
  Future<void> fetchWishlist() async {
    try {
      if (_isLoading.value) return;
      
      _isLoading.value = true;
      
      final userId = _firebaseService.userId;
      if (userId.isEmpty) {
        _wishlistItems.clear();
        return;
      }
      
      List<WishlistModel> items = await _firebaseService.getWishlistItems();
      _wishlistItems.assignAll(items);
      
      // Update status cache for existing items
      for (var item in items) {
        _productWishlistStatus[item.productId] = true;
      }
    } catch (e) {
      debugPrint('Error fetching wishlist: $e');
      Get.snackbar(
        'Error',
        'Failed to load wishlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<bool> isProductInWishlist(String productId) async {
    // Check cache first
    if (_productWishlistStatus.containsKey(productId)) {
      return _productWishlistStatus[productId]!;
    }
    
    // If not in cache, fetch from Firebase
    final isInWishlist = await _firebaseService.isProductInWishlist(productId);
    
    // Update cache
    _productWishlistStatus[productId] = isInWishlist;
    
    return isInWishlist;
  }
  
  Future<void> toggleWishlist(ProductModel product) async {
    try {
      final currentStatus = await isProductInWishlist(product.id);
      
      // Update local cache immediately for responsive UI
      _productWishlistStatus[product.id] = !currentStatus;
      
      if (currentStatus) {
        // If it's in wishlist, remove it locally first
        _wishlistItems.removeWhere((item) => item.productId == product.id);
      } else {
        // If it's not in wishlist, add it locally first
        _wishlistItems.add(WishlistModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: product.id,
          productName: product.name,
          productPrice: product.price,
          productImage: product.images.isNotEmpty ? product.images[0] : '',
          addedAt: DateTime.now(),
        ));
      }
      
      // Then update Firebase
      await _firebaseService.toggleWishlist(product);
      
      // Refresh to ensure consistency
      fetchWishlist();
      
      // Show success message
      Get.snackbar(
        'Success',
        currentStatus ? 'Removed from wishlist' : 'Added to wishlist',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Revert local change on error
      await fetchWishlist();
      
      debugPrint('Error toggling wishlist: $e');
      Get.snackbar(
        'Error',
        'Failed to update wishlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> removeFromWishlist(String productId) async {
    try {
      // Update local cache immediately
      _productWishlistStatus[productId] = false;
      _wishlistItems.removeWhere((item) => item.productId == productId);
      
      // Update Firebase
      await _firebaseService.removeFromWishlist(productId);
      
      Get.snackbar(
        'Success',
        'Removed from wishlist',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Revert local change on error
      await fetchWishlist();
      
      debugPrint('Error removing from wishlist: $e');
      Get.snackbar(
        'Error',
        'Failed to remove from wishlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
  
  void clearWishlistCache() {
    _productWishlistStatus.clear();
  }
} 