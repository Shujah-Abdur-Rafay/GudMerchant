import 'package:flutter/material.dart';

class AppConstants {
  static Color primaryColor = const Color(0xFF5956E9); // Original purple color
  static Color secondaryColor = const Color(0xFFFA4A0C); // Original orange/red color
  static Color accentColor = const Color(0xFF2196F3); // Original info color from app_theme
  static Color backgroundColor = const Color(0xFFF5F5F8); // Original background color
  
  static const String appName = 'GudMerchant';
  static const String appVersion = '1.0.0';
  
  // Currency related
  static const String currencySymbol = 'PKR';
  static const String currencyName = 'Pakistani Rupee';
  
  // Format a number as PKR currency
  static String formatAsCurrency(double amount) {
    return '$currencySymbol ${amount.toStringAsFixed(2)}';
  }
  
  static const double defaultPadding = 16.0;
  static const double borderRadius = 12.0;
  
  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  
  // Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  
  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 22.0;
  
  // API endpoints
  static const String baseUrl = 'https://api.gudmerchant.pk';
  static const String apiVersion = 'v1';
  static const String apiKey = 'your-api-key';
  
  // Contact & Support
  static const String supportEmail = 'support@gudmerchant.pk';
  static const String contactPhone = '+92-300-1234567';
  
  // Pakistan-specific
  static const String companyAddress = 'Office #123, XYZ Plaza, Clifton, Karachi, Pakistan';
  static const String ntnNumber = '1234567-8';
  static const String gstNumber = 'PK-12345-67';
  
  // Pakistan Payment Methods
  static const List<String> paymentMethods = [
    'Cash on Delivery',
    'EasyPaisa',
    'JazzCash',
    'Bank Transfer',
    'Credit/Debit Card'
  ];
  
  // List of major Pakistani cities for dropdown selection
  static const List<String> pakistaniCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Hyderabad',
    'Gujranwala',
    'Abbottabad',
    'Bahawalpur',
    'Sargodha',
    'Sukkur',
    'Larkana',
    'Sheikhupura',
    'Mirpur Khas',
    'Jhang',
    'Rahim Yar Khan',
    'Gujrat',
    'Mardan',
    'Kasur',
    'Okara',
    'Mingora',
    'Nawabshah',
    'Sahiwal',
    'Wah Cantonment',
    'Dera Ghazi Khan',
    'Other'
  ];
} 