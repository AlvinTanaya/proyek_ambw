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

class ChooseUploadTypeScreen extends StatefulWidget {
  @override
  _ChooseUploadTypeScreenState createState() => _ChooseUploadTypeScreenState();
}

class _ChooseUploadTypeScreenState extends State<ChooseUploadTypeScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/images/video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Upload Type"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddPostImageScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/ok.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.8), BlendMode.dstATop),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Upload Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddPostVideoScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _videoController.value.isInitialized
                              ? VideoPlayer(_videoController)
                              : Center(child: CircularProgressIndicator()),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 133, 133, 133)
                                .withOpacity(
                                    0.3), // Adjusted opacity to match the image overlay
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Upload Video',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
  List<File> _images = [];
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      List<File> croppedFiles = [];
      for (var pickedFile in pickedFiles) {
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
        if (croppedFile != null) {
          croppedFiles.add(croppedFile);
        }
      }
      setState(() {
        _images = croppedFiles;
      });
    } else {
      print('No image picked.');
    }
  }

  Future uploadPost(BuildContext context) async {
    if (_images.isEmpty || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please provide images and a caption."),
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

      List<String> imageUrls = [];
      for (var image in _images) {
        String fileName =
            'posts/${DateTime.now().millisecondsSinceEpoch.toString()}_${_images.indexOf(image)}';
        firebase_storage.UploadTask task = firebase_storage
            .FirebaseStorage.instance
            .ref(fileName)
            .putFile(image);

        final snapshot = await task.whenComplete(() {});
        final imageUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      await FirebaseFirestore.instance.collection('post').add({
        'imageUrls': imageUrls,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GestureDetector(
                onTap: getImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _images.isEmpty
                        ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: _images
                                .map((image) => Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.file(image, fit: BoxFit.cover, height: 200),
                                    ))
                                .toList(),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  labelText: 'Caption',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
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
              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  labelText: 'Caption',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
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
