import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'home_screen.dart';

class AddStoryVideoScreen extends StatefulWidget {
  @override
  _AddStoryVideoScreenState createState() => _AddStoryVideoScreenState();
}

class _AddStoryVideoScreenState extends State<AddStoryVideoScreen> {
  File? _videoFile;
  VideoPlayerController? _controller;
  final picker = ImagePicker();
  bool _isVideoLoading = false;

  Future getVideo() async {
    final pickedFile = await picker.getVideo(source: ImageSource.gallery);

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
          });
          _controller!.play();
        });
    } else {
      print('No video picked.');
    }
  }

  Future uploadStory(BuildContext context) async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please provide a video."),
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
          .putFile(_videoFile!);

      final snapshot = await task.whenComplete(() {});
      final videoUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('story').add({
        'videoUrl': videoUrl,
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
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
              child: _videoFile == null
                  ? Text('No video selected.')
                  : _controller!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : CircularProgressIndicator(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: getVideo,
                child: Text('Pick Video'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
