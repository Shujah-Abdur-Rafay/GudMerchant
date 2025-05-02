# GoodMerchant E-commerce App - System Architecture

This document outlines the technical architecture, design patterns, and system components of the GoodMerchant E-commerce application.

## 🏗️ System Architecture Overview

GoodMerchant follows a client-server architecture with Flutter as the cross-platform frontend and Firebase as the serverless backend.

### Architecture Diagram

```
┌─────────────────────────────────────┐     ┌──────────────────────────────┐
│            Client Side              │     │         Server Side          │
│         (Flutter Mobile App)        │     │        (Firebase Cloud)      │
│                                     │     │                              │
│  ┌─────────────┐    ┌─────────────┐ │     │  ┌─────────────┐             │
│  │    Views    │    │Controllers  │ │     │  │  Firestore  │             │
│  │  (Screens)  │◄───│   (GetX)    │ │     │  │  Database   │             │
│  └─────────────┘    └────┬────────┘ │     │  └──────┬──────┘             │
│         ▲                │          │     │         │                    │
│         │                │          │     │         │                    │
│         │                │          │     │         │                    │
│  ┌──────┴────────┐  ┌────▼────────┐ │     │  ┌──────▼──────┐             │
│  │   Widgets &   │  │ Firebase    │ │◄────┼──►│Firebase Auth│             │
│  │  Components   │  │ Services    │ │     │  └─────────────┘             │
│  └───────────────┘  └────┬────────┘ │     │                              │
│                          │          │     │  ┌─────────────┐             │
│  ┌───────────────┐  ┌────▼────────┐ │     │  │   Storage   │             │
│  │    Models     │◄─┤    Utils    │ │     │  │   Service   │             │
│  └───────────────┘  └─────────────┘ │     │  └─────────────┘             │
│                                     │     │                              │
└─────────────────────────────────────┘     └──────────────────────────────┘
```

## 📱 Client-Side Architecture

### Design Pattern: GetX (MVVM-like)

The app follows a Model-View-ViewModel pattern implemented using the GetX state management framework:

- **Models**: Data structures that represent application entities
- **Views**: UI screens and widgets that display data to the user
- **Controllers**: Manage state, business logic, and interact with services
- **Services**: Handle data operations and external API communication

### Key Components

#### 1. Models

Located in `/lib/models/`, these classes define the data structures:

- `UserModel`: User profile data
- `ProductModel`: Product information
- `CartItemModel`: Shopping cart items
- `OrderModel`: Order information
- `PaymentDetailsModel`: Payment information
- `WishlistModel`: Wishlist items

Example model structure (simplified):

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
  
  // Constructor and JSON serialization methods
}
```

#### 2. Screens & Widgets

Located in `/lib/screens/` and `/lib/widgets/`, these files contain the UI components:

- **Screens**: Complete UI pages (`HomeScreen`, `ProductDetailScreen`, etc.)
- **Widgets**: Reusable UI components (`ProductCard`, `CartItem`, etc.)

The UI follows Flutter's widget-based composition pattern.

#### 3. Controllers

Located in `/lib/controllers/`, these classes manage state and business logic:

- `AuthController`: Handles user authentication
- `ProductController`: Manages product data and operations
- `CartController`: Manages shopping cart state
- `OrderController`: Handles order processing
- `WishlistController`: Manages wishlist operations

Example controller structure (simplified):

```dart
class CartController extends GetxController {
  final RxList<CartItemModel> _cartItems = <CartItemModel>[].obs;
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  List<CartItemModel> get cartItems => _cartItems;
  
  Future<void> addToCart(ProductModel product, int quantity) async {
    // Implementation
  }
  
  double get totalAmount => _calculateTotal();
  
