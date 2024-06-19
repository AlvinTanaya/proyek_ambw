import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'marketplace_detail_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  OtherUserProfileScreen({required this.userId});

  @override
  _OtherUserProfileScreenState createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    // Get the current user's ID
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;

    if (_isLinked) {
      // If already linked, unlink the users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .update({
        'linked': FieldValue.arrayRemove([widget.userId]),
      });
    } else {
      // If not linked, link the users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .update({
        'linked': FieldValue.arrayUnion([widget.userId]),
      });
    }

    setState(() {
      // Toggle the linked state
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
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileData['profilePicture'] != null &&
                              profileData['profilePicture'].isNotEmpty
                          ? NetworkImage(profileData['profilePicture'])
                          : null,
                      child: profileData['profilePicture'] == null ||
                              profileData['profilePicture'].isEmpty
                          ? Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profileData['fullName'],
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(profileData['bio'] ?? 'No bio available'),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Posts: ${profileData['countPost']}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed:
                                  _linkUser, // Call _linkUser function when the button is pressed
                              child: Text(_isLinked ? 'Linked' : 'Link'),
                            ),
                          ],
                        ),
                        Text(
                            'Items Sold: ${profileData['countMarketplace']}'), // Ensure this field exists in Firestore
                        Text(
                            'Linked: ${_countLinked(profileData['linked'] ?? [])}'), // Ensure this field exists in Firestore
                      ],
                    ),
                  ],
                ),
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
                            Center(
                                child: Text(
                                    'No Posts')), // Placeholder for posts page
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
                                    childAspectRatio: 3 / 2,
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
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: item['images'] != null &&
                                                      item['images'].isNotEmpty
                                                  ? Image.network(
                                                      item['images'][0],
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(), // Handle missing image
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['price']?.toString() ??
                                                        'N/A',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(item['name'] ??
                                                      'No Name'),
                                                  Text(
                                                    item['userName'] ??
                                                        'Unknown User',
                                                    style: TextStyle(
                                                        color: Colors.grey),
                                                  ),
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
