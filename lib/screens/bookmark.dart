import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

          List<String> bookmarks = List<String>.from(snapshot.data!['bookmarks'] ?? []);
          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('post').doc(bookmarks[index]).get(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text('Loading...'));
                  }
                  if (postSnapshot.hasError) {
                    return ListTile(title: Text('Error: ${postSnapshot.error}'));
                  }
                  if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                    return ListTile(title: Text('Post not found'));
                  }

                  var post = postSnapshot.data!;
                  var postData = post.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: postData['imageUrls'] != null && postData['imageUrls'].isNotEmpty
                        ? Image.network(postData['imageUrls'][0], width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.image),
                    title: Text(postData['description'] ?? 'No description'),
                    subtitle: Text(postData['username'] ?? 'Unknown user'),
                    onTap: () {
                      // Navigate to post detail page
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
