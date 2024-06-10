import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_screen.dart';
import 'signin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.camera_alt, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('post').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
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
              Map<String, dynamic>? postData = post.data() as Map<String, dynamic>?;

              // Use null-aware operators to ensure no null access
              String imageUrl = postData?.containsKey('imageUrl') ?? false
                ? postData!['imageUrl'] as String
                : 'default_image_url';
              String caption = postData?.containsKey('caption') ?? false
                ? postData!['caption'] as String
                : 'ERROR NAME';
              String description = postData?.containsKey('description') ?? false
                ? postData!['description'] as String
                : 'No Description';

              return Card(
                margin: EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                      title: Text(caption, style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.more_vert),
                    ),
                    Image.network(imageUrl, fit: BoxFit.cover),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.favorite_border),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.comment),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.send),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.bookmark_border),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Liked by others',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.topLeft,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 16, color: Colors.black), // Default style for all spans
                          children: <TextSpan>[
                            TextSpan(
                              text: caption, // Your caption variable
                              style: TextStyle(fontWeight: FontWeight.bold), // Bold text for the caption
                            ),
                            TextSpan(
                              text: " " + description,
                              style: TextStyle(fontWeight: FontWeight.normal), // Normal weight text
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      alignment: Alignment.topLeft,
                      child: Text('View all comments'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 0),
    );
  }
}
