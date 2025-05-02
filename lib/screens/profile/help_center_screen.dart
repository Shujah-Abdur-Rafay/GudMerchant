import 'package:flutter/material.dart';
import 'package:gudmerchant/utils/app_constants.dart';
import 'package:get/get.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildFaqItem(
              'How do I place an order?',
              'To place an order, simply browse our products, add items to your cart, and proceed to checkout. You\'ll need to enter your shipping information and payment details to complete the purchase.',
              context,
            ),
            _buildFaqItem(
              'What payment methods do you accept?',
              'We accept credit cards (Visa, Mastercard), debit cards, and Cash on Delivery in select areas.',
              context,
            ),
            _buildFaqItem(
              'How can I track my order?',
              'Once your order has been shipped, you\'ll receive a tracking number via email. You can also check the status of your order in the "My Orders" section of your account.',
              context,
            ),
            _buildFaqItem(
              'What is your return policy?',
              'We accept returns within 30 days of delivery. Items must be in their original condition with all tags and packaging. Please contact customer service to initiate a return.',
              context,
            ),
            _buildFaqItem(
              'How do I change my password?',
              'You can change your password in the Settings section of your account. Go to Settings > Privacy & Security > Change Password.',
              context,
            ),
            const SizedBox(height: 32),
            const Text(
              'Need More Help?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Support'),
              subtitle: const Text('support@goodmerchant.com'),
              onTap: () {
                // Open email app
                Get.snackbar(
                  'Contact Us',
                  'Email support@goodmerchant.com for assistance',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Call Support'),
              subtitle: const Text('+92 300 123 4567'),
              onTap: () {
                // Open phone app
                Get.snackbar(
                  'Contact Us',
                  'Call +92 300 123 4567 for assistance',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 9am-5pm, Monday-Friday'),
              onTap: () {
                // Open chat interface
                Get.snackbar(
                  'Coming Soon',
                  'Live chat support will be available in a future update',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
} 