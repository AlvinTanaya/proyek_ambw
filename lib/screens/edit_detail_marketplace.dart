import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditDetailMarketPlaceScreen extends StatefulWidget {
  final DocumentSnapshot item;

  EditDetailMarketPlaceScreen({required this.item});

  @override
  _EditDetailMarketPlaceScreenState createState() =>
      _EditDetailMarketPlaceScreenState();
}

class _EditDetailMarketPlaceScreenState
    extends State<EditDetailMarketPlaceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _category;
  List<XFile>? _imageFileList;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.item['name'];
    _priceController.text = widget.item['price'].toString();
    _descriptionController.text = widget.item['description'];
    _locationController.text = widget.item['location'];
    _category = widget.item['category'];
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFileList = pickedFiles;
      });
    }
  }

  Future<void> _updateData() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> imageUrls = widget.item['images'].cast<String>();
      if (_imageFileList != null && _imageFileList!.isNotEmpty) {
        for (XFile file in _imageFileList!) {
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          Reference ref = FirebaseStorage.instance
              .ref()
              .child('marketplace')
              .child(fileName);
          await ref.putFile(File(file.path));
          String imageUrl = await ref.getDownloadURL();
          imageUrls.add(imageUrl);
        }
      }

      await FirebaseFirestore.instance
          .collection('marketplace')
          .doc(widget.item.id)
          .update({
        'name': _nameController.text,
        'price': int.parse(_priceController.text),
        'description': _descriptionController.text,
        'location': _locationController.text,
        'category': _category,
        'images': imageUrls,
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update data')),
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
        title: Text('Edit Listing'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateData,
            child: Text(
              'Save',
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
                      ? GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4.0,
                            mainAxisSpacing: 4.0,
                          ),
                          itemCount: widget.item['images'].length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              widget.item['images'][index],
                              fit: BoxFit.cover,
                            );
                          },
                        )
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
