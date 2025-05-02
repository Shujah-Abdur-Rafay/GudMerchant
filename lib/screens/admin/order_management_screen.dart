import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gudmerchant/controllers/order_controller.dart';
import 'package:gudmerchant/models/order_model.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final OrderController _orderController = Get.find<OrderController>();
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _orderController.adminMode = true;
    
    // Immediately load orders and add post-frame callback for second load
    // to ensure data is fetched as soon as possible
    _orderController.fetchAllOrders();
    
    // Add a second fetch after the UI is built for reliability
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orderController.fetchAllOrders();
    });
  }

  @override
  void dispose() {
    _orderController.adminMode = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = 'All';
              });
            },
            child: Text(
              'All',
              style: TextStyle(
                color: _filterStatus == 'All' 
                    ? AppConstants.primaryColor 
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = 'Paid';
              });
            },
            child: Text(
              'Paid',
              style: TextStyle(
                color: _filterStatus == 'Paid' 
                    ? AppConstants.primaryColor 
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = 'Unpaid';
              });
            },
            child: Text(
              'Unpaid',
              style: TextStyle(
                color: _filterStatus == 'Unpaid' 
                    ? AppConstants.primaryColor 
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Obx(() => _buildOrderStats()), // Wrapped with Obx to update when orders change
          Expanded(
            child: Obx(() {
              if (_orderController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (_orderController.orders.isEmpty) {
                return const Center(child: Text('No orders found'));
              } else {
                final filteredOrders = _filterOrders(_orderController.orders);
                return _buildOrdersList(filteredOrders);
              }
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _orderController.fetchAllOrders();
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by order ID, customer ID or amount',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildOrderStats() {
    // Calculate counts from the actual orders list
    final orders = _orderController.orders;
    int totalOrders = orders.length;
    int paidOrders = orders.where((order) => order.isPaid).length;
    int unpaidOrders = totalOrders - paidOrders;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Orders',
              value: totalOrders.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              title: 'Paid',
              value: paidOrders.toString(),
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              title: 'Unpaid',
              value: unpaidOrders.toString(),
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: _filterStatus == title ? color : Colors.transparent, 
            width: 2
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final isPaid = order.isPaid;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 7,
                  child: Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(isPaid ? 'Paid' : 'Unpaid', isPaid ? Colors.green : Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(order.OrderDate)} • ${AppConstants.formatAsCurrency(order.totalAmount)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Customer ID: ${order.userId.substring(0, math.min(order.userId.length, 12))}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 7,
                  child: Text(
                    'Profit: ${AppConstants.formatAsCurrency(order.profit)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  _capitalizeFirstLetter(order.status.name), 
                  _getStatusColor(order.status)
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _getOrderProgress(order.status),
                        backgroundColor: Colors.grey[200],
                        color: _getStatusColor(order.status),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusStep('Pending', OrderStatus.pending, order.status),
                          _buildStatusStep('Processing', OrderStatus.processing, order.status),
                          _buildStatusStep('Shipped', OrderStatus.shipped, order.status),
                          _buildStatusStep('Delivered', OrderStatus.delivered, order.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Order item preview with thumbnail
            if (order.items.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: order.items.first.productImage.isNotEmpty
                        ? Image.network(
                            order.items.first.productImage,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items.first.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Qty: ${order.items.first.quantity} ${order.items.length > 1 ? '+ ${order.items.length - 1} more items' : ''}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Show details
                    _showOrderDetails(order);
                  },
                  child: const Text('View Details'),
                ),
                if (order.status != OrderStatus.cancelled)
                  ElevatedButton(
                    onPressed: () {
                      // Show order status options
                      _showOrderStatusOptions(order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                    ),
                    child: const Text('Update Status'),
                  ),
                if (order.status != OrderStatus.cancelled)
                  TextButton(
                    onPressed: () {
                      _showCancelConfirmation(order);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    return orders.where((order) {
      // Apply status filter
      if (_filterStatus == 'Paid') {
        if (!order.isPaid) {
          return false;
        }
      } else if (_filterStatus == 'Unpaid') {
        if (order.isPaid) {
          return false;
        }
      }
      
      // Apply search query
      if (_searchQuery.isEmpty) {
        return true;
      }
      
      // Search by order ID, customer ID, or amount
      final query = _searchQuery.toLowerCase();
      return order.id.toLowerCase().contains(query) ||
             order.userId.toLowerCase().contains(query) ||
             order.totalAmount.toString().contains(query);
    }).toList();
  }

  // Helper method to get status color
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
      default:
        return Colors.grey;
    }
  }

  // Show cancel confirmation dialog
  void _showCancelConfirmation(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );
  }

  // Cancel order method
  void _cancelOrder(OrderModel order) async {
    try {
      await _orderController.updateOrderStatus(order.id, OrderStatus.cancelled);
      Get.snackbar(
        'Success',
        'Order cancelled successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel order: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Show order details
  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer ID', order.userId),
              _buildDetailRow('Total Amount', AppConstants.formatAsCurrency(order.totalAmount)),
              _buildDetailRow('Profit', AppConstants.formatAsCurrency(order.profit)),
              _buildDetailRow('Status', order.status.name),
              _buildDetailRow('Payment Status', order.isPaid ? 'Paid' : 'Unpaid'),
              _buildDetailRow('Payment Method', order.paymentMethod),
              _buildDetailRow('Date', _formatDate(order.OrderDate)),
              _buildDetailRow('Address', order.shippingAddress),
              const Divider(),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => ListTile(
                leading: item.productImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          item.productImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                          ),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 20, color: Colors.grey),
                      ),
                title: Text(
                  item.productName,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('Qty: ${item.quantity}'),
                trailing: Text(AppConstants.formatAsCurrency(item.productPrice * item.quantity)),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('MMM d, y');
    return formatter.format(date);
  }

  // Show order status management dialog
  void _showOrderStatusOptions(OrderModel order) {
    // Don't show options if the order is already cancelled
    if (order.status == OrderStatus.cancelled) {
      Get.snackbar(
        'Cannot Update',
        'Cancelled orders cannot be updated',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Status: ${_capitalizeFirstLetter(order.status.name)}', 
              style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(order.status))),
            const SizedBox(height: 16),
            const Text('Select new status:'),
            const SizedBox(height: 8),
            _buildStatusRadioTiles(order, context),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRadioTiles(OrderModel order, BuildContext context) {
    // Define which status options to show based on current status
    List<OrderStatus> availableStatuses = [];
    
    switch (order.status) {
      case OrderStatus.pending:
        availableStatuses = [OrderStatus.processing, OrderStatus.cancelled];
        break;
      case OrderStatus.processing:
        availableStatuses = [OrderStatus.shipped, OrderStatus.cancelled];
        break;
      case OrderStatus.shipped:
        availableStatuses = [OrderStatus.delivered, OrderStatus.cancelled];
        break;
      case OrderStatus.delivered:
        // No status changes available for delivered orders
        availableStatuses = [];
        break;
      case OrderStatus.cancelled:
        // No status changes available for cancelled orders
        availableStatuses = [];
        break;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show current status message
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Current Status: ${_capitalizeFirstLetter(order.status.name)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getStatusColor(order.status),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Only build status tiles for available statuses
        if (availableStatuses.isEmpty)
          const Text('No status changes available for this order.'),
          
        if (availableStatuses.contains(OrderStatus.processing))
          _buildStatusTile(
            context: context,
            order: order, 
            status: OrderStatus.processing, 
            title: 'Processing',
            subtitle: 'Order is being processed',
            icon: Icons.hourglass_empty,
            color: Colors.blue,
          ),
        
        if (availableStatuses.contains(OrderStatus.shipped))
          _buildStatusTile(
            context: context,
            order: order, 
            status: OrderStatus.shipped, 
            title: 'Shipped',
            subtitle: 'Order has been shipped',
            icon: Icons.local_shipping,
            color: Colors.purple,
          ),
        
        if (availableStatuses.contains(OrderStatus.delivered))
          _buildStatusTile(
            context: context,
            order: order, 
            status: OrderStatus.delivered, 
            title: 'Delivered',
            subtitle: 'Order has been delivered',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        
        if (availableStatuses.contains(OrderStatus.cancelled))
          _buildStatusTile(
            context: context,
            order: order, 
            status: OrderStatus.cancelled, 
            title: 'Cancelled',
            subtitle: 'Cancel the order',
            icon: Icons.cancel,
            color: Colors.red,
          ),
      ],
    );
  }

  Widget _buildStatusTile({
    required BuildContext context,
    required OrderModel order, 
    required OrderStatus status, 
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isCurrentStatus = order.status == status;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCurrentStatus ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: isCurrentStatus ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(subtitle),
        tileColor: isCurrentStatus ? color.withOpacity(0.1) : null,
        onTap: isCurrentStatus ? null : () {
          Navigator.of(context).pop();
          _updateOrderStatus(order, status);
        },
        trailing: isCurrentStatus 
          ? const Icon(Icons.check, color: Colors.green)
          : const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  // Update order status
  void _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    try {
      if (newStatus == OrderStatus.cancelled) {
        _showCancelConfirmation(order);
        return;
      }

      // Confirm status change
      final confirmChange = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Status Change'),
          content: Text(
            'Are you sure you want to change the status from '
            '"${_capitalizeFirstLetter(order.status.name)}" to '
            '"${_capitalizeFirstLetter(newStatus.name)}"?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _getStatusColor(newStatus)),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmChange == true) {
        await _orderController.updateOrderStatus(order.id, newStatus);
        Get.snackbar(
          'Success',
          'Order status updated to ${_capitalizeFirstLetter(newStatus.name)}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order status: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Calculate order progress for the progress indicator
  double _getOrderProgress(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0.0;
      case OrderStatus.processing:
        return 0.33;
      case OrderStatus.shipped:
        return 0.66;
      case OrderStatus.delivered:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
      default:
        return 0.0;
    }
  }
  
  // Build a single status step indicator
  Widget _buildStatusStep(String label, OrderStatus status, OrderStatus currentStatus) {
    final bool isActive = currentStatus.index >= status.index && currentStatus != OrderStatus.cancelled;
    final bool isCurrent = currentStatus == status;
    
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isActive ? _getStatusColor(status) : Colors.grey[300],
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: Colors.white, width: 3) : null,
            boxShadow: isCurrent ? [
              BoxShadow(
                color: _getStatusColor(status).withOpacity(0.5),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ] : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? _getStatusColor(status) : Colors.grey,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
} 