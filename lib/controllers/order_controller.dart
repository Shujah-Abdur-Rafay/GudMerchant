import 'package:gudmerchant/models/cart_item_model.dart';
import 'package:gudmerchant/models/order_model.dart';
import 'package:gudmerchant/models/payment_details_model.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:gudmerchant/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final RxList<OrderModel> _orders = <OrderModel>[].obs;
  final RxBool _isLoading = false.obs;
  
  // Filter for admin order management
  final RxString _statusFilter = 'All'.obs;
  String get statusFilter => _statusFilter.value;
  set statusFilter(String value) => _statusFilter.value = value;
  
  // Admin mode flag to fetch all orders instead of just user orders
  final RxBool _adminMode = false.obs;
  bool get adminMode => _adminMode.value;
  set adminMode(bool value) => _adminMode.value = value;
  
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading.value;
  
  StreamSubscription? _authSubscription;
  
  @override
  void onInit() {
    super.onInit();
    // Fetch orders when controller initializes
    fetchUserOrders();
    
    // Set up listener for auth changes to reload orders when user logs in/out
    _authSubscription = _firebaseService.userChanges.listen((_) {
      if (adminMode) {
        fetchAllOrders();
      } else {
      fetchUserOrders();
      }
    });
  }
  
  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
  
  Future<void> forceRefresh() async {
    _orders.clear(); // Clear existing orders first
    
    if (adminMode) {
      await fetchAllOrders();
    } else {
    await fetchUserOrders();
    }
    
    // Show notification to inform user that refresh is complete
    Get.snackbar(
      'Order History',
      'Order history has been refreshed${_orders.isEmpty ? " (No orders found)" : " (" + _orders.length.toString() + " orders)"}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
  
  Future<void> fetchUserOrders() async {
    try {
      if (_isLoading.value) return; // Prevent multiple concurrent fetches
      
      _isLoading.value = true;
      debugPrint('🔄 Fetching user orders...');
      
      // Check if user is logged in
      final userId = _firebaseService.userId;
      debugPrint('👤 Current user ID: $userId');
      
      if (userId.isEmpty) {
        debugPrint('⚠️ No user ID available, skipping fetch');
        _orders.clear();
        return;
      }
      
      List<OrderModel> userOrders = await _firebaseService.getUserOrders();
      debugPrint('📋 Orders fetched: ${userOrders.length}');
      
      // Log order details for debugging
      for (var order in userOrders) {
        debugPrint('📦 Order ID: ${order.id}, Date: ${order.OrderDate}, Status: ${order.status}, Items: ${order.items.length}');
      }
      
      _orders.assignAll(userOrders);
      
      debugPrint('✅ Orders updated in controller. Count: ${_orders.length}');
    } catch (e) {
      debugPrint('❌ Error fetching user orders: $e');
      Get.snackbar(
        'Error',
        'Failed to load order history',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<bool> placeOrder({
    required List<CartItemModel> items,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
    PaymentDetailsModel? paymentDetails,
  }) async {
    try {
      EasyLoading.show(status: 'Placing order...');
      
      debugPrint('🔄 Placing order with ${items.length} items, total: $totalAmount');
      debugPrint('💳 Payment method: $paymentMethod');
      
      if (paymentDetails != null) {
        debugPrint('📋 Payment details provided: ${paymentDetails.paymentMethod}');
      } else {
        debugPrint('📋 No payment details provided (likely Cash on Delivery)');
      }
      
      // Calculate profit (15% of total)
      double profit = totalAmount * 0.15;
      debugPrint('💰 Calculated profit: PKR ${profit.toStringAsFixed(2)}');
      
      String orderId = await _firebaseService.placeOrder(
        items: items,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
        profit: profit,
      );
      
      debugPrint('✅ Order placed successfully with ID: $orderId');
      
      // Force refresh order list with slight delay to ensure Firestore has updated
      await Future.delayed(const Duration(milliseconds: 500));
      await forceRefresh();
      
      // Get the newly created order for notification
      final newOrder = await _firebaseService.getOrderById(orderId);
      if (newOrder != null) {
        // Send notification
        await _notificationService.showOrderPlacedNotification(newOrder);
      }
      
      EasyLoading.dismiss();
      
      Get.snackbar(
        'Success',
        'Order placed successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      
      // Debug print when returning success
      debugPrint('✅ Returning success=true from order controller');
      return true;
    } catch (e) {
      debugPrint('❌ Error placing order: $e');
      EasyLoading.dismiss();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      // Debug print when returning failure
      debugPrint('❌ Returning success=false from order controller');
      return false;
    }
  }
  
  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhereOrNull((order) => order.id == orderId);
    } catch (e) {
      debugPrint('Error getting order by ID: $e');
      return null;
    }
  }
  
  // Fetch all orders (for admin use)
  Future<void> fetchAllOrders() async {
    try {
      if (_isLoading.value) return; // Prevent multiple concurrent fetches
      
      _isLoading.value = true;
      debugPrint('🔄 Admin: Fetching all orders...');
      
      // Get all orders
      List<OrderModel> allOrders = await _firebaseService.getAllOrders();
      debugPrint('📋 Admin: All orders fetched: ${allOrders.length}');
      
      _orders.assignAll(allOrders);
      
      debugPrint('✅ Admin: Orders updated in controller. Count: ${_orders.length}');
    } catch (e) {
      debugPrint('❌ Admin: Error fetching all orders: $e');
      Get.snackbar(
        'Error',
        'Failed to load orders',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<List<OrderModel>> getFilteredOrders(String statusFilter) async {
    try {
      final allOrders = await fetchAllOrders();
      
      if (statusFilter == 'All') {
        return [];
      }
      
      final OrderStatus filterStatus = OrderStatus.values.firstWhere(
        (e) => e.name == statusFilter,
        orElse: () => OrderStatus.pending,
      );
      
      List<OrderModel> filteredOrders = _orders.where((order) => order.status == filterStatus).toList();
      return filteredOrders;
    } catch (e) {
      debugPrint('Error filtering orders: $e');
      return [];
    }
  }
  
  /// Filters orders by status
  List<OrderModel> _filterOrders(List<OrderModel> orders, String filterStatus) {
    if (filterStatus == 'All') {
      return orders;
    } else if (filterStatus == 'Paid') {
      return orders.where((order) => order.isPaid).toList();
    } else if (filterStatus == 'Unpaid') {
      return orders.where((order) => !order.isPaid).toList();
    } else {
      // Filter by order status (pending, processing, etc.)
      final OrderStatus status = _getOrderStatusFromString(filterStatus);
      return orders.where((order) => order.status == status).toList();
    }
  }
  
  /// Converts string to OrderStatus enum
  OrderStatus _getOrderStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
  
  /// Update the status of an order
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      debugPrint('🔄 Updating order $orderId status to ${newStatus.name}');
      _isLoading.value = true;
      
      // Get the order reference
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
      
      // Update the status field
      await orderRef.update({
        'status': newStatus.name,
        // If status is delivered or cancelled, update isPaid field accordingly
        if (newStatus == OrderStatus.delivered) 'isPaid': true,
      });
      
      // Update the local copy
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = OrderModel(
          id: _orders[index].id,
          userId: _orders[index].userId,
          items: _orders[index].items,
          totalAmount: _orders[index].totalAmount,
          shippingAddress: _orders[index].shippingAddress,
          status: newStatus,
          OrderDate: _orders[index].OrderDate,
          paymentMethod: _orders[index].paymentMethod,
          isPaid: newStatus == OrderStatus.delivered ? true : _orders[index].isPaid,
          paymentDetails: _orders[index].paymentDetails,
          profit: _orders[index].profit,
        );
        
        // Update the order in the observable list
        _orders[index] = updatedOrder;
        // Notify observers that the list has changed
        _orders.refresh();
      }
      
      debugPrint('✅ Order status updated successfully');
      
      // Get updated order for notification
      final updatedOrder = await _firebaseService.getOrderById(orderId);
      if (updatedOrder != null) {
        // Send notification about status update
        await _notificationService.showOrderStatusUpdateNotification(updatedOrder);
      }
      
      // Force refresh the order list to ensure UI is updated
      await forceRefresh();
      
    } catch (e) {
      debugPrint('❌ Error updating order status: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<bool> cancelOrder(String orderId) async {
    try {
      EasyLoading.show(status: 'Cancelling order...');
      
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': OrderStatus.cancelled.name});
      
      // Get updated order for notification
      final updatedOrder = await _firebaseService.getOrderById(orderId);
      if (updatedOrder != null) {
        // Send notification about cancellation
        await _notificationService.showOrderStatusUpdateNotification(updatedOrder);
      }
      
      EasyLoading.dismiss();
      
      Get.snackbar(
        'Success',
        'Order cancelled successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      EasyLoading.dismiss();
      
      Get.snackbar(
        'Error',
        'Failed to cancel order: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      
      return false;
    }
  }
  
  // Get total revenue and profit statistics
  Future<Map<String, double>> getOrderStatistics() async {
    try {
      final List<OrderModel> orders = _orders.toList();
      
      double totalRevenue = 0;
      double totalProfit = 0;
      int completedOrders = 0;
      int pendingOrders = 0;
      
      for (var order in orders) {
        totalRevenue += order.totalAmount;
        
        // Calculate profit as 15% if not already stored
        final profit = _getOrderProfit(order);
        totalProfit += profit;
        
        if (order.status == OrderStatus.delivered) {
          completedOrders++;
        } else if (order.status == OrderStatus.pending) {
          pendingOrders++;
        }
      }
      
      return {
        'revenue': totalRevenue,
        'profit': totalProfit,
        'completedOrders': completedOrders.toDouble(),
        'pendingOrders': pendingOrders.toDouble(),
      };
    } catch (e) {
      debugPrint('Error calculating order statistics: $e');
      return {
        'revenue': 0,
        'profit': 0,
        'completedOrders': 0,
        'pendingOrders': 0,
      };
    }
  }
  
  // Helper function to get order profit
  double _getOrderProfit(OrderModel order) {
    // Try to get profit from Firestore data, or calculate as 15% of total
    try {
      // Get the order document to check if profit field exists
      final orderDoc = FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id);
      
      // If profit doesn't exist in database, calculate it
      return order.totalAmount * 0.15;
    } catch (e) {
      debugPrint('Error getting profit for order ${order.id}: $e');
      return order.totalAmount * 0.15; // Default calculation
    }
  }
}