import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gudmerchant/models/order_model.dart';
import 'package:gudmerchant/controllers/order_controller.dart';
import 'package:gudmerchant/controllers/product_controller.dart';
import 'package:gudmerchant/screens/admin/admin_notifications_screen.dart';
import 'package:gudmerchant/screens/admin/user_management_panel.dart';
import 'package:gudmerchant/screens/admin/product_management_screen.dart';
import 'package:gudmerchant/screens/admin/orders_screen.dart';
import 'package:gudmerchant/screens/admin/product_generator_screen.dart';
import 'package:gudmerchant/screens/admin/order_management_screen.dart';
import 'package:gudmerchant/screens/admin/inventory_management_screen.dart';
// import 'package:gudmerchant/models/statistics_model.dart'; // Commented out missing import
import 'package:gudmerchant/services/admin_service.dart';
// import 'package:gudmerchant/services/statistics_service.dart'; // Commented out missing import
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:gudmerchant/utils/db_initializer.dart';
// import 'package:gudmerchant/utils/app_theme.dart'; // Commented out if not needed
// import 'package:gudmerchant/widgets/admin/admin_stat_card.dart'; // Commented out missing import
// import 'package:gudmerchant/widgets/admin/sales_chart.dart'; // Commented out missing import
// import 'package:gudmerchant/widgets/admin/recent_orders_card.dart'; // Commented out missing import
import 'dart:math' as math;

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OrderController _orderController;
  final DbInitializer _dbInitializer = DbInitializer();
  late ProductController _productController;
  bool _controllersInitialized = false;

  final List<String> _tabTitles = [
    'Dashboard',
    'Orders',
    'Products',
    'Inventory',
    'Users',
    'Notifications'
  ];
  final List<double> _weeklySales = [4500, 5200, 3800, 6100, 5400, 7800, 6500];
  final List<String> _daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initControllers();
  }

  void _initControllers() {
    try {
      _orderController = Get.find<OrderController>();
      _productController = Get.find<ProductController>();
      _controllersInitialized = true;
      _orderController.fetchUserOrders();
    } catch (e) {
      debugPrint('Error initializing controllers in Admin Panel: $e');
      _controllersInitialized = false;

      // Show an error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Some controllers failed to initialize. App may not work correctly.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ));
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _orderController.forceRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data refreshed')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Show admin settings
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Dashboard'),
            Tab(text: 'Orders'),
            Tab(text: 'Products'),
            Tab(text: 'Inventory'),
            Tab(text: 'Users'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.primaryColor,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          const OrderManagementScreen(),
          const ProductManagementScreen(),
          const InventoryManagementScreen(),
          const UserManagementPanel(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0
                ? Icons.dashboard
                : Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 1
                ? Icons.shopping_bag
                : Icons.shopping_bag_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 2
                ? Icons.inventory
                : Icons.inventory_outlined),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(
                _selectedIndex == 3 ? Icons.person : Icons.person_outlined),
            label: 'Users',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Navigate based on selected index
          switch (index) {
            case 0:
              // Dashboard tab
              _tabController.animateTo(0);
              break;
            case 1:
              // Orders tab
              _tabController.animateTo(1);
              break;
            case 2:
              // Products tab
              _tabController.animateTo(2);
              break;
            case 3:
              // Users tab
              _tabController.animateTo(4);
              break;
          }
        },
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsSection(),
          const SizedBox(height: 24),
          _buildSalesGraph(),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Obx(() {
      if (!_controllersInitialized || _orderController.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      
      // Calculate real statistics from order data
      final allOrders = _orderController.orders;
      final pendingOrders = allOrders.where((order) => order.status == OrderStatus.pending).length;
      
      double totalRevenue = 0;
      double totalProfit = 0;
      
      for (final order in allOrders) {
        totalRevenue += order.totalAmount;
        totalProfit += order.profit;
      }
      
      // Count low stock items (example implementation)
      final lowStockItems = _productController.products
          .where((product) => product.stock < 10)
          .length;
      
      return SizedBox(
        width: double.infinity,
        child: GridView.count(
        crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStatCard(
            title: 'Total Orders',
            value: allOrders.length.toString(),
            icon: Icons.shopping_bag,
            color: Colors.blue,
          ),
          _buildStatCard(
            title: 'Pending Orders',
            value: pendingOrders.toString(),
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
          _buildStatCard(
            title: 'Total Revenue',
            value: AppConstants.formatAsCurrency(totalRevenue),
            icon: Icons.attach_money,
            color: Colors.green,
          ),
          _buildStatCard(
            title: 'Total Profit',
            value: AppConstants.formatAsCurrency(totalProfit),
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ],
        ),
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 12,
                    color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
              value,
              style: const TextStyle(
                  fontSize: 18,
                fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesGraph() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Sales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total PKR39,358',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 8000,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'PKR ${_weeklySales[groupIndex].toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(_daysOfWeek[
                                value.toInt() % _daysOfWeek.length]),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          if (value % 2000 != 0) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              'PKR ${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _weeklySales.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: AppConstants.primaryColor,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Initialize database with categories and products
                    _dbInitializer.initializeDatabase();
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Initialize Categories & Products'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Products
          TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 16),

          // Product List
          Expanded(
            child: ListView.builder(
              itemCount: 15, // Sample data
              itemBuilder: (context, index) {
                final bool isLowStock = index % 7 == 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Product Image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Product Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: PRD-${10000 + index}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'PKR ${(50 + index * 10).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLowStock
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isLowStock
                                          ? 'Low Stock: 3'
                                          : 'In Stock: ${20 + index}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isLowStock
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                // Edit product
                              },
                              tooltip: 'Edit Product',
                            ),
                            IconButton(
                              icon: const Icon(Icons.update),
                              onPressed: () {
                                // Update stock
                                _showUpdateStockDialog(index);
                              },
                              tooltip: 'Update Stock',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(int index) {
    TextEditingController stockController =
        TextEditingController(text: '${20 + index}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock for Product ${index + 1}'),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update stock logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Stock updated for Product ${index + 1}')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
