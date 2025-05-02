class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  int quantity;
  
  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      productImage: map['productImage'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }

  double get totalPrice => productPrice * quantity;
} 