import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'base_screen.dart';
import 'other_user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoryScreen extends StatefulWidget {
  final List<DocumentSnapshot> stories;
  final String username;
  final String profilePicture;
  final Map<String, List<DocumentSnapshot>> allUsersStories;

  StoryScreen({
    required this.stories,
    required this.username,
    required this.profilePicture,
    required this.allUsersStories,
  });

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isNextUser = false;
  VideoPlayerController? _videoController;
  late Duration _storyDuration;
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.stories.isNotEmpty) {
      _initializeStory(widget.stories[_currentIndex]);
    }
  }

  void _startAutoPlay() {
    Future.delayed(_storyDuration, () {
      if (_pageController.hasClients && mounted) {
        _pageController.nextPage(
            duration: Duration(milliseconds: 300), curve: Curves.easeIn);
      }
    });
  }

  void _onPageChanged(int index) {
    if (index >= widget.stories.length) {
      _showNextUserStories();
    } else {
      setState(() {
        _currentIndex = index;
        _isNextUser = false;
      });
      _disposeVideoController();
      _initializeStory(widget.stories[index]);
    }
  }

  void _showNextUserStories() {
    var userIds = widget.allUsersStories.keys.toList();
    var currentIndex = userIds.indexOf(widget.stories[0]['userId']);
    var nextIndex = currentIndex + 1;

    if (nextIndex < userIds.length) {
      var nextUserId = userIds[nextIndex];
      var nextUserStories = widget.allUsersStories[nextUserId];
      var nextUserDoc = nextUserStories![0];

      FirebaseFirestore.instance
          .collection('users')
          .doc(nextUserId)
          .get()
          .then((userDoc) {
        var nextUsername = userDoc['username'] ?? 'Unknown';
        var nextProfilePicture = userDoc['profilePicture'] ?? '';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoryScreen(
              stories: nextUserStories,
              username: nextUsername,
              profilePicture: nextProfilePicture,
              allUsersStories: widget.allUsersStories,
            ),
          ),
        );
      });
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => BaseScreen(currentIndex: 0),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _initializeStory(DocumentSnapshot story) {
    var videoUrl = story['videoUrl'];
    if (videoUrl != null) {
      _videoController = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {
            _storyDuration = _videoController!.value.duration;
          });
          _videoController!.play();
          _startAutoPlay();
        });
    } else {
      setState(() {
        _storyDuration = Duration(seconds: 5);
      });
      _startAutoPlay();
    }
  }

  void _disposeVideoController() {
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  void _handleTap() {
    if (_isNextUser) {
      Navigator.of(context).pop();
    } else {
      var nextIndex = _currentIndex + 1;
      if (nextIndex < widget.stories.length) {
        var nextStory = widget.stories[nextIndex];
        var videoUrl = nextStory['videoUrl'];
        if (videoUrl != null) {
          setState(() {
            _storyDuration = Duration.zero;
          });
        }
      }
      _pageController.nextPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  void _navigateToUserProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          userId: widget.stories[0]['userId'],
        ),
      ),
    );
  }

  void _deleteStory(DocumentSnapshot story) async {
    if (story.exists) {
      try {
        await FirebaseFirestore.instance.collection('story').doc(story.id).delete();
        print("Story deleted successfully.");

        if (mounted) {
          setState(() {
            widget.stories.remove(story);
            if (_currentIndex >= widget.stories.length) {
              _currentIndex = widget.stories.length - 1; // Adjust current index if necessary
            }
            if (widget.stories.isEmpty) {
              Navigator.pop(context); // If no stories left, exit the screen
            } else {
              _initializeStory(widget.stories[_currentIndex]); // Initialize the next story
            }
          });
        }
      } catch (e) {
        print("Error deleting story: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete story: $e"))
        );
      }
    } else {
      print("Story document does not exist.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (details) => _handleTap(),
        child: Stack(
          children: [
            if (widget.stories.isNotEmpty)
              PageView.builder(
                controller: _pageController,
                itemCount: widget.stories.length + 1,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  if (index < widget.stories.length) {
                    var story = widget.stories[index];
                    var imageUrl = story['imageUrl'];
                    var videoUrl = story['videoUrl'];
                    if (imageUrl != null) {
                      return Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      );
                    } else if (videoUrl != null) {
                      return _videoController != null &&
                              _videoController!.value.isInitialized
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            )
                          : Center(child: CircularProgressIndicator());
                    }
                  } else {
                    return Container(color: Colors.black);
                  }
                  return Container();
                },
              )
            else
              Center(
                child: Text(
                  'No stories available',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / (widget.stories.length > 0 ? widget.stories.length : 1),
                    backgroundColor: Colors.black26,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(widget.profilePicture),
                            radius: 15,
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _navigateToUserProfile(context),
                            child: Text(
                              widget.username,
                              style: TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                      if (widget.stories.isNotEmpty &&
                          widget.stories[_currentIndex]['userId'] == currentUserId)
                      PopupMenuButton<String>(
                        onSelected: (String choice) {
                          if (choice == 'Delete') {
                            _deleteStory(widget.stories[_currentIndex]);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return {'Delete'}.map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
