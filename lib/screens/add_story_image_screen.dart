import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart';

class AddStoryImageScreen extends StatefulWidget {
  @override
  _AddStoryImageScreenState createState() => _AddStoryImageScreenState();
}

class _AddStoryImageScreenState extends State<AddStoryImageScreen> {
  File? _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 9, ratioY: 16),
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Crop your image',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 9 / 16.0,
          aspectRatioLockEnabled: true,
        ),
      );

      setState(() {
        _image = croppedFile;
      });
    } else {
      print('No image picked.');
    }
  }

  Future uploadStory(BuildContext context) async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please provide an image."),
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

    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String username = userData['username'] ?? 'Anonymous';
      String profilePicture = userData['profilePicture'] ?? 'default.png';

      String fileName =
          'story/${DateTime.now().millisecondsSinceEpoch.toString()}';
      firebase_storage.UploadTask task = firebase_storage
          .FirebaseStorage.instance
          .ref(fileName)
          .putFile(_image!);

      final snapshot = await task.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('story').add({
        'imageUrl': imageUrl,
        'userProfile': profilePicture,
        'caption': username,
        'timestamp': DateTime.now(),
        'userId': user.uid,
      });

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to upload story: $e"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add a Story"),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => uploadStory(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 10),
            Center(
              child: _image == null
                  ? Text('No image selected.')
                  : Image.file(_image!, height: 300),
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
    );
  }
}
