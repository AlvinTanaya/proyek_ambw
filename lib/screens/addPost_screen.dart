import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'base_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadPost(BuildContext context) async {
    if (_image == null || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please provide an image and a caption."),
      ));
      return;
    }


  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("No user logged in."),
    ));
    return;
  }

  DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  String username = userData.exists ? userData.get('username') : 'Anonymous';

    try {
      // Upload image to Firebase Storage
      String fileName = 'posts/${DateTime.now().millisecondsSinceEpoch.toString()}';
      firebase_storage.UploadTask task = firebase_storage.FirebaseStorage.instance
          .ref(fileName)
          .putFile(_image!);

      final snapshot = await task.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Add post details to Firestore
      await FirebaseFirestore.instance.collection('post').add({
        'imageUrl': imageUrl,
        'caption': username,
        'description': _captionController.text,
        'timestamp': DateTime.now(), // Optional: for ordering posts by time
        'userId': user.uid, 
      });

      Navigator.pop(context); // Assuming success, pop back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to upload post: $e"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add a Post"),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => uploadPost(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  labelText: 'Caption',
                ),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: _image == null ? Text('No image selected.') : Image.file(_image!, height: 300),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: getImage,
                child: Text('Pick Image'),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 2), // Highlight the 'Add Post' tab
    );
  }
}
