import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proyek_ambw/reusable_widgets/video_widget.dart';
import 'addStory_screen.dart';
import 'base_screen.dart';
import 'other_user_profile_screen.dart'; // Import the OtherUserProfileScreen
import 'story_screen.dart';
import 'comment_page.dart';
import 'likers_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Feed'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.camera_alt, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChooseStoryUploadTypeScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 90,
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text('No linked users found'));
                }

                List<dynamic> linkedUserIds = snapshot.data!['linked'] ?? [];
                linkedUserIds.add(
                    currentUserId); // Add the current user's ID to show their own stories

                if (linkedUserIds.isEmpty) {
                  return Center(child: Text('No linked users found'));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('story')
                      .where('userId', whereIn: linkedUserIds)
                      .snapshots(),
                  builder: (context, storySnapshot) {
                    if (storySnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${storySnapshot.error}'));
                    }

                    if (storySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!storySnapshot.hasData ||
                        storySnapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No stories found'));
                    }

                    var stories = _groupStoriesByUser(storySnapshot.data!.docs);

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: stories.keys.map((userId) {
                        return _buildStoryThumbnail(
                            userId, stories[userId]!, context, stories);
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('post').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No posts found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot post = snapshot.data!.docs[index];
                    return _buildPostCard(post, context, currentUserId);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 0),
    );
  }

  Map<String, List<DocumentSnapshot>> _groupStoriesByUser(
      List<DocumentSnapshot> docs) {
    Map<String, List<DocumentSnapshot>> groupedStories = {};

    for (var doc in docs) {
      String userId = doc['userId'] as String;
      if (groupedStories.containsKey(userId)) {
        groupedStories[userId]!.add(doc);
      } else {
        groupedStories[userId] = [doc];
      }
    }

    return groupedStories;
  }

  Widget _buildStoryThumbnail(String userId, List<DocumentSnapshot> stories,
      BuildContext context, Map<String, List<DocumentSnapshot>> allStories) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return Container();
        }

        var userDoc = snapshot.data!;
        String username = userDoc['username'] ?? 'Unknown';
        String profilePicture = userDoc['profilePicture'] ?? '';

        return Column(
          children: [
            InkWell(
              onTap: () => _showFullStory(
                  context, stories, username, profilePicture, allStories),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black54),
                  image: DecorationImage(
                    image: NetworkImage(profilePicture),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              username,
              style: TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  void _showFullStory(
      BuildContext context,
      List<DocumentSnapshot> stories,
      String username,
      String profilePicture,
      Map<String, List<DocumentSnapshot>> allStories) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StoryScreen(
          stories: stories,
          username: username,
          profilePicture: profilePicture,
          allUsersStories: allStories),
    ));
  }

  void _navigateToUserProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(userId: userId),
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot post, BuildContext context, String currentUserId) {
    String userId = post['userId'] as String;
    Map<String, bool> likes = (post.data() as Map)['likes']?.cast<String, bool>() ?? {};
    int countLikes = likes.values.where((value) => value).length;
    bool isLiked = likes[FirebaseAuth.instance.currentUser!.uid] ?? false;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(post['userId']).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(),
              title: Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }

        var userDoc = snapshot.data!;
        String profilePicture = userDoc['profilePicture'] as String;
        String username = userDoc['username'] as String;

        return Card(
          margin: EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(profilePicture),
                ),
                title: GestureDetector(
                  onTap: () => _navigateToUserProfile(context, userId),
                  child: Text(username,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (post['imageUrl'] != null)
                Image.network(post['imageUrl'] as String, fit: BoxFit.cover)
              else if (post['videoUrl'] != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VideoPlayerWidget(url: post['videoUrl'] as String),
                )
              else
                Text('No media available'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                          icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null),
                          onPressed: () => toggleLike(post, currentUserId),
                      ),
                      IconButton(
                        icon: Icon(Icons.comment),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommentPage(postId: post.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  IconButton(
                      icon: Icon(Icons.bookmark_border), onPressed: () {}),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LikersPage(postId: post.id),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.topLeft,
                  child: Text('Liked by $countLikes fans',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.topLeft,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                          text: username,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: " " +
                              (post['description'] as String? ??
                                  'No Description'),
                          style: TextStyle(fontWeight: FontWeight.normal)),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                alignment: Alignment.topLeft,
              ),
            ],
          ),
        );
      },
    );
  }
}

void toggleLike(DocumentSnapshot post, String userId) async {
  var postRef = FirebaseFirestore.instance.collection('post').doc(post.id);
  
  var snapshot = await postRef.get();
  var data = snapshot.data() as Map;
  var likes = Map<String, bool>.from(data['likes'] ?? {});

  if (likes.containsKey(userId)) {
    likes.remove(userId);
  } else {
    likes[userId] = true;
  }
  int countLikes = likes.values.where((value) => value).length;
  await postRef.update({
    'likes': likes,
    'countLikes': countLikes,
  });
}