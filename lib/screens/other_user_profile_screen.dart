import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'marketplace_detail_screen.dart';
import 'post_detail_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  OtherUserProfileScreen({required this.userId});

  @override
  _OtherUserProfileScreenState createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Future<Map<String, dynamic>> profileData;
  bool _isLinked = false;

  @override
  void initState() {
    super.initState();
    profileData = _fetchProfileData();
    _checkIfLinked();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    DocumentSnapshot userProfileSnapshot =
        await _firestore.collection('users').doc(widget.userId).get();
    return userProfileSnapshot.data() as Map<String, dynamic>;
  }

  Future<List<DocumentSnapshot>> _fetchUserMarketplaceItems(
      String userId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('marketplace')
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs;
  }

  Future<List<DocumentSnapshot>> _fetchUserPosts(String userId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('post')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
    return querySnapshot.docs;
  }

  int _countLinked(List<dynamic> linked) {
    return linked.length;
  }

  Future<void> _checkIfLinked() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final currentUserId = currentUser.uid;
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUserLinked = currentUserDoc.data()?['linked'] ?? [];

      setState(() {
        _isLinked = currentUserLinked.contains(widget.userId);
      });
    }
  }

  Future<void> _linkUser() async {
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;

    if (_isLinked) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .update({
        'linked': FieldValue.arrayRemove([widget.userId]),
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .update({
        'linked': FieldValue.arrayUnion([widget.userId]),
      });
    }

    setState(() {
      _isLinked = !_isLinked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: profileData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: Text('No profile data found')),
          );
        }

        var profileData = snapshot.data!;
        String userId = widget.userId;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              profileData['username'],
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: ElevatedButton(
                  onPressed: _linkUser,
                  child: Text(
                    _isLinked ? 'Linked' : 'Link',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: profileData['profilePicture'] != null &&
                        profileData['profilePicture'].isNotEmpty
                    ? NetworkImage(profileData['profilePicture'])
                    : null,
                child: profileData['profilePicture'] == null ||
                        profileData['profilePicture'].isEmpty
                    ? Icon(Icons.person, color: Colors.grey, size: 80)
                    : null,
              ),
              SizedBox(height: 20),
              Text(
                profileData['fullName'],
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                profileData['bio'] ?? 'No bio available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        profileData['countPost'].toString(),
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'posts',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        profileData['countMarketplace'].toString(),
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'items',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _countLinked(profileData['linked'] ?? []).toString(),
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'linked',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.grid_on, color: Colors.black)),
                          Tab(
                              icon: Icon(Icons.shopping_cart,
                                  color: Colors.black)),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            FutureBuilder<List<DocumentSnapshot>>(
                              future: _fetchUserPosts(userId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                      child: Text('No posts available'));
                                }

                                var posts = snapshot.data!;
                                return GridView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8.0,
                                    mainAxisSpacing: 8.0,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: posts.length,
                                  itemBuilder: (context, index) {
                                    var post = posts[index].data()
                                        as Map<String, dynamic>;
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PostDetailScreen(
                                                    post: posts[index]),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              color: Colors.black, width: 1),
                                        ),
                                        child: post['imageUrls'] != null &&
                                                post['imageUrls'].isNotEmpty
                                            ? Image.network(
                                                post['imageUrls'][0],
                                                fit: BoxFit.cover)
                                            : post['thumbnailUrl'] != null
                                                ? Stack(
                                                    children: [
                                                      Image.network(
                                                          post['thumbnailUrl'],
                                                          fit: BoxFit.cover),
                                                      Center(
                                                        child: Icon(
                                                          Icons
                                                              .play_circle_outline,
                                                          color: Colors.white,
                                                          size: 50,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Container(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            FutureBuilder<List<DocumentSnapshot>>(
                              future: _fetchUserMarketplaceItems(userId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                      child: Text('Not yet sold anything'));
                                }

                                var items = snapshot.data!;
                                return GridView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8.0,
                                    mainAxisSpacing: 8.0,
                                    childAspectRatio: 3 / 4,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    var item = items[index].data()
                                        as Map<String, dynamic>;
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MarketPlaceDetailScreen(
                                              item: items[index],
                                              canEditDelete: false,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            15)),
                                                child: item['images'] != null &&
                                                        item['images']
                                                            .isNotEmpty
                                                    ? Image.network(
                                                        item['images'][0],
                                                        width: double.infinity,
                                                        fit: BoxFit.cover)
                                                    : Container(),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name'] ?? 'No Name',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.attach_money,
                                                          color: Colors.green,
                                                          size: 16),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        item['price']
                                                                ?.toString() ??
                                                            'N/A',
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.green),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4)
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
