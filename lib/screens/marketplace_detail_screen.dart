import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketPlaceDetailScreen extends StatelessWidget {
  final DocumentSnapshot item;
  final bool canEditDelete;

  MarketPlaceDetailScreen({required this.item, required this.canEditDelete});

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

  void _deleteItem(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('marketplace')
        .doc(item.id)
        .delete();

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item deleted successfully')),
    );
  }

  void _editItem(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditItemScreen(item: item),
    ));
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = item['images'];
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(item['name']),
        actions: [
          if (canEditDelete && item['userId'] == currentUserId) ...[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editItem(context),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteItem(context),
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              margin: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 300, // Set fixed height for the image
                    child: Stack(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 300,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                          ),
                          items: images.map((imageUrl) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover, // Crop if necessary
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            item['name'], // Item name centered here
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Price: ${item['price']}',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.category, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Category: ${item['category']}',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Location: ${item['location']}',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Description: ${item['description']}',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Seller: ${item['userName']}',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _contactSeller(context),
                icon: Icon(Icons.message),
                label: Text('Contact Seller'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class EditItemScreen extends StatefulWidget {
  final DocumentSnapshot item;

  EditItemScreen({required this.item});

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item['name']);
    _priceController = TextEditingController(text: widget.item['price'].toString());
    _categoryController = TextEditingController(text: widget.item['category']);
    _locationController = TextEditingController(text: widget.item['location']);
    _descriptionController = TextEditingController(text: widget.item['description']);
  }

  void _updateItem() async {
    await FirebaseFirestore.instance.collection('marketplace').doc(widget.item.id).update({
      'name': _nameController.text,
      'price': double.parse(_priceController.text),
      'category': _categoryController.text,
      'location': _locationController.text,
      'description': _descriptionController.text,
    });

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Item'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateItem,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
    );
  }
}
