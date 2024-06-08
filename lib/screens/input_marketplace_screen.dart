import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'marketplace_screen.dart';

class InputMarketPlaceScreen extends StatefulWidget {
  @override
  _InputMarketPlaceScreenState createState() => _InputMarketPlaceScreenState();
}

class _InputMarketPlaceScreenState extends State<InputMarketPlaceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<XFile>? _images;
  String? itemName;
  int? itemPrice;
  String? itemCategory;
  String? itemCondition;
  String? itemDescription;
  String? itemLocation;

  void _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles;
      });
    } else {
      print('No images selected.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select images.'),
        ),
      );
    }
  }

  Future<void> _addItem() async {
    if (_images == null || _images!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select images before publishing.'),
        ),
      );
      return;
    }

    if (itemName == null || itemPrice == null || itemCategory == null || itemCondition == null || itemLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all the required fields.'),
        ),
      );
      return;
    }

    List<String> imageUrls = [];

    for (var image in _images!) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = _storage.ref().child('marketplace/$fileName');
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg', // Adjust based on the actual image type
      );
      UploadTask uploadTask = storageReference.putFile(File(image.path), metadata);
      TaskSnapshot taskSnapshot = await uploadTask;
      String imageUrl = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(imageUrl);
    }

    await _firestore.collection('marketplace').add({
      'name': itemName,
      'price': itemPrice,
      'images': imageUrls,
      'category': itemCategory,
      'condition': itemCondition,
      'description': itemDescription,
      'location': itemLocation,
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MarketPlaceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Listing'),
        actions: [
          TextButton(
            onPressed: _addItem,
            child: Text(
              'Publish',
              style: TextStyle(color: Colors.black), // Change text color to black
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: _images == null || _images!.isEmpty
                      ? Text('Add Photos')
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images!.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.file(
                                File(_images![index].path),
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Title'),
              onChanged: (value) {
                itemName = value;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                itemPrice = int.tryParse(value);
              },
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Category'),
              items: ['Electronics', 'Automobile', 'Gaming']
                  .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                itemCategory = value;
              },
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Condition'),
              items: ['New', 'Used']
                  .map((condition) => DropdownMenuItem<String>(
                        value: condition,
                        child: Text(condition),
                      ))
                  .toList(),
              onChanged: (value) {
                itemCondition = value;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Description'),
              onChanged: (value) {
                itemDescription = value;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Location'),
              onChanged: (value) {
                itemLocation = value;
              },
            ),
          ],
        ),
      ),
    );
  }
}
