import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MarketPlaceScreen extends StatefulWidget {
  const MarketPlaceScreen({Key? key}) : super(key: key);

  @override
  _MarketPlaceScreenState createState() => _MarketPlaceScreenState();
}

class _MarketPlaceScreenState extends State<MarketPlaceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  File? _image;
  String? itemName;
  String? itemPrice; // Change to String
  String selectedCategory = 'All'; // Define selectedCategory variable

  void _showSellDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sell Item'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(hintText: 'Item Name'),
                  onChanged: (value) {
                    itemName = value;
                  },
                ),
                TextField(
                  decoration: InputDecoration(hintText: 'Item Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    itemPrice = value; // Change to String
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);
                    setState(() {
                      if (pickedFile != null) {
                        _image = File(pickedFile.path);
                      } else {
                        print('No image selected.');
                      }
                    });
                  },
                  child: Text('Select Image'),
                ),
                if (_image != null) Image.file(_image!),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Post'),
              onPressed: () {
                if (itemName != null && itemPrice != null && _image != null) {
                  _addItem(itemName!, itemPrice!);
                  Navigator.of(context).pop();
                } else {
                  // Show error if fields are incomplete
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Please fill all fields and select an image'),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addItem(String name, String price) async {
    if (_image != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference =
          _storage.ref().child('marketplace/$fileName');
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg', // Adjust based on the actual image type
      );
      UploadTask uploadTask = storageReference.putFile(_image!, metadata);
      TaskSnapshot taskSnapshot = await uploadTask;
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      await _firestore.collection('marketplace').add({
        'name': name,
        'price': price, // Save as String
        'image': imageUrl,
        'category': selectedCategory,
      });

      setState(() {
        _image = null;
      });
    }
  }

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Category'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  title: Text('All'),
                  onTap: () {
                    setState(() {
                      selectedCategory = 'All';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('Electronics'),
                  onTap: () {
                    setState(() {
                      selectedCategory = 'Electronics';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('Automobile'),
                  onTap: () {
                    setState(() {
                      selectedCategory = 'Automobile';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('Gaming'),
                  onTap: () {
                    setState(() {
                      selectedCategory = 'Gaming';
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marketplace'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _showSellDialog,
                icon: Icon(Icons.edit),
                label: Text('Sell'),
              ),
              ElevatedButton.icon(
                onPressed: _showCategoriesDialog,
                icon: Icon(Icons.list),
                label: Text('Categories'),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text('Today\'s picks',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                Icon(Icons.location_on),
                Text('Surabaya, Indonesia'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('marketplace').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var items = snapshot.data!.docs.where((item) {
                  if (selectedCategory == 'All') return true;
                  return item['category'] == selectedCategory;
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 3 / 2,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    return Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: item['image'] != null
                                ? Image.network(
                                    item['image'],
                                    fit: BoxFit.cover,
                                  )
                                : Container(), // Handle missing image
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ??
                                      'N/A', // Handle missing price
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  item['name'] ??
                                      'No Name', // Handle missing name
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
