import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proyek_ambw/reusable_widgets/video_widget.dart';
import 'likers_page.dart';
import 'comment_page.dart';

class PostDetailScreen extends StatefulWidget {
  final DocumentSnapshot post;

  PostDetailScreen({required this.post});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Map<String, dynamic> postData;
  late Map<String, bool> likes;
  late int countLikes;
  late bool isLiked;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    postData = widget.post.data() as Map<String, dynamic>;
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    likes = (postData['likes'] ?? {}).cast<String, bool>();
    countLikes = likes.values.where((value) => value).length;
    isLiked = likes[currentUserId] ?? false;
  }

  Future<Map<String, dynamic>> _fetchUserData(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot.data() as Map<String, dynamic>;
  }

  Future<void> _editDescription(BuildContext context) async {
    TextEditingController _descriptionController =
        TextEditingController(text: postData['description']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Caption'),
          content: TextField(
            controller: _descriptionController,
            maxLines: null,
            decoration: InputDecoration(hintText: 'Enter new description'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('post')
                    .doc(widget.post.id)
                    .update({'description': _descriptionController.text});
                setState(() {
                  postData['description'] = _descriptionController.text;
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text(
              'Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed) {
     
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(postData['userId']);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userDocSnapshot = await transaction.get(userDocRef);
        if (userDocSnapshot.exists) {
          int currentCount = userDocSnapshot['countPost'] ?? 0;
          transaction.update(userDocRef, {'countPost': currentCount - 1});
        }
      });

   
      await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.post.id)
          .delete();
      Navigator.pop(context);
    }
  }

  void toggleLike() {
    setState(() {
      if (isLiked) {
        likes.remove(currentUserId);
      } else {
        likes[currentUserId] = true;
      }
      countLikes = likes.values.where((value) => value).length;
      isLiked = !isLiked;
    });

    var postRef =
        FirebaseFirestore.instance.collection('post').doc(widget.post.id);
    postRef.update({
      'likes': likes,
      'countLikes': countLikes,
    });
  }

  @override
  Widget build(BuildContext context) {
    String userId = postData['userId'];
    List<dynamic> imageUrls = postData['imageUrls'] != null
        ? List<dynamic>.from(postData['imageUrls'])
        : [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text('Post Detail', style: TextStyle(color: Colors.black)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('User not found'));
          }

          var userData = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData['profilePicture'] != null &&
                            userData['profilePicture'].isNotEmpty
                        ? NetworkImage(userData['profilePicture'])
                        : null,
                    child: userData['profilePicture'] == null ||
                            userData['profilePicture'].isEmpty
                        ? Icon(Icons.person)
                        : null,
                  ),
                  title: Text(userData['username'] ?? 'Unknown User',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String result) {
                      if (result == 'Edit') {
                        _editDescription(context);
                      } else if (result == 'Delete') {
                        _deletePost(context);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return {'Edit', 'Delete'}.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    },
                  ),
                ),
                if (imageUrls.isNotEmpty)
                  Column(
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 300,
                          enlargeCenterPage: true,
                          viewportFraction: 1.0,
                          aspectRatio: 2.0,
                          enableInfiniteScroll: false,
                          autoPlay: false,
                          disableCenter: true,
                          scrollPhysics: imageUrls.length == 1
                              ? NeverScrollableScrollPhysics()
                              : null,
                        ),
                        items: imageUrls.map((url) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.symmetric(horizontal: 5.0),
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(url),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                      if (imageUrls.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: imageUrls.map((url) {
                            int index = imageUrls.indexOf(url);
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 2.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                if (postData['videoUrl'] != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child:
                        VideoPlayerWidget(url: postData['videoUrl'] as String),
                  ),
                if (imageUrls.isEmpty && postData['videoUrl'] == null)
                  Text('No media available'),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : null),
                        onPressed: toggleLike,
                      ),
                      IconButton(
                        icon: Icon(Icons.comment),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CommentPage(postId: widget.post.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LikersPage(postId: widget.post.id),
                        ),
                      );
                    },
                    child: Text(
                      'Liked by $countLikes fans',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['username'] ?? 'Unknown User',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          postData['description'] ?? 'No description available',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
