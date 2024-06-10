import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'base_screen.dart';
import 'other_user_profile_screen.dart';

class OtherUserScreen extends StatefulWidget {
  @override
  _OtherUserScreenState createState() => _OtherUserScreenState();
}

class _OtherUserScreenState extends State<OtherUserScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final currentUserId = currentUser.uid;

      return Scaffold(
        appBar: AppBar(
          title: _isSearching ? _buildSearchField() : Text('Other Users'),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black),
          actions: _buildActions(),
          automaticallyImplyLeading: false,
        ),
        body: Container(
          color: Colors.white,
          child: StreamBuilder<List<UserProfile>>(
            stream: _firestoreService.getUserProfiles(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No profiles found'));
              }

              final profiles = snapshot.data!;
              final filteredProfiles = profiles.where((profile) {
                return profile.username
                    .toLowerCase()
                    .contains(_searchText.toLowerCase());
              }).toList();

              return ListView.builder(
                itemCount: filteredProfiles.length,
                itemBuilder: (context, index) {
                  final profile = filteredProfiles[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile.profilePictureUrl != null
                          ? NetworkImage(profile.profilePictureUrl!)
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      child: profile.profilePictureUrl == null
                          ? Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(profile.username),
                    subtitle: Text(profile.fullName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherUserProfileScreen(
                            userId: profile.userId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        bottomNavigationBar: BaseScreen(currentIndex: 1),
      );
    } else {
      // Handle case where current user is null (not logged in)
      return Scaffold(
          // Widget for users who are not logged in
          );
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
      style: TextStyle(color: Colors.black, fontSize: 16.0),
    );
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _isSearching = false;
            });
          },
        ),
      ];
    }

    return [
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          setState(() {
            _isSearching = true;
          });
        },
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<UserProfile>> getUserProfiles(String currentUserId) {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .where((doc) => doc.id != currentUserId) // Exclude current user
        .map((doc) => UserProfile.fromFirestore(doc.id, doc.data()))
        .toList());
  }
}

class UserProfile {
  final String userId;
  final String fullName;
  final String username;
  final String? profilePictureUrl;
  final String? bio;
  final int countPost;
  final int countMarketplace;
  final List<dynamic> linked;

  UserProfile({
    required this.userId,
    required this.fullName,
    required this.username,
    this.profilePictureUrl,
    this.bio,
    required this.countPost,
    required this.countMarketplace,
    required this.linked,
  });

  factory UserProfile.fromFirestore(String userId, Map<String, dynamic> data) {
    return UserProfile(
      userId: userId,
      username: data['username'] ?? '',
      fullName: data['fullName'] ?? '',
      profilePictureUrl: data['profilePicture'],
      bio: data['bio'],
      countPost: data['countPost'] ?? 0,
      countMarketplace: data['countMarketplace'] ?? 0,
      linked: List<dynamic>.from(data['linked'] ?? []),
    );
  }
}
