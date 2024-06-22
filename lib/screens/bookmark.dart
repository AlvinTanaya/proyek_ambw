import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'post_detail_screen.dart';

class BookmarkScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('bookmarks').doc(currentUserId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No bookmarks found'));
          }

          List<Map<String, dynamic>> bookmarks = List<Map<String, dynamic>>.from(snapshot.data!['bookmarks'] ?? []);
          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              String postId = bookmarks[index]['postId'];
              String ownerId = bookmarks[index]['ownerId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('post').doc(postId).get(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text('Loading post...'));
                  }
                  if (postSnapshot.hasError) {
                    return ListTile(title: Text('Error: ${postSnapshot.error}'));
                  }
                  if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                    return ListTile(title: Text('Post not found'));
                  }

                  var post = postSnapshot.data!;
                  var postData = post.data() as Map<String, dynamic>;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(title: Text('Loading user...'));
                      }
                      if (userSnapshot.hasError) {
                        return ListTile(title: Text('Error: ${userSnapshot.error}'));
                      }
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return ListTile(title: Text('User not found'));
                      }

                      var user = userSnapshot.data!;
                      var userData = user.data() as Map<String, dynamic>;

                      return ListTile(
                        leading: postData['imageUrls'] != null && postData['imageUrls'].isNotEmpty
                            ? Image.network(postData['imageUrls'][0], width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.image),
                        title: Text(userData['username'] ?? 'Unknown user'),
                        subtitle: Text(postData['description'] ?? 'No description'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(post: post),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
