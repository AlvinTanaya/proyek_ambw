import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'base_screen.dart';
import 'marketplace_detail_screen.dart';
import 'post_detail_screen.dart';
import 'profile_setting_screen.dart';
import 'signin_screen.dart'; // Import halaman SignInScreen jika belum diimpor

class ProfileUserScreen extends StatefulWidget {
  @override
  _ProfileUserScreenState createState() => _ProfileUserScreenState();
}

class _ProfileUserScreenState extends State<ProfileUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late User currentUser;
  late Future<Map<String, dynamic>> profileData;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser!;
    profileData = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    DocumentSnapshot userProfileSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();
    return userProfileSnapshot.data() as Map<String, dynamic>;
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;

    try {
      String filePath = 'profile_pictures/${currentUser.uid}.png';
      await _storage.ref().child(filePath).putFile(_imageFile!);

      String downloadUrl =
          await _storage.ref().child(filePath).getDownloadURL();

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({'profilePicture': downloadUrl});

      setState(() {
        profileData = _fetchProfileData();
      });
    } catch (e) {
      print('Error uploading profile picture: $e');
    }
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
        .get();
    return querySnapshot.docs;
  }

  Future<int> _fetchUserPostsImageCount(String userId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('post')
        .where('userId', isEqualTo: userId)
        .get();

    int imageCount = 0;
    querySnapshot.docs.forEach((doc) {
      Map<String, dynamic> postData = doc.data() as Map<String, dynamic>;
      if (postData['imageUrl'] != null && postData['imageUrl'].isNotEmpty) {
        imageCount++;
      }
    });

    return imageCount;
  }

  int _countLinked(List<dynamic> linked) {
    return linked.length;
  }

  void _showFeedbackDialog(BuildContext context) {
    String _feedback = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: Text('Give Feedback'),
          content: Container(
            width: double.maxFinite,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Enter your feedback...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (value) {
                _feedback = value;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Submit'),
              onPressed: () async {
                // Handle submit logic here, e.g., send feedback to server or process locally
                String feedbackText = _feedback;
                // Simulate a delay for demonstration purposes (replace with actual logic)
                await Future.delayed(Duration(seconds: 1));
                // Show notification
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green,
                    content: Text('Feedback submitted successfully!'),
                  ),
                );
                // Close the feedback dialog
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => SignInScreen()),
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  void _deleteAccount() async {
    try {
      await currentUser.delete();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => SignInScreen()),
      );
    } catch (e) {
      print('Error deleting account: $e');
    }
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
        String userId = currentUser.uid;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false, // Remove the back arrow
            title: Text(profileData['username'],
                style: TextStyle(color: Colors.black)),
            actions: [
              IconButton(
                icon: Icon(Icons.bookmark, color: Colors.black),
                onPressed: () {
                  // Handle bookmark action
                },
              ),
              PopupMenuButton(
                icon: Icon(Icons.settings, color: Colors.black),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text('Edit Profile'),
                    value: 'edit_profile',
                  ),
                  PopupMenuItem(
                    child: Text('Feedback'),
                    value: 'feedback',
                  ),
                  PopupMenuItem(
                    child: Text('Log out'),
                    value: 'logout',
                  ),
                  PopupMenuItem(
                    child: Text('Delete account'),
                    value: 'delete_account',
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit_profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileSettingScreen(),
                      ),
                    );
                  } else if (value == 'feedback') {
                    _showFeedbackDialog(context);
                  } else if (value == 'logout') {
                    _logout();
                  } else if (value == 'delete_account') {
                    _deleteAccount();
                  }
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Stack(
                children: [
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
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                profileData['fullName'],
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                profileData['biodata'] ?? 'No bio available',
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
                                    crossAxisSpacing: 0,
                                    mainAxisSpacing: 0,
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
                                              post: posts[index],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              color: Colors.black, width: 1),
                                        ),
                                        child: post['imageUrl'] != null &&
                                                post['imageUrl'].isNotEmpty
                                            ? Image.network(
                                                post['imageUrl'],
                                                fit: BoxFit.cover,
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
                                              canEditDelete: true,
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
                                                        fit: BoxFit.cover,
                                                      )
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
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.attach_money,
                                                        color: Colors.green,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        item['price']
                                                                ?.toString() ??
                                                            'N/A',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.green,
                                                        ),
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
          bottomNavigationBar: BaseScreen(currentIndex: 4),
        );
      },
    );
  }
}
