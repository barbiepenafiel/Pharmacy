import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I place an order?',
        'answer':
            'Browse products, add items to cart, enter delivery address, and choose payment method to place an order.',
      },
      {
        'question': 'Can I cancel my order?',
        'answer':
            'Yes, you can cancel orders within 1 hour of placing them through the My Orders section.',
      },
      {
        'question': 'What payment methods do you accept?',
        'answer':
            'We accept Credit Cards, Debit Cards, Digital Wallets, and Cash on Delivery.',
      },
      {
        'question': 'How long does delivery take?',
        'answer':
            'Standard delivery takes 2-3 business days. Express delivery is available for 24 hours.',
      },
      {
        'question': 'Do you provide refunds?',
        'answer':
            'Yes, we offer full refunds for damaged or incorrect items within 7 days of delivery.',
      },
      {
        'question': 'Can I upload prescriptions?',
        'answer':
            'Yes, you can upload prescriptions in the Prescriptions section to order prescription medicines.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Support Options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get in Touch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactOption(
                    context,
                    icon: Icons.phone,
                    title: 'Call Us',
                    subtitle: '+1 (555) 123-4567',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening phone dialer...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildContactOption(
                    context,
                    icon: Icons.email,
                    title: 'Email Us',
                    subtitle: 'support@pharmacyapp.com',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening email client...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildContactOption(
                    context,
                    icon: Icons.chat,
                    title: 'Live Chat',
                    subtitle: 'Chat with our support team',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening live chat...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    faqs.length,
                    (index) => _buildFAQItem(
                      question: faqs[index]['question']!,
                      answer: faqs[index]['answer']!,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.teal.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        collapsedBackgroundColor: Colors.grey.shade50,
        backgroundColor: Colors.grey.shade50,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: TextStyle(color: Colors.grey.shade700, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
