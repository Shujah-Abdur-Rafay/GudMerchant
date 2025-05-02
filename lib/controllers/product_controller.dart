import 'package:gudmerchant/models/product_model.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  final RxList<ProductModel> _products = <ProductModel>[].obs;
  final RxList<ProductModel> _featuredProducts = <ProductModel>[].obs;
  final RxList<ProductModel> _recommendedProducts = <ProductModel>[].obs;
  final RxMap<String, List<ProductModel>> _categoryProducts = <String, List<ProductModel>>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isFeaturedLoading = false.obs;
  final RxBool _isRecommendedLoading = false.obs;
  
  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get recommendedProducts => _recommendedProducts;
  Map<String, List<ProductModel>> get categoryProducts => _categoryProducts;
  bool get isLoading => _isLoading.value;
  bool get isFeaturedLoading => _isFeaturedLoading.value;
  bool get isRecommendedLoading => _isRecommendedLoading.value;
  
  @override
  void onInit() {
    super.onInit();
    // Load products immediately, don't wait for manual loading
    // This will ensure products are loaded when the app starts
    fetchProducts();
    fetchFeaturedProducts();
    fetchRecommendedProducts();
    
    debugPrint('ProductController initialized - automatic product loading enabled');
  }
  
  Future<void> fetchProducts() async {
    try {
      _isLoading.value = true;
      List<ProductModel> fetchedProducts = await _firebaseService.getProducts();
      
      // Filter out duplicate products (same name, price, and first image)
      fetchedProducts = _filterDuplicateProducts(fetchedProducts);
      
      // Filter out mock products (new filtering step)
      fetchedProducts = _filterMockProducts(fetchedProducts);
      
      _products.assignAll(fetchedProducts);
      
      // Organize products by category
      Map<String, List<ProductModel>> groupedProducts = {};
      for (var product in fetchedProducts) {
        if (!groupedProducts.containsKey(product.category)) {
          groupedProducts[product.category] = [];
        }
        groupedProducts[product.category]!.add(product);
      }
      _categoryProducts.assignAll(groupedProducts);
      
      // Explicitly refresh to ensure UI updates
      _products.refresh();
      _categoryProducts.refresh();
      
      debugPrint('✅ Fetched ${fetchedProducts.length} products successfully');
    } catch (e) {
      debugPrint('❌ Error fetching products: $e');
      Get.snackbar(
        'Error',
        'Failed to load products',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Filter out mock products based on known mock data patterns
  List<ProductModel> _filterMockProducts(List<ProductModel> products) {
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
    
    final realProducts = products.where((product) {
      // Check if the product name matches any known mock product names
      if (mockProductNames.contains(product.name)) {
        debugPrint('🚫 Filtering out mock product: ${product.name}');
        return false;
      }
      
      // Additional checks for mock data patterns
      // Filter out products from the default mock images
      if (product.images.isNotEmpty) {
        String imageUrl = product.images[0].toLowerCase();
        if (imageUrl.contains('unsplash.com')) {
          debugPrint('🚫 Filtering out product with mock image: ${product.name}');
          return false;
        }
      }
      
      return true;
    }).toList();
    
    debugPrint('📋 Filtered ${products.length - realProducts.length} mock products');
    return realProducts;
  }
  
  // Filter out duplicate products based on name, price, and first image
  List<ProductModel> _filterDuplicateProducts(List<ProductModel> products) {
    final uniqueProducts = <ProductModel>[];
    final signatureSet = <String>{};
    
    for (final product in products) {
      // Create a unique signature for the product based on name, price, and first image
      final imageSignature = product.images.isNotEmpty ? product.images[0] : '';
      final signature = '${product.name}_${product.price}_$imageSignature';
      
      // Only add if this signature hasn't been seen before
      if (!signatureSet.contains(signature)) {
        signatureSet.add(signature);
        uniqueProducts.add(product);
      } else {
        debugPrint('Filtering out duplicate product: ${product.name}');
      }
    }
    
    return uniqueProducts;
  }
  
  Future<void> fetchFeaturedProducts() async {
    try {
      _isFeaturedLoading.value = true;
      List<ProductModel> featured = await _firebaseService.getFeaturedProducts();
      // Apply duplicate filtering to featured products as well
      featured = _filterDuplicateProducts(featured);
      // Filter out mock products
      featured = _filterMockProducts(featured);
      _featuredProducts.assignAll(featured);
      
      // Explicitly refresh to ensure UI updates
      _featuredProducts.refresh();
      
      debugPrint('✅ Fetched ${featured.length} featured products successfully');
    } catch (e) {
      debugPrint('❌ Error fetching featured products: $e');
    } finally {
      _isFeaturedLoading.value = false;
    }
  }
  
  Future<void> fetchRecommendedProducts() async {
    try {
      _isRecommendedLoading.value = true;
      List<ProductModel> recommended = await _firebaseService.getRecommendedProducts();
      // Apply duplicate filtering to recommended products
      recommended = _filterDuplicateProducts(recommended);
      // Filter out mock products
      recommended = _filterMockProducts(recommended);
      _recommendedProducts.assignAll(recommended);
      
      // Explicitly refresh to ensure UI updates
      _recommendedProducts.refresh();
      
      debugPrint('✅ Fetched ${recommended.length} recommended products successfully');
    } catch (e) {
      debugPrint('❌ Error fetching recommended products: $e');
    } finally {
      _isRecommendedLoading.value = false;
    }
  }
  
  Future<void> fetchProductsByCategory(String category) async {
    try {
      _isLoading.value = true;
      List<ProductModel> categoryProds = await _firebaseService.getProductsByCategory(category);
      // Apply duplicate filtering to category products
      categoryProds = _filterDuplicateProducts(categoryProds);
      // Filter out mock products
      categoryProds = _filterMockProducts(categoryProds);
      _categoryProducts[category] = categoryProds;
      
      // Explicitly refresh to ensure UI updates
      _categoryProducts.refresh();
      
      debugPrint('✅ Fetched ${categoryProds.length} products for category $category');
    } catch (e) {
      debugPrint('❌ Error fetching products by category: $e');
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<ProductModel?> getProductById(String productId) async {
    try {
      // Check if product is already in local list
      ProductModel? product = _products.firstWhereOrNull((p) => p.id == productId);
      
      if (product != null) {
        return product;
      }
      
      // If not found locally, fetch from Firestore
      return await _firebaseService.getProductById(productId);
    } catch (e) {
      debugPrint('❌ Error getting product by ID: $e');
      return null;
    }
  }
} 