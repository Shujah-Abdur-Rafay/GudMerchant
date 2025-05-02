import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'dart:math';

// Class to hold product data during generation
class ProductData {
  final String name;
  final String description;
  final double price;
  final List<String> images;
  
  ProductData({
    required this.name,
    required this.description,
    required this.price,
    required this.images,
  });
}

class ProductGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _random = Random();
  
  // Generate and add 5-10 new unique products for each category
  Future<void> generateAndAddUniqueProducts() async {
    try {
      // Get all categories
      final QuerySnapshot categorySnapshot = await _firestore.collection('categories').get();
      
      if (categorySnapshot.docs.isEmpty) {
        debugPrint('No categories found. Please add categories first.');
        return;
      }
      
      // Get all existing products to check for uniqueness
      final QuerySnapshot existingProductsSnapshot = await _firestore.collection('products').get();
      final List<ProductModel> existingProducts = existingProductsSnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Set to track used names to ensure uniqueness
      final Set<String> usedNames = existingProducts
          .map((product) => product.name.toLowerCase())
          .toSet();
      
      // Set to track signatures (name_price_imageUrl) to ensure uniqueness
      final Set<String> productSignatures = {};
      for (final product in existingProducts) {
        final imageSignature = product.images.isNotEmpty ? product.images[0] : '';
        final signature = '${product.name.toLowerCase()}_${product.price}_$imageSignature';
        productSignatures.add(signature);
      }
      
      int totalAdded = 0;
      final List<Future<void>> addFutures = [];
      
      // For each category, add 5-10 unique products
      for (var categoryDoc in categorySnapshot.docs) {
        final categoryData = categoryDoc.data() as Map<String, dynamic>;
        if (!categoryData.containsKey('name')) continue;
        
        final String category = categoryData['name'];
        final int productsToAdd = 5 + _random.nextInt(6); // 5-10 products
        
        debugPrint('Adding $productsToAdd products to category: $category');
        
        int addedToCategory = 0;
        int attempts = 0;
        final int maxAttempts = productsToAdd * 3; // Allow multiple attempts to find unique products
        
        while (addedToCategory < productsToAdd && attempts < maxAttempts) {
          attempts++;
          
          final product = _generateUniqueProduct(category, usedNames, productSignatures);
          
          if (product != null) {
            addedToCategory++;
            totalAdded++;
            
            // Add to tracking sets to maintain uniqueness
            usedNames.add(product.name.toLowerCase());
            final imageSignature = product.images.isNotEmpty ? product.images[0] : '';
            final signature = '${product.name.toLowerCase()}_${product.price}_$imageSignature';
            productSignatures.add(signature);
            
            // Add to Firestore
            addFutures.add(_firestore.collection('products').doc(product.id).set(product.toMap()));
            
            debugPrint('Created unique product: ${product.name} for category: $category');
          }
        }
        
        debugPrint('Added $addedToCategory products to category: $category');
      }
      
      // Wait for all products to be added
      await Future.wait(addFutures);
      
      debugPrint('Successfully added $totalAdded new unique products');
      
      Get.snackbar(
        'Success',
        'Added $totalAdded new unique products to your store',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Error generating products: $e');
      
      Get.snackbar(
        'Error',
        'Failed to add new products: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Generate a unique product for a given category
  ProductModel? _generateUniqueProduct(
    String category, 
    Set<String> usedNames,
    Set<String> signatures
  ) {
    // Generate product data based on category
    final ProductData productData = _getProductDataForCategory(category);
    
    // Check if name is already used
    if (usedNames.contains(productData.name.toLowerCase())) {
      return null;
    }
    
    // Check if signature is unique
    final imageSignature = productData.images.isNotEmpty ? productData.images[0] : '';
    final signature = '${productData.name.toLowerCase()}_${productData.price}_$imageSignature';
    if (signatures.contains(signature)) {
      return null;
    }
    
    // Generate a unique product
    final now = DateTime.now();
    return ProductModel(
      id: _uuid.v4(),
      name: productData.name,
      description: productData.description,
      price: productData.price,
      images: productData.images,
      category: category,
      stock: 10 + _random.nextInt(90),
      isFeatured: _random.nextBool(),
      rating: (3 + _random.nextDouble() * 2).clamp(3.0, 5.0),
      reviewCount: _random.nextInt(50),
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // Generate product data for a specific category
  ProductData _getProductDataForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return _generateElectronicsProduct();
      case 'clothing':
        return _generateClothingProduct();
      case 'home & kitchen':
        return _generateHomeKitchenProduct();
      case 'beauty & personal care':
        return _generateBeautyProduct();
      case 'sports & outdoors':
        return _generateSportsProduct();
      case 'books & media':
        return _generateBooksProduct();
      case 'toys & games':
        return _generateToysProduct();
      case 'jewelry & watches':
        return _generateJewelryProduct();
      case 'health & wellness':
        return _generateHealthProduct();
      case 'automotive':
        return _generateAutomotiveProduct();
      default:
        return _generateGenericProduct(category);
    }
  }
  
  // Generate products for different categories
  ProductData _generateElectronicsProduct() {
    final devices = [
      'Ultra HD Smart TV',
      'Noise Cancelling Headphones',
      'Wireless Gaming Mouse',
      'Bluetooth Speaker System',
      'Smart Home Hub',
      'Gaming Laptop',
      'Portable Power Bank',
      'Wireless Earbuds',
      'Digital Camera',
      'Smart Watch',
      'VR Headset',
      'Drone with HD Camera',
      'Wireless Charging Pad',
      'Mechanical Keyboard',
      'Curved Monitor',
      'Smart Thermostat',
      'Wi-Fi Mesh System',
      'Graphic Tablet',
      'Ultra-thin Laptop',
      'Smart Light Bulbs',
    ];
    
    final brands = [
      'TechPro', 'NexGen', 'EliteWare', 'FutureTech', 'InnoVision',
      'PrimeTech', 'QuantumX', 'ZenTech', 'VortexGear', 'ApexTech'
    ];
    
    final features = [
      'with AI enhancement', 
      'with premium build quality', 
      'featuring next-gen technology',
      'with extended battery life',
      'in limited edition color',
      'with advanced cooling system',
      'featuring voice commands',
      'with customizable settings',
      'with high-definition display',
      'with smart connectivity'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedDevice = devices[_random.nextInt(devices.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $selectedDevice';
    final description = '$name $selectedFeature. Perfect for home or office use. Includes 1-year warranty and free technical support.';
    final price = (99.99 + _random.nextInt(900)).toDouble();
    
    // Electronics images
    final images = [
      'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=800',
      'https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=800',
      'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateClothingProduct() {
    final items = [
      'Premium Cotton T-Shirt',
      'Slim Fit Jeans',
      'Casual Hoodie',
      'Knit Sweater',
      'Formal Blazer',
      'Athletic Shorts',
      'Puffer Jacket',
      'Dress Shirt',
      'Yoga Pants',
      'Winter Coat',
      'Casual Chinos',
      'Summer Dress',
      'Denim Jacket',
      'Leather Boots',
      'Running Shoes',
    ];
    
    final brands = [
      'UrbanStyle', 'ModernFit', 'ElegantWear', 'ActiveLife', 'ClassicThreads',
      'PureComfort', 'NatureFabric', 'LuxeApparel', 'EcoWear', 'SeasonalChic'
    ];
    
    final features = [
      'in breathable fabric',
      'with moisture-wicking technology',
      'with eco-friendly materials',
      'in trendy seasonal colors',
      'with premium stitching',
      'featuring minimalist design',
      'with adjustable fit',
      'in limited edition pattern',
      'with temperature control',
      'made from organic materials'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $selectedItem';
    final description = '$name $selectedFeature. Comfortable and stylish for everyday wear. Easy care, machine washable.';
    final price = (19.99 + _random.nextInt(80)).toDouble();
    
    // Clothing images
    final images = [
      'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=800',
      'https://images.unsplash.com/photo-1516762689617-e1cffcef479d?w=800',
      'https://images.unsplash.com/photo-1528575303289-10c5406e8b3c?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateHomeKitchenProduct() {
    final items = [
      'Coffee Maker',
      'Non-Stick Cookware Set',
      'Kitchen Knife Set',
      'Blender',
      'Food Processor',
      'Slow Cooker',
      'Stand Mixer',
      'Toaster Oven',
      'Dinnerware Set',
      'Air Fryer',
      'Pressure Cooker',
      'Ceramic Bakeware',
      'Storage Container Set',
      'Cutlery Collection',
      'Wine Glass Set',
    ];
    
    final brands = [
      'HomeLuxe', 'KitchenElite', 'CulinaryPro', 'GourmetChoice', 'ChefSelect',
      'HomeEssentials', 'CookCraft', 'KitchenMaster', 'HomeStyle', 'DiningDelight'
    ];
    
    final features = [
      'with stainless steel finish',
      'with non-stick coating',
      'featuring ergonomic design',
      'with easy-clean surface',
      'with precision control',
      'featuring modern design',
      'with energy-efficient technology',
      'made with premium materials',
      'with space-saving design',
      'with multi-function capability'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $selectedItem';
    final description = '$name $selectedFeature. Perfect for any kitchen. Durable construction ensures long-lasting performance.';
    final price = (29.99 + _random.nextInt(170)).toDouble();
    
    // Home & Kitchen images
    final images = [
      'https://images.unsplash.com/photo-1589140365482-422e4b9b2520?w=800',
      'https://images.unsplash.com/photo-1507048331197-7d4ac70811cf?w=800',
      'https://images.unsplash.com/photo-1556910585-09baa3a3998e?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateBeautyProduct() {
    final items = [
      'Facial Cleanser',
      'Moisturizing Cream',
      'Hair Styling Kit',
      'Perfume Collection',
      'Makeup Palette',
      'Anti-Aging Serum',
      'Hair Conditioner',
      'Body Lotion',
      'Essential Oils Set',
      'Makeup Brush Kit',
      'Face Mask Set',
      'Nail Polish Collection',
      'Exfoliating Scrub',
      'Lip Care Kit',
      'Shaving Kit',
    ];
    
    final brands = [
      'PureGlow', 'NaturalEssence', 'BeautySecret', 'VitalSkin', 'LuxeBeauty',
      'OrganicBliss', 'RadiantYou', 'EssentialCare', 'GentleTouch', 'ElixirBeauty'
    ];
    
    final features = [
      'with natural ingredients',
      'with vitamin-enriched formula',
      'featuring anti-aging properties',
      'with gentle formula',
      'with organic extracts',
      'featuring aromatherapy benefits',
      'with moisturizing complex',
      'with SPF protection',
      'with plant-based ingredients',
      'featuring hydrating technology'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $selectedItem';
    final description = '$name $selectedFeature. Gentle and effective for all skin types. Cruelty-free and paraben-free formula.';
    final price = (14.99 + _random.nextInt(85)).toDouble();
    
    // Beauty images
    final images = [
      'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=800',
      'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800',
      'https://images.unsplash.com/photo-1526947425960-945c6e72858f?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateSportsProduct() {
    final items = [
      'Training Shoes',
      'Yoga Mat',
      'Fitness Tracker',
      'Resistance Bands Set',
      'Dumbbell Set',
      'Basketball',
      'Tennis Racket',
      'Cycling Helmet',
      'Hiking Backpack',
      'Golf Club Set',
      'Swimming Goggles',
      'Running Shorts',
      'Camping Tent',
      'Fishing Rod',
      'Ski Goggles',
    ];
    
    final brands = [
      'ActivePro', 'FitnessPeak', 'SportElite', 'AdventurePro', 'TrailMaster',
      'AthleticForce', 'EnduranceGear', 'PerformancePlus', 'OutdoorEssentials', 'SportVital'
    ];
    
    final features = [
      'with lightweight design',
      'featuring ergonomic grip',
      'with moisture-wicking fabric',
      'featuring adjustable settings',
      'with durable construction',
      'featuring impact protection',
      'with all-weather technology',
      'featuring breathable material',
      'with water-resistant coating',
      'featuring reinforced support'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $selectedItem';
    final description = '$name $selectedFeature. Engineered for peak performance. Ideal for both beginners and experienced athletes.';
    final price = (24.99 + _random.nextInt(150)).toDouble();
    
    // Sports images
    final images = [
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
      'https://images.unsplash.com/photo-1599058917212-d750089bc07e?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateBooksProduct() {
    final items = [
      'Mystery Novel',
      'Self-Help Book',
      'Science Fiction Anthology',
      'Cookbook Collection',
      'Historical Biography',
      'Fantasy Series',
      'Business Strategy Guide',
      'Travel Guide',
      'Children\'s Illustrated Book',
      'Poetry Collection',
      'Educational Textbook',
      'Memoir',
      'Photography Album',
      'Graphic Novel',
      'Audio Book Collection',
    ];
    
    final authors = [
      'J.R. Morgan', 'Emma Winters', 'Christopher Blake', 'Sophia Reynolds', 'Daniel Torres',
      'Olivia Chen', 'Michael Brooks', 'Isabella Garcia', 'Samuel Wilson', 'Elizabeth Clark'
    ];
    
    final features = [
      'bestselling edition',
      'award-winning collection',
      'illustrated special edition',
      'expanded and revised',
      'with exclusive content',
      'collector\'s edition',
      'with author commentary',
      'featuring new chapters',
      'critically acclaimed',
      'international edition'
    ];
    
    final selectedAuthor = authors[_random.nextInt(authors.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedItem by $selectedAuthor';
    final description = 'A $selectedFeature that captivates readers from beginning to end. $selectedAuthor\'s masterful storytelling creates an immersive experience for all types of readers.';
    final price = (9.99 + _random.nextInt(40)).toDouble();
    
    // Books images
    final images = [
      'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800',
      'https://images.unsplash.com/photo-1519682337058-a94d519337bc?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateToysProduct() {
    final items = [
      'Building Blocks Set',
      'Remote Control Car',
      'Educational Puzzle',
      'Plush Animal Collection',
      'Board Game',
      'Science Experiment Kit',
      'Art and Craft Set',
      'Action Figure Collection',
      'Interactive Robot',
      'Musical Instrument Toy',
      'Outdoor Play Equipment',
      'Dollhouse',
      'Card Game',
      'Fidget Toy Set',
      'Model Building Kit',
    ];
    
    final brands = [
      'PlayWell', 'KidCreative', 'ImagineWorld', 'BrightMinds', 'FunZone',
      'TinyExplorers', 'JoyfulPlay', 'DreamToys', 'LearningFun', 'WonderKids'
    ];
    
    final features = [
      'with interactive elements',
      'featuring educational content',
      'with colorful design',
      'featuring multiple play modes',
      'with durable construction',
      'suitable for all ages',
      'with STEM learning focus',
      'featuring realistic details',
      'with easy assembly',
      'featuring sound effects'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $selectedItem';
    final description = '$name $selectedFeature. Encourages creativity and imaginative play. Safe materials meet all safety standards.';
    final price = (12.99 + _random.nextInt(70)).toDouble();
    
    // Toys images
    final images = [
      'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=800',
      'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?w=800',
      'https://images.unsplash.com/photo-1618842676088-c4d48a6a7c9d?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateJewelryProduct() {
    final items = [
      'Diamond Necklace',
      'Gold Bracelet',
      'Silver Earrings',
      'Pearl Pendant',
      'Watch Collection',
      'Gemstone Ring',
      'Vintage Brooch',
      'Charm Collection',
      'Cufflink Set',
      'Bangle Set',
      'Anklet',
      'Stackable Rings',
      'Statement Necklace',
      'Tennis Bracelet',
      'Birthstone Collection',
    ];
    
    final brands = [
      'ElegantGems', 'LuxeJewels', 'PreciousMetal', 'TimelessCharm', 'RadiantStone',
      'GoldenTouch', 'SilverCraft', 'GemEssence', 'RoyalJewel', 'DiamondDreams'
    ];
    
    final features = [
      'with genuine stones',
      'hand-crafted design',
      'featuring adjustable sizing',
      'with hypoallergenic materials',
      'featuring intricate detailing',
      'with premium finish',
      'featuring classic styling',
      'with modern aesthetic',
      'featuring ethically sourced materials',
      'with secure clasp'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $selectedItem';
    final description = '$name $selectedFeature. Perfect for special occasions or everyday elegance. Comes in a premium gift box.';
    final price = (49.99 + _random.nextInt(950)).toDouble();
    
    // Jewelry images
    final images = [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800',
      'https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800',
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateHealthProduct() {
    final items = [
      'Vitamin Supplement',
      'Fitness Tracker',
      'Massage Device',
      'Aromatherapy Diffuser',
      'Sleep Aid',
      'Meditation Kit',
      'Herbal Tea Collection',
      'Yoga Accessories',
      'Digital Scale',
      'Blood Pressure Monitor',
      'Air Purifier',
      'Posture Corrector',
      'Resistance Training Set',
      'Protein Supplement',
      'Wellness Journal',
    ];
    
    final brands = [
      'VitalLife', 'WellnessEssentials', 'PureHealth', 'NaturalBalance', 'HealthHarmony',
      'OptimalWell', 'HolisticCare', 'NutritionPlus', 'VitalitySource', 'WellBeingPro'
    ];
    
    final features = [
      'with natural ingredients',
      'featuring advanced technology',
      'with proven results',
      'scientifically formulated',
      'with organic components',
      'featuring easy-to-use design',
      'with multiple benefits',
      'featuring portable design',
      'with clinically tested formulation',
      'featuring sustainable materials'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $selectedItem';
    final description = '$name $selectedFeature. Support your wellness journey with this high-quality health product. Made to the highest standards.';
    final price = (19.99 + _random.nextInt(180)).toDouble();
    
    // Health images
    final images = [
      'https://images.unsplash.com/photo-1544829728-e5ca4718dd8f?w=800',
      'https://images.unsplash.com/photo-1616690010876-88d21346a3a7?w=800',
      'https://images.unsplash.com/photo-1656268164012-119304af0e5b?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateAutomotiveProduct() {
    final items = [
      'Car Care Kit',
      'Portable Jump Starter',
      'Dashboard Camera',
      'Tire Pressure Monitor',
      'Interior Accessories Set',
      'GPS Navigation System',
      'Car Phone Mount',
      'LED Headlight Set',
      'Car Seat Covers',
      'Bluetooth Adapter',
      'Car Vacuum Cleaner',
      'Air Freshener Collection',
      'Car Washer Kit',
      'Windshield Wipers',
      'Tool Kit',
    ];
    
    final brands = [
      'DriveTech', 'AutoElite', 'RoadMaster', 'CarPro', 'DriverEssentials',
      'MotorCare', 'AutoSmart', 'RideWell', 'VehiclePlus', 'TravelDrive'
    ];
    
    final features = [
      'with durable construction',
      'featuring easy installation',
      'with universal fit',
      'featuring premium materials',
      'with weather-resistant design',
      'featuring compact storage',
      'with high performance',
      'featuring smart technology',
      'with ergonomic design',
      'featuring multi-function capability'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $selectedItem';
    final description = '$name $selectedFeature. Keep your vehicle in top condition with this essential automotive product. Compatible with most vehicle models.';
    final price = (24.99 + _random.nextInt(175)).toDouble();
    
    // Automotive images
    final images = [
      'https://images.unsplash.com/photo-1597766350699-ce3ee9a58b3e?w=800',
      'https://images.unsplash.com/photo-1582639510494-c80b5de9f148?w=800',
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
  
  ProductData _generateGenericProduct(String category) {
    final items = [
      'Premium Collection',
      'Essential Kit',
      'Deluxe Set',
      'Professional Series',
      'Starter Package',
      'Luxury Edition',
      'Classic Collection',
      'Signature Series',
      'Limited Edition',
      'Complete Set',
      'Advanced Kit',
      'Bundle Pack',
      'Value Set',
      'All-in-One Package',
      'Premium Selection',
    ];
    
    final brands = [
      'QualityPro', 'PremiumSelect', 'TopChoice', 'EliteProducts', 'PrimeEssentials',
      'SuperiorGoods', 'MasterCraft', 'FinestQuality', 'SelectChoice', 'BestValue'
    ];
    
    final features = [
      'with exceptional quality',
      'featuring premium materials',
      'with versatile functionality',
      'featuring modern design',
      'with durable construction',
      'featuring innovative technology',
      'with superior craftsmanship',
      'featuring practical design',
      'with reliable performance',
      'featuring unique styling'
    ];
    
    final selectedBrand = brands[_random.nextInt(brands.length)];
    final selectedItem = items[_random.nextInt(items.length)];
    final selectedFeature = features[_random.nextInt(features.length)];
    
    final name = '$selectedBrand $category $selectedItem';
    final description = '$name $selectedFeature. A high-quality product designed to exceed expectations. Satisfaction guaranteed.';
    final price = (29.99 + _random.nextInt(170)).toDouble();
    
    // Generic images
    final images = [
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800',
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800',
      'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800',
    ];
    
    return ProductData(
      name: name,
      description: description,
      price: price,
      images: [images[_random.nextInt(images.length)]],
    );
  }
} 