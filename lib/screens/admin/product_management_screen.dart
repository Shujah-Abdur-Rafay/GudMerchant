import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:gudmerchant/controllers/product_controller.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:uuid/uuid.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ProductController _productController = Get.find<ProductController>();
  bool _isLoading = true;
  List<ProductModel> _products = [];
  String _searchQuery = '';
  String _filterCategory = 'All';
  
  // Default fixed categories that will always be available
  final List<String> _fixedCategories = [
    'Electronics',
    'Clothing',
    'Home & Kitchen',
    'Beauty & Personal Care',
    'Sports & Outdoors',
    'Toys & Games',
    'Books',
    'Jewelry',
    'Health & Wellness',
    'Food & Beverages'
  ];
  
  List<String> _categories = ['All'];
  List<String> _allProductCategories = []; // Categories from products

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _productController.fetchProducts();
      final products = _productController.products;
      
      // Extract unique categories from existing products
      final Set<String> productCategories = {};
      
      // Also fetch custom categories from Firestore
      try {
        final QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .get();
            
        if (categorySnapshot.docs.isNotEmpty) {
          for (var doc in categorySnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('name') && data['name'] is String) {
              productCategories.add(data['name'] as String);
            }
          }
        }
      } catch (e) {
        print('Error fetching categories: $e');
      }
      
      // Add categories from products too
      for (final product in products) {
        if (product.category.isNotEmpty) {
          productCategories.add(product.category);
        }
      }

      // Start with fixed categories, then add custom ones
      final Set<String> allCategories = {'All'};
      allCategories.addAll(_fixedCategories);
      allCategories.addAll(productCategories);

      setState(() {
        _products = products;
        _allProductCategories = productCategories.toList()..sort();
        _categories = allCategories.toList()..sort();
        // Make sure 'All' remains at the beginning
        _categories.remove('All');
        _categories.insert(0, 'All');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load products: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<ProductModel> get _filteredProducts {
    return _products.where((product) {
      // Apply category filter
      if (_filterCategory != 'All' && product.category != _filterCategory) {
        return false;
      }
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }

  Future<void> _deleteProduct(ProductModel product) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
      
      // Update local state
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
      });
      
      // Refresh product controller to sync with Firebase
      await _productController.fetchProducts();
      
      Get.snackbar(
        'Success',
        'Product deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete product: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh Products',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditProductDialog(),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _filterCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filterCategory = selected ? category : 'All';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: product.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Image.network(
                  product.images[0],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.image),
              ),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PKR ${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              'Category: ${product.category}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddEditProductDialog(product: product),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(product),
              tooltip: 'Delete',
              color: Colors.red,
            ),
          ],
        ),
        onTap: () => _showAddEditProductDialog(product: product),
      ),
    );
  }

  void _showDeleteConfirmation(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProduct(product);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showAddEditProductDialog({ProductModel? product}) {
    final bool isEditing = product != null;
    
    // Controllers
    final titleController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '');
    final imageUrlsController = TextEditingController(
      text: product?.images.join('\n') ?? '',
    );
    
    // Combined categories list for dropdown
    final List<String> dropdownCategories = [];
    
    // First add fixed categories, removing 'All' if it's in the list
    dropdownCategories.addAll(_fixedCategories);
    
    // Then add any custom categories from products that aren't already in the fixed list
    for (String category in _allProductCategories) {
      if (!dropdownCategories.contains(category)) {
        dropdownCategories.add(category);
      }
    }
    
    // Sort the categories alphabetically
    dropdownCategories.sort();
    
    // State variables
    String selectedCategory = '';
    // First check if product category exists in our dropdown categories
    if (product?.category != null && dropdownCategories.contains(product!.category)) {
      selectedCategory = product.category;
    } else {
      // Otherwise use the first category in the dropdown
      selectedCategory = dropdownCategories.isNotEmpty ? dropdownCategories[0] : _fixedCategories[0];
    }
    
    bool isFeatured = product?.isFeatured ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: Text('${isEditing ? 'Edit' : 'Add'} Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Product title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter product title',
                  ),
                ),
              const SizedBox(height: 16),
              
              // Product category
              DropdownButtonFormField<String>(
                value: selectedCategory,
                  decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                    items: [
                  ...dropdownCategories.map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                  )),
                      const DropdownMenuItem(
                        value: 'add_new_category',
                    child: Text('+ Add New Category'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == 'add_new_category') {
                    _showAddCategoryDialog(context).then((newCategory) {
                      if (newCategory != null && newCategory.isNotEmpty) {
                        setState(() {
                          selectedCategory = newCategory;
                          // Also add to our lists if it's new
                          if (!_allProductCategories.contains(newCategory)) {
                            _allProductCategories.add(newCategory);
                            _allProductCategories.sort();
                          }
                          if (!_categories.contains(newCategory)) {
                            _categories.add(newCategory);
                            _categories.sort();
                            // Keep 'All' at the beginning of _categories
                            _categories.remove('All');
                            _categories.insert(0, 'All');
                          }
                        });
                      }
                    });
                  } else if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Price and stock in a row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (PKR)',
                        hintText: 'Enter price',
                              ),
                    ),
                          ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                  controller: stockController,
                      keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                        labelText: 'Stock',
                        hintText: 'Enter stock quantity',
                  ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Product description
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter product description',
                  alignLabelWithHint: true,
                ),
                ),
              const SizedBox(height: 16),
              
              // Product images
                TextField(
                  controller: imageUrlsController,
                maxLines: 3,
                  decoration: const InputDecoration(
                  labelText: 'Image URLs (one per line)',
                  hintText: 'Enter image URLs, one per line',
                  alignLabelWithHint: true,
                ),
                ),
              const SizedBox(height: 24),
              
              // Featured and Recommended toggles
                const Text(
                'Product Visibility',
                  style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
              
              // Featured toggle
              Row(
                children: [
                  Switch(
                    value: isFeatured,
                    onChanged: (value) {
                      setState(() {
                        isFeatured = value;
                      });
                    },
                  ),
                  const Text('Featured Product'),
                ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
              onPressed: () {
              // Validate inputs
              if (titleController.text.isEmpty) {
                  Get.snackbar(
                    'Error',
                  'Product title is required',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                // Split image URLs by new line
                final imageUrls = imageUrlsController.text
                    .split('\n')
                    .where((url) => url.trim().isNotEmpty)
                    .toList();

                if (imageUrls.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'At least one image URL is required',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                // Parse price and stock
                double? price;
                int? stock;
                try {
                  price = double.parse(priceController.text);
                  stock = int.parse(stockController.text);
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Invalid price or stock value',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                // Create or update product
                final updatedProduct = ProductModel(
                  id: product?.id ?? const Uuid().v4(),
                  name: titleController.text,
                  price: price,
                  description: descriptionController.text,
                  category: selectedCategory,
                  images: imageUrls,
                isFeatured: isFeatured,
                isRecommended: false,
                  stock: stock,
                  rating: product?.rating ?? 0,
                  createdAt: product?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                _saveProduct(updatedProduct, isEditing);
                Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
      ),
    );
  }

  Future<void> _saveProduct(ProductModel product, bool isEditing) async {
    try {
      // If not editing, check for duplicates
      if (!isEditing) {
        // Check for duplicates before saving
        bool isDuplicate = await _checkForDuplicateProduct(product);
        if (isDuplicate) {
          Get.snackbar(
            'Duplicate Product',
            'A product with the same name, price, and image already exists.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          // Let the user decide whether to continue or not
          bool continueAnyway = await _showDuplicateConfirmationDialog();
          if (!continueAnyway) {
            return; // User chose not to continue
          }
        }
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .set(product.toMap());

      // Check if category is new and save it to Firestore
      if (!_categories.contains(product.category) || product.category == 'add_new_category') {
        // Save category to Firestore
        await FirebaseFirestore.instance
            .collection('categories')
            .doc()
            .set({
              'name': product.category,
              'createdAt': DateTime.now(),
            });
      }

      // Update local state
      setState(() {
        if (isEditing) {
          final index = _products.indexWhere((p) => p.id == product.id);
          if (index >= 0) {
            _products[index] = product;
          }
        } else {
          _products.add(product);
        }

        // Update categories
        if (!_categories.contains(product.category)) {
          _categories.add(product.category);
          _categories.sort();
        }
      });

      Get.snackbar(
        'Success',
        '${isEditing ? 'Updated' : 'Added'} product successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to ${isEditing ? 'update' : 'add'} product: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Check if a product with the same name, price, and first image already exists
  Future<bool> _checkForDuplicateProduct(ProductModel newProduct) async {
    try {
      // Query Firestore for products with the same name
      final QuerySnapshot nameMatches = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: newProduct.name)
          .get();
      
      if (nameMatches.docs.isEmpty) {
        return false; // No products with the same name
      }
      
      // Check for price and image match among name matches
      for (var doc in nameMatches.docs) {
        final productData = doc.data() as Map<String, dynamic>;
        final double price = (productData['price'] ?? 0.0).toDouble();
        final List<dynamic> images = productData['images'] ?? [];
        
        // Check if price matches and at least one image matches
        if (price == newProduct.price && 
            images.isNotEmpty && 
            newProduct.images.isNotEmpty &&
            images.contains(newProduct.images[0])) {
          return true; // Found a duplicate
        }
      }
      
      return false; // No duplicates found
    } catch (e) {
      debugPrint('Error checking for duplicate product: $e');
      return false; // On error, proceed with save
    }
  }
  
  // Show confirmation dialog when a duplicate is detected
  Future<bool> _showDuplicateConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Product Detected'),
        content: const Text(
          'A similar product already exists in the database. Do you want to add this product anyway?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add Anyway'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<String?> _showAddCategoryDialog(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter new category name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: Create specific, descriptive categories to organize your products effectively.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (categoryController.text.trim().isNotEmpty) {
                String newCategory = categoryController.text.trim();
                // Add new category to the list
                if (!_categories.contains(newCategory)) {
                  setState(() {
                    _categories.add(newCategory);
                    _allProductCategories.add(newCategory);
                    _categories.sort();
                    _allProductCategories.sort();
                    // Keep 'All' at the beginning of _categories
                    _categories.remove('All');
                    _categories.insert(0, 'All');
                  });
                }
                
                Navigator.of(context).pop(newCategory);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 