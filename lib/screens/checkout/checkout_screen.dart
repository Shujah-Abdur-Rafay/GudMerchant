import 'package:gudmerchant/controllers/auth_controller.dart';
import 'package:gudmerchant/controllers/order_controller.dart';
import 'package:gudmerchant/models/cart_item_model.dart';
import 'package:gudmerchant/models/usermodel.dart';
import 'package:gudmerchant/screens/order/order_success_screen.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gudmerchant/models/payment_details_model.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderController _orderController = Get.find<OrderController>();
  final AuthController _authController = Get.find<AuthController>();
  
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isAddressValid = false;
  
  // Payment form controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _routingNumberController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }
  
  void _initializeUserData() {
    UserModel? user = _authController.userModel;
    if (user != null) {
      _addressController.text = user.userAdress;
      // The other fields could be populated if they were available in the user model
    }
  }
  
  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _routingNumberController.dispose();
    super.dispose();
  }
  
  void _placeOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid address')),
      );
      return;
    }
    
    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city')),
      );
      return;
    }
    
    // Validate zip code
    final zipCodeError = _validateZipCode(_zipController.text);
    if (zipCodeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zip code error: $zipCodeError')),
      );
      return;
    }

    // Create payment details based on selected method
    PaymentDetailsModel? paymentDetails;
    
    if (_selectedPaymentMethod == 'Credit Card') {
      // Validate credit card details
      if (_cardNumberController.text.isEmpty || 
          _cardHolderController.text.isEmpty || 
          _expiryDateController.text.isEmpty || 
          _cvvController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all credit card details')),
        );
        return;
      }
      
      paymentDetails = PaymentDetailsModel(
        paymentMethod: 'Credit Card',
        cardNumber: _cardNumberController.text,
        cardHolderName: _cardHolderController.text,
        expiryDate: _expiryDateController.text,
        cvv: _cvvController.text,
      );
      
      debugPrint('💳 Credit Card details prepared');
    } else if (_selectedPaymentMethod == 'Bank Transfer') {
      // Validate bank transfer details
      if (_bankNameController.text.isEmpty || 
          _accountNumberController.text.isEmpty || 
          _accountHolderController.text.isEmpty || 
          _routingNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all bank details')),
        );
        return;
      }
      
      paymentDetails = PaymentDetailsModel(
        paymentMethod: 'Bank Transfer',
        bankName: _bankNameController.text,
        accountNumber: _accountNumberController.text,
        accountHolderName: _accountHolderController.text,
        routingNumber: _routingNumberController.text,
      );
      
      debugPrint('🏦 Bank Transfer details prepared');
    } else {
      debugPrint('💵 Cash on Delivery selected');
    }

    debugPrint('🔄 Attempting to place order with payment method: $_selectedPaymentMethod');
    
    // Use the existing controller instead of creating a new one
    final success = await _orderController.placeOrder(
      items: widget.cartItems,
      totalAmount: widget.totalAmount,
      shippingAddress: _buildFullAddress(),
      paymentMethod: _selectedPaymentMethod,
      paymentDetails: paymentDetails,
    );

    if (!mounted) return;
    
    debugPrint('📋 Order placement result: $success');
    
    if (success) {
      debugPrint('✅ Order successful, navigating to success screen');
      // Use Navigator.pushReplacement with MaterialPageRoute for better compatibility
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
      );
    } else {
      debugPrint('❌ Order failed');
    }
  }
  
  String _buildFullAddress() {
    List<String> addressParts = [
      _addressController.text,
      _cityController.text,
      _stateController.text,
      _zipController.text,
    ].where((part) => part.isNotEmpty).toList();
    
    return addressParts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${widget.cartItems.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          AppConstants.formatAsCurrency(widget.totalAmount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shipping:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const Text(
                          'Free',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppConstants.formatAsCurrency(widget.totalAmount),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Shipping Address
            const Text(
              'Shipping Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pakistani City Selector
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      value: _cityController.text.isEmpty ? null : _cityController.text,
                      hint: const Text('Select your city'),
                      items: AppConstants.pakistaniCities.map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _cityController.text = value!;
                        });
                      },
                    ),
                    // Show text field for "Other" city
                    if (_cityController.text == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Specify City',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            // We don't update _cityController here to keep "Other" selected in dropdown
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'Province',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _zipController,
                            decoration: InputDecoration(
                              labelText: 'ZIP Code',
                              border: const OutlineInputBorder(),
                              errorText: _validateZipCode(_zipController.text),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              // Force rebuild to show validation error
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Payment Method
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // List all payment methods defined in AppConstants
                    ...AppConstants.paymentMethods.map((method) => 
                      RadioListTile<String>(
                        title: Text(method),
                        value: method,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                    ).toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: const Text(
                'Place Order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Credit Card form
  Widget _buildCreditCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: 'XXXX XXXX XXXX XXXX',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cardHolderController,
            decoration: const InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'John Doe',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryDateController,
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectExpiryDate(context),
                    ),
                  ),
                  readOnly: true, // Make the input read-only
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: 'XXX',
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Method to show date picker for expiry date
  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = now.add(const Duration(days: 365)); // Default to 1 year from now
    
    final List<String> months = List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
    final List<String> years = List.generate(10, (index) => (now.year + index).toString().substring(2));
    
    // Show bottom sheet with month and year pickers
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        String selectedMonth = months[0];
        String selectedYear = years[0];
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Select Expiry Date',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Month'),
                            const SizedBox(height: 10),
                            DropdownButton<String>(
                              value: selectedMonth,
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedMonth = newValue!;
                                });
                              },
                              items: months.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Year'),
                            const SizedBox(height: 10),
                            DropdownButton<String>(
                              value: selectedYear,
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedYear = newValue!;
                                });
                              },
                              items: years.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text('20$value'),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      _expiryDateController.text = '$selectedMonth/$selectedYear';
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
  
  // Bank Transfer form
  Widget _buildBankTransferForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _bankNameController,
            decoration: const InputDecoration(
              labelText: 'Bank Name',
              hintText: 'Enter bank name',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _accountNumberController,
            decoration: const InputDecoration(
              labelText: 'Account Number',
              hintText: 'Enter account number',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _accountHolderController,
            decoration: const InputDecoration(
              labelText: 'Account Holder Name',
              hintText: 'John Doe',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _routingNumberController,
            decoration: const InputDecoration(
              labelText: 'Routing Number',
              hintText: 'Enter routing number',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  String? _validateZipCode(String value) {
    if (value.isEmpty) {
      return 'Required';
    }
    
    if (value.length != 5) {
      return 'Must be exactly 5 digits';
    }
    
    if (!RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Numbers only';
    }
    
    return null;
  }
} 