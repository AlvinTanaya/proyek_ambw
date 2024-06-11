import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'base_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : Text('Other Users'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black),
        actions: _buildActions(),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<List<UserProfile>>(
          stream: _firestoreService.getUserProfiles(),
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
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(Icons.person, color: Colors.grey),
                  ),
                  title: Text(profile.username),
                  subtitle: Text(profile.fullName),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 1),
    );
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

  Stream<List<UserProfile>> getUserProfiles() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserProfile.fromFirestore(doc.data()))
        .toList());
  }
}

class UserProfile {
  final String fullName;
  final String username;

  UserProfile({
    required this.fullName,
    required this.username,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      username: data['username'] ?? '',
      fullName: data['fullName'] ?? '',
    );
  }
}
