import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'base_screen.dart';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
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
            _isVideoPlaying = true; // Autoplay the video
          });
        })
        ..setLooping(true) // Set the video to loop
        ..addListener(() {
          setState(() {});
        })
        ..play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Post'),
        centerTitle: true,
      ),
      body: Center(
        child: _videoFile != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    _controller!.value.isInitialized &&
                            !_controller!.value.isPlaying
                        ? IconButton(
                            icon: Icon(Icons.play_arrow),
                            onPressed: () {
                              setState(() {
                                _isVideoPlaying = true;
                                _controller!.play();
                              });
                            },
                          )
                        : Container(),
                  ],
                ),
              )
            : _isVideoLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _pickVideo,
                    child: Text('Pick a video'),
                  ),
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 2),
    );
  }
}
