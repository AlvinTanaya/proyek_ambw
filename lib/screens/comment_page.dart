import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class CommentPage extends StatefulWidget {
  final String postId;

  const CommentPage({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_commentController.text.isNotEmpty && user != null) {
      await FirebaseFirestore.instance.collection('comments').add({
        'postId': widget.postId,
        'userId': user.uid,
        'text': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comments"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('postId', isEqualTo: widget.postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var documents = snapshot.data!.docs;

                if (documents.isEmpty) {
                  return Center(child: Text("There are no comments yet"));
                }

                documents.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

                return ListView(
                  children: documents.map((doc) => _buildCommentTile(doc)).toList(),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(DocumentSnapshot comment) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(comment['userId']).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(
            leading: CircleAvatar(),
            title: Text('Loading...'),
            subtitle: Text(comment['text'] ?? ''),
          );
        }
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: snapshot.data!['profilePicture'] != null
              ? NetworkImage(snapshot.data!['profilePicture'])
              : null,
            child: snapshot.data!['profilePicture'] == null ? Icon(Icons.person) : null,
          ),
          title: Text(snapshot.data!['username'] ?? 'Anonymous'),
          subtitle: Text(comment['text'] ?? ''),
        );
      },
    );
  }
}
