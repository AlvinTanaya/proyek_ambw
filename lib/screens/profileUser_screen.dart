import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'base_screen.dart';
import 'marketplace_detail_screen.dart';
import 'profile_setting_screen.dart';

class ProfileUserScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> _fetchProfileData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("No user logged in");
    }
    String userId = currentUser.uid;
    DocumentSnapshot userProfileSnapshot =
        await _firestore.collection('users').doc(userId).get();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchProfileData(),
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
        String userId = _auth.currentUser!.uid;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false, // Remove the back arrow
            title: Text(profileData['username'],
                style: TextStyle(color: Colors.black)),
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfileSettingScreen()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/images/logo1.png'),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profileData['fullName'],
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                            'Posts: ${profileData['postCount']}'), // Ensure this field exists in Firestore
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
                                              padding:
                                                  const EdgeInsets.all(8.0),
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
                                                  Text(
                                                    item['name'] ?? 'No Name',
                                                  ),
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
          bottomNavigationBar: BaseScreen(currentIndex: 4),
        );
      },
    );
  }
}
