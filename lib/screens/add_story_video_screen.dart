import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'base_screen.dart';

class AddStoryVideoScreen extends StatefulWidget {
  @override
  _AddStoryVideoScreenState createState() => _AddStoryVideoScreenState();
}

class _AddStoryVideoScreenState extends State<AddStoryVideoScreen> {
  File? _videoFile;
  VideoPlayerController? _controller;
  bool _isVideoLoading = false;

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
          });
          _controller!.play();
        })
        ..setLooping(true)
        ..addListener(() {
          setState(() {});
        });
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
        'imageUrl': null,
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => BaseScreen(currentIndex: 0),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to upload stroy: $e"),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _videoFile == null
                        ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                        : _controller != null &&
                                _controller!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              )
                            : CircularProgressIndicator(),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
