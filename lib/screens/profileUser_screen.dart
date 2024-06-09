import 'package:flutter/material.dart';
import 'base_screen.dart';

class ProfileUserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Profile Screen'),
      ),
      bottomNavigationBar: BaseScreen(currentIndex: 4),
    );
  }
}
