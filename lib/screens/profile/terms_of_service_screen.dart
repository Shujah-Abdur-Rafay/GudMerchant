import 'package:flutter/material.dart';
import 'package:gudmerchant/utils/app_constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: May 1, 2025',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Agreement to Terms',
              'By accessing or using our services, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing our services.',
            ),
            _buildSection(
              'Use of Services',
              'You agree to use our services only for lawful purposes and in accordance with these Terms. You agree not to use our services for any illegal or unauthorized purpose.',
            ),
            _buildSection(
              'Account Registration',
              'To use certain features of our services, you may be required to register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete.',
            ),
            _buildSection(
              'Intellectual Property',
              'Our services and their original content, features, and functionality are and will remain the exclusive property of GoodMerchant and its licensors.',
            ),
            _buildSection(
              'User Content',
              'You retain all rights to any content you submit, post, or display on or through our services. By submitting content, you grant us a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, adapt, publish, translate, create derivative works from, distribute, and display such content.',
            ),
            _buildSection(
              'Termination',
              'We may terminate or suspend your account and bar access to our services immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach these Terms.',
            ),
            _buildSection(
              'Limitation of Liability',
              'In no event shall GoodMerchant, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.',
            ),
            _buildSection(
              'Changes to Terms',
              'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days\' notice prior to any new terms taking effect.',
            ),
            _buildSection(
              'Contact Us',
              'If you have any questions about these Terms, please contact us at terms@goodmerchant.com.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
} 