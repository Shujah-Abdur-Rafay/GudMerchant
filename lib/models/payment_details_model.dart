import 'package:flutter/foundation.dart';

/// Model for storing payment details for different payment methods
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
  
  PaymentDetailsModel({
    required this.paymentMethod,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.cvv,
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    this.routingNumber,
  });
  
  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {
      'paymentMethod': paymentMethod,
    };
    
    // Only include relevant details based on payment method
    if (paymentMethod == 'Credit Card') {
      data.addAll({
        'cardNumber': cardNumber,
        'cardHolderName': cardHolderName,
        'expiryDate': expiryDate,
        'cvv': cvv,
      });
    } else if (paymentMethod == 'Bank Transfer') {
      data.addAll({
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountHolderName': accountHolderName,
        'routingNumber': routingNumber,
      });
    }
    
    return data;
  }
  
  factory PaymentDetailsModel.fromMap(Map<String, dynamic> map) {
    try {
      String method = map['paymentMethod'] ?? '';
      
      return PaymentDetailsModel(
        paymentMethod: method,
        // Credit card details
        cardNumber: map['cardNumber'],
        cardHolderName: map['cardHolderName'],
        expiryDate: map['expiryDate'],
        cvv: map['cvv'],
        // Bank transfer details
        bankName: map['bankName'],
        accountNumber: map['accountNumber'],
        accountHolderName: map['accountHolderName'],
        routingNumber: map['routingNumber'],
      );
    } catch (e) {
      debugPrint('❌ Error parsing PaymentDetailsModel: $e');
      return PaymentDetailsModel(
        paymentMethod: map['paymentMethod'] ?? 'Unknown',
      );
    }
  }
} 