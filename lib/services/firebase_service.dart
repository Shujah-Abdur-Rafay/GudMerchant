import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gudmerchant/models/cart_item_model.dart';
import 'package:gudmerchant/models/order_model.dart';
import 'package:gudmerchant/models/payment_details_model.dart';
import 'package:gudmerchant/models/product_model.dart';
import 'package:gudmerchant/models/usermodel.dart';
import 'package:gudmerchant/models/wishlist_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class FirebaseService extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable for auth state changes
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String get userId => currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    // Initialize the user
    _firebaseUser.value = _auth.currentUser;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _firebaseUser.value = user;
      debugPrint('🔐 Auth state changed: ${user?.uid ?? 'logged out'}');
    });
  }

  // Collection references
  CollectionReference get usersRef => _firestore.collection('users');
  CollectionReference get productsRef => _firestore.collection('products');
  CollectionReference get cartsRef => _firestore.collection('carts');
  CollectionReference get ordersRef => _firestore.collection('orders');
  CollectionReference get wishlistsRef => _firestore.collection('wishlists');

  // User authentication methods
  Future<UserCredential> signUpWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _firebaseUser.value = credential.user;
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _firebaseUser.value = credential.user;
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      _firebaseUser.value = null;
      debugPrint('🔐 Successfully signed out from Firebase');
    } catch (e) {
      debugPrint('❌ Error during sign out: $e');
      rethrow;
    }
  }

  // User data methods
  Future<void> createUserRecord(UserModel user) async {
    try {
      debugPrint('📝 Creating user record for UID: ${user.uID}');
      debugPrint('📄 User data: ${user.toMap()}');

      // Check if the user document already exists
      DocumentSnapshot existingDoc = await usersRef.doc(user.uID).get();
      if (existingDoc.exists) {
        debugPrint('⚠️ User document already exists. Will update it.');
      }

      // Set user data in Firestore
      await usersRef.doc(user.uID).set(user.toMap());

      // Verify the data was written
      DocumentSnapshot verifyDoc = await usersRef.doc(user.uID).get();
      if (verifyDoc.exists) {
        debugPrint('✅ User record created/updated successfully');
        debugPrint('📄 Stored data: ${verifyDoc.data()}');
      } else {
        debugPrint('❌ User record was not found after write operation');
        throw Exception('Failed to verify user record creation');
      }
    } catch (e) {
      debugPrint('❌ Error creating user record: $e');
      // Log the stacktrace for debugging
      debugPrint('📋 Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<UserModel?> getUserData() async {
    try {
      if (userId.isEmpty) {
        debugPrint('❌ getUserData: No user ID available');
        return null;
      }

      debugPrint('🔍 Fetching user data for ID: $userId');

      DocumentSnapshot doc = await usersRef.doc(userId).get();

      if (doc.exists) {
        debugPrint('✅ User document found');
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        debugPrint('📄 User data keys: ${data.keys.toList()}');

        try {
          UserModel user = UserModel.fromMap(data);
          debugPrint('✅ Successfully parsed UserModel: ${user.username}');
          return user;
        } catch (parseError) {
          debugPrint('❌ Error parsing UserModel: $parseError');
          // Try to repair the user data if possible
          Map<String, dynamic> repairedData = {...data};
          // Ensure required fields exist
          if (!repairedData.containsKey('uID')) repairedData['uID'] = userId;

          debugPrint('🔄 Attempting to create user model with repaired data');
          return UserModel.fromMap(repairedData);
        }
      } else {
        debugPrint('⚠️ No user document found for ID: $userId');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in getUserData: $e');
      debugPrint('📋 Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Products methods
  Future<List<ProductModel>> getProducts() async {
    try {
      QuerySnapshot snapshot = await productsRef.get();
      return snapshot.docs
          .map(
              (doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      QuerySnapshot querySnapshot = await productsRef
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();
      
      List<ProductModel> featuredProducts = querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      debugPrint('✅ Fetched ${featuredProducts.length} featured products');
      return featuredProducts;
    } catch (e) {
      debugPrint('❌ Error getting featured products: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      QuerySnapshot snapshot =
          await productsRef.where('category', isEqualTo: category).get();
      return snapshot.docs
          .map(
              (doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      return [];
    }
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await productsRef.doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product by ID: $e');
      return null;
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      debugPrint('Adding product: ${product.name}');
      await productsRef.doc(product.id).set(product.toMap());
      debugPrint('Product added successfully');
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  // Cart methods
  Future<List<CartItemModel>> getCartItems() async {
    try {
      if (userId.isEmpty) return [];

      DocumentSnapshot cartDoc = await cartsRef.doc(userId).get();
      if (!cartDoc.exists) return [];

      Map<String, dynamic> data = cartDoc.data() as Map<String, dynamic>;
      List<dynamic> items = data['items'] ?? [];

      return items.map((item) => CartItemModel.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error getting cart items: $e');
      return [];
    }
  }

  Future<void> addToCart(ProductModel product, int quantity) async {
    try {
      if (userId.isEmpty) throw Exception('User not logged in');

      DocumentReference cartDocRef = cartsRef.doc(userId);
      DocumentSnapshot cartDoc = await cartDocRef.get();

      List<CartItemModel> cartItems = [];
      if (cartDoc.exists) {
        Map<String, dynamic> data = cartDoc.data() as Map<String, dynamic>;
        List<dynamic> items = data['items'] ?? [];
        cartItems = items.map((item) => CartItemModel.fromMap(item)).toList();
      }

      // Check if product already exists in cart
      int existingIndex =
          cartItems.indexWhere((item) => item.productId == product.id);

      if (existingIndex >= 0) {
        // Update quantity
        cartItems[existingIndex].quantity += quantity;
      } else {
        // Add new item
        cartItems.add(CartItemModel(
          id: const Uuid().v4(),
          productId: product.id,
          productName: product.name,
          productPrice: product.price,
          productImage: product.images.isNotEmpty ? product.images[0] : '',
          quantity: quantity,
        ));
      }

      await cartDocRef.set({
        'userId': userId,
        'items': cartItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateCartItemQuantity(String itemId, int quantity) async {
    try {
      if (userId.isEmpty) throw Exception('User not logged in');

      DocumentReference cartDocRef = cartsRef.doc(userId);
      DocumentSnapshot cartDoc = await cartDocRef.get();

      if (!cartDoc.exists) throw Exception('Cart does not exist');

      Map<String, dynamic> data = cartDoc.data() as Map<String, dynamic>;
      List<dynamic> items = data['items'] ?? [];
      List<CartItemModel> cartItems =
          items.map((item) => CartItemModel.fromMap(item)).toList();

      int itemIndex = cartItems.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) throw Exception('Item not found in cart');

      if (quantity <= 0) {
        cartItems.removeAt(itemIndex);
      } else {
        cartItems[itemIndex].quantity = quantity;
      }

      await cartDocRef.update({
        'items': cartItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating cart item quantity: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      await updateCartItemQuantity(itemId, 0);
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      if (userId.isEmpty) throw Exception('User not logged in');

      await cartsRef.doc(userId).update({
        'items': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  // Order methods
  Future<List<OrderModel>> getUserOrders() async {
    try {
      if (userId.isEmpty) {
        debugPrint(
            '❌ getUserOrders: No user ID available. User might not be logged in.');
        return [];
      }

      debugPrint('🔍 Fetching orders for user: $userId');

      // Debug current auth state
      if (currentUser != null) {
        debugPrint(
            '👤 User is authenticated - Email: ${currentUser?.email}, UID: ${currentUser?.uid}');
      } else {
        debugPrint('❗ No authenticated user found');
      }

      // Get the orders reference
      final ordersCollection = ordersRef;
      debugPrint('📂 Querying orders collection: ${ordersCollection.path}');

      // IMPROVED APPROACH: Get all orders first, then filter in memory to avoid index issues
      QuerySnapshot snapshot = await ordersCollection.get();

      debugPrint(
          '📋 Query returned ${snapshot.docs.length} total orders in database');

      // Filter orders in memory for the current user
      List<OrderModel> orders = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Check if this order belongs to the current user, handling both string and other types
          String docUserId = data['userId']?.toString() ?? '';

          // Case insensitive comparison to be safe
          if (docUserId.toLowerCase() == userId.toLowerCase()) {
            debugPrint('📦 Found matching order: ${data['id']}');

            OrderModel order = OrderModel.fromMap(data);
            debugPrint('✅ Successfully parsed order: ${order.id}');
            orders.add(order);
          }
        } catch (e) {
          debugPrint('❌ Error parsing order document: $e');
          // Continue with next document
        }
      }

      // Sort orders by date (descending) since we're not using orderBy in the query anymore
      orders.sort((a, b) => b.OrderDate.compareTo(a.OrderDate));

      debugPrint('📊 Returning ${orders.length} orders to controller');
      return orders;
    } catch (e) {
      debugPrint('❌ Error in getUserOrders: $e');
      return [];
    }
  }
  
  // Get all orders from Firestore (for admin use)
  Future<List<OrderModel>> getAllOrders() async {
    try {
      debugPrint('🔍 Admin: Fetching all orders from database');
      
      // Get all orders from Firestore
      QuerySnapshot snapshot = await ordersRef
          .orderBy('OrderDate', descending: true)
          .get();
      
      debugPrint('📋 Query returned ${snapshot.docs.length} total orders');
      
      // Parse all orders
      List<OrderModel> orders = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          OrderModel order = OrderModel.fromMap(data);
          orders.add(order);
        } catch (e) {
          debugPrint('❌ Error parsing order document: $e');
          // Continue with next document
        }
      }
      
      debugPrint('📊 Returning ${orders.length} orders to admin panel');
      return orders;
    } catch (e) {
      debugPrint('❌ Error in getAllOrders: $e');
      return [];
    }
  }

  Future<String> placeOrder({
    required List<CartItemModel> items,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
    PaymentDetailsModel? paymentDetails,
    double? profit,
  }) async {
    try {
      if (userId.isEmpty) {
        debugPrint('❌ placeOrder: User is not logged in');
        throw Exception('User not logged in');
      }

      String orderId = const Uuid().v4();
      debugPrint('🆕 Creating new order with ID: $orderId for user: $userId');

      // Ensure userId is stored as a string
      String orderUserId = userId.toString();

      // Convert CartItemModels to Maps
      List<Map<String, dynamic>> itemMaps = items.map((item) => item.toMap()).toList();
      
      // Create order data
      Map<String, dynamic> orderData = {
        'id': orderId,
        'userId': orderUserId,
        'items': itemMaps,
        'totalAmount': totalAmount,
        'shippingAddress': shippingAddress,
        'status': OrderStatus.pending.name,
        'OrderDate': DateTime.now().millisecondsSinceEpoch,
        'paymentMethod': paymentMethod,
        'isPaid': paymentMethod != 'Cash on Delivery',
        'paymentDetails': paymentDetails?.toMap(),
        'profit': profit ?? (totalAmount * 0.15), // Store the profit (15% of total by default)
      };

      // Convert to map for debugging
      Map<String, dynamic> orderMap = orderData;
      debugPrint(
          '📝 Order data: UserID: ${orderMap['userId']}, Items: ${items.length}, Total: $totalAmount');

      if (paymentDetails != null) {
        debugPrint('💳 Payment method: ${paymentDetails.paymentMethod}');
        if (paymentDetails.paymentMethod == 'Credit Card') {
          debugPrint('💳 Card details provided for payment');
        } else if (paymentDetails.paymentMethod == 'Bank Transfer') {
          debugPrint('🏦 Bank details provided for payment');
        }
      }

      // Save to Firestore
      await ordersRef.doc(orderId).set(orderMap);
      debugPrint('✅ Order document created successfully in Firestore');

      // Clear cart after successful order
      await clearCart();

      return orderId;
    } catch (e) {
      debugPrint('❌ Error in placeOrder: $e');
      rethrow;
    }
  }

  // Get recommended products from Firestore (now returns all products)
  Future<List<ProductModel>> getRecommendedProducts() async {
    try {
      // Get all products with a reasonable limit instead of just recommended ones
      QuerySnapshot querySnapshot = await productsRef
          .limit(20)
          .get();
      
      List<ProductModel> allProducts = querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      debugPrint('✅ Fetched ${allProducts.length} products for "All Products" section');
      return allProducts;
    } catch (e) {
      debugPrint('❌ Error getting products: $e');
      return [];
    }
  }

  // Wishlist methods
  Future<List<WishlistModel>> getWishlistItems() async {
    try {
      if (userId.isEmpty) return [];

      debugPrint('🔍 Fetching wishlist for user: $userId');

      DocumentSnapshot wishlistDoc = await wishlistsRef.doc(userId).get();
      if (!wishlistDoc.exists) {
        debugPrint('ℹ️ No wishlist found for user');
        return [];
      }

      Map<String, dynamic> data = wishlistDoc.data() as Map<String, dynamic>;
      List<dynamic> items = data['items'] ?? [];

      debugPrint('✅ Found ${items.length} items in wishlist');

      return items.map((item) => WishlistModel.fromMap(item)).toList();
    } catch (e) {
      debugPrint('❌ Error getting wishlist items: $e');
      return [];
    }
  }

  Future<bool> isProductInWishlist(String productId) async {
    try {
      if (userId.isEmpty) return false;

      List<WishlistModel> wishlistItems = await getWishlistItems();
      return wishlistItems.any((item) => item.productId == productId);
    } catch (e) {
      debugPrint('❌ Error checking if product is in wishlist: $e');
      return false;
    }
  }

  Future<void> addToWishlist(ProductModel product) async {
    try {
      if (userId.isEmpty) throw Exception('User not logged in');

      debugPrint('➕ Adding product to wishlist: ${product.id}');

      DocumentReference wishlistDocRef = wishlistsRef.doc(userId);
      DocumentSnapshot wishlistDoc = await wishlistDocRef.get();

      List<WishlistModel> wishlistItems = [];
      if (wishlistDoc.exists) {
        Map<String, dynamic> data = wishlistDoc.data() as Map<String, dynamic>;
        List<dynamic> items = data['items'] ?? [];
        wishlistItems =
            items.map((item) => WishlistModel.fromMap(item)).toList();
      }

      // Check if product already exists in wishlist
      if (wishlistItems.any((item) => item.productId == product.id)) {
        debugPrint('ℹ️ Product already in wishlist');
        return;
      }

      // Add new item
      wishlistItems.add(WishlistModel(
        id: const Uuid().v4(),
        productId: product.id,
        productName: product.name,
        productPrice: product.price,
        productImage: product.images.isNotEmpty ? product.images[0] : '',
        addedAt: DateTime.now(),
      ));

      await wishlistDocRef.set({
        'userId': userId,
        'items': wishlistItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Product added to wishlist successfully');
    } catch (e) {
      debugPrint('❌ Error adding to wishlist: $e');
      rethrow;
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    try {
      if (userId.isEmpty) throw Exception('User not logged in');

      debugPrint('➖ Removing product from wishlist: $productId');

      DocumentReference wishlistDocRef = wishlistsRef.doc(userId);
      DocumentSnapshot wishlistDoc = await wishlistDocRef.get();

      if (!wishlistDoc.exists) {
        debugPrint('ℹ️ Wishlist does not exist');
        return;
      }

      Map<String, dynamic> data = wishlistDoc.data() as Map<String, dynamic>;
      List<dynamic> items = data['items'] ?? [];
      List<WishlistModel> wishlistItems =
          items.map((item) => WishlistModel.fromMap(item)).toList();

      // Remove item
      wishlistItems.removeWhere((item) => item.productId == productId);

      await wishlistDocRef.update({
        'items': wishlistItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Product removed from wishlist successfully');
    } catch (e) {
      debugPrint('❌ Error removing from wishlist: $e');
      rethrow;
    }
  }

  Future<void> toggleWishlist(ProductModel product) async {
    try {
      bool isInWishlist = await isProductInWishlist(product.id);

      if (isInWishlist) {
        await removeFromWishlist(product.id);
      } else {
        await addToWishlist(product);
      }
    } catch (e) {
      debugPrint('❌ Error toggling wishlist: $e');
      rethrow;
    }
  }

  /// Make a user an admin
  Future<bool> makeUserAdmin(String userId) async {
    try {
      await usersRef.doc(userId).update({'isAdmin': true});
      debugPrint('✅ User $userId has been made an admin');
      return true;
    } catch (e) {
      debugPrint('❌ Error making user an admin: $e');
      return false;
    }
  }

  /// Delete a user's data from Firestore
  Future<void> deleteUserData(String userId) async {
    try {
      debugPrint('🗑️ Deleting user data for user: $userId');
      
      // Delete user's cart
      await cartsRef.doc(userId).delete();
      
      // Delete user's wishlist
      await wishlistsRef.doc(userId).delete();
      
      // Get user's orders
      QuerySnapshot orderSnapshot = await ordersRef
          .where('userId', isEqualTo: userId)
          .get();
      
      // Delete each order
      for (var doc in orderSnapshot.docs) {
        await ordersRef.doc(doc.id).delete();
      }
      
      // Finally delete the user document
      await usersRef.doc(userId).delete();
      
      debugPrint('✅ User data deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting user data: $e');
      rethrow;
    }
  }

  Future<FirebaseService> init() async {
    debugPrint('Initializing Firebase Service');
    // Any initialization logic can go here
    return this;
  }

  // Add the missing getOrderById method
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      debugPrint('🔄 Getting order with ID: $orderId');
      
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
          
      if (!orderDoc.exists) {
        debugPrint('❌ Order not found with ID: $orderId');
        return null;
      }
      
      final orderData = orderDoc.data()!;
      return OrderModel.fromMap(orderData);
    } catch (e) {
      debugPrint('❌ Error getting order by ID: $e');
      return null;
    }
  }
}
