import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSettingScreen extends StatefulWidget {
  @override
  _ProfileSettingScreenState createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late User _currentUser;
  late Future<Map<String, dynamic>> _profileData;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    _profileData = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    DocumentSnapshot snapshot =
        await _firestore.collection('users').doc(_currentUser.uid).get();

    if (snapshot.exists) {
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      if (data != null) {
        // Fill the text controllers with the fetched data
        _usernameController.text = data['username'] ?? '';
        _fullNameController.text = data['fullName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneNumberController.text = data['phoneNumber'] ?? '';
        _bioController.text = data['biodata'] ?? '';
        return data;
      }
    }
    return {};
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

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
      String filePath = 'profile_pictures/${_currentUser.uid}.png';
      await _storage.ref().child(filePath).putFile(_imageFile!);

      String downloadUrl = await _storage.ref().child(filePath).getDownloadURL();

      await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .update({'profilePicture': downloadUrl});

      setState(() {
        _profileData = _fetchProfileData();
      });
    } catch (e) {
      print('Error uploading profile picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileData,
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
        String profilePictureUrl = profileData['profilePicture'];

        return Scaffold(
          appBar: AppBar(
            title: Text('Edit Profile'),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                            ? NetworkImage(profilePictureUrl)
                            : null,
                        child: profilePictureUrl == null || profilePictureUrl.isEmpty
                            ? Icon(Icons.person, color: Colors.grey, size: 100)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.0),
                _buildProfileField('Username', _usernameController),
                _buildProfileField('Full Name', _fullNameController),
                _buildProfileField('Email', _emailController),
                _buildProfileField('Phone Number', _phoneNumberController),
                _buildProfileField('Bio', _bioController),
                SizedBox(height: 32.0),
                ElevatedButton(
                  onPressed: () => _saveProfile(context),
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter $label',
                labelText: controller.text.isNotEmpty ? null : label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile(BuildContext context) async {
    // Validate input fields
    if (_usernameController.text.isEmpty || 
        _fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all required fields.'),
      ));
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Get the values from the text fields
      String username = _usernameController.text.trim();
      String fullName = _fullNameController.text.trim();
      String email = _emailController.text.trim();
      String phoneNumber = _phoneNumberController.text.trim();
      String biodata = _bioController.text.trim();

      // Update Firestore
      await _firestore.collection('users').doc(_currentUser.uid).update({
        'username': username,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'biodata': biodata,
      });

      // Hide loading indicator
      Navigator.pop(context);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile updated successfully!'),
      ));

      // Navigate back to the profile user screen
      Navigator.pop(context);
    } catch (error) {
      // Hide loading indicator
      Navigator.pop(context);

      // Show an error message if any
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update profile: $error'),
      ));
    }
  }
}