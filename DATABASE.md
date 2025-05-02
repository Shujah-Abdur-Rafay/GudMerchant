# GoodMerchant Database Documentation

This document provides comprehensive information about the database structure, operations, and security rules for the GoodMerchant e-commerce application.

## 🔍 Database Overview

GoodMerchant uses Firebase Cloud Firestore as the primary database. It's a NoSQL, document-oriented database that provides real-time synchronization and offline support.

## 📊 Database Collections

### 1. **users**
Stores user profiles and account information.

```
users/{userId}
  - uID: string                // User ID (same as Firebase Auth UID)
  - username: string           // User's display name
  - email: string              // User's email address
  - phone: string              // User's phone number
  - userImg: string            // URL to user's profile image
  - userDeviceToken: string    // Device token for push notifications
  - country: string            // User's country
  - userAdress: string         // User's address
  - street: string             // User's street address
  - isAdmin: boolean           // Whether user has admin privileges
  - isActive: boolean          // Whether user account is active
  - CreatedOn: timestamp       // Account creation date
```

### 2. **products**
Contains the product catalog information.

```
products/{productId}
  - id: string                 // Product unique identifier
  - name: string               // Product name
  - description: string        // Product description
  - price: number              // Product price
  - images: string[]           // Array of image URLs
  - category: string           // Product category
  - stockQuantity: number      // Available stock quantity
  - isFeatured: boolean        // Whether product is featured
  - rating: number             // Average product rating
  - reviewCount: number        // Number of reviews
  - createdAt: timestamp       // When product was added
```

### 3. **carts**
Manages user shopping cart items.

```
carts/{userId}
  - userId: string             // User ID who owns the cart
  - items: array               // Cart items array
    - id: string               // Cart item ID
    - productId: string        // Reference to product
    - productName: string      // Product name (denormalized)
    - productPrice: number     // Product price (denormalized)
    - productImage: string     // Product image URL (denormalized)
    - quantity: number         // Quantity of item
  - updatedAt: timestamp       // Last cart update timestamp
```

### 4. **orders**
Stores order information and history.

```
orders/{orderId}
  - id: string                 // Order unique identifier
  - userId: string             // User who placed the order
  - items: array               // Ordered items (same structure as cart items)
  - totalAmount: number        // Total order amount
  - shippingAddress: string    // Delivery address
  - status: string             // Order status (pending/processing/shipped/delivered/cancelled)
  - OrderDate: timestamp       // When order was placed
  - paymentMethod: string      // Payment method used
  - isPaid: boolean            // Whether order has been paid for
  - paymentDetails: object     // Payment information
    - paymentMethod: string    // Payment method type
    - cardNumber: string       // For credit card payments
    - cardHolderName: string   // For credit card payments
    - expiryDate: string       // For credit card payments
    - cvv: string              // For credit card payments
    - bankName: string         // For bank transfer payments
    - accountNumber: string    // For bank transfer payments
    - accountHolderName: string // For bank transfer payments
    - routingNumber: string    // For bank transfer payments
```

### 5. **wishlists**
Tracks user wishlist items.

```
wishlists/{userId}
  - userId: string             // User ID who owns the wishlist
  - items: array               // Wishlist items
    - id: string               // Wishlist item ID
    - productId: string        // Reference to product
    - productName: string      // Product name (denormalized)
    - productPrice: number     // Product price (denormalized)
    - productImage: string     // Product image URL (denormalized)
    - addedAt: timestamp       // When item was added to wishlist
  - updatedAt: timestamp       // Last wishlist update
```

## 🔐 Security Rules

The database is protected by custom Firestore security rules to ensure data integrity and access control:

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

## 🔄 Database Operations

### User Operations

#### User Authentication
- **Sign Up**: `signUpWithEmailPassword(email, password)`
- **Sign In**: `signInWithEmailPassword(email, password)`
- **Sign Out**: `signOut()`

#### User Profile Management
- **Create User**: `createUserRecord(UserModel user)`
- **Get User Data**: `getUserData()`

### Product Operations

#### Retrieving Products
- **Get All Products**: `getProducts()`
- **Get Products by Category**: *Uses client-side filtering*
- **Get Featured Products**: *Uses client-side filtering*
- **Get Product by ID**: *Uses client-side filtering*

#### Admin Product Management
- **Upload Mock Products**: `uploadMockProducts()`
- **Clear All Products**: `clearAllProducts()` (Safety feature: intentionally left unimplemented)

### Cart Operations

#### Cart Management
- **Get Cart Items**: `getCartItems()`
- **Add to Cart**: `addToCart(ProductModel product, [int quantity])`
- **Update Cart Item Quantity**: `updateCartItemQuantity(String itemId, int quantity)`
- **Remove from Cart**: `removeFromCart(String itemId)`
- **Clear Cart**: `clearCart()`

### Order Operations

#### Order Management
- **Get User Orders**: `getUserOrders()`
- **Place Order**: `placeOrder({ items, totalAmount, shippingAddress, paymentMethod, paymentDetails })`

### Wishlist Operations

#### Wishlist Management
- **Get Wishlist Items**: `getWishlistItems()`
- **Check if Product in Wishlist**: `isProductInWishlist(String productId)`
- **Add to Wishlist**: `addToWishlist(ProductModel product)`
- **Remove from Wishlist**: `removeFromWishlist(String productId)`
- **Toggle Wishlist Item**: `toggleWishlist(ProductModel product)`

## 📋 Data Models

The application uses strongly-typed Dart models for interacting with the database:

1. **UserModel**: Represents user account information
2. **ProductModel**: Represents product information
3. **CartItemModel**: Represents items in a shopping cart
4. **OrderModel**: Represents an order
5. **PaymentDetailsModel**: Represents payment information for orders
6. **WishlistModel**: Represents items in a user's wishlist

## 🔄 State Management

The application uses GetX for state management, including reactive state with database operations:

```dart
// Example of reactive state with GetX
final RxList<CartItemModel> _cartItems = <CartItemModel>[].obs;
final RxBool _isLoading = false.obs;
```

## ⚠️ Important Notes

1. **Data Denormalization**: Some data (like product details in carts and wishlists) is intentionally denormalized for better performance and offline support.

2. **Transaction Safety**: The database operations use try-catch blocks to ensure data consistency and handle potential errors.

3. **Development Tools**: Admin features for uploading mock data should only be enabled in development environments.

4. **Security**: Ensure Firebase security rules are properly set up to protect sensitive data. Admin access is controlled via the `isAdmin` field in user documents.

5. **Performance Considerations**:
   - Limit query sizes when retrieving large data sets
   - Use offline persistence features for a better user experience
   - Monitor database usage and costs 