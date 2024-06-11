import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'base_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(MaterialApp(
    home: ChooseUploadTypeScreen(),
  ));
}

class ChooseUploadTypeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Upload Type"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPostImageScreen()),
                );
              },
              child: Text('Upload Image'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPostVideoScreen()),
                );
              },
              child: Text('Upload Video'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 2),
    );
  }
}

class AddPostImageScreen extends StatefulWidget {
  @override
  _AddPostImageScreenState createState() => _AddPostImageScreenState();
}

class _AddPostImageScreenState extends State<AddPostImageScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Crop your image',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
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

    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String username = userData['username'] ?? 'Anonymous';
      String profilePicture = userData['profilePicture'] ?? 'default.png';

      String fileName =
          'posts/${DateTime.now().millisecondsSinceEpoch.toString()}';
      firebase_storage.UploadTask task = firebase_storage
          .FirebaseStorage.instance
          .ref(fileName)
          .putFile(_image!);

      final snapshot = await task.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('post').add({
        'imageUrl': imageUrl,
        'userProfile': profilePicture,
        'caption': username,
        'description': _captionController.text,
        'timestamp': DateTime.now(),
        'userId': user.uid,
        'videoUrl': null,
      });

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
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
      bottomNavigationBar: BaseScreen(currentIndex: 2),
    );
  }
}

class AddPostVideoScreen extends StatefulWidget {
  @override
  _AddPostVideoScreenState createState() => _AddPostVideoScreenState();
}

class _AddPostVideoScreenState extends State<AddPostVideoScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _videoFile;
  VideoPlayerController? _controller;
  bool _isVideoLoading = false;
  bool _isVideoPlaying = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final pickedFile =
        await ImagePicker().getVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isVideoLoading = true;
      });

      File videoFile = File(pickedFile.path);
      _controller = VideoPlayerController.file(videoFile)
        ..initialize().then((_) {
          setState(() {
            _videoFile = videoFile;
            _isVideoLoading = false;
            _isVideoPlaying = true;
          });
        })
        ..setLooping(true)
        ..addListener(() {
          setState(() {});
        })
        ..play();
    }
  }

  Future uploadVideo(BuildContext context) async {
    if (_videoFile == null || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please provide a video and a caption."),
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
          'videos/${DateTime.now().millisecondsSinceEpoch.toString()}';
      firebase_storage.UploadTask task = firebase_storage
          .FirebaseStorage.instance
          .ref(fileName)
          .putFile(_videoFile!);

      final snapshot = await task.whenComplete(() {});
      final videoUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('post').add({
        'videoUrl': videoUrl,
        'imageUrl': null,
        'userProfile': profilePicture,
        'caption': username,
        'description': _captionController.text,
        'timestamp': DateTime.now(),
        'userId': user.uid,
      });

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
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
            onPressed: () => uploadVideo(context),
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
              child: _videoFile == null
                  ? Text('No video selected.')
                  : AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _pickVideo,
                child: Text('Pick Video'),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 2),
    );
  }
}
