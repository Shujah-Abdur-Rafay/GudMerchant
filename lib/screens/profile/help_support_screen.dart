import 'package:gudmerchant/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // List of FAQ items
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'How do I track my order?',
      'answer': 'You can track your order by navigating to the "My Orders" section in your profile, selecting the specific order, and clicking on the "Track Order" button.'
    },
    {
      'question': 'How can I cancel my order?',
      'answer': 'To cancel your order, go to "My Orders" in your profile, select the order you wish to cancel, and tap the "Cancel Order" button. Please note that orders can only be cancelled if they have not been shipped yet.'
    },
    {
      'question': 'What is your return policy?',
      'answer': 'We accept returns within 30 days of delivery. Items must be unused and in their original packaging. To initiate a return, go to "My Orders" and select "Return" for the specific item.'
    },
    {
      'question': 'How do I change my shipping address?',
      'answer': 'You can update your shipping address in the "My Addresses" section of your profile. For ongoing orders, please contact customer support as soon as possible.'
    },
    {
      'question': 'When will I receive my refund?',
      'answer': 'Refunds are typically processed within 5-7 business days after we receive the returned item. The time it takes for the refund to appear in your account depends on your payment method and bank.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact Card
          _buildContactCard(),
          
          const SizedBox(height: 24),
          
          // FAQs Section
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // FAQ Items
          ..._buildFaqItems(),
          
          const SizedBox(height: 32),
          
          // Additional Support Options
          const Text(
            'Still Need Help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Email Support Option
          _buildSupportOption(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@gudmerchant.com',
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'support@gudmerchant.com',
                queryParameters: {
                  'subject': 'Support Request from App',
                },
              );
              
              try {
                await launchUrl(emailLaunchUri);
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Could not open email client',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
          
          // Phone Support Option
          _buildSupportOption(
            icon: Icons.phone_outlined,
            title: 'Call Support',
            subtitle: '+1 (800) 123-4567',
            onTap: () async {
              final Uri phoneUri = Uri(
                scheme: 'tel',
                path: '+18001234567',
              );
              
              try {
                await launchUrl(phoneUri);
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Could not make phone call',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.support_agent,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our customer support team is here to help you with any questions or concerns.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Implement contact support functionality
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'support@gudmerchant.com',
                );
                
                launchUrl(emailLaunchUri).catchError((_) {
                  Get.snackbar(
                    'Error',
                    'Could not open email client',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Contact Support'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFaqItems() {
    return _faqItems.map((faqItem) {
      return ExpansionTile(
        title: Text(
          faqItem['question']!,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(faqItem['answer']!),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildSupportOption({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppConstants.primaryColor,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
} 