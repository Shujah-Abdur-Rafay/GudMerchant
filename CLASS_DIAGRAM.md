# GoodMerchant E-commerce App - Class System

This document explains the class architecture and relationships in the GoodMerchant e-commerce application, presenting class diagrams for each major component of the system.

## 📊 Class Diagram Overview

```
┌───────────────────┐      ┌───────────────────┐      ┌───────────────────┐
│     Models        │      │    Controllers    │      │     Services      │
│                   │      │                   │      │                   │
│  ┌─────────────┐  │      │  ┌─────────────┐  │      │  ┌─────────────┐  │
│  │  UserModel  │  │      │  │AuthController│◄─┼──────┼─►│FirebaseService│  │
│  └─────────────┘  │      │  └─────────────┘  │      │  └─────────────┘  │
│        ▲          │      │        ▲          │      │        ▲          │
│        │          │      │        │          │      │        │          │
│  ┌─────────────┐  │      │  ┌─────────────┐  │      │  ┌─────────────┐  │
│  │ ProductModel│◄─┼──────┼─►│ProductControl│◄─┼──────┼─►│ AdminService │  │
│  └─────────────┘  │      │  └─────────────┘  │      │  └─────────────┘  │
│        ▲          │      │        ▲          │      │                   │
│        │          │      │        │          │      └───────────────────┘
│  ┌─────────────┐  │      │  ┌─────────────┐  │
│  │CartItemModel│◄─┼──────┼─►│CartController│  │
│  └─────────────┘  │      │  └─────────────┘  │
│        ▲          │      │        ▲          │
│        │          │      │        │          │
│  ┌─────────────┐  │      │  ┌─────────────┐  │
│  │  OrderModel │◄─┼──────┼─►│OrderController│  │
│  └─────────────┘  │      │  └─────────────┘  │
│        ▲          │      │        ▲          │
│        │          │      │        │          │
│  ┌─────────────┐  │      │  ┌─────────────┐  │
│  │WishlistModel│◄─┼──────┼─►│WishlistContrl│  │
│  └─────────────┘  │      │  └─────────────┘  │
│                   │      │                   │
└───────────────────┘      └───────────────────┘
```

## 📝 Model Classes

The model classes define the data structures used in the application. They represent the business entities and encapsulate the data.

### UserModel

```dart
class UserModel {
  final String uID;
  final String username;
  final String email;
  final String userAdress;
  final DateTime createdAt;
  final bool isAdmin;
  
  // Constructor and methods
}
```

**Responsibilities**:
- Store user information and preferences
- Provide serialization/deserialization methods for Firestore

**Relationships**:
- Used by AuthController for user management

### ProductModel

```dart
class ProductModel {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> images;
  final String category;
  final int stock;
  final bool isFeatured;
  final double rating;
  
  // Constructor and methods
}
```

**Responsibilities**:
- Store product details
- Provide serialization/deserialization methods for Firestore

**Relationships**:
- Used by ProductController for product management
- Referenced by CartItemModel for cart items
- Referenced by OrderModel for order items

### CartItemModel

```dart
class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  int quantity;
  
  double get totalPrice => productPrice * quantity;
  
  // Constructor and methods
}
```

**Responsibilities**:
- Store cart item information
- Calculate total price for items

**Relationships**:
- Used by CartController for cart management
- References ProductModel via productId
- Used in OrderModel for creating orders

### OrderModel

```dart
class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double totalAmount;
  final String shippingAddress;
  final OrderStatus status;
  final DateTime OrderDate;
  final String paymentMethod;
  final bool isPaid;
  final PaymentDetailsModel? paymentDetails;
  
  // Constructor and methods
}

enum OrderStatus { 
  pending, 
  processing, 
  shipped, 
  delivered, 
  cancelled 
}
```

**Responsibilities**:
- Store order information
- Track order status

**Relationships**:
- Used by OrderController for order management
- Contains CartItemModel instances for order items
- References UserModel via userId
- Contains PaymentDetailsModel for payment information

### PaymentDetailsModel

```dart
class PaymentDetailsModel {
  final String paymentMethod;
  
  // Credit card details
  final String? cardNumber;
  final String? cardHolderName;
  final String? expiryDate;
  final String? cvv;
  
  // Bank transfer details
  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final String? routingNumber;
  
  // Constructor and methods
}
```

**Responsibilities**:
- Store payment details based on payment method
- Provide serialization/deserialization methods for Firestore

**Relationships**:
- Used by OrderModel for payment information
- Used by OrderController during checkout

