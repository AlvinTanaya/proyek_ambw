import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'base_screen.dart';
import 'signin_screen.dart';

class ProfileSettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text("Logout"),
          onPressed: () {
            FirebaseAuth.instance.signOut().then((value) {
              print("Signed Out");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen()),
              );
            });
          },
        ),
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 0),
    );
  }
}
