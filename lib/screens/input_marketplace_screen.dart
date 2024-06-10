import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class InputMarketPlaceScreen extends StatefulWidget {
  @override
  _InputMarketPlaceScreenState createState() => _InputMarketPlaceScreenState();
}

class _InputMarketPlaceScreenState extends State<InputMarketPlaceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _category;
  late User currentUser;
  List<XFile>? _imageFileList;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFileList = pickedFiles;
      });
    }
  }

  void initState() {
    super.initState();
    currentUser = _auth.currentUser!;
  }

  Future<void> _uploadData() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _category == null ||
        _imageFileList == null ||
        _imageFileList!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and pick images')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      List<String> imageUrls = [];
      for (XFile file in _imageFileList!) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref =
            FirebaseStorage.instance.ref().child('marketplace').child(fileName);
        await ref.putFile(File(file.path));
        String imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      // Increment countMarketplace
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'countMarketplace': FieldValue.increment(1),
      });

      await FirebaseFirestore.instance.collection('marketplace').add({
        'name': _nameController.text,
        'price': int.parse(_priceController.text),
        'description': _descriptionController.text,
        'location': _locationController.text,
        'category': _category,
        'images': imageUrls,
        'userId': user?.uid,
        'userName': user?.displayName ?? 'Anonymous',
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload data')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Listing'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _uploadData,
            child: Text(
              'Publish',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: _imageFileList == null
                      ? Icon(Icons.add_a_photo)
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4.0,
                            mainAxisSpacing: 4.0,
                          ),
                          itemCount: _imageFileList!.length,
                          itemBuilder: (context, index) {
                            return Image.file(
                              File(_imageFileList![index].path),
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                ),
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _category,
              hint: Text('Category'),
              items: ['Electronics', 'Automobile', 'Gaming']
                  .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _category = value;
                });
              },
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
