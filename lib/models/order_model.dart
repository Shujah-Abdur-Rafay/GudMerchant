// ignore_for_file: non_constant_identifier_names

import 'package:gudmerchant/models/cart_item_model.dart';
import 'package:gudmerchant/models/payment_details_model.dart';
import 'package:flutter/foundation.dart';

enum OrderStatus { 
  pending, 
  processing, 
  shipped, 
  delivered, 
  cancelled 
}

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
  final double profit; // 15% of total amount

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    this.status = OrderStatus.pending,
    required this.OrderDate,
    required this.paymentMethod,
    this.isPaid = false,
    this.paymentDetails,
    this.profit = 0, // Default value
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress,
      'status': status.name,
      'OrderDate': OrderDate.millisecondsSinceEpoch,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'paymentDetails': paymentDetails?.toMap(),
      'profit': profit,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    try {
      // Debug the incoming map
      debugPrint('🔍 Parsing OrderModel from map:');
      debugPrint('  - ID: ${map['id']}');
      debugPrint('  - UserID: ${map['userId']}');
      debugPrint('  - Status: ${map['status']}');
      debugPrint('  - Total: ${map['totalAmount']}');
      
      // Check for items list
      if (map['items'] == null) {
        debugPrint('⚠️ Warning: items is null in the order data');
      } else {
        debugPrint('  - Items count: ${(map['items'] as List?)?.length ?? 0}');
      }
      
      // Parse items with better error handling
      List<CartItemModel> cartItems = [];
      try {
        if (map['items'] != null) {
          cartItems = List<CartItemModel>.from(
            (map['items'] as List).map((item) => CartItemModel.fromMap(item)),
          );
        }
      } catch (e) {
        debugPrint('❌ Error parsing items array: $e');
      }
      
      // Parse date with better error handling
      DateTime orderDate = DateTime.now();
      try {
        if (map['OrderDate'] != null) {
          orderDate = DateTime.fromMillisecondsSinceEpoch(map['OrderDate']);
        } else {
          debugPrint('⚠️ Warning: OrderDate is missing in the data');
        }
      } catch (e) {
        debugPrint('❌ Error parsing OrderDate: $e');
      }
      
      // Parse status with better error handling
      OrderStatus orderStatus = OrderStatus.pending;
      try {
        if (map['status'] != null) {
          orderStatus = OrderStatus.values.firstWhere(
            (e) => e.name == map['status'],
            orElse: () => OrderStatus.pending,
          );
        } else {
          debugPrint('⚠️ Warning: status is missing in the data');
        }
      } catch (e) {
        debugPrint('❌ Error parsing status: $e');
      }
      
      // Parse payment details
      PaymentDetailsModel? paymentDetails;
      try {
        if (map['paymentDetails'] != null) {
          paymentDetails = PaymentDetailsModel.fromMap(map['paymentDetails']);
        }
      } catch (e) {
        debugPrint('❌ Error parsing payment details: $e');
      }
      
      // Parse profit with default
      double profit = 0;
      try {
        if (map['profit'] != null) {
          profit = (map['profit'] as num).toDouble();
        } else {
          // If profit is missing, calculate as 15% of total
          final totalAmount = (map['totalAmount'] ?? 0.0).toDouble();
          profit = totalAmount * 0.15;
        }
      } catch (e) {
        debugPrint('❌ Error parsing profit: $e');
      }
      
      return OrderModel(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        items: cartItems,
        totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
        shippingAddress: map['shippingAddress'] ?? '',
        status: orderStatus,
        OrderDate: orderDate,
        paymentMethod: map['paymentMethod'] ?? '',
        isPaid: map['isPaid'] ?? false,
        paymentDetails: paymentDetails,
        profit: profit,
      );
    } catch (e) {
      debugPrint('❌ Critical error parsing OrderModel: $e');
      rethrow;
    }
  }
} 