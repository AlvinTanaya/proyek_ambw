import 'package:flutter/material.dart';
import 'base_screen.dart';

class PrivacyAndPolicyScreen extends StatelessWidget {
  const PrivacyAndPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy and Policy'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Effective Date: 22 June 2024',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text(
              'Introduction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Welcome to Fans Favorite. We value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and share information when you use our mobile application ("App").',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Information We Collect',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '1. Personal Information: When you create an account or interact with our App, we may collect personal information such as your name, email address, profile picture, and other details you provide.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '2. Usage Information: We collect information about your interactions with the App, including the content you view, the features you use, and the time and duration of your activities.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '3. Device Information: We may collect information about the device you use to access our App, including the hardware model, operating system, unique device identifiers, and mobile network information.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '4. Location Information: With your consent, we may collect information about your location when you use our App.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'How We Use Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We use the information we collect for various purposes, including:',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- To provide, maintain, and improve our App and services',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- To personalize your experience and provide tailored content',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- To communicate with you, respond to your inquiries, and provide customer support',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- To analyze usage trends and improve our App\'s functionality',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- To comply with legal obligations and protect our rights and interests',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Sharing Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We may share your information with third parties in the following circumstances:',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- With your consent or at your direction',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- With service providers who help us operate our App and provide services to you',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- In response to legal requests or to comply with legal obligations',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- To protect the rights, property, or safety of our users, the public, or our App',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Your Choices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'You can manage your account settings and personal information through the App. You may also choose to disable certain features, such as location services, through your device settings.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We take reasonable measures to protect your information from unauthorized access, loss, misuse, or alteration. However, no data transmission over the internet or electronic storage system is completely secure, and we cannot guarantee absolute security.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Changes to This Privacy Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy within the App. Your continued use of the App after any changes indicates your acceptance of the updated Privacy Policy.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'If you have any questions or concerns about this Privacy Policy, please contact us at help@fans.favorite.com',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
