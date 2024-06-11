import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_screen.dart';
import 'addStory_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _showFullStory(BuildContext context, String imageUrl, String username, String profilePicture) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        body: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: double.infinity, // Use the full width of the screen
                  height: MediaQuery.of(context).size.width * (16 / 9), // Set height based on the screen width to maintain a 9:16 ratio
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover, // Ensures the image covers the container fully, cropping as necessary
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(profilePicture),
                        radius: 15,
                      ),
                      SizedBox(width: 8),
                      Text(username, style: TextStyle(color: Colors.black, fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }



  Widget _buildStoryThumbnail(DocumentSnapshot storyDoc, BuildContext context) {
    String imageUrl = storyDoc['imageUrl'] as String;
    String userId = storyDoc['userId'] as String;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return Container();
        }

        var userDoc = snapshot.data!;
        String username = userDoc['username'] as String;
        String profilePicture = userDoc['profilePicture'] as String;

        return Column(
          children: [
            InkWell(
              onTap: () => _showFullStory(context, imageUrl, username, profilePicture),
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
            Text(username,
              style: TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddStoryScreen()),
              );
            },
          ),
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

          return Column(
            children: [
              Container(
                height: 90,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('story').snapshots(),
                  builder: (context, storySnapshot) {
                    if (storySnapshot.hasError) {
                      return Text('Error: ${storySnapshot.error}');
                    }

                    if (storySnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!storySnapshot.hasData || storySnapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No stories found'));
                    }

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: storySnapshot.data!.docs.map((doc) {
                        return _buildStoryThumbnail(doc, context);
                      }).toList(),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot post = snapshot.data!.docs[index];
                    return _buildPostCard(post, context);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 0),
    );
  }

  Widget _buildPostCard(DocumentSnapshot post, BuildContext context) {
    String userId = post['userId'] as String;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
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
        String username = userDoc['username'] as String; // Assuming 'username' field exists

        return Card(
          margin: EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(profilePicture),
                ),
                title: Text(username, style: TextStyle(fontWeight: FontWeight.bold)), // Changed from caption to username
                trailing: Icon(Icons.more_vert),
              ),
              Image.network(post['imageUrl'] as String? ?? 'default_image_url', fit: BoxFit.cover),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
                      IconButton(icon: Icon(Icons.comment), onPressed: () {}),
                      IconButton(icon: Icon(Icons.send), onPressed: () {}),
                    ],
                  ),
                  IconButton(icon: Icon(Icons.bookmark_border), onPressed: () {}),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.topLeft,
                child: Text('Liked by others', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.topLeft,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(text: username, style: TextStyle(fontWeight: FontWeight.bold)), // Changed to display username
                      TextSpan(text: " " + (post['description'] as String? ?? 'No Description'), style: TextStyle(fontWeight: FontWeight.normal)),
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
  }
}
