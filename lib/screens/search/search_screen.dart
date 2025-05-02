import 'package:gudmerchant/controllers/product_controller.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:gudmerchant/screens/product/product_details_screen.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:gudmerchant/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<ProductModel> _searchResults = <ProductModel>[].obs;
  final RxBool _isSearching = false.obs;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      _searchResults.clear();
      _isSearching.value = false;
      return;
    }
    
    _performSearch(_searchController.text);
  }
  
  void _performSearch(String query) {
    _isSearching.value = true;
    
    if (query.isEmpty) {
      _searchResults.clear();
      _isSearching.value = false;
      return;
    }
    
    // Get products from the controller
    final ProductController productController = Get.find<ProductController>();
    final List<ProductModel> allProducts = productController.products;
    
    // Filter products based on search query
    final String lowercaseQuery = query.toLowerCase();
    final List<ProductModel> results = allProducts.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.description.toLowerCase().contains(lowercaseQuery) ||
             product.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
    
    // Sort results by relevance (name match is prioritized)
    results.sort((a, b) {
      bool aNameMatch = a.name.toLowerCase().contains(lowercaseQuery);
      bool bNameMatch = b.name.toLowerCase().contains(lowercaseQuery);
      
      if (aNameMatch && !bNameMatch) return -1;
      if (!aNameMatch && bNameMatch) return 1;
      return 0;
    });
    
    _searchResults.assignAll(results);
    _isSearching.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
              },
            ),
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          autofocus: true,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Obx(() {
        if (_isSearching.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (_searchController.text.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Search for products',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        if (_searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
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
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final product = _searchResults[index];
            return GestureDetector(
              onTap: () {
                Get.to(() => ProductDetailsScreen(productId: product.id));
              },
              child: ProductCard(product: product),
            );
          },
        );
      }),
    );
  }
} 