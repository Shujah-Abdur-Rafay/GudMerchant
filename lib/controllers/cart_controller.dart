import 'package:gudmerchant/models/cart_item_model.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class CartController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final RxList<CartItemModel> _cartItems = <CartItemModel>[].obs;
  final RxBool _isLoading = false.obs;
  
  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading.value;
  int get itemCount => _cartItems.length;
  
  double get totalAmount {
    double total = 0.0;
    for (var item in _cartItems) {
      total += item.totalPrice;
    }
    return total;
  }
  
  @override
  void onInit() {
    super.onInit();
    fetchCartItems();
  }
  
  Future<void> fetchCartItems() async {
    try {
      _isLoading.value = true;
      List<CartItemModel> items = await _firebaseService.getCartItems();
      _cartItems.assignAll(items);
    } catch (e) {
      debugPrint('Error fetching cart items: $e');
      Get.snackbar(
        'Error',
        'Failed to load cart items',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    try {
      EasyLoading.show(status: 'Adding to cart...');
      await _firebaseService.addToCart(product, quantity);
      await fetchCartItems();
      EasyLoading.dismiss();
      
      Get.snackbar(
        'Success',
        '${product.name} added to cart',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      EasyLoading.show(status: 'Updating cart...');
      await _firebaseService.updateCartItemQuantity(itemId, quantity);
      await fetchCartItems();
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> removeFromCart(String itemId) async {
    try {
      EasyLoading.show(status: 'Removing item...');
      await _firebaseService.removeFromCart(itemId);
      await fetchCartItems();
      EasyLoading.dismiss();
      
      Get.snackbar(
        'Success',
        'Item removed from cart',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> clearCart() async {
    try {
      EasyLoading.show(status: 'Clearing cart...');
      await _firebaseService.clearCart();
      _cartItems.clear();
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
} 