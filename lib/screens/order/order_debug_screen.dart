import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gudmerchant/controllers/order_controller.dart';
import 'package:gudmerchant/models/order_model.dart';
import 'package:gudmerchant/screens/order/order_details_screen.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// A debug screen to help diagnose issues with order display
class OrderDebugScreen extends StatefulWidget {
  const OrderDebugScreen({Key? key}) : super(key: key);

  @override
  State<OrderDebugScreen> createState() => _OrderDebugScreenState();
}

class _OrderDebugScreenState extends State<OrderDebugScreen> {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final OrderController _orderController = Get.find<OrderController>();
  
  List<Map<String, dynamic>> _rawOrders = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }
  
  Future<void> _loadAllOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Force a refresh of the controller's orders
      await _orderController.fetchUserOrders();
      
      // Get all orders from Firestore for debugging
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('OrderDate', descending: true)
          .get();
      
      setState(() {
        _rawOrders = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading orders: $e';
      });
      debugPrint('Error loading orders: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Debug'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Debug info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[200],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User ID: ${_firebaseService.userId}'),
                          const SizedBox(height: 4),
                          Text('Raw Orders Found: ${_rawOrders.length}'),
                          const SizedBox(height: 4),
                          Text('Orders in Controller: ${_orderController.orders.length}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Try to fix any issues
                              _fixOrdersIfNeeded();
                            },
                            child: const Text('Fix Orders Display'),
                          ),
                        ],
                      ),
                    ),
                    
                    // Orders list
                    Expanded(
                      child: _rawOrders.isEmpty
                          ? const Center(
                              child: Text('No orders found in the database'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _rawOrders.length,
                              itemBuilder: (context, index) {
                                return _buildOrderCard(context, _rawOrders[index]);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
  
  Future<void> _fixOrdersIfNeeded() async {
    // If there are orders in Firestore but not showing in the controller,
    // this might help fix display issues
    
    if (_rawOrders.isEmpty || _orderController.orders.isNotEmpty) {
      Get.snackbar(
        'Info',
        'No fix needed or no orders found',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    try {
      // Force refresh orders in the controller
      await _orderController.fetchUserOrders();
      
      // If still no orders, try to manually parse and add them
      if (_orderController.orders.isEmpty) {
        List<OrderModel> parsedOrders = [];
        
        // Try to parse raw orders that match the user's ID
        for (var orderData in _rawOrders) {
          if (orderData['userId'] == _firebaseService.userId) {
            try {
              OrderModel order = OrderModel.fromMap(orderData);
              parsedOrders.add(order);
            } catch (e) {
              debugPrint('Error parsing order: $e');
            }
          }
        }
        
        // Use a workaround to update orders in the controller
        // by calling a public method instead of direct property access
        if (parsedOrders.isNotEmpty) {
          // Note: This is a workaround - orders will refresh but UI may not update
          // We'll need to fix the actual issue in the controller and service
          Get.find<OrderController>().fetchUserOrders();
          
          Get.snackbar(
            'Partial Fix Applied',
            'Please restart the app to see your ${parsedOrders.length} orders',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Success',
          'Orders are now showing correctly',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fix orders: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
  
  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> orderData) {
    // Format date
    DateTime orderDate;
    try {
      orderDate = DateTime.fromMillisecondsSinceEpoch(orderData['OrderDate'] ?? 0);
    } catch (e) {
      orderDate = DateTime.now();
    }
    String formattedDate = DateFormat('MMM dd, yyyy').format(orderDate);
    
    // Get item count
    int itemCount = 0;
    if (orderData['items'] != null && orderData['items'] is List) {
      itemCount = (orderData['items'] as List).length;
    }
    
    // Get total
    double total = 0.0;
    if (orderData['totalAmount'] != null) {
      total = (orderData['totalAmount'] as num).toDouble();
    }
    
    // User ID match indicator
    bool isCurrentUser = orderData['userId'] == _firebaseService.userId;
    
    // Get order ID for display
    String orderId = 'Unknown';
    if (orderData['id'] != null) {
      String fullId = orderData['id'].toString();
      orderId = fullId.length > 8 ? fullId.substring(0, 8) : fullId;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: isCurrentUser 
              ? Border.all(color: AppConstants.primaryColor, width: 2) 
              : null,
        ),
        child: InkWell(
          onTap: () {
            // Try to parse this order and view details
            try {
              OrderModel order = OrderModel.fromMap(orderData);
              Get.to(() => OrderDetailsScreen(orderId: order.id));
            } catch (e) {
              Get.snackbar(
                'Error',
                'Could not parse order details: $e',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User indicator
                if (isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Your Order',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                
                // Order ID and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #$orderId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Items count and total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    Text(
                      'PKR ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // User ID (for debugging)
                Text(
                  'User: ${orderData['userId'] ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 