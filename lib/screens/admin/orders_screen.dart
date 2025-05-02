import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gudmerchant/controllers/order_controller.dart';
import 'package:gudmerchant/models/order_model.dart';
import 'package:gudmerchant/models/cart_item_model.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  List<OrderModel> _orders = [];
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  List<OrderModel> _filteredOrders = [];
  String _selectedFilter = 'All';
  final OrderController _orderController = Get.find<OrderController>();
  
  // New stats tracking
  double _totalRevenue = 0;
  double _totalProfit = 0;
  
  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _searchController.addListener(_filterOrders);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_filterOrders);
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Use our controller to get filtered orders
      List<OrderModel> ordersList = await _orderController.getFilteredOrders(_selectedFilter);
      
      // Calculate totals
      _calculateTotals(ordersList);
      
      setState(() {
        _orders = ordersList;
        _filteredOrders = ordersList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch orders: $e';
        _isLoading = false;
      });
    }
  }
  
  void _calculateTotals(List<OrderModel> orders) {
    double revenue = 0;
    double profit = 0;
    
    for (var order in orders) {
      revenue += order.totalAmount;
      profit += order.profit;
    }
    
    setState(() {
      _totalRevenue = revenue;
      _totalProfit = profit;
    });
  }
  
  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    
    List<OrderModel> filtered = _orders;
    
    // Apply search query
    if (query.isNotEmpty) {
      filtered = filtered.where((order) {
        final id = order.id.toLowerCase();
        final userId = order.userId.toLowerCase();
        final address = order.shippingAddress.toLowerCase();
        
        return id.contains(query) || 
               userId.contains(query) || 
               address.contains(query);
      }).toList();
    }
    
    setState(() {
      _filteredOrders = filtered;
    });
  }
  
  void _applyStatusFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _fetchOrders();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _applyStatusFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'All',
                child: Text('All Orders'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending Orders'),
              ),
              const PopupMenuItem(
                value: 'processing',
                child: Text('Processing Orders'),
              ),
              const PopupMenuItem(
                value: 'shipped',
                child: Text('Shipped Orders'),
              ),
              const PopupMenuItem(
                value: 'delivered',
                child: Text('Delivered Orders'),
              ),
              const PopupMenuItem(
                value: 'cancelled',
                child: Text('Cancelled Orders'),
              ),
            ],
            child: Chip(
              label: Text(_selectedFilter),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by order ID, customer ID or address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
              ),
            ),
          ),
          
          // Order statistics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildOrderStats(),
          ),
          
          const SizedBox(height: 8),
          
          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : _filteredOrders.isEmpty
                        ? const Center(child: Text('No orders found'))
                        : ListView.builder(
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              return _buildOrderCard(order);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchOrders,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildOrderStats() {
    final totalOrders = _orders.length;
    final paidOrders = _orders.where((order) => order.isPaid).length;
    final unpaidOrders = totalOrders - paidOrders;
    
    return Column(
      children: [
        // First row - order counts
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Total Orders',
                value: totalOrders.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                label: 'Paid',
                value: paidOrders.toString(),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                label: 'Unpaid',
                value: unpaidOrders.toString(),
                color: Colors.orange,
              ),
            ),
          ],
        ),
        
        // Second row - Revenue and Profit
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Total Revenue',
                value: 'PKR ${_totalRevenue.toStringAsFixed(2)}',
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                label: 'Total Profit (15%)',
                value: 'PKR ${_totalProfit.toStringAsFixed(2)}',
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderCard(OrderModel order) {
    final formattedDate = _formatDate(order.OrderDate);
    final orderShortId = order.id.substring(0, 8);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          'Order #$orderShortId',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$formattedDate • PKR ${order.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: _buildStatusChip(order.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Customer ID', order.userId),
                _buildDetailRow('Items', '${order.items.length} items'),
                _buildDetailRow('Shipping Address', order.shippingAddress),
                _buildDetailRow('Payment Method', order.paymentMethod),
                _buildDetailRow('Payment Status', order.isPaid ? 'Paid' : 'Unpaid'),
                _buildDetailRow('Profit', 'PKR ${order.profit.toStringAsFixed(2)}'),
                
                const Divider(height: 24),
                
                // Item list
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => _buildOrderItem(item)).toList(),
                
                const Divider(height: 24),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PKR ${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                
                // Status management
                const SizedBox(height: 16),
                const Text(
                  'Manage Order Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusManagement(order),
                
                // Actions
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: order.status != OrderStatus.cancelled 
                          ? () => _cancelOrder(order)
                          : null,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                      label: const Text('Cancel Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: order.isPaid ? null : () => _markAsPaid(order),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Mark as Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange;
        break;
      case OrderStatus.processing:
        chipColor = Colors.blue;
        break;
      case OrderStatus.shipped:
        chipColor = Colors.purple;
        break;
      case OrderStatus.delivered:
        chipColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        chipColor = Colors.red;
        break;
    }
    
    return Chip(
      label: Text(
        _capitalizeFirstLetter(status.name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
  
  Widget _buildStatusManagement(OrderModel order) {
    // Don't show status management for cancelled orders
    if (order.status == OrderStatus.cancelled) {
      return const Text(
        'This order has been cancelled and cannot be updated.',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.red),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: OrderStatus.values
          .where((status) => status != OrderStatus.cancelled) // Exclude cancelled status here
          .map((status) {
        final isCurrentStatus = order.status == status;
        
        return FilterChip(
          selected: isCurrentStatus,
          label: Text(_capitalizeFirstLetter(status.name)),
          onSelected: isCurrentStatus
              ? null // Can't select the current status again
              : (_) {
                  _updateOrderStatus(order, status);
                },
          backgroundColor: Colors.grey[200],
          selectedColor: _getStatusColor(status),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isCurrentStatus ? Colors.white : Colors.black,
            fontWeight: isCurrentStatus ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
  
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
  
  Future<void> _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Text(
          'Are you sure you want to change the status from "${_capitalizeFirstLetter(order.status.name)}" to "${_capitalizeFirstLetter(newStatus.name)}"?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      await _orderController.updateOrderStatus(order.id, newStatus);
        _fetchOrders(); // Refresh the list
    }
  }
  
  Future<void> _cancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order'),
        content: Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes, Cancel Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      await _orderController.cancelOrder(order.id);
        _fetchOrders(); // Refresh the list
    }
  }
  
  Future<void> _markAsPaid(OrderModel order) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Mark as Paid'),
          content: Text('Are you sure you want to mark this order as paid?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Mark as Paid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ) ?? false;
      
      if (confirmed) {
        // Update the isPaid field in Firestore
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .update({'isPaid': true});
            
        // Refresh the list
        _fetchOrders();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked as paid successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating payment status: $e')),
      );
    }
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderItem(CartItemModel item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: item.productImage.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.productImage,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 20),
                ),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported, size: 20),
            ),
      title: Text(
        item.productName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('${item.quantity} x PKR ${item.productPrice.toStringAsFixed(2)}'),
      trailing: Text(
        'PKR ${(item.quantity * item.productPrice).toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
  
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
} 