### WishlistModel

```dart
class WishlistModel {
  final String id;
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  final DateTime addedAt;
  
  // Constructor and methods
}
```

**Responsibilities**:
- Store wishlist item information

**Relationships**:
- Used by WishlistController for wishlist management
- References ProductModel via productId

## 🎮 Controller Classes

The controller classes manage the application state and business logic. They use reactive programming with GetX.

### AuthController

```dart
class AuthController extends GetxController {
  final FirebaseService _firebaseService;
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  
  UserModel? get userModel => _userModel.value;
  bool get isLoading => _isLoading.value;
  
  // Methods for authentication
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password, required String username});
  Future<void> signOut();
  Future<void> resetPassword(String email);
  
  // User data methods
  Future<void> updateUserProfile({String? username, String? address});
}
```

**Responsibilities**:
- Manage user authentication state
- Handle login, signup, and logout
- Manage user profile data

**Relationships**:
- Uses FirebaseService for Firebase interactions
- Manages UserModel instances

### ProductController

```dart
class ProductController extends GetxController {
  final FirebaseService _firebaseService;
  final RxList<ProductModel> _products = <ProductModel>[].obs;
  final RxList<ProductModel> _featuredProducts = <ProductModel>[].obs;
  final RxBool _isLoading = false.obs;
  
  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading.value;
  
  // Product fetching methods
  Future<void> fetchProducts();
  Future<void> fetchFeaturedProducts();
  Future<void> fetchProductsByCategory(String category);
  Future<ProductModel?> getProductById(String id);
  
  // Product search method
  List<ProductModel> searchProducts(String query);
}
```

**Responsibilities**:
- Manage product data
- Fetch and filter products

**Relationships**:
- Uses FirebaseService for Firebase interactions
- Manages ProductModel instances

### CartController

```dart
class CartController extends GetxController {
  final FirebaseService _firebaseService;
  final RxList<CartItemModel> _cartItems = <CartItemModel>[].obs;
  final RxBool _isLoading = false.obs;
  
  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading.value;
  double get totalAmount => _calculateTotal();
  
  // Cart methods
  Future<void> addToCart(ProductModel product, int quantity);
  Future<void> updateCartItemQuantity(String itemId, int quantity);
  Future<void> removeFromCart(String itemId);
  Future<void> clearCart();
  
  // Helper methods
  double _calculateTotal();
}
```

**Responsibilities**:
- Manage shopping cart state
- Add, update, remove cart items
- Calculate cart totals

**Relationships**:
- Uses FirebaseService for Firebase interactions
- Manages CartItemModel instances
- Interacts with ProductModel instances

### OrderController

```dart
class OrderController extends GetxController {
  final FirebaseService _firebaseService;
  final RxList<OrderModel> _orders = <OrderModel>[].obs;
  final RxBool _isLoading = false.obs;
  
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading.value;
  
  // Order methods
  Future<void> fetchUserOrders();
  Future<bool> placeOrder({
    required List<CartItemModel> items,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
    PaymentDetailsModel? paymentDetails,
  });
  Future<void> forceRefresh();
  OrderModel? getOrderById(String orderId);
}
```

**Responsibilities**:
- Manage order data
- Place new orders
- Fetch and update orders

**Relationships**:
- Uses FirebaseService for Firebase interactions
- Manages OrderModel instances
- Interacts with CartItemModel instances
- Interacts with PaymentDetailsModel instances

### WishlistController

```dart
class WishlistController extends GetxController {
  final FirebaseService _firebaseService;
  final RxList<WishlistModel> _wishlistItems = <WishlistModel>[].obs;
  final RxBool _isLoading = false.obs;
  
  List<WishlistModel> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading.value;
  
  // Wishlist methods
  Future<void> fetchWishlistItems();
  Future<void> addToWishlist(ProductModel product);
  Future<void> removeFromWishlist(String productId);
  Future<bool> isProductInWishlist(String productId);
  Future<void> toggleWishlist(ProductModel product);
}
```

**Responsibilities**:
- Manage wishlist state
- Add, remove wishlist items
- Check product status in wishlist

**Relationships**:
- Uses FirebaseService for Firebase interactions
- Manages WishlistModel instances
- Interacts with ProductModel instances

## 🔌 Service Classes

The service classes handle external interactions and data operations.

### FirebaseService

