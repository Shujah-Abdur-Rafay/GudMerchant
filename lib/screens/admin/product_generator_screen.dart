import 'package:flutter/material.dart';
import 'package:gudmerchant/utils/product_generator.dart';
import 'package:get/get.dart';

class ProductGeneratorScreen extends StatefulWidget {
  const ProductGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<ProductGeneratorScreen> createState() => _ProductGeneratorScreenState();
}

class _ProductGeneratorScreenState extends State<ProductGeneratorScreen> {
  final ProductGenerator _productGenerator = ProductGenerator();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Products'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_basket,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Product Generator',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This utility will generate and add 5-10 unique products for each category in your database.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Product Generation Features:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildFeatureItem('Category-specific product generation'),
              _buildFeatureItem('Unique names, prices, and images'),
              _buildFeatureItem('Detailed product descriptions'),
              _buildFeatureItem('Realistic pricing based on category'),
              _buildFeatureItem('Proper categorization in your store'),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () async {
                        setState(() {
                          _isGenerating = true;
                        });
                        
                        try {
                          await _productGenerator.generateAndAddUniqueProducts();
                        } finally {
                          setState(() {
                            _isGenerating = false;
                          });
                        }
                      },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(_isGenerating ? 'Generating...' : 'Generate Products'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              if (_isGenerating)
                Column(
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text(
                      'Adding products to your store...',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
} 