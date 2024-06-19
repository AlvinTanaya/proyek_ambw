import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'other_user_profile_screen.dart';

class LikersPage extends StatelessWidget {
  final String postId;

  const LikersPage({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Who Liked This Post"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('post').doc(postId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return Center(child: Text("No likes yet"));
          }

          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          Map likes = data['likes'] ?? {};
          List<String> userIds = likes.keys.cast<String>().toList();  // Explicit casting to List<String>

          if (userIds.isEmpty) {
            return Center(child: Text("No likes yet"));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: userIds).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                return Center(child: Text("No user details found"));
              }

              return ListView(
                children: userSnapshot.data!.docs.map((userDoc) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userDoc['profilePicture'] != null ? NetworkImage(userDoc['profilePicture']) : null,
                      backgroundColor: Colors.grey,
                      child: userDoc['profilePicture'] == null ? Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(userDoc['username'] ?? 'Unknown'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherUserProfileScreen(userId: userDoc.id),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