```dart
class FirebaseService extends GetxService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String get userId => currentUser?.uid ?? '';
  
  // Collection references
  CollectionReference get usersRef => _firestore.collection('users');
  CollectionReference get productsRef => _firestore.collection('products');
  CollectionReference get cartsRef => _firestore.collection('carts');
  CollectionReference get ordersRef => _firestore.collection('orders');
  CollectionReference get wishlistsRef => _firestore.collection('wishlists');

  // Authentication methods
  Future<UserCredential> signUpWithEmailPassword(String email, String password);
  Future<UserCredential> signInWithEmailPassword(String email, String password);
  Future<void> signOut();
  
  // User data methods
  Future<void> createUserRecord(UserModel user);
  Future<UserModel?> getUserData();
  
  // Products methods
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getFeaturedProducts();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<ProductModel?> getProductById(String productId);
  
  // Cart methods
  Future<List<CartItemModel>> getCartItems();
  Future<void> addToCart(ProductModel product, int quantity);
  Future<void> updateCartItemQuantity(String itemId, int quantity);
  Future<void> removeFromCart(String itemId);
  Future<void> clearCart();
  
  // Order methods
  Future<List<OrderModel>> getUserOrders();
  Future<String> placeOrder({
    required List<CartItemModel> items,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
    PaymentDetailsModel? paymentDetails,
  });
  
  // Wishlist methods
  Future<List<WishlistModel>> getWishlistItems();
  Future<bool> isProductInWishlist(String productId);
  Future<void> addToWishlist(ProductModel product);
  Future<void> removeFromWishlist(String productId);
}
```

**Responsibilities**:
- Manage Firebase authentication
- Provide Firestore database access
- Handle all Firebase interactions

**Relationships**:
- Used by all controllers
- Manages all model instances persistence

### AdminService

```dart
class AdminService extends GetxService {
  final FirebaseFirestore _firestore;
  
  // Admin methods
  Future<void> uploadMockProducts();
  Future<void> updateProductStock(String productId, int stockCount);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<List<OrderModel>> getAllOrders();
}
```

**Responsibilities**:
- Provide admin-specific functionality
- Handle admin-only operations

**Relationships**:
- Uses FirebaseService for Firebase interactions
- Used by ProductController for admin operations
- Manages ProductModel and OrderModel instances for admin tasks

## 🔄 Class Inheritance and Implementations

```
┌─────────────────────┐
│    GetxController    │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│    BaseController   │
└─────────┬───────────┘
          │
     ┌────┴─────┬─────────┬──────────┬────────────┐
     ▼          ▼         ▼          ▼            ▼
┌──────────┐ ┌───────┐ ┌───────┐ ┌────────┐ ┌──────────┐
│AuthContrl│ │ProdCtrl│ │CartCtrl│ │OrderCtrl│ │WishlistCt│
└──────────┘ └───────┘ └───────┘ └────────┘ └──────────┘
```

```
┌─────────────────────┐
│      GetxService    │
└─────────┬───────────┘
          │
     ┌────┴────────┐
     ▼             ▼
┌──────────┐ ┌──────────┐
│FirebaseSv│ │AdminSv   │
└──────────┘ └──────────┘
```

## 🔄 Dependency Injection

The application uses GetX dependency injection to manage service and controller instances:

```dart
// In main.dart
Future<void> initServices() async {
  try {
    // Register services first
    Get.put(FirebaseService(), permanent: true);
    Get.put(AdminService(), permanent: true);
    
    // Register controllers
    Get.put(AuthController(), permanent: true);
    Get.put(ProductController(), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(OrderController(), permanent: true);
    Get.put(WishlistController(), permanent: true);
  } catch (e) {
    debugPrint('❌ Error initializing services: $e');
  }
}
```

## 📦 Widget Classes

While not complete classes in the traditional OOP sense, the widget classes form an important part of the Flutter UI hierarchy:

```
┌─────────────────────┐
│      StatelessWidget│
└─────────┬───────────┘
          │
     ┌────┴────────────────┬─────────────────┐
     ▼                     ▼                 ▼
┌──────────┐        ┌──────────┐      ┌──────────┐
│ProductCard│        │OrderItem  │      │CartItem  │
└──────────┘        └──────────┘      └──────────┘
```

```
┌─────────────────────┐
│      StatefulWidget │
└─────────┬───────────┘
          │
     ┌────┴────────────────┬─────────────────┐
     ▼                     ▼                 ▼
┌──────────┐        ┌──────────┐      ┌──────────┐
│HomeScreen │        │CartScreen │      │CheckoutScr│
└──────────┘        └──────────┘      └──────────┘
```

The widgets use the controllers through GetX to access and modify application state. 