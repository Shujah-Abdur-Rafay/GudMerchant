import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistModel {
  final String id;
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  final DateTime addedAt;

  WishlistModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory WishlistModel.fromMap(Map<String, dynamic> map) {
    return WishlistModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      productImage: map['productImage'] ?? '',
      addedAt: map['addedAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['addedAt']) 
        : DateTime.now(),
    );
  }
} 