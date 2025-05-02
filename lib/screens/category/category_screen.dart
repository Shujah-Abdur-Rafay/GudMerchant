import 'package:gudmerchant/controllers/product_controller.dart';
import 'package:gudmerchant/data/mock_categories.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:gudmerchant/screens/product/product_details_screen.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:gudmerchant/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryScreen extends StatefulWidget {
  final String? selectedCategory;
  
  const CategoryScreen({Key? key, this.selectedCategory}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late String _currentCategory;
  
  @override
  void initState() {
    super.initState();
    final ProductController productController = Get.find<ProductController>();
    final categories = productController.categoryProducts.keys.toList();
    
    _currentCategory = widget.selectedCategory ?? 
      (categories.isNotEmpty ? categories.first : '');
    
    // Explicitly load products since we disabled auto-loading in ProductController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      productController.fetchProductsByCategory(_currentCategory);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final ProductController productController = Get.find<ProductController>();
    final categories = productController.categoryProducts.keys.toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category image banner - shows featured image of current category
          _buildCategoryBanner(_currentCategory),
          
          // Category tabs
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _currentCategory;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppConstants.primaryColor 
                          : AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? Colors.white 
                            : AppConstants.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Category description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _getCategoryDescription(_currentCategory),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Products grid
          Expanded(
            child: Obx(() {
              final products = productController.categoryProducts[_currentCategory] ?? [];
              
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products found in $_currentCategory',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => ProductDetailsScreen(productId: product.id));
                    },
                    child: ProductCard(product: product),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
  
  // Build a banner showing the featured image for the current category
  Widget _buildCategoryBanner(String category) {
    // Find the matching category data
    final categoryData = categories.firstWhere(
      (c) => c.name == category,
      orElse: () => CategoryData(
        name: category,
        image: 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?q=80&w=2070&auto=format&fit=crop',
        description: 'Explore our collection of $category',
      ),
    );
    
    return Container(
      height: 120,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(categoryData.image),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      child: Center(
        child: Text(
          category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Get the description for a category
  String _getCategoryDescription(String category) {
    final categoryData = categories.firstWhere(
      (c) => c.name == category,
      orElse: () => CategoryData(
        name: category,
        image: '',
        description: 'Explore our collection of $category',
      ),
    );
    
    return categoryData.description;
  }
} 