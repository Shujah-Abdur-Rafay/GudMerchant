import 'package:gudmerchant/controllers/auth_controller.dart';
import 'package:gudmerchant/controllers/cart_controller.dart';
import 'package:gudmerchant/controllers/product_controller.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:gudmerchant/screens/cart/cart_screen.dart';
import 'package:gudmerchant/screens/category/category_screen.dart';
import 'package:gudmerchant/screens/order/order_debug_screen.dart';
import 'package:gudmerchant/screens/order/order_history_screen.dart';
import 'package:gudmerchant/screens/product/product_details_screen.dart';
import 'package:gudmerchant/screens/profile/profile_screen.dart';
import 'package:gudmerchant/screens/profile/settings_screen.dart';
import 'package:gudmerchant/screens/profile/wishlist_screen.dart';
import 'package:gudmerchant/screens/auth-ui/SignInScreen.dart';
import 'package:gudmerchant/screens/search/search_screen.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:gudmerchant/widgets/lottie_compat.dart';
import 'package:gudmerchant/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:gudmerchant/services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    
    // Explicitly load products with proper loading state handling
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ProductController productController = Get.find<ProductController>();
      
      // One-time cleanup to permanently remove mock products from database
      await _cleanupMockProducts();
      
      // Load products in parallel to reduce wait time
      await Future.wait([
        productController.fetchProducts(),
        productController.fetchFeaturedProducts(),
        productController.fetchRecommendedProducts(),
      ]);
      
      // Force UI update
      if (mounted) setState(() {});
    });
    
    // Check if we have tab index from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.arguments != null && Get.arguments is int) {
        int tabIndex = Get.arguments as int;
        if (tabIndex >= 0 && tabIndex < 5) {
          // Make sure it's a valid index
          setState(() {
            _selectedIndex = tabIndex;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController;
    final ProductController productController;
    final CartController cartController;

    try {
      authController = Get.find<AuthController>();
      productController = Get.find<ProductController>();
      cartController = Get.find<CartController>();
    } catch (e) {
      debugPrint('Error finding controllers in HomeScreen: $e');
      // Show an error message and navigate to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error loading app data. Please log in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
        Get.offAll(() => const Signinscreen());
      });

      // Return a simple loading screen while we navigate away
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading app data...')
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, authController),
      onDrawerChanged: (isOpened) {
        // This helps track drawer state
        debugPrint('Drawer is ${isOpened ? 'opened' : 'closed'}');
      },
      body: _selectedIndex == 0
          ? _buildHomeContent(authController, productController, cartController)
          : _buildNavigationPage(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BottomNavigationBar(
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
                icon: Icon(
                    _selectedIndex == 0 ? Icons.home : Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 1
                    ? Icons.category
                    : Icons.category_outlined),
                label: 'Categories',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 2
                    ? Icons.shopping_cart
                    : Icons.shopping_cart_outlined),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 3
                    ? Icons.receipt
                    : Icons.receipt_outlined),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                    _selectedIndex == 4 ? Icons.person : Icons.person_outlined),
                label: 'Profile',
              ),
            ],
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationPage(int index) {
    switch (index) {
      case 1:
        return CategoryScreen();
      case 2:
        return const CartScreen();
      case 3:
        return const OrderHistoryScreen();
      case 4:
        return const ProfileScreen();
      default:
        return Container();
    }
  }

  Widget _buildHomeContent(AuthController authController,
      ProductController productController, CartController cartController) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.black87,
              onPressed: _openDrawer,
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),
            title: Text(
              'Home',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                color: Colors.black87,
                onPressed: () {
                  // Navigate to search screen
                  Get.to(() => const SearchScreen());
                },
              ),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded),
                    color: Colors.black87,
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                  Obx(() => cartController.itemCount > 0
                      ? Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartController.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Container()),
                ],
              ),
              // Force Logout Button
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Force Logout',
                onPressed: () {
                  authController.forceSignOut();
                  debugPrint('🚪 Force logout requested');
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Obx(() {
              if (productController.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await productController.fetchProducts();
                  await productController.fetchFeaturedProducts();
                  await productController.fetchRecommendedProducts();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome User with card
                      Container(
                        margin: const EdgeInsets.only(top: 20, bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppConstants.primaryColor,
                              AppConstants.primaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Obx(() {
                                    final username =
                                        authController.userModel?.username ??
                                            'Guest';
                                    return Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedIndex = 4;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side:
                                          const BorderSide(color: Colors.white),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'View Profile',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 30,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Categories
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoriesRow(productController),

                      const SizedBox(height: 24),

                      // Featured Products
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Featured Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 1;
                              });
                            },
                            child: Text(
                              'See All',
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFeaturedProducts(productController),

                      const SizedBox(height: 24),

                      // All Products (formerly Recommended Products)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Show all products
                            },
                            child: Text(
                              'See All',
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRecommendedProducts(productController),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow(ProductController productController) {
    final categories = productController.categoryProducts.keys.toList();

    if (categories.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const Text('No categories available'),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CategoryScreen(selectedCategory: category),
                ),
              );
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _getCategoryIcon(category),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData iconData;

    switch (category.toLowerCase()) {
      case 'electronics':
        iconData = Icons.devices_rounded;
        break;
      case 'clothing':
        iconData = Icons.checkroom_rounded;
        break;
      case 'home & kitchen':
        iconData = Icons.kitchen_rounded;
        break;
      case 'beauty & personal care':
        iconData = Icons.spa_rounded;
        break;
      case 'sports & outdoors':
        iconData = Icons.sports_soccer_rounded;
        break;
      default:
        iconData = Icons.category_rounded;
    }

    return Icon(
      iconData,
      color: AppConstants.primaryColor,
      size: 30,
    );
  }

  Widget _buildFeaturedProducts(ProductController productController) {
    // If there are no featured products, display a message
    if (productController.featuredProducts.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: const Column(
            children: [
              Icon(
                Icons.star_border_rounded,
                size: 48,
                color: Colors.amber,
              ),
              SizedBox(height: 16),
              Text(
                'No featured products available',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Check back later for featured items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productController.featuredProducts.length,
        itemBuilder: (context, index) {
          final product = productController.featuredProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildRecommendedProducts(ProductController productController) {
    // If there are no products, display a message
    if (productController.recommendedProducts.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: const Column(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              Text(
                'No products available',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Check back later for more products',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productController.recommendedProducts.length,
        itemBuilder: (context, index) {
          final product = productController.recommendedProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailsScreen(productId: product.id));
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        child: ProductCard(
          product: product,
          showAddButton: true,
        ),
      ),
    );
  }

  // Build the drawer menu
  Widget _buildDrawer(BuildContext context, AuthController authController) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header with user info
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final isLoggedIn = authController.isLoggedIn;
                  final username =
                      authController.userModel?.username ?? 'Guest';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar or icon
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          isLoggedIn ? Icons.person : Icons.person_outline,
                          size: 40,
                          color: AppConstants.primaryColor,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Username
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Email if logged in
                      if (isLoggedIn && authController.userModel?.email != null)
                        Text(
                          authController.userModel!.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Home
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),

          // Categories
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),

          // Cart
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('My Cart'),
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.pop(context);
            },
          ),

          // Orders
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('My Orders'),
            onTap: () {
              setState(() {
                _selectedIndex = 3;
              });
              Navigator.pop(context);
            },
          ),

          // Profile
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              setState(() {
                _selectedIndex = 4;
              });
              Navigator.pop(context);
            },
          ),

          const Divider(),

          // Wishlist
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('My Wishlist'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const WishlistScreen());
            },
          ),

          // Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const SettingsScreen());
            },
          ),

          // Help & Support
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help screen
            },
          ),

          // Login/Logout
          Obx(() {
            final isLoggedIn = authController.isLoggedIn;

            return ListTile(
              leading: Icon(isLoggedIn ? Icons.logout : Icons.login),
              title: Text(isLoggedIn ? 'Logout' : 'Login'),
              onTap: () {
                Navigator.pop(context);

                if (isLoggedIn) {
                  // Show confirmation dialog
                  Get.defaultDialog(
                    title: 'Logout',
                    middleText: 'Are you sure you want to logout?',
                    textConfirm: 'Logout',
                    textCancel: 'Cancel',
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      authController.signOut();
                      Get.back();
                    },
                  );
                } else {
                  // Navigate to login screen
                  Get.to(() => const Signinscreen());
                }
              },
            );
          }),

          // App version
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'App Version 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // One-time cleanup function to remove mock products from database
  Future<void> _cleanupMockProducts() async {
    try {
      final mockProductNames = [
        'Wireless Earbuds',
        'Smart Watch',
        'Bluetooth Speaker',
        'Men\'s Casual Shirt',
        'Women\'s Summer Dress',
        'Coffee Maker',
        'Cookware Set',
        'Bestselling Novel',
        'Cookbook', 
        'Skincare Set',
        'Perfume',
        'Yoga Mat',
        'Hiking Backpack',
        'Board Game',
        'RC Car',
        'Silver Necklace',
        'Gold Bracelet'
      ];
      
      // Get a reference to Firestore
      final firestore = Get.find<FirebaseService>().productsRef;
      
      // Find products with mock names
      for (final mockName in mockProductNames) {
        final snapshot = await firestore.where('name', isEqualTo: mockName).get();
        
        if (snapshot.docs.isNotEmpty) {
          debugPrint('🧹 Found ${snapshot.docs.length} instances of mock product: $mockName');
          
          // Delete each mock product
          for (final doc in snapshot.docs) {
            await firestore.doc(doc.id).delete();
            debugPrint('🗑️ Deleted mock product: $mockName (ID: ${doc.id})');
          }
        }
      }
      
      // Find products with unsplash image URLs (another indicator of mock data)
      final allProducts = await firestore.get();
      int deletedCount = 0;
      
      for (final doc in allProducts.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> images = data['images'] ?? [];
        
        if (images.isNotEmpty) {
          final String imageUrl = images[0].toString().toLowerCase();
          if (imageUrl.contains('unsplash.com')) {
            await firestore.doc(doc.id).delete();
            deletedCount++;
            debugPrint('🗑️ Deleted product with mock image: ${data['name']} (ID: ${doc.id})');
          }
        }
      }
      
      if (deletedCount > 0) {
        debugPrint('🧹 Cleaned up $deletedCount additional mock products with unsplash images');
      }
      
      debugPrint('✅ Mock product cleanup completed');
    } catch (e) {
      debugPrint('❌ Error cleaning up mock products: $e');
    }
  }
}