  // Other methods
}
```

#### 4. Services

Located in `/lib/services/`, these handle external data operations:

- `FirebaseService`: Manages all Firebase interactions
- `AdminService`: Provides admin-specific operations

## ☁️ Server-Side Architecture

### Firebase Backend

The application uses Firebase as a serverless backend with the following components:

#### 1. Firebase Authentication

Handles user authentication with multiple providers:
- Email/password authentication
- Google Sign-In
- Anonymous authentication

#### 2. Cloud Firestore

NoSQL database organized into collections:

- **users**: User profiles and preferences
  ```
  users/{userId}
    - username
    - email
    - userAdress
    - createdAt
    - ...
  ```

- **products**: Product catalog
  ```
  products/{productId}
    - name
    - price
    - description
    - category
    - images[]
    - stock
    - ...
  ```

- **carts**: Shopping cart data
  ```
  carts/{userId}
    - userId
    - items[]
      - productId
      - quantity
      - ...
    - updatedAt
  ```

- **orders**: User orders
  ```
  orders/{orderId}
    - userId
    - items[]
    - totalAmount
    - status
    - paymentMethod
    - shippingAddress
    - ...
  ```

- **wishlists**: User wishlists
  ```
  wishlists/{userId}
    - userId
    - items[]
    - updatedAt
  ```

#### 3. Firebase Storage

Stores product images and user uploads.

#### 4. Security Rules

Custom Firestore security rules ensure data protection:

```
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read their own data
    match /users/{userId} {
      allow read, update, delete: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }
    
    // Products are readable by all, writable by admins
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Orders rules
    match /orders/{orderId} {
      allow read: if request.auth != null && (request.auth.uid == resource.data.userId || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

## 🔄 State Management

### GetX State Management

The application uses GetX for state management, route management, and dependency injection:

#### 1. Reactive State

Uses `Rx` variables and `.obs` for reactive state:

```dart
// Declaration
final RxList<CartItemModel> _cartItems = <CartItemModel>[].obs;
final RxBool _isLoading = false.obs;

// Usage in UI
Obx(() => _isLoading.value 
  ? CircularProgressIndicator() 
  : ProductListView(products: _products))
```

#### 2. Dependency Injection

Services and controllers are injected using GetX:

```dart
// Registration
void initServices() {
  Get.put(FirebaseService(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(ProductController(), permanent: true);
}

// Usage
final productController = Get.find<ProductController>();
```

#### 3. Route Management

Navigation using GetX router:

```dart
// Navigation
Get.to(() => ProductDetailScreen(product: product));

// Dialog
Get.dialog(CustomAlertDialog());

// Snackbar
Get.snackbar('Success', 'Item added to cart');
```

## 📊 Data Flow

### Request Flow Example: Adding a Product to Cart

1. **UI Action**: User taps "Add to Cart" button on product screen
2. **Controller**: `CartController.addToCart(product, quantity)` is called
3. **Service**: `FirebaseService.addToCart(product, quantity)` processes the request
4. **Firebase**: Data is sent to Firestore to update the cart collection
5. **Response**: Success/failure is returned to the controller
6. **State Update**: CartController updates its state with the new cart item
7. **UI Update**: Cart UI reactively updates due to Obx() observers

## 📱 UI Architecture

### Screen Structure

Screens follow a consistent structure:

```dart
class ProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: Obx(() => 
        productController.isLoading
          ? LoadingView()
          : productController.products.isEmpty
              ? EmptyStateView()
              : ListView.builder(
                  itemCount: productController.products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: productController.products[index],
                    );
                  },
                ),
      ),
    );
  }
}
```

### Theme Management

Centralized theme configuration in `app_theme.dart`:

```dart
class AppTheme {
  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Colors.white;
  static const Color textPrimaryColor = Colors.black87;
  
  // Spacing
  static const double spacing_sm = 8.0;
  static const double spacing_md = 16.0;
  
  // Border radius
  static const double borderRadius = 8.0;
  
  // Theme data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      // Other theme configurations
    );
  }
}
```

## 🔒 Security Architecture

### Authentication Security

- Firebase Authentication for secure user authentication
- Password hashing and protection
- Email verification
- Google OAuth integration

### Data Security

- Firestore security rules for access control
- Field-level validation
- Admin-only operations protection

### Payment Security

- Sensitive payment details protection
- Secure payment processing
- PCI compliance considerations

## 🚀 Performance Optimizations

### Data Loading Optimizations

- Pagination for product listings
- Lazy loading of images
- Caching strategies

### UI Performance

- Widget optimization
- Memory management
- Image optimization and caching

## 💾 Local Storage

### Shared Preferences

Used for storing small user preferences and settings.

### Caching

- Product images cached using CachedNetworkImage
- Query results cached for offline support

## 📶 Network Architecture

### API Communication

- RESTful API calls to Firebase
- Error handling and retry mechanisms
- Connection state management

### Offline Support

- Offline data persistence
- Queue operations for offline actions
- Sync when reconnected

## 🧪 Testing Architecture

### Test Types

- Unit tests for business logic
- Widget tests for UI components
- Integration tests for complete flows

### Test Implementation

```dart
void main() {
  group('CartController Tests', () {
    late CartController cartController;
    
    setUp(() {
      // Setup test environment
    });
    
    test('Adding item to cart increases quantity', () {
      // Test implementation
    });
    
    test('Removing item from cart decreases quantity', () {
      // Test implementation
    });
  });
}
```

## 🔧 Dependency Management

Dependencies managed through `pubspec.yaml` with strict versioning to ensure stability.

## 🚀 Deployment Architecture

### Build Variants

- Development
- Staging
- Production

### Environment Configuration

Environment-specific configuration for Firebase projects.

## 📊 Analytics Architecture

Firebase Analytics integration for tracking:

- User engagement
- Screen views
- Conversion events
- Custom events

## 🗃️ Code Organization

### Directory Structure

```
lib/
├── main.dart             # Entry point
├── firebase_options.dart # Firebase configuration
├── controllers/          # Business logic and state management
├── models/               # Data models
├── screens/              # UI screens
│   ├── admin/            # Admin screens
│   ├── auth-ui/          # Authentication screens
│   ├── home/             # Home screens
│   ├── product/          # Product screens
│   ├── cart/             # Cart screens
│   ├── checkout/         # Checkout screens
│   ├── order/            # Order screens
│   └── profile/          # Profile screens
├── services/             # Services for external communication
├── utils/                # Utility functions and constants
├── providers/            # Data providers
├── components/           # Reusable UI components
└── widgets/              # Smaller reusable widgets
```

## 🔄 Continuous Integration/Deployment

### CI/CD Workflow

1. Code changes pushed to repository
2. Automated tests run
3. Build process initiated
4. Deployment to test environment
5. Manual testing and approval
6. Production deployment 