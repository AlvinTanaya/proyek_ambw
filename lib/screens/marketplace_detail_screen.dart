import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'edit_detail_marketplace.dart';

class MarketPlaceDetailScreen extends StatelessWidget {
  final DocumentSnapshot item;

  MarketPlaceDetailScreen({required this.item});

  void _deleteItem(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('marketplace')
        .doc(item.id)
        .delete();
    Navigator.pop(context);
  }

  void _editItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDetailMarketPlaceScreen(item: item),
      ),
    );
  }

  void _contactSeller(BuildContext context) async {
    String userId = item['userId'];
    print('User ID from marketplace item: $userId');

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    print('userDoc: $userDoc');
    print('userDoc exists: ${userDoc.exists}');
    print('userDoc data: ${userDoc.data()}');

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String phoneNumber = userData['phoneNumber'];
      print('Phone Number: $phoneNumber');

      // Ensure the phone number is in the correct format
      if (!phoneNumber.startsWith('62')) {
        phoneNumber = '62' +
            phoneNumber
                .substring(1); // Remove leading zero and add country code
      }
      print('Formatted Phone Number: $phoneNumber');

      String message =
          'Hello, I am interested in your listing: ${item['name']}';
      print('Message: $message');

      String whatsappUrl =
          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
      print('WhatsApp URL: $whatsappUrl');

      try {
        await launch(whatsappUrl);
      } catch (e) {
        print('Error launching WhatsApp: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seller information not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = item['images'];

    return Scaffold(
      appBar: AppBar(
        title: Text(item['name']),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editItem(context),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteItem(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 400,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
              ),
              items: images.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    );
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            Text(
              item['name'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Price: ${item['price']}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Category: ${item['category']}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Location: ${item['location']}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Description: ${item['description']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Seller: ${item['userName']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _contactSeller(context),
              icon: Icon(Icons.message),
              label: Text('Contact Seller'),
            ),
          ],
        ),
      ),
    );
  }
}